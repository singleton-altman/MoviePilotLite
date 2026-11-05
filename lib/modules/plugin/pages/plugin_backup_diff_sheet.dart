import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_backup_diff.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_backup_models.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

Future<void> showPluginBackupDiffSheet({
  required BuildContext context,
  required PluginBackupFile left,
  required PluginBackupFile right,
}) {
  final palette = DashboardPalette.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    isDismissible: true,
    showDragHandle: false,
    backgroundColor: palette.pageBackground,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.42,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: PluginBackupDiffSheet(
            left: left,
            right: right,
            scrollController: scrollController,
          ),
        );
      },
    ),
  );
}

class PluginBackupDiffSheet extends StatefulWidget {
  const PluginBackupDiffSheet({
    super.key,
    required this.left,
    required this.right,
    this.scrollController,
  });

  final PluginBackupFile left;
  final PluginBackupFile right;
  final ScrollController? scrollController;

  @override
  State<PluginBackupDiffSheet> createState() => _PluginBackupDiffSheetState();
}

class _PluginBackupDiffSheetState extends State<PluginBackupDiffSheet> {
  final _controller = Get.find<PluginController>();
  late final PluginBackupDiffResult _diff;
  late final String _leftTitle;
  late final String _rightTitle;
  final Set<String> _selectedIds = <String>{};
  PluginBackupDiffKind? _filter;

  @override
  void initState() {
    super.initState();
    _controller.restoreProgress.value = null;
    final ordered = widget.left.createdAt.isAfter(widget.right.createdAt)
        ? (left: widget.right, right: widget.left)
        : (left: widget.left, right: widget.right);
    _leftTitle = _backupTitle(ordered.left);
    _rightTitle = _backupTitle(ordered.right);
    _diff = computePluginBackupDiff(
      left: ordered.left.plugins,
      right: ordered.right.plugins,
      leftLabel: _leftTitle,
      rightLabel: _rightTitle,
    );
    for (final entry in _diff.entries) {
      if (entry.kind == PluginBackupDiffKind.added ||
          entry.kind == PluginBackupDiffKind.changed) {
        final item = entry.installCandidate;
        if (item != null && (item.repoUrl ?? '').trim().isNotEmpty) {
          _selectedIds.add(entry.id);
        }
      }
    }
  }

  @override
  void dispose() {
    if (!_controller.isRestoring.value) {
      _controller.restoreProgress.value = null;
    }
    super.dispose();
  }

  String _backupTitle(PluginBackupFile backup) {
    final t = backup.createdAt;
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
    if (backup.auto) return '自动 · $stamp';
    if (backup.imported) return '导入 · $stamp';
    return stamp;
  }

  List<PluginBackupDiffEntry> get _visibleEntries {
    final filter = _filter;
    if (filter == null) {
      return _diff.entries
          .where((e) => e.kind != PluginBackupDiffKind.same)
          .toList(growable: false);
    }
    return _diff.ofKind(filter);
  }

