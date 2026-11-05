/// ══════════════════════════════════════════════════════════════════════
/// 动效令牌 —— 全项目唯一来源
/// ══════════════════════════════════════════════════════════════════════
///
/// ## 时长刻度的来历
///
/// 取自 Astryx（https://github.com/facebook/astryx）主题配置里唯一的动效
/// 定义（`packages/themes/neutral/src/neutralTheme.ts`）：
///
/// ```
/// motion: {fast: 125, medium: 300, slow: 700, ratio: 0.75}
/// // fast-min=95ms, fast=125ms, fast-max=165ms,
/// // medium-min=225ms, medium=300ms, medium-max=400ms
/// ```
///
/// 三个基准档，每档用同一个 ratio 派生上下界（`min = base × ratio`、
/// `max = base ÷ ratio`，按 5ms 取整），共 9 个刻度：
///
/// | 档 | min | base | max |
/// |---|---|---|---|
/// | fast   |  95 | 125 | 165 |
/// | medium | 225 | 300 | 400 |
/// | slow   | 525 | 700 | 935 |
///
/// 好处是刻度可推导而不是一堆魔数：改 ratio 或某个基准值，整把尺子跟着变，
/// 并且 `test/motion_tokens_test.dart` 会守住常量与公式的一致性。
///
/// Astryx **不定义缓动令牌**（缓动交给平台/组件），所以下面的 [AppEase] 走
/// Material 3 + Apple 的曲线，但同样收敛成一套命名。
///
/// ## 语义命名的来历
///
/// 取自 ui-ux-pro-max-skill（https://github.com/nextlevelbuilder/ui-ux-pro-max-skill）
/// 的 motion 数据集（`src/ui-ux-pro-max/data/motion.csv`，17 行 ×
/// subtle/standard/complex 三档强度）。刻意**不**暴露按量级命名的令牌
/// （fast/normal/slow 那种），因为量级名会诱使调用方"随便挑一个差不多的"；
/// 按语义命名才能把规则绑在令牌上。数据集里几条硬规则已经固化进本文件
/// 并有测试守护：
///
/// 1. 退场必须快于入场，且 ≤250ms      → [exit] / [pageExit]
/// 2. 只动 transform / opacity，不动 width / height / margin
/// 3. reduced-motion 直出终态           → [MotionContext.motion]
/// 4. 循环动画随离屏 / 后台停并彻底拆除 → `lib/utils/motion_loop.dart`
/// 5. 错峰不超过约 8 个子元素           → [staggerMaxItems]
/// 6. 骨架微光 1200–1600ms；<300ms 的等待不上骨架
///                                      → [shimmerLoop] / [skeletonMinWait]
/// 7. 过冲缓动限 1–2 个焦点元素，别用在数据列表上 → [AppEase.overshoot]
library;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Astryx 的三档带宽时长模型。
///
/// 单位统一为毫秒。[band] 是 Astryx 用来从基准值派生上下界的公式。
class MotionScale {
  const MotionScale({
    required this.fast,
    required this.medium,
    required this.slow,
    required this.ratio,
  });

  /// 快档基准（ms）。
  final int fast;

  /// 中档基准（ms）。
  final int medium;

  /// 慢档基准（ms）。
  final int slow;

  /// 派生上下界用的比例。下界 = 基准 × ratio，上界 = 基准 ÷ ratio。
  final double ratio;

  /// Astryx 的派生公式：基准值乘上因子后按 5ms 取整。
  ///
  /// 5ms 取整是为了让刻度值可读（95/165/225/400 而不是 93.75/166.67）。
  static int band(int base, double factor) => ((base * factor) / 5).round() * 5;

  int get fastMin => band(fast, ratio);
  int get fastMax => band(fast, 1 / ratio);
  int get mediumMin => band(medium, ratio);
  int get mediumMax => band(medium, 1 / ratio);
  int get slowMin => band(slow, ratio);
  int get slowMax => band(slow, 1 / ratio);
}

