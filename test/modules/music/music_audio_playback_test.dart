import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanplayer_player/lanplayer_player.dart' as kit;
import 'package:moviepilot_mobile/modules/mediaserver/models/mediaserver_model.dart';
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/player/controllers/player_launch_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

class _Api implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Version implements ServerApiVersionService {
  _Version([this.v3 = true]);
  final bool v3;
  @override
  Future<bool> isV3() async => v3;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VideoService implements kit.MediaServerService {
  @override
  Future<List<kit.MediaItem>> search(String query) =>
      throw StateError('Video search must never be called');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AudioService extends _VideoService implements kit.AudioSearchCapability {
  _AudioService(this.results, {this.error, this.pending});
  final List<kit.MediaItem> results;
  final Object? error;
  final Completer<List<kit.MediaItem>>? pending;
  int queries = 0;
  String? requestedAlbum;
  String? requestedArtist;
  @override
  bool get supportsAudioSearch => true;
  @override
  Future<List<kit.MediaItem>> searchAudio(
    String album, {
    String? artist,
  }) async {
    queries++;
    requestedAlbum = album;
    requestedArtist = artist;
    if (error != null) throw error!;
    return pending != null ? pending!.future : results;
  }
}

class _Launch implements PlayerLaunchController {
  _Launch(this.services);
  final Map<String, kit.MediaServerService> services;
  final conversionErrors = <String>{};
  bool permitted = true;
  int serverLoads = 0;
  List<kit.MediaItem>? played;
  String? playedId;
  String? playedServer;
  bool? autoNext;
  @override
  bool get canNativePlay => permitted;
  @override
  Future<List<MediaServer>> enabledServers({bool force = false}) async {
    serverLoads++;
    return services.keys
        .map((name) => MediaServer(name: name, enabled: true))
        .toList();
  }

  @override
  Future<kit.MediaServer?> toKitServer(
    MediaServer server, {
    bool isDefault = false,
  }) async {
    if (conversionErrors.contains(server.name))
      throw StateError('Address resolution failed');
    return kit.MediaServer(
      id: server.name,
      name: server.name,
      url: 'https://server.example',
      type: kit.ServerType.emby,
    );
  }

  @override
  kit.MediaServerService? serviceFor(kit.MediaServer server) =>
      services[server.name];
  @override
  void startPlayback({
    required String itemId,
    String? serverName,
    String? serverType,
    bool fromStart = false,
    bool autoNextEpisode = true,
    String title = '正在准备播放',
    String? subtitle,
    kit.MediaServerService? service,
    kit.MediaServer? server,
    List<kit.MediaItem>? episodes,
  }) {
    playedId = itemId;
    playedServer = server?.name;
    played = episodes;
    autoNext = autoNextEpisode;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _album = MusicAlbumDetail(
  mediaSource: 'musicbrainz',
  mediaId: 'album-id',
  title: ' Album ',
  artists: ['Artist'],
);
kit.MediaItem _track(
  String id, {
  String album = 'Album',
  String artist = 'Artist',
  int disc = 1,
  int number = 1,
  kit.MediaType type = kit.MediaType.audio,
  List<Map<String, dynamic>>? videoTracks,
}) => kit.MediaItem(
  id: id,
  title: 'Track $number',
  posterUrl: '',
  type: type,
  album: album,
  albumArtist: artist,
  trackNumber: number,
  discNumber: disc,
  videoTracks: videoTracks,
);
MusicAlbumController _controller(_Launch launch, {bool v3 = true}) {
  final controller = MusicAlbumController(
    apiClient: _Api(),
    versionService: _Version(v3),
    playerLaunch: launch,
  );
  controller.album.value = _album;
  return controller;
}

void main() {
  test(
    'safe playlist excludes fuzzy/wrong artist/video/empty IDs, deduplicates and sorts',
    () {
      final tracks = musicAlbumPlaylist(_album, [
        _track('disc2', disc: 2),
        _track('second', number: 2),
        _track('wrong-album', album: 'Album Deluxe'),
        _track('wrong-artist', artist: 'Other Artist'),
        _track('video', type: kit.MediaType.movie),
        _track(
          'video-stream',
          videoTracks: [
            {'codec': 'h264'},
          ],
        ),
        _track(''),
        _track('first', album: ' ALBUM ', artist: ' artist '),
        _track('first'),
      ]);
      expect(tracks.map((e) => e.id), ['first', 'second', 'disc2']);
      expect(
        musicAlbumPlaylist(
          const MusicAlbumDetail(
            mediaId: 'id',
            mediaSource: '',
            title: 'Album',
          ),
          tracks,
        ),
        isEmpty,
      );
    },
  );

  test(
    'explicit audio capability is required, never video search fallback',
    () async {
      final launch = _Launch({'unsupported': _VideoService()});
      final c = _controller(launch);
      expect(await c.playInLibrary(), contains('不支持音乐搜索播放'));
      expect(launch.played, isNull);
      expect(c.isOperating.value, isFalse);
    },
  );

  test(
    'address and search errors are isolated; later supported server supplies safe queue',
    () async {
      final broken = _AudioService([], error: StateError('network failure'));
      final good = _AudioService([
        _track('two', number: 2),
        _track('bad', album: 'other'),
        _track('one'),
      ]);
      final launch = _Launch({
        'address-error': _VideoService(),
        'query-error': broken,
        'good': good,
      });
      launch.conversionErrors.add('address-error');
      final c = _controller(launch);
      expect(await c.playInLibrary(), isNull);
      expect(launch.playedServer, 'good');
      expect(launch.playedId, 'one');
      expect(launch.played!.map((e) => e.id), ['one', 'two']);
      expect(launch.autoNext, isFalse);
      expect(good.requestedAlbum, 'Album');
      expect(good.requestedArtist, 'Artist');
      expect(broken.queries, 1);
    },
  );

  test('failed audio search is not reported as album absent', () async {
    final launch = _Launch({
      'error': _AudioService([], error: StateError('offline')),
    });
    final c = _controller(launch);
    expect(await c.playInLibrary(), contains('搜索失败'));
    expect(launch.played, isNull);
  });

  test(
    'confirmed empty search is distinct from unsupported or failed',
    () async {
      final c = _controller(_Launch({'empty': _AudioService([])}));
      expect(await c.playInLibrary(), contains('可能尚未入库'));
    },
  );

  test(
    'V2 and non-native accounts do not enumerate media-server credentials',
    () async {
      final launch = _Launch({
        'good': _AudioService([_track('one')]),
      });
      expect(
        await _controller(launch, v3: false).playInLibrary(),
        contains('v3'),
      );
      launch.permitted = false;
      expect(await _controller(launch).playInLibrary(), contains('当前账号'));
      expect(launch.serverLoads, 0);
    },
  );

  test(
    'inflight play cannot be duplicated or launch after controller closes',
    () async {
      final pending = Completer<List<kit.MediaItem>>();
      final launch = _Launch({'good': _AudioService([], pending: pending)});
      final c = _controller(launch);
      final result = c.playInLibrary();
      await Future<void>.delayed(Duration.zero);
      expect(c.isOperating.value, isTrue);
      expect(await c.playInLibrary(), contains('操作进行中'));
      c.onClose();
      pending.complete([_track('one')]);
      expect(await result, isNotNull);
      expect(launch.played, isNull);
      expect(c.isOperating.value, isFalse);
    },
  );
}
