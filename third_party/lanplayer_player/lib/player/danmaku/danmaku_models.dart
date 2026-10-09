import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../services/danmaku_service.dart';
import '../../providers/app_providers.dart';

/// 活动弹幕（已激活，正在屏幕上显示的弹幕）
///
/// 从 player_screen.dart 的 _ActiveDanmaku 提取，供 DanmakuController 与
/// DanmakuRenderer 共享。painter 复用 TextPainter 以减少对象创建开销。
class ActiveDanmaku {
  Danmaku danmaku;
  int track;
  double offset;
  double width;
  double height;
  double fontSize;
  int expireTimeMs; // 顶部/底部弹幕过期时间（毫秒），0=滚动弹幕不过期
  // 可被文本缓存替换（DanmakuFlameMaster 式共享 TextPainter：相同文本+样式复用同一 layout）
  TextPainter painter;
  // P-1: Bitmap 绘制缓存 — 首次渲染时 toImage() 为位图，后续帧直接 drawImage
  ui.Image? bitmapCache;
  bool bitmapDirty = true; // 标记位图需要重新生成（样式变化时置 true）

  ActiveDanmaku({
    required this.danmaku,
    required this.track,
    required this.offset,
    required this.width,
    required this.height,
    required this.fontSize,
    this.expireTimeMs = 0,
    required this.painter,
    this.bitmapCache,
    this.bitmapDirty = true,
  });

  /// 释放位图缓存资源
  void disposeBitmap() {
    bitmapCache?.dispose();
    bitmapCache = null;
    bitmapDirty = true;
  }

  /// 创建空对象，用于对象池复用
  factory ActiveDanmaku.empty() => ActiveDanmaku(
        danmaku: Danmaku(id: '', text: '', time: 0, color: '#FFFFFF', type: DanmakuType.scroll),
        track: 0,
        offset: 0,
        width: 0,
        height: 0,
        fontSize: 0,
        expireTimeMs: 0,
        painter: TextPainter(textDirection: TextDirection.ltr),
      );
}

/// 弹幕渲染配置（从 DanmakuDisplaySettings 映射）
///
/// 将 Riverpod 中的 DanmakuDisplaySettings 与视频倍速合并为控制器所需的纯值对象，
/// 避免控制器直接依赖 Provider。
class DanmakuRenderConfig {
  final double fontSize;
  final double opacity;
  final double speed;
  final bool showTop;
  final bool showBottom;
  final bool showScroll;
  final double playbackSpeed; // 视频倍速，影响滚动弹幕位移
  final double syncDelay;       // 弹幕同步偏移（秒）
  final double displayArea;     // 弹幕显示区域（0.5~1.0，占屏幕高度比例）
  final int maxScrollLines;     // 滚动弹幕最大行数
  final int maxTopLines;        // 顶部弹幕最大行数
  final int maxBottomLines;     // 底部弹幕最大行数
  final bool bold;              // 粗体
  final bool mergeDuplicates;   // 合并重复弹幕
  final bool preventOverlap;    // 防止弹幕重叠
  final bool heatmap;           // 弹幕热力图
  final int maxScreen;          // 屏幕最大弹幕数（0=使用默认值）
  final List<String> blockedWords; // 屏蔽词列表
  final int minimumLength;      // 弹幕最短长度过滤

  const DanmakuRenderConfig({
    this.fontSize = 17,
    this.opacity = 1.0,
    this.speed = 12,
    this.showTop = true,
    this.showBottom = true,
    this.showScroll = true,
    this.playbackSpeed = 1.0,
    this.syncDelay = 0.0,
    this.displayArea = 1.0,
    this.maxScrollLines = 4,
    this.maxTopLines = 8,
    this.maxBottomLines = 8,
    this.bold = false,
    this.mergeDuplicates = false,
    this.preventOverlap = true,
    this.heatmap = true,
    this.maxScreen = 0,
    this.blockedWords = const [],
    this.minimumLength = 0,
  });

  /// 默认配置
  factory DanmakuRenderConfig.defaults() => const DanmakuRenderConfig();

  /// 从弹幕显示设置构建（合并视频倍速）
  factory DanmakuRenderConfig.fromSettings(
    DanmakuDisplaySettings settings, {
    double playbackSpeed = 1.0,
  }) {
    return DanmakuRenderConfig(
      fontSize: settings.fontSize,
      opacity: settings.opacity,
      speed: settings.speed,
      showTop: settings.showTop,
      showBottom: settings.showBottom,
      showScroll: settings.showScroll,
      playbackSpeed: playbackSpeed,
      syncDelay: settings.syncDelay,
      displayArea: settings.displayArea,
      maxScrollLines: settings.maxScrollLines, // 仅作下限；实际轨道数由屏幕高度自适应
      maxTopLines: settings.maxTopLines,
      maxBottomLines: settings.maxBottomLines,
      bold: settings.bold,
      mergeDuplicates: settings.mergeDuplicates,
      preventOverlap: false, // [A] 关闭防重叠：同速弹幕永不追尾，gap 36px→8px 密度提升~4x
      heatmap: settings.heatmap,
      maxScreen: settings.maxScreen,
      blockedWords: settings.blockKeywords,
      minimumLength: settings.minimumLength,
    );
  }

  DanmakuRenderConfig copyWith({
    double? fontSize,
    double? opacity,
    double? speed,
    bool? showTop,
    bool? showBottom,
    bool? showScroll,
    double? playbackSpeed,
    double? syncDelay,
    double? displayArea,
    int? maxScrollLines,
    int? maxTopLines,
    int? maxBottomLines,
    bool? bold,
    bool? mergeDuplicates,
    bool? preventOverlap,
    bool? heatmap,
    int? maxScreen,
    List<String>? blockedWords,
    int? minimumLength,
  }) {
    return DanmakuRenderConfig(
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      speed: speed ?? this.speed,
      showTop: showTop ?? this.showTop,
      showBottom: showBottom ?? this.showBottom,
      showScroll: showScroll ?? this.showScroll,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      syncDelay: syncDelay ?? this.syncDelay,
      displayArea: displayArea ?? this.displayArea,
      maxScrollLines: maxScrollLines ?? this.maxScrollLines,
      maxTopLines: maxTopLines ?? this.maxTopLines,
      maxBottomLines: maxBottomLines ?? this.maxBottomLines,
      bold: bold ?? this.bold,
      mergeDuplicates: mergeDuplicates ?? this.mergeDuplicates,
      preventOverlap: preventOverlap ?? this.preventOverlap,
      heatmap: heatmap ?? this.heatmap,
      maxScreen: maxScreen ?? this.maxScreen,
      blockedWords: blockedWords ?? this.blockedWords,
      minimumLength: minimumLength ?? this.minimumLength,
    );
  }
}

/// 弹幕加载错误分类
enum DanmakuLoadError {
  /// 未配置弹幕源
  noConfig,
  /// 弹幕服务连接失败
  connectionFail,
  /// 未找到匹配的弹幕
  noMatch,
  /// API 请求异常
  apiError,
  /// 未知错误
  unknown;

  /// 用户可见的错误描述
  String get message {
    switch (this) {
      case DanmakuLoadError.noConfig:
        return '未配置弹幕源';
      case DanmakuLoadError.connectionFail:
        return '弹幕服务连接失败';
      case DanmakuLoadError.noMatch:
        return '未找到匹配弹幕';
      case DanmakuLoadError.apiError:
        return '弹幕接口异常';
      case DanmakuLoadError.unknown:
        return '加载失败';
    }
  }
}
