import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Request {
  _Request(this.path, this.query);
  final String path;
  final Map<String, dynamic>? query;
  final result = Completer<Response<dynamic>>();
  void complete(dynamic data, {int status = 200}) => result.complete(
    Response(
      requestOptions: RequestOptions(path: path),
      statusCode: status,
      data: data,
    ),
  );
}

class _Api implements ApiClient {
  final gets = <_Request>[];
  final posts = <Map<String, dynamic>?>[];
  dynamic postData = {'success': true};
  int postStatus = 200;
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
    final request = _Request(path, queryParameters);
    gets.add(request);
    return await request.result.future as Response<T>;
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
    posts.add(data);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: postStatus,
      data: postData as T,
    );
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
  _App([this.allowed = false]);
  final bool allowed;
  @override
  bool get canSubscribe => allowed;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _tick() => Future<void>.delayed(Duration.zero);
List<Map<String, dynamic>> _page(String prefix, [int count = 30]) =>
    List.generate(
      count,
      (i) => {
        'music_type': 'album',
        'media_id': '$prefix-$i',
        'title': '$prefix $i',
      },
    );

MusicExploreItem _genreItem(
  String id,
  List<String> genres, {
  String type = 'album',
}) => MusicExploreItem(
  musicType: type,
  mediaSource: 'musicbrainz',
  mediaId: id,
  title: id,
  genres: genres,
);

