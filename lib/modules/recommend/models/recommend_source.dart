import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

/// /recommend/source returns additional plugin sources, not built-in defaults.
class RecommendSource {
  const RecommendSource({
    required this.name,
    required this.apiPath,
    required this.type,
  });

  final String name;
  final String apiPath;
  final String type;

  static String resolveApiPath(String value) {
    final path = value.trim();
    // Check before Uri parsing, which normalizes away dot segments.
    final rawPath = Uri.decodeComponent(path.split('?').first);
    final unsafePath =
        rawPath.contains('\\') ||
        rawPath.split('/').any((part) => part == '..' || part == '.');
    final uri = Uri.tryParse(path);
    // Never attach the authenticated client's token to another origin.
    if (unsafePath ||
        uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasFragment ||
        uri.pathSegments.any((part) => part == '..' || part == '.')) {
      throw const FormatException('推荐源地址无效');
    }
    if (path.startsWith('/api/v1/')) return path;
    if (path.startsWith('api/v1/')) return '/$path';
    if (path.isEmpty) throw const FormatException('推荐源地址无效');
    // Plugin api_path values are relative to /api/v1, e.g. plugin/Foo/list
    // or recommend/custom. Legacy mobile keys are bare recommend names.
    if (uri.pathSegments.length > 1) {
      return '/api/v1/${path.startsWith('/') ? path.substring(1) : path}';
    }
    if (path.startsWith('/')) throw const FormatException('推荐源地址无效');
    return '/api/v1/recommend/$path';
  }

  static List<RecommendSource> parse(dynamic raw) {
    dynamic data = raw is String ? jsonDecode(raw) : raw;
    if (data is Map) {
      if (data['success'] == false) throw StateError('获取推荐源失败');
      data = data['data'];
    }
    if (data is! List) throw const FormatException('推荐源响应无效');
    final result = <RecommendSource>[];
    final seen = <String>{};
    for (final entry in data.whereType<Map>()) {
      final name = entry['name'];
      final path = entry['api_path'];
      final type = entry['type'];
      if (name is! String ||
          name.trim().isEmpty ||
          path is! String ||
          type is! String) {
        continue;
      }
      try {
        final resolved = resolveApiPath(path);
        if (seen.add(resolved)) {
          result.add(
            RecommendSource(name: name.trim(), apiPath: resolved, type: type),
          );
        }
      } on FormatException {
        // An invalid plugin must not prevent other sources or defaults loading.
      }
    }
    return List.unmodifiable(result);
  }
}

class RecommendSourceService {
  RecommendSourceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? Get.find<ApiClient>();

  final ApiClient _apiClient;

  Future<List<RecommendSource>> load() async {
    final response = await _apiClient.get<dynamic>('/api/v1/recommend/source');
    if (response.statusCode != 200) {
      throw ApiHttpException(response.statusCode ?? 0, '获取推荐源失败');
    }
    return RecommendSource.parse(response.data);
  }
}
