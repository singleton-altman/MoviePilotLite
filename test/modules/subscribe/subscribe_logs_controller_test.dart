import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_execution_repository.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_logs_controller.dart';

class _LogCall {
  _LogCall(this.subscribeId, this.length);
  final int subscribeId;
  final int length;
}

/// 只实现控制器用到的接口，其余经 noSuchMethod 显式失败
class _Repo implements SubscribeExecutionRepository {
  final logCalls = <_LogCall>[];
  String Function(_LogCall call) onLogs = (_) => '';

  @override
  Future<String> fetchLogs(int subscribeId, {required int length}) async {
    final call = _LogCall(subscribeId, length);
    logCalls.add(call);
    return onLogs(call);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.put(AppLog());
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> pumpHarness(WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
  }

  testWidgets('v2 服务端不请求日志', (tester) async {
    await pumpHarness(tester);
    final repo = _Repo();
    Get.put(
      SubscribeLogsController(
        subscribeId: 5,
        repository: repo,
        detectV3: () async => false,
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<SubscribeLogsController>();
    expect(repo.logCalls, isEmpty);
    expect(controller.v3Supported.value, isFalse);
  });

  testWidgets('默认拉取最近 100 行，切换 600/全部时按长度重新拉取', (tester) async {
    await pumpHarness(tester);
    final repo = _Repo()..onLogs = (c) => 'log-${c.length}';
    Get.put(
      SubscribeLogsController(
        subscribeId: 5,
        repository: repo,
        detectV3: () async => true,
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<SubscribeLogsController>();
    expect(controller.selectedLength.value, 100);
    expect(repo.logCalls.single.length, 100);
    expect(controller.content.value, 'log-100');

    controller.setLength(600);
    await tester.pumpAndSettle();
    expect(repo.logCalls.last.length, 600);
    expect(controller.content.value, 'log-600');

    controller.setLength(-1);
    await tester.pumpAndSettle();
    expect(repo.logCalls.last.length, -1);

    // 非法长度被忽略，不触发请求
    final calls = repo.logCalls.length;
    controller.setLength(50);
    await tester.pumpAndSettle();
    expect(repo.logCalls.length, calls);

    // 重复选择当前长度不重复请求
    controller.setLength(-1);
    await tester.pumpAndSettle();
    expect(repo.logCalls.length, calls);
  });

  testWidgets('请求失败时透出错误文案，重试可恢复', (tester) async {
    await pumpHarness(tester);
    var fail = true;
    final repo = _Repo()
      ..onLogs = (c) {
        if (fail) throw StateError('获取运行日志失败 (HTTP 404)');
        return '恢复后的日志';
      };
    Get.put(
      SubscribeLogsController(
        subscribeId: 5,
        repository: repo,
        detectV3: () async => true,
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<SubscribeLogsController>();
    expect(controller.errorText.value, '获取运行日志失败 (HTTP 404)');
    expect(controller.content.value, isEmpty);

    fail = false;
    await controller.reload();
    await tester.pumpAndSettle();
    expect(controller.errorText.value, isNull);
    expect(controller.content.value, '恢复后的日志');
  });

  testWidgets('无效订阅 ID 不发请求', (tester) async {
    await pumpHarness(tester);
    final repo = _Repo();
    Get.put(
      SubscribeLogsController(
        subscribeId: 0,
        repository: repo,
        detectV3: () async => true,
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<SubscribeLogsController>();
    expect(repo.logCalls, isEmpty);
    expect(controller.errorText.value, '无效的订阅 ID');
  });
}
