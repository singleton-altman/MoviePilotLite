import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lanplayer_player/lanplayer_player.dart' as kit;

import '../../../services/api_client.dart';
import '../../mediaserver/models/mediaserver_model.dart';
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

  /// 库所属媒体服务器名(v3 常配多台,点哪台的库就打开哪台)
  String? _serverName;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _libraryId = args['libraryId']?.toString();
      _libraryName = args['libraryName']?.toString();
      _serverName = args['serverName']?.toString();
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
      final kitServer = await _pickReachableServer(servers);
      if (kitServer == null) {
        setState(() {
          _loading = false;
          // 指定了库所属服务器却用不上时不能说"不可达":类型不支持(如 Plex)
          // 也会走到这里,分开提示才不至于误导。
          final requested = _serverName?.trim() ?? '';
          _error = requested.isNotEmpty
              ? '库所属的「$requested」媒体服务器不可用\n请检查该服务器的地址与账号密码(内嵌播放支持 Emby / Jellyfin / 飞牛)'
              : '媒体服务器不可达\n请检查服务端「媒体服务器」配置,下线的那台建议先停用';
        });
        return;
      }
      final service = PlayerLaunchController.to.serviceFor(kitServer);
      if (service == null) {
        setState(() {
          _loading = false;
          // 内嵌播放器只直连 Emby / Jellyfin(Plex 等类型没有对应实现)。
          // 这里把限制说清楚,别让用户对着"加载失败"猜原因。
          _error = kitServer.type == kit.ServerType.plex
              ? '内嵌播放暂不支持 Plex\n请改用 Emby 或 Jellyfin'
              : '当前媒体服务器配置不完整\n请检查账号密码,或改用 Emby / Jellyfin';
        });
        return;
      }
      setState(() {
        _server = kitServer;
        _service = service;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = '加载媒体服务器配置失败';
      });
    }
  }

  /// 探测某台服务器下有哪些库；返回 null 表示该服务器不可用。
  Future<List<String>?> _probeLibraries(ApiClient api, String serverName) async {
    try {
      final probe = await api.get<dynamic>(
        '/api/v1/mediaserver/library?server=$serverName&hidden=true',
      );
      if ((probe.statusCode ?? 0) != 200) return null;
      final data = probe.data;
      dynamic list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = data['value'] ?? data['data'];
        if (list is Map) list = list['value'];
      }
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => (e['id'] ?? e['item_id'])?.toString())
          .whereType<String>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// 挑一台**确实在线、且目标库确实属于它**的媒体服务器。
  ///
  /// 背景(2026-10-10 v3 实测):v3 常同时配多台媒体服务器(如 jellyfin + emby),
  /// 其中一台下线时 MP 的代理接口会对它返回 502;而这里原先固定用第一台,
  /// 结果「点击媒体库」直接加载失败。
  ///
  /// 2026-10-24 真机补充:路由里的 serverName 实际是 MP 的**服务端类型**
  /// (emby / jellyfin / trimemedia),而服务器显示名可能是中文(飞牛)。只按
  /// 名字匹配、匹配不上就静默换台,会拿 A 服务器的库 id 去查 B 服务器(Emby
  /// 对不认识的父 id 返回默认列表),表现为**每个媒体库打开都一模一样**。
  /// 现在:按名字或类型匹配候选,再用 MP 的库列表核对库归属;指定了服务器
  /// 却用不上时直接失败,不再静默换台。
  Future<kit.MediaServer?> _pickReachableServer(
    List<MediaServer> servers,
  ) async {
    final launch = PlayerLaunchController.to;
    final api = Get.find<ApiClient>();
    final requested = _serverName?.trim().toLowerCase() ?? '';

    final candidates = requested.isEmpty
        ? <MediaServer>[...servers]
        : servers
            .where((s) =>
                s.name.toLowerCase() == requested ||
                s.type.toLowerCase() == requested)
            .toList();
    if (requested.isNotEmpty && candidates.isEmpty) return null;

    for (final server in candidates) {
      final ids = await _probeLibraries(api, server.name);
      if (ids == null) continue; // 该服务器不可用
      if (_libraryId != null &&
          _libraryId!.isNotEmpty &&
          ids.isNotEmpty &&
          !ids.contains(_libraryId)) {
        continue; // 目标库不在这台服务器下
      }
      final kitServer = await launch.toKitServer(server, isDefault: true);
      if (kitServer == null) continue;
      if (launch.serviceFor(kitServer) == null) continue; // 类型不支持/缺账号
      return kitServer;
    }
    return null;
  }

  /// kit 浏览网格点条目:优先打开 MP 媒体详情页(观感与 Emby/Jellyfin 一致),
  /// 同时携带媒体服务器条目上下文,详情页播放区可直连起播;返回 false 交给
  /// kit 默认详情页(无 TMDB 映射的条目)。
  ///
  /// 飞牛条目不带 TMDB 标识(API 只给 imdb_id),所以无标识时先按
  /// 标题+年份+类型查一次 MP 媒体身份,命中才跳 MP 详情页。
  Future<bool> _openItemDetail(kit.MediaItem item) async {
    // 合集(BoxSet)交给播放器自己的合集详情页:它会列出合集内的影视。
    // 合集携带的是"合集级 TMDB 标识",拿它去查 MP 媒体详情会返回不完整数据
    // (2026-10-10 v3 真机实测:合集点进去显示「请求错误 · 媒体信息不完整」,
    //  而且会渲染出一个点了必然失败的播放入口)。
    if (item.isBoxSet) return false;
    final path = await _resolveMediaPath(item);
    if (path == null) return false;
    PlayerLaunchController.to.resumeContexts[path] = ResumeContext(
      itemId: item.id,
      serverName: _server!.name,
      serverType: _server!.type.name,
      percent: item.watchProgress,
      label: null,
      isSeries: item.type == kit.MediaType.series,
    );
    Get.toNamed('/media-detail', parameters: {
      'path': path,
      'title': item.title,
      'type_name': item.type == kit.MediaType.series ? '电视剧' : '电影',
      if (item.year != null && item.year! > 0) 'year': '${item.year}',
    });
    return true;
  }

  /// 解析条目的 MP 媒体标识(如 tmdb:123)。
  Future<String?> _resolveMediaPath(kit.MediaItem item) async {
    final tmdbId = item.tmdbId;
    if (tmdbId != null && tmdbId > 0) return 'tmdb:$tmdbId';
    final title = item.title.trim();
    if (title.isEmpty) return null;
    try {
      final api = Get.find<ApiClient>();
      final resp = await api.get<dynamic>(
        '/api/v1/media/search',
        queryParameters: {'title': title, 'type': 'media', 'count': 20},
      );
      if ((resp.statusCode ?? 0) != 200) return null;
      final data = resp.data;
      dynamic list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = data['items'] ?? data['value'] ?? data['data'];
        if (list is Map) list = list['items'] ?? list['value'];
      }
      if (list is! List) return null;
      final wantType = item.type == kit.MediaType.series ? '电视剧' : '电影';
      final wantTitle = _normalizeTitle(title);
      final wantYear = item.year;
      String? loose;
      for (final raw in list) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final path = _mediaPathOf(m);
        if (path == null) continue;
        final type = (m['type'] ?? '').toString();
        if (type.isNotEmpty && !type.contains(wantType)) continue;
        final titles = <Object?>[
          m['title'],
          m['en_title'],
          m['original_title'],
          m['original_name'],
        ]
            .whereType<Object>()
            .map((e) => _normalizeTitle(e.toString()))
            .toList();
        final titleMatch = titles.contains(wantTitle);
        final yearStr = (m['year'] ?? '').toString();
        final year = int.tryParse(
            yearStr.length >= 4 ? yearStr.substring(0, 4) : yearStr);
        final yearMatch =
            wantYear == null || year == null || (year - wantYear).abs() <= 1;
        if (titleMatch && yearMatch) return path;
        if (titleMatch && loose == null) loose = path;
      }
      return loose;
    } catch (_) {
      return null;
    }
  }

  String _normalizeTitle(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'''[\s·:：\-—_.,，。!！?？"“”'‘’()（）\[\]【】]'''), '');

  String? _mediaPathOf(Map<String, dynamic> m) {
    final tmdb = m['tmdb_id'];
    if (tmdb != null) {
      final id = tmdb is num ? tmdb.toInt() : int.tryParse(tmdb.toString());
      if (id != null && id > 0) return 'tmdb:$id';
    }
    final source = (m['media_source'] ?? '').toString().toLowerCase();
    final mediaId = (m['media_id'] ?? '').toString();
    if (mediaId.isEmpty) return null;
    if (source == 'tmdb') return 'tmdb:$mediaId';
    if (source == 'douban') return 'douban:$mediaId';
    if (source == 'bangumi') return 'bangumi:$mediaId';
    return null;
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
