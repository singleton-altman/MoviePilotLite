import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 把登录会话同步给桌面小组件。
///
/// iOS 写入 App Group UserDefaults（WidgetKit 读取），Android 写入小组件专用
/// SharedPreferences（WorkManager 后台刷新读取）；两边共用同一组 MethodChannel 方法名。
class IosSharedSessionService {
  static const _channel = MethodChannel('org.moviepilot/ios_shared_session');

  Future<void> syncSession({
    required String server,
    required String accessToken,
  }) async {
    if (!_isSupportedPlatform) return;
    final normalizedServer = server.trim();
    final normalizedToken = accessToken.trim();
    if (normalizedServer.isEmpty || normalizedToken.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('saveSharedSession', {
        'server': normalizedServer,
        'accessToken': normalizedToken,
      });
    } catch (_) {}
  }

  Future<void> clearSession() async {
    if (!_isSupportedPlatform) return;
    try {
      await _channel.invokeMethod<void>('clearSharedSession');
    } catch (_) {}
  }

  Future<void> syncSiteWidgetPayload(String payload) async {
    if (!_isSupportedPlatform) return;
    final normalizedPayload = payload.trim();
    if (normalizedPayload.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('saveSiteWidgetPayload', {
        'payload': normalizedPayload,
      });
    } catch (_) {}
  }

  Future<void> reloadWidgets() async {
    if (!_isSupportedPlatform) return;
    final now = DateTime.now();
    final last = _lastReloadAt;
    if (last != null && now.difference(last) < _reloadCooldown) return;
    _lastReloadAt = now;
    try {
      await _channel.invokeMethod<void>('reloadWidgets');
    } catch (_) {
      _lastReloadAt = last;
    }
  }

  static const _reloadCooldown = Duration(seconds: 8);
  DateTime? _lastReloadAt;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
}
