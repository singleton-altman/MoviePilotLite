import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_activity_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_execution_repository.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_execution_models.dart';

class _ActivityCall {
  _ActivityCall(this.history, this.kind, this.before, this.limit);
  final bool history;
  final String? kind;
  final String? before;
  final int limit;
}

SubscriptionActivityEvent _event(String id, {String status = 'completed'}) =>
    SubscriptionActivityEvent(
      eventId: id,
      kind: 'search',
      source: 'user',
      status: status,
      startedAt: '2026-10-21T08:00:00Z',
    );

/// 只实现控制器用到的接口，其余经 noSuchMethod 显式失败
class _Repo implements SubscribeExecutionRepository {
  final activityCalls = <_ActivityCall>[];
  final cancelCalls = <String>[];
  List<SubscriptionActivityEvent> Function(_ActivityCall call) onActivity =
      (_) => <SubscriptionActivityEvent>[];
  List<SubscriptionBatchStatus> batches = <SubscriptionBatchStatus>[];
  int batchFetches = 0;

  @override
  Future<SubscriptionActivityPage> fetchActivity(
    int subscribeId, {
    required bool history,
    String? kind,
    String? before,
    int limit = 30,
  }) async {
    final call = _ActivityCall(history, kind, before, limit);
    activityCalls.add(call);
    return SubscriptionActivityPage(
      items: onActivity(call),
      nextCursor: before == null ? 'cursor-2' : null,
    );
  }

  @override
  Future<List<SubscriptionBatchStatus>> fetchBatches({int limit = 10}) async {
    batchFetches++;
    return batches;
  }

