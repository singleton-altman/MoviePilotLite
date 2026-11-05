import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

import '../models/cache_model.dart';

class CacheController extends GetxController {
  final keywordController = TextEditingController();

  final keyword = ''.obs;
  final selectedSites = <String>{}.obs;

  final isLoading = false.obs;
  final errorText = RxnString();
  final statusCode = RxnInt();
  final cacheResponse = Rxn<CacheResponse>();
  final showActions = false.obs;

  final ApiClient _apiClient = Get.find<ApiClient>();
  final AppLog _log = Get.find<AppLog>();

  @override
  void onInit() {
    super.onInit();
    fetchCache();
  }

  @override
  void onClose() {
    keywordController.dispose();
    super.onClose();
  }

  Future<void> fetchCache() async {
    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    errorText.value = null;
    statusCode.value = null;

    try {
      final response = await _apiClient.get<dynamic>('/api/v1/torrent/cache');

      statusCode.value = response.statusCode ?? 0;
      final parsed = _parseResponse(response.data);
      cacheResponse.value = parsed;

      if (parsed == null) {
        errorText.value = _buildErrorMessage(
          response.statusCode,
          response.data,
        );
      } else if (!parsed.success) {
        errorText.value = parsed.message?.trim().isNotEmpty == true
            ? parsed.message
            : _buildErrorMessage(response.statusCode, response.data);
      }

      _syncSelectedSite();
    } catch (e) {
      errorText.value = '请求异常: $e';
      ToastUtil.error('获取缓存失败');
    } finally {
      isLoading.value = false;
    }
  }

  void updateKeyword(String value) {
    keyword.value = value;
  }

  void updateSelectedSites(Set<String> values) {
    selectedSites.assignAll(values);
  }

  void toggleActions() {
    showActions.value = !showActions.value;
  }

  void closeActions() {
    showActions.value = false;
  }

  void clearFilters() {
    keywordController.text = '';
    keyword.value = '';
    selectedSites.clear();
  }

  bool get hasFilter {
    return keyword.value.trim().isNotEmpty || hasSiteFilter;
  }

  bool get hasSiteFilter => selectedSites.isNotEmpty;

  String get selectedSiteLabel {
    if (selectedSites.isEmpty) return '全部';
    final list = selectedSites.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (list.length == 1) return list.first;
    return '已选 ${list.length}';
  }

  int get totalCount {
    final payload = cacheResponse.value?.data;
    if (payload?.count != null) return payload!.count!;
    return payload?.items?.length ?? 0;
  }

  int get siteCount {
    final payload = cacheResponse.value?.data;
    if (payload?.sites != null) return payload!.sites!;
    final items = payload?.items ?? const [];
    return items.map(_siteLabel).whereType<String>().toSet().length;
  }

  List<String> get siteOptions {
    final items = cacheResponse.value?.data?.items ?? const [];
    final sites = <String>{};
    for (final item in items) {
      final label = _siteLabel(item);
      if (label != null && label.trim().isNotEmpty) {
        sites.add(label.trim());
      }
    }
    final list = sites.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<CacheItem> get filteredItems {
    final items = cacheResponse.value?.data?.items ?? const [];
    if (items.isEmpty) return const [];

    final keywordText = keyword.value.trim().toLowerCase();
    final siteFilter = Set<String>.from(selectedSites);
    return items.where((item) {
      final siteLabel = _siteLabel(item) ?? '';
      if (siteFilter.isNotEmpty && !siteFilter.contains(siteLabel)) {
        return false;
      }
      if (keywordText.isEmpty) return true;
      return _matchesKeyword(item, keywordText);
    }).toList();
  }

  bool _matchesKeyword(CacheItem item, String keyword) {
    final fields = [
      item.title,
      item.description,
      item.mediaName,
      item.siteName,
      item.domain,
      item.mediaType,
      item.seasonEpisode,
      item.resourceTerm,
    ];
    for (final field in fields) {
      if (field == null) continue;
      if (field.toLowerCase().contains(keyword)) return true;
    }
    return false;
  }

  String? _siteLabel(CacheItem item) {
    final site = item.siteName?.trim();
    if (site != null && site.isNotEmpty) return site;
    final domain = item.domain?.trim();
    if (domain != null && domain.isNotEmpty) return domain;
    return null;
  }

  void _syncSelectedSite() {
    if (selectedSites.isEmpty) return;
    final options = siteOptions.toSet();
    if (options.isEmpty) {
      selectedSites.clear();
      return;
    }
    final next = selectedSites.where(options.contains).toSet();
    if (next.length != selectedSites.length) {
      selectedSites.assignAll(next);
    }
  }

  String _buildErrorMessage(int? status, dynamic data) {
    final code = status ?? 0;
    final detail = _extractMessage(data);
    if (detail != null && detail.trim().isNotEmpty) {
      return '请求失败 ($code): $detail';
    }
    return '请求失败 ($code)';
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in ['message', 'detail', 'error', 'msg']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  CacheResponse? _parseResponse(dynamic data) => parseCacheResponse(data);

  // ---------------- 缓存管理动作（v2/v3.1.5 双线一致） ----------------

  Future<({bool ok, String message})> _runAction(
    String label,
    Future<dynamic> Function() action,
  ) async {
    try {
      final response = await action();
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        return (ok: false, message: '$label失败 (HTTP $status)');
      }
      final data = response.data;
      if (data is Map && data['success'] == false) {
        return (
          ok: false,
          message: (data['message']?.toString() ?? '').isNotEmpty
              ? data['message'].toString()
              : '$label失败',
        );
      }
      return (ok: true, message: '$label成功');
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '$label异常');
      return (ok: false, message: '$label失败，请稍后重试');
    }
  }

