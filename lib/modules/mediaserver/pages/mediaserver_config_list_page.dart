import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:lanplayer_player/lanplayer_player.dart' as kit;
import 'package:moviepilot_mobile/modules/player/controllers/player_launch_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/statistic_model.dart';
import 'package:moviepilot_mobile/modules/mediaserver/controllers/mediaserver_controller.dart';
import 'package:moviepilot_mobile/modules/mediaserver/models/mediaserver_model.dart';

/// 媒体服务器配置列表：使用 MediaServerController 的服务器列表与统计，展示基本信息
class MediaServerConfigListPage extends GetView<MediaServerController> {
  const MediaServerConfigListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('媒体服务器'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshMediaServers(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.mediaServers.value.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final servers = controller.mediaServers.value;
        if (servers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.live_tv_outlined,
                  size: 64,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无媒体服务器配置',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 24),
                Text(
                  '请在设定中配置 Emby / Jellyfin / Plex 等媒体服务器',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refreshMediaServers,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              return Obx(
                () => _MediaServerItemCard(
                  server: server,
                  stats: controller.statsFor(server.name),
                  onTap: () {
                    // 详情页待接入
                    Get.snackbar('提示', '${server.name} 详情页待接入');
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _MediaServerItemCard extends StatelessWidget {
  const _MediaServerItemCard({
    required this.server,
    required this.stats,
    required this.onTap,
  });

  final MediaServer server;
  final StatisticModel? stats;
  final VoidCallback onTap;
  Widget _buildLogo(BuildContext context) {
    final logo = switch (server.type) {
      'emby' => Assets.images.misc.emby,
      'jellyfin' => Assets.images.misc.jellyfin,
      'plex' => Assets.images.misc.plex,
      _ => Assets.images.logos.mediaserver,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: logo.image(width: 60, height: 60, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surface;
    final statsBg = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.5)
        : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.6);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: cardBg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    _buildLogo(context),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            server.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (server.type.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: server.enabled
                                        ? const Color(
                                            0xFF4CAF50,
                                          ).withValues(alpha: 0.15)
                                        : theme.colorScheme.outline.withValues(
                                            alpha: 0.2,
                                          ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    server.type,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: server.enabled
                                          ? const Color(0xFF4CAF50)
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                if (!server.enabled) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '未启用',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    _ServerAccountButton(
                      serverName: server.name,
                      serverType: server.type,
                      baseUrl: (server.config?.host ?? '').isNotEmpty
                          ? server.config!.host
                          : (server.config?.play_host ?? ''),
                      fallbackUsername: server.config?.username ?? '',
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      size: 22,
                    ),
                  ],
                ),
              ),
              if (stats != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statsBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.08,
                        ),
                        width: 1,
                      ),
                    ),
                    child: _MediaStatGrid(stats: stats!),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: statsBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '获取统计中…',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}

class _MediaStatGrid extends StatelessWidget {
  const _MediaStatGrid({required this.stats});

  final StatisticModel stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        icon: CupertinoIcons.film,
        label: '电影',
        value: stats.movie_count.toString(),
        color: CupertinoColors.systemPurple,
      ),
      _StatItem(
        icon: CupertinoIcons.tv,
        label: '剧集',
        value: stats.tv_count.toString(),
        color: CupertinoColors.systemGreen,
      ),
      _StatItem(
        icon: CupertinoIcons.collections,
        label: '集数',
        value: stats.episode_count.toString(),
        color: CupertinoColors.systemOrange,
      ),
      _StatItem(
        icon: CupertinoIcons.person,
        label: '用户',
        value: stats.user_count.toString(),
        color: CupertinoColors.systemBlue,
      ),
    ];
    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < items.length - 1 ? 6 : 0),
            child: _StatTile(
              icon: e.icon,
              label: e.label,
              value: e.value,
              color: e.color,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 媒体服务器「本机账号」入口:显示配置状态,点击打开配置弹层。
///
/// 为什么不写在 MP 服务端配置里:这是**客户端的登录凭据**(本机用哪个账号登录
/// 媒体服务器以写入观看进度),与 MP 服务端的服务器配置是两回事,存本机即可。
class _ServerAccountButton extends StatefulWidget {
  const _ServerAccountButton({
    required this.serverName,
    required this.serverType,
    required this.baseUrl,
    required this.fallbackUsername,
  });

  final String serverName;
  final String serverType;
  final String baseUrl;
  final String fallbackUsername;

  @override
  State<_ServerAccountButton> createState() => _ServerAccountButtonState();
}

class _ServerAccountButtonState extends State<_ServerAccountButton> {
  bool? _configured;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final account =
        await PlayerLaunchController.to.loadAccount(widget.serverName);
    if (!mounted) return;
    setState(() => _configured = account != null);
  }

  Future<void> _openSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServerAccountSheet(
        serverName: widget.serverName,
        serverType: widget.serverType,
        baseUrl: widget.baseUrl,
        fallbackUsername: widget.fallbackUsername,
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configured = _configured == true;
    return Tooltip(
      message: configured ? '本机账号已配置' : '配置本机账号(播放进度同步)',
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: _openSheet,
        icon: Icon(
          configured
              ? Icons.account_circle_rounded
              : Icons.account_circle_outlined,
          size: 22,
          color: configured
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// 本机账号配置弹层:用户名 / 密码 / 测试登录 / 保存或清除。
class _ServerAccountSheet extends StatefulWidget {
  const _ServerAccountSheet({
    required this.serverName,
    required this.serverType,
    required this.baseUrl,
    required this.fallbackUsername,
  });

  final String serverName;
  final String serverType;
  final String baseUrl;
  final String fallbackUsername;

  @override
  State<_ServerAccountSheet> createState() => _ServerAccountSheetState();
}

class _ServerAccountSheetState extends State<_ServerAccountSheet> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final account =
        await PlayerLaunchController.to.loadAccount(widget.serverName);
    if (!mounted) return;
    setState(() {
      _userCtrl.text = account?.username.isNotEmpty == true
          ? account!.username
          : widget.fallbackUsername;
      _passCtrl.text = account?.password ?? '';
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  kit.ServerType get _kitType {
    switch (widget.serverType.toLowerCase()) {
      case 'jellyfin':
        return kit.ServerType.jellyfin;
      default:
        return kit.ServerType.emby;
    }
  }

  Future<void> _test() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (user.isEmpty || pass.isEmpty) {
      ToastUtil.info('请填写用户名与密码');
      return;
    }
    if (widget.baseUrl.isEmpty) {
      ToastUtil.info('该服务器缺少地址,无法测试');
      return;
    }
    setState(() => _busy = true);
    final err = await PlayerLaunchController.to.testAccount(
      baseUrl: widget.baseUrl,
      type: _kitType,
      username: user,
      password: pass,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      ToastUtil.success('登录成功,账号有效');
    } else {
      ToastUtil.error(err);
    }
  }

  Future<void> _save() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text;
    if (user.isEmpty || pass.isEmpty) {
      ToastUtil.info('请填写用户名与密码');
      return;
    }
    setState(() => _busy = true);
    await PlayerLaunchController.to
        .saveAccount(widget.serverName, username: user, password: pass);
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();
    ToastUtil.success('已保存,播放进度将同步到服务端');
  }

  Future<void> _clear() async {
    setState(() => _busy = true);
    await PlayerLaunchController.to
        .saveAccount(widget.serverName, username: '', password: '');
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();
    ToastUtil.success('已清除本机账号');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本机账号 · ${widget.serverName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '用于以「用户登录」身份访问媒体服务器——'
                        '未配置时播放进度不会同步到服务端(继续观看无法更新)。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: '密码',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _test,
                    icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                    label: const Text('测试登录'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('保存'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _clear,
                child: const Text('清除本机账号'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
