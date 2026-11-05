import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanplayer_player/host/player_host.dart';
import 'package:lanplayer_player/models/media_models.dart';
import 'package:lanplayer_player/services/media_server_service.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Map<String, dynamic> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(respond(options)), 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
  @override
  void close({bool force = false}) {}
}

class _VideoOnlyFake implements MediaServerService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _track(String id, int disc, int number,
    {String album = 'Album', String artist = 'Artist'}) => {
  'Id': id, 'Name': 'Track $id', 'Type': 'Audio', 'Album': album,
  'AlbumArtist': artist, 'Artists': ['Singer'],
  'ParentIndexNumber': disc, 'IndexNumber': number,
  'RunTimeTicks': 1200000000,
  'MediaSources': [
    {'Id': 'source-$id', 'Path': '/music/$id.flac', 'MediaStreams': [
      {'Type': 'Audio', 'Codec': 'flac'},
    ]},
  ],
};

void main() {
  for (final jellyfin in [false, true]) {
    group(jellyfin ? 'Jellyfin' : 'Emby', () {
      late _Adapter adapter;
      late EmbyService service;
      setUp(() {
        adapter = _Adapter((r) {
          if (r.path == '/Items') return {'Items': [], 'TotalRecordCount': 0};
          return {'Id': 'user'};
        });
        final dio = Dio(BaseOptions(baseUrl: 'https://media.example/base'))
          ..httpClientAdapter = adapter;
        service = jellyfin
            ? JellyfinService(baseUrl: dio.options.baseUrl, dioClient: dio,
                apiKey: 'token', userId: 'user')
            : EmbyService(baseUrl: dio.options.baseUrl, dioClient: dio,
                apiKey: 'token', userId: 'user');
      });

      test('audio is opt-in, exact album/artist, disc-track order', () async {
        final source = service.dio;
        adapter = _Adapter((r) {
          if (r.path == '/Items') return {'Items': [
            _track('disc2', 2, 1), _track('two', 1, 2), _track('one', 1, 1),
            _track('other-album', 1, 3, album: 'Album Live'),
            _track('other-artist', 1, 4, artist: 'Other'),
            {..._track('container', 1, 0), 'Type': 'MusicAlbum'},
            {..._track('movie', 1, 0), 'Type': 'Movie'},
            {..._track('', 1, 0)},
            {..._track('video', 1, 5), 'MediaSources': [],
              'MediaStreams': [{'Type': 'Video'}]},
          ], 'TotalRecordCount': 9};
          return {'Id': 'user'};
        });
        source.httpClientAdapter = adapter;
        MediaServerService abstractService = service;
        expect(abstractService.supportsAudioSearch, isTrue);
        final tracks = await abstractService.searchAudio(' Album ', artist: ' artist ');
        expect(tracks.map((t) => t.id), ['one', 'two', 'disc2']);
        expect(tracks.every((t) => t.type == MediaType.audio), isTrue);
        final request = adapter.requests.singleWhere((r) => r.path == '/Items');
        expect(request.method, 'GET');
        expect(request.queryParameters['IncludeItemTypes'], 'Audio');
        expect(request.queryParameters['Albums'], 'Album');
        expect(request.queryParameters.containsKey('SearchTerm'), isFalse);
        expect(request.headers['X-MediaBrowser-Token'], 'token');
        if (jellyfin) expect(request.headers['Authorization'], contains('Token="token"'));
      });

      test('all accepted album artist credits survive copy and JSON', () async {
        service.dio.httpClientAdapter = _Adapter((r) => r.path == '/Items'
            ? {'Items': [{..._track('one', 1, 1, artist: 'Lead'),
                'AlbumArtists': ['Co Artist'],
                'AlbumArtistItems': [{'Id': 'credit', 'Name': 'Guest Artist'}]}],
                'TotalRecordCount': 1}
            : {'Id': 'user'});
        final tracks = await service.searchAudio('Album', artist: 'Guest Artist');
        expect(tracks, hasLength(1));
        final track = tracks.single;
        final restored = MediaItem.fromJson(track.copyWith().toJson());
        expect(restored.artists, containsAll(['Singer', 'Lead', 'Co Artist', 'Guest Artist']));
        expect(restored.album, 'Album');
        expect(restored.albumArtist, 'Lead');
        expect(restored.discNumber, 1);
        expect(restored.trackNumber, 1);
        expect(restored.type, MediaType.audio);
      });

      test('paginates despite server page size cap and deduplicates IDs', () async {
        service.dio.httpClientAdapter = _Adapter((r) {
          if (r.path != '/Items') return {'Id': 'user'};
          final start = r.queryParameters['StartIndex'] as int;
          return {'Items': [if (start == 0) _track('one', 1, 1) else _track('two', 1, 2)],
            'TotalRecordCount': 2};
        });
        expect((await service.searchAudio('Album')).map((t) => t.id), ['one', 'two']);
      });

      test('ordinary search remains movie/series only', () async {
        service.dio.httpClientAdapter = _Adapter((r) => r.path == '/Items'
            ? {'Items': [_track('audio', 1, 1),
                {'Id': 'movie', 'Name': 'Movie', 'Type': 'Movie'}]}
            : {'Id': 'user'});
        expect((await service.search('Album')).map((t) => t.id), ['movie']);
      });

      test('track ID resolves to audio PlaybackInfo and audio stream, not Videos', () async {
        service.dio.httpClientAdapter = adapter = _Adapter((r) {
          if (r.path.endsWith('/PlaybackInfo')) return {
            'PlaySessionId': 'audio-session',
            'MediaSources': [{'Id': 'real-source', 'SupportsDirectPlay': true}],
          };
          if (r.path.endsWith('/Items/one')) return _track('one', 1, 1);
          if (r.path == '/Sessions/Playing') return {};
          return {'Id': 'user'};
        });
        final session = await PlaybackResolver.resolve(service: service,
          server: MediaServer(id: 's', name: 's', url: service.baseUrl,
            type: jellyfin ? ServerType.jellyfin : ServerType.emby), itemId: 'one');
        expect(session.media.type, MediaType.audio);
        final uri = Uri.parse(session.streamUrl);
        expect(uri.path, '/base/Audio/one/stream');
        expect(uri.queryParameters['Static'], 'true');
        expect(uri.queryParameters['MediaSourceId'], 'real-source');
        expect(uri.queryParameters['PlaySessionId'], 'audio-session');
        expect(session.httpHeaders!['X-MediaBrowser-Token'], 'token');
        final info = adapter.requests.singleWhere((r) => r.path.endsWith('/PlaybackInfo'));
        expect(info.method, 'POST');
        final profile = (info.data as Map)['DeviceProfile'] as Map;
        expect((profile['DirectPlayProfiles'] as List).single['Type'], 'Audio');
        await service.reportPlaybackStart('one');
        final report = adapter.requests.singleWhere((r) => r.path == '/Sessions/Playing');
        expect(report.data['ItemId'], 'one');
        expect(report.data['MediaSourceId'], 'real-source');
        expect(report.data['PlaySessionId'], 'audio-session');
      });

      test('audio transcode response is used without video fallback', () async {
        service.dio.httpClientAdapter = _Adapter((r) {
          if (r.path.endsWith('/PlaybackInfo')) return {'MediaSources': [{
            'Id': 'source', 'SupportsDirectPlay': false,
            'TranscodingUrl': '/Audio/one/stream.mp3?AudioCodec=mp3',
          }]};
          if (r.path.endsWith('/Items/one')) return _track('one', 1, 1);
          return {'Id': 'user'};
        });
        await service.getItemDetails('one');
        expect(await service.getStreamUrl('one'),
            'https://media.example/base/Audio/one/stream.mp3?AudioCodec=mp3');
      });
    });
  }

  test('existing video fake remains unsupported without added interface members', () {
    final service = _VideoOnlyFake();
    expect(service.supportsAudioSearch, isFalse);
    expect(() => service.searchAudio('Album'), throwsUnsupportedError);
  });

  test('FnOS never inherits unsupported Emby audio capability', () async {
    MediaServerService service = FnOSService(baseUrl: 'https://fnos.example',
      username: 'user', password: 'password');
    expect(service.supportsAudioSearch, isFalse);
    expect(() => service.searchAudio('Album'), throwsUnsupportedError);
  });
}
