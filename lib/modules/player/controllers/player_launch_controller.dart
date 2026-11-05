import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:get/get.dart';
import 'package:lanplayer_player/lanplayer_player.dart' as kit;

import '../../../applog/app_log.dart';
import '../models/player_play_request.dart';
import '../../../services/api_client.dart';
import '../../../services/app_service.dart';
import '../../../utils/open_url.dart';
import '../../../utils/toast_util.dart';
import '../../mediaserver/models/mediaserver_model.dart';

/// exists 映射结果:MoviePilot 媒体身份 → 媒体服务器条目
class PlayProbe {
  final String serverName;
  final String itemId;
  final bool isSeries;

  const PlayProbe({
    required this.serverName,
    required this.itemId,
    required this.isSeries,
  });
}

/// 首页「继续观看」卡片携带的续播上下文
class ResumeContext {
  final String itemId;
  final String? serverName;
  final String? serverType;
  final double? percent;
  final String? label;
  final bool isSeries;

  const ResumeContext({
    required this.itemId,
    this.serverName,
    this.serverType,
    this.percent,
    this.label,
    this.isSeries = false,
  });

  /// 是否带进度信息。卡片/浏览入口只带「条目身份」(条目 id + 服务器 + 类型)时
  /// 为 false——详情页照样立即渲染播放与选集按钮,但不显示续播进度行。
  bool get hasProgress =>
      (percent != null && percent! > 0) || (label != null && label!.isNotEmpty);
}

/// 面向用户的播放错误:toString 直接给出提示文案(不带 Exception: 前缀),
/// 让播放页与 Toast 里的文案干净可读。
class PlaybackError implements Exception {
  final String message;

  const PlaybackError(this.message);

  @override
  String toString() => message;
}

/// 内嵌播放接入层:把 MoviePilot 侧媒体身份映射到媒体服务器条目并拉起播放。
/// 原生播放需要媒体服务器凭据(仅管理员可读系统设置);普通用户回退网页播放。
class PlayerLaunchController extends GetxService {
  PlayerLaunchController._();

  static final PlayerLaunchController to = PlayerLaunchController._();

  final ApiClient _api = Get.find<ApiClient>();
  final AppService _app = Get.find<AppService>();
  final AppLog _log = Get.find<AppLog>();

  List<MediaServer>? _enabledCache;
  final Map<String, Map<String, dynamic>> _rawConfigByName = {};
  DateTime? _cacheAt;
  static const Duration _cacheTtl = Duration(minutes: 5);
  final Map<String, kit.MediaServerService> _serviceCache = {};

  /// 详情页条目上下文缓存,键为媒体标识(如 tmdb:24516)。
  /// 由卡片/浏览入口写入;详情页播放区按自身媒体标识读取,
  /// 不做一次性消费(页面反复进出结果稳定)。
  final Map<String, ResumeContext> resumeContexts = {};

  /// 探测结果缓存,键为 mtype|tmdb|season|title
  final Map<String, PlayProbe?> _probeCache = {};

  bool _accountHintShown = false;

  /// 可用地址解析缓存:serverName -> 选中的地址 + 当时的网络指纹
  final Map<String, String> _resolvedUrl = {};
  final Map<String, String> _resolvedFp = {};

  /// 「两地址均探测失败」的记录:serverName -> (判定时间, 网络指纹)。
  /// 冷却期内直接用外网地址;同时供播放失败时给出准确的错误提示。
  final Map<String, (DateTime, String)> _degraded = {};

  ResumeContext? resumeContextFor(String? pathKey) =>
      pathKey == null ? null : resumeContexts[pathKey];

  bool get canNativePlay => _app.isSuperuser;

  /// 所有 kit 交互前必须确保包内存储已初始化
  Future<void> _ensureKit() => kit.LanPlayerKit.ensureInitialized();


