import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_config.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class SettingsSubListController extends GetxController {
  SettingsSubListController({required this.categoryId, required this.pageTitle});

  final String categoryId;
  final String pageTitle;
  final _appService = Get.find<AppService>();

  late final SettingsCategory _category;

  List<SettingsSubItem> get items => _category.items
      .where((item) => _appService.canAccessRoute(item.route))
      .toList();

  @override
  void onInit() {
    super.onInit();
    final list = settingsCategories.where((c) => c.id == categoryId).toList();
    if (list.isEmpty) {
      _category = SettingsCategory(
        id: categoryId,
        title: pageTitle,
        icon: Icons.settings_outlined,
        items: const [],
      );
      return;
    }
    _category = list.first;
  }

  void onSubItemTap(SettingsSubItem item) {
    if (!_appService.canAccessRoute(item.route)) {
      ToastUtil.info(_appService.accessDeniedMessage(item.route));
      return;
    }
    if (item.route != null && item.route!.isNotEmpty) {
      Get.toNamed(item.route!, arguments: {'title': item.title, 'categoryId': categoryId, 'subId': item.id});
      return;
    }
    ToastUtil.info('${item.title} 详情页待接入');
  }
}
