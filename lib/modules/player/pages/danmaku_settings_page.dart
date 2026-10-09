import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lanplayer_player/lanplayer_player.dart' as kit;

import '../../../utils/toast_util.dart';

/// 弹幕源服务器设置(系统设置 · 弹幕设置):
/// 管理 dandanplay 兼容 API 服务器列表(地址 + 可选 API 密钥),
/// 持久化与内嵌播放器的弹幕自动匹配共用同一份存储。
class DanmakuSettingsController extends GetxController {
  final configs = <kit.DanmakuConfig>[].obs;
  final testingIds = <String>{}.obs;
  final testResults = <String, ({bool ok, String message})>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await kit.LanPlayerKit.ensureInitialized();
    await reload();
  }

  Future<void> reload() async {
    try {
      final list = await kit.DbService.getDanmakuConfigs();
      configs.assignAll(list);
    } catch (_) {
      configs.clear();
    }
  }

  Future<void> _persist() async {
    try {
      await kit.DbService.saveDanmakuConfigs(configs.toList());
    } catch (_) {}
    // 与播放器 DanmakuConfigsNotifier 的 Storage 兜底同键,保证两端一致
    try {
      await kit.StorageService.setJsonList(
        kit.StorageService.danmakuConfigKey,
        configs.map((c) => c.toJson()).toList(),
      );
    } catch (_) {}
  }

  Future<void> addConfig(kit.DanmakuConfig config) async {
    configs.add(config);
    await _persist();
  }

  Future<void> updateConfig(kit.DanmakuConfig config) async {
    final i = configs.indexWhere((c) => c.id == config.id);
    if (i >= 0) {
      configs[i] = config;
      await _persist();
    }
  }

  Future<void> removeConfig(String id) async {
    configs.removeWhere((c) => c.id == id);
    await _persist();
  }

  Future<void> setDefault(String id) async {
    // 列表顺序即匹配顺序:置顶即默认
    final c = configs.firstWhereOrNull((c) => c.id == id);
    if (c == null) return;
    configs.remove(c);
    configs.insert(0, c);
    await _persist();
  }

  Future<void> testConnection(kit.DanmakuConfig config) async {
    testingIds.add(config.id);
    testResults.remove(config.id);
    try {
      final service = kit.DanmakuService(
        baseUrl: config.url,
        apiKey: config.apiKey,
      );
      final ok = await service.testConnection();
      testResults[config.id] = ok
          ? (ok: true, message: '连接成功')
          : (ok: false, message: '连接失败,请检查地址或密钥');
    } catch (e) {
      testResults[config.id] = (ok: false, message: '连接失败: $e');
    } finally {
      testingIds.remove(config.id);
    }
  }
}

class DanmakuSettingsPage extends GetWidget<DanmakuSettingsController> {
  const DanmakuSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('弹幕设置')),
      body: Obx(() {
        final configs = controller.configs;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              '播放时按文件名 / 哈希自动匹配弹幕库,支持 dandanplay 兼容 API;'
              '可配置多台服务器,匹配按列表顺序依次尝试。',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 14),
            if (configs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(Icons.speaker_notes_off_outlined,
                        size: 40, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 10),
                    Text('暂无弹幕服务器',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.35))),
                  ],
                ),
              ),
            ...configs.map((c) => _buildServerCard(context, c, primary)),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () => _showEditSheet(context, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加弹幕服务器'),
            ),
            const SizedBox(height: 8),
            Text(
              '长按服务器可设为默认(置顶,优先匹配)。',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildServerCard(
      BuildContext context, kit.DanmakuConfig config, Color primary) {
    final result = controller.testResults[config.id];
    final testing = controller.testingIds.contains(config.id);
    final isDefault = controller.configs.indexOf(config) == 0;
    return GestureDetector(
      onLongPress: () async {
        await controller.setDefault(config.id);
        ToastUtil.success('已设为默认,优先匹配');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.speaker_notes_outlined, color: primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(config.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800)),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('默认',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        testing
                            ? Icons.hourglass_top_rounded
                            : (result == null
                                ? Icons.circle
                                : (result.ok
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded)),
                        size: 11,
                        color: testing
                            ? Colors.white38
                            : (result == null
                                ? Colors.white24
                                : (result.ok
                                    ? const Color(0xFF81C784)
                                    : Colors.redAccent)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          testing
                              ? '测试中…'
                              : (result?.message ??
                                  '${config.url}${(config.apiKey ?? '').isNotEmpty ? ' · 密钥已配置' : ''}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5,
                              color:
                                  Colors.white.withOpacity(0.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => _showEditSheet(context, config),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, kit.DanmakuConfig? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    final keyCtrl = TextEditingController(text: existing?.apiKey ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      existing == null ? '添加弹幕服务器' : '编辑弹幕服务器',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: '名称'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '请输入名称' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                      labelText: '服务器地址(https://...)'),
                  keyboardType: TextInputType.url,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '请输入服务器地址' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: keyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'API 密钥(可选)'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(sheetContext).colorScheme.primary,
                          side: BorderSide(
                              color: Theme.of(sheetContext)
                                  .colorScheme
                                  .primary),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () {
                          final url = urlCtrl.text.trim();
                          if (url.isEmpty) {
                            ToastUtil.info('请先填写服务器地址');
                            return;
                          }
                          final id = existing?.id ??
                              'mp_${DateTime.now().millisecondsSinceEpoch}';
                          final probe = kit.DanmakuConfig(
                            id: id,
                            name: nameCtrl.text.trim().isEmpty
                                ? url
                                : nameCtrl.text.trim(),
                            url: url,
                            apiKey: keyCtrl.text.trim().isEmpty
                                ? null
                                : keyCtrl.text.trim(),
                            isEnabled: true,
                          );
                          controller.testConnection(probe);
                        },
                        icon: const Icon(Icons.wifi_tethering_rounded,
                            size: 18),
                        label: const Text('测试连接'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(sheetContext).colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ??
                              false)) {
                            return;
                          }
                          final config = kit.DanmakuConfig(
                            id: existing?.id ??
                                'mp_${DateTime.now().millisecondsSinceEpoch}',
                            name: nameCtrl.text.trim(),
                            url: urlCtrl.text.trim(),
                            apiKey: keyCtrl.text.trim().isEmpty
                                ? null
                                : keyCtrl.text.trim(),
                            isEnabled: existing?.isEnabled ?? true,
                          );
                          if (existing == null) {
                            await controller.addConfig(config);
                          } else {
                            await controller.updateConfig(config);
                          }
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                          ToastUtil.success('已保存');
                        },
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text('保存'),
                      ),
                    ),
                  ],
                ),
                if (existing != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        await controller.removeConfig(existing.id);
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        ToastUtil.success('已删除');
                      },
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18),
                      label: const Text('删除此服务器'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
