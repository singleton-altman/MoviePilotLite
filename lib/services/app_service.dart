import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/login/models/login_profile.dart';
import 'package:moviepilot_mobile/modules/plugin/models/installed_plugin_model_cache.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_model_cache.dart';
import 'package:moviepilot_mobile/utils/prefs_keys.dart';
import 'package:moviepilot_mobile/modules/login/models/login_response.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:moviepilot_mobile/services/realm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用全局服务
class AppService extends GetxService {
  static const Color _defaultPrimaryColor = Color(0xFF007AFF);

  final themeMode = ThemeMode.system.obs;
  final primaryColor = _defaultPrimaryColor.obs;
  final showSearchButton = true.obs;
  final enableDownloaderManager = false.obs;
  final enableSpecialDownload = false.obs;
  final useExternalBrowser = false.obs;
  final enableFetchMediaserverLibraryStatus = false.obs;

  // 背景图设置
  final backgroundImageBytes = Rxn<Uint8List>();
  final backgroundImageOpacity = 0.5.obs;
  final backgroundImageGradientTop = Colors.transparent.obs;
  final backgroundImageGradientBottom = Colors.black.obs;
  final backgroundImageEnabled = false.obs;
  final backgroundImageUseServer = false.obs;
  final backgroundImageServerUrl = ''.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    // 主题色：以 RGB 存储，读取后还原
    final r = prefs.getInt('primaryColorR');
    final g = prefs.getInt('primaryColorG');
    final b = prefs.getInt('primaryColorB');
    if (r != null && g != null && b != null) {
      primaryColor.value = Color.fromARGB(255, r, g, b);
    }
    showSearchButton.value = prefs.getBool('showSearchButton') ?? true;
    enableDownloaderManager.value =
        prefs.getBool('enableDownloaderManager') ?? false;
    enableSpecialDownload.value =
        prefs.getBool('enableSpecialDownload') ?? false;
    useExternalBrowser.value = isHarmonyOs
        ? true
        : prefs.getBool('useExternalBrowser') ?? false;
    enableFetchMediaserverLibraryStatus.value =
        prefs.getBool('enableFetchMediaserverLibraryStatus') ?? false;

    // 背景图设置
    backgroundImageEnabled.value =
        prefs.getBool('backgroundImageEnabled') ?? false;
    backgroundImageOpacity.value =
        prefs.getDouble('backgroundImageOpacity') ?? 0.5;
    backgroundImageUseServer.value =
        prefs.getBool('backgroundImageUseServer') ?? false;
    backgroundImageServerUrl.value =
        prefs.getString('backgroundImageServerUrl') ?? '';

