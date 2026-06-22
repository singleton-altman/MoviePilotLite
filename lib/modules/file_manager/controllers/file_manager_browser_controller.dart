import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/file_manager/file_manager_picker_service.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/recognize/models/recognize_model.dart';
import 'package:moviepilot_mobile/modules/storage/controllers/storage_list_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class FileActionResult {
  const FileActionResult({required this.success, this.message = ''});

  final bool success;
  final String message;
}

/// 文件浏览器控制器 - 使用 Get.to 页面级导航，每页单一 currentPath
class FileManagerBrowserController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();

  /// 当前路径（本页）
  final currentPath = '/'.obs;

  /// 面包屑用路径层级（由 currentPath 推导）
  List<String> get pathStack {
    final path = currentPath.value;
    if (path == '/' || path.isEmpty) return ['/'];
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final stack = <String>['/'];
    for (final p in parts) {
      stack.add('${stack.last == '/' ? '' : stack.last}/$p');
    }
    return stack;
  }

  // 当前选中存储
  final selectedStorage = Rxn<StorageSetting>();

  // 模式配置（从 Get.arguments 传入）
  final bool isPickerMode;
  final bool allowMultipleSelection;
  final bool allowFileSelection;
  final bool allowDirSelection;
  final bool allowSelectStorage;
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
    this.allowSelectStorage = true,
    String? initialStorageType,
    String? initialPath,
  }) {
    currentPath.value = initialPath ?? '/';
    if (currentPath.value == '/' || currentPath.value.isEmpty) {
      FileManagerPickerService.clear();
    }
  }

  @override
  void onInit() {
    super.onInit();
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
    currentPath.value = '/';
    loadFiles();
  }

  /// 获取进入子目录后的路径，由 Page 使用 Get.to 跳转
  String? getNextPathForDir(MediaOrganizeFileItem item) {
    if (!_isDirectory(item)) return null;
    return getNextPath(item);
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
          'path': currentPath.value,
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
            } catch (e) {
              _log.handle(e, message: '解析文件项失败');
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
            } catch (e) {
              _log.handle(e, message: '解析文件项失败');
            }
          }
        }
        files.assignAll(list);
      } else {
        files.clear();
      }
    } catch (e) {
      _log.handle(e, message: '获取文件列表失败');
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
    final path = currentPath.value;
    if (!_isDirectory(item)) return path;
    return item.path ?? '${path == '/' ? '' : path}/${item.name}';
  }

  /// 本地过滤后的文件列表
  List<MediaOrganizeFileItem> get filteredFiles {
    final kw = searchKeyword.value.trim().toLowerCase();
    if (kw.isEmpty) return files;
    return files
        .where(
          (f) =>
              (f.name ?? '').toLowerCase().contains(kw) ||
              (f.basename ?? '').toLowerCase().contains(kw),
        )
        .toList();
  }

  void onSearch(String keyword) {
    searchKeyword.value = keyword;
  }

  void clearSearch() {
    searchController.clear();
    searchKeyword.value = '';
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
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 删除文件/文件夹
  Future<bool> deleteFile(MediaOrganizeFileItem file) async {
    final storage = selectedStorage.value;
    if (storage == null) return false;

    final body = _buildStorageFilePayload(file, storageType: storage.type);

    try {
      final response = await _apiClient.postJson<dynamic>(
        '/api/v1/storage/delete',
        body,
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        loadFiles();
        return true;
      }
      return false;
    } catch (e) {
      _log.handle(e, message: '删除文件失败');
      return false;
    }
  }

  String formatModifyTime(double? modifyTime) {
    if (modifyTime == null) return '';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (modifyTime * 1000).toInt(),
      );
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  /// 识别文件/文件夹 - GET /api/v1/media/recognize_file?path=...
  Future<RecognizeResponse?> recognizeFile(MediaOrganizeFileItem item) async {
    final storage = selectedStorage.value;
    if (storage == null) return null;

    final path =
        item.path ??
        '${currentPath.value == '/' ? '' : currentPath.value}/${item.name}';
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
    } catch (e) {
      _log.handle(e, message: '识别文件失败');
      return null;
    }
  }

  RecognizeResponse? _parseRecognizeResponse(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map) {
        return RecognizeResponse.fromJson(
          _normalizeRecognizePayload(Map<String, dynamic>.from(data)),
        );
      }
      if (data is String && data.trim().startsWith('{')) {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return RecognizeResponse.fromJson(
            _normalizeRecognizePayload(Map<String, dynamic>.from(decoded)),
          );
        }
      }
    } catch (e) {
      _log.handle(e, message: '解析识别结果失败');
    }
    return null;
  }

  static const Set<String> _recognizeStringKeys = {
    'source',
    'type',
    'title',
    'subtitle',
    'name',
    'cn_name',
    'en_name',
    'year',
    'org_string',
    'season_episode',
    'part',
    'resource_type',
    'resource_effect',
    'resource_pix',
    'resource_team',
    'video_encode',
    'audio_encode',
    'edition',
    'web_source',
    'en_title',
    'title_year',
    'imdb_id',
    'mediaid_prefix',
    'media_id',
    'original_language',
    'original_title',
    'release_date',
    'backdrop_path',
    'poster_path',
    'overview',
    'category',
    'detail_link',
    'first_air_date',
    'homepage',
    'last_air_date',
    'original_name',
    'status',
    'tagline',
    'air_date',
    'known_for_department',
    'profile_path',
    'character',
    'credit_id',
    'job',
    'logo_path',
    'origin_country',
    'iso_3166_1',
    'english_name',
    'iso_639_1',
    'certification',
    'note',
    'description',
    'production_code',
    'still_path',
  };

  Map<String, dynamic> _normalizeRecognizePayload(Map<String, dynamic> source) {
    final normalized = <String, dynamic>{};
    source.forEach((key, value) {
      normalized[key] = _normalizeRecognizeValue(key, value);
    });
    return normalized;
  }

  dynamic _normalizeRecognizeValue(String key, dynamic value) {
    if (value is Map) {
      return _normalizeRecognizePayload(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return value.map((item) {
        if (item is Map) {
          return _normalizeRecognizePayload(Map<String, dynamic>.from(item));
        }
        return item;
      }).toList();
    }
    if (_recognizeStringKeys.contains(key) &&
        value != null &&
        value is! String) {
      return value.toString();
    }
    return value;
  }

  /// 刮削文件/文件夹 - POST /api/v1/media/scrape/{storage}
  Future<bool> scrapeFile(MediaOrganizeFileItem file) async {
    final storage = selectedStorage.value;
    if (storage == null) return false;

    final body = _buildStorageFilePayload(file, storageType: storage.type);

    try {
      final response = await _apiClient.postJson<dynamic>(
        '/api/v1/media/scrape/${storage.type}',
        body,
      );
      final status = response.statusCode ?? 0;
      return status >= 200 && status < 300;
    } catch (e) {
      _log.handle(e, message: '刮削失败');
      return false;
    }
  }

  /// 获取建议名称 - GET /api/v1/transfer/name?path=...&filetype=dir|file
  Future<String?> getRecognizedName(MediaOrganizeFileItem item) async {
    final storage = selectedStorage.value;
    if (storage == null) return null;

    final path =
        item.path ??
        '${currentPath.value == '/' ? '' : currentPath.value}/${item.name}';
    if (path.isEmpty) return null;

    final filetype = _isDirectory(item) ? 'dir' : 'file';

    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/transfer/name',
        queryParameters: {'path': path, 'filetype': filetype},
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data is Map) {
        final data = response.data as Map;
        final result = data['data'];
        if (result is Map && result['name'] != null) {
          return result['name']?.toString().trim();
        }
      }
      return null;
    } catch (e) {
      _log.handle(e, message: '获取建议名称失败');
      return null;
    }
  }

  /// 重命名 - POST /api/v1/storage/rename?new_name=...
  Future<bool> renameFile(
    MediaOrganizeFileItem file, {
    required String newName,
    bool renameDirFiles = false,
  }) async {
    final storage = selectedStorage.value;
    if (storage == null) return false;

    final body = _buildStorageFilePayload(file, storageType: storage.type);
    if (renameDirFiles) {
      body['rename_dir_files'] = true;
    }

    try {
      final response = await _apiClient.postJson<dynamic>(
        '/api/v1/storage/rename',
        body,
        queryParameters: {'new_name': newName},
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        loadFiles();
        return true;
      }
      return false;
    } catch (e) {
      _log.handle(e, message: '重命名失败');
      return false;
    }
  }

  Future<FileActionResult> manualTransfer(
    MediaOrganizeFileItem file, {
    required String mode,
    required String targetStorage,
    required String transferType,
    required String targetPath,
    required bool scrape,
    required bool libraryTypeFolder,
    required bool libraryCategoryFolder,
    required String tmdbId,
    required String part,
    required String minFileSize,
    required String episodeGroup,
    required String season,
    required String episodeFormat,
    required String episodeOffset,
  }) async {
    final sourceStorage = selectedStorage.value?.type ?? file.storage ?? '';
    if (sourceStorage.isEmpty || targetStorage.trim().isEmpty) {
      return const FileActionResult(success: false, message: '缺少源存储或目标存储');
    }

    final normalizedTransferType = transferType.trim();
    final normalizedTargetPath = targetPath.trim();
    final normalizedTmdbId = tmdbId.trim();
    final normalizedPart = part.trim();
    final normalizedEpisodeGroup = episodeGroup.trim();
    final normalizedSeason = season.trim();
    final normalizedEpisodeFormat = episodeFormat.trim();
    final normalizedEpisodeOffset = episodeOffset.trim();
    final parsedMinFileSize =
        double.tryParse(minFileSize.trim())?.floor().clamp(0, 1 << 31) ?? 0;

    final payload = <String, dynamic>{
      'fileitem': _buildStorageFilePayload(file, storageType: sourceStorage),
      'logid': 0,
      'target_storage': targetStorage.trim(),
      'transfer_type': normalizedTransferType == 'auto'
          ? ''
          : normalizedTransferType,
      'target_path': normalizedTargetPath,
      'min_filesize': parsedMinFileSize,
      'scrape': scrape,
      'from_history': false,
      'library_category_folder': libraryCategoryFolder,
      'library_type_folder': libraryTypeFolder,
    };

    if (mode == 'movie') {
      payload['type_name'] = '';
    } else if (mode == 'tv') {
      payload['type_name'] = '电视剧';
    }

    if (normalizedTmdbId.isNotEmpty) {
      payload['tmdbid'] = normalizedTmdbId;
    }

    if (normalizedPart.isNotEmpty) {
      payload[mode == 'tv' ? 'episode_part' : 'part'] = normalizedPart;
    }

    if (mode == 'tv') {
      if (normalizedEpisodeGroup.isNotEmpty) {
        payload['episode_group'] = normalizedEpisodeGroup;
      }
      final parsedSeason = int.tryParse(normalizedSeason);
      if (parsedSeason != null) {
        payload['season'] = parsedSeason;
      }
      if (normalizedEpisodeFormat.isNotEmpty) {
        payload['episode_format'] = normalizedEpisodeFormat;
      }
      if (normalizedEpisodeOffset.isNotEmpty) {
        payload['episode_offset'] = normalizedEpisodeOffset;
      }
    }

    try {
      final response = await _apiClient.postJson<dynamic>(
        '/api/v1/transfer/manual',
        payload,
        queryParameters: {'background': false},
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final data = response.data;
        if (data is Map) {
          final result = Map<String, dynamic>.from(data);
          final success = result['success'] is bool
              ? result['success'] as bool
              : false;
          final message = result['message']?.toString().trim() ?? '';
          if (success) {
            loadFiles();
          }
          return FileActionResult(success: success, message: message);
        }
        return const FileActionResult(success: false, message: '整理响应格式异常');
      }
      final data = response.data;
      String message = '整理失败 (HTTP $status)';
      if (data is Map && data['message'] != null) {
        final serverMessage = data['message']?.toString().trim() ?? '';
        if (serverMessage.isNotEmpty) {
          message = serverMessage;
        }
      }
      return FileActionResult(success: false, message: message);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '手动整理失败');
      return const FileActionResult(success: false, message: '手动整理失败');
    }
  }

  Map<String, dynamic> _buildStorageFilePayload(
    MediaOrganizeFileItem file, {
    required String storageType,
  }) {
    final path = (file.path?.trim().isNotEmpty ?? false)
        ? file.path!.trim()
        : getNextPath(file);
    return {
      'path': path,
      'storage': storageType,
      'type': file.type,
      'name': file.name,
      'basename': file.basename,
      'extension': file.extension,
      'size': file.size,
      'modify_time': file.modifyTime,
      'children': file.children,
      'fileid': file.fileid,
      'parent_fileid': file.parent_fileid,
      'thumbnail': file.thumbnail,
      'pickcode': file.pickcode,
      'drive_id': file.drive_id,
      'url': file.url,
    };
  }

  void retryLoadStorages() {
    if (Get.isRegistered<StorageListController>()) {
      Get.find<StorageListController>().loadStorages();
    }
  }
}
