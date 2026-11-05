import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/directory/controllers/directory_list_controller.dart';
import 'package:moviepilot_mobile/modules/file_manager/controllers/file_manager_browser_controller.dart';
import 'package:moviepilot_mobile/modules/file_manager/widgets/file_manual_transfer_sheet.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/media_organize/services/transfer_assist_service.dart';
import 'package:moviepilot_mobile/modules/media_organize/widgets/media_organize_item_card.dart';
import 'package:moviepilot_mobile/modules/setting/models/setting_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class _Api extends GetxController implements ApiClient {
  @override
  String? get baseUrl => null;
  @override
  String? get token => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _App extends AppService {
  bool manage = true;
  @override
  bool get canManage => manage;
  // Keep the test double offline instead of loading account configuration.
  @override
  // ignore: must_call_super
  Future<void> onInit() async {}
}

class _Directories extends DirectoryListController {
  @override
  void onReady() {}
  @override
  Future<void> loadDirectories({bool force = false}) async {}
}

class _Assist extends TransferAssistService {
  Completer<({bool ok, String? message, Map<String, dynamic>? target})>? target;
  int histories = 0;
  int recommendations = 0;
  @override
  Future<({bool ok, String? message, Map<String, dynamic>? target})>
  matchTargetPath({
    required Map<String, dynamic> fileitem,
    String? targetStorage,
  }) => target!.future;
  @override
  Future<({bool ok, String? message, int? historyCount, bool reorganize})>
  fetchManualHistory(Map<String, dynamic> fileitem) async {
    histories++;
    return (ok: true, message: null, historyCount: 2, reorganize: true);
  }

  @override
  Future<({bool ok, String? message, Map<String, dynamic>? recommendation})>
  recommendEpisodeFormat(Map<String, dynamic> fileitem) async {
    recommendations++;
    return (
      ok: true,
      message: null,
      recommendation: {
        'episode_format': 'recommended-template',
        'rule_name': 'rule',
        'sample_file': 'show.01.mkv',
      },
    );
  }
}

