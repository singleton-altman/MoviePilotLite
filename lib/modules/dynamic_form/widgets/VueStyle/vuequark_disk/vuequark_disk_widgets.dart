import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/vuequark_disk_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/vuequark_disk_converter.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 夸克网盘存储（VueQuarkDisk）自定义渲染器。
///
/// 页面模式 = 连接状态 + 空间统计 + 扫码登录 + 用户信息
/// 配置模式 = 状态视图 + 可编辑配置表单（保存由页面右上角按钮触发）
void registerVueQuarkDiskRenderer() {
  PluginFormAdapterRegistry.registerRenderer('VueQuarkDisk', (
    context,
    blocks,
    controller,
    formMode,
    buildBlock,
  ) {
    final adapter = controller.pluginAdapter;
    if (adapter is! VueQuarkDiskFormController) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: blocks.map((block) => buildBlock(context, block)).toList(),
      );
    }
    return VueQuarkDiskPageView(
      controller: adapter,
      formMode: formMode,
      blocks: blocks,
      buildBlock: buildBlock,
    );
  });
}

class VueQuarkDiskPageView extends StatefulWidget {
  const VueQuarkDiskPageView({
    super.key,
    required this.controller,
    required this.formMode,
    required this.blocks,
    required this.buildBlock,
  });

  final VueQuarkDiskFormController controller;
  final bool formMode;
  final List<FormBlock> blocks;
  final Widget Function(BuildContext context, FormBlock block) buildBlock;

  @override
  State<VueQuarkDiskPageView> createState() => _VueQuarkDiskPageViewState();
}

class _VueQuarkDiskPageViewState extends State<VueQuarkDiskPageView> {
  bool _logoutLoading = false;

  @override
  void initState() {
    super.initState();
    // 未登录时自动拉起二维码（page 与 form 模式都需要）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = widget.controller.status.value;
      if (status != null &&
          !status.loggedIn &&
          widget.controller.qrUrl.value == null &&
          !widget.controller.qrPolling.value) {
        widget.controller.startQrLogin();
      }
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前夸克账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _logoutLoading = true);
    final ok = await widget.controller.logout();
    if (!mounted) return;
    setState(() => _logoutLoading = false);
    if (ok) {
      ToastUtil.success('已退出登录');
      widget.controller.startQrLogin();
    } else {
      ToastUtil.error(widget.controller.errorText.value ?? '退出登录失败');
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
        sections.add(_StatusSection(status: status));
        sections.add(_SpaceSection(status: status));
        if (!status.loggedIn) {
          sections.add(_QrLoginSection(controller: controller));
        }
        if (status.loggedIn) {
          sections.add(
            _UserSection(
              status: status,
              logoutLoading: _logoutLoading || controller.actionLoading.value,
              onLogout: _logout,
            ),
          );
        }
      }

      if (widget.formMode) {
        for (final block in widget.blocks) {
          sections.add(widget.buildBlock(context, block));
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
  const _StatusSection({required this.status});

  final VueQuarkDiskStatus status;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData, Color)>[
      (
        '登录状态',
        status.loggedIn ? '在线' : '离线',
        Icons.link_rounded,
        status.loggedIn ? const Color(0xFF2E9E5B) : const Color(0xFFE53935),
      ),
      (
        '插件状态',
        status.enabled ? '启用' : '禁用',
        Icons.toggle_on_rounded,
        status.enabled ? const Color(0xFF2E9E5B) : Colors.grey,
      ),
      (
        '排序字段',
        status.sortFieldLabel,
        Icons.sort_rounded,
        const Color(0xFF1E88E5),
      ),
      (
        '分页大小',
        '${status.pageSize}',
        Icons.format_list_numbered_rounded,
        const Color(0xFFFB8C00),
      ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _SpaceSection extends StatelessWidget {
  const _SpaceSection({required this.status});

  final VueQuarkDiskStatus status;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    final ratio = status.usedRatio;
    final hasSpace = status.totalSpace > 0;
    return Section(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: '空间统计',
            icon: Icons.pie_chart_outline_rounded,
            color: Color(0xFF7C4DFF),
          ),
          if (!hasSpace)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('扫码登录后自动同步空间信息', style: mutedStyle),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio ?? 0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${VueQuarkDiskStatus.formatSpace(status.usedSpace)} / '
              '${VueQuarkDiskStatus.formatSpace(status.totalSpace)}'
              '（剩余 ${VueQuarkDiskStatus.formatSpace(status.freeSpace)}）',
              style: mutedStyle,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              _SpaceChip(
                label: '总空间',
                value: VueQuarkDiskStatus.formatSpace(status.totalSpace),
              ),
              const SizedBox(width: 8),
              _SpaceChip(
                label: '已用',
                value: VueQuarkDiskStatus.formatSpace(status.usedSpace),
              ),
              const SizedBox(width: 8),
              _SpaceChip(
                label: '剩余',
                value: VueQuarkDiskStatus.formatSpace(status.freeSpace),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpaceChip extends StatelessWidget {
  const _SpaceChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _QrLoginSection extends StatelessWidget {
  const _QrLoginSection({required this.controller});

  final VueQuarkDiskFormController controller;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Section(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: '扫码登录',
            icon: Icons.qr_code_scanner_rounded,
            color: Color(0xFF4C6FFF),
          ),
          Obx(() {
            final qrUrl = controller.qrUrl.value;
            final polling = controller.qrPolling.value;
            final message = controller.qrMessage.value;
            final expiresIn = controller.qrExpiresIn.value;
            if (qrUrl == null || qrUrl.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message ?? '正在获取二维码…', style: mutedStyle),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => controller.startQrLogin(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('刷新二维码'),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: qrUrl,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    polling ? '请使用夸克 App 扫码登录' : (message ?? '等待扫码'),
                    style: mutedStyle,
                  ),
                ),
                if (polling && expiresIn > 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '二维码 ${expiresIn ~/ 60}:${(expiresIn % 60).toString().padLeft(2, '0')} 后过期',
                        style: TextStyle(
                          fontSize: 12,
                          color: expiresIn <= 30
                              ? const Color(0xFFE53935)
                              : CupertinoDynamicColor.resolve(
                                  CupertinoColors.secondaryLabel,
                                  context,
                                ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.startQrLogin(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('重新获取'),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  const _UserSection({
    required this.status,
    required this.logoutLoading,
    required this.onLogout,
  });

  final VueQuarkDiskStatus status;
  final bool logoutLoading;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    final cookieStatus = status.cookie.contains('__pus')
        ? '有效'
        : '未知';
    return Section(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: '账号信息',
            icon: Icons.account_circle_outlined,
            color: Color(0xFF2E9E5B),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            status.userName.isEmpty ? '夸克用户' : status.userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.vipLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7C4DFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.svipExpAt.isEmpty
                          ? '会员到期：未知'
                          : '会员到期：${status.svipExpAt}',
                      style: mutedStyle,
                    ),
                    const SizedBox(height: 2),
                    Text('Cookie 状态：$cookieStatus', style: mutedStyle),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: const Color(0xFFE53935),
                ),
                onPressed: logoutLoading ? null : onLogout,
                child: logoutLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CupertinoActivityIndicator(radius: 6),
                      )
                    : const Text('退出'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
