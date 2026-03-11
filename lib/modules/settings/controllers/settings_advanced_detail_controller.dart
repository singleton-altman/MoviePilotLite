import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_advanced_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/system_env_model.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

/// 高级设置详情控制器：加载系统环境数据，提供只读展示
class SettingsAdvancedDetailController extends GetxController {
  final _apiClient = Get.find<ApiClient>();

  final envData = Rxn<SystemEnvData>();
  final isLoading = false.obs;
  final errorText = RxnString();

  final imageUtil = Get.find<ImageUtil>();

  /// 所有区块：(标题, 字段列表)
  List<(String, List<SettingsFieldConfig>)> get sections => [
    ('系统', advancedSystemFields),
    ('媒体', advancedMediaFields),
    ('网络', advancedNetworkFields),
    ('日志', advancedLogFields),
    ('实验室', advancedLabFields),
  ];

  dynamic valueFor(SettingsFieldConfig field) =>
      envData.value?.valueFor(field.envKey);

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    try {
      final resp = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/system/env',
      );
      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        final body = resp.data;
        if (body != null) {
          final parsed = SystemEnvResponse.fromJson(body);
          if (parsed.success && parsed.data != null) {
            envData.value = parsed.data;
            imageUtil.saveGlobalCachedEnabled(
              envData.value?.globalImageCache ?? false,
            );
            return;
          }
        }
      }
      errorText.value = '加载失败';
    } catch (e) {
      errorText.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
