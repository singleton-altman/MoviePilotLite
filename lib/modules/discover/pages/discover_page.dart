import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/discover/widgets/discover_filter_sheet.dart';
import 'package:moviepilot_mobile/modules/discover/widgets/discover_media_card.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/grid_layout.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class DiscoverPage extends GetView<DiscoverController> {
  const DiscoverPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const double _gridSpacing = 12;
  static const double _gridPadding = 16;
  static const double _cardAspectRatio = 0.62;
  static const Color _cinemaBlack = Color(0xFF050506);
  static const Color _surfaceSoft = Color(0xFF1D1D21);
  static const Color _netflixRed = Color(0xFFE50914);
  static const Color _gold = Color(0xFFFFC46B);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureUserCookieRefreshed();
    });
    final appService = Get.find<AppService>();
    return Obx(() {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final hasPageBackground =
          appService.backgroundImageEnabled.value &&
          appService.backgroundImageBytes.value != null;
      return Scaffold(
        backgroundColor: isDark ? _cinemaBlack : const Color(0xFFF4F7FB),
        extendBodyBehindAppBar: true,
        appBar: _buildNavigationBar(context),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPageBackground)
              Positioned.fill(child: _buildBackgroundImage(context, appService))
            else
              const Positioned.fill(child: _CinematicAtmosphere()),
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
                SliverToBoxAdapter(child: Obx(() => _buildHero(context))),
                SliverToBoxAdapter(
                  child: Obx(() => _buildFilterSummary(context)),
                ),
                SliverToBoxAdapter(child: Obx(() => _buildSection(context))),
                SliverToBoxAdapter(
                  child: SizedBox(height: _bottomSpacer(context)),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  double _bottomSpacer(BuildContext context) {
    return 104;
  }

  AppBar _buildNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      foregroundColor: colorScheme.onSurface,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {},
        child: Icon(Icons.explore_outlined, color: colorScheme.onSurface),
      ),
      title: Text(
        'Discover',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _GlassButton(
            icon: Icons.tune_rounded,
            label: '筛选',
            compact: true,
            onTap: () => _openFilterSheet(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundImage(BuildContext context, AppService appService) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bytes = appService.backgroundImageBytes.value;
    if (bytes == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: appService.backgroundImageOpacity.value,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  appService.backgroundImageGradientTop.value,
                  appService.backgroundImageGradientBottom.value,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xBB050501)
                  : Colors.white.withValues(alpha: 0.54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final items = controller.currentItems();
    final isLoading = controller.isLoading();
    final hero = items.isNotEmpty ? items.first : null;
    final imageUrl = _imageUrl(hero, preferBackdrop: true);
    final top = MediaQuery.paddingOf(context).top;
    final title = hero == null
        ? 'Cinematic Discovery'
        : _bestTitle(hero) ?? 'Untitled';
    final source = controller.selectedSource.value;
    final subtitle = isLoading && hero == null
        ? '正在校准片库雷达'
        : hero?.overview?.trim().isNotEmpty == true
        ? hero!.overview!.trim()
        : '从 ${source.label} 中发现下一部值得停留的作品';
    final meta = _compactHeroMeta(hero, source);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 68, 16, 12),
      child: GestureDetector(
        onTap: hero == null ? null : () => _openDetail(hero),
        child: Container(
          height: 310,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: _netflixRed.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                CachedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: const _HeroPlaceholder(),
                  errorWidget: const _HeroPlaceholder(),
                )
              else
                const _HeroPlaceholder(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22000000),
                      Color(0x66000000),
                      Color(0xF2050506),
                    ],
                    stops: [0.12, 0.48, 1],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.95, -0.85),
                    radius: 1.05,
                    colors: [
                      _netflixRed.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 0.96,
                            letterSpacing: -1.2,
                          ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PrimaryActionButton(
                        enabled: hero != null,
                        onTap: hero == null ? null : () => _openDetail(hero),
                        compact: true,
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

  Widget _buildFilterSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final parts = _summaryParts(controller.currentSummaryText());
    final visibleParts = parts.take(5).toList();
    final remaining = parts.length - visibleParts.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: InkWell(
            onTap: () => _openFilterSheet(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(
                  alpha: isDark ? 0.72 : 0.92,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_netflixRed, Color(0xFFFF6B35)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_movies_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final part in visibleParts)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildSummaryChip(context, part),
                            ),
                          if (remaining > 0)
                            _buildSummaryChip(context, '+$remaining'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context) {
    final items = controller.currentItems();
    final isLoading = controller.isLoading();
    final errorText = controller.errorText();
    final gridItems = items.length > 1 ? items.skip(1).toList() : items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Now Discovering',
          subtitle: items.isEmpty ? '按当前条件探索片单' : '${items.length} 部作品已就绪',
        ),
        if (items.isEmpty && isLoading)
          _buildLoadingGrid(context)
        else if (items.isEmpty && errorText != null)
          _buildEmptyRail(context, errorText)
        else if (items.isEmpty)
          _buildEmptyRail(context, '当前条件暂时没有匹配作品')
        else
          _buildItemsGrid(context, gridItems),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_netflixRed, _gold],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid(BuildContext context, List<RecommendApiItem> items) {
    final layout = gridLayout(
      context,
      gridSpacing: _gridSpacing,
      gridPadding: _gridPadding,
    );
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: _gridPadding),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layout.crossAxisCount,
        crossAxisSpacing: _gridSpacing,
        mainAxisSpacing: _gridSpacing,
        childAspectRatio: _cardAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return DiscoverMediaCard(item: item, onTap: () => _openDetail(item));
      },
    );
  }

  Widget _buildLoadingGrid(BuildContext context) {
    final layout = gridLayout(
      context,
      gridSpacing: _gridSpacing,
      gridPadding: _gridPadding,
    );
    final placeholderCount = layout.crossAxisCount * 3;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: _gridPadding),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: placeholderCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layout.crossAxisCount,
        crossAxisSpacing: _gridSpacing,
        mainAxisSpacing: _gridSpacing,
        childAspectRatio: _cardAspectRatio,
      ),
      itemBuilder: (context, index) => const _DiscoverCardSkeleton(),
    );
  }

  Widget _buildEmptyRail(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: isDark ? 0.66 : 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _netflixRed.withValues(alpha: 0.42),
                    colorScheme.surfaceContainerHighest,
                  ],
                ),
              ),
              child: const Icon(
                Icons.movie_filter_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '片场暂时安静',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            _GlassButton(
              icon: Icons.tune_rounded,
              label: '调整筛选条件',
              onTap: () => _openFilterSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final result = await showModalBottomSheet<DiscoverFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
  }

  List<String> _summaryParts(String summary) {
    return summary
        .split(' · ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  Widget _buildSummaryChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.28)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _compactHeroMeta(RecommendApiItem? item, DiscoverSourceEntry source) {
    final result = <String>[source.label];
    if (item == null) return result.join(' · ');
    final type = item.type?.trim() ?? '';
    final year = item.year?.trim() ?? item.title_year?.trim() ?? '';
    final vote = item.vote_average;
    if (type.isNotEmpty) result.add(type);
    if (year.isNotEmpty) result.add(year);
    if (vote != null && vote > 0) result.add('★ ${vote.toStringAsFixed(1)}');
    return result.join(' · ');
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
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: compact ? 38 : 44,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(
                alpha: isDark ? 0.72 : 0.92,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: colorScheme.onSurface,
                  size: compact ? 18 : 19,
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.enabled,
    required this.onTap,
    this.compact = false,
  });

  final bool enabled;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.62,
        child: Container(
          height: compact ? 40 : 46,
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DiscoverPage._netflixRed, Color(0xFFFF4B2B)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: DiscoverPage._netflixRed.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: compact ? 22 : 24,
              ),
              const SizedBox(width: 5),
              const Text(
                '查看详情',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CinematicAtmosphere extends StatelessWidget {
  const _CinematicAtmosphere();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? DiscoverPage._cinemaBlack : const Color(0xFFF4F7FB);
    final surface = isDark
        ? DiscoverPage._surfaceSoft
        : const Color(0xFFE8EEF6);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.72, -0.92),
          radius: 1.25,
          colors: [
            DiscoverPage._netflixRed.withValues(alpha: isDark ? 0.18 : 0.08),
            base,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white.withValues(alpha: isDark ? 0.035 : 0.32),
              Colors.transparent,
              surface.withValues(alpha: isDark ? 0.32 : 0.56),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? DiscoverPage._surfaceSoft : const Color(0xFFE2E8F0),
            DiscoverPage._netflixRed.withValues(alpha: 0.42),
            isDark ? DiscoverPage._cinemaBlack : const Color(0xFFCBD5E1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_movies_rounded,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.18),
          size: 88,
        ),
      ),
    );
  }
}

class _DiscoverCardSkeleton extends StatelessWidget {
  const _DiscoverCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: isDark ? 0.66 : 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.58,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
