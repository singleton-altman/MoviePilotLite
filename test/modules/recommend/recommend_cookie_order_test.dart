import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_global_config.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// 记录请求发生顺序，用来断言 Cookie 刷新早于推荐请求。
class _OrderedApi extends GetxService implements ApiClient {
  _OrderedApi(this.events);

  final List<String> events;
  dynamic payload = const [];
  int status = 200;

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
    events.add('GET $path');
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: payload as T?,
      statusCode: status,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingAuthRepository extends GetxService implements AuthRepository {
  _RecordingAuthRepository(this.events, this.gate);

  final List<String> events;
  final Completer<void> gate;

  @override
  Future<UserGlobalConfig?> getUserGlobalConfig({
    required String server,
    required String accessToken,
  }) async {
    events.add('COOKIE start');
    await gate.future;
    events.add('COOKIE done');
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DiscoveryAppService extends AppService {
  @override
  // ignore: must_call_super
  Future<void> onInit() async {}

  @override
  bool get canDiscovery => true;

  @override
  String? get baseUrl => 'https://moviepilot.test';

  @override
  String? get latestLoginProfileAccessToken => 'token';
}

class _TestRecommendController extends RecommendController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  test('推荐请求等待 Cookie 刷新完成后才发出', () async {
    final events = <String>[];
    final gate = Completer<void>();
    final api = _OrderedApi(events);
    Get.put<ApiClient>(api);
    Get.put<AppService>(_DiscoveryAppService());
    Get.put<AppLog>(AppLog());
    Get.put<AuthRepository>(_RecordingAuthRepository(events, gate));

    final controller = _TestRecommendController();
    addTearDown(() {
      controller.onClose();
      Get.reset();
    });

    controller.prefetchAllVisibleCategories();
    // 让队列跑起来，此时 Cookie 刷新被 gate 挡住
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(events, contains('COOKIE start'));
    expect(
      events.where((event) => event.startsWith('GET ')),
      isEmpty,
      reason: 'Cookie 未就绪前不应发推荐请求',
    );

    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final cookieDoneAt = events.indexOf('COOKIE done');
    final firstGetAt = events.indexWhere((event) => event.startsWith('GET '));
    expect(firstGetAt, isNot(-1));
    expect(cookieDoneAt, lessThan(firstGetAt));
  });

  test('并发调用共享同一次 Cookie 刷新，且都等到它完成', () async {
    final events = <String>[];
    final gate = Completer<void>();
    Get.put<ApiClient>(_OrderedApi(events));
    Get.put<AppService>(_DiscoveryAppService());
    Get.put<AppLog>(AppLog());
    Get.put<AuthRepository>(_RecordingAuthRepository(events, gate));

    final controller = _TestRecommendController();
    addTearDown(() {
      controller.onClose();
      Get.reset();
    });

    var firstDone = false;
    var secondDone = false;
    final first = controller.ensureUserCookieRefreshed().then((_) {
      firstDone = true;
    });
    final second = controller.ensureUserCookieRefreshed().then((_) {
      secondDone = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(firstDone, isFalse, reason: '刷新未完成时调用方不应提前返回');
    expect(secondDone, isFalse, reason: '后到的调用方也不应被直接放过');

    gate.complete();
    await Future.wait([first, second]);

    expect(firstDone && secondDone, isTrue);
    expect(
      events.where((event) => event == 'COOKIE start').length,
      1,
      reason: '并发调用不应重复刷新 Cookie',
    );
  });
}
