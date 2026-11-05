import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_history_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_history_item_card.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';

class SubscribeHistoryPage extends GetView<SubscribeHistoryController> {
  const SubscribeHistoryPage({super.key});

  static const double _horizontalPadding = 16;
  static const double _itemSpacing = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.subscribeType.stype}历史订阅'),
        centerTitle: false,
        actions: [
          Obx(() {
            if (!controller.isLoading.value) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverContent(context),
            Obx(() {
              final items = controller.items;
              return SliverToBoxAdapter(
                child: LoadMoreFooter(
                  hasMore: controller.hasMore.value,
                  isLoading: controller.isLoadingMore.value,
                  hasItems: items.isNotEmpty,
                  onLoadMore: controller.loadMore,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverContent(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final error = controller.errorText.value;
      final items = controller.items;
      if (loading && items.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
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
              '暂无历史订阅',
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
          12,
          _horizontalPadding,
          0,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final entry = items[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? _itemSpacing : 0,
              ),
              child: SubscribeHistoryItemCard(
                entry: entry,
                isTv: controller.isTv,
                onTap: () => _openDetail(entry.item),
                onResubscribe: () => _resubscribe(entry),
                onDelete: () => _delete(entry),
              ),
            );
          }, childCount: items.length),
        ),
      );
    });
  }

  void _resubscribe(SubscribeHistoryEntry entry) {
    ToastUtil.warning(
      '确定重新订阅「${entry.item.name ?? ''}」吗？',
      onConfirm: () => controller.resubscribe(entry),
    );
  }

  void _delete(SubscribeHistoryEntry entry) {
    ToastUtil.warning(
      '确定删除「${entry.item.name ?? ''}」的历史记录吗？',
      onConfirm: () => controller.deleteHistory(entry),
    );
  }

  void _openDetail(SubscribeItem item) {
    String path = '';
    if (item.tmdbid != null) {
      path = HttpPathBuilderUtil.buildHttpPath(
        DiscoverSource.tmdb,
        item.tmdbid.toString(),
      );
    } else if (item.doubanid != null) {
      path = HttpPathBuilderUtil.buildHttpPath(
        DiscoverSource.douban,
        item.doubanid.toString(),
      );
    } else if (item.bangumiid != null) {
      path = HttpPathBuilderUtil.buildHttpPath(
        DiscoverSource.bangumi,
        item.bangumiid.toString(),
      );
    }
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = item.name;
    Get.toNamed(
      '/media-detail',
      parameters: {
        'path': path,
        if (title != null && title.isNotEmpty) 'title': title,
        if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
        if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
      },
    );
  }
}
