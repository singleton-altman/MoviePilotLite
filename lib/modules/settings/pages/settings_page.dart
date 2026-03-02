import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/controllers/settings_controller.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_config.dart';

/// 设定页：单页展示，iOS 设置风格（分组 + 分区标题 + 行）
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.back(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('设定', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
          context,
        ),
        border: null,
      ),
      child: CustomScrollView(
        slivers: [
          SliverCupertinoListSection(
            categories: controller.categories,
            onRowTap: controller.onRowTap,
          ),
        ],
      ),
    );
  }
}

/// 使用 Cupertino 分组列表展示所有分类，每分类一个 section，section 内为子项行
class SliverCupertinoListSection extends StatelessWidget {
  const SliverCupertinoListSection({
    super.key,
    required this.categories,
    required this.onRowTap,
  });

  final List<SettingsCategory> categories;
  final void Function(SettingsCategory category, SettingsSubItem? item)
  onRowTap;

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

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final category = categories[index];
        final isServiceRow =
            category.directRoute != null && category.items.isEmpty;
        final rowCount = isServiceRow ? 1 : category.items.length;

        return CupertinoListSection.insetGrouped(
          backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
            context,
          ),
          header: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Text(
              category.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          children: [
            for (int i = 0; i < rowCount; i++)
              _buildTile(
                context,
                category: category,
                item: isServiceRow ? null : category.items[i],
                displayTitle: isServiceRow ? '后台任务' : category.items[i].title,
                displaySubtitle: isServiceRow
                    ? null
                    : category.items[i].subtitle,
                icon: isServiceRow
                    ? category.icon
                    : (category.items[i].icon ?? category.icon),
                iconColor: _iconColorForCategory(category),
                onTap: () =>
                    onRowTap(category, isServiceRow ? null : category.items[i]),
              ),
          ],
        );
      }, childCount: categories.length),
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
}
