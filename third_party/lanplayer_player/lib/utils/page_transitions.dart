/// ══════════════════════════════════════════════════════════════════════
/// 页面转场 —— 手机端与 TV 端共用的唯一实现
/// ══════════════════════════════════════════════════════════════════════
///
/// ## 为什么要有这一层
///
/// 改造前同一个 App 里跑着两份近乎逐字相同的转场实现：`AppAnimations
/// .slideFromRightTransition`（服务 18 个 `Navigator.push` 调用点）和
/// `PageTransitions.slideFromRight`（服务 23 条 `GoRoute`）。同一次操作路径上
/// 走两份拷贝，改一处忘一处。
///
/// 现在一档转场只有一份定义（[TransitionSpec]），由 [MotionPageRoute] 同时
/// 供给 `Navigator.push` 和 go_router 的 `Page`。
///
/// ## 分档语义
///
/// | 档                  | 语义                       | 用在              |
/// |---------------------|----------------------------|-------------------|
/// | [fadeSpec]          | 纯淡入，无方向感           | 根级页面（首页）  |
/// | [slideRightSpec]    | 右入右出镜像               | 层级导航（设置…） |
/// | [fadeSlideUpSpec]   | 下方升起                   | 覆盖式面板（搜索）|
/// | [immersiveSpec]     | 淡入 + 轻微放大            | 进入内容（播放器）|
/// | [slideFromRightSpec]| 全宽右侧滑入 + 底层视差    | 进入内容（详情页）|
///
/// ## 三条被固化的规则
///
/// 1. **退场快于入场且 ≤250ms** —— 时长只能取自 [AppMotion] 的语义令牌，
///    `test/page_transition_motion_test.dart` 遍历 [allSpecs] 逐档断言。
/// 2. **减少动效直出终态** —— [MotionPageRoute] 自己从 navigator 上下文读
///    MediaQuery，调用方无法漏掉这个门禁。
/// 3. **底层页视差由上层路由决定** —— 走 Flutter 的
///    [ModalRoute.delegatedTransition]，所以不管下层用哪一档（甚至是
///    `MaterialPageRoute`）都能拿到一致的让位动作。
library;

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';

/// 一档转场的完整定义。
///
/// 相等性按引用比较（字段里有闭包），所有 spec 都是本文件的 `static final`
/// 单例，因此引用比较即语义比较。
@immutable
class TransitionSpec {
  const TransitionSpec({
    required this.debugName,
    required this.enter,
    required this.exit,
    required this.enterCurve,
    required this.exitCurve,
    required this.primary,
    this.delegatedExit,
  });

  /// 仅用于调试输出与测试失败信息。
  final String debugName;

  /// 入场时长。
  final Duration enter;

  /// 退场时长。必须严格小于 [enter] 且 ≤250ms。
  final Duration exit;

  /// 入场曲线。
  final Curve enterCurve;

  /// 退场曲线。
  final Curve exitCurve;

  /// 本页进入 / 离开的外观。[t] 是已按 [enterCurve] / [exitCurve] 整形的进度。
  final Widget Function(Animation<double> t, Widget child) primary;

  /// 本页压上来时，**下层页**该怎么让位；null 表示下层页保持原样。
  ///
  /// [s] 是下层页视角的 secondary 进度（0 = 未被覆盖，1 = 完全被覆盖），
  /// 同样已按本 spec 的曲线整形，保证与上层页的滑入严格同步。
  final Widget Function(Animation<double> s, Widget child)? delegatedExit;

  @override
  String toString() => 'TransitionSpec($debugName)';
}

/// 把 [CurvedAnimation] 的生命周期收进 State。
///
/// `buildTransitions` 在一次 push 里会被调用 6 次、push+pop 共 9 次（实测）。
/// 而 `CurvedAnimation` 的构造函数**无条件**给 parent 挂一个 status listener，
/// 只有 `dispose()` 会摘掉。所以在 builder 里直接 `CurvedAnimation(...)` 每次
/// 导航都会留下 6~9 个不会被回收的 listener，一直挂到路由销毁。放进 State 里
/// 就只建一次、并且能正确 dispose。
class _SpecTransition extends StatefulWidget {
  const _SpecTransition({
    required this.spec,
    required this.animation,
    required this.child,
    required this.secondary,
  });

  final TransitionSpec spec;
  final Animation<double> animation;
  final Widget child;

  /// false = 用 [TransitionSpec.primary]；true = 用 [TransitionSpec.delegatedExit]。
  final bool secondary;

  @override
  State<_SpecTransition> createState() => _SpecTransitionState();
}

class _SpecTransitionState extends State<_SpecTransition> {
  CurvedAnimation? _curved;

  @override
  void initState() {
    super.initState();
    _makeCurve();
  }

