import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// issue #74：普通账号的「搜索」权限只约束站点资源搜索，
/// TMDB/豆瓣影片检索对任何已登录用户开放；系统消息仅超级用户可见。
class _PermissionService extends AppService {
  _PermissionService({
    this.admin = false,
    this.search = false,
    this.subscribe = false,
    this.discovery = false,
    this.manage = false,
    this.loggedIn = true,
  });

  final bool admin;
  final bool search;
  final bool subscribe;
  final bool discovery;
  final bool manage;
  final bool loggedIn;

  @override
  bool get isSuperuser => admin;

  @override
  bool get canSearch => admin || search;

  @override
  bool get canSubscribe => admin || subscribe;

  @override
  bool get canDiscovery => admin || discovery;

  @override
  bool get canManage => admin || manage;

  @override
  bool get hasLoggedInSession => loggedIn;
}

void main() {
  group('media catalog search does not depend on the search permission', () {
    for (final route in [
      '/media-search-list',
      '/person-search-list',
      '/person-search-result',
    ]) {
      test('$route is open to any logged-in account', () {
        expect(_PermissionService().canAccessRoute(route), isTrue);
        expect(
          _PermissionService(subscribe: true).canAccessRoute(route),
          isTrue,
        );
        expect(_PermissionService(admin: true).canAccessRoute(route), isTrue);
      });

      test('$route still requires a logged-in session', () {
        expect(
          _PermissionService(loggedIn: false).canAccessRoute(route),
          isFalse,
        );
      });
    }
  });

  group('site resource search requires the search permission', () {
    for (final route in [
      '/search-result',
      '/search-media-result',
      '/subtitle-search-result',
    ]) {
      test('$route is denied without the search permission', () {
        expect(_PermissionService().canAccessRoute(route), isFalse);
        expect(
          _PermissionService(
            subscribe: true,
            discovery: true,
            manage: true,
          ).canAccessRoute(route),
          isFalse,
        );
        expect(
          _PermissionService().accessDeniedMessage(route),
          contains('资源搜索'),
        );
      });

      test('$route is allowed with the search permission or as admin', () {
        expect(_PermissionService(search: true).canAccessRoute(route), isTrue);
        expect(_PermissionService(admin: true).canAccessRoute(route), isTrue);
      });
    }
  });

  group('system messages are restricted to administrators', () {
    test('a normal account is denied even with every feature permission', () {
      final service = _PermissionService(
        search: true,
        subscribe: true,
        discovery: true,
        manage: true,
      );
      expect(service.canAccessRoute('/system-message'), isFalse);
      expect(service.accessDeniedMessage('/system-message'), contains('系统消息'));
    });

    test('an administrator is allowed', () {
      expect(
        _PermissionService(admin: true).canAccessRoute('/system-message'),
        isTrue,
      );
    });
  });
}
