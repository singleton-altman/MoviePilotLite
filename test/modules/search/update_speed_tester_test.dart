import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/search/services/update_speed_tester.dart';

void main() {
  group('MirrorSpeedResult.displaySpeed', () {
    test('reports MB/s for fast links', () {
      const result = MirrorSpeedResult(
        mirrorId: 'a',
        bytes: 6 * 1024 * 1024,
        elapsed: Duration(seconds: 1),
      );
      expect(result.displaySpeed, '6.0 MB/s');
      expect(result.ok, isTrue);
    });

    test('falls back to KB/s below 1 MB/s', () {
      const result = MirrorSpeedResult(
        mirrorId: 'a',
        bytes: 512 * 1024,
        elapsed: Duration(seconds: 1),
      );
      expect(result.displaySpeed, '512 KB/s');
    });

    test('shows failure label when errored', () {
      const result = MirrorSpeedResult(
        mirrorId: 'a',
        bytes: 0,
        elapsed: Duration(seconds: 1),
        error: '连接超时',
      );
      expect(result.ok, isFalse);
      expect(result.displaySpeed, '失败');
    });

    test('treats zero bytes as failure', () {
      const result = MirrorSpeedResult(
        mirrorId: 'a',
        bytes: 0,
        elapsed: Duration(seconds: 1),
      );
      expect(result.ok, isFalse);
    });

    test('avoids division by zero on empty elapsed', () {
      const result = MirrorSpeedResult(
        mirrorId: 'a',
        bytes: 1024,
        elapsed: Duration.zero,
      );
      expect(result.bytesPerSecond, 0);
    });
  });

  test('fallback probe url is a public GitHub endpoint', () {
    expect(
      UpdateSpeedTester.fallbackProbeUrl,
      startsWith('https://github.com/'),
    );
  });
}
