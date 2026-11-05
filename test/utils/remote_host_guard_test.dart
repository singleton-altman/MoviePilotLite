import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/utils/remote_host_guard.dart';

void main() {
  group('isSafeRemoteHost accepts public hosts', () {
    for (final host in [
      'github.com',
      'gh-proxy.org',
      'raw.githubusercontent.com',
      '1.1.1.1',
      '8.8.8.8',
      '2606:4700:4700::1111',
    ]) {
      test(host, () => expect(isSafeRemoteHost(host), isTrue));
    }
  });

  group('isSafeRemoteHost rejects local and private targets', () {
    for (final host in [
      'localhost',
      'foo.localhost',
      'nas.local',
      'router.internal',
      'printer.lan',
      '0.0.0.0',
      '127.0.0.1',
      '127.1.2.3',
      '10.0.0.5',
      '172.16.0.1',
      '172.31.255.254',
      '192.168.1.1',
      '169.254.1.1',
      '100.64.0.1',
      '192.0.2.1',
      '198.18.0.1',
      '203.0.113.9',
      '224.0.0.1',
      '255.255.255.255',
      '::1',
      '::',
      'fe80::1',
      'fd00::1',
      'ff02::1',
      '::ffff:127.0.0.1',
      'intranet',
      '',
    ]) {
      test('"$host"', () => expect(isSafeRemoteHost(host), isFalse));
    }
  });

  group('isSafeRemoteUrl', () {
    test('accepts https public url', () {
      expect(isSafeRemoteUrl('https://ghproxy.net/'), isTrue);
    });

    test('accepts http public url', () {
      expect(isSafeRemoteUrl('http://example.com/x'), isTrue);
    });

    test('rejects non http schemes', () {
      expect(isSafeRemoteUrl('ftp://example.com/'), isFalse);
      expect(isSafeRemoteUrl('file:///etc/passwd'), isFalse);
    });

    test('rejects loopback and private hosts', () {
      expect(isSafeRemoteUrl('http://127.0.0.1:8080/'), isFalse);
      expect(isSafeRemoteUrl('http://192.168.1.1/admin'), isFalse);
      expect(isSafeRemoteUrl('http://localhost/'), isFalse);
    });

    test('rejects unparsable input', () {
      expect(isSafeRemoteUrl(''), isFalse);
      expect(isSafeRemoteUrl('not a url'), isFalse);
    });
  });
}