void main() {
  test('available genres trim blanks and deduplicate case in source order', () {
    final api = _Api();
    final c = MusicLibraryController(
      apiClient: api,
      versionService: _Version(),
    );
    expect(c.selectedGenre.value, isNull);
    expect(c.availableGenres, isEmpty);
    c.items.addAll([
      _genreItem('first', [' ', ' Rock ', 'rock', 'Jazz', '']),
      _genreItem('second', ['ROCK', ' jazz ', 'Electronic']),
      _genreItem('artist', [' electronic ', ' Ambient '], type: 'artist'),
      _genreItem('untagged', []),
    ]);
    expect(c.availableGenres, ['Rock', 'Jazz', 'Electronic', 'Ambient']);
    expect(api.gets, isEmpty);
    expect(api.posts, isEmpty);
  });

  test(
    'real genre filtering preserves order and sections without requests',
    () async {
      final api = _Api();
      final c = MusicLibraryController(
        apiClient: api,
        versionService: _Version(),
      );
      final load = c.reload();
      await _tick();
      api.gets.single.complete([
        {
          'music_type': 'album',
          'media_id': 'z',
          'genres': [' Rock '],
        },
        {
          'music_type': 'album',
          'media_id': 'a',
          'genres': ['Jazz'],
        },
        {
          'music_type': 'artist',
          'media_id': 'artist',
          'genres': ['rOcK'],
        },
        {
          'music_type': 'album',
          'media_id': 'm',
          'genres': ['rock', 'Jazz'],
        },
        {'music_type': 'album', 'media_id': 'untagged'},
      ]);
      await load;
      final original = c.items.toList();
      final albums = [original[0], original[1], original[3], original[4]];
      expect(c.availableGenres, ['Rock', 'Jazz']);
      expect(c.visibleItems, orderedEquals(original));

      c.selectGenre('Rock');
      expect(c.selectedGenre.value, 'Rock');
      expect(
        c.visibleItems,
        orderedEquals([original[0], original[2], original[3]]),
      );
      c.selectGenre('不存在的风格');
      expect(c.selectedGenre.value, 'Rock');
      c.selectGenre('Jazz');
      expect(c.visibleItems, orderedEquals([original[1], original[3]]));
      expect(c.items, orderedEquals(original));
      expect(c.featuredAlbums, orderedEquals(albums));
      expect(c.discoveryAlbums, orderedEquals(albums));
      c.selectGenre(null);
      expect(c.selectedGenre.value, isNull);
      expect(c.visibleItems, orderedEquals(original));
      expect(api.gets, hasLength(1));
      expect(api.gets.single.path, '/api/v1/music/explore');
      expect(api.gets.single.query, {
        'page': 1,
        'count': 30,
        'media_source': 'musicbrainz',
        'entity': 'album',
      });
      expect(api.posts, isEmpty);
    },
  );

  test(
    'album sections exclude artists and keep the first six and nine albums',
    () {
      final api = _Api();
      final c = MusicLibraryController(
        apiClient: api,
        versionService: _Version(),
      );
      final albums = List.generate(
        12,
        (index) => _genreItem('album-${12 - index}', ['Rock']),
      );
      c.items.add(_genreItem('leading-artist', ['Jazz'], type: 'artist'));
      for (final album in albums) {
        c.items.addAll([
          album,
          _genreItem('artist-${album.mediaId}', [], type: 'artist'),
        ]);
      }
      c.selectGenre('Jazz');
      expect(c.featuredAlbums, orderedEquals(albums.take(6)));
      expect(c.discoveryAlbums, orderedEquals(albums.take(9)));
      expect(c.featuredAlbums.every((item) => item.isAlbum), isTrue);
      expect(c.discoveryAlbums.every((item) => item.isAlbum), isTrue);
      expect(api.gets, isEmpty);
    },
  );

  for (final count in [0, 1, 2, 5]) {
    test('sections do not invent albums when only $count are available', () {
      final c = MusicLibraryController(
        apiClient: _Api(),
        versionService: _Version(),
      );
      final albums = List.generate(count, (i) => _genreItem('album-$i', []));
      c.items.addAll([_genreItem('artist', [], type: 'artist'), ...albums]);
      expect(c.featuredAlbums, orderedEquals(albums));
      expect(c.discoveryAlbums, orderedEquals(albums));
    });
  }

  test(
    'source changes and refresh reset genre without changing explore contract',
    () async {
      final api = _Api();
      final c = MusicLibraryController(
        apiClient: api,
        versionService: _Version(),
      );
      final initial = c.reload();
      await _tick();
      api.gets.single.complete([
        {
          'music_type': 'album',
          'media_id': 'first',
          'genres': ['Rock'],
        },
      ]);
      await initial;
      c.selectGenre('Rock');
      await c.selectSource('musicbrainz');
      await c.selectSource('theaudiodb');
      expect(c.selectedGenre.value, 'Rock');
      expect(api.gets, hasLength(1));

      final changed = c.selectSource('doubanmusic');
      expect(c.selectedGenre.value, isNull);
      expect(c.items, isEmpty);
      await _tick();
      expect(api.gets, hasLength(2));
      api.gets.last.complete([
        {
          'music_type': 'album',
          'media_id': 'second',
          'genres': ['Jazz'],
        },
      ]);
      await changed;
      expect(c.availableGenres, ['Jazz']);
      c.selectGenre('Jazz');
      final refreshed = c.reload();
      expect(c.selectedGenre.value, isNull);
      expect(c.availableGenres, isEmpty);
      await _tick();
      expect(api.gets, hasLength(3));
      api.gets.last.complete([
        {
          'music_type': 'album',
          'media_id': 'fresh',
          'genres': ['Ambient'],
        },
      ]);
      await refreshed;
      expect(c.selectedGenre.value, isNull);
      expect(c.visibleItems.single.mediaId, 'fresh');
      expect(c.availableGenres, ['Ambient']);
      for (var index = 0; index < api.gets.length; index++) {
        expect(api.gets[index].path, '/api/v1/music/explore');
        expect(api.gets[index].query, {
          'page': 1,
          'count': 30,
          'media_source': index == 0 ? 'musicbrainz' : 'doubanmusic',
          'entity': 'album',
        });
      }
      expect(api.posts, isEmpty);
    },
  );

  test(
    'bootstrap restores the locally recorded source for first load',
    () async {
      SharedPreferences.setMockInitialValues({
        'music_explore_last_source': 'doubanmusic',
      });
      final api = _Api();
      final c = MusicLibraryController(
        apiClient: api,
        versionService: _Version(),
      );
      final boot = c.bootstrap();
      await _tick();
      api.gets.single.complete([
        {'music_type': 'album', 'media_id': 'restored'},
      ]);
      await boot;
      expect(c.selectedSource.value, 'doubanmusic');
      expect(api.gets.single.query, {
        'page': 1,
        'count': 30,
        'media_source': 'doubanmusic',
        'entity': 'album',
      });
    },
  );

  test(
    'stored source outside explore list keeps the default selection',
    () async {
      SharedPreferences.setMockInitialValues({
        'music_explore_last_source': 'theaudiodb',
      });
      final api = _Api();
      final c = MusicLibraryController(
        apiClient: api,
        versionService: _Version(),
      );
      final boot = c.bootstrap();
      await _tick();
      api.gets.single.complete([
        {'music_type': 'album', 'media_id': 'default'},
      ]);
      await boot;
      expect(c.selectedSource.value, 'musicbrainz');
      expect(api.gets.single.query, {
        'page': 1,
        'count': 30,
        'media_source': 'musicbrainz',
        'entity': 'album',
      });
    },
  );

  test('switching sources records the choice locally', () async {
    SharedPreferences.setMockInitialValues(const {});
    final api = _Api();
    final c = MusicLibraryController(
      apiClient: api,
      versionService: _Version(),
    );
    final initial = c.reload();
    await _tick();
    api.gets.single.complete([
      {'music_type': 'album', 'media_id': 'one'},
    ]);
    await initial;
    final switched = c.selectSource('doubanmusic');
    await _tick();
    api.gets.last.complete([
      {'music_type': 'album', 'media_id': 'two'},
    ]);
    await switched;
    await pumpEventQueue();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('music_explore_last_source'), 'doubanmusic');
    expect(api.gets.last.query, {
      'page': 1,
      'count': 30,
      'media_source': 'doubanmusic',
      'entity': 'album',
    });
  });

  test(
    'album subscription preserves music identity and rejects ambiguous success',
    () async {
      final api = _Api();
      final c = MusicAlbumController(
        apiClient: api,
        versionService: _Version(),
        appService: _App(true),
        mediaId: 'route-id',
        mediaSource: 'doubanmusic',
      );
      c.album.value = MusicAlbumDetail.fromJson({
        'title': 'Album',
        'year': '2026',
      });
      expect(await c.subscribeAlbum(), isNull);
      expect(api.posts.single, {
        'type': '音乐',
        'name': 'Album',
        'year': '2026',
        'media_id': 'route-id',
        'media_source': 'doubanmusic',
        'music_type': 'album',
      });
      api.postData = {'success': false, 'message': 'denied'};
      expect(await c.subscribeAlbum(), 'denied');
      api.postData = {};
      expect(await c.subscribeAlbum(), isNotNull);
      api.postStatus = 403;
      expect(await c.subscribeAlbum(), contains('403'));
      expect(c.isOperating.value, isFalse);
    },
  );

  test(
    'V2 cannot submit music subscription even with subscribe permission',
    () async {
      final api = _Api();
      final c = MusicAlbumController(
        apiClient: api,
        versionService: _Version(false),
        appService: _App(true),
      );
      c.album.value = const MusicAlbumDetail(
        mediaSource: 'musicbrainz',
        mediaId: 'album',
      );
      expect(await c.subscribeAlbum(), contains('v3'));
      expect(api.posts, isEmpty);
    },
  );

  test('explore requests albums and drops stale source replies', () async {
    final api = _Api();
    final c = MusicLibraryController(
      apiClient: api,
      versionService: _Version(),
    );
    final initial = c.reload();
    await _tick();
    expect(api.gets.single.query?['entity'], 'album');
    final changed = c.selectSource('doubanmusic');
    await _tick();
    expect(api.gets.length, 2);
    api.gets.last.complete({'success': true, 'data': _page('new', 1)});
    await changed;
    api.gets.first.complete(_page('old'));
    await initial;
    expect(c.items.single.mediaId, 'new-0');
    expect(c.items.single.mediaSource, 'doubanmusic');
    expect(c.isLoading.value, isFalse);
    expect(c.hasMore.value, isFalse);
    await c.selectSource('theaudiodb');
    expect(api.gets.length, 2);
  });

  test(
    'pagination uses raw count, deduplicates, and retries same failed page',
    () async {
      final api = _Api();
      final c = MusicLibraryController(
        apiClient: api,
        versionService: _Version(),
      );
      final first = c.reload();
      await _tick();
      final raw = _page('first');
      raw[0] = {'music_type': 'recording', 'media_id': 'song'};
      raw[1]['genres'] = ['Rock'];
      raw[2]['music_type'] = 'artist';
      api.gets.last.complete(raw);
      await first;
      expect(c.items.length, 29);
      expect(c.hasMore.value, isTrue);
      c.selectGenre('Rock');
      final original = c.items.toList();
      final featured = c.featuredAlbums;
      final discovery = c.discoveryAlbums;
      final failed = c.loadMore();
      await _tick();
      api.gets.last.complete({'success': false, 'message': 'failed'});
      await failed;
      expect(c.errorText.value, contains('failed'));
      expect(c.items, orderedEquals(original));
      expect(c.featuredAlbums, orderedEquals(featured));
      expect(c.discoveryAlbums, orderedEquals(discovery));
      expect(c.visibleItems, orderedEquals([original.first]));
      expect(c.selectedGenre.value, 'Rock');
      expect(c.hasMore.value, isTrue);
      expect(c.isLoading.value, isFalse);
      final retry = c.loadMore();
      await _tick();
      expect(api.gets.last.query?['page'], 2);
      final last = _page('last', 1).single..['genres'] = [' rock '];
      api.gets.last.complete([raw[1], last]);
      await retry;
      expect(c.items.length, 30);
      expect(c.items.take(original.length), orderedEquals(original));
      expect(c.visibleItems.map((item) => item.mediaId), ['first-1', 'last-0']);
      expect(c.featuredAlbums, orderedEquals(featured));
      expect(c.discoveryAlbums, orderedEquals(discovery));
      expect(c.selectedGenre.value, 'Rock');
      expect(c.hasMore.value, isFalse);
      expect(c.errorText.value, isNull);
      expect(api.gets, hasLength(3));
      for (final request in api.gets.skip(1)) {
        expect(request.path, '/api/v1/music/explore');
        expect(request.query, {
          'page': 2,
          'count': 30,
          'media_source': 'musicbrainz',
          'entity': 'album',
        });
      }
      expect(api.posts, isEmpty);
    },
  );

  test(
    'artist loading covers both requests and blocks concurrent pagination',
    () async {
      final api = _Api();
      final c = MusicArtistController(
        apiClient: api,
        versionService: _Version(),
        mediaId: 'artist',
      );
      final load = c.reload();
      await _tick();
      expect(c.isLoading.value, isTrue);
      await c.loadMore();
      expect(api.gets.length, 2);
      api.gets.first.complete({'media_id': 'artist', 'name': 'Artist'});
      await _tick();
      expect(c.isLoading.value, isTrue);
      api.gets.last.complete(_page('album'));
      await load;
      expect(c.isLoading.value, isFalse);
      final more = c.loadMore();
      await _tick();
      await c.loadMore();
      expect(api.gets.length, 3);
      expect(c.isLoadingMore.value, isTrue);
      api.gets.last.complete(_page('second', 1));
      await more;
      expect(c.albums.length, 31);
      expect(c.isLoadingMore.value, isFalse);
    },
  );

  test('artist refresh invalidates pending page and detail replies', () async {
    final api = _Api();
    final c = MusicArtistController(
      apiClient: api,
      versionService: _Version(),
      mediaId: 'artist',
    );
    final first = c.reload();
    await _tick();
    final reset = c.reload();
    await _tick();
    api.gets[2].complete({'name': 'new artist'});
    api.gets[3].complete(_page('new', 1));
    await reset;
    api.gets[0].complete({'name': 'old artist'});
    api.gets[1].complete(_page('old'));
    await first;
    expect(c.artist.value?.name, 'new artist');
    expect(c.albums.single.mediaId, 'new-0');
    expect(c.hasMore.value, isFalse);
  });

  test(
    'artist pagination failure is visible and retries without advancing page',
    () async {
      final api = _Api();
      final c = MusicArtistController(
        apiClient: api,
        versionService: _Version(),
        mediaId: 'artist',
      );
      final load = c.reload();
      await _tick();
      api.gets.first.complete({}, status: 500);
      api.gets.last.complete(_page('first'));
      await load;
      expect(c.artistError.value, contains('500'));
      final more = c.loadMore();
      await _tick();
      api.gets.last.complete({}, status: 503);
      await more;
      expect(c.errorText.value, contains('503'));
      final retry = c.loadMore();
      await _tick();
      expect(api.gets.last.query?['page'], 2);
      api.gets.last.complete([]);
      await retry;
      expect(c.errorText.value, isNull);
    },
  );

  test('V2 blocks direct library, artist, album requests', () async {
    final api = _Api();
    final version = _Version(false);
    final library = MusicLibraryController(
      apiClient: api,
      versionService: version,
    );
    final artist = MusicArtistController(
      apiClient: api,
      versionService: version,
      mediaId: 'a',
    );
    final album = MusicAlbumController(
      apiClient: api,
      versionService: version,
      mediaId: 'b',
    );
    await Future.wait([library.reload(), artist.reload(), album.load()]);
    expect(api.gets, isEmpty);
    expect(library.supported.value, isFalse);
    expect(artist.errorText.value, contains('v3'));
    expect(album.errorText.value, contains('v3'));
  });

  test(
    'controller itself denies unauthorized subscribe, not just the button',
    () async {
      final api = _Api();
      final c = MusicAlbumController(
        apiClient: api,
        versionService: _Version(),
        appService: _App(),
      );
      c.album.value = const MusicAlbumDetail(
        mediaSource: 'musicbrainz',
        mediaId: 'album',
      );
      await c.subscribeAlbum();
      expect(api.posts, isEmpty);
      expect(c.isOperating.value, isFalse);
    },
  );

  test(
    'album refresh ignores stale details and close ignores inflight response',
    () async {
      final api = _Api();
      final c = MusicAlbumController(
        apiClient: api,
        versionService: _Version(),
        mediaId: 'album',
      );
      final old = c.load();
      await _tick();
      final fresh = c.load();
      await _tick();
      api.gets.last.complete({
        'success': true,
        'data': {'title': 'New'},
      });
      await fresh;
      api.gets.first.complete({'title': 'Old'});
      await old;
      expect(c.album.value?.title, 'New');
      final closing = c.load();
      await _tick();
      c.onClose();
      api.gets.last.complete({'title': 'Closed'});
      await closing;
      expect(c.album.value?.title, 'New');
    },
  );
}
