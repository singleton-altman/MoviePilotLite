import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/pages/music_album_page.dart';
import 'package:moviepilot_mobile/modules/music/pages/music_artist_page.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

class _Request {
  _Request(this.path, {this.query, this.data, this.skipEnvelope = false});

  final String path;
  final Map<String, dynamic>? query;
  final Map<String, dynamic>? data;
  final bool skipEnvelope;
  final result = Completer<Response<dynamic>>();

  void complete(dynamic data, {int status = 200}) {
    result.complete(
      Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: status,
        data: data,
      ),
    );
  }
}

// No Dio/HTTP client is constructed: all requests are completed in memory.
class _Api implements ApiClient {
  final gets = <_Request>[];
  final posts = <_Request>[];

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
    final request = _Request(
      path,
      query: queryParameters,
      skipEnvelope: skipV3EnvelopeUnwrap,
    );
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
    final request = _Request(path, query: queryParameters, data: data);
    posts.add(request);
    return await request.result.future as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Version implements ServerApiVersionService {
  int checks = 0;

  @override
  Future<bool> isV3() async {
    checks++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AlbumController extends MusicAlbumController {
  _AlbumController({
    required _Api api,
    required _Version version,
    this.playAllowed = true,
    this.subscribeAllowed = true,
  }) : super(apiClient: api, versionService: version, mediaId: 'album-id');

  final bool playAllowed;
  final bool subscribeAllowed;
  int playCalls = 0;

  // Suppress automatic requests only in this test subclass.
  @override
  void onReady() {}

  @override
  bool get canPlayInLibrary => playAllowed;

  @override
  bool get canSubscribe => subscribeAllowed;

  // Playback dispatch is a UI boundary; do not start a native player in a test.
  // Subscription, loading, and locking still use the real controller methods.
  @override
  Future<String?> playInLibrary() async {
    playCalls++;
    return null;
  }
}

class _ArtistController extends MusicArtistController {
  _ArtistController({required _Api api, required _Version version})
    : super(apiClient: api, versionService: version, mediaId: 'artist-id');

  @override
  void onReady() {}
}

const _album = MusicAlbumDetail(
  mediaSource: 'musicbrainz',
  mediaId: 'album-id',
  title: '测试专辑',
  artist: '测试艺术家',
  year: 2026,
  totalTracks: 2,
  rating: 8.6,
  genres: ['流行', '摇滚'],
  overview: '这是一段专辑简介。',
  tracks: [
    MusicTrack(
      title: '第一首歌曲',
      trackNumber: 1,
      artists: ['曲目演唱者'],
      duration: 245,
    ),
    MusicTrack(title: '第二首歌曲', duration: 59),
  ],
);

Map<String, dynamic> _albumJson(String id) => {
  'music_type': 'album',
  'media_source': 'musicbrainz',
  'media_id': id,
  'title': '目录专辑 $id',
  'artist': '目录艺术家',
  'year': 2026,
};

Finder _textButton(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((widget) => widget is TextButton),
);

Finder get _playButton => find.ancestor(
  of: find.text('媒体库播放'),
  matching: find.byWidgetPredicate((widget) => widget is FilledButton),
);
Finder get _subscribeButton => _textButton('订阅');
Finder get _skeleton =>
    find.byWidgetPredicate((widget) => widget is Skeletonizer);
Finder get _outerScrollable => find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _mount(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: page,
    ),
  );
  // Do not settle: skeletons and pending operations intentionally animate.
  await tester.pump();
  final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
  expect(scaffold.appBar, isA<AppBar>());
  expect(scaffold.body, isNotNull);
  expect(tester.takeException(), isNull);
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: _outerScrollable,
    maxScrolls: 100,
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

void _expectActions(
  WidgetTester tester, {
  required bool play,
  required bool subscribe,
}) {
  expect(tester.widget<FilledButton>(_playButton).onPressed != null, play);
  expect(
    tester.widget<TextButton>(_subscribeButton).onPressed != null,
    subscribe,
  );
}

void main() {
  late _Api api;
  late _Version version;

  setUp(() {
    Get.testMode = true;
    api = _Api();
    version = _Version();
  });

  tearDown(() {
    expect(
      [...api.gets, ...api.posts].every((r) => r.result.isCompleted),
      isTrue,
      reason: 'Every fake request must be explicitly resolved by its test',
    );
    Get.reset();
  });

  group('MusicAlbumPage', () {
    testWidgets('无封面展示占位、专辑元数据、曲目及简介，不自动请求', (tester) async {
      final controller = _AlbumController(api: api, version: version)
        ..album.value = _album;
      Get.put<MusicAlbumController>(controller);

      await _mount(tester, const MusicAlbumPage());

      expect(find.text('测试专辑'), findsNWidgets(2));
      expect(find.text('测试艺术家'), findsOneWidget);
      expect(find.text('专辑 · 2026 · 2 首歌曲 · 评分 8.6'), findsOneWidget);
      expect(find.text('流行 · 摇滚'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.music_note_2), findsOneWidget);
      expect(find.byType(CachedImage), findsNothing);
      final artwork = tester.widget<MusicArtwork>(find.byType(MusicArtwork));
      expect(artwork.imageUrl, isNull);
      expect(artwork.elevated, isTrue);
      expect(artwork.isArtist, isFalse);
      _expectActions(tester, play: true, subscribe: true);

      await _scrollTo(tester, find.text('第一首歌曲'));
      expect(find.text('曲目演唱者'), findsOneWidget);
      expect(find.text('4:05'), findsOneWidget);
      await _scrollTo(tester, find.text('这是一段专辑简介。'));
      expect(find.text('专辑简介'), findsOneWidget);
      expect(api.gets, isEmpty);
      expect(api.posts, isEmpty);
      expect(version.checks, 0);
    });

    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('长标题 ${width.toInt()} 窄屏 ${scale.toInt()} 倍字体无溢出', (
          tester,
        ) async {
          final longTitle = List.filled(8, '漫长的专辑标题与远方的故事').join(' ');
          final longArtist = List.filled(4, '名字很长的合作艺术家').join(' / ');
          final longTrack = List.filled(6, '没有被截断的漫长曲目名称').join(' ');
          final controller = _AlbumController(api: api, version: version)
            ..album.value = MusicAlbumDetail(
              mediaSource: 'musicbrainz',
              mediaId: 'album-id',
              title: longTitle,
              artist: longArtist,
              year: 2026,
              totalTracks: 1,
              genres: ['实验流行', '独立摇滚'],
              tracks: [
                MusicTrack(
                  title: longTrack,
                  artists: [longArtist],
                  duration: 245,
                ),
              ],
            );
          Get.put<MusicAlbumController>(controller);

          await _mount(
            tester,
            const MusicAlbumPage(),
            size: Size(width, 844),
            textScale: scale,
            brightness: scale == 2 ? Brightness.dark : Brightness.light,
          );

          expect(find.text(longTitle), findsNWidgets(2));
          final appBarTitle = tester.widget<Text>(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text(longTitle),
            ),
          );
          expect(appBarTitle.maxLines, 1);
          expect(appBarTitle.overflow, TextOverflow.ellipsis);
          final artworkRect = tester.getRect(find.byType(MusicArtwork));
          expect(artworkRect.left, greaterThanOrEqualTo(0));
          expect(artworkRect.right, lessThanOrEqualTo(width));
          expect(artworkRect.width, lessThanOrEqualTo(270));

          await _scrollTo(tester, _playButton);
          await _scrollTo(tester, _subscribeButton);
          final playRect = tester.getRect(_playButton);
          final subscribeRect = tester.getRect(_subscribeButton);
          if (width == 320 || scale == 2) {
            expect(subscribeRect.top, greaterThanOrEqualTo(playRect.bottom));
            expect(subscribeRect.width, closeTo(playRect.width, 0.01));
          } else {
            expect(subscribeRect.top, closeTo(playRect.top, 0.01));
          }
          _expectActions(tester, play: true, subscribe: true);

          await _scrollTo(tester, find.text(longTrack));
          await _scrollTo(tester, find.text('4:05'));
          expect(find.text(longTrack), findsOneWidget);
          expect(find.text('4:05'), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(api.gets, isEmpty);
          expect(api.posts, isEmpty);
        });
      }
    }

    for (final playAllowed in [false, true]) {
      for (final subscribeAllowed in [false, true]) {
        testWidgets('权限独立控制按钮：播放 $playAllowed、订阅 $subscribeAllowed', (
          tester,
        ) async {
          final controller = _AlbumController(
            api: api,
            version: version,
            playAllowed: playAllowed,
            subscribeAllowed: subscribeAllowed,
          )..album.value = _album;
          Get.put<MusicAlbumController>(controller);
          final semantics = tester.ensureSemantics();
          try {
            await _mount(tester, const MusicAlbumPage());
            _expectActions(
              tester,
              play: playAllowed,
              subscribe: subscribeAllowed,
            );
            expect(
              tester
                  .getSemantics(_playButton)
                  .flagsCollection
                  .isEnabled
                  .toBoolOrNull(),
              playAllowed,
            );
            expect(
              tester
                  .getSemantics(_subscribeButton)
                  .flagsCollection
                  .isEnabled
                  .toBoolOrNull(),
              subscribeAllowed,
            );

            await tester.tap(_playButton);
            if (!subscribeAllowed) await tester.tap(_subscribeButton);
            await tester.pump();
            expect(controller.playCalls, playAllowed ? 1 : 0);
            expect(api.posts, isEmpty);
            expect(api.gets, isEmpty);
            expect(version.checks, 0);
          } finally {
            semantics.dispose();
          }
        });
      }
    }

    testWidgets('操作中锁定两个按钮，结束后恢复可用状态', (tester) async {
      final controller = _AlbumController(api: api, version: version)
        ..album.value = _album;
      Get.put<MusicAlbumController>(controller);
      await _mount(tester, const MusicAlbumPage());
      _expectActions(tester, play: true, subscribe: true);

      controller.isOperating.value = true;
      await tester.pump();
      _expectActions(tester, play: false, subscribe: false);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      await tester.tap(_playButton);
      await tester.tap(_subscribeButton);
      await tester.pump();
      expect(controller.playCalls, 0);
      expect(api.posts, isEmpty);

      controller.isOperating.value = false;
      await tester.pump();
      _expectActions(tester, play: true, subscribe: true);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      await tester.tap(_playButton);
      await tester.pump();
      expect(controller.playCalls, 1);
    });

    testWidgets('点击订阅调用真实控制器，等待假响应时禁止重复操作', (tester) async {
      final controller = _AlbumController(api: api, version: version)
        ..album.value = _album;
      Get.put<MusicAlbumController>(controller);
      await _mount(tester, const MusicAlbumPage());

      await tester.tap(_subscribeButton);
      await tester.pump();
      expect(controller.isOperating.value, isTrue);
      _expectActions(tester, play: false, subscribe: false);
      expect(api.posts.single.path, '/api/v1/subscribe/');
      expect(api.posts.single.data, {
        'type': '音乐',
        'name': '测试专辑',
        'year': '2026',
        'media_source': 'musicbrainz',
        'media_id': 'album-id',
        'music_type': 'album',
      });
      await tester.tap(_playButton);
      await tester.tap(_subscribeButton);
      await tester.pump();
      expect(controller.playCalls, 0);
      expect(api.posts, hasLength(1));

      api.posts.single.complete({'success': true});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.isOperating.value, isFalse);
      _expectActions(tester, play: true, subscribe: true);
      expect(find.text('已提交音乐订阅'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(api.gets, isEmpty);
      expect(version.checks, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('曲目没有点击语义或点击处理，点击不播放、不导航', (tester) async {
      final controller = _AlbumController(api: api, version: version)
        ..album.value = _album;
      Get.put<MusicAlbumController>(controller);
      final semantics = tester.ensureSemantics();
      try {
        await _mount(tester, const MusicAlbumPage());
        await _scrollTo(tester, find.text('第一首歌曲'));
        final row = find.ancestor(
          of: find.text('第一首歌曲'),
          matching: find.byType(MergeSemantics),
        );
        expect(row, findsOneWidget);
        final data = tester.getSemantics(row).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isFalse);
        expect(data.flagsCollection.isButton, isFalse);
        expect(
          find.ancestor(
            of: find.text('第一首歌曲'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is ButtonStyleButton ||
                  widget is CupertinoButton ||
                  (widget is InkWell && widget.onTap != null) ||
                  (widget is GestureDetector && widget.onTap != null),
            ),
          ),
          findsNothing,
        );

        final route = Get.currentRoute;
        await tester.tap(find.text('第一首歌曲'));
        await tester.pump();
        expect(controller.playCalls, 0);
        expect(api.gets, isEmpty);
        expect(api.posts, isEmpty);
        expect(Get.currentRoute, route);
        expect(find.byType(MusicAlbumPage), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('加载骨架禁用操作，完成后展示专辑', (tester) async {
      final controller = _AlbumController(api: api, version: version)
        ..isLoading.value = true;
      Get.put<MusicAlbumController>(controller);
      await _mount(tester, const MusicAlbumPage());
      expect(tester.widget<Skeletonizer>(_skeleton).enabled, isTrue);
      expect(
        find.ancestor(of: _playButton, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      _expectActions(tester, play: false, subscribe: false);
      expect(api.gets, isEmpty);
      expect(version.checks, 0);

      controller.album.value = _album;
      controller.isLoading.value = false;
      await tester.pump();
      expect(_skeleton, findsNothing);
      expect(find.text('测试专辑'), findsNWidgets(2));
      _expectActions(tester, play: true, subscribe: true);
    });

    testWidgets('无专辑显示空状态，错误可重试并恢复内容', (tester) async {
      final controller = _AlbumController(api: api, version: version)
        ..albumTitle = '路由中的专辑名';
      Get.put<MusicAlbumController>(controller);
      await _mount(tester, const MusicAlbumPage());
      expect(find.text('路由中的专辑名'), findsOneWidget);
      expect(find.text('暂无专辑信息'), findsOneWidget);
      expect(_playButton, findsNothing);

      controller.errorText.value = '离线错误';
      await tester.pump();
      expect(find.text('无法加载专辑'), findsOneWidget);
      expect(find.text('离线错误'), findsOneWidget);
      await tester.tap(find.widgetWithText(CupertinoButton, '重试'));
      await tester.pump();
      expect(controller.isLoading.value, isTrue);
      expect(api.gets.single.path, '/api/v1/music/album/album-id');
      expect(api.gets.single.query, {'media_source': 'musicbrainz'});
      expect(api.gets.single.skipEnvelope, isTrue);
      api.gets.single.complete({
        'success': true,
        'data': {
          'media_source': 'musicbrainz',
          'media_id': 'album-id',
          'title': '重试成功的专辑',
        },
      });
      await tester.pumpAndSettle();
      expect(find.text('重试成功的专辑'), findsNWidgets(2));
      expect(find.text('无法加载专辑'), findsNothing);
      await _scrollTo(tester, find.text('暂无曲目信息'));
      expect(find.text('此专辑暂未提供曲目列表'), findsOneWidget);
      expect(controller.errorText.value, isNull);
    });

    testWidgets('已有专辑更新失败仍保留内容和重试入口', (tester) async {
      final controller = _AlbumController(api: api, version: version)
        ..album.value = _album
        ..errorText.value = '更新失败，请稍后重试';
      Get.put<MusicAlbumController>(controller);
      await _mount(tester, const MusicAlbumPage());
      await _scrollTo(tester, find.text('专辑更新失败'));
      expect(find.text('更新失败，请稍后重试'), findsOneWidget);
      expect(find.widgetWithText(CupertinoButton, '重试'), findsOneWidget);
      await _scrollTo(tester, find.text('第一首歌曲'));
      expect(find.text('第一首歌曲'), findsOneWidget);
      expect(controller.album.value, same(_album));
    });
  });

  group('MusicArtistPage', () {
    testWidgets('详情失败仍展示专辑，点击详情重试后恢复艺术家资料', (tester) async {
      final controller = _ArtistController(api: api, version: version)
        ..artistName = '路由艺术家';
      Get.put<MusicArtistController>(controller);
      await _mount(tester, const MusicArtistPage());
      expect(api.gets, isEmpty);
      expect(version.checks, 0);

      final reload = controller.reload();
      await tester.pump();
      expect(api.gets, hasLength(2));
      expect(api.gets.first.path, '/api/v1/music/artist/artist-id');
      expect(api.gets.first.query, {'media_source': 'musicbrainz'});
      expect(api.gets.last.path, '/api/v1/music/artist/artist-id/albums');
      expect(api.gets.every((r) => r.skipEnvelope), isTrue);
      api.gets.first.complete({}, status: 503);
      api.gets.last.complete([_albumJson('first')]);
      await tester.pump();
      await reload;
      await tester.pump();

      expect(find.text('路由艺术家'), findsNWidgets(2));
      expect(find.text('艺术家详情暂不可用，仍可浏览下方专辑。'), findsOneWidget);
      expect(find.text('请求失败 (HTTP 503)'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.person_fill), findsOneWidget);
      await _scrollTo(tester, find.text('目录专辑 first'));
      expect(find.byType(MusicAlbumGrid), findsOneWidget);
      expect(controller.albums.single.mediaId, 'first');

      await tester.ensureVisible(_textButton('重试艺术家详情'));
      await tester.pump();
      await tester.tap(_textButton('重试艺术家详情'));
      await tester.pump();
      expect(api.gets, hasLength(4));
      api.gets[2].complete({
        'media_id': 'artist-id',
        'media_source': 'musicbrainz',
        'name': '恢复的艺术家',
        'artist_type': '组合',
        'country': '中国',
        'life_span': '2000–2026',
        'album_count': 1,
        'genres': ['独立流行'],
      });
      api.gets[3].complete([_albumJson('first')]);
      await tester.pumpAndSettle();
      expect(find.text('恢复的艺术家'), findsNWidgets(2));
      expect(find.text('组合 · 中国 · 2000–2026 · 1 张专辑'), findsOneWidget);
      expect(find.text('独立流行'), findsOneWidget);
      expect(find.text('艺术家详情暂不可用，仍可浏览下方专辑。'), findsNothing);
      expect(controller.artistError.value, isNull);
      expect(controller.albums.single.mediaId, 'first');
      expect(version.checks, 2);
    });

    testWidgets('分页失败保留目录，重试同一页且加载中禁用，再成功追加', (tester) async {
      final controller = _ArtistController(api: api, version: version);
      Get.put<MusicArtistController>(controller);
      await _mount(tester, const MusicArtistPage());
      final reload = controller.reload();
      await tester.pump();
      api.gets.first.complete({'name': '目录艺术家'});
      api.gets.last.complete(List.generate(30, (i) => _albumJson('first-$i')));
      await tester.pump();
      await reload;
      await tester.pump();
      expect(controller.hasMore.value, isTrue);
      expect(api.gets.last.query, {
        'page': 1,
        'count': 30,
        'media_source': 'musicbrainz',
      });

      await _scrollTo(tester, find.text('加载更多'));
      await tester.tap(find.widgetWithText(CupertinoButton, '加载更多'));
      await tester.pump();
      expect(api.gets, hasLength(3));
      expect(api.gets.last.query?['page'], 2);
      expect(controller.isLoadingMore.value, isTrue);
      expect(
        tester
            .widget<CupertinoButton>(
              find.widgetWithText(CupertinoButton, '加载中…'),
            )
            .onPressed,
        isNull,
      );
      api.gets.last.complete({}, status: 502);
      await tester.pumpAndSettle();
      expect(controller.albums, hasLength(30));
      expect(controller.hasMore.value, isTrue);
      await _scrollTo(tester, find.text('未能加载更多专辑'));
      expect(find.text('请求失败 (HTTP 502)'), findsOneWidget);
      await _scrollTo(tester, find.widgetWithText(CupertinoButton, '重试'));
      await tester.tap(find.widgetWithText(CupertinoButton, '重试'));
      await tester.pump();
      expect(api.gets, hasLength(4));
      expect(api.gets.last.query?['page'], 2);
      expect(find.text('未能加载更多专辑'), findsNothing);
      final busyButton = find.widgetWithText(CupertinoButton, '加载中…');
      expect(tester.widget<CupertinoButton>(busyButton).onPressed, isNull);
      await tester.tap(busyButton);
      await tester.pump();
      expect(api.gets, hasLength(4));

      api.gets.last.complete([_albumJson('first-0'), _albumJson('last')]);
      await tester.pumpAndSettle();
      expect(controller.albums, hasLength(31));
      expect(controller.albums.first.mediaId, 'first-0');
      expect(controller.albums.last.mediaId, 'last');
      expect(controller.errorText.value, isNull);
      expect(controller.hasMore.value, isFalse);
      expect(
        tester.widget<MusicAlbumGrid>(find.byType(MusicAlbumGrid)).items,
        hasLength(31),
      );
      await _scrollTo(tester, find.text('目录专辑 last'));
      expect(find.text('目录专辑 last'), findsOneWidget);
      await _scrollTo(tester, find.text('没有更多了'));
      expect(find.text('未能加载更多专辑'), findsNothing);
      expect(find.text('加载更多'), findsNothing);
    });

    testWidgets('空目录、加载占位、首次目录错误与页面重试', (tester) async {
      final controller = _ArtistController(api: api, version: version)
        ..artistName = '备用艺术家';
      Get.put<MusicArtistController>(controller);
      await _mount(tester, const MusicArtistPage());
      expect(find.text('暂无专辑'), findsOneWidget);
      expect(find.text('此艺术家暂未提供专辑信息'), findsOneWidget);
      expect(find.text('备用艺术家'), findsNWidgets(2));
      expect(find.text('加载更多'), findsNothing);

      final reload = controller.reload();
      await tester.pump();
      expect(tester.widget<Skeletonizer>(_skeleton).enabled, isTrue);
      expect(find.text('加载中的艺术家'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('暂无专辑'), findsNothing);
      api.gets.first.complete({'name': '已加载艺术家'});
      api.gets.last.complete({}, status: 500);
      await tester.pump();
      await reload;
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text('无法加载专辑'));
      expect(find.text('请求失败 (HTTP 500)'), findsOneWidget);
      await _scrollTo(tester, find.widgetWithText(CupertinoButton, '重试'));
      await tester.tap(find.widgetWithText(CupertinoButton, '重试'));
      await tester.pump();
      expect(api.gets, hasLength(4));
      expect(api.gets.last.query?['page'], 1);
      api.gets[2].complete({'name': '已加载艺术家'});
      api.gets[3].complete([_albumJson('recovered')]);
      await tester.pumpAndSettle();
      expect(controller.errorText.value, isNull);
      expect(find.text('无法加载专辑'), findsNothing);
      await _scrollTo(tester, find.text('目录专辑 recovered'));
      expect(find.text('目录专辑 recovered'), findsOneWidget);
    });
  });
}