void main() {
  late _App app;
  late _Assist assist;
  late _Directories directories;
  var submissions = 0;
  const source = MediaOrganizeFileItem(
    path: '/downloads/show',
    storage: 'local',
    type: 'dir',
    name: 'show',
  );
  Finder field(String label) => find.byKey(ValueKey('manual-transfer-$label'));
  String input(WidgetTester tester, String label) =>
      tester.widget<CupertinoTextField>(field(label)).controller!.text;

  setUp(() {
    Get.testMode = true;
    Get.put<AppLog>(AppLog());
    Get.put<ApiClient>(_Api());
    app = Get.put<AppService>(_App()) as _App;
    directories = _Directories();
    directories.directories.assignAll([
      const DirectorySetting(
        libraryStorage: 'local',
        libraryPath: '/configured/local',
      ),
      const DirectorySetting(
        libraryStorage: '115',
        libraryPath: '/configured/cloud',
      ),
    ]);
    Get.put<DirectoryListController>(directories);
    assist = _Assist();
    Get.put<TransferAssistService>(assist);
    submissions = 0;
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: FileManualTransferSheet(
            file: source,
            availableStorages: const [
              StorageSetting(type: 'local', name: '本地'),
              StorageSetting(type: '115', name: '云盘'),
            ],
            defaultTargetStorage: 'local',
            submitTransfer:
                ({
                  required mode,
                  required targetStorage,
                  required transferType,
                  required targetPath,
                  required scrape,
                  required libraryTypeFolder,
                  required libraryCategoryFolder,
                  required tmdbId,
                  required part,
                  required minFileSize,
                  required episodeGroup,
                  required season,
                  required episodeFormat,
                  required episodeOffset,
                }) async {
                  submissions++;
                  return const FileActionResult(
                    success: false,
                    message: 'test failure',
                  );
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'late suggestions and directory refresh preserve input until explicit adoption',
    (tester) async {
      assist.target = Completer();
      await pumpSheet(tester);
      expect(input(tester, '目标目录'), isEmpty);
      await tester.enterText(field('目标目录'), '/user/path');
      await tester.tap(find.text('匹配目标路径建议'));
      await tester.pump();
      expect(find.text('正在匹配目标...'), findsOneWidget);
      directories.directories.add(
        const DirectorySetting(libraryStorage: 'local', libraryPath: '/later'),
      );
      await tester.pump();
      assist.target!.complete((
        ok: true,
        message: null,
        target: {
          'target_storage': 'local',
          'target_path': '/suggested',
          'transfer_type': 'copy',
          'scrape': false,
          'library_type_folder': false,
          'library_category_folder': true,
        },
      ));
      await tester.pumpAndSettle();
      expect(input(tester, '目标目录'), '/user/path');
      await tester.tap(find.text('采用目标配置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(input(tester, '目标目录'), '/user/path');
      await tester.tap(find.text('采用目标配置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('采用'));
      await tester.pumpAndSettle();
      expect(input(tester, '目标目录'), '/suggested');
      expect(submissions, 0);
      expect(assist.histories, 1);
      expect(find.textContaining('已命中 2 条成功记录'), findsOneWidget);
    },
  );

  testWidgets(
    'storage changes reject stale target responses without replacing typed path',
    (tester) async {
      assist.target = Completer();
      await pumpSheet(tester);
      await tester.enterText(field('目标目录'), '/user/path');
      await tester.tap(find.text('匹配目标路径建议'));
      await tester.pump();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      // Start and then finish the popup animation without waiting for the
      // unrelated, deliberately pending target-request spinner to settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('云盘').last);
      await tester.pumpAndSettle();
      assist.target!.complete((
        ok: true,
        message: null,
        target: {'target_storage': 'local', 'target_path': '/stale'},
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('/stale'), findsNothing);
      expect(input(tester, '目标目录'), '/user/path');
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();
      expect(find.text('/configured/cloud'), findsOneWidget);
      expect(find.text('/configured/local'), findsNothing);
    },
  );

  testWidgets(
    'episode recommendation never overwrites template or related inputs without consent',
    (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text('电视剧'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('高级参数'));
      await tester.pumpAndSettle();
      await tester.enterText(field('集数定位'), 'my-template');
      await tester.enterText(field('Season'), '3');
      await tester.enterText(field('指定剧集组'), 'my-group');
      await tester.enterText(field('集数偏移'), '-1');
      await tester.ensureVisible(find.text('推荐集数定位模板'));
      await tester.tap(find.text('推荐集数定位模板'));
      await tester.pumpAndSettle();
      expect(input(tester, '集数定位'), 'my-template');
      await tester.ensureVisible(find.text('采用集数模板'));
      await tester.tap(find.text('采用集数模板'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('采用'));
      await tester.pumpAndSettle();
      expect(input(tester, '集数定位'), 'recommended-template');
      expect(input(tester, 'Season'), '3');
      expect(input(tester, '指定剧集组'), 'my-group');
      expect(input(tester, '集数偏移'), '-1');
      expect(submissions, 0);
    },
  );

  testWidgets('manual transfer cancellation sends no real file operation', (
    tester,
  ) async {
    await pumpSheet(tester);
    await tester.enterText(field('目标目录'), '/user/path');
    final button = find.widgetWithText(FilledButton, '开始整理');
    // CustomButton uses an InkWell; find the actual action by its text instead.
    final action = find.text('开始整理').last;
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('确认文件整理'), findsOneWidget);
    expect(submissions, 0);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(input(tester, '目标目录'), '/user/path');
    expect(submissions, 0);
    expect(button, findsNothing);
  });

  testWidgets('assistance is unavailable without management permission', (
    tester,
  ) async {
    app.manage = false;
    await pumpSheet(tester);
    expect(find.text('匹配目标路径建议'), findsNothing);
    expect(find.text('成功整理历史'), findsNothing);
    expect(assist.histories, 0);
    expect(submissions, 0);
  });

  testWidgets('AI menu is opt-in and requires a valid history ID', (
    tester,
  ) async {
    var redo = 0;
    Future<void> pumpCard({VoidCallback? callback, int? id = 1}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaOrganizeItemCard(
              item: MediaOrganizeTransferItem(id: id, title: 'show'),
              srcStorageName: 'local',
              destStorageName: 'local',
              onAiRedo: callback,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
    }

    await pumpCard();
    expect(find.text('AI 重新整理'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await pumpCard(callback: () => redo++, id: 0);
    expect(find.text('AI 重新整理'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await pumpCard(callback: () => redo++);
    expect(find.text('AI 重新整理'), findsOneWidget);
    expect(redo, 0);
    await tester.tap(find.text('AI 重新整理'));
    await tester.pumpAndSettle();
    expect(redo, 1);
  });
}
