import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';

import '../controllers/file_manager_controller.dart';

/// 文件列表项 Widget - Plain 样式
class FileItemWidget extends StatelessWidget {
  final MediaOrganizeFileItem file;
  final FileManagerController controller;

  const FileItemWidget({
    super.key,
    required this.file,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDir = file.type == 'dir';
    final canSelect =
        controller.isPickerMode &&
        ((isDir && controller.allowDirSelection) ||
            (!isDir && controller.allowFileSelection));

    return Obx(() {
      final isSelected = controller.isSelected(file);

      return GestureDetector(
        onTap: () {
          if (controller.isPickerMode && canSelect) {
            controller.toggleSelection(file);
          } else if (isDir) {
            controller.enterDirectory(file);
          }
        },
        onLongPress: canSelect ? () => controller.toggleSelection(file) : null,
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

  /// 构建文件图标 - Plain 样式
  Widget _buildFileIcon(MediaOrganizeFileItem file) {
    final isDir = file.type == 'dir';
    final iconColor = isDir
        ? CupertinoColors.systemBlue
        : _getFileIconColor(file.extension);

    return Icon(
      isDir ? CupertinoIcons.folder : _getFileIcon(file.extension),
      color: iconColor,
      size: 26,
    );
  }

  /// 获取文件图标
  IconData _getFileIcon(String? extension) {
    if (extension == null) return CupertinoIcons.doc;
    final ext = extension.toLowerCase();
    if (['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(ext)) {
      return CupertinoIcons.film;
    }
    if (['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(ext)) {
      return CupertinoIcons.music_note;
    }
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return CupertinoIcons.photo;
    }
    if (['txt', 'md', 'doc', 'docx', 'pdf'].contains(ext)) {
      return CupertinoIcons.doc_text;
    }
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return CupertinoIcons.archivebox;
    }
    return CupertinoIcons.doc;
  }

  /// 获取文件图标颜色
  Color _getFileIconColor(String? extension) {
    if (extension == null) return CupertinoColors.systemGrey;
    final ext = extension.toLowerCase();
    if (['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(ext)) {
      return CupertinoColors.systemPurple;
    }
    if (['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(ext)) {
      return CupertinoColors.systemPink;
    }
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      return CupertinoColors.systemGreen;
    }
    if (['txt', 'md', 'doc', 'docx', 'pdf'].contains(ext)) {
      return CupertinoColors.systemBlue;
    }
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return CupertinoColors.systemOrange;
    }
    return CupertinoColors.systemGrey;
  }

  /// 构建文件副标题
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

  /// 构建尾部操作区
  Widget _buildTrailing(
    MediaOrganizeFileItem file,
    bool canSelect,
    bool isSelected,
  ) {
    // Picker 模式且可以选择
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

    // 文件夹显示进入箭头
    if (file.type == 'dir') {
      return const Icon(
        CupertinoIcons.chevron_right,
        color: CupertinoColors.systemGrey3,
        size: 18,
      );
    } else {
      return SizedBox(
        width: 22,
        height: 22,
        child: Icon(CupertinoIcons.ellipsis),
      );
    }
  }
}
