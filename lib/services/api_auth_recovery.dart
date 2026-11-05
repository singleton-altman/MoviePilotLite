import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' as g;
import 'package:moviepilot_mobile/services/api_auth_failure.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 401/403 的统一处置:登录态失效时优先用本地保存的账号静默重登恢复会话,
/// 恢复失败则清理会话并踢回登录页。
///
/// 权限不足（403 或带权限标记的 401）不会触发重登与登出——
/// 重新登录仍是同样的权限，踢回登录页只会让用户困惑。
///
/// 从 ApiClient 拆出,只负责"处置决策与会话踢出"这一件事;
/// 会话数据本身的清理(Cookie/Token/本地档案)由宿主通过
/// [clearSession] 回调完成。
class ApiAuthRecovery {
  ApiAuthRecovery({
    required Future<void> Function() clearSession,
    this.notify,
    this.redirectToLogin,
    this.currentRoute,
  }) : _clearSession = clearSession;

  final Future<void> Function() _clearSession;

  /// 提示用户的手段，默认走 [ToastUtil]；测试可替换。
  final void Function(String message)? notify;

  /// 跳转登录页的手段，默认 `Get.offAllNamed('/login')`；测试可替换。
  final void Function()? redirectToLogin;

  /// 读取当前路由，默认从 Get 取；测试可替换。
  final String Function()? currentRoute;

  /// 401 时的静默恢复钩子，由 AuthRepository 注册；返回 true 表示已重新登录成功。
  Future<bool> Function()? handler;
  bool _redirecting = false;
  bool _inProgress = false;
  DateTime? _lastAt;

  /// 最近一次已提示过的文案，避免并发 401 连续弹多条。
  String? _lastNotified;
  DateTime? _lastNotifiedAt;

  /// 两次静默重登尝试之间的最小间隔，避免旧 token 的并发 401 反复触发重登。
  static const Duration _cooldown = Duration(seconds: 15);

  /// 相同提示的去重窗口。
  static const Duration _notifyCooldown = Duration(seconds: 3);

  void maybeHandle(RequestOptions? opts, int? status, [dynamic body]) {
    if (opts?.extra['skipUnauthorizedHandling'] == true) return;
    handle(status, body);
  }

  void handle(int? status, [dynamic body]) {
    final failure = ApiAuthFailure.from(status, body);
    if (!failure.isAuthFailure) return;
    // 权限不足：重登与登出都无意义，交给调用方按自身语境提示。
    if (!failure.requiresRelogin) return;
    if (_redirecting) return;
    if (!_hasEnteredMain()) return;
    unawaited(_recoverOrLogout(failure));
  }

  Future<void> _recoverOrLogout(ApiAuthFailure failure) async {
    if (handler != null) {
      if (_inProgress) return;
      final last = _lastAt;
      if (last != null && DateTime.now().difference(last) < _cooldown) {
        // 冷却期内：最近一次恢复要么成功要么正在进行，静默忽略而非踢出。
        return;
      }
      _inProgress = true;
      bool recovered = false;
      try {
        recovered = await handler!();
      } catch (_) {
        recovered = false;
      } finally {
        _inProgress = false;
        _lastAt = DateTime.now();
      }
      if (recovered) {
        return;
      }
    }

    _redirecting = true;
    try {
      await _clearSession();
    } finally {
      _notify(failure.message);
      (redirectToLogin ?? _defaultRedirect)();
      Future.delayed(const Duration(seconds: 1), () {
        _redirecting = false;
      });
    }
  }

  void _defaultRedirect() => g.Get.offAllNamed('/login');

  /// 同一文案在短窗口内只提示一次：并发请求会同时拿到 401，
  /// 否则用户会被多条重复提示刷屏。
  void _notify(String message) {
    final now = DateTime.now();
    final lastAt = _lastNotifiedAt;
    if (_lastNotified == message &&
        lastAt != null &&
        now.difference(lastAt) < _notifyCooldown) {
      return;
    }
    _lastNotified = message;
    _lastNotifiedAt = now;
    (notify ?? ToastUtil.error)(message);
  }

  bool _hasEnteredMain() {
    final route = (currentRoute ?? (() => g.Get.currentRoute))();
    if (route.isEmpty) return false;
    return route != '/login';
  }
}
