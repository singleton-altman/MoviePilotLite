import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class StorageService {
  static late SharedPreferences _prefs;
  static bool _initialized = false;
  static final Completer<void> _readyCompleter = Completer<void>();

  /// 等待 StorageService 初始化完成
  /// 在任何同步读取方法（getString/getJsonList 等）之前调用
  static Future<void> get ready async {
    if (_initialized) return;
    return _readyCompleter.future;
  }

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }

  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  static Future<void> setJson(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final value = _prefs.getString(key);
    if (value == null) return null;
    return jsonDecode(value) as Map<String, dynamic>;
  }

  static Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  static List<Map<String, dynamic>>? getJsonList(String key) {
    final value = _prefs.getString(key);
    if (value == null) return null;
    return (jsonDecode(value) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  static Future<void> clear() async {
    await _prefs.clear();
  }

  static Future<void> setSecure(String key, String value) async {
    await _prefs.setString('secure_$key', value);
  }

  static Future<String?> getSecure(String key) async {
    return _prefs.getString('secure_$key');
  }

  static Future<void> deleteSecure(String key) async {
    await _prefs.remove('secure_$key');
  }

  static Future<void> deleteAllSecure() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('secure_')).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  static const String serversKey = 'media_servers';
  static const String danmakuConfigKey = 'danmaku_configs';
  static const String subscriptionsKey = 'subscriptions';
  static const String watchHistoryKey = 'watch_history';
  static const String favoritesKey = 'favorites';
  static const String themeKey = 'theme_mode';
  static const String themeColorKey = 'theme_color';
  static const String defaultServerKey = 'default_server_id';
  static const String tmdbApiKey = 'tmdb_api_key';
  static const String moviePilotUrlKey = 'moviepilot_url';
  static const String moviePilotApiKey = 'moviepilot_api_key';
  static const String playerSettingsKey = 'player_settings';
  static const String danmakuUrlKey = 'danmaku_url';
  static const String danmakuApiKey = 'danmaku_api_key';

  /// 媒体库缓存前缀，实际 key 为 "media_library_cache_<serverId>"
  static const String mediaLibraryCachePrefix = 'media_library_cache_';
}


