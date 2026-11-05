import 'dart:convert';

/// 鉴权类失败的分类结果。
enum ApiAuthFailureKind {
  /// 不是鉴权类失败，或没有可判定的状态码。
  none,

  /// 登录态失效（令牌过期、账号被删除/停用等），需要重新登录。
  sessionInvalid,

  /// 权限不足（服务端 401/403 且带权限标记），重新登录也无济于事。
  permissionDenied,

  /// 请求被拒绝但不属于权限不足（如资源令牌校验失败）。
  forbidden,
}

/// 把服务端的 401/403 响应翻译成「是否要重新登录」与「给用户看什么」。
///
/// 服务端 v3 用统一信封 `{success:false, message}` 描述错误，
/// v2 用 `{detail}`；两边对「权限不足」的状态码也不一致
/// （v3 为 403，v2 部分接口为 401 或 400），因此判定不能只看状态码。
class ApiAuthFailure {
  const ApiAuthFailure._({
    required this.statusCode,
    required this.kind,
    required this.message,
    this.serverReason,
  });

  final int statusCode;
  final ApiAuthFailureKind kind;

  /// 可直接展示给用户的文案。
  final String message;

  /// 服务端原始原因，便于日志排查。
  final String? serverReason;

  static const String sessionExpiredMessage = '登录已过期，请重新登录';
  static const String permissionDeniedMessage = '需要管理员权限';
  static const String forbiddenMessage = '当前账号无权访问该功能';
  static const String notLoggedInMessage = '尚未登录，请先登录';
  static const String unknownMessage = '请求失败，请稍后重试';

  /// 会话失效才值得静默重登；权限不足重登也是同样的结果。
  bool get requiresRelogin => kind == ApiAuthFailureKind.sessionInvalid;

  bool get isPermissionDenied => kind == ApiAuthFailureKind.permissionDenied;

  bool get isAuthFailure => kind != ApiAuthFailureKind.none;

  /// 权限不足的标记词。v3 的 detail 为「用户权限不足」，
  /// v2 的 manage 依赖同样返回它，只是状态码可能是 401/400。
  static const List<String> _permissionMarkers = [
    '权限不足',
    '无权访问',
    '无权限',
    'not enough permissions',
    'insufficient permission',
    'permission denied',
  ];

  /// 从状态码与响应体解析失败类型；非鉴权类返回 [ApiAuthFailureKind.none]。
  static ApiAuthFailure from(int? statusCode, [dynamic body]) {
    final status = statusCode ?? 0;
    final reason = extractReason(body);

    if (reason != null && _hasPermissionMarker(reason)) {
      return ApiAuthFailure._(
        statusCode: status,
        kind: ApiAuthFailureKind.permissionDenied,
        message: permissionDeniedMessage,
        serverReason: reason,
      );
    }

    if (status == 401) {
      return ApiAuthFailure._(
        statusCode: status,
        kind: ApiAuthFailureKind.sessionInvalid,
        message: _sessionInvalidMessage(reason),
        serverReason: reason,
      );
    }

    if (status == 403) {
      return ApiAuthFailure._(
        statusCode: status,
        kind: ApiAuthFailureKind.forbidden,
        message: _forbiddenMessage(reason),
        serverReason: reason,
      );
    }

    return ApiAuthFailure._(
      statusCode: status,
      kind: ApiAuthFailureKind.none,
      message: '',
      serverReason: reason,
    );
  }

  /// 从响应体取服务端原因：兼容 v3 的 message 与 v2 的 detail，
  /// 以及少量接口使用的 msg/error；响应体是字符串时先尝试按 JSON 解析。
  static String? extractReason(dynamic body) {
    dynamic payload = body;
    if (payload is String) {
      final raw = payload.trim();
      if (raw.isEmpty) return null;
      try {
        payload = jsonDecode(raw);
      } catch (_) {
        return _clean(raw);
      }
    }
    if (payload is! Map) return null;
    for (final key in const ['message', 'detail', 'msg', 'error']) {
      final value = payload[key];
      if (value is String) {
        final text = _clean(value);
        if (text != null) return text;
      }
    }
    return null;
  }

  /// 401 的原因映射：让用户能区分密码失效、账号被停用与令牌过期。
  static String _sessionInvalidMessage(String? reason) {
    if (reason == null) return sessionExpiredMessage;
    if (reason.contains('用户不存在')) {
      return '账号不存在或已被删除，请重新登录';
    }
    if (reason.contains('未激活')) {
      return '账号未激活，请联系管理员';
    }
    // 服务端的通用认证失败措辞不值得透出，统一换成用户能理解的说法。
    if (reason == 'Not authenticated' ||
        reason == 'token校验不通过' ||
        reason.contains('invalid token') ||
        reason.contains('Invalid token')) {
      return sessionExpiredMessage;
    }
    return sessionExpiredMessage;
  }

  static String _forbiddenMessage(String? reason) {
    if (reason == null || reason.isEmpty) return forbiddenMessage;
    // 实现细节类原因（令牌/Cookie 校验细节）对用户没有意义，统一兜底。
    if (_isImplementationDetail(reason)) return forbiddenMessage;
    if (!_containsCjk(reason)) return forbiddenMessage;
    return reason;
  }

  static bool _isImplementationDetail(String reason) {
    final lower = reason.toLowerCase();
    return lower.contains('token') ||
        lower.contains('cookie') ||
        lower.contains('jwt');
  }

  static bool _hasPermissionMarker(String reason) {
    final lower = reason.toLowerCase();
    return _permissionMarkers.any((marker) => lower.contains(marker));
  }

  static bool _containsCjk(String text) {
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
  }

  static String? _clean(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
