import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/app/app_bootstrap.dart';
import 'package:moviepilot_mobile/app/app_pages.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/bindings/app_binding.dart';
import 'package:moviepilot_mobile/l10n/app_localizations.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/theme/app_scaffold_background.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/widgets/agent_floating_entry.dart';
import 'package:talker_flutter/talker_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapApp();
  runApp(const MyApp());
  // 非关键路径的初始化移到首帧之后，避免阻塞启动
  unawaited(postLaunchInit());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    final talker = Get.find<AppLog>();
    final appService = Get.find<AppService>();
    final routeObserver = TalkerRouteObserver(talker.talker);
    return Obx(() {
      final primary = appService.primaryColor.value;
      return GetMaterialApp(
        title: 'MoviePilot',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        themeMode: appService.themeMode.value,
        theme: AppTheme.lightThemeWithPrimary(primary),
        darkTheme: AppTheme.darkThemeWithPrimary(primary),
        initialBinding: AppBinding(),
        initialRoute: '/login',
        navigatorObservers: [
          // 添加Talker路由观察器
          routeObserver,
          AgentFloatingRouteObserver(),
        ],
        getPages: buildAppPages(),
        // 配置错误处理
        builder: (context, child) {
          return AppScaffoldBackground(
            child: TalkerWrapper(
              talker: talker.talker,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child ?? const SizedBox.shrink(),
                  const AgentFloatingEntry(),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
