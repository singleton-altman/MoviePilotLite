import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/downloader/controllers/downloader_controller.dart';
import 'package:moviepilot_mobile/modules/downloader/models/download_task.dart';
import 'package:moviepilot_mobile/modules/downloader/widgets/downloader_client_tab_chip.dart';
import 'package:moviepilot_mobile/modules/downloader/widgets/downloader_task_item_card.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class DownloaderPage extends GetView<DownloaderController> {
  const DownloaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: '下载历史',
            icon: const Icon(Icons.history_rounded, size: 22),
            onPressed: () => Get.toNamed('/download-history'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => _buildDownloaderTabs(context)),
          Expanded(child: _buildTaskList(context)),
        ],
      ),
    );
  }

  Widget _buildDownloaderTabs(BuildContext context) {
    if (controller.downloaders.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          for (int i = 0; i < controller.downloaders.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DownloaderClientTabChip(
                title: controller.downloaders[i].name,
                isSelected: controller.selectedIndex.value == i,
                onTap: () => controller.switchDownloader(i),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, DownloadTask task) {
    final label = (task.title ?? task.name ?? '').trim();
    ToastUtil.warning(
      label.isEmpty ? '删除后将无法恢复,确定删除该任务吗?' : '删除后将无法恢复,确定删除「$label」吗?',
      title: '删除下载任务',
      onConfirm: () => controller.deleteTask(task),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    return Obx(() {
      if (controller.downloaders.isEmpty &&
          !controller.isLoadingDownloaders.value) {
        return const Center(child: Text('暂无下载器'));
      }
      return RefreshIndicator(
        onRefresh: controller.refreshTasks,
        child: Obx(() {
          if (controller.isLoading.value && controller.tasks.isEmpty) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (controller.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_outlined,
                    size: 64,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无下载任务',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: controller.tasks.length,
            itemBuilder: (context, index) {
              final task = controller.tasks[index];
              return DownloaderTaskItemCard(
                task: task,
                onPauseResume: () => controller.togglePauseResume(task),
                onDelete: () => _confirmDeleteTask(context, task),
                isDownloading: controller.isDownloading(task),
                isOperating:
                    task.hash != null &&
                    controller.operatingHashes.contains(task.hash),
              );
            },
          );
        }),
      );
    });
  }
}