/// 本项目采用的刻度，数值直接取自 Astryx neutral 主题。
const MotionScale kMotionScale = MotionScale(
  fast: 125,
  medium: 300,
  slow: 700,
  ratio: 0.75,
);

/// 动效时长令牌。
///
/// 前 9 个是 [kMotionScale] 的刻度，之后是按语义命名的令牌 —— 业务代码
/// 应当只用语义令牌，刻度常量留给新增语义令牌时挑档位用。
class AppMotion {
  AppMotion._();

  // ── 刻度（由 kMotionScale 派生，见 test/motion_tokens_test.dart）──

  static const Duration fastMin = Duration(milliseconds: 95);
  static const Duration fast = Duration(milliseconds: 125);
  static const Duration fastMax = Duration(milliseconds: 165);
  static const Duration mediumMin = Duration(milliseconds: 225);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration mediumMax = Duration(milliseconds: 400);
  static const Duration slowMin = Duration(milliseconds: 525);
  static const Duration slow = Duration(milliseconds: 700);
  static const Duration slowMax = Duration(milliseconds: 935);

  // ── 语义：交互反馈 ──

  /// 按压 / 松手反馈。subtle 档，反馈要在手指还没离开时就出现。
  static const Duration press = fastMin;

  /// 开关、高亮、选中态等局部状态切换。subtle 档（数据集给 150–200ms）。
  static const Duration toggle = fastMax;

  // ── 语义：组件与面板 ──

  /// 组件 / 面板 / 浮层入场。
  static const Duration enter = mediumMin;

  /// 组件 / 面板 / 浮层退场。**必须快于 [enter]**：用户已经决定关掉它了，
  /// 让它慢慢消失只是在挡路。
  static const Duration exit = fastMax;

  /// 列表项 / 卡片渐显。
  static const Duration reveal = medium;

  // ── 语义：页面转场 ──

  /// 页面入场。
  static const Duration pageEnter = mediumMax;

  /// 页面退场。**必须快于 [pageEnter] 且 ≤250ms**。
  static const Duration pageExit = mediumMin;

  /// 共享元素（Hero）飞行。complex 档，需要足够时间让眼睛跟住。
  static const Duration heroFlight = slowMin;

  // ── 语义：轮播 ──

  /// 轮播换页动画时长。
  static const Duration carouselSlide = slowMin;

  /// 轮播每页停留时长。
  static const Duration carouselDwell = Duration(seconds: 8);

  /// 播放器控制栏无操作后自动隐藏的停留时长。
  ///
  /// 与 [carouselDwell] 一样属于「停留」而非「过渡」，不吸附时长刻度 ——
  /// 刻度描述的是眼睛跟随一次变化需要多久，几秒级的等待不在那把尺子上。
  static const Duration controlsDwell = Duration(seconds: 4);

  // ── 语义：错峰 ──

  /// 逐项错峰的单项步长。subtle 档（数据集给 20–40ms）。
  static const Duration staggerStep = Duration(milliseconds: 40);

  /// 参与错峰的最大项数。超出的项直接用同一时刻入场 —— 数据集明确
  /// 「不要给超过约 8 个子元素做错峰」，再多就变成让用户等。
  static const int staggerMaxItems = 8;

  // ── 语义：加载态 ──

  /// 骨架屏微光循环周期（数据集给 1200–1600ms）。
  static const Duration shimmerLoop = Duration(milliseconds: 1400);

  /// 低于此等待时长不要显示骨架屏 —— 闪一下比直接等更烦。
  static const Duration skeletonMinWait = medium;

  // ── TV 焦点（off-ladder 例外）──
  //
  // 下面三个值刻意不吸附到刻度（对应档位是 300 / 225 / 95）。出处是
  // docs/plans/2026-08-20-tv-focus-unify-plan.md 里已确认的 TV 焦点规格，
  // 由原型实测定下：遥控器连按方向键时 300ms 会明显拖尾。
  // 已确认的手感规格优先于刻度的整齐。

