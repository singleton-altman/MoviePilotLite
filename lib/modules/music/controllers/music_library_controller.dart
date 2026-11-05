import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:lanplayer_player/lanplayer_player.dart' as kit;
import 'package:moviepilot_mobile/modules/player/controllers/player_launch_controller.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _checkResponse(Response<dynamic> response) {
  final status = response.statusCode ?? 0;
  if (status < 200 || status >= 300) {
    throw StateError('请求失败 (HTTP $status)');
  }
  final data = response.data;
  if (data is Map && data['success'] == false) {
    throw StateError(data['message']?.toString() ?? '请求失败');
  }
}

dynamic _payload(Response<dynamic> response) {
  _checkResponse(response);
  final data = response.data;
  return data is Map && data.containsKey('data') ? data['data'] : data;
}

List<dynamic> _list(Response<dynamic> response) {
  final data = _payload(response);
  if (data is! List) throw const FormatException('数据格式异常');
  return data;
}

Map<String, dynamic> _map(Response<dynamic> response) {
  final data = _payload(response);
  if (data is! Map) throw const FormatException('数据格式异常');
  return Map<String, dynamic>.from(data);
}

List<MusicExploreItem> _albums(List<dynamic> raw, String source) => raw
    .whereType<Map>()
    .map(
      (e) => MusicExploreItem.fromJson(
        Map<String, dynamic>.from(e),
        fallbackSource: source,
      ),
    )
    .where((e) => e.mediaId.isNotEmpty && (e.isAlbum || e.isArtist))
    .toList();

void _appendUnique(
  RxList<MusicExploreItem> target,
  List<MusicExploreItem> values,
) {
  final ids = target
      .map((e) => '${e.mediaSource}:${e.musicType}:${e.mediaId}')
      .toSet();
  target.addAll(
    values.where(
      (e) => ids.add('${e.mediaSource}:${e.musicType}:${e.mediaId}'),
    ),
  );
}

