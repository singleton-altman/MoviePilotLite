import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
    try {
      await _channel.invokeMethod<void>('reloadWidgets');
    } catch (_) {}
  }

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
