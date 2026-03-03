import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

import '../../recognize/models/recognize_model.dart';
import '../../recognize/widgets/recognize_media_detail_widget.dart';

/// 文件识别结果 BottomSheet - 在页面内执行识别，显示 fake progress，完成后展示结果
class FileRecognizeResultSheet extends StatefulWidget {
  const FileRecognizeResultSheet({
    super.key,
    required this.file,
    required this.recognizeFuture,
  });

  final MediaOrganizeFileItem file;
  final Future<RecognizeResponse?> Function(MediaOrganizeFileItem)
  recognizeFuture;

  static Future<void> show(
    BuildContext context, {
    required MediaOrganizeFileItem file,
    required Future<RecognizeResponse?> Function(MediaOrganizeFileItem)
    recognizeFuture,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FileRecognizeResultSheet(
        file: file,
        recognizeFuture: recognizeFuture,
      ),
    );
  }

  @override
  State<FileRecognizeResultSheet> createState() =>
      _FileRecognizeResultSheetState();
}

class _FileRecognizeResultSheetState extends State<FileRecognizeResultSheet>
    with SingleTickerProviderStateMixin {
  RecognizeResponse? _response;
  bool _isLoading = true;
  double _fakeProgress = 0;

  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2200),
        )..addListener(() {
          if (mounted && _isLoading && _response == null) {
            setState(() => _fakeProgress = _progressController.value * 0.92);
          }
        });
    _startRecognize();
  }

  Future<void> _startRecognize() async {
    _progressController.forward();

    final response = await widget.recognizeFuture(widget.file);

    if (!mounted) return;
    _progressController.stop();
    setState(() {
      _fakeProgress = 1.0;
      _isLoading = false;
      _response = response;
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: _isLoading ? '识别中...' : '识别结果'),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _fakeProgress,
                  minHeight: 3,
                  backgroundColor: CupertinoColors.systemGrey5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Section(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                CupertinoActivityIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '正在识别 ${widget.file.name ?? widget.file.basename ?? "..."}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_response == null) {
      return Section(
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 48,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 12),
              const Text(
                '识别失败，请稍后重试',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final media = _response!.media_info;
    if (media != null) {
      return RecognizeMediaDetailWidget(media: media);
    }

    // 无 media_info，显示原始结果
    final meta = _response!.meta_info;
    final rawText = _formatRawResponse(_response!);
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (meta != null) ...[
            _buildMetaRow('标题', meta.title),
            _buildMetaRow('副标题', meta.subtitle),
            _buildMetaRow('类型', meta.type),
            _buildMetaRow('年份', meta.year),
            _buildMetaRow('季', meta.total_season?.toString()),
            _buildMetaRow('集', meta.total_episode?.toString()),
          ],
          if (rawText != null && rawText.isNotEmpty) ...[
            if (meta != null) const SizedBox(height: 12),
            const Text(
              '原始结果',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.systemGrey4),
              ),
              child: SelectableText(
                rawText,
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
          if ((meta == null || _isEmptyMeta(meta)) &&
              (rawText == null || rawText.isEmpty))
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '暂无识别结果',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  bool _isEmptyMeta(MetaInfo meta) {
    return (meta.title == null || meta.title!.trim().isEmpty) &&
        (meta.subtitle == null || meta.subtitle!.trim().isEmpty) &&
        (meta.type == null || meta.type!.trim().isEmpty);
  }

  String? _formatRawResponse(RecognizeResponse r) {
    try {
      final map = r.toJson();
      if (map.isEmpty) return null;
      return const JsonEncoder.withIndent('  ').convert(map);
    } catch (_) {
      return null;
    }
  }
}
