import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/setting/models/setting_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 目录列表页 Controller
/// 使用 /api/v1/system/setting/Directories 获取 DirectorySetting 列表
class DirectoryListController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  final directories = <DirectorySetting>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorText = RxnString();

  @override
  void onReady() {
    super.onReady();
    loadDirectories();
  }

  /// 加载目录设置列表
  Future<void> loadDirectories({bool force = false}) async {
    isLoading.value = true;
    errorText.value = null;
    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        ToastUtil.error('请先登录');
        errorText.value = '请先登录';
        if (force) {
          directories.clear();
        }
        return;
      }

      final items = await _fetchDirectories(token);
      if (items != null) {
        directories.assignAll(items);
      } else {
        errorText.value ??= '数据格式异常';
        if (force || directories.isEmpty) {
          directories.clear();
        }
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载目录设置失败');
      errorText.value = '请求失败，请稍后重试';
      if (force || directories.isEmpty) {
        directories.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateDirectoryAt(int index, DirectorySetting updated) async {
    if (index < 0 || index >= directories.length) return false;
    final previous = directories[index];
    directories[index] = updated;
    directories.refresh();
    final ok = await saveDirectories();
    if (!ok) {
      directories[index] = previous;
      directories.refresh();
    }
    return ok;
  }

  Future<bool> saveDirectories() async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        ToastUtil.error('请先登录');
        return false;
      }

      final payload = directories.map((d) => d.toJson()).toList();
      final resp = await _apiClient.postJson<dynamic>(
        '/api/v1/system/setting/Directories',
        payload,
        token: token,
      );
      final status = resp.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final latest = await _fetchDirectories(token);
        if (latest != null) {
          directories.assignAll(latest);
          errorText.value = null;
          return true;
        }
        ToastUtil.error(errorText.value ?? '保存后同步失败');
        return false;
      }
      ToastUtil.error('保存失败 (HTTP $status)');
      return false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存目录设置失败');
      ToastUtil.error('保存失败');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// 获取目录建议列表（从目录设置中提取 download_path）
  List<String> get directorySuggestions => directories
      .map((dir) => dir.downloadPath)
      .where((path) => path.isNotEmpty)
      .toList();

  Future<List<DirectorySetting>?> _fetchDirectories(String token) async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/system/setting/Directories',
      token: token,
    );
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      errorText.value = '请求失败 (HTTP $status)';
      return null;
    }
    final parsed = _parseDirectoryList(response.data);
    errorText.value = parsed == null ? '数据格式异常' : null;
    return parsed;
  }

  List<DirectorySetting>? _parseDirectoryList(dynamic data) {
    if (data is List) {
      return _decodeDirectoryItems(data);
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final wrappedData = map['data'];
      if (wrappedData is Map) {
        final wrappedValue = wrappedData['value'];
        if (wrappedValue is List) {
          return _decodeDirectoryItems(wrappedValue);
        }
      }

      final directValue = map['value'];
      if (directValue is List) {
        return _decodeDirectoryItems(directValue);
      }

      final parsed = DirectorySettingResponse.fromJson(map);
      if (parsed.success && parsed.data != null) {
        return parsed.data!.value;
      }
    }

    return null;
  }

  List<DirectorySetting>? _decodeDirectoryItems(List items) {
    final directories = <DirectorySetting>[];
    for (final item in items) {
      if (item is! Map) {
        _log.warning('目录设置项格式异常: ${item.runtimeType}');
        return null;
      }
      try {
        directories.add(
          DirectorySetting.fromJson(Map<String, dynamic>.from(item)),
        );
      } catch (e, st) {
        _log.handle(e, stackTrace: st, message: '解析目录设置失败');
        return null;
      }
    }
    return directories;
  }
}
