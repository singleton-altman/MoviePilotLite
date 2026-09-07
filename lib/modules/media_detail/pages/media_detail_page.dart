import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_controller.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_notexists.dart';
import 'package:moviepilot_mobile/modules/media_detail/pages/media_season_detail_page.dart';
import 'package:moviepilot_mobile/modules/media_detail/widgets/media_detail_season_card.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (detail?.year != null && detail?.year!.isNotEmpty == true)
              _buildMetaChip(detail?.year),
            if (detail?.category != null &&
                detail?.category!.isNotEmpty == true)
              _buildMetaChip(detail?.category),
            if (detail?.vote_average != null && detail!.vote_average! > 0)
              _buildScoreChip(detail.vote_average!),
            Obx(() {
              final app = Get.find<AppService>();
              if (!app.enableFetchMediaserverLibraryStatus.value) {
                return const SizedBox.shrink();
              }
              if (!controller.mediaserverInLibrary.value) {
                return const SizedBox.shrink();
              }
              return _buildInLibraryChip();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaChip(String? text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            text ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInLibraryChip() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF81C784).withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF81C784).withValues(alpha: 0.32),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Color(0xFF81C784),
              ),
              SizedBox(width: 4),
              Text(
                '已入库',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChip(double? score) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF5C518).withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFF5C518).withValues(alpha: 0.28),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.star_fill,
                size: 12,
                color: Color(0xFFFFD66B),
              ),
              const SizedBox(width: 4),
              Text(
                score?.toStringAsFixed(1) ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
          if (detail.season_info != null && detail.season_info!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('季度信息'),
            _buildSeasonList(context, detail.season_info!, detail),
          ],
          if (_hasExternalLinks(detail)) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('相关链接'),
            _buildExternalLinks(context, detail, isLoading),
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
        ],
      ),
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

    Widget row({
      required IconData icon,
      required String label,
      required String value,
      Color? accent,
      VoidCallback? onTap,
    }) {
      final a = accent ?? const Color(0xFF7C4DFF);
      return GestureDetector(
        behavior: onTap == null
            ? HitTestBehavior.deferToChild
            : HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 42),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: a.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: a),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onTap != null
                        ? const Color(0xFF93C5FD)
                        : Colors.white.withValues(alpha: 0.74),
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: Colors.white54,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final firstAir = detail.first_air_date ?? detail.release_date;
    final runtime = _formatRuntime(detail);
    final country =
        (detail.origin_country != null && detail.origin_country!.isNotEmpty)
        ? detail.origin_country!.join(' / ')
        : null;
    final networks = (detail.networks != null && detail.networks!.isNotEmpty)
        ? detail.networks!.map((e) => e.name).whereType<String>().join(' / ')
        : null;

    final rows = <Widget>[];
    void addRow(Widget w) {
      if (rows.isNotEmpty) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        );
      }
      rows.add(w);
    }

    if (firstAir != null && firstAir.isNotEmpty) {
      addRow(
        row(
          icon: CupertinoIcons.calendar,
          label: '首播',
          value: firstAir,
          accent: const Color(0xFF60A5FA),
        ),
      );
    }
    if (detail.last_air_date != null && detail.last_air_date!.isNotEmpty) {
      addRow(
        row(
          icon: CupertinoIcons.clock,
          label: '最后播出',
          value: detail.last_air_date!,
          accent: const Color(0xFF34D399),
        ),
      );
    }
    if (detail.number_of_seasons != null && detail.number_of_seasons! > 0) {
      addRow(
        row(
          icon: CupertinoIcons.square_stack_3d_up,
          label: '季数',
          value: detail.number_of_seasons!.toString(),
        ),
      );
    }
    if (detail.number_of_episodes != null && detail.number_of_episodes! > 0) {
      addRow(
        row(
          icon: CupertinoIcons.film,
          label: '集数',
          value: detail.number_of_episodes!.toString(),
        ),
      );
    }
    if (runtime != null && runtime.isNotEmpty) {
      addRow(
        row(
          icon: CupertinoIcons.timer,
          label: '时长',
          value: runtime,
          accent: const Color(0xFFF97316),
        ),
      );
    }
    if (detail.status != null && detail.status!.isNotEmpty) {
      addRow(
        row(
          icon: CupertinoIcons.bolt_circle,
          label: '状态',
          value: detail.status!,
          accent: const Color(0xFFF5C518),
        ),
      );
    }
    if (detail.original_language != null &&
        detail.original_language!.isNotEmpty) {
      addRow(
        row(
          icon: CupertinoIcons.globe,
          label: '语言',
          value: detail.original_language!,
        ),
      );
    }
    if (country != null && country.isNotEmpty) {
      addRow(row(icon: CupertinoIcons.map, label: '地区', value: country));
    }
    if (networks != null && networks.isNotEmpty) {
      addRow(row(icon: CupertinoIcons.tv, label: '播出平台', value: networks));
    }
    if (detail.homepage != null && detail.homepage!.isNotEmpty) {
      addRow(
        row(
          icon: CupertinoIcons.link,
          label: '官网',
          value: detail.homepage!,
          accent: const Color(0xFF60A5FA),
          onTap: () => WebUtil.open(url: detail.homepage!),
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildGlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
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

      return Row(
        children: [
          if (canSearch)
            Expanded(
              child: _buildSearchPillButton(
                context,
                enabled: !isLoading,
                onPressed: () => _openSearch(context),
              ),
            )
          else
            const Spacer(),
          if (canSubscribe) ...[
            if (canSearch) const SizedBox(width: 10),
            _buildCircleActionButton(
              context,
              icon: controller.subscribeLoadingState.value
                  ? CupertinoIcons.arrow_2_circlepath
                  : (isSubscribed
                        ? CupertinoIcons.bell_fill
                        : CupertinoIcons.bell),
              accentColor: isSubscribed
                  ? const Color(0xFFFF6B6B)
                  : Colors.white,
              onPressed: isLoading || controller.subscribeLoadingState.value
                  ? null
                  : () => _onSubscribePressed(context, detail, isSubscribed),
            ),
          ],
          if (canSearch) ...[
            const SizedBox(width: 8),
            _buildCircleActionButton(
              context,
              icon: CupertinoIcons.text_bubble,
              onPressed: isLoading ? null : () => _openSubtitleSearch(context),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSearchPillButton(
    BuildContext context, {
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: Material(
        color: accent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(999),
          child: const SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.search, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '搜索资源',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleActionButton(
    BuildContext context, {
    required IconData icon,
    Color accentColor = Colors.white,
    VoidCallback? onPressed,
  }) {
    return Opacity(
      opacity: onPressed == null ? 0.52 : 1,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 20, color: accentColor),
          ),
        ),
      ),
    );
  }

  Future<void> _onSubscribePressed(
    BuildContext context,
    MediaDetail detail,
    bool isSubscribed,
  ) async {
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

  Widget _buildExternalLinks(
    BuildContext context,
    MediaDetail detail,
    bool isLoading,
  ) {
    final actions = <Widget>[];
    final tmdbUrl = _tmdbUrl(detail);
    if (tmdbUrl != null) {
      actions.add(
        _buildLinkAction(
          iconPath: Assets.images.logos.thetvdb.path,
          label: 'TMDB',
          onPressed: isLoading ? null : () => WebUtil.open(url: tmdbUrl),
          context: context,
        ),
      );
    }
    final imdbUrl = _imdbUrl(detail);
    if (imdbUrl != null) {
      actions.add(
        _buildLinkAction(
          label: 'IMDB',
          onPressed: isLoading ? null : () => WebUtil.open(url: imdbUrl),
          context: context,
        ),
      );
    }
    final doubanUrl = _doubanUrl(detail);
    if (doubanUrl != null) {
      actions.add(
        _buildLinkAction(
          iconPath: Assets.images.logos.douban.path,
          label: '豆瓣',
          onPressed: isLoading ? null : () => WebUtil.open(url: doubanUrl),
          context: context,
        ),
      );
    }
    return _buildGlassPanel(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Container(
                width: 0.5,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: Colors.white.withValues(alpha: 0.16),
              ),
            Expanded(child: actions[i]),
          ],
        ],
      ),
    );
  }

  bool _hasExternalLinks(MediaDetail detail) {
    return _tmdbUrl(detail) != null ||
        _imdbUrl(detail) != null ||
        _doubanUrl(detail) != null;
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

  Widget _buildLinkAction({
    required String label,
    String? iconPath,
    required BuildContext context,
    VoidCallback? onPressed,
  }) {
    return CupertinoButton(
      onPressed: onPressed,
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null) Image.asset(iconPath, width: 18, height: 18),
            if (iconPath != null) const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) async {
    if (!Get.find<AppService>().canSearch) {
      ToastUtil.info('当前帐号无资源搜索权限');
      return;
    }
    final searchKey = controller.args.path;
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
    if (!Get.find<AppService>().canSearch) {
      ToastUtil.info('当前帐号无资源搜索权限');
      return;
    }
    final searchKey = controller.args.path;
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
