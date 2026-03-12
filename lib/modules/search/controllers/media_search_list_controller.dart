import 'dart:async';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_api_item_ext.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class MediaSearchListController extends GetxController {
  final _subscribeService = Get.put(SubscribeService());
  MediaSearchListController({String? initialKeyword, String? initialType}) {
    final seed = initialKeyword?.trim();
    if (seed != null && seed.isNotEmpty) {
      keyword.value = seed;
    }
    if (initialType != null && initialType.isNotEmpty) {
      type = initialType.trim().toLowerCase();
    }
  }
  String type = 'media';
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  final RxString keyword = ''.obs;
  final RxList<RecommendApiItem> items = <RecommendApiItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  final RxBool hasMore = false.obs;
  final RxInt currentPage = 1.obs;
  final RxnInt totalItems = RxnInt();
  final RxnInt totalPages = RxnInt();
  final RxnInt pageSize = RxnInt();

  static const _basePath = '/api/v1/media/search';

  @override
  void onReady() {
    super.onReady();
    if (keyword.value.isNotEmpty) {
      search(keyword: keyword.value);
    }
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> search({String? keyword}) async {
    final term = (keyword ?? this.keyword.value).trim();
    if (term.isEmpty) {
      error.value = '请输入搜索关键字';
      items.clear();
      hasMore.value = false;
      return;
    }
    this.keyword.value = term;
    await _fetch(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    await _fetch(page: currentPage.value + 1, append: true);
  }

  Future<void> _fetch({required int page, required bool append}) async {
    final term = keyword.value.trim();
    if (term.isEmpty) return;
    isLoading.value = true;
    error.value = null;

    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        error.value = '请先登录后再尝试搜索';
        isLoading.value = false;
        return;
      }
      final params = {'title': term, 'type': type, 'page': page};

      final response = await _apiClient.get<dynamic>(
        _basePath,
        token: token,
        timeout: 30,
        queryParameters: params,
      );
      final status = response.statusCode ?? 0;
      if (status == 401 || status == 403) {
        error.value = '登录已过期，请重新登录';
        isLoading.value = false;
        return;
      }
      if (status >= 400) {
        error.value = '请求失败 (HTTP $status)';
        isLoading.value = false;
        return;
      }
      final raw = response.data;
      final parsed = _extractList(raw)
          .whereType<Map<String, dynamic>>()
          .map(RecommendApiItem.fromJson)
          .toList();
      if (append) {
        items.addAll(parsed);
      } else {
        items.assignAll(parsed);
      }
      currentPage.value = page;
      _updatePagination(raw, page, parsed.length, append);
      if (parsed.isEmpty && !append) {
        error.value = '没有找到匹配的媒体';
      }
      for (final item in parsed) {
        _subscribeService.fetchAndSaveSubscribeStatus(
          item.mediaKey,
          season: item.season,
          title: item.title,
        );
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '媒体搜索失败');
      error.value = '搜索失败，请稍后重试';
    } finally {
      isLoading.value = false;
    }
  }

  Iterable<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      for (final key in const ['data', 'results', 'items', 'list']) {
        final value = raw[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  void _updatePagination(dynamic raw, int page, int received, bool append) {
    bool? serverHasMore;
    int? serverTotal;
    int? serverPages;
    int? serverPageSize;
    if (raw is Map<String, dynamic>) {
      serverHasMore = _asBool(
        raw['has_more'] ?? raw['hasMore'] ?? raw['has_next'] ?? raw['hasNext'],
      );
      serverTotal = _asInt(raw['total'] ?? raw['total_count'] ?? raw['count']);
      serverPages = _asInt(
        raw['pages'] ?? raw['total_pages'] ?? raw['totalPages'],
      );
      serverPageSize = _asInt(
        raw['page_size'] ?? raw['pageSize'] ?? raw['per_page'],
      );
    }

    if (!append || page == 1) {
      totalItems.value = serverTotal;
      totalPages.value = serverPages;
      pageSize.value = serverPageSize;
    } else {
      totalItems.value ??= serverTotal;
      totalPages.value ??= serverPages;
      pageSize.value ??= serverPageSize;
    }

    bool next;
    if (serverHasMore != null) {
      next = serverHasMore;
    } else if (totalPages.value != null) {
      next = page < totalPages.value!;
    } else if (totalItems.value != null &&
        pageSize.value != null &&
        pageSize.value! > 0) {
      final maxPages = (totalItems.value! / pageSize.value!).ceil();
      next = page < maxPages;
    } else {
      final expectedSize = pageSize.value ?? received;
      if (expectedSize <= 0) {
        next = received > 0;
      } else {
        next = received >= expectedSize;
      }
    }
    hasMore.value = next;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }
}
