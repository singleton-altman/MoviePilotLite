import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/file_manager/file_manager_picker_service.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/recognize/models/recognize_model.dart';
import 'package:moviepilot_mobile/modules/storage/controllers/storage_list_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

/// 文件浏览器控制器 - 单页 pathStack 导航，GetX 状态管理
class FileManagerBrowserController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();

  // 路径栈
  final pathStack = <String>[].obs;

  String get currentPath => pathStack.isEmpty ? '/' : pathStack.last;

  // 当前选中存储
  final selectedStorage = Rxn<StorageSetting>();

  // 模式配置（从 Get.arguments 传入）
  final bool isPickerMode;
  final bool allowMultipleSelection;
  final bool allowFileSelection;
  final bool allowDirSelection;

  // 文件列表
  final files = <MediaOrganizeFileItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  // 搜索
  final searchController = TextEditingController();
  final searchKeyword = ''.obs;

  // 排序（仅按名称/时间，无正反序）
  final sortBy = 'name'.obs;

  FileManagerBrowserController({
    this.isPickerMode = false,
    this.allowMultipleSelection = false,
    this.allowFileSelection = true,
    this.allowDirSelection = true,
    String? initialStorageType,
    String? initialPath,
  }) {
    pathStack.assignAll([initialPath ?? '/']);
  }

  @override
  void onInit() {
    super.onInit();
    FileManagerPickerService.clear();
    _initStorage();
  }

  void _initStorage() {
    if (!Get.isRegistered<StorageListController>()) {
      errorText.value = '存储服务未就绪';
      return;
    }
    final storageController = Get.find<StorageListController>();
    if (storageController.storages.isNotEmpty) {
      _selectStorage(storageController.storages);
    } else {
      ever(storageController.storages, (list) {
        if (list.isNotEmpty && selectedStorage.value == null) {
          _selectStorage(list);
        }
      });
      storageController.loadStorages();
    }
  }

  void _selectStorage(List<StorageSetting> list) {
    final type = Get.arguments is Map
        ? (Get.arguments as Map)['initialStorage']?.toString()
        : null;
    StorageSetting? target;
    if (type != null && type.isNotEmpty) {
      target = list.firstWhereOrNull((s) => s.type == type);
    }
    target ??= list.firstWhereOrNull((s) => s.type == 'local');
    target ??= list.first;
    selectedStorage.value = target;
    loadFiles();
  }

  void switchStorage(StorageSetting s) {
    selectedStorage.value = s;
    pathStack.assignAll(['/']);
    loadFiles();
  }

  void enterDirectory(MediaOrganizeFileItem item) {
    if (!_isDirectory(item)) return;
    final nextPath = getNextPath(item);
    pathStack.add(nextPath);
    loadFiles();
  }

  void goBack() {
    if (pathStack.length > 1) {
      pathStack.removeLast();
      loadFiles();
    }
  }

  void jumpToPath(int index) {
    if (index < 0 || index >= pathStack.length) return;
    if (index < pathStack.length - 1) {
      pathStack.removeRange(index + 1, pathStack.length);
      loadFiles();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadFiles() async {
    final storage = selectedStorage.value;
    if (storage == null) return;

    isLoading.value = true;
    errorText.value = null;

    try {
      final response = await _apiClient.post<dynamic>(
        '/api/v1/storage/list?sort=${sortBy.value}',
        data: {
          'type': 'dir',
          'storage': storage.type,
          'name': searchKeyword.value,
          'path': currentPath,
        },
      );

      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '获取文件列表失败 (HTTP $status)';
        files.clear();
        return;
      }

      final data = response.data;
      if (data is List) {
        final list = <MediaOrganizeFileItem>[];
        for (final raw in data) {
          if (raw is Map<String, dynamic>) {
            try {
              list.add(MediaOrganizeFileItem.fromJson(raw));
            } catch (e, st) {
              _log.handle(e, stackTrace: st, message: '解析文件项失败');
            }
          }
        }
        files.assignAll(list);
      } else if (data is Map && data['data'] is List) {
        final list = <MediaOrganizeFileItem>[];
        for (final raw in data['data']) {
          if (raw is Map<String, dynamic>) {
            try {
              list.add(MediaOrganizeFileItem.fromJson(raw));
            } catch (e, st) {
              _log.handle(e, stackTrace: st, message: '解析文件项失败');
            }
          }
        }
        files.assignAll(list);
      } else {
        files.clear();
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取文件列表失败');
      errorText.value = '请求失败，请稍后重试';
      files.clear();
    } finally {
      isLoading.value = false;
    }
  }

  static bool _isDirectory(MediaOrganizeFileItem item) {
    final t = item.type?.toLowerCase();
    return t == 'dir' || t == 'directory' || t == 'folder';
  }

  String getNextPath(MediaOrganizeFileItem item) {
    if (!_isDirectory(item)) return currentPath;
    return item.path ?? '${currentPath == '/' ? '' : currentPath}/${item.name}';
  }

  void onSearch(String keyword) {
    searchKeyword.value = keyword;
    loadFiles();
  }

  void clearSearch() {
    searchController.clear();
    searchKeyword.value = '';
    loadFiles();
  }

  void setSortBy(String by) {
    if (sortBy.value == by) return;
    sortBy.value = by;
    loadFiles();
  }

  String formatFileSize(int? size) {
    if (size == null || size <= 0) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 删除文件/文件夹
  Future<bool> deleteFile(MediaOrganizeFileItem file) async {
    final storage = selectedStorage.value;
    if (storage == null) return false;

    final body = file.toJson();
    // 确保 storage 字段正确
    if (body['storage'] == null || (body['storage'] as String).isEmpty) {
      body['storage'] = storage.type;
    }

    try {
      final response = await _apiClient.post<dynamic>(
        '/api/v1/storage/delete',
        data: body,
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        loadFiles();
        return true;
      }
      return false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '删除文件失败');
      return false;
    }
  }

  String formatModifyTime(double? modifyTime) {
    if (modifyTime == null) return '';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch((modifyTime * 1000).toInt());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  /// 识别文件/文件夹 - GET /api/v1/media/recognize_file?path=...
  Future<RecognizeResponse?> recognizeFile(MediaOrganizeFileItem item) async {
    final storage = selectedStorage.value;
    if (storage == null) return null;

    final path = item.path ?? '${currentPath == '/' ? '' : currentPath}/${item.name}';
    if (path.isEmpty) return null;

    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/media/recognize_file',
        queryParameters: {'path': path},
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300 && response.data != null) {
        return _parseRecognizeResponse(response.data);
      }
      return null;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '识别文件失败');
      return null;
    }
  }

  RecognizeResponse? _parseRecognizeResponse(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map) {
        return RecognizeResponse.fromJson(Map<String, dynamic>.from(data));
      }
      if (data is String && data.trim().startsWith('{')) {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return RecognizeResponse.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {}
    return null;
  }

  /// 刮削文件/文件夹 - POST /api/v1/media/scrape/{storage}
  Future<bool> scrapeFile(MediaOrganizeFileItem file) async {
    final storage = selectedStorage.value;
    if (storage == null) return false;

    final body = file.toJson();
    if (body['storage'] == null || (body['storage'] as String).isEmpty) {
      body['storage'] = storage.type;
    }

    try {
      final response = await _apiClient.post<dynamic>(
        '/api/v1/media/scrape/${storage.type}',
        data: body,
      );
      final status = response.statusCode ?? 0;
      return status >= 200 && status < 300;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '刮削失败');
      return false;
    }
  }

  void retryLoadStorages() {
    if (Get.isRegistered<StorageListController>()) {
      Get.find<StorageListController>().loadStorages();
    }
  }
}
