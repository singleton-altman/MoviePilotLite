import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:altman_totp/services/totp_service.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

import '../modules/login/controllers/login_controller.dart';
import '../modules/login/repositories/auth_repository.dart';
import '../modules/media_detail/controllers/media_detail_service.dart';
import '../modules/plugin/services/plugin_palette_cache.dart';
import '../services/realm_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AppLog>()) {
      Get.put(AppLog(), permanent: true);
    }
    if (!Get.isRegistered<AppService>()) {
      Get.put(AppService(), permanent: true);
    }
    if (!Get.isRegistered<TotpService>()) {
      Get.put(TotpService(), permanent: true);
    }
    if (!Get.isRegistered<RealmService>()) {
      throw StateError('RealmService must be initialized before app start');
    }
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put(AuthRepository(), permanent: true);
    }
    if (!Get.isRegistered<LoginController>()) {
      Get.put(LoginController(), permanent: true);
    }
    if (!Get.isRegistered<MediaDetailService>()) {
      Get.put(MediaDetailService(), permanent: true);
    }
    if (!Get.isRegistered<PluginPaletteCache>()) {
      Get.put(PluginPaletteCache(), permanent: true);
    }
  }
}
