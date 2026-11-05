import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_controller.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/modules/download/widgets/download_sheet.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_source.dart';
import 'package:moviepilot_mobile/modules/tmdb/controllers/tmdb_collection_controller.dart';
import 'package:moviepilot_mobile/modules/tmdb/pages/tmdb_collection_page.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/user_config_service.dart';

class _FakeApiClient extends GetxService implements ApiClient {
  dynamic payload;
  int status = 200;
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  Object? lastBody;
  bool? skipUnwrap;
  int getCalls = 0;
  @override
  String? get baseUrl => 'https://moviepilot.test';

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
    getCalls++;
    lastPath = path;
    lastQuery = queryParameters;
    skipUnwrap = skipV3EnvelopeUnwrap;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: payload as T?,
      statusCode: status,
    );
  }

  @override
  Future<Response<T>> postJson<T>(
    String path,
    Object? data, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) async {
    lastPath = path;
    lastBody = data;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: payload as T?,
      statusCode: status,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestAppService extends AppService {
  @override
  // Keep unit tests independent of device preference/plugin initialization.
  // ignore: must_call_super
  Future<void> onInit() async {}
  @override
  bool get canDiscovery => false;
}

class _FakeAuthRepository extends GetxService implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestRecommendController extends RecommendController {
  @override
  // Initialization is exercised explicitly rather than starting background fetches.
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  testWidgets(
    'recommendation controller adds plugin sources without replacing defaults and writes real source visibility preferences',
    (tester) async {
      final api = _FakeApiClient()
        ..payload = [
          {
            'name': '插件电影',
            'api_path': '/api/v1/plugin/Example/list',
            'type': '电影',
          },
          {
            'name': '正在热映',
            'api_path': '/api/v1/plugin/Override/list',
            'type': '电影',
          },
        ];
      Get.put<ApiClient>(api);
      Get.put<AppService>(_TestAppService());
      Get.put<AppLog>(AppLog());
      Get.put<AuthRepository>(_FakeAuthRepository());
      final controller = _TestRecommendController();
      addTearDown(() async {
        controller.onClose();
        Get.reset();
      });
      final defaults = controller.allVisibleSubCategories.toList();
      expect(defaults.length, 13);
      await controller.reloadSources();
      expect(controller.allVisibleSubCategories, [
        ...defaults.take(4),
        '插件电影',
        ...defaults.skip(4),
      ]);
      expect(controller.keyForSubCategory('正在热映'), 'douban_showing');
      expect(
        controller.keyForSubCategory('插件电影'),
        '/api/v1/plugin/Example/list',
      );
      api.payload = {'success': true};
      controller.setSubCategoryVisibility(
        RecommendCategory.movie,
        '插件电影',
        false,
      );
      await tester.pumpAndSettle();
      expect(controller.allVisibleSubCategories, defaults);
      expect(
        api.lastPath,
        '/api/v1/user/config/MoviePilotMobile.RecommendSources',
      );
      expect(
        (api.lastBody as Map)['hiddenSubCategoryKeys'],
        contains('movie::插件电影'),
      );
      expect(controller.preferenceSyncError.value, isNull);
    },
  );
  group('per-user preferences contract', () {
    test(
      'reads V2 and V3 data.value without changing false, null or arrays',
      () async {
        final api = _FakeApiClient();
        final service = UserConfigService(apiClient: api);
        for (final value in [
          null,
          false,
          ['plugin'],
          {'hidden': true},
        ]) {
          api.payload = {
            'success': true,
            'data': {'value': value},
          };
          expect(await service.read('mobile preferences'), value);
          expect(api.lastPath, '/api/v1/user/config/mobile%20preferences');
          expect(api.skipUnwrap, true);
        }
      },
    );

    test('writes the raw preference value, not a value wrapper', () async {
      final api = _FakeApiClient()..payload = {'success': true};
      final service = UserConfigService(apiClient: api);
      for (final value in [
        false,
        ['one'],
        {
          'hidden': ['two'],
        },
        null,
      ]) {
        await service.write('Mobile.RecommendSources', value);
        expect(api.lastBody, value);
      }
    });

    test('has no cross-account preference cache', () async {
      final api = _FakeApiClient()
        ..payload = {
          'success': true,
          'data': {'value': 'alice'},
        };
      final service = UserConfigService(apiClient: api);
      expect(await service.read('key'), 'alice');
      api.payload = {
        'success': true,
        'data': {'value': 'bob'},
      };
      expect(await service.read('key'), 'bob');
      expect(api.getCalls, 2);
    });

    test(
      'rejects HTTP and business failures and malformed successful reads',
      () async {
        final api = _FakeApiClient()..status = 403;
        final service = UserConfigService(apiClient: api);
        await expectLater(
          service.read('key'),
          throwsA(isA<ApiHttpException>()),
        );
        api.status = 200;
        api.payload = {'success': false, 'message': 'denied'};
        await expectLater(service.write('key', true), throwsStateError);
        api.payload = {'success': true, 'data': {}};
        await expectLater(service.read('key'), throwsFormatException);
      },
    );
  });

  group('additional recommendation sources', () {
    final sources = [
      {
        'name': '插件电影',
        'api_path': '/api/v1/plugin/Example/list?kind=movie',
        'type': '电影',
      },
      {
        'name': '重复路径',
        'api_path': '/api/v1/plugin/Example/list?kind=movie',
        'type': '电影',
      },
      {'name': '外部地址', 'api_path': 'https://evil.test/list', 'type': '电影'},
      {'name': '坏数据'},
    ];

    test(
      'parses bare V2 and enveloped V3 source arrays and skips unsafe entries',
      () {
        for (final body in [
          sources,
          {'success': true, 'data': sources},
        ]) {
          final parsed = RecommendSource.parse(body);
          expect(parsed.length, 1);
          expect(parsed.single.name, '插件电影');
          expect(parsed.single.type, '电影');
          expect(
            parsed.single.apiPath,
            '/api/v1/plugin/Example/list?kind=movie',
          );
        }
      },
    );

    test('preserves legacy built-in keys and plugin queries', () {
      expect(
        RecommendSource.resolveApiPath(
          'tmdb_tvs?with_original_language=zh|en|ja|ko',
        ),
        '/api/v1/recommend/tmdb_tvs?with_original_language=zh|en|ja|ko',
      );
      expect(
        RecommendSource.resolveApiPath('api/v1/plugin/Source/list'),
        '/api/v1/plugin/Source/list',
      );
      expect(
        RecommendSource.resolveApiPath('recommend/custom?tag=movie'),
        '/api/v1/recommend/custom?tag=movie',
      );
      expect(
        RecommendSource.resolveApiPath('plugin/Example/list'),
        '/api/v1/plugin/Example/list',
      );
      expect(RecommendSource.parse([]), isEmpty);
    });

    test(
      'rejects cross-origin and traversal paths before using bearer client',
      () {
        for (final path in [
          '//evil.test/data',
          'http://evil.test/data',
          '/api/v1/../secret',
          '/api/v1/%2e%2e/secret',
          '/only',
          'list#fragment',
        ]) {
          expect(
            () => RecommendSource.resolveApiPath(path),
            throwsFormatException,
          );
        }
      },
    );

    test('requests exact source operation and propagates errors', () async {
      final api = _FakeApiClient()..payload = sources;
      expect(await RecommendSourceService(apiClient: api).load(), hasLength(1));
      expect(api.lastPath, '/api/v1/recommend/source');
      expect(api.lastQuery, isNull);
      api.status = 404;
      await expectLater(
        RecommendSourceService(apiClient: api).load(),
        throwsA(isA<ApiHttpException>()),
      );
    });
  });

  group('download paths', () {
    test(
      'keeps opaque save_path and only falls back to local download_path',
      () {
        final parsed = DownloadPathOption.parse({
          'success': true,
          'data': [
            {
              'name': '远程电影',
              'storage': 'rclone',
              'save_path': 'rclone:/movies',
              'download_path': '/wrong',
            },
            {'name': '本地', 'storage': 'local', 'download_path': '/downloads'},
            {'name': '重复', 'save_path': '/downloads'},
            {
              'name': '不可用远程',
              'storage': 'alist',
              'download_path': '/not-local',
            },
          ],
        });
        expect(parsed.map((option) => option.savePath), [
          'rclone:/movies',
          '/downloads',
        ]);
        expect(parsed.first.label, '远程电影');
      },
    );

    testWidgets('actual picker requests paths and selection is optional', (
      tester,
    ) async {
      final api = _FakeApiClient()
        ..payload = [
          {'name': '服务器电影目录', 'save_path': 'local:/movies'},
        ];
      final selected = ''.obs;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadPathPicker(
              apiClient: api,
              selectedPath: selected,
              onSelected: (value) => selected.value = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.lastPath, '/api/v1/download/paths');
      expect(selected.value, '');
      await tester.tap(find.text('服务器电影目录'));
      await tester.pump();
      expect(selected.value, 'local:/movies');
      await tester.tap(find.text('服务器电影目录'));
      await tester.pump();
      expect(selected.value, '');
    });

    testWidgets(
      'failure preserves existing selection and offers a working retry',
      (tester) async {
        final api = _FakeApiClient()..status = 500;
        final selected = '/existing'.obs;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DownloadPathPicker(
                apiClient: api,
                selectedPath: selected,
                onSelected: (value) => selected.value = value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(selected.value, '/existing');
        api.status = 200;
        api.payload = [
          {'name': '恢复目录', 'save_path': '/recovered'},
        ];
        await tester.tap(find.text('重试'));
        await tester.pumpAndSettle();
        expect(find.text('恢复目录'), findsOneWidget);
        expect(selected.value, '/existing');
      },
    );
  });

  group('TMDB collections', () {
    Map<String, dynamic> movie(int id) => {
      'title': '电影 $id',
      'tmdb_id': id,
      'type': '电影',
    };

    test(
      'uses collection ID plus explicit page/count for V2 and V3 responses',
      () async {
        final api = _FakeApiClient();
        for (final payload in [
          [movie(1)],
          {
            'success': true,
            'data': [movie(1)],
          },
        ]) {
          api.payload = payload;
          final result = await TmdbCollectionService(
            apiClient: api,
          ).load(10, page: 2, count: 20);
          expect(result.single.tmdb_id, '1');
          expect(api.lastPath, '/api/v1/tmdb/collection/10');
          expect(api.lastQuery, {'page': 2, 'count': 20});
        }
      },
    );

    test(
      'paginates, retains content on failure, retries the same page and refreshes',
      () async {
        final api = _FakeApiClient()..payload = List.generate(20, movie);
        final controller = TmdbCollectionController(
          collectionId: 10,
          service: TmdbCollectionService(apiClient: api),
        );
        await controller.load();
        expect(controller.items, hasLength(20));
        expect(controller.hasMore, true);
        api.status = 502;
        await controller.load();
        expect(controller.items, hasLength(20));
        expect(controller.error, isNotNull);
        api.status = 200;
        api.payload = [movie(21)];
        await controller.load();
        expect(api.lastQuery?['page'], 2);
        expect(controller.items, hasLength(21));
        expect(controller.hasMore, false);
        api.payload = [];
        await controller.load(refresh: true);
        expect(api.lastQuery?['page'], 1);
        expect(controller.items, isEmpty);
        controller.dispose();
      },
    );

    testWidgets('collection page has app bar, empty, error and retry states', (
      tester,
    ) async {
      final api = _FakeApiClient()..status = 500;
      await tester.pumpWidget(
        MaterialApp(
          home: TmdbCollectionPage(
            collectionId: 10,
            service: TmdbCollectionService(apiClient: api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      api.status = 200;
      api.payload = [];
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('暂无合集影片'), findsOneWidget);
    });
  });
}
