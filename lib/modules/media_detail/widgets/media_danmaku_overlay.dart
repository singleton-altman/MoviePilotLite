import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_comment_models.dart';

const _danmakuPalette = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFF93C5FD),
  Color(0xFFFDE68A),
  Color(0xFFF9A8D4),
  Color(0xFF6EE7B7),
  Color(0xFFC4B5FD),
  Color(0xFFFDBA74),
];

const _danmakuGap = 28.0;
const _danmakuMaxLength = 56;

/// 详情页头图上的豆瓣短评弹幕层。
///
/// 默认 3 行，每行是一条持续左移的评论流；颜色由评论内容和行号做稳定散列
/// 从调色板中选取，避免重建时颜色闪烁。
class MediaDanmakuOverlay extends StatelessWidget {
  const MediaDanmakuOverlay({
    super.key,
    required this.comments,
    this.laneCount = 3,
    this.laneHeight = 30,
  });

  final List<DoubanComment> comments;
  final int laneCount;
  final double laneHeight;

  @override
  Widget build(BuildContext context) {
    final texts = _extractTexts(comments);
    if (texts.isEmpty) return const SizedBox.shrink();
    final lanes = math.min(laneCount, texts.length);

    return RepaintBoundary(
      child: ClipRect(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var lane = 0; lane < lanes; lane++)
              SizedBox(
                height: laneHeight,
                child: _DanmakuLane(
                  key: ValueKey('danmaku-$lane-${texts.length}'),
                  entries: _entriesForLane(texts, lane),
                  speed: _speedForLane(lane),
                  fontSize: _fontSizeForLane(lane),
                  opacity: _opacityForLane(lane),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _extractTexts(List<DoubanComment> comments) {
    final seen = <String>{};
    final texts = <String>[];
    for (final comment in comments) {
      final raw = comment.comment?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
      if (raw.isEmpty || seen.contains(raw)) continue;
      seen.add(raw);
      final limited = raw.runes.length > _danmakuMaxLength
          ? '${String.fromCharCodes(raw.runes.take(_danmakuMaxLength))}…'
          : raw;
      texts.add(limited);
      if (texts.length >= 24) break;
    }
    return texts;
  }

  List<_DanmakuEntry> _entriesForLane(List<String> texts, int lane) {
    final offset = lane % texts.length;
    final rotated = <String>[...texts.skip(offset), ...texts.take(offset)];
    return [
      for (var index = 0; index < rotated.length; index++)
        _DanmakuEntry(
          text: rotated[index],
          color: _colorFor(rotated[index], lane, index),
        ),
    ];
  }

  Color _colorFor(String text, int lane, int index) {
    var hash = 17;
    for (final code in text.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    final seed = hash + lane * 13 + index * 7;
    return _danmakuPalette[seed % _danmakuPalette.length];
  }

  double _speedForLane(int lane) {
    const speeds = [13.0, 17.0, 22.0];
    return speeds[lane % speeds.length];
  }

  double _fontSizeForLane(int lane) {
    const sizes = [11.5, 12.5, 13.5];
    return sizes[lane % sizes.length];
  }

  double _opacityForLane(int lane) {
    const opacities = [0.72, 0.86, 1.0];
    return opacities[lane % opacities.length];
  }
}

class _DanmakuEntry {
  const _DanmakuEntry({required this.text, required this.color});

  final String text;
  final Color color;
}

class _DanmakuLane extends StatefulWidget {
  const _DanmakuLane({
    super.key,
    required this.entries,
    required this.speed,
    required this.fontSize,
    required this.opacity,
  });

  final List<_DanmakuEntry> entries;
  final double speed;
  final double fontSize;
  final double opacity;

  @override
  State<_DanmakuLane> createState() => _DanmakuLaneState();
}

class _DanmakuLaneState extends State<_DanmakuLane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _contentWidth = 1;
  String _signature = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _refreshMeasurement();
  }

  @override
  void didUpdateWidget(covariant _DanmakuLane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signatureFor(widget) != _signature) {
      _refreshMeasurement();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _signatureFor(_DanmakuLane lane) {
    return '${lane.speed}|${lane.fontSize}|${lane.opacity}|'
        '${lane.entries.map((entry) => entry.text).join('|')}';
  }

  void _refreshMeasurement() {
    _signature = _signatureFor(widget);
    var width = 0.0;
    for (final entry in widget.entries) {
      final painter = TextPainter(
        text: TextSpan(text: entry.text, style: _textStyle(entry.color)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        textScaler: TextScaler.noScaling,
      )..layout();
      width += painter.width + _danmakuGap;
    }
    _contentWidth = math.max(width, 1);
    final milliseconds = (1000 * _contentWidth / widget.speed).round().clamp(
      9000,
      60000,
    );
    _controller
      ..stop()
      ..duration = Duration(milliseconds: milliseconds)
      ..repeat();
  }

  TextStyle _textStyle(Color color) {
    return TextStyle(
      color: color.withValues(alpha: widget.opacity),
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w600,
      height: 1,
      letterSpacing: 0.15,
      shadows: const [
        Shadow(color: Color(0xD9000000), blurRadius: 4, offset: Offset(0, 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.translate(
            offset: Offset(-_contentWidth * _controller.value, 0),
            child: child,
          ),
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var copy = 0; copy < 2; copy++) ...[
                  for (final entry in widget.entries) ...[
                    Text(
                      entry.text,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: TextScaler.noScaling,
                      style: _textStyle(entry.color),
                    ),
                    const SizedBox(width: _danmakuGap),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