  /// POST /api/v1/torrent/cache/refresh 刷新种子缓存
  Future<({bool ok, String message})> refreshTorrentCache() async {
    final result = await _runAction(
      '刷新种子缓存',
      () => _apiClient.post<dynamic>('/api/v1/torrent/cache/refresh'),
    );
    if (result.ok) await fetchCache();
    return result;
  }

  /// DELETE /api/v1/torrent/cache 清空种子缓存
  Future<({bool ok, String message})> clearTorrentCache() => _runAction(
        '清空种子缓存',
        () => _apiClient.request<dynamic>(
          '/api/v1/torrent/cache',
          RequestMethod.delete,
          <String, dynamic>{},
        ),
      );

  /// DELETE /api/v1/torrent/cache/{domain}/{hash} 删除单条种子缓存
  Future<({bool ok, String message})> deleteTorrentCacheItem(
    String domain,
    String hash,
  ) => _runAction(
        '删除缓存',
        () => _apiClient.request<dynamic>(
          '/api/v1/torrent/cache/$domain/$hash',
          RequestMethod.delete,
          <String, dynamic>{},
        ),
      );

  /// POST /api/v1/torrent/cache/reidentify/{domain}/{hash} 重新识别种子
  Future<({bool ok, String message})> reidentifyTorrentCacheItem(
    String domain,
    String hash,
  ) => _runAction(
        '重新识别',
        () => _apiClient.post<dynamic>(
          '/api/v1/torrent/cache/reidentify/$domain/$hash',
        ),
      );

  /// DELETE /api/v1/tmdb/cache 清空 TMDB 识别缓存
  Future<({bool ok, String message})> clearTmdbCache() => _runAction(
        '清空 TMDB 识别缓存',
        () => _apiClient.request<dynamic>(
          '/api/v1/tmdb/cache',
          RequestMethod.delete,
          <String, dynamic>{},
        ),
      );

  /// GET /api/v1/tmdb/cache 查询 TMDB 识别缓存（返回原始列表供页面展示）
  Future<List<Map<String, dynamic>>> loadTmdbCache() async {
    try {
      final response = await _apiClient.get<dynamic>('/api/v1/tmdb/cache');
      if ((response.statusCode ?? 0) >= 400) return const [];
      final data = response.data;
      final rawList = data is List
          ? data
          : data is Map
              ? data['data']
              : null;
      if (rawList is! List) return const [];
      return rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 TMDB 识别缓存失败');
      return const [];
    }
  }

  /// DELETE /api/v1/tmdb/cache/{cache_key} 删除单条 TMDB 识别缓存
  Future<({bool ok, String message})> deleteTmdbCacheItem(String cacheKey) =>
      _runAction(
        '删除识别缓存',
        () => _apiClient.request<dynamic>(
          '/api/v1/tmdb/cache/${Uri.encodeComponent(cacheKey)}',
          RequestMethod.delete,
          <String, dynamic>{},
        ),
      );
}
