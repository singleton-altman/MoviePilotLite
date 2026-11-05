import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_category_list_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_base_card.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/utils/grid_layout.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/app_glass_card.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class RecommendCategoryListPage
    extends GetView<RecommendCategoryListController> {
  const RecommendCategoryListPage({super.key});

  static const double _gridSpacing = 10;
  static const double _gridPadding = 16;
  static const double _cardAspectRatio = 1 / 1.3;
  static const double _listPosterWidth = 84;
  static const double _listPosterHeight = 122;
  static const double _narrowScreenBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final themeColor = controller.appBarThemeColor;
    if (themeColor == null) {
      return Obx(
        () => Scaffold(
          appBar: _buildPlainAppBar(context),
          body: _buildBody(context, immersive: false),
        ),
      );
    }

    final bodyColor = _pageSurface(context);
    return Scaffold(
      backgroundColor: bodyColor,
      body: _buildBody(context, immersive: true, bodyColor: bodyColor),
    );
  }

  AppBar _buildPlainAppBar(BuildContext context) {
    final isNarrowScreen =
        MediaQuery.sizeOf(context).width < _narrowScreenBreakpoint;
    controller.preferredViewMode.value;
    final viewMode = controller.resolvedViewMode(
      isNarrowScreen: isNarrowScreen,
    );
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: Get.back,
      ),
      title: Text(controller.categoryTitle),
      centerTitle: false,
      actions: [
        IconButton(
          tooltip: viewMode == SearchResultViewMode.list ? '切换为网格' : '切换为列表',
          onPressed: () =>
              controller.toggleViewMode(isNarrowScreen: isNarrowScreen),
          icon: Icon(
            viewMode == SearchResultViewMode.list
                ? CupertinoIcons.square_grid_2x2
                : CupertinoIcons.list_bullet,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool immersive,
    Color? bodyColor,
  }) {
    return Obx(() {
      final items = controller.items.toList();
      final isInitialLoading = items.isEmpty && controller.isLoading.value;
      final error = controller.error.value;
      final isNarrowScreen =
          MediaQuery.sizeOf(context).width < _narrowScreenBreakpoint;
      controller.preferredViewMode.value;
      final viewMode = controller.resolvedViewMode(
        isNarrowScreen: isNarrowScreen,
      );
      final layout = gridLayout(
        context,
        gridSpacing: _gridSpacing,
        gridPadding: _gridPadding,
      );

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: CustomScrollView(
          cacheExtent: 160,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (immersive)
              _buildImmersiveHeader(
                context,
                items,
                bodyColor: bodyColor,
                viewMode: viewMode,
                isNarrowScreen: isNarrowScreen,
              )
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                _gridPadding,
                immersive ? 14 : 12,
                _gridPadding,
                12,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildCategoryControlPanel(
                  context,
                  items: items,
                  viewMode: viewMode,
                  isNarrowScreen: isNarrowScreen,
                  immersive: immersive,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                _gridPadding,
                0,
                _gridPadding,
                _gridPadding,
              ),
              sliver: isInitialLoading
                  ? SliverToBoxAdapter(child: _buildInitialLoading(context))
                  : items.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(context, error: error),
                    )
                  : viewMode == SearchResultViewMode.list
                  ? _buildListSliver(context, items)
                  : _buildGridSliver(items, layout.crossAxisCount),
            ),
            SliverToBoxAdapter(child: _buildBottomStatusHost(context)),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      );
    });
  }

  Widget _buildGridSliver(List<RecommendApiItem> items, int crossAxisCount) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return _buildGridItem(context, item);
        },
        childCount: items.length,
        addAutomaticKeepAlives: false,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: _gridSpacing,
        crossAxisSpacing: _gridSpacing,
        childAspectRatio: _cardAspectRatio,
      ),
    );
  }

  Widget _buildListSliver(BuildContext context, List<RecommendApiItem> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildListItem(context, item),
          );
        },
        childCount: items.length,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  Widget _buildInitialLoading(BuildContext context) {
    final theme = Theme.of(context);
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      borderRadius: 20,
      surfaceAlpha: theme.brightness == Brightness.dark ? 0.38 : 0.90,
      borderAlpha: theme.brightness == Brightness.dark ? 0.14 : 0.42,
      shadowAlpha: theme.brightness == Brightness.dark ? 0.18 : 0.08,
      accentColor: _pageAccent(context),
      child: AppLoading(
        message: '正在整理推荐内容…',
        messageStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? error}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasError = error != null && error.trim().isNotEmpty;
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      borderRadius: 20,
      surfaceAlpha: theme.brightness == Brightness.dark ? 0.38 : 0.92,
      borderAlpha: theme.brightness == Brightness.dark ? 0.14 : 0.42,
      shadowAlpha: theme.brightness == Brightness.dark ? 0.18 : 0.08,
      accentColor: _pageAccent(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.72,
              ),
            ),
            child: Icon(
              hasError
                  ? CupertinoIcons.exclamationmark_triangle
                  : CupertinoIcons.film,
              color: hasError ? colorScheme.error : colorScheme.primary,
              size: 23,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasError ? error.trim() : '暂无推荐内容',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasError ? '可以稍后重试，或返回上一页切换其他分类。' : '换个分类看看，也许会遇到更合眼缘的片单。',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.refreshData,
            icon: const Icon(CupertinoIcons.refresh, size: 17),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, RecommendApiItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _bestTitle(item) ?? '';
    final year = _displayYear(item);
    final overview = item.overview?.trim();
    final type = item.type?.trim();
    final vote = item.vote_average;
    final accent = _accentForItem(context, item);
    final artworkSize = _listArtworkSize(item);
    final metaChips = <Widget>[
      if (type != null && type.isNotEmpty)
        _buildMetaPill(context, type, accent: accent),
      if (year.isNotEmpty)
        _buildMetaPill(
          context,
          year,
          accent: colorScheme.secondary,
          quiet: true,
        ),
      if (vote != null && vote > 0)
        _buildMetaPill(
          context,
          vote.toStringAsFixed(1),
          accent: const Color(0xFFFFC857),
        ),
    ];

    return RecommendItemBaseCard(
      item: item,
      child: AppGlassCard(
        onTap: () => _openDetail(item),
        padding: EdgeInsets.zero,
        borderRadius: 20,
        blurSigma: 14,
        surfaceAlpha: isDark ? 0.42 : 0.92,
        borderAlpha: isDark ? 0.18 : 0.48,
        shadowAlpha: isDark ? 0.22 : 0.10,
        accentColor: colorScheme.onSurfaceVariant,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.34 : 0.14,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _buildPosterFrame(
                        context,
                        item,
                        width: artworkSize.width,
                        height: artworkSize.height,
                        radius: 15,
                        showScore: false,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.16,
                              ),
                            ),
                            if (metaChips.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 7,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: metaChips,
                              ),
                            ],
                            if (overview != null && overview.isNotEmpty) ...[
                              const SizedBox(height: 9),
                              Text(
                                overview,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: isDark ? 0.78 : 0.86),
                                  fontSize: 12.5,
                                  height: 1.42,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            _buildListItemFooter(context, item, accent),
                          ],
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

  Widget _buildGridItem(BuildContext context, RecommendApiItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final title = _bestTitle(item) ?? '';
    final year = _displayYear(item);
    final type = item.type?.trim();
    final vote = item.vote_average;

    return RecommendItemBaseCard(
      item: item,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 160.0;
          final height = width / _cardAspectRatio;
          return SizedBox(
            width: width,
            height: height,
            child: AppGlassCard(
              onTap: () => _openDetail(item),
              padding: EdgeInsets.zero,
              borderRadius: 20,
              blurSigma: 14,
              surfaceAlpha: isDark ? 0.24 : 0.68,
              borderAlpha: isDark ? 0.16 : 0.48,
              shadowAlpha: isDark ? 0.24 : 0.12,
              accentColor: colorScheme.onSurfaceVariant,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPosterImage(
                      context,
                      item,
                      fit: BoxFit.cover,
                      memCacheWidth: _scaledCacheExtent(context, width),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.black.withValues(alpha: 0.18),
                            Colors.black.withValues(alpha: 0.86),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      top: 10,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (type != null && type.isNotEmpty)
                            Flexible(
                              child: _buildOverlayPill(
                                type,
                                background: Colors.black.withValues(
                                  alpha: 0.36,
                                ),
                              ),
                            ),
                          const Spacer(),
                          if (vote != null && vote > 0)
                            _buildOverlayPill(
                              vote.toStringAsFixed(1),
                              background: const Color(
                                0xFFFFC857,
                              ).withValues(alpha: 0.92),
                              foreground: Colors.black87,
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 13,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (year.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                year,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: isDark ? 0.12 : 0.22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItemFooter(
    BuildContext context,
    RecommendApiItem item,
    Color accent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final source = item.source?.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.sparkles,
            size: 14,
            color: accent.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              source != null && source.isNotEmpty ? source : '推荐内容',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.56),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterFrame(
    BuildContext context,
    RecommendApiItem item, {
    required double width,
    required double height,
    required double radius,
    bool showScore = true,
  }) {
    final vote = item.vote_average;
    final borderRadius = BorderRadius.circular(radius);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPosterImage(
              context,
              item,
              fit: BoxFit.cover,
              memCacheWidth: _scaledCacheExtent(context, width),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
            if (showScore && vote != null && vote > 0)
              Positioned(
                left: 7,
                bottom: 7,
                child: _buildOverlayPill(
                  vote.toStringAsFixed(1),
                  background: Colors.black.withValues(alpha: 0.48),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterImage(
    BuildContext context,
    RecommendApiItem item, {
    required BoxFit fit,
    int? memCacheWidth,
  }) {
    final raw = _bestArtworkPath(item);
    if (raw != null && raw.isNotEmpty) {
      return CachedImage(
        imageUrl: ImageUtil.convertCacheImageUrl(raw),
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        memCacheWidth: memCacheWidth,
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.primaryContainer.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.54),
          size: 30,
        ),
      ),
    );
  }

  Size _listArtworkSize(RecommendApiItem item) {
    final hasPoster = (item.poster_path?.trim().isNotEmpty ?? false);
    if (hasPoster) {
      return const Size(_listPosterWidth, _listPosterHeight);
    }
    final hasBackdrop = (item.backdrop_path?.trim().isNotEmpty ?? false);
    if (hasBackdrop) {
      return const Size(116, 74);
    }
    return const Size(_listPosterWidth, _listPosterHeight);
  }

  String? _bestArtworkPath(RecommendApiItem item) {
    final poster = item.poster_path?.trim();
    if (poster != null && poster.isNotEmpty) return poster;
    final backdrop = item.backdrop_path?.trim();
    if (backdrop != null && backdrop.isNotEmpty) return backdrop;
    return null;
  }

  int _scaledCacheExtent(BuildContext context, double logicalExtent) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final value = (logicalExtent * devicePixelRatio * 1.25).ceil();
    return value.clamp(96, 900);
  }

  Widget _buildMetaPill(
    BuildContext context,
    String text, {
    required Color accent,
    bool quiet = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: quiet
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.62)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: quiet
              ? colorScheme.outlineVariant.withValues(alpha: 0.28)
              : accent.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: quiet ? colorScheme.onSurfaceVariant : accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOverlayPill(
    String text, {
    required Color background,
    Color foreground = Colors.white,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _accentForItem(BuildContext context, RecommendApiItem item) {
    final source = (item.source ?? item.type ?? item.category ?? '')
        .toLowerCase()
        .trim();
    if (source.contains('douban')) return const Color(0xFF42A75C);
    if (source.contains('imdb')) return const Color(0xFFF5C518);
    if (source.contains('bangumi')) return const Color(0xFFF09199);
    if (source.contains('tmdb') || source.contains('themoviedb')) {
      return const Color(0xFF01B4E4);
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color _pageAccent(BuildContext context) {
    return controller.appBarThemeColor ?? Theme.of(context).colorScheme.primary;
  }

  Color _pageSecondaryAccent(BuildContext context) {
    return controller.appBarSecondaryThemeColor ?? _pageAccent(context);
  }

  Color _pageSurface(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Color.alphaBlend(
      _pageAccent(context).withValues(alpha: isDark ? 0.14 : 0.08),
      colorScheme.surface,
    );
  }

  String _displayYear(RecommendApiItem item) {
    final year = item.year?.trim() ?? '';
    if (year.isNotEmpty) return year;
    return item.title_year?.trim() ?? '';
  }

  SliverAppBar _buildImmersiveHeader(
    BuildContext context,
    List<RecommendApiItem> items, {
    Color? bodyColor,
    required SearchResultViewMode viewMode,
    required bool isNarrowScreen,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _pageAccent(context);
    final secondaryAccent = _pageSecondaryAccent(context);
    final surface = bodyColor ?? colorScheme.surface;
    final headerTop = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.82 : 0.56),
      isDark ? const Color(0xFF070811) : colorScheme.surfaceContainerHighest,
    );
    final headerMid = Color.alphaBlend(
      secondaryAccent.withValues(alpha: isDark ? 0.56 : 0.34),
      surface,
    );
    final headerForeground = _readableOnColor(headerTop);
    final topItems = items.take(3).toList();
    final loadedCount = items.length;
    final totalCount = controller.totalItems.value;
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 312,
      backgroundColor: headerTop,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: headerForeground),
        onPressed: Get.back,
      ),
      actions: [
        IconButton(
          tooltip: viewMode == SearchResultViewMode.list ? '切换为网格' : '切换为列表',
          onPressed: () =>
              controller.toggleViewMode(isNarrowScreen: isNarrowScreen),
          icon: Icon(
            viewMode == SearchResultViewMode.list
                ? CupertinoIcons.square_grid_2x2
                : CupertinoIcons.list_bullet,
            color: headerForeground,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    headerTop,
                    Color.alphaBlend(
                      secondaryAccent.withValues(alpha: isDark ? 0.42 : 0.22),
                      headerMid,
                    ),
                    surface,
                  ],
                  stops: const [0.0, 0.54, 1.0],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _RecommendCategoryHeaderPainter(
                  accent: accent,
                  secondaryAccent: secondaryAccent,
                  isDark: isDark,
                ),
              ),
            ),
            Positioned(
              top: 74,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 182,
                child: _buildPosterRow(context, topItems),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: isDark ? 0.06 : 0.00),
                      surface.withValues(alpha: isDark ? 0.92 : 0.88),
                    ],
                    stops: const [0.32, 0.74, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 22,
              child: _buildHeaderTitleBlock(
                context,
                foreground: colorScheme.onSurface,
                loadedCount: loadedCount,
                totalCount: totalCount,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitleBlock(
    BuildContext context, {
    required Color foreground,
    required int loadedCount,
    required int? totalCount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalLabel = totalCount != null && totalCount > 0
        ? '$loadedCount / $totalCount'
        : '$loadedCount';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          controller.categoryTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 30,
            height: 1.04,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildHeaderChip(
              context,
              icon: CupertinoIcons.play_rectangle,
              text: '媒体推荐',
            ),
            _buildHeaderChip(
              context,
              icon: CupertinoIcons.square_stack_3d_up,
              text: '已加载 $totalLabel',
            ),
            if (controller.hasMore.value)
              _buildHeaderChip(
                context,
                icon: CupertinoIcons.arrow_down_circle,
                text: '可继续加载',
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '按来源与热度整理的精选片单，长按卡片可快速订阅或搜索资源。',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderChip(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: isDark ? 0.28 : 0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.20 : 0.42,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryControlPanel(
    BuildContext context, {
    required List<RecommendApiItem> items,
    required SearchResultViewMode viewMode,
    required bool isNarrowScreen,
    required bool immersive,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _pageAccent(context);
    final total = controller.totalItems.value;
    final countLabel = total != null && total > 0
        ? '${items.length}/$total'
        : '${items.length}';
    final pageLabel = math.max(1, controller.currentPage.value);
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      blurSigma: immersive ? 18 : 10,
      surfaceAlpha: isDark ? 0.42 : 0.90,
      borderAlpha: isDark ? 0.16 : 0.44,
      shadowAlpha: isDark ? 0.18 : 0.07,
      accentColor: accent,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: isDark ? 0.96 : 0.84),
                  _pageSecondaryAccent(
                    context,
                  ).withValues(alpha: isDark ? 0.78 : 0.64),
                ],
              ),
            ),
            child: const Icon(
              CupertinoIcons.rectangle_stack_fill,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '精选目录',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$countLabel 项内容 · 第 $pageLabel 页',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildViewModeSwitch(
            context,
            viewMode: viewMode,
            isNarrowScreen: isNarrowScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSwitch(
    BuildContext context, {
    required SearchResultViewMode viewMode,
    required bool isNarrowScreen,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(
            context,
            icon: CupertinoIcons.list_bullet,
            selected: viewMode == SearchResultViewMode.list,
            tooltip: '列表视图',
            onPressed: () {
              if (viewMode != SearchResultViewMode.list) {
                controller.toggleViewMode(isNarrowScreen: isNarrowScreen);
              }
            },
          ),
          _buildViewModeButton(
            context,
            icon: CupertinoIcons.square_grid_2x2,
            selected: viewMode == SearchResultViewMode.grid,
            tooltip: '网格视图',
            onPressed: () {
              if (viewMode != SearchResultViewMode.grid) {
                controller.toggleViewMode(isNarrowScreen: isNarrowScreen);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(
    BuildContext context, {
    required IconData icon,
    required bool selected,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _pageAccent(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            width: 34,
            height: 32,
            child: Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterRow(BuildContext context, List<RecommendApiItem> items) {
    final posters = items
        .map((e) => e.poster_path ?? e.backdrop_path)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
    if (posters.isEmpty) {
      return const SizedBox.shrink();
    }
    const posterWidth = 94.0;
    const posterHeight = 142.0;
    final children = <Widget>[];
    for (var i = 0; i < posters.length && i < 3; i++) {
      var angleValue = 0.0;
      var offsetValue = Offset(0, 0);
      if (i == 0) {
        angleValue = 8;
        offsetValue = const Offset(-82, 8);
      } else if (i == 1) {
        angleValue = -4;
        offsetValue = const Offset(0, 18);
      } else {
        angleValue = 6;
        offsetValue = const Offset(82, 8);
      }

      final angle = angleValue * math.pi / 180;

      children.add(
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: offsetValue,
            child: Transform.rotate(
              angle: angle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedImage(
                    imageUrl: ImageUtil.convertCacheImageUrl(posters[i]),
                    width: posterWidth,
                    height: posterHeight,
                    fit: BoxFit.cover,
                    memCacheWidth: _scaledCacheExtent(context, posterWidth),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(
      children: [if (children.length == 1) children[0] else ...children],
    );
  }

  Widget _buildBottomStatusHost(BuildContext context) {
    return Obx(
      () => _buildBottomStatus(
        context,
        isLoading: controller.isLoading.value,
        hasMore: controller.hasMore.value,
        hasItems: controller.items.isNotEmpty,
        error: controller.error.value,
      ),
    );
  }

  Widget _buildBottomStatus(
    BuildContext context, {
    required bool isLoading,
    required bool hasMore,
    required bool hasItems,
    required String? error,
  }) {
    if (!hasItems) {
      return const SizedBox.shrink();
    }
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: AppLoading()),
      );
    }
    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: FilledButton.icon(
          onPressed: controller.loadMore,
          icon: const Icon(CupertinoIcons.arrow_down_circle, size: 18),
          label: const Text('加载更多'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Text(
            '已经到底啦',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  void _openDetail(RecommendApiItem item) {
    final path = HttpPathBuilderUtil.buildMediaPath(item);
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = _bestTitle(item);
    final params = <String, String>{
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
    };
    Get.toNamed('/media-detail', parameters: params);
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

  Color _readableOnColor(Color color) {
    return color.computeLuminance() > 0.48 ? Colors.black87 : Colors.white;
  }
}

class _RecommendCategoryHeaderPainter extends CustomPainter {
  const _RecommendCategoryHeaderPainter({
    required this.accent,
    required this.secondaryAccent,
    required this.isDark,
  });

  final Color accent;
  final Color secondaryAccent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.08 : 0.20),
          Colors.transparent,
          secondaryAccent.withValues(alpha: isDark ? 0.20 : 0.12),
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(bounds);
    canvas.drawRect(bounds, sheen);

    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          accent.withValues(alpha: isDark ? 0.34 : 0.24),
          secondaryAccent.withValues(alpha: isDark ? 0.26 : 0.18),
        ],
      ).createShader(bounds);

    final band = Path()
      ..moveTo(size.width * 0.06, size.height * 0.22)
      ..lineTo(size.width * 0.96, size.height * 0.06)
      ..lineTo(size.width * 1.02, size.height * 0.18)
      ..lineTo(size.width * 0.10, size.height * 0.38)
      ..close();
    canvas.drawPath(band, bandPaint);

    final lowerBand = Path()
      ..moveTo(size.width * -0.06, size.height * 0.54)
      ..lineTo(size.width * 0.74, size.height * 0.38)
      ..lineTo(size.width * 0.88, size.height * 0.48)
      ..lineTo(size.width * 0.02, size.height * 0.68)
      ..close();
    canvas.drawPath(
      lowerBand,
      Paint()..color = Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.10 : 0.24)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.16 + i * 0.09);
      canvas.drawLine(
        Offset(size.width * 0.10, y),
        Offset(size.width * 0.90, y - size.height * 0.11),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RecommendCategoryHeaderPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.secondaryAccent != secondaryAccent ||
        oldDelegate.isDark != isDark;
  }
}
