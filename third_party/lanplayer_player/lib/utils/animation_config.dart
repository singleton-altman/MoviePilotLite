/// 旧动效常量的兼容层。
///
/// **新代码请直接用 [AppMotion] / [AppEase]（`lib/theme/motion.dart`）。**
///
/// 本文件曾经装着三套并存的令牌：`AppAnimations`（141 处在用）、
/// `AppDurations` + `AppEasing`（0 处在用）、`AppPageRouteTransitions` +
/// `ListItemAnimation`（0 处在用）。后两套连同 `slideFromRightTransition`
/// （与 `PageTransitions.slideFromRight` 逐字重复的拷贝）共约 300 行死代码
/// 已删除，剩下的 11 个在用成员改为指向语义令牌的别名。
///
/// 时长映射（旧的按量级命名 → 新的按语义命名）：
///
/// | 旧              | 旧值  | 新              | 新值  |
/// |-----------------|-------|-----------------|-------|
/// | fast            | 120ms | [AppMotion.fast]     | 125ms |
/// | normal          | 200ms | [AppMotion.toggle]   | 165ms |
/// | medium          | 300ms | [AppMotion.reveal]   | 300ms |
/// | slow            | 400ms | [AppMotion.pageEnter]| 400ms |
/// | pageTransition  | 350ms | [AppMotion.pageEnter]| 400ms |
/// | navPill         | 220ms | [AppMotion.enter]    | 225ms |
/// | carouselColor   | 400ms | [AppMotion.pageEnter]| 400ms |
///
/// 六个里三个原地不动、两个只挪 5ms —— 换刻度不换手感。
library;

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';
import 'page_transitions.dart';

/// 旧动效常量别名。新代码用 [AppMotion] / [AppEase]。
class AppAnimations {
  AppAnimations._();

  // ── 时长 ──

  /// 按量级命名的旧令牌。新代码用 [AppMotion.press] 或 [AppMotion.fast]。
  static const Duration fast = AppMotion.fast;

  /// 按量级命名的旧令牌。新代码用 [AppMotion.toggle]。
  static const Duration normal = AppMotion.toggle;

  /// 按量级命名的旧令牌。新代码用 [AppMotion.reveal]。
  static const Duration medium = AppMotion.reveal;

  /// 按量级命名的旧令牌。新代码用 [AppMotion.pageEnter]。
  static const Duration slow = AppMotion.pageEnter;

  /// 新代码用 [AppMotion.pageEnter]。
  static const Duration pageTransition = AppMotion.pageEnter;

  /// 底部导航胶囊滑动。新代码用 [AppMotion.enter]。
  static const Duration navPill = AppMotion.enter;

  /// 轮播取色背景过渡。新代码用 [AppMotion.pageEnter]。
  ///
  /// 分类区背景色与底部渐变遮罩共用此时长，两者必须同步否则出现色带割裂。
  static const Duration carouselColor = AppMotion.pageEnter;

  // ── 曲线 ──

  /// 新代码用 [AppEase.standard]。
  static const Curve easeOut = AppEase.standard;

  /// 新代码用 [AppEase.exit]。
  static const Curve easeIn = AppEase.exit;

  /// 新代码用 [AppEase.standard]。
  static const Curve easeInOut = AppEase.standard;

  // ── 转场 ──

  /// 旧的转场类型到 [TransitionSpec] 的映射。
  static TransitionSpec specFor(PageTransitionType type) => switch (type) {
        PageTransitionType.fade => PageTransitions.fadeSpec,
        PageTransitionType.slideRight => PageTransitions.slideRightSpec,
        // slideUp 与 fadeSlide 在旧实现里只差 10% 的起始偏移，
        // 视觉上分不出来，统一到覆盖式面板一档。
        PageTransitionType.slideUp => PageTransitions.fadeSlideUpSpec,
        PageTransitionType.fadeSlide => PageTransitions.fadeSlideUpSpec,
        PageTransitionType.slideFromRight => PageTransitions.slideFromRightSpec,
      };

  /// 构造 `Navigator.push` 用的路由。
  ///
  /// 改造前这里是一份与 [PageTransitions] 逐字重复的实现，现在转发过去，
  /// 保证 `Navigator.push` 与 go_router 的 23 条路由跑同一份转场。
  static Route<T> buildPageRoute<T>({
    required Widget page,
    PageTransitionType type = PageTransitionType.fade,
  }) =>
      PageTransitions.route<T>(specFor(type), page);
}

/// 旧的转场类型枚举。新代码直接用 [PageTransitions] 的分档工厂。
enum PageTransitionType {
  fade,
  slideRight,
  slideUp,
  fadeSlide,
  slideFromRight,
}
