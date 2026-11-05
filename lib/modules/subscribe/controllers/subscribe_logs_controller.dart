// 订阅运行日志控制器：长度切换（100/600/全部）与手动刷新。

import 'dart:async';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_execution_repository.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

class SubscribeLogsController extends GetxController {
  SubscribeLogsController({
    required this.subscribeId,
    this.subscribeTitle = '',
    SubscribeExecutionRepository? repository,
    Future<bool> Function()? detectV3,
  }) : _repository = repository ?? SubscribeExecutionRepository(),
       _detectV3 = detectV3;

  final int subscribeId;
  final String subscribeTitle;

  final SubscribeExecutionRepository _repository;
  final Future<bool> Function()? _detectV3;

  final _log = Get.find<AppLog>();

  /// 服务端长度取值：默认 100，可选 600，-1 为全部
  static const List<int> lengthOptions = <int>[100, 600, -1];

  final selectedLength = 100.obs;
  final content = ''.obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  /// v3 能力门控：v2 下页面展示不支持提示，不发出任何 v3 专有请求
  final v3Supported = true.obs;

  int _requestId = 0;

  bool get isEmpty => !isLoading.value && errorText.value == null && content.value.isEmpty;

  String get pageTitle {
    final name = subscribeTitle.trim();
    return name.isNotEmpty ? name : '运行日志';
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
  }

  void setLength(int length) {
    if (!lengthOptions.contains(length) || selectedLength.value == length) {
      return;
    }
    selectedLength.value = length;
    unawaited(reload());
  }

  Future<void> reload() async {
    if (subscribeId <= 0) {
      errorText.value = '无效的订阅 ID';
      return;
    }
    final requestId = ++_requestId;
    isLoading.value = true;
    errorText.value = null;
    try {
      final text = await _repository.fetchLogs(
        subscribeId,
        length: selectedLength.value,
      );
      if (requestId != _requestId) return;
      content.value = text;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取订阅运行日志失败');
      if (requestId == _requestId) {
        errorText.value = e is StateError ? e.message : '日志加载失败，请重试';
      }
    } finally {
      if (requestId == _requestId) {
        isLoading.value = false;
      }
    }
  }
}
