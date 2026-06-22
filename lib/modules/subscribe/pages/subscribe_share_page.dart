import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_share_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/shared_subscribe_detail_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_list_floating_bar.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_popular_filter_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_share_item_card.dart';

class SubscribeSharePage extends GetView<SubscribeShareController> {
  const SubscribeSharePage({super.key});

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.ensureUserCookieRefreshed();
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅分享'),
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
          Tooltip(
            message: '分享统计',
            child: IconButton(
              icon: Icon(
                CupertinoIcons.chart_bar_alt_fill,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Get.toNamed('/subscribe-share-statistics'),
            ),
          ),
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
        isTv: true,
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
              '暂无分享订阅',
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
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _horizontalPadding,
          16,
          _horizontalPadding,
          0,
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < items.length - 1 ? _cardSpacing : 0,
                  ),
                  child: SubscribeShareItemCard(
                    item: item,
                    onTap: () => _openSharedSubscribeDetailSheet(context, item),
                    onMoreTap: () {},
                  ),
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

  void _openSharedSubscribeDetailSheet(
    BuildContext context,
    SubscribeShareItem item,
  ) {
    showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SharedSubscribeDetailSheet(item: item),
    );
  }
}
