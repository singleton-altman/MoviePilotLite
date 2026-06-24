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
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_card.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/media_source_util.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

class MediaDetailPage extends GetWidget<MediaDetailController> {
  const MediaDetailPage({super.key});

  Color get _immersiveBodyColor => Color.alphaBlend(
    Theme.of(Get.context!).colorScheme.primary.withOpacity(0.4),
    AppTheme.darkBackgroundColor,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _immersiveBodyColor,
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
    final expandedHeight = isWide ? 320.0 : 440.0;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      backgroundColor: _immersiveBodyColor,
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
            if (backdropUrl != null)
              SoftEdgeBlur(
                edges: [
                  EdgeBlur(
                    type: EdgeType.bottomEdge,
                    size: 200,
                    sigma: 30,
                    controlPoints: [
                      ControlPoint(
                        position: 0.5,
                        type: ControlPointType.visible,
                      ),
                      ControlPoint(
                        position: 0.8,
                        type: ControlPointType.visible,
                      ),
                      ControlPoint(
                        position: 1,
                        type: ControlPointType.transparent,
                      ),
                    ],
                  ),
                ],
                child: CachedImage(imageUrl: backdropUrl, fit: BoxFit.cover),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D2F3A), Color(0xFF0F1115)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                    _immersiveBodyColor,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
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
                          const SizedBox(height: 12),
                          _buildHeaderInfo(context, detail),
                          const SizedBox(height: 14),
                          _buildActionButtons(context, detail, isLoading),
                        ],
                      ),
              ),
            ),
          ],
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
    return SizedBox(
      height: 200,
      width: 500,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPoster(posterUrl, width: 100, height: 100),
              SizedBox(width: 20),
              _buildHeaderInfo(context, detail, alignStart: true),
            ],
          ),
          SizedBox(height: 20),
          _buildActionButtons(context, detail, isLoading),
        ],
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
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
        const SizedBox(height: 10),
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
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
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
          color: const Color(0xFF81C784).withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
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
          color: const Color(0xFF7C4DFF).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.star_fill,
                size: 12,
                color: Colors.white,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (errorText != null && errorText.trim().isNotEmpty) ...[
          _buildSectionTitle('请求错误'),
          Section(child: _buildErrorBanner(errorText)),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _buildSectionTitle(_relatedSectionTitle(detail, isSimilar: false)),
          const SizedBox(height: 16),
          _buildRelatedRail(
            context,
            items: recommendItems,
            isLoading: recommendLoading,
            errorText: recommendError,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final detail = _skeletonDetail();
    return Skeletonizer(
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
    );
  }

  Widget _buildOverView(BuildContext context, MediaDetail detail) {
    final overview = detail.overview?.trim().isNotEmpty == true
        ? detail.overview!.trim()
        : '暂无简介';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // 稍微降低一点更高级
              borderRadius: BorderRadius.circular(25),

              // ⭐加一个轻微边框（更像 iOS）
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  overview,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Divider(color: Colors.white.withOpacity(0.1)),
                SizedBox(height: 8),
                Text(
                  '上映日期',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  detail.release_date ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
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
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: a.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: a),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: onTap != null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  decoration: onTap != null ? TextDecoration.underline : null,
                  decorationThickness: onTap != null ? 1.5 : 0,
                ),
              ),
            ),
          ),
        ],
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
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
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
        : 0.9;
    final useThreePagePager = seasons.length >= 3;
    final perPage = useThreePagePager ? (seasons.length / 3).ceil() : 1;
    final compactItemHeight = 104.0;
    final dividerBlockHeight = 13.0; // 6 + 1 + 6
    final threePagerHeight =
        perPage * compactItemHeight + (perPage - 1) * dividerBlockHeight;
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6),
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
            context: context,
            builder: (context) => MediaSeasonDetailPage(
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
        padding: EdgeInsets.symmetric(horizontal: 16),
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
      final seasons = detail.season_info;
      if (isTv && seasons?.isNotEmpty == true) {
        if (!canSearch) return const SizedBox.shrink();
        return Row(
          children: [
            Expanded(
              child: _buildPrimaryAction(
                label: '搜索资源',
                icon: CupertinoIcons.search,
                onPressed: isLoading ? null : () => _openSearch(context),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        );
      }
      final actions = <Widget>[];
      if (canSubscribe) {
        actions.add(
          Expanded(
            child: _buildSubscribeButton(
              context,
              detail,
              isLoading,
              movieSubscribed,
            ),
          ),
        );
      }
      if (canSearch) {
        if (actions.isNotEmpty) {
          actions.add(const SizedBox(width: 12));
        }
        actions.add(
          Expanded(
            child: _buildPrimaryAction(
              label: '搜索资源',
              icon: CupertinoIcons.search,
              onPressed: isLoading ? null : () => _openSearch(context),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
        );
      }
      if (actions.isEmpty) {
        return const SizedBox.shrink();
      }
      return Row(children: actions);
    });
  }

  Widget _buildSubscribeButton(
    BuildContext context,
    MediaDetail detail,
    bool isLoading,
    bool isSubscribed,
  ) {
    return Obx(() {
      if (controller.subscribeLoadingState.value) {
        return _buildPrimaryAction(
          label: 'loading...',
          icon: Icons.local_dining_outlined,
          onPressed: null,
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
        );
      }
      return _buildPrimaryAction(
        label: isSubscribed ? '已订阅' : '订阅',
        icon: isSubscribed
            ? CupertinoIcons.heart_slash_fill
            : CupertinoIcons.heart_fill,
        onPressed: () async {
          try {
            final (success, isTv, subscribeId) = await controller
                .handleSubscribe();
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
        },
        backgroundColor: isLoading
            ? Colors.grey
            : isSubscribed
            ? Colors.red
            : Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      );
    });
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: actions
            .map(
              (el) => Expanded(
                child: Padding(padding: const EdgeInsets.all(8.0), child: el),
              ),
            )
            .toList(),
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
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return RecommendItemCard(
            item: item,
            onTap: () => _openRelatedDetail(item),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildRelatedPlaceholder() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 8),
        itemBuilder: (context, index) => const RecommendItemCard(item: null),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: 6,
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

  String? _buildMediaPath(RecommendApiItem item) {
    return HttpPathBuilderUtil.buildMediaPath(item);
  }

  Widget _buildPrimaryAction({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return CupertinoButton.filled(
      color: backgroundColor,
      foregroundColor: foregroundColor,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(25),
      sizeStyle: CupertinoButtonSize.medium,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkAction({
    required String label,
    String? iconPath,
    required BuildContext context,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconPath != null) Image.asset(iconPath, width: 18, height: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
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
    if (actor.avatar == null) {
      return "https://image.tmdb.org/t/p/w600_and_h900_bestv2/${actor.profile_path}";
    }
    final avatar = actor.avatar!;
    if (avatar.large != null && avatar.large!.trim().isNotEmpty) {
      return ImageUtil.convertCacheImageUrl(avatar.large!);
    }
    if (avatar.normal != null && avatar.normal!.trim().isNotEmpty) {
      return ImageUtil.convertCacheImageUrl(avatar.normal!);
    }
    return null;
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
