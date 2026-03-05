import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';

/// TrashClean 清理进度/结果 Bottom Sheet
class PluginCleanProgressSheet extends StatefulWidget {
  const PluginCleanProgressSheet({required this.controller});
  final DynamicFormController controller;

  @override
  State<PluginCleanProgressSheet> createState() =>
      PluginCleanProgressSheetState();
}

class PluginCleanProgressSheetState extends State<PluginCleanProgressSheet> {
  bool _loading = true;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _doClean();
  }

  Future<void> _doClean() async {
    final result = await widget.controller.triggerClean();
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _loading = false;
        _error = '清理请求失败，请稍后重试';
      });
      return;
    }
    final progress = await widget.controller.fetchCleanProgress();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result;
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(context),
            _buildTitle(context),
            const Divider(height: 1),
            if (_loading) _buildLoading(context),
            if (_error != null) _buildError(context),
            if (_result != null) Flexible(child: _buildResult(context)),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGrey3,
            context,
          ),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.cleaning_services,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '垃圾清理',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.label,
                context,
              ),
            ),
          ),
          const Spacer(),
          if (!_loading)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () {
                Navigator.of(context).pop();
                widget.controller.load();
              },
              child: const Text('完成', style: TextStyle(fontSize: 15)),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          const SizedBox(height: 16),
          Text(
            '正在清理中...',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            size: 40,
            color: Color(0xFFFF3B30),
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.label,
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final result = _result!;
    final status = result['status']?.toString() ?? '';
    final isSuccess = status == 'success';
    final removedDirs = result['removed_dirs'] as List? ?? [];
    final emptyCount = result['removed_empty_dirs_count'] ?? 0;
    final smallCount = result['removed_small_dirs_count'] ?? 0;
    final reductionCount = result['removed_size_reduction_dirs_count'] ?? 0;
    final totalCount = emptyCount + smallCount + reductionCount;
    final freedSpace = result['total_freed_space'] ?? 0;
    final freedMB = (freedSpace is num && freedSpace > 0)
        ? (freedSpace / (1024 * 1024)).toStringAsFixed(2)
        : '0.00';

    final percent = (_progress?['percent'] as num?)?.toDouble() ?? 100;
    final totalDirs = _progress?['total_dirs'] ?? 0;
    final processedDirs = _progress?['processed_dirs'] ?? 0;
    final startTime = _progress?['start_time']?.toString() ?? '';
    final currentDir = _progress?['current_dir']?.toString() ?? '';

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        // Summary row: text + percent
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                isSuccess
                    ? '清理任务完成！共清理 $totalCount 个目录，释放 ${freedMB}MB 空间'
                    : '清理失败: $status',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondaryLabel,
                    context,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${percent.toInt()}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isSuccess
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: CupertinoDynamicColor.resolve(
              CupertinoColors.systemGrey5,
              context,
            ),
            valueColor: AlwaysStoppedAnimation(
              isSuccess ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
            ),
          ),
        ),
        // Progress detail card
        if (_progress != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemBackground,
                context,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (startTime.isNotEmpty)
                  _buildDetailItem(
                    context,
                    CupertinoIcons.clock,
                    '开始时间',
                    startTime,
                  ),
                _buildDetailItem(
                  context,
                  CupertinoIcons.folder,
                  '总目录数',
                  '$totalDirs',
                ),
                _buildDetailItem(
                  context,
                  CupertinoIcons.folder_fill,
                  '已处理',
                  '$processedDirs',
                ),
                _buildDetailItem(
                  context,
                  Icons.delete_outline,
                  '已清理',
                  '$totalCount',
                ),
                if (currentDir.isNotEmpty)
                  _buildDetailItem(
                    context,
                    CupertinoIcons.folder_open,
                    '当前处理',
                    currentDir,
                  ),
              ],
            ),
          ),
        ],
        // Stats chips
        if (isSuccess) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                context,
                '空目录',
                emptyCount,
                const Color(0xFF007AFF),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                context,
                '小目录',
                smallCount,
                const Color(0xFFFF9500),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                context,
                '缩减目录',
                reductionCount,
                const Color(0xFFAF52DE),
              ),
            ],
          ),
        ],
        // Removed dirs list
        if (removedDirs.isNotEmpty) ...[
          const SizedBox(height: 16),
          CupertinoListSection.insetGrouped(
            margin: EdgeInsets.zero,
            header: Text(
              '已清理目录',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
            ),
            children: removedDirs.map((dir) {
              final item = dir is Map<String, dynamic>
                  ? dir
                  : <String, dynamic>{};
              final path = item['path']?.toString() ?? '';
              final type = item['type']?.toString() ?? '';
              final dirName =
                  path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? path;

              return CupertinoListTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.folder_delete,
                    size: 16,
                    color: Color(0xFFFF3B30),
                  ),
                ),
                title: Text(
                  dirName,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E8E93),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _typeLabel(type),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (removedDirs.isEmpty && isSuccess) ...[
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 40,
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.tertiaryLabel,
                    context,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '没有需要清理的目录',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.secondaryLabel,
                      context,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondaryLabel,
            context,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.secondaryLabel,
              context,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.label,
                context,
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    dynamic count,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'empty':
        return '空目录';
      case 'small':
        return '小目录';
      case 'size_reduction':
        return '体积缩减';
      default:
        return type;
    }
  }
}
