import 'dart:async';

import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/login/models/login_profile.dart';
import 'package:moviepilot_mobile/modules/multifunction/models/multifunction_config.dart';
import 'package:moviepilot_mobile/modules/multifunction/models/multifunction_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/hive_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscribePosterItem {
  const SubscribePosterItem({required this.poster, required this.route});

  final String poster;
  final String route;
}

class SubscribeDashboardInfo {
  const SubscribeDashboardInfo({
    this.movieCount = 0,
    this.tvCount = 0,
    this.posters = const [],
    this.posterItems = const [],
  });

  final int movieCount;
  final int tvCount;
  final List<String> posters;
  final List<SubscribePosterItem> posterItems;
}

class DashboardCalendarEntry {
  const DashboardCalendarEntry({
    required this.airDate,
    required this.showName,
    required this.episodeCode,
    required this.poster,
  });

  final String airDate;
  final String showName;
  final String episodeCode;
  final String poster;
}

class DownloaderClientInfo {
  const DownloaderClientInfo({
    required this.name,
    this.type = '',
    this.host = '',
    this.username = '',
    this.password = '',
    this.downloadSpeed = 0,
    this.uploadSpeed = 0,
  });

  final String name;
  final String type;
  final String host;
  final String username;
  final String password;
  final double downloadSpeed;
  final double uploadSpeed;
}

class DownloaderDashboardInfo {
  const DownloaderDashboardInfo({
    this.totalDownloadSpeed = 0,
    this.totalUploadSpeed = 0,
    this.totalDownloadSize = 0,
    this.totalUploadSize = 0,
    this.clients = const [],
  });

  final double totalDownloadSpeed;
  final double totalUploadSpeed;
  final double totalDownloadSize;
  final double totalUploadSize;
  final List<DownloaderClientInfo> clients;
}

class CalendarDashboardInfo {
  const CalendarDashboardInfo({
    this.todayCount = 0,
    this.weekCount = 0,
    this.todayItems = const [],
    this.weekItems = const [],
  });

  final int todayCount;
  final int weekCount;
  final List<DashboardCalendarEntry> todayItems;
  final List<DashboardCalendarEntry> weekItems;
}

class SiteDashboardInfo {
  const SiteDashboardInfo({
    this.siteCount = 0,
    this.totalUpload = 0,
    this.totalDownload = 0,
  });

  final int siteCount;
  final double totalUpload;
  final double totalDownload;
}

class DashboardModuleViewModel {
  const DashboardModuleViewModel({
    required this.title,
    required this.route,
    required this.icon,
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    this.emptyText,
    required this.hasData,
    this.posters = const [],
  });

  final String title;
  final String route;
  final IconData icon;
  final Color accent;
  final String primaryText;
  final String secondaryText;
  final String? emptyText;
  final bool hasData;
  final List<String> posters;
}

class MultifunctionController extends GetxController {
  static const String _calendarSegmentPrefsKey =
      'multifunction_calendar_segment';

  final _appService = Get.find<AppService>();
  final _apiClient = Get.find<ApiClient>();

  final isLoadingDashboard = false.obs;

  final subscribeInfo = const SubscribeDashboardInfo().obs;
  final downloaderInfo = const DownloaderDashboardInfo().obs;
  final calendarInfo = const CalendarDashboardInfo().obs;
  final pluginInstalledCount = 0.obs;
  final userCount = 0.obs;
  final siteInfo = const SiteDashboardInfo().obs;
  final subscribeDataReady = false.obs;
  final calendarDataReady = false.obs;
  final downloaderDataReady = false.obs;
  final pluginDataReady = false.obs;
  final userDataReady = false.obs;
  final siteDataReady = false.obs;
  final sidebarNavItems = <PluginSidebarNavItem>[].obs;
  final sidebarNavDataReady = false.obs;
  final calendarSegment = 'today'.obs;
  Timer? _downloaderPollingTimer;
  var _isRefreshingDownloader = false;

  bool get canAccessDiscovery => _appService.canDiscovery;
  bool get canAccessSearch => _appService.canSearch;
  bool get canAccessSubscribe => _appService.canSubscribe;
  bool get canAccessManage => _appService.canManage;
  bool get canAccessSystemSettings => _appService.canAccessRoute('/settings');
  bool get canAccessUserManagement => _appService.isSuperuser;

