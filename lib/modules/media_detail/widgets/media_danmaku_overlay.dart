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

const _danmakuSizes = [11.5, 12.5, 13.5];
const _danmakuSpeeds = [13.0, 17.0, 22.0];
const _danmakuOpacities = [0.72, 0.86, 1.0];
const _danmakuMaxLength = 56;

/// 详情页头图上的豆瓣短评弹幕层。
///
/// 默认 3 行；同一行内的每条弹幕独立拥有字号、速度和透明度，
/// 速度/字号/透明度按评论内容做稳定散列分档，避免重建时闪烁。
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          return ClipRect(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var lane = 0; lane < lanes; lane++)
                  SizedBox(
                    height: laneHeight,
                    child: _DanmakuLane(
                      key: ValueKey('danmaku-$lane-${texts.length}'),
                      entries: _entriesForLane(texts, lane),
                      viewportWidth: viewportWidth,
                      laneHeight: laneHeight,
                      phase: _phaseForLane(lane),
                    ),
                  ),
              ],
            ),
          );
        },
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
    final entries = <_DanmakuEntry>[];
    var previousTier = -1;
    for (var index = 0; index < rotated.length; index++) {
      var tier = _tierFor(rotated[index], lane, index);
      if (tier == previousTier) tier = (tier + 1) % 3;
      previousTier = tier;
      entries.add(
        _DanmakuEntry(
          text: rotated[index],
          color: _colorFor(rotated[index], lane, index),
          fontSize: _danmakuSizes[tier],
          speed: _danmakuSpeeds[tier],
          opacity: _danmakuOpacities[tier],
        ),
      );
    }
    return entries;
  }

  int _tierFor(String text, int lane, int index) {
    var hash = 17;
    for (final code in text.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return (hash + lane * 11 + index * 7) % 3;
  }

  Color _colorFor(String text, int lane, int index) {
    var hash = 17;
    for (final code in text.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    final seed = hash + lane * 13 + index * 7;
    return _danmakuPalette[seed % _danmakuPalette.length];
  }

  double _phaseForLane(int lane) {
    const phases = [0.22, 0.48, 0.34];
    return phases[lane % phases.length];
  }
}

class _DanmakuEntry {
  const _DanmakuEntry({
    required this.text,
    required this.color,
    required this.fontSize,
    required this.speed,
    required this.opacity,
  });

  final String text;
  final Color color;
  final double fontSize;
  final double speed;
  final double opacity;
}

class _DanmakuLane extends StatefulWidget {
  const _DanmakuLane({
    super.key,
    required this.entries,
    required this.viewportWidth,
    required this.laneHeight,
    required this.phase,
  });

  final List<_DanmakuEntry> entries;
  final double viewportWidth;
  final double laneHeight;
  final double phase;

  @override
  State<_DanmakuLane> createState() => _DanmakuLaneState();
}

class _DanmakuLaneState extends State<_DanmakuLane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_LaneItem> _items = const [];
  double _cycleSeconds = 20;
  String _signature = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _rebuildTimeline();
  }

  @override
  void didUpdateWidget(covariant _DanmakuLane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signatureFor(widget) != _signature) {
      _rebuildTimeline();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _signatureFor(_DanmakuLane lane) {
    final entries = lane.entries
        .map((entry) => '${entry.text}:${entry.fontSize}:${entry.speed}')
        .join('|');
    return '${lane.viewportWidth}|${lane.laneHeight}|$entries';
  }

  void _rebuildTimeline() {
    _signature = _signatureFor(widget);
    final items = <_LaneItem>[];
    var cursor = 0.0;
    for (final entry in widget.entries) {
      final width = _measure(entry);
      final duration = (widget.viewportWidth + width) / entry.speed;
      items.add(
        _LaneItem(
          entry: entry,
          width: width,
          start: cursor,
          duration: duration,
        ),
      );
      cursor += (width + 36) / entry.speed + 0.6;
    }
    _items = items;
    final lastEnd = items.isEmpty
        ? 0.0
        : items
              .map((item) => item.start + item.duration)
              .reduce((a, b) => math.max(a, b));
    _cycleSeconds = math.max(lastEnd + 3, 12);
    _controller
      ..stop()
      ..duration = Duration(milliseconds: (_cycleSeconds * 1000).round())
      ..repeat();
  }

  double _measure(_DanmakuEntry entry) {
    final painter = TextPainter(
      text: TextSpan(text: entry.text, style: _textStyle(entry)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout();
    return painter.width;
  }

  TextStyle _textStyle(_DanmakuEntry entry) {
    return TextStyle(
      color: entry.color.withValues(alpha: entry.opacity),
      fontSize: entry.fontSize,
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
          builder: (context, _) {
            final elapsed =
                (_cycleSeconds * (_controller.value + widget.phase)) %
                _cycleSeconds;
            final children = <Widget>[];
            for (final item in _items) {
              final progress = elapsed - item.start;
              if (progress < 0 || progress > item.duration) continue;
              final x = widget.viewportWidth - progress * item.entry.speed;
              if (x > widget.viewportWidth || x + item.width < 0) continue;
              children.add(
                Positioned(
                  left: x,
                  top: 0,
                  height: widget.laneHeight,
                  child: Align(
                    widthFactor: 1,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.entry.text,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: TextScaler.noScaling,
                      style: _textStyle(item.entry),
                    ),
                  ),
                ),
              );
            }
            return Stack(clipBehavior: Clip.hardEdge, children: children);
          },
        ),
      ),
    );
  }
}

class _LaneItem {
  const _LaneItem({
    required this.entry,
    required this.width,
    required this.start,
    required this.duration,
  });

  final _DanmakuEntry entry;
  final double width;
  final double start;
  final double duration;
}