  /// TV 焦点进入（配合 scale 1.08）。
  static const Duration tvFocusEnter = Duration(milliseconds: 280);

  /// TV 焦点离开。
  static const Duration tvFocusExit = Duration(milliseconds: 200);

  /// TV 按下（配合 scale 0.94）。
  static const Duration tvPress = Duration(milliseconds: 80);

  /// 遥控器按下后保持按压视觉的时长。
  ///
  /// 遥控器只给 KeyDown/KeyUp，没有"手指还在键上"这个状态，所以按压态是
  /// 定时撤掉的而不是跟着手指走。比 [tvPress] 长：按压动画 80ms 就到位了，
  /// 但立刻弹回会让人怀疑到底按上没按上。这是停留时长，不吸附时长刻度。
  static const Duration tvPressHold = Duration(milliseconds: 150);
}

/// 缓动曲线令牌。
///
/// Astryx 不定义缓动，所以这层取 Material 3 的 emphasized 系列 + Apple
/// UINavigationController 的空间位移曲线，收敛成一套语义命名。
class AppEase {
  AppEase._();

  /// 通用双向过渡（M3 emphasized）。淡入淡出、颜色、尺寸都用它。
  static const Cubic standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// 入场减速（M3 emphasizedDecelerate）。新内容进入，末端平缓落位。
  static const Cubic enter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// 退场加速（M3 emphasizedAccelerate）。旧内容离开，起步就快。
  static const Cubic exit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// 空间位移入场（Apple push 进入）。整页滑入用它。
  static const Cubic spatialEnter = Cubic(0.32, 0.72, 0.0, 1.0);

  /// 空间位移退场（Apple push 返回）。
  static const Cubic spatialExit = Cubic(0.5, 0.0, 0.75, 0.4);

  /// 过冲（末端控制点 y>1，约 35% 过冲后回落）。
  ///
  /// 只用在**同时只有一个焦点元素**的场景：TV 遥控器焦点、底部导航胶囊吸附。
  /// 数据集明确禁止把过冲用在数据列表 / 表格上 —— 一屏十几个东西同时弹会晕。
  ///
  /// 数值来自 docs/plans/2026-08-20-tv-focus-unify-plan.md 已确认的
  /// `cubic(.22,.95,.3,1.35)`。
  static const Cubic overshoot = Cubic(0.22, 0.95, 0.3, 1.35);

  /// 可打断的弹簧（底部导航胶囊拖拽吸附等需要接管速度的场景）。
  static const SpringDescription spring = SpringDescription(
    mass: 0.5,
    stiffness: 260,
    damping: 26,
  );
}

/// 减少动效门禁。
///
/// ui-ux-pro-max 的 motion 数据集里 17 行**每一行**都要求：命中
/// `prefers-reduced-motion` 时跳过动效并**立即渲染终态**。Flutter 侧的对应
/// 开关是系统无障碍设置里的「移除动画」（Android）/「减弱动态效果」（iOS），
/// 读法是 `MediaQuery.disableAnimations`。
///
/// 用法就一行：
/// ```dart
/// AnimatedOpacity(duration: context.motion(AppMotion.enter), ...)
/// ```
extension MotionContext on BuildContext {
  /// 系统是否要求减少动效。
  ///
  /// 用 `maybeDisableAnimationsOf`（而非 `disableAnimationsOf`）有两个原因：
  /// 它只订阅 disableAnimations 这一个 aspect，尺寸变化不会引发重建；
  /// 并且在没有 MediaQuery 祖先的上下文（如 router 的 pageBuilder）里
  /// 退化为 null 而不是抛异常。
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// 需要减少动效时把时长塌缩为 0（直出终态），否则原样返回。
  Duration motion(Duration d) => reduceMotion ? Duration.zero : d;
}
