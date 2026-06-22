import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/download/utils/search_result_raw_cache.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

enum SearchResultViewMode { list, grid }

enum SearchResultSortKey { defaultSort, site, size, seeders, pubdate }

enum SortDirection { asc, desc }

enum SearchResultFilterType {
  site,
  season,
  promotion,
  videoEncode,
  quality,
  resolution,
  team,
}

class SearchResultController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  final items = <SearchResultItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  final viewMode = SearchResultViewMode.list.obs;
  final sortKey = SearchResultSortKey.defaultSort.obs;
  final sortDirection = SortDirection.desc.obs;
  final keyword = ''.obs;

  final selectedSites = <String>{}.obs;
  final selectedSeasons = <String>{}.obs;
  final selectedPromotions = <String>{}.obs;
  final selectedVideoEncodes = <String>{}.obs;
  final selectedQualities = <String>{}.obs;
  final selectedResolutions = <String>{}.obs;
  final selectedTeams = <String>{}.obs;

  final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  onReady() {
    super.onReady();
    loadLatest();
  }

  Future<void> loadLatest() async {
    isLoading.value = true;
    errorText.value = null;
    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录后再查看搜索结果';
        return;
      }
      final response = await _apiClient.get<dynamic>(
        '/api/v1/search/last',
        token: token,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        return;
      }
      final raw = response.data;
      final list = _extractList(raw);
      items
        ..clear()
        ..addAll(
          list
              .whereType<Map<String, dynamic>>()
              .map(parseAndCacheSearchResultItem),
        );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取搜索结果失败');
      errorText.value = '请求失败，请稍后重试';
    } finally {
      isLoading.value = false;
    }
  }

  void updateKeyword(String value) {
    keyword.value = value.trim();
  }

  void toggleViewMode() {
    viewMode.value = viewMode.value == SearchResultViewMode.list
        ? SearchResultViewMode.grid
        : SearchResultViewMode.list;
  }

  void updateSortKey(SearchResultSortKey next) {
    sortKey.value = next;
  }

  void toggleSortDirection() {
    sortDirection.value = sortDirection.value == SortDirection.asc
        ? SortDirection.desc
        : SortDirection.asc;
  }

  void toggleFilter(SearchResultFilterType type, String value) {
    final target = _filterSet(type);
    final next = target.toSet();
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    _assignFilter(type, next);
  }

  void clearFilters() {
    selectedSites.value = <String>{};
    selectedSeasons.value = <String>{};
    selectedPromotions.value = <String>{};
    selectedVideoEncodes.value = <String>{};
    selectedQualities.value = <String>{};
    selectedResolutions.value = <String>{};
    selectedTeams.value = <String>{};
  }

  bool get hasActiveFilters =>
      selectedSites.value.isNotEmpty ||
      selectedSeasons.value.isNotEmpty ||
      selectedPromotions.value.isNotEmpty ||
      selectedVideoEncodes.value.isNotEmpty ||
      selectedQualities.value.isNotEmpty ||
      selectedResolutions.value.isNotEmpty ||
      selectedTeams.value.isNotEmpty;

  List<SearchResultItem> get visibleItems {
    final key = keyword.value.trim().toLowerCase();
    final sites = selectedSites.value.toSet();
    final seasons = selectedSeasons.value.toSet();
    final promotions = selectedPromotions.value.toSet();
    final encodes = selectedVideoEncodes.value.toSet();
    final qualities = selectedQualities.value.toSet();
    final resolutions = selectedResolutions.value.toSet();
    final teams = selectedTeams.value.toSet();

    var results = items.toList();
    if (key.isNotEmpty) {
      results = results.where((item) => _matchKeyword(item, key)).toList();
    }
    results = results.where((item) {
      if (sites.isNotEmpty && !sites.contains(_siteName(item))) {
        return false;
      }
      if (seasons.isNotEmpty) {
        final season = _seasonLabel(item);
        if (season == null || !seasons.contains(season)) return false;
      }
      if (promotions.isNotEmpty) {
        final promotion = _promotionLabel(item);
        if (promotion == null || !promotions.contains(promotion)) {
          return false;
        }
      }
      if (encodes.isNotEmpty) {
        final encode = item.meta_info?.video_encode ?? '';
        if (!encodes.contains(encode)) return false;
      }
      if (qualities.isNotEmpty) {
        final quality = _qualityLabel(item);
        if (quality == null || !qualities.contains(quality)) return false;
      }
      if (resolutions.isNotEmpty) {
        final resolution = item.meta_info?.resource_pix ?? '';
        if (!resolutions.contains(resolution)) return false;
      }
      if (teams.isNotEmpty) {
        final team = item.meta_info?.resource_team ?? '';
        if (!teams.contains(team)) return false;
      }
      return true;
    }).toList();

    return _sortResults(results);
  }

  List<String> get availableSites => _uniqueOptions(items.map(_siteName));
  List<String> get availableSeasons => _uniqueOptions(items.map(_seasonLabel));
  List<String> get availablePromotions =>
      _uniqueOptions(items.map(_promotionLabel));
  List<String> get availableVideoEncodes =>
      _uniqueOptions(items.map((e) => e.meta_info?.video_encode));
  List<String> get availableQualities =>
      _uniqueOptions(items.map(_qualityLabel));
  List<String> get availableResolutions =>
      _uniqueOptions(items.map((e) => e.meta_info?.resource_pix));
  List<String> get availableTeams =>
      _uniqueOptions(items.map((e) => e.meta_info?.resource_team));

  List<String> _uniqueOptions(Iterable<String?> values) {
    final set = <String>{};
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      set.add(trimmed);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<SearchResultItem> _sortResults(List<SearchResultItem> list) {
    final key = sortKey.value;
    if (key == SearchResultSortKey.defaultSort) {
      return list;
    }
    list.sort((a, b) {
      int result;
      switch (key) {
        case SearchResultSortKey.site:
          result = _siteName(a).compareTo(_siteName(b));
          break;
        case SearchResultSortKey.size:
          result = (_size(a)).compareTo(_size(b));
          break;
        case SearchResultSortKey.seeders:
          result = (_seeders(a)).compareTo(_seeders(b));
          break;
        case SearchResultSortKey.pubdate:
          result = (_pubdate(a)).compareTo(_pubdate(b));
          break;
        case SearchResultSortKey.defaultSort:
          result = 0;
          break;
      }
      return sortDirection.value == SortDirection.asc ? result : -result;
    });
    return list;
  }

  bool _matchKeyword(SearchResultItem item, String keywordLower) {
    final meta = item.meta_info;
    final torrent = item.torrent_info;
    final buffer = StringBuffer()
      ..write(meta?.title ?? '')
      ..write(' ')
      ..write(meta?.subtitle ?? '')
      ..write(' ')
      ..write(meta?.name ?? '')
      ..write(' ')
      ..write(meta?.cn_name ?? '')
      ..write(' ')
      ..write(meta?.en_name ?? '')
      ..write(' ')
      ..write(torrent?.title ?? '')
      ..write(' ')
      ..write(torrent?.description ?? '')
      ..write(' ')
      ..write(_siteName(item));
    final haystack = buffer.toString().toLowerCase();
    return haystack.contains(keywordLower);
  }

  String _siteName(SearchResultItem item) =>
      item.torrent_info?.site_name ?? '未知站点';

  String? _seasonLabel(SearchResultItem item) {
    final meta = item.meta_info;
    if (meta == null) return null;
    final seasonEpisode = meta.season_episode?.trim();
    if (seasonEpisode != null && seasonEpisode.isNotEmpty) {
      return seasonEpisode;
    }
    final season = meta.begin_season ?? meta.total_season;
    if (season != null && season > 0) {
      return 'S${season.toString().padLeft(2, '0')}';
    }
    return null;
  }

  String? _promotionLabel(SearchResultItem item) {
    final torrent = item.torrent_info;
    if (torrent == null) return null;
    final volume = torrent.volume_factor?.trim();
    final download = torrent.downloadvolumefactor;
    final freedate = torrent.freedate;
    if ((download != null && download == 0) ||
        (volume != null && volume.contains('免费')) ||
        (freedate != null && freedate.isNotEmpty)) {
      return '免费';
    }
    if (download != null && download < 1) {
      return '优惠';
    }
    if (volume != null && volume.isNotEmpty) return volume;
    return '普通';
  }

  String? _qualityLabel(SearchResultItem item) {
    final meta = item.meta_info;
    final quality = meta?.resource_type ?? meta?.edition;
    return quality?.trim().isEmpty ?? true ? null : quality;
  }

  int _seeders(SearchResultItem item) => item.torrent_info?.seeders ?? 0;

  double _size(SearchResultItem item) => item.torrent_info?.size ?? 0;

  DateTime _pubdate(SearchResultItem item) {
    final raw = item.torrent_info?.pubdate;
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

  Iterable<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) return data;
    }
    return const [];
  }

  Set<String> _filterSet(SearchResultFilterType type) {
    switch (type) {
      case SearchResultFilterType.site:
        return selectedSites.value.toSet();
      case SearchResultFilterType.season:
        return selectedSeasons.value.toSet();
      case SearchResultFilterType.promotion:
        return selectedPromotions.value.toSet();
      case SearchResultFilterType.videoEncode:
        return selectedVideoEncodes.value.toSet();
      case SearchResultFilterType.quality:
        return selectedQualities.value.toSet();
      case SearchResultFilterType.resolution:
        return selectedResolutions.value.toSet();
      case SearchResultFilterType.team:
        return selectedTeams.value.toSet();
    }
  }

  void _assignFilter(SearchResultFilterType type, Set<String> value) {
    switch (type) {
      case SearchResultFilterType.site:
        selectedSites.value = value;
        break;
      case SearchResultFilterType.season:
        selectedSeasons.value = value;
        break;
      case SearchResultFilterType.promotion:
        selectedPromotions.value = value;
        break;
      case SearchResultFilterType.videoEncode:
        selectedVideoEncodes.value = value;
        break;
      case SearchResultFilterType.quality:
        selectedQualities.value = value;
        break;
      case SearchResultFilterType.resolution:
        selectedResolutions.value = value;
        break;
      case SearchResultFilterType.team:
        selectedTeams.value = value;
        break;
    }
  }
}
