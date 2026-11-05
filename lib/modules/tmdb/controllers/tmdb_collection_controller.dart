import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';

class TmdbCollectionService {
  TmdbCollectionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? Get.find<ApiClient>();
  final ApiClient _apiClient;

  Future<List<RecommendApiItem>> load(
    int collectionId, {
    required int page,
    required int count,
  }) async {
    if (collectionId <= 0 || page <= 0 || count <= 0) {
      throw ArgumentError('无效的合集分页参数');
    }
    final response = await _apiClient.get<dynamic>(
      '/api/v1/tmdb/collection/$collectionId',
      queryParameters: {'page': page, 'count': count},
    );
    if (response.statusCode != 200) {
      throw ApiHttpException(response.statusCode ?? 0, '加载合集失败');
    }
    dynamic data = response.data;
    if (data is String) data = jsonDecode(data);
    if (data is Map) {
      if (data['success'] == false) throw StateError('加载合集失败');
      data = data['data'];
    }
    if (data is! List) throw const FormatException('合集响应无效');
    return data
        .whereType<Map>()
        .map(
          (raw) => RecommendApiItem.fromJson(
            normalizeMediaJson(Map<String, dynamic>.from(raw)),
          ),
        )
        .toList();
  }
}

class TmdbCollectionController extends ChangeNotifier {
  TmdbCollectionController({
    required this.collectionId,
    TmdbCollectionService? service,
  }) : _service = service ?? TmdbCollectionService();

  final int collectionId;
  final TmdbCollectionService _service;
  static const pageSize = 20;
  final List<RecommendApiItem> _items = [];
  List<RecommendApiItem> get items => List.unmodifiable(_items);
  bool isLoading = false;
  bool hasMore = true;
  String? error;
  int _page = 0;
  bool _disposed = false;

  Future<void> load({bool refresh = false}) async {
    if (isLoading || (!refresh && !hasMore)) return;
    isLoading = true;
    error = null;
    notifyListeners();
    final page = refresh ? 1 : _page + 1;
    try {
      final result = await _service.load(
        collectionId,
        page: page,
        count: pageSize,
      );
      if (_disposed) return;
      if (refresh) _items.clear();
      _items.addAll(result);
      _page = page;
      hasMore = result.length >= pageSize;
    } catch (_) {
      if (!_disposed) error = '合集加载失败，请重试';
    } finally {
      if (!_disposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
