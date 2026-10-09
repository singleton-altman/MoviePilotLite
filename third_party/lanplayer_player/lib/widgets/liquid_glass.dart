import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/glass_quality.dart';

/// 液体玻璃表面。
///
/// ## 它和磨砂玻璃差在哪
///
/// 磨砂玻璃是 `BackdropFilter(ImageFilter.blur(...))` —— 背景糊掉，边缘什么
/// 都不发生。液体玻璃多了**折射**：靠近边缘时背景被向内拉弯，像透过一块有
/// 厚度的玻璃。这一步必须拿到背景像素，纯 Widget 叠加做不到，所以走
/// `ImageFilter.shader` + [shaders/nav_glass.frag]。
///
/// ## 降级不是可选项
///
/// `ImageFilter.shader` **只在 Impeller 后端可用**，Skia 后端直接抛
/// `UnsupportedError`。Android 上 Impeller 是 Vulkan 设备的默认后端，但老设备
/// 仍会落到 Skia。所以这里必须双路径：
///
/// - 支持 → 着色器折射
/// - 不支持 / 着色器还没加载完 → 退回原来的磨砂玻璃（视觉上少了边缘折射，
///   但不会白屏也不会崩）
///
/// 判定走 [ui.ImageFilter.isShaderFilterSupported]，不是自己猜平台。
///
/// ## 着色器程序只编译一次
///
/// [FragmentProgram.fromAsset] 每次调用都会重新解析资源，而这个 widget 在
/// 导航栏里每帧都要 build。程序对象缓存成静态 Future，全进程一份。
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    required this.borderRadius,
    this.highlightX = 0.5,
    this.blurSigma = 18,
    this.baseBlur = 0.0,
    this.refract = 0.012,
    this.edge = 0.10,
    this.specular = 0.55,
    this.tint = 0.34,
  });

  final Widget child;

  /// 圆角。**只用于外层 ClipRRect 的遮罩**，不再传给着色器 ——
  /// 第一版把它换算成归一化半径喂给距离场，而距离场基于 uSize（纹理尺寸，
  /// 不是 widget 尺寸），算出来的形状跟导航栏无关，屏幕上表现为正中间一个
  /// 硬边缺口。现在形状只由这里的裁剪决定。
  final BorderRadius borderRadius;

  /// 高光中心横向位置（0..1）。导航栏把胶囊的当前位置喂进来，
  /// 高光就会跟着胶囊扫过去。
  final double highlightX;

  /// 降级路径用的模糊强度；着色器路径下玻璃本体的通透感由 [tint] 控制。
  final double blurSigma;

  /// 着色器路径的基线模糊（sigma）。**默认 0 —— 玻璃必须是一整块材质**：
  /// 只要中间还垫模糊,锐利的折射棱线圈着雾面内芯,眼睛就把它拆成
  /// 「透明外框 + 磨砂内芯两块玻璃,且尺寸对不上」（用户多轮实测的结论:
  /// sigma 5 → 「中间糊」、sigma 2 → 「内芯小一圈」）。玻璃感由折射棱线、
  /// 顶线、微透镜视差这些「线」提供,不靠雾。0 = 完全清澈。
  /// 通过 ImageFilter.compose 垫在折射着色器底下（若 >0）。经过
  /// GlassQuality.scaleBlur 分级（低端机/减少动效自动衰减）。
  final double baseBlur;

  /// 折射强度（归一化单位）。
  final double refract;

  /// 折射影响的边缘带宽（栏高占比）。0.10 ≈ 7.6px 的细折射线 ——
  /// 旧值 0.22（17px）时边缘带里铺满折射+雾度+亮环，环绕一圈像透明
  /// 玻璃上糊了块磨砂边框，中间清、边缘雾，两种材质不统一（用户实测：
  /// 「透明玻璃上面又糊了一块磨砂玻璃」）。窄带让边缘读作玻璃的棱线。
  final double edge;

  /// 高光强度。
  final double specular;

  /// 玻璃本体着色浓度。0 = 只有折射不着色。
  final double tint;

  /// 着色器资源路径。测试里也引用它，避免字符串写两遍。
  static const String shaderAsset = 'shaders/nav_glass.frag';

  /// 设置页「玻璃效果等级」对基线模糊的作用：高=原值；低=上限 3
  /// （与高拉开可感知差距；折射/高光是单 pass 着色器，开销小，保留）；
  /// 关=0。关档时 build 里整块玻璃退场，不采样背景。
  static double effectiveBaseBlur(double baseBlur, GlassQualityLevel level) =>
      switch (level) {
        GlassQualityLevel.high => baseBlur,
        GlassQualityLevel.low => baseBlur.clamp(0.0, 3.0),
        GlassQualityLevel.off => 0.0,
      };

  /// 全进程共享的着色器程序。
  static Future<ui.FragmentProgram>? _programFuture;

  static Future<ui.FragmentProgram> _loadProgram() =>
      _programFuture ??= ui.FragmentProgram.fromAsset(shaderAsset);

  /// 当前环境能否走着色器路径。
  ///
  /// 单独暴露出来是为了让调用方（和测试）能问同一个问题，
  /// 而不是各自去判断平台。
  static bool get isSupported => ui.ImageFilter.isShaderFilterSupported;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  ui.FragmentShader? _shader;
  bool _failed = false;
  // widget 在背景快照纹理里的物理矩形（方案 A：折射/高光的几何坐标系）。
  // 布局完成才能测，首帧先走降级路径，测到后切回着色器路径。
  ui.Rect? _rectPx;

  @override
  void initState() {
    super.initState();
    if (LiquidGlass.isSupported) _initShader();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureRect());
  }

  /// 把 widget 的全局矩形换算成纹理像素坐标。
  ///
  /// 背景快照与屏幕同尺寸同原点（首页整层背景），uRect 因此用
  /// 全局逻辑坐标 × devicePixelRatio。玻璃本体不会移动（胶囊高光动画
  /// 在内部，不挪玻璃层），postFrame 里值不变就不触发 setState。
  void _measureRect() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final topLeft = box.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(topLeft.dx * dpr, topLeft.dy * dpr,
        box.size.width * dpr, box.size.height * dpr);
    if (rect != _rectPx) setState(() => _rectPx = rect);
  }

  Future<void> _initShader() async {
    try {
      final program = await LiquidGlass._loadProgram();
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (e, s) {
      // 资源缺失或编译失败都不该让导航栏消失 —— 记一笔然后降级。
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: s,
        library: 'liquid_glass',
        context: ErrorDescription('加载 ${LiquidGlass.shaderAsset} 失败，退回磨砂玻璃'),
      ));
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 设置页「玻璃效果等级」对导航栏生效：关 = 玻璃整块退场，不采样
    // 背景，只剩 child 自带的半透明表面 + 描边（最省 GPU 的一档）。
    // 优先级最高 —— 比降级路径更彻底，放最前。
    final quality = GlassQuality.current;
    if (quality == GlassQualityLevel.off) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: widget.child,
      );
    }

    final shader = _shader;
    final rect = _rectPx;
    // 矩形还没测到（首帧）或着色器不可用 —— 都走降级。
    if (shader == null || _failed || rect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureRect());
      return _fallback(context);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 下标必须与 nav_glass.frag 的 uniform 声明顺序一致。
    // 0、1 是 uSize，由引擎写入，这里不能碰；8..11 是 uRect 四个分量。
    shader
      ..setFloat(2, widget.refract)
      ..setFloat(3, widget.edge)
      ..setFloat(4, widget.highlightX)
      ..setFloat(5, widget.specular)
      ..setFloat(6, widget.tint)
      ..setFloat(7, isDark ? 1.0 : 0.0)
      ..setFloat(8, rect.left)
      ..setFloat(9, rect.top)
      ..setFloat(10, rect.right)
      ..setFloat(11, rect.bottom);

    // 形状只由这层裁剪决定 —— 着色器不再自己推几何。
    // baseBlur > 0 时把轻微模糊垫在折射着色器底下（compose 的 inner 先
    // 作用于背景，着色器采到的就是柔化后的背景，折射重影也随之变柔）。
    final blurSigma = GlassQuality.scaleBlur(
        LiquidGlass.effectiveBaseBlur(widget.baseBlur, quality), context);
    final ui.ImageFilter filter = blurSigma > 0
        ? ui.ImageFilter.compose(
            outer: ui.ImageFilter.shader(shader),
            inner: ui.ImageFilter.blur(
                sigmaX: blurSigma, sigmaY: blurSigma))
        : ui.ImageFilter.shader(shader);
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: BackdropFilter(
        filter: filter,
        child: widget.child,
      ),
    );
  }

  /// 降级：原来的磨砂玻璃。
  Widget _fallback(BuildContext context) => ClipRRect(
        borderRadius: widget.borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: GlassQuality.scaleBlur(widget.blurSigma, context),
            sigmaY: GlassQuality.scaleBlur(widget.blurSigma, context),
          ),
          child: widget.child,
        ),
      );
}
