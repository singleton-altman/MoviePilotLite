import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';
import 'package:moviepilot_mobile/widgets/custom_button.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

/// 文件重命名 BottomSheet
class FileRenameSheet extends StatefulWidget {
  const FileRenameSheet({
    super.key,
    required this.file,
    required this.isDir,
    required this.getRecognizedName,
    required this.renameFile,
  });

  final MediaOrganizeFileItem file;
  final bool isDir;
  final Future<String?> Function(MediaOrganizeFileItem) getRecognizedName;
  final Future<bool> Function(
    MediaOrganizeFileItem, {
    required String newName,
    bool renameDirFiles,
  })
  renameFile;

  static Future<void> show(
    BuildContext context, {
    required MediaOrganizeFileItem file,
    required bool isDir,
    required Future<String?> Function(MediaOrganizeFileItem) getRecognizedName,
    required Future<bool> Function(
      MediaOrganizeFileItem, {
      required String newName,
      bool renameDirFiles,
    })
    renameFile,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FileRenameSheet(
        file: file,
        isDir: isDir,
        getRecognizedName: getRecognizedName,
        renameFile: renameFile,
      ),
    );
  }

  @override
  State<FileRenameSheet> createState() => _FileRenameSheetState();
}

class _FileRenameSheetState extends State<FileRenameSheet> {
  late TextEditingController _nameController;
  bool _isRecognizing = false;
  bool _isSubmitting = false;
  bool _renameDirFiles = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.file.name ?? widget.file.basename ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onAutoRecognize() async {
    setState(() => _isRecognizing = true);
    final name = await widget.getRecognizedName(widget.file);
    if (mounted) {
      setState(() => _isRecognizing = false);
      if (name != null && name.isNotEmpty) {
        _nameController.text = name;
      } else {
        ToastUtil.info('未能识别到建议名称');
      }
    }
  }

  Future<void> _onConfirm() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ToastUtil.info('请输入新名称');
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await widget.renameFile(
      widget.file,
      newName: newName,
      renameDirFiles: widget.isDir && _renameDirFiles,
    );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ToastUtil.success('重命名成功');
        Navigator.of(context).pop();
      } else {
        ToastUtil.error('重命名失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      header: SectionHeader(title: '重命名'),
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Section(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '新名称',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _nameController,
                placeholder: '请输入名称',
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: CupertinoColors.systemGrey5,
                  onPressed: _isRecognizing ? null : _onAutoRecognize,
                  child: _isRecognizing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CupertinoActivityIndicator(),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.sparkles, size: 18),
                            SizedBox(width: 8),
                            Text('自动识别名称'),
                          ],
                        ),
                ),
              ),
              if (widget.isDir) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '自动重命名目录内所有媒体文件',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    CupertinoSwitch(
                      value: _renameDirFiles,
                      onChanged: (v) => setState(() => _renameDirFiles = v),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              CustomButton(
                text: '确认重命名',
                icon: CupertinoIcons.checkmark,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