  @override
  void onInit() {
    super.onInit();
    _loadCalendarSegment();
  }

  @override
  void onReady() {
    super.onReady();
    refreshDashboard();
    _startDownloaderPollingIfNeeded();
  }

  @override
  void onClose() {
    _stopDownloaderPolling();
    super.onClose();
  }

  Future<void> refreshDashboard() async {
    if (isLoadingDashboard.value) return;
    isLoadingDashboard.value = true;
    try {
      List<Map<String, dynamic>> subscribes = const [];
      if (canAccessSubscribe) {
        try {
          subscribes = await _fetchSubscribeItems();
          subscribeDataReady.value = true;
          _buildSubscribeInfo(subscribes);
          try {
            await _buildCalendarInfo(subscribes);
            calendarDataReady.value = true;
          } catch (_) {
            if (!calendarDataReady.value) {
              calendarInfo.value = const CalendarDashboardInfo();
            }
          }
        } catch (_) {
          if (!subscribeDataReady.value) {
            _buildSubscribeInfo(const []);
          }
        }
      } else {
        subscribeInfo.value = const SubscribeDashboardInfo();
        calendarInfo.value = const CalendarDashboardInfo();
        subscribeDataReady.value = false;
        calendarDataReady.value = false;
      }
      final dashboardTasks = <Future<void>>[
        _loadDownloaderInfo()
            .then((ok) {
              if (ok) downloaderDataReady.value = true;
            })
            .catchError((_) {}),
      ];
      if (canAccessManage) {
        dashboardTasks.addAll([
          _loadPluginCount()
              .then((ok) {
                if (ok) pluginDataReady.value = true;
              })
              .catchError((_) {}),
          _loadUserCount()
              .then((ok) {
                if (ok) userDataReady.value = true;
              })
              .catchError((_) {}),
          _loadSiteInfo()
              .then((ok) {
                if (ok) siteDataReady.value = true;
              })
              .catchError((_) {}),
          _loadSidebarNav()
              .then((ok) {
                if (ok) sidebarNavDataReady.value = true;
              })
              .catchError((_) {}),
        ]);
      } else {
        pluginInstalledCount.value = 0;
        userCount.value = 0;
        siteInfo.value = const SiteDashboardInfo();
        sidebarNavItems.clear();
        pluginDataReady.value = false;
        userDataReady.value = false;
        siteDataReady.value = false;
        sidebarNavDataReady.value = false;
      }
      await Future.wait(dashboardTasks);
    } finally {
      isLoadingDashboard.value = false;
      _startDownloaderPollingIfNeeded();
    }
  }

  Future<void> handleTap(MultifunctionItem item) async {
    await handleRouteTap(item.route, title: item.title);
  }

  Future<void> handleSidebarNavTap(PluginSidebarNavItem item) async {
    if (!canAccessManage) {
      ToastUtil.info(_appService.accessDeniedMessage('/plugin'));
      return;
    }
    if (item.pluginId.isEmpty) {
      ToastUtil.info('${item.title} 暂未开放');
      return;
    }
    final route = item.navKey == 'form'
        ? '/plugin/dynamic-form/form'
        : '/plugin/dynamic-form/page';
    if (!_appService.canAccessRoute(route)) {
      ToastUtil.info(_appService.accessDeniedMessage(route));
      return;
    }
    await Get.toNamed(
      route,
      arguments: {'id': item.pluginId, 'title': item.title},
    );
    if (!isClosed) {
      await refreshDashboard();
    }
  }

  Future<void> handleRouteTap(String? route, {String? title}) async {
    var targetRoute = route;
    if (!_appService.canAccessRoute(targetRoute)) {
      ToastUtil.info(_appService.accessDeniedMessage(targetRoute));
      return;
    }
    if (targetRoute == '/downloader' &&
        _appService.enableDownloaderManager.value) {
      targetRoute = '/downloader-config';
    }
    if (targetRoute != null && targetRoute.isNotEmpty) {
      await Get.toNamed(targetRoute);
      if (!isClosed) {
        await refreshDashboard();
      }
      return;
    }
    ToastUtil.info('${title ?? '该功能'} 暂未开放');
  }

  String downloaderRoute() {
    if (_appService.enableDownloaderManager.value) {
      return '/downloader-config';
    }
    return '/downloader';
  }

  Future<void> openDownloaderList() async {
    await handleRouteTap(downloaderRoute(), title: '下载器');
  }

