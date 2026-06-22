import 'package:drift/drift.dart' hide Value;
import 'package:drift/drift.dart' as drift show Value;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/database/app_database.dart';
import 'package:moviepilot_mobile/database/tables/site_icon_caches.dart';
import 'package:moviepilot_mobile/modules/site/models/site_models.dart';
import 'package:moviepilot_mobile/modules/site/models/site_resource_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/database_service.dart';

class SiteDetailController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _db = Get.find<DatabaseService>();
  final _log = Get.find<AppLog>();

  int? siteId;
  String siteName = '';
  SiteModel? site;

  final iconBase64 = RxnString();
  final historyItems = <SiteUserDataHistoryItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  // 站点资源（合并自 SiteResourceController）
  final resourceCategories = <SiteResourceCategory>[].obs;
  final resourceItems = <SiteResourceItem>[].obs;
  final resourceLoading = false.obs;
  final resourceErrorText = RxnString();
  final resourceKeyword = ''.obs;
  final selectedResourceCategoryId = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      final id = args['siteId'];
      siteId = id is int ? id : (id is String ? int.tryParse(id) : null);
      siteName = args['siteName']?.toString() ?? '';
      if (args['site'] is Map<String, dynamic>) {
        try {
          site = SiteModel.fromJson(args['site'] as Map<String, dynamic>);
        } catch (e, st) {
          _log.handle(e, stackTrace: st, message: '解析站点信息失败');
        }
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (siteId != null) {
      loadSiteDetail();
      loadIcon();
      loadUserdataHistory();
      loadResourceCategories();
      loadResources();
    }
  }

  Future<void> loadSiteDetail() async {
    final id = siteId;
    if (id == null) return;
    try {
      final response = await _apiClient.get<dynamic>('/api/v1/site/$id');
      final status = response.statusCode ?? 0;
      if (status >= 400) return;
      final data = response.data;
      if (data is! Map<String, dynamic>) return;
      final detail = SiteModel.fromJson(data);
      site = detail;
      siteName = detail.name;
      update();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载站点详情失败');
    }
  }

  /// 优先从 Realm 按站点 url 取 icon，未命中再请求接口并写入缓存
  Future<void> loadIcon() async {
    final id = siteId;
    final siteUrl = site?.url ?? '';
    if (id == null) return;

    if (!kIsWeb && siteUrl.isNotEmpty) {
      final cached = await _db.db.siteCacheDao.findIconByUrl(siteUrl);
      if (cached != null && cached.iconBase64.isNotEmpty) {
        String base64 = cached.iconBase64.trim();
        if (base64.contains(',')) {
          final comma = base64.indexOf(',');
          base64 = base64.substring(comma + 1).trim();
        }
        if (base64.isNotEmpty) {
          iconBase64.value = base64;
          return;
        }
      }
    }

    try {
      final response = await _apiClient.get<dynamic>('/api/v1/site/icon/$id');
      if ((response.statusCode ?? 0) >= 400) return;
      final data = response.data;
      if (data is! Map<String, dynamic>) return;
      final res = SiteIconResponse.fromJson(data);
      final raw = res.data?.icon;
      if (raw == null || raw.isEmpty) return;
      String base64 = raw.trim();
      if (base64.contains(',')) {
        final comma = base64.indexOf(',');
        base64 = base64.substring(comma + 1).trim();
      }
      if (base64.isEmpty || iconBase64.value == base64) return;
      iconBase64.value = base64;
      if (!kIsWeb && siteUrl.isNotEmpty) {
        await _db.db.siteCacheDao.upsertIcon(
          SiteIconCachesCompanion(
            url: drift.Value(siteUrl),
            iconBase64: drift.Value(base64),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> loadUserdataHistory() async {
    final id = siteId;
    if (id == null) return;
    isLoading.value = true;
    errorText.value = null;
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/site/userdata/$id',
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '获取用户数据失败 (HTTP $status)';
        historyItems.clear();
        return;
      }
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        historyItems.clear();
        return;
      }
      final res = SiteUserDataHistoryResponse.fromJson(raw);
      if (!res.success) {
        errorText.value = res.message ?? '请求失败';
        historyItems.clear();
        return;
      }
      final list = res.data.toList();
      list.sort((a, b) {
        final da = a.updatedDay;
        final db = b.updatedDay;
        if (da != db) return da.compareTo(db);
        return (a.updatedTime).compareTo(b.updatedTime);
      });
      historyItems.assignAll(list);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载用户数据历史失败');
      errorText.value = '加载失败，请稍后重试';
      historyItems.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // ---------- 站点资源（合并自 SiteResourceController）----------

  bool get hasActiveResourceFilters => selectedResourceCategoryId.value != null;

  String get resourceCategoryFilterLabel {
    final id = selectedResourceCategoryId.value;
    if (id == null) return '全部分类';
    SiteResourceCategory? c;
    for (final e in resourceCategories) {
      if (e.id == id) {
        c = e;
        break;
      }
    }
    return c?.desc.isNotEmpty == true ? c!.desc : (c?.cat ?? '全部分类');
  }

  Future<void> loadResourceCategories() async {
    final id = siteId;
    if (id == null) return;
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/site/category/$id',
      );
      if ((response.statusCode ?? 0) >= 400) return;
      final raw = response.data;
      final list = raw is List ? raw : <dynamic>[];
      final parsed = <SiteResourceCategory>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          try {
            parsed.add(SiteResourceCategory.fromJson(item));
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析站点分类失败');
          }
        }
      }
      resourceCategories.assignAll(parsed);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载站点分类失败');
    }
  }

  Future<void> loadResources() async {
    final id = siteId;
    if (id == null) {
      resourceErrorText.value = '缺少站点 ID';
      resourceItems.clear();
      return;
    }
    resourceLoading.value = true;
    resourceErrorText.value = null;
    try {
      final query = <String, String>{};
      final cid = selectedResourceCategoryId.value;
      if (cid != null) {
        SiteResourceCategory? c;
        for (final e in resourceCategories) {
          if (e.id == cid) {
            c = e;
            break;
          }
        }
        query['cat'] = (c != null && c.cat.isNotEmpty) ? c.cat : cid.toString();
      }
      final kw = resourceKeyword.value.trim();
      if (kw.isNotEmpty) query['keyword'] = kw;

      final response = await _apiClient.get<dynamic>(
        '/api/v1/site/resource/$id',
        queryParameters: query.isEmpty ? null : query,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        resourceErrorText.value = '获取资源失败 (HTTP $status)';
        resourceItems.clear();
        return;
      }
      final raw = response.data;
      final list = raw is List ? raw : <dynamic>[];
      final parsed = <SiteResourceItem>[];
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          try {
            parsed.add(SiteResourceItem.fromJson(item));
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析资源项失败');
          }
        }
      }
      resourceItems.assignAll(parsed);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载站点资源失败');
      resourceErrorText.value = '加载失败，请稍后重试';
      resourceItems.clear();
    } finally {
      resourceLoading.value = false;
    }
  }

  void updateResourceKeyword(String value) {
    resourceKeyword.value = value.trim();
  }

  void setResourceCategoryFilter(int? categoryId) {
    selectedResourceCategoryId.value = categoryId;
  }

  void clearResourceCategoryFilter() {
    selectedResourceCategoryId.value = null;
  }

  void onResourceSearchSubmitted(String value) {
    resourceKeyword.value = value.trim();
    loadResources();
  }

  void applyResourceFilterAndLoad() {
    loadResources();
  }

  /// 下拉刷新：同时刷新用户数据历史与资源列表
  Future<void> refreshAll() async {
    await Future.wait([
      loadSiteDetail(),
      loadUserdataHistory(),
      loadResources(),
    ]);
  }
}