  @override
  void didUpdateWidget(_SpecTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation || oldWidget.spec != widget.spec) {
      _makeCurve();
    }
  }

  void _makeCurve() {
    _curved?.dispose();
    _curved = CurvedAnimation(
      parent: widget.animation,
      curve: widget.spec.enterCurve,
      reverseCurve: widget.spec.exitCurve,
    );
  }

  @override
  void dispose() {
    _curved?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = _curved!;
    return widget.secondary
        ? widget.spec.delegatedExit!(curved, widget.child)
        : widget.spec.primary(curved, widget.child);
  }
}

/// 由 [TransitionSpec] 驱动的路由。`Navigator.push` 与 go_router 共用。
class MotionPageRoute<T> extends PageRoute<T> {
  MotionPageRoute({
    required this.spec,
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : _builder = builder;

  final TransitionSpec spec;
  final WidgetBuilder _builder;

  /// 系统是否要求减少动效。
  ///
  /// 从 navigator 的上下文自己读，而不是让调用方传参 —— 门禁一旦可选就一定
  /// 会被漏掉（改造前 23 条路由无一处做门禁）。用
  /// [BuildContext.getInheritedWidgetOfExactType] 而非 `MediaQuery.of`：路由
  /// 不是 widget，不该建立 inherited 依赖，而 SDK 文档明确允许用这个方法在
  /// 非 build 场景取一次性值。
  bool get _reduceMotion {
    final ctx = navigator?.context;
    if (ctx == null) return false;
    return ctx.getInheritedWidgetOfExactType<MediaQuery>()?.data.disableAnimations ??
        false;
  }

  @override
  Duration get transitionDuration => _reduceMotion ? Duration.zero : spec.enter;

  @override
  Duration get reverseTransitionDuration =>
      _reduceMotion ? Duration.zero : spec.exit;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    if (spec.delegatedExit == null) return null;
    return (context, animation, secondaryAnimation, allowSnapshotting, child) {
      if (child == null) return null;
      // 下层页的让位动作由 secondaryAnimation 驱动（它跟踪本页的推进进度）。
      return _SpecTransition(
        spec: spec,
        animation: secondaryAnimation,
        secondary: true,
        child: child,
      );
    };
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      _builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      _SpecTransition(
        spec: spec,
        animation: animation,
        secondary: false,
        child: child,
      );
}

/// go_router 用的 [Page]，`createRoute` 产出 [MotionPageRoute]。
class MotionPage<T> extends Page<T> {
  const MotionPage({
    required this.spec,
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final TransitionSpec spec;
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => MotionPageRoute<T>(
        spec: spec,
        builder: (_) => child,
        settings: this,
      );
}

// ── 复用的 Tween（顶层 final，避免每次 build 重新分配）──

final Tween<Offset> _fromRightFull =
    Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero);
final Tween<Offset> _fromRightSmall =
    Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero);
final Tween<Offset> _fromBelow =
    Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero);
final Tween<Offset> _parallaxFull =
    Tween<Offset>(begin: Offset.zero, end: const Offset(-0.25, 0));
final Tween<Offset> _parallaxSmall =
    Tween<Offset>(begin: Offset.zero, end: const Offset(-0.08, 0));
final Tween<double> _immersiveScale = Tween<double>(begin: 1.04, end: 1.0);
final Tween<double> _immersiveBelowScale = Tween<double>(begin: 1.0, end: 0.96);

/// 全宽右滑页的左缘投影。
///
/// 改造前这里用 `DecoratedBoxTransition` + `DecorationTween` 逐帧插值阴影
/// —— 每帧重新光栅化模糊，是最贵的画法之一。而阴影画在页面左侧 14px 外，
/// 页面落位后它本就在屏幕外，根本不需要动画：换成静态装饰，视觉一样，
/// 成本归零。
const BoxDecoration _pushShadow = BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: Color(0x6B000000), // 黑 42%
      blurRadius: 24,
      spreadRadius: -6,
      offset: Offset(-14, 0),
    ),
  ],
);

/// 全局统一的页面转场工厂。
class PageTransitions {
  PageTransitions._();

  // ── 分档定义 ──

  /// 纯淡入（根级页面，无方向感）。不推动下层页。
  static final TransitionSpec fadeSpec = TransitionSpec(
    debugName: 'fade',
    enter: AppMotion.enter,
    exit: AppMotion.exit,
    enterCurve: AppEase.enter,
    exitCurve: AppEase.exit,
    primary: (t, child) => FadeTransition(opacity: t, child: child),
  );

  /// 右入右出镜像（层级导航：设置 / 日志 / 服务器）。
  ///
  /// 入场幅度只有 8%，配一个同幅度的下层让位，读起来是"一层薄纸推过来"。
  static final TransitionSpec slideRightSpec = TransitionSpec(
    debugName: 'slideRight',
    enter: AppMotion.pageEnter,
    exit: AppMotion.pageExit,
    enterCurve: AppEase.enter,
    exitCurve: AppEase.exit,
    primary: (t, child) => SlideTransition(
      position: t.drive(_fromRightSmall),
      child: FadeTransition(opacity: t, child: child),
    ),
    delegatedExit: (s, child) => SlideTransition(
      position: s.drive(_parallaxSmall),
      child: child,
    ),
  );