  Future<void> openDownloaderClient(DownloaderClientInfo client) async {
    if (!_appService.canAccessRoute('/downloader') &&
        !_appService.canAccessRoute('/downloader-config')) {
      ToastUtil.info(_appService.accessDeniedMessage('/downloader'));
      return;
    }
    if (_appService.enableDownloaderManager.value) {
      final type = _downloaderDetailType(client.type);
      if (type == null) {
        ToastUtil.warning('下载器类型不支持');
        return;
      }
      var host = client.host.trim();
      var username = client.username;
      var password = client.password;
      if (host.isEmpty) {
        final settings = await _loadDownloaderSettingsByName();
        final setting = settings[client.name];
        final settingConfig = setting?['config'] is Map
            ? Map<String, dynamic>.from(setting!['config'] as Map)
            : const <String, dynamic>{};
        host = _firstNonEmpty([settingConfig['host'], setting?['host']]);
        username = _firstNonEmpty([
          username,
          settingConfig['username'],
          setting?['username'],
        ]);
        password = _firstNonEmpty([
          password,
          settingConfig['password'],
          setting?['password'],
        ]);
      }
      if (host.isEmpty) {
        ToastUtil.warning('下载器地址为空，请先在下载器配置中完善连接信息');
        return;
      }
      await Get.toNamed(
        '/downloader-detail',
        arguments: {
          'config': {
            'id': client.name,
            'url': host,
            'username': username,
            'password': password,
            'type': type,
            'name': client.name,
          },
        },
      );
    } else {
      await Get.toNamed('/downloader', parameters: {'name': client.name});
    }
    if (!isClosed) {
      await refreshDownloaderSection();
    }
  }

  DownloaderType? _downloaderDetailType(String type) {
    switch (type.toLowerCase()) {
      case 'qbittorrent':
        return DownloaderType.qbittorrent;
      case 'transmission':
        return DownloaderType.transmission;
      default:
        return null;
    }
  }