  @override
  Future<({bool ok, String message})> cancelBatch(String batchId) async {
    cancelCalls.add(batchId);
    return (ok: true, message: '已请求停止');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SubscribeActivityController _controller(
  _Repo repo, {
  required bool v3,
  int subscribeId = 5,
}) {
  return SubscribeActivityController(
    subscribeId: subscribeId,
    subscribeTitle: '示例剧集',
    repository: repo,
    detectV3: () async => v3,
  );
}

void main() {
  setUp(() {
    Get.reset();
    Get.put(AppLog());
  });

  tearDown(() {
    Get.reset();
  });

  /// ToastUtil 依赖 Get 的全局 overlay，控制器用例统一挂在 GetMaterialApp 下
  Future<void> pumpHarness(WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
  }

  testWidgets('v2 服务端不发出任何 v3 专有请求', (tester) async {
    await pumpHarness(tester);
    final repo = _Repo();
    Get.put(_controller(repo, v3: false));
    await tester.pumpAndSettle();

    expect(repo.activityCalls, isEmpty);
    expect(repo.batchFetches, 0);
    final controller = Get.find<SubscribeActivityController>();
    expect(controller.v3Supported.value, isFalse);
    expect(controller.items, isEmpty);
  });

  testWidgets('首屏拉取活动与批次，筛选 kind/history 重新加载', (tester) async {
    await pumpHarness(tester);
    final repo = _Repo()..onActivity = (_) => [_event('e1'), _event('e2')];
    Get.put(_controller(repo, v3: true));
    await tester.pumpAndSettle();

    // 首屏：默认全部事件 + 非历史
    expect(repo.activityCalls, hasLength(1));
    expect(repo.activityCalls.first.history, isFalse);
    expect(repo.activityCalls.first.kind, isNull);
    expect(repo.activityCalls.first.limit, 30);
    final controller = Get.find<SubscribeActivityController>();
    expect(controller.items, hasLength(2));
    expect(controller.hasMore, isTrue);

    // kind 筛选
    controller.setKind('search');
    await tester.pumpAndSettle();
    expect(repo.activityCalls.last.kind, 'search');
    expect(repo.activityCalls.last.before, isNull);

    // history 开关
    controller.toggleHistory();
    await tester.pumpAndSettle();
    expect(repo.activityCalls.last.history, isTrue);
    expect(controller.history.value, isTrue);

    // 重复设置同 kind 不重复请求
    final callsBefore = repo.activityCalls.length;
    controller.setKind('search');
    await tester.pumpAndSettle();
    expect(repo.activityCalls.length, callsBefore);
  });

  testWidgets('游标加载更多：携带 before 并按 event_id 去重', (tester) async {
    await pumpHarness(tester);
    final repo = _Repo()
      ..onActivity = (call) => call.before == null
          ? [_event('e1'), _event('e2')]
          : [_event('e2'), _event('e3')];
    Get.put(_controller(repo, v3: true));
    await tester.pumpAndSettle();

    final controller = Get.find<SubscribeActivityController>();
    await controller.loadMore();
    await tester.pumpAndSettle();

    expect(repo.activityCalls.last.before, 'cursor-2');
    expect(controller.items.map((e) => e.eventId), ['e1', 'e2', 'e3']);
    // 第二页没有游标，hasMore 收敛
    expect(controller.hasMore, isFalse);
    // 再触发 loadMore 不发请求
    final calls = repo.activityCalls.length;
    await controller.loadMore();
    await tester.pumpAndSettle();
    expect(repo.activityCalls.length, calls);
  });

  testWidgets('批次横幅只保留活跃批次，可取消时停止并刷新', (tester) async {
    await pumpHarness(tester);
    final running = SubscriptionBatchStatus.fromJson(<String, dynamic>{
      'batch_id': 'batch-run',
      'source': 'automatic',
      'state': 'running',
      'phase': 'searching',
      'total_count': 4,
      'processed_count': 1,
      'finished_count': 0,
      'failed_count': 0,
      'cancelled_count': 0,
      'created_at': '2026-10-21T08:00:00Z',
      'updated_at': '2026-10-21T08:01:00Z',
      'can_cancel': true,
    });
    final completed = SubscriptionBatchStatus.fromJson(<String, dynamic>{
      'batch_id': 'batch-done',
      'source': 'automatic',
      'state': 'completed',
      'phase': 'completed',
      'total_count': 4,
      'processed_count': 4,
      'finished_count': 4,
      'failed_count': 0,
      'cancelled_count': 0,
      'created_at': '2026-10-21T07:00:00Z',
      'updated_at': '2026-10-21T07:10:00Z',
    });
    final repo = _Repo()..batches = [completed, running];
    Get.put(_controller(repo, v3: true));
    await tester.pumpAndSettle();

    final controller = Get.find<SubscribeActivityController>();
    expect(controller.batch.value?.batchId, 'batch-run');

    await controller.cancelRunningBatch();
    // 取消成功会弹 toast，推进假时钟让其关闭，避免遗留定时器
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(repo.cancelCalls, ['batch-run']);
    // 取消后重新拉取批次
    expect(repo.batchFetches, greaterThanOrEqualTo(2));
  });

  testWidgets('无活跃批次时横幅数据为空', (tester) async {
    await pumpHarness(tester);
    final completed = SubscriptionBatchStatus.fromJson(<String, dynamic>{
      'batch_id': 'batch-done',
      'source': 'user',
      'state': 'completed',
      'phase': 'completed',
      'total_count': 1,
      'processed_count': 1,
      'finished_count': 1,
      'failed_count': 0,
      'cancelled_count': 0,
      'created_at': '',
      'updated_at': '',
    });
    final repo = _Repo()..batches = [completed];
    Get.put(_controller(repo, v3: true));
    await tester.pumpAndSettle();

    final controller = Get.find<SubscribeActivityController>();
    expect(controller.batch.value, isNull);
  });

  testWidgets('无效订阅 ID 不发请求并提示错误', (tester) async {
    await pumpHarness(tester);
    final repo = _Repo();
    Get.put(_controller(repo, v3: true, subscribeId: 0));
    await tester.pumpAndSettle();

    final controller = Get.find<SubscribeActivityController>();
    expect(repo.activityCalls, isEmpty);
    expect(controller.errorText.value, '无效的订阅 ID');
  });
}
