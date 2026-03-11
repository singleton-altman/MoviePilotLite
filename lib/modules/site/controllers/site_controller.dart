import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/site/models/site_icon_cache.dart';
import 'package:moviepilot_mobile/modules/site/models/site_model_cache.dart';
import 'package:moviepilot_mobile/modules/site/models/site_models.dart';
import 'package:moviepilot_mobile/modules/site/models/site_userdata_cache.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/realm_service.dart';

class SiteController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _realm = Get.find<RealmService>();
  final _log = Get.find<AppLog>();

  final items = <SiteItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  /// 可用于 RSS 订阅的站点 ID 集合；null 表示未加载，空集合表示 API 无配置
  final rssSiteIds = Rxn<Set<int>>();

  @override
  void onReady() {
    super.onReady();
    load();
    loadRssSiteIds();
  }

  /// 获取可用于 RSS 的站点 ID 列表
  /// API: GET /api/v1/system/setting/RssSites
  /// 返回: {"success":true,"message":null,"data":{"value":[1,3,2]}}
  Future<void> loadRssSiteIds() async {
    try {
      final resp = await _apiClient.get<dynamic>(
        '/api/v1/system/setting/RssSites',
      );
      if (resp.statusCode == null || resp.statusCode! >= 400) return;
      final body = resp.data;
      if (body is! Map<String, dynamic>) return;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return;
      final value = data['value'];
      if (value is List) {
        final ids = value
            .map((e) => e is int ? e : (e is num ? e.toInt() : null))
            .whereType<int>()
            .toSet();
        rssSiteIds.value = ids;
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 RSS 站点列表失败');
    }
  }

  void search(String? keyword) {
    if (keyword != null && keyword.isNotEmpty) {
      items.value = items
          .where(
            (item) =>
                item.site.name.contains(keyword) ||
                item.site.domain.contains(keyword),
          )
          .toList();
    }
  }

  Future<void> load({String? keyword}) async {
    isLoading.value = true;
    errorText.value = null;
    loadFromCache();

    try {
      // 1. 获取站点列表
      final siteResponse = await _apiClient.get<dynamic>('/api/v1/site/');
      final status = siteResponse.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '获取站点列表失败 (HTTP $status)';
        if (items.isEmpty) items.clear();
        return;
      }

      final siteListRaw = siteResponse.data;
      final siteList = siteListRaw is List ? siteListRaw : <dynamic>[];
      final sites = <SiteModel>[];
      for (final item in siteList) {
        if (item is Map<String, dynamic>) {
          try {
            sites.add(SiteModel.fromJson(item));
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析站点失败');
          }
        }
      }

      // 2. 获取用户数据（按 domain 匹配）
      final userDataMap = <String, SiteUserDataModel>{};
      final userDataResponse = await _apiClient.get<dynamic>(
        '/api/v1/site/userdata/latest',
      );
      final udStatus = userDataResponse.statusCode ?? 0;
      if (udStatus < 400) {
        final udListRaw = userDataResponse.data;
        final udList = udListRaw is List ? udListRaw : <dynamic>[];
        for (final item in udList) {
          if (item is Map<String, dynamic>) {
            try {
              final ud = SiteUserDataModel.fromJson(item);
              if (ud.domain.isNotEmpty) {
                userDataMap[ud.domain] = ud;
              }
            } catch (e, st) {
              _log.handle(e, stackTrace: st, message: '解析站点用户数据失败');
            }
          }
        }
      }

      // 3. 并行拉取每个站点的 icon（先查本地 url->base64 缓存，未命中再请求接口并写入缓存）
      final iconBytesMap = <int, List<int>>{};
      await Future.wait(sites.map((site) => _fetchIconBytes(site))).then((
        results,
      ) {
        for (var i = 0; i < sites.length; i++) {
          final bytes = results[i];
          if (bytes != null && bytes.isNotEmpty) {
            iconBytesMap[sites[i].id] = bytes;
          }
        }
      });

      // 4. 合并为 SiteItem，按 pri 排序
      final merged = sites.map((site) {
        final userData = userDataMap[site.domain];
        final iconBytes = iconBytesMap[site.id];
        return SiteItem(site: site, iconBytes: iconBytes, userData: userData);
      }).toList();

      merged.sort((a, b) => a.site.pri.compareTo(b.site.pri));
      items.assignAll(merged);
      _saveToCache();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载站点失败');
      errorText.value = '加载失败，请稍后重试';
      if (items.isEmpty) items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void loadFromCache() {
    final siteCaches = _realm.realm.all<SiteModelCache>();
    if (siteCaches.isEmpty) return;

    final userDataCaches = _realm.realm.all<SiteUserDataCache>();
    final userDataByDomain = <String, SiteUserDataModel>{};
    for (final c in userDataCaches) {
      userDataByDomain[c.domain] = SiteUserDataModel(
        domain: c.domain,
        username: c.username,
        userid: c.userid,
        userLevel: c.userLevel,
        joinAt: c.joinAt.isEmpty ? null : c.joinAt,
        bonus: c.bonus,
        upload: c.upload,
        download: c.download,
        ratio: c.ratio,
        seeding: c.seeding,
        leeching: c.leeching,
        seedingSize: c.seedingSize,
        leechingSize: c.leechingSize,
        seedingInfo: const [],
        messageUnread: c.messageUnread,
        messageUnreadContents: const [],
        errMsg: c.errMsg,
        updatedDay: c.updatedDay,
        updatedTime: c.updatedTime,
      );
    }

    final iconCaches = _realm.realm.all<SiteIconCache>();
    final iconBytesByUrl = <String, List<int>>{};
    for (final c in iconCaches) {
      if (c.iconBase64.isEmpty) continue;
      final bytes = _decodeBase64ToBytes(c.iconBase64);
      if (bytes != null) iconBytesByUrl[c.url] = bytes;
    }

    final list = siteCaches.map((c) {
      final site = SiteModel(
        id: c.id,
        name: c.name,
        domain: c.domain,
        url: c.url,
        pri: c.pri,
        rss: c.rss.isEmpty ? null : c.rss,
        cookie: c.cookie.isEmpty ? null : c.cookie,
        ua: c.ua.isEmpty ? null : c.ua,
        apikey: c.apikey.isEmpty ? null : c.apikey,
        token: c.token.isEmpty ? null : c.token,
        proxy: c.proxy,
        filter: c.filter.isEmpty ? null : c.filter,
        render: c.render,
        public: c.public,
        note: c.note.isEmpty ? null : c.note,
        timeout: c.timeout,
        limitInterval: c.limitInterval,
        limitCount: c.limitCount,
        limitSeconds: c.limitSeconds,
        isActive: c.isActive,
        downloader: c.downloader,
      );
      final userData = userDataByDomain[c.domain];
      final iconBytes = iconBytesByUrl[c.url];
      return SiteItem(site: site, iconBytes: iconBytes, userData: userData);
    }).toList();

    list.sort((a, b) => a.site.pri.compareTo(b.site.pri));
    items.assignAll(list);
  }

  void _saveToCache() {
    final siteCaches = items.map((item) {
      final s = item.site;
      return SiteModelCache(
        s.id,
        s.name,
        s.domain,
        s.url,
        s.pri,
        s.rss ?? '',
        s.cookie ?? '',
        s.ua ?? '',
        s.apikey ?? '',
        s.token ?? '',
        s.proxy,
        s.filter ?? '',
        s.render,
        s.public,
        s.note ?? '',
        s.timeout,
        s.limitInterval,
        s.limitCount,
        s.limitSeconds,
        s.isActive,
        s.downloader,
      );
    }).toList();

    final userDataCaches = items.where((item) => item.userData != null).map((
      item,
    ) {
      final u = item.userData!;
      return SiteUserDataCache(
        u.domain,
        u.username,
        u.userid,
        u.userLevel,
        u.joinAt ?? '',
        u.bonus,
        u.upload,
        u.download,
        u.ratio,
        u.seeding,
        u.leeching,
        u.seedingSize,
        u.leechingSize,
        u.messageUnread,
        u.errMsg,
        u.updatedDay,
        u.updatedTime,
      );
    }).toList();

    _realm.realm.write(() {
      _realm.realm.deleteAll<SiteModelCache>();
      _realm.realm.deleteAll<SiteUserDataCache>();
      _realm.realm.addAll(siteCaches);
      _realm.realm.addAll(userDataCaches);
    });
  }

  /// 先按站点 url 查本地 icon 缓存，未命中再请求接口并写入 Realm（url -> base64）
  Future<List<int>?> _fetchIconBytes(SiteModel site) async {
    final url = site.url;
    if (url.isEmpty) return _fetchIconBytesFromApi(site.id, url);

    final cached = _realm.realm.find<SiteIconCache>(url);
    if (cached != null && cached.iconBase64.isNotEmpty) {
      return _decodeBase64ToBytes(cached.iconBase64);
    }

    return _fetchIconBytesFromApi(site.id, url);
  }

  /// 通用图标加载：优先本地缓存，其次请求接口；返回 bytes 并同步到 items
  Future<List<int>?> loadIcon(SiteModel site) async {
    final index = items.indexWhere((e) => e.site.id == site.id);
    final cachedBytes = index == -1 ? null : items[index].iconBytes;
    if (cachedBytes != null && cachedBytes.isNotEmpty) {
      return cachedBytes;
    }

    final bytes = await _fetchIconBytes(site);
    if (bytes != null && bytes.isNotEmpty && index != -1) {
      final current = items[index];
      items[index] = current.copyWith(iconBytes: bytes);
    }
    return bytes;
  }

  Future<List<int>?> _fetchIconBytesFromApi(int siteId, String siteUrl) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/site/icon/$siteId',
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) return null;
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final res = SiteIconResponse.fromJson(data);
      final raw = res.data?.icon;
      if (raw == null || raw.isEmpty) return null;

      String base64 = raw.trim();
      if (base64.contains(',')) {
        final comma = base64.indexOf(',');
        base64 = base64.substring(comma + 1).trim();
      }
      if (base64.isEmpty) return null;

      final bytes = base64Decode(base64);
      if (bytes.isEmpty) return null;

      if (siteUrl.isNotEmpty) {
        _realm.realm.write(() {
          _realm.realm.add(SiteIconCache(siteUrl, base64), update: true);
        });
      }

      return bytes;
    } catch (_) {
      return null;
    }
  }

  List<int>? _decodeBase64ToBytes(String base64) {
    try {
      String s = base64.trim();
      if (s.contains(',')) {
        final comma = s.indexOf(',');
        s = s.substring(comma + 1).trim();
      }
      if (s.isEmpty) return null;
      final bytes = base64Decode(s);
      return bytes.isNotEmpty ? bytes : null;
    } catch (_) {
      return null;
    }
  }
}
