import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

/// 存储使用情况
class StorageUsage {
  const StorageUsage({required this.total, required this.available});

  final double total;
  final double available;

  factory StorageUsage.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] is num)
        ? (json['total'] as num).toDouble()
        : 0.0;
    final available = (json['available'] is num)
        ? (json['available'] as num).toDouble()
        : 0.0;
    return StorageUsage(total: total, available: available);
  }
}

/// 存储列表页 Controller
/// 使用 /api/v1/system/setting/Storages 获取 StorageSetting 列表
/// 获取各存储的使用信息
class StorageListController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  ServerApiVersionService get _serverApiVersionService =>
      Get.find<ServerApiVersionService>();

  final storages = <StorageSetting>[].obs;
  final storageNameMap = <String, String>{}.obs;
  final usageMap = <String, StorageUsage>{}.obs;
  final isLoading = false.obs;
  final errorText = RxnString();

  @override
  void onReady() {
    super.onReady();
    loadStorages();
  }

  /// 获取存储列表并构建 type -> name 映射
  Future<void> loadStorages() async {
    isLoading.value = true;
    errorText.value = null;
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/system/setting/Storages',
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        storages.clear();
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
      final map = <String, String>{};
      for (final raw in value) {
        if (raw is Map<String, dynamic>) {
          try {
            final item = StorageSetting.fromJson(raw);
            list.add(item);
            map[item.type] = item.name;
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析存储设置失败');
          }
        }
      }
      storages.assignAll(list);
      storageNameMap.assignAll(map);

      await _loadAllUsage();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取存储列表失败');
      errorText.value = '请求失败，请稍后重试';
      storages.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadAllUsage() async {
    usageMap.clear();
    for (final s in storages) {
      final usage = await _loadUsage(s.type);
      if (usage != null) {
        usageMap[s.type] = usage;
      }
    }
    usageMap.refresh();
  }

  Future<StorageUsage?> _loadUsage(String type) async {
    try {
      final isV3 = await _serverApiVersionService.isV3();
      final response = isV3
          ? await _apiClient.postJson<dynamic>('/api/v1/storage/manage', {
              'target': _storageUsageTarget(type),
              'action': 'usage',
              'params': <String, dynamic>{},
            })
          : await _apiClient.get<dynamic>('/api/v1/storage/usage/$type');
      final status = response.statusCode ?? 0;
      if (status >= 400) return null;

      final payload = _unwrapUsagePayload(response.data);
      if (payload == null) return null;
      final usage = StorageUsage.fromJson(payload);
      if (usage.total <= 0 && usage.available <= 0) return null;
      return usage;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取存储使用信息失败: $type');
      return null;
    }
  }

  Map<String, dynamic>? _unwrapUsagePayload(dynamic data) {
    if (data is! Map) return null;
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data);
    final nested = map['data'];
    if (nested is Map) {
      final nestedMap = nested is Map<String, dynamic>
          ? nested
          : Map<String, dynamic>.from(nested);
      if (nestedMap.containsKey('total') ||
          nestedMap.containsKey('available')) {
        return nestedMap;
      }
    }
    if (map.containsKey('total') || map.containsKey('available')) {
      return map;
    }
    return null;
  }

  String _storageUsageTarget(String type) => type;

  /// 根据 storage type 获取显示名称
  String getStorageName(String? type) {
    if (type == null || type.isEmpty) return type ?? '';
    return storageNameMap[type] ?? type;
  }

  StorageUsage? getUsageFor(String? type) {
    if (type == null || type.isEmpty) return null;
    return usageMap[type];
  }

  static bool isConfigured(StorageSetting storage) {
    final type = storage.type.toLowerCase();
    final config = storage.config;
    if (type == 'local') return true;
    if (type == 'alist' || type == 'openlist') {
      final url = config['url']?.toString().trim() ?? '';
      return url.isNotEmpty;
    }
    if (type == 'u115' || type == 'alipan') {
      final access = config['access_token']?.toString().trim() ?? '';
      final refresh = config['refresh_token']?.toString().trim() ?? '';
      return access.isNotEmpty || refresh.isNotEmpty;
    }
    if (type == 'rclone') {
      return config.values.any((v) => v?.toString().trim().isNotEmpty == true);
    }
    return config.values.any((v) => v?.toString().trim().isNotEmpty == true);
  }
}
