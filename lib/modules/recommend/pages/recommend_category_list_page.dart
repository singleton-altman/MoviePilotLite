import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_category_list_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_base_card.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_card.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/grid_layout.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RecommendCategoryListPage
    extends GetView<RecommendCategoryListController> {
  const RecommendCategoryListPage({super.key});

  static const double _gridSpacing = 8;
  static const double _gridPadding = 16;
  static const double _cardAspectRatio = 1 / 1.3;
  static const double _listPosterWidth = 72;
  static const double _listPosterHeight = 96;
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

    final bodyColor = AppTheme.darkBackgroundColor;
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
      final isLoading = controller.isLoading.value;
      final error = controller.error.value;
      final hasMore = controller.hasMore.value;
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

            immersive
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        controller.categoryTitle,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : const SliverToBoxAdapter(child: SizedBox.shrink()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                _gridPadding,
                immersive ? 0 : 8,
                _gridPadding,
                _gridPadding,
              ),
              sliver: Skeletonizer.sliver(
                enabled: isLoading || items.isEmpty,
                child: viewMode == SearchResultViewMode.list
                    ? _buildListSliver(items)
                    : _buildGridSliver(items, layout.crossAxisCount),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildBottomStatus(
                context,
                isLoading: isLoading,
                hasMore: hasMore,
                hasItems: items.isNotEmpty,
                error: error,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      );
    });
  }

  Widget _buildGridSliver(List<RecommendApiItem> items, int crossAxisCount) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return RecommendItemCard(
          item: item,
          onTap: () => _openDetail(item),
        );
      }, childCount: items.length),
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
        final item = items[index];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RecommendItemBaseCard(
              item: item,
              child: _buildListRow(item),
            ),
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

  Widget _buildListRow(RecommendApiItem item) {
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
                    Text(
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

  SliverAppBar _buildImmersiveHeader(
    BuildContext context,
    List<RecommendApiItem> items, {
    Color? bodyColor,
    required SearchResultViewMode viewMode,
    required bool isNarrowScreen,
  }) {
    final themeColor = controller.appBarThemeColor ?? Colors.black;
    final secondaryColor = controller.appBarSecondaryThemeColor ?? Colors.black;
    final topItems = items.take(3).toList();
    return SliverAppBar(
      pinned: true,
      expandedHeight: 250,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            color: Colors.white,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                secondaryColor,
                themeColor.withValues(alpha: 0.5),
                bodyColor ?? Colors.black87,
              ],
              stops: const [0, 0.6, 1.0],
            ),
          ),
          child: Center(
            child: SizedBox(height: 160, child: _buildPosterRow(topItems)),
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
    if (posters.isEmpty) {
      return const SizedBox.shrink();
    }
    final size = 90.0;
    final children = <Widget>[];
    for (var i = 0; i < posters.length && i < 3; i++) {
      var angleValue = 0.0;
      var offsetValue = Offset(0, 0);
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
    return Stack(
      children: [if (children.length == 1) children[0] else ...children],
    );
  }

  Widget _buildPlaceholderState(bool isLoading, String? error) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final message = error ?? '暂无数据';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => controller.loadFirst(),
          child: const Text('重新加载'),
        ),
      ],
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
        child: Center(child: CircularProgressIndicator()),
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
}
