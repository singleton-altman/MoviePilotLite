import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_files_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';

class SubscribeFilesController extends GetxController {
  SubscribeFilesController({required this.item});

  final SubscribeItem item;

  final _log = Get.find<AppLog>();
  final _subscribeService = Get.put(SubscribeService());

  final isLoading = false.obs;
  final errorText = RxnString();
  final result = Rxn<SubscribeFilesResult>();

  int get subscribeId => item.id ?? 0;

  SubscribeItem get displaySubscribe => result.value?.subscribe ?? item;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (subscribeId <= 0) {
      errorText.value = '无效的订阅 ID';
      return;
    }
    isLoading.value = true;
    errorText.value = null;
    try {
      result.value = await _subscribeService.fetchSubscribeFiles(subscribeId);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取订阅文件统计失败');
      errorText.value = e is StateError ? e.message : '请求失败，请稍后重试';
    } finally {
      isLoading.value = false;
    }
  }

  String get pageTitle {
    final name = displaySubscribe.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return '文件统计';
  }

  int get downloadCount {
    final episodes = result.value?.episodes ?? const [];
    return episodes.fold<int>(0, (sum, e) => sum + e.downloads.length);
  }

  int get libraryCount {
    final episodes = result.value?.episodes ?? const [];
    return episodes.fold<int>(0, (sum, e) => sum + e.libraries.length);
  }

  int get episodeCount {
    final loaded = result.value?.episodes;
    if (loaded != null) return loaded.length;
    return item.totalEpisode ?? 0;
  }
}