String _error(Object error) => error is StateError
    ? error.message.toString()
    : error is FormatException
    ? '数据格式异常'
    : '请求失败，请稍后重试';

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String _musicName(String? value) =>
    (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Defense in depth: never play fuzzy title matches, video files, empty IDs or
/// another album's tracks even if a server adapter returns an unexpected result.
List<kit.MediaItem> musicAlbumPlaylist(
  MusicAlbumDetail album,
  Iterable<kit.MediaItem> results,
) {
  final title = _musicName(album.title);
  final artists = [
    ...album.artists,
    if (album.artist != null) album.artist!,
  ].map(_musicName).where((e) => e.isNotEmpty).toSet();
  if (title.isEmpty || artists.isEmpty) return [];
  final ids = <String>{};
  final tracks = results.where((item) {
    final credited = [
      ...item.artists,
      if (item.albumArtist != null) item.albumArtist!,
    ].map(_musicName);
    return item.type == kit.MediaType.audio &&
        item.id.trim().isNotEmpty &&
        item.videoTracks?.isNotEmpty != true &&
        _musicName(item.album) == title &&
        credited.any(artists.contains) &&
        ids.add(item.id);
  }).toList();
  tracks.sort((a, b) {
    final disc = (a.discNumber ?? 1).compareTo(b.discNumber ?? 1);
    if (disc != 0) return disc;
    final track = (a.trackNumber ?? 1 << 30).compareTo(
      b.trackNumber ?? 1 << 30,
    );
    return track != 0 ? track : a.id.compareTo(b.id);
  });
  return tracks;
}

/// Music endpoints exist only on V3; all entry points, including deep links, gate requests.
abstract class _MusicController extends GetxController {
  _MusicController({
    ApiClient? apiClient,
    ServerApiVersionService? versionService,
  }) : api = apiClient ?? Get.find<ApiClient>(),
       version = versionService ?? Get.find<ServerApiVersionService>();

  final ApiClient api;
  final ServerApiVersionService version;
  final errorText = RxnString();
  int generation = 0;
  bool current(int request) => !isClosed && request == generation;

  Future<bool> checkSupport(int request) async {
    final supported = await version.isV3();
    if (!current(request)) return false;
    if (!supported) errorText.value = '音乐功能需要 MoviePilot v3 服务端';
    return supported;
  }

  void report(Object e, StackTrace st) {
    if (Get.isRegistered<AppLog>()) {
      Get.find<AppLog>().handle(e, stackTrace: st, message: '音乐请求失败');
    }
  }

  @override
  void onClose() {
    generation++;
    super.onClose();
  }
}

class MusicLibraryController extends _MusicController {
  MusicLibraryController({super.apiClient, super.versionService});
  static const int _pageSize = 30;
  static const String _persistedSourceKey = 'music_explore_last_source';
  final items = <MusicExploreItem>[].obs;
  final isLoading = false.obs;
  final hasMore = true.obs;
  final selectedSource = 'musicbrainz'.obs;
  final supported = Rxn<bool>();
  final selectedGenre = RxnString();
  int _page = 1;

  List<MusicExploreItem> get featuredAlbums =>
      items.where((item) => item.isAlbum).take(6).toList();

  List<MusicExploreItem> get discoveryAlbums =>
      items.where((item) => item.isAlbum).take(9).toList();

  List<String> get availableGenres {
    final genres = <String, String>{};
    for (final item in items) {
      for (final value in item.genres) {
        final genre = value.trim();
        if (genre.isNotEmpty) {
          genres.putIfAbsent(genre.toLowerCase(), () => genre);
        }
      }
    }
    return genres.values.toList();
  }

  List<MusicExploreItem> get visibleItems {
    final selected = selectedGenre.value;
    if (selected == null) return items.toList();
    return items
        .where(
          (item) => item.genres.any(
            (genre) => genre.trim().toLowerCase() == selected.toLowerCase(),
          ),
        )
        .toList();
  }

  void selectGenre(String? genre) {
    if (genre == null || availableGenres.contains(genre)) {
      selectedGenre.value = genre;
    }
  }

  @override
  void onReady() {
    super.onReady();
    bootstrap();
  }

  /// 恢复本地记录的来源后再发起首次加载，保证首页请求使用用户偏好来源。
  Future<void> bootstrap() async {
    await _restorePersistedSource();
    if (isClosed) return;
    await reload();
  }

  Future<void> _restorePersistedSource() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_persistedSourceKey) ?? '';
      if (stored.isEmpty ||
          stored == selectedSource.value ||
          !kMusicExploreSources.any((e) => e.id == stored)) {
        return;
      }
      selectedSource.value = stored;
    } catch (e, st) {
      report(e, st);
    }
  }

  Future<void> _persistSource(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_persistedSourceKey, id);
    } catch (e, st) {
      report(e, st);
    }
  }

  Future<void> selectSource(String id) async {
    if (selectedSource.value == id ||
        !kMusicExploreSources.any((e) => e.id == id)) {
      return;
    }
    selectedSource.value = id;
    selectedGenre.value = null;
    // 本地记录并发写入，失败不打断切换；reload 保持同步清空旧内容的时序。
    unawaited(_persistSource(id));
    await reload();
  }

  Future<void> reload() async {
    final request = ++generation;
    _page = 1;
    hasMore.value = true;
    selectedGenre.value = null;
    items.clear();
    errorText.value = null;
    isLoading.value = true;
    try {
      final available = await checkSupport(request);
      if (!current(request)) return;
      supported.value = available;
      if (available) await _loadPage(request);
    } catch (e, st) {
      if (current(request)) errorText.value = _error(e);
      report(e, st);
    } finally {
      if (current(request)) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isClosed ||
        isLoading.value ||
        !hasMore.value ||
        supported.value != true) {
      return;
    }
    final request = generation;
    isLoading.value = true;
    try {
      await _loadPage(request);
    } catch (e, st) {
      if (current(request)) errorText.value = _error(e);
      report(e, st);
    } finally {
      if (current(request)) isLoading.value = false;
    }
  }

  Future<void> _loadPage(int request) async {
    final page = _page;
    final source = selectedSource.value;
    errorText.value = null;
    final raw = _list(
      await api.get<dynamic>(
        '/api/v1/music/explore',
        queryParameters: {
          'page': page,
          'count': _pageSize,
          'media_source': source,
          'entity': 'album',
        },
        skipV3EnvelopeUnwrap: true,
      ),
    );
    if (!current(request)) return;
    _appendUnique(items, _albums(raw, source));
    hasMore.value = raw.length >= _pageSize;
    _page = page + 1;
  }
}

