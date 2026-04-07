import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/shortcut_popover.dart';
import 'package:moviepilot_mobile/modules/network_test/controllers/network_test_controller.dart';
import 'package:moviepilot_mobile/modules/network_test/pages/network_test_page.dart';
import 'package:moviepilot_mobile/modules/system_health/controllers/system_health_controller.dart';
import 'package:moviepilot_mobile/modules/system_health/pages/system_health_page.dart';
import 'package:moviepilot_mobile/modules/recognize/controllers/recognize_controller.dart';
import 'package:moviepilot_mobile/modules/recognize/pages/recognize_page.dart';
import 'package:moviepilot_mobile/modules/system_message/controllers/system_message_controller.dart';

import 'package:moviepilot_mobile/services/realm_service.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/modules/login/models/login_profile.dart';
import 'package:realm/realm.dart';

import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});
  Realm? get _realmService => Get.find<RealmService>().realm.value;

  @override
  Widget build(BuildContext context) {
    final appService = Get.find<AppService>();
    return Obx(() {
      final hasDashboardBackground =
          appService.backgroundImageEnabled.value &&
          appService.backgroundImageBytes.value != null;
      final topInset = hasDashboardBackground
          ? MediaQuery.paddingOf(context).top + kToolbarHeight
          : 0.0;

      return Scaffold(
        extendBodyBehindAppBar: hasDashboardBackground,
        appBar: _buildNavigationBar(
          context,
          transparent: hasDashboardBackground,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (hasDashboardBackground)
              Positioned.fill(child: _buildBackgroundImage(appService)),
            Padding(
              padding: EdgeInsets.only(top: topInset),
              child: CustomScrollView(
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      await controller.refreshData();
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildWidgetGrid(
                        context,
                        translucentSections: hasDashboardBackground,
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

  double _bottomSpacer(BuildContext context) {
    return 100;
  }

  /// 获取最新的登录配置文件
  LoginProfile? _getLatestLoginProfile() {
    try {
      final realm = _realmService;
      if (realm == null) return null;
      final profiles = realm.all<LoginProfile>();
      if (profiles.isEmpty) {
        return null;
      }
      // 按更新时间排序，返回最新的登录配置
      final sortedProfiles = profiles.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sortedProfiles.first;
    } catch (e) {
      // 如果获取失败，返回null
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
  AppBar _buildNavigationBar(BuildContext context, {bool transparent = false}) {
    // 获取最新的登录配置文件
    final loginProfile = _getLatestLoginProfile();

    return AppBar(
      backgroundColor: transparent ? Colors.transparent : null,
      elevation: transparent ? 0 : null,
      scrolledUnderElevation: transparent ? 0 : null,
      surfaceTintColor: transparent ? Colors.transparent : null,
      leading: Builder(
        builder: (buttonContext) => CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showShortcuts(buttonContext),
          child: const Icon(CupertinoIcons.app_badge),
        ),
      ),
      title: Text(
        'Dashboard',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      actions: [
        Builder(
          builder: (context) {
            if (!Get.isRegistered<SystemMessageController>()) {
              return CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Get.toNamed('/system-message'),
                child: const Stack(children: [Icon(CupertinoIcons.mail)]),
              );
            }
            return Obx(() {
              final hasUnread =
                  Get.find<SystemMessageController>().hasUnreadMessages.value;
              return CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Get.toNamed('/system-message'),
                child: Stack(
                  children: [
                    const Icon(CupertinoIcons.mail),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: CupertinoColors.systemRed,
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
          padding: EdgeInsets.symmetric(horizontal: 12),
          onPressed: () => _showProfile(context),
          child:
              loginProfile != null &&
                  loginProfile.avatar != null &&
                  loginProfile.avatar!.isNotEmpty
              ? () {
                  final avatarBytes = _decodeAvatar(loginProfile.avatar!);
                  if (avatarBytes.isNotEmpty) {
                    return Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: MemoryImage(avatarBytes),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  } else {
                    return const Icon(CupertinoIcons.person_circle);
                  }
                }()
              : Assets.images.avatars.avatar1.image(width: 34, height: 34),
        ),
      ],
    );
  }

  /// 构建组件网格
  Widget _buildWidgetGrid(
    BuildContext context, {
    bool translucentSections = false,
  }) {
    return Obx(() {
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: controller.displayedWidgets
            .map((widget) => _buildWidgetCard(context, widget))
            .toList(),
      );
      if (!translucentSections) return content;
      final theme = Theme.of(context);
      final translucentCardColor = theme.cardColor.withValues(alpha: 0.7);
      return Theme(
        data: theme.copyWith(cardColor: translucentCardColor),
        child: content,
      );
    });
  }

  /// 构建组件卡片
  Widget _buildWidgetCard(BuildContext context, String widgetType) {
    return DashboardWidgets.buildWidget(widgetType);
  }

  /// 显示捷径
  void _showShortcuts(BuildContext context) {
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
    await showCupertinoModalBottomSheet<void>(
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
    await showCupertinoModalBottomSheet<void>(
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
    await showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (_) => const SystemHealthPage(),
    );
    if (Get.isRegistered<SystemHealthController>()) {
      Get.delete<SystemHealthController>();
    }
  }
}
