import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/controllers/music_search_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/pages/music_library_page.dart';
import 'package:moviepilot_mobile/modules/music/pages/music_search_page.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_discovery_sections.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_item_card.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Api implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Version implements ServerApiVersionService {
  @override
  Future<bool> isV3() async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BrowseApi extends _Api {
  final queries = <Map<String, dynamic>?>[];
  bool failNext = false;

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
    expect(path, '/api/v1/music/explore');
    queries.add(queryParameters);
    final fail = failNext;
    failNext = false;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: fail ? 503 : 200,
      data:
          (fail
                  ? <String, dynamic>{}
                  : [
                      for (final item in _browseAlbums(
                        queryParameters?['page'] == 1 ? 5 : 6,
                      ))
                        {
                          'music_type': item.musicType,
                          'media_id': item.mediaId,
                          'title': item.title,
                          'artist': item.artist,
                          'year': item.year,
                          'genres': item.genres,
                        },
                      if (queryParameters?['page'] == 1)
                        for (var i = 0; i < 25; i++)
                          {'music_type': 'recording', 'media_id': 'track-$i'},
                    ])
              as T,
    );
  }
}

class _LiveLibrary extends MusicLibraryController {
  _LiveLibrary(_BrowseApi api)
    : super(apiClient: api, versionService: _Version());
  @override
  void onReady() {}
}

class _Library extends MusicLibraryController {
  _Library() : super(apiClient: _Api(), versionService: _Version());
  int reloads = 0;
  int more = 0;
  @override
  void onReady() {}
  @override
  Future<void> reload() async => reloads++;
  @override
  Future<void> loadMore() async => more++;
}

class _Search extends MusicSearchController {
  _Search() : super(apiClient: _Api(), versionService: _Version());
  final submissions = <String>[];
  int more = 0;
  @override
  void onReady() {}
  @override
  Future<void> search({String? keywordOverride}) async {
    final term = keywordOverride ?? keyword.value;
    submissions.add(term);
    keyword.value = term;
  }

  @override
  Future<void> loadMore() async => more++;
}

const _album = MusicExploreItem(
  musicType: 'album',
  mediaSource: 'doubanmusic',
  mediaId: 'album-id',
  title: '漫长的旅途与四季更迭中的音乐专辑',
  artist: '艺人名字',
  year: 2026,
);
const _artist = MusicExploreItem(
  musicType: 'artist',
  mediaSource: 'musicbrainz',
  mediaId: 'artist-id',
  title: '艺人名字',
);

List<MusicExploreItem> _browseAlbums(int count) => List.generate(
  count,
  (index) => MusicExploreItem(
    musicType: 'album',
    mediaSource: 'doubanmusic',
    mediaId: 'browse-$index',
    title: '第${index + 1}张漫长的旅途与四季更迭中的音乐专辑',
    artist: '艺人名字与合作伙伴',
    year: 2026 - index,
    genres: index.isEven ? ['Rock'] : ['Jazz'],
  ),
);

Finder _inSection(Type type, Finder finder) =>
    find.descendant(of: find.byType(type), matching: finder);

Finder get _verticalScroll => find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    )
    .first;

Future<void> _scrollTo(
  WidgetTester tester,
  Finder target, {
  double delta = 250,
}) async {
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: _verticalScroll,
    maxScrolls: 80,
  );
  await tester.pumpAndSettle();
}

// Sliver children outside the cache extent may not be mounted yet. State
// snapshots inspect configured sections; interaction tests scroll to real widgets.
Iterable<T> _sections<T extends Widget>(WidgetTester tester) => tester
    .widget<CustomScrollView>(find.byType(CustomScrollView))
    .slivers
    .whereType<SliverToBoxAdapter>()
    .map((sliver) => sliver.child)
    .whereType<T>();

T _section<T extends Widget>(WidgetTester tester) =>
    _sections<T>(tester).single;

MusicAlbumGrid _grid(WidgetTester tester) => tester
    .widget<CustomScrollView>(find.byType(CustomScrollView))
    .slivers
    .whereType<MusicAlbumGrid>()
    .single;

Iterable<String> _headings(WidgetTester tester) =>
    _sections<MusicSectionHeading>(tester).map((heading) => heading.title);