class MusicArtistController extends _MusicController {
  MusicArtistController({
    super.apiClient,
    super.versionService,
    this.mediaId = '',
    this.mediaSource = 'musicbrainz',
  });
  static const int _pageSize = 30;
  String mediaId;
  String mediaSource;
  String artistName = '';
  final artist = Rxn<MusicArtistDetail>();
  final albums = <MusicExploreItem>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final artistError = RxnString();
  final hasMore = true.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      mediaId = args['mediaId']?.toString().trim() ?? mediaId;
      mediaSource = musicSource(args['mediaSource'], fallback: mediaSource);
      artistName = args['name']?.toString() ?? '';
    }
  }

  @override
  void onReady() {
    super.onReady();
    reload();
  }

  Future<void> reload() async {
    final request = ++generation;
    _page = 1;
    hasMore.value = true;
    albums.clear();
    artist.value = null;
    errorText.value = null;
    artistError.value = null;
    isLoading.value = true;
    isLoadingMore.value = false;
    try {
      if (mediaId.isEmpty) throw StateError('缺少艺术家标识');
      if (!await checkSupport(request)) return;
      await Future.wait([_loadArtist(request), _loadAlbums(request)]);
    } catch (e, st) {
      if (current(request)) errorText.value = _error(e);
      report(e, st);
    } finally {
      if (current(request)) isLoading.value = false;
    }
  }

  Future<void> _loadArtist(int request) async {
    try {
      final data = _map(
        await api.get<dynamic>(
          '/api/v1/music/artist/${Uri.encodeComponent(mediaId)}',
          queryParameters: {'media_source': mediaSource},
          skipV3EnvelopeUnwrap: true,
        ),
      );
      if (current(request)) artist.value = MusicArtistDetail.fromJson(data);
    } catch (e, st) {
      if (current(request)) artistError.value = _error(e);
      report(e, st);
    }
  }

  Future<void> _loadAlbums(int request) async {
    final page = _page;
    errorText.value = null;
    final raw = _list(
      await api.get<dynamic>(
        '/api/v1/music/artist/${Uri.encodeComponent(mediaId)}/albums',
        queryParameters: {
          'page': page,
          'count': _pageSize,
          'media_source': mediaSource,
        },
        skipV3EnvelopeUnwrap: true,
      ),
    );
    if (!current(request)) return;
    _appendUnique(
      albums,
      _albums(raw, mediaSource).where((e) => e.isAlbum).toList(),
    );
    hasMore.value = raw.length >= _pageSize;
    _page = page + 1;
  }

  Future<void> loadMore() async {
    if (isClosed || isLoading.value || isLoadingMore.value || !hasMore.value) {
      return;
    }
    final request = generation;
    isLoadingMore.value = true;
    try {
      if (await checkSupport(request)) await _loadAlbums(request);
    } catch (e, st) {
      if (current(request)) errorText.value = _error(e);
      report(e, st);
    } finally {
      if (current(request)) isLoadingMore.value = false;
    }
  }
}

class MusicAlbumController extends _MusicController {
  MusicAlbumController({
    super.apiClient,
    super.versionService,
    AppService? appService,
    PlayerLaunchController? playerLaunch,
    this.mediaId = '',
    this.mediaSource = 'musicbrainz',
  }) : _appService = appService,
       _playerLaunch = playerLaunch;
  final AppService? _appService;
  final PlayerLaunchController? _playerLaunch;
  PlayerLaunchController get _launch =>
      _playerLaunch ?? PlayerLaunchController.to;
  String mediaId;
  String mediaSource;
  String albumTitle = '';
  final album = Rxn<MusicAlbumDetail>();
  final isLoading = false.obs;
  final isOperating = false.obs;
  bool get canSubscribe => (_appService ?? Get.find<AppService>()).canSubscribe;

