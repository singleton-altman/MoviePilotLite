import 'dart:convert';
import 'dart:async';

import 'package:drift/drift.dart' hide Value;
import 'package:drift/drift.dart' as drift show Value;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/database/app_database.dart';
import 'package:moviepilot_mobile/database/tables/site_icon_caches.dart';
import 'package:moviepilot_mobile/database/tables/site_model_caches.dart';
import 'package:moviepilot_mobile/database/tables/site_userdata_caches.dart';
import 'package:moviepilot_mobile/modules/site/models/site_models.dart';
import 'package:moviepilot_mobile/modules/site/models/site_resource_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/database_service.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';

class SiteController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _iosSharedSessionService = Get.find<IosSharedSessionService>();
  final _db = Get.find<DatabaseService>();
  final _log = Get.find<AppLog>();

  final items = <SiteItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();
  bool _didInitialize = false;

  /// 可用于 RSS 订阅的站点 ID 集合；null 表示未加载，空集合表示 API 无配置
  final rssSiteIds = Rxn<Set<int>>();

  @override
  void onReady() {
    super.onReady();
    unawaited(ensureInitialized());
  }

  Future<void> ensureInitialized() async {
    if (_didInitialize) return;
    _didInitialize = true;
    await load();
    await loadRssSiteIds();
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

  SiteModel _safeParseSiteModel(Map<String, dynamic> json) {
    int asInt(Object? v, {int def = 0}) {
      if (v == null) return def;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    String asString(Object? v, {String def = ''}) {
      if (v == null) return def;
      final s = v.toString();
      return s;
    }

    bool asBool(Object? v, {bool def = false}) {
      if (v == null) return def;
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is num) return v.toInt() != 0;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1';
      }
      return def;
    }

    return SiteModel(
      id: asInt(json['id']),
      name: asString(json['name']),
      domain: asString(json['domain']),
      url: asString(json['url']),
      pri: asInt(json['pri']),
      rss: (json['rss']?.toString().isEmpty ?? true)
          ? null
          : json['rss'].toString(),
      cookie: (json['cookie']?.toString().isEmpty ?? true)
          ? null
          : json['cookie'].toString(),
      ua: (json['ua']?.toString().isEmpty ?? true)
          ? null
          : json['ua'].toString(),
      apikey: (json['apikey']?.toString().isEmpty ?? true)
          ? null
          : json['apikey'].toString(),
      token: (json['token']?.toString().isEmpty ?? true)
          ? null
          : json['token'].toString(),
      proxy: asInt(json['proxy']),
      filter: (json['filter']?.toString().isEmpty ?? true)
          ? null
          : json['filter'].toString(),
      render: asInt(json['render']),
      public: asInt(json['public']),
      note: (json['note']?.toString().isEmpty ?? true)
          ? null
          : json['note'].toString(),
      timeout: asInt(json['timeout'], def: 15),
      limitInterval: asInt(json['limit_interval']),
      limitCount: asInt(json['limit_count']),
      limitSeconds: asInt(json['limit_seconds']),
      isActive: asBool(json['is_active'], def: true),
      downloader: asString(json['downloader']),
    );
  }

  Future<void> load({String? keyword}) async {
    isLoading.value = true;
    errorText.value = null;
    await loadFromCache();

    final sites = <SiteModel>[];
    final userDataMap = <String, SiteUserDataModel>{};
    final iconBytesMap = <int, List<int>>{};

    try {
      final siteResponse = await _apiClient.get<dynamic>('/api/v1/site/');
      final status = siteResponse.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '获取站点列表失败 (HTTP $status)';
        if (items.isEmpty) items.clear();
        isLoading.value = false;
        return;
      }

      final siteListRaw = siteResponse.data;
      final siteList = siteListRaw is List ? siteListRaw : <dynamic>[];
      for (final item in siteList) {
        if (item is Map<String, dynamic>) {
          try {
            final site = _safeParseSiteModel(item);
            if (site.id != -1) sites.add(site);
          } catch (e, st) {
            final id = item['id'];
            final name = item['name'];
            _log.handle(e, stackTrace: st, message: '解析站点失败 id=$id name=$name');
          }
        }
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载站点列表失败');
      errorText.value = '加载失败，请稍后重试';
      if (items.isEmpty) items.clear();
      isLoading.value = false;
      return;
    } finally {
      if (sites.isNotEmpty) {
        final baseMerged =
            sites
                .map(
                  (site) =>
                      SiteItem(site: site, userData: null, iconBytes: null),
                )
                .toList()
              ..sort((a, b) => a.site.pri.compareTo(b.site.pri));
        items.assignAll(baseMerged);
      }
    }

    try {
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
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载站点用户数据失败');
    }

    try {
      final results = await Future.wait(
        sites.map((site) => _fetchIconBytes(site)),
      );
      for (var i = 0; i < sites.length; i++) {
        final bytes = results[i];
        if (bytes != null && bytes.isNotEmpty) {
          iconBytesMap[sites[i].id] = bytes;
        }
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载站点图标失败');
    }

    final merged = sites.map((site) {
      final userData = userDataMap[site.domain];
      final iconBytes = iconBytesMap[site.id];
      return SiteItem(site: site, iconBytes: iconBytes, userData: userData);
    }).toList();

    merged.sort((a, b) => a.site.pri.compareTo(b.site.pri));
    items.assignAll(merged);
    await _saveToCache();
    await _syncWidgetSnapshot(merged);
    isLoading.value = false;
  }

  Future<void> loadFromCache() async {
    if (kIsWeb) return;
    final dao = _db.db.siteCacheDao;
    final siteRows = await dao.getAllSiteModels();
    if (siteRows.isEmpty) return;

    final userDataRows = await dao.getAllUserData();
    final userDataByDomain = <String, SiteUserDataModel>{};
    for (final c in userDataRows) {
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

    final iconRows = await dao.getAllIcons();
    final iconBytesByUrl = <String, List<int>>{};
    for (final c in iconRows) {
      if (c.iconBase64.isEmpty) continue;
      final bytes = _decodeBase64ToBytes(c.iconBase64);
      if (bytes != null) iconBytesByUrl[c.url] = bytes;
    }

    final list = siteRows.map((c) {
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
    unawaited(_syncWidgetSnapshot(list));
  }

  Future<void> _syncWidgetSnapshot(List<SiteItem> sourceItems) async {
    if (sourceItems.isEmpty) return;
    try {
      await _iosSharedSessionService.syncSiteWidgetPayload(
        jsonEncode(_buildWidgetPayload(sourceItems)),
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '同步 iOS 站点组件数据失败');
    }
  }

  Map<String, dynamic> _buildWidgetPayload(List<SiteItem> sourceItems) {
    final summarySites = List<SiteItem>.from(sourceItems)
      ..sort((a, b) {
        final aIssue = _hasSiteIssue(a) ? 1 : 0;
        final bIssue = _hasSiteIssue(b) ? 1 : 0;
        if (aIssue != bIssue) return bIssue.compareTo(aIssue);

        final aUnread = a.userData?.messageUnread ?? 0;
        final bUnread = b.userData?.messageUnread ?? 0;
        if (aUnread != bUnread) return bUnread.compareTo(aUnread);

        final aUpload = a.userData?.upload ?? 0;
        final bUpload = b.userData?.upload ?? 0;
        if (aUpload != bUpload) return bUpload.compareTo(aUpload);

        return a.site.pri.compareTo(b.site.pri);
      });

    return {
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'summary': {
        'totalSites': sourceItems.length,
        'enabledSites': sourceItems.where((item) => item.site.isActive).length,
        'sitesWithUserData': sourceItems
            .where((item) => item.userData != null)
            .length,
        'warningSites': sourceItems.where(_hasSiteIssue).length,
        'unreadMessages': sourceItems.fold<int>(
          0,
          (sum, item) => sum + (item.userData?.messageUnread ?? 0),
        ),
        'totalUpload': sourceItems.fold<int>(
          0,
          (sum, item) => sum + (item.userData?.upload ?? 0),
        ),
        'totalDownload': sourceItems.fold<int>(
          0,
          (sum, item) => sum + (item.userData?.download ?? 0),
        ),
        'totalSeeding': sourceItems.fold<int>(
          0,
          (sum, item) => sum + (item.userData?.seeding ?? 0),
        ),
        'totalSeedingSize': sourceItems.fold<int>(
          0,
          (sum, item) => sum + (item.userData?.seedingSize ?? 0),
        ),
        'totalBonus': sourceItems.fold<double>(
          0,
          (sum, item) => sum + (item.userData?.bonus ?? 0),
        ),
      },
      'sites': summarySites.map((item) {
        final userData = item.userData;
        final iconBase64 = _siteIconBase64(item);
        return {
          'id': item.site.id,
          'name': item.site.name,
          'domain': item.site.domain,
          'priority': item.site.pri,
          'iconBase64': iconBase64,
          'isActive': item.site.isActive,
          'hasIssue': _hasSiteIssue(item),
          'errorMessage': (userData?.errMsg ?? '').trim(),
          'messageUnread': userData?.messageUnread ?? 0,
          'upload': userData?.upload ?? 0,
          'download': userData?.download ?? 0,
          'ratio': userData?.ratio ?? 0,
          'seeding': userData?.seeding ?? 0,
          'seedingSize': userData?.seedingSize ?? 0,
          'bonus': userData?.bonus ?? 0,
          'updatedDay': userData?.updatedDay ?? '',
          'updatedTime': userData?.updatedTime ?? '',
        };
      }).toList(),
    };
  }

  bool _hasSiteIssue(SiteItem item) {
    if (!item.site.isActive) return true;
    final errMsg = (item.userData?.errMsg ?? '').trim();
    return errMsg.isNotEmpty;
  }

  String? _siteIconBase64(SiteItem item) {
    final inlineBase64 = item.iconBase64?.trim();
    if (inlineBase64 != null && inlineBase64.isNotEmpty) {
      return inlineBase64;
    }
    final bytes = item.iconBytes;
    if (bytes == null || bytes.isEmpty) return null;
    return base64Encode(bytes);
  }

  Future<void> _saveToCache() async {
    if (kIsWeb) return;
    final dao = _db.db.siteCacheDao;
    final siteRows = items.map((item) {
      final s = item.site;
      return SiteModelCachesCompanion(
        id: drift.Value(s.id),
        name: drift.Value(s.name),
        domain: drift.Value(s.domain),
        url: drift.Value(s.url),
        pri: drift.Value(s.pri),
        rss: drift.Value(s.rss ?? ''),
        cookie: drift.Value(s.cookie ?? ''),
        ua: drift.Value(s.ua ?? ''),
        apikey: drift.Value(s.apikey ?? ''),
        token: drift.Value(s.token ?? ''),
        proxy: drift.Value(s.proxy),
        filter: drift.Value(s.filter ?? ''),
        render: drift.Value(s.render),
        public: drift.Value(s.public),
        note: drift.Value(s.note ?? ''),
        timeout: drift.Value(s.timeout),
        limitInterval: drift.Value(s.limitInterval),
        limitCount: drift.Value(s.limitCount),
        limitSeconds: drift.Value(s.limitSeconds),
        isActive: drift.Value(s.isActive),
        downloader: drift.Value(s.downloader),
      );
    }).toList();

    final userDataByDomain = <String, SiteUserDataCachesCompanion>{};
    for (final item in items) {
      final u = item.userData;
      if (u == null) continue;
      if (u.domain.isEmpty) continue;
      userDataByDomain[u.domain] = SiteUserDataCachesCompanion(
        domain: drift.Value(u.domain),
        username: drift.Value(u.username),
        userid: drift.Value(u.userid),
        userLevel: drift.Value(u.userLevel),
        joinAt: drift.Value(u.joinAt ?? ''),
        bonus: drift.Value(u.bonus),
        upload: drift.Value(u.upload),
        download: drift.Value(u.download),
        ratio: drift.Value(u.ratio),
        seeding: drift.Value(u.seeding),
        leeching: drift.Value(u.leeching),
        seedingSize: drift.Value(u.seedingSize),
        leechingSize: drift.Value(u.leechingSize),
        messageUnread: drift.Value(u.messageUnread),
        errMsg: drift.Value(u.errMsg),
        updatedDay: drift.Value(u.updatedDay),
        updatedTime: drift.Value(u.updatedTime),
      );
    }

    await dao.replaceAllSiteModels(siteRows);
    await dao.replaceAllUserData(userDataByDomain.values.toList());
  }

  /// Look up local icon cache by site url, fall back to API.
  Future<List<int>?> _fetchIconBytes(SiteModel site) async {
    final url = site.url;
    if (url.isEmpty) return _fetchIconBytesFromApi(site.id, url);

    if (kIsWeb) {
      return _fetchIconBytesFromApi(site.id, url);
    }

    final cached = await _db.db.siteCacheDao.findIconByUrl(url);
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

      if (!kIsWeb && siteUrl.isNotEmpty) {
        await _db.db.siteCacheDao.upsertIcon(
          SiteIconCachesCompanion(
            url: drift.Value(siteUrl),
            iconBase64: drift.Value(base64),
          ),
        );
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
