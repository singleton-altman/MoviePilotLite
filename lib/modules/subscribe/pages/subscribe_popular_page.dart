import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_popular_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_list_floating_bar.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_popular_filter_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_popular_item_card.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class SubscribePopularPage extends GetView<SubscribePopularController> {
  const SubscribePopularPage({super.key});

  static const double _horizontalPadding = 16;
  static const double _gridCrossAxisSpacing = 12;
  static const double _gridMainAxisSpacing = 16;

  static const double _wideBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureUserCookieRefreshed();
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('热门订阅'),
        centerTitle: false,
        actions: [
          Obx(() {
            if (!controller.isLoading.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(
        () => SubscribeListFloatingBar(
          hasActiveFilters: controller.hasActiveFilters,
          onFilterTap: () => _openFilterSheet(context),
          keyword: controller.keyword.value,
          onKeywordSubmitted: controller.updateKeyword,
          sortValue: controller.sortType.value,
          onSortChanged: controller.setSortType,
        ),
      ),
      body: CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          _buildSliverContent(context),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  MediaQuery.paddingOf(context).bottom +
                  SubscribeListFloatingBar.height +
                  32,
            ),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SubscribePopularFilterSheet(
        initialGenres: controller.selectedGenres.toList(),
        initialRatingMin: controller.voteMin.value,
        isTv: controller.isTv,
        onApply: (genres, ratingMin) {
          controller.applyFilter(genres, ratingMin);
        },
      ),
    );
  }

  Widget _buildSliverContent(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final error = controller.errorText.value;
      final items = controller.visibleItems;
      if (loading && items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      if (error != null && items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: controller.load,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '暂无热门订阅',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
            ),
          ),
        );
      }
      final width = MediaQuery.sizeOf(context).width;
      final crossAxisCount = width >= _wideBreakpoint ? 5 : 2;
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _horizontalPadding,
          16,
          _horizontalPadding,
          0,
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: _gridMainAxisSpacing,
                crossAxisSpacing: _gridCrossAxisSpacing,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return SubscribePopularItemCard(
                  item: item,
                  onTap: () => _openDetail(item),
                );
              }, childCount: items.length),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                if (items.isEmpty) return const SizedBox.shrink();
                if (!controller.hasMore.value) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
                    child: Center(
                      child: Text(
                        '没有更多了',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoDynamicColor.resolve(
                            CupertinoColors.secondaryLabel,
                            context,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                final loading = controller.isLoading.value;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                  child: Center(
                    child: CupertinoButton(
                      onPressed: loading ? null : () => controller.loadMore(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : Text(
                              '加载更多',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  void _openDetail(RecommendApiItem item) {
    final path = HttpPathBuilderUtil.buildMediaPath(item);
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = item.title;
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
    };
    Get.toNamed('/media-detail', parameters: params);
  }
}