  /// 拉取已启用的媒体服务器配置(GET /api/v1/system/setting/MediaServers,
  /// Swagger:仅管理员),带短缓存。
  Future<List<MediaServer>> enabledServers({bool force = false}) async {
    if (!force && _enabledCache != null && _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _cacheTtl) {
      return _enabledCache!;
    }
    final response = await _api.get<dynamic>(
      '/api/v1/system/setting/MediaServers',
    );
    dynamic data = response.data;
    // 兼容三种包装:{success,data:[...]}, {success,data:{value:[...]}}, 直接 [...]
    if (data is Map) {
      final d = data['data'];
      if (d is List) {
        data = d;
      } else if (d is Map && d['value'] is List) {
        data = d['value'];
      }
    }
    if (data is! List) return _empty();
    _rawConfigByName.clear();
    final servers = <MediaServer>[];
    for (final item in data.whereType<Map>()) {
      final raw = Map<String, dynamic>.from(item);
      final server = MediaServer.fromJson(raw);
      if (!server.enabled) continue;
      _rawConfigByName[server.name] =
          raw['config'] is Map ? Map<String, dynamic>.from(raw['config'] as Map) : <String, dynamic>{};
      servers.add(server);
    }
    _enabledCache = servers;
    _cacheAt = DateTime.now();
    return servers;
  }

  List<MediaServer> _empty() {
    _enabledCache = [];
    _cacheAt = DateTime.now();
    return _enabledCache!;
  }

  void invalidateCache() {
    _enabledCache = null;
  }

