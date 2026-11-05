import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/controllers/notification_wechat_controller.dart';
import 'package:moviepilot_mobile/theme/section.dart';
// Already supplied by the existing altman_totp dependency; no new dependency.
// ignore: depend_on_referenced_packages
import 'package:qr_flutter/qr_flutter.dart';

class NotificationWechatPage extends StatefulWidget {
  const NotificationWechatPage({super.key});

  @override
  State<NotificationWechatPage> createState() => _NotificationWechatPageState();
}

class _NotificationWechatPageState extends State<NotificationWechatPage>
    with WidgetsBindingObserver {
  final controller = Get.find<NotificationWechatController>();
  final _source = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.setActive(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    controller.setActive(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.setActive(false);
    _source.dispose();
    super.dispose();
  }

  Future<void> _run(Future<WechatActionResult> Function() action) async {
    final result = await action();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认'),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _editChannel([Map<String, dynamic>? item]) async {
    controller.setActive(false);
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ChannelEditor(original: item),
    );
    if (!mounted) return;
    if (values != null) {
      await _run(
        () => controller.saveChannel(
          original: item,
          name: values['name'] as String,
          enabled: values['enabled'] as bool,
          config: values['config'] as Map<String, dynamic>,
          switchs: values['switchs'] as List<String>,
        ),
      );
    }
    if (mounted) controller.setActive(true);
  }

  Future<void> _migrate() async {
    controller.setActive(false);
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _MigrationDialog(),
    );
    if (!mounted) return;
    if (values != null &&
        await _confirm(
          '迁移登录缓存',
          '迁移仅处理登录缓存，不会重命名通知配置。清理旧缓存或覆盖目标可能导致原登录失效，确定继续？',
        )) {
      if (!mounted) return;
      await _run(
        () => controller.migrate(
          oldSource: values['old'] as String,
          newSource: values['new'] as String,
          cleanupOld: values['cleanup'] as bool,
          overwrite: values['overwrite'] as bool,
        ),
      );
    }
    if (mounted) controller.setActive(true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('通知渠道'), centerTitle: false),
    body: Obx(() {
      if (!controller.authorized) {
        return const Center(child: Text('仅管理员可管理通知渠道'));
      }
      if (controller.supported.value == null) {
        return const Center(child: CupertinoActivityIndicator());
      }
      final busy = controller.busy;
      final error = controller.errorText.value;
      final status = controller.status.value;
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!controller.configLoaded.value &&
                          controller.isV3.value) {
                        await controller.reloadConfigurations();
                      } else {
                        await controller.initialize();
                        await controller.reload();
                      }
                    },
              child: const Text('重试'),
            ),
          ],
          if (controller.isV3.value) ...[
            Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '微信 ClawBot 渠道',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text('仅编辑微信 ClawBot；保存时保留其它通知渠道。改名保持渠道身份，并由服务端同步缓存。'),
                  if (controller.wechatConfigurations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('尚未配置微信 ClawBot 渠道'),
                    ),
                  for (final item in controller.wechatConfigurations)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['name']?.toString() ?? '未命名渠道'),
                      subtitle: Text(item['enabled'] == true ? '已启用' : '未启用'),
                      leading: Icon(
                        (item['id'] ?? item['name']) == controller.source.value
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        semanticLabel: (item['id'] ?? item['name']) == controller.source.value
                            ? '已选择渠道' : '未选择渠道',
                      ),
                      onTap: busy
                          ? null
                          : () => controller.selectSource(
                              (item['id'] ?? item['name']) as String,
                            ),
                      trailing: PopupMenuButton<String>(
                        enabled: !busy,
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _editChannel(item);
                            return;
                          }
                          if (await _confirm(
                            '删除通知渠道',
                            '删除后服务端会清理该渠道的登录缓存，此操作不可撤销。',
                          )) {
                            if (!mounted) return;
                            await _run(
                              () => controller.saveChannel(
                                original: item,
                                delete: true,
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('编辑')),
                          PopupMenuItem(value: 'delete', child: Text('删除')),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: busy || !controller.configLoaded.value
                            ? null
                            : _editChannel,
                        child: const Text('添加渠道'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : controller.reloadConfigurations,
                        child: const Text('刷新配置'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else
            Section(
              child: Column(
                children: [
                  TextField(
                    controller: _source,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: '渠道名称（可选）',
                      helperText: '留空使用服务端默认渠道；多渠道时填写准确名称',
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => controller.selectSource(_source.text),
                    child: const Text('选择渠道并查询'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '微信 ClawBot 登录',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  status == null
                      ? '状态未知'
                      : controller.loggedIn
                      ? '已登录'
                      : '未登录',
                ),
                if (controller.loggedIn && controller.accountId != null)
                  Text('账号：${controller.accountId}'),
                if (!controller.loggedIn && status != null) ...[
                  if (controller.qrStatus != null)
                    Text('扫码状态：${controller.qrStatus}'),
                  if (controller.qrExpired)
                    const Text('二维码已过期，请刷新二维码')
                  else if (controller.qrcodeUrl != null) ...[
                    const SizedBox(height: 12),
                    Center(child: _LoginQr(value: controller.qrcodeUrl!)),
                    const SizedBox(height: 8),
                    const Text('使用微信扫码并确认登录。二维码属于登录凭据，请勿分享。'),
                  ] else
                    const Text('点击刷新二维码开始登录'),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : controller.reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新登录状态'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: busy || controller.loggedIn
                      ? null
                      : () => _run(controller.refreshQrcode),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('刷新二维码'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _run(controller.test),
                  icon: const Icon(Icons.network_check),
                  label: const Text('测试连通性'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : _migrate,
                  icon: const Icon(Icons.sync),
                  label: const Text('迁移登录缓存'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: busy || !controller.loggedIn
                      ? null
                      : () async {
                          if (await _confirm(
                            '退出微信登录',
                            '退出后将停止通过该微信账号推送通知，确定继续？',
                          )) {
                            if (mounted) await _run(controller.logout);
                          }
                        },
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                ),
              ],
            ),
          ),
        ],
      );
    }),
  );
}

/// qrcode_url is either a login URL or an image URL/data URL, not qrcode's ID.
class _LoginQr extends StatelessWidget {
  const _LoginQr({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    const failure = SizedBox(
      width: 220,
      height: 120,
      child: Center(child: Text('二维码无法显示，请刷新后重试')),
    );
    Widget image;
    try {
      final uri = Uri.parse(value);
      if (value.startsWith('data:image/')) {
        final data = UriData.parse(value);
        image = Image.memory(
          data.contentAsBytes(),
          width: 220,
          height: 220,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => failure,
        );
      } else if (uri.host == 'liteapp.weixin.qq.com') {
        image = QrImageView(
          data: value,
          size: 220,
          backgroundColor: Colors.white,
          errorStateBuilder: (_, _) => failure,
        );
      } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.userInfo.isEmpty) {
        // No MoviePilot bearer header is ever sent to the QR image origin.
        image = Image.network(
          value,
          width: 220,
          height: 220,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => failure,
        );
      } else {
        image = failure;
      }
    } catch (_) {
      image = failure;
    }
    return Semantics(
      label: '微信登录二维码',
      image: true,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: image,
      ),
    );
  }
}

class _ChannelEditor extends StatefulWidget {
  const _ChannelEditor({this.original});
  final Map<String, dynamic>? original;
  @override
  State<_ChannelEditor> createState() => _ChannelEditorState();
}

class _ChannelEditorState extends State<_ChannelEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _base;
  late final TextEditingController _target;
  late final TextEditingController _admins;
  late final TextEditingController _timeout;
  late final TextEditingController _switchs;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    final item = widget.original;
    final config = item?['config'] as Map? ?? {};
    _name = TextEditingController(text: item?['name'] as String? ?? '');
    _base = TextEditingController(
      text: config['WECHATCLAWBOT_BASE_URL'] as String? ?? '',
    );
    _target = TextEditingController(
      text: config['WECHATCLAWBOT_DEFAULT_TARGET'] as String? ?? '',
    );
    _admins = TextEditingController(
      text: config['WECHATCLAWBOT_ADMINS'] as String? ?? '',
    );
    _timeout = TextEditingController(
      text: config['WECHATCLAWBOT_POLL_TIMEOUT']?.toString() ?? '',
    );
    _switchs = TextEditingController(
      text: (item?['switchs'] as List? ?? []).join(','),
    );
    _enabled = item?['enabled'] == true;
  }

  @override
  void dispose() {
    for (final field in [_name, _base, _target, _admins, _timeout, _switchs]) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.original == null ? '添加微信 ClawBot 渠道' : '编辑微信 ClawBot 渠道',
    ),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: '渠道名称'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? '请输入渠道名称' : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('启用渠道'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              TextFormField(
                controller: _base,
                decoration: const InputDecoration(labelText: 'iLink 服务地址（可选）'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final uri = Uri.tryParse(v.trim());
                  return uri != null &&
                          ['http', 'https'].contains(uri.scheme) &&
                          uri.host.isNotEmpty &&
                          uri.userInfo.isEmpty &&
                          !uri.hasQuery &&
                          !uri.hasFragment
                      ? null
                      : '请输入不含凭据的 HTTP/HTTPS 地址';
                },
              ),
              TextFormField(
                controller: _target,
                decoration: const InputDecoration(labelText: '默认消息目标（可选）'),
              ),
              TextFormField(
                controller: _admins,
                decoration: const InputDecoration(labelText: '管理员 ID（逗号分隔，可选）'),
              ),
              TextFormField(
                controller: _timeout,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '长轮询超时秒数（可选，至少 10）',
                ),
                validator: (v) =>
                    v == null ||
                        v.trim().isEmpty ||
                        (int.tryParse(v.trim()) ?? 0) >= 10
                    ? null
                    : '请输入至少 10 的整数',
              ),
              TextFormField(
                controller: _switchs,
                decoration: const InputDecoration(labelText: '场景开关名称（逗号分隔，可选）'),
              ),
              const SizedBox(height: 12),
              const Text('其它渠道和未展示的配置字段会保留。删除和改名的登录缓存由服务端同步。'),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(context, <String, dynamic>{
            'name': _name.text.trim(),
            'enabled': _enabled,
            'switchs': _switchs.text
                .split(',')
                .map((v) => v.trim())
                .where((v) => v.isNotEmpty)
                .toList(),
            'config': <String, dynamic>{
              'WECHATCLAWBOT_BASE_URL': _base.text.trim(),
              'WECHATCLAWBOT_DEFAULT_TARGET': _target.text.trim(),
              'WECHATCLAWBOT_ADMINS': _admins.text.trim(),
              'WECHATCLAWBOT_POLL_TIMEOUT': int.tryParse(_timeout.text.trim()),
            },
          });
        },
        child: const Text('保存'),
      ),
    ],
  );
}

class _MigrationDialog extends StatefulWidget {
  const _MigrationDialog();
  @override
  State<_MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<_MigrationDialog> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _cleanup = false;
  bool _overwrite = false;
  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('迁移登录缓存'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _old,
              decoration: const InputDecoration(labelText: '原渠道名称'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '请输入原渠道名称' : null,
            ),
            TextFormField(
              controller: _new,
              decoration: const InputDecoration(labelText: '新渠道名称'),
              validator: (v) =>
                  v == null || v.trim().isEmpty || v.trim() == _old.text.trim()
                  ? '请输入不同的新渠道名称'
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('清理旧缓存（危险）'),
              value: _cleanup,
              onChanged: (v) => setState(() => _cleanup = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('覆盖目标缓存（危险）'),
              value: _overwrite,
              onChanged: (v) => setState(() => _overwrite = v),
            ),
            const Text('默认保留旧缓存且不覆盖目标。v3 常规改名请编辑渠道，保持稳定身份；此处仅用于显式迁移旧名称缓存。'),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, <String, dynamic>{
              'old': _old.text,
              'new': _new.text,
              'cleanup': _cleanup,
              'overwrite': _overwrite,
            });
          }
        },
        child: const Text('继续'),
      ),
    ],
  );
}