  /// 下方淡入上滑（覆盖式面板，如搜索页）。
  ///
  /// 刻意不推动下层页：面板是"盖上来"而不是"挤进来"，横向位移会给错方向感。
  static final TransitionSpec fadeSlideUpSpec = TransitionSpec(
    debugName: 'fadeSlideUp',
    enter: AppMotion.pageEnter,
    exit: AppMotion.pageExit,
    enterCurve: AppEase.enter,
    exitCurve: AppEase.exit,
    primary: (t, child) => SlideTransition(
      position: t.drive(_fromBelow),
      child: FadeTransition(opacity: t, child: child),
    ),
  );

  /// 沉浸式进入：淡入 + 从 1.04 收到 1.0 的轻微放大（详情页 / 播放器）。
  ///
  /// 配合 Hero 共享元素时缩放幅度刻意做得很小，避免与飞行中的海报打架。
  ///
  /// 下层让位**只缩不淡**：本页是淡入的，转场中途下层页仍然可见，如果下层
  /// 同时淡出就会出现一段整屏发暗（旧代码里那个从未被接上的
  /// `AppPageRouteTransitions.crossfade` 想解决的正是这个"亮度塌陷"）。
  static final TransitionSpec immersiveSpec = TransitionSpec(
    debugName: 'immersive',
    enter: AppMotion.pageEnter,
    exit: AppMotion.pageExit,
    enterCurve: AppEase.enter,
    exitCurve: AppEase.exit,
    primary: (t, child) => FadeTransition(
      opacity: t,
      child: ScaleTransition(scale: t.drive(_immersiveScale), child: child),
    ),
    delegatedExit: (s, child) => ScaleTransition(
      scale: s.drive(_immersiveBelowScale),
      child: child,
    ),
  );

  /// 全宽右侧滑入（iOS push 风格，详情页）。
  ///
  /// iOS push 的三个要素这里齐了：① 新页从右全宽滑入（Apple 曲线）
  /// ② 底层页左移 25% 视差 ③ 新页左缘投影。改造前只有 ①③，②
  /// 在注释里被写成"由 buildPageRoute 驱动"但实际从未实现。
  static final TransitionSpec slideFromRightSpec = TransitionSpec(
    debugName: 'slideFromRight',
    enter: AppMotion.pageEnter,
    exit: AppMotion.pageExit,
    enterCurve: AppEase.spatialEnter,
    exitCurve: AppEase.spatialExit,
    primary: (t, child) => SlideTransition(
      position: t.drive(_fromRightFull),
      child: DecoratedBox(decoration: _pushShadow, child: child),
    ),
    delegatedExit: (s, child) => SlideTransition(
      position: s.drive(_parallaxFull),
      child: child,
    ),
  );

  /// 全部分档，供测试遍历断言不变式。
  static final Map<String, TransitionSpec> allSpecs = {
    'fade': fadeSpec,
    'slideRight': slideRightSpec,
    'fadeSlideUp': fadeSlideUpSpec,
    'immersive': immersiveSpec,
    'slideFromRight': slideFromRightSpec,
  };

  // ── go_router 用的工厂（签名与改造前一致，23 条路由无需改动）──

  /// 纯淡入（根级页面）。
  static MotionPage<T> fade<T>({required Widget child, required LocalKey key}) =>
      MotionPage<T>(spec: fadeSpec, child: child, key: key);

  /// 右入右出镜像（层级导航）。
  static MotionPage<T> slideRight<T>({
    required Widget child,
    required LocalKey key,
  }) =>
      MotionPage<T>(spec: slideRightSpec, child: child, key: key);

  /// 从下方淡入 + 上滑（覆盖式面板）。
  static MotionPage<T> fadeSlideUp<T>({
    required Widget child,
    required LocalKey key,
  }) =>
      MotionPage<T>(spec: fadeSlideUpSpec, child: child, key: key);

  /// 沉浸式进入（淡入 + 轻微放大）。
  static MotionPage<T> immersive<T>({
    required Widget child,
    required LocalKey key,
  }) =>
      MotionPage<T>(spec: immersiveSpec, child: child, key: key);

  /// 全宽右侧滑入（iOS push 风格）。
  static MotionPage<T> slideFromRight<T>({
    required Widget child,
    required LocalKey key,
  }) =>
      MotionPage<T>(spec: slideFromRightSpec, child: child, key: key);

  // ── Navigator.push 用的工厂 ──

  /// 由 [TransitionSpec] 直接构造 `Navigator.push` 用的路由。
  static Route<T> route<T>(TransitionSpec spec, Widget page) =>
      MotionPageRoute<T>(spec: spec, builder: (_) => page);
}
