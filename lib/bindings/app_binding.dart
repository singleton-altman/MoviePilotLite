import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:altman_totp/services/totp_service.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

import '../modules/login/controllers/login_controller.dart';
import '../modules/login/repositories/auth_repository.dart';
import '../modules/media_detail/controllers/media_detail_service.dart';
import '../modules/plugin/services/plugin_palette_cache.dart';
import '../modules/search/services/search_keyword_hints_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppLog(), permanent: true);
    Get.put(AppService(), permanent: true);
    Get.put(TotpService(), permanent: true);
    Get.put(AuthRepository(), permanent: true);
    Get.put(LoginController(), permanent: true);
    Get.put(MediaDetailService(), permanent: true);
    Get.put(PluginPaletteCache(), permanent: true);
    Get.put(SearchKeywordHintsService(), permanent: true);
  }
}
