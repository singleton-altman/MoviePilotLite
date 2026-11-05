import 'package:flutter/services.dart';

enum AppInstallResult { launched, permissionRequired, missingFile, unsupported }

class AppUpdateInstaller {
  static const _channel = MethodChannel('org.moviepilot/app_update');

  static Future<AppInstallResult> installApk(String path) async {
    try {
      final result = await _channel.invokeMethod<String>('installApk', {
        'path': path,
      });
      switch (result) {
        case 'launched':
          return AppInstallResult.launched;
        case 'permissionRequired':
          return AppInstallResult.permissionRequired;
        case 'missingFile':
          return AppInstallResult.missingFile;
        default:
          return AppInstallResult.unsupported;
      }
    } on MissingPluginException {
      return AppInstallResult.unsupported;
    }
  }
}