  /// MP 服务器配置 → kit MediaServer。
  /// 地址自动选择:内网地址可直连则用内网(更快、不占宽带上行),
  /// 内网不可达时自动回退外网播放地址;结果按网络指纹缓存,换网自动重判。
  Future<kit.MediaServer?> toKitServer(
    MediaServer s, {
    bool isDefault = false,
  }) async {
    // 配置未加载时先拉取:否则本次构造会拿到空的 apiKey/username,
    // 产生一个"无凭据"的实例(日志中的 hasKey=false),与后续实例分裂。
    if (_rawConfigByName.isEmpty) {
      await enabledServers();
    }
    final raw = _rawConfigByName[s.name] ?? const <String, dynamic>{};
    String cfgOf(List<String> keys) {
      for (final k in keys) {
        final v = raw[k]?.toString() ?? '';
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    // MP 服务端的键名是 api_key;兼容 apikey 与 token 变体
    final apiKey = cfgOf(['api_key', 'apikey', 'token']);
    var username = cfgOf(['username', 'user']);
    var password = cfgOf(['password']);
    // 优先用 App 内配置的本机账号(用户令牌登录,播放进度才会被服务端接受)
    final account = await loadAccount(s.name);
    if (account != null) {
      if (account.username.isNotEmpty) username = account.username;
      password = account.password;
    }
    final playHost = cfgOf(['play_host', 'play_url']);
    final host = cfgOf(['host', 'url']);
    final url = await _resolveUsableUrl(
      s.name,
      lan: host,
      wan: playHost,
    );
    if (url == null || url.isEmpty) return null;
    _log.warning(
        'MediaServers[${s.name}] keys=${raw.keys.toList()} hasKey=${apiKey.isNotEmpty} url=$url');
    return kit.MediaServer(
      id: s.name,
      name: s.name,
      url: url,
      type: mapKitType(s.type),
      apiKey: apiKey,
      username: username.isEmpty ? null : username,
      password: password.isEmpty ? null : password,
      isDefault: isDefault,
    );
  }

  /// 公开的服务工厂(详情页选集等处使用);内部带缓存与免迁移构造
  kit.MediaServerService? serviceFor(kit.MediaServer server) =>
      _serviceFor(server);

  kit.MediaServerService? _serviceFor(kit.MediaServer server) {
    // 缓存键不含 apiKey:账号登录会改写 apiKey(用户令牌),若含它就会分裂出
    // 第二个「未登录」实例——上报走登录实例、取流走旧密钥实例(真机日志实证:
    // 两个 init,hasKey=false 与 true 并存 → 进度写不进服务端)。
    final cacheKey = '${server.id}_${server.url}';
    final cached = _serviceCache[cacheKey];
    if (cached != null) return cached;
    kit.MediaServerService? service;
    // 配了本机账号时不传 API 密钥:服务内的 _ensureAuth 见到非空 apiKey 会直接
    // 短路(return true)而永不登录,导致播放会话带的是系统密钥 —— Emby 对系统
    // 密钥的会话不写观看进度(2026-09-27 实证)。留空 apiKey 才会走用户名密码
    // 登录、拿到用户令牌。
    final hasAccountCreds = (server.password ?? '').isNotEmpty &&
        (server.username ?? '').isNotEmpty;
    final effectiveApiKey = hasAccountCreds ? '' : (server.apiKey ?? '');
    switch (server.type) {
      case kit.ServerType.emby:
        service = kit.EmbyService(
          baseUrl: server.url,
          apiKey: effectiveApiKey,
          username: server.username,
          password: server.password,
        );
        break;
      case kit.ServerType.jellyfin:
        service = kit.JellyfinService(
          baseUrl: server.url,
          apiKey: effectiveApiKey,
          username: server.username,
          password: server.password,
        );
        break;
      case kit.ServerType.fnos:
        // 飞牛需要真实账号密码登录;MP 配置无密码时无法直连
        if ((server.password ?? '').isNotEmpty &&
            (server.username ?? '').isNotEmpty) {
          service = kit.FnOSService(
            baseUrl: server.url,
            username: server.username ?? '',
            password: server.password ?? '',
          );
        }
        break;
      default:
        service = null;
    }
    if (service != null) _serviceCache[cacheKey] = service;
    return service;
  }

  /// 选择可用地址:内网优先(探测通过即用),内网不可达时用外网播放地址。
  ///
  /// 两个地址都探测失败时**回退外网地址**,不再回退内网:公网/反代地址在
  /// 任何网络下都可能可访问,而内网地址只在局域网可达——回退内网等于必然
  /// 超时(真机表现:DioException connection timeout 10s,"获取媒体信息失败")。
  /// 探测成功的结果按网络指纹缓存;**失败结果不写缓存**,避免一次网络抖动
  /// 把错误地址锁死 5 分钟;仅保留 90 秒冷却,防止连续重试反复空等两轮探测。
  Future<String?> _resolveUsableUrl(
    String serverName, {
    required String lan,
    required String wan,
  }) async {
    if (wan.isEmpty) return lan.isEmpty ? null : lan;
    if (lan.isEmpty) return wan;
    if (lan == wan) return lan;

    final fp = await _networkFingerprint();
    final cached = _resolvedUrl[serverName];
    if (cached != null && _resolvedFp[serverName] == fp) return cached;

    // 刚判定过"两地址均不可达"且网络没换:直接用外网地址,不再空等探测
    final deg = _degraded[serverName];
    if (deg != null &&
        deg.$2 == fp &&
        DateTime.now().difference(deg.$1) < const Duration(seconds: 90)) {
      _log.warning('播放地址[$serverName] 冷却期内沿用外网地址: $wan');
      return wan;
    }

    _log.warning('播放地址[$serverName] 探测中: 内网=$lan 外网=$wan');
    if (await _probeUrl(lan)) {
      _resolvedUrl[serverName] = lan;
      _resolvedFp[serverName] = fp;
      _degraded.remove(serverName);
      _log.warning('播放地址[$serverName] 选内网: $lan');
      return lan;
    }
    if (await _probeUrl(wan)) {
      _resolvedUrl[serverName] = wan;
      _resolvedFp[serverName] = fp;
      _degraded.remove(serverName);
      _log.warning('播放地址[$serverName] 选外网(内网不可达): $wan');
      return wan;
    }
    _degraded[serverName] = (DateTime.now(), fp);
    _log.warning('播放地址[$serverName] 两地址均探测失败,本次回退外网地址(不缓存): $wan');
    return wan;
  }

  /// ── 媒体服务器本机账号 ──
  ///
  /// 为什么需要:Emby/Jellyfin 只对「用户登录令牌」建立的播放会话写入观看进度;
  /// 用系统级 API 密钥时上报虽返回 204 但进度被静默丢弃(2026-09-27 双向实证)。
  /// 配置账号后服务会走 loginByUsernamePassword 取得用户令牌,「继续观看」可正常同步。
  static const String _accountKeyPrefix = 'player_ms_account_';

  String _accountKey(String serverName) => '$_accountKeyPrefix$serverName';

  /// 读取某媒体服务器的本机账号(未配置返回 null)
  Future<({String username, String password})?> loadAccount(
    String serverName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_accountKey(serverName));
      if (raw == null || raw.isEmpty) return null;
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final u = m['username']?.toString() ?? '';
      final pw = m['password']?.toString() ?? '';
      if (pw.isEmpty) return null;
      return (username: u, password: pw);
    } catch (_) {
      return null;
    }
  }

