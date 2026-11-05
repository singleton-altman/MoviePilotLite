import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/search/controllers/app_setting_controller.dart';
import 'package:moviepilot_mobile/modules/search/models/app_update_info.dart';
import 'package:moviepilot_mobile/modules/search/services/update_mirror_store.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/hive_service.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppUpdateInfo _info({
  required bool newer,
  bool withApk = true,
  String notes = '- fix something',
}) => AppUpdateInfo(
  currentVersion: '1.2.6',
  currentBuildNumber: 1,
  latestVersion: newer ? '1.2.7' : '1.2.6',
  latestBuildNumber: newer ? 2 : 1,
  tagName: 'release-v1.2.6',
  releaseName: 'v1.2.6',
  releaseUrl: 'https://github.com/singleton-altman/MoviePilotLite/releases',
  releaseNotes: notes,
  apkDownloadUrl: withApk ? 'https://github.com/x/a.apk' : '',
  apkAssetName: withApk ? 'a.apk' : '',
  apkSize: withApk ? 1024 : null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  Future<AppSettingController> openDialog(
    WidgetTester tester,
    AppUpdateInfo info, {
    bool isAndroid = true,
  }) async {
    Get.put(AppLog());
    Get.put(AppService());
    Get.put(IosSharedSessionService());
    Get.put(HiveService());
    Get.put(ApiClient());
    Get.put(UpdateMirrorStore(), permanent: true);
    final controller = Get.put(AppSettingController());
    controller.debugIsAndroidOverride = isAndroid;
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: SizedBox())),
    );
    await tester.pumpAndSettle();
    controller.showUpdateDialogForTest(info);
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('dialog shows version info, notes and download action', (
    tester,
  ) async {
    await openDialog(tester, _info(newer: true));
    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('更新内容'), findsOneWidget);
    expect(find.text('下载更新'), findsOneWidget);
  });

  testWidgets('update dialog no longer hosts mirror selection', (
    tester,
  ) async {
    // 线路配置改为独立入口，更新弹框内不再包含任何线路逻辑。
    await openDialog(tester, _info(newer: true));
    expect(find.text('下载线路'), findsNothing);
    expect(find.text('管理'), findsNothing);
    expect(find.text('测速'), findsNothing);
  });

  testWidgets('mirror logic stays out of the dialog without an apk asset', (
    tester,
  ) async {
    await openDialog(tester, _info(newer: true, withApk: false));
    expect(find.text('下载线路'), findsNothing);
    expect(find.text('测速'), findsNothing);
  });

  testWidgets('up-to-date on Android keeps the toast-only behaviour', (
    tester,
  ) async {
    // 线路入口独立后，无需再为「已是最新」强行弹框。
    await openDialog(tester, _info(newer: false));
    expect(find.text('发现新版本'), findsNothing);
    expect(find.text('下载更新'), findsNothing);
  });

  testWidgets('iOS still opens the changelog dialog when up to date', (
    tester,
  ) async {
    await openDialog(tester, _info(newer: false), isAndroid: false);
    expect(find.text('更新内容'), findsOneWidget);
    expect(find.text('前往 Release'), findsOneWidget);
  });
}
