import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/downloader/controllers/download_history_controller.dart';
import 'package:moviepilot_mobile/modules/downloader/models/download_history_item.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 下载历史页（GET /api/v1/history/download）。
/// 服务端维度的历史下载记录，与下载器实时任务互补；支持删除单条记录。
class DownloadHistoryPage extends GetView<DownloadHistoryController> {
  const DownloadHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('下载历史'), centerTitle: false),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Skeletonizer(
            enabled: true,
            child: _buildList(context, _skeletonItems, theme),
          );
        }
        final error = controller.errorText.value;
        if (error != null && controller.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 40, color: theme.colorScheme.error.withOpacity(0.7)),
                const SizedBox(height: 12),
                Text(error,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: controller.reload,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }
        if (controller.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_done_outlined,
                    size: 44,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text('暂无下载历史',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)),
                const SizedBox(height: 6),
                Text('下载器完成任务后会在这里留下记录',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }
        return _buildList(context, controller.items, theme);
      }),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<DownloadHistoryItem> items,
    ThemeData theme,
  ) {
    final footer = LoadMoreFooter(
      hasMore: controller.hasMore.value,
      isLoading: controller.isLoadingMore.value,
      hasItems: items.isNotEmpty,
      onLoadMore: controller.loadMore,
    );
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: controller.reload),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _buildItemCard(context, items[index], theme),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: footer,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    DownloadHistoryItem item,
    ThemeData theme,
  ) {
    final meta = item.buildMetaLine();
    final imageUrl = item.image?.trim() ?? '';
    final subParts = <String>[
      if (item.torrentSite != null && item.torrentSite!.trim().isNotEmpty)
        item.torrentSite!.trim(),
      if (item.displayDate.isNotEmpty) item.displayDate,
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 90,
              child: imageUrl.isEmpty
                  ? Container(
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                      child: Icon(Icons.movie_outlined,
                          size: 26,
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.6)),
                    )
                  : CachedImage(
                      imageUrl: ImageUtil.convertCacheImageUrl(imageUrl),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                if (item.torrentName != null &&
                    item.torrentName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.torrentName!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8))),
                ],
                if (subParts.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(subParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.7))),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '删除',
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: theme.colorScheme.error.withOpacity(0.8)),
            onPressed: () => _confirmDelete(context, item),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DownloadHistoryItem item) {
    ToastUtil.warning(
      '删除后将无法恢复,确定删除「${item.displayTitle}」的下载记录吗?',
      title: '删除下载历史',
      onConfirm: () async {
        final error = await controller.deleteItem(item);
        if (error != null) {
          ToastUtil.error(error);
        } else {
          ToastUtil.success('已删除');
        }
      },
    );
  }

  static final List<DownloadHistoryItem> _skeletonItems = List.generate(
    6,
    (i) => const DownloadHistoryItem(
      id: -1,
      title: '加载中的历史条目',
      year: '2026',
      type: 'movie',
      torrentSite: 'Site',
      date: '2026-01-01T00:00:00',
    ),
  );
}
