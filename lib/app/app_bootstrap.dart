import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_service.dart';
import 'package:moviepilot_mobile/modules/search/services/app_update_service.dart';
import 'package:moviepilot_mobile/modules/search/services/update_mirror_store.dart';
import 'package:moviepilot_mobile/modules/search/services/update_speed_tester.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';
import 'package:moviepilot_mobile/services/ios_widget_navigation_service.dart';
import 'package:moviepilot_mobile/services/jpush_service.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/hive_service.dart';
import 'package:moviepilot_mobile/utils/frame_jank_reporter.dart';
import 'package:moviepilot_mobile/utils/image_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

import 'package:moviepilot_mobile/modules/player/controllers/player_launch_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/brush_flow_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/p115_strm_helper_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/proxmox_ve_backup_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/subtitle_manual_upload_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/trash_clean_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/applitepush/app_lite_push_widgets.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/brush_flow/brush_flow_widgets.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/proxmox_ve/proxmox_ve_backup_widgets.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/subtitle_manual_upload/subtitle_manual_upload_widgets.dart';

/// 启动期依赖注册与插件适配器注册。
Future<void> bootstrapApp() async {
  AppImageCacheManager.configureGlobalDecodedCache();
  try {
    Get.put(AppLog());
    await Get.putAsync(() => HiveService().init(), permanent: true);
    await Get.putAsync(
      () => IosWidgetNavigationService().init(),
      permanent: true,
    );
    Get.put(JPushService(), permanent: true);
    Get.put(IosSharedSessionService(), permanent: true);
    Get.put(AppService());
    Get.put(ApiClient());
    Get.put(PlayerLaunchController.to);
    Get.put(AppUpdateService(), permanent: true);
    Get.put(UpdateMirrorStore(), permanent: true);
    Get.put(UpdateSpeedTester(), permanent: true);
    Get.put(MediaDetailService());
    Get.put(ImageUtil());
    // 注册 vue 模式插件适配器
    PluginFormAdapterRegistry.register(
      'TrashClean',
      ({required formMode}) => TrashCleanFormController(formMode: formMode),
    );
    PluginFormAdapterRegistry.register(
      'P115StrmHelper',
      ({required formMode}) => P115StrmHelperFormController(formMode: formMode),
    );
    PluginFormAdapterRegistry.register(
      'ProxmoxVEBackup',
      ({required formMode}) =>
          ProxmoxVEBackupFormController(formMode: formMode),
    );
    PluginFormAdapterRegistry.register(
      'SubtitleManualUpload',
      ({required formMode}) =>
          SubtitleManualUploadFormController(formMode: formMode),
    );
    PluginFormAdapterRegistry.register(
      'BrushFlow',
      ({required formMode}) => BrushFlowFormController(formMode: formMode),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
  }

  registerProxmoxVeBackupRenderer();
  registerAppLitePushRenderer();
  registerSubtitleManualUploadRenderer();
  registerBrushFlowRenderer();
  WidgetsBinding.instance.addObserver(_WidgetRefreshLifecycle());
}

/// App 回到前台时让桌面小组件重新拉取，避免登录后的空缓存一直留在桌面。
class _WidgetRefreshLifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!Get.isRegistered<IosSharedSessionService>()) return;
    Get.find<IosSharedSessionService>().reloadWidgets();
  }
}

/// 首帧之后执行的初始化：慢帧诊断、推送 SDK 注册、APK 更新缓存清理
Future<void> postLaunchInit() async {
  FrameJankReporter.install();
  try {
    if (Get.isRegistered<JPushService>()) {
      await Get.find<JPushService>().init();
    }
  } catch (e) {
    debugPrint('JPush init failed: $e');
  }
  try {
    if (Get.isRegistered<AppUpdateService>()) {
      await Get.find<AppUpdateService>().cleanupExpiredApkCache(
        maxAge: Duration.zero,
      );
    }
  } catch (e) {
    debugPrint('APK cache cleanup failed: $e');
  }
}
