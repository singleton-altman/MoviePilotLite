import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// 系统维护 Controller：重启（GET /system/restart）与升级（POST /system/upgrade）。
/// 两端点在 v2/v3.1.5 双线均存在。
class SystemMaintenanceController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();

  final isOperating = false.obs;

  Future<({bool ok, String message})> _run(
    String label,
    Future<dynamic> Function() action,
  ) async {
    if (!Get.find<AppService>().isSuperuser) {
      return (ok: false, message: '系统维护仅限管理员操作');
    }
    if (isOperating.value) {
      return (ok: false, message: '操作进行中');
    }
    isOperating.value = true;
    try {
      final response = await action();
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        return (ok: false, message: '$label失败 (HTTP $status)');
      }
      final data = response.data;
      if (data is Map && data['success'] == false) {
        return (
          ok: false,
          message: (data['message']?.toString() ?? '').isNotEmpty
              ? data['message'].toString()
              : '$label失败',
        );
      }
      return (ok: true, message: '$label指令已下发');
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '$label异常');
      return (ok: false, message: '$label失败，请稍后重试');
    } finally {
      isOperating.value = false;
    }
  }

  Future<({bool ok, String message})> restart() =>
      _run('重启', () => _apiClient.get<dynamic>('/api/v1/system/restart'));

  Future<({bool ok, String message})> upgrade() =>
      _run('升级', () => _apiClient.post<dynamic>('/api/v1/system/upgrade'));
}
