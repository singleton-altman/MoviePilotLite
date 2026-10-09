import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Netflix 风格双击涟漪动画
/// 在双击位置显示扩展圆弧 + "« 10s" / "10s »" 文字；
/// [playPause] 为 true 时切换为"播放/暂停"模式：柔和扩散圆 + 中央图标，无圆弧无文字。
class DoubleTapRipple extends StatefulWidget {
  final Offset tapPosition;
  final bool isLeftSide;
  final int seconds;
  final VoidCallback? onComplete;
  final int trigger;
  final bool playPause;
  final IconData? playPauseIcon;

  const DoubleTapRipple({
    super.key,
    required this.tapPosition,
    required this.isLeftSide,
    required this.seconds,
    required this.trigger,
    this.onComplete,
    this.playPause = false,
    this.playPauseIcon,
  });

  @override
  State<DoubleTapRipple> createState() => _DoubleTapRippleState();
}

class _DoubleTapRippleState extends State<DoubleTapRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // 双击快进的水波：一次性反馈流线，用最慢档的下界（525ms）。
      // 原先是游离的 600ms。
      duration: AppMotion.slowMin,
      vsync: this,
    );
    _expandAnim = CurvedAnimation(parent: _controller, curve: AppEase.enter);
    _opacityAnim = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _controller.forward();
    _controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete?.call();
    });
  }

  @override
  void didUpdateWidget(DoubleTapRipple old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary 不能省：这是一个全屏 CustomPaint，600ms 内每帧重绘。
    // 没有边界时它的脏区会向上传播，把播放器的视频层一起拖进重绘。
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _ArcPainter(
              progress: _expandAnim.value,
              opacity: _opacityAnim.value,
              tapPosition: widget.tapPosition,
              isLeftSide: widget.isLeftSide,
              seconds: widget.seconds,
              playPause: widget.playPause,
              playPauseIcon: widget.playPauseIcon,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final Offset tapPosition;
  final bool isLeftSide;
  final int seconds;
  final bool playPause;
  final IconData? playPauseIcon;

  _ArcPainter({
    required this.progress,
    required this.opacity,
    required this.tapPosition,
    required this.isLeftSide,
    required this.seconds,
    required this.playPause,
    required this.playPauseIcon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    // 播放/暂停模式：柔和扩散圆 + 中央图标（双击中间区时使用，不画圆弧/秒数）
    if (playPause) {
      final icon = playPauseIcon ?? Icons.pause_rounded;
      final radius = 34 + (84 - 34) * progress;
      final circleFill = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.12)
        ..style = PaintingStyle.fill;
      final circleStroke = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(tapPosition, radius, circleFill);
      canvas.drawCircle(tapPosition, radius, circleStroke);
      // 中央播放/暂停图标（轻微放大 + 淡出）
      final iconSize = 42 + 10 * progress;
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: icon.fontFamily,
            color: Colors.white.withValues(alpha: opacity),
            shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        tapPosition - Offset(iconPainter.width / 2, iconPainter.height / 2),
      );
      return;
    }

    final minRadius = 30.0;
    final maxRadius = 110.0;
    final radius = minRadius + (maxRadius - minRadius) * progress;

    // 半透明扇形填充
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.15)
      ..style = PaintingStyle.fill;

    // 圆弧描边
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 左侧 tap → 弧形朝左; 右侧 tap → 弧形朝右
    final sweepAngle = math.pi * 0.75;
    final startAngle = isLeftSide
        ? math.pi - sweepAngle / 2   // 朝左展开
        : -sweepAngle / 2;           // 朝右展开

    final rect = Rect.fromCircle(center: tapPosition, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, true, fillPaint);
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // 文字: « 10s 或 10s »
    final text = isLeftSide ? '\u00AB ${seconds}s' : '${seconds}s \u00BB';
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity),
          fontSize: 15,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      tapPosition - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress || old.opacity != opacity;
}
