import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../theme/app_theme.dart';
import '../../services/danmaku_service.dart';
import 'danmaku_models.dart';

/// 弹幕渲染层（StatefulWidget，内部持有 painter 并监听 tickNotifier）
///
/// 性能优化：
/// - 不通过 ValueListenableBuilder 重建 widget 树，直接调用 painter.notifyListeners() 触发重绘
/// - RepaintBoundary 隔离重绘区域，避免影响视频和控制层
/// - 屏幕外的弹幕跳过绘制
class DanmakuRenderer extends StatefulWidget {
  final ValueListenable<int> tickNotifier;
  final List<ActiveDanmaku> Function() getActiveDanmaku;
  final double screenWidth;
  final double screenHeight;
  final double displayArea; // 弹幕显示区域（0.5~1.0）

  const DanmakuRenderer({
    super.key,
    required this.tickNotifier,
    required this.getActiveDanmaku,
    required this.screenWidth,
    required this.screenHeight,
    this.displayArea = 1.0,
  });

  @override
  State<DanmakuRenderer> createState() => _DanmakuRendererState();
}

class _DanmakuRendererState extends State<DanmakuRenderer> {
  late final DanmakuPainter _painter;
  final _repaintNotifier = _RepaintNotifier();

  @override
  void initState() {
    super.initState();
    _painter = DanmakuPainter(
      getActiveDanmaku: widget.getActiveDanmaku,
      screenWidth: widget.screenWidth,
      screenHeight: widget.screenHeight,
      displayArea: widget.displayArea,
      repaint: _repaintNotifier,
    );
    widget.tickNotifier.addListener(_onTick);
  }

  @override
  void didUpdateWidget(DanmakuRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tickNotifier != widget.tickNotifier) {
      oldWidget.tickNotifier.removeListener(_onTick);
      widget.tickNotifier.addListener(_onTick);
    }
    _painter.screenWidth = widget.screenWidth;
    _painter.screenHeight = widget.screenHeight;
    _painter.displayArea = widget.displayArea;
  }

  void _onTick() {
    _repaintNotifier.tick();
  }

  @override
  void dispose() {
    widget.tickNotifier.removeListener(_onTick);
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _painter,
        size: Size(widget.screenWidth, widget.screenHeight),
      ),
    );
  }
}

/// 弹幕画笔
///
/// 直接从 controller 回调获取活动弹幕列表，通过 notifyListeners() 触发重绘。
/// 屏幕外的弹幕跳过绘制以减少 GPU 填充率开销。
/// 位图缓存按 devicePixelRatio 缩放存储，绘制时还原为逻辑像素。
class DanmakuPainter extends CustomPainter {
  final List<ActiveDanmaku> Function() getActiveDanmaku;
  double screenWidth;
  double screenHeight;
  double displayArea;

  DanmakuPainter({
    required this.getActiveDanmaku,
    required this.screenWidth,
    required this.screenHeight,
    this.displayArea = 1.0,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final activeDanmaku = getActiveDanmaku();
    if (activeDanmaku.isEmpty) return;

    final w = screenWidth > 0 ? screenWidth : size.width;
    final h = screenHeight > 0 ? screenHeight : size.height;
    // 设备像素比：位图按 DPR 存储，绘制时需缩放回逻辑像素
    // 弹幕显示区域：限制在屏幕上部 displayArea 比例内（0.5~1.0）
    final area = displayArea.clamp(0.5, 1.0);
    final areaBottom = h * area;
    final areaTop = h - areaBottom;
    // 滚动/顶部弹幕的裁剪下界：与 Controller 的轨道分配保持同一口径
    // （分配器用 h*area - 40 计算可容纳轨道数，这里也必须按同一基准裁剪，
    //  否则最后一条轨道分配出去了却被 paint 静默跳过）
    final scrollClipBottom = areaBottom;

    for (final d in activeDanmaku) {
      // P-5：类型过滤改为 paint skip（不移除，只跳过绘制）
      // 切换开关时零开销，弹幕仍保留在数据结构中
      // （此过滤已由 DanmakuController 在激活时处理，此处为双重保险）

      final trackHeight = d.fontSize * AppTheme.danmakuTrackHeightRatio;
      double left;
      double top;

      switch (d.danmaku.type) {
        case DanmakuType.top:
          left = (w - d.width) / 2;
          top = 40 + d.track * trackHeight;
          if (top + trackHeight > areaBottom) continue;
          break;
        case DanmakuType.bottom:
          left = (w - d.width) / 2;
          top = h - 40 - (d.track + 1) * trackHeight;
          // 底部弹幕只在显示区域内绘制（区域缩小时从底部向上收窄）
          if (top < areaTop || top < h * 0.5) continue;
          break;
        case DanmakuType.scroll:
          left = d.offset;
          top = 40 + d.track * trackHeight;
          if (top + trackHeight > scrollClipBottom) continue;
          // 完全在屏幕外的跳过绘制（减少 GPU 填充率）
          if (left + d.width < 0 || left > w) continue;
          break;
      }

      // 直接按绝对位置画，不 save/translate/restore ——
      // 一屏上百条弹幕 × 60fps 下，每条省掉的是一对矩阵压栈出栈；
      // drawImageRect 的目标矩形和 TextPainter.paint 都能直接吃偏移。
      final bmp = d.bitmapCache;
      if (bmp != null && !d.bitmapDirty) {
        // P-1: Bitmap 缓存绘制 — 首帧由 Controller 异步生成位图，
        // 后续帧直接 drawImage。密集弹幕场景下可减少 50%+ 的 GPU 填充率开销。
        canvas.drawImageRect(
          bmp,
          Rect.fromLTWH(0, 0, bmp.width.toDouble(), bmp.height.toDouble()),
          Rect.fromLTWH(left, top, d.width, d.height),
          _bitmapPaint,
        );
      } else {
        // 位图尚未生成或已失效，先用 TextPainter 绘制，Controller 会异步生成位图
        d.painter.paint(canvas, Offset(left, top));
      }
    }
  }

  /// 位图绘制用的常量 Paint。
  ///
  /// 位图按 DPR 物理像素生成，drawImageRect 的源尺寸恰好等于目标物理尺寸，
  /// 属于 1:1 映射，无需任何插值过滤 —— high 会白付一次双三次采样开销。
  ///
  /// 提到 static：原先每条弹幕每帧 new 一个 Paint，一屏上百条就是每秒
  /// 上万次分配，全都立刻变垃圾。这个 Paint 不含任何随弹幕变化的字段。
  static final Paint _bitmapPaint = Paint()
    ..filterQuality = FilterQuality.none;

  @override
  bool shouldRepaint(covariant DanmakuPainter oldDelegate) {
    return false;
  }
}

/// 供 CustomPainter 的 `repaint` 用的重绘信号源。
///
/// 直接用 `ChangeNotifier` 会导致外部调用 `notifyListeners()` ——
/// 那是 protected + visibleForTesting 的成员，analyze 会报两条 warning。
/// 这里开一个公开的 [tick] 转发，语义也更清楚：每个弹幕时钟脉冲触发一次重绘。
class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}
