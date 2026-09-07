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
                    padding: EdgeInsets.fromLTRB(16, top + 64, 16, 110),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSourceBar(context, palette),
                        const SizedBox(height: 14),
                        _buildBody(context, palette),
                      ]),
                    ),
                  );
                }),
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

  Widget _buildBody(BuildContext context, DashboardPaletteData palette) {
    final items = controller.currentItems();
    final isLoading = controller.isLoading();
    final errorText = controller.errorText();

    if (items.isEmpty && isLoading) {
      return Column(
        children: List.generate(5, (_) => const _DiscoverRowSkeleton()),
      );
    }
    if (items.isEmpty) {
      return _EmptyState(
        message: errorText ?? '当前条件没有匹配作品',
        onFilter: () => _openFilterSheet(context),
      );
    }

    final hero = items.first;
    final rest = items.length > 1 ? items.skip(1).toList() : const <RecommendApiItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeaturedCard(
          item: hero,
          source: controller.selectedSource.value,
          onTap: () => _openDetail(hero),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            '更多推荐',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: palette.titleText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rest.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _MediaRowCard(
              key: ValueKey(
                '${rest[i].media_id ?? rest[i].tmdb_id ?? rest[i].title}_$i',
              ),
              item: rest[i],
              onTap: () => _openDetail(rest[i]),
            ),
          ],
        ],
      ],
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

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.item,
    required this.source,
    required this.onTap,
  });

  final RecommendApiItem item;
  final DiscoverSourceEntry source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final title = _bestTitle(item) ?? 'Untitled';
    final imageUrl = _imageUrl(item, preferBackdrop: true);
    final meta = _itemMeta(item);

    return Semantics(
      button: true,
      label: '打开 $title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 220,
            decoration: BoxDecoration(
              color: palette.pageBackgroundAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.tileBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    CachedImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: const _SoftPlaceholder(),
                      errorWidget: const _SoftPlaceholder(),
                    )
                  else
                    const _SoftPlaceholder(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x22000000),
                          Color(0x99000000),
                          Color(0xE6000000),
                        ],
                        stops: [0.2, 0.55, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: DiscoverSourceVisual.logoWidget(
                                source,
                                size: 14,
                                fallbackColor: DiscoverSourceVisual.brandOf(
                                  source,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              source.label,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.vote_average != null &&
                                item.vote_average! > 0) ...[
                              const Spacer(),
                              Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: Colors.amber.shade400,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.vote_average!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                height: 1.15,
                              ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }
}

class _MediaRowCard extends StatelessWidget {
  const _MediaRowCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final RecommendApiItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DashboardPalette.of(context);
    final title = _bestTitle(item) ?? 'Untitled';
    final image = _imageUrl(item);
    final meta = _itemMeta(item);
    final overview = item.overview?.trim() ?? '';

    return Semantics(
      button: true,
      label: '打开 $title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.pageBackgroundAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.tileBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 78,
                    height: 112,
                    child: image.isEmpty
                        ? const _SoftPlaceholder()
                        : CachedImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            placeholder: const _SoftPlaceholder(),
                            errorWidget: const _SoftPlaceholder(),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 112,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: palette.titleText,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (overview.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              overview,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.mutedText,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: palette.pageBackgroundAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.explore_outlined, size: 36, color: palette.faintText),
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

class _DiscoverRowSkeleton extends StatelessWidget {
  const _DiscoverRowSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.pageBackgroundAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.tileBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 78,
              height: 112,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: palette.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftPlaceholder extends StatelessWidget {
  const _SoftPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DashboardPalette.of(context).surfaceAlt,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          color: DashboardPalette.of(context).faintText,
        ),
      ),
    );
  }
}

String _imageUrl(RecommendApiItem? item, {bool preferBackdrop = false}) {
  if (item == null) return '';
  final raw = preferBackdrop
      ? item.backdrop_path ?? item.poster_path ?? ''
      : item.poster_path ?? item.backdrop_path ?? '';
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  return ImageUtil.convertCacheImageUrl(trimmed);
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

String _itemMeta(RecommendApiItem item) {
  final year = item.year?.trim() ?? item.title_year?.trim() ?? '';
  final type = item.type?.trim() ?? '';
  final vote = item.vote_average;
  return [
    if (year.isNotEmpty) year,
    if (type.isNotEmpty) type,
    if (vote != null && vote > 0) vote.toStringAsFixed(1),
  ].join(' · ');
}
