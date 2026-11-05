import 'subtitle_cue.dart';
import 'subtitle_decoder.dart';
import 'ssa_decoder.dart';
import 'srt_decoder.dart';
import 'vtt_decoder.dart';

/// 字幕格式注册表
///
/// 负责根据文件扩展名或内容特征自动检测字幕格式，
/// 并路由到对应的 [SubtitleDecoder]。
class SubtitleRegistry {
  SubtitleRegistry._();

  /// 根据文件扩展名获取解码器
  static SubtitleDecoder? getDecoder(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot >= 0 ? path.substring(dot + 1).toLowerCase() : '';
    switch (ext) {
      case 'srt':
        return SrtDecoder();
      case 'vtt':
        return VttDecoder();
      case 'ssa':
      case 'ass':
        return SsaDecoder();
      default:
        return null;
    }
  }

  /// 自动检测内容格式并解析
  ///
  /// 通过内容特征判断格式：
  /// - 含 `[Script Info]` → SSA/ASS
  /// - 以 `WEBVTT` 开头 → VTT
  /// - 其他 → SRT
  static List<SubtitleCue> decodeAuto(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return [];
    if (trimmed.contains('[Script Info]')) {
      return SsaDecoder().decode(content);
    }
    if (trimmed.toUpperCase().startsWith('WEBVTT')) {
      return VttDecoder().decode(content);
    }
    return SrtDecoder().decode(content);
  }
}
