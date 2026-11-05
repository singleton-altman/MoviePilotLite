import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

class _Call {
  _Call(this.path, {this.query, this.data});
  final String path;
  final Map<String, dynamic>? query;
  final Map<String, dynamic>? data;
  final response = Completer<Response<dynamic>>();

  void complete(dynamic body, {int status = 200}) => response.complete(
    Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      statusCode: status,
      data: body,
    ),
  );
}

class _Api implements ApiClient {
  final gets = <_Call>[];
  final posts = <_Call>[];
  final deletes = <_Call>[];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
    bool skipV3EnvelopeUnwrap = false,
  }) async {
    final call = _Call(path, query: queryParameters);
    gets.add(call);
    return await call.response.future as Response<T>;
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
  }) async {
    final call = _Call(path, query: queryParameters, data: data);
    posts.add(call);
    return await call.response.future as Response<T>;
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) async {
    final call = _Call(path, query: queryParameters);
    deletes.add(call);
    return await call.response.future as Response<T>;
  }

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

class _App implements AppService {
  _App({this.subscribe = true});
  final bool subscribe;
  @override
  bool get canSubscribe => subscribe;
  @override
  bool get canSearch => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Controller extends MusicRecordingController {
  _Controller({
    required _Api api,
    required _Version version,
    required _App app,
    super.mediaId = 'recording-id',
  }) : super(
         apiClient: api,
         versionService: version,
         appService: app,
       );

  @override
  void onReady() {}
}

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);

  test('recording detail parses v3 fields and formats track numbers', () {
    final detail = MusicRecordingDetail.fromJson({
      'music_type': ' recording ',
      'media_source': ' MusicBrainz ',
      'media_id': 1234,
      'title': ' 晴天 ',
      'artist': '周杰伦',
      'artists': ['周杰伦', null],
      'artist_ids': ['artist-1'],
      'album': '叶惠美',
      'album_id': 'album-9',
      'album_artist': '周杰伦',
      'album_type': 'Album',
      'year': '2003',
      'release_date': '2003-07-31',
      'track_number': '3',
      'disc_number': 2,
      'total_tracks': '11',
      'duration': '269',
      'isrc': 'TW-A65-03-00001',
      'cover_url': 'https://image.example/cover.jpg',
      'genres': ['Pop'],
      'listen_count': '1000',
    });
    expect(detail.musicType, 'recording');
    expect(detail.isAlbum, isFalse);
    expect(detail.mediaSource, 'musicbrainz');
    expect(detail.mediaId, '1234');
    expect(detail.displayTitle, '晴天');
    expect(detail.displayArtist, '周杰伦');
    expect(detail.albumId, 'album-9');
    expect(detail.trackNumber, 3);
    expect(detail.displayTrackNumber, '2-3');
    expect(detail.displayDuration, '4:29');
    expect(detail.listenCount, 1000);
    expect(detail.genres, ['Pop']);
  });

  test('recording detail tolerates missing and malformed fields', () {
    final detail = MusicRecordingDetail.fromJson({
      'track_number': 'x',
      'duration': -4,
      'artists': false,
      'genres': {},
    });
    expect(detail.mediaId, isEmpty);
    expect(detail.trackNumber, isNull);
    expect(detail.displayTrackNumber, isEmpty);
    expect(detail.displayDuration, isEmpty);
    expect(detail.artists, isEmpty);
    expect(detail.genres, isEmpty);
    expect(detail.displayTitle, '未知曲目');
  });

  test('load posts recognize then fills the album and subscribe status', () async {
    final api = _Api();
    final controller = _Controller(
      api: api,
      version: _Version(),
      app: _App(),
    );
    final loading = controller.load();
    await _tick();
    expect(api.posts, hasLength(1));
    expect(api.posts.single.path, '/api/v1/music/recognize');
    expect(api.posts.single.data, {
      'media_source': 'musicbrainz',
      'media_id': 'recording-id',
      'music_type': 'recording',
    });
    api.posts.single.complete({
      'media_source': 'musicbrainz',
      'media_id': 'recording-id',
      'title': '晴天',
      'album': '叶惠美',
      'album_id': 'album-9',
      'track_number': 3,
    });
    await _tick();
    expect(controller.recording.value?.displayTitle, '晴天');
    expect(api.gets.map((c) => c.path), [
      '/api/v1/music/album/album-9',
      '/api/v1/subscribe/media/recording-id',
    ]);
    expect(api.gets.first.query, {'media_source': 'musicbrainz'});
    expect(api.gets.last.query?['music_type'], 'recording');
    api.gets.first.complete({
      'media_source': 'musicbrainz',
      'media_id': 'album-9',
      'title': '叶惠美',
      'tracks': [
        {'media_id': 'recording-id', 'title': '晴天', 'track_number': 3},
        {'media_id': 'other', 'title': '以父之名', 'track_number': 2},
      ],
    });
    api.gets.last.complete({'success': true, 'data': <String, dynamic>{}});
    await loading;
    expect(controller.album.value?.tracks, hasLength(2));
    expect(controller.album.value?.tracks.first.mediaId, 'recording-id');
    expect(controller.isSubscribed.value, isFalse);
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorText.value, isNull);
  });

  test('album entity redirects to the album route instead of rendering', () async {
    final api = _Api();
    final controller = _Controller(
      api: api,
      version: _Version(),
      app: _App(),
    );
    final loading = controller.load();
    await _tick();
    api.posts.single.complete({
      'music_source': 'musicbrainz',
      'media_source': 'musicbrainz',
      'media_id': 'album-9',
      'music_type': 'album',
      'title': '叶惠美',
    });
    await loading;
    expect(controller.recording.value, isNull);
    expect(controller.errorText.value, isNull);
    expect(api.gets, isEmpty);
  });

  test('non v3 servers surface the version gate without requests', () async {
    final api = _Api();
    final controller = _Controller(
      api: api,
      version: _Version(false),
      app: _App(),
    );
    await controller.load();
    expect(api.posts, isEmpty);
    expect(controller.errorText.value, contains('v3'));
  });

  test('toggle subscribes and unsubscribes a recording', () async {
    final api = _Api();
    final controller = _Controller(
      api: api,
      version: _Version(),
      app: _App(),
    );
    controller.recording.value = const MusicRecordingDetail(
      mediaSource: 'musicbrainz',
      mediaId: 'recording-id',
      title: '晴天',
      year: 2003,
    );
    controller.isSubscribed.value = false;

    final subscribing = controller.toggleSubscribe();
    await _tick();
    expect(api.posts.single.path, '/api/v1/subscribe/');
    expect(api.posts.single.data, {
      'type': '音乐',
      'name': '晴天',
      'year': '2003',
      'media_source': 'musicbrainz',
      'media_id': 'recording-id',
      'music_type': 'recording',
    });
    api.posts.single.complete({'success': true, 'data': {'id': 5}});
    expect(await subscribing, isNull);
    expect(controller.isSubscribed.value, isTrue);

    final unsubscribing = controller.toggleSubscribe();
    await _tick();
    expect(api.deletes.single.path, '/api/v1/subscribe/media/recording-id');
    expect(api.deletes.single.query, {
      'media_source': 'musicbrainz',
      'music_type': 'recording',
    });
    api.deletes.single.complete({'success': true});
    expect(await unsubscribing, isNull);
    expect(controller.isSubscribed.value, isFalse);
  });

  test('subscribe is blocked without permission or identity', () async {
    final api = _Api();
    final denied = _Controller(
      api: api,
      version: _Version(),
      app: _App(subscribe: false),
    );
    denied.recording.value = const MusicRecordingDetail(
      mediaSource: 'musicbrainz',
      mediaId: 'recording-id',
    );
    expect(await denied.toggleSubscribe(), contains('订阅权限'));

    final missing = _Controller(
      api: api,
      version: _Version(),
      app: _App(),
      mediaId: '',
    );
    missing.recording.value = const MusicRecordingDetail(
      mediaSource: 'musicbrainz',
      mediaId: '',
    );
    expect(await missing.toggleSubscribe(), contains('标识'));
    expect(api.posts, isEmpty);
    expect(api.deletes, isEmpty);
  });

  test('music site ids keep only active ids and degrade to null', () async {
    final api = _Api();
    final controller = _Controller(
      api: api,
      version: _Version(),
      app: _App(),
    );
    final ids = controller.musicSiteIds();
    await _tick();
    expect(api.gets.single.path, '/api/v1/site/media/music');
    api.gets.single.complete([
      {'id': 1, 'is_active': true},
      {'id': '2', 'is_active': true},
      {'id': 3, 'is_active': false},
      'bad',
    ]);
    expect(await ids, {1, 2});

    final failing = _Controller(
      api: api,
      version: _Version(),
      app: _App(),
    );
    final unavailable = failing.musicSiteIds();
    await _tick();
    api.gets.last.complete(<String, dynamic>{}, status: 404);
    expect(await unavailable, isNull);
  });
}
