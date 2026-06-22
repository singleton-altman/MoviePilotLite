import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/pages/edit_dashboard_page.dart';
import 'package:moviepilot_mobile/modules/search/controllers/app_setting_controller.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

class AppSettingPage extends GetView<AppSettingController> {
  const AppSettingPage({super.key});

  static const String _repoUrl =
      'https://github.com/singleton-altman/MoviePilotLite';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('应用设置'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildAppInfoCard(context),
          _buildAppearanceSection(context),
          _buildSearchAndDownloadSection(context),
          _buildBrowserSection(context),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return Section(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.zero,
      header: const SectionHeader(title: '外观与首页', subtitle: '主题、背景、布局'),
      separatorBuilder: _buildDivider,
      children: [
        _buildNavigationTile(
          context,
          title: '主题风格',
          subtitle: '主题模式与主色设置',
          icon: Icons.palette_outlined,
          iconColor: CupertinoColors.activeBlue,
          onTap: () => Get.toNamed('/settings/app/theme-mode'),
        ),
        _buildNavigationTile(
          context,
          title: '背景图片',
          subtitle: '自定义应用背景与视觉氛围',
          icon: Icons.photo_outlined,
          iconColor: CupertinoColors.systemPurple,
          onTap: () => Get.toNamed('/settings/app/background-image'),
        ),
        _buildNavigationTile(
          context,
          title: '首页布局',
          subtitle: '编辑 Dashboard 的模块展示方式',
          icon: Icons.dashboard_customize_outlined,
          iconColor: CupertinoColors.systemTeal,
          onTap: () => _showEditDashboardModal(context),
        ),
      ],
    );
  }

  Widget _buildSearchAndDownloadSection(BuildContext context) {
    return Section(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.zero,
      header: const SectionHeader(title: '搜索与下载', subtitle: '入口、状态、直连'),
      separatorBuilder: _buildDivider,
      children: [
        Obx(
          () => _buildSwitchTile(
            context,
            title: '搜索按钮',
            subtitle: '控制首页是否展示快捷搜索入口',
            icon: Icons.search,
            iconColor: CupertinoColors.activeBlue,
            value: controller.showSearchButton.value,
            onChanged: controller.updateShowSearchButton,
          ),
        ),
        Obx(
          () => _buildSwitchTile(
            context,
            title: '搜索页入库状态',
            subtitle: '在搜索结果中显示媒体库收录状态',
            icon: Icons.video_library_outlined,
            iconColor: CupertinoColors.systemGreen,
            value: controller.enableFetchMediaserverLibraryStatus.value,
            onChanged: controller.updateEnableFetchMediaserverLibraryStatus,
          ),
        ),
        Obx(
          () => _buildSwitchTile(
            context,
            title: '下载器直连下载',
            subtitle: '下载前先保存本地种子文件并跳转直连下载页',
            icon: Icons.bolt_outlined,
            iconColor: CupertinoColors.systemOrange,
            value: controller.enableSpecialDownload.value,
            onChanged: (value) async {
              if (!value) {
                controller.updateEnableSpecialDownload(false);
                return;
              }
              ToastUtil.warning(
                '由于站点特殊性，下载器直连下载暂不能保证适配所有站点。如有特殊需求，请提交 PR。',
                onConfirm: () => controller.updateEnableSpecialDownload(true),
                onCancel: () => controller.updateEnableSpecialDownload(false),
              );
            },
          ),
        ),
        Obx(
          () => _buildSwitchTile(
            context,
            title: '下载器管理',
            subtitle: '由 App 直接连接下载器，不经过 MoviePilot 服务器',
            icon: Icons.download_outlined,
            iconColor: CupertinoColors.systemIndigo,
            value: controller.enableDownloaderManager.value,
            onChanged: (value) async {
              if (!value) {
                controller.updateEnableDownloaderManager(false);
                return;
              }
              ToastUtil.warning(
                '已启用 app 种子管理：请求由 App 直连下载器，不经过 MoviePilot 服务器，请确保网络可达。',
                onConfirm: () => controller.updateEnableDownloaderManager(true),
                onCancel: () => controller.updateEnableDownloaderManager(false),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrowserSection(BuildContext context) {
    return Section(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.zero,
      header: const SectionHeader(title: '浏览与实验', subtitle: '兼容性与访问方式'),
      separatorBuilder: _buildDivider,
      children: [
        Obx(
          () => _buildSwitchTile(
            context,
            title: '使用外部浏览器',
            subtitle: '部分站点场景下可获得更好的兼容性',
            icon: Icons.public,
            iconColor: CupertinoColors.systemPink,
            value: controller.useExternalBrowser.value,
            onChanged: controller.updateUseExternalBrowser,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Section(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      header: const SectionHeader(title: '关于应用', subtitle: '版本、日志、仓库'),
      separatorBuilder: _buildDivider,
      children: [
        Obx(
          () => _buildNavigationTile(
            context,
            title: '当前版本',
            subtitle: '已安装版本信息',
            icon: Icons.info_outline,
            iconColor: CupertinoColors.systemBlue,
            additionalInfo: controller.version.value,
          ),
        ),
        _buildNavigationTile(
          context,
          title: '更新日志',
          subtitle: '查看版本演进与功能更新记录',
          icon: Icons.history,
          iconColor: CupertinoColors.systemOrange,
          onTap: () => Get.toNamed('/settings/app/changelog'),
        ),
        _buildNavigationTile(
          context,
          title: '开源仓库',
          subtitle: '前往 GitHub 查看项目与发布信息',
          icon: Icons.open_in_new_rounded,
          iconColor: CupertinoColors.systemGrey,
          onTap: () => WebUtil.open(url: _repoUrl, internal: false),
        ),
      ],
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Obx(
      () => Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Assets.logo.svg(
                      colorFilter: ColorFilter.mode(primary, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MoviePilot',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '移动端设置与体验偏好',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    onPressed: () =>
                        WebUtil.open(url: _repoUrl, internal: false),
                    child: Text(
                      'GitHub',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        context,
                        label: '当前版本',
                        value: controller.version.value,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      color: theme.dividerColor.withValues(alpha: 0.28),
                    ),
                    Expanded(
                      child: _buildInfoColumn(
                        context,
                        label: '项目属性',
                        value: '开源移动客户端',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Text(
                'Copyright © 2026 Altman. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: onSurface.withValues(alpha: 0.48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.86),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
    String? additionalInfo,
  }) {
    return _buildSettingTile(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      additionalInfo: additionalInfo,
      trailing: onTap != null ? const CupertinoListTileChevron() : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingTile(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      onTap: () => onChanged(!value),
      trailing: Switch.adaptive(
        padding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
    String? additionalInfo,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CupertinoListTile.notched(
      padding: const EdgeInsetsDirectional.only(
        start: 14,
        end: 12,
        top: 8,
        bottom: 8,
      ),
      leading: _buildLeadingIcon(context, icon: icon, color: iconColor),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            )
          : null,
      additionalInfo: additionalInfo != null
          ? Text(
              additionalInfo,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildLeadingIcon(
    BuildContext context, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 0.1,
      color: Theme.of(context).dividerColor,
      indent: 58,
      endIndent: 16,
    );
  }

  Future<void> _showEditDashboardModal(BuildContext context) async {
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    await showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (_) => const EditDashboardPage(),
    );
  }
}
