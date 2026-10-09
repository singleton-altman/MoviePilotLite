import 'package:flutter/services.dart';

import '../utils/app_log.dart';

/// 音频输出能力探测(原生 AudioCapabilityPlugin)。
class AudioCapability {
  static const MethodChannel _channel = MethodChannel('com.lanplayer/audio_caps');
  static bool? _surroundOutput;

  /// 是否存在环绕声输出(HDMI 系)。结果按会话缓存——HDMI 热插拔
  /// 后重进播放页会重新查询。
  static Future<bool> hasSurroundOutput() async {
    if (_surroundOutput != null) return _surroundOutput!;
    try {
      final r = await _channel.invokeMethod<bool>('hasSurroundOutput');
      _surroundOutput = r ?? false;
    } catch (e) {
      AppLog.w('AudioCap', '环绕声探测失败: $e');
      _surroundOutput = false;
    }
    return _surroundOutput!;
  }
}
