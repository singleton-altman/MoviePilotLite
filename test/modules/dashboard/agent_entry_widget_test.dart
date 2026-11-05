import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/login/models/login_response.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/widgets/agent_floating_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    agentFloatingEntryRouteHidden.value = false;
    SharedPreferences.setMockInitialValues({});
    Get.put(AppService());
  });

  tearDown(Get.reset);

  Widget buildHarness() {
    return GetMaterialApp(
      navigatorObservers: [AgentFloatingRouteObserver()],
      getPages: [
        GetPage(
          name: '/agent',
          page: () => const Scaffold(body: Text('agent page')),
        ),
      ],
      home: const Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [SizedBox.expand(), AgentFloatingEntry()],
        ),
      ),
    );
  }

  void signInAndEnableAgent() {
    final appService = Get.find<AppService>();
    appService.saveProfile(
      'https://server.example',
      const LoginResponse(
        accessToken: 'token',
        tokenType: 'bearer',
        userId: 1,
        userName: 'alice',
        level: 1,
        permissions: {},
      ),
    );
    appService.applyUserGlobalConfig({
      'AI_AGENT_ENABLE': true,
      'AI_AGENT_HIDE_ENTRY': false,
    });
  }

  testWidgets('hides agent floating entry by default', (tester) async {
    await tester.pumpWidget(buildHarness());

    expect(find.byIcon(CupertinoIcons.sparkles), findsNothing);
  });

  testWidgets('hides agent floating entry before login even when enabled', (
    tester,
  ) async {
    Get.find<AppService>().applyUserGlobalConfig({
      'AI_AGENT_ENABLE': true,
      'AI_AGENT_HIDE_ENTRY': false,
    });

    await tester.pumpWidget(buildHarness());

    expect(find.byIcon(CupertinoIcons.sparkles), findsNothing);
  });

  testWidgets('shows agent floating entry when enabled and not hidden', (
    tester,
  ) async {
    signInAndEnableAgent();

    await tester.pumpWidget(buildHarness());

    expect(find.byIcon(CupertinoIcons.sparkles), findsOneWidget);
  });

  testWidgets('opens agent page and hides floating entry until back', (
    tester,
  ) async {
    signInAndEnableAgent();

    await tester.pumpWidget(buildHarness());
    await tester.tap(find.byIcon(CupertinoIcons.sparkles));
    await tester.pumpAndSettle();

    expect(find.text('agent page'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.sparkles), findsNothing);

    Get.back<void>();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.byIcon(CupertinoIcons.sparkles), findsOneWidget);
  });

  testWidgets('can drag floating entry', (tester) async {
    signInAndEnableAgent();

    await tester.pumpWidget(buildHarness());
    final before = tester.getTopLeft(find.byIcon(CupertinoIcons.sparkles));
    await tester.drag(
      find.byIcon(CupertinoIcons.sparkles),
      const Offset(-520, 40),
    );
    await tester.pump(const Duration(milliseconds: 320));
    final after = tester.getTopLeft(find.byIcon(CupertinoIcons.sparkles));

    expect(after.dx, isNot(before.dx));
    expect(after.dy, isNot(before.dy));
  });

  testWidgets('opens after dragging floating entry', (tester) async {
    signInAndEnableAgent();

    await tester.pumpWidget(buildHarness());
    await tester.drag(
      find.byIcon(CupertinoIcons.sparkles),
      const Offset(-520, 40),
    );
    await tester.pump(const Duration(milliseconds: 320));
    await tester.tap(find.byIcon(CupertinoIcons.sparkles));
    await tester.pumpAndSettle();

    expect(find.text('agent page'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.sparkles), findsNothing);
  });
}
