import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/storage/controllers/storage_list_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../controllers/file_manager_browser_controller.dart';
import '../file_manager_picker_service.dart';
import '../widgets/file_recognize_result_sheet.dart';

/// 存储 type -> 图标资源映射
Widget _storageIconWidget(String type, {double size = 24}) {
  final m = Assets.images.misc;
  switch (type.toLowerCase()) {
    case 'alist':
      return m.alist.svg(width: size, height: size);
    case 'openlist':
      return m.openlist.svg(width: size, height: size);
    case 'alipan':
      return m.alipan.image(width: size, height: size, fit: BoxFit.contain);
    case 'u115':
      return m.u115.image(width: size, height: size, fit: BoxFit.contain);
    case 'smb':
      return m.smb.image(width: size, height: size, fit: BoxFit.contain);
    case 'rclone':
      return m.rclone.image(width: size, height: size, fit: BoxFit.contain);
    case 'plex':
      return m.plex.image(width: size, height: size, fit: BoxFit.contain);
    case 'emby':
      return m.emby.image(width: size, height: size, fit: BoxFit.contain);
    case 'jellyfin':
      return m.jellyfin.image(width: size, height: size, fit: BoxFit.contain);
    case 'local':
    default:
      return m.storage.image(width: size, height: size, fit: BoxFit.contain);
  }
}

