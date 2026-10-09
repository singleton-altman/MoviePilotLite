// 液体玻璃：底部导航栏的折射 + 高光着色器。
//
// ## 与磨砂玻璃的区别
//
// 磨砂玻璃只是把背景模糊掉（BackdropFilter + blur）。液体玻璃多两件事：
//   1. 折射 —— 靠近边缘时背景被"拉弯"，像透过一块有厚度的玻璃看下去。
//      这是最能区分两者的特征，纯 Widget 叠加做不出来（拿不到背景像素）。
//   2. 动态高光 —— 高光带跟着胶囊位置扫过，而不是钉死在某个角落。
//
// ## 坐标系：一切几何以 uRect 为准（第二版，方案 A）
//
// `ImageFilter.shader` 的 uSize 是**背景快照纹理**的尺寸——那是一张约等于
// 整屏的图，不是导航栏的尺寸。第一版把 uv（= fragCoord/uSize，纹理坐标）当
// 几何坐标用：
//   - 折射场按「到纹理边缘的距离」算，导航栏贴着屏幕底部，纵向场整条饱和、
//     横向场几乎全零，实际可见的折射区与栏形无关；
//   - 顶缘亮线钉在 uv.y≈0（纹理顶边），而导航栏在纹理底部——永远不可见；
//   - 高光带位置 Dart 传的是「栏内占比」，着色器却拿去乘纹理宽，落点在栏外。
// 真机（Impeller/Vulkan）上的表现就是一块平平的半透明条，什么效果都没有。
// 作者当时在注释里把这记录为「宁可看不出来，也不要画错」的最坏情况——
// 现在修掉：Dart 侧把 widget 的物理矩形（左上原点，与背景快照同坐标系）
// 通过 uRect 传进来，折射、顶线、高光全部改按矩形计算。
//
// ## 不要用 uSize 推形状（第一版就错在这里）
//
// uRadiusFrac 距离场方案的错误记录见 git 历史：uSize 不是 widget 尺寸，
// 拿它算出的形状与导航栏无关。形状仍然只由外层 ClipRRect 决定。
//
// ## 为什么用逐轴平滑场而不是 SDF 梯度
//
// 圆角矩形 SDF 的内部距离是 `min(max(qx,qy),0)`，x 与 y 的主导权在对角线上
// 切换，梯度方向因此在对角线两侧突变 —— 折射方向跟着翻，画面上出现楔形接缝。
// 逐轴的 inward() 是两个独立的一维平滑函数，天然没有接缝。
//
// ## uniform 顺序不能动
//
// 前两个 float 必须是 vec2，引擎会把纹理尺寸写进去；第一个 sampler2D 也由
// 引擎绑定成背景输入。中间的标量与 uRect 从下标 2 开始依次排布，Dart 侧
// setFloat 的下标与这里的声明顺序一一对应（test/liquid_glass_test.dart 对账）。
//
// ## Impeller 限制
//
// ImageFilter.shader 只在 Impeller 后端可用，Skia 后端会抛 UnsupportedError。
// 调用方必须先查 ui.ImageFilter.isShaderFilterSupported 并准备降级路径。
// OpenGLES 后端的 y 轴是反的，几何统一到左上原点空间、采样走 toUv() 翻转。

#include <flutter/runtime_effect.glsl>

// 引擎写入：绑定纹理尺寸（必须是第一个 uniform，且是 vec2）
uniform vec2 uSize;

// 折射强度（uv 单位）。0.01 已经能看出边缘被拉弯。
uniform float uRefract;

// 折射影响的边缘宽度（栏高的占比，0..0.5）
uniform float uEdge;

// 高光中心的横向位置（栏内占比，0..1）
uniform float uHighlightX;

// 高光强度
uniform float uSpecular;

// 玻璃本体的着色浓度，0 = 完全透明只有折射
uniform float uTint;

// 1 = 深色主题
uniform float uIsDark;

// 导航栏在背景纹理里的物理矩形 (left, top, right, bottom)。
// Dart 侧用 RenderBox.localToGlobal × devicePixelRatio 计算，
// 与引擎写入 uSize 的纹理同一坐标系（左上原点）。
uniform vec4 uRect;

// 引擎绑定：背景输入（必须存在，且不能由 Dart 侧 setImageSampler 覆盖）
uniform sampler2D uTex;

out vec4 fragColor;

/// uv → 采样坐标，按后端修正 y 轴方向。
vec2 toUv(vec2 uv) {
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return clamp(uv, vec2(0.0), vec2(1.0));
}

/// 一维「向内」方向场（像素域）：靠近矩形左/上边缘为 +1，右/下边缘为 -1，
/// 中间为 0。两端各一次 smoothstep，连续可导 —— 这是不出接缝的关键。
float inward(float pPx, float lo, float hi, float edgePx) {
  float w = max(edgePx, 1e-4);
  float nearLo = 1.0 - smoothstep(0.0, w, pPx - lo);
  float nearHi = 1.0 - smoothstep(0.0, w, hi - pPx);
  return nearLo - nearHi;
}

