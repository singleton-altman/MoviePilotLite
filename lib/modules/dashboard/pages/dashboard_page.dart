import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/cpu_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/media_stats_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/memory_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/my_media_library_widget.dart';
import 'package:moviepilot_mobile/modules/player/controllers/player_launch_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/network_traffic_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/recent_added_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/recently_added_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/recently_playing_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/real_time_speed_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/schedule_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/storage_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/shortcut_popover.dart';
import 'package:moviepilot_mobile/modules/network_test/controllers/network_test_controller.dart';
import 'package:moviepilot_mobile/modules/network_test/pages/network_test_page.dart';
import 'package:moviepilot_mobile/modules/system_health/controllers/system_health_controller.dart';
import 'package:moviepilot_mobile/modules/system_health/pages/system_health_page.dart';
import 'package:moviepilot_mobile/modules/recognize/controllers/recognize_controller.dart';
import 'package:moviepilot_mobile/modules/recognize/pages/recognize_page.dart';
import 'package:moviepilot_mobile/modules/system_message/controllers/system_message_controller.dart';

import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/widgets/constrained_page_content.dart';
import 'package:moviepilot_mobile/widgets/dashboard_scaffold.dart';

import '../controllers/dashboard_controller.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return DashboardScaffold(
      appBar: _buildNavigationBar(context),
      body: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await controller.refreshData();
              },
            ),
            SliverToBoxAdapter(
              child: ConstrainedPageContent(
                padding: const EdgeInsets.only(top: 20),
                child: _buildStitchLayout(context),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: _bottomSpacer(context))),
          ],
        ),
      ),
    );
  }

  double _bottomSpacer(BuildContext context) {
    return 100;
  }

  String? _dashboardBarAvatar() {
    try {
      final app = Get.find<AppService>();
      // Try appService in-memory profile first
      final u = app.userInfo?.avatar;
      if (u != null && u.isNotEmpty) return u;
      final lr = app.loginResponse?.avatar;
      if (lr != null && lr.isNotEmpty) return lr;
      // Fall back to stored profile cache
      final profile = app.currentStoredProfile;
      return profile?.avatar;
    } catch (_) {
      return null;
    }
  }

  /// 解码头像
  Uint8List _decodeAvatar(String avatar) {
    try {
      // 检查是否是data URL格式
      if (avatar.startsWith('data:image')) {
        // 提取base64部分
        final commaIndex = avatar.indexOf(',');
        if (commaIndex != -1) {
          final base64String = avatar.substring(commaIndex + 1);
          return Uint8List.fromList(base64Decode(base64String));
        }
      }
      // 否则，直接解码
      return Uint8List.fromList(base64Decode(avatar));
    } catch (e) {
      // 如果解码失败，返回空列表
      return Uint8List(0);
    }
  }

  /// 构建导航栏
  AppBar _buildNavigationBar(BuildContext context) {
    final avatarStr = _dashboardBarAvatar();
    final palette = DashboardPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuperuser = Get.find<AppService>().isSuperuser;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      titleSpacing: 0,
      leading: Builder(
        builder: (buttonContext) => CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showShortcuts(buttonContext),
          child: Icon(
            CupertinoIcons.square_grid_2x2_fill,
            size: 18,
            color: palette.primary,
          ),
        ),
      ),
      title: const Text(
        'Dashboard',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: [
        if (isSuperuser)
          Builder(
            builder: (context) {
              if (!Get.isRegistered<SystemMessageController>()) {
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Get.toNamed('/system-message'),
                  child: _buildActionBadge(
                    child: Icon(
                      CupertinoIcons.dot_radiowaves_left_right,
                      size: 18,
                      color: palette.mutedText,
                    ),
                  ),
                );
              }
              return Obx(() {
                final hasUnread =
                    Get.find<SystemMessageController>().hasUnreadMessages.value;
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Get.toNamed('/system-message'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildActionBadge(
                        child: Icon(
                          CupertinoIcons.dot_radiowaves_left_right,
                          size: 18,
                          color: palette.mutedText,
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: palette.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              });
            },
          ),
        CupertinoButton(
          padding: const EdgeInsets.only(left: 6, right: 12),
          onPressed: () => _showProfile(context),
          child: _buildDashboardAvatar(avatarStr, palette),
        ),
      ],
    );
  }

  Widget _buildDashboardAvatar(String? avatar, DashboardPaletteData palette) {
    final avatarBytes = avatar == null || avatar.trim().isEmpty
        ? Uint8List(0)
        : _decodeAvatar(avatar);

    if (avatarBytes.isEmpty) {
      return ClipOval(
        child: Assets.images.avatars.avatar1.image(
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: palette.primary.withValues(alpha: 0.42)),
        image: DecorationImage(
          image: MemoryImage(avatarBytes),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildActionBadge({required Widget child}) {
    final palette = DashboardPalette.of(Get.context!);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: palette.tileSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.tileBorder),
      ),
      child: child,
    );
  }

  Widget _buildStitchLayout(BuildContext context) {
    return Obx(() {
      final visible = controller.displayedWidgets.toSet();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showAny(visible, {'实时速率', '存储空间', 'CPU', '内存'}))
            _buildServerStatusSection(context, visible),

          if (_showAny(visible, {'媒体统计', '存储空间'}))
            _buildLibraryCapacitySection(context),

          if (_showAny(visible, {'最近添加', '我的媒体库', '继续观看'}))
            _buildMediaBrowseSection(context, visible),
          if (visible.contains('最近入库'))
            _buildCardSection(
              child: const RecentAddedWidget(),
              onTapMore: () => Get.toNamed('/media-organize'),
            ),
          if (visible.contains('后台任务'))
            _buildOpenSection(
              title: '任务',
              child: const ScheduleWidget(),
              actionLabel: '查看全部',
              onTapMore: () => Get.toNamed('/background-task-list'),
            ),
          if (visible.contains('网络流量') && !visible.contains('实时速率'))
            _buildCardSection(
              title: '网络流量',
              child: const NetworkTrafficWidget(),
              showBorder: false,
            ),
          if (visible.contains('媒体统计') && !visible.contains('存储空间'))
            _buildCardSection(title: '媒体统计', child: const MediaStatsWidget()),
        ],
      );
    });
  }

  bool _showAny(Set<String> visible, Set<String> candidates) {
    return candidates.any(visible.contains);
  }

  Widget _buildMediaBrowseSection(BuildContext context, Set<String> visible) {
    final palette = DashboardPalette.of(context);
    final rails = <Widget>[];

    if (visible.contains('继续观看')) {
      rails.add(
        _buildMediaRail(
          title: '继续观看',
          subtitle: '从上次进度继续',
          icon: CupertinoIcons.play_circle_fill,
          accentColor: palette.warningAccent,
          actionLabel: '查看全部',
          onTapMore: () => RecentlyPlayingWidget.showAllSheet(context),
          child: const RecentlyPlayingWidget(),
        ),
      );
    }
    if (visible.contains('最近添加')) {
      rails.add(
        _buildMediaRail(
          title: '最近添加',
          subtitle: '新入库的海报墙',
          icon: CupertinoIcons.sparkles,
          accentColor: palette.primary,
          actionLabel: '查看全部',
          onTapMore: () => RecentlyAddedWidget.showAllSheet(context),
          child: const RecentlyAddedWidget(),
        ),
      );
    }
    if (visible.contains('我的媒体库')) {
      rails.add(
        _buildMediaRail(
          title: '媒体库',
          subtitle: '按服务与类型浏览',
          icon: CupertinoIcons.rectangle_stack_fill,
          accentColor: palette.coolAccent,
          child: MyMediaLibraryWidget(
            onTap: (library) {
              // 管理员进入 MP 内嵌媒体库浏览;普通用户维持网页方式
              if (PlayerLaunchController.to.canNativePlay) {
                Get.toNamed('/media-library-browser', arguments: {
                  'libraryId': library.id,
                  'libraryName': library.name,
                });
                return;
              }
              WebUtil.open(url: library.link);
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: '媒体浏览',
            action: DashboardInfoPill(
              text: '媒体中心',
              color: palette.primary,
              icon: CupertinoIcons.play_rectangle_fill,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < rails.length; index++) ...[
            rails[index],
            if (index != rails.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaRail({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Widget child,
    String? actionLabel,
    VoidCallback? onTapMore,
  }) {
    final palette = DashboardPalette.of(Get.context!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: palette.isDark ? 0.16 : 0.11,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: palette.titleText,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onTapMore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(
                        alpha: palette.isDark ? 0.12 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildServerStatusSection(BuildContext context, Set<String> visible) {
    final palette = DashboardPalette.of(context);
    final cards = <Widget>[];
    if (visible.contains('实时速率')) {
      cards.add(
        InkWell(
          child: const RealTimeSpeedWidget(compact: true),
          onTap: () => Get.toNamed('/downloader-config'),
        ),
      );
    }
    if (visible.contains('存储空间')) {
      cards.add(
        GestureDetector(
          onTap: () => Get.toNamed('/storage-list'),
          child: const StorageWidget(compact: true),
        ),
      );
    }
    if (visible.contains('CPU')) {
      cards.add(const CpuWidget(compact: true));
    }
    if (visible.contains('内存')) {
      cards.add(const MemoryWidget(compact: true));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: '状态',
            action: DashboardInfoPill(
              text: '运行正常',
              color: palette.successAccent,
              icon: CupertinoIcons.circle_fill,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 16.0;
              final cardWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards
                    .map((card) => SizedBox(width: cardWidth, child: card))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryCapacitySection(BuildContext context) {
    return Obx(() {
      final palette = DashboardPalette.of(context);
      final storage = controller.storageData;
      final stats = controller.statisticData.value;
      final totalStorage = (storage['total_storage'] ?? 0.0) as double;
      final movieCount = stats?.movie_count ?? 0;
      final tvCount = stats?.tv_count ?? 0;
      final episodeCount = stats?.episode_count ?? 0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: DashboardMetricCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '媒体库容量',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: palette.mutedText,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    CupertinoIcons.chart_bar_square_fill,
                    color: palette.primary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                totalStorage > 0
                    ? SizeFormatter.formatSize(totalStorage, 1)
                    : '0 B',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: palette.titleText,
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: palette.divider),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DashboardMiniStat(
                      label: '电影',
                      value: '$movieCount',
                      valueColor: palette.titleText,
                    ),
                  ),
                  Expanded(
                    child: DashboardMiniStat(
                      label: '剧集',
                      value: '$tvCount',
                      valueColor: palette.titleText,
                      crossAxisAlignment: CrossAxisAlignment.center,
                    ),
                  ),
                  Expanded(
                    child: DashboardMiniStat(
                      label: '集数',
                      value: '$episodeCount',
                      valueColor: palette.titleText,
                      crossAxisAlignment: CrossAxisAlignment.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOpenSection({
    required String title,
    String? actionLabel,
    required Widget child,
    VoidCallback? onTapMore,
  }) {
    final palette = DashboardPalette.of(Get.context!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: title,
            action: actionLabel == null
                ? null
                : GestureDetector(
                    onTap: onTapMore,
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: palette.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCardSection({
    String title = '',
    required Widget child,
    VoidCallback? onTapMore,
    bool showBorder = true,
  }) {
    return GestureDetector(
      onTap: onTapMore,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              _buildSectionTitle(title: title),
              const SizedBox(height: 16),
            ],
            if (showBorder)
              DashboardMetricCard(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            if (!showBorder) child,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required String title, Widget? action}) {
    final context = Get.context!;
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? theme.colorScheme.onSurface;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: titleColor,
            ),
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  /// 显示捷径
  void _showShortcuts(BuildContext context) {
    final isSuperuser = Get.find<AppService>().isSuperuser;
    final overlay = Overlay.of(context);

    // 计算按钮在屏幕中的位置，用于锚定菜单
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final target = box.localToGlobal(Offset.zero);
    final size = box.size;

    final shortcuts = <ShortcutItem>[
      ShortcutItem(
        icon: CupertinoIcons.textformat,
        title: '识别',
        subtitle: '标题/副标题识别',
        onTap: () => _showRecognizeModal(context),
      ),
      const ShortcutItem(
        icon: CupertinoIcons.settings,
        title: 'TODO: 规则',
        subtitle: '规则测试',
      ),
      ShortcutItem(
        icon: CupertinoIcons.doc_text,
        title: '日志',
        subtitle: '实时日志',
        onTap: () => Get.toNamed('/server-log'),
      ),
      ShortcutItem(
        icon: CupertinoIcons.desktopcomputer,
        title: '网络测试',
        subtitle: '网速连通性测试',
        onTap: () => _showNetworkTestModal(context),
      ),
      const ShortcutItem(
        icon: CupertinoIcons.text_alignleft,
        title: 'TODO: 词表',
        subtitle: '词表设置',
      ),
      ShortcutItem(
        icon: CupertinoIcons.cube_box,
        title: '缓存',
        subtitle: '管理缓存',
        onTap: () => Get.toNamed('/cache'),
      ),
      ShortcutItem(
        icon: CupertinoIcons.gear_alt_fill,
        title: '系统',
        subtitle: '健康检查',
        onTap: () => _showSystemHealthModal(context),
      ),
      if (isSuperuser)
        ShortcutItem(
          icon: CupertinoIcons.chat_bubble_2_fill,
          title: '消息',
          subtitle: '消息中心',
          onTap: () => Get.toNamed('/system-message'),
        ),
    ];

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return ShortcutPopover(
          target: target,
          targetSize: size,
          items: shortcuts,
          onClose: () => entry.remove(),
        );
      },
    );

    overlay.insert(entry);
  }

  /// 显示个人资料
  void _showProfile(BuildContext context) {
    Get.toNamed('/profile');
  }

  /// 显示识别模块（Modal）
  Future<void> _showRecognizeModal(BuildContext context) async {
    if (Get.isRegistered<RecognizeController>()) {
      Get.delete<RecognizeController>();
    }
    Get.put(RecognizeController());
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.36,
        maxChildSize: 1,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: RecognizePage(scrollController: scrollController),
        ),
      ),
    );
    if (Get.isRegistered<RecognizeController>()) {
      Get.delete<RecognizeController>();
    }
  }

  /// 显示网络测试（Modal）
  Future<void> _showNetworkTestModal(BuildContext context) async {
    if (Get.isRegistered<NetworkTestController>()) {
      Get.delete<NetworkTestController>();
    }
    Get.put(NetworkTestController());
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.36,
        maxChildSize: 1,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: NetworkTestPage(scrollController: scrollController),
        ),
      ),
    );
    if (Get.isRegistered<NetworkTestController>()) {
      Get.delete<NetworkTestController>();
    }
  }

  /// 显示系统健康检查（Modal）
  Future<void> _showSystemHealthModal(BuildContext context) async {
    if (Get.isRegistered<SystemHealthController>()) {
      Get.delete<SystemHealthController>();
    }
    Get.put(SystemHealthController());
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: SystemHealthPage(),
        ),
      ),
    );
    if (Get.isRegistered<SystemHealthController>()) {
      Get.delete<SystemHealthController>();
    }
  }
}
