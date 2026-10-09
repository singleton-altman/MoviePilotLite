import 'dart:convert';
import 'dart:io';
import 'package:fast_gbk/fast_gbk.dart';
import '../utils/app_log.dart';
import 'http_client.dart';
import 'storage_service.dart';

/// OpenSubtitles.com 在线字幕服务（REST API v1）
///
/// 需要用户在设置里填写 OpenSubtitles 账号（用户名/密码）与 API Key：
/// - API Key 在 https://opensubtitles.com 注册后在「Account → Developers」页生成
/// - 登录接口换取 JWT token，之后搜索/下载都带 token
///
/// 数据流：login → search → download(file_id) → gzip 解压 → UTF-8/GBK 解码 → SRT 内容
class OpenSubtitlesService {
  static const _base = 'https://api.opensubtitles.com/api/v1';
  static const _userAgent = 'LanPlayer v1.0';

  static const _keyApiKey = 'opensubtitles_api_key';
  static const _keyUsername = 'opensubtitles_username';
  static const _keyPassword = 'opensubtitles_password';

  String? _token;

  // ─── 配置存取 ───

  static String? get apiKey => StorageService.getString(_keyApiKey);
  static String? get username => StorageService.getString(_keyUsername);
  static String? get password => StorageService.getString(_keyPassword);

  static bool get isConfigured => apiKey != null && apiKey!.isNotEmpty && username != null && username!.isNotEmpty;

  static Future<void> saveConfig({String? apiKey, String? username, String? password}) async {
    if (apiKey != null) await StorageService.setString(_keyApiKey, apiKey);
    if (username != null) await StorageService.setString(_keyUsername, username);
    if (password != null) await StorageService.setString(_keyPassword, password);
  }

  /// 清除账号密码（保留 API Key，方便换账号）
  static Future<void> clearCredentials() async {
    await StorageService.setString(_keyUsername, '');
    await StorageService.setString(_keyPassword, '');
  }

  // ─── 认证 ───

