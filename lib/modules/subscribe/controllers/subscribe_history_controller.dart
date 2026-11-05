import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class SubscribeHistoryEntry {
  const SubscribeHistoryEntry({required this.item, required this.raw});

  final SubscribeItem item;
  final Map<String, dynamic> raw;

  int? get completedEpisode {
    final v = raw['completed_episode'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

class SubscribeHistoryController extends GetxController {
  static const int _pageSize = 30;

  final _log = Get.find<AppLog>();
  final _subscribeService = Get.put(SubscribeService());

  late final SubscribeType subscribeType;

  final items = <SubscribeHistoryEntry>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorText = RxnString();
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SubscribeType) {
      subscribeType = args;
    } else if (args is Map && args['type'] is SubscribeType) {
      subscribeType = args['type'] as SubscribeType;
    } else {
      final route = Get.currentRoute;
      subscribeType = route.contains('movie')
          ? SubscribeType.movie
          : SubscribeType.tv;
    }
  }

  @override
  void onReady() {
    super.onReady();
    load();
  }

  bool get isTv => subscribeType == SubscribeType.tv;

  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    _page = 1;
    hasMore.value = true;
    try {
      final list = await _subscribeService.fetchSubscribeHistory(
        mtype: subscribeType.stype,
        page: _page,
        count: _pageSize,
      );
      items.assignAll(_parse(list));
      hasMore.value = list.length >= _pageSize;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载订阅历史失败');
      errorText.value = e is StateError ? e.message : '请求失败，请稍后重试';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    isLoadingMore.value = true;
    try {
      final next = _page + 1;
      final list = await _subscribeService.fetchSubscribeHistory(
        mtype: subscribeType.stype,
        page: next,
        count: _pageSize,
      );
      if (list.isEmpty) {
        hasMore.value = false;
        return;
      }
      _page = next;
      items.addAll(_parse(list));
      hasMore.value = list.length >= _pageSize;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载更多订阅历史失败');
      ToastUtil.error('加载更多失败');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> resubscribe(SubscribeHistoryEntry entry) async {
    final resp = await _subscribeService.resubscribeFromHistory(
      Map<String, dynamic>.from(entry.raw),
    );
    if (resp.success == true) {
      ToastUtil.success('${entry.item.name ?? ''} 重新订阅成功');
      await _refreshSubscribeList();
      return;
    }
    ToastUtil.error(resp.message?.trim().isNotEmpty == true
        ? resp.message!
        : '重新订阅失败');
  }

  Future<void> deleteHistory(SubscribeHistoryEntry entry) async {
    final id = entry.item.id;
    if (id == null) {
      ToastUtil.error('无效的历史记录');
      return;
    }
    final ok = await _subscribeService.deleteSubscribeHistory(id);
    if (!ok) {
      ToastUtil.error('删除失败');
      return;
    }
    items.removeWhere((e) => e.item.id == id);
    ToastUtil.success('已删除历史订阅');
  }

  Future<void> _refreshSubscribeList() async {
    if (Get.isRegistered<SubscribeController>()) {
      await Get.find<SubscribeController>().loadUserSubscribes();
    }
    if (Get.isRegistered<MultifunctionController>()) {
      await Get.find<MultifunctionController>().refreshSubscribeSection();
    }
  }

  List<SubscribeHistoryEntry> _parse(List<Map<String, dynamic>> list) {
    final result = <SubscribeHistoryEntry>[];
    for (final raw in list) {
      try {
        result.add(
          SubscribeHistoryEntry(
            item: SubscribeItem.fromJson(normalizeSubscribeJson(raw)),
            raw: raw,
          ),
        );
      } catch (e, st) {
        _log.handle(e, stackTrace: st, message: '解析订阅历史项失败');
      }
    }
    return result;
  }
}