void _expectSectionItems(WidgetTester tester, List<MusicExploreItem> albums) {
  expect(
    _section<MusicFeaturedShelf>(tester).items,
    orderedEquals(albums.take(6)),
  );
  expect(
    _section<MusicDiscoveryRanking>(tester).items,
    orderedEquals(albums.take(9)),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  double width = 390,
  double scale = 1,
  Brightness brightness = Brightness.light,
  List<GetPage<dynamic>> routes = const [],
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      getPages: routes,
      home: page,
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());

  testWidgets('library keeps loading, unsupported, empty and retry states', (
    tester,
  ) async {
    final c = Get.put<MusicLibraryController>(_Library()) as _Library;
    await _pump(tester, const MusicLibraryPage());
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    c.supported.value = false;
    await tester.pump();
    expect(find.text('音乐功能需要 MoviePilot v3 服务端'), findsOneWidget);
    expect(find.byType(MusicSearchField), findsNothing);
    c.supported.value = true;
    c.hasMore.value = false;
    await tester.pump();
    expect(find.text('暂无音乐内容'), findsOneWidget);
    c.errorText.value = '测试网络错误';
    await tester.pump();
    expect(find.text('暂时无法载入音乐'), findsOneWidget);
    await tester.ensureVisible(find.text('重试'));
    await tester.tap(find.text('重试'));
    expect(c.reloads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'appbar source picker exposes only explore sources with selected semantics',
    (tester) async {
      final c = Get.put<MusicLibraryController>(_Library()) as _Library;
      SharedPreferences.setMockInitialValues(const {});
      c.supported.value = true;
      c.hasMore.value = false;
      await _pump(tester, const MusicLibraryPage());
      final semantics = tester.ensureSemantics();
      expect(find.text('TheAudioDB'), findsNothing);
      expect(find.byType(CupertinoSlidingSegmentedControl), findsNothing);
      await tester.tap(find.byIcon(CupertinoIcons.music_note_list));
      await tester.pumpAndSettle();
      expect(find.text('音乐来源'), findsOneWidget);
      expect(find.text('TheAudioDB'), findsNothing);
      final selected = find.ancestor(
        of: find.text('MusicBrainz'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.selected == true,
        ),
      );
      expect(selected, findsOneWidget);
      await tester.tap(find.text('豆瓣音乐'));
      await tester.pumpAndSettle();
      expect(c.selectedSource.value, 'doubanmusic');
      expect(c.reloads, 1);
      expect(find.text('音乐来源'), findsNothing);
      expect(find.text('豆瓣音乐'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'library search trims keyword and preserves search route contract',
    (tester) async {
      final c = Get.put<MusicLibraryController>(_Library());
      c.supported.value = true;
      c.hasMore.value = false;
      String? keyword;
      await _pump(
        tester,
        const MusicLibraryPage(),
        routes: [
          GetPage(
            name: '/music/search',
            page: () {
              keyword = Get.parameters['keyword'];
              return const Scaffold(body: Text('搜索目标页面'));
            },
          ),
        ],
      );
      await tester.enterText(find.byType(TextFormField), '  海阔天空 & live  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(keyword, '海阔天空 & live');
      expect(find.text('搜索目标页面'), findsOneWidget);
    },
  );

  testWidgets('library album navigation preserves identity and source', (
    tester,
  ) async {
    final c = Get.put<MusicLibraryController>(_Library());
    c.supported.value = true;
    c.hasMore.value = false;
    c.items.add(_album);
    Object? arguments;
    await _pump(
      tester,
      const MusicLibraryPage(),
      routes: [
        GetPage(
          name: '/music/album',
          page: () {
            arguments = Get.arguments;
            return const Scaffold(body: Text('专辑目标页面'));
          },
        ),
      ],
    );
    final gridTitle = _inSection(
      MusicAlbumGrid,
      find.text(_album.displayTitle),
    );
    await _scrollTo(tester, gridTitle);
    await tester.tap(gridTitle);
    await tester.pumpAndSettle();
    expect(arguments, {
      'mediaId': 'album-id',
      'mediaSource': 'doubanmusic',
      'title': _album.displayTitle,
    });
  });

  testWidgets(
    'featured covers scroll horizontally and navigate with album identity',
    (tester) async {
      final c = Get.put<MusicLibraryController>(_Library());
      final albums = _browseAlbums(10);
      c.supported.value = true;
      c.hasMore.value = false;
      c.items.addAll([_artist, ...albums]);
      Object? arguments;
      await _pump(
        tester,
        const MusicLibraryPage(),
        routes: [
          GetPage(
            name: '/music/album',
            page: () {
              arguments = Get.arguments;
              return const Scaffold(body: Text('推荐专辑目标页面'));
            },
          ),
        ],
      );
      expect(find.text('值得一听'), findsOneWidget);
      expect(find.text('发现 TOP 9'), findsOneWidget);
      expect(find.text('按来源返回顺序展示 · 序号非官方榜单名次'), findsOneWidget);
      _expectSectionItems(tester, albums);
      final shelf = find.byType(MusicFeaturedShelf);
      await _scrollTo(tester, shelf);
      final target = _inSection(
        MusicFeaturedShelf,
        find.byWidgetPredicate(
          (w) => w is MusicItemCard && w.item.mediaId == albums[5].mediaId,
        ),
      );
      expect(target.hitTestable(), findsNothing);
      final horizontal = find.descendant(
        of: shelf,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(target, 240, scrollable: horizontal);
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(horizontal).position.pixels,
        greaterThan(0),
      );
      expect(target.hitTestable(), findsOneWidget);
      await tester.tap(
        find.descendant(of: target, matching: find.byType(MusicArtwork)),
      );
      await tester.pumpAndSettle();
      expect(arguments, {
        'mediaId': albums[5].mediaId,
        'mediaSource': 'doubanmusic',
        'title': albums[5].displayTitle,
      });
      expect(find.text('推荐专辑目标页面'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ranking fourth album scrolls into view with honest semantics and navigation',
    (tester) async {
      final c = Get.put<MusicLibraryController>(_Library());
      final albums = _browseAlbums(10);
      c.supported.value = true;
      c.hasMore.value = false;
      c.items.addAll([_artist, ...albums.take(2), _artist, ...albums.skip(2)]);
      Object? arguments;
      await _pump(
        tester,
        const MusicLibraryPage(),
        routes: [
          GetPage(
            name: '/music/album',
            page: () {
              arguments = Get.arguments;
              return const Scaffold(body: Text('排名专辑目标页面'));
            },
          ),
        ],
      );
      final handle = tester.ensureSemantics();
      await _scrollTo(tester, find.byType(MusicDiscoveryRanking));
      final label =
          '浏览序号 4，${albums[3].displayTitle}，${albums[3].displayArtist} · ${albums[3].year}';
      final target = _inSection(
        MusicDiscoveryRanking,
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == label,
        ),
      );
      expect(target.hitTestable(), findsNothing);
      final horizontal = _inSection(
        MusicDiscoveryRanking,
        find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(target, 240, scrollable: horizontal);
      await tester.pumpAndSettle();
      expect(target.hitTestable(), findsOneWidget);
      expect(
        _inSection(MusicDiscoveryRanking, find.text('04')).hitTestable(),
        findsOneWidget,
      );
      expect(
        _inSection(
          MusicDiscoveryRanking,
          find.text(albums[3].displayTitle),
        ).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(target),
        matchesSemantics(label: label, isButton: true, hasTapAction: true),
      );
      expect(
        _inSection(MusicDiscoveryRanking, find.text(_artist.displayTitle)),
        findsNothing,
      );
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(arguments, {
        'mediaId': albums[3].mediaId,
        'mediaSource': 'doubanmusic',
        'title': albums[3].displayTitle,
      });
      expect(find.text('排名专辑目标页面'), findsOneWidget);
      handle.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'genre picker filters only the catalog and restores all source items',
    (tester) async {
      final c = Get.put<MusicLibraryController>(_Library()) as _Library;
      final albums = _browseAlbums(5);
      final artist = MusicExploreItem(
        musicType: 'artist',
        mediaSource: 'musicbrainz',
        mediaId: 'rock-artist',
        title: '真实风格艺人',
        genres: const [' rock '],
      );
      c.supported.value = true;
      c.hasMore.value = false;
      c.items.addAll([albums[0], albums[1], artist, ...albums.skip(2)]);
      final original = c.items.toList();
      await _pump(tester, const MusicLibraryPage());
      await _scrollTo(tester, find.text('风格漫游'));
      expect(find.text('风格漫游').hitTestable(), findsOneWidget);
      expect(_headings(tester), contains('探索专辑'));
      expect(_section<MusicGenrePicker>(tester).genres, ['Rock', 'Jazz']);
      await _scrollTo(tester, _inSection(MusicGenrePicker, find.text('Rock')));
      await tester.tap(_inSection(MusicGenrePicker, find.text('Rock')));
      await tester.pumpAndSettle();
      expect(c.selectedGenre.value, 'Rock');
      expect(_headings(tester), contains('Rock · 专辑'));
      expect(_headings(tester), isNot(contains('探索专辑')));
      expect(
        _grid(tester).items,
        orderedEquals([albums[0], artist, albums[2], albums[4]]),
      );
      _expectSectionItems(tester, albums);
      expect(_headings(tester), containsAll(['值得一听', '发现 TOP 5']));
      expect(_section<MusicGenrePicker>(tester).selected, 'Rock');
      final selected = find.ancestor(
        of: _inSection(MusicGenrePicker, find.text('Rock')),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.selected == true,
        ),
      );
      expect(selected, findsOneWidget);
      await tester.tap(_inSection(MusicGenrePicker, find.text('全部风格')));
      await tester.pumpAndSettle();
      expect(c.selectedGenre.value, isNull);
      expect(_grid(tester).items, orderedEquals(original));
      _expectSectionItems(tester, albums);
      expect(c.reloads, 0);
      expect(c.more, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final count in [0, 1, 2]) {
    testWidgets(
      'only $count albums renders honest sections without invented genres',
      (tester) async {
        final c = Get.put<MusicLibraryController>(_Library());
        final albums = List.generate(
          count,
          (i) => MusicExploreItem(
            musicType: 'album',
            mediaSource: 'musicbrainz',
            mediaId: 'sparse-$i',
            title: '稀疏专辑$i',
          ),
        );
        c.supported.value = true;
        c.hasMore.value = false;
        c.items.addAll([_artist, ...albums]);
        await _pump(tester, const MusicLibraryPage());
        expect(find.byType(MusicGenrePicker), findsNothing);
        expect(find.text('风格漫游'), findsNothing);
        expect(find.text('全部风格'), findsNothing);
        await _scrollTo(tester, find.text('探索专辑'));
        expect(find.text('探索专辑').hitTestable(), findsOneWidget);
        expect(_grid(tester).items, orderedEquals([_artist, ...albums]));
        if (count == 0) {
          expect(find.byType(MusicFeaturedShelf), findsNothing);
          expect(find.text('值得一听'), findsNothing);
        } else {
          expect(
            _section<MusicFeaturedShelf>(tester).items,
            orderedEquals(albums),
          );
        }
        if (count < 2) {
          expect(find.byType(MusicDiscoveryRanking), findsNothing);
          expect(find.textContaining('发现 TOP'), findsNothing);
        } else {
          _expectSectionItems(tester, albums);
          expect(_headings(tester), contains('发现 TOP 2'));
          await _scrollTo(
            tester,
            find.byType(MusicDiscoveryRanking),
            delta: -250,
          );
          expect(
            _inSection(MusicDiscoveryRanking, find.text('03')),
            findsNothing,
          );
        }
        expect(find.text('发现 TOP 9'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'source selection and pull to refresh reset the real controller genre',
    (tester) async {
      final api = _BrowseApi();
      final c = Get.put<MusicLibraryController>(_LiveLibrary(api));
      await c.reload();
      await _pump(tester, const MusicLibraryPage());
      Future<void> selectRock() async {
        final rock = _inSection(MusicGenrePicker, find.text('Rock'));
        await _scrollTo(tester, rock);
        await tester.tap(rock);
        await tester.pumpAndSettle();
        expect(c.selectedGenre.value, 'Rock');
      }

      await selectRock();
      expect(api.queries, hasLength(1));
      await tester.tap(find.byIcon(CupertinoIcons.music_note_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('豆瓣音乐'));
      await tester.pumpAndSettle();
      expect(c.selectedSource.value, 'doubanmusic');
      expect(c.selectedGenre.value, isNull);
      expect(_section<MusicGenrePicker>(tester).selected, isNull);
      expect(api.queries, hasLength(2));
      await selectRock();
      await _scrollTo(tester, find.text('音乐库'), delta: -250);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(api.queries, hasLength(3));
      expect(c.selectedGenre.value, isNull);
      expect(_headings(tester), contains('探索专辑'));
      for (var index = 0; index < api.queries.length; index++) {
        expect(api.queries[index], {
          'page': 1,
          'count': 30,
          'media_source': index == 0 ? 'musicbrainz' : 'doubanmusic',
          'entity': 'album',
        });
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'library pagination errors retain all sections and retry the same page',
    (tester) async {
      final api = _BrowseApi();
      final c = Get.put<MusicLibraryController>(_LiveLibrary(api));
      await c.reload();
      final original = c.items.toList();
      await _pump(tester, const MusicLibraryPage());
      c.selectGenre('Rock');
      await tester.pumpAndSettle();
      final filtered = c.visibleItems;
      api.failNext = true;
      await _scrollTo(tester, find.text('加载更多'));
      await tester.tap(find.text('加载更多'));
      await tester.pumpAndSettle();
      expect(api.queries, hasLength(2));
      expect(c.items, orderedEquals(original));
      expect(c.selectedGenre.value, 'Rock');
      _expectSectionItems(tester, original);
      expect(_grid(tester).items, orderedEquals(filtered));
      expect(_headings(tester), containsAll(['值得一听', '发现 TOP 5']));
      expect(find.text('暂时无法载入音乐'), findsNothing);
      final retry = find.text('请求失败 (HTTP 503) · 重试');
      await _scrollTo(tester, retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(api.queries, hasLength(3));
      expect(api.queries[1], {
        'page': 2,
        'count': 30,
        'media_source': 'musicbrainz',
        'entity': 'album',
      });
      expect(api.queries[2], api.queries[1]);
      expect(c.errorText.value, isNull);
      expect(retry, findsNothing);
      expect(c.items.map((item) => item.mediaId), [
        ...original.map((item) => item.mediaId),
        'browse-5',
      ]);
      expect(c.items.take(original.length), orderedEquals(original));
      expect(c.selectedGenre.value, 'Rock');
      expect(_grid(tester).items, orderedEquals(filtered));
      _expectSectionItems(tester, c.items.toList());
      expect(_headings(tester), containsAll(['值得一听', '发现 TOP 6']));
      expect(c.hasMore.value, isFalse);
      await _scrollTo(tester, find.text('没有更多了'));
      expect(find.text('没有更多了').hitTestable(), findsOneWidget);
      expect(find.text('加载更多'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 390.0, 768.0]) {
      testWidgets(
        'discovery components fit $width at 2x in ${brightness.name}',
        (tester) async {
          final albums = _browseAlbums(9);
          final opened = <MusicExploreItem>[];
          await _pump(
            tester,
            MusicTheme(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      MusicFeaturedShelf(
                        items: albums.take(6).toList(),
                        onOpen: opened.add,
                      ),
                      MusicDiscoveryRanking(items: albums, onOpen: opened.add),
                      MusicGenrePicker(
                        genres: const ['Rock', 'Jazz', '电子音乐'],
                        selected: 'Rock',
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
            width: width,
            scale: 2,
            brightness: brightness,
          );
          expect(tester.takeException(), isNull);
          final shelfTitle = _inSection(
            MusicFeaturedShelf,
            find.text(albums.first.displayTitle),
          );
          final shelfContext = tester.element(shelfTitle);
          expect(
            tester.widget<Text>(shelfTitle).style?.color,
            Theme.of(shelfContext).colorScheme.onSurface,
          );
          await _scrollTo(
            tester,
            _inSection(MusicDiscoveryRanking, find.text('03')),
          );
          expect(
            _inSection(MusicDiscoveryRanking, find.text('03')).hitTestable(),
            findsOneWidget,
          );
          final rankTitle = _inSection(
            MusicDiscoveryRanking,
            find.text(albums.first.displayTitle),
          );
          expect(
            tester.widget<Text>(rankTitle).style?.color,
            Theme.of(tester.element(rankTitle)).colorScheme.onSurface,
          );
          await _scrollTo(
            tester,
            _inSection(MusicGenrePicker, find.text('电子音乐')),
          );
          expect(
            _inSection(MusicGenrePicker, find.text('电子音乐')).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'artwork grid fits $width at $scale in ${brightness.name}',
          (tester) async {
            final c = Get.put<MusicLibraryController>(_Library());
            c.supported.value = true;
            c.hasMore.value = false;
            c.items.addAll([_album, _artist, ..._browseAlbums(2)]);
            await _pump(
              tester,
              const MusicLibraryPage(),
              width: width,
              scale: scale,
              brightness: brightness,
            );
            final gridTitle = _inSection(
              MusicAlbumGrid,
              find.text(_album.displayTitle),
            );
            await _scrollTo(tester, gridTitle);
            expect(
              _inSection(MusicAlbumGrid, find.byType(MusicItemCard)),
              findsWidgets,
            );
            expect(gridTitle.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
            final text = tester.widget<Text>(gridTitle);
            final context = tester.element(gridTitle);
            expect(text.style?.color, Theme.of(context).colorScheme.onSurface);
          },
        );
      }
    }
  }

  testWidgets('initial grid skeleton works with sliver layout', (tester) async {
    final c = Get.put<MusicLibraryController>(_Library());
    c.supported.value = true;
    c.isLoading.value = true;
    await _pump(tester, const MusicLibraryPage());
    expect(find.byType(MusicAlbumGrid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'grid uses its constrained width and card exposes accessible tap',
    (tester) async {
      int opened = 0;
      await _pump(
        tester,
        MusicTheme(
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: CustomScrollView(
                  slivers: [
                    MusicAlbumGrid(
                      items: const [_album, _artist],
                      onOpen: (_) => opened++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        width: 900,
      );
      final cards = tester.widgetList<MusicItemCard>(
        find.byType(MusicItemCard),
      );
      expect(cards.first.cardWidth, lessThanOrEqualTo(300));
      final handle = tester.ensureSemantics();
      final semantics = tester.getSemantics(find.byType(MusicItemCard).first);
      expect(
        semantics,
        matchesSemantics(
          label:
              '${_album.displayTitle}，${_album.displayArtist} · ${_album.year}',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text(_album.displayTitle));
      expect(opened, 1);
      handle.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search ignores blank terms and resubmits a trimmed keyword', (
    tester,
  ) async {
    final c = Get.put<MusicSearchController>(_Search()) as _Search;
    await _pump(tester, const MusicSearchPage(), width: 320, scale: 2);
    expect(find.text('寻找你的下一首心动'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(c.submissions, isEmpty);
    await tester.enterText(find.byType(TextFormField), '  测试歌曲  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(c.submissions, ['测试歌曲']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search states distinguish no results from retryable errors', (
    tester,
  ) async {
    final c = Get.put<MusicSearchController>(_Search()) as _Search;
    c.keyword.value = '测试';
    c.errorText.value = '没有找到匹配的音乐';
    await _pump(tester, const MusicSearchPage());
    expect(find.text('没有找到匹配的音乐'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    c.errorText.value = '测试失败';
    await tester.pump();
    await tester.tap(find.text('重试'));
    expect(c.submissions, ['测试']);
    c.supported.value = false;
    await tester.pump();
    expect(find.text('音乐功能需要 MoviePilot v3 服务端'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search pagination retains results and offers explicit retry', (
    tester,
  ) async {
    final c = Get.put<MusicSearchController>(_Search()) as _Search;
    c.keyword.value = '测试';
    c.supported.value = true;
    c.items.addAll([_album, _artist]);
    c.errorText.value = '测试分页错误';
    await _pump(
      tester,
      const MusicSearchPage(),
      width: 320,
      scale: 2,
      brightness: Brightness.dark,
    );
    expect(find.text(_album.displayTitle), findsOneWidget);
    await tester.ensureVisible(find.text('测试分页错误 · 重试'));
    await tester.tap(find.text('测试分页错误 · 重试'));
    expect(c.more, 1);
    c.errorText.value = null;
    await tester.pump();
    await tester.ensureVisible(find.text('加载更多'));
    await tester.tap(find.text('加载更多'));
    expect(c.more, greaterThanOrEqualTo(2));
    expect(tester.takeException(), isNull);
  });
}