  Future<void> setCalendarSegment(String segment) async {
    if (segment != 'today' && segment != 'week') return;
    calendarSegment.value = segment;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calendarSegmentPrefsKey, segment);
  }

  /// 仅刷新多功能页的订阅区数据（电影/剧集计数与海报），避免全量刷新。
  Future<void> refreshSubscribeSection() async {
    if (!canAccessSubscribe) {
      subscribeDataReady.value = false;
      _buildSubscribeInfo(const []);
      return;
    }
    try {
      final subscribes = await _fetchSubscribeItems();
      subscribeDataReady.value = true;
      _buildSubscribeInfo(subscribes);
    } catch (_) {
      subscribeDataReady.value = false;
      _buildSubscribeInfo(const []);
    }
  }

  /// 仅刷新下载管理区数据，供定时器轮询使用。
  Future<void> refreshDownloaderSection() async {
    if (_isRefreshingDownloader) return;
    if (!_hasAuthSession()) {
      downloaderDataReady.value = false;
      downloaderInfo.value = const DownloaderDashboardInfo();
      _stopDownloaderPolling();
      return;
    }
    _isRefreshingDownloader = true;
    try {
      final ok = await _loadDownloaderInfo();
      if (ok) downloaderDataReady.value = true;
    } catch (_) {
      // 保留已有数据，避免轮询失败清空列表
    } finally {
      _isRefreshingDownloader = false;
    }
  }

  String? _normalizeUsername(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.toLowerCase();
  }

  String? _latestProfileUsername() {
    if (!Get.isRegistered<HiveService>()) return null;
    try {
      final profiles = Get.find<HiveService>().loginProfileBox.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (profiles.isEmpty) return null;
      return _normalizeUsername(profiles.first.username);
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> _currentUsernames() async {
    final usernames = <String>{};

    final profileUsername = _latestProfileUsername();
    if (profileUsername != null) {
      usernames.add(profileUsername);
    }

    final loginUsername = _normalizeUsername(
      _appService.loginResponse?.userName,
    );
    if (loginUsername != null) {
      usernames.add(loginUsername);
    }

    final userInfoName = _normalizeUsername(_appService.userInfo?.name);
    if (userInfoName != null) {
      usernames.add(userInfoName);
    }

    return usernames;
  }

  bool _matchesCurrentUser(
    Map<String, dynamic> item,
    Set<String> currentUsernames,
  ) {
    if (_appService.isSuperuser) return true;
    if (currentUsernames.isEmpty) return true;
    final itemUsername = _normalizeUsername(item['username']?.toString());
    if (itemUsername == null) return false;
    return currentUsernames.contains(itemUsername);
  }

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  Future<List<Map<String, dynamic>>> _fetchSubscribeItems() async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/subscribe/',
      token: _getToken(),
    );
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw Exception('subscribe request failed');
    }
    final currentUsernames = await _currentUsernames();
    final raw = response.data;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .where((item) => _matchesCurrentUser(item, currentUsernames))
          .toList();
    }
    if (raw is Map<String, dynamic> && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map<String, dynamic>>()
          .where((item) => _matchesCurrentUser(item, currentUsernames))
          .toList();
    }
    return const [];
  }

  void _buildSubscribeInfo(List<Map<String, dynamic>> subscribes) {
    var movieCount = 0;
    var tvCount = 0;
    final posters = <String>[];
    final posterItems = <SubscribePosterItem>[];
    for (final item in subscribes) {
      final type = (item['type']?.toString() ?? '').trim().toLowerCase();
      String route = '/subscribe-tv';
      if (type.contains('movie') || type.contains('电影')) {
        movieCount++;
        route = '/subscribe-movie';
      } else if (type.contains('tv') || type.contains('电视剧')) {
        tvCount++;
        route = '/subscribe-tv';
      }
      final poster = (item['poster']?.toString() ?? '').trim();
      if (poster.isNotEmpty) {
        posters.add(poster);
        posterItems.add(SubscribePosterItem(poster: poster, route: route));
      }
    }
    subscribeInfo.value = SubscribeDashboardInfo(
      movieCount: movieCount,
      tvCount: tvCount,
      posters: posters.take(5).toList(),
      posterItems: posterItems.take(8).toList(),
    );
  }

  Future<void> _buildCalendarInfo(List<Map<String, dynamic>> subscribes) async {
    final tvItems = subscribes
        .where((item) {
          final type = (item['type']?.toString() ?? '').trim().toLowerCase();
          return type.contains('tv') || type.contains('电视剧');
        })
        .take(12)
        .toList();
    final today = DateTime.now().toUtc();
    final todayStr = _dateOnly(today);
    final weekEndStr = _dateOnly(today.add(const Duration(days: 6)));
    var todayCount = 0;
    var weekCount = 0;
    final todayEntries = <DashboardCalendarEntry>[];
    final weekEntries = <DashboardCalendarEntry>[];
    for (final item in tvItems) {
      final tmdbId = _asInt(item['tmdbid']);
      if (tmdbId <= 0) continue;
      final season = _asInt(item['season']) > 0 ? _asInt(item['season']) : 1;
      final showName = (item['name']?.toString() ?? '').trim();
      final poster = normalizePoster((item['poster']?.toString() ?? '').trim());
      final response = await _apiClient.get<dynamic>(
        '/api/v1/tmdb/$tmdbId/$season',
        token: _getToken(),
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) continue;
      final episodes = _extractList(response.data);
      for (final episode in episodes) {
        final date = (episode['air_date']?.toString() ?? '').trim();
        if (date.isEmpty) continue;
        if (date.compareTo(todayStr) < 0) continue;
        final epNo = _asInt(episode['episode_number']);
        final seasonNo = _asInt(episode['season_number']) > 0
            ? _asInt(episode['season_number'])
            : season;
        final code = epNo > 0
            ? 'S${seasonNo.toString().padLeft(2, '0')}E${epNo.toString().padLeft(2, '0')}'
            : 'S${seasonNo.toString().padLeft(2, '0')}';
        final entry = DashboardCalendarEntry(
          airDate: date,
          showName: showName.isEmpty ? '剧集 $tmdbId' : showName,
          episodeCode: code,
          poster: poster,
        );
        if (date == todayStr) todayCount++;
        if (date == todayStr) {
          todayEntries.add(entry);
        }
        if (date.compareTo(weekEndStr) <= 0) {
          if (date != todayStr) {
            weekCount++;
          }
          weekEntries.add(entry);
        }
      }
    }
    todayEntries.sort((a, b) => a.episodeCode.compareTo(b.episodeCode));
    weekEntries.sort((a, b) {
      final cmp = a.airDate.compareTo(b.airDate);
      if (cmp != 0) return cmp;
      return a.episodeCode.compareTo(b.episodeCode);
    });
    final upcomingWeekEntries = weekEntries
        .where((entry) => entry.airDate != todayStr)
        .toList();
    calendarInfo.value = CalendarDashboardInfo(
      todayCount: todayCount,
      weekCount: weekCount,
      todayItems: todayEntries.take(3).toList(),
      weekItems: upcomingWeekEntries.take(4).toList(),
    );
  }

  Future<bool> _loadDownloaderInfo() async {
    final clientsResp = await _apiClient.get<List<dynamic>>(
      '/api/v1/download/clients',
    );
    if ((clientsResp.statusCode ?? 0) >= 400 || clientsResp.data == null) {
      if (!downloaderDataReady.value) {
        downloaderInfo.value = const DownloaderDashboardInfo();
      }
      return false;
    }
    final clients = clientsResp.data!
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => (e['name']?.toString() ?? '').trim().isNotEmpty)
        .toList();
    final settingsByName = await _loadDownloaderSettingsByName();
    final info = <DownloaderClientInfo>[];
    var totalDownSpeed = 0.0;
    var totalUpSpeed = 0.0;
    var totalDownSize = 0.0;
    var totalUpSize = 0.0;
    for (final client in clients) {
      final name = (client['name']?.toString() ?? '').trim();
      final setting = settingsByName[name];
      final clientConfig = client['config'] is Map
          ? Map<String, dynamic>.from(client['config'] as Map)
          : const <String, dynamic>{};
      final settingConfig = setting?['config'] is Map
          ? Map<String, dynamic>.from(setting!['config'] as Map)
          : const <String, dynamic>{};
      final type = _firstNonEmpty([client['type'], setting?['type']]);
      final host = _firstNonEmpty([
        clientConfig['host'],
        settingConfig['host'],
        client['host'],
        setting?['host'],
      ]);
      final username = _firstNonEmpty([
        clientConfig['username'],
        settingConfig['username'],
        client['username'],
        setting?['username'],
      ]);
      final password = _firstNonEmpty([
        clientConfig['password'],
        settingConfig['password'],
        client['password'],
        setting?['password'],
      ]);
      final resp = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/dashboard/downloader',
        queryParameters: {'name': name},
      );
      var downSpeed = 0.0;
      var upSpeed = 0.0;
      if ((resp.statusCode ?? 0) < 400 && resp.data != null) {
        final data = resp.data!;
        downSpeed = _asDouble(data['download_speed']);
        upSpeed = _asDouble(data['upload_speed']);
        totalDownSpeed += downSpeed;
        totalUpSpeed += upSpeed;
        totalDownSize += _asDouble(data['download_size']);
        totalUpSize += _asDouble(data['upload_size']);
      }
      info.add(
        DownloaderClientInfo(
          name: name,
          type: type,
          host: host,
          username: username,
          password: password,
          downloadSpeed: downSpeed,
          uploadSpeed: upSpeed,
        ),
      );
    }
    downloaderInfo.value = DownloaderDashboardInfo(
      totalDownloadSpeed: totalDownSpeed,
      totalUploadSpeed: totalUpSpeed,
      totalDownloadSize: totalDownSize,
      totalUploadSize: totalUpSize,
      clients: info,
    );
    refresh();
    return true;
  }

  Future<Map<String, Map<String, dynamic>>>
  _loadDownloaderSettingsByName() async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/system/setting/Downloaders',
      );
      if ((response.statusCode ?? 0) >= 400 || response.data is! Map) {
        return const {};
      }
      final root = Map<String, dynamic>.from(response.data as Map);
      final data = root['data'];
      final value = data is Map ? data['value'] : null;
      if (value is! List) return const {};
      final result = <String, Map<String, dynamic>>{};
      for (final item in value) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final name = (map['name']?.toString() ?? '').trim();
        if (name.isEmpty) continue;
        result[name] = map;
      }
      return result;
    } catch (_) {
      return const {};
    }
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<bool> _loadPluginCount() async {
    if (!canAccessManage) {
      pluginInstalledCount.value = 0;
      return false;
    }
    final response = await _apiClient.get<dynamic>(
      '/api/v1/plugin/',
      queryParameters: {'state': 'installed'},
    );
    if ((response.statusCode ?? 0) >= 400) {
      pluginInstalledCount.value = 0;
      return false;
    }
    final raw = response.data;
    if (raw is List) {
      pluginInstalledCount.value = raw.length;
      return true;
    }
    pluginInstalledCount.value = 0;
    return false;
  }

  Future<bool> _loadUserCount() async {
    if (!canAccessManage) {
      userCount.value = 0;
      return false;
    }
    final response = await _apiClient.get<dynamic>('/api/v1/user/');
    if ((response.statusCode ?? 0) >= 400) {
      userCount.value = 0;
      return false;
    }
    final raw = response.data;
    if (raw is List) {
      userCount.value = raw.length;
      return true;
    }
    userCount.value = 0;
    return false;
  }

  Future<bool> _loadSidebarNav() async {
    if (!canAccessManage) {
      sidebarNavItems.clear();
      return false;
    }
    final response = await _apiClient.get<dynamic>(
      '/api/v1/plugin/sidebar_nav',
    );
    if ((response.statusCode ?? 0) >= 400) {
      sidebarNavItems.clear();
      return false;
    }
    final raw = response.data;
    if (raw is! List) {
      sidebarNavItems.clear();
      return false;
    }
    final items =
        raw
            .whereType<Map<String, dynamic>>()
            .map(PluginSidebarNavItem.fromJson)
            .where((item) {
              if (item.pluginId.isEmpty || item.title.isEmpty) return false;
              if (item.permission == 'manage') return canAccessManage;
              return true;
            })
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    sidebarNavItems.assignAll(items);
    return true;
  }

  Future<bool> _loadSiteInfo() async {
    if (!canAccessManage) {
      siteInfo.value = const SiteDashboardInfo();
      return false;
    }
    final siteResp = await _apiClient.get<dynamic>('/api/v1/site/');
    var count = 0;
    var siteOk = false;
    if ((siteResp.statusCode ?? 0) < 400) {
      final raw = siteResp.data;
      if (raw is List) {
        siteOk = true;
        count = raw.where((e) {
          if (e is! Map<String, dynamic>) return false;
          return _asInt(e['id']) != -1;
        }).length;
      }
    }

    final userDataResp = await _apiClient.get<dynamic>(
      '/api/v1/site/userdata/latest',
    );
    var totalUpload = 0.0;
    var totalDownload = 0.0;
    var userdataOk = false;
    if ((userDataResp.statusCode ?? 0) < 400) {
      final raw = userDataResp.data;
      if (raw is List) {
        userdataOk = true;
        for (final item in raw.whereType<Map<String, dynamic>>()) {
          totalUpload += _asDouble(item['upload']);
          totalDownload += _asDouble(item['download']);
        }
      }
    }
    siteInfo.value = SiteDashboardInfo(
      siteCount: count,
      totalUpload: totalUpload,
      totalDownload: totalDownload,
    );
    return siteOk || userdataOk;
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    if (raw is Map<String, dynamic> && raw['data'] is List) {
      return (raw['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  String normalizePoster(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final url = ImageUtil.convertCacheImageUrl(raw);
    return url.isNotEmpty ? url : trimmed;

    // if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    //   return trimmed;
    // }
    // if (trimmed.startsWith('/')) {
    //   return 'https://image.tmdb.org/t/p/w300$trimmed';
    // }
    // return trimmed;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _dateOnly(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<DashboardModuleViewModel> buildDashboardModules() {
    final infoSubscribe = subscribeInfo.value;
    final infoDownloader = downloaderInfo.value;
    final infoCalendar = calendarInfo.value;
    final infoSite = siteInfo.value;
    final posters = infoSubscribe.posters
        .map(normalizePoster)
        .where((e) => e.isNotEmpty)
        .toList();
    final allItems = multifunctionSections
        .expand((section) => section.items)
        .where((item) => _appService.canAccessRoute(item.route))
        .toList();
    final modules = allItems.map((item) {
      final route = item.route ?? '';
      switch (route) {
        case '/subscribe-movie':
          return DashboardModuleViewModel(
            title: item.title,
            route: route,
            icon: item.icon,
            accent: item.accent,
            primaryText: '电影订阅 ${infoSubscribe.movieCount}',
            secondaryText: '电视订阅 ${infoSubscribe.tvCount}',

            hasData: subscribeDataReady.value,
            posters: posters,
          );
        case '/subscribe-tv':
          return DashboardModuleViewModel(
            title: item.title,
            route: route,
            icon: item.icon,
            accent: item.accent,
            primaryText: '电视订阅 ${infoSubscribe.tvCount}',
            secondaryText: '电影订阅 ${infoSubscribe.movieCount}',
            hasData: subscribeDataReady.value,
            posters: posters,
          );
        case '/subscribe-calendar':
          return DashboardModuleViewModel(
            title: item.title,
            route: route,
            icon: item.icon,
            accent: item.accent,
            primaryText: '今天上映 ${infoCalendar.todayCount}',
            secondaryText: '本周上映 ${infoCalendar.weekCount}',
            hasData: calendarDataReady.value,
          );
        case '/downloader':
          return DashboardModuleViewModel(
            title: item.title,
            route: route,
            icon: item.icon,
            accent: item.accent,
            primaryText:
                '下行 ${_formatSpeed(infoDownloader.totalDownloadSpeed)} / 上行 ${_formatSpeed(infoDownloader.totalUploadSpeed)}',
            secondaryText: '在线下载器 ${infoDownloader.clients.length}',
            hasData: downloaderDataReady.value,
          );
        case '/plugin':
          return DashboardModuleViewModel(
            title: item.title,
            route: route,
            icon: item.icon,
            accent: item.accent,
            primaryText: '',
            secondaryText: '插件中心与扩展能力',
            hasData: pluginDataReady.value,
          );
        case '/user-management':
          return DashboardModuleViewModel(
            title: item.title,
            route: route,
            icon: item.icon,
            accent: item.accent,
            primaryText: '用户总数 ${userCount.value}',
            secondaryText: '账号、角色与权限管理',
            hasData: userDataReady.value,
          );
        case '/site':
          return DashboardModuleViewModel(
            title: item.title,
            route: route,
            icon: item.icon,
            accent: item.accent,
            primaryText: '站点总数 ${infoSite.siteCount}',
            secondaryText:
                '上传 ${_formatSize(infoSite.totalUpload)} / 下载 ${_formatSize(infoSite.totalDownload)}',
            hasData: siteDataReady.value,
          );
        default:
          return DashboardModuleViewModel(
            title: item.title,
            route: route,
            icon: item.icon,
            accent: item.accent,
            primaryText: item.subtitle?.isNotEmpty == true
                ? item.subtitle!
                : '${item.title} 功能入口',
            secondaryText: '点击进入 ${item.title}',
            hasData: false,
          );
      }
    }).toList();

    modules.sort(
      (a, b) => _modulePriority(a.route).compareTo(_modulePriority(b.route)),
    );
    return modules;
  }

  static const List<String> _dashboardOrder = [
    '/subscribe-movie',
    '/subscribe-tv',
    '/subscribe-calendar',
    '/downloader',
    '/media-organize',
    '/file-manager',
    '/plugin',
    '/user-management',
    '/site',
    '/workflow',
  ];

  int _modulePriority(String route) {
    final index = _dashboardOrder.indexOf(route);
    if (index >= 0) return index;
    return _dashboardOrder.length + 1;
  }

  String _formatSpeed(double value) {
    final amount = _formatSize(value);
    return '$amount/s';
  }

  String _formatSize(double value) {
    final units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = value;
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final fixed = size >= 100
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$fixed ${units[unitIndex]}';
  }

  Future<void> _loadCalendarSegment() async {
    final prefs = await SharedPreferences.getInstance();
    final segment = prefs.getString(_calendarSegmentPrefsKey);
    if (segment == 'today' || segment == 'week') {
      calendarSegment.value = segment!;
    }
  }

  bool _hasAuthSession() {
    return true;
  }

  Duration get _downloaderPollingInterval {
    if (kReleaseMode) {
      return const Duration(seconds: 10);
    }
    return const Duration(seconds: 60);
  }

  void _startDownloaderPollingIfNeeded() {
    if (!_hasAuthSession()) {
      _stopDownloaderPolling();
      return;
    }
    _downloaderPollingTimer?.cancel();
    _downloaderPollingTimer = Timer.periodic(_downloaderPollingInterval, (_) {
      if (!_hasAuthSession()) {
        _stopDownloaderPolling();
        return;
      }
      refreshDownloaderSection();
    });
  }

  void _stopDownloaderPolling() {
    _downloaderPollingTimer?.cancel();
    _downloaderPollingTimer = null;
  }
}
