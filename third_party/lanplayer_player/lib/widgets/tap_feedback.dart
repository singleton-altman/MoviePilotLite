import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// 按压反馈的唯一实现核心。
///
/// ## 为什么要有它
///
/// 改造前有五个几乎重复的按压组件 —— [TapFeedback] / [CardTapFeedback]
/// （本文件）、`ScaleCard` / `AnimatedCard` / `HeroAnimatedCard`
/// （animated_card.dart），每个都自己写一遍 `GestureDetector` +
/// `AnimatedScale` + 硬编码时长，且没有一个做减少动效门禁。
///
/// 现在按压手感只有这一份定义，其余组件都是它的薄壳（默认参数不变，
/// 调用点零改动）。
///
/// ## 两档强度
///
/// 对应 ui-ux-pro-max motion 数据集的 subtle / standard 分档：
/// - [PressFeedbackStyle.subtle]：只缩放。用于海报/剧集卡这类有图片的场景 ——
///   底色变化会干扰图片。
/// - [PressFeedbackStyle.standard]：缩放 + 底色微亮。用于按钮/条目。
///
/// 两档都受减少动效门禁：命中时缩放直接跳到终态、底色不再过渡。
enum PressFeedbackStyle {
  /// 仅缩放。
  subtle,

  /// 缩放 + 底色微亮。
  standard,
}

class PressFeedback extends StatefulWidget {
  const PressFeedback({
    super.key,
    this.child,
    this.pressedBuilder,
    this.onTap,
    this.onLongPress,
    this.style = PressFeedbackStyle.standard,
    this.scaleOnPress = defaultPressScale,
    this.highlightColor,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.springBack = false,
    this.behavior = HitTestBehavior.opaque,
  }) : assert(
          (child == null) != (pressedBuilder == null),
          'child 与 pressedBuilder 必须且只能提供一个',
        );

  /// 内容。与 [pressedBuilder] 二选一。
  final Widget? child;

  /// 需要按压态驱动额外视觉（如阴影切换）时用它取代 [child]。
  ///
  /// 这样按压状态只有一处来源 —— 不必在外面再挂一个 Listener 自己跟踪一遍。
  final Widget Function(BuildContext context, bool pressed)? pressedBuilder;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 反馈强度档位。
  final PressFeedbackStyle style;

  /// 按下时缩放到的比例。
  final double scaleOnPress;

  /// [PressFeedbackStyle.standard] 下按下时的底色；null 用默认微亮白。
  final Color? highlightColor;

  /// [PressFeedbackStyle.standard] 下底色的圆角。
  final BorderRadius? borderRadius;

  /// 缩放锚点。
  final Alignment alignment;

  /// 松手时用 elasticOut 弹回（轻微过冲），形成"回弹"手感。
  final bool springBack;

  final HitTestBehavior behavior;

  /// 默认按下缩放。
  static const double defaultPressScale = 0.96;

  /// 按下时长。subtle 档，反馈要在手指还没离开时就出现。
  static const Duration pressDuration = AppMotion.press;

  /// 松手时长。比按下稍慢，从容回弹。
  static const Duration releaseDuration = AppMotion.toggle;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool v) {
    if (!_interactive || v == _pressed) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    final scale = _pressed ? widget.scaleOnPress : 1.0;

    final pressDur = context.motion(PressFeedback.pressDuration);
    final releaseDur = context.motion(
      widget.springBack ? const Duration(milliseconds: 380) : PressFeedback.releaseDuration,
    );

    Widget content =
        widget.child ?? widget.pressedBuilder!(context, _pressed);

    if (widget.style == PressFeedbackStyle.standard) {
      content = AnimatedContainer(
        duration: pressDur,
        curve: AppEase.standard,
        decoration: BoxDecoration(
          color: _pressed
              ? (widget.highlightColor ?? Colors.white.withValues(alpha: 0.06))
              : Colors.transparent,
          borderRadius: widget.borderRadius,
        ),
        child: content,
      );
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: scale,
        alignment: widget.alignment,
        duration: _pressed ? pressDur : releaseDur,
        // 松手回弹用 elasticOut（除非减少动效，弹簧过冲对前庭敏感者不友好）
        curve: _pressed
            ? AppEase.standard
            : (widget.springBack && !reduce ? Curves.elasticOut : AppEase.standard),
        child: content,
      ),
    );
  }
}

/// 按压反馈包装组件（缩放 + 底色微亮，不使用 Material 涟漪）。
///
/// 用法：
/// ```dart
/// TapFeedback(onTap: () => _handleTap(), child: Text('按钮'))
/// ```
class TapFeedback extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleOnPress;
  final Color? highlightColor;
  final BorderRadius? borderRadius;

  /// 抬起时用 elasticOut 弹回（轻微过冲再回落），形成"回弹"手感。
  final bool springBack;

  const TapFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleOnPress = 0.96,
    this.highlightColor,
    this.borderRadius,
    this.springBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      onTap: onTap,
      onLongPress: onLongPress,
      style: PressFeedbackStyle.standard,
      scaleOnPress: scaleOnPress,
      highlightColor: highlightColor,
      borderRadius: borderRadius,
      springBack: springBack,
      child: child,
    );
  }
}

/// 媒体卡片专用按压反馈（缩放，不改变底色）。
///
/// 用于海报/剧集等有图片的卡片，底色变化会干扰图片显示。
class CardTapFeedback extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleOnPress;

  const CardTapFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleOnPress = 0.95,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      onTap: onTap,
      onLongPress: onLongPress,
      style: PressFeedbackStyle.subtle,
      scaleOnPress: scaleOnPress,
      behavior: HitTestBehavior.deferToChild,
      child: child,
    );
  }
}
