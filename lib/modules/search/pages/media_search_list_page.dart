import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_palette_cache.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_base_card.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_card.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/grid_layout.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

import '../controllers/media_search_list_controller.dart';

class MediaSearchListPage extends GetView<MediaSearchListController> {
  const MediaSearchListPage({super.key});
  static const double _gridSpacing = 8;
  static const double _gridPadding = 16;
  static const double _cardAspectRatio = 1 / 1.3;
  static const double _listPosterWidth = 72;
  static const double _listPosterHeight = 96;
  static const double _immersiveHeaderHeight = 250;
  static const double _narrowScreenBreakpoint = 600;
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.items.toList();
      final theme = _firstItemTheme(items);
      final bodyColor = AppTheme.darkBackgroundColor;
      final immersive = true;
      return Scaffold(
        backgroundColor: bodyColor,
        body: _buildBody(
          context,
          immersive: immersive,
          bodyColor: bodyColor,
          theme: theme,
        ),
      );
    });
  }

  Widget _buildBody(
    BuildContext context, {
    required bool immersive,
    required Color bodyColor,
    required ({
      Color themeColor,
      Color secondaryColor,
      List<RecommendApiItem> topItems,
    })?
    theme,
  }) {
    return Obx(() {
      final items = controller.items.toList();
      final isLoading = controller.isLoading.value;
      final hasCompletedInitialSearch =
          controller.hasCompletedInitialSearch.value;
      final error = controller.error.value;
      final hasMore = controller.hasMore.value;
      final isNarrowScreen =
          MediaQuery.sizeOf(context).width < _narrowScreenBreakpoint;
      final viewMode = controller.resolvedViewMode(
        isNarrowScreen: isNarrowScreen,
      );
      final layout = gridLayout(
        context,
        gridSpacing: _gridSpacing,
        gridPadding: _gridPadding,
      );
      final showOnlyLoading =
          items.isEmpty && (isLoading || !hasCompletedInitialSearch);
      if (showOnlyLoading) {
        return _buildLoadingScaffold(context, bodyColor: bodyColor);
      }
      return RefreshIndicator(
        onRefresh: () => controller.search(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildImmersiveHeader(
              context,
              theme: theme,
              bodyColor: bodyColor,
              isLoading: isLoading,
              hasItems: items.isNotEmpty,
              viewMode: viewMode,
              isNarrowScreen: isNarrowScreen,
            ),
            SliverToBoxAdapter(
              child: _buildSummary(context, immersive: immersive),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, error: error),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  _gridPadding,
                  0,
                  _gridPadding,
                  _gridPadding,
                ),
                sliver: viewMode == SearchResultViewMode.list
                    ? _buildListSliver(items)
                    : _buildGridSliver(items, layout.crossAxisCount),
              ),
            SliverToBoxAdapter(
              child: _buildBottomStatus(
                context,
                isLoading: isLoading,
                hasMore: hasMore,
                hasItems: items.isNotEmpty,
                error: error,
                immersive: immersive,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      );
    });
  }

  Widget _buildLoadingScaffold(
    BuildContext context, {
    required Color bodyColor,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050816),
                  bodyColor,
                  const Color(0xFF020617),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: Get.back,
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _WarpLoading(size: 220),
              const SizedBox(height: 18),
              Text(
                '正在搜索…',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridSliver(List<RecommendApiItem> items, int crossAxisCount) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildMediaItem(items, index, listMode: false),
        childCount: items.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: _gridSpacing,
        crossAxisSpacing: _gridSpacing,
        childAspectRatio: _cardAspectRatio,
      ),
    );
  }

  Widget _buildListSliver(List<RecommendApiItem> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final isLast = index == items.length - 1;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMediaItem(items, index, listMode: true),
            if (!isLast) ...[
              const SizedBox(height: 10),
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      }, childCount: items.length),
    );
  }

  Widget _buildMediaItem(
    List<RecommendApiItem> items,
    int index, {
    required bool listMode,
  }) {
    final item = items[index];
    return Obx(() {
      final appService = Get.find<AppService>();
      final existsOn = appService.enableFetchMediaserverLibraryStatus.value;
      final existsKey = controller.mediaserverExistsKey(item);
      final inLib =
          existsOn && (controller.mediaserverInLibrary[existsKey] ?? false);
      if (listMode) {
        return RecommendItemBaseCard(
          item: item,
          child: _buildListRow(item, inLibrary: inLib),
        );
      }
      return RecommendItemCard(
        item: item,
        inLibrary: inLib,
        onTap: () => _openDetail(item),
      );
    });
  }

  Widget _buildListRow(RecommendApiItem item, {required bool inLibrary}) {
    final title = _bestTitle(item) ?? '';
    final year = _displayYear(item);
    final overview = item.overview?.trim();
    final type = item.type?.trim();
    final vote = item.vote_average;
    final metaChips = <Widget>[
      if (type != null && type.isNotEmpty) _buildListMetaPill(type),
      if (year.isNotEmpty)
        Text(
          year,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 13,
          ),
        ),
      if (vote != null && vote > 0) _buildListMetaPill(vote.toStringAsFixed(1)),
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _listPoster(item),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (inLibrary) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Color(0xFF81C784),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (metaChips.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: metaChips,
                      ),
                    ],
                    if (overview != null && overview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        overview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 12,
                          height: 1.4,
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

  Widget _listPoster(RecommendApiItem item) {
    final raw = item.poster_path ?? item.backdrop_path;
    if (raw != null && raw.isNotEmpty) {
      return CachedImage(
        imageUrl: ImageUtil.convertCacheImageUrl(raw),
        width: _listPosterWidth,
        height: _listPosterHeight,
        fit: BoxFit.cover,
      );
    }
    return Container(
      width: _listPosterWidth,
      height: _listPosterHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9FA8DA), Color(0xFF5C6BC0)],
        ),
      ),
    );
  }

  Widget _buildListMetaPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4C6FFF).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _displayYear(RecommendApiItem item) {
    final year = item.year?.trim() ?? '';
    if (year.isNotEmpty) return year;
    return item.title_year?.trim() ?? '';
  }

  Widget _buildSummary(BuildContext context, {required bool immersive}) {
    return Obx(() {
      final count = controller.items.length;
      final total = controller.totalItems.value;
      final summary = total != null ? '共找到 $total 条结果' : '共找到 $count 条结果';
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                summary,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => controller.search(),
              child: const Text('重新搜索'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, {required String? error}) {
    final keyword = controller.keyword.value.trim();
    final isNoResult = error == null || error == '没有找到匹配的媒体';
    final title = isNoResult ? '没有找到匹配的媒体' : '搜索遇到问题';
    final subtitle = isNoResult
        ? (keyword.isEmpty ? '换一个关键词再试试。' : '没有命中 “$keyword”，可以换个片名、别名或年份再试。')
        : error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _EmptySearchMark(isError: !isNoResult),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => controller.search(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新搜索'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatus(
    BuildContext context, {
    required bool isLoading,
    required bool hasMore,
    required bool hasItems,
    required String? error,
    required bool immersive,
  }) {
    if (!hasItems) {
      return const SizedBox.shrink();
    }

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const _WarpLoading(size: 96),
              Text(
                '正在加载更多…',
                style: TextStyle(
                  color: immersive ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: OutlinedButton(
          onPressed: controller.loadMore,
          child: const Text('加载更多'),
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
            style: TextStyle(color: immersive ? Colors.white70 : Colors.grey),
          ),
        ],
      ),
    );
  }

  ({Color themeColor, Color secondaryColor, List<RecommendApiItem> topItems})?
  _firstItemTheme(List<RecommendApiItem> items) {
    if (items.isEmpty) return null;
    final first = items.first;
    final url = (first.poster_path ?? first.backdrop_path) ?? '';
    if (url.isEmpty) return null;
    final cache = Get.find<PluginPaletteCache>();
    final color = cache.watchColor(url) ?? cache.getCached(url);
    if (color == null) return null;
    final secondUrl = items.length > 1
        ? (items[1].poster_path ?? items[1].backdrop_path) ?? ''
        : '';
    final secondary =
        (secondUrl.isNotEmpty ? cache.watchColor(secondUrl) : null)?.withValues(
          alpha: 0.6,
        ) ??
        color.withValues(alpha: 0.9);
    return (
      themeColor: color,
      secondaryColor: secondary,
      topItems: items.take(3).toList(),
    );
  }

  SliverAppBar _buildImmersiveHeader(
    BuildContext context, {
    required ({
      Color themeColor,
      Color secondaryColor,
      List<RecommendApiItem> topItems,
    })?
    theme,
    required Color bodyColor,
    required bool isLoading,
    required bool hasItems,
    required SearchResultViewMode viewMode,
    required bool isNarrowScreen,
  }) {
    final baseA = Colors.black;
    final baseB = Colors.black.withValues(alpha: 0.5);
    final baseC = bodyColor;
    final targetA = theme?.secondaryColor ?? baseA;
    final targetB = (theme?.themeColor ?? baseA).withValues(alpha: 0.5);
    final targetC = bodyColor;
    final title = Obx(
      () => Text(
        controller.keyword.value.isEmpty
            ? '媒体搜索'
            : '搜索：${controller.keyword.value}',
        style: const TextStyle(color: Colors.white),
      ),
    );
    return SliverAppBar(
      pinned: true,
      expandedHeight: _immersiveHeaderHeight,
      backgroundColor: Colors.transparent,
      title: hasItems ? title : null,
      actions: [
        IconButton(
          tooltip: viewMode == SearchResultViewMode.list ? '切换为网格' : '切换为列表',
          onPressed: () =>
              controller.toggleViewMode(isNarrowScreen: isNarrowScreen),
          icon: Icon(
            viewMode == SearchResultViewMode.list
                ? CupertinoIcons.square_grid_2x2
                : CupertinoIcons.list_bullet,
            color: Colors.white,
          ),
        ),
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: Get.back,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: theme == null ? 0 : 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            final a = Color.lerp(baseA, targetA, t)!;
            final b = Color.lerp(baseB, targetB, t)!;
            final c = Color.lerp(baseC, targetC, t)!;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [a, b, c],
                  stops: const [0, 0.6, 1.0],
                ),
              ),
              child: child,
            );
          },
          child: Center(
            child: SizedBox(
              height: 160,
              child: (!isLoading && theme != null)
                  ? _buildPosterRow(theme.topItems)
                  : const Center(child: _WarpLoading(size: 132)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterRow(List<RecommendApiItem> items) {
    final posters = items
        .map((e) => e.poster_path ?? e.backdrop_path)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
    if (posters.isEmpty) return const SizedBox.shrink();
    final size = 90.0;
    if (posters.length == 1) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedImage(
            imageUrl: ImageUtil.convertCacheImageUrl(posters.first),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (posters.length == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedImage(
              imageUrl: ImageUtil.convertCacheImageUrl(posters[0]),
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedImage(
              imageUrl: ImageUtil.convertCacheImageUrl(posters[1]),
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ],
      );
    }
    final children = <Widget>[];
    for (var i = 0; i < posters.length && i < 3; i++) {
      var angleValue = 0.0;
      var offsetValue = Offset.zero;
      if (i == 0) {
        angleValue = 10;
        offsetValue = Offset(-size + 10, 0);
      } else if (i == 1) {
        angleValue = -5;
        offsetValue = Offset(0, size / 4);
      } else {
        angleValue = 8;
        offsetValue = Offset(size - 10, size - 30);
      }
      final angle = angleValue * math.pi / 180;
      children.add(
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: offsetValue,
            child: Transform.rotate(
              angle: angle,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedImage(
                  imageUrl: ImageUtil.convertCacheImageUrl(posters[i]),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: children);
  }

  void _openDetail(RecommendApiItem item) {
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

  String? _buildMediaPath(RecommendApiItem item) {
    final prefix = item.mediaid_prefix;
    final mediaId = item.media_id;
    if (prefix != null &&
        prefix.isNotEmpty &&
        mediaId != null &&
        mediaId.isNotEmpty) {
      return '$prefix:$mediaId';
    }
    final tmdbId = item.tmdb_id;
    if (tmdbId != null && tmdbId.isNotEmpty) {
      return 'tmdb:$tmdbId';
    }
    final doubanId = item.douban_id;
    if (doubanId != null && doubanId.isNotEmpty) {
      return 'douban:$doubanId';
    }
    final bangumiId = item.bangumi_id;
    if (bangumiId != null && bangumiId.isNotEmpty) {
      return 'bangumi:$bangumiId';
    }
    return null;
  }
}

class _WarpLoading extends StatefulWidget {
  const _WarpLoading({required this.size});

  final double size;

  @override
  State<_WarpLoading> createState() => _WarpLoadingState();
}

class _WarpLoadingState extends State<_WarpLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WarpLoadingPainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class _WarpLoadingPainter extends CustomPainter {
  const _WarpLoadingPainter({required this.progress});

  final double progress;

  static const int _particleCount = 72;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shortest = size.shortestSide;
    final maxRadius = shortest * 0.45;
    final basePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.plus;
    final glowPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..blendMode = BlendMode.plus;

    _paintBackdrop(canvas, center, shortest);
    _paintCore(canvas, center, shortest);

    for (var i = 0; i < _particleCount; i++) {
      final seed = i * 12.9898;
      final angle = _pseudo(seed) * math.pi * 2;
      final lane = _pseudo(seed + 7.31);
      final phase = (progress + _pseudo(seed + 19.7)) % 1.0;
      final curve = Curves.easeOutCubic.transform(phase);
      final radius = shortest * (0.05 + lane * 0.06) + maxRadius * curve;
      final trail = shortest * (0.035 + curve * 0.14);
      final opacity = math.sin((1 - phase) * math.pi).clamp(0.0, 1.0);
      final direction = Offset(math.cos(angle), math.sin(angle));
      final start = center + direction * radius;
      final end = center + direction * (radius + trail);
      final hueMix = _pseudo(seed + 3.17);
      final color = Color.lerp(
        const Color(0xFF7DD3FC),
        const Color(0xFFE0F2FE),
        hueMix,
      )!.withValues(alpha: 0.08 + opacity * 0.42);
      final width = shortest * (0.0038 + curve * 0.0065);

      glowPaint
        ..color = color.withValues(alpha: opacity * 0.18)
        ..strokeWidth = width * 3.2;
      canvas.drawLine(start, end, glowPaint);

      basePaint
        ..color = color
        ..strokeWidth = width;
      canvas.drawLine(start, end, basePaint);
    }
  }

  void _paintBackdrop(Canvas canvas, Offset center, double shortest) {
    final washPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1D4ED8).withValues(alpha: 0.18),
          const Color(0xFF0F172A).withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: shortest * 0.62));
    canvas.drawCircle(center, shortest * 0.62, washPaint);
  }

  void _paintCore(Canvas canvas, Offset center, double shortest) {
    final pulse = math.sin(progress * math.pi * 2) * 0.5 + 0.5;
    final coreRadius = shortest * (0.025 + pulse * 0.01);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.7),
          const Color(0xFF93C5FD).withValues(alpha: 0.26),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: shortest * 0.16));
    canvas.drawCircle(center, shortest * 0.16, corePaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.005
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.12 + pulse * 0.1);
    canvas.drawCircle(center, coreRadius * 4.8, ringPaint);
  }

  double _pseudo(double value) {
    final raw = math.sin(value) * 43758.5453123;
    return raw - raw.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _WarpLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _EmptySearchMark extends StatelessWidget {
  const _EmptySearchMark({required this.isError});

  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent = isError ? const Color(0xFFF87171) : const Color(0xFF60A5FA);
    return SizedBox.square(
      dimension: 132,
      child: CustomPaint(
        painter: _EmptySearchMarkPainter(accent: accent, isError: isError),
      ),
    );
  }
}

class _EmptySearchMarkPainter extends CustomPainter {
  const _EmptySearchMarkPainter({required this.accent, required this.isError});

  final Color accent;
  final bool isError;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shortest = size.shortestSide;
    final radius = shortest * 0.34;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.22),
          accent.withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: shortest * 0.5));
    canvas.drawCircle(center, shortest * 0.5, glowPaint);

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.12);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i - 1) * math.pi / 8);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: shortest * (0.72 + i * 0.08),
          height: shortest * (0.34 + i * 0.04),
        ),
        orbitPaint,
      );
      canvas.restore();
    }

    final iconPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = shortest * 0.055
      ..color = accent.withValues(alpha: 0.9);
    canvas.drawCircle(
      center.translate(-shortest * 0.04, -shortest * 0.03),
      radius,
      iconPaint,
    );
    canvas.drawLine(
      center.translate(radius * 0.58, radius * 0.58),
      center.translate(radius * 1.15, radius * 1.15),
      iconPaint,
    );

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.72);
    for (final offset in const [
      Offset(0.18, 0.22),
      Offset(0.72, 0.18),
      Offset(0.74, 0.72),
      Offset(0.25, 0.78),
    ]) {
      canvas.drawCircle(
        Offset(size.width * offset.dx, size.height * offset.dy),
        shortest * 0.015,
        dotPaint,
      );
    }

    if (isError) {
      final markPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = shortest * 0.035
        ..color = Colors.white.withValues(alpha: 0.8);
      canvas.drawLine(
        center.translate(-shortest * 0.1, -shortest * 0.1),
        center.translate(shortest * 0.1, shortest * 0.1),
        markPaint,
      );
      canvas.drawLine(
        center.translate(shortest * 0.1, -shortest * 0.1),
        center.translate(-shortest * 0.1, shortest * 0.1),
        markPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmptySearchMarkPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.isError != isError;
  }
}
