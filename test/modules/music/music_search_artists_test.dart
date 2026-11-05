import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/modules/music/controllers/music_search_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

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
  bool failArtists = false;

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
    if (failArtists && queryParameters?['music_type'] == 'artist') {
      request.result.completeError(StateError('boom'));
      return await request.result.future as Response<T>;
    }
    return await request.result.future as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Version implements ServerApiVersionService {
  @override
  Future<bool> isV3() async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Map<String, dynamic>> _pageOf(String prefix, int count) => [
  for (var i = 0; i < count; i++)
    {'music_type': 'album', 'media_id': '$prefix-$i', 'title': '$prefix $i'},
];

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('首页合并艺人并置顶，翻页不再检索艺人', () async {
    final api = _Api();
    final c = MusicSearchController(apiClient: api, versionService: _Version());
    final first = c.search(keywordOverride: '周杰伦');
    await _tick();
    expect(api.gets, hasLength(2));
    expect(api.gets[0].query?['type'], 'music');
    expect(api.gets[0].query?.containsKey('music_type'), isFalse);
    expect(api.gets[1].query, {
      'title': '周杰伦',
      'type': 'music',
      'music_type': 'artist',
      'page': 1,
      'count': 10,
    });
    api.gets[0].complete(_pageOf('main', 30));
    api.gets[1].complete([
      {
        'music_type': 'artist',
        'media_source': 'musicbrainz',
        'media_id': 'artist-1',
        'title': '周杰伦',
      },
    ]);
    await first;
    expect(c.items.first.musicType, 'artist');
    expect(c.items.first.mediaId, 'artist-1');
    expect(c.items.where((e) => e.isArtist), hasLength(1));
    expect(c.errorText.value, isNull);
    expect(c.hasMore.value, isTrue);

    final second = c.loadMore();
    await _tick();
    expect(api.gets.length, 3);
    expect(api.gets.last.query?['page'], 2);
    expect(api.gets.last.query?.containsKey('music_type'), isFalse);
    api.gets.last.complete(_pageOf('main', 2));
    await second;
    expect(c.items.where((e) => e.isArtist), hasLength(1));
    expect(c.hasMore.value, isFalse);
  });

  test('艺人检索失败不打断主搜索，hasMore 以主查询为准', () async {
    final api = _Api()..failArtists = true;
    final c = MusicSearchController(apiClient: api, versionService: _Version());
    final searching = c.search(keywordOverride: '晴天');
    await _tick();
    api.gets[0].complete(_pageOf('main', 30));
    await searching;
    expect(c.errorText.value, isNull);
    expect(c.items, isNotEmpty);
    expect(c.items.any((e) => e.isArtist), isFalse);
    expect(c.hasMore.value, isTrue);
  });

  test('主查询为空但命中艺人时不显示无结果', () async {
    final api = _Api();
    final c = MusicSearchController(apiClient: api, versionService: _Version());
    final searching = c.search(keywordOverride: ' Coldplay ');
    await _tick();
    api.gets[0].complete(<dynamic>[]);
    api.gets[1].complete([
      {
        'music_type': 'artist',
        'media_source': 'musicbrainz',
        'media_id': 'artist-2',
        'title': 'Coldplay',
      },
    ]);
    await searching;
    expect(c.items.single.mediaId, 'artist-2');
    expect(c.errorText.value, isNull);
    expect(c.hasMore.value, isFalse);
  });

  test('重复搜索会把新一轮艺人再次置顶且不与旧结果混淆', () async {
    final api = _Api();
    final c = MusicSearchController(apiClient: api, versionService: _Version());
    final first = c.search(keywordOverride: '周杰伦');
    await _tick();
    api.gets[0].complete(_pageOf('a', 1));
    api.gets[1].complete([
      {
        'music_type': 'artist',
        'media_source': 'musicbrainz',
        'media_id': 'artist-1',
      },
    ]);
    await first;
    final second = c.search(keywordOverride: '晴天');
    await _tick();
    api.gets[2].complete(_pageOf('b', 1));
    api.gets[3].complete(<dynamic>[]);
    await second;
    expect(c.items.map((e) => e.mediaId).toList(), ['b-0']);
    expect(c.keyword.value, '晴天');
  });
}
