import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_backup_models.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/pages/plugin_backup_diff_sheet.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showPluginBackupCenterSheet(BuildContext context) async {
  final palette = DashboardPalette.of(context);
  final appService = Get.find<AppService>();
  appService.hideBottomNavBar.value = true;
  await WidgetsBinding.instance.endOfFrame;
  try {
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
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
        minChildSize: 0.4,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: PluginBackupCenterSheet(scrollController: scrollController),
          );
        },
      ),
    );
  } finally {
    appService.hideBottomNavBar.value = false;
  }
}

Future<void> showPluginBackupSelectSheet(
  BuildContext context,
  PluginBackupFile backup,
) {
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
          child: PluginBackupSelectSheet(
            backup: backup,
            scrollController: scrollController,
          ),
        );
      },
    ),
  );
}

class PluginBackupCenterSheet extends StatefulWidget {
  const PluginBackupCenterSheet({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<PluginBackupCenterSheet> createState() =>
      _PluginBackupCenterSheetState();
}

class _PluginBackupCenterSheetState extends State<PluginBackupCenterSheet> {
  final _controller = Get.find<PluginController>();

  bool _loadingList = true;
  bool _openingBackup = false;
  String? _errorText;
  List<PluginBackupListItem> _backups = const [];
  bool _diffMode = false;
  String? _diffFirstPath;

  @override
  void initState() {
    super.initState();
    _reloadBackupList();
  }

  Future<void> _reloadBackupList() async {
    setState(() {
      _loadingList = true;
      _errorText = null;
    });
    try {
      final list = await _controller.listPluginBackups();
      if (!mounted) return;
      setState(() {
        _backups = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = '读取本地备份失败';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingList = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final palette = DashboardPalette.of(context);

    return Material(
      color: palette.pageBackground,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _SheetHeader(
              palette: palette,
              title: '备份中心',
              subtitle: '本地插件清单 · 导入导出',
              onClose: () => Get.back(),
            ),
            Expanded(
              child: Obx(() {
                final backingUp = _controller.isBackingUp.value;
                final busy = backingUp || _openingBackup;
                return ListView(
                  controller: widget.scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    20 + bottomSafe + bottomInset,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ActionTile(
                            palette: palette,
                            icon: Icons.backup_rounded,
                            label: backingUp ? '备份中' : '立即备份',
                            color: palette.primary,
                            loading: backingUp,
                            onTap: busy ? null : _backupNow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionTile(
                            palette: palette,
                            icon: Icons.file_open_rounded,
                            label: _openingBackup ? '读取中' : '导入 JSON',
                            color: palette.coolAccent,
                            outlined: true,
                            loading: _openingBackup,
                            onTap: busy ? null : _importFromFile,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AutoBackupSwitch(
                      palette: palette,
                      enabled: _controller.autoBackupEnabled.value,
                      onChanged: busy
                          ? null
                          : (value) async {
                              await _controller.setAutoBackupEnabled(value);
                              if (value && mounted) {
                                await _reloadBackupList();
                              }
                            },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          '本地备份',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: palette.titleText,
                          ),
                        ),
                        const Spacer(),
                        if (!_loadingList && _backups.length >= 2)
                          _MiniActionChip(
                            palette: palette,
                            label: _diffMode
                                ? (_diffFirstPath == null
                                      ? '选择第 1 份'
                                      : '选择第 2 份')
                                : '对比',
                            selected: _diffMode,
                            onTap: busy
                                ? null
                                : () {
                                    setState(() {
                                      if (_diffMode) {
                                        _diffMode = false;
                                        _diffFirstPath = null;
                                      } else {
                                        _diffMode = true;
                                        _diffFirstPath = null;
                                      }
                                    });
                                  },
                          ),
                        if (!_loadingList && _backups.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${_backups.length} 份',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: palette.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_diffMode) ...[
                      const SizedBox(height: 8),
                      _InfoBanner(
                        palette: palette,
                        icon: Icons.compare_arrows_rounded,
                        text: _diffFirstPath == null
                            ? '请点选第一份备份作为基准（通常为较旧）'
                            : '再点选第二份备份开始对比',
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (_loadingList)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: AppLoadingCenter.small(message: '读取本地备份…'),
                      )
                    else if (_errorText != null)
                      _InfoBanner(
                        palette: palette,
                        icon: Icons.error_outline_rounded,
                        text: _errorText!,
                        accent: Theme.of(context).colorScheme.error,
                      )
                    else if (_backups.isEmpty)
                      _EmptyBackupCard(palette: palette)
                    else
                      for (var i = 0; i < _backups.length; i++) ...[
                        _BackupFileCard(
                          palette: palette,
                          item: _backups[i],
                          selected: _diffMode &&
                              _diffFirstPath == _backups[i].filePath,
                          onTap: busy
                              ? () {}
                              : () => _onBackupTap(_backups[i]),
                          onRestore: busy
                              ? () {}
                              : () => _openBackup(_backups[i].filePath),
                          onExport: () => _exportBackup(_backups[i]),
                          onDelete: () => _deleteBackup(_backups[i]),
                          onCompare: _backups.length < 2
                              ? null
                              : () => _startDiffWith(_backups[i]),
                        ),
                        if (i != _backups.length - 1)
                          const SizedBox(height: 10),
                      ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backupNow() async {
    try {
      final saved = await _controller.backupInstalledPlugins();
      if (!mounted) return;
      ToastUtil.success('已备份 ${saved.plugins.length} 个插件');
      await _reloadBackupList();
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _exportBackup(PluginBackupListItem item) async {
    try {
      final status = await _controller.exportPluginBackup(item.filePath);
      if (status == ShareResultStatus.success) {
        ToastUtil.success('导出成功');
      }
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _openSelectSheet(PluginBackupFile backup) async {
    if (!mounted) return;
    await showPluginBackupSelectSheet(context, backup);
  }

  Future<void> _openBackup(String path) async {
    setState(() {
      _openingBackup = true;
      _errorText = null;
    });
    try {
      final backup = await _controller.readPluginBackup(path);
      if (!mounted) return;
      setState(() {
        _openingBackup = false;
      });
      await _openSelectSheet(backup);
    } catch (_) {
      if (!mounted) return;
      ToastUtil.error('读取备份失败');
      setState(() {
        _openingBackup = false;
      });
    }
  }

  void _onBackupTap(PluginBackupListItem item) {
    if (_diffMode) {
      _pickDiffTarget(item);
      return;
    }
    _openBackup(item.filePath);
  }

  void _startDiffWith(PluginBackupListItem item) {
    setState(() {
      _diffMode = true;
      _diffFirstPath = item.filePath;
    });
  }

  Future<void> _pickDiffTarget(PluginBackupListItem item) async {
    final first = _diffFirstPath;
    if (first == null) {
      setState(() {
        _diffFirstPath = item.filePath;
      });
      return;
    }
    if (first == item.filePath) {
      ToastUtil.info('请选择另一份备份');
      return;
    }
    await _openDiff(first, item.filePath);
  }

  Future<void> _openDiff(String leftPath, String rightPath) async {
    setState(() {
      _openingBackup = true;
      _errorText = null;
    });
    try {
      final left = await _controller.readPluginBackup(leftPath);
      final right = await _controller.readPluginBackup(rightPath);
      if (!mounted) return;
      setState(() {
        _openingBackup = false;
        _diffMode = false;
        _diffFirstPath = null;
      });
      await showPluginBackupDiffSheet(
        context: context,
        left: left,
        right: right,
      );
    } catch (_) {
      if (!mounted) return;
      ToastUtil.error('读取备份失败');
      setState(() {
        _openingBackup = false;
      });
    }
  }

  Future<void> _importFromFile() async {
    setState(() {
      _openingBackup = true;
      _errorText = null;
    });
    try {
      final result = await fp.FilePicker.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      final PluginBackupFile backup;
      if (bytes != null) {
        backup = await _controller.importPluginBackup(
          bytes: bytes,
          fileName: file.name,
        );
      } else if (file.path != null && file.path!.isNotEmpty) {
        backup = await _controller.importPluginBackup(path: file.path);
      } else {
        ToastUtil.error('无法读取所选文件');
        return;
      }
      if (!mounted) return;
      ToastUtil.success('已导入并保存 ${backup.plugins.length} 个插件备份');
      await _reloadBackupList();
      if (!mounted) return;
      await _openSelectSheet(backup);
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _openingBackup = false;
        });
      }
    }
  }

  Future<void> _deleteBackup(PluginBackupListItem item) async {
    final confirmed = await Get.dialog<bool>(
      _DeleteBackupDialog(item: item),
      barrierDismissible: true,
    );
    if (confirmed != true) return;
    await _controller.deletePluginBackup(item.filePath);
    await _reloadBackupList();
  }
}

class PluginBackupSelectSheet extends StatefulWidget {
  const PluginBackupSelectSheet({
    super.key,
    required this.backup,
    this.scrollController,
  });

  final PluginBackupFile backup;
  final ScrollController? scrollController;

  @override
  State<PluginBackupSelectSheet> createState() =>
      _PluginBackupSelectSheetState();
}

class _PluginBackupSelectSheetState extends State<PluginBackupSelectSheet> {
  final _controller = Get.find<PluginController>();
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _controller.restoreProgress.value = null;
    final installedIds = _controller.items.map((e) => e.id).toSet();
    _selectedIds.addAll(
      widget.backup.plugins
          .where(
            (e) =>
                (e.repoUrl ?? '').trim().isNotEmpty &&
                !installedIds.contains(e.id),
          )
          .map((e) => e.id),
    );
  }

  @override
  void dispose() {
    if (!_controller.isRestoring.value) {
      _controller.restoreProgress.value = null;
    }
    super.dispose();
  }

  Future<void> _startRestore() async {
    if (_selectedIds.isEmpty) return;
    final selected = widget.backup.plugins
        .where((e) => _selectedIds.contains(e.id))
        .toList();
    try {
      await _controller.restorePlugins(selected);
    } catch (e) {
      ToastUtil.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final palette = DashboardPalette.of(context);
    final selectable = widget.backup.plugins
        .where((e) => (e.repoUrl ?? '').trim().isNotEmpty)
        .toList();

    return Material(
      color: palette.pageBackground,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _SheetHeader(
              palette: palette,
              title: '选择要恢复的插件',
              onClose: () {
                if (_controller.isRestoring.value) return;
                Get.back();
              },
            ),
            Expanded(
              child: Obx(() {
                final localById = <String, PluginItem>{
                  for (final item in _controller.items) item.id: item,
                };
                final restoring = _controller.isRestoring.value;
                final progress = _controller.restoreProgress.value;
                final installingId =
                    restoring && progress != null && !progress.done
                    ? progress.currentId
                    : '';
                return ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  children: [
                    Row(
                      children: [
                        _ChipButton(
                          palette: palette,
                          label: '全选',
                          onPressed: restoring || selectable.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _selectedIds
                                      ..clear()
                                      ..addAll(selectable.map((e) => e.id));
                                  });
                                },
                        ),
                        const SizedBox(width: 8),
                        _ChipButton(
                          palette: palette,
                          label: '清空',
                          onPressed: restoring
                              ? null
                              : () => setState(_selectedIds.clear),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primary.withValues(
                              alpha: palette.isDark ? 0.18 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '已选 ${_selectedIds.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < widget.backup.plugins.length; i++) ...[
                      _PluginSelectCard(
                        palette: palette,
                        item: widget.backup.plugins[i],
                        selected: _selectedIds.contains(
                          widget.backup.plugins[i].id,
                        ),
                        localItem: localById[widget.backup.plugins[i].id],
                        installing:
                            installingId == widget.backup.plugins[i].id,
                        hasRepo:
                            (widget.backup.plugins[i].repoUrl ?? '')
                                .trim()
                                .isNotEmpty,
                        interactive: !restoring,
                        onChanged: (value) {
                          setState(() {
                            if (value) {
                              _selectedIds.add(widget.backup.plugins[i].id);
                            } else {
                              _selectedIds.remove(
                                widget.backup.plugins[i].id,
                              );
                            }
                          });
                        },
                      ),
                      if (i != widget.backup.plugins.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }),
            ),
            Obx(() {
              final restoring = _controller.isRestoring.value;
              final progress = _controller.restoreProgress.value;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.pageBackgroundAlt,
                  border: Border(top: BorderSide(color: palette.tileBorder)),
                  boxShadow: [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomSafe),
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
                              ? '完成 ${progress.total}/${progress.total}'
                              : '正在安装 ${progress.currentIndex + 1}/${progress.total}'
                                    '${progress.currentName.isEmpty ? '' : '：${progress.currentName}'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.mutedText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '成功 ${progress.successCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: palette.successAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '失败 ${progress.failedCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: progress.failedCount > 0
                                    ? Theme.of(context).colorScheme.error
                                    : palette.mutedText,
                              ),
                            ),
                            if (progress.done) ...[
                              const Spacer(),
                              Text(
                                '已完成',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: palette.titleText,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      _PrimaryActionButton(
                        palette: palette,
                        icon: Icons.install_desktop_rounded,
                        label: restoring
                            ? '恢复中…'
                            : progress != null && progress.done
                            ? '再次安装（${_selectedIds.length}）'
                            : '安装选中（${_selectedIds.length}）',
                        loading: restoring,
                        onPressed: restoring || _selectedIds.isEmpty
                            ? null
                            : _startRestore,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.palette,
    required this.title,
    required this.onClose,
    this.subtitle,
  });

  final DashboardPaletteData palette;
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: palette.titleText,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: palette.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _HeaderIconButton(
                palette: palette,
                icon: CupertinoIcons.xmark,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.palette,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.loading = false,
  });

  final DashboardPaletteData palette;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool outlined;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final bg = outlined
        ? palette.pageBackgroundAlt
        : Color.alphaBlend(
            color.withValues(alpha: palette.isDark ? 0.28 : 0.14),
            palette.pageBackgroundAlt,
          );
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: outlined
                  ? palette.tileBorder
                  : color.withValues(alpha: enabled ? 0.4 : 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: palette.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: loading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: enabled ? palette.titleText : palette.faintText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoBackupSwitch extends StatelessWidget {
  const _AutoBackupSwitch({
    required this.palette,
    required this.enabled,
    required this.onChanged,
  });

  final DashboardPaletteData palette;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: palette.pageBackgroundAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                palette.successAccent.withValues(
                  alpha: palette.isDark ? 0.26 : 0.12,
                ),
                palette.pageBackgroundAlt,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.autorenew_rounded,
              size: 17,
              color: palette.successAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '每日自动备份',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.titleText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '开启后每天启动 App 自动备份一次',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: palette.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: palette.successAccent,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.palette,
    required this.icon,
    required this.onPressed,
  });

  final DashboardPaletteData palette;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.surfaceAlt.withValues(alpha: palette.isDark ? 0.55 : 0.8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: palette.titleText),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.palette,
    required this.icon,
    required this.text,
    this.accent,
  });

  final DashboardPaletteData palette;
  final IconData icon;
  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? palette.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: palette.bodyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBackupCard extends StatelessWidget {
  const _EmptyBackupCard({required this.palette});

  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: palette.pageBackgroundAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.folder_open_outlined,
              color: palette.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无本地备份',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.titleText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '点上方「立即备份」或「导入 JSON」开始。导出可分享到文件/隔空投送。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: palette.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final DashboardPaletteData palette;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: onPrimary,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: palette.primary.withValues(alpha: 0.28),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.72),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.palette,
    required this.label,
    required this.onPressed,
  });

  final DashboardPaletteData palette;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.tileBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: onPressed == null
                  ? palette.faintText
                  : palette.titleText,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackupFileCard extends StatelessWidget {
  const _BackupFileCard({
    required this.palette,
    required this.item,
    required this.onTap,
    required this.onRestore,
    required this.onExport,
    required this.onDelete,
    this.selected = false,
    this.onCompare,
  });

  final DashboardPaletteData palette;
  final PluginBackupListItem item;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final bool selected;
  final VoidCallback? onCompare;

  static const double _cardHeight = 88;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${item.createdAt.year.toString().padLeft(4, '0')}-'
        '${item.createdAt.month.toString().padLeft(2, '0')}-'
        '${item.createdAt.day.toString().padLeft(2, '0')}';
    final timeLabel =
        '${item.createdAt.hour.toString().padLeft(2, '0')}:'
        '${item.createdAt.minute.toString().padLeft(2, '0')}';
    final accent = selected ? palette.primary : palette.coolAccent;
    final borderColor = selected
        ? palette.primary.withValues(alpha: 0.55)
        : palette.tileBorder;

    final card = Material(
      color: palette.pageBackgroundAlt,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: _cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(width: 4, color: accent),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    accent.withValues(alpha: palette.isDark ? 0.26 : 0.12),
                    palette.pageBackgroundAlt,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selected
                      ? Icons.check_rounded
                      : Icons.inventory_2_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              dateLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.25,
                                height: 1.2,
                                color: palette.titleText,
                              ),
                            ),
                          ),
                          if (item.auto) ...[
                            const SizedBox(width: 8),
                            _BackupMetaChip(
                              palette: palette,
                              icon: Icons.autorenew_rounded,
                              label: '自动',
                              color: palette.successAccent,
                            ),
                          ] else if (item.imported) ...[
                            const SizedBox(width: 8),
                            _BackupMetaChip(
                              palette: palette,
                              icon: Icons.download_rounded,
                              label: '导入',
                              color: palette.warningAccent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _BackupMetaChip(
                            palette: palette,
                            icon: Icons.schedule_rounded,
                            label: timeLabel,
                          ),
                          const SizedBox(width: 6),
                          _BackupMetaChip(
                            palette: palette,
                            icon: Icons.extension_rounded,
                            label: '${item.pluginCount} 插件',
                            color: accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.compare_arrows_rounded
                    : CupertinoIcons.chevron_right,
                size: 15,
                color: selected ? accent : palette.faintText,
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );

    return CupertinoContextMenu.builder(
      enableHapticFeedback: true,
      actions: [
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.share,
          onPressed: () {
            Navigator.of(context).pop();
            onExport();
          },
          child: const Text('导出备份'),
        ),
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.arrow_down_doc,
          onPressed: () {
            Navigator.of(context).pop();
            onRestore();
          },
          child: const Text('恢复安装'),
        ),
        if (onCompare != null)
          CupertinoContextMenuAction(
            trailingIcon: CupertinoIcons.arrow_right_arrow_left,
            onPressed: () {
              Navigator.of(context).pop();
              onCompare!();
            },
            child: const Text('作为对比基准'),
          ),
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          trailingIcon: CupertinoIcons.delete,
          onPressed: () {
            Navigator.of(context).pop();
            onDelete();
          },
          child: const Text('删除备份'),
        ),
      ],
      builder: (context, animation) {
        return SizedBox(
          width: MediaQuery.sizeOf(context).width - 32,
          height: _cardHeight,
          child: card,
        );
      },
    );
  }
}

class _MiniActionChip extends StatelessWidget {
  const _MiniActionChip({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final DashboardPaletteData palette;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = palette.primary;
    return Material(
      color: selected
          ? Color.alphaBlend(
              accent.withValues(alpha: palette.isDark ? 0.28 : 0.14),
              palette.pageBackgroundAlt,
            )
          : palette.surfaceAlt,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.45)
                  : palette.tileBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? accent : palette.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackupMetaChip extends StatelessWidget {
  const _BackupMetaChip({
    required this.palette,
    required this.icon,
    required this.label,
    this.color,
  });

  final DashboardPaletteData palette;
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? palette.mutedText;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 8, 4),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tone),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class _PluginSelectCard extends StatelessWidget {
  const _PluginSelectCard({
    required this.palette,
    required this.item,
    required this.selected,
    required this.localItem,
    required this.installing,
    required this.hasRepo,
    required this.interactive,
    required this.onChanged,
  });

  final DashboardPaletteData palette;
  final PluginItem item;
  final bool selected;
  final PluginItem? localItem;
  final bool installing;
  final bool hasRepo;
  final bool interactive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final iconUrl = item.pluginIcon != null && item.pluginIcon!.isNotEmpty
        ? ImageUtil.convertPluginIconUrl(item.pluginIcon!)
        : '';
    final backupVersion = (item.pluginVersion ?? '').trim();
    final localVersion = (localItem?.pluginVersion ?? '').trim();
    final versionDiffer =
        localItem != null &&
        backupVersion.isNotEmpty &&
        localVersion.isNotEmpty &&
        backupVersion != localVersion;
    final repoUrl = (item.repoUrl ?? '').trim();
    final author = (item.pluginAuthor ?? '').trim();
    final canTap = interactive && hasRepo && !installing;
    final borderColor = installing
        ? palette.primary.withValues(alpha: 0.55)
        : selected
        ? palette.primary.withValues(alpha: 0.5)
        : palette.tileBorder;
    final bg = installing || selected
        ? Color.alphaBlend(
            palette.primary.withValues(alpha: palette.isDark ? 0.18 : 0.08),
            palette.pageBackgroundAlt,
          )
        : palette.pageBackgroundAlt;

    return Opacity(
      opacity: hasRepo || installing || selected ? 1 : 0.48,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canTap ? () => onChanged(!selected) : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: installing || selected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: installing || selected
                      ? palette.primary.withValues(alpha: 0.12)
                      : palette.shadow,
                  blurRadius: installing || selected ? 14 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    color: installing || selected
                        ? palette.primary
                        : palette.primary.withValues(alpha: 0.18),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: palette.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: palette.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedImage(
                                  imageUrl: iconUrl,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (installing)
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: palette.surface.withValues(
                                      alpha: 0.72,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: palette.primary,
                                    ),
                                  ),
                                ),
                            ],
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
                                        item.pluginName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.25,
                                          color: palette.titleText,
                                        ),
                                      ),
                                    ),
                                    if (installing) ...[
                                      const SizedBox(width: 8),
                                      _VersionChip(
                                        palette: palette,
                                        icon: Icons.downloading_rounded,
                                        label: '安装中',
                                        color: palette.primary,
                                        emphasized: true,
                                      ),
                                    ] else if (hasRepo) ...[
                                      const SizedBox(width: 8),
                                      _SelectMark(
                                        palette: palette,
                                        selected: selected,
                                      ),
                                    ],
                                  ],
                                ),
                                if (author.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: palette.mutedText,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (backupVersion.isNotEmpty)
                                      _VersionChip(
                                        palette: palette,
                                        icon: Icons.inventory_2_outlined,
                                        label: '备份 $backupVersion',
                                        color: palette.coolAccent,
                                      ),
                                    if (localVersion.isNotEmpty)
                                      _VersionChip(
                                        palette: palette,
                                        icon: Icons.phone_iphone_rounded,
                                        label: '本地 $localVersion',
                                        color: versionDiffer
                                            ? palette.warningAccent
                                            : palette.successAccent,
                                        emphasized: true,
                                      ),
                                    if (!hasRepo)
                                      _VersionChip(
                                        palette: palette,
                                        icon: Icons.link_off_rounded,
                                        label: '无法反推仓库',
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                  ],
                                ),
                                if (repoUrl.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    repoUrl,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                      color: palette.bodyText.withValues(
                                        alpha: palette.isDark ? 0.82 : 0.78,
                                      ),
                                    ),
                                  ),
                                ],
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

class _SelectMark extends StatelessWidget {
  const _SelectMark({
    required this.palette,
    required this.selected,
  });

  final DashboardPaletteData palette;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
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

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.palette,
    required this.icon,
    required this.label,
    required this.color,
    this.emphasized = false,
  });

  final DashboardPaletteData palette;
  final IconData icon;
  final String label;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: palette.isDark
              ? (emphasized ? 0.22 : 0.16)
              : (emphasized ? 0.14 : 0.10),
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: emphasized ? 0.36 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackupDialog extends StatelessWidget {
  const _DeleteBackupDialog({required this.item});

  final PluginBackupListItem item;

  String get _timeLabel =>
      '${item.createdAt.year.toString().padLeft(4, '0')}-'
      '${item.createdAt.month.toString().padLeft(2, '0')}-'
      '${item.createdAt.day.toString().padLeft(2, '0')} '
      '${item.createdAt.hour.toString().padLeft(2, '0')}:'
      '${item.createdAt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final danger = Theme.of(context).colorScheme.error;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: palette.tileBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: palette.isDark ? 0.45 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: danger.withValues(alpha: palette.isDark ? 0.18 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: danger.withValues(alpha: palette.isDark ? 0.4 : 0.28),
                ),
              ),
              child: Icon(
                CupertinoIcons.trash_fill,
                size: 24,
                color: danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '删除备份',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: palette.titleText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '删除后无法恢复，确定继续？',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: palette.bodyText.withValues(
                  alpha: palette.isDark ? 0.78 : 0.72,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: palette.surfaceAlt.withValues(
                  alpha: palette.isDark ? 0.55 : 0.85,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.tileBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.35,
                      color: palette.titleText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_timeLabel · ${item.pluginCount} 个插件',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.bodyText.withValues(
                        alpha: palette.isDark ? 0.72 : 0.68,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: palette.surfaceAlt.withValues(
                      alpha: palette.isDark ? 0.55 : 0.9,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Get.back(result: false),
                      child: SizedBox(
                        height: 46,
                        child: Center(
                          child: Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.titleText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: danger,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Get.back(result: true),
                      child: const SizedBox(
                        height: 46,
                        child: Center(
                          child: Text(
                            '删除',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
