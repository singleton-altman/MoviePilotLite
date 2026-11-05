// 订阅活动记录控制器：kind 筛选、history 开关、游标分页与进行中批次横幅。

import 'dart:async';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_execution_repository.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_execution_models.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class SubscribeActivityController extends GetxController {
  SubscribeActivityController({
    required this.subscribeId,
    this.subscribeTitle = '',
    SubscribeExecutionRepository? repository,
    Future<bool> Function()? detectV3,
  }) : _repository =
           repository ?? SubscribeExecutionRepository(),
       _detectV3 = detectV3;

  final int subscribeId;
  final String subscribeTitle;

  final SubscribeExecutionRepository _repository;
  final Future<bool> Function()? _detectV3;

  final _log = Get.find<AppLog>();

  final items = <SubscriptionActivityEvent>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorText = RxnString();
  final nextCursor = RxnString();
  bool _requestId = false;

  /// 筛选条件；null 表示全部事件
  final kind = RxnString();
  final history = false.obs;

  /// v3 能力门控：v2 下页面展示不支持提示，不发出任何 v3 专有请求
  final v3Supported = true.obs;

  /// 进行中的搜索批次（无活跃批次时为 null，横幅隐藏）
  final batch = Rxn<SubscriptionBatchStatus>();
  final batchLoading = false.obs;
  final cancellingBatch = false.obs;

  static const int pageSize = 30;

  bool get hasMore => nextCursor.value != null;

  String get pageTitle {
    final name = subscribeTitle.trim();
    return name.isNotEmpty ? name : '活动记录';
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(init());
  }

  Future<void> init() async {
    final supported = _detectV3 != null
        ? await _detectV3()
        : await Get.find<ServerApiVersionService>().isV3();
    v3Supported.value = supported;
    if (!supported) return;
    unawaited(reload());
    unawaited(loadBatch());
  }

  void setKind(String? value) {
    if (kind.value == value) return;
    kind.value = value;
    unawaited(reload());
  }

  void toggleHistory() {
    history.value = !history.value;
    unawaited(reload());
  }

  /// 首屏/筛选变化后重载
  Future<void> reload() async {
    if (subscribeId <= 0) {
      errorText.value = '无效的订阅 ID';
      return;
    }
    final requestId = _requestId = !_requestId;
    isLoading.value = true;
    errorText.value = null;
    try {
      final page = await _repository.fetchActivity(
        subscribeId,
        history: history.value,
        kind: kind.value,
      );
      if (requestId != _requestId) return;
      items.value = page.items;
      nextCursor.value = page.nextCursor;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取订阅活动失败');
      if (requestId == _requestId) {
        errorText.value = e is StateError ? e.message : '活动加载失败，请重试';
      }
    } finally {
      if (requestId == _requestId) {
        isLoading.value = false;
      }
    }
  }

  /// 游标加载下一页
  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore.value || isLoading.value) return;
    final cursor = nextCursor.value;
    if (cursor == null) return;
    final requestId = _requestId;
    isLoadingMore.value = true;
    try {
      final page = await _repository.fetchActivity(
        subscribeId,
        history: history.value,
        kind: kind.value,
        before: cursor,
      );
      if (requestId != _requestId) return;
      final known = items.map((e) => e.eventId).toSet();
      items.addAll(page.items.where((e) => !known.contains(e.eventId)));
      nextCursor.value = page.nextCursor;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载更多订阅活动失败');
      ToastUtil.error('加载更多失败，请重试');
    } finally {
      if (requestId == _requestId) {
        isLoadingMore.value = false;
      }
    }
  }

  /// 拉取最近批次，仅保留活跃批次用于横幅展示
  Future<void> loadBatch() async {
    if (subscribeId <= 0) return;
    batchLoading.value = true;
    try {
      final batches = await _repository.fetchBatches();
      final active = batches.where((b) => b.isActive).toList();
      batch.value = active.isEmpty ? null : active.first;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取搜索批次失败');
    } finally {
      batchLoading.value = false;
    }
  }

  /// 停止进行中的一轮搜索
  Future<void> cancelRunningBatch() async {
    final target = batch.value;
    if (target == null || !target.canCancel || cancellingBatch.value) return;
    cancellingBatch.value = true;
    try {
      final result = await _repository.cancelBatch(target.batchId);
      if (result.ok) {
        ToastUtil.success(result.message);
      } else {
        ToastUtil.error(result.message);
      }
    } finally {
      cancellingBatch.value = false;
    }
    unawaited(loadBatch());
  }
}