    final imageBase64 = prefs.getString('backgroundImageBase64');
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        backgroundImageBytes.value = base64Decode(imageBase64);
      } catch (_) {}
    }

    final gradientTopValue = prefs.getInt('backgroundGradientTop');
    if (gradientTopValue != null) {
      backgroundImageGradientTop.value = Color(gradientTopValue);
    }
    final gradientBottomValue = prefs.getInt('backgroundGradientBottom');
    if (gradientBottomValue != null) {
      backgroundImageGradientBottom.value = Color(gradientBottomValue);
    }

    if (backgroundImageEnabled.value && backgroundImageUseServer.value) {
      await cacheBackgroundImageFromServerUrl();
    }

    if (kIsWeb) {
      final storedCookie = prefs.getString(kAppSessionCookieKey);
      if (storedCookie != null && storedCookie.isNotEmpty) {
        _cookie = storedCookie;
      }
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = mode;
    prefs.setInt('themeMode', mode.index);
    Get.forceAppUpdate();
  }

  Future<void> updatePrimaryColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    primaryColor.value = color;
    final r = (color.r * 255).round().clamp(0, 255).toInt();
    final g = (color.g * 255).round().clamp(0, 255).toInt();
    final b = (color.b * 255).round().clamp(0, 255).toInt();
    prefs.setInt('primaryColorR', r);
    prefs.setInt('primaryColorG', g);
    prefs.setInt('primaryColorB', b);
    Get.forceAppUpdate();
  }

  Future<void> updateShowSearchButton(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    showSearchButton.value = value;
    await prefs.setBool('showSearchButton', value);
  }

  Future<void> updateEnableDownloaderManager(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    enableDownloaderManager.value = value;
    await prefs.setBool('enableDownloaderManager', value);
  }

  Future<void> updateEnableSpecialDownload(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    enableSpecialDownload.value = value;
    await prefs.setBool('enableSpecialDownload', value);
  }

  Future<void> updateUseExternalBrowser(bool value) async {
    if (isHarmonyOs) {
      useExternalBrowser.value = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    useExternalBrowser.value = value;
    await prefs.setBool('useExternalBrowser', value);
  }

  Future<void> updateEnableFetchMediaserverLibraryStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    enableFetchMediaserverLibraryStatus.value = value;
    await prefs.setBool('enableFetchMediaserverLibraryStatus', value);
  }

  Future<void> updateBackgroundImageEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageEnabled.value = value;
    await prefs.setBool('backgroundImageEnabled', value);
  }

  Future<void> updateBackgroundImageOpacity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageOpacity.value = value;
    await prefs.setDouble('backgroundImageOpacity', value);
  }

  Future<void> updateBackgroundImageGradientTop(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageGradientTop.value = color;
    await prefs.setInt('backgroundGradientTop', color.toARGB32());
  }

  Future<void> updateBackgroundImageGradientBottom(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageGradientBottom.value = color;
    await prefs.setInt('backgroundGradientBottom', color.toARGB32());
  }

  Future<void> updateBackgroundImage(Uint8List? bytes) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageBytes.value = bytes;
    if (bytes != null) {
      await prefs.setString('backgroundImageBase64', base64Encode(bytes));
    } else {
      await prefs.remove('backgroundImageBase64');
    }
  }

  Future<void> updateBackgroundImageUseServer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageUseServer.value = value;
    await prefs.setBool('backgroundImageUseServer', value);
  }

  Future<void> updateBackgroundImageServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageServerUrl.value = url;
    await prefs.setString('backgroundImageServerUrl', url);
  }

  bool _isValidHttpUrl(String url) {
    final u = Uri.tryParse(url.trim());
    if (u == null) return false;
    if (!u.hasScheme) return false;
    return u.scheme == 'http' || u.scheme == 'https';
  }

  String _cacheBustingUrl(String url) {
    final uri = Uri.parse(url);
    final qp = Map<String, String>.from(uri.queryParameters);
    qp['_t'] = DateTime.now().millisecondsSinceEpoch.toString();
    qp['_r'] = math.Random().nextInt(1 << 30).toString();
    return uri.replace(queryParameters: qp).toString();
  }

  Future<bool> cacheBackgroundImageFromServerUrl() async {
    final raw = backgroundImageServerUrl.value.trim();
    if (!_isValidHttpUrl(raw)) return false;
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          responseType: ResponseType.bytes,
          headers: const {'cache-control': 'no-cache', 'pragma': 'no-cache'},
        ),
      );
      final resp = await dio.get<List<int>>(_cacheBustingUrl(raw));
      if (resp.statusCode != 200) return false;
      final data = resp.data;
      if (data == null || data.isEmpty) return false;
      await updateBackgroundImage(Uint8List.fromList(data));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageBytes.value = null;
    backgroundImageEnabled.value = false;
    await prefs.remove('backgroundImageBase64');
    await prefs.setBool('backgroundImageEnabled', false);
  }

  /// 基础URL
  String? _baseUrl;

  /// 缓存的cookie
  String? _cookie;

  /// 获取基础URL
  String? get baseUrl => _baseUrl;

  /// 设置基础URL
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  /// 清除基础URL
  void clearBaseUrl() {
    _baseUrl = null;
  }

  /// 检查是否有基础URL
  bool get hasBaseUrl => _baseUrl != null && _baseUrl!.isNotEmpty;

  /// 获取缓存的cookie
  String? get cookie => _cookie;

  LoginResponse? _loginResponse;

  LoginResponse? get loginResponse => _loginResponse;

  UserInfo? _userInfo;

  UserInfo? get userInfo => _userInfo;

  bool? _parsePermissionValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return null;
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  dynamic _permissionValueFromMap(Map<String, dynamic> source, String key) {
    if (source.containsKey(key)) return source[key];
    final normalizedKey = key.toLowerCase();
    for (final entry in source.entries) {
      if (entry.key.toLowerCase() == normalizedKey) {
        return entry.value;
      }
    }
    return null;
  }

  Map<String, dynamic> _permissionsFromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }

  LoginProfile? _findStoredProfile({
    String? server,
    String? username,
    int? userId,
    String? accessToken,
  }) {
    if (!Get.isRegistered<RealmService>()) return null;
    try {
      final profiles =
          Get.find<RealmService>().realm.all<LoginProfile>().toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (profiles.isEmpty) return null;

      final normalizedServer = server?.trim();
      final normalizedUsername = username?.trim().toLowerCase();
      for (final profile in profiles) {
        if (normalizedServer != null &&
            normalizedServer.isNotEmpty &&
            profile.server.trim() != normalizedServer) {
          continue;
        }
        if (userId != null && profile.userId == userId) {
          return profile;
        }
        if (accessToken != null &&
            accessToken.isNotEmpty &&
            profile.accessToken == accessToken) {
          return profile;
        }
        if (normalizedUsername != null &&
            normalizedUsername.isNotEmpty &&
            profile.username.trim().toLowerCase() == normalizedUsername) {
          return profile;
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void restoreSessionFromProfile(LoginProfile profile) {
    setBaseUrl(profile.server);
    _loginResponse = LoginResponse(
      accessToken: profile.accessToken,
      tokenType: profile.tokenType,
      superUser: profile.superUser,
      userId: profile.userId,
      userName: profile.userName,
      avatar: profile.avatar,
      level: profile.level,
      permissions: _permissionsFromJson(profile.permissionsJson),
      wizard: profile.wizard,
    );

    final currentUserId = _userInfo?.id;
    final normalizedProfileName = profile.userName.trim().toLowerCase();
    final normalizedUserInfoName = _userInfo?.name.trim().toLowerCase();
    final isSameUser =
        currentUserId == profile.userId ||
        (normalizedUserInfoName != null &&
            normalizedUserInfoName.isNotEmpty &&
            normalizedUserInfoName == normalizedProfileName);
    if (!isSameUser) {
      _userInfo = null;
    }
    _clearRestrictedPluginCachesIfNeeded();
  }

  LoginProfile? get currentStoredProfile {
    final login = _loginResponse;
    final user = _userInfo;
    return _findStoredProfile(
      server: _baseUrl,
      username: user?.name ?? login?.userName,
      userId: user?.id ?? login?.userId,
      accessToken: login?.accessToken,
    );
  }

  String get pluginCacheScopeKey {
    final profile = currentStoredProfile;
    final server = (_baseUrl ?? profile?.server ?? '').trim().toLowerCase();
    final userId =
        _userInfo?.id.toString() ??
        _loginResponse?.userId.toString() ??
        profile?.userId.toString();
    final username =
        _userInfo?.name ??
        _loginResponse?.userName ??
        profile?.username ??
        profile?.userName;
    final normalizedUsername = username?.trim().toLowerCase() ?? '';
    if (server.isEmpty) return '';
    if (userId != null && userId.isNotEmpty) {
      return '$server|$userId';
    }
    if (normalizedUsername.isNotEmpty) {
      return '$server|$normalizedUsername';
    }
    return '';
  }

  void _clearPluginCaches() {
    if (kIsWeb || !Get.isRegistered<RealmService>()) return;
    try {
      final scopeKey = pluginCacheScopeKey;
      if (scopeKey.isEmpty) return;
      final realm = Get.find<RealmService>().realm;
      final installed = realm
          .all<InstalledPluginModelCache>()
          .where((item) => matchesInstalledPluginScope(item.id, scopeKey))
          .toList();
      final market = realm
          .all<PluginModelCache>()
          .where((item) => matchesPluginMarketScope(item.id, scopeKey))
          .toList();
      realm.write(() {
        realm.deleteMany(installed);
        realm.deleteMany(market);
      });
    } catch (_) {}
  }

  void _clearRestrictedPluginCachesIfNeeded() {
    if (!canManage) {
      _clearPluginCaches();
    }
  }

  bool get isSuperuser {
    final userSuperuser = _userInfo?.isSuperuser;
    if (userSuperuser != null) return userSuperuser;

    final loginSuperuser = _loginResponse?.superUser;
    if (loginSuperuser != null) return loginSuperuser;

    final profileSuperuser = currentStoredProfile?.superUser;
    if (profileSuperuser != null) return profileSuperuser;

    return false;
  }

  bool hasPermission(String key, {bool defaultValue = false}) {
    if (isSuperuser) {
      return true;
    }

    final permissionSources = <Map<String, dynamic>>[];
    final userPermissions = _userInfo?.permissions;
    if (userPermissions != null && userPermissions.isNotEmpty) {
      permissionSources.add(userPermissions);
    }
    final loginPermissions = _loginResponse?.permissions;
    if (loginPermissions != null && loginPermissions.isNotEmpty) {
      permissionSources.add(loginPermissions);
    }
    final profilePermissions = currentStoredProfile?.permissionsJson;
    final parsedProfilePermissions = _permissionsFromJson(profilePermissions);
    if (parsedProfilePermissions.isNotEmpty) {
      permissionSources.add(parsedProfilePermissions);
    }

    for (final source in permissionSources) {
      final parsed = _parsePermissionValue(
        _permissionValueFromMap(source, key),
      );
      if (parsed != null) return parsed;
    }

    if (permissionSources.isEmpty) {
      return defaultValue;
    }
    return false;
  }

  bool get canDiscovery => hasPermission('discovery');

  /// 站点资源搜索（搜索结果页、详情内搜资源）
  bool get canSearch => hasPermission('search');

  bool get canSubscribe => hasPermission('subscribe');

  bool get canManage => hasPermission('manage');

  bool get hasLoggedInSession {
    final loginToken = _loginResponse?.accessToken?.trim();
    if (loginToken != null && loginToken.isNotEmpty) return true;
    final profileToken = currentStoredProfile?.accessToken.trim();
    return profileToken != null && profileToken.isNotEmpty;
  }

  /// TMDB/豆瓣等媒体目录搜索（与 Web 一致，不依赖 search 权限）
  bool get canBrowseMediaCatalog => hasLoggedInSession;

  bool get canAccessAppSettings => true;

  bool canAccessRoute(String? route, {bool defaultValue = true}) {
    final normalized = route?.trim();
    if (normalized == null || normalized.isEmpty) return true;

    if (normalized == '/settings') {
      return isSuperuser || canAccessAppSettings;
    }

    if (normalized.startsWith('/settings/app')) {
      return canAccessAppSettings;
    }

    if (normalized == '/search-result' ||
        normalized == '/search-media-result') {
      return canSearch;
    }

    if (normalized == '/system-message') {
      return isSuperuser;
    }

    if (normalized.startsWith('/subscribe') || normalized == '/workflow') {
      return canSubscribe;
    }

    if (normalized.startsWith('/settings') ||
        normalized == '/app/log' ||
        normalized == '/background-task-list' ||
        normalized == '/user-management') {
      return isSuperuser;
    }

    if (normalized == '/media-search-list' ||
        normalized == '/person-search-list' ||
        normalized == '/person-search-result') {
      return canBrowseMediaCatalog;
    }

    if (normalized == '/storage-list' ||
        normalized == '/directory-list' ||
        normalized == '/organize-scrape' ||
        normalized == '/site-sync' ||
        normalized == '/site-options' ||
        normalized == '/custom-rule' ||
        normalized == '/priority-rule' ||
        normalized == '/download-rule' ||
        normalized == '/downloader-config' ||
        normalized == '/mediaserver-config' ||
        normalized == '/media-organize' ||
        normalized.startsWith('/file-manager') ||
        normalized.startsWith('/plugin') ||
        normalized == '/site' ||
        normalized.startsWith('/site-')) {
      return canManage;
    }

    if (normalized.startsWith('/recommend') ||
        normalized.startsWith('/discover')) {
      return canDiscovery;
    }

    return defaultValue;
  }

  String accessDeniedMessage(String? route) {
    final normalized = route?.trim() ?? '';
    if (normalized == '/settings') {
      return '当前帐号无设置访问权限';
    }
    if (normalized.startsWith('/settings/app')) {
      return '当前帐号无应用设置权限';
    }
    if (normalized == '/search-result' ||
        normalized == '/search-media-result') {
      return '当前帐号无资源搜索权限';
    }
    if (normalized == '/system-message') {
      return '当前帐号无系统消息权限';
    }
    if (normalized.startsWith('/subscribe') || normalized == '/workflow') {
      return '当前帐号无订阅权限';
    }
    if (normalized.startsWith('/settings') || normalized == '/app/log') {
      return '当前帐号无系统设置权限';
    }
    if (normalized == '/user-management') {
      return '当前帐号无账户管理权限';
    }
    if (normalized.startsWith('/recommend') ||
        normalized.startsWith('/discover')) {
      return '当前帐号无发现内容权限';
    }
    if (normalized == '/background-task-list' ||
        normalized == '/storage-list' ||
        normalized == '/directory-list' ||
        normalized == '/organize-scrape' ||
        normalized == '/site-sync' ||
        normalized == '/site-options' ||
        normalized == '/custom-rule' ||
        normalized == '/priority-rule' ||
        normalized == '/download-rule' ||
        normalized == '/downloader-config' ||
        normalized == '/mediaserver-config' ||
        normalized == '/media-organize' ||
        normalized.startsWith('/file-manager') ||
        normalized.startsWith('/plugin') ||
        normalized == '/site' ||
        normalized.startsWith('/site-')) {
      return '当前帐号无管理权限';
    }
    return '当前帐号无权限访问该功能';
  }

  /// 设置缓存的cookie
  void setCookie(String cookie) {
    _cookie = cookie.isEmpty ? null : cookie;
    if (kIsWeb) {
      SharedPreferences.getInstance().then((p) async {
        if (cookie.isEmpty) {
          await p.remove(kAppSessionCookieKey);
        } else {
          await p.setString(kAppSessionCookieKey, cookie);
        }
      });
    }
  }

  /// 清除缓存的cookie
  void clearCookie() {
    _cookie = null;
    if (kIsWeb) {
      SharedPreferences.getInstance().then(
        (p) => p.remove(kAppSessionCookieKey),
      );
    }
  }

  /// 清除登录态（内存）
  void clearLoginState() {
    _loginResponse = null;
    _userInfo = null;
    _cookie = null;
    if (kIsWeb) {
      SharedPreferences.getInstance().then(
        (p) => p.remove(kAppSessionCookieKey),
      );
    }
  }

  saveProfile(String server, LoginResponse login) {
    final currentUserId = _userInfo?.id;
    final currentUserName = _userInfo?.name.trim().toLowerCase();
    final nextUserName = login.userName.trim().toLowerCase();
    _loginResponse = login;
    setBaseUrl(server);
    final isSameUser =
        currentUserId == login.userId ||
        (currentUserName != null &&
            currentUserName.isNotEmpty &&
            currentUserName == nextUserName);
    if (!isSameUser) {
      _userInfo = null;
    }
    _clearRestrictedPluginCachesIfNeeded();
  }

  void saveUserInfo(UserInfo userInfo) {
    _userInfo = userInfo;
    _clearRestrictedPluginCachesIfNeeded();
  }

  /// 检查是否有缓存的cookie
  bool get hasCookie => _cookie != null && _cookie!.isNotEmpty;

  LoginResponse? get latestLoginProfile => _loginResponse;

  String? get latestLoginProfileAccessToken => _loginResponse?.accessToken;

  bool get isHarmonyOs =>
      Platform.operatingSystem == 'ohos' ||
      Platform.operatingSystem == 'harmonyos';
}
