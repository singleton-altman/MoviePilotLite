import 'subtitle_cue.dart';
import 'subtitle_decoder.dart';

/// SRT 字幕解码器
///
/// 格式示例：
/// ```
/// 1
/// 00:00:01,000 --> 00:00:04,000
/// 字幕文本
/// （空行）
/// ```
class SrtDecoder extends SubtitleDecoder {
  @override
  String get formatName => 'srt';

  /// 从字符串解析 SRT 字幕
  @override
  List<SubtitleCue> decode(String content) {
    final cues = <SubtitleCue>[];
    final blocks = SubtitleDecoder.splitBlocks(content);
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i].trim();
      if (block.isEmpty) continue;
      final cue = SubtitleDecoder.parseBlock(block, i);
      if (cue != null) cues.add(cue);
    }
    return cues;
  }
}