  // Native playback needs administrator-only media-server credentials. Actual audio
  // search support is checked separately for every configured adapter, never inferred
  // from video search results or file extensions.
  bool get canPlayInLibrary => _launch.canNativePlay;

  Future<String?> playInLibrary() async {
    final a = album.value;
    if (isOperating.value || isLoading.value) return '操作进行中，请稍后重试';
    if (a == null || isClosed) return '请先加载专辑详情';
    if (!canPlayInLibrary) return '当前账号不支持内嵌播放';
    final artistName =
        a.artists.where((name) => name.trim().isNotEmpty).firstOrNull ??
        a.artist?.trim();
    if (a.title?.trim().isNotEmpty != true ||
        artistName == null ||
        artistName.isEmpty) {
      return '缺少专辑名或艺术家信息，无法安全匹配媒体库';
    }
    final request = generation;
    isOperating.value = true;
    try {
      if (!await checkSupport(request)) return errorText.value ?? '当前服务器不支持音乐';
      final launch = _launch;
      final servers = await launch.enabledServers();
      if (!current(request)) return '专辑已更新，请重试';
      if (servers.isEmpty) return '请先配置并启用媒体服务器';
      var audioCapable = false;
      var failed = false;
      for (final server in servers) {
        try {
          final kitServer = await launch.toKitServer(
            server,
            isDefault: server == servers.first,
          );
          if (!current(request)) return '专辑已更新，请重试';
          if (kitServer == null) {
            failed = true;
            continue;
          }
          final service = launch.serviceFor(kitServer);
          if (service == null || !service.supportsAudioSearch) continue;
          audioCapable = true;
          final results = await service
              .searchAudio(a.displayTitle, artist: artistName)
              .timeout(const Duration(seconds: 15));
          if (!current(request)) return '专辑已更新，请重试';
          final tracks = musicAlbumPlaylist(a, results);
          if (tracks.isEmpty) continue;
          launch.startPlayback(
            itemId: tracks.first.id,
            service: service,
            server: kitServer,
            episodes: tracks,
            autoNextEpisode: false,
            title: a.displayTitle,
            subtitle: a.displayArtist,
          );
          return null;
        } catch (e, st) {
          failed = true;
          report(e, st);
        }
      }
      if (failed) return '部分媒体服务器搜索失败，未找到可播放曲目，请稍后重试';
      if (!audioCapable) return '已配置的媒体服务器暂不支持音乐搜索播放';
      return '未在媒体服务器中找到匹配的专辑音频，可能尚未入库';
    } catch (e, st) {
      report(e, st);
      return '音乐搜索失败，请稍后重试';
    } finally {
      isOperating.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      mediaId = args['mediaId']?.toString().trim() ?? mediaId;
      mediaSource = musicSource(args['mediaSource'], fallback: mediaSource);
      albumTitle = args['title']?.toString() ?? '';
    }
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    final request = ++generation;
    isLoading.value = true;
    errorText.value = null;
    try {
      if (mediaId.isEmpty) throw StateError('缺少专辑标识');
      if (!await checkSupport(request)) return;
      final data = _map(
        await api.get<dynamic>(
          '/api/v1/music/album/${Uri.encodeComponent(mediaId)}',
          queryParameters: {'media_source': mediaSource},
          skipV3EnvelopeUnwrap: true,
        ),
      );
      if (current(request)) album.value = MusicAlbumDetail.fromJson(data);
    } catch (e, st) {
      if (current(request)) errorText.value = _error(e);
      report(e, st);
    } finally {
      if (current(request)) isLoading.value = false;
    }
  }

