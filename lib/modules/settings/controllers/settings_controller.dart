import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/controllers/app_setting_controller.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_config.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class SettingsController extends GetxController {
  List<SettingsCategory> get categories {
    if (_appService.isSuperuser) {
      return settingsCategories;
    }
    return settingsCategories.where((category) {
      if (category.id == SettingsCategoryId.app) {
        return true;
      }
      return false;
    }).toList();
  }

  final appSettingController = Get.put(AppSettingController());
  final _appService = Get.find<AppService>();
  Rx<String> get version => appSettingController.version;

  /// 单页设定：点击某分类下的某一行（子项或「服务」唯一行）
  void onRowTap(SettingsCategory category, SettingsSubItem? item) {
    final route = item?.route ?? category.directRoute;
    if (!_appService.canAccessRoute(route)) {
      ToastUtil.info(_appService.accessDeniedMessage(route));
      return;
    }
    if (category.directRoute != null && category.directRoute!.isNotEmpty) {
      Get.toNamed(category.directRoute!);
      return;
    }
    if (item == null) return;
    if (item.route != null && item.route!.isNotEmpty) {
      Get.toNamed(
        item.route!,
        arguments: {
          'title': item.title,
          'categoryId': category.id,
          'subId': item.id,
        },
      );
      return;
    }
    ToastUtil.info('${item.title} 详情页待接入');
  }
}
