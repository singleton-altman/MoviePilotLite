import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/proxmox_ve_backup_form_controller.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

/// PVE 备份存储目标编辑器（本地磁盘 / MP 存储多目标）
///
/// 对应插件 Config.vue 的「备份存储（本地磁盘 / MP 存储）」区块：
/// 可添加多个目标，备份时同时写入所有目标，保留数量 0 表示不限制。
class ProxmoxStorageTargetsEditor extends StatefulWidget {
  const ProxmoxStorageTargetsEditor({super.key, required this.controller});

  final ProxmoxVEBackupFormController controller;

  @override
  State<ProxmoxStorageTargetsEditor> createState() =>
      _ProxmoxStorageTargetsEditorState();
}

class _ProxmoxStorageTargetsEditorState
    extends State<ProxmoxStorageTargetsEditor> {
  List<Map<String, dynamic>> _targets = [];
  bool _enabled = false;
  bool _initialized = false;

  List<Map<String, String>> get _storageOptions {
    final raw = widget.controller.formModel.value['mp_storages'];
    final list = <Map<String, String>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final type = item['type']?.toString() ?? '';
        if (type.isEmpty) continue;
        list.add({'type': type, 'name': item['name']?.toString() ?? type});
      }
    }
    return list;
  }

  void _syncFromModel() {
    final model = widget.controller.formModel.value;
    final raw = model['storage_targets'];
    _targets = raw is List
        ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : [];
    _enabled = model['storage_backup_enable'] == true;
    _initialized = true;
  }

  Future<void> _persist({bool? enabled}) async {
    await widget.controller.saveStorageTargets(
      _targets,
      enabled: enabled ?? _enabled,
    );
  }

  String _typeLabel(String type) {
    if (type == 'local' || type.isEmpty) return '本地磁盘';
    final match = _storageOptions.where((e) => e['type'] == type);
    return match.isEmpty ? type : '${match.first['name']} ($type)';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // formModel 首次加载完成后初始化一次
      if (!_initialized && widget.controller.formModel.value.isNotEmpty) {
        _syncFromModel();
      }
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionHeader(
            title: '备份存储目标',
            subtitle: '可同时备份到本地磁盘与多个 MP 存储',
          ),
          Section(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '备份存储（本地磁盘 / MP 存储）',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  '关闭后仅按上方「启用本地备份」配置执行',
                  style: TextStyle(fontSize: 12),
                ),
                value: _enabled,
                onChanged: (v) async {
                  setState(() => _enabled = v);
                  await _persist(enabled: v);
                },
              ),
              if (_enabled) ...[
                if (_targets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '暂未配置存储目标',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (var i = 0; i < _targets.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _targets[i]['type'] == 'local' ||
                              (_targets[i]['type']?.toString() ?? '').isEmpty
                          ? Icons.folder_outlined
                          : Icons.cloud_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      _typeLabel(_targets[i]['type']?.toString() ?? 'local'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${(_targets[i]['path']?.toString().trim().isEmpty ?? true) ? '默认目录' : _targets[i]['path']}'
                      ' · 保留 ${_targets[i]['keep_backup_num'] ?? 0} 份',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editTarget(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: theme.colorScheme.error,
                          onPressed: _targets.length <= 1
                              ? null
                              : () async {
                                  setState(() => _targets.removeAt(i));
                                  await _persist();
                                },
                        ),
                      ],
                    ),
                    onTap: () => _editTarget(i),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _editTarget(-1),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加备份目标'),
                  ),
                ),
                Text(
                  '保留数量为 0 表示保留全部备份',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    });
  }

  Future<void> _editTarget(int index) async {
    final existing = index >= 0 ? _targets[index] : null;
    var type = existing?['type']?.toString() ?? 'local';
    if (type.isEmpty) type = 'local';
    final pathController = TextEditingController(
      text: existing?['path']?.toString() ?? '',
    );
    final keepController = TextEditingController(
      text: '${existing?['keep_backup_num'] ?? 0}',
    );

    final options = <Map<String, String>>[
      {'type': 'local', 'name': '本地磁盘'},
      ..._storageOptions,
    ];

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(index >= 0 ? '编辑备份目标' : '添加备份目标'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: '存储',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: options
                      .map(
                        (o) => DropdownMenuItem(
                          value: o['type']!,
                          child: Text(
                            o['name']!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => type = v ?? 'local'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pathController,
                  decoration: InputDecoration(
                    labelText: type == 'local' ? '备份路径（默认本地备份目录）' : '远端目录',
                    hintText: type == 'local' ? '/config/plugins/ProxmoxVEBackup' : '/pve_backups',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keepController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '备份保留数量（0 为不限制）',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final keep = int.tryParse(keepController.text.trim()) ?? 0;
      final target = <String, dynamic>{
        'type': type,
        'path': pathController.text.trim(),
        'keep_backup_num': keep < 0 ? 0 : keep,
      };
      setState(() {
        if (index >= 0) {
          _targets[index] = target;
        } else {
          _targets.add(target);
        }
      });
      await _persist();
    }
    pathController.dispose();
    keepController.dispose();
  }
}
