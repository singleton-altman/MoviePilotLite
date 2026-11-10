import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/random_pic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/random_pic_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/random_pic_converter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/random_pic/random_pic_download_panel.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 随机图床（RandomPic）自定义渲染器。
///
/// 该插件在 Web 端是 Vue 联邦组件（`render_mode = vue`），App 里按插件真实接口重建：
/// 页面模式 = 运行状态 + 随机预览 + 统计 + 图源/接口信息
/// 配置模式 = 同一套状态视图 + 可编辑配置表单（保存由页面右上角按钮触发）
void registerRandomPicRenderer() {
  PluginFormAdapterRegistry.registerRenderer('RandomPic', (
    context,
    blocks,
    controller,
    formMode,
    buildBlock,
  ) {
    final adapter = controller.pluginAdapter;
    if (adapter is! RandomPicFormController) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: blocks.map((block) => buildBlock(context, block)).toList(),
      );
    }
    return RandomPicPageView(
      controller: adapter,
      formMode: formMode,
      blocks: blocks,
      buildBlock: buildBlock,
    );
  });
}

class RandomPicPageView extends StatefulWidget {
  const RandomPicPageView({
    super.key,
    required this.controller,
    required this.formMode,
    required this.blocks,
    required this.buildBlock,
  });

  final RandomPicFormController controller;
  final bool formMode;
  final List<FormBlock> blocks;
  final Widget Function(BuildContext context, FormBlock block) buildBlock;

  @override
  State<RandomPicPageView> createState() => _RandomPicPageViewState();
}

class _RandomPicPageViewState extends State<RandomPicPageView> {
  static const _previewTypes = <String, String>{
    'auto': '自动',
    'pc': '横屏',
    'mobile': '竖屏',
  };

  String _previewType = 'auto';
  Uint8List? _imageBytes;
  bool _loadingPreview = false;
  bool _savingLocal = false;
  bool _previewRequested = false;
  String? _previewError;
  Worker? _statusWorker;

