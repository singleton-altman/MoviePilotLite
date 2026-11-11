import 'package:moviepilot_mobile/modules/player/widgets/detail_play_section.dart';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_controller.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_comment_models.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_notexists.dart';
import 'package:moviepilot_mobile/modules/media_detail/pages/media_season_detail_page.dart';
import 'package:moviepilot_mobile/modules/media_detail/services/danmaku_display_settings_service.dart';
import 'package:moviepilot_mobile/modules/media_detail/widgets/media_detail_season_card.dart';
import 'package:moviepilot_mobile/modules/media_detail/widgets/media_danmaku_overlay.dart';
import 'package:moviepilot_mobile/modules/search/pages/search_mid_sheet.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_tv_season_sheet.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/media_source_util.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:moviepilot_mobile/modules/tmdb/pages/tmdb_collection_page.dart';

class MediaDetailPage extends GetWidget<MediaDetailController> {
  const MediaDetailPage({super.key});

  static const double _pageHorizontalPadding = 16;
  static const double _contentMaxWidth = 680;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Obx(() {
        final detail = controller.mediaDetail.value;
        final prefill = controller.prefillDetail;
        final isLoading = controller.isLoading.value;
        final errorText = controller.errorText.value;
        final hasError = errorText != null && errorText.trim().isNotEmpty;
        if (detail == null && prefill == null && !isLoading) {
          if (hasError) {
            return _buildErrorState(context, errorText);
          }
          return _buildEmptyState(context);
        }

        final headerDetail = detail ?? prefill ?? _skeletonDetail();
        final viewDetail = detail ?? _skeletonDetail();
        final contentSkeletonEnabled = isLoading && detail == null;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(context, headerDetail, isLoading: isLoading),
            SliverToBoxAdapter(
              child: contentSkeletonEnabled
                  ? _buildLoadingSkeleton(context)
                  : _buildContent(
                      context,
                      viewDetail,
                      errorText: hasError && !isLoading ? errorText : null,
                      isLoading: isLoading,
                    ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 44)),
          ],
        );
      }),
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildContentFrame(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pageHorizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: child,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.fetchDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.photo,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 12),
            Text('暂无详情数据', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    MediaDetail? detail, {
    required bool isLoading,
  }) {
    final posterUrl = _resolveImageUrl(detail?.poster_path);
    final backdropUrl = _resolveImageUrl(detail?.backdrop_path) ?? posterUrl;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final expandedHeight = isWide ? 400.0 : 520.0;
    final danmakuSettings =
        Get.find<DanmakuDisplaySettingsService>().settings.value;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      backgroundColor: AppTheme.darkBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.circular(44),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.chevron_left, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
      ),

      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (backdropUrl != null) _buildHeaderBackdrop(backdropUrl),
            if (isLoading) _buildHeaderLoadingBackdrop(context, isWide: isWide),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.18),
                    AppTheme.darkBackgroundColor,
                  ],
                  stops: const [0.0, 0.58, 1.0],
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxHeight < 300) {
                    return const SizedBox.shrink();
                  }
                  final comments = controller.doubanComments
                      .where(
                        (comment) => comment.comment?.trim().isNotEmpty == true,
                      )
                      .take(24)
                      .toList(growable: false);
                  if (comments.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: isWide
                            ? 60
                            : MediaQuery.of(context).padding.top + 56,
                        left: 14,
                        right: 14,
                      ),
                      child: Semantics(
                        button: true,
                        label: '弹幕设置',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Get.toNamed('/settings/system/danmaku'),
                          child: SizedBox(
                            height: 90,
                            child: MediaDanmakuOverlay(
                              comments: comments,
                              laneCount: 3,
                              settings: danmakuSettings,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildHeaderContentFrame(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: isWide
                      ? _buildWideHeaderContent(
                          context,
                          posterUrl: posterUrl,
                          detail: detail,
                          isLoading: isLoading,
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // _buildPoster(posterUrl, width: 126, height: 126),
                            const SizedBox(height: 16),
                            _buildHeaderInfo(context, detail),
                            const SizedBox(height: 14),
                            _buildActionButtons(context, detail, isLoading),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBackdrop(String backdropUrl) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedImage(imageUrl: backdropUrl, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.34),
                  AppTheme.darkBackgroundColor,
                ],
                stops: const [0, 0.54, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderLoadingBackdrop(
    BuildContext context, {
    required bool isWide,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: isWide
              ? const Alignment(0, -0.18)
              : const Alignment(0, -0.36),
          child: AppLoading(
            size: isWide ? 132 : 116,
            message: '加载详情中',
            messageStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            spacing: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContentFrame({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pageHorizontalPadding),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWideHeaderContent(
    BuildContext context, {
    required String? posterUrl,
    required MediaDetail? detail,
    required bool isLoading,
  }) {
    final showInlineActions = posterUrl != null;
    return SizedBox(
      height: 224,
      width: double.infinity,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: showInlineActions
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPoster(posterUrl, width: 128, height: 192),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderInfo(context, detail, alignStart: true),
                        const SizedBox(height: 14),
                        _buildActionButtons(context, detail, isLoading),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPoster(posterUrl, width: 100, height: 100),
                      const SizedBox(width: 22),
                      _buildHeaderInfo(context, detail, alignStart: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildActionButtons(context, detail, isLoading),
                ],
              ),
      ),
    );
  }

  Widget _buildPoster(String? posterUrl, {double? width, double? height}) {
    final w = width ?? 110.0;
    final h = height ?? 165.0;
    if (posterUrl == null) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Icon(
          CupertinoIcons.photo,
          color: Colors.white70,
          size: 32,
        ),
      );
    }
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(31),
        child: CachedImage(
          imageUrl: posterUrl,
          fit: BoxFit.cover,
          width: w,
          height: h,
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(
    BuildContext context,
    MediaDetail? detail, {
    bool alignStart = false,
  }) {
    final subtitle = _subtitle(detail);
    return Column(
      crossAxisAlignment: alignStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _displayTitle(detail),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: alignStart ? TextAlign.start : TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
          ),
        ],
        const SizedBox(height: 14),
        _buildTagRow(detail, alignStart: alignStart),
      ],
    );
  }

  Widget _buildTagRow(MediaDetail? detail, {bool alignStart = false}) {
    final parts = <String>[];
    final type = detail?.type?.trim();
    if (type != null && type.isNotEmpty) {
      parts.add(type);
    } else if (detail != null) {
      parts.add(_isTv(detail) ? '电视剧' : '电影');
    }
    final category = detail?.category?.trim();
    if (category != null && category.isNotEmpty && !parts.contains(category)) {
      parts.add(category);
    }
    final genres = detail?.genres
        ?.map((genre) => genre.name)
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .take(2);
    if (genres != null) {
      for (final genre in genres) {
        if (!parts.contains(genre)) parts.add(genre);
      }
    }

    final score = (detail?.vote_average ?? 0) > 0
        ? detail!.vote_average!.toStringAsFixed(1)
        : null;
    final contentRating = _contentRating(detail);

    return Row(
      mainAxisAlignment: alignStart
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        _buildSourceMark(detail),
        if (parts.isNotEmpty) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              parts.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.94),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
        if (score != null) ...[
          const SizedBox(width: 10),
          _buildRingBadge(score, icon: CupertinoIcons.star_fill),
        ],
        if (contentRating != null) ...[
          const SizedBox(width: 8),
          _buildRingBadge(contentRating, highlight: true),
        ],
        Obx(() {
          final app = Get.find<AppService>();
          if (!app.enableFetchMediaserverLibraryStatus.value ||
              !controller.mediaserverInLibrary.value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF81C784).withValues(alpha: 0.20),
                border: Border.all(
                  color: const Color(0xFF81C784).withValues(alpha: 0.42),
                ),
              ),
              child: const Icon(
                CupertinoIcons.checkmark,
                size: 14,
                color: Color(0xFFA7F3D0),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSourceMark(MediaDetail? detail) {
    final raw =
        ('${detail?.media_source ?? ''} ${detail?.source ?? ''} '
                '${detail?.mediaid_prefix ?? ''} '
                '${controller.args.path.split(':').first}')
            .toLowerCase();
    String? iconPath;
    if (raw.contains('douban')) {
      iconPath = Assets.images.logos.douban.path;
    } else if (raw.contains('tmdb') || raw.contains('themoviedb')) {
      iconPath = Assets.images.logos.tmdb.path;
    }
    return Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: iconPath != null
          ? Image.asset(iconPath, fit: BoxFit.contain)
          : Icon(
              CupertinoIcons.film,
              size: 17,
              color: Colors.white.withValues(alpha: 0.9),
            ),
    );
  }

  Widget _buildRingBadge(
    String text, {
    IconData? icon,
    bool highlight = false,
  }) {
    final color = highlight ? const Color(0xFFFFD66B) : Colors.white;
    return Container(
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFF5C518).withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight
              ? const Color(0xFFFFD66B).withValues(alpha: 0.56)
              : Colors.white.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MediaDetail detail, {
    String? errorText,
    bool isLoading = false,
  }) {
    final similarItems = controller.similarItems.toList();
    final recommendItems = controller.recommendItems.toList();
    final similarLoading = controller.isLoadingSimilar.value;
    final recommendLoading = controller.isLoadingRecommend.value;
    final similarError = controller.errorSimilar.value;
    final recommendError = controller.errorRecommend.value;
    final similarSupported = controller.similarSupported.value;
    final recommendSupported = controller.recommendSupported.value;

    return _buildContentFrame(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (errorText != null && errorText.trim().isNotEmpty) ...[
            _buildSectionTitle('请求错误'),
            _buildGlassPanel(child: _buildErrorBanner(errorText)),
            const SizedBox(height: 16),
          ],
          _buildOverView(context, detail),
          if ((detail.collection_id ?? 0) > 0) ...[
            const SizedBox(height: 16),
            _buildGlassPanel(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.collections_bookmark_outlined),
                title: const Text('查看系列合集'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.to(
                  () => TmdbCollectionPage(collectionId: detail.collection_id!),
                ),
              ),
            ),
          ],
          if (detail.season_info != null && detail.season_info!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('季度信息'),
            _buildSeasonList(context, detail.season_info!, detail),
          ],
          const SizedBox(height: 16),
          _buildSectionTitle('核心信息'),
          _buildInfoList(context, detail),

          if (detail.actors != null && detail.actors!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('主演'),
            const SizedBox(height: 16),
            _buildActorList(detail.actors!),
            const SizedBox(height: 16),
          ],

          if (controller.doubanCommentsEnabled.value ||
              controller.doubanReviewsEnabled.value) ...[
            const SizedBox(height: 2),
            _buildSectionTitle('豆瓣短评'),
            const SizedBox(height: 12),
            _buildDoubanComments(),
            const SizedBox(height: 18),
            _buildSectionTitle('豆瓣影评'),
            const SizedBox(height: 12),
            _buildDoubanReviews(),
            const SizedBox(height: 16),
          ],

          if (similarSupported &&
              _shouldShowRelatedSection(
                similarItems,
                similarLoading,
                similarError,
              )) ...[
            _buildSectionTitle(_relatedSectionTitle(detail, isSimilar: true)),
            const SizedBox(height: 14),
            _buildRelatedRail(
              context,
              items: similarItems,
              isLoading: similarLoading,
              errorText: similarError,
            ),
          ],
          if (recommendSupported &&
              _shouldShowRelatedSection(
                recommendItems,
                recommendLoading,
                recommendError,
              )) ...[
            const SizedBox(height: 18),
            _buildSectionTitle(_relatedSectionTitle(detail, isSimilar: false)),
            const SizedBox(height: 14),
            _buildRelatedRail(
              context,
              items: recommendItems,
              isLoading: recommendLoading,
              errorText: recommendError,
            ),
          ],
          if (_hasExternalLinks(detail)) ...[
            const SizedBox(height: 20),
            _buildSectionTitle('相关链接'),
            const SizedBox(height: 12),
            _buildExternalLinks(context, detail, isLoading),
          ],
        ],
      ),
    );
  }

  Widget _buildDoubanComments() {
    final items = controller.doubanComments;
    final isLoading = controller.isLoadingDoubanComments.value;
    final isLoadingMore = controller.isLoadingMoreDoubanComments.value;
    if (items.isEmpty) {
      return _buildGlassPanel(
        child: _buildDoubanStatus(isLoading: isLoading, emptyText: '暂无豆瓣短评'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGlassPanel(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _buildDoubanCommentTile(items[index]),
                if (index != items.length - 1)
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
              ],
            ],
          ),
        ),
        LoadMoreFooter(
          hasMore: controller.hasMoreDoubanComments,
          isLoading: isLoadingMore,
          total: controller.doubanCommentsTotal.value,
          onLoadMore: controller.loadMoreDoubanComments,
        ),
      ],
    );
  }

  Widget _buildDoubanReviews() {
    final items = controller.doubanReviews;
    final isLoading = controller.isLoadingDoubanReviews.value;
    final isLoadingMore = controller.isLoadingMoreDoubanReviews.value;
    if (items.isEmpty) {
      return _buildGlassPanel(
        child: _buildDoubanStatus(isLoading: isLoading, emptyText: '暂无豆瓣影评'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGlassPanel(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _buildDoubanReviewTile(items[index]),
                if (index != items.length - 1)
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
              ],
            ],
          ),
        ),
        LoadMoreFooter(
          hasMore: controller.hasMoreDoubanReviews,
          isLoading: isLoadingMore,
          total: controller.doubanReviewsTotal.value,
          onLoadMore: controller.loadMoreDoubanReviews,
        ),
      ],
    );
  }

  Widget _buildDoubanStatus({
    required bool isLoading,
    required String emptyText,
  }) {
    return Row(
      children: [
        if (isLoading) ...[
          const CupertinoActivityIndicator(radius: 8, color: Colors.white70),
          const SizedBox(width: 10),
        ],
        Text(
          isLoading ? '正在加载豆瓣评论...' : emptyText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDoubanCommentTile(DoubanComment comment) {
    final author = comment.author;
    final content = comment.comment ?? '';
    final url = comment.url?.trim() ?? '';
    return GestureDetector(
      behavior: url.isEmpty
          ? HitTestBehavior.deferToChild
          : HitTestBehavior.opaque,
      onTap: url.isEmpty ? null : () => WebUtil.open(url: url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoubanAvatar(author?.avatar),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          author?.name ?? '豆瓣用户',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildDoubanRating(comment.rating),
                      const SizedBox(width: 8),
                      if ((comment.createTime ?? '').isNotEmpty)
                        Text(
                          comment.createTime!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.48),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  if (content.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      content,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if ((comment.voteCount ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.hand_thumbsup,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.48),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${comment.voteCount} 有用',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.48),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoubanReviewTile(DoubanReview review) {
    final author = review.author;
    final title = review.title ?? '豆瓣影评';
    final abstract = review.abstract ?? '';
    final url = review.url?.trim() ?? '';
    return GestureDetector(
      behavior: url.isEmpty
          ? HitTestBehavior.deferToChild
          : HitTestBehavior.opaque,
      onTap: url.isEmpty ? null : () => WebUtil.open(url: url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                _buildDoubanAvatar(author?.avatar, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    author?.name ?? '豆瓣用户',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _buildDoubanRating(review.rating),
                const SizedBox(width: 8),
                if ((review.createTime ?? '').isNotEmpty)
                  Text(
                    review.createTime!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.46),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            if (abstract.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                abstract,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            if ((review.usefulCount ?? 0) > 0 ||
                (review.commentsCount ?? 0) > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((review.usefulCount ?? 0) > 0)
                    _buildDoubanMeta(
                      CupertinoIcons.hand_thumbsup,
                      '${review.usefulCount} 有用',
                    ),
                  if ((review.usefulCount ?? 0) > 0 &&
                      (review.commentsCount ?? 0) > 0)
                    const SizedBox(width: 12),
                  if ((review.commentsCount ?? 0) > 0)
                    _buildDoubanMeta(
                      CupertinoIcons.chat_bubble,
                      '${review.commentsCount} 回应',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoubanMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.48)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.48),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDoubanAvatar(String? avatar, {double size = 28}) {
    final raw = avatar?.trim() ?? '';
    final url = raw.isEmpty ? null : ImageUtil.convertCacheImageUrl(raw);
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? Container(
                color: Colors.white.withValues(alpha: 0.12),
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: size * 0.6,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              )
            : CachedImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildDoubanRating(double? rating) {
    final value = rating ?? 0;
    if (value <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 5; index++)
          Icon(
            value >= index + 1
                ? CupertinoIcons.star_fill
                : value > index + 0.25
                ? CupertinoIcons.star_lefthalf_fill
                : CupertinoIcons.star,
            size: 10,
            color: value > index
                ? const Color(0xFFFFD66B)
                : Colors.white.withValues(alpha: 0.24),
          ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final detail = _skeletonDetail();
    return _buildContentFrame(
      Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverView(context, detail),
            const SizedBox(height: 16),
            _buildSectionTitle('核心信息'),
            _buildInfoList(context, detail),
            const SizedBox(height: 16),
            _buildSectionTitle('主演'),
            const SizedBox(height: 16),
            _buildActorList(detail.actors ?? const []),
          ],
        ),
      ),
    );
  }

  Widget _buildOverView(BuildContext context, MediaDetail detail) {
    final overview = detail.overview?.trim().isNotEmpty == true
        ? detail.overview!.trim()
        : '暂无简介';
    final releaseDate = detail.release_date?.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.tagline != null && detail.tagline!.trim().isNotEmpty) ...[
            Text(
              '“${detail.tagline!.trim()}”',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            overview,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          if (releaseDate != null && releaseDate.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.calendar,
                    size: 16,
                    color: Color(0xFF93C5FD),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '上映日期',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  releaseDate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: CupertinoColors.systemRed,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: CupertinoColors.systemRed),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF60A5FA), Color(0xFFF5C518)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList(BuildContext context, MediaDetail? detail) {
    if (detail == null) {
      return const SizedBox.shrink();
    }

    final facts = _buildCoreFacts(detail);
    if (facts.isEmpty && !_hasMoreInfo(detail)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (facts.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 18.0;
                final columns = constraints.maxWidth >= 560 ? 3 : 2;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: 18,
                  children: [
                    for (final fact in facts)
                      SizedBox(width: width, child: _buildFactItem(fact)),
                  ],
                );
              },
            ),
          if (_hasMoreInfo(detail)) ...[
            const SizedBox(height: 18),
            _buildMoreInfoButton(context, detail),
          ],
        ],
      ),
    );
  }

  List<_DetailFact> _buildCoreFacts(MediaDetail detail) {
    final isTv = _isTv(detail);
    final firstAir = detail.first_air_date ?? detail.release_date;
    final seasonEpisode = isTv ? _formatSeasonEpisode(detail) : null;
    final runtime = _formatRuntime(detail);
    final status = _localizedStatus(detail.status);
    final rating = _formatRating(detail);
    final country = _formatCountryCodes(detail.origin_country);
    final languages = _formatLanguages(detail);
    final contentRating = _contentRating(detail);

    return <_DetailFact>[
      if (firstAir != null && firstAir.isNotEmpty)
        _DetailFact(
          icon: CupertinoIcons.calendar,
          label: isTv ? '首播' : '上映',
          value: firstAir,
          accent: const Color(0xFF60A5FA),
        ),
      if (seasonEpisode != null)
        _DetailFact(
          icon: CupertinoIcons.square_stack_3d_up,
          label: '季 / 集',
          value: seasonEpisode,
          accent: const Color(0xFFA78BFA),
        ),
      if (runtime != null && runtime.isNotEmpty)
        _DetailFact(
          icon: CupertinoIcons.timer,
          label: isTv ? '单集时长' : '片长',
          value: runtime,
          accent: const Color(0xFFF97316),
        ),
      if (status != null)
        _DetailFact(
          icon: CupertinoIcons.bolt_circle,
          label: '状态',
          value: status,
          accent: const Color(0xFFF5C518),
        ),
      if (rating != null)
        _DetailFact(
          icon: CupertinoIcons.star_fill,
          label: '评分',
          value: rating,
          accent: const Color(0xFFF5C518),
        ),
      if (country != null)
        _DetailFact(
          icon: CupertinoIcons.map,
          label: '地区',
          value: country,
          accent: const Color(0xFF34D399),
        ),
      if (languages != null)
        _DetailFact(
          icon: CupertinoIcons.globe,
          label: '语言',
          value: languages,
          accent: const Color(0xFF38BDF8),
        ),
      if (contentRating != null)
        _DetailFact(
          icon: CupertinoIcons.shield_lefthalf_fill,
          label: '分级',
          value: contentRating,
          accent: const Color(0xFFFB7185),
        ),
    ];
  }

  bool _hasMoreInfo(MediaDetail detail) {
    return _collectExtraFacts(detail).isNotEmpty ||
        _collectInfoLinks(detail).isNotEmpty ||
        _collectAliases(detail).isNotEmpty;
  }

  List<_DetailFact> _collectExtraFacts(MediaDetail detail) {
    final networks = _joinNames(
      detail.networks?.map((network) => network.name),
    );
    final companies = _joinNames(
      detail.production_companies?.map((company) => company.name),
    );
    final productionCountries = _joinNames(
      detail.production_countries?.map((country) => country.name),
    );
    final directors = _joinNames(
      detail.directors?.map((director) => director.name),
    );
    final creators = _joinNames(
      detail.created_by?.map((creator) => creator.name),
    );
    return <_DetailFact>[
      if (networks != null)
        _DetailFact(
          icon: CupertinoIcons.tv,
          label: '播出平台',
          value: networks,
          accent: const Color(0xFF60A5FA),
        ),
      if (companies != null)
        _DetailFact(
          icon: CupertinoIcons.building_2_fill,
          label: '出品公司',
          value: companies,
          accent: const Color(0xFFA78BFA),
        ),
      if (productionCountries != null)
        _DetailFact(
          icon: CupertinoIcons.flag,
          label: '出品地区',
          value: productionCountries,
          accent: const Color(0xFFF472B6),
        ),
      if (directors != null)
        _DetailFact(
          icon: CupertinoIcons.person_2_fill,
          label: '导演',
          value: directors,
          accent: const Color(0xFFF59E0B),
        ),
      if (creators != null)
        _DetailFact(
          icon: CupertinoIcons.person_crop_circle_fill,
          label: '主创',
          value: creators,
          accent: const Color(0xFFF59E0B),
        ),
    ];
  }

  Widget _buildFactItem(_DetailFact fact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fact.icon,
              size: 10,
              color: fact.accent.withValues(alpha: 0.72),
            ),
            const SizedBox(width: 5),
            Text(
              fact.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: Colors.white.withValues(alpha: 0.44),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          fact.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.32,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoLink(_DetailLink link) {
    final url = link.url?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    return GestureDetector(
      behavior: hasUrl ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      onTap: hasUrl ? () => WebUtil.open(url: url) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            link.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.44),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            link.value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          if (hasUrl) ...[
            const SizedBox(width: 3),
            Icon(
              CupertinoIcons.arrow_up_right,
              size: 9,
              color: Colors.white.withValues(alpha: 0.32),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAliasLine(List<String> aliases) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '别名  ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Colors.white.withValues(alpha: 0.44),
            ),
          ),
          TextSpan(
            text: aliases.join(' / '),
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMoreInfoButton(BuildContext context, MediaDetail detail) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showMoreInfoSheet(context, detail),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '更多资料',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.44),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 10,
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ],
      ),
    );
  }

  Future<void> _showMoreInfoSheet(
    BuildContext context,
    MediaDetail detail,
  ) async {
    final extraFacts = _collectExtraFacts(detail);
    final links = _collectInfoLinks(detail);
    final aliases = _collectAliases(detail);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF17191F),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '更多资料',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (extraFacts.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildSheetFacts(extraFacts),
              ],
              if (links.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSheetSectionTitle('外部编号'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [for (final link in links) _buildInfoLink(link)],
                ),
              ],
              if (aliases.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSheetSectionTitle('别名'),
                const SizedBox(height: 8),
                _buildAliasLine(aliases),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetFacts(List<_DetailFact> facts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 18.0;
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 18,
          children: [
            for (final fact in facts)
              SizedBox(width: width, child: _buildFactItem(fact)),
          ],
        );
      },
    );
  }

  Widget _buildSheetSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: Colors.white.withValues(alpha: 0.42),
      ),
    );
  }

  String? _joinNames(Iterable<String?>? values) {
    if (values == null) return null;
    final names = values
        .map((value) => value?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    return names.isEmpty ? null : names.join(' / ');
  }

  String? _formatCountryCodes(List<String>? codes) {
    if (codes == null || codes.isEmpty) return null;
    final names = codes
        .map((code) => _countryName(code))
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    return names.isEmpty ? null : names.join(' / ');
  }

  String _countryName(String code) {
    switch (code.trim().toUpperCase()) {
      case 'CN':
        return '中国';
      case 'HK':
        return '中国香港';
      case 'TW':
        return '中国台湾';
      case 'US':
        return '美国';
      case 'JP':
        return '日本';
      case 'KR':
        return '韩国';
      case 'GB':
        return '英国';
      case 'FR':
        return '法国';
      case 'DE':
        return '德国';
      case 'IT':
        return '意大利';
      case 'ES':
        return '西班牙';
      case 'IN':
        return '印度';
      case 'TH':
        return '泰国';
      case 'CA':
        return '加拿大';
      case 'AU':
        return '澳大利亚';
      case 'NZ':
        return '新西兰';
      case 'RU':
        return '俄罗斯';
      default:
        return code.trim();
    }
  }

  String? _formatLanguages(MediaDetail detail) {
    final spoken = detail.spoken_languages
        ?.map((language) => language.name ?? language.english_name)
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    if (spoken != null && spoken.isNotEmpty) return spoken.join(' / ');

    final codes = <String>[
      if (detail.original_language?.trim().isNotEmpty == true)
        detail.original_language!.trim(),
      ...?detail.languages,
    ];
    final names = codes
        .map(_languageName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    return names.isEmpty ? null : names.join(' / ');
  }

  String _languageName(String code) {
    switch (code.trim().toLowerCase()) {
      case 'zh':
      case 'cn':
        return '中文';
      case 'en':
        return '英语';
      case 'ja':
        return '日语';
      case 'ko':
        return '韩语';
      case 'fr':
        return '法语';
      case 'de':
        return '德语';
      case 'es':
        return '西班牙语';
      case 'it':
        return '意大利语';
      case 'ru':
        return '俄语';
      case 'th':
        return '泰语';
      case 'hi':
        return '印地语';
      default:
        return code.trim().toUpperCase();
    }
  }

  String? _formatSeasonEpisode(MediaDetail detail) {
    final seasons = detail.number_of_seasons ?? 0;
    final episodes = detail.number_of_episodes ?? 0;
    if (seasons > 0 && episodes > 0) return '$seasons 季 · $episodes 集';
    if (episodes > 0) return '$episodes 集';
    if (seasons > 0) return '$seasons 季';
    return null;
  }

  String? _formatRating(MediaDetail detail) {
    final score = detail.vote_average;
    if (score == null || score <= 0) return null;
    final count = detail.vote_count ?? 0;
    if (count <= 0) return '${score.toStringAsFixed(1)} / 10';
    return '${score.toStringAsFixed(1)} / 10 · ${_compactCount(count)} 人';
  }

  String _compactCount(int value) {
    if (value >= 10000) {
      final text = (value / 10000).toStringAsFixed(1);
      return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}万';
    }
    return value.toString();
  }

  String? _localizedStatus(String? status) {
    final raw = status?.trim();
    if (raw == null || raw.isEmpty) return null;
    const mapping = {
      'returning series': '连载中',
      'ended': '已完结',
      'released': '已上映',
      'canceled': '已取消',
      'cancelled': '已取消',
      'in production': '制作中',
      'post production': '后期制作',
      'planned': '已计划',
      'rumored': '传闻中',
      'pilot': '试播集',
    };
    return mapping[raw.toLowerCase()] ?? raw;
  }

  String? _contentRating(MediaDetail? detail) {
    final direct = detail?.content_rating?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final releaseDates = detail?.release_dates;
    if (releaseDates != null) {
      for (final item in releaseDates) {
        final certification = item.certification?.trim();
        if (certification != null &&
            certification.isNotEmpty &&
            certification.toUpperCase() != 'NR') {
          return certification;
        }
      }
    }
    return null;
  }

  List<String> _collectAliases(MediaDetail detail) {
    final primary = detail.title?.trim();
    final values = <String?>[
      detail.hk_title,
      detail.tw_title,
      detail.sg_title,
      detail.original_title,
      detail.original_name,
      detail.en_title,
      ...?detail.names,
    ];
    final aliases = values
        .map((value) => value?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty && value != primary)
        .toSet()
        .take(8)
        .toList();
    return aliases;
  }

  String? _tvdbUrl(MediaDetail detail) {
    final id = detail.tvdb_id ?? 0;
    if (id <= 0) return null;
    final slug = detail.tvdb_slug?.trim();
    if (slug != null && slug.isNotEmpty) {
      return 'https://thetvdb.com/series/$slug';
    }
    return 'https://thetvdb.com/?id=$id&tab=series';
  }

  Widget _buildSeasonList(
    BuildContext context,
    List<SeasonInfo> seasons,
    MediaDetail detail,
  ) {
    final viewportFraction = MediaQuery.of(context).size.width > 600
        ? 0.6
        : 0.92;
    final useThreePagePager = seasons.length >= 3;
    final perPage = useThreePagePager ? (seasons.length / 3).ceil() : 1;
    final compactItemHeight = 112.0;
    final dividerBlockHeight = 13.0; // 6 + 1 + 6
    final threePagerHeight =
        perPage * compactItemHeight + (perPage - 1) * dividerBlockHeight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SizedBox(
        height: useThreePagePager ? threePagerHeight : 350,
        child: useThreePagePager
            ? PageView.builder(
                padEnds: false,
                controller: PageController(viewportFraction: viewportFraction),
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * perPage;
                  final endExclusive = (start + perPage) > seasons.length
                      ? seasons.length
                      : (start + perPage);
                  final pageItems = start < seasons.length
                      ? seasons.sublist(start, endExclusive)
                      : const <SeasonInfo>[];
                  return Padding(
                    padding: EdgeInsets.only(right: pageIndex == 2 ? 0 : 12),
                    child: Column(
                      children: [
                        for (var i = 0; i < perPage; i++) ...[
                          SizedBox(
                            height: compactItemHeight,
                            child: i < pageItems.length
                                ? _buildSeasonListContent(
                                    context,
                                    pageItems[i],
                                    compact: true,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          if (i != perPage - 1) ...[
                            const SizedBox(height: 6),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.08),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ],
                    ),
                  );
                },
              )
            : PageView.builder(
                padEnds: false,
                controller: PageController(viewportFraction: viewportFraction),
                scrollDirection: Axis.horizontal,
                itemCount: seasons.length,
                itemBuilder: (context, index) {
                  final season = seasons[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == seasons.length - 1 ? 0 : 12,
                    ),
                    child: _buildSeasonListContent(context, season),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSeasonListContent(
    BuildContext context,
    SeasonInfo season, {
    bool compact = false,
  }) {
    return Obx(() {
      final posterUrl = ImageUtil.convertMediaSeasonImageUrl(
        season.poster_path ?? '',
      );
      final sn = season.season_number;
      MediaNotExists? notExists = controller.mediaNotExists.firstWhereOrNull(
        (e) => e.season == sn,
      );
      final subscribeItem = controller.seasonSubscribeMap[sn];
      final isSubscribed = sn != null && subscribeItem?.id != null;
      final isMissing =
          notExists != null &&
          ((notExists.episodes?.isNotEmpty ?? false) ||
              (notExists.total_episode ?? 0) > 0);
      return GestureDetector(
        onTap: () {
          final detail = controller.mediaDetail.value;
          if (detail == null) return;
          final reqPath = controller.seasonMediaKey(
            detail,
            season.season_number ?? 0,
          );
          showModalBottomSheet(
            isScrollControlled: true,
            useSafeArea: true,
            isDismissible: true,
            showDragHandle: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            context: context,
            builder: (context) => DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.92,
              minChildSize: 0.36,
              maxChildSize: 1,
              builder: (context, scrollController) => MediaSeasonDetailPage(
                scrollController: scrollController,
                reqPath: reqPath,
                subscribeMediaKey: controller.args.path,
                tmdbId: detail.tmdb_id?.toString() ?? '',
                seasonNumber: season.season_number ?? 0,
                title: detail.title ?? '',
                year: detail.year ?? '',
                doubanId: detail.douban_id?.toString() ?? '',
                mediaId: detail.media_id ?? '',
                subscribeItem: subscribeItem,
              ),
            ),
          );
        },
        child: MediaDetailSeasonCard(
          season: season,
          isSubscribed: isSubscribed,
          isMissing: isMissing,
          posterUrl: posterUrl,
          seasonTitle: season.name ?? '',
          seasonYear: season.air_date ?? '',
          seasonEpisodeCount: season.episode_count?.toString() ?? '',
          seasonVoteAverage: season.vote_average?.toString() ?? '',
          seasonName: _seasonTitle(season),
          compact: compact,
        ),
      );
    });
  }

  Widget _buildActorList(List<Actor> actors) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: actors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final actor = actors[index];
          final avatarUrl = _resolveAvatarUrl(actor);
          return GestureDetector(
            onTap: () {
              final source = controller.mediaDetail.value?.source;
              if (source == null) return;
              final sourceValue = MediaSourceUtil.sourceValue(source);
              Get.toNamed(
                '/person-detail',
                parameters: {'id': actor.id.toString(), 'source': sourceValue},
              );
            },
            child: SizedBox(
              width: 90,
              child: Column(
                children: [
                  if (avatarUrl != null)
                    CachedAvatar(imageUrl: avatarUrl, radius: 32)
                  else
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: CupertinoColors.systemGrey5,
                      child: Icon(
                        CupertinoIcons.person,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    actor.name ?? '未知演员',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  if (actor.character != null && actor.character!.isNotEmpty)
                    Text(
                      actor.character!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    MediaDetail? detail,
    bool isLoading,
  ) {
    if (detail == null) {
      return const SizedBox.shrink();
    }
    final isTv = _isTv(detail);
    return Obx(() {
      final appService = Get.find<AppService>();
      final canSubscribe = appService.canSubscribe;
      final canSearch = appService.canSearch;
      final movieSubscribed = controller.movieSubscribeItem.value != null;
      final isSubscribed = isTv
          ? controller.seasonSubscribeMap.isNotEmpty
          : movieSubscribed;
      if (!canSubscribe && !canSearch) {
        return const SizedBox.shrink();
      }

      return DetailPlaySection(
        detail: detail,
        isLoading: isLoading,
        mediaKey: controller.args.path,
        canSearch: canSearch,
        canSubscribe: canSubscribe,
        isSubscribed: isSubscribed,
        subscribeLoading: controller.subscribeLoadingState.value,
        onSearch: () => _openSearch(context),
        onSubscribe: () => _onSubscribePressed(context, detail, isSubscribed),
        onSubtitleSearch: () => _openSubtitleSearch(context),
      );
    });
  }

  Future<void> _onSubscribePressed(
    BuildContext context,
    MediaDetail detail,
    bool isSubscribed,
  ) async {
    // ignore: avoid_print
    print('[DetailPage] subscribe tapped');
    try {
      if (_isTv(detail)) {
        await _openTvSubscribeSheet(context, detail);
        return;
      }
      final (success, isTv, subscribeId) = await controller.handleSubscribe();
      if (!success) {
        ToastUtil.error('${isSubscribed ? '取消' : ''}订阅失败');
        return;
      }

      if (!isSubscribed && isTv && subscribeId != null) {
        ToastUtil.success(
          '${detail.title ?? ''} 订阅成功',
          title: '订阅成功',
          duration: const Duration(seconds: 3),
          mainButtonText: '编辑',
          onMainButtonPressed: () {
            Get.toNamed(
              '/subscribe-edit',
              arguments: SubscribeItem(id: subscribeId),
            );
          },
        );
        return;
      }

      if (isSubscribed) {
        ToastUtil.success('${isSubscribed ? '取消' : ''}订阅成功');
      } else {
        ToastUtil.info('${isSubscribed ? '取消' : ''}订阅成功');
      }
    } catch (e) {
      ToastUtil.error('请求失败 $e');
    }
  }

  Future<void> _openTvSubscribeSheet(
    BuildContext context,
    MediaDetail detail,
  ) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.36,
        maxChildSize: 1,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SubscribeTvSeasonSheet(
            mediaKey: controller.args.path,
            tmdbId: detail.tmdb_id?.toString(),
            title: detail.title,
            year: detail.year,
            season: detail.season?.toString(),
            itemInfo: detail.toJson(),
            scrollController: scrollController,
            subscribedItems: Map<int, SubscribeItem>.from(
              controller.seasonSubscribeMap,
            ),
          ),
        ),
      ),
    );
    await controller.fetchDetail();
  }

  List<_DetailLink> _collectInfoLinks(MediaDetail detail) {
    return <_DetailLink>[
      if (_tmdbUrl(detail) != null)
        _DetailLink(
          label: 'TMDB',
          value: detail.tmdb_id?.toString() ?? '详情页',
          iconPath: Assets.images.logos.tmdb.path,
          url: _tmdbUrl(detail),
        ),
      if (_imdbUrl(detail) != null)
        _DetailLink(
          label: 'IMDb',
          value: detail.imdb_id ?? '详情页',
          icon: CupertinoIcons.link,
          url: _imdbUrl(detail),
        ),
      if (_doubanUrl(detail) != null)
        _DetailLink(
          label: '豆瓣',
          value: detail.douban_id?.toString() ?? '详情页',
          iconPath: Assets.images.logos.douban.path,
          url: _doubanUrl(detail),
        ),
      if (_tvdbUrl(detail) != null)
        _DetailLink(
          label: 'TVDB',
          value: detail.tvdb_slug ?? detail.tvdb_id?.toString() ?? '详情页',
          iconPath: Assets.images.logos.thetvdb.path,
          url: _tvdbUrl(detail),
        ),
      if ((detail.bangumi_id ?? 0) > 0)
        _DetailLink(
          label: 'Bangumi',
          value: detail.bangumi_id!.toString(),
          icon: CupertinoIcons.link,
          url: 'https://bgm.tv/subject/${detail.bangumi_id}',
        ),
      if ((detail.anilist_id ?? 0) > 0)
        _DetailLink(
          label: 'AniList',
          value: detail.anilist_id!.toString(),
          icon: CupertinoIcons.link,
          url: 'https://anilist.co/anime/${detail.anilist_id}',
        ),
      if (detail.homepage != null && detail.homepage!.trim().isNotEmpty)
        _DetailLink(
          label: '官网',
          value: 'Official Site',
          icon: CupertinoIcons.globe,
          url: detail.homepage!.trim(),
        ),
    ];
  }

  Widget _buildExternalLinks(
    BuildContext context,
    MediaDetail detail,
    bool isLoading,
  ) {
    final links = _collectInfoLinks(detail);
    if (links.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = links.length <= 2
            ? links.length
            : (links.length == 4 ? 2 : 3);
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final link in links)
              SizedBox(
                width: width,
                child: _buildLinkTile(link, isLoading: isLoading),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLinkTile(_DetailLink link, {required bool isLoading}) {
    final url = link.url?.trim();
    final enabled = !isLoading && url != null && url.isNotEmpty;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: enabled ? () => WebUtil.open(url: url) : null,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.085),
              Colors.white.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
        ),
        child: Row(
          children: [
            _buildLinkBrand(link),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    link.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.arrow_up_right,
              size: 12,
              color: Colors.white.withValues(alpha: enabled ? 0.48 : 0.20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkBrand(_DetailLink link) {
    if (link.label == 'IMDb') {
      return Container(
        width: 34,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF5C518),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text(
          'IMDb',
          style: TextStyle(
            color: Colors.black,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      );
    }
    return Container(
      width: 30,
      height: 30,
      padding: link.iconPath != null
          ? const EdgeInsets.all(5)
          : EdgeInsets.zero,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: link.iconPath != null
          ? Image.asset(link.iconPath!, fit: BoxFit.contain)
          : Icon(
              link.icon ?? CupertinoIcons.link,
              size: 14,
              color: Colors.white.withValues(alpha: 0.78),
            ),
    );
  }

  bool _hasExternalLinks(MediaDetail detail) {
    return _tmdbUrl(detail) != null ||
        _imdbUrl(detail) != null ||
        _doubanUrl(detail) != null ||
        _tvdbUrl(detail) != null ||
        (detail.bangumi_id ?? 0) > 0 ||
        (detail.anilist_id ?? 0) > 0 ||
        (detail.homepage?.trim().isNotEmpty ?? false);
  }

  bool _shouldShowRelatedSection(
    List<RecommendApiItem> items,
    bool isLoading,
    String? errorText,
  ) {
    return items.isNotEmpty || isLoading || (errorText?.isNotEmpty ?? false);
  }

  String _relatedSectionTitle(MediaDetail detail, {required bool isSimilar}) {
    final isTv = _isTv(detail);
    if (isSimilar) {
      return isTv ? '类似剧集' : '类似影片';
    }
    return isTv ? '推荐剧集' : '推荐影片';
  }

  Widget _buildRelatedRail(
    BuildContext context, {
    required List<RecommendApiItem> items,
    required bool isLoading,
    String? errorText,
  }) {
    if (items.isEmpty) {
      if (isLoading) return _buildRelatedPlaceholder();
      if (errorText != null && errorText.isNotEmpty) {
        return _buildRelatedError(context, errorText);
      }
      return _buildRelatedEmpty(context);
    }

    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) =>
            _buildRelatedCard(context, items[index]),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildRelatedPlaceholder() {
    return SizedBox(
      height: 248,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) => _buildRelatedCardPlaceholder(),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 6,
      ),
    );
  }

  Widget _buildRelatedCard(BuildContext context, RecommendApiItem item) {
    final title = _bestTitle(item) ?? '未知标题';
    final year = _relatedYear(item);
    final backdropUrl = _resolveImageUrl(item.backdrop_path);
    final posterUrl = _resolveImageUrl(item.poster_path);
    final imageUrl = posterUrl ?? backdropUrl;
    final score = item.vote_average;

    return GestureDetector(
      onTap: () => _openRelatedDetail(item),
      child: SizedBox(
        width: 135,
        height: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                CachedImage(imageUrl: imageUrl, fit: BoxFit.cover)
              else
                _buildRelatedImageFallback(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.04),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.46, 1.0],
                  ),
                ),
              ),
              if (score != null && score > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildRelatedBadge(
                    score.toStringAsFixed(1),
                    icon: CupertinoIcons.star_fill,
                    color: const Color(0xFFFFD66B),
                  ),
                ),
              Positioned(
                left: 11,
                right: 11,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    if (year.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        year,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedCardPlaceholder() {
    return SizedBox(
      width: 135,
      height: 240,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(color: Colors.white.withValues(alpha: 0.10)),
      ),
    );
  }

  Widget _buildRelatedImageFallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF334155).withValues(alpha: 0.92),
            const Color(0xFF111827).withValues(alpha: 0.98),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedBadge(
    String text, {
    IconData? icon,
    Color color = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedError(BuildContext context, String message) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildRelatedEmpty(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          '暂无数据',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  void _openRelatedDetail(RecommendApiItem item) {
    final path = _buildMediaPath(item);
    if (path == null) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = _bestTitle(item);
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
    };
    Get.toNamed('/media-detail', parameters: params, preventDuplicates: true);
  }

  String? _bestTitle(RecommendApiItem item) {
    final title = item.title;
    if (title != null && title.trim().isNotEmpty) return title.trim();
    final enTitle = item.en_title;
    if (enTitle != null && enTitle.trim().isNotEmpty) return enTitle.trim();
    final original = item.original_title ?? item.original_name;
    if (original != null && original.trim().isNotEmpty) {
      return original.trim();
    }
    return null;
  }

  String _relatedYear(RecommendApiItem item) {
    final year = item.year?.trim() ?? '';
    if (year.isNotEmpty) return year;
    final titleYear = item.title_year?.trim() ?? '';
    if (titleYear.isNotEmpty) return titleYear;
    final release = item.release_date?.trim() ?? '';
    if (release.length >= 4) return release.substring(0, 4);
    return '';
  }

  String? _buildMediaPath(RecommendApiItem item) {
    return HttpPathBuilderUtil.buildMediaPath(item);
  }

  /// path 是否为媒体标识(tmdb:xxx 等),而非真实文件路径
  bool _isMediaIdPath(String path) {
    final t = path.trim().toLowerCase();
    return t.startsWith('tmdb:') ||
        t.startsWith('douban:') ||
        t.startsWith('bangumi:') ||
        t.startsWith('tvdb:');
  }

  void _openSearch(BuildContext context) async {
    // ignore: avoid_print
    print('[DetailPage] _openSearch tapped');

    if (!Get.find<AppService>().canSearch) {
      ToastUtil.info('当前帐号无资源搜索权限');
      return;
    }
    // path 为 tmdb:xxx 等媒体标识时,改用标题作为搜索关键字
    final searchKey = _isMediaIdPath(controller.args.path)
        ? (controller.mediaDetail.value?.title ??
              controller.mediaDetail.value?.en_title ??
              '')
        : controller.args.path;
    final detail = controller.mediaDetail.value;
    final result = await Get.bottomSheet<({String area, List<int> sites})>(
      SiteSelectSheet(
        hasSegment: true,
        seasons: detail == null ? null : _availableSeasons(detail),
        mediaSearchKey: searchKey,
      ),
      isScrollControlled: true,
    );
    if (result == null) return;
    final (area, sites) = (result.area, result.sites);
    if (sites.isEmpty) {
      ToastUtil.info('请至少选择一个站点');
      return;
    }
    final selectedSeason = await _loadLastSelectedSeason(searchKey);
    var params = <String, String>{
      'mediaSearchKey': searchKey,
      'area': area,
      'sites': sites.join(','),
      'year': detail?.year ?? '',
      'mtype': detail?.type ?? 'movie',
      'title': detail?.title ?? '',
      if ((detail?.backdrop_path ?? '').isNotEmpty)
        'backdrop': detail!.backdrop_path!,
    };
    if (detail != null && _isTv(detail) && selectedSeason > 0) {
      params['season'] = selectedSeason.toString();
    }
    Get.toNamed('/search-media-result', parameters: params);
  }

  void _openSubtitleSearch(BuildContext context) async {
    // ignore: avoid_print
    print('[DetailPage] _openSubtitleSearch tapped');

    if (!Get.find<AppService>().canSearch) {
      ToastUtil.info('当前帐号无资源搜索权限');
      return;
    }
    // path 为媒体标识时改用标题(同 _openSearch)
    final searchKey = _isMediaIdPath(controller.args.path)
        ? (controller.mediaDetail.value?.title ??
              controller.mediaDetail.value?.en_title ??
              '')
        : controller.args.path;
    final detail = controller.mediaDetail.value;
    final result = await Get.bottomSheet<({String area, List<int> sites})>(
      SiteSelectSheet(
        hasSegment: false,
        seasons: detail == null ? null : _availableSeasons(detail),
        mediaSearchKey: searchKey,
      ),
      isScrollControlled: true,
    );
    if (result == null) return;
    final sites = result.sites;
    if (sites.isEmpty) {
      ToastUtil.info('请至少选择一个站点');
      return;
    }
    final selectedSeason = await _loadLastSelectedSeason(searchKey);
    final params = <String, String>{
      'mediaSearchKey': searchKey,
      'sites': sites.join(','),
      'year': detail?.year ?? '',
      'mtype': detail?.type ?? '电影',
      'title': detail?.title ?? '',
      if ((detail?.backdrop_path ?? '').isNotEmpty)
        'backdrop': detail!.backdrop_path!,
    };
    if (detail != null && _isTv(detail) && selectedSeason > 0) {
      params['season'] = selectedSeason.toString();
    }
    Get.toNamed('/subtitle-search-result', parameters: params);
  }

  Future<int> _loadLastSelectedSeason(String mediaSearchKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = Get.find<AppService>().baseUrl ?? 'unknown';
      final userId = Get.find<AppService>().loginResponse?.userId ?? 0;
      final key = 'media_search_last_season:$baseUrl:$userId:$mediaSearchKey';
      return prefs.getInt(key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  List<int> _availableSeasons(MediaDetail detail) {
    final set = <int>{};
    final seasons = detail.season_info;
    if (seasons != null && seasons.isNotEmpty) {
      for (final s in seasons) {
        final n = s.season_number;
        if (n != null && n > 0) set.add(n);
      }
    }
    if (set.isEmpty) {
      final n = detail.number_of_seasons ?? 0;
      if (n > 0) {
        for (var i = 1; i <= n; i++) {
          set.add(i);
        }
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  String? _tmdbUrl(MediaDetail detail) {
    final link = detail.detail_link;
    if (link != null && link.trim().isNotEmpty) return link.trim();
    final tmdbId = detail.tmdb_id;
    if (tmdbId == null) return null;
    final typeSegment = _isTv(detail) ? 'tv' : 'movie';
    return 'https://www.themoviedb.org/$typeSegment/$tmdbId';
  }

  String? _imdbUrl(MediaDetail detail) {
    final imdbId = detail.imdb_id;
    if (imdbId == null || imdbId.trim().isEmpty) return null;
    return 'https://www.imdb.com/title/${imdbId.trim()}';
  }

  String? _doubanUrl(MediaDetail detail) {
    final doubanId = detail.douban_id;
    if (doubanId == null || doubanId <= 0) return null;
    return 'https://movie.douban.com/subject/$doubanId/';
  }

  bool _isTv(MediaDetail detail) {
    final type = detail.type?.toLowerCase();
    if (type != null) {
      if (type.contains('剧') ||
          type.contains('tv') ||
          type.contains('series')) {
        return true;
      }
      if (type.contains('电影') || type.contains('movie')) {
        return false;
      }
    }
    if (detail.number_of_seasons != null && detail.number_of_seasons! > 0) {
      return true;
    }
    return false;
  }

  String _displayTitle(MediaDetail? detail) {
    final title = detail?.title;
    if (title != null && title.trim().isNotEmpty) return title;
    final original = detail?.original_title ?? detail?.original_name;
    if (original != null && original.trim().isNotEmpty) return original;
    return '未知标题';
  }

  String? _subtitle(MediaDetail? detail) {
    final subtitle = detail?.en_title;
    if (subtitle != null && subtitle.trim().isNotEmpty) return subtitle;
    final origin = detail?.original_title ?? detail?.original_name;
    if (origin != null && origin.trim().isNotEmpty) {
      if (origin != detail?.title) return origin;
    }
    return null;
  }

  String? _formatRuntime(MediaDetail? detail) {
    if (detail == null) return null;
    if (detail.runtime != null && detail.runtime! > 0) {
      return '${detail.runtime} 分钟';
    }
    final runtimeList = detail.episode_run_time;
    if (runtimeList != null && runtimeList.isNotEmpty) {
      final value = runtimeList.firstWhere((item) => item > 0, orElse: () => 0);
      if (value > 0) return '$value 分钟/集';
    }
    return null;
  }

  String _seasonTitle(SeasonInfo season) {
    final name = season.name;
    if (name != null && name.trim().isNotEmpty) return name;
    if (season.season_number != null) {
      return '第 ${season.season_number} 季';
    }
    return '未知季度';
  }

  String? _resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();
    return ImageUtil.convertCacheImageUrl(trimmed);
  }

  String? _resolveAvatarUrl(Actor actor) {
    final avatar = actor.avatar;
    if (avatar != null) {
      if (avatar.large != null && avatar.large!.trim().isNotEmpty) {
        return ImageUtil.convertCacheImageUrl(avatar.large!);
      }
      if (avatar.normal != null && avatar.normal!.trim().isNotEmpty) {
        return ImageUtil.convertCacheImageUrl(avatar.normal!);
      }
    }
    final images = actor.images;
    final imageUrl = images?.large?.url ?? images?.normal?.url;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return ImageUtil.convertCacheImageUrl(imageUrl.trim());
    }
    final profile = actor.profile_path?.trim();
    if (profile == null || profile.isEmpty) return null;
    if (profile.startsWith('http://') || profile.startsWith('https://')) {
      return ImageUtil.convertCacheImageUrl(profile);
    }
    return ImageUtil.convertCacheImageUrl(
      'https://image.tmdb.org/t/p/w600_and_h900_bestv2/$profile',
    );
  }

  MediaDetail _skeletonDetail() {
    return MediaDetail(
      title: '加载中',
      en_title: 'Loading',
      year: '2024',
      type: '电视剧',
      category: '分类',
      vote_average: 8.6,
      overview: '加载中...',
      first_air_date: '2024-01-01',
      last_air_date: '2024-01-01',
      number_of_seasons: 2,
      number_of_episodes: 12,
      status: 'Returning Series',
      original_language: 'en',
      origin_country: const ['US'],
      genres: const [
        Genre(name: '剧情'),
        Genre(name: '爱情'),
      ],
      season_info: const [
        SeasonInfo(
          name: '第 1 季',
          air_date: '2024-01-01',
          episode_count: 8,
          season_number: 1,
        ),
        SeasonInfo(
          name: '第 2 季',
          air_date: '2025-01-01',
          episode_count: 8,
          season_number: 2,
        ),
      ],
      actors: const [
        Actor(name: '演员 A', character: '角色 A'),
        Actor(name: '演员 B', character: '角色 B'),
        Actor(name: '演员 C', character: '角色 C'),
      ],
      created_by: const [
        CreatedBy(name: '主创 A'),
        CreatedBy(name: '主创 B'),
      ],
      names: const ['别名 A', '别名 B'],
    );
  }
}

class _DetailFact {
  const _DetailFact({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
}

class _DetailLink {
  const _DetailLink({
    required this.label,
    required this.value,
    this.iconPath,
    this.icon,
    this.url,
  });

  final String label;
  final String value;
  final String? iconPath;
  final IconData? icon;
  final String? url;
}
