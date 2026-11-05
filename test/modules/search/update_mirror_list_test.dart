import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/controllers/mirror_speed_controller.dart';
import 'package:moviepilot_mobile/modules/search/models/update_mirror.dart';
import 'package:moviepilot_mobile/modules/search/pages/update_mirror_sheet.dart';
import 'package:moviepilot_mobile/modules/search/services/update_mirror_store.dart';
import 'package:moviepilot_mobile/modules/search/services/update_speed_tester.dart';
import 'package:moviepilot_mobile/modules/search/widgets/update_mirror_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  Future<UpdateMirrorStore> pumpList(
    WidgetTester tester, {
    bool compact = false,
  }) async {
    final store = Get.put(UpdateMirrorStore(), permanent: true);
    await store.load();
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UpdateMirrorList(sourceUrl: '', compact: compact),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('compact list shows every line and a speed badge', (
    tester,
  ) async {
    final store = await pumpList(tester, compact: true);
    for (final mirror in store.allMirrors) {
      expect(find.text(mirror.label), findsWidgets);
    }
    // 每条线路一个「测速」徽标，外加顶部一键测速按钮。
    expect(find.text('测速'), findsNWidgets(store.allMirrors.length + 1));
  });

  testWidgets('tapping a line switches the selection', (tester) async {
    final store = await pumpList(tester, compact: true);
    expect(store.selectedId.value, UpdateMirror.directId);
    await tester.tap(find.text('gh-proxy.org'));
    await tester.pumpAndSettle();
    expect(store.selectedId.value, 'gh-proxy-org');
  });

  testWidgets('selection change notifies the caller', (tester) async {
    final store = Get.put(UpdateMirrorStore(), permanent: true);
    await store.load();
    UpdateMirror? picked;
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UpdateMirrorList(
              compact: true,
              onSelected: (mirror) => picked = mirror,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ghfast.top'));
    await tester.pumpAndSettle();
    expect(picked?.id, 'ghfast');
  });

  testWidgets('compact list hides template and delete action', (tester) async {
    final store = Get.put(UpdateMirrorStore(), permanent: true);
    await store.load();
    await store.addCustom('https://myproxy.example/');
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UpdateMirrorList(sourceUrl: '', compact: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('myproxy.example'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.text('https://myproxy.example/'), findsNothing);
  });

  testWidgets('full manager sheet exposes the add form', (tester) async {
    Get.put(UpdateMirrorStore(), permanent: true);
    await tester.pumpWidget(
      GetMaterialApp(home: const Scaffold(body: UpdateMirrorSheet())),
    );
    await tester.pumpAndSettle();
    expect(find.text('自定义加速源'), findsOneWidget);
    expect(find.text('保存并使用'), findsOneWidget);
  });

  group('MirrorSpeedController.fastestHint', () {
    UpdateMirror mirror(String id) =>
        UpdateMirror(id: id, label: id, template: 'https://$id.example/');

    test('is silent with fewer than two measurements', () {
      final controller = MirrorSpeedController();
      controller.results['a'] = const MirrorSpeedResult(
        mirrorId: 'a',
        bytes: 1024,
        elapsed: Duration(seconds: 1),
      );
      expect(
        controller.fastestHint([mirror('a')], selectedId: 'direct'),
        isNull,
      );
    });

    test('points at the fastest line when it is not selected', () {
      final controller = MirrorSpeedController();
      controller.results['a'] = const MirrorSpeedResult(
        mirrorId: 'a',
        bytes: 1024 * 1024,
        elapsed: Duration(seconds: 1),
      );
      controller.results['b'] = const MirrorSpeedResult(
        mirrorId: 'b',
        bytes: 4 * 1024 * 1024,
        elapsed: Duration(seconds: 1),
      );
      final hint = controller.fastestHint(
        [mirror('a'), mirror('b')],
        selectedId: 'a',
      );
      expect(hint, contains('b'));
      expect(hint, contains('4.0 MB/s'));
    });

    test('is silent when the fastest line is already selected', () {
      final controller = MirrorSpeedController();
      controller.results['a'] = const MirrorSpeedResult(
        mirrorId: 'a',
        bytes: 1024 * 1024,
        elapsed: Duration(seconds: 1),
      );
      controller.results['b'] = const MirrorSpeedResult(
        mirrorId: 'b',
        bytes: 4 * 1024 * 1024,
        elapsed: Duration(seconds: 1),
      );
      expect(
        controller.fastestHint(
          [mirror('a'), mirror('b')],
          selectedId: 'b',
        ),
        isNull,
      );
    });

    test('ignores failed measurements', () {
      final controller = MirrorSpeedController();
      controller.results['a'] = const MirrorSpeedResult(
        mirrorId: 'a',
        bytes: 1024,
        elapsed: Duration(seconds: 1),
      );
      controller.results['b'] = const MirrorSpeedResult(
        mirrorId: 'b',
        bytes: 0,
        elapsed: Duration(seconds: 1),
        error: '连接超时',
      );
      expect(
        controller.fastestHint(
          [mirror('a'), mirror('b')],
          selectedId: 'direct',
        ),
        isNull,
      );
    });
  });
}
