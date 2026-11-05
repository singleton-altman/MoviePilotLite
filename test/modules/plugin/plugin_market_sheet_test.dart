import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_folder_models.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/pages/plugin_market_sheet.dart';

class _Controller extends Fake implements PluginController {
  @override
  String get managementScope => 'test-scope';
  @override
  final items = <PluginItem>[
    const PluginItem(id: 'A', pluginName: 'Installed A'),
    const PluginItem(id: 'B', pluginName: 'Installed B'),
  ].obs;

  PluginFolders folders = PluginFolders.fromJson({
    'Rich': {
      'plugins': ['A', 'Unknown'],
      'order': 4,
      'showIcon': false,
    },
  });
  Completer<PluginFolders>? loading;
  Completer<void>? saving;
  bool failRead = false;
  int writes = 0;

  @override
  Future<PluginFolders> fetchFolders(String scope) async {
    if (failRead) throw StateError('Folder request failed');
    return loading?.future ?? folders;
  }

  @override
  Future<List<PluginRemote>> fetchRemotes(String scope) async => const [
    PluginRemote(id: 'A', name: 'Vue A', url: 'plugin/file/a/remoteEntry.js'),
  ];

  @override
  Future<void> saveFolders({
    required PluginFolders expected,
    required PluginFolders updated,
    required String scope,
  }) async {
    writes++;
    if (saving != null) await saving!.future;
    folders = updated;
  }
}

Future<void> _mount(
  WidgetTester tester,
  _Controller controller,
  ScrollController scroll,
) => tester.pumpWidget(
  GetMaterialApp(
    home: PluginMarketSheet(controller: controller, scrollController: scroll),
  ),
);

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('failed read disables create and exposes working retry', (
    tester,
  ) async {
    final controller = _Controller()..failRead = true;
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await _mount(tester, controller, scroll);
    await tester.pumpAndSettle();
    expect(find.textContaining('Folder request failed'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == '新建文件夹',
            ),
          )
          .onPressed,
      isNull,
    );
    controller.failRead = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('Rich'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == '新建文件夹',
            ),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      find.textContaining('组件入口：plugin/file/a/remoteEntry.js'),
      findsOneWidget,
    );
  });

  testWidgets('late folder response after dismissal does not setState', (
    tester,
  ) async {
    final controller = _Controller()..loading = Completer<PluginFolders>();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await _mount(tester, controller, scroll);
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == '新建文件夹',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    controller.loading!.complete(controller.folders);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('create validates duplicate names and saves once', (
    tester,
  ) async {
    final controller = _Controller()..saving = Completer<void>();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await _mount(tester, controller, scroll);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == '新建文件夹',
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Rich');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('文件夹已存在'), findsOneWidget);
    expect(controller.writes, 0);
    await tester.enterText(find.byType(TextFormField), ' New ');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.writes, 1);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == '新建文件夹',
            ),
          )
          .onPressed,
      isNull,
    );
    // Dispose during the write as well as during reads.
    await tester.pumpWidget(const SizedBox());
    controller.saving!.complete();
    await tester.pump();
    expect(controller.folders.names, ['Rich', 'New']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'membership editor keeps unknown IDs and adds installed plugins',
    (tester) async {
      final controller = _Controller()..saving = Completer<void>();
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await _mount(tester, controller, scroll);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rich'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Unknown（未在当前列表中'), findsOneWidget);
      await tester.tap(find.text('Installed B'));
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox());
      controller.saving!.complete();
      await tester.pump();
      expect(controller.folders.pluginsIn('Rich'), ['A', 'Unknown', 'B']);
      expect(controller.folders.toJson()['Rich']['showIcon'], isFalse);
      expect(controller.writes, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('rename keeps metadata and delete never uninstalls plugins', (
    tester,
  ) async {
    for (final action in ['重命名', '删除分组']) {
      final controller = _Controller()..saving = Completer<void>();
      final scroll = ScrollController();
      await _mount(tester, controller, scroll);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('文件夹操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      if (action == '重命名') {
        await tester.enterText(find.byType(TextFormField), 'Renamed');
        await tester.tap(find.text('保存'));
      } else {
        expect(find.textContaining('不会卸载其中的插件'), findsOneWidget);
        await tester.tap(find.text('删除'));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox());
      controller.saving!.complete();
      await tester.pump();
      if (action == '重命名') {
        expect(controller.folders.names, ['Renamed']);
        expect(controller.folders.pluginsIn('Renamed'), ['A', 'Unknown']);
        expect(controller.folders.toJson()['Renamed']['order'], 4);
      } else {
        expect(controller.folders.isEmpty, isTrue);
      }
      expect(controller.items.map((item) => item.id), ['A', 'B']);
      expect(controller.writes, 1);
      expect(tester.takeException(), isNull);
      scroll.dispose();
    }
  });
}
