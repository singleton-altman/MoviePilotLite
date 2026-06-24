import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/cpu_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/media_stats_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/memory_widget.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/my_media_library_widget.dart';
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

import 'package:moviepilot_mobile/modules/login/models/login_profile.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';

import '../controllers/dashboard_controller.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final appService = Get.find<AppService>();
    return Obx(() {
      final hasDashboardBackground =
          appService.backgroundImageEnabled.value &&
          appService.backgroundImageBytes.value != null;
      final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;

      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildNavigationBar(context),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _buildPageBackground(
                appService,
                includeImage: hasDashboardBackground,
              ),
            ),
            Padding(
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildStitchLayout(context)],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: _bottomSpacer(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBackgroundImage(AppService appService) {
    return IgnorePointer(
      child: Obx(() {
        final bytes = appService.backgroundImageBytes.value;
        if (bytes == null) return const SizedBox.shrink();
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: appService.backgroundImageOpacity.value,
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      appService.backgroundImageGradientTop.value,
                      appService.backgroundImageGradientBottom.value,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPageBackground(
    AppService appService, {
    required bool includeImage,
  }) {
    final palette = DashboardPalette.of(Get.context!);
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: palette.pageBackground),
        if (includeImage) _buildBackgroundImage(appService),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.overlay.withValues(
                    alpha: palette.isDark ? 0.18 : 0.08,
                  ),
                  palette.pageBackgroundAlt,
                  palette.pageBackground,
                ],
                stops: const [0, 0.68, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.primary.withValues(
                      alpha: palette.isDark ? 0.18 : 0.10,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

          if (visible.contains('最近添加'))
            _buildOpenSection(
              title: '最近添加',
              actionLabel: '查看全部',
              child: const RecentlyAddedWidget(),
              onTapMore: () => Get.toNamed('/media-organize'),
            ),
          if (visible.contains('最近入库'))
            _buildCardSection(
              accentColor: DashboardPalette.of(context).warningAccent,
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
          if (visible.contains('我的媒体库'))
            _buildOpenSection(
              title: '媒体库',
              child: MyMediaLibraryWidget(
                onTap: (library) {
                  WebUtil.open(url: library.link);
                },
              ),
            ),
          if (visible.contains('继续观看'))
            _buildOpenSection(
              title: '继续观看',
              // actionLabel: '查看全部',
              child: const RecentlyPlayingWidget(),
            ),
          if (visible.contains('网络流量') && !visible.contains('实时速率'))
            _buildCardSection(
              title: '网络流量',
              accentColor: DashboardPalette.of(context).coolAccent,
              child: const NetworkTrafficWidget(),
              showBorder: false,
            ),
          if (visible.contains('媒体统计') && !visible.contains('存储空间'))
            _buildCardSection(
              title: '媒体统计',
              accentColor: DashboardPalette.of(context).warningAccent,
              child: const MediaStatsWidget(),
            ),
        ],
      );
    });
  }

  bool _showAny(Set<String> visible, Set<String> candidates) {
    return candidates.any(visible.contains);
  }

  Widget _buildServerStatusSection(BuildContext context, Set<String> visible) {
    final palette = DashboardPalette.of(context);
    final cards = <Widget>[];
    if (visible.contains('实时速率')) {
      cards.add(const RealTimeSpeedWidget(compact: true));
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards.map((card) {
              return SizedBox(
                width: (MediaQuery.sizeOf(context).width - 56) / 2,
                child: card,
              );
            }).toList(),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.tileBorder),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.surface,
                    Color.alphaBlend(
                      palette.primary.withValues(
                        alpha: palette.isDark ? 0.06 : 0.05,
                      ),
                      palette.pageBackgroundAlt,
                    ),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
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
    required Color accentColor,
    required Widget child,
    VoidCallback? onTapMore,
    bool showBorder = true,
  }) {
    final palette = DashboardPalette.of(Get.context!);
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
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: palette.tileBorder),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.surface,
                          Color.alphaBlend(
                            accentColor.withValues(
                              alpha: palette.isDark ? 0.05 : 0.04,
                            ),
                            palette.pageBackgroundAlt,
                          ),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.shadow,
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
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
      context: context,
      builder: (_) => const RecognizePage(),
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
      context: context,
      builder: (_) => const NetworkTestPage(),
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
      context: context,
      builder: (_) => const SystemHealthPage(),
    );
    if (Get.isRegistered<SystemHealthController>()) {
      Get.delete<SystemHealthController>();
    }
  }
}
