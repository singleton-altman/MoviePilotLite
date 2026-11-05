import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/mfa/controllers/mfa_settings_controller.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 两步验证设置页：OTP 绑定管理 + Passkey 列表管理。
/// 注册/使用 Passkey 的 WebAuthn 交互需要平台能力（关联域名等配置），
/// App 内提供查看与删除管理，注册引导到 Web 端完成。
class MfaSettingsPage extends StatefulWidget {
  const MfaSettingsPage({super.key});

  @override
  State<MfaSettingsPage> createState() => _MfaSettingsPageState();
}

class _MfaSettingsPageState extends State<MfaSettingsPage> {
  final controller = Get.find<MfaSettingsController>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    controller.cancelPendingOtp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('两步验证'),
        centerTitle: false,
        actions: [
          Obx(
            () => IconButton(
              tooltip: '刷新',
              icon: const Icon(Icons.refresh),
              onPressed:
                  controller.isLoading.value || controller.isSubmitting.value
                  ? null
                  : controller.loadAll,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildOtpSection(context, theme),
            const SizedBox(height: 14),
            _buildPasskeySection(context, theme),
          ],
        );
      }),
    );
  }

  Widget _buildOtpSection(BuildContext context, ThemeData theme) {
    return Section(
      child: Obx(() {
        final enabled = controller.otpEnabled.value;
        final pending = controller.pendingSecret.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'OTP 两步验证',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                _buildStatusChip(theme, enabled),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              enabled == true
                  ? '登录时除账号密码外还需输入动态验证码'
                  : '开启后登录需输入动态验证码，大幅提升账号安全性',
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (controller.otpError.value != null) ...[
              const SizedBox(height: 8),
              Text(
                controller.otpError.value!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              TextButton(
                onPressed: controller.loadAll,
                child: const Text('重试'),
              ),
            ],
            if (enabled == false && pending == null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        final ok = await controller.generateOtp();
                        if (!context.mounted) return;
                        if (!ok) {
                          ToastUtil.error(
                            controller.operationError.value ?? '生成密钥失败，请稍后重试',
                          );
                        } else {
                          _codeController.clear();
                        }
                      },
                icon: const Icon(CupertinoIcons.qrcode, size: 20),
                label: const Text('生成绑定密钥'),
              ),
            ],
            if (enabled == false && pending != null) ...[
              const SizedBox(height: 14),
              _buildSecretPanel(context, theme),
            ],
            if (enabled == true) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: controller.isSubmitting.value
                    ? null
                    : () => _showDisableOtpDialog(context),
                icon: const Icon(CupertinoIcons.lock_open, size: 18),
                label: const Text('关闭两步验证'),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildStatusChip(ThemeData theme, bool? status) {
    final enabled = status == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (enabled ? const Color(0xFF30D158) : theme.colorScheme.onSurface)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status == null
            ? '状态未知'
            : enabled
            ? '已开启'
            : '未开启',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: enabled
              ? const Color(0xFF30D158)
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSecretPanel(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. 将密钥添加到验证器 App',
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(
            controller.pendingSecret.value ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '验证 URI（可复制导入）',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          controller.pendingUri.value ?? '',
          maxLines: 2,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '2. 输入验证器生成的 6 位验证码完成绑定',
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: '动态验证码',
            counterText: '',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () {
                        _codeController.clear();
                        controller.cancelPendingOtp();
                      },
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        final error = await controller.verifyOtp(
                          _codeController.text,
                        );
                        if (!context.mounted) return;
                        if (error != null) {
                          ToastUtil.error(error);
                        } else {
                          _codeController.clear();
                          ToastUtil.success('两步验证已开启');
                        }
                      },
                child: const Text('绑定'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasskeySection(BuildContext context, ThemeData theme) {
    return Section(
      child: Obx(() {
        final passkeys = controller.passkeys;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '通行密钥（Passkey）',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '注册通行密钥需在 Web 端完成（依赖平台 WebAuthn 能力），此处可管理已绑定的密钥。',
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (controller.passkeyError.value != null) ...[
              Text(
                controller.passkeyError.value!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              TextButton(
                onPressed: controller.loadAll,
                child: const Text('重试'),
              ),
            ] else if (passkeys.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    '暂无绑定的通行密钥',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              for (final item in passkeys)
                _buildPasskeyRow(context, theme, item),
          ],
        );
      }),
    );
  }

  Widget _buildPasskeyRow(
    BuildContext context,
    ThemeData theme,
    MfaPasskeyItem item,
  ) {
    final created = item.createdAt?.split('T').first ?? '';
    final lastUsed = item.lastUsedAt?.split('T').first ?? '';
    final meta = <String>[
      if (created.isNotEmpty) '创建于 $created',
      if (lastUsed.isNotEmpty) '最近使用 $lastUsed',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.vpn_key_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name?.isNotEmpty == true ? item.name! : '通行密钥',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      meta,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '删除',
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: theme.colorScheme.error.withOpacity(0.8),
            ),
            onPressed: controller.isSubmitting.value
                ? null
                : () => _showDeletePasskeyDialog(context, item),
          ),
        ],
      ),
    );
  }

  Future<void> _showDisableOtpDialog(BuildContext context) async {
    await _showPasswordDialog(
      context,
      title: '关闭两步验证',
      message: '关闭后登录仅需账号密码，安全性会降低。请输入账号密码确认。',
      confirmLabel: '关闭',
      onConfirm: (password) async {
        final error = await controller.disableOtp(password);
        if (error != null) {
          ToastUtil.error(error);
          return false;
        }
        ToastUtil.success('已关闭两步验证');
        return true;
      },
    );
  }

  Future<void> _showDeletePasskeyDialog(
    BuildContext context,
    MfaPasskeyItem item,
  ) async {
    await _showPasswordDialog(
      context,
      title: '删除通行密钥',
      message: '删除后该设备将无法使用通行密钥登录。请输入账号密码确认。',
      confirmLabel: '删除',
      onConfirm: (password) async {
        final error = await controller.deletePasskey(item, password);
        if (error != null) {
          ToastUtil.error(error);
          return false;
        }
        ToastUtil.success('已删除');
        return true;
      },
    );
  }

  /// 通用密码确认弹窗。onConfirm 返回 true 时关闭弹窗（失败保持打开便于重试）。
  Future<void> _showPasswordDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<bool> Function(String password) onConfirm,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PasswordConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _PasswordConfirmationDialog extends StatefulWidget {
  const _PasswordConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final Future<bool> Function(String) onConfirm;

  @override
  State<_PasswordConfirmationDialog> createState() =>
      _PasswordConfirmationDialogState();
}

class _PasswordConfirmationDialogState
    extends State<_PasswordConfirmationDialog> {
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    if (_passwordController.text.isEmpty) {
      ToastUtil.info('请输入账号密码');
      return;
    }
    setState(() => _submitting = true);
    try {
      final ok = await widget.onConfirm(_passwordController.text);
      if (!mounted) return;
      setState(() => _submitting = false);
      if (ok) Navigator.of(context).pop();
    } finally {
      if (mounted && _submitting) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message,
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            enabled: !_submitting,
            decoration: const InputDecoration(labelText: '账号密码'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _submitting ? null : _confirm,
          child: Text(_submitting ? '处理中…' : widget.confirmLabel),
        ),
      ],
    ),
  );
}