/// 文件浏览器页面 - 单页 pathStack 导航
class FileManagerBrowserPage extends GetView<FileManagerBrowserController> {
  const FileManagerBrowserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(child: _buildFileList()),
          if (controller.isPickerMode) _buildPickerBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildStorageTitle(BuildContext context) {
    return Obx(() {
      final name = controller.selectedStorage.value?.name ?? '选择存储';
      if (!Get.isRegistered<StorageListController>()) {
        return Text(
          name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        );
      }
      final storageController = Get.find<StorageListController>();
      final list = storageController.storages;
      if (list.isEmpty) {
        return Text(
          name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        );
      }
      final selected = controller.selectedStorage.value;
      return PopupMenuButton<StorageSetting>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: _storageIconWidget(selected.type, size: 22),
                  ),
                ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_down_circle_fill,
                size: 18,
                color: CupertinoColors.systemGrey3,
              ),
            ],
          ),
        ),
        onSelected: (s) => controller.switchStorage(s),
        itemBuilder: (context) => [
          for (final s in list)
            PopupMenuItem<StorageSetting>(
              value: s,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: _storageIconWidget(s.type),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (controller.selectedStorage.value?.type == s.type)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        CupertinoIcons.checkmark,
                        size: 18,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    });
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leading: Obx(() {
        final atRoot = controller.pathStack.length <= 1;
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            if (atRoot) {
              Get.back();
            } else {
              controller.goBack();
            }
          },
          child: atRoot
              ? const Icon(CupertinoIcons.xmark, size: 22)
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.chevron_back, size: 20),
                    Text('返回'),
                  ],
                ),
        );
      }),
      title: _buildStorageTitle(context),
      actions: [
        Obx(
          () => PopupMenuButton<String>(
            padding: EdgeInsets.symmetric(horizontal: 20),
            icon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                controller.sortBy.value == 'name'
                    ? CupertinoIcons.textformat
                    : CupertinoIcons.clock,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            onSelected: controller.setSortBy,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.textformat, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '名称',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (controller.sortBy.value == 'name')
                      const Icon(
                        CupertinoIcons.checkmark,
                        size: 18,
                        color: CupertinoColors.activeBlue,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'time',
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.clock, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '时间',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (controller.sortBy.value == 'time')
                      const Icon(
                        CupertinoIcons.checkmark,
                        size: 18,
                        color: CupertinoColors.activeBlue,
                      ),
                  ],
                ),
              ),
            ],
            // child: Text(
            //   controller.sortBy.value == 'name' ? '名称' : '时间',
            //   style: const TextStyle(fontSize: 14),
            // ),
          ),
        ),
      ],
    );
  }

  Widget _buildPathBreadcrumb() {
    return Obx(() {
      final stack = controller.pathStack;
      if (stack.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < stack.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: CupertinoColors.systemGrey3,
                    ),
                  ),
                GestureDetector(
                  onTap: () => controller.jumpToPath(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      _folderNameFromPath(stack[i]),
                      style: TextStyle(
                        fontSize: 14,
                        color: i == stack.length - 1
                            ? CupertinoColors.systemBlue
                            : CupertinoColors.systemGrey,
                        fontWeight: i == stack.length - 1
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  String _folderNameFromPath(String path) {
    if (path == '/') return '根目录';
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? '根目录' : parts.last;
  }

  Widget _buildFileList() {
    return Obx(() {
      if (controller.selectedStorage.value == null &&
          controller.errorText.value != null) {
        return _buildNoStorageView();
      }

      if (controller.selectedStorage.value == null) {
        return const Center(child: CupertinoActivityIndicator());
      }

      if (controller.isLoading.value && controller.files.isEmpty) {
        return _buildSkeletonList();
      }

      if (controller.errorText.value != null) {
        return _buildErrorView();
      }

      return CustomScrollView(
        slivers: [
          // 路径面包屑
          SliverToBoxAdapter(child: _buildPathBreadcrumb()),
          // 搜索栏
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CupertinoSearchTextField(
                controller: controller.searchController,
                placeholder: '搜索文件...',
                onSubmitted: controller.onSearch,
                onSuffixTap: controller.clearSearch,
              ),
            ),
          ),
          // 文件列表或空状态
          if (controller.files.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyView())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final file = controller.files[index];
                return _buildFileItem(file);
              }, childCount: controller.files.length),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: controller.isPickerMode ? 0 : 20),
          ),
        ],
      );
    });
  }

  static bool _isDirectory(MediaOrganizeFileItem file) {
    final t = file.type?.toLowerCase();
    return t == 'dir' || t == 'directory' || t == 'folder';
  }

  Widget _buildFileItem(MediaOrganizeFileItem file) {
    final isDir = _isDirectory(file);
    final canSelect =
        controller.isPickerMode &&
        ((isDir && controller.allowDirSelection) ||
            (!isDir && controller.allowFileSelection));

    return Obx(() {
      final selectedFiles = FileManagerPickerService.selectedFiles;
      final isSelected = selectedFiles.contains(file);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isDir) {
            controller.enterDirectory(file);
          } else if (controller.isPickerMode && canSelect) {
            FileManagerPickerService.toggleSelection(
              file,
              controller.allowMultipleSelection,
            );
          }
        },
        onLongPress: () {
          if (controller.isPickerMode &&
              isDir &&
              controller.allowDirSelection) {
            FileManagerPickerService.toggleSelection(
              file,
              controller.allowMultipleSelection,
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.systemBlue.withValues(alpha: 0.08)
                : null,
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFileIcon(file),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name ?? '未知',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_hasSubtitle(file)) ...[
                        const SizedBox(height: 2),
                        _buildFileSubtitle(file),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildTrailing(file, canSelect, isSelected),
              ],
            ),
          ),
        ),
      );
    });
  }

  bool _hasSubtitle(MediaOrganizeFileItem file) {
    return (file.size != null && file.size! > 0) || file.modifyTime != null;
  }

  Widget _buildFileIcon(MediaOrganizeFileItem file) {
    final isDir = _isDirectory(file);
    if (isDir) {
      return Icon(
        CupertinoIcons.folder_fill,
        color: CupertinoColors.systemBlue,
        size: 26,
      );
    }
    final style = _getFileTypeStyle(file.extension);
    return Icon(style.icon, color: style.color, size: 26);
  }

  static const _videoExts = {
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'm2ts',
    'mts',
    'ts',
    'm4v',
    '3gp',
    '3g2',
    'f4v',
    'vob',
    'mpg',
    'mpeg',
  };
  static const _audioExts = {
    'mp3',
    'wav',
    'flac',
    'aac',
    'ogg',
    'm4a',
    'wma',
    'opus',
    'ape',
    'alac',
  };
  static const _imageExts = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
    'tiff',
    'tif',
    'ico',
  };
  static const _subtitleExts = {'srt', 'ass', 'ssa', 'vtt', 'sub', 'idx'};
  static const _documentExts = {'txt', 'md', 'doc', 'docx', 'pdf', 'nfo'};
  static const _archiveExts = {
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
    'bz2',
    'xz',
    'iso',
  };
  static const _codeExts = {
    'json',
    'yaml',
    'yml',
    'xml',
    'html',
    'py',
    'js',
    'ts',
    'dart',
  };

  ({IconData icon, Color color}) _getFileTypeStyle(String? extension) {
    if (extension == null || extension.isEmpty) {
      return (icon: CupertinoIcons.doc, color: CupertinoColors.systemGrey);
    }
    final ext = extension.toLowerCase();

    if (_videoExts.contains(ext)) {
      return (
        icon: CupertinoIcons.film_fill,
        color: CupertinoColors.systemPurple,
      );
    }
    if (_audioExts.contains(ext)) {
      return (
        icon: CupertinoIcons.music_note_2,
        color: CupertinoColors.systemPink,
      );
    }
    if (_imageExts.contains(ext)) {
      return (
        icon: CupertinoIcons.photo_fill,
        color: CupertinoColors.systemGreen,
      );
    }
    if (_subtitleExts.contains(ext)) {
      return (
        icon: CupertinoIcons.text_cursor,
        color: CupertinoColors.systemTeal,
      );
    }
    if (_documentExts.contains(ext)) {
      return (
        icon: CupertinoIcons.doc_text_fill,
        color: CupertinoColors.systemBlue,
      );
    }
    if (_archiveExts.contains(ext)) {
      return (
        icon: CupertinoIcons.archivebox_fill,
        color: CupertinoColors.systemOrange,
      );
    }
    if (_codeExts.contains(ext)) {
      return (
        icon: CupertinoIcons.chevron_left_slash_chevron_right,
        color: CupertinoColors.systemIndigo,
      );
    }

    return (icon: CupertinoIcons.doc, color: CupertinoColors.systemGrey);
  }

  Widget _buildFileSubtitle(MediaOrganizeFileItem file) {
    final parts = <String>[];
    if (file.size != null && file.size! > 0) {
      parts.add(controller.formatFileSize(file.size));
    }
    if (file.modifyTime != null) {
      parts.add(controller.formatModifyTime(file.modifyTime));
    }

    return Text(
      parts.join(' · '),
      style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
    );
  }

  Widget _buildTrailing(
    MediaOrganizeFileItem file,
    bool canSelect,
    bool isSelected,
  ) {
    if (controller.isPickerMode && canSelect) {
      return Icon(
        isSelected
            ? CupertinoIcons.checkmark_circle_fill
            : CupertinoIcons.circle,
        color: isSelected
            ? CupertinoColors.systemBlue
            : CupertinoColors.systemGrey3,
        size: 22,
      );
    }

    // Browser 模式：显示操作菜单
    if (!controller.isPickerMode) {
      return PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(
          CupertinoIcons.ellipsis,
          color: CupertinoColors.systemGrey3,
          size: 22,
        ),
        onSelected: (value) {
          switch (value) {
            case 'rename':
              _handleRename(file);
              break;
            case 'scrape':
              _handleScrape(file);
              break;
            case 'recognize':
              _handleRecognize(file);
              break;
            case 'delete':
              _handleDelete(file);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(CupertinoIcons.pencil, size: 20),
                SizedBox(width: 12),
                Text(
                  '重命名',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'scrape',
            child: Row(
              children: [
                Icon(CupertinoIcons.doc_text_search, size: 20),
                SizedBox(width: 12),
                Text(
                  '刮削',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'recognize',
            child: Row(
              children: [
                Icon(CupertinoIcons.sparkles, size: 20),
                SizedBox(width: 12),
                Text(
                  '识别',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.trash,
                  size: 20,
                  color: CupertinoColors.systemRed,
                ),
                SizedBox(width: 12),
                Text(
                  '删除',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_isDirectory(file)) {
      return const Icon(
        CupertinoIcons.chevron_right,
        color: CupertinoColors.systemGrey3,
        size: 18,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildSkeletonList() {
    return Skeletonizer(
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.systemGrey5,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Bone.icon(size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(words: 2),
                      SizedBox(height: 2),
                      Bone.text(words: 1),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoStorageView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            controller.errorText.value ?? '未找到存储配置',
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: controller.retryLoadStorages,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            controller.errorText.value ?? '加载失败',
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: controller.loadFiles,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.folder,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchKeyword.value.isNotEmpty ? '未找到匹配的文件' : '文件夹为空',
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerBottomBar(BuildContext context) {
    return Obx(() {
      final count = FileManagerPickerService.selectedCount;
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground,
          border: Border(
            top: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  count > 0 ? '已选择 $count 项' : '请选择文件',
                  style: TextStyle(
                    fontSize: 15,
                    color: count > 0
                        ? CupertinoColors.label
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                onPressed: count > 0
                    ? () => FileManagerPickerService.confirm()
                    : null,
                child: const Text('确认', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _handleRename(MediaOrganizeFileItem file) {
    // TODO: 后续实现重命名
  }

  Future<void> _handleScrape(MediaOrganizeFileItem file) async {
    final displayName = file.name ?? file.basename ?? '该文件';
    final isDir = _isDirectory(file);
    final confirmed = await showCupertinoDialog<bool>(
      context: Get.context!,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('确认刮削'),
        content: Text(
          isDir ? '确定要对文件夹「$displayName」执行刮削吗？' : '确定要对文件「$displayName」执行刮削吗？',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('刮削'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await controller.scrapeFile(file);
    if (success) {
      ToastUtil.success('刮削任务已提交');
    } else {
      ToastUtil.error('刮削失败');
    }
  }

  void _handleRecognize(MediaOrganizeFileItem file) {
    if (!Get.context!.mounted) return;
    FileRecognizeResultSheet.show(
      Get.context!,
      file: file,
      recognizeFuture: controller.recognizeFile,
    );
  }

  Future<void> _handleDelete(MediaOrganizeFileItem file) async {
    final displayName = file.name ?? file.basename ?? '该文件';
    final isDir = _isDirectory(file);
    final confirmed = await showCupertinoDialog<bool>(
      context: Get.context!,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: Text(
          isDir
              ? '确定要删除文件夹「$displayName」吗？此操作不可恢复。'
              : '确定要删除文件「$displayName」吗？此操作不可恢复。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await controller.deleteFile(file);
    if (success) {
      ToastUtil.success('已删除');
    } else {
      ToastUtil.error('删除失败');
    }
  }
}