  Future<void> _installSelected() async {
    if (_selectedIds.isEmpty) return;
    final byId = <String, PluginItem>{};
    for (final entry in _diff.entries) {
      if (!_selectedIds.contains(entry.id)) continue;
      final item = entry.installCandidate;
      if (item == null) continue;
      if ((item.repoUrl ?? '').trim().isEmpty) continue;
      byId[entry.id] = item;
    }
    if (byId.isEmpty) {
      ToastUtil.info('所选插件缺少仓库地址，无法安装');
      return;
    }
    try {
      await _controller.restorePlugins(byId.values.toList(growable: false));
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final visible = _visibleEntries;

    return Material(
      color: palette.pageBackground,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.faintText.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '备份对比',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: palette.titleText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_leftTitle  →  $_rightTitle',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: palette.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_controller.isRestoring.value) return;
                      Get.back();
                    },
                    icon: Icon(Icons.close_rounded, color: palette.mutedText),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    palette: palette,
                    label: '差异 ${_diff.addedCount + _diff.removedCount + _diff.changedCount}',
                    selected: _filter == null,
                    color: palette.primary,
                    onTap: () => setState(() => _filter = null),
                  ),
                  _FilterChip(
                    palette: palette,
                    label: '新增 ${_diff.addedCount}',
                    selected: _filter == PluginBackupDiffKind.added,
                    color: palette.successAccent,
                    onTap: () => setState(
                      () => _filter = PluginBackupDiffKind.added,
                    ),
                  ),
                  _FilterChip(
                    palette: palette,
                    label: '缺失 ${_diff.removedCount}',
                    selected: _filter == PluginBackupDiffKind.removed,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () => setState(
                      () => _filter = PluginBackupDiffKind.removed,
                    ),
                  ),
                  _FilterChip(
                    palette: palette,
                    label: '变更 ${_diff.changedCount}',
                    selected: _filter == PluginBackupDiffKind.changed,
                    color: palette.warningAccent,
                    onTap: () => setState(
                      () => _filter = PluginBackupDiffKind.changed,
                    ),
                  ),
                  _FilterChip(
                    palette: palette,
                    label: '相同 ${_diff.sameCount}',
                    selected: _filter == PluginBackupDiffKind.same,
                    color: palette.mutedText,
                    onTap: () =>
                        setState(() => _filter = PluginBackupDiffKind.same),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _MiniTextButton(
                    palette: palette,
                    label: '全选可见',
                    onPressed: () {
                      setState(() {
                        for (final entry in visible) {
                          final item = entry.installCandidate;
                          if (item != null &&
                              (item.repoUrl ?? '').trim().isNotEmpty) {
                            _selectedIds.add(entry.id);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _MiniTextButton(
                    palette: palette,
                    label: '清空',
                    onPressed: () => setState(_selectedIds.clear),
                  ),
                  const Spacer(),
                  Text(
                    '已选 ${_selectedIds.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final restoring = _controller.isRestoring.value;
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      '当前筛选下没有条目',
                      style: TextStyle(color: palette.mutedText),
                    ),
                  );
                }
                return ListView.separated(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = visible[index];
                    final item = entry.installCandidate;
                    final hasRepo =
                        item != null && (item.repoUrl ?? '').trim().isNotEmpty;
                    return _DiffEntryCard(
                      palette: palette,
                      entry: entry,
                      selected: _selectedIds.contains(entry.id),
                      interactive: !restoring && hasRepo,
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            _selectedIds.add(entry.id);
                          } else {
                            _selectedIds.remove(entry.id);
                          }
                        });
                      },
                    );
                  },
                );
              }),
            ),
            Obx(() {
              final restoring = _controller.isRestoring.value;
              final progress = _controller.restoreProgress.value;
              return Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomSafe),
                decoration: BoxDecoration(
                  color: palette.pageBackground,
                  border: Border(top: BorderSide(color: palette.tileBorder)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (progress != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.done ? 1 : progress.ratio,
                          minHeight: 6,
                          backgroundColor: palette.primary.withValues(
                            alpha: 0.12,
                          ),
                          color: progress.done && progress.failedCount > 0
                              ? Theme.of(context).colorScheme.error
                              : palette.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        progress.done
                            ? '完成 成功 ${progress.successCount} / 失败 ${progress.failedCount}'
                            : '正在安装 ${progress.currentIndex + 1}/${progress.total}'
                                  '${progress.currentName.isEmpty ? '' : '：${progress.currentName}'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.mutedText,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: restoring || _selectedIds.isEmpty
                            ? null
                            : _installSelected,
                        icon: restoring
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.install_desktop_rounded),
                        label: Text(
                          restoring
                              ? '安装中…'
                              : '安装选中（${_selectedIds.length}）',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.palette,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final DashboardPaletteData palette;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Color.alphaBlend(
            color.withValues(alpha: palette.isDark ? 0.28 : 0.14),
            palette.pageBackgroundAlt,
          )
        : palette.surfaceAlt;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.5)
                  : palette.tileBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? color : palette.titleText,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTextButton extends StatelessWidget {
  const _MiniTextButton({
    required this.palette,
    required this.label,
    required this.onPressed,
  });

  final DashboardPaletteData palette;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.surfaceAlt,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.tileBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.titleText,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiffEntryCard extends StatelessWidget {
  const _DiffEntryCard({
    required this.palette,
    required this.entry,
    required this.selected,
    required this.interactive,
    required this.onChanged,
  });

  final DashboardPaletteData palette;
  final PluginBackupDiffEntry entry;
  final bool selected;
  final bool interactive;
  final ValueChanged<bool> onChanged;

  ({String label, Color color}) get _kindMeta {
    switch (entry.kind) {
      case PluginBackupDiffKind.added:
        return (label: '新增', color: palette.successAccent);
      case PluginBackupDiffKind.removed:
        return (label: '缺失', color: const Color(0xFFEF4444));
      case PluginBackupDiffKind.changed:
        return (label: '变更', color: palette.warningAccent);
      case PluginBackupDiffKind.same:
        return (label: '相同', color: palette.mutedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = entry.installCandidate;
    final iconUrl = item?.pluginIcon != null && item!.pluginIcon!.isNotEmpty
        ? ImageUtil.convertPluginIconUrl(item.pluginIcon!)
        : '';
    final kind = _kindMeta;
    final hasRepo = item != null && (item.repoUrl ?? '').trim().isNotEmpty;
    final bg = selected
        ? Color.alphaBlend(
            palette.primary.withValues(alpha: palette.isDark ? 0.18 : 0.08),
            palette.pageBackgroundAlt,
          )
        : palette.pageBackgroundAlt;

    return Opacity(
      opacity: hasRepo || selected ? 1 : 0.55,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: interactive ? () => onChanged(!selected) : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? palette.primary.withValues(alpha: 0.5)
                    : palette.tileBorder,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: kind.color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: iconUrl.isEmpty
                                  ? ColoredBox(
                                      color: palette.surfaceAlt,
                                      child: Icon(
                                        Icons.extension_rounded,
                                        color: palette.mutedText,
                                      ),
                                    )
                                  : CachedImage(
                                      imageUrl: iconUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: palette.titleText,
                                        ),
                                      ),
                                    ),
                                    if (interactive)
                                      _SelectDot(
                                        palette: palette,
                                        selected: selected,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _Tag(
                                      palette: palette,
                                      label: kind.label,
                                      color: kind.color,
                                    ),
                                    if (entry.kind ==
                                        PluginBackupDiffKind.changed)
                                      _Tag(
                                        palette: palette,
                                        label:
                                            '${entry.leftVersion.isEmpty ? '—' : entry.leftVersion} → ${entry.rightVersion.isEmpty ? '—' : entry.rightVersion}',
                                        color: palette.coolAccent,
                                      )
                                    else if ((item?.pluginVersion ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      _Tag(
                                        palette: palette,
                                        label: item!.pluginVersion!.trim(),
                                        color: palette.coolAccent,
                                      ),
                                    if (!hasRepo)
                                      _Tag(
                                        palette: palette,
                                        label: '无仓库',
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.palette, required this.selected});

  final DashboardPaletteData palette;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? palette.primary : Colors.transparent,
        border: Border.all(
          color: selected
              ? palette.primary
              : palette.mutedText.withValues(alpha: 0.35),
          width: selected ? 0 : 1.5,
        ),
      ),
      child: selected
          ? Icon(
              CupertinoIcons.checkmark_alt,
              size: 13,
              color: palette.inverseText,
            )
          : null,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.palette,
    required this.label,
    required this.color,
  });

  final DashboardPaletteData palette;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
