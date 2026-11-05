import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class _PermissionService extends AppService {
  _PermissionService({
    this.admin = false,
    this.manage = false,
    this.loggedIn = true,
  });

  final bool admin;
  final bool manage;
  final bool loggedIn;

  @override
  bool get isSuperuser => admin;

  @override
  bool get canManage => admin || manage;

  @override
  bool get hasLoggedInSession => loggedIn;
}

void main() {
  group('new feature route permissions', () {
    for (final route in [
      '/mcp-tools',
      '/system-maintenance',
      '/settings/notification-wechat',
    ]) {
      test('$route is restricted to administrators', () {
        expect(_PermissionService().canAccessRoute(route), isFalse);
        expect(_PermissionService(manage: true).canAccessRoute(route), isFalse);
        expect(_PermissionService(admin: true).canAccessRoute(route), isTrue);
      });
    }

    test('transfer queue requires management permission', () {
      expect(_PermissionService().canAccessRoute('/transfer-queue'), isFalse);
      expect(
        _PermissionService(manage: true).canAccessRoute('/transfer-queue'),
        isTrue,
      );
      expect(
        _PermissionService(admin: true).canAccessRoute('/transfer-queue'),
        isTrue,
      );
      expect(
        _PermissionService().accessDeniedMessage('/transfer-queue'),
        contains('管理权限'),
      );
    });

    for (final route in [
      '/mfa-settings',
      '/download-history',
      '/music',
      '/music/artist',
      '/music/album',
    ]) {
      test(
        '$route requires a logged-in session, not administrator permission',
        () {
          expect(
            _PermissionService(loggedIn: false).canAccessRoute(route),
            isFalse,
          );
          expect(_PermissionService().canAccessRoute(route), isTrue);
          expect(
            _PermissionService(loggedIn: false).accessDeniedMessage(route),
            contains('登录'),
          );
        },
      );
    }

    test('application appearance settings remain available', () {
      expect(
        _PermissionService(
          loggedIn: false,
        ).canAccessRoute('/settings/app/theme-mode'),
        isTrue,
      );
    });
  });
}