/// 贴边程度 0~1：dir 模长的八次方，色散雾度和亮环共用同一把尺。
/// 八次方让亮环保留但收窄成一条细线 —— 六次方时整圈 17px 都是白晕，
/// 在亮背景上读作白色描边（真机暖金色页面实测）。
float rimMask(vec2 dir) {
  return pow(clamp(length(dir), 0.0, 1.0), 8.0);
}

void main() {
  vec2 fragPx = FlutterFragCoord().xy;
  // 统一到左上原点的纹理像素空间（与 uRect 同系）；OpenGLES 的
  // FragCoord y 朝上，先翻过来。采样仍用纹理 uv 走 toUv。
  vec2 suvPx = fragPx;
#ifdef IMPELLER_TARGET_OPENGLES
  suvPx.y = uSize.y - fragPx.y;
#endif
  vec2 uv = fragPx / uSize;

  // ── 导航栏矩形内的局部坐标（0..1 相对玻璃本身）
  float rw = max(uRect.z - uRect.x, 1e-4);
  float rh = max(uRect.w - uRect.y, 1e-4);
  vec2 local = (suvPx - uRect.xy) / vec2(rw, rh);

  // 边缘带宽：栏高的 uEdge 占比换算成像素，横竖两轴同一厚度。
  float edgePx = uEdge * rh;

  // 折射：逐轴向内偏移，越靠边偏得越多。
  // 三次方让弯曲集中在很窄的一圈，中间大片区域保持不失真。
  vec2 dir = vec2(
      inward(suvPx.x, uRect.x, uRect.z, edgePx),
      inward(suvPx.y, uRect.y, uRect.w, edgePx));
  vec2 bend = sign(dir) * pow(abs(dir), vec2(3.0)) * uRefract;

  // 内部微透镜：中心向外的小幅均匀偏移（最大 ~1.5px）。
  // 没有它，玻璃只有边缘弯、中间只是糊 —— 内容滑进栏内从「被折射」
  // 变成「被糊掉」，不像一整块玻璃（用户实测反馈）。加了它，内部
  // 带着轻微视差与边缘折射连续过渡，文字依然可读。
  vec2 mid = (local - vec2(0.5)) * 2.0;
  bend += mid * (uRefract * 0.12);

  // ── 色散：真实玻璃边缘把白光拆成彩虹，这是「液体玻璃」观感的灵魂细节。
  // RGB 三通道用略不同的折射强度采样（红弯得最少、蓝最多），中带区域
  // 三通道几乎重合、不影响清晰度，只有边缘露出细彩虹边。
  vec3 spread = vec3(0.93, 1.0, 1.07);
  vec4 bgG = texture(uTex, toUv(uv - bend * spread.g));
  vec3 bg3 = vec3(
    texture(uTex, toUv(uv - bend * spread.r)).r,
    bgG.g,
    texture(uTex, toUv(uv - bend * spread.b)).b
  );

  // ── 雾度：折射环内 4-tap 微模糊，让玻璃「厚」而不是「透」。
  vec2 px = vec2(uEdge * 0.06);
  vec3 fog = (
    texture(uTex, toUv(uv - bend + vec2(px.x, 0.0))).rgb +
    texture(uTex, toUv(uv - bend - vec2(px.x, 0.0))).rgb +
    texture(uTex, toUv(uv - bend + vec2(0.0, px.y))).rgb +
    texture(uTex, toUv(uv - bend - vec2(0.0, px.y))).rgb
  ) * 0.25;
  vec3 sampled = mix(bg3, fog, rimMask(dir) * 0.35);

  vec3 tintColor = mix(vec3(1.0), vec3(0.06), clamp(uIsDark, 0.0, 1.0));
  vec3 col = mix(sampled, tintColor, clamp(uTint, 0.0, 1.0));

  // 边缘亮环：模拟玻璃厚度处的全反射亮边。用 dir 的模长当"贴边程度"，
  // 与折射同源，所以亮边总是出现在被拉弯的那一圈上。
  // 系数 0.22：亮环只是玻璃厚度的一记提示 —— 0.5 时整圈 27% 白，
  // 亮背景上就是一圈白色描边（用户指出的「边缘白色」）。
  float rim = rimMask(dir);
  col += rim * uSpecular * 0.22;

  // ── 顶缘高光线：galaxy 玻璃卡片的公共特征——顶边一条 1px 亮线，
  // 人眼靠它识别玻璃厚度。只在矩形最顶 4.5% 高度内、避开首行像素防全宽糊边。
  float topLine = smoothstep(0.045, 0.012, local.y) * smoothstep(0.0, 0.004, local.y);
  col += topLine * uSpecular * 0.55;

  // 移动高光带：以 uHighlightX（栏内占比）换算回矩形像素坐标
  float hx = uRect.x + clamp(uHighlightX, 0.0, 1.0) * rw;
  float dx = (suvPx.x - hx) / (0.16 * rw);
  float band = exp(-dx * dx);
  float topFade = smoothstep(0.75, 0.0, local.y);
  col += band * topFade * uSpecular * 0.28;

  fragColor = vec4(col, bgG.a);
}
