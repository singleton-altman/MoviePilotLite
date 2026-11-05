import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/controllers/music_search_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/pages/music_recording_page.dart';
import 'package:moviepilot_mobile/modules/music/pages/music_search_page.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

class _Recording extends MusicRecordingController {
  _Recording({bool subscribeAllowed = true, bool searchAllowed = true})
    : super(
        apiClient: _Api(),
        versionService: _Version(),
        mediaId: 'recording-id',
      ) {
    canSubscribeOverride = subscribeAllowed;
    canSearchOverride = searchAllowed;
  }

  bool canSubscribeOverride = true;
  bool canSearchOverride = true;

  @override
  void onReady() {}

  @override
  void onInit() {
    super.onInit();
    mediaId = 'recording-id';
    mediaSource = 'musicbrainz';
  }

  @override
  bool get canSubscribe => canSubscribeOverride;

  @override
  bool get canSearch => canSearchOverride;

  int toggles = 0;

  @override
  Future<String?> toggleSubscribe() async {
    toggles++;
    return null;
  }
}

class _Search extends MusicSearchController {
  _Search() : super(apiClient: _Api(), versionService: _Version());

  @override
  void onReady() {}
}

const _detail = MusicRecordingDetail(
  mediaSource: 'musicbrainz',
  mediaId: 'recording-id',
  title: '晴天',
  artist: '周杰伦',
  album: '叶惠美',
  albumId: 'album-9',
  year: 2003,
  trackNumber: 3,
  totalTracks: 2,
  duration: 269,
  isrc: 'TW-A65-03-00001',
  genres: ['流行'],
  detailLink: 'https://musicbrainz.org/recording/recording-id',
);

const _album = MusicAlbumDetail(
  mediaSource: 'musicbrainz',
  mediaId: 'album-9',
  title: '叶惠美',
  tracks: [
    MusicTrack(
      mediaId: 'recording-id',
      title: '晴天',
      trackNumber: 3,
      duration: 269,
    ),
    MusicTrack(mediaId: 'other', title: '以父之名', trackNumber: 2, duration: 341),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
  double scale = 1,
  Brightness brightness = Brightness.light,
  List<GetPage<dynamic>> routes = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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

Finder get _subscribeButton => find.ancestor(
  of: find.text('订阅'),
  matching: find.byWidgetPredicate((w) => w is FilledButton),
);

Finder get _resourceButton => find.ancestor(
  of: find.text('搜索资源'),
  matching: find.byWidgetPredicate((w) => w is TextButton),
);

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('单曲详情展示曲目信息、高亮当前曲目并列出所属专辑', (tester) async {
    final controller = _Recording()
      ..recording.value = _detail
      ..album.value = _album
      ..isSubscribed.value = false;
    Get.put<MusicRecordingController>(controller);

    await _pump(tester, const MusicRecordingPage());

    expect(find.text('晴天'), findsNWidgets(3));
    expect(find.text('周杰伦'), findsOneWidget);
    expect(find.textContaining('叶惠美'), findsWidgets);
    expect(find.textContaining('4:29'), findsWidgets);
    expect(find.textContaining('第 3 轨'), findsOneWidget);
    expect(find.textContaining('ISRC TW-A65-03-00001'), findsOneWidget);
    expect(find.text('流行'), findsOneWidget);
    expect(find.byType(MusicArtwork), findsOneWidget);
    expect(tester.widget<FilledButton>(_subscribeButton).onPressed, isNotNull);
    expect(tester.widget<TextButton>(_resourceButton).onPressed, isNotNull);

    await tester.scrollUntilVisible(
      find.text('以父之名'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 40,
    );
    await tester.pump();
    expect(find.text('以父之名'), findsOneWidget);
    expect(find.byType(CupertinoButton), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('订阅与搜索资源按钮按权限独立控制', (tester) async {
    for (final subscribe in [false, true]) {
      for (final search in [false, true]) {
        final controller = _Recording(
          subscribeAllowed: subscribe,
          searchAllowed: search,
        )..recording.value = _detail;
        Get.put<MusicRecordingController>(controller);
        await _pump(tester, const MusicRecordingPage());
        expect(
          tester.widget<FilledButton>(_subscribeButton).onPressed != null,
          subscribe,
        );
        expect(
          tester.widget<TextButton>(_resourceButton).onPressed != null,
          search,
        );
        Get.reset();
      }
    }
  });

  testWidgets('加载中显示骨架，失败显示可重试状态', (tester) async {
    final controller = _Recording();
    Get.put<MusicRecordingController>(controller);
    controller.isLoading.value = true;
    await _pump(tester, const MusicRecordingPage());
    expect(
      find.byWidgetPredicate((widget) => widget is Skeletonizer),
      findsOneWidget,
    );

    controller.isLoading.value = false;
    controller.errorText.value = '识别失败';
    await tester.pump();
    expect(find.text('无法加载单曲'), findsOneWidget);
    expect(find.text('识别失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('缺少 album_id 时给出说明而不是空区块', (tester) async {
    final controller = _Recording()
      ..recording.value = const MusicRecordingDetail(
        mediaSource: 'musicbrainz',
        mediaId: 'recording-id',
        title: '没有专辑的单曲',
      );
    Get.put<MusicRecordingController>(controller);
    await _pump(tester, const MusicRecordingPage());
    expect(find.text('该单曲未关联专辑信息'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏与 2 倍字体下操作按钮纵向排列且不溢出', (tester) async {
    final controller = _Recording()
      ..recording.value = _detail
      ..album.value = _album;
    Get.put<MusicRecordingController>(controller);
    await _pump(
      tester,
      const MusicRecordingPage(),
      size: const Size(320, 844),
      scale: 2,
      brightness: Brightness.dark,
    );
    await tester.scrollUntilVisible(
      _resourceButton,
      240,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 40,
    );
    await tester.pump();
    final subscribeRect = tester.getRect(_subscribeButton);
    final resourceRect = tester.getRect(_resourceButton);
    expect(resourceRect.top, greaterThanOrEqualTo(subscribeRect.bottom));
    expect(resourceRect.width, closeTo(subscribeRect.width, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索结果中的单曲跳转单曲详情并带来源与艺人', (tester) async {
    final controller = _Search();
    controller.supported.value = true;
    controller.items.addAll(const [
      MusicExploreItem(
        musicType: 'recording',
        mediaSource: 'doubanmusic',
        mediaId: 'song-1',
        title: '海阔天空',
        artist: 'Beyond',
        album: '乐与怒',
        albumId: 'album-1',
      ),
      MusicExploreItem(
        musicType: 'recording',
        mediaSource: 'musicbrainz',
        mediaId: '',
        title: '无标识单曲',
      ),
    ]);
    Get.put<MusicSearchController>(controller);
    Object? arguments;
    final toasts = <String>[];
    await _pump(
      tester,
      const MusicSearchPage(),
      routes: [
        GetPage(
          name: '/music/detail',
          page: () {
            arguments = Get.arguments;
            return const Scaffold(body: Text('单曲目标页面'));
          },
        ),
      ],
    );
    await tester.tap(find.text('海阔天空'));
    await tester.pumpAndSettle();
    expect(arguments, {
      'mediaId': 'song-1',
      'mediaSource': 'doubanmusic',
      'title': '海阔天空',
      'artist': 'Beyond',
    });
    expect(find.text('单曲目标页面'), findsOneWidget);
    expect(toasts, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
