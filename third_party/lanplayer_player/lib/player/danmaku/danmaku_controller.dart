import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import '../../services/danmaku_service.dart';
import '../../theme/app_theme.dart';
import 'danmaku_models.dart';
import 'lru_byte_pool.dart';

import '../../utils/app_log.dart';
/// 弹幕控制器
///
/// 类似 AkDanmaku 的 DanmakuPlayer，负责弹幕的激活、轨道分配、滚动位移、
/// 过期回收等核心逻辑，与 UI 解耦。PlayerScreen 只需在合适时机调用
/// init / setData / start / pause / seekTo / updateActive / updateConfig 等接口。
///
/// 通过 [TickerProvider]（通常是 TickerProviderStateMixin）驱动逐帧更新，
/// 内部维护对象池与扫描游标以降低分配开销。
class DanmakuController {
  /// [lowFrameRateMode] 低帧率模式：每 2 个 vsync 才通知一次重绘（内部
  /// 位移照每帧推进，只是渲染降半）。弱核 TV（真机 gfxinfo 2026-09-06：
  /// 掉帧 44.94%，瓶颈在 CPU 栅格而非 GPU）开启后成本直接减半；
  /// 手机传 false 保持 60fps。
  DanmakuController(this._tickerProvider, {this.lowFrameRateMode = false});

  final TickerProvider _tickerProvider;
  final bool lowFrameRateMode;

  /// 重绘节流决策（静态纯函数，便于测试）：
  /// - 静止且无回收：不重绘（降功耗逻辑保留）
  /// - 普通模式：有移动/回收就每帧重绘
  /// - 低帧率模式：只在偶数帧重绘（30fps）
  static bool shouldRepaintThisFrame({
    required bool lowFrameRateMode,
    required int tickCount,
    required bool hasMoving,
    required bool removedAny,
  }) {
    if (!hasMoving && !removedAny) return false;
    if (!lowFrameRateMode) return true;
    return tickCount.isEven;
  }

  // ===== 弹幕数据与活动状态 =====
  List<Danmaku> _danmakuList = [];
  final List<ActiveDanmaku> _activeDanmaku = [];
  final List<ActiveDanmaku> _danmakuPool = []; // 对象池
  final Map<String, ActiveDanmaku> _trackLastDanmaku = {}; // 每条轨道末尾弹幕（key: "type_trackIdx"）
  final Set<String> _activeDanmakuIds = {}; // 已激活弹幕 ID 集合，O(1) 查找
  // DanmakuFlameMaster 式文本缓存：相同 text+字号+粗体+颜色 共享已 layout 的
  // TextPainter（layout 是最大开销，密集弹幕时避免对重复文本反复测量）
  // 使用 LinkedHashMap 按访问顺序实现 LRU 淘汰，替代全清（避免瞬间卡顿）
  final LinkedHashMap<String, TextPainter> _textCache = LinkedHashMap();
  static const int _textCacheMax = 300;
  // ── 位图常驻池（性能关键，2026-09-06 TV 真机实证）──
  // 位图是原生内存（dpr2 下每张约 80KB）：旧实现每条激活都新生成一张,
  // 密集段 NativeAlloc GC 高峰 2 次/秒、掉帧 44.94%。弹幕同文本极多,
  // 按「文本+样式」key 常驻复用后命中零分配。上限 24MB（约 300 张）。
  late final LruBytePool<ui.Image> _bitmapPool = LruBytePool<ui.Image>(
    maxBytes: 24 << 20,
    sizeOf: (img) => img.width * img.height * 4,
    onEvict: _onPoolEvict,
  );
  // 位图引用计数：活动弹幕「借用」池里的位图；池逐出时若仍被借用,
  // 挂到待释放列表,等最后一个借用者断开时再真正 dispose（防 use-after-dispose）
  final Map<ui.Image, int> _bitmapBorrows = {};
  final List<ui.Image> _bitmapPendingDispose = [];
  // 位图生成串行闸：每帧最多 1 张 toImage,其余排队（削密集入场分配尖峰;
  // 等待期间渲染层用 TextPainter 兜底,肉眼无感）
  final List<ActiveDanmaku> _bitmapGenPending = [];
  bool _bitmapGenDrainScheduled = false;
  bool _disposed = false;
  // 活动弹幕文本计数（mergeDuplicates 用 O(1) 判重）
  // 用「计数」而非 Set：同文本可能同时有多条在屏，Set 移除一条后判重就失效了
  final Map<String, int> _activeTexts = {};
  // 批量删除待处理集合（避免在遍历中 removeAt 导致索引偏移）
  final Set<int> _pendingRemoval = {};
  // 屏上滚动弹幕计数（增删时 ±1，避免每次移除都 O(n) 全表重扫）
  int _scrollActiveCount = 0;
  // 轨道轮转游标：下次分配从这条轨道开始找。
  // 不做轮转的话，稀疏场景下 track 0 永远空闲 → 所有弹幕垂直位置完全一致。
  int _nextScrollTrack = 0;
  int _nextTopTrack = 0;
  int _nextBottomTrack = 0;
  // 是否存在移动中的滚动弹幕（全是顶部/底部静态弹幕时跳过逐帧重绘，降功耗）
  bool get _hasMovingDanmaku => _scrollActiveCount > 0;

  // ── 时钟校正软着陆 / 入场错峰 / 轨道满重试（真机日志 2026-08-29 实证）──
  // 上次时钟校正的时间戳（ms 时间钟）：300ms 内的连续校正合并，防拖动时
  // 引擎连推两个位置导致连续两次全清屏。
  int _lastCorrectionAt = 0;
  // 漂移不超过此值走「平移在屏弹幕」的软校正，超过才清屏重扫
  static const int _softCorrectionMaxDrift = 1500;
  // 轨道满被搁置、等待下轮重试的滚动弹幕（宁可排队也不丢弃）
  final List<Danmaku> _retryQueue = [];
  static const int _retryQueueMax = 200;
  // 过滤原因计数（合并重复/屏蔽词/最短长度/类型开关），供日志诊断
  // 「加载 5196 条但激活稀」到底是内容稀还是被过滤
  final Map<String, int> _filterSkipCounts = {};

  // ── 弹幕热力图：弹幕密度分桶缓存（Hills/DanmakuFlameMaster 山峰风格）──
  // setData 时一次性预计算：分桶 → 高斯平滑 → 幂函数增强 → 归一化
  // 渲染时 O(1) 查桶，绝不逐帧重算
  static const int _heatmapBucketMs = 5000; // 每桶 5 秒（更细粒度，山峰更明显）
  List<double> _heatmapDensity = const [];
  int _danmakuScanIndex = 0; // _danmakuList 扫描游标（前提：列表按 time 升序）