  Future<String?> subscribeAlbum() async {
    final a = album.value;
    if (!canSubscribe) return '当前账号没有订阅权限';
    if (a == null || isClosed) return '请先加载专辑详情';
    if (isOperating.value || isLoading.value) return '操作进行中，请稍后重试';
    final request = generation;
    isOperating.value = true;
    try {
      if (!await checkSupport(request)) return errorText.value ?? '当前服务器不支持音乐';
      if (!canSubscribe) return '当前账号没有订阅权限';
      final id = a.mediaId.isNotEmpty ? a.mediaId : mediaId;
      final source = a.mediaSource.isNotEmpty ? a.mediaSource : mediaSource;
      if (id.isEmpty || !kMusicSources.any((e) => e.id == source)) {
        throw StateError('缺少有效的音乐来源或专辑标识');
      }
      final response = await api.post<dynamic>(
        '/api/v1/subscribe/',
        data: {
          'type': '音乐',
          'name': a.displayTitle,
          'year': a.year?.toString() ?? '',
          'media_source': source,
          'media_id': id,
          'music_type': 'album',
        },
      );
      _checkResponse(response);
      if (response.data is! Map || response.data['success'] != true) {
        throw const FormatException('订阅结果不明确');
      }
      return null;
    } catch (e, st) {
      report(e, st);
      return _error(e);
    } finally {
      isOperating.value = false;
    }
  }
}

/// 单曲详情：POST /api/v1/music/recognize 取实体，再按 album_id 补全所属专辑曲目。
/// 与 v3 MusicDetailView 对齐：识别为专辑时替换路由到专辑详情。
class MusicRecordingController extends _MusicController {
  MusicRecordingController({
    super.apiClient,
    super.versionService,
    AppService? appService,
    this.mediaId = '',
    this.mediaSource = 'musicbrainz',
  }) : _appService = appService;

  final AppService? _appService;
  AppService get _app => _appService ?? Get.find<AppService>();

  String mediaId;
  String mediaSource;
  String seedTitle = '';
  String seedArtist = '';

  final recording = Rxn<MusicRecordingDetail>();
  final album = Rxn<MusicAlbumDetail>();
  final isLoading = false.obs;
  final isOperating = false.obs;
  final isSubscribed = Rxn<bool>();

  /// recognize 返回专辑实体时记录目标专辑 ID，随后替换当前路由。
  final redirectAlbumId = RxnString();

