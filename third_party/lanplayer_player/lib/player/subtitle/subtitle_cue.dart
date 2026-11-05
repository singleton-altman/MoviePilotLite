/// 字幕 cue（单条字幕）
///
/// 借鉴 AndroidX Media3 的 Cue 设计，作为统一的字幕数据模型，
/// 支持 SRT / VTT / SSA / ASS 格式。
class SubtitleCue {
  /// 序号
  final int index;

  /// 开始时间
  final Duration start;

  /// 结束时间
  final Duration end;

  /// 字幕文本（可能含多行，以 \n 分隔）
  final String text;

  /// SSA/ASS 样式名
  final String? styleName;

  /// ARGB 颜色（SSA/ASS 内联样式）
  final int? color;

  /// SSA/ASS 加粗
  final bool? bold;

  /// SSA/ASS 斜体
  final bool? italic;

  /// SSA/ASS 字号
  final double? fontSize;

  const SubtitleCue({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
    this.styleName,
    this.color,
    this.bold,
    this.italic,
    this.fontSize,
  });

  /// 判断给定时间是否在 cue 时间范围内
  bool contains(Duration position) => position >= start && position <= end;

  /// 复制并修改部分字段
  SubtitleCue copyWith({
    int? index,
    Duration? start,
    Duration? end,
    String? text,
    String? styleName,
    int? color,
    bool? bold,
    bool? italic,
    double? fontSize,
  }) {
    return SubtitleCue(
      index: index ?? this.index,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
      styleName: styleName ?? this.styleName,
      color: color ?? this.color,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  String toString() =>
      'SubtitleCue($index: ${start.inMilliseconds}ms-${end.inMilliseconds}ms "$text")';
}
