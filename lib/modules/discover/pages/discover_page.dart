import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/discover/widgets/discover_filter_sheet.dart';
import 'package:moviepilot_mobile/modules/discover/widgets/discover_source_chip.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class DiscoverPage extends GetView<DiscoverController> {
  const DiscoverPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const double _gridHPadding = 16;
  static const double _gridCrossSpacing = 12;
  static const double _gridMainSpacing = 18;
  static const double _posterTextBlockHeight = 63;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureUserCookieRefreshed();
    });
    final appService = Get.find<AppService>();
    final palette = DashboardPalette.of(context);

    return Obx(() {
      final hasPageBackground =
          appService.backgroundImageEnabled.value &&
          appService.backgroundImageBytes.value != null;
      return Scaffold(
        backgroundColor: hasPageBackground
            ? Colors.transparent
            : palette.pageBackground,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context, palette),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPageBackground)
              Positioned.fill(child: _buildBackgroundImage(context, appService))
            else
              ColoredBox(color: palette.pageBackground),
            CustomScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async =>
                      controller.loadCurrent(forceRefresh: true),
                ),
                Obx(() {
                  final top = MediaQuery.paddingOf(context).top;
                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      _gridHPadding,
                      top + 56,
                      _gridHPadding,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildSourceBar(context, palette),
                    ),
                  );
                }),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                _buildContentSliver(context, palette),
              ],
            ),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    DashboardPaletteData palette,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      forceMaterialTransparency: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: palette.isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: palette.isDark
            ? Brightness.dark
            : Brightness.light,
      ),
      titleSpacing: 16,
      title: Text(
        '探索',
        style: TextStyle(
          color: palette.titleText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          tooltip: '筛选',
          onPressed: () => _openFilterSheet(context),
          icon: Icon(Icons.tune_rounded, color: palette.titleText),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBackgroundImage(BuildContext context, AppService appService) {
    final palette = DashboardPalette.of(context);
    final bytes = appService.backgroundImageBytes.value;
    if (bytes == null) return ColoredBox(color: palette.pageBackground);
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: appService.backgroundImageOpacity.value,
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
          ColoredBox(
            color: palette.pageBackground.withValues(
              alpha: palette.isDark ? 0.72 : 0.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBar(
    BuildContext context,
    DashboardPaletteData palette,
  ) {
    final sources = controller.sourceEntries.toList();
    if (sources.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < sources.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            DiscoverSourceChip(
              source: sources[i],
              selected: controller.selectedSource.value == sources[i],
              onTap: () => controller.selectSource(sources[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSliver(
    BuildContext context,
    DashboardPaletteData palette,
  ) {
    final items = controller.currentItems();
    final isLoading = controller.isLoading();
    final errorText = controller.errorText();
    final metrics = _gridMetrics(context);

    if (items.isEmpty && isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _gridHPadding,
          0,
          _gridHPadding,
          110,
        ),
        sliver: SliverGrid(
          gridDelegate: metrics.delegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) => const _PosterGridSkeletonCell(),
            childCount: metrics.columns * 4,
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _gridHPadding,
            8,
            _gridHPadding,
            110,
          ),
          child: _EmptyState(
            message: errorText ?? '当前条件没有匹配作品',
            onFilter: () => _openFilterSheet(context),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(_gridHPadding, 0, _gridHPadding, 110),
      sliver: SliverGrid(
        gridDelegate: metrics.delegate,
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return _PosterCard(
              key: ValueKey(
                '${item.media_id ?? item.tmdb_id ?? item.title}_$index',
              ),
              item: item,
              onTap: () => _openDetail(item),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  _GridMetrics _gridMetrics(BuildContext context) {
    final usableWidth =
        MediaQuery.sizeOf(context).width - _gridHPadding * 2;
    final columns = (usableWidth / 172).floor().clamp(2, 5);
    final cardWidth =
        (usableWidth - _gridCrossSpacing * (columns - 1)) / columns;
    final cardHeight =
        cardWidth * 1.5 + _posterTextBlockHeight;
    return _GridMetrics(
      columns: columns,
      delegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: _gridCrossSpacing,
        mainAxisSpacing: _gridMainSpacing,
        childAspectRatio: cardWidth / cardHeight,
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final palette = DashboardPalette.of(context);
    final appService = Get.find<AppService>();
    appService.hideBottomNavBar.value = true;
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) {
      appService.hideBottomNavBar.value = false;
      return;
    }
    try {
      final result = await showModalBottomSheet<DiscoverFilterSelection>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: palette.pageBackground,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => DiscoverFilterSheet(
          initialSource: controller.selectedSource.value,
          sources: controller.sourceEntries.toList(),
          filtersBySource: controller.snapshotFiltersBySource(),
          dynamicFiltersBySource: controller.snapshotDynamicFiltersBySource(),
        ),
      );
      if (result == null) return;
      controller.applySelection(
        result.selectedSource,
        result.filtersBySource,
        result.dynamicFiltersBySource,
      );
    } finally {
      appService.hideBottomNavBar.value = false;
    }
  }

  void _openDetail(RecommendApiItem item) {
    final path = HttpPathBuilderUtil.buildMediaPath(item);
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = _bestTitle(item);
    Get.toNamed(
      '/media-detail',
      parameters: {
        'path': path,
        if (title != null && title.isNotEmpty) 'title': title,
        if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
        if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
        if (item.poster_path != null && item.poster_path!.isNotEmpty)
          'poster_path': item.poster_path!,
        if (item.backdrop_path != null && item.backdrop_path!.isNotEmpty)
          'backdrop_path': item.backdrop_path!,
        if (item.vote_average != null && item.vote_average! > 0)
          'vote_average': item.vote_average!.toStringAsFixed(1),
      },
    );
  }
}

class _GridMetrics {
  const _GridMetrics({required this.columns, required this.delegate});

  final int columns;
  final SliverGridDelegate delegate;
}

class _PosterCard extends StatefulWidget {
  const _PosterCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final RecommendApiItem item;
  final VoidCallback onTap;

  @override
  State<_PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<_PosterCard> {
  static const Color _ratingGoldDark = Color(0xFFFFAC2D);
  static const Color _ratingGoldLight = Color(0xFFD97706);

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final title = _bestTitle(widget.item) ?? 'Untitled';
    final posterUrl = _posterUrl(widget.item);
    final vote = widget.item.vote_average;
    final hasVote = vote != null && vote > 0;
    final year = widget.item.year?.trim() ?? widget.item.title_year?.trim() ?? '';
    final ratingColor = palette.isDark ? _ratingGoldDark : _ratingGoldLight;

    return Semantics(
      button: true,
      label: '打开 $title',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (_pressed) return;
          setState(() => _pressed = true);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.965 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: palette.tileBorder.withValues(alpha: 0.55),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: ColoredBox(
                      color: palette.surfaceAlt,
                      child: posterUrl.isEmpty
                          ? const _SoftPlaceholder()
                          : CachedImage(
                              imageUrl: posterUrl,
                              fit: BoxFit.cover,
                              placeholder: const _SoftPlaceholder(),
                              errorWidget: const _SoftPlaceholder(),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                width: double.infinity,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.titleText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 16,
                child: Row(
                  children: [
                    if (hasVote) ...[
                      Icon(Icons.star_rounded, size: 14, color: ratingColor),
                      const SizedBox(width: 2),
                      Text(
                        vote.toStringAsFixed(1),
                        style: TextStyle(
                          color: ratingColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else
                      Text(
                        '暂无评分',
                        style: TextStyle(
                          color: palette.faintText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const Spacer(),
                    if (year.isNotEmpty)
                      Flexible(
                        child: Text(
                          year,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _posterUrl(RecommendApiItem item) {
    final raw = item.poster_path ?? item.backdrop_path ?? '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return ImageUtil.convertCacheImageUrl(trimmed);
  }
}

class _PosterGridSkeletonCell extends StatelessWidget {
  const _PosterGridSkeletonCell();

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 10,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onFilter});

  final String message;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: palette.pageBackgroundAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.explore_outlined, size: 34, color: palette.faintText),
          const SizedBox(height: 14),
          Text(
            '暂无内容',
            style: TextStyle(
              color: palette.titleText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.mutedText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: onFilter,
            child: const Text('调整筛选'),
          ),
        ],
      ),
    );
  }
}

class _SoftPlaceholder extends StatelessWidget {
  const _SoftPlaceholder();

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Center(
      child: Icon(
        Icons.movie_outlined,
        size: 30,
        color: palette.faintText.withValues(alpha: 0.7),
      ),
    );
  }
}

String? _bestTitle(RecommendApiItem item) {
  final title = item.title;
  if (title != null && title.trim().isNotEmpty) return title.trim();
  final enTitle = item.en_title;
  if (enTitle != null && enTitle.trim().isNotEmpty) return enTitle.trim();
  final original = item.original_title ?? item.original_name;
  if (original != null && original.trim().isNotEmpty) return original.trim();
  return null;
}
