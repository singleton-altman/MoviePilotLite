import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/storage/controllers/storage_list_controller.dart';
import 'package:moviepilot_mobile/modules/storage/services/storage_configuration_service.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
// Already supplied by the project's altman_totp package; no new dependency.
// ignore: depend_on_referenced_packages
import 'package:qr_flutter/qr_flutter.dart';

class StorageManageSheet extends StatefulWidget {
  const StorageManageSheet({
    super.key,
    required this.storage,
    required this.controller,
  });

  final StorageSetting storage;
  final StorageListController controller;

  @override
  State<StorageManageSheet> createState() => _StorageManageSheetState();
}

class _StorageManageSheetState extends State<StorageManageSheet> {
  StorageQrCode? _qr;
  String? _message;
  bool _confirming = false;
  bool _loginComplete = false;
  StorageListController get controller => widget.controller;

  Future<void> _acquireQr() async {
    final qr = await controller.acquireQrCode(widget.storage.type);
    if (!mounted || qr == null) return;
    setState(() {
      _qr = qr;
      _loginComplete = false;
      _message = '请使用对应网盘 App 扫码，再检查登录状态';
    });
  }

  Future<void> _auth() async {
    final url = await controller.acquireAuthUrl(widget.storage.type);
    if (!mounted || url == null || !controller.canManage) return;
    setState(() {
      _qr = null;
      _loginComplete = false;
      _message = '请在浏览器中完成授权，返回后检查登录状态';
    });
    await WebUtil.open(url: url, internal: false);
  }

  Future<void> _check() async {
    final status = await controller.checkLogin(widget.storage.type);
    if (!mounted || status == null) return;
    setState(() {
      _loginComplete = status.complete;
      _message = status.complete ? '${status.tip}；登录凭据已由服务端保存' : status.tip;
      if (status.complete) _qr = null;
    });
  }

  Future<void> _edit() async {
    final original = await controller.readConfiguration(widget.storage.type);
    if (!mounted || original == null || !controller.canManage) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StorageConfigurationEditor(
        original: original,
        controller: controller,
      ),
    );
  }

  Future<void> _reset() async {
    if (_confirming || controller.isSubmitting.value) return;
    setState(() => _confirming = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('重置存储配置'),
          content: Text('将清空「${widget.storage.name}」的登录与配置信息。此操作不可撤销，确定继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('确认重置'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final ok = await controller.resetStorage(
        widget.storage.type,
        confirmed: true,
      );
      if (!mounted || ok != true) return;
      setState(() {
        _qr = null;
        _loginComplete = false;
        _message = '存储配置已重置';
      });
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final busy = controller.isSubmitting.value;
    final disabled = busy || _confirming || !controller.canManage;
    final loginProvider = const {
      'alipan',
      'u115',
    }.contains(widget.storage.type);
    return PopScope(
      canPop: !busy && !_confirming,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.storage.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (loginProvider) ...[
                ListTile(
                  leading: const Icon(Icons.qr_code_rounded),
                  title: Text(_qr == null ? '获取登录二维码' : '重新获取二维码'),
                  enabled: !disabled,
                  onTap: _acquireQr,
                ),
                if (widget.storage.type == 'u115')
                  ListTile(
                    leading: const Icon(Icons.link_rounded),
                    title: const Text('OAuth 授权链接'),
                    enabled: !disabled,
                    onTap: _auth,
                  ),
                if (_qr != null)
                  Center(
                    child: ColoredBox(
                      color: Colors.white,
                      child: _qr!.content != null
                          ? QrImageView(
                              data: _qr!.content!,
                              size: 220,
                              backgroundColor: Colors.white,
                              semanticsLabel: '网盘登录二维码',
                            )
                          : Image.network(
                              _qr!.imageUrl!,
                              width: 220,
                              height: 220,
                              // Do not attach MoviePilot credentials to provider images.
                              semanticLabel: '网盘登录二维码',
                              errorBuilder: (_, _, _) => const SizedBox(
                                width: 220,
                                height: 100,
                                child: Center(child: Text('二维码图片加载失败，请重新获取')),
                              ),
                            ),
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('检查扫码/授权结果'),
                  subtitle: const Text('登录成功时由服务端保存凭据，不会提交状态覆盖配置'),
                  enabled: !disabled && !_loginComplete,
                  onTap: _check,
                ),
              ],
              if (widget.storage.type != 'local') ...[
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('编辑存储配置'),
                  subtitle: const Text('读取当前配置后编辑并保存'),
                  enabled: !disabled,
                  onTap: _edit,
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: const Text('重置存储配置'),
                  enabled: !disabled,
                  onTap: _reset,
                ),
              ],
              if (busy) const LinearProgressIndicator(),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_message!),
                ),
              if (controller.operationError.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    controller.operationError.value!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextButton(
                onPressed: busy || _confirming
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  });
}

class _StorageConfigurationEditor extends StatefulWidget {
  const _StorageConfigurationEditor({
    required this.original,
    required this.controller,
  });
  final StorageSetting original;
  final StorageListController controller;

  @override
  State<_StorageConfigurationEditor> createState() =>
      _StorageConfigurationEditorState();
}

class _StorageConfigurationEditorState
    extends State<_StorageConfigurationEditor> {
  late final String _initial = const JsonEncoder.withIndent(
    '  ',
  ).convert(widget.original.config);
  late final TextEditingController _text = TextEditingController(
    text: _initial,
  );
  String? _error;
  bool _closing = false;
  bool _allowPop = false;
  bool get _dirty => _text.text != _initial;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing || widget.controller.isSubmitting.value) return;
    _closing = true;
    try {
      final discard =
          !_dirty ||
          await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('放弃未保存的修改？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('继续编辑'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('放弃修改'),
                    ),
                  ],
                ),
              ) ==
              true;
      if (!mounted || !discard) return;
      await _pop();
    } finally {
      _closing = false;
    }
  }

  Future<void> _pop() async {
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (widget.controller.isSubmitting.value || !_dirty) return;
    Map<String, dynamic> config;
    try {
      final decoded = jsonDecode(_text.text);
      if (decoded is! Map<String, dynamic> || decoded.isEmpty) {
        throw const FormatException('请输入非空的 JSON 配置对象，清空配置请使用重置');
      }
      config = decoded;
    } catch (_) {
      setState(() => _error = '请输入有效的非空 JSON 配置对象，原有输入已保留');
      return;
    }
    setState(() => _error = null);
    final saved = await widget.controller.saveConfiguration(
      widget.original,
      config,
    );
    if (mounted && saved == true) await _pop();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final busy = widget.controller.isSubmitting.value;
    return PopScope(
      canPop: _allowPop || (!busy && !_dirty),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AlertDialog(
        title: const Text('编辑存储配置'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '高级配置：保存将替换该存储的完整配置。包含敏感凭据，请勿分享。失败时保留输入；服务端配置变化时拒绝覆盖。',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _text,
                  enabled: !busy && widget.controller.canManage,
                  minLines: 6,
                  maxLines: 14,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: '配置 JSON',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_error ?? widget.controller.operationError.value
                    case final String error)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: busy ? null : _close, child: const Text('取消')),
          FilledButton(
            onPressed: busy || !_dirty || !widget.controller.canManage
                ? null
                : _save,
            child: Text(busy ? '保存中…' : '保存配置'),
          ),
        ],
      ),
    );
  });
}
