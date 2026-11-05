import 'dart:io';

import 'subtitle_cue.dart';
import 'subtitle_decoder.dart';
import 'subtitle_registry.dart';

/// 字幕解析器（向后兼容包装器）
///
/// 原本的解析逻辑已拆分到独立的解码器中：
/// - [SrtDecoder]：SRT 格式
/// - [VttDecoder]：WebVTT 格式
/// - [SsaDecoder]：SSA/ASS 格式
///
/// 此类保留 [SubtitleParser] 类名与静态 API，内部委托给
/// [SubtitleRegistry] 与各解码器，保证既有调用方不受影响。
class SubtitleParser {
  /// 从文件路径解析字幕
  ///
  /// 根据扩展名选择对应解码器；未知扩展名则读取内容后自动检测格式。
  static Future<List<SubtitleCue>> parseFile(String path) async {
    try {
      final decoder = SubtitleRegistry.getDecoder(path);
      if (decoder != null) return decoder.decodeFile(path);
      // 未知扩展名，读取内容后自动检测格式
      final file = File(path);
      final bytes = await file.readAsBytes();
      final content = SubtitleDecoder.decodeBytes(bytes);
      return SubtitleRegistry.decodeAuto(content);
    } catch (e) {
      return [];
    }
  }

  /// 从字符串解析字幕
  /// 自动识别 SRT / VTT / SSA 格式
  static List<SubtitleCue> parseContent(String content) {
    return SubtitleRegistry.decodeAuto(content);
  }
}
