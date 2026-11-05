import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// 整理队列中的单个任务（TransferJobTask）。
/// 保留原始 fileitem map 作为删除请求体（DELETE /api/v1/transfer/queue）。
class TransferQueueTask {
  const TransferQueueTask({
    required this.fileitem,
    this.fileName,
    this.state,
    this.downloader,
  });

  /// 原始 FileItem（删除时原样回传）
  final Map<String, dynamic> fileitem;
  final String? fileName;
  final String? state;
  final String? downloader;

  factory TransferQueueTask.fromJson(Map<String, dynamic> json) {
    final fileitem = json['fileitem'];
    return TransferQueueTask(
      fileitem: fileitem is Map
          ? Map<String, dynamic>.from(fileitem)
          : <String, dynamic>{},
      fileName:
          (fileitem is Map ? fileitem['name'] : null)?.toString() ??
          json['name']?.toString(),
      state: json['state']?.toString(),
      downloader: json['downloader']?.toString(),
    );
  }
}

/// 整理队列中的一个媒体作业（TransferJob：媒体 + 季 + 任务列表）。
class TransferQueueJob {
  const TransferQueueJob({
    this.title,
    this.year,
    this.poster,
    this.season,
    this.tasks = const [],
  });

  final String? title;
  final String? year;
  final String? poster;
  final int? season;
  final List<TransferQueueTask> tasks;

  factory TransferQueueJob.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    final mediaMap = media is Map<String, dynamic> ? media : null;
    return TransferQueueJob(
      title: mediaMap?['title']?.toString() ?? mediaMap?['name']?.toString(),
      year: mediaMap?['year']?.toString(),
      poster: mediaMap?['poster']?.toString(),
      season: (json['season'] as num?)?.toInt(),
      tasks:
          (json['tasks'] as List?)
              ?.whereType<Map>()
              .map(
                (e) => TransferQueueTask.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          const [],
    );
  }

  String get displayTitle =>
      title?.trim().isNotEmpty == true ? title!.trim() : '未知媒体';
}

/// 整理队列 Controller。GET/DELETE /api/v1/transfer/queue（v2/v3.1.5 双线一致）。
class TransferQueueController extends GetxController {
  TransferQueueController({ApiClient? apiClient, AppLog? log})
    : _injectedApiClient = apiClient,
      _injectedLog = log;

  final ApiClient? _injectedApiClient;
  final AppLog? _injectedLog;
  ApiClient get _apiClient => _injectedApiClient ?? Get.find<ApiClient>();
  AppLog get _log => _injectedLog ?? Get.find<AppLog>();

  final jobs = <TransferQueueJob>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();
  final _removingPaths = <String>{};

  @override
  void onReady() {
    super.onReady();
    reload();
  }

  Future<void> reload() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorText.value = null;
    try {
      final response = await _apiClient.get<dynamic>('/api/v1/transfer/queue');
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        return;
      }
      final data = response.data;
      if (data is Map && data['success'] == false) {
        errorText.value = data['message']?.toString() ?? '获取整理队列失败';
        return;
      }
      final rawList = data is List
          ? data
          : data is Map
          ? data['data']
          : null;
      if (rawList is! List) {
        errorText.value = '数据格式异常';
        return;
      }
      jobs.assignAll(
        rawList.whereType<Map>().map(
          (e) => TransferQueueJob.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取整理队列失败');
      errorText.value = '请求失败，请稍后重试';
    } finally {
      isLoading.value = false;
    }
  }

  /// 删除队列中的单个任务（原样回传该任务的 fileitem）。
  /// 返回 null 表示成功，否则为错误文案。
  Future<String?> deleteTask(
    TransferQueueJob job,
    TransferQueueTask task,
  ) async {
    if (!Get.find<AppService>().canManage) return '当前帐号无管理权限';
    final path = task.fileitem['path']?.toString().trim() ?? '';
    if (path.isEmpty) return '任务缺少文件路径，无法移除';
    final key = '${task.fileitem['storage']}:$path';
    if (!_removingPaths.add(key)) return '任务正在移除，请勿重复提交';
    try {
      final response = await _apiClient.request<dynamic>(
        '/api/v1/transfer/queue',
        RequestMethod.delete,
        task.fileitem,
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        return '移除失败 (HTTP $status)';
      }
      final data = response.data;
      if (data is Map && data['success'] == false) {
        return data['message']?.toString() ?? '移除失败';
      }
      _removeTask(job, task);
      return null;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '移除整理任务失败');
      return '移除失败，请稍后重试';
    } finally {
      _removingPaths.remove(key);
    }
  }

  void _removeTask(TransferQueueJob job, TransferQueueTask task) {
    final index = jobs.indexOf(job);
    if (index < 0) return;
    final remaining = job.tasks.where((t) => !identical(t, task)).toList();
    if (remaining.isEmpty) {
      jobs.removeAt(index);
    } else {
      jobs[index] = TransferQueueJob(
        title: job.title,
        year: job.year,
        poster: job.poster,
        season: job.season,
        tasks: remaining,
      );
    }
  }
}