  int _frameCount = 0;
  int _tickCount = 0;
  int _timeoutDroppedCount = 0;  // 超时丢弃计数
  int _totalActivatedCount = 0;  // 总激活计数
  // ===== 渲染配置 =====
  DanmakuRenderConfig _config = DanmakuRenderConfig.defaults();
  double _screenWidth = 0;
  double _screenHeight = 0;
  Ticker? _ticker;
  final ValueNotifier<int> _tickNotifier = ValueNotifier<int>(0);

  // ===== 运行时状态 =====
  int _lastDanmakuUpdateMs = 0;
  int _currentMs = 0;
  int _lastElapsedMs = 0;  // Ticker 上次 elapsed（ms），用于计算实际帧间隔
  int _clockScanAccumMs = 0;  // 时钟自推进后累计的扫描间隔（ms），约每 300ms 扫描一次
  bool _isPlaying = false;
  bool _isSeeking = false;
  bool _enabled = true;
  // 样式变化检测（避免每帧重建 TextPainter）
  double _lastAppliedFontSizeScale = 1.0;
  double _lastAppliedOpacity = 1.0;
  bool _lastAppliedBold = false;
  // 样式批量更新：将重建分摊到多帧，避免拖拽滑块时一次性重建所有弹幕导致卡顿
  bool _styleUpdatePending = false;
  int _styleUpdateBatchIndex = 0;
  // 设备像素比（位图缓存生成用，确保高DPI屏幕字体清晰不发虚）
  double _devicePixelRatio = 1.0;
  // 位图就绪重绘通知合并标记（同一帧内多张位图完成只通知一次）
  bool _bitmapRepaintScheduled = false;

  // ===== 对外暴露的接口 =====

  /// 帧通知，UI 通过 ValueListenableBuilder 监听后重建 DanmakuRenderer
  ValueListenable<int> get tickNotifier => _tickNotifier;

  /// 当前活动弹幕列表（只读视图）
  List<ActiveDanmaku> get activeDanmaku => _activeDanmaku;

  /// 是否有活动弹幕（UI 据此决定是否渲染弹幕层）
  bool get hasActiveDanmaku => _activeDanmaku.isNotEmpty;

