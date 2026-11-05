import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_models.dart';
import '../services/media_server_service.dart';
import '../database/media_library_repository.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';
import '../utils/app_log.dart';
import '../utils/validated_image_store.dart';

enum DataSource { none, cache, network }

class MediaLibraryState {
  final List<MediaItem> libraries;
  final Map<String, List<MediaItem>> libraryItems;
  final List<MediaItem> carouselItems;
  final bool isLoading;
  final bool hasLoaded;
  final DateTime? lastRefreshTime;
  final String? errorMessage;
  final DataSource dataSource;
  final bool isRefreshing;

  MediaLibraryState({
    this.libraries = const [],
    this.libraryItems = const {},
    this.carouselItems = const [],
    this.isLoading = false,
    this.hasLoaded = false,
    this.lastRefreshTime,
    this.errorMessage,
    this.dataSource = DataSource.none,
    this.isRefreshing = false,
  });

  MediaLibraryState copyWith({
    List<MediaItem>? libraries,
    Map<String, List<MediaItem>>? libraryItems,
    List<MediaItem>? carouselItems,
    bool? isLoading,
    bool? hasLoaded,
    DateTime? lastRefreshTime,
    String? errorMessage,
    DataSource? dataSource,
    bool? isRefreshing,
  }) {
    return MediaLibraryState(
      libraries: libraries ?? this.libraries,
      libraryItems: libraryItems ?? this.libraryItems,
      carouselItems: carouselItems ?? this.carouselItems,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
      errorMessage: errorMessage,
      dataSource: dataSource ?? this.dataSource,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

const _kCacheTTL = Duration(minutes: 30);

class MediaLibraryNotifier extends StateNotifier<MediaLibraryState> {
  final Ref ref;
  MediaServerService? _service;
  String? _currentServerId;

  MediaLibraryNotifier(this.ref) : super(MediaLibraryState()) {
    // hashCode+堆栈诊断:真机日志显示冷启动时 Notifier 创建了两次
    // (2026-09-06,不同 hashCode 排除日志重发),定位创建源头后收敛为单例
    final stack = StackTrace.current
        .toString()
        .split('\n')
        .take(7)
        .join(' | ');
    AppLog.i('MediaLibrary', 'Notifier created (#$hashCode) <- $stack');
    ref.listen(currentMediaServerServiceProvider, (previous, next) {
      AppLog.i('MediaLibrary', 'Service changed: prev=${previous != null ? "yes" : "no"}, next=${next != null ? "yes" : "no"}');
      _handleServiceChange(next);
    });
    Future.microtask(() {
      _service = ref.read(currentMediaServerServiceProvider);
      final servers = ref.read(mediaServersProvider);
      _currentServerId = servers.where((s) => s.isDefault).firstOrNull?.id ?? servers.firstOrNull?.id;
      AppLog.i('MediaLibrary', 'Initial service: ${_service != null ? _service!.baseUrl : "null"}');
      if (_service != null && !state.hasLoaded && !state.isLoading) {
        loadAll();
      }
    });
  }

  void _handleServiceChange(MediaServerService? next) {
    final servers = ref.read(mediaServersProvider);
    final defaultServer = servers.where((s) => s.isDefault).firstOrNull ?? servers.firstOrNull;
    final newServerId = defaultServer?.id;

    AppLog.i('MediaLibrary', 'handleServiceChange: serverCount=${servers.length}, defaultId=$newServerId, currentId=$_currentServerId');

    if (_currentServerId == null && next != null) {
      _service = next;
      _currentServerId = newServerId;
      if (!state.hasLoaded && !state.isLoading) {
        loadAll();
      }
      return;
    }

    _service = next;
    if (newServerId != _currentServerId && newServerId != null) {
      _currentServerId = newServerId;
      state = MediaLibraryState();
      if (_service != null) {
        AppLog.i('MediaLibrary', 'Server changed: ${_service!.baseUrl}, starting loadAll');
        loadAll();
      }
    } else if (newServerId == _currentServerId) {
      AppLog.i('MediaLibrary', 'handleServiceChange: same server, skipping reload. service=${next != null ? next.baseUrl : "null"}');
    } else {
      AppLog.i('MediaLibrary', 'Service is null, not loading');
    }
  }

  /// 缓存数据格式版本：结构变化（新增字段）时 +1，旧缓存强制失效触发一次网络刷新。
  /// 按服务器分别记录，避免一台服务器刷新后另一台的旧缓存被误判为已是最新格式。
  static const int _cacheFormatVersion = 2;
  static String _cacheFormatKey(String serverId) => 'media_cache_format_$serverId';

  /// 是否运行在 TV 环境：main.dart 检测 Leanback 后注入。
  /// TV 没有下拉刷新手势，用「冷启动首刷一次」补数据新鲜度；
  /// 手机端保持 TTL(30min) + 下拉刷新。
  static bool runsOnTv = false;

  /// 本次进程是否已做过冷启动强刷：只生效一次，运行期内不再绕过 TTL
  /// （避免每次进首页都全量拉取）。走到网络刷新分支才清标记，
  /// 跳过刷新的调用不影响它。
  static bool _coldRefreshPending = true;

  Future<void> loadAll({bool forceRefresh = false}) async {
    final service = _service;
    final serverId = _currentServerId;
    if (service == null || serverId == null) return;

    final cacheLoaded = await _loadFromDb(serverId);
    final hasCache = cacheLoaded && state.libraries.isNotEmpty;
    final cacheFresh = _isCacheFresh();
    // v2：media_items 缓存新增 isBoxSet、media_libraries 新增 collectionType，
    // 旧缓存缺字段，即使未过期也强制刷新一次
    final cacheFormatValid = (StorageService.getInt(_cacheFormatKey(serverId)) ?? 0) >= _cacheFormatVersion;
    // TV 冷启动首刷:缓存先显示(isRefreshing 态,数据保留),后台绕过 TTL
    // 拉一次全量,保证"每天第一次打开就是新的"
    final bypassTtl = forceRefresh || (runsOnTv && _coldRefreshPending);

    if (!hasCache) {
      state = state.copyWith(isLoading: true);
    } else if (bypassTtl || !cacheFormatValid) {
      state = state.copyWith(isRefreshing: true);
    }

    if (hasCache && cacheFresh && !bypassTtl && cacheFormatValid) {
      AppLog.i('MediaLibrary', 'Cache is fresh, skipping network refresh');
      state = state.copyWith(isLoading: false);
      return;
    }
    _coldRefreshPending = false;
    if (!cacheFormatValid) {
      AppLog.i('MediaLibrary', 'Cache format outdated (stored < $_cacheFormatVersion), forcing refresh');
    }

    try {
      AppLog.i('MediaLibrary', 'Ensuring authentication for ${service.baseUrl}...');
      final authed = await service.ensureAuthenticated();
      if (!authed) {
        AppLog.e('MediaLibrary', 'Authentication failed for ${service.baseUrl}');
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: hasCache ? '认证失败，显示缓存数据' : '认证失败，请检查用户名和密码',
        );
        return;
      }
      AppLog.i('MediaLibrary', 'Authentication OK, loading libraries...');
      final libraries = await service.getLibraries();
      state = state.copyWith(libraries: libraries);

      AppLog.i('MediaLibrary', 'Loading ${libraries.length} library items...');
      final itemsMap = <String, List<MediaItem>>{};
      await Future.wait(libraries.map((lib) async {
        try {
          // 分页拉全量（单页默认 50 条，大库只取第一页会"少"）；
          // boxsets 库需显式带上 BoxSet 类型（Jellyfin 用 Movie,Series 查合集返回 0）
          final items = await service.getAllLibraryItems(
            lib.id,
            includeBoxSets: lib.collectionType == 'boxsets',
          );
          itemsMap[lib.id] = items;
          AppLog.i('MediaLibrary', 'Library ${lib.title}: ${items.length} items');
        } catch (e) {
          AppLog.w('MediaLibrary', 'Failed to load ${lib.title}: $e');
          itemsMap[lib.id] = state.libraryItems[lib.id] ?? [];
        }
      }));
      state = state.copyWith(libraryItems: itemsMap);

      final allItems = itemsMap.values.expand((x) => x).toList();
      final allWithBackdrop = allItems.where((i) => i.backdropUrl?.isNotEmpty == true).toList()..shuffle();
      final carousel = allWithBackdrop.take(6).toList();
      final now = DateTime.now();
      final carouselItems = carousel.isEmpty
          ? (() {
              final withPosters = allItems.where((i) => i.posterUrl.isNotEmpty).toList()..shuffle();
              return withPosters.take(6).toList();
            })()
          : carousel;

      // 为缺少 backdrop 的 carousel 条目从 detail API 补全宽幅背景图（FnOS list 不带 backdrop）
      final enrichedCarousel = await Future.wait(carouselItems.map((item) async {
        if (item.backdropUrl != null && item.backdropUrl!.isNotEmpty) return item;
        try {
          final detail = await service.getItemDetails(item.id);
          if (detail.backdropUrl != null && detail.backdropUrl!.isNotEmpty) {
            return item.copyWith(backdropUrl: detail.backdropUrl);
          }
        } catch (_) {}
        return item;
      }));

      state = state.copyWith(
        carouselItems: enrichedCarousel,
        hasLoaded: true,
        isLoading: false,
        isRefreshing: false,
        lastRefreshTime: now,
        errorMessage: null,
        dataSource: DataSource.network,
      );

      AppLog.i('MediaLibrary', 'Load complete: ${libraries.length} libraries, ${allItems.length} items');

      _saveToDbBackground(serverId, libraries, itemsMap, enrichedCarousel, now);
      // 刷新成功且数据带最新缓存格式，记录版本号（下次启动不再强制刷新）
      StorageService.setInt(_cacheFormatKey(serverId), _cacheFormatVersion);

      _preloadAllImages(libraries, itemsMap, state.carouselItems, service);
    } catch (e) {
      AppLog.e('MediaLibrary', 'Load failed', e);
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: hasCache ? '刷新失败，显示缓存数据' : e.toString(),
      );
    }
  }

  /// 联动首页/列表卡片右上角已观看绿勾（详情页标记/取消已观看后调用）
  void markWatchedLocal(String itemId, {bool watched = true}) {
    final itemsMap = state.libraryItems.map((libId, items) => MapEntry(
          libId,
          items.map((i) => i.id == itemId ? i.copyWith(isWatched: watched) : i).toList(),
        ));
    state = state.copyWith(libraryItems: itemsMap);
    AppLog.i('MediaLibrary', 'markWatchedLocal: $itemId watched=$watched');
  }

  bool _isCacheFresh() {
    final lastRefresh = state.lastRefreshTime;
    if (lastRefresh == null) return false;
    final age = DateTime.now().difference(lastRefresh);
    return age < _kCacheTTL;
  }

  Future<bool> _loadFromDb(String serverId) async {
    try {
      final hasCache = await MediaLibraryRepository.hasCache(serverId);
      if (!hasCache) {
        AppLog.i('MediaLibrary', 'No DB cache for server $serverId');
        return false;
      }

      final libraries = await MediaLibraryRepository.getLibraries(serverId);
      final libraryItems = await MediaLibraryRepository.getLibraryItems(serverId);
      final carouselItems = await MediaLibraryRepository.getCarouselItems(serverId);
      final lastRefreshTime = await MediaLibraryRepository.getLastRefreshTime(serverId);

      if (libraries.isEmpty) {
        AppLog.i('MediaLibrary', 'DB cache empty for server $serverId');
        return false;
      }

      state = state.copyWith(
        libraries: libraries,
        libraryItems: libraryItems,
        carouselItems: carouselItems,
        hasLoaded: true,
        lastRefreshTime: lastRefreshTime,
        dataSource: DataSource.cache,
      );

      final totalItems = libraryItems.values.fold<int>(0, (s, l) => s + l.length);
      final fresh = _isCacheFresh();
      AppLog.i('MediaLibrary',
          'DB cache loaded: ${libraries.length} libraries, $totalItems items, last refresh: $lastRefreshTime, fresh=$fresh');
      return true;
    } catch (e) {
      AppLog.w('MediaLibrary', 'Load from DB failed: $e');
      return false;
    }
  }

  bool _isSavingCache = false;
  void _saveToDbBackground(
    String serverId,
    List<MediaItem> libraries,
    Map<String, List<MediaItem>> libraryItems,
    List<MediaItem> carouselItems,
    DateTime lastRefreshTime,
  ) {
    if (_isSavingCache) return;
    _isSavingCache = true;

    Future.microtask(() async {
      try {
        await MediaLibraryRepository.upsertAll(
          serverId: serverId,
          libraries: libraries,
          libraryItems: libraryItems,
          carouselItems: carouselItems,
          lastRefreshTime: lastRefreshTime,
        );
        AppLog.i('MediaLibrary', 'DB cache upserted for server $serverId');
      } catch (e) {
        AppLog.w('MediaLibrary', 'Save to DB failed: $e');
      } finally {
        _isSavingCache = false;
      }
    });
  }

  void _preloadAllImages(
    List<MediaItem> libraries,
    Map<String, List<MediaItem>> itemsMap,
    List<MediaItem> carousel,
    MediaServerService service,
  ) {
    final urls = <String>{};
    final headers = service.imageHeaders;
    final headerMap = headers.isEmpty ? null : headers;

    for (final lib in libraries) {
      if (lib.posterUrl.isNotEmpty) urls.add(lib.posterUrl);
    }

    for (final item in carousel) {
      final backdrop = item.backdropUrl;
      if (backdrop != null && backdrop.isNotEmpty) urls.add(backdrop);
      if (item.posterUrl.isNotEmpty) urls.add(item.posterUrl);
    }

    // TV 上预加载图片全部按原始分辨率解码进图片缓存(单张 4-8MB),
    // 46 张 = 数百 MB 常驻,是输入法被系统杀死的内存压力源之一。
    // TV 只保留 12 张(轮播+首屏),手机内存大维持原量。
    final perLibrary = runsOnTv ? 4 : 8;

    for (final items in itemsMap.values) {
      for (var i = 0; i < items.length && i < perLibrary; i++) {
        if (items[i].posterUrl.isNotEmpty) urls.add(items[i].posterUrl);
      }
    }

    if (urls.isEmpty) return;

    final urlList = urls.toList();
    AppLog.i('MediaLibrary', 'Preloading ${urlList.length} images (TV scope)...');

    Future.microtask(() => _preloadImagesConcurrently(urlList, headerMap));
  }

  Future<void> _preloadImagesConcurrently(
    List<String> urls,
    Map<String, String>? headers,
  ) async {
    const maxConcurrent = 2;
    var completedCount = 0;
    final queue = List<String>.from(urls);
    var activeCount = 0;

    final completer = Completer<void>();

    void preloadNext() {
      while (queue.isNotEmpty && activeCount < maxConcurrent) {
        final url = queue.removeLast();
        activeCount++;

        void done() {
          completedCount++;
          activeCount--;
          if (completedCount % 20 == 0) {
            AppLog.i('MediaLibrary', 'Preload progress: $completedCount/${urls.length}');
          }
          if (queue.isEmpty && activeCount == 0) {
            AppLog.i('MediaLibrary', 'Preload complete: $completedCount images');
            if (!completer.isCompleted) completer.complete();
          } else {
            preloadNext();
          }
        }

        // 两端统一:只下载+验魔数暖磁盘缓存(ServerImage 读的就是它),
        // 不走解码 —— 两台真机的平台解码器都解不了飞牛 webp
        // (MIUI 'unimplemented'/TV 同类失败,2026-09-06 实证),且解码
        // 产物进的全局 imageCache 对 ServerImage 的 RawImage 直渲染无效。
        loadValidatedImageFile(url, headers: headers)
            .then((_) => done())
            .catchError((_) => done());
      }
    }

    preloadNext();

    await completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        AppLog.w('MediaLibrary', 'Preload timeout at $completedCount/${urls.length}');
      },
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await loadAll();
  }

  MediaItem? getItemById(String id) {
    for (final items in state.libraryItems.values) {
      for (final item in items) {
        if (item.id == id) return item;
      }
    }
    for (final lib in state.libraries) {
      if (lib.id == id) return lib;
    }
    return null;
  }

  MediaItem? getItemByTitle(String title) {
    final lowerTitle = title.trim().toLowerCase();
    for (final items in state.libraryItems.values) {
      for (final item in items) {
        if (item.title.trim().toLowerCase() == lowerTitle) return item;
      }
    }
    return null;
  }

  List<MediaItem> getItemsForLibrary(String libraryId) {
    return state.libraryItems[libraryId] ?? [];
  }
}

final mediaLibraryProvider = StateNotifierProvider<MediaLibraryNotifier, MediaLibraryState>((ref) {
  return MediaLibraryNotifier(ref);
});
