import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/search/models/update_mirror.dart';

void main() {
  const source = 'https://github.com/o/r/releases/download/v1/app.apk';

  group('UpdateMirror.resolve', () {
    test('direct returns the source url untouched', () {
      expect(const UpdateMirror.direct().resolve(source), source);
    });

    test('prefix template joins with a trailing slash', () {
      const mirror = UpdateMirror(
        id: 'p',
        label: 'p',
        template: 'https://ghproxy.net/',
      );
      expect(mirror.resolve(source), 'https://ghproxy.net/$source');
    });

    test('prefix template without trailing slash still joins correctly', () {
      const mirror = UpdateMirror(
        id: 'p',
        label: 'p',
        template: 'https://ghproxy.net',
      );
      expect(mirror.resolve(source), 'https://ghproxy.net/$source');
    });

    test('placeholder template substitutes {url}', () {
      const mirror = UpdateMirror(
        id: 'q',
        label: 'q',
        template: 'https://x.dev/fetch?u={url}&flag=1',
      );
      expect(
        mirror.resolve(source),
        'https://x.dev/fetch?u=https://github.com/o/r/releases/download/v1/app.apk&flag=1',
      );
    });
  });

  group('UpdateMirror.validateTemplate', () {
    test('rejects empty input', () {
      expect(UpdateMirror.validateTemplate('   '), isNotNull);
    });

    test('rejects non http schemes', () {
      expect(UpdateMirror.validateTemplate('ftp://example.com/'), isNotNull);
    });

    test('rejects a bare host without slash or placeholder', () {
      // 裸域名是合法写法，会被规整为带斜杠的前缀式；仅拒绝无法解析的输入。
      expect(UpdateMirror.validateTemplate('https://example.com'), isNull);
    });

    test('accepts a host without scheme', () {
      expect(UpdateMirror.validateTemplate('ghproxy.net'), isNull);
      expect(UpdateMirror.validateTemplate('ghproxy.net/'), isNull);
    });

    test('accepts prefix style with trailing slash', () {
      expect(UpdateMirror.validateTemplate('https://example.com/'), isNull);
    });

    test('accepts prefix style with a path', () {
      expect(
        UpdateMirror.validateTemplate('https://example.com/gh'),
        isNull,
      );
    });

    test('accepts placeholder style', () {
      expect(
        UpdateMirror.validateTemplate('https://example.com/{url}'),
        isNull,
      );
    });

    test('rejects loopback and private hosts', () {
      expect(
        UpdateMirror.validateTemplate('http://127.0.0.1:8080/'),
        isNotNull,
      );
      expect(
        UpdateMirror.validateTemplate('http://192.168.1.10/{url}'),
        isNotNull,
      );
      expect(UpdateMirror.validateTemplate('http://localhost/'), isNotNull);
    });
  });

  group('UpdateMirror.labelFromTemplate', () {
    test('uses the host as the label', () {
      expect(
        UpdateMirror.labelFromTemplate('https://ghproxy.net/'),
        'ghproxy.net',
      );
    });

    test('works with a placeholder template', () {
      expect(
        UpdateMirror.labelFromTemplate('https://mirror.dev/{url}'),
        'mirror.dev',
      );
    });
  });

  group('UpdateMirror.normalizeTemplate', () {
    test('adds a trailing slash to a bare host', () {
      expect(
        UpdateMirror.normalizeTemplate('https://ghproxy.net'),
        'https://ghproxy.net/',
      );
    });

    test('adds the https scheme when missing', () {
      expect(
        UpdateMirror.normalizeTemplate('ghproxy.net'),
        'https://ghproxy.net/',
      );
      expect(
        UpdateMirror.normalizeTemplate('ghproxy.net/'),
        'https://ghproxy.net/',
      );
    });

    test('keeps a path template intact', () {
      expect(
        UpdateMirror.normalizeTemplate('https://x.dev/proxy'),
        'https://x.dev/proxy',
      );
    });

    test('keeps placeholder templates intact', () {
      expect(
        UpdateMirror.normalizeTemplate('https://x.dev/?u={url}'),
        'https://x.dev/?u={url}',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        UpdateMirror.normalizeTemplate('  https://ghproxy.net/  '),
        'https://ghproxy.net/',
      );
    });

    test('returns null for rejected input', () {
      expect(UpdateMirror.normalizeTemplate('localhost'), isNull);
      expect(UpdateMirror.normalizeTemplate('ftp://x.dev/'), isNull);
      expect(UpdateMirror.normalizeTemplate('   '), isNull);
    });
  });

  test('fromJson drops malformed entries and defaults the label', () {
    expect(UpdateMirror.fromJson('nope'), isNull);
    expect(UpdateMirror.fromJson({'id': '', 'template': 'x'}), isNull);
    final parsed = UpdateMirror.fromJson({
      'id': 'c1',
      'template': 'https://mirror.dev/',
    });
    expect(parsed?.label, 'mirror.dev');
    expect(parsed?.builtin, isFalse);
  });
}
