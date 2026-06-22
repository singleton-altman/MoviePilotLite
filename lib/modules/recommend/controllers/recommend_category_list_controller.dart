import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 推荐分类列表控制器，支持分页加载
class RecommendCategoryListController extends GetxController {
  static const _viewModePrefKey = 'recommend_category_list_view_mode';

  RecommendCategoryListController({
    required String key,
    required String title,
    this.appBarThemeColor,
    this.appBarSecondaryThemeColor,
  }) : _key = key,
       _title = title;

  final String _key;
  final String _title;
  final Color? appBarThemeColor;
  final Color? appBarSecondaryThemeColor;
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _authRepository = Get.find<AuthRepository>();
  final _appService = Get.find<AppService>();

  static const String _basePath = '/api/v1/recommend/';
  bool _cookieRefreshTriggered = false;

  String get categoryTitle => _title;

  final RxList<RecommendApiItem> items = <RecommendApiItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  final RxBool hasMore = false.obs;
  final RxInt currentPage = 0.obs;
  final RxnInt totalItems = RxnInt();
  final Rxn<SearchResultViewMode> preferredViewMode =
      Rxn<SearchResultViewMode>();

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreViewModePref());
  }

  SearchResultViewMode resolvedViewMode({required bool isNarrowScreen}) {
    return preferredViewMode.value ??
        (isNarrowScreen
            ? SearchResultViewMode.list
            : SearchResultViewMode.grid);
  }

  void toggleViewMode({required bool isNarrowScreen}) {
    final current = resolvedViewMode(isNarrowScreen: isNarrowScreen);
    preferredViewMode.value = current == SearchResultViewMode.list
        ? SearchResultViewMode.grid
        : SearchResultViewMode.list;
    unawaited(_persistViewModePref());
  }

  @override
  void onReady() {
    super.onReady();
    _ensureCookieRefreshed();
    loadFirst();
  }

  void _ensureCookieRefreshed() {
    if (_cookieRefreshTriggered) return;
    _cookieRefreshTriggered = true;
    _refreshUserCookie();
  }

  Future<void> _refreshUserCookie() async {
    final server = _appService.baseUrl ?? _apiClient.baseUrl;
    final token =
        _appService.loginResponse?.accessToken ??
        _appService.latestLoginProfileAccessToken ??
        _apiClient.token;
    if (server == null || server.isEmpty || token == null || token.isEmpty) {
      return;
    }
    try {
      await _authRepository.getUserGlobalConfig(
        server: server,
        accessToken: token,
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '刷新推荐分类 Cookie 失败');
    }
  }

  Future<void> loadFirst() async {
    await _fetch(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    await _fetch(page: currentPage.value + 1, append: true);
  }

  Future<void> refreshData() async {
    _ensureCookieRefreshed();
    await loadFirst();
  }

  Future<void> _fetch({required int page, required bool append}) async {
    isLoading.value = true;
    if (!append) {
      error.value = null;
    }
    try {
      final path = '$_basePath$_key';
      final response = await _apiClient.get<dynamic>(
        path,
        queryParameters: {'page': page, 'title': _title},
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 400) {
        if (!append) {
          error.value = '请求失败 (HTTP $statusCode)';
        }
        return;
      }

      final payload = _decodePayload(response.data);
      final list = _extractList(payload);
      final parsed = list
          .whereType<Map>()
          .map((e) => RecommendApiItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (append) {
        items.addAll(parsed);
      } else {
        items.assignAll(parsed);
      }
      currentPage.value = page;
      _updatePagination(payload, page, parsed.length, append);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '推荐分类列表请求异常');
      if (!append) {
        error.value = '请求异常';
      }
    } finally {
      isLoading.value = false;
    }
  }

  dynamic _decodePayload(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      for (final key in ['results', 'data', 'items', 'list', 'subjects']) {
        final value = payload[key];
        if (value is List) return value;
        if (value is Map) {
          for (final inner in value.values) {
            if (inner is List) return inner;
          }
        }
      }
    }
    return const [];
  }

  void _updatePagination(dynamic raw, int page, int received, bool append) {
    int? total;
    bool? hasMoreFromServer;
    if (raw is Map) {
      final map = raw.map((k, v) => MapEntry(k?.toString() ?? '', v));
      total = _asInt(
        map['total'] ??
            map['total_count'] ??
            map['count'] ??
            map['total_results'],
      );
      hasMoreFromServer = _asBool(
        map['has_more'] ?? map['hasMore'] ?? map['has_next'] ?? map['hasNext'],
      );
    }
    if (total != null) totalItems.value = total;
    if (hasMoreFromServer != null) {
      hasMore.value = hasMoreFromServer;
    } else {
      hasMore.value = received >= 20;
    }
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
      final lower = value.toString().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  Future<void> _persistViewModePref() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = preferredViewMode.value;
    if (mode == null) {
      await prefs.remove(_viewModePrefKey);
      return;
    }
    await prefs.setString(_viewModePrefKey, mode.name);
  }

  Future<void> _restoreViewModePref() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_viewModePrefKey);
    if (raw == null || raw.isEmpty) return;
    final matched = SearchResultViewMode.values.where((e) => e.name == raw);
    if (matched.isNotEmpty) {
      preferredViewMode.value = matched.first;
    }
  }
}
