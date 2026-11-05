import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/services/api_auth_failure.dart';
import 'package:moviepilot_mobile/services/api_auth_recovery.dart';

void main() {
  /// 收集恢复器的副作用，避免测试里真的弹窗与跳路由。
  late List<String> notifications;
  late int redirects;
  late int clears;
  late String route;
  late ApiAuthRecovery recovery;
  late Future<bool> Function() handler;
  late int handlerCalls;

  setUp(() {
    notifications = <String>[];
    redirects = 0;
    clears = 0;
    route = '/dashboard';
    handlerCalls = 0;
    handler = () async {
      handlerCalls++;
      return false;
    };
    recovery = ApiAuthRecovery(
      clearSession: () async => clears++,
      notify: notifications.add,
      redirectToLogin: () => redirects++,
      currentRoute: () => route,
    )..handler = () async => handler();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('403 权限不足不重登、不清会话、不跳登录页', () async {
    recovery.handle(403, {'message': '用户权限不足'});
    await settle();
    expect(handlerCalls, 0);
    expect(clears, 0);
    expect(redirects, 0);
    expect(notifications, isEmpty);
  });

  test('v2 的 401 + 用户权限不足同样不登出', () async {
    recovery.handle(401, {'detail': '用户权限不足'});
    await settle();
    expect(handlerCalls, 0);
    expect(clears, 0);
    expect(redirects, 0);
  });

  test('401 会话失效先尝试静默重登，失败才清会话并跳登录页', () async {
    recovery.handle(401, {'detail': 'Not authenticated'});
    await settle();
    expect(handlerCalls, 1);
    expect(clears, 1);
    expect(redirects, 1);
    expect(notifications, [ApiAuthFailure.sessionExpiredMessage]);
  });

  test('静默重登成功则不清理会话、不跳转、不提示', () async {
    recovery.handler = () async => true;
    recovery.handle(401);
    await settle();
    expect(clears, 0);
    expect(redirects, 0);
    expect(notifications, isEmpty);
  });

  test('重登抛异常按失败处理，仍能登出', () async {
    recovery.handler = () async => throw StateError('network');
    recovery.handle(401);
    await settle();
    expect(clears, 1);
    expect(redirects, 1);
  });

  test('并发 401 只触发一次重登与一次跳转', () async {
    final gate = Completer<bool>();
    var gateCalls = 0;
    recovery.handler = () {
      gateCalls++;
      return gate.future;
    };
    recovery.handle(401);
    recovery.handle(401);
    recovery.handle(401);
    await settle();
    expect(gateCalls, 1);
    gate.complete(false);
    await settle();
    await settle();
    expect(clears, 1);
    expect(redirects, 1);
    expect(notifications.length, 1);
  });

  test('冷却窗口内的后续 401 不重复重登', () async {
    recovery.handle(401);
    await settle();
    recovery.handle(401);
    await settle();
    expect(handlerCalls, 1);
  });

  test('已在登录页时不重登、不提示、不重复跳转', () async {
    route = '/login';
    recovery.handle(401);
    await settle();
    expect(handlerCalls, 0);
    expect(redirects, 0);
    expect(notifications, isEmpty);
  });

  test('标记 skipUnauthorizedHandling 的请求不进入处置', () async {
    recovery.maybeHandle(
      RequestOptions(extra: const {'skipUnauthorizedHandling': true}),
      401,
      {'detail': 'Not authenticated'},
    );
    await settle();
    expect(handlerCalls, 0);
    expect(redirects, 0);
  });

  test('非鉴权状态码不触发任何处置', () async {
    for (final status in [200, 400, 404, 500]) {
      recovery.handle(status);
    }
    await settle();
    expect(handlerCalls, 0);
    expect(redirects, 0);
    expect(notifications, isEmpty);
  });
}
