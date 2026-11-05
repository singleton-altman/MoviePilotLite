import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/pages/edit_dashboard_page.dart';
import 'package:moviepilot_mobile/modules/search/controllers/app_setting_controller.dart';
import 'package:moviepilot_mobile/modules/search/pages/update_mirror_sheet.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildAppHeaderCard(context),
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
      header: const SectionHeader(title: '外观与首页'),
      separatorBuilder: _buildDivider,
      children: [
        _buildNavigationTile(
          context,
          title: '主题风格',
          icon: Icons.palette_outlined,
          iconColor: CupertinoColors.activeBlue,
          onTap: () => Get.toNamed('/settings/app/theme-mode'),
        ),
        _buildNavigationTile(
          context,
          title: '背景图片',
          icon: Icons.photo_outlined,
          iconColor: CupertinoColors.systemPurple,
          onTap: () => Get.toNamed('/settings/app/background-image'),
        ),
        _buildNavigationTile(
          context,
          title: '首页布局',
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
      header: const SectionHeader(title: '搜索与下载'),
      separatorBuilder: _buildDivider,
      children: [
        Obx(
          () => _buildSwitchTile(
            context,
            title: '搜索按钮',
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
      header: const SectionHeader(title: '浏览'),
      separatorBuilder: _buildDivider,
      children: [
        Obx(
          () => _buildSwitchTile(
            context,
            title: '使用外部浏览器',
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
      header: const SectionHeader(title: '关于'),
      separatorBuilder: _buildDivider,
      children: [
        Obx(
          () => _buildNavigationTile(
            context,
            title: '版本更新',
            icon: Icons.system_update_alt_rounded,
            iconColor: CupertinoColors.systemBlue,
            additionalInfo: controller.updateStatusText,
            onTap: () => controller.handleVersionTap(context),
          ),
        ),
        Obx(
          () => _buildNavigationTile(
            context,
            title: '更新下载线路',
            icon: Icons.speed_rounded,
            iconColor: CupertinoColors.systemGreen,
            additionalInfo: controller.updateMirrorLabel,
            onTap: () => showUpdateMirrorSheet(
              context,
              sourceUrl: controller.updateInfo.value?.apkDownloadUrl ?? '',
            ),
          ),
        ),
        _buildNavigationTile(
          context,
          title: '更新日志',
          icon: Icons.history,
          iconColor: CupertinoColors.systemOrange,
          onTap: () => Get.toNamed('/settings/app/changelog'),
        ),
        _buildNavigationTile(
          context,
          title: '开源仓库',
          icon: Icons.open_in_new_rounded,
          iconColor: CupertinoColors.systemGrey,
          onTap: () => WebUtil.open(url: _repoUrl, internal: false),
        ),
      ],
    );
  }

  /// 顶部应用信息：品牌、当前版本与仓库入口，单行呈现。
  Widget _buildAppHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Obx(
      () => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Assets.logo.svg(
                colorFilter: ColorFilter.mode(primary, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MoviePilot',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => controller.handleVersionTap(context),
                    child: Text(
                      controller.version.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              onPressed: () => WebUtil.open(url: _repoUrl, internal: false),
              child: Text(
                'GitHub',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
    String? additionalInfo,
  }) {
    return _buildSettingTile(
      context,
      title: title,
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
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingTile(
      context,
      title: title,
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
        top: 4,
        bottom: 4,
      ),
      leading: _buildLeadingIcon(context, icon: icon, color: iconColor),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      additionalInfo: additionalInfo != null
          ? Text(
              additionalInfo,
              style: theme.textTheme.bodySmall?.copyWith(
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
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 0.1,
      color: Theme.of(context).dividerColor,
      indent: 54,
      endIndent: 16,
    );
  }

  Future<void> _showEditDashboardModal(BuildContext context) async {
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => const EditDashboardPage(),
    );
  }
}
