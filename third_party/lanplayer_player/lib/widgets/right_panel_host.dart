library;

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';

/// 右侧滑入面板的转场宿主。
///
/// ## 为什么要有这一层
///
/// 改造前每个面板自己在 `initState` 里建 `AnimationController` 然后
/// `forward()`，退场则各行其是，结果是同一个播放器里三种关闭行为并存：
///
/// - `MoreRightPanel`：只有 `forward()`，**没有任何退场动画** ——
///   宿主 `setState(() => _rightPanelType = null)` 直接把它从树上摘掉，
///   面板凭空消失。
/// - `TrackRightPanel`：有 `_animateClose()`，但只有点面板自己的关闭按钮
///   才会走到；点遮罩关闭走的是宿主那个 `setState`，**同一个面板两种行为**。
/// - 全部面板都没设 `reverseDuration`，`reverse()` 因此复用正向时长，
///   退场与入场等速，违反「退场必须快于入场」。
///
/// 根因是入退场归属错了：面板自己控制不了自己什么时候被卸载，所以退场动画
/// 天然放不进面板内部。这里把它提到宿主 —— 面板只管画自己长什么样，
/// 什么时候滑入滑出由 [RightPanelHost] 统一负责，关闭路径也就只剩一条。
///
/// ## 用法
///
/// ```dart
/// RightPanelHost(
///   panelType: _rightPanelType,          // null = 关闭
///   onScrimTap: () => setState(() => _rightPanelType = null),
///   panelBuilder: (type) => switch (type) { ... },
/// )
/// ```
///
/// 调用方仍然只需要把类型置空，退场动画由宿主接管：面板会留在树上滑出去，
/// 播完才真正卸载。
class RightPanelHost extends StatefulWidget {
  const RightPanelHost({
    super.key,
    required this.panelType,
    required this.panelBuilder,
    required this.onScrimTap,
    this.scrimTop = 0,
  });

  /// 当前面板类型；null 表示关闭。
  final String? panelType;

  /// 按类型构建面板内容。退场期间会用最后一个非空类型继续构建。
  final Widget Function(String type) panelBuilder;

  /// 点击面板外遮罩。调用方应在这里把 [panelType] 置空。
  final VoidCallback onScrimTap;

  /// 遮罩顶部留白（播放器里用来放行顶栏点击，使面板打开时仍能切换面板）。
  final double scrimTop;

  /// 入场时长。
  static const Duration enterDuration = AppMotion.enter;

  /// 退场时长。必须快于 [enterDuration]。
  static const Duration exitDuration = AppMotion.exit;

  @override
  State<RightPanelHost> createState() => _RightPanelHostState();
}

class _RightPanelHostState extends State<RightPanelHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  /// 退场期间用来继续构建面板内容 —— widget.panelType 这时已经是 null 了。
  String? _lastType;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: RightPanelHost.enterDuration,
      reverseDuration: RightPanelHost.exitDuration,
      value: widget.panelType == null ? 0.0 : 1.0,
    );
    _slide = _controller.drive(
      Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: AppEase.enter)),
    );
    _lastType = widget.panelType;
  }

  @override
  void didUpdateWidget(RightPanelHost old) {
    super.didUpdateWidget(old);
    if (widget.panelType == old.panelType) return;

    if (widget.panelType != null) {
      // 打开，或在两个面板之间直接切换（不重播入场，避免闪一下）
      _lastType = widget.panelType;
      if (old.panelType == null) {
        if (context.reduceMotion) {
          _controller.value = 1.0;
        } else {
          _controller.forward();
        }
      }
      setState(() {});
    } else {
      // 关闭：留在树上播完退场再卸载
      if (context.reduceMotion) {
        _controller.value = 0.0;
        setState(() => _lastType = null);
      } else {
        _controller.reverse().then((_) {
          if (mounted && widget.panelType == null) {
            setState(() => _lastType = null);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = _lastType;
    if (type == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // 遮罩只在面板真正打开时吃点击；退场途中不再响应，
        // 避免关闭动画期间的误触又把面板拉回来。
        if (widget.panelType != null)
          Positioned(
            top: widget.scrimTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onScrimTap,
              child: const SizedBox.expand(),
            ),
          ),
        // 面板层铺满：面板内部靠 Align(centerRight) 贴右侧定位，需要有界约束。
        // SlideTransition 的位移按 child 尺寸取比例，铺满时 Offset(1,0)
        // 正好等于「整屏宽度」，面板刚好滑出屏幕外。
        Positioned.fill(
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _controller,
              child: RepaintBoundary(child: widget.panelBuilder(type)),
            ),
          ),
        ),
      ],
    );
  }
}
