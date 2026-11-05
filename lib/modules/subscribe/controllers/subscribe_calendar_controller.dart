import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_calendar_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';

/// 订阅日历：基于用户 TV 订阅拉取各剧集播出信息，按日期时间轴展示
class SubscribeCalendarController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  final allItems = <CalendarEpisodeItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  /// 当前选中的剧集筛选：null = 全部，否则为 'tmdbId_season'
  final selectedShowKey = RxnString();

  /// 是否隐藏已过期剧集（选中 = 隐藏，反选 = 显示全部）
  final hideExpired = true.obs;

  void toggleHideExpired() {
    hideExpired.value = !hideExpired.value;
  }

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  @override
  void onReady() {
    super.onReady();
    load();
    if (Get.isRegistered<IosSharedSessionService>()) {
      Get.find<IosSharedSessionService>().reloadWidgets();
    }
  }

  static String get _todayUtc =>
      DateTime.now().toUtc().toIso8601String().substring(0, 10);

  List<CalendarEpisodeItem> get _itemsFilteredByExpired {
    final list = allItems.toList();
    if (!hideExpired.value) return list;
    final today = _todayUtc;
    return list.where((e) {
      if (e.airDate.isEmpty) return true;
      return e.airDate.compareTo(today) >= 0;
    }).toList();
  }

  /// 可选的剧集列表（用于筛选下拉）
  List<MapEntry<String, String>> get showOptions {
    final keys = <String>{};
    final names = <String, String>{};
    for (final item in _itemsFilteredByExpired) {
      final key = '${item.tmdbId}_${item.seasonNumber}';
      if (!keys.contains(key)) {
        keys.add(key);
        names[key] = item.showName;
      }
    }
    final list = names.entries.toList();
    list.sort((a, b) => (a.value).compareTo(b.value));
    return list;
  }

  /// 可见剧集：先按是否隐藏过期过滤，再按剧集筛选
  List<CalendarEpisodeItem> get visibleItems {
    var list = _itemsFilteredByExpired;
    final key = selectedShowKey.value;
    if (key != null && key.isNotEmpty) {
      list = list.where((e) => '${e.tmdbId}_${e.seasonNumber}' == key).toList();
    }
    list.sort((a, b) {
      final da = a.airDate;
      final db = b.airDate;
      if (da.isEmpty && db.isEmpty) return 0;
      if (da.isEmpty) return 1;
      if (db.isEmpty) return -1;
      return da.compareTo(db);
    });
    return list;
  }

  /// 按播出日期分组，用于时间轴同一天展示
  List<MapEntry<String, List<CalendarEpisodeItem>>>
  get visibleItemsGroupedByDate {
    final list = visibleItems;
    final map = <String, List<CalendarEpisodeItem>>{};
    for (final item in list) {
      final date = item.airDate.isEmpty ? '未定' : item.airDate;
      map.putIfAbsent(date, () => []).add(item);
    }
    final entries = map.entries.toList();
    entries.sort((a, b) {
      if (a.key == '未定') return 1;
      if (b.key == '未定') return -1;
      return a.key.compareTo(b.key);
    });
    return entries;
  }

  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    allItems.clear();
    selectedShowKey.value = null;
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        return;
      }
      final subscribes = await _fetchUserTvSubscribes(token);
      if (subscribes.isEmpty) {
        return;
      }
      for (final sub in subscribes) {
        final tmdbId = sub.tmdbid;
        final season = sub.season ?? 1;
        if (tmdbId == null || tmdbId <= 0) continue;
        try {
          final episodes = await _fetchTmdbEpisodes(token, tmdbId, season);
          final showName = sub.name ?? '剧集 $tmdbId';
          final showPoster = sub.poster;
          for (final ep in episodes) {
            allItems.add(
              CalendarEpisodeItem(
                episode: ep,
                showName: showName,
                showPoster: showPoster,
                tmdbId: tmdbId,
                seasonNumber: season,
              ),
            );
          }
        } catch (e, st) {
          _log.handle(
            e,
            stackTrace: st,
            message: '获取剧集日历失败 ${sub.name ?? tmdbId}',
          );
        }
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '订阅日历加载失败');
      errorText.value = '请求失败，请稍后重试';
    } finally {
      isLoading.value = false;
    }
  }

  void setShowFilter(String? key) {
    selectedShowKey.value = key;
  }

  Future<List<SubscribeItem>> _fetchUserTvSubscribes(String token) async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/subscribe/',
      token: token,
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception('订阅列表请求失败');
    }
    final list = _extractList(response.data);
    final parsed = <SubscribeItem>[];
    for (final raw in list) {
      if (raw is Map<String, dynamic>) {
        try {
          final item = SubscribeItem.fromJson(normalizeSubscribeJson(raw));
          final t = item.type?.trim().toLowerCase() ?? '';
          if (t.contains('电视剧') || t.contains('tv') || t == 'tv') {
            parsed.add(item);
          }
        } catch (_) {}
      }
    }
    return parsed;
  }

  Future<List<TmdbEpisode>> _fetchTmdbEpisodes(
    String token,
    int tmdbId,
    int season,
  ) async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/tmdb/$tmdbId/$season',
      token: token,
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      return [];
    }
    final list = _extractList(response.data);
    final parsed = <TmdbEpisode>[];
    for (final raw in list) {
      if (raw is Map<String, dynamic>) {
        try {
          parsed.add(TmdbEpisode.fromJson(raw));
        } catch (_) {}
      }
    }
    return parsed;
  }

  Iterable<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) return data;
    }
    return const [];
  }
}
