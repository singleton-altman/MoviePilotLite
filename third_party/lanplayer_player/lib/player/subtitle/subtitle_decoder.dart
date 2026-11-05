import 'dart:convert';
import 'dart:io';
import 'package:fast_gbk/fast_gbk.dart';

import 'subtitle_cue.dart';

/// 字幕解码器抽象接口
///
/// 借鉴 AndroidX Media3 的 SubtitleDecoder 分层设计：
/// 每种字幕格式（SRT / VTT / SSA / ASS）实现此接口，
/// 将原始字幕内容解码为统一的 [SubtitleCue] 列表。
abstract class SubtitleDecoder {
  /// 格式标识（如 'srt' / 'vtt' / 'ssa'）
  String get formatName;

  /// 从字符串解析字幕
  List<SubtitleCue> decode(String content);

  /// 从文件解析字幕（自动检测编码）
  ///
  /// 编码检测逻辑（UTF-8 / GBK）统一放在此方法中：
  /// 优先 UTF-8，失败则尝试 GBK，最后兜底强制解码。
  Future<List<SubtitleCue>> decodeFile(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final content = decodeBytes(bytes);
    return decode(content);
  }

  // ------------------------------------------------------------------
  // 编码检测：供所有解码器共享
  // ------------------------------------------------------------------

  /// 自动检测字节编码并解码
  /// 优先 UTF-8，失败则尝试 GBK
  static String decodeBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      // 尝试 GBK 解码（中文字幕常见）
      try {
        return _decodeGbk(bytes);
      } catch (_) {
        // 兜底：强制 UTF-8 解码（替换无效字节）
        return utf8.decode(bytes, allowMalformed: true);
      }
    }
  }

  /// GBK/GB18030 解码（中文字幕常见编码）
  /// 原实现用 String.fromCharCodes 逐字节映射，解码结果全为乱码。
  /// 改用 fast_gbk 纯 Dart 解码器，正确处理双字节汉字。
  static String _decodeGbk(List<int> bytes) {
    try {
      return gbk.decode(bytes);
    } catch (_) {
      // 兜底：强制 UTF-8 解码（替换无效字节）
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  // ------------------------------------------------------------------
  // SRT / VTT 共用的块解析辅助方法
  // ------------------------------------------------------------------

  /// 按空行分割块
  static List<String> splitBlocks(String content) {
    return content.split(RegExp(r'\r?\n\s*\r?\n'));
  }

  /// 解析单个字幕块
  static SubtitleCue? parseBlock(String block, int index) {
    final lines = block
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    int lineIdx = 0;
    // 跳过序号行（SRT 第 1 行是序号，VTT 可能没有）
    if (lineIdx < lines.length && isIndexLine(lines[lineIdx])) {
      lineIdx++;
    }

    if (lineIdx >= lines.length) return null;

    // 解析时间行
    final timeLine = lines[lineIdx];
    final timeMatch = parseTimeLine(timeLine);
    if (timeMatch == null) return null;
    lineIdx++;

    // 剩余行是字幕文本
    if (lineIdx >= lines.length) return null;
    final text = lines.sublist(lineIdx).join('\n').trim();
    if (text.isEmpty) return null;

    return SubtitleCue(
      index: index,
      start: timeMatch.$1,
      end: timeMatch.$2,
      text: text,
    );
  }

  /// 判断是否是序号行（纯数字）
  static bool isIndexLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    return int.tryParse(trimmed) != null;
  }

  /// 解析时间行：00:00:01,000 --> 00:00:04,000 或 00:00:01.000 --> 00:00:04.000
  /// 返回 (start, end)
  static (Duration, Duration)? parseTimeLine(String line) {
    // 匹配 HH:MM:SS,mmm --> HH:MM:SS,mmm 或 HH:MM:SS.mmm --> HH:MM:SS.mmm
    final regex = RegExp(
      r'(\d{1,2}:\d{2}:\d{2}[,.]\d{1,3})\s*-->\s*(\d{1,2}:\d{2}:\d{2}[,.]\d{1,3})',
    );
    final match = regex.firstMatch(line);
    if (match == null) return null;
    final start = parseTime(match.group(1)!);
    final end = parseTime(match.group(2)!);
    if (start == null || end == null) return null;
    return (start, end);
  }

  /// 解析单个时间字符串：00:00:01,000 或 00:00:01.000 或 00:01.000（VTT 简写）
  static Duration? parseTime(String time) {
    try {
      // 统一用 . 或 , 作为毫秒分隔符
      final normalized = time.replaceAll(',', '.');
      final parts = normalized.split(':');
      int hours = 0, minutes = 0;
      double secondsWithMs = 0;
      if (parts.length == 3) {
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
        secondsWithMs = double.parse(parts[2]);
      } else if (parts.length == 2) {
        // VTT 简写格式 MM:SS.mmm
        minutes = int.parse(parts[0]);
        secondsWithMs = double.parse(parts[1]);
      } else {
        return null;
      }
      final totalMs = (hours * 3600 + minutes * 60 + secondsWithMs) * 1000;
      return Duration(milliseconds: totalMs.round());
    } catch (_) {
      return null;
    }
  }
}
