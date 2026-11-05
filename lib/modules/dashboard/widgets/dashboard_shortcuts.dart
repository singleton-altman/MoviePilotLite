import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/shortcut_popover.dart';
import 'package:moviepilot_mobile/modules/network_test/controllers/network_test_controller.dart';
import 'package:moviepilot_mobile/modules/network_test/pages/network_test_page.dart';
import 'package:moviepilot_mobile/modules/recognize/controllers/recognize_controller.dart';
import 'package:moviepilot_mobile/modules/recognize/pages/recognize_page.dart';
import 'package:moviepilot_mobile/modules/system_health/controllers/system_health_controller.dart';
import 'package:moviepilot_mobile/modules/system_health/pages/system_health_page.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// 顶栏捷径弹层与「快捷操作」卡片共用的工具入口定义，避免两处入口各自维护一份清单。
class DashboardShortcuts {
  DashboardShortcuts._();

  /// 顶栏捷径弹层展示的完整清单（含尚未实现的占位项）
  static List<ShortcutItem> popoverItems(BuildContext context) {
    final isSuperuser = Get.find<AppService>().isSuperuser;
    return [
      ShortcutItem(
        icon: CupertinoIcons.textformat,
        title: '识别',
        subtitle: '标题/副标题识别',
        onTap: () => showRecognizeModal(context),
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
        onTap: () => showNetworkTestModal(context),
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
        onTap: () => showSystemHealthModal(context),
      ),
      if (isSuperuser)
        ShortcutItem(
          icon: CupertinoIcons.chat_bubble_2_fill,
          title: '消息',
          subtitle: '消息中心',
          onTap: () => Get.toNamed('/system-message'),
        ),
    ];
  }

  /// 仪表板「快捷操作」卡片展示的清单：只保留可直接触发的入口，按 4 列排成两行。
  static List<ShortcutItem> quickActionItems(BuildContext context) {
    return [
      ShortcutItem(
        icon: CupertinoIcons.textformat,
        title: '识别',
        subtitle: '标题/副标题识别',
        onTap: () => showRecognizeModal(context),
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
        onTap: () => showNetworkTestModal(context),
      ),
      ShortcutItem(
        icon: CupertinoIcons.gear_alt_fill,
        title: '系统',
        subtitle: '健康检查',
        onTap: () => showSystemHealthModal(context),
      ),
      ShortcutItem(
        icon: CupertinoIcons.cube_box,
        title: '缓存',
        subtitle: '管理缓存',
        onTap: () => Get.toNamed('/cache'),
      ),
      ShortcutItem(
        icon: CupertinoIcons.list_bullet_below_rectangle,
        title: '后台任务',
        subtitle: '定时服务',
        onTap: () => Get.toNamed('/background-task-list'),
      ),
      ShortcutItem(
        icon: CupertinoIcons.arrow_down_circle_fill,
        title: '下载管理',
        subtitle: '下载任务',
        onTap: () => Get.toNamed('/downloader'),
      ),
      ShortcutItem(
        icon: CupertinoIcons.folder_fill,
        title: '文件管理',
        subtitle: '浏览存储文件',
        onTap: () => Get.toNamed('/file-manager'),
      ),
    ];
  }

  /// 显示识别模块（Modal）
  static Future<void> showRecognizeModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => _SheetControllerScope<RecognizeController>(
        create: RecognizeController.new,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.36,
          maxChildSize: 1,
          builder: (context, scrollController) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: RecognizePage(scrollController: scrollController),
          ),
        ),
      ),
    );
  }

  /// 显示网络测试（Modal）
  static Future<void> showNetworkTestModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => _SheetControllerScope<NetworkTestController>(
        create: NetworkTestController.new,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.36,
          maxChildSize: 1,
          builder: (context, scrollController) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: NetworkTestPage(scrollController: scrollController),
          ),
        ),
      ),
    );
  }

  /// 显示系统健康检查（Modal）
  static Future<void> showSystemHealthModal(BuildContext context) async {
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => _SheetControllerScope<SystemHealthController>(
        create: SystemHealthController.new,
        child: const FractionallySizedBox(
          heightFactor: 0.92,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: SystemHealthPage(),
          ),
        ),
      ),
    );
  }
}

/// 弹层内容的 GetX 控制器生命周期托管。
///
/// showModalBottomSheet 的 Future 在 pop 开始时即完成，若在 await 之后才
/// Get.delete，控制器会在退场动画期间被删掉，而弹层 Obx 仍挂载，在途的
/// Rx 通知会触发 "controller not found"。改为挂载时注册、子树卸载完才
/// 注销（Element 卸载顺序保证后代先于本组件 dispose），消除该窗口。
class _SheetControllerScope<T> extends StatefulWidget {
  const _SheetControllerScope({required this.create, required this.child});

  final T Function() create;
  final Widget child;

  @override
  State<_SheetControllerScope<T>> createState() =>
      _SheetControllerScopeState<T>();
}

class _SheetControllerScopeState<T> extends State<_SheetControllerScope<T>> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<T>()) {
      Get.delete<T>();
    }
    Get.put<T>(widget.create());
  }

  @override
  void dispose() {
    if (Get.isRegistered<T>()) {
      Get.delete<T>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
