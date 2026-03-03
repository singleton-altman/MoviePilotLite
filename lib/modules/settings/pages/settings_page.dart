import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/controllers/settings_controller.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_config.dart';
import 'package:moviepilot_mobile/theme/section.dart';

/// 设定页：单页展示，iOS 设置风格（分组 + 分区标题 + 行）
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.back(),
          child: const Icon(CupertinoIcons.back),
        ),
        title: const Text('设定'),
        centerTitle: false,
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final category = controller.categories[index];
          final rowCount = category.items.length;
          return Section(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(0),
            separatorBuilder: (context) {
              return Divider(height: 1, color: Theme.of(context).dividerColor);
            },
            header: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Text(
                category.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              ),
            ),
            children: [
              for (int i = 0; i < rowCount; i++)
                _buildTile(
                  context,
                  category: category,
                  item: category.items[i],
                  displayTitle: category.items[i].title,
                  displaySubtitle: category.items[i].subtitle,
                  icon: category.items[i].icon ?? category.icon,
                  iconColor: _iconColorForCategory(category),
                  onTap: () => controller.onRowTap(category, category.items[i]),
                ),
            ],
          );
        },
        itemCount: controller.categories.length,
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required SettingsCategory category,
    required SettingsSubItem? item,
    required String displayTitle,
    required String? displaySubtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return CupertinoListTile.notched(
      leading: Container(
        width: 29,
        height: 29,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(displayTitle),
      // subtitle: displaySubtitle != null ? Text(displaySubtitle) : null,
      trailing: const CupertinoListTileChevron(),
      onTap: onTap,
    );
  }

  static Color _iconColorForCategory(SettingsCategory category) {
    switch (category.id) {
      case SettingsCategoryId.system:
        return CupertinoColors.systemIndigo;
      case SettingsCategoryId.storage:
        return CupertinoColors.systemBrown;
      case SettingsCategoryId.site:
        return CupertinoColors.systemBlue;
      case SettingsCategoryId.rule:
        return CupertinoColors.systemPurple;
      case SettingsCategoryId.search:
        return CupertinoColors.systemTeal;
      case SettingsCategoryId.subscribe:
        return CupertinoColors.systemOrange;
      case SettingsCategoryId.service:
        return CupertinoColors.systemGreen;
      case SettingsCategoryId.notification:
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
