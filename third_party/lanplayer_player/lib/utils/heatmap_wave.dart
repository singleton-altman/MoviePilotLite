import 'dart:ui';

/// 弹幕热力图波浪路径的构建结果。
class HeatmapWavePaths {
  const HeatmapWavePaths({required this.fill, required this.crest});

  /// 基线到波峰之间的填充区（闭合）。
  final Path fill;

  /// 波峰轮廓线（未闭合，沿波面，两端贴基线）。
  final Path crest;
}

/// 把归一化密度数组 [density]（0~1，按桶）构建成平滑波浪路径。
///
/// 坐标系：x 铺满 [width]，每个桶中心一个采样点，y 从 [baselineY] 向上
/// 顶起 `density × [amplitude]`。首尾各补一个贴地点，让波浪从进度条
/// 两端起落。
///
/// 平滑算法：二次贝塞尔过中点 —— 以第 i 个点为控制点、相邻两点中点为
/// 端点连 quadraticBezierTo。无过冲、O(n)，且「全 1 输入」严格等于振幅
/// 线、「全 0 输入」严格等于基线，可直接测。
///
/// [baselineY] 必须由调用方固定（建议：进度条膨胀后的上沿再留 1px），
/// 这样轨道 3px↔8px 的膨胀动画不会引起路径重建 —— 路径缓存才能生效。
///
/// [density] 长度 <2、[width] <= 0 或 [amplitude] <= 0 时返回 null。
HeatmapWavePaths? buildHeatmapWavePaths({
  required List<double> density,
  required double width,
  required double baselineY,
  required double amplitude,
}) {
  if (density.length < 2 || width <= 0 || amplitude <= 0) return null;
  final n = density.length;
  Offset pointOf(int i) {
    final x = (i + 0.5) / n * width;
    final d = density[i].clamp(0.0, 1.0);
    return Offset(x, baselineY - d * amplitude);
  }

  final pts = List<Offset>.generate(n, pointOf);

  final crest = Path()..moveTo(0, baselineY);
  crest.lineTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < n - 1; i++) {
    final mid = Offset(
      (pts[i].dx + pts[i + 1].dx) / 2,
      (pts[i].dy + pts[i + 1].dy) / 2,
    );
    crest.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
  }
  crest.lineTo(pts.last.dx, pts.last.dy);
  crest.lineTo(width, baselineY);

  final fill = Path.from(crest)
    ..lineTo(0, baselineY)
    ..close();
  return HeatmapWavePaths(fill: fill, crest: crest);
}
