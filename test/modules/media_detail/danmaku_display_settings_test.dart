import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/danmaku_display_settings.dart';
import 'package:moviepilot_mobile/modules/media_detail/services/danmaku_display_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('model clamps invalid persisted values', () {
    final settings = DanmakuDisplaySettings.fromJson({
      'speedScale': 99,
      'fontScale': '0.5',
      'opacity': -1,
      'colorMode': 'pink',
    });

    expect(settings.speedScale, 1.8);
    expect(settings.fontScale, 0.8);
    expect(settings.opacity, 0.4);
    expect(settings.colorMode, DanmakuColorMode.pink);
  });

  test('service persists and reloads settings', () async {
    final service = DanmakuDisplaySettingsService();
    await service.load();

    await service.update(
      const DanmakuDisplaySettings(
        speedScale: 1.5,
        fontScale: 1.2,
        opacity: 0.8,
        colorMode: DanmakuColorMode.yellow,
      ),
    );

    final reloaded = DanmakuDisplaySettingsService();
    await reloaded.load();

    expect(reloaded.settings.value.speedScale, 1.5);
    expect(reloaded.settings.value.fontScale, 1.2);
    expect(reloaded.settings.value.opacity, 0.8);
    expect(reloaded.settings.value.colorMode, DanmakuColorMode.yellow);
  });

  test('fixed color modes expose a concrete color', () {
    expect(DanmakuColorMode.multi.color, isNull);
    expect(DanmakuColorMode.white.color, Colors.white);
    expect(DanmakuColorMode.orange.color, isNotNull);
  });
}
