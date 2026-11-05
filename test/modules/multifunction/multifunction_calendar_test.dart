import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/models/login_response.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:moviepilot_mobile/modules/multifunction/debug/dashboard_calendar_debug_api.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

class _FakeApiClient extends GetxService implements ApiClient {
  List<Map<String, dynamic>> subscribes = [];
  final payloads = <String, dynamic>{};
  final statuses = <String, int>{};
  final failures = <String>{};
  final paths = <String>[];
  final queries = <String, Map<String, dynamic>?>{};
  final queryLog = <Map<String, dynamic>?>[];
  final tokens = <String, String?>{};

  @override
  String? get token => 'test-token';

  // 置空让 ServerApiVersionService.isV3() 直接返回 false，不触发网络探测
  @override
  String? get baseUrl => null;

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
    paths.add(path);
    queries[path] = queryParameters;
    queryLog.add(queryParameters);
    tokens[path] = token;
    if (failures.contains(path)) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionTimeout,
      );
    }
    final payload = path == '/api/v1/subscribe/'
        ? subscribes
        : payloads[path] ?? <dynamic>[];
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: payload as T?,
      statusCode: statuses[path] ?? 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAppService extends GetxService implements AppService {
  bool subscribeAllowed = true;

  @override
  Future<void> onInit() async {
    super.onInit();
  }

  @override
  bool get canSubscribe => subscribeAllowed;
  @override
  bool get canManage => false;
  @override
  bool get isSuperuser => true;
  @override
  LoginResponse? get loginResponse => null;
  @override
  UserInfo? get userInfo => null;
  @override
  String? get latestLoginProfileAccessToken => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _subscription(int id, {String type = '电视剧'}) => {
  'tmdbid': id,
  'name': '剧集 $id',
  'type': type,
  'season': 1,
  'poster': 'https://image.test/$id.jpg',
};

Map<String, dynamic> _episode(String date, {int number = 1}) => {
  'air_date': date,
  'episode_number': number,
  'season_number': 1,
};

void main() {
  late _FakeApiClient api;
  late _FakeAppService app;
  late MultifunctionController controller;

  setUp(() {
    api = _FakeApiClient();
    app = _FakeAppService();
    Get.put<ApiClient>(api);
    Get.put<AppService>(app);
    Get.put<AppLog>(AppLog());
    // 控制器构造函数 Get.find 该服务（音乐库入口判定）
    Get.put<ServerApiVersionService>(ServerApiVersionService(apiClient: api));
    controller = MultifunctionController(
      now: () => DateTime(2026, 10, 16, 0, 30),
      debugCalendarMock: false,
    );
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  for (final now in [DateTime(2026, 10, 31), DateTime(2026, 12, 31)]) {
    test(
      'debug hook provides relative dates across $now without requests',
      () async {
        controller = MultifunctionController(
          now: () => now,
          debugCalendarMock: true,
        );

        await controller.refreshSubscribeSection();

        expect(controller.isCalendarMockEnabled, isTrue);
        expect(controller.subscribeInfo.value.tvCount, 13);
        expect(controller.calendarInfo.value.todayCount, 2);
        expect(controller.calendarInfo.value.weekCount, 4);
        expect(
          controller.calendarInfo.value.todayItems.map((item) => item.showName),
          contains('测试剧集 · 第13条订阅'),
        );
        final lastDate = DateTime(now.year, now.month, now.day + 6);
        expect(
          controller.calendarInfo.value.weekItems.last.airDate,
          lastDate.toIso8601String().split('T').first,
        );
        expect(controller.calendarError.value, isNull);
        expect(api.paths, isEmpty);
      },
    );
  }

  test('debug hook retains permission checks', () async {
    controller = MultifunctionController(debugCalendarMock: true);
    app.subscribeAllowed = false;

    await controller.refreshSubscribeSection();

    expect(controller.calendarDataReady.value, isFalse);
    expect(controller.calendarInfo.value.weekItems, isEmpty);
    expect(api.paths, isEmpty);
  });

  test('debug hook does not intercept unrelated requests', () async {
    final hook = DashboardCalendarDebugApi(
      client: api,
      now: DateTime.now,
      enabled: true,
    );
    await hook.get(
      '/api/v1/tmdb/42/2',
      token: 'forwarded-token',
      queryParameters: {'episode_group': 'group'},
    );

    expect(api.paths, ['/api/v1/tmdb/42/2']);
    expect(api.tokens.values.single, 'forwarded-token');
    expect(api.queries.values.single, {'episode_group': 'group'});
  });

  test(
    'debug hook returns fresh subscription fixtures for current user',
    () async {
      final hook = DashboardCalendarDebugApi(
        client: api,
        now: DateTime.now,
        enabled: true,
      );
      final first = await hook.get('/api/v1/subscribe/', username: 'test-user');
      final items = first.data as List;
      expect(items.every((item) => item['username'] == 'test-user'), isTrue);
      items.first['poster'] = 'changed';
      final second = await hook.get(
        '/api/v1/subscribe/',
        username: 'test-user',
      );

      expect((second.data as List).first['poster'], isEmpty);
      expect(api.paths, isEmpty);
    },
  );

  test(
    'loads releases after the twelfth subscription and accepts 剧集',
    () async {
      api.subscribes = List.generate(
        13,
        (i) => _subscription(i + 1, type: '剧集'),
      );
      api.payloads['/api/v1/tmdb/13/1'] = [_episode('2026-10-16')];

      await controller.refreshDashboard();

      expect(controller.calendarDataReady.value, isTrue);
      expect(controller.calendarInfo.value.todayCount, 1);
      expect(controller.calendarInfo.value.todayItems.single.showName, '剧集 13');
      expect(
        api.paths.where((path) => path.startsWith('/api/v1/tmdb/')),
        hasLength(13),
      );
      expect(controller.calendarError.value, isNull);
    },
  );

  test(
    'isolates network and HTTP failures without discarding successful shows',
    () async {
      api.subscribes = [_subscription(1), _subscription(2), _subscription(3)];
      api.failures.add('/api/v1/tmdb/1/1');
      api.statuses['/api/v1/tmdb/2/1'] = 503;
      api.payloads['/api/v1/tmdb/3/1'] = [_episode('2026-10-16')];

      await controller.refreshDashboard();

      expect(controller.calendarDataReady.value, isTrue);
      expect(controller.calendarInfo.value.todayItems.single.showName, '剧集 3');
      expect(controller.calendarError.value, contains('部分'));
    },
  );

  test(
    'uses local today, includes today in seven-day window, and bounds previews only',
    () async {
      api.subscribes = [_subscription(1)];
      api.payloads['/api/v1/tmdb/1/1'] = [
        _episode('2026-10-15'),
        for (var i = 1; i <= 5; i++) _episode('2026-10-16', number: i),
        _episode('2026-10-22', number: 6),
        _episode('2026-10-23', number: 7),
        _episode('', number: 8),
      ];

      await controller.refreshSubscribeSection();

      expect(controller.calendarInfo.value.todayCount, 5);
      expect(controller.calendarInfo.value.weekCount, 6);
      expect(controller.calendarInfo.value.todayItems, hasLength(3));
      expect(controller.calendarInfo.value.weekItems, hasLength(4));
      expect(
        controller.calendarInfo.value.weekItems.first.airDate,
        '2026-10-16',
      );
      expect(
        controller.calendarInfo.value.todayItems.first.poster,
        'https://image.test/1.jpg',
      );
    },
  );

  test(
    'normalizes V3 identity and forwards episode group with authentication',
    () async {
      api.subscribes = [
        {
          ..._subscription(1),
          'tmdbid': null,
          'media_source': 'themoviedb',
          'media_id': '42',
          'season': 2,
          'episode_group': 'custom-group',
        },
      ];
      api.payloads['/api/v1/tmdb/42/2'] = {
        'data': [_episode('2026-10-16')],
      };

      await controller.refreshSubscribeSection();

      expect(controller.calendarInfo.value.todayCount, 1);
      expect(api.queries['/api/v1/tmdb/42/2'], {
        'episode_group': 'custom-group',
      });
      expect(api.tokens['/api/v1/tmdb/42/2'], 'test-token');
    },
  );

  test(
    'deduplicates seasons, skips missing IDs, and defaults missing seasons',
    () async {
      api.subscribes = [
        _subscription(0),
        _subscription(1),
        {..._subscription(1), 'season': null},
        _subscription(2, type: '电影'),
      ];
      api.payloads['/api/v1/tmdb/1/1'] = [_episode('2026-10-16')];

      await controller.refreshSubscribeSection();

      expect(controller.calendarInfo.value.todayCount, 1);
      expect(api.paths.where((path) => path.startsWith('/api/v1/tmdb/')), [
        '/api/v1/tmdb/1/1',
      ]);
    },
  );

  test(
    'keeps previous calendar on total failure and clears error after recovery',
    () async {
      api.subscribes = [_subscription(1)];
      api.payloads['/api/v1/tmdb/1/1'] = [_episode('2026-10-16')];
      await controller.refreshSubscribeSection();
      final previous = controller.calendarInfo.value;

      api.failures.add('/api/v1/tmdb/1/1');
      await controller.refreshSubscribeSection();
      expect(controller.calendarInfo.value, same(previous));
      expect(controller.calendarDataReady.value, isTrue);
      expect(controller.calendarError.value, isNotNull);

      api.failures.clear();
      await controller.refreshSubscribeSection();
      expect(controller.calendarError.value, isNull);
      expect(controller.calendarInfo.value.todayCount, 1);
    },
  );

  test(
    'does not mark initial total failure as an empty successful calendar',
    () async {
      api.subscribes = [_subscription(1)];
      api.payloads['/api/v1/tmdb/1/1'] = {'unexpected': 'response'};

      await controller.refreshDashboard();

      expect(controller.calendarDataReady.value, isFalse);
      expect(controller.calendarError.value, isNotNull);
    },
  );

  test(
    'reports subscription failure and preserves existing calendar',
    () async {
      api.subscribes = [_subscription(1)];
      api.payloads['/api/v1/tmdb/1/1'] = [_episode('2026-10-16')];
      await controller.refreshSubscribeSection();
      final previous = controller.calendarInfo.value;
      api.statuses['/api/v1/subscribe/'] = 503;

      await controller.refreshDashboard();

      expect(controller.calendarInfo.value, same(previous));
      expect(controller.calendarError.value, isNotNull);
    },
  );

  test(
    'empty subscriptions clear stale releases as a successful empty result',
    () async {
      api.subscribes = [_subscription(1)];
      api.payloads['/api/v1/tmdb/1/1'] = [_episode('2026-10-16')];
      await controller.refreshSubscribeSection();
      api.subscribes = [];

      await controller.refreshSubscribeSection();

      expect(controller.calendarInfo.value.todayItems, isEmpty);
      expect(controller.calendarInfo.value.weekCount, 0);
      expect(controller.calendarDataReady.value, isTrue);
      expect(controller.calendarError.value, isNull);
    },
  );

  test(
    'permission removal clears calendar without requesting subscriptions',
    () async {
      api.subscribes = [_subscription(1)];
      api.payloads['/api/v1/tmdb/1/1'] = [_episode('2026-10-16')];
      await controller.refreshSubscribeSection();
      app.subscribeAllowed = false;
      api.paths.clear();

      await controller.refreshSubscribeSection();

      expect(controller.calendarInfo.value.todayItems, isEmpty);
      expect(controller.calendarDataReady.value, isFalse);
      expect(controller.calendarError.value, isNull);
      expect(api.paths, isEmpty);
    },
  );

  test(
    'keeps per-category subscribe posters instead of truncating globally',
    () async {
      api.subscribes = [
        for (var i = 1; i <= 10; i++) _subscription(i, type: '电影'),
        _subscription(11, type: '电视剧'),
        _subscription(12, type: '音乐'),
      ];

      await controller.refreshSubscribeSection();

      final items = controller.subscribeInfo.value.posterItems;
      expect(items.where((e) => e.route == '/subscribe-movie'), hasLength(3));
      expect(items.where((e) => e.route == '/subscribe-tv'), hasLength(1));
      expect(items.where((e) => e.route == '/subscribe-music'), hasLength(1));
    },
  );

  test(
    'falls back to backdrop when the subscription poster is empty',
    () async {
      api.subscribes = [
        {
          ..._subscription(1),
          'poster': '',
          'backdrop': 'https://image.test/1-backdrop.jpg',
        },
      ];

      await controller.refreshSubscribeSection();

      final item = controller.subscribeInfo.value.posterItems.single;
      expect(item.poster, 'https://image.test/1-backdrop.jpg');
      expect(
        api.paths.where((path) => path == '/api/v1/media/search'),
        isEmpty,
      );
    },
  );

  test(
    'backfills missing covers for every subscribe category',
    () async {
      api.subscribes = [
        for (var i = 1; i <= 10; i++)
          {..._subscription(i, type: '音乐'), 'poster': ''},
        {..._subscription(11, type: '电视剧'), 'poster': ''},
      ];
      api.payloads['/api/v1/media/search'] = [
        {
          'type': '音乐',
          'title': '另一个专辑',
          'cover_url': 'https://cover.test/music.jpg',
        },
        {
          'type': '电视剧',
          'title': '另一个剧集',
          'poster': 'https://cover.test/tv.jpg',
        },
      ];

      await controller.refreshSubscribeSection();
      await _waitFor(
        () =>
            controller.subscribeInfo.value.posterItems.any(
              (e) => e.route == '/subscribe-music',
            ) &&
            controller.subscribeInfo.value.posterItems.any(
              (e) => e.route == '/subscribe-tv',
            ),
        reason: '分类封面补齐未完成',
      );

      final items = controller.subscribeInfo.value.posterItems;
      final music = items.where((e) => e.route == '/subscribe-music').toList();
      final tv = items.where((e) => e.route == '/subscribe-tv').toList();
      // 每个分类各自最多补 3 条：音乐不会把剧集的补齐名额占光。
      expect(music, hasLength(3));
      expect(
        music.every((e) => e.poster == 'https://cover.test/music.jpg'),
        isTrue,
      );
      expect(tv, hasLength(1));
      expect(tv.single.poster, 'https://cover.test/tv.jpg');
      final musicQuery = api.queryLog.firstWhere(
        (query) => query?['type'] == 'music',
      );
      expect(musicQuery?['count'], 6);
    },
  );
}

Future<void> _waitFor(
  bool Function() condition, {
  String reason = 'condition not met in time',
}) async {
  for (var i = 0; i < 200; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail(reason);
}
