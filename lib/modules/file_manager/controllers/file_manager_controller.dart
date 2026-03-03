import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/storage/controllers/storage_list_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

/// 文件管理器控制器
/// 支持普通浏览模式和 picker 模式
class FileManagerController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();

  // 模式配置
  final bool isPickerMode;
  final bool allowMultipleSelection;
  final bool allowFileSelection;
  final bool allowDirSelection;
  final String? initialStorage;
  final String? initialPath;

  // 存储相关
  final storages = <StorageSetting>[].obs;
  final selectedStorage = Rxn<StorageSetting>();

  // 文件列表相关
  final files = <MediaOrganizeFileItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  // 路径导航（面包屑）
  final pathStack = <String>['/'].obs;

  // 选择相关（picker 模式）
  final selectedFiles = <MediaOrganizeFileItem>{}.obs;

  // 搜索相关
  final searchController = TextEditingController();
  final searchKeyword = ''.obs;

  // 排序相关
  final sortBy = 'name'.obs; // 'name' 或 'time'
  final sortOrder = 'asc'.obs; // 'asc' 或 'desc'

  FileManagerController({
    this.isPickerMode = false,
    this.allowMultipleSelection = false,
    this.allowFileSelection = true,
    this.allowDirSelection = true,
    this.initialStorage,
    this.initialPath,
  });

  @override
  void onInit() {
    super.onInit();
    _initStorageList();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// 获取当前路径
  String get currentPath => pathStack.isEmpty ? '/' : pathStack.last;

  /// 初始化存储列表
  void _initStorageList() {
    // 尝试从已有的 StorageListController 获取
    if (Get.isRegistered<StorageListController>()) {
      final storageController = Get.find<StorageListController>();
      if (storageController.storages.isNotEmpty) {
        storages.assignAll(storageController.storages);
        _selectInitialStorage();
      } else {
        // 监听存储列表加载完成
        ever(storageController.storages, (list) {
          if (list.isNotEmpty && storages.isEmpty) {
            storages.assignAll(list);
            _selectInitialStorage();
          }
        });
        // 触发加载
        storageController.loadStorages();
      }
    } else {
      // 自己加载存储列表
      loadStorages();
    }
  }

  /// 选择初始存储
  void _selectInitialStorage() {
    if (storages.isEmpty) return;

    StorageSetting? target;
    if (initialStorage != null && initialStorage!.isNotEmpty) {
      target = storages.firstWhereOrNull((s) => s.type == initialStorage);
    }
    target ??= storages.firstWhereOrNull((s) => s.type == 'local') ?? storages.first;

    selectStorage(target);

    // 设置初始路径
    if (initialPath != null && initialPath!.isNotEmpty && initialPath != '/') {
      final parts = initialPath!.split('/').where((p) => p.isNotEmpty).toList();
      pathStack.value = ['/', ...parts.map((p) => '/${parts.take(parts.indexOf(p) + 1).join('/')}')];
    }
  }

  /// 加载存储列表
  Future<void> loadStorages() async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/system/setting/Storages',
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '获取存储列表失败 (HTTP $status)';
        return;
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        errorText.value = '数据格式异常';
        return;
      }
      final value = data['data']?['value'];
      if (value is! List) {
        errorText.value = '数据格式异常';
        return;
      }

      final list = <StorageSetting>[];
      for (final raw in value) {
        if (raw is Map<String, dynamic>) {
          try {
            final item = StorageSetting.fromJson(raw);
            list.add(item);
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析存储设置失败');
          }
        }
      }
      storages.assignAll(list);
      _selectInitialStorage();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取存储列表失败');
      errorText.value = '请求失败，请稍后重试';
    }
  }

  /// 选择存储
  void selectStorage(StorageSetting? storage) {
    if (storage == null) return;
    selectedStorage.value = storage;
    // 重置路径
    pathStack.value = ['/'];
    selectedFiles.clear();
    loadFiles();
  }

  /// 加载文件列表
  Future<void> loadFiles() async {
    if (selectedStorage.value == null) return;

    isLoading.value = true;
    errorText.value = null;

    try {
      final response = await _apiClient.post<dynamic>(
        '/api/v1/storage/list?sort=${sortBy.value}',
        data: {
          'type': 'dir',
          'storage': selectedStorage.value!.type,
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
              final item = MediaOrganizeFileItem.fromJson(raw);
              list.add(item);
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
              final item = MediaOrganizeFileItem.fromJson(raw);
              list.add(item);
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

  /// 进入文件夹
  void enterDirectory(MediaOrganizeFileItem item) {
    if (item.type != 'dir') return;
    final newPath = item.path ?? '${currentPath == '/' ? '' : currentPath}/${item.name}';
    pathStack.add(newPath);
    loadFiles();
  }

  /// 返回上一级
  void goBack() {
    if (pathStack.length > 1) {
      pathStack.removeLast();
      loadFiles();
    }
  }

  /// 跳转到指定路径层级
  void jumpToPath(int index) {
    if (index < 0 || index >= pathStack.length - 1) return;
    pathStack.removeRange(index + 1, pathStack.length);
    loadFiles();
  }

  /// 切换文件选择状态（picker 模式）
  void toggleSelection(MediaOrganizeFileItem item) {
    if (!isPickerMode) return;

    // 检查是否允许选择该类型
    if (item.type == 'dir' && !allowDirSelection) return;
    if (item.type != 'dir' && !allowFileSelection) return;

    if (selectedFiles.contains(item)) {
      selectedFiles.remove(item);
    } else {
      if (!allowMultipleSelection) {
        selectedFiles.clear();
      }
      selectedFiles.add(item);
    }
  }

  /// 判断是否已选中
  bool isSelected(MediaOrganizeFileItem item) {
    return selectedFiles.contains(item);
  }

  /// 确认选择（picker 模式）
  void confirmSelection() {
    if (!isPickerMode) return;
    if (selectedFiles.isEmpty) {
      Get.back();
      return;
    }

    final result = selectedFiles.toList();
    Get.back(result: result);
  }

  /// 搜索文件
  void onSearch(String keyword) {
    searchKeyword.value = keyword;
    loadFiles();
  }

  /// 清除搜索
  void clearSearch() {
    searchController.clear();
    searchKeyword.value = '';
    loadFiles();
  }

  /// 获取面包屑路径名称
  String getBreadcrumbName(int index) {
    if (index == 0) return '根目录';
    final path = pathStack[index];
    final parts = path.split('/');
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => '根目录');
  }

  /// 格式化文件大小
  String formatFileSize(int? size) {
    if (size == null || size <= 0) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 格式化修改时间
  String formatModifyTime(double? modifyTime) {
    if (modifyTime == null) return '';
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        (modifyTime * 1000).toInt(),
      );
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  /// 切换排序方式
  void toggleSort(String by) {
    if (sortBy.value == by) {
      // 切换排序顺序
      sortOrder.value = sortOrder.value == 'asc' ? 'desc' : 'asc';
    } else {
      sortBy.value = by;
      sortOrder.value = 'asc';
    }
    loadFiles();
  }

  /// 获取排序图标
  IconData getSortIcon(String by) {
    if (sortBy.value != by) {
      return CupertinoIcons.arrow_up_arrow_down;
    }
    return sortOrder.value == 'asc'
        ? CupertinoIcons.arrow_up
        : CupertinoIcons.arrow_down;
  }
}
