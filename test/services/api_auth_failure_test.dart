import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/services/api_auth_failure.dart';

void main() {
  group('ApiAuthFailure.from 权限判定', () {
    test('v3 403 + 统一信封 permission message ⇒ 权限不足', () {
      final failure = ApiAuthFailure.from(403, {
        'success': false,
        'message': '用户权限不足',
      });
      expect(failure.kind, ApiAuthFailureKind.permissionDenied);
      expect(failure.isPermissionDenied, isTrue);
      expect(failure.requiresRelogin, isFalse);
      expect(failure.message, ApiAuthFailure.permissionDeniedMessage);
      expect(failure.serverReason, '用户权限不足');
    });

    test('v2 401 + 用户权限不足仍判定为权限不足，不触发重登', () {
      final failure = ApiAuthFailure.from(401, {'detail': '用户权限不足'});
      expect(failure.kind, ApiAuthFailureKind.permissionDenied);
      expect(failure.requiresRelogin, isFalse);
    });

    test('v2 400 + 用户权限不足（user 接口）也判定为权限不足', () {
      final failure = ApiAuthFailure.from(400, {'detail': '用户权限不足'});
      expect(failure.kind, ApiAuthFailureKind.permissionDenied);
    });

    test('英文权限标记同样识别', () {
      final failure = ApiAuthFailure.from(403, {
        'detail': 'Not enough permissions',
      });
      expect(failure.isPermissionDenied, isTrue);
    });
  });

  group('ApiAuthFailure.from 会话失效', () {
    test('401 + Not authenticated ⇒ 登录已过期', () {
      final failure = ApiAuthFailure.from(401, {'detail': 'Not authenticated'});
      expect(failure.kind, ApiAuthFailureKind.sessionInvalid);
      expect(failure.requiresRelogin, isTrue);
      expect(failure.message, ApiAuthFailure.sessionExpiredMessage);
    });

    test('401 无响应体 ⇒ 登录已过期', () {
      expect(
        ApiAuthFailure.from(401).message,
        ApiAuthFailure.sessionExpiredMessage,
      );
    });

    test('401 用户不存在 ⇒ 提示账号不存在', () {
      final failure = ApiAuthFailure.from(401, {'detail': '用户不存在'});
      expect(failure.kind, ApiAuthFailureKind.sessionInvalid);
      expect(failure.message, contains('账号不存在'));
    });

    test('401 用户未激活 ⇒ 提示联系管理员', () {
      final failure = ApiAuthFailure.from(401, {'detail': '用户未激活'});
      expect(failure.message, contains('未激活'));
    });

    test('字符串响应体会先按 JSON 解析', () {
      final failure = ApiAuthFailure.from(401, '{"detail":"用户不存在"}');
      expect(failure.message, contains('账号不存在'));
    });

    test('非 JSON 字符串响应体作为原因保留', () {
      expect(
        ApiAuthFailure.extractReason('  bad gateway  '),
        'bad gateway',
      );
    });
  });

  group('ApiAuthFailure.from 其他分支', () {
    test('403 无权限标记 ⇒ forbidden，不重登也不判权限不足', () {
      final failure = ApiAuthFailure.from(403, {'detail': 'token校验不通过'});
      expect(failure.kind, ApiAuthFailureKind.forbidden);
      expect(failure.requiresRelogin, isFalse);
      expect(failure.isPermissionDenied, isFalse);
      // 英文实现细节不透出
      expect(failure.message, ApiAuthFailure.forbiddenMessage);
    });

    test('403 带中文原因时透出服务端原因', () {
      final failure = ApiAuthFailure.from(403, {'message': '该功能未启用'});
      expect(failure.message, '该功能未启用');
    });

    test('非鉴权状态码不算鉴权失败', () {
      for (final status in [0, 200, 400, 404, 422, 500]) {
        final failure = ApiAuthFailure.from(status, {'detail': 'x'});
        expect(failure.isAuthFailure, isFalse, reason: 'status=$status');
        expect(failure.requiresRelogin, isFalse);
      }
    });

    test('v3 信封的 message 优先于其他键', () {
      expect(
        ApiAuthFailure.extractReason({
          'success': false,
          'message': '服务端消息',
          'detail': '旧字段',
        }),
        '服务端消息',
      );
    });

    test('空白原因被忽略', () {
      expect(ApiAuthFailure.extractReason({'detail': '   '}), isNull);
      expect(ApiAuthFailure.extractReason(<String, dynamic>{}), isNull);
      expect(ApiAuthFailure.extractReason(null), isNull);
    });
  });
}
