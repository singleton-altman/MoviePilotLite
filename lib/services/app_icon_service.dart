import 'package:flutter/services.dart';

/// Changes the launcher icon through the platform-specific app icon APIs.
class AppIconService {
  static const _channel = MethodChannel('org.moviepilot/app_icon');

  Future<bool> setIcon(String iconId) async {
    try {
      return await _channel.invokeMethod<bool>('setAppIcon', {
            'iconId': iconId,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
