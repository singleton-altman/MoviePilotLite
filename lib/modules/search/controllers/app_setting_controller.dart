import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingController extends GetxController {
  final themeMode = ThemeMode.system.obs;
  final service = Get.find<AppService>();

  @override
  void onInit() {
    super.onInit();
    themeMode.value = service.themeMode.value;
  }

  void updateThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    service.updateThemeMode(mode);
  }
}
