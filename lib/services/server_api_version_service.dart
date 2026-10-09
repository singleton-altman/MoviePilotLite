import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

/// 服务端 API 形态判定与能力表。
///
/// 背景(2026-09-28 两台真实服务器实测):
/// - 媒体搜索接口存在两种契约:旧式「前缀标识」(/search/media/tmdb:123)与
///   新式「数字标识 + media_source」(/search/media/123?media_source=themoviedb);
/// - 新式服务端缺 media_source 会直接 422(响应体写明 Field required),
///   而旧式前缀形态在另一台服务端上会**挂住不返回**(40 秒无响应);
/// - 因此判定不能只看版本号,要"能力表优先 + 实测结果纠正"。
class ServerApiVersionService extends GetxService {
  final _apiClient = Get.find<ApiClient>();

  /// baseUrl -> 服务端广告的媒体来源取值(如 themoviedb/douban)
  final _sources = <String, Set<String>>{};

  /// baseUrl -> 实测学到的形态(true = 需要新式)。优先级高于能力表。
  final _learnedMode = <String, bool>{};

  /// 搜索模块**专用**的形态记忆:baseUrl -> 该服务器媒体搜索是否需要 media_source。
  ///
  /// 为什么单独存:实测结论只对「媒体搜索」这一个接口成立。若写进全局 [_learnedMode]
  /// (isV3),会连带影响信封解封、详情页/订阅/字幕搜索/存储/文件管理等模块的形态判断
  /// ——搜索端点学到的形态不该污染其它 endpoint。
  final _searchMode = <String, bool>{};

  final _inFlight = <String, Future<Set<String>?>>{};
  int _generation = 0;

  Future<bool> isV3() async {
    final key = _normalizeBaseUrl(_apiClient.baseUrl);
    if (key == null) return false;
    final learned = _learnedMode[key];
    if (learned != null) return learned;
    final values = await mediaSourceValues();
    return values != null && values.isNotEmpty;
  }

  /// 服务端媒体来源表(探测 GET /api/v1/media/source)。
  /// 返回 null 表示这次没探测成功(不缓存,下次重试);返回空集合表示探测成功
  /// 但服务端没有这个能力(旧式契约)。
  Future<Set<String>?> mediaSourceValues() {
    final baseUrl = _normalizeBaseUrl(_apiClient.baseUrl);
    if (baseUrl == null) return Future.value(null);
    final cached = _sources[baseUrl];
    if (cached != null) return Future.value(cached);
    final pending = _inFlight[baseUrl];
    if (pending != null) return pending;

    final generation = _generation;
    final detection = _detect(baseUrl, generation);
    _inFlight[baseUrl] = detection;
    return detection;
  }

  /// 搜索模块专用:读取该服务器的形态记忆(null = 未知,交由能力表判断)。
  /// 这是"上次搜索哪一形态赢了"的结论,只用于搜索请求的形态选择。
  bool? get searchNeedsMediaSource {
    final key = _normalizeBaseUrl(_apiClient.baseUrl);
    return key == null ? null : _searchMode[key];
  }

  /// 搜索模块专用:记住该服务器的媒体搜索是否需要 media_source。
  /// **不写全局 isV3**——搜索形态不参与其它模块的契约判断。
  void markSearchNeedsMediaSource(bool required) {
    final key = _normalizeBaseUrl(_apiClient.baseUrl);
    if (key != null) _searchMode[key] = required;
  }

  /// 兼容旧调用:详情页 422 翻转重试成功后标记该服务器实际认哪种形态
  void markV3(String? baseUrl, bool isV3) {
    final key = _normalizeBaseUrl(baseUrl ?? _apiClient.baseUrl);
    if (key == null) return;
    _learnedMode[key] = isV3;
    _inFlight.remove(key);
  }

  void reset() {
    _generation++;
    _sources.clear();
    _learnedMode.clear();
    _searchMode.clear();
    _inFlight.clear();
  }

  void invalidate(String? baseUrl) {
    final key = _normalizeBaseUrl(baseUrl ?? _apiClient.baseUrl);
    if (key == null) return;
    _generation++;
    _sources.remove(key);
    _learnedMode.remove(key);
    _searchMode.remove(key);
    _inFlight.clear();
  }

  Future<Set<String>?> _detect(String baseUrl, int generation) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/media/source',
        skipV3EnvelopeUnwrap: true,
      );
      final status = response.statusCode ?? 0;
      if (status != 200) return null;
      final values = _extractSources(response.data);
      if (generation == _generation) {
        _sources[baseUrl] = values;
      }
      return values;
    } catch (_) {
      return null;
    } finally {
      if (generation == _generation) {
        _inFlight.remove(baseUrl);
      }
    }
  }

  /// 解析能力表:兼容裸数组与 {success,data:[...]} 两种包装
  Set<String> _extractSources(dynamic data) {
    final list = switch (data) {
      List<dynamic> l => l,
      Map<dynamic, dynamic> m when m['data'] is List => m['data'] as List<dynamic>,
      _ => const <dynamic>[],
    };
    final out = <String>{};
    for (final item in list.whereType<Map>()) {
      final raw = item['media_source'] ?? item['source'] ?? item['name'] ?? '';
      final value = raw.toString().trim().toLowerCase();
      if (value.isNotEmpty) out.add(value);
    }
    return out;
  }

  String? _normalizeBaseUrl(String? baseUrl) {
    final normalized = baseUrl?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