  /// 点击命中检测：返回点击位置（逻辑坐标）处可见的最近一条弹幕
  /// 位置公式与 DanmakuPainter 保持一致，避免「点得到处不是这条」的偏差
  ActiveDanmaku? hitTest(double x, double y) {
    final w = _screenWidth;
    final h = _screenHeight;
    if (w <= 0 || h <= 0) return null;
    final area = _config.displayArea.clamp(0.5, 1.0);
    final areaBottom = h * area;
    final areaTop = h - areaBottom;
    // 从后往前：越晚发送的弹幕越靠上层
    for (final d in _activeDanmaku.reversed) {
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
          if (top < areaTop || top < h * 0.5) continue;
          break;
        case DanmakuType.scroll:
          left = d.offset;
          top = 40 + d.track * trackHeight;
          if (top + trackHeight > areaBottom) continue;
          break;
      }
      if (y >= top && y < top + trackHeight && x >= left && x < left + d.width) {
        return d;
      }
    }
    return null;
  }

  /// 统计：当前活动弹幕数
  int get activeCount => _activeDanmaku.length;

  /// 统计：超时丢弃计数
  int get timeoutDroppedCount => _timeoutDroppedCount;

  /// 统计：总激活计数
  int get totalActivatedCount => _totalActivatedCount;

  /// 初始化（设置屏幕尺寸、配置，并创建 Ticker）
  void init({
    required double screenWidth,
    required double screenHeight,
    required DanmakuRenderConfig config,
  }) {
    _screenWidth = screenWidth;
    _screenHeight = screenHeight;
    _config = config;
    _lastAppliedFontSizeScale = config.fontSize / AppTheme.danmakuDefaultFontSize;
    _lastAppliedOpacity = config.opacity;
    _lastAppliedBold = config.bold;
    // 提前创建 Ticker，start() 时直接启动
    _ticker ??= _tickerProvider.createTicker((elapsed) {
      if (!_isPlaying || _isSeeking || !_enabled) return;
      final ms = elapsed.inMilliseconds;
      final deltaMs = _lastElapsedMs > 0 ? ms - _lastElapsedMs : 16;
      _lastElapsedMs = ms;
      // 弹幕时钟自推进：持续播放时按帧推进，不依赖外部位置推送（防止时钟冻结、
      // 后续弹幕永不激活）。外部 updateActive 仍是权威同步，会纠正任何漂移。
      _currentMs += (deltaMs * _config.playbackSpeed).round();
      // 周期性扫描激活新弹幕（约每 300ms 时钟；updateActive 内部还有节流兜底）
      _clockScanAccumMs += (deltaMs * _config.playbackSpeed).round();
      if (_clockScanAccumMs >= 300) {
        _clockScanAccumMs = 0;
        updateActive(_currentMs);
      }
      _tickDanmaku(deltaMs);
    });
  }

  /// 设置弹幕数据列表（已按 time 排序）
  void setData(List<Danmaku> danmakuList) {
    _danmakuList = danmakuList;
    if (danmakuList.isNotEmpty) {
      AppLog.i('Danmaku', 'setData: ${danmakuList.length}条, first.time=${danmakuList.first.time}ms, last.time=${danmakuList.last.time}ms');
    }
    clearActive();
    _retryQueue.clear();
    _filterSkipCounts.clear();
    _danmakuScanIndex = 0;
    _lastDanmakuUpdateMs = 0; // 重置节流，setData后立即允许updateActive
    _lastElapsedMs = 0; // 重置帧时间基准
    // 弹幕数据变化 → 重建热力分桶缓存（O(n) 一次，后续只读）
    _buildHeatmap();
  }

  // ===== 弹幕热力图（密度分桶缓存） =====

  /// 热力图密度数组（已归一化 0~1，按桶索引；桶宽 [heatmapBucketWidthMs]）
  List<double> get heatmapDensity => _heatmapDensity;

  /// 热力图桶宽（毫秒）
  int get heatmapBucketWidthMs => _heatmapBucketMs;

  /// O(1) 查询某时刻弹幕密度（0~1），无数据返回 0
  double heatmapDensityAt(int positionMs) {
    if (_heatmapDensity.isEmpty) return 0;
    final idx = positionMs ~/ _heatmapBucketMs;
    if (idx < 0 || idx >= _heatmapDensity.length) return 0;
    return _heatmapDensity[idx];
  }

  /// 预计算热力分桶 + 高斯平滑 + 幂函数增强
  /// 产生 Hills 风格的山峰效果：高峰陡峭、低谷平坦、过渡自然
  void _buildHeatmap() {
    if (_danmakuList.isEmpty) {
      _heatmapDensity = const [];
      return;
    }
    final bucketCount = (_danmakuList.last.time ~/ _heatmapBucketMs) + 1;
    final counts = List<int>.filled(bucketCount, 0);
    var maxCount = 0;
    for (final d in _danmakuList) {
      final idx = d.time ~/ _heatmapBucketMs;
      if (idx >= 0 && idx < bucketCount) {
        counts[idx]++;
        if (counts[idx] > maxCount) maxCount = counts[idx];
      }
    }
    if (maxCount <= 0) {
      _heatmapDensity = const [];
      return;
    }
    // Step 1: 归一化到 0~1
    final raw = List<double>.generate(
      bucketCount,
      (i) => (counts[i] / maxCount).clamp(0.0, 1.0),
    );
    // Step 2: 高斯平滑（σ=2桶，让相邻桶过渡自然，形成山峰弧度）
    final smoothed = _gaussianSmooth(raw, sigma: 2.0);
    // Step 3: 幂函数增强（0.7次方：放大中低密度差异，高峰更突出）
    _heatmapDensity = List<double>.generate(
      bucketCount,
      (i) => _powCurve(smoothed[i], 0.7).clamp(0.0, 1.0),
    );
  }

  /// 高斯平滑：对密度数组做一维高斯卷积，sigma 为标准差（桶数）
  List<double> _gaussianSmooth(List<double> data, {double sigma = 2.0}) {
    if (data.length < 3 || sigma <= 0) return data;
    final radius = (sigma * 2).ceil().clamp(1, data.length ~/ 2);
    final result = List<double>.filled(data.length, 0);
    for (int i = 0; i < data.length; i++) {
      double sum = 0, weightSum = 0;
      for (int j = -radius; j <= radius; j++) {
        final idx = i + j;
        if (idx < 0 || idx >= data.length) continue;
        final w = _gaussianWeight(j, sigma);
        sum += data[idx] * w;
        weightSum += w;
      }
      result[i] = weightSum > 0 ? sum / weightSum : data[i];
    }
    return result;
  }

  /// 高斯权重函数
  double _gaussianWeight(int x, double sigma) {
    return exp(-0.5 * (x * x) / (sigma * sigma));
  }

  /// 幂函数曲线：power < 1 放大低值，power > 1 压缩低值
  double _powCurve(double x, double power) {
    return x <= 0 ? 0 : pow(x.clamp(0.0, 1.0), power).toDouble();
  }

  /// 开始播放（启动 Ticker）
  void start() {
    _isPlaying = true;
    _lastElapsedMs = 0; // 重置帧时间基准
    _ticker ??= _tickerProvider.createTicker((elapsed) {
      if (!_isPlaying || _isSeeking || !_enabled) return;
      final ms = elapsed.inMilliseconds;
      final deltaMs = _lastElapsedMs > 0 ? ms - _lastElapsedMs : 16;
      _lastElapsedMs = ms;
      // 弹幕时钟自推进：持续播放时按帧推进，不依赖外部位置推送（防止时钟冻结、
      // 后续弹幕永不激活）。外部 updateActive 仍是权威同步，会纠正任何漂移。
      _currentMs += (deltaMs * _config.playbackSpeed).round();
      // 周期性扫描激活新弹幕（约每 300ms 时钟；updateActive 内部还有节流兜底）
      _clockScanAccumMs += (deltaMs * _config.playbackSpeed).round();
      if (_clockScanAccumMs >= 300) {
        _clockScanAccumMs = 0;
        updateActive(_currentMs);
      }
      _tickDanmaku(deltaMs);
    });
    // 仅在 ticker 未激活时才启动，避免重复 start 抛出异常
    if (!_ticker!.isActive) {
      _ticker!.start();
    }
  }

  /// 暂停
  void pause() {
    _isPlaying = false;
    _ticker?.stop();
  }

  /// Seek 到指定位置（清理活动弹幕，重置游标）
  void seekTo(Duration position) {
    _currentMs = position.inMilliseconds;
    clearActive();
    _retryQueue.clear(); // 游标已重定位，旧的重试条目位置全部失效
    _lastDanmakuUpdateMs = 0; // 重置节流，确保 seek 后立即允许 updateActive
    _lastElapsedMs = 0; // 重置帧时间基准

    // 二分查找：将游标定位到 position 附近（回看 5 秒范围内）
    // 无论前进还是后退 seek，都能正确定位，避免游标越界导致 active=0
    final targetMs = position.inMilliseconds;
    if (_danmakuList.isNotEmpty) {
      final lookbackMs = (targetMs - 5000).clamp(0, _danmakuList.last.time + 1);
      int lo = 0, hi = _danmakuList.length - 1;
      while (lo < hi) {
        final mid = (lo + hi) ~/ 2;
        if (_danmakuList[mid].time < lookbackMs) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      _danmakuScanIndex = lo;
    } else {
      _danmakuScanIndex = 0;
    }

    _tickNotifier.value++;
  }

  /// 更新配置（字体大小、透明度、速度、显示开关、倍速等）
  void updateConfig(DanmakuRenderConfig config) {
    _config = config;
  }

  /// 更新屏幕尺寸
  void updateScreenSize(double width, double height) {
    final wasZero = _screenWidth == 0 || _screenHeight == 0;
    _screenWidth = width;
    _screenHeight = height;
    // 屏幕尺寸从0变为真实值时，重新分配已有弹幕的轨道（修复初始加载全挤在track 0）
    if (wasZero && width > 0 && height > 0 && _activeDanmaku.isNotEmpty) {
      _reassignTracks();
      _tickNotifier.value++;
    }
  }

  /// 重新分配所有活动弹幕的轨道（屏幕尺寸变化时调用）
  void _reassignTracks() {
    _trackLastDanmaku.clear();
    final fontSizeScale = _config.fontSize / AppTheme.danmakuDefaultFontSize;
    for (final d in _activeDanmaku) {
      final fontSize = (d.danmaku.fontSize?.toDouble() ?? AppTheme.danmakuDefaultFontSize) * fontSizeScale;
      final trackHeight = fontSize * AppTheme.danmakuTrackHeightRatio;
      final trackKey = _allocateTrack(d, trackHeight);
      if (trackKey == null) {
        d.track = 0;
        _trackLastDanmaku['${_trackPrefix(d.danmaku.type)}_0'] = d;
      }
    }
  }

  /// 设置设备像素比（在 init 时由 PlayerScreen 传入）
  void setDevicePixelRatio(double dpr) {
    _devicePixelRatio = dpr;
  }

  /// 发送单条弹幕（用户发送，立即加入活动列表）
  void send(Danmaku danmaku) {
    _addDanmakuToTrack(danmaku);
    _activeDanmakuIds.add(danmaku.id);
    _tickNotifier.value++;
  }

  /// 设置弹幕开关
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (_enabled && _isPlaying) {
      start();
    } else {
      _ticker?.stop();
    }
  }

  /// 设置是否正在拖拽进度条
  ///
  /// 开始拖拽时清理活动弹幕（与原实现一致），拖拽期间 Ticker 回调提前返回。
  void setSeeking(bool seeking) {
    _isSeeking = seeking;
    if (seeking) {
      clearActive();
    }
  }

  /// 更新活动弹幕（根据当前播放位置添加新弹幕到轨道）
  ///
  /// 利用 _danmakuList 已按 time 升序排列的特性，从游标处向后扫描。
  /// 节流 300ms，避免引擎频繁回调时重复扫描。
  void updateActive(int currentMs) {
    // 引擎位置瞬时报 0 的防抖：正常播放中从未 seek 却收到 0（内核内部重开的
    // 偶发抖动），直接忽略——否则会整屏清空重扫，表现就是「弹幕突然消失」。
    if (currentMs <= 0 && _currentMs > 3000 && !_isSeeking) {
      AppLog.w('Danmaku', '忽略可疑位置上报: currentMs=0 (内部时钟=$_currentMs)');
      return;
    }
    final prevMs = _currentMs;
    final drift = (currentMs - prevMs).abs();
    _currentMs = currentMs;
    if (drift > 500) {
      _lastElapsedMs = 0; // 重置帧时间基准，防止下一帧用旧delta跳帧
      final now = DateTime.now().millisecondsSinceEpoch;
      final debounced =
          _lastCorrectionAt != 0 && now - _lastCorrectionAt < 300;
      if (drift > _softCorrectionMaxDrift) {
        // 大跳变（seek/换段）：整屏清空重扫；300ms 内的连续校正合并处理
        if (!debounced) {
          AppLog.i('Danmaku', '时钟校正: drift=${drift}ms, 清屏重扫 currentMs=$currentMs');
          _lastCorrectionAt = now;
          _danmakuScanIndex = 0;
          _retryQueue.clear(); // 清屏后游标归零，重试队列整体重扫即可
          clearActive();
          _lastDanmakuUpdateMs = 0; // 重置节流基准：否则下面的 300ms 节流会直接 return，
                                    // 造成「清空了却没重新激活」的空窗（最长 300ms 无弹幕）
        }
      } else if (!debounced) {
        // 软着陆（小漂移 ≤1.5s）：不清屏——滚动弹幕整体平移、静态弹幕过期
        // 时间随漂移前移/后移，时间轴对上后继续显示。之前每次校正都全清，
        // 拖动/卡顿时表现就是「弹幕断续消失」。
        final deltaMs = currentMs - prevMs; // 可正可负（回退为负）
        final pxPerMs = _screenWidth / (_config.speed * 1000);
        final dx = pxPerMs * deltaMs * _config.playbackSpeed;
        for (final d in _activeDanmaku) {
          if (d.danmaku.type == DanmakuType.scroll) {
            d.offset -= dx;
          } else if (d.expireTimeMs > 0) {
            d.expireTimeMs += deltaMs;
          }
        }
        AppLog.i('Danmaku', '时钟软校正: drift=${drift}ms, 平移${_activeDanmaku.length}条在屏弹幕');
        _lastCorrectionAt = now;
      }
    }
    if (_screenWidth == 0) { AppLog.w('Danmaku', 'updateActive: screenWidth=0, skip'); return; }
    if (_lastDanmakuUpdateMs > 0 && (currentMs - _lastDanmakuUpdateMs).abs() < 300) return;
    _lastDanmakuUpdateMs = currentMs;
    // 诊断日志：每 30 次打印一次
    if (_frameCount % 30 == 0) {
      AppLog.d('Danmaku', 'updateActive: ms=$currentMs, scanIdx=$_danmakuScanIndex/${_danmakuList.length}, active=${_activeDanmaku.length}, enabled=$_enabled, isPlaying=$_isPlaying, isSeeking=$_isSeeking');
    }
    _frameCount++;

    final display = _config;
    final syncOffsetMs = (display.syncDelay * 1000).round();

    // 滚动弹幕可见窗口（毫秒）：从右侧进入 → 完全离开左侧的时长。
    // pxPerMs = 屏宽/(speed×1000)，穿越 (屏宽+平均弹幕宽120px) 需要
    // (屏宽+120)/pxPerMs 毫秒 ≈ speed 秒多一点。
    //
    // ⚠️ 原式是 (屏宽+120)/(speed×1000)×1000，把 speed 当成了 px/ms——
    // 2400px 屏、速度 12 时算出 **210ms**，而真实穿越要 12 秒。扫描间隔
    // 0.3~1s，几乎每条弹幕被扫到时都已「超过 210ms 可见期」→ 按过期静默
    // 跳过。真机日志实证：45s 内游标推进 250 条、实际激活 58 条，77% 被
    // 此路径吞掉——这才是「屏上弹幕稀少」的根源，与轨道数/上限无关。
    final pxPerMs = _screenWidth / (display.speed * 1000);
    final scrollVisibleMs =
        pxPerMs > 0 ? ((_screenWidth + 120) / pxPerMs).round() : 12000;

    // 快进/快退优化：如果游标距当前位置很远，快进游标跳过已过期的弹幕
    if (_danmakuScanIndex < _danmakuList.length) {
      final gapMs = currentMs - _danmakuList[_danmakuScanIndex].time;
      if (gapMs > 10000) {
        // 快进游标：跳过所有已完全过期的弹幕
        while (_danmakuScanIndex < _danmakuList.length) {
          final d = _danmakuList[_danmakuScanIndex];
          final adjustedTime = d.time + syncOffsetMs;
          // 滚动弹幕：时间 + 可见窗口 < 当前时间 → 已过期
          // 顶部/底部弹幕：时间 + 5000 < 当前时间 → 已过期
          final expireMs = (d.type == DanmakuType.scroll)
              ? adjustedTime + scrollVisibleMs
              : adjustedTime + 5000;
          if (expireMs < currentMs) {
            _danmakuScanIndex++;
          } else {
            break;
          }
        }
        AppLog.d('Danmaku', 'seek fast-forward: scanIdx=$_danmakuScanIndex/${_danmakuList.length}');
      }
    }

    // 轨道满重试队列：上一轮被搁置的滚动弹幕，只要还在可见窗口内就再试——
    // 宁可晚点入场也不丢（之前是直接丢弃，高峰段因此出现空洞）。
    int activatedThisPass = 0;
    if (_retryQueue.isNotEmpty) {
      // 削峰:每轮最多重试 30 条,未轮到的原地保留(下轮从它们开始)——
      // 密集段 200 条全量重试=每 300ms 几百次轨道尝试白烧 CPU
      const maxRetryPerPass = 30;
      final still = <Danmaku>[];
      var tried = 0;
      for (final d in _retryQueue) {
        if (tried >= maxRetryPerPass) {
          still.add(d);
          continue;
        }
        tried++;
        final expired =
            currentMs > d.time + syncOffsetMs + scrollVisibleMs;
        if (expired) {
          _timeoutDroppedCount++;
          continue;
        }
        if (_addDanmakuToTrack(d, queueIndex: activatedThisPass)) {
          _activeDanmakuIds.add(d.id);
          activatedThisPass++;
        } else {
          still.add(d);
        }
      }
      _retryQueue
        ..clear()
        ..addAll(still);
    }

    int activated = 0;
    while (_danmakuScanIndex < _danmakuList.length) {
      final danmaku = _danmakuList[_danmakuScanIndex];
      if (danmaku.time > currentMs + syncOffsetMs) break; // 后面的都还没到时间（含同步偏移）

      // 已激活则跳过
      if (_activeDanmakuIds.contains(danmaku.id)) {
        _danmakuScanIndex++;
        continue;
      }

      // 合并重复弹幕：O(1) 集合判重（DanmakuFlameMaster 同款，避免逐条 any 扫描）
      if (display.mergeDuplicates && _activeTexts.containsKey(danmaku.text)) {
        _filterSkipCounts['合并重复'] = (_filterSkipCounts['合并重复'] ?? 0) + 1;
        _danmakuScanIndex++;
        continue;
      }

      // 屏蔽词过滤：支持普通文本和正则（/regex/ 格式，Hills 同款）
      if (display.blockedWords.isNotEmpty && _isBlocked(danmaku.text, display.blockedWords)) {
        _filterSkipCounts['屏蔽词'] = (_filterSkipCounts['屏蔽词'] ?? 0) + 1;
        _danmakuScanIndex++;
        continue;
      }

      // 最短长度过滤
      if (display.minimumLength > 0 && danmaku.text.length < display.minimumLength) {
        _filterSkipCounts['最短长度'] = (_filterSkipCounts['最短长度'] ?? 0) + 1;
        _danmakuScanIndex++;
        continue;
      }

      // 根据显示设置过滤弹幕类型
      if (danmaku.type == DanmakuType.top && !display.showTop) {
        _filterSkipCounts['顶部关闭'] = (_filterSkipCounts['顶部关闭'] ?? 0) + 1;
        _danmakuScanIndex++;
        continue;
      }
      if (danmaku.type == DanmakuType.bottom && !display.showBottom) {
        _filterSkipCounts['底部关闭'] = (_filterSkipCounts['底部关闭'] ?? 0) + 1;
        _danmakuScanIndex++;
        continue;
      }
      if (danmaku.type == DanmakuType.scroll && !display.showScroll) {
        _filterSkipCounts['滚动关闭'] = (_filterSkipCounts['滚动关闭'] ?? 0) + 1;
        _danmakuScanIndex++;
        continue;
      }

      // 顶部/底部弹幕：如果已超过其5秒显示窗口，跳过（避免激活即过期）
      if ((danmaku.type == DanmakuType.top || danmaku.type == DanmakuType.bottom)
          && currentMs > danmaku.time + syncOffsetMs + 5000) {
        _danmakuScanIndex++;
        continue;
      }

      // 滚动弹幕：如果已超过其可见窗口，跳过（避免 seek 后大量过期弹幕涌入）
      if (danmaku.type == DanmakuType.scroll
          && currentMs > danmaku.time + syncOffsetMs + scrollVisibleMs) {
        _danmakuScanIndex++;
        continue;
      }

      // 性能限制：活动弹幕数超过上限时停止激活（滚动弹幕）
      final maxScreen = _config.maxScreen > 0 ? _config.maxScreen : AppTheme.danmakuMaxActive;
      if (danmaku.type == DanmakuType.scroll && _activeDanmaku.length >= maxScreen) {
        break;
      }

      if (_addDanmakuToTrack(danmaku, queueIndex: activatedThisPass)) {
        _activeDanmakuIds.add(danmaku.id);
        activated++;
        activatedThisPass++;
      } else if (danmaku.type == DanmakuType.scroll &&
          _retryQueue.length < _retryQueueMax) {
        // 轨道满：滚动弹幕进入重试队列（顶部/底部弹幕生命周期短，仍直接丢弃）
        _retryQueue.add(danmaku);
      } else {
        _timeoutDroppedCount++;
      }
      _danmakuScanIndex++;
    }
    // 过滤统计：诊断「加载 N 条但屏上稀」——差距是被过滤还是内容本身稀，
    // 一看便知（约每 36s 一条 INFO）
    if (_filterSkipCounts.isNotEmpty && _frameCount % 120 == 0) {
      final s = _filterSkipCounts.entries
          .map((e) => '${e.key}:${e.value}')
          .join(', ');
      AppLog.i('Danmaku', '过滤统计(累计): $s, 重试队列=${_retryQueue.length}');
    }
    if (activated > 0) {
      AppLog.i('Danmaku', 'updateActive: 激活$activated条, currentMs=$currentMs, scanIdx=$_danmakuScanIndex/${_danmakuList.length}');
      // 激活了新弹幕时立即通知 UI 重建，不依赖 _tickDanmaku 的帧回调
      _tickNotifier.value++;
    }
  }

  /// 清理活动弹幕（保留对象池）
  void clearActive() {
    // 断开位图引用(位图所有权在常驻池,不能在这里 dispose)
    for (final d in _activeDanmaku) {
      _detachBitmap(d);
    }
    _activeDanmaku.clear();
    _trackLastDanmaku.clear();
    _activeDanmakuIds.clear();
    _activeTexts.clear();
    _scrollActiveCount = 0;
    // 轨道轮转游标复位，避免下次分配从一条不存在的轨道开始
    _nextScrollTrack = 0;
    _nextTopTrack = 0;
    _nextBottomTrack = 0;
  }

  /// 内部：Ticker 回调驱动的逐帧更新（移动、过期回收、样式同步）
  void _tickDanmaku(int deltaMs) {
    if (_screenWidth == 0 || _screenHeight == 0) {
      AppLog.w('Danmaku', '_tickDanmaku: screen=0x0, skip');
      return;
    }
    // 诊断日志：每 120 帧打印一次
    _tickCount++;
    if (_tickCount % 120 == 0) {
      AppLog.d('Danmaku', '_tickDanmaku: active=${_activeDanmaku.length}, currentMs=$_currentMs, scanIdx=$_danmakuScanIndex/${_danmakuList.length}, enabled=$_enabled, isPlaying=$_isPlaying, isSeeking=$_isSeeking');
    }
    final display = _config;
    final fontSizeScale = display.fontSize / AppTheme.danmakuDefaultFontSize;
    final opacity = display.opacity;

    // 字体大小、透明度或粗体变化时，分批更新已激活弹幕的样式
    // 每帧最多更新 _styleUpdateBatchSize 条，避免拖拽滑块时一次性重建所有弹幕导致卡顿
    final styleChanged = _lastAppliedFontSizeScale != fontSizeScale ||
        _lastAppliedOpacity != opacity ||
        _lastAppliedBold != display.bold;
    if (styleChanged && !_styleUpdatePending) {
      // 首次检测到变化：标记待更新，重置游标
      _styleUpdatePending = true;
      _styleUpdateBatchIndex = 0;
      _lastAppliedFontSizeScale = fontSizeScale;
      _lastAppliedOpacity = opacity;
      _lastAppliedBold = display.bold;
      // 旧文本缓存全部失效（新样式无法复用旧 painter）
      _textCache.clear();
    }
    // 批量重建：每帧最多更新 15 条弹幕样式（分摊到 ~3-4 帧完成 50 条）
    if (_styleUpdatePending && _activeDanmaku.isNotEmpty) {
      const int batchSize = 15;
      final int start = _styleUpdateBatchIndex;
      final int end = (start + batchSize).clamp(0, _activeDanmaku.length);
      for (int i = start; i < end; i++) {
        final d = _activeDanmaku[i];
        final fontSize = (d.danmaku.fontSize?.toDouble() ?? AppTheme.danmakuDefaultFontSize) * fontSizeScale;
        final textColor = _parseColor(d.danmaku.color).withValues(alpha: opacity);
        d.painter = _cachedPainter(d.danmaku.text, fontSize, display.bold, textColor);
        d.fontSize = fontSize;
        d.width = d.painter.width;
        d.height = d.painter.height;
        _detachBitmap(d); // 旧位图断引用(池里可能还有旧样式,LRU 自会淘汰)
        _scheduleBitmapGeneration(d); // 新样式重排入生成队列(池命中即零分配)
      }
      _styleUpdateBatchIndex = end;
      if (end >= _activeDanmaku.length) {
        _styleUpdatePending = false; // 全部更新完成
      }
    }

    final currentMs = _currentMs;
    final dtMs = deltaMs.clamp(1, 50).toDouble(); // 限制 delta 范围，防止切后台回来时跳帧
    final pxPerMs = _screenWidth / (display.speed * 1000);
    final dx = pxPerMs * dtMs * display.playbackSpeed; // 倍速联动
    var removedAny = false;
    _pendingRemoval.clear();
    for (int i = _activeDanmaku.length - 1; i >= 0; i--) {
      final d = _activeDanmaku[i];
      // 滚动弹幕：移动位置（从右向左）
      if (d.danmaku.type == DanmakuType.scroll) {
        d.offset -= dx;
        // 移出屏幕后回收
        if (d.offset < -d.width) {
          _pendingRemoval.add(i);
          final trackKey = 's_${d.track}';
          if (_trackLastDanmaku[trackKey] == d) {
            _trackLastDanmaku.remove(trackKey);
          }
          if (_danmakuPool.length < 200) {
            _danmakuPool.add(d);
          }
        }
      }
      // 顶部/底部弹幕：超时自动消失
      if (d.expireTimeMs > 0 && currentMs >= d.expireTimeMs) {
        _pendingRemoval.add(i);
        final prefix = d.danmaku.type == DanmakuType.top ? 't' : 'b';
        final expireTrackKey = '${prefix}_${d.track}';
        if (_trackLastDanmaku[expireTrackKey] == d) {
          _trackLastDanmaku.remove(expireTrackKey);
        }
        if (_danmakuPool.length < 200) {
          _danmakuPool.add(d);
        }
      }
    }
    // 批量清理：从后往前移除，避免索引偏移
    for (final i in _pendingRemoval) {
      _removeActive(i, _activeDanmaku[i]);
      removedAny = true;
    }
    // 智能重绘：有移动中的滚动弹幕才逐帧重绘；全是顶部/底部静态弹幕时
    // 只在激活/过期瞬间重绘（DanmakuFlameMaster 同款降功耗）
    if (shouldRepaintThisFrame(
        lowFrameRateMode: lowFrameRateMode,
        tickCount: _tickCount,
        hasMoving: _hasMovingDanmaku,
        removedAny: removedAny)) {
      _tickNotifier.value++;
    }
  }

  /// 内部：将弹幕分配到轨道并加入活动列表。
  ///
  /// [queueIndex] 是本次扫描批次的入场序号：同一批激活的弹幕若都从右缘同一
  /// X 出发，会以相同速度锁步左移，视觉上竖直排成一列（真机截图实证）。
  /// 按序号把起点往屏外排开，入场自然错峰——列变成流。
  /// 返回是否成功分配轨道；失败时弹幕回对象池，由调用方决定丢弃或重试。
  bool _addDanmakuToTrack(Danmaku danmaku, {int queueIndex = 0}) {
    // 排队上限 12 档:seek/恢复播放后的一次性大批补激活,最后一条也只
    // 顺延 ~5s 入场,不会排到几十秒开外。
    final qi = queueIndex.clamp(0, 12);
    final fontSizeScale = _config.fontSize / AppTheme.danmakuDefaultFontSize;
    final fontSize = (danmaku.fontSize?.toDouble() ?? AppTheme.danmakuDefaultFontSize) * fontSizeScale;
    final trackHeight = fontSize * AppTheme.danmakuTrackHeightRatio;

    // 从对象池取一个复用
    final d = _danmakuPool.isNotEmpty ? _danmakuPool.removeLast() : ActiveDanmaku.empty();

    final textColor = _danmakuTextColor(danmaku);
    // 共享 TextPainter：相同文本+样式复用已 layout 结果，避免重复测量
    d.painter = _cachedPainter(danmaku.text, fontSize, _config.bold, textColor);
    d
      ..danmaku = danmaku
      ..fontSize = fontSize
      ..width = d.painter.width
      ..height = d.painter.height
      ..offset = _screenWidth + qi * _entryStaggerPx
      ..expireTimeMs = (danmaku.type == DanmakuType.top || danmaku.type == DanmakuType.bottom)
          ? danmaku.time + 5000 // 顶部/底部弹幕显示 5 秒后自动消失
          : 0;

    // 分配轨道
    final trackKey = _allocateTrack(d, trackHeight);
    if (trackKey == null) {
      // 无可用轨道：绝不强制塞进已占用轨道（否则必然重叠）。是否丢弃由
      // 调用方决定——滚动弹幕可进重试队列，顶部/底部弹幕直接计丢。
      _timeoutDroppedCount++;
      // 每丢 50 条报一次，便于判断是否因轨道太少而丢弃过多
      if (_timeoutDroppedCount % 500 == 0) {
        final th = _config.fontSize * AppTheme.danmakuTrackHeightRatio;
        final lines = ((_screenHeight * _config.displayArea - 40) / th).floor();
        AppLog.i('Danmaku',
            '轨道满丢弃累计=$_timeoutDroppedCount (active=${_activeDanmaku.length}, '
            '实际轨道=$lines, 屏高=${_screenHeight.toInt()}, 轨高=${th.toStringAsFixed(1)}, '
            'type=${danmaku.type.name})');
      }
      if (_danmakuPool.length < 200) _danmakuPool.add(d);
      return false;
    }
    _totalActivatedCount++;
    _activeTexts[danmaku.text] = (_activeTexts[danmaku.text] ?? 0) + 1;
    // 真正入列后再计数（轨道分配失败被丢弃的不会误计）
    if (danmaku.type == DanmakuType.scroll) _scrollActiveCount++;
    _activeDanmaku.add(d);
    // P-1: 调度位图缓存生成（不阻塞当前帧，下一帧渲染时生效）
    _scheduleBitmapGeneration(d);
    return true;
  }

  /// 同批相邻两条弹幕的入场水平间隔：约等于 420ms 的滚动距离（比 300ms
  /// 扫描周期略大，保证后条入场时前条已让出空间），并夹在合理范围。
  double get _entryStaggerPx {
    if (_screenWidth <= 0) return 60.0;
    final pxPerMs = _screenWidth / (_config.speed * 1000);
    return (pxPerMs * 420).clamp(24.0, 240.0);
  }

  /// 弹幕文字颜色（透明度按配置烘焙进位图,与 TextPainter 一致）
  Color _danmakuTextColor(Danmaku danmaku) =>
      _parseColor(danmaku.color).withValues(alpha: _config.opacity);

  /// 位图池/文本缓存共用的样式 key（文本+字号+粗体+量化色）
  String _styleKey(String text, double fontSize, bool bold, Color color) {
    final quantized = color.toARGB32() & 0xFFF8F8F8; // RGB 各保留高 5 bit
    return '${fontSize.toStringAsFixed(1)}|${bold ? 1 : 0}|${quantized.toRadixString(16)}|$text';
  }

  /// P-1: 异步生成弹幕位图缓存 —— 先查常驻池（命中零分配,掐死 GC 风暴）,
  /// 未命中进队列串行生成（每帧最多 1 张 toImage,削密集入场的分配尖峰;
  /// 等待期间渲染层用 TextPainter 兜底,肉眼无感）。
  /// 重绘通知合并不变：同一帧多张就绪只通知一次。
  void _scheduleBitmapGeneration(ActiveDanmaku d) {
    if (_disposed) return;
    final key = _styleKey(
        d.danmaku.text, d.fontSize, _config.bold, _danmakuTextColor(d.danmaku));
    final pooled = _bitmapPool.get(key);
    if (pooled != null) {
      _borrowBitmap(d, pooled);
      _requestBitmapRepaint();
      return;
    }
    _bitmapGenPending.add(d);
    _scheduleBitmapGenDrain();
  }

  void _scheduleBitmapGenDrain() {
    if (_bitmapGenDrainScheduled || _disposed) return;
    _bitmapGenDrainScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _bitmapGenDrainScheduled = false;
      if (_disposed || _bitmapGenPending.isEmpty) return;
      final d = _bitmapGenPending.removeAt(0);
      if (!(d.bitmapDirty || d.bitmapCache == null)) {
        // 已被别处补上干净缓存（如同文本先到先得）
      } else {
        final key = _styleKey(d.danmaku.text, d.fontSize, _config.bold,
            _danmakuTextColor(d.danmaku));
        final pooled = _bitmapPool.get(key);
        if (pooled != null) {
          _borrowBitmap(d, pooled);
          _requestBitmapRepaint();
        } else {
          _generateBitmap(d, key);
        }
      }
      if (_bitmapGenPending.isNotEmpty) _scheduleBitmapGenDrain();
    });
  }

  /// 用 PictureRecorder 把 TextPainter 渲染成位图,入常驻池并借给弹幕。
  /// 位图尺寸 = 逻辑像素 × DPR,保证高 DPI 屏幕清晰不发虚。
  void _generateBitmap(ActiveDanmaku d, String key) {
    try {
      final dpr = _devicePixelRatio;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(dpr, dpr);
      d.painter.paint(canvas, Offset.zero);
      final picture = recorder.endRecording();
      final width = (d.painter.width * dpr).ceil();
      final height = (d.painter.height * dpr).ceil();
      if (width <= 0 || height <= 0) return;
      picture.toImage(width, height).then((image) {
        if (_disposed) {
          image.dispose();
          return;
        }
        _bitmapPool.put(key, image); // 池持有所有权,逐出/销毁由池负责
        _borrowBitmap(d, image);
        _requestBitmapRepaint(); // 合并通知,避免 N 张位图 = N 次重绘
      });
    } catch (_) {}
  }

  /// 借用位图：引用计数 +1,并断开弹幕上的旧引用（按引用计数决定是否释放）
  void _borrowBitmap(ActiveDanmaku d, ui.Image image) {
    _detachBitmap(d);
    d.bitmapCache = image;
    d.bitmapDirty = false;
    _bitmapBorrows[image] = (_bitmapBorrows[image] ?? 0) + 1;
  }

  /// 断开弹幕上的位图引用。位图所有权在常驻池,这里只在引用归零且
  /// 已被池逐出时才真正 dispose（防 use-after-dispose）。
  void _detachBitmap(ActiveDanmaku d) {
    final img = d.bitmapCache;
    d.bitmapCache = null;
    d.bitmapDirty = true;
    if (img == null) return;
    final n = (_bitmapBorrows[img] ?? 1) - 1;
    if (n <= 0) {
      _bitmapBorrows.remove(img);
      if (_bitmapPendingDispose.remove(img)) img.dispose();
    } else {
      _bitmapBorrows[img] = n;
    }
  }

  /// 池逐出回调：仍被借用的位图挂待释放列表（等最后一个借用者断开）,
  /// 无人借用的立即 dispose。
  void _onPoolEvict(ui.Image image) {
    if ((_bitmapBorrows[image] ?? 0) > 0) {
      _bitmapPendingDispose.add(image);
    } else {
      image.dispose();
    }
  }

  /// 位图就绪后的重绘请求合并：同一帧内多张位图完成只触发一次通知
  void _requestBitmapRepaint() {
    if (_bitmapRepaintScheduled) return;
    _bitmapRepaintScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _bitmapRepaintScheduled = false;
      // 滚动弹幕本来每帧都在重绘，只有静态弹幕场景才真正需要这次通知
      if (!_hasMovingDanmaku && _activeDanmaku.isNotEmpty) {
        _tickNotifier.value++;
      }
    });
  }

  /// 取（或创建）共享 TextPainter：layout 只做一次，后续同文本命中直接复用
  /// （DanmakuFlameMaster 测量缓存，layout 是弹幕渲染最大开销）
  /// LRU 淘汰：缓存满时移除最久未使用的条目，而非全清（避免瞬间卡顿）
  ///
  /// 颜色量化：颜色不影响 layout 结果，但若原样编入 key 会让「同文本不同色」
  /// 各自重新 layout。这里把 RGB 各通道量化到 5 bit（32 档），把 key 空间从
  /// 数百色压到几十色，命中率显著提升（视觉上肉眼无差）。
  TextPainter _cachedPainter(String text, double fontSize, bool bold, Color color) {
    final key = _styleKey(text, fontSize, bold, color);
    final cached = _textCache[key];
    if (cached != null) return cached;
    // LRU 淘汰：移除最旧的条目（LinkedHashMap 按访问顺序，first 是最久未用的）
    while (_textCache.length >= _textCacheMax) {
      _textCache.remove(_textCache.keys.first);
    }
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.6 * _config.opacity),
              blurRadius: AppTheme.danmakuShadowBlur,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    _textCache[key] = painter;
    return painter;
  }

  /// 移除活动弹幕并维护副作用集合（O(1) 判重计数 / 滚动计数）
  void _removeActive(int index, ActiveDanmaku d) {
    _detachBitmap(d); // 断引用,位图归池(LRU 复用/超限逐出)
    _activeDanmaku.removeAt(index);
    _activeDanmakuIds.remove(d.danmaku.id);
    // 文本计数 -1，归零才真正移除（同文本多条在屏时判重仍生效）
    final txt = d.danmaku.text;
    final cnt = (_activeTexts[txt] ?? 1) - 1;
    if (cnt <= 0) {
      _activeTexts.remove(txt);
    } else {
      _activeTexts[txt] = cnt;
    }
    // 滚动计数 -1（不再 O(n) 全表重扫）
    if (d.danmaku.type == DanmakuType.scroll && _scrollActiveCount > 0) {
      _scrollActiveCount--;
    }
  }

  /// 轨道前缀（用于分离不同类型的轨道编号）
  String _trackPrefix(DanmakuType type) {
    switch (type) {
      case DanmakuType.scroll: return 's';
      case DanmakuType.top: return 't';
      case DanmakuType.bottom: return 'b';
    }
  }

  /// 内部：为弹幕分配轨道（返回轨道键，null 表示无可用轨道）
  ///
  /// 轨道垂直范围：使用 _config.displayArea（默认 1.0=全屏高度）。
  ///
  /// 滚动弹幕轨道数 = 屏幕可容纳的全部轨道（maxLines），不再被 maxScrollLines 截断。
  /// 原先 clamp(1, 16) 让轨道只铺到 40+16*25.5=448px（约屏幕 41%），
  /// 下半屏永远没有滚动弹幕 —— 这是「弹幕挤在上半部分」的根因。
  /// maxScrollLines 现在仅作为**下限保障**（配置值比屏幕容量大时才生效）。
  ///
  /// 轮转起点（关键）：从上次分配的下一条轨道开始找，而不是每次都从 0 开始。
  /// 否则稀疏场景下 track 0 总是空闲，所有弹幕都会落在同一行（垂直位置完全一致）。
  ///
  /// 满载时返回 null，由调用方丢弃 —— 绝不强制塞进已占用轨道。
  String? _allocateTrack(ActiveDanmaku d, double trackHeight) {
    final danmaku = d.danmaku;
    // 可用垂直空间：减去顶部 40px 起始偏移（与渲染器 top = 40 + track*trackHeight 对齐）
    final usableHeight = _screenHeight * _config.displayArea - 40;
    final maxLines = (usableHeight / trackHeight).floor().clamp(1, 60);
    final prefix = _trackPrefix(danmaku.type);

    int typeMaxLines;
    int startCursor;
    switch (danmaku.type) {
      case DanmakuType.scroll:
        // 铺满屏幕：取屏幕容量与配置值的较大者，让下半屏也有弹幕
        typeMaxLines = maxLines > _config.maxScrollLines ? maxLines : _config.maxScrollLines;
        startCursor = _nextScrollTrack;
        break;
      case DanmakuType.top:
        typeMaxLines = maxLines.clamp(1, _config.maxTopLines);
        startCursor = _nextTopTrack;
        break;
      case DanmakuType.bottom:
        typeMaxLines = maxLines.clamp(1, _config.maxBottomLines);
        startCursor = _nextBottomTrack;
        break;
    }

    // 从轮转起点开始环形查找，命中即分配并推进游标
    for (int n = 0; n < typeMaxLines; n++) {
      final i = (startCursor + n) % typeMaxLines;
      final key = '${prefix}_$i';
      final prev = _trackLastDanmaku[key];
      if (prev == null || _isTrackAvailable(d, prev)) {
        d.track = i;
        _trackLastDanmaku[key] = d;
        final next = (i + 1) % typeMaxLines;
        switch (danmaku.type) {
          case DanmakuType.scroll:
            _nextScrollTrack = next;
            break;
          case DanmakuType.top:
            _nextTopTrack = next;
            break;
          case DanmakuType.bottom:
            _nextBottomTrack = next;
            break;
        }
        return key;
      }
    }

    // 所有轨道都被占用 → 返回 null，调用方丢弃本条（宁可少弹几条也不重叠）
    return null;
  }

  /// 轨道是否可以接纳新弹幕（前一条为 prev）
  ///
  /// 滚动弹幕：所有滚动弹幕**速度完全相同**（pxPerMs 全局一致），因此同轨道上
  /// 相邻两条的间距恒定、永远不会追尾。判据只需「前一条尾部已完全进入屏幕
  /// 并留出间隙」即可。
  ///
  /// 原实现用 `safeMargin = d.width + prev.width + 150` 要求前一条多走
  /// 2~3 倍距离，导致密集片段大量弹幕因无轨道被丢弃（表现为弹幕数量骤减）。
  bool _isTrackAvailable(ActiveDanmaku d, ActiveDanmaku prev) {
    if (d.danmaku.type == DanmakuType.scroll) {
      // 防重叠开启时留大一点的视觉间隙，关闭时只要不贴着即可
      final gap = _config.preventOverlap ? 36.0 : 8.0;
      return prev.offset + prev.width + gap <= _screenWidth;
    }
    // 顶部/底部弹幕：前一条过期后轨道才可复用
    return _currentMs >= prev.expireTimeMs;
  }

  /// 屏蔽词匹配：支持普通文本和 /regex/ 格式（Hills 同款 DanmakuFilters）
  bool _isBlocked(String text, List<String> blockedWords) {
    for (final word in blockedWords) {
      if (word.startsWith('/') && word.endsWith('/') && word.length > 2) {
        // 正则格式：/regex/
        try {
          final pattern = word.substring(1, word.length - 1);
          if (RegExp(pattern, caseSensitive: false).hasMatch(text)) return true;
        } catch (_) {}
      } else {
        // 普通文本：包含即屏蔽
        if (text.contains(word)) return true;
      }
    }
    return false;
  }

  /// 解析十六进制颜色字符串
  ///
  /// 支持 #RRGGBB 与 #AARRGGBB 两种格式，空串或非法格式返回白色。
  Color _parseColor(String color) {
    if (color.isEmpty) return Colors.white;
    if (color.startsWith('#')) {
      final hex = color.substring(1);
      if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    }
    return Colors.white;
  }

  /// 释放资源
  ///
  /// 停止并销毁 Ticker，释放 ValueNotifier，清空活动弹幕与对象池。
  void dispose() {
    _disposed = true;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _tickNotifier.dispose();
    _bitmapGenPending.clear();
    // 所有位图都在常驻池(借用的引用随池一起释放)
    _bitmapPool.disposeAll();
    for (final img in _bitmapPendingDispose) {
      img.dispose();
    }
    _bitmapPendingDispose.clear();
    _bitmapBorrows.clear();
    _activeDanmaku.clear();
    _danmakuPool.clear();
    _retryQueue.clear();
    _trackLastDanmaku.clear();
    _activeDanmakuIds.clear();
    _activeTexts.clear();
    _textCache.clear();
    _danmakuList = [];
  }
}