  bool get canSubscribe => _app.canSubscribe;
  bool get canSearch => _app.canSearch;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      mediaId = args['mediaId']?.toString().trim() ?? mediaId;
      mediaSource = musicSource(args['mediaSource'], fallback: mediaSource);
      seedTitle = args['title']?.toString() ?? '';
      seedArtist = args['artist']?.toString() ?? '';
    }
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    final request = ++generation;
    isLoading.value = true;
    errorText.value = null;
    recording.value = null;
    album.value = null;
    isSubscribed.value = null;
    try {
      if (mediaId.isEmpty) throw StateError('缺少单曲标识');
      if (!await checkSupport(request)) return;
      final detail = MusicRecordingDetail.fromJson(
        _map(
          await api.post<dynamic>(
            '/api/v1/music/recognize',
            data: {
              'media_source': mediaSource,
              'media_id': mediaId,
              'music_type': 'recording',
            },
          ),
        ),
        fallbackSource: mediaSource,
      );
      if (!current(request)) return;
      if (detail.mediaId.isEmpty) throw const FormatException('数据格式异常');
      // 订阅或旧链接可能指向专辑实体，v3 同样把当前页替换为专辑详情。
      if (detail.isAlbum) {
        redirectAlbumId.value = detail.mediaId;
        if (!Get.testMode) {
          Get.offNamed(
            '/music/album',
            arguments: {
              'mediaId': detail.mediaId,
              'mediaSource': detail.mediaSource,
              'title': detail.displayTitle,
            },
          );
        }
        return;
      }
      recording.value = detail;
      await Future.wait([
        _loadAlbum(request, detail),
        _loadSubscribeStatus(request, detail),
      ]);
    } catch (e, st) {
      if (current(request)) errorText.value = _error(e);
      report(e, st);
    } finally {
      if (current(request)) isLoading.value = false;
    }
  }

  Future<void> _loadAlbum(int request, MusicRecordingDetail detail) async {
    final albumId = detail.albumId?.trim() ?? '';
    if (albumId.isEmpty) return;
    final source = detail.mediaSource.isNotEmpty
        ? detail.mediaSource
        : mediaSource;
    try {
      final data = _map(
        await api.get<dynamic>(
          '/api/v1/music/album/${Uri.encodeComponent(albumId)}',
          queryParameters: {'media_source': source},
          skipV3EnvelopeUnwrap: true,
        ),
      );
      if (current(request)) album.value = MusicAlbumDetail.fromJson(data);
    } catch (e, st) {
      // 专辑只是补充信息，失败不阻塞单曲本身。
      report(e, st);
    }
  }

  Future<void> _loadSubscribeStatus(
    int request,
    MusicRecordingDetail detail,
  ) async {
    if (!canSubscribe || detail.mediaId.isEmpty) return;
    final source = detail.mediaSource.isNotEmpty
        ? detail.mediaSource
        : mediaSource;
    try {
      final response = await api.get<dynamic>(
        '/api/v1/subscribe/media/${Uri.encodeComponent(detail.mediaId)}',
        queryParameters: {
          'media_source': source,
          'music_type': 'recording',
          if (detail.title?.trim().isNotEmpty == true) 'title': detail.title,
          'mtype': '音乐',
          if (detail.year != null) 'year': detail.year,
        },
      );
      if (!current(request)) return;
      final status = response.statusCode ?? 0;
      if (status == 404 || status == 204) {
        isSubscribed.value = false;
        return;
      }
      final data = response.data;
      isSubscribed.value =
          data is Map && (data['id'] ?? (data['data'] is Map ? (data['data'] as Map)['id'] : null)) != null;
    } catch (e, st) {
      report(e, st);
    }
  }

  /// 订阅 / 取消订阅单曲；返回 null 表示成功，否则为可展示的错误文案。
  Future<String?> toggleSubscribe() async {
    final d = recording.value;
    if (!canSubscribe) return '当前账号没有订阅权限';
    if (d == null) return '请先加载单曲详情';
    if (isOperating.value || isLoading.value) return '操作进行中，请稍后重试';
    if (d.isArtist) return '艺术家不支持订阅，请订阅其专辑或单曲';
    final id = d.mediaId.isNotEmpty ? d.mediaId : mediaId;
    final source = d.mediaSource.isNotEmpty ? d.mediaSource : mediaSource;
    if (id.isEmpty || !kMusicSources.any((e) => e.id == source)) {
      return '缺少有效的音乐来源或单曲标识';
    }
    final request = generation;
    final wasSubscribed = isSubscribed.value == true;
    isOperating.value = true;
    try {
      if (wasSubscribed) {
        final response = await api.delete<dynamic>(
          '/api/v1/subscribe/media/${Uri.encodeComponent(id)}',
          queryParameters: {'media_source': source, 'music_type': 'recording'},
        );
        _checkResponse(response);
        if (current(request)) isSubscribed.value = false;
      } else {
        final response = await api.post<dynamic>(
          '/api/v1/subscribe/',
          data: {
            'type': '音乐',
            'name': d.displayTitle,
            'year': d.year?.toString() ?? '',
            'media_source': source,
            'media_id': id,
            'music_type': 'recording',
          },
        );
        _checkResponse(response);
        if (response.data is! Map || response.data['success'] != true) {
          throw const FormatException('订阅结果不明确');
        }
        if (current(request)) isSubscribed.value = true;
      }
      return null;
    } catch (e, st) {
      report(e, st);
      return _error(e);
    } finally {
      isOperating.value = false;
    }
  }

  /// 已启用且声明支持音乐搜索的站点 ID；接口不可用时返回 null 表示不做限制。
  Future<Set<int>?> musicSiteIds() async {
    try {
      final response = await api.get<dynamic>(
        '/api/v1/site/media/music',
        skipV3EnvelopeUnwrap: true,
      );
      if ((response.statusCode ?? 0) >= 400) return null;
      final data = response.data;
      final raw = data is List ? data : (data is Map ? data['data'] : null);
      if (raw is! List) return null;
      return raw
          .whereType<Map>()
          .where((e) => e['is_active'] != false)
          .map((e) => _asInt(e['id']))
          .whereType<int>()
          .toSet();
    } catch (e, st) {
      report(e, st);
      return null;
    }
  }
}
