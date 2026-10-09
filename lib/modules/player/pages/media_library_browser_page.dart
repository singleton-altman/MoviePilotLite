import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lanplayer_player/lanplayer_player.dart' as kit;

import '../controllers/player_launch_controller.dart';

/// 媒体库浏览宿主页:管理员凭据直连媒体服务器,内嵌 lanplayer 浏览界面。
/// 非管理员提示后不进入(原生浏览需要媒体服务器地址与密钥)。
class MediaLibraryBrowserPage extends StatefulWidget {
  const MediaLibraryBrowserPage({super.key});

  @override
  State<MediaLibraryBrowserPage> createState() =>
      _MediaLibraryBrowserPageState();
}

class _MediaLibraryBrowserPageState extends State<MediaLibraryBrowserPage> {
  bool _loading = true;
  String? _error;
  kit.MediaServer? _server;
  kit.MediaServerService? _service;
  String? _libraryId;
  String? _libraryName;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _libraryId = args['libraryId']?.toString();
      _libraryName = args['libraryName']?.toString();
    }
    _prepare();
  }

  Future<void> _prepare() async {
    final launch = PlayerLaunchController.to;
    if (!launch.canNativePlay) {
      setState(() {
        _loading = false;
        _error = '媒体库浏览需要管理员权限\n(需读取媒体服务器连接配置)';
      });
      return;
    }
    try {
      await kit.LanPlayerKit.ensureInitialized();
      final servers = await launch.enabledServers();
      if (servers.isEmpty) {
        setState(() {
          _loading = false;
          _error = '尚未配置启用的媒体服务器\n请到「设置 · 系统设置 · 媒体服务器」配置';
        });
        return;
      }
      final kitServer =
          await launch.toKitServer(servers.first, isDefault: true);
      if (kitServer == null) {
        setState(() {
          _loading = false;
          _error = '媒体服务器配置缺少地址';
        });
        return;
      }
      setState(() {
        _server = kitServer;
        _service = PlayerLaunchController.to.serviceFor(kitServer);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = '加载媒体服务器配置失败';
      });
    }
  }

  /// kit 浏览网格点条目:有 TMDB 身份时打开 MP 媒体详情页(观感与 MP 一致),
  /// 同时携带媒体服务器条目上下文,详情页播放区可直连起播;返回 false 交给
  /// kit 默认详情页(无 TMDB 映射的条目)。
  bool _openItemDetail(kit.MediaItem item) {
    final tmdbId = item.tmdbId;
    if (tmdbId == null || tmdbId <= 0) return false;
    final pathKey = 'tmdb:$tmdbId';
    PlayerLaunchController.to.resumeContexts[pathKey] = ResumeContext(
      itemId: item.id,
      serverName: _server!.name,
      serverType: _server!.type.name,
      percent: item.watchProgress,
      label: null,
      isSeries: item.type == kit.MediaType.series,
    );
    Get.toNamed('/media-detail', parameters: {
      'path': 'tmdb:$tmdbId',
      'title': item.title,
      'type_name': item.type == kit.MediaType.series ? '电视剧' : '电影',
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final server = _server;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('媒体库')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (server == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('媒体库')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_library_outlined,
                  size: 44, color: Colors.white38),
              const SizedBox(height: 14),
              Text(
                _error ?? '无法进入媒体库',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    // lanplayer 浏览页为 Riverpod ConsumerWidget,需要 ProviderScope;
    // 强调色随 MP 主题设置注入。
    kit.LanPlayerKit.setAccentColor(Theme.of(context).colorScheme.primary);
    return kit.ProviderScope(
      overrides: [
        kit.currentMediaServerServiceProvider.overrideWithValue(_service),
      ],
      child: Scaffold(
        // 内层 Navigator:kit 深层页面(库内容/条目详情)的 push 都落在这个
        // Navigator 上,始终处于 ProviderScope 之内(否则报 No ProviderScope)
        body: Navigator(
          onGenerateRoute: (settings) {
            if (_libraryId != null && _libraryId!.isNotEmpty) {
              // 从首页指定库卡片进入:直达该库内容网格
              final library = kit.MediaItem(
                id: _libraryId!,
                title: _libraryName ?? '媒体库',
                posterUrl: '',
                type: kit.MediaType.movie,
              );
              return MaterialPageRoute(
                builder: (_) => kit.LibraryItemsScreen(
                  server: server,
                  serverService: _service!,
                  library: library,
                  onOpenItem: _openItemDetail,
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => kit.MediaLibraryScreen(
                server: server,
                onOpenItem: _openItemDetail,
              ),
            );
          },
        ),
      ),
    );
  }
}