  @override
  void initState() {
    super.initState();
    // 状态可能是首帧之后才到（配置页先拉 status 再拉 config），
    // 这里监听一次，保证数据到位后自动加载首张预览图。
    _statusWorker = ever<RandomPicStatus?>(widget.controller.status, (_) {
      _maybeAutoLoadPreview();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoLoadPreview());
  }

  @override
  void dispose() {
    _statusWorker?.dispose();
    super.dispose();
  }

  void _maybeAutoLoadPreview() {
    if (!mounted) return;
    final status = widget.controller.status.value;
    if (status == null || !status.enable) return;
    if (_previewRequested || _loadingPreview || _imageBytes != null) return;
    _previewRequested = true;
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final status = widget.controller.status.value;
    if (status != null && !status.enable) {
      setState(() {
        _previewError = '插件未启用，无法获取预览图';
        _imageBytes = null;
      });
      return;
    }
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });
    final bytes = await widget.controller.fetchPreview(_previewType);
    if (!mounted) return;
    setState(() {
      _loadingPreview = false;
      if (bytes == null || bytes.isEmpty) {
        _previewError = '预览图加载失败，请稍后重试';
      } else {
        _imageBytes = bytes;
      }
    });
  }

  Future<void> _switchType(String type) async {
    setState(() => _previewType = type);
    await _loadPreview();
  }

  Future<void> _saveToLocal() async {
    final bytes = _imageBytes;
    if (bytes == null) {
      ToastUtil.warning('请先加载预览图');
      return;
    }
    setState(() => _savingLocal = true);
    final result = await widget.controller.savePreviewToLocal(bytes);
    if (!mounted) return;
    setState(() => _savingLocal = false);
    if (result.success) {
      ToastUtil.success(result.message);
    } else {
      ToastUtil.error(result.message);
    }
  }

  Future<void> _toggleEnable(RandomPicStatus status) async {
    final wasEnabled = status.enable;
    final ok = await widget.controller.setEnabled(!wasEnabled);
    if (!mounted) return;
    if (ok) {
      ToastUtil.success(wasEnabled ? '已禁用随机图床' : '已启用随机图床');
      if (!wasEnabled) await _loadPreview();
    } else {
      ToastUtil.error(widget.controller.errorText.value ?? '操作失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = widget.controller;
      final status = controller.status.value;
      final loading = controller.isLoading.value;

      if (status == null && loading) {
        return const Center(child: CupertinoActivityIndicator());
      }
      if (status == null && widget.blocks.isEmpty) {
        return Center(
          child: Text(
            controller.errorText.value ?? '暂无数据',
            style: TextStyle(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
          ),
        );
      }

      final sections = <Widget>[];
      if (status != null) {
        sections.add(
          _StatusSection(
            status: status,
            busy: controller.actionLoading.value,
            onRefresh: controller.load,
            onToggle: () => _toggleEnable(status),
          ),
        );
        sections.add(
          _PreviewSection(
            types: _previewTypes,
            current: _previewType,
            bytes: _imageBytes,
            loading: _loadingPreview,
            error: _previewError,
            saving: _savingLocal,
            onSelectType: _switchType,
            onRefresh: _loadPreview,
            onSave: _saveToLocal,
          ),
        );
        sections.add(_StatsSection(status: status));
      }

      if (widget.formMode) {
        for (final block in widget.blocks) {
          sections.add(widget.buildBlock(context, block));
        }
      }

      if (status != null) {
        sections.add(_SourcesSection(status: status));
        if (!widget.formMode) {
          final extras = <FormBlock>[
            if (controller.visits.value != null)
              ...RandomPicConverter.convertVisits(controller.visits.value!),
            ...RandomPicConverter.convertPings(controller.pings),
          ];
          for (final block in extras) {
            sections.add(widget.buildBlock(context, block));
          }
          sections.add(
            RandomPicSpeedTestSection(controller: controller),
          );
          sections.add(
            RandomPicDownloadPanel(controller: controller),
          );
          sections.add(
            _EndpointsSection(status: status, urlBuilder: controller.previewUrl),
          );
        }
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => sections[index],
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon, this.color});

  final String title;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.status,
    required this.busy,
    required this.onRefresh,
    required this.onToggle,
  });

  final RandomPicStatus status;
  final bool busy;
  final Future<void> Function() onRefresh;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = status.enable
        ? const Color(0xFF2E9E5B)
        : theme.colorScheme.outline;
    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.enable ? '随机图床运行中' : '随机图床已禁用',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '共 ${status.totalCount} 张 · 今日访问 ${status.todayVisits}',
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
          IconButton(
            tooltip: '刷新',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: busy ? null : () => onRefresh(),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: busy ? null : onToggle,
            child: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CupertinoActivityIndicator(radius: 6),
                  )
                : Text(status.enable ? '禁用' : '启用'),
          ),
        ],
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({
    required this.types,
    required this.current,
    required this.bytes,
    required this.loading,
    required this.error,
    required this.saving,
    required this.onSelectType,
    required this.onRefresh,
    required this.onSave,
  });

  final Map<String, String> types;
  final String current;
  final Uint8List? bytes;
  final bool loading;
  final String? error;
  final bool saving;
  final Future<void> Function(String type) onSelectType;
  final Future<void> Function() onRefresh;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Section(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: '随机预览',
            icon: Icons.image_outlined,
          ),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              segments: types.entries
                  .map(
                    (entry) => ButtonSegment<String>(
                      value: entry.key,
                      label: Text(entry.value),
                    ),
                  )
                  .toList(),
              selected: {current},
              onSelectionChanged: (value) => onSelectType(value.first),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 220,
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
              child: _buildPreviewBody(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : () => onRefresh(),
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: const Text('换一张'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CupertinoActivityIndicator(radius: 6),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: const Text('保存到本地'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBody(BuildContext context) {
    if (loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    final mutedStyle = TextStyle(
      fontSize: 13,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(error!, textAlign: TextAlign.center, style: mutedStyle),
        ),
      );
    }
    final data = bytes;
    if (data == null) {
      return Center(child: Text('点击「换一张」获取随机图片', style: mutedStyle));
    }
    return Image.memory(
      data,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, _, __) =>
          Center(child: Text('图片解码失败', style: mutedStyle)),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.status});

  final RandomPicStatus status;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData, Color)>[
      (
        '总图片数',
        '${status.totalCount}',
        Icons.photo_library_outlined,
        const Color(0xFF7C4DFF),
      ),
      ('横屏', '${status.pcCount}', Icons.desktop_windows_outlined, const Color(0xFF1E88E5)),
      ('竖屏', '${status.mobileCount}', Icons.smartphone_outlined, const Color(0xFF00897B)),
      ('今日访问', '${status.todayVisits}', Icons.trending_up_rounded, const Color(0xFFFB8C00)),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Section(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                children: [
                  Icon(items[i].$3, size: 20, color: items[i].$4),
                  const SizedBox(height: 6),
                  Text(
                    items[i].$2,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].$1,
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.secondaryLabel,
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.status});

  final RandomPicStatus status;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, bool)>[
      (
        '横屏来源',
        status.pcSourceLabel,
        status.pcPath.isNotEmpty ||
            status.networkImageUrlPc.isNotEmpty ||
            status.networkImageUrl.isNotEmpty,
      ),
      (
        '竖屏来源',
        status.mobileSourceLabel,
        status.mobilePath.isNotEmpty ||
            status.networkImageUrlMobile.isNotEmpty ||
            status.networkImageUrl.isNotEmpty,
      ),
      (
        '本地图片',
        '横 ${status.localPcCount} / 竖 ${status.localMobileCount}',
        status.localPcCount + status.localMobileCount > 0,
      ),
      (
        '网络图片',
        '横 ${status.networkPcCount} / 竖 ${status.networkMobileCount}',
        status.networkPcCount + status.networkMobileCount > 0,
      ),
    ];
    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '图源状态',
            icon: Icons.folder_open_rounded,
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemBlue,
              context,
            ),
          ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    row.$3
                        ? Icons.check_circle_rounded
                        : Icons.remove_circle_outline,
                    size: 16,
                    color: row.$3
                        ? const Color(0xFF2E9E5B)
                        : CupertinoDynamicColor.resolve(
                            CupertinoColors.systemGrey3,
                            context,
                          ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 68,
                    child: Text(row.$1, style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: CupertinoDynamicColor.resolve(
                          CupertinoColors.secondaryLabel,
                          context,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EndpointsSection extends StatelessWidget {
  const _EndpointsSection({required this.status, required this.urlBuilder});

  final RandomPicStatus status;
  final String Function(String type) urlBuilder;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, String, bool)>[
      ('自动识别设备', '/random', 'auto', status.autoAvailable),
      ('指定横屏图片', '/random?type=pc', 'pc', status.pcAvailable),
      ('指定竖屏图片', '/random?type=mobile', 'mobile', status.mobileAvailable),
      (
        '统计数据',
        '/stats',
        'stats',
        status.endpointAvailability['stats'] == true,
      ),
    ];
    return Section(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'API 接口',
            icon: Icons.link_rounded,
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemGreen,
              context,
            ),
          ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.$1,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (item.$4
                                            ? const Color(0xFF2E9E5B)
                                            : CupertinoDynamicColor.resolve(
                                                CupertinoColors.systemGrey3,
                                                context,
                                              ))
                                        .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.$4 ? '正常' : '不可用',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: item.$4
                                      ? const Color(0xFF2E9E5B)
                                      : CupertinoDynamicColor.resolve(
                                          CupertinoColors.systemGrey,
                                          context,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: CupertinoDynamicColor.resolve(
                              CupertinoColors.secondaryLabel,
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '复制地址',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: urlBuilder(item.$3)),
                      );
                      ToastUtil.success('链接已复制');
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
