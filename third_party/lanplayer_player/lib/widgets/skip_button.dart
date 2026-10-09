import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Netflix 风格 "跳过片头/片尾" 浮动按钮
/// 从右侧滑入，自动聚焦，10s 倒计时进度条走完后自动跳过
class SkipButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onAutoExpire;

  /// 是否启用 10s 倒计时自动跳过。
  ///
  /// 关闭时按钮纯手动：不启动倒计时、不显示进度环，也不会自己触发 onTap，
  /// 停留到播放位置移出片头/片尾区间后由父级淡出。接「自动跳过片头/片尾」
  /// 设置——该设置关闭时按钮不得自作主张跳过（用户实证过的行为：关了自动
  /// 跳过按钮却在 10s 后自己跳，根因就是这里无条件倒计时）。
  final bool autoSkip;

  const SkipButton({
    super.key,
    required this.label,
    required this.onTap,
    this.onAutoExpire,
    this.autoSkip = true,
  });

  @override
  State<SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<SkipButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _cancelled = false;

  // 10s 倒计时
  static const int _countdownTotal = 10;

  /// 倒计时每一跳的长度。
  ///
  /// 进度条的补间时长必须等于这个值 —— 两者不一致的话进度条会追不上或
  /// 提前跑完，看起来像卡顿。所以只留一个常量，两处都引用它。
  static const Duration countdownTick = Duration(seconds: 1);
  int _countdownRemaining = _countdownTotal;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // 入场用 mediumMax（400ms）。这里刻意**不**用 AppMotion.enter(225ms)：
      // 那一档对「浮层入场」是对的，但这个按钮是在观众正看着片头时突然出现在
      // 画面角上的东西，225ms 实测太急，像弹窗砸出来。400ms 才是"滑进来"。
      // 退场仍用 exit —— 用户已经决定让它走了。
      duration: AppMotion.mediumMax,
      reverseDuration: AppMotion.exit,
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppEase.spatialEnter,
      reverseCurve: AppEase.spatialExit,
    ));
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppEase.enter,
        reverseCurve: AppEase.exit,
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppEase.enter,
        reverseCurve: AppEase.exit,
      ),
    );

    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });

    // 入场播完再要焦点。改造前是写死的 400ms 延迟 —— 那个数字和入场时长
    // 没有任何绑定关系，改了入场时长它就错位（要么抢在滑入途中夺焦，
    // 要么白等）。挂在 forward() 的 TickerFuture 上就不会脱节。
    _controller.forward().then((_) {
      if (mounted) _focusNode.requestFocus();
    });

    // 10s 倒计时，每秒 tick（autoSkip=false 时纯手动，不倒计时）
    if (widget.autoSkip) _startCountdown();
  }

  @override
  void didUpdateWidget(covariant SkipButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label == widget.label) return;
    _countdownTimer?.cancel();
    _countdownRemaining = _countdownTotal;
    _cancelled = false;
    _controller
      ..reset()
      ..forward();
    if (widget.autoSkip) _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(countdownTick, (_) {
      if (!mounted || _cancelled) return;
      setState(() => _countdownRemaining--);
      if (_countdownRemaining <= 0) {
        _countdownTimer?.cancel();
        widget.onTap();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // OK/Enter → 立即跳过
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      _countdownTimer?.cancel();
      widget.onTap();
      return KeyEventResult.handled;
    }
    // LEFT/BACK → 取消自动跳过，按钮淡出
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelled = true;
      _countdownTimer?.cancel();
      _controller.reverse().then((_) {
        if (mounted) widget.onAutoExpire?.call();
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _countdownTotal > 0
        ? (1.0 - _countdownRemaining / _countdownTotal).clamp(0.0, 1.0)
        : 0.0;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Focus(
            focusNode: _focusNode,
          onKeyEvent: _onKey,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              // 焦点态边框切换：局部状态切换用 toggle，并受减少动效门禁。
              duration: context.motion(AppMotion.toggle),
              curve: AppEase.standard,
              padding: const EdgeInsets.fromLTRB(20, 10, 14, 10),
              decoration: BoxDecoration(
                // 实心白底：不依赖背景模糊，明亮画面上也醒目。
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                // 聚焦时加一圈黑环 —— 白底上黑环比"更白"看得清。
                border: _isFocused
                    ? Border.all(color: Colors.black, width: 3)
                    : null,
                boxShadow: [
                  // 与视频画面拉开层次，白底压在亮画面上才不会糊成一片。
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  // 聚焦时再加一圈白色外发光，遥控器操作时一眼能找到
                  if (_isFocused)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.55),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                ],
              ),
              // 单行紧凑：标签 + 环形倒计时，不再是"两行 + 底部横条"
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 倒计时环只在自动跳过模式下显示；纯手动模式没有倒计时，
                  // 留着环会误导用户"还有几秒会自动跳"。
                  if (widget.autoSkip) ...[
                    _CountdownRing(
                      progress: progress,
                      remaining: _countdownRemaining,
                      tick: _SkipButtonState.countdownTick,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// 环形倒计时（白底黑环）。
///
/// 取代原先按钮底部那条 140px 宽的横条：横条要额外占一行高度，把按钮撑成
/// 两行；环形塞在文字右边，一行就够，也更像"还剩多久"而不是"加载进度"。
///
/// 补间时长必须等于倒计时步长（[tick]），否则环追不上中间那个数字。
class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.progress,
    required this.remaining,
    required this.tick,
  });

  /// 已流逝比例 0..1。
  final double progress;

  /// 剩余秒数，画在环中间。
  final int remaining;

  final Duration tick;

  static const double _size = 24;
  static const double _stroke = 2.4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: tick,
        curve: Curves.linear,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(value),
          child: Center(
            child: Text(
              '$remaining',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  /// 轨道与进度弧的画笔都不随进度变化，提为静态避免每帧分配。
  static final Paint _track = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _CountdownRing._stroke
    ..color = Colors.black.withValues(alpha: 0.18);

  static final Paint _arc = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = _CountdownRing._stroke
    ..strokeCap = StrokeCap.round
    ..color = Colors.black;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = _CountdownRing._stroke / 2;
    final arcRect = rect.deflate(inset);
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, _track);
    // 从 12 点方向顺时针推进
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      _arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// 下一集自动播放倒计时卡片
class NextEpisodeCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? thumbnailUrl;
  final int totalSeconds;
  final int remainingSeconds;
  final VoidCallback onPlay;
  final VoidCallback onCancel;

  const NextEpisodeCard({
    super.key,
    required this.title,
    this.subtitle,
    this.thumbnailUrl,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.onPlay,
    required this.onCancel,
  });

  @override
  State<NextEpisodeCard> createState() => _NextEpisodeCardState();
}

class _NextEpisodeCardState extends State<NextEpisodeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.enter,
    )..forward();
    // TV 上倒计时卡必须持有焦点,遥控器才能 OK 立即播 / ← 取消;
    // 触屏端 Focus 不拦手势,无感。
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA ||
        event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
      widget.onPlay();
      return KeyEventResult.handled;
    }
    // ← / 返回 = 取消自动播放（父级在 onCancel 里归还焦点）
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onCancel();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalSeconds > 0
        ? (1.0 - widget.remainingSeconds / widget.totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.6, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
      ),
      child: FadeTransition(
        opacity: _entranceCtrl,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _onKey,
          child: Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '下一集',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.remainingSeconds}s',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onPlay,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progress),
                            // 必须等于倒计时步长
                            duration: _SkipButtonState.countdownTick,
                            curve: Curves.linear,
                            builder: (context, value, _) {
                              return SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  color: AppTheme.primary,
                                ),
                              );
                            },
                          ),
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        '取消自动播放',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
          ),
        ),
      ),
    );
  }
}
