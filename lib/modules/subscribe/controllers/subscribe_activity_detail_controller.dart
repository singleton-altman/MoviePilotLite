// 订阅活动详情控制器：按 event_id 拉取完整活动明细。

import 'dart:async';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_execution_repository.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_execution_models.dart';

class SubscribeActivityDetailController extends GetxController {
  SubscribeActivityDetailController({
    required this.subscribeId,
    required this.eventId,
    this.history = false,
    SubscribeExecutionRepository? repository,
  }) : _repository = repository ?? SubscribeExecutionRepository();

  final int subscribeId;
  final String eventId;
  final bool history;

  final SubscribeExecutionRepository _repository;
  final _log = Get.find<AppLog>();

  final event = Rxn<SubscriptionActivityEvent>();
  final isLoading = false.obs;
  final errorText = RxnString();

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    if (subscribeId <= 0 || eventId.isEmpty) {
      errorText.value = '无效的活动标识';
      return;
    }
    isLoading.value = true;
    errorText.value = null;
    try {
      event.value = await _repository.fetchActivityEvent(
        subscribeId,
        eventId,
        history: history,
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取活动详情失败');
      errorText.value = e is StateError ? e.message : '详情加载失败，请重试';
    } finally {
      isLoading.value = false;
    }
  }
}
