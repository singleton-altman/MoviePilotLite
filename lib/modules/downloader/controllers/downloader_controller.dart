import 'dart:async';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/downloader/models/download_task.dart';
import 'package:moviepilot_mobile/modules/downloader/models/downloader_stats.dart';
import 'package:moviepilot_mobile/modules/setting/models/setting_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/api_auth_failure.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class DownloaderController extends GetxController {
  final _api = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();

  /// 下载器列表（从 /api/v1/download/clients 获取）
  final downloaders = <DownloadClient>[].obs;

  /// 各下载器简要信息（从 /api/v1/dashboard/downloader?name=xxx 获取）
  final downloaderStats = <String, DownloaderStats>{}.obs;

  /// 当前选中的下载器索引
  final selectedIndex = 0.obs;

  /// 下载任务列表
  final tasks = <DownloadTask>[].obs;

  /// 加载下载器列表中
  final isLoadingDownloaders = false.obs;

  /// 加载任务列表中
  final isLoading = false.obs;

  /// 刷新中（下拉刷新）
  final isRefreshing = false.obs;

  /// 操作中的任务 hash（避免重复点击）
  final operatingHashes = <String>{}.obs;

  /// 状态乐观更新：hash -> true 表示视为「正在下载」，false 表示视为「已暂停」
  final stateOverrides = <String, bool>{}.obs;

  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    loadDownloaders();
  }

  @override
  void onReady() {
    super.onReady();
    restartTimer();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.onClose();
  }

  /// 重启定时器（进入页面时调用，确保 timer 执行）
  void restartTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchTasksForSelectedDownloader(),
    );
  }

  Future<void> loadDownloaders() async {
    if (isLoadingDownloaders.value) return;
    isLoadingDownloaders.value = true;
    try {
      final response = await _api.get<List<dynamic>>(
        '/api/v1/download/clients',
      );
      if (response.statusCode == 200 && response.data != null) {
        downloaders.value = response.data!
            .whereType<Map<String, dynamic>>()
            .map((e) => DownloadClient.fromJson(e))
            .where((c) => c.name.isNotEmpty)
            .toList();
        final nameParam = Get.parameters['name'];
        if (nameParam != null && downloaders.isNotEmpty) {
          final idx = downloaders.indexWhere((d) => d.name == nameParam);
          selectedIndex.value = idx >= 0 ? idx : 0;
        } else {
          selectedIndex.value = 0;
        }
        await loadDownloaderStats();
        await loadTasksForSelectedDownloader();
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载下载器列表失败');
    } finally {
      isLoadingDownloaders.value = false;
    }
  }

  void switchDownloader(int index) {
    if (index < 0 || index >= downloaders.length) return;
    selectedIndex.value = index;
    loadTasksForSelectedDownloader();
  }

  /// 加载当前选中下载器的任务
  Future<void> loadTasksForSelectedDownloader() async {
    if (downloaders.isEmpty || selectedIndex.value >= downloaders.length)
      return;
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _fetchTasks(downloaders[selectedIndex.value].name);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载下载任务失败');
      ToastUtil.error('加载失败');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTasks() async {
    if (downloaders.isEmpty || selectedIndex.value >= downloaders.length)
      return;
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    try {
      await loadDownloaderStats();
      await _fetchTasks(downloaders[selectedIndex.value].name);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '刷新下载任务失败');
      ToastUtil.error('刷新失败');
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _fetchTasksForSelectedDownloader() async {
    if (downloaders.isEmpty || selectedIndex.value >= downloaders.length)
      return;
    await _fetchTasks(downloaders[selectedIndex.value].name);
  }

  /// 获取所有下载器的简要信息
  Future<void> loadDownloaderStats() async {
    for (final d in downloaders) {
      if (d.name.isEmpty) continue;
      try {
        final resp = await _api.get<Map<String, dynamic>>(
          '/api/v1/dashboard/downloader',
          queryParameters: {'name': d.name},
        );
        if (resp.statusCode == 200 && resp.data != null) {
          downloaderStats[d.name] = DownloaderStats.fromJson(resp.data!);
        }
      } catch (e, st) {
        _log.handle(e, stackTrace: st, message: '获取下载器 ${d.name} 信息失败');
      }
    }
  }

  DownloaderStats? statsFor(String downloaderName) =>
      downloaderStats[downloaderName];

  Future<void> _fetchTasks(String downloaderName) async {
    final response = await _api.get<List<dynamic>>(
      '/api/v1/download/',
      queryParameters: {'name': downloaderName},
    );

    if (response.statusCode == 200 && response.data != null) {
      final list = response.data!;
      tasks.value = list
          .whereType<Map<String, dynamic>>()
          .map((e) => DownloadTask.fromJson(e))
          .toList();
      _log.info('加载下载任务成功: ${tasks.length} 个');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      ToastUtil.error(
        ApiAuthFailure.from(response.statusCode, response.data).message,
      );
    } else {
      ToastUtil.error('加载失败: ${response.statusCode}');
    }
  }

  /// 暂停任务
  Future<void> pauseTask(DownloadTask task) async {
    final hash = task.hash;
    final downloader = task.downloader;
    if (hash == null ||
        hash.isEmpty ||
        downloader == null ||
        operatingHashes.contains(hash))
      return;
    operatingHashes.add(hash);
    stateOverrides[hash] = false;
    try {
      final response = await _api.get<dynamic>(
        '/api/v1/download/stop/$hash',
        queryParameters: {'name': downloader},
      );
      if (response.statusCode == 200) {
        ToastUtil.success('已暂停');
        await _fetchTasksForSelectedDownloader();
      } else {
        ToastUtil.error('暂停失败');
        stateOverrides.remove(hash);
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '暂停任务失败');
      ToastUtil.error('暂停失败');
      stateOverrides.remove(hash);
    } finally {
      operatingHashes.remove(hash);
    }
    stateOverrides.remove(hash);
  }

  /// 继续任务
  Future<void> resumeTask(DownloadTask task) async {
    final hash = task.hash;
    final downloader = task.downloader;
    if (hash == null ||
        hash.isEmpty ||
        downloader == null ||
        operatingHashes.contains(hash))
      return;
    operatingHashes.add(hash);
    stateOverrides[hash] = true;
    try {
      final response = await _api.get<dynamic>(
        '/api/v1/download/start/$hash',
        queryParameters: {'name': downloader},
      );
      if (response.statusCode == 200) {
        ToastUtil.success('已继续');
        await _fetchTasksForSelectedDownloader();
      } else {
        ToastUtil.error('继续失败');
        stateOverrides.remove(hash);
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '继续任务失败');
      ToastUtil.error('继续失败');
      stateOverrides.remove(hash);
    } finally {
      operatingHashes.remove(hash);
    }
    stateOverrides.remove(hash);
  }

  /// 切换暂停/继续
  Future<void> togglePauseResume(DownloadTask task) async {
    if (isDownloading(task)) {
      await pauseTask(task);
    } else {
      await resumeTask(task);
    }
  }

  /// 删除任务
  Future<void> deleteTask(DownloadTask task) async {
    final hash = task.hash;
    final downloader = task.downloader;
    if (hash == null ||
        hash.isEmpty ||
        downloader == null ||
        operatingHashes.contains(hash))
      return;
    operatingHashes.add(hash);
    try {
      final response = await _api.delete<dynamic>(
        '/api/v1/download/$hash',
        queryParameters: {'name': downloader},
      );
      if (response.statusCode == 200) {
        ToastUtil.success('已删除');
        await _fetchTasksForSelectedDownloader();
      } else {
        ToastUtil.error('删除失败');
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '删除任务失败');
      ToastUtil.error('删除失败');
    } finally {
      operatingHashes.remove(hash);
    }
  }

  /// 是否正在下载（显示暂停按钮）
  /// 根据 left_time 为空或 empty 认定为暂停状态
  bool isDownloading(DownloadTask task) {
    if (task.state == 'downloading') {
      return true;
    }
    final hash = task.hash;
    if (hash != null && stateOverrides.containsKey(hash)) {
      return stateOverrides[hash] ?? false;
    }
    final leftTime = task.leftTime;
    return leftTime != null && leftTime.trim().isNotEmpty;
  }
}
