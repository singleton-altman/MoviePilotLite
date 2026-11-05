import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../utils/glass_quality.dart';
import 'tap_feedback.dart';

/// 播放器右侧滑入面板的统一外壳。
///
/// ## 为什么要有它
///
/// 改造前 `_FitRightPanel` 和 `_DanmakuRightPanel` 把同一套容器抄了两遍：
/// 一样的 `0xFF0F0F1A` 底色与 0.94 透明度、一样的 24 圆角 + 0.1 白边 +
/// 32 模糊投影、一样的「图标 + 标题 + 圆形关闭按钮」标题栏。两边只差宽度、
/// 最大高度和上下留白三个数。
///
/// 抄两遍的直接后果已经出现了一个：两个面板都硬编码
/// `ImageFilter.blur(sigmaX: 32, sigmaY: 32)`，**绕过了 [GlassQuality]** ——
/// 用户在设置里把玻璃质量调成「低」或「关」，这两个面板照样糊 32。现在模糊
/// 只有这一处定义，自然就走上了那个开关。
///
/// 滑入 / 滑出动画不在这里，由 `RightPanelHost` 负责（面板自己控制不了何时
/// 被卸载，退场动画放不进面板内部）。这一层只管"长什么样"。
class PlayerSidePanel extends StatelessWidget {
  const PlayerSidePanel({
    super.key,
    this.title,
    this.icon,
    this.onClose,
    required this.child,
    this.width = 320,
    this.maxHeightFactor = 0.85,
    this.verticalMargin = 48,
  }) : assert(
          (title == null) == (icon == null),
          'title 与 icon 要么都给（有标题栏），要么都不给（无标题栏）',
        );

  /// 标题。为 null 时**不渲染标题栏** —— 设计稿的新版面板靠「点面板外关闭」
  /// 而不是右上角小叉，省下的 44px 高度还给内容。
  final String? title;
  final IconData? icon;

  /// 关闭回调。无标题栏时可以为 null（关闭走外部遮罩）。
  final VoidCallback? onClose;

  /// 面板内容。
  ///
  /// 外壳内部会把它包进 [Flexible]，所以调用方**不要**自己再包一层 ——
  /// 也不必操心限高。改造中间态曾经要求调用方自己包，结果是「谁忘了包谁溢出」，
  /// 那种隐式约定迟早有人踩。
  final Widget child;

  /// 面板宽度。子面板之间切换时会补间过渡（230 ↔ 320）。
  final double width;

  /// 最大高度占屏幕高度的比例。
  final double maxHeightFactor;

  /// 上下留白。画幅面板给得比弹幕面板多，因为它矮得多，居中看起来更稳。
  final double verticalMargin;

  /// 面板底色。两个面板共用，改一处两边一起变。
  static const Color surface = Color(0xFF0F0F1A);

  /// 圆角。
  static const double radius = 24;

  /// 请求的模糊强度。实际值过 [GlassQuality.scaleBlur]，
  /// 用户设置「低」时会被压到 6，「关」时为 0。
  static const double blurSigma = 32;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    return Align(
      alignment: Alignment.centerRight,
      // 宽度补间：首屏 230 ↔ 子面板 320。不补间的话切换时面板会"跳"一下宽度，
      // 而内容是淡入的，两者错开看着很廉价。
      child: AnimatedContainer(
        duration: context.motion(AppMotion.enter),
        curve: AppEase.standard,
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight),
        margin: EdgeInsets.symmetric(vertical: verticalMargin, horizontal: 12),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassQuality.scaleBlur(blurSigma, context),
              sigmaY: GlassQuality.scaleBlur(blurSigma, context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  _TitleBar(
                    title: title!,
                    icon: icon!,
                    onClose: onClose ?? () {},
                  ),
                // 内容超过限高时收缩而不是溢出。放在外壳里兜，
                // 调用方就不必记得自己包 Flexible。
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.title,
    required this.icon,
    required this.onClose,
  });

  final String title;
  final IconData icon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 关闭按钮走项目统一的按压反馈，不再是裸 GestureDetector ——
          // 点了没反馈的按钮会让人怀疑是不是没点上。
          TapFeedback(
            onTap: onClose,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
