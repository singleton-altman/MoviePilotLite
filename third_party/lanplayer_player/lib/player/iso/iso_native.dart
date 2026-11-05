import 'package:flutter/services.dart';

import '../../utils/app_log.dart';

/// ISO 原盘(BDMV ISO)原生直连(libudfread)。
///
/// 打开远端 ISO:解析 UDF 文件系统 → 定位 BDMV/STREAM 正片 m2ts
/// → 本地 127.0.0.1 服务以 Range 流暴露给播放内核。
class IsoNative {
  static const MethodChannel _channel = MethodChannel('com.lanplayer/iso');

  /// 打开 ISO 并启动本地流服务;返回 127.0.0.1 播放地址,null=失败。
  static Future<String?> openIso(String url, int sizeBytes) async {
    try {
      return await _channel.invokeMethod<String>('openIso', {
        'url': url,
        'size': sizeBytes,
      });
    } catch (e) {
      AppLog.w('IsoNative', '原生 ISO 直连失败: $e');
      return null;
    }
  }

  /// 释放原生直连资源(换片/退出时调用)。
  static Future<void> closeIso() async {
    try {
      await _channel.invokeMethod('closeIso');
    } catch (_) {}
  }
}