  Map<String, String> _headers({bool auth = true}) {
    return {
      'Api-Key': apiKey ?? '',
      'User-Agent': _userAgent,
      if (auth && _token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// 登录换取 token（幂等：已有 token 直接返回）
  Future<String?> login() async {
    if (_token != null) return _token;
    final user = username;
    final pass = password;
    final key = apiKey;
    if (key == null || key.isEmpty || user == null || user.isEmpty || pass == null || pass.isEmpty) {
      AppLog.w('OpenSubtitles', '未配置账号或 API Key，无法登录');
      return null;
    }
    try {
      final data = await HttpClient.postJson(
        '$_base/login',
        headers: {'Api-Key': key, 'User-Agent': _userAgent, 'Content-Type': 'application/json'},
        data: {'username': user, 'password': pass},
      );
      final token = (data as Map<String, dynamic>)['token'];
      if (token is String && token.isNotEmpty) {
        _token = token;
        AppLog.i('OpenSubtitles', '登录成功');
        return token;
      }
      AppLog.w('OpenSubtitles', '登录失败: ${data['message'] ?? data}');
      return null;
    } catch (e) {
      AppLog.e('OpenSubtitles', '登录异常: $e');
      return null;
    }
  }

  // ─── 搜索 ───

  /// 按标题搜索字幕，返回候选列表
  Future<List<OpenSubtitleItem>> search({
    required String query,
    int? season,
    int? episode,
    String languages = 'zh-cn,zh,en',
  }) async {
    final token = await login();
    if (token == null) throw const OpenSubtitlesException('登录失败，请检查 OpenSubtitles 账号与 API Key');
    try {
      final data = await HttpClient.getJson(
        '$_base/subtitles',
        headers: _headers(),
        query: {
          'query': query,
          if (season != null) 'season_number': '$season',
          if (episode != null) 'episode_number': '$episode',
          'languages': languages,
          'order_by': 'download_count',
          'order_direction': 'desc',
        },
        timeout: const Duration(seconds: 20),
      );
      final list = (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
      final items = <OpenSubtitleItem>[];
      for (final raw in list) {
        final map = raw as Map<String, dynamic>;
        final attrs = (map['attributes'] ?? const {}) as Map<String, dynamic>;
        final files = (attrs['files'] ?? const []) as List<dynamic>;
        if (files.isEmpty) continue;
        items.add(OpenSubtitleItem(
          id: map['id'],
          title: attrs['title'] ?? '',
          language: attrs['language'] ?? '',
          release: attrs['release'] ?? '',
          uploader: attrs['uploader']?['name'] ?? '',
          season: attrs['season_number'],
          episode: attrs['episode_number'],
          downloads: attrs['download_count'] ?? 0,
          fileId: (files.first as Map<String, dynamic>)['file_id'],
          fileName: (files.first as Map<String, dynamic>)['file_name'] ?? '',
        ));
      }
      AppLog.i('OpenSubtitles', '搜索 "$query" 命中 ${items.length} 条');
      return items;
    } catch (e) {
      AppLog.e('OpenSubtitles', '搜索异常: $e');
      rethrow;
    }
  }

  // ─── 下载 ───

  /// 下载并解码字幕，返回 SRT/ASS 文本内容
  Future<String> download(OpenSubtitleItem item) async {
    final token = await login();
    if (token == null) throw const OpenSubtitlesException('登录失败，请检查 OpenSubtitles 账号与 API Key');
    try {
      final data = await HttpClient.postJson(
        '$_base/download',
        headers: _headers(),
        data: {'file_id': item.fileId},
        timeout: const Duration(seconds: 20),
      );
      final link = (data as Map<String, dynamic>)['link'] as String?;
      if (link == null || link.isEmpty) {
        throw OpenSubtitlesException('下载失败: ${data['message'] ?? '无下载链接'}');
      }
      final bytes = await HttpClient.getBytes(link, timeout: const Duration(seconds: 60));
      return _decode(bytes);
    } catch (e) {
      AppLog.e('OpenSubtitles', '下载异常: $e');
      rethrow;
    }
  }

  /// 字幕内容解码：优先 UTF-8，失败回退 GBK（中文字幕常见编码）
  String _decode(List<int> bytes) {
    try {
      // gzip 压缩的字幕解压
      final raw = _tryGunzip(bytes);
      try {
        return utf8.decode(raw);
      } catch (_) {
        return gbk.decode(raw);
      }
    } catch (e) {
      AppLog.w('OpenSubtitles', '字幕解码失败，尝试直接解码: $e');
      try {
        return utf8.decode(bytes);
      } catch (_) {
        return gbk.decode(bytes);
      }
    }
  }

  static List<int> _tryGunzip(List<int> bytes) {
    // gzip 魔数 1f 8b
    if (bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      return gzip.decode(bytes);
    }
    return bytes;
  }
}

/// 一条字幕候选
class OpenSubtitleItem {
  final dynamic id;
  final String title;
  final String language;
  final String release;
  final String uploader;
  final int? season;
  final int? episode;
  final int downloads;
  final dynamic fileId;
  final String fileName;

  const OpenSubtitleItem({
    required this.id,
    required this.title,
    required this.language,
    required this.release,
    required this.uploader,
    required this.season,
    required this.episode,
    required this.downloads,
    required this.fileId,
    required this.fileName,
  });

  String get label {
    final parts = <String>[
      if (release.isNotEmpty) release,
      if (season != null && episode != null) 'S${season!.toString().padLeft(2, '0')}E${episode!.toString().padLeft(2, '0')}',
      language,
    ];
    return parts.join(' · ');
  }
}

class OpenSubtitlesException implements Exception {
  final String message;
  const OpenSubtitlesException(this.message);
  @override
  String toString() => message;
}