  /// 保存本机账号(密码为空则清除配置)
  Future<void> saveAccount(
    String serverName, {
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (password.isEmpty) {
      await prefs.remove(_accountKey(serverName));
    } else {
      await prefs.setString(
        _accountKey(serverName),
        jsonEncode({'username': username, 'password': password}),
      );
    }
    _serviceCache.clear();
  }

  /// 测试账号是否可登录(返回错误信息,null 表示成功)
  Future<String?> testAccount({
    required String baseUrl,
    required kit.ServerType type,
    required String username,
    required String password,
  }) async {
    try {
      final probe = type == kit.ServerType.jellyfin
          ? kit.JellyfinService(baseUrl: baseUrl, username: username, password: password)
          : kit.EmbyService(baseUrl: baseUrl, username: username, password: password);
      final ok = await probe.loginByUsernamePassword();
      return ok ? null : '登录失败,请检查用户名与密码';
    } catch (e) {
      return '登录失败: $e';
    }
  }

  /// 轻量连通性探测(走双栈竞速,IPv4/IPv6 任一可达即通过)。
  /// 超时给到 5 秒:HTTPS 反代需要 TLS 握手 + 公网往返,原来的 2 秒连接
  /// 超时会把可用的反代地址误判为不可达(→ 进而选错地址、播放超时)。
  Future<bool> _probeUrl(String base) async {
    try {
      final dio = kit.createDualStackDio(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      );
      final r = await dio.get<dynamic>('/System/Info/Public');
      return r.statusCode != null && r.statusCode! < 500;
    } catch (e) {
      // 打印失败原因(超时/TLS/404),便于从日志区分"地址不可达"与"配置写错"
      _log.warning('播放地址探测失败[$base]: $e');
      return false;
    }
  }

  /// 网络指纹:当前设备的 IPv4 地址集合(排序),换网络时变化
  Future<String> _networkFingerprint() async {
    try {
      final ifaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final addrs = <String>[];
      for (final i in ifaces) {
        for (final a in i.addresses) {
          addrs.add(a.address);
        }
      }
      addrs.sort();
      return addrs.join(',');
    } catch (_) {
      return '';
    }
  }

  /// 手动清空地址解析缓存(切换账号/配置变更后调用)
  void invalidateResolvedUrl() {
    _resolvedUrl.clear();
    _resolvedFp.clear();
    _degraded.clear();
  }

  kit.ServerType mapKitType(String type) {
    switch (type.toLowerCase()) {
      case 'jellyfin':
        return kit.ServerType.jellyfin;
      case 'fnos':
        return kit.ServerType.fnos;
      case 'plex':
        return kit.ServerType.plex;
      case 'emby':
      default:
        return kit.ServerType.emby;
    }
  }

  /// exists 映射:优先问 MP 自己的媒体库同步库(GET /api/v1/mediaserver/exists,
  /// 本地数据库查询,实测 11~27ms 且条目 id 与媒体服务器一致),
  /// 未命中或调用失败时回退媒体服务器标题搜索(原有路径)。
  /// 返回命中的服务器名与条目 id;未收录返回 null。
  Future<PlayProbe?> probeExists({
    required String title,
    String? year,
    String? mtype,
    int? tmdbId,
    int? season,
  }) async {
    await _ensureKit();
    final isTv = (mtype ?? '').contains('剧') ||
        (mtype ?? '').toLowerCase().contains('tv');
    final cacheKey = '$mtype|$tmdbId|$season|$title';
    if (_probeCache.containsKey(cacheKey)) {
      return _probeCache[cacheKey];
    }
    final byMp = await _probeByMpLibrary(
      title: title,
      year: year,
      mtype: mtype,
      tmdbId: tmdbId,
      isTv: isTv,
    );
    if (byMp != null) {
      _probeCache[cacheKey] = byMp;
      return byMp;
    }
    // ignore: avoid_print
    print('[PlayerLaunch] MP 本地库未命中,回退媒体服务器搜索: $title (tmdb=$tmdbId)');
    final servers = await enabledServers();
    for (final s in servers) {
      final kitServer = await toKitServer(s);
      if (kitServer == null) continue;
      final service = _serviceFor(kitServer);
      if (service == null) continue;
      try {
        // 按 TMDB ProviderId 直查媒体服务器(电影/剧集通吃)
        // 仅 Emby/Jellyfin 服务支持(飞牛无密钥认证,已在 _serviceFor 拦截)
        final embyLike = service is kit.EmbyService ? service as kit.EmbyService : null;
        final item = embyLike == null
            ? null
            : await embyLike
                .findItemByTmdb(
                  tmdbId: tmdbId ?? 0,
                  isTv: isTv,
                  title: title,
                )
                .timeout(const Duration(seconds: 12));
        if (item != null && item.id.isNotEmpty) {
          final probe = PlayProbe(
            serverName: s.name,
            itemId: item.id,
            isSeries: isTv || item.type == kit.MediaType.series,
          );
          _probeCache[cacheKey] = probe;
          return probe;
        }
      } catch (e) {
        _log.warning('probeExists[${s.name}] 查询失败: $e');
      }
    }
    _probeCache[cacheKey] = null;
    return null;
  }

  /// MP 侧类型取值:MediaType 枚举只有「电影」「电视剧」两个中文值。
  /// 判不出来返回 null(此时不用 MP 本地库路径,直接回退搜索)。
  String? _mpMediaType(String? mtype) {
    final t = (mtype ?? '').toLowerCase();
    if (t.isEmpty) return null;
    if (t.contains('剧') || t.contains('tv')) return '电视剧';
    if (t.contains('电影') || t.contains('movie')) return '电影';
    return null;
  }

  /// 用 MP 自己的媒体库同步库解析「条目 id」:GET /api/v1/mediaserver/exists,
  /// 参数用 tmdbid + mtype(命中即返回 data.item.id = 媒体服务器条目 id)。
  ///
  /// 2026-09-28 实测(用户服务器):剧集 tmdbid=124595 → id=18070、
  /// 三部电影全部命中且与媒体服务器条目 id 一致,耗时 11~27ms。
  ///
  /// 实测陷阱:
  /// 1) **必须带 mtype**——只给 tmdbid 即使数据存在也返回不存在;
  /// 2) **不能带 season**——MP 的季信息不全时会把存在的条目判为不存在
  ///    (与选集面板"季对不上"同源),季校验交给上层用真实分集数据判断。
  Future<PlayProbe?> _probeByMpLibrary({
    required String title,
    String? year,
    String? mtype,
    int? tmdbId,
    bool isTv = false,
  }) async {
    try {
      return await _probeByMpLibraryInner(
        title: title,
        year: year,
        mtype: mtype,
        tmdbId: tmdbId,
        isTv: isTv,
      );
    } catch (e) {
      // 任何异常都不影响主流程:回退媒体服务器搜索
      _log.warning('MP 本地库身份解析异常,回退搜索: $e');
      return null;
    }
  }

  Future<PlayProbe?> _probeByMpLibraryInner({
    required String title,
    String? year,
    String? mtype,
    int? tmdbId,
    bool isTv = false,
  }) async {
    final mpType = _mpMediaType(mtype);
    if (mpType == null) return null;
    final servers = await enabledServers();
    if (servers.isEmpty) return null;
    final target = servers.first;

    Future<String?> ask(Map<String, dynamic> query) async {
      try {
        final r = await _api.get<dynamic>(
          '/api/v1/mediaserver/exists',
          queryParameters: query,
        );
        final data = r.data;
        if (data is! Map || data['success'] != true) return null;
        final d = data['data'];
        final item = d is Map ? d['item'] : null;
        final id = item is Map ? (item['id']?.toString() ?? '') : '';
        return id.isEmpty ? null : id;
      } catch (e) {
        _log.warning('MP 本地库身份查询失败: $e');
        return null;
      }
    }

    // 先按 TMDB 标识精确查,再退回标题(+年份)——两者都是 MP 本地查询
    var id = tmdbId != null && tmdbId > 0
        ? await ask({'tmdbid': tmdbId, 'mtype': mpType})
        : null;
    id ??= await ask({
      'title': title,
      'mtype': mpType,
      if (year != null && year.isNotEmpty) 'year': year,
    });
    if (id == null) return null;

    // 多服务器时 MP 的返回不带服务器名:用一次条目直查确认这条 id 属于目标服务器,
    // 确认不了就走回退搜索(单服务器场景直接采信,不再打媒体服务器)
    if (servers.length > 1) {
      final kitTarget = await toKitServer(target);
      final svc = kitTarget == null ? null : _serviceFor(kitTarget);
      if (svc == null) return null;
      try {
        final it = await svc
            .getItemDetails(id)
            .timeout(const Duration(seconds: 8));
        if (it.id.isEmpty) return null;
      } catch (_) {
        return null;
      }
    }
    _log.warning(
        'MP本地库命中[$title] tmdb=$tmdbId type=$mpType -> 条目=$id 服务器=${target.name}');
    // ignore: avoid_print
    print('[PlayerLaunch] MP 本地库命中: $title tmdb=$tmdbId type=$mpType '
        '-> 条目=$id 服务器=${target.name}');
    return PlayProbe(
      serverName: target.name,
      itemId: id,
      isSeries: isTv,
    );
  }

  /// 网页播放回退:GET /api/v1/mediaserver/play/{itemid} 取播放页地址
  /// 首页「继续观看 / 最近添加」卡片直连播放(媒体服务器条目 id 已知)。
  /// 立即进入播放容器页,条目/流地址解析由容器页内部完成(见 [resolveForPlayback]),
  /// 剧集自动定位「下一集未看完的」。
  Future<void> playByItemId({
    required String itemId,
    String? serverName,
    String? serverType,
    bool fromStart = false,
    String? title,
    String? subtitle,
  }) async {
    startPlayback(
      itemId: itemId,
      serverName: serverName,
      serverType: serverType,
      fromStart: fromStart,
      title: title ?? '正在准备播放',
      subtitle: subtitle,
    );
  }

  /// 立即进入播放容器页(不等待解析):把"卡在详情页无反馈"
  /// 变成"播放页里有进度",ISO 等慢解析场景收益最大。
  void startPlayback({
    required String itemId,
    String? serverName,
    String? serverType,
    bool fromStart = false,
    bool autoNextEpisode = true,
    String title = '正在准备播放',
    String? subtitle,
    kit.MediaServerService? service,
    kit.MediaServer? server,
    List<kit.MediaItem>? episodes,
  }) {
    Get.toNamed<void>(
      '/player',
      arguments: PlayerPlayRequest(
        itemId: itemId,
        serverName: serverName,
        serverType: serverType,
        fromStart: fromStart,
        autoNextEpisode: autoNextEpisode,
        title: title,
        subtitle: subtitle,
        service: service,
        server: server,
        episodes: episodes,
      ),
    );
  }

  /// 解析播放会话(由播放容器页调用):定位条目 → 必要时自动选续播单集
  /// → 解析直连流地址(ISO 场景含原盘解析,耗时 1-2 秒)。
  Future<kit.PlayerSession> resolveForPlayback({
    required String itemId,
    String? serverName,
    String? serverType,
    bool fromStart = false,
    bool autoNextEpisode = true,
    kit.MediaServerService? service,
    kit.MediaServer? server,
    List<kit.MediaItem>? episodes,
  }) async {
    await _ensureKit();
    var svc = service;
    var srv = server;
    if (svc == null || srv == null) {
      srv = await _pickServer(serverName: serverName, serverType: serverType);
      if (srv == null) {
        throw Exception('未找到可用的媒体服务器配置');
      }
      svc = _serviceFor(srv);
      if (svc == null) {
        throw Exception('媒体服务器配置不完整');
      }
    }
    // 未配置本机账号时提示一次:Emby/Jellyfin 只对用户令牌的会话写进度,
    // API 密钥的播放进度会被服务端静默丢弃(继续观看不更新)。
    if (!_accountHintShown) {
      final account = await loadAccount(srv.name);
      if (account == null &&
          (srv.type == kit.ServerType.emby ||
              srv.type == kit.ServerType.jellyfin)) {
        _accountHintShown = true;
        ToastUtil.info(
          '提示:在「设置 → 系统设置 → 媒体服务器」配置本机账号后,播放进度才能同步',
          duration: const Duration(seconds: 4),
        );
      }
    }
    final kit.MediaItem item;
    try {
      item = await svc.getItemDetails(itemId);
    } catch (e) {
      throw _friendlyPlaybackError(e, srv);
    }
    var eps = episodes;
    var targetId = itemId;
    // 剧集标识:剧集条目用自身 id;「单集」条目(如从继续观看进入——Emby 的
    // 正在播放记录是单集级别)用其 seriesId。
    // 此前只在 type==series 时加载全集,单集入口拿不到 episodes → 播放页
    // 没有选集面板、下一集禁用、播完不连播(lanplayer 同源坑 9358eaf:
    // "home 的继续观看分支推单集详情 → episodes 为空没有选集按钮")。
    final seriesId = item.type == kit.MediaType.series
        ? item.id
        : (item.type == kit.MediaType.episode ? (item.seriesId ?? '') : '');
    if (autoNextEpisode && seriesId.isNotEmpty) {
      eps ??= await svc.getEpisodes(seriesId);
      if (eps.isNotEmpty && item.type == kit.MediaType.series) {
        // 剧集入口:定位「下一集未看完的」
        final next = eps.firstWhere(
          (e) => (e.watchProgress ?? 0) < 1,
          orElse: () => eps!.first,
        );
        targetId = next.id;
      }
      // 单集入口:targetId 保持为该集(尊重续播点),此处只补全选集列表
    }
    final kit.PlayerSession session;
    try {
      session = await kit.PlaybackResolver.resolve(
        service: svc,
        server: srv,
        itemId: targetId,
        episodes: eps,
      );
    } catch (e) {
      throw _friendlyPlaybackError(e, srv);
    }
    return fromStart ? _sessionFromStart(session) : session;
  }

  /// 连接类异常 → 面向用户的提示(带当前地址,并区分"两地址均不可达"
  /// 与"单个地址连不上")。非连接类异常原样返回,不掩盖真实原因。
  Object _friendlyPlaybackError(Object e, kit.MediaServer srv) {
    final msg = e.toString();
    final lower = msg.toLowerCase();
    final isConn = lower.contains('timeout') ||
        lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('connection error') ||
        lower.contains('failed host lookup') ||
        lower.contains('所有地址连接失败');
    if (!isConn) return e;
    if (_degraded.containsKey(srv.name)) {
      return PlaybackError(
        '无法连接媒体服务器\n'
        '内网地址与外网(反代)地址均探测失败\n'
        '当前地址:${srv.url}\n'
        '请检查手机网络,或用浏览器确认该反代地址可正常打开',
      );
    }
    return PlaybackError(
      '无法连接媒体服务器:${srv.url}\n'
      '请检查网络,或在「设置 → 系统设置 → 媒体服务器」中更换地址',
    );
  }

  /// 从媒体服务器拉取条目详情(用于反查 TMDB 身份)
  Future<kit.MediaItem?> fetchKitItem({
    required String itemId,
    String? serverName,
    String? serverType,
  }) async {
    final server = await _pickServer(serverName: serverName, serverType: serverType);
    if (server == null) return null;
    final service = _serviceFor(server);
    if (service == null) return null;
    try {
      return await service.getItemDetails(itemId);
    } catch (e) {
      // 与播放路径同源(「最近添加」卡片点进详情页会先走这里):连接类失败
      // 换成人话提示,原始超时异常只写日志。
      _log.warning('fetchKitItem[${server.name}] 失败: $e');
      throw _friendlyPlaybackError(e, server);
    }
  }

  /// 详情页播放入口(电影直连 / 剧集默认播下一集未看完的)。
  /// 立即进入播放容器页,解析在页内完成。
  Future<void> playProbe({
    required PlayProbe probe,
    bool fromStart = false,
    String? title,
    String? subtitle,
  }) async {
    startPlayback(
      itemId: probe.itemId,
      serverName: probe.serverName,
      fromStart: fromStart,
      autoNextEpisode: probe.isSeries,
      title: title ?? '正在准备播放',
      subtitle: subtitle,
    );
  }

  /// 选集播放(详情页选集弹层 / 浏览详情页):立即进入播放容器页,
  /// service/server/episodes 已就绪直接传入,不再重复定位。
  Future<void> playEpisodeItem({
    required kit.MediaServerService service,
    required kit.MediaServer server,
    required kit.MediaItem episode,
    List<kit.MediaItem>? episodes,
    bool fromStart = false,
  }) async {
    startPlayback(
      itemId: episode.id,
      fromStart: fromStart,
      autoNextEpisode: false,
      title: episode.title.isNotEmpty ? episode.title : '正在准备播放',
      service: service,
      server: server,
      episodes: episodes,
    );
  }

  /// 首页「继续观看」卡片带上下文的播放(续播/从头看)。
  /// 统一走 playByItemId:剧集自动定位「下一集未看完的单集」,
  /// 避免把剧集 ID 直接当单集丢给流接口(Emby 会 500)。
  Future<void> playLatestItem({
    required String itemId,
    String? serverName,
    String? serverType,
    bool fromStart = false,
    String? title,
    String? subtitle,
  }) {
    return playByItemId(
      itemId: itemId,
      serverName: serverName,
      serverType: serverType,
      fromStart: fromStart,
      title: title,
      subtitle: subtitle,
    );
  }

  kit.PlayerSession _sessionFromStart(kit.PlayerSession session) {
    return kit.PlayerSession(
      media: session.media,
      streamUrl: session.streamUrl,
      httpHeaders: session.httpHeaders,
      transcodeUrl: session.transcodeUrl,
      episodes: session.episodes,
      service: session.service,
      server: session.server,
      resumePositionMs: 0,
    );
  }

  Future<void> webPlay(String itemId) async {
    try {
      final response = await _api.get<dynamic>(
        '/api/v1/mediaserver/play/$itemId',
      );
      dynamic data = response.data;
      if (data is Map && data.containsKey('data')) data = data['data'];
      final url = data?.toString() ?? '';
      if (url.isEmpty || !url.startsWith('http')) {
        ToastUtil.info('媒体服务器未收录该影片');
        return;
      }
      await WebUtil.open(url: url);
    } catch (e) {
      _log.warning('网页播放回退失败: $e');
      ToastUtil.error('无法打开播放页');
    }
  }

  Future<kit.MediaServer?> _pickServer({
    String? serverName,
    String? serverType,
  }) async {
    final servers = await enabledServers();
    if (servers.isEmpty) return null;
    MediaServer? picked;
    for (final s in servers) {
      if (serverName != null && serverName.isNotEmpty && s.name == serverName) {
        picked = s;
        break;
      }
      if ((serverType ?? '').isNotEmpty &&
          s.type.toLowerCase() == serverType!.toLowerCase()) {
        picked = s;
        break;
      }
    }
    picked ??= servers.first;
    return await toKitServer(picked, isDefault: picked == servers.first);
  }

  void _push(kit.PlayerSession session) {
    Get.toNamed<void>('/player', arguments: session);
  }
}
