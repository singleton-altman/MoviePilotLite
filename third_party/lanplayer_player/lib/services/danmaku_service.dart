import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/app_log.dart';
import '../database/database_service.dart';

enum DanmakuApiType { v1, v2, misaka, danmuApi, bilibili, fntv, unknown }

/// 弹幕匹配模式（Hills 同款 DanmuMatchMode）
enum DanmakuMatchMode {
  /// 文件哈希 + 文件名（精准匹配，需要本地文件路径）
  hashAndFileName,

  /// 仅文件名（快速匹配，适用于网络串流/URL 播放）
  fileNameOnly,

  /// 手动选择（匹配失败时弹出搜索界面让用户选）
  manual,
}

class DanmakuService {
  final String baseUrl;
  final String? apiKey;
  late final Dio _dio;
  DanmakuApiType _apiType = DanmakuApiType.unknown;

  DanmakuService({
    required String baseUrl,
    this.apiKey,
    Dio? dioClient,
  }) : baseUrl = normalizeBaseUrl(baseUrl) {
    // 构建包含 apiKey 的 baseUrl
    var dioBaseUrl = normalizeBaseUrl(baseUrl);
    if (!dioBaseUrl.endsWith('/')) dioBaseUrl += '/';
    if (apiKey != null && apiKey!.isNotEmpty) {
      dioBaseUrl += '$apiKey/';
    }
    _dio = dioClient ?? Dio(BaseOptions(
      baseUrl: dioBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _dio.options.headers = {
      'User-Agent': 'LANPlayer/1.0.0',
      'Accept': 'application/json',
    };
  }

  static String normalizeBaseUrl(String url) {
    String result = url.trim();
    if (result.isEmpty) return result;
    if (!result.startsWith('http://') && !result.startsWith('https://')) {
      result = 'http://$result';
    }
    final uri = Uri.tryParse(result);
    if (uri != null && uri.hasScheme && uri.hasAuthority) {
      final base = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      return base;
    }
    return result;
  }

  /// 从完整 URL 中提取 apiKey（如果 URL 中包含路径段）
  static String? extractApiKeyFromUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasAuthority) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      return segments.first;
    }
    return null;
  }

  String _buildUrl(String path) {
    String url = baseUrl;
    if (!url.endsWith('/')) url += '/';
    if (apiKey != null && apiKey!.isNotEmpty) {
      url += '$apiKey/';
    }
    return url + path.replaceFirst('/', '');
  }

  Future<bool> testConnection() async {
    final endpoints = {
      DanmakuApiType.v1: '/api/v1/ping',
      DanmakuApiType.v2: '/api/v2/ping',
      DanmakuApiType.misaka: '/api/ping',
      DanmakuApiType.danmuApi: '/ping',
      DanmakuApiType.fntv: '/api/ping',
    };

    for (final type in endpoints.keys) {
      try {
        final url = _buildUrl(endpoints[type]!);
        final response = await _dio.get(url, options: Options(
          headers: {'X-API-KEY': apiKey ?? ''},
          validateStatus: (s) => s != null && s < 500,
        ));
        // huangxd API /api/v2/ping 返回 404，改用状态码判断
        if (response.statusCode != null && response.statusCode! < 500) {
          _apiType = type;
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  /// 根据匹配模式执行匹配（F-3：弹幕匹配模式切换）
  Future<DanmakuMatch?> matchByMode({
    required String fileName,
    String? fileHash,
    int? duration,
    required DanmakuMatchMode mode,
  }) async {
    switch (mode) {
      case DanmakuMatchMode.hashAndFileName:
        return await matchV2(fileName: fileName, fileHash: fileHash, duration: duration);
      case DanmakuMatchMode.fileNameOnly:
        return await _fallbackMatch(fileName);
      case DanmakuMatchMode.manual:
        return null; // 让调用方弹出搜索界面
    }
  }

  /// 多维度评分匹配（M-1~M-2：替代硬匹配，基于标题相似度+季号+年份+弹幕量）
  double scoreDanmakuMatch(DanmakuMatch m, String query, {int? season, int? year}) {
    double score = 0;
    final q = query.toLowerCase();
    final t = m.title.toLowerCase();

    // 标题相似度（0~50 分）
    if (t == q) {
      score += 50; // 完全匹配
    } else if (t.contains(q) || q.contains(t)) {
      score += 35; // 包含关系
    } else {
      // 最长公共子串占比
      final lcsLen = _longestCommonSubstring(q, t);
      score += (lcsLen / q.length * 25).clamp(0, 25);
    }

    // 季号匹配（0~20 分）
    if (season != null && m.episodeNumber > 0) {
      final parsed = parseTitle(m.title);
      if (parsed['season'] == season) score += 20;
    }

    // 弹幕数量加成（0~10 分）
    if (m.count > 0) {
      score += (m.count / 1000 * 10).clamp(0, 10);
    }

    return score.clamp(0, 100);
  }

  /// 最长公共子串长度（用于标题相似度计算）
  int _longestCommonSubstring(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final la = a.length, lb = b.length;
    final dp = List<List<int>>.generate(la + 1, (_) => List<int>.filled(lb + 1, 0));
    var maxLen = 0;
    for (int i = 1; i <= la; i++) {
      for (int j = 1; j <= lb; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
          if (dp[i][j] > maxLen) maxLen = dp[i][j];
        }
      }
    }
    return maxLen;
  }

  /// v2 match API: POST /api/v2/match  (danmu_api 项目)
  /// 请求体: { "fileName": "xxx", "duration": 1234, "matchMode": "hashAndFileName" }
  /// 响应: { "episodeId": 123, "animeTitle": "...", "episodeTitle": "..." }
  Future<DanmakuMatch?> matchV2({required String fileName, String? fileHash, int? duration}) async {
    try {
      final url = _buildUrl('/api/v2/match');
      final response = await _dio.post(url, data: {
        'fileName': fileName,
        if (fileHash != null) 'fileHash': fileHash,
        if (duration != null) 'duration': duration,
        'matchMode': 'hashAndFileName',
      }, options: Options(
        headers: _getOptions().headers,
        sendTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && (data['episodeId'] != null || data['episode_id'] != null)) {
          _apiType = DanmakuApiType.v2;
          return DanmakuMatch.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<Danmaku>> getDanmaku({
    required String episodeId,
    int? episode,
    String? title,
  }) async {
    // SQLite 缓存（7天 TTL）
    final cacheKey = 'danmaku_$episodeId';
    try {
      final cached = await DbService.getDanmakuCache(cacheKey);
      if (cached != null) {
        final list = jsonDecode(cached) as List<dynamic>;
        return list.map((e) => Danmaku.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // 网络请求
    final paths = {
      DanmakuApiType.v1: '/api/v1/comment/$episodeId',
      DanmakuApiType.v2: '/api/v2/comment/$episodeId',
      DanmakuApiType.misaka: '/api/danmaku/$episodeId',
      DanmakuApiType.danmuApi: '/api/comment/$episodeId',
      DanmakuApiType.fntv: '/api/danmaku/$episodeId',
    };

    for (final type in [_apiType, DanmakuApiType.v2, DanmakuApiType.v1, DanmakuApiType.misaka, DanmakuApiType.danmuApi, DanmakuApiType.fntv]) {
      if (type == DanmakuApiType.unknown) continue;
      try {
        final url = _buildUrl(paths[type]!);
        final response = await _dio.get(
          url,
          queryParameters: {'format': 'json', 'duration': 'true', if (episode != null) 'ep': episode},
          options: _getOptions(),
        );
        final data = _extractDanmakuData(response.data);
        if (data.isNotEmpty) {
          _apiType = type;
          // 保存到 SQLite 缓存
          final jsonStr = jsonEncode(data.map((d) => d.toJson()).toList());
          DbService.saveDanmakuCache(cacheKey, jsonStr);
          return data;
        }
      } catch (_) {}
    }

    return [];
  }

  Future<List<Danmaku>> getDanmakuByTitle(String title, {int? episode}) async {
    return await searchDanmakuByAnime(title, episode: episode);
  }

  List<Danmaku> _extractDanmakuData(dynamic responseData) {
    List<dynamic> rawList = [];
    if (responseData is List) {
      rawList = responseData;
    } else if (responseData is Map) {
      // 弹弹play v2 标准格式: { data: { comments: [...] } }
      if (responseData['data'] is Map) {
        final data = responseData['data'] as Map;
        if (data['comments'] is List) {
          rawList = data['comments'] as List;
        } else if (data['data'] is List) {
          rawList = data['data'] as List;
        }
      }
      // 其他格式
      if (rawList.isEmpty) {
        if (responseData['data'] is List) {
          rawList = responseData['data'] as List;
        } else if (responseData['comments'] is List) {
          rawList = responseData['comments'] as List;
        } else if (responseData['items'] is List) {
          rawList = responseData['items'] as List;
        } else if (responseData['danmaku'] is List) {
          rawList = responseData['danmaku'] as List;
        } else if (responseData['result'] is List) {
          rawList = responseData['result'] as List;
        }
      }
    }
    if (rawList.isNotEmpty) {
      AppLog.i('DanmakuService', '原始弹幕样本: ${rawList.first} (type=${rawList.first.runtimeType})');
    }
    return rawList.map((item) {
      if (item is Map<String, dynamic>) {
        return Danmaku.fromJson(item);
      } else if (item is Map) {
        return Danmaku.fromJson(Map<String, dynamic>.from(item));
      } else if (item is List) {
        // 弹弹play v2 数组格式: [cid, "p", "m"]
        if (item.length >= 3) {
          final fakeJson = <String, dynamic>{
            'cid': item[0],
            'p': item[1]?.toString(),
            'm': item[2]?.toString(),
          };
          return Danmaku.fromJson(fakeJson);
        }
      }
      return Danmaku.fromJson({});
    }).toList();
  }

  Future<List<Danmaku>> getDanmakuByTime({
    required String episodeId,
    required int startTime,
    required int endTime,
  }) async {
    return await getDanmaku(episodeId: episodeId);
  }

  Future<bool> sendDanmaku({
    required String episodeId,
    required String text,
    required int time,
    required String color,
    required String type,
  }) async {
    try {
      final paths = {
        DanmakuApiType.v1: '/api/v1/danmaku',
        DanmakuApiType.v2: '/api/v2/danmaku',
        DanmakuApiType.misaka: '/api/send',
        DanmakuApiType.danmuApi: '/api/danmaku',
        DanmakuApiType.fntv: '/api/send',
      };
      final url = _buildUrl(paths[_apiType] ?? paths[DanmakuApiType.v2]!);
      final response = await _dio.post(url, data: {
        'episode_id': episodeId,
        'text': text,
        'time': time,
        'color': color,
        'type': type,
      }, options: _getOptions());
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 获取番剧详情（包含剧集列表）
  /// GET /api/v2/bangumi/{bangumiId}
  /// 响应格式: { "bangumi": { "episodes": [...] } }
  Future<Map<String, dynamic>?> getBangumiDetail(String bangumiId) async {
    for (final type in [_apiType, DanmakuApiType.v2, DanmakuApiType.fntv]) {
      if (type == DanmakuApiType.unknown) continue;
      try {
        final url = _buildUrl('/api/v2/bangumi/$bangumiId');
        final response = await _dio.get(url, options: _getOptions());
        if (response.statusCode == 200 && response.data != null) {
          _apiType = type;
          // 返回完整的响应，让调用方解析 bangumi 嵌套
          return response.data as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<List<DanmakuMatch>> searchDanmaku(String keyword) async {
    final paths = {
      DanmakuApiType.v1: '/api/v1/search/anime',
      DanmakuApiType.v2: '/api/v2/search/anime',
      DanmakuApiType.misaka: '/api/search',
      DanmakuApiType.danmuApi: '/api/search',
      DanmakuApiType.fntv: '/api/anime/search',
    };

    for (final type in [_apiType, DanmakuApiType.v2, DanmakuApiType.v1, DanmakuApiType.misaka, DanmakuApiType.danmuApi, DanmakuApiType.fntv]) {
      if (type == DanmakuApiType.unknown) continue;
      try {
        final url = _buildUrl(paths[type]!);
        final response = await _dio.get(url, queryParameters: {'keyword': keyword}, options: _getOptions());
        final data = _extractMatchData(response.data);
        if (data.isNotEmpty) {
          _apiType = type;
          return data;
        }
      } catch (e) {
        // 忽略错误，尝试下一个端点
      }
    }
    return [];
  }

  List<DanmakuMatch> _extractMatchData(dynamic responseData) {
    if (responseData is List) {
      return responseData.map((json) => DanmakuMatch.fromJson(json)).toList();
    }
    if (responseData is Map) {
      // 弹弹play v2 搜索格式: { "animes": [...] }
      if (responseData['animes'] is List) {
        return (responseData['animes'] as List).map((json) => DanmakuMatch.fromJson(json)).toList();
      }
      // 弹弹play v2 可能嵌套: { "data": { "animes": [...] } }
      if (responseData['data'] is Map && responseData['data']['animes'] is List) {
        return (responseData['data']['animes'] as List).map((json) => DanmakuMatch.fromJson(json)).toList();
      }
      // 其他常见格式
      if (responseData['data'] is List) {
        return (responseData['data'] as List).map((json) => DanmakuMatch.fromJson(json)).toList();
      }
      if (responseData['results'] is List) {
        return (responseData['results'] as List).map((json) => DanmakuMatch.fromJson(json)).toList();
      }
      if (responseData['items'] is List) {
        return (responseData['items'] as List).map((json) => DanmakuMatch.fromJson(json)).toList();
      }
      if (responseData['anime'] is List) {
        return (responseData['anime'] as List).map((json) => DanmakuMatch.fromJson(json)).toList();
      }
      // 弹弹play v2 match 格式: { "isMatched": true, "matches": [...] }
      if (responseData['matches'] is List) {
        return (responseData['matches'] as List).map((json) => DanmakuMatch.fromJson(json)).toList();
      }
      // 单条结果直接包裹在 Map 中
      if (responseData['animeId'] != null || responseData['bangumiId'] != null || responseData['episodeId'] != null || responseData['episode_id'] != null) {
        return [DanmakuMatch.fromJson(Map<String, dynamic>.from(responseData))];
      }
    }
    return [];
  }

  /// 搜索番剧并获取指定集数的弹幕
  Future<List<Danmaku>> searchDanmakuByAnime(String title, {int? season, int? episode}) async {
    try {
      final matches = await searchDanmaku(title);
      if (matches.isEmpty) return [];

      // 找到匹配的番剧
      final animeMatch = matches.first;
      final bangumiId = animeMatch.bangumiId;
      // bangumiId 可能是 "ss132358" 格式，需要用它获取详情

      // 获取番剧详情以找到具体剧集
      final detail = await getBangumiDetail(bangumiId);
      if (detail != null && detail['bangumi'] is Map) {
        final bangumi = detail['bangumi'] as Map<String, dynamic>;
        final episodes = bangumi['episodes'] as List?;
        if (episodes != null && episodes.isNotEmpty) {
          // 如果有集号，找到对应集数
          if (episode != null) {
            for (final ep in episodes) {
              final epNum = ep['episodeNumber'] ?? ep['episode_number'] ?? ep['number'];
              if (epNum != null && epNum.toString() == episode.toString()) {
                final epId = ep['episodeId']?.toString() ?? ep['episode_id']?.toString() ?? ep['id']?.toString() ?? '';
                if (epId.isNotEmpty) return await getDanmaku(episodeId: epId);
              }
            }
          }
          // 否则返回第一集的弹幕
          final firstEp = episodes.first;
          final epId = firstEp['episodeId']?.toString() ?? firstEp['episode_id']?.toString() ?? firstEp['id']?.toString() ?? '';
          if (epId.isNotEmpty) return await getDanmaku(episodeId: epId);
        }
      }

      // 回退：直接用搜索结果的 episodeId（可能不正确，但尝试一下）
      return await getDanmaku(episodeId: bangumiId);
    } catch (_) {
      return [];
    }
  }

  Future<DanmakuMatch?> matchDanmaku({
    required String fileName,
    String? fileHash,
    int? duration,
    String? episodeTitle,
  }) async {
    final paths = {
      DanmakuApiType.v1: '/api/v1/danmaku/match',
      DanmakuApiType.v2: '/api/v2/danmaku/match',
      DanmakuApiType.misaka: '/api/match',
      DanmakuApiType.danmuApi: '/api/match',
      DanmakuApiType.fntv: '/api/danmaku/match',
    };

    for (final type in [_apiType, DanmakuApiType.v2, DanmakuApiType.v1, DanmakuApiType.misaka, DanmakuApiType.danmuApi, DanmakuApiType.fntv]) {
      if (type == DanmakuApiType.unknown) continue;
      try {
        final url = _buildUrl(paths[type]!);
        final response = await _dio.post(url, data: {
          'fileName': fileName,
          if (fileHash != null) 'fileHash': fileHash,
          if (duration != null) 'duration': duration,
          if (episodeTitle != null) 'episodeTitle': episodeTitle,
          'matchMode': 'hashAndFileName',
        }, options: _getOptions());
        if (response.data['data'] != null) {
          _apiType = type;
          return DanmakuMatch.fromJson(response.data['data']);
        }
        if (response.data['episode_id'] != null) {
          _apiType = type;
          return DanmakuMatch.fromJson(response.data);
        }
        if (response.data['id'] != null) {
          _apiType = type;
          return DanmakuMatch.fromJson(response.data);
        }
      } catch (_) {}
    }

    return await _fallbackMatch(fileName);
  }

  Future<DanmakuMatch?> _fallbackMatch(String fileName) async {
    try {
      final searchResults = await searchDanmaku(fileName);
      if (searchResults.isNotEmpty) {
        return searchResults.first;
      }
    } catch (_) {}

    try {
      final keywords = _extractKeywords(fileName);
      for (final keyword in keywords) {
        final results = await searchDanmaku(keyword);
        if (results.isNotEmpty) {
          return results.first;
        }
      }
    } catch (_) {}

    try {
      final cleaned = _cleanFileName(fileName);
      final shortKeywords = _extractShortKeywords(cleaned);
      for (final keyword in shortKeywords) {
        final results = await searchDanmaku(keyword);
        if (results.isNotEmpty) {
          return results.first;
        }
      }
    } catch (_) {}

    return null;
  }

  String _cleanFileName(String fileName) {
    return fileName.toLowerCase()
        .replaceAll(RegExp(r'\.(mp4|mkv|avi|mov|flv|webm|ts|m2ts|iso)$'), '')
        .replaceAll(RegExp(r'[._-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _extractKeywords(String fileName) {
    final keywords = <String>[];
    final name = fileName.toLowerCase();
    final patterns = [
      RegExp(r'(.+?)\s*[sS]\d+[eE]\d+'),
      RegExp(r'(.+?)\s*\d+[xX]\d+'),
      RegExp(r'(.+?)\s*\[\d+\]'),
      RegExp(r'(.+?)\s*第\d+[季部]'),
      RegExp(r'(.+?)\s*第\d+[集话]'),
      RegExp(r'(.+?)\s*\d{1,3}\s*[集话]'),
      RegExp(r'(.+?)\s*EP?\d+'),
      RegExp(r'(.+?)\s*第[一二三四五六七八九十\d]+[季部]'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(name);
      if (match != null && match.group(1) != null) {
        final keyword = match.group(1)!.trim()
            .replaceAll(RegExp(r'[._-]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (keyword.length > 2) {
          keywords.add(keyword);
        }
      }
    }

    if (keywords.isEmpty) {
      final cleaned = _cleanFileName(name);
      if (cleaned.length > 2) {
        keywords.add(cleaned);
      }
    }

    return keywords;
  }

  List<String> _extractShortKeywords(String name) {
    final keywords = <String>[];
    name = name.replaceAll(RegExp(r'\s+'), ' ');

    final parts = name.split(' ');
    for (int i = 0; i < parts.length; i++) {
      for (int j = i + 1; j <= parts.length; j++) {
        final combined = parts.sublist(i, j).join(' ').trim();
        if (combined.length >= 4 && combined.length <= 20) {
          keywords.add(combined);
        }
      }
    }

    return keywords.toSet().toList();
  }

  /// 从标题中解析番剧名、季号、集号
  /// 返回 { 'title': String, 'season': int?, 'episode': int? }
  Map<String, dynamic> parseTitle(String title) {
    String name = title;
    int? season;
    int? episode;

    // 清理文件扩展名
    name = name.replaceAll(RegExp(r'\.(mp4|mkv|avi|mov|flv|webm|ts|m2ts|iso)$'), '');

    // 解析季号
    final seasonPatterns = [
      RegExp(r'[sS](\d+)', caseSensitive: false),
      RegExp(r'第([一二三四五六七八九十\d]+)[季部]'),
    ];
    for (final p in seasonPatterns) {
      final m = p.firstMatch(name);
      if (m != null) {
        season = _parseChineseNumber(m.group(1)!) ?? int.tryParse(m.group(1) ?? '');
        break;
      }
    }

    // 解析集号
    final episodePatterns = [
      RegExp(r'[eE](\d+)'),
      RegExp(r'第(\d+)[集话]'),
      RegExp(r'EP?(\d+)', caseSensitive: false),
      RegExp(r'\[(\d+)\]'),
    ];
    for (final p in episodePatterns) {
      final m = p.firstMatch(name);
      if (m != null) {
        episode = int.tryParse(m.group(1) ?? '');
        break;
      }
    }

    // 提取番剧名（去掉季集信息）
    final cleanPatterns = [
      RegExp(r'\s*[sS]\d+[eE]\d+.*$'),
      RegExp(r'\s*第\d+[季部].*$'),
      RegExp(r'\s*第\d+[集话].*$'),
      RegExp(r'\s*EP?\d+.*$'),
      RegExp(r'\s*\[\d+\].*$'),
    ];
    for (final p in cleanPatterns) {
      name = name.replaceAll(p, '');
    }
    name = name.replaceAll(RegExp(r'[._-]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    return {'title': name, 'season': season, 'episode': episode};
  }

  int? _parseChineseNumber(String s) {
    const map = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10};
    if (map.containsKey(s)) return map[s];
    if (s == '十') return 10;
    if (s.startsWith('十')) return 10 + (map[s.substring(1)] ?? 0);
    if (s.endsWith('十')) return (map[s.substring(0, s.length - 1)] ?? 0) * 10;
    return null;
  }

  Options _getOptions() {
    if (apiKey != null && apiKey!.isNotEmpty) {
      return Options(headers: {'Authorization': 'Bearer $apiKey'});
    }
    return Options();
  }

  DanmakuApiType get apiType => _apiType;

  // ═══════════════════════════════════════════════
  // 本地弹幕文件导入（F-1：支持 .xml/.json/.txt）
  // ═══════════════════════════════════════════════

  /// 从本地文件导入弹幕（支持 B 站 XML、JSON、纯文本格式）
  static Future<List<Danmaku>> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];
    final content = await file.readAsString(encoding: utf8);
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'xml':
        return _parseXmlDanmaku(content);
      case 'json':
        return _parseJsonDanmaku(content);
      case 'txt':
        return _parseTxtDanmaku(content);
      default:
        return [];
    }
  }

  /// 解析 B 站 XML 弹幕格式
  /// <d p="时间,模式,字号,颜色,时间戳,弹幕池,用户哈希,弹幕ID">弹幕文本</d>
  static List<Danmaku> _parseXmlDanmaku(String xml) {
    final danmakus = <Danmaku>[];
    final reg = RegExp(r'<d p="([^"]*)">([^<]*)</d>');
    for (final match in reg.allMatches(xml)) {
      final attrs = match.group(1) ?? '';
      final text = match.group(2) ?? '';
      if (text.isEmpty || attrs.isEmpty) continue;
      final parts = attrs.split(',');
      if (parts.length < 3) continue;
      final timeMs = ((double.tryParse(parts[0]) ?? 0) * 1000).toInt();
      final mode = int.tryParse(parts[1]) ?? 1;
      final colorDec = int.tryParse(parts[3]) ?? 16777215;
      final colorHex = '#${colorDec.toRadixString(16).padLeft(6, '0')}';
      danmakus.add(Danmaku(
        id: parts.length >= 7 ? parts[7] : '',
        text: text,
        time: timeMs,
        color: colorHex,
        type: Danmaku._parseType(mode),
      ));
    }
    danmakus.sort((a, b) => a.time.compareTo(b.time));
    return danmakus;
  }

  /// 解析 JSON 弹幕格式（数组或对象）
  static List<Danmaku> _parseJsonDanmaku(String jsonStr) {
    try {
      final data = json.decode(jsonStr);
      if (data is List) {
        return data.map((item) {
          if (item is Map) return Danmaku.fromJson(Map<String, dynamic>.from(item));
          return Danmaku.fromJson({});
        }).toList();
      }
      if (data is Map) {
        // 常见嵌套: { comments: [...] } 或 { data: [...] }
        final list = data['comments'] ?? data['data'] ?? data['danmaku'] ?? data['items'];
        if (list is List) {
          return list.map((item) {
            if (item is Map) return Danmaku.fromJson(Map<String, dynamic>.from(item));
            return Danmaku.fromJson({});
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// 解析纯文本弹幕格式（每行一条，可选 "时间|弹幕" 或 "时间,弹幕" 格式）
  static List<Danmaku> _parseTxtDanmaku(String content) {
    final danmakus = <Danmaku>[];
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // 尝试 "时间|弹幕" 或 "时间,弹幕" 格式
      final sepMatch = RegExp(r'^(\d+[.]?\d*)\s*[,|]\s*(.+)$').firstMatch(trimmed);
      if (sepMatch != null) {
        final timeMs = ((double.tryParse(sepMatch.group(1)!) ?? 0) * 1000).toInt();
        final text = sepMatch.group(2) ?? '';
        if (text.isNotEmpty) {
          danmakus.add(Danmaku(
            id: '${danmakus.length}',
            text: text,
            time: timeMs,
            color: '#FFFFFF',
            type: DanmakuType.scroll,
          ));
        }
      } else {
        // 纯文本，按行号估算时间（每条间隔 1 秒）
        danmakus.add(Danmaku(
          id: '${danmakus.length}',
          text: trimmed,
          time: danmakus.length * 1000,
          color: '#FFFFFF',
          type: DanmakuType.scroll,
        ));
      }
    }
    return danmakus;
  }
}

class Danmaku {
  final String id;
  final String text;
  final int time;
  final String color;
  final DanmakuType type;
  final String? author;
  final int? fontSize;

  Danmaku({
    required this.id,
    required this.text,
    required this.time,
    required this.color,
    required this.type,
    this.author,
    this.fontSize,
  });

  factory Danmaku.fromJson(Map<String, dynamic> json) {
    final p = json['p']?.toString();
    if (p != null && p.isNotEmpty) {
      // 尝试分号分隔（弹弹play标准格式: time;mode;size;color;...）
      var parts = p.split(';');
      if (parts.length < 3) {
        // 尝试逗号分隔（弹弹play v2简化格式: time,mode,color,userHash）
        parts = p.split(',');
      }
      if (parts.length >= 3) {
        final time = ((double.tryParse(parts[0]) ?? 0) * 1000).toInt();
        final mode = int.tryParse(parts[1]) ?? 1;
        int colorDec;
        int? fontSize;
        if (parts.length >= 5) {
          // 分号格式: time;mode;size;color;...
          fontSize = int.tryParse(parts[2]);
          colorDec = int.tryParse(parts[3]) ?? 16777215;
        } else {
          // 逗号简化格式: time,mode,color,userHash
          colorDec = int.tryParse(parts[2]) ?? 16777215;
        }
        final colorHex = '#${colorDec.toRadixString(16).padLeft(6, '0')}';
        final author = parts.length >= 4 ? parts[parts.length - 1] : null;
        return Danmaku(
          id: json['cid']?.toString() ?? '',
          text: _sanitizeText(json['m']),
          time: time,
          color: colorHex,
          type: _parseType(mode),
          author: json['user']?.toString() ?? author,
          fontSize: fontSize,
        );
      }
    }

    // 其他常见格式
    return Danmaku(
      id: json['id']?.toString() ?? json['cid']?.toString() ?? '',
      text: _sanitizeText(json['text'] ?? json['content'] ?? json['message'] ?? json['m']),
      time: _parseTime(json['time'] ?? json['t'] ?? json['appear_time'] ?? json['timestamp']),
      color: json['color'] ?? json['font_color'] ?? '#FFFFFF',
      type: _parseType(json['type'] ?? json['mode'] ?? 'scroll'),
      author: json['author'] ?? json['user'] ?? json['username'],
      fontSize: json['font_size'] ?? json['size'],
    );
  }

  static DanmakuType _parseType(dynamic type) {
    final t = type.toString().toLowerCase();
    switch (t) {
      case 'top':
      case 'top_fixed':
      case '5':
        return DanmakuType.top;
      case 'bottom':
      case 'bottom_fixed':
      case '4':
        return DanmakuType.bottom;
      case 'scroll':
      case '1':
        return DanmakuType.scroll;
      case 'reverse':
      case '6':
        return DanmakuType.scroll;
      default:
        return DanmakuType.scroll;
    }
  }

  static int _parseTime(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) {
        return parsed.toInt();
      }
      return int.tryParse(v) ?? 0;
    }
    return 0;
  }

  static String _sanitizeText(dynamic text) {
    final str = text?.toString() ?? '';
    if (str.isEmpty) return '';
    // 过滤控制字符
    final cleaned = StringBuffer();
    for (final char in str.runes) {
      if (char >= 0x20 && char <= 0x10FFFF) {
        cleaned.writeCharCode(char);
      }
    }
    final result = cleaned.toString();
    if (result.isEmpty) return '';

    // 过滤纯乱码：如果文本中没有常见字符
    final normalCharCount = result.runes.where((r) =>
      (r >= 0x4E00 && r <= 0x9FFF) || // CJK统一汉字
      (r >= 0x3040 && r <= 0x30FF) || // 日文假名
      (r >= 0xAC00 && r <= 0xD7AF) || // 韩文音节
      (r >= 0x3130 && r <= 0x318F) || // 韩文字母
      (r >= 0x20 && r <= 0x7E) ||     // ASCII
      (r >= 0x3000 && r <= 0x303F) || // CJK标点
      (r >= 0xFF00 && r <= 0xFFEF)    // 全角ASCII
    ).length;
    if (normalCharCount == 0) return '';

    // 过滤连续重复字符过多的短弹幕（如 "豭豭豭" "aaa"）
    if (result.length >= 3 && result.length <= 10) {
      int maxRepeat = 1;
      int currentRepeat = 1;
      for (int i = 1; i < result.length; i++) {
        if (result[i] == result[i-1]) {
          currentRepeat++;
          if (currentRepeat > maxRepeat) maxRepeat = currentRepeat;
        } else {
          currentRepeat = 1;
        }
      }
      // 短文本中连续重复超过3个相同字符（如 "豭豭豭"）
      if (maxRepeat >= 3 && maxRepeat >= result.length * 0.5) return '';
    }

    // 过滤过长弹幕（减少屏幕占用）
    if (result.length > 100) return result.substring(0, 100);

    return result;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'time': time,
        'color': color,
        'type': type.toString().split('.').last,
        'author': author,
        'font_size': fontSize,
      };
}

enum DanmakuType { scroll, top, bottom }

class DanmakuMatch {
  /// 番剧ID（bangumiId / animeId）
  /// 注意：搜索API返回的是番剧ID，不是单集ID
  /// 要获取单集弹幕，需要先用 bangumiId 获取番剧详情，再取对应 episodeId
  final String bangumiId;

  /// 单集ID（match API 精准匹配时才会有值）
  final String? episodeId;

  final String title;
  final int episodeNumber;
  final int count;
  /// 番剧级候选的集数(搜索结果 episodes 列表长度或 numberOfEpisodes);
  /// 单集级结果为 null。面板展示「共N集」用 —— 搜索接口没有单集条数字段,
  /// 旧实现兜底的 count=0 纯属虚构
  final int? episodeCount;
  final double matchScore;
  final double confidence;  // 匹配置信度 0~1（M-5）
  final String matchReason; // 匹配原因说明（M-5）

  DanmakuMatch({
    required this.bangumiId,
    this.episodeCount,
    this.episodeId,
    required this.title,
    required this.episodeNumber,
    required this.count,
    required this.matchScore,
    this.confidence = 0.0,
    this.matchReason = '',
  });

  /// 向后兼容：优先使用 episodeId，没有则返回 bangumiId
  @Deprecated('使用 bangumiId 或 episodeId 替代，语义更明确')
  String get episodeIdCompat => episodeId ?? bangumiId;

  factory DanmakuMatch.fromJson(Map<String, dynamic> json) {
    // 单集ID（精准匹配时才有）
    final epId = json['episodeId']?.toString()
        ?? json['episode_id']?.toString();

    // 番剧ID（搜索结果中常见）
    final bgmId = json['bangumiId']?.toString()
        ?? json['bangumi_id']?.toString()
        ?? json['animeId']?.toString()
        ?? json['anime_id']?.toString()
        ?? json['id']?.toString()
        ?? epId
        ?? '';

    return DanmakuMatch(
      bangumiId: bgmId,
      episodeId: epId,
      title: json['animeTitle'] ?? json['anime_title'] ?? json['title'] ?? json['name'] ?? '',
      episodeNumber: json['episodeNumber'] ?? json['episode_number'] ?? json['episode'] ?? json['ep'] ?? 1,
      count: json['count'] ?? json['danmaku_count'] ?? json['total'] ?? 0,
      episodeCount: (json['episodes'] is List)
          ? (json['episodes'] as List).length
          : ((json['episodeCount'] ?? json['numberOfEpisodes']) as num?)?.toInt(),
      matchScore: (json['match_score'] ?? json['matchScore'] ?? json['score'] ?? json['similarity'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      matchReason: json['matchReason'] ?? json['match_reason'] ?? '',
    );
  }
}


