import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_card.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

import '../controllers/media_search_list_controller.dart';

class MediaSearchListPage extends GetView<MediaSearchListController> {
  const MediaSearchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: Obx(
          () => Text(
            controller.keyword.value.isEmpty
                ? '媒体搜索'
                : '搜索：${controller.keyword.value}',
          ),
        ),
        centerTitle: false,
        actions: [
          // SSE 进度指示器（参考 WebView 样式）
          Obx(() {
            if (!controller.isProgressActive.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: controller.searchProgress.value > 0
                      ? controller.searchProgress.value
                      : null,
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.search(),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(context),
            // SSE 进度条（顶部线性进度条，类似 WebView）
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  /// 构建 SSE 进度指示器
  Widget _buildProgressIndicator() {
    return Obx(() {
      if (!controller.isProgressActive.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 线性进度条
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: controller.searchProgress.value,
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value > 0 ? value : null,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(controller.progressStatus.value),
                  ),
                  minHeight: 3,
                );
              },
            ),
            // 进度信息卡片
            if (controller.progressMessage.value.isNotEmpty)
              _buildProgressInfoCard(),
          ],
        ),
      );
    });
  }

  /// 构建进度信息卡片
  Widget _buildProgressInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(controller.progressStatus.value),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.progressMessage.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (controller.progressSource.value.isNotEmpty)
                  Text(
                    controller.progressSource.value,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            controller.formattedProgress,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 根据状态获取进度条颜色
  Color _getProgressColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'failed':
      case 'error':
        return Colors.red;
      case 'searching':
      default:
        return Colors.blue;
    }
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      final items = controller.items.toList();
      final isLoading = controller.isLoading.value;
      final error = controller.error.value;
      final hasMore = controller.hasMore.value;
      final cardWidth = _gridCardWidth(context);

      return RefreshIndicator(
        onRefresh: () => controller.search(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSummary(context)),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildPlaceholderState(isLoading, error),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    return RecommendItemCard(
                      item: item,
                      width: cardWidth,
                      onTap: () => _openDetail(item),
                    );
                  }, childCount: items.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
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

  Widget _buildSummary(BuildContext context) {
    return Obx(() {
      final count = controller.items.length;
      final total = controller.totalItems.value;
      final summary = total != null ? '共找到 $total 条结果' : '共找到 $count 条结果';
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                summary,
                style: Theme.of(context).textTheme.titleMedium,
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

  Widget _buildPlaceholderState(bool isLoading, String? error) {
    // 如果有 SSE 进度，显示进度状态而不是简单的 loading
    if (controller.isProgressActive.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                value: controller.searchProgress.value > 0
                    ? controller.searchProgress.value
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.progressMessage.value.isNotEmpty
                  ? controller.progressMessage.value
                  : '正在搜索...',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (controller.formattedProgress.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                controller.formattedProgress,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final message = error ?? '暂无数据，请尝试其它关键字';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => controller.search(),
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

    // 如果有 SSE 进度，显示进度指示而不是简单的 loading
    if (isLoading && controller.isProgressActive.value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: controller.searchProgress.value > 0
                      ? controller.searchProgress.value
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                controller.progressMessage.value.isNotEmpty
                    ? controller.progressMessage.value
                    : '加载中...',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              if (controller.formattedProgress.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '(${controller.formattedProgress})',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
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
          const Text('已经到底啦', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  double _gridCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 32.0; // left + right padding of 16
    const crossAxisSpacing = 16.0;
    final available = screenWidth - horizontalPadding - crossAxisSpacing;
    return available / 2;
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
