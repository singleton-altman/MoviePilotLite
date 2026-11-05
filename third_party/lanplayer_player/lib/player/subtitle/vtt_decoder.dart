import 'subtitle_cue.dart';
import 'subtitle_decoder.dart';

/// WebVTT 字幕解码器
///
/// 格式示例：
/// ```
/// WEBVTT
///
/// 00:00:01.000 --> 00:00:04.000
/// 字幕文本
/// （空行）
/// ```
///
/// VTT 特有处理：
/// - 移除 WEBVTT 头部（可能包含元数据）
/// - 跳过 NOTE / STYLE / REGION 块
/// - 支持 VTT 简写时间格式（MM:SS.mmm）
class VttDecoder extends SubtitleDecoder {
  @override
  String get formatName => 'vtt';

  /// 从字符串解析 VTT 字幕
  @override
  List<SubtitleCue> decode(String content) {
    final cues = <SubtitleCue>[];
    final lines = content.split(RegExp(r'\r?\n'));

    // 移除 WEBVTT 头部（可能包含元数据）
    int startIdx = 0;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().toUpperCase().startsWith('WEBVTT')) {
        startIdx = i + 1;
        break;
      }
    }
    // 跳过头部后的空行
    while (startIdx < lines.length && lines[startIdx].trim().isEmpty) {
      startIdx++;
    }

    final body = lines.sublist(startIdx).join('\n');
    final blocks = SubtitleDecoder.splitBlocks(body);
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i].trim();
      if (block.isEmpty) continue;
      // 跳过 NOTE / STYLE / REGION 块
      if (_isMetaBlock(block)) continue;
      final cue = SubtitleDecoder.parseBlock(block, i);
      if (cue != null) cues.add(cue);
    }
    return cues;
  }

  /// 判断是否是 VTT 元数据块（NOTE / STYLE / REGION）
  bool _isMetaBlock(String block) {
    final firstLine = block.split(RegExp(r'\r?\n')).first.trim().toUpperCase();
    return firstLine.startsWith('NOTE') ||
        firstLine.startsWith('STYLE') ||
        firstLine.startsWith('REGION');
  }
}
