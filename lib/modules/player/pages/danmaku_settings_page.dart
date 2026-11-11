import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lanplayer_player/lanplayer_player.dart' as kit;
import 'package:moviepilot_mobile/modules/media_detail/models/danmaku_display_settings.dart';
import 'package:moviepilot_mobile/modules/media_detail/services/danmaku_display_settings_service.dart';

import '../../../utils/toast_util.dart';

/// 弹幕设置(系统设置 · 弹幕设置):
/// 上半部分为本地显示配置(速度、字号、透明度、字色),详情页与后续播放器共用;
/// 下半部分管理 dandanplay 兼容 API 服务器列表(地址 + 可选 API 密钥)。
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
    final scheme = Theme.of(context).colorScheme;
    final background = Theme.of(
      context,
    ).scaffoldBackgroundColor.withValues(alpha: 1);
    final displaySettings = Get.isRegistered<DanmakuDisplaySettingsService>()
        ? Get.find<DanmakuDisplaySettingsService>()
        : Get.put(DanmakuDisplaySettingsService());

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        title: const Text('弹幕设置'),
      ),
      body: Obx(() {
        final configs = controller.configs;
        final settings = displaySettings.settings.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildDisplaySettings(context, displaySettings, settings),
            const SizedBox(height: 24),
            _buildSourceHeader(context),
            const SizedBox(height: 8),
            Text(
              '播放时按文件名 / 哈希自动匹配弹幕库，支持 dandanplay 兼容 API。'
              '可配置多台服务器，按列表顺序依次尝试。',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.7,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (configs.isEmpty)
              _buildEmptyServers(context)
            else
              ...configs.map((config) => _buildServerCard(context, config)),
            if (configs.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '点击服务器卡片进入编辑，长按可设为默认。',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildDisplaySettings(
    BuildContext context,
    DanmakuDisplaySettingsService service,
    DanmakuDisplaySettings settings,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return _surfaceCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBadge(context, Icons.tune_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '显示设置',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '本地保存 · 详情页与播放器共用',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  await service.reset();
                  if (context.mounted) {
                    ToastUtil.success('已恢复默认弹幕样式');
                  }
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('重置'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreview(context, settings),
          const SizedBox(height: 18),
          _buildSliderRow(
            context,
            icon: Icons.speed_rounded,
            label: '速度',
            value: '${settings.speedScale.toStringAsFixed(1)}x',
            current: settings.speedScale,
            min: 0.6,
            max: 1.8,
            divisions: 12,
            onChanged: (value) =>
                service.preview(settings.copyWith(speedScale: value)),
            onChangeEnd: (_) => service.persist(),
          ),
          _buildSliderRow(
            context,
            icon: Icons.text_fields_rounded,
            label: '字号',
            value: '${(settings.fontScale * 100).round()}%',
            current: settings.fontScale,
            min: 0.8,
            max: 1.4,
            divisions: 6,
            onChanged: (value) =>
                service.preview(settings.copyWith(fontScale: value)),
            onChangeEnd: (_) => service.persist(),
          ),
          _buildSliderRow(
            context,
            icon: Icons.opacity_rounded,
            label: '透明度',
            value: '${(settings.opacity * 100).round()}%',
            current: settings.opacity,
            min: 0.4,
            max: 1,
            divisions: 6,
            onChanged: (value) =>
                service.preview(settings.copyWith(opacity: value)),
            onChangeEnd: (_) => service.persist(),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.28),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                '字色',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                settings.colorMode.label,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildColorPicker(context, service, settings),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, DanmakuDisplaySettings settings) {
    final scheme = Theme.of(context).colorScheme;
    final firstColor = settings.colorMode.color ?? const Color(0xFFFDE68A);
    final secondColor = settings.colorMode.color ?? const Color(0xFF93C5FD);
    return Container(
      height: 66,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 10,
            right: 40,
            child: Text(
              '这是一条弹幕预览',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: firstColor.withValues(alpha: settings.opacity),
                fontSize: 12.5 * settings.fontScale,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(
                    color: Color(0xB3000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 74,
            bottom: 9,
            right: 14,
            child: Text(
              '字号与字色会实时生效',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: secondColor.withValues(alpha: settings.opacity * 0.8),
                fontSize: 11 * settings.fontScale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: Text(
              '预览',
              style: TextStyle(
                fontSize: 9,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required double current,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: scheme.onSurfaceVariant),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.primary.withValues(alpha: 0.14),
              thumbColor: scheme.primary,
              overlayColor: scheme.primary.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: current,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(
    BuildContext context,
    DanmakuDisplaySettingsService service,
    DanmakuDisplaySettings settings,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final mode in DanmakuColorMode.values)
            _buildColorOption(context, service, settings, mode),
        ],
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    DanmakuDisplaySettingsService service,
    DanmakuDisplaySettings settings,
    DanmakuColorMode mode,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = settings.colorMode == mode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => service.update(settings.copyWith(colorMode: mode)),
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: SizedBox(
          width: 48,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mode == DanmakuColorMode.multi ? null : mode.color,
                  gradient: mode == DanmakuColorMode.multi
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFDE68A),
                            Color(0xFFF9A8D4),
                            Color(0xFF93C5FD),
                          ],
                        )
                      : null,
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.35),
                    width: selected ? 2.2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.22),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: _checkColor(mode),
                      )
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                mode.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _checkColor(DanmakuColorMode mode) {
    return switch (mode) {
      DanmakuColorMode.white ||
      DanmakuColorMode.yellow ||
      DanmakuColorMode.mint => Colors.black87,
      _ => Colors.white,
    };
  }

  Widget _buildSourceHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '弹幕源',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'dandanplay 兼容服务',
                style: TextStyle(
                  fontSize: 11.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _showEditSheet(context, null),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 38),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('添加'),
        ),
      ],
    );
  }

  Widget _buildEmptyServers(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.dns_outlined, size: 25, color: scheme.primary),
          ),
          const SizedBox(height: 14),
          const Text(
            '还没有弹幕服务器',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            '添加一个 dandanplay 兼容服务，播放时自动匹配弹幕',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showEditSheet(context, null),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('添加服务器'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, kit.DanmakuConfig config) {
    final scheme = Theme.of(context).colorScheme;
    final result = controller.testResults[config.id];
    final testing = controller.testingIds.contains(config.id);
    final isDefault = controller.configs.indexOf(config) == 0;
    final statusColor = testing
        ? scheme.tertiary
        : result == null
        ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
        : result.ok
        ? const Color(0xFF34D399)
        : scheme.error;
    final statusText = testing
        ? '正在测试连接…'
        : result?.message ??
              '未测试连接${(config.apiKey ?? '').isNotEmpty ? ' · 密钥已配置' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showEditSheet(context, config),
          onLongPress: () async {
            await controller.setDefault(config.id);
            ToastUtil.success('已设为默认，优先匹配');
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.30),
                        scheme.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.speaker_notes_rounded,
                    size: 20,
                    color: scheme.primary,
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
                              config.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                '默认',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.45),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '更多操作',
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 19,
                    color: scheme.onSurfaceVariant,
                  ),
                  onSelected: (value) async {
                    if (value == 'default') {
                      await controller.setDefault(config.id);
                      ToastUtil.success('已设为默认，优先匹配');
                    } else if (value == 'edit') {
                      _showEditSheet(context, config);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: _MenuRow(
                          icon: Icons.star_outline_rounded,
                          label: '设为默认',
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: _MenuRow(icon: Icons.edit_outlined, label: '编辑'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _surfaceCard(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBadge(BuildContext context, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.30),
            scheme.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 21, color: scheme.primary),
    );
  }

  void _showEditSheet(BuildContext context, kit.DanmakuConfig? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    final keyCtrl = TextEditingController(text: existing?.apiKey ?? '');
    final formKey = GlobalKey<FormState>();
    var obscureKey = true;
    var testing = false;
    ({bool ok, String message})? testResult;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            InputDecoration inputDecoration({
              required String label,
              required String hint,
              required IconData icon,
              Widget? suffix,
            }) {
              return InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: Icon(icon, size: 18),
                suffixIcon: suffix,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.30),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: scheme.primary, width: 1.2),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.20,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _iconBadge(context, Icons.dns_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    existing == null ? '添加弹幕服务器' : '编辑弹幕服务器',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '支持 dandanplay 兼容 API',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.42),
                                minimumSize: const Size(34, 34),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: nameCtrl,
                          style: const TextStyle(fontSize: 14),
                          decoration: inputDecoration(
                            label: '名称',
                            hint: '例如 主弹幕库',
                            icon: Icons.label_outline_rounded,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? '请输入名称'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: urlCtrl,
                          style: const TextStyle(fontSize: 14),
                          keyboardType: TextInputType.url,
                          decoration: inputDecoration(
                            label: '服务器地址',
                            hint: 'https://danmaku.example.com',
                            icon: Icons.link_rounded,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? '请输入服务器地址'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: keyCtrl,
                          style: const TextStyle(fontSize: 14),
                          obscureText: obscureKey,
                          decoration: inputDecoration(
                            label: 'API 密钥（可选）',
                            hint: '没有密钥可留空',
                            icon: Icons.key_rounded,
                            suffix: IconButton(
                              onPressed: () =>
                                  setSheetState(() => obscureKey = !obscureKey),
                              icon: Icon(
                                obscureKey
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        if (testResult != null) ...[
                          const SizedBox(height: 12),
                          _buildTestResult(context, testResult!),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  side: BorderSide(
                                    color: scheme.primary.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                                onPressed: testing
                                    ? null
                                    : () async {
                                        final url = urlCtrl.text.trim();
                                        if (url.isEmpty) {
                                          ToastUtil.info('请先填写服务器地址');
                                          return;
                                        }
                                        setSheetState(() {
                                          testing = true;
                                          testResult = null;
                                        });
                                        final id =
                                            existing?.id ??
                                            'probe_${DateTime.now().millisecondsSinceEpoch}';
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
                                        await controller.testConnection(probe);
                                        final result =
                                            controller.testResults[id];
                                        if (sheetContext.mounted) {
                                          setSheetState(() {
                                            testing = false;
                                            testResult = result;
                                          });
                                        }
                                      },
                                icon: testing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.wifi_tethering_rounded,
                                        size: 18,
                                      ),
                                label: Text(testing ? '测试中…' : '测试连接'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  foregroundColor: scheme.onPrimary,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  final config = kit.DanmakuConfig(
                                    id:
                                        existing?.id ??
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
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('保存'),
                              ),
                            ),
                          ],
                        ),
                        if (existing != null) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                ToastUtil.warning(
                                  '删除后不可恢复,确定删除「${existing.name}」吗?',
                                  title: '删除弹幕服务器',
                                  onConfirm: () async {
                                    await controller.removeConfig(existing.id);
                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    }
                                    ToastUtil.success('已删除');
                                  },
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.error,
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
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
          },
        );
      },
    );
  }

  Widget _buildTestResult(
    BuildContext context,
    ({bool ok, String message}) result,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final color = result.ok ? const Color(0xFF34D399) : scheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(
            result.ok
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 17), const SizedBox(width: 9), Text(label)],
    );
  }
}
