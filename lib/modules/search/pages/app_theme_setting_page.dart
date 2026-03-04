import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/controllers/app_setting_controller.dart';
import 'package:moviepilot_mobile/theme/section.dart';

class AppThemeSettingPage extends GetView<AppSettingController> {
  const AppThemeSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('主题模式'), centerTitle: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Section(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          separatorBuilder: (context) => Divider(
            height: 0.1,
            color: Theme.of(context).dividerColor,
            endIndent: 16,
            indent: 16,
          ),
          children: [ThemeMode.system, ThemeMode.light, ThemeMode.dark]
              .map(
                (themeMode) => _buildThemeMode(context, themeMode, () {
                  controller.updateThemeMode(themeMode);
                }),
              )
              .toList(),
        ),
      ),
    );
  }

  String _themeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  IconData _themeModeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_5;
      case ThemeMode.dark:
        return Icons.brightness_2;
    }
  }

  Widget _buildThemeMode(
    BuildContext context,
    ThemeMode themeMode,
    VoidCallback onTap,
  ) {
    final color = Theme.of(context).primaryColor;
    return ListTile(
      // leading: Icon(_themeModeIcon(themeMode), size: 24),
      title: Text(
        _themeModeName(themeMode),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
      trailing: themeMode == controller.themeMode.value
          ? Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.check, color: Colors.white, size: 15),
            )
          : null,
      onTap: onTap,
    );
  }
}
