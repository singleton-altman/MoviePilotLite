import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moviepilot_mobile/modules/download/utils/search_result_raw_cache.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/site/models/site_resource_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

enum SiteResourceSortKey { defaultSort, size, seeders, pubdate }

enum SiteResourceSortDirection { asc, desc }

class SiteResourceController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  int? siteId;
  String siteName = '';

  final categories = <SiteResourceCategory>[].obs;
  final rawItems = <SiteResourceItem>[].obs;
  final items = <SearchResultItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  final keyword = ''.obs;
  final selectedCategoryId = Rxn<int>();
  final sortKey = SiteResourceSortKey.defaultSort.obs;
  final sortDirection = SiteResourceSortDirection.desc.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      final id = args['siteId'];
      siteId = id is int ? id : (id is String ? int.tryParse(id) : null);
      siteName = args['siteName']?.toString() ?? '';
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadCategories();
    loadResources();
  }

  bool get hasActiveFilters => selectedCategoryId.value != null;

  List<SearchResultItem> get visibleItems {
    final key = keyword.value.trim().toLowerCase();
    var list = items.toList();
    if (key.isNotEmpty) {
      list = list.where((item) => _matchKeyword(item, key)).toList();
    }
    return _sortItems(list);
  }

  String get categoryFilterLabel {
    final id = selectedCategoryId.value;
    if (id == null) return '全部分类';
    SiteResourceCategory? c;
    for (final e in categories) {
      if (e.id == id) {
        c = e;
        break;
      }
    }
    return c?.desc.isNotEmpty == true ? c!.desc : (c?.cat ?? '全部分类');
  }

  Future<void> loadCategories() async {
    final id = siteId;
    if (id == null) return;
    try {
      final response = await _apiClient.get<dynamic>('/api/v1/site/category/$id');
      final status = response.statusCode ?? 0;
      if (status >= 400) return;
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
      categories.assignAll(parsed);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载站点分类失败');
    }
  }

  Future<void> loadResources() async {
    final id = siteId;
    if (id == null) {
      errorText.value = '缺少站点 ID';
      items.clear();
      return;
    }
    isLoading.value = true;
    errorText.value = null;
    try {
      final query = <String, String>{};
      final cid = selectedCategoryId.value;
      if (cid != null) {
        SiteResourceCategory? c;
        for (final e in categories) {
          if (e.id == cid) {
            c = e;
            break;
          }
        }
        query['cat'] = (c != null && c.cat.isNotEmpty) ? c.cat : cid.toString();
      }
      final kw = keyword.value.trim();
      if (kw.isNotEmpty) query['keyword'] = kw;

      final response = await _apiClient.get<dynamic>(
        '/api/v1/site/resource/$id',
        queryParameters: query.isEmpty ? null : query,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '获取资源失败 (HTTP $status)';
        items.clear();
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
      rawItems.assignAll(parsed);
      items.assignAll(parsed.map(_mapToSearchResultItem));
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载站点资源失败');
      errorText.value = '加载失败，请稍后重试';
      rawItems.clear();
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void updateKeyword(String value) {
    keyword.value = value.trim();
    loadResources();
  }

  void setCategoryFilter(int? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  void clearCategoryFilter() {
    selectedCategoryId.value = null;
  }

  void onSearchSubmitted(String value) {
    keyword.value = value.trim();
    loadResources();
  }

  void updateSortKey(SiteResourceSortKey value) {
    sortKey.value = value;
  }

  void updateSortDirection(bool ascending) {
    sortDirection.value = ascending
        ? SiteResourceSortDirection.asc
        : SiteResourceSortDirection.desc;
  }

  void applyFilterAndLoad() {
    loadResources();
  }

  SearchResultItem _mapToSearchResultItem(SiteResourceItem item) {
    final result = SearchResultItem(
      meta_info: SearchMetaInfo(
        title: item.title,
        subtitle: item.description,
        org_string: item.title,
        resource_type: item.labels.isNotEmpty ? item.labels.first : null,
      ),
      torrent_info: SearchTorrentInfo(
        site: item.site,
        site_name: item.siteName,
        site_cookie: item.siteCookie,
        site_ua: item.siteUa,
        site_proxy: item.siteProxy,
        site_order: item.siteOrder,
        site_downloader: item.siteDownloader,
        title: item.title,
        description: item.description,
        imdbid: item.imdbid,
        enclosure: item.enclosure,
        page_url: item.pageUrl,
        size: item.size,
        seeders: item.seeders,
        peers: item.peers,
        grabs: item.grabs,
        pubdate: item.pubdate,
        date_elapsed: item.dateElapsed,
        freedate: item.freedate,
        uploadvolumefactor: item.uploadVolumeFactor,
        downloadvolumefactor: item.downloadVolumeFactor,
        hit_and_run: item.hitAndRun,
        labels: item.labels,
        pri_order: item.priOrder,
        volume_factor: item.volumeFactor,
        freedate_diff: item.freedateDiff,
      ),
    );
    cacheSearchResultItemRaw(result, {
      'meta_info': result.meta_info?.toJson(),
      'torrent_info': result.torrent_info?.toJson(),
    });
    return result;
  }

  bool _matchKeyword(SearchResultItem item, String keywordLower) {
    final meta = item.meta_info;
    final torrent = item.torrent_info;
    final buffer = StringBuffer()
      ..write(meta?.title ?? '')
      ..write(' ')
      ..write(meta?.subtitle ?? '')
      ..write(' ')
      ..write(torrent?.title ?? '')
      ..write(' ')
      ..write(torrent?.description ?? '')
      ..write(' ')
      ..write(torrent?.site_name ?? '');
    return buffer.toString().toLowerCase().contains(keywordLower);
  }

  List<SearchResultItem> _sortItems(List<SearchResultItem> list) {
    if (sortKey.value == SiteResourceSortKey.defaultSort) {
      return list;
    }
    list.sort((a, b) {
      int result;
      switch (sortKey.value) {
        case SiteResourceSortKey.defaultSort:
          result = 0;
          break;
        case SiteResourceSortKey.size:
          result = (a.torrent_info?.size ?? 0).compareTo(
            b.torrent_info?.size ?? 0,
          );
          break;
        case SiteResourceSortKey.seeders:
          result = (a.torrent_info?.seeders ?? 0).compareTo(
            b.torrent_info?.seeders ?? 0,
          );
          break;
        case SiteResourceSortKey.pubdate:
          result = _parseDate(a.torrent_info?.pubdate).compareTo(
            _parseDate(b.torrent_info?.pubdate),
          );
          break;
      }
      return sortDirection.value == SiteResourceSortDirection.asc
          ? result
          : -result;
    });
    return list;
  }

  DateTime _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    try {
      return _dateFormat.parseUtc(raw).toLocal();
    } catch (_) {
      try {
        return _dateFormat.parse(raw);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
  }
}
