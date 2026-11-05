import 'package:flutter/services.dart';
import '../../../utils/app_log.dart';

/// ExoPlayer FFmpeg 音频软解扩展
///
/// 通过 MethodChannel 与 Android 原生层通信，在 ExoPlayer 的音频解码器
/// 无法处理（TrueHD/DTS-HD/EAC3 等）时，自动回退到 FFmpeg 软件解码。
///
/// 参考 Jellyfin 的 jellyfin-androidx-media 项目：
/// - 使用 media3-exoplayer + media3-decoder-ffmpeg
/// - FFmpeg 编译为 .so 库，通过 ExoPlayer 的 Renderer 扩展接口接入
/// - 视频继续使用 MediaCodec 硬解，仅音频走 FFmpeg 软解
class FFmpegAudioExtension {
  static const MethodChannel _channel =
      MethodChannel('com.lanplayer/exo_ffmpeg');

  /// 检查 FFmpeg 音频扩展是否可用（原生层已加载 .so）
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isFFmpegAvailable');
      return result ?? false;
    } catch (e) {
      AppLog.w('FFmpegAudio', 'FFmpeg 扩展不可用: $e');
      return false;
    }
  }

  /// 获取 FFmpeg 支持的音频编解码器列表
  static Future<List<String>> getSupportedCodecs() async {
    try {
      final result = await _channel.invokeMethod<List>('getSupportedCodecs');
      return result?.cast<String>() ?? [];
    } catch (_) {
      return [];
    }
  }

  /// 检查指定音频编解码器是否需要 FFmpeg 软解
  /// 例如：truehd, dts-hd, dts, eac3
  static Future<bool> needsFFmpegDecode(String codec) async {
    final supported = await getSupportedCodecs();
    // 系统硬解不支持的格式，需要 FFmpeg 软解
    const needsSoftDecode = {
      'truehd', 'dts-hd', 'dts', 'eac3', 'mlp', 'alac',
    };
    final lower = codec.toLowerCase();
    if (needsSoftDecode.contains(lower)) {
      return supported.contains(lower);
    }
    return false;
  }
}
