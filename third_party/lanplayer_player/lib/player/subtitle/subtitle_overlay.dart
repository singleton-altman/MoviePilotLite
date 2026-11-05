import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/player_settings.dart';
import '../../utils/subtitle_fonts.dart';
import 'subtitle_cue.dart';
import 'subtitle_parser.dart';

/// 外挂字幕叠加层
/// 通过 CustomPaint + ValueNotifier 渲染当前时间点的字幕
/// 复用 Phase 1 的 PlayerSettings 字幕样式
class SubtitleOverlay extends StatefulWidget {
  final List<SubtitleCue> cues;
  final Duration Function() currentPosition;
  final PlayerSettings settings;
  final double screenWidth;
  final double screenHeight;
  final BoxFit fitMode;    // 当前画幅模式，用于计算视频实际底部偏移
  final Size videoSize;    // 视频原始尺寸（如 1920x1080）

  /// 自行轮询 [currentPosition] 的间隔。
  ///
  /// 改造前字幕只在**父级重建**时才换 cue，而播放器的 UI 定时器是 500ms
  /// 一跳 —— 字幕的出入点因此被量化到半秒，能看出迟到。这里自己起一个更细
  /// 的轮询：每次只做一次 O(log n) 二分查找，且只有 cue 真的换了才推
  /// notifier（见 [_SubtitleOverlayState._lastCueIndex]），所以不产生额外重建，
  /// 更不会让整个播放器页面跟着重建。
  final Duration pollInterval;

  const SubtitleOverlay({
    super.key,
    required this.cues,
    required this.currentPosition,
    required this.settings,
    required this.screenWidth,
    required this.screenHeight,
    this.fitMode = BoxFit.contain,
    this.videoSize = const Size(1920, 1080),
    this.pollInterval = const Duration(milliseconds: 100),
  });

  @override
  State<SubtitleOverlay> createState() => _SubtitleOverlayState();
}

class _SubtitleOverlayState extends State<SubtitleOverlay> {
  final ValueNotifier<SubtitleCue?> _currentCueNotifier = ValueNotifier<SubtitleCue?>(null);
  int _lastCueIndex = -1;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _updateCurrentCue();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (widget.pollInterval <= Duration.zero) return;
    _pollTimer = Timer.periodic(widget.pollInterval, (_) => _updateCurrentCue());
  }

  @override
  void didUpdateWidget(SubtitleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cues != widget.cues) {
      _lastCueIndex = -1;
    }
    if (oldWidget.pollInterval != widget.pollInterval) {
      _startPolling();
    }
    _updateCurrentCue();
  }

  /// 更新当前字幕
  /// 调用方需在播放位置变化时调用此方法（通过 setState 或 ValueNotifier 触发重建）
  /// 使用二分查找（cues 按 start 升序），与 ExternalSubtitleManager.getCueAt 一致，
  /// 大字幕文件下 O(log n) 替代线性扫描。
  void _updateCurrentCue() {
    final position = widget.currentPosition();
    final cues = widget.cues;
    SubtitleCue? found;
    int newIdx = -1;
    if (cues.isNotEmpty) {
      int left = 0;
      int right = cues.length - 1;
      while (left <= right) {
        final mid = (left + right) ~/ 2;
        final cue = cues[mid];
        if (cue.contains(position)) {
          found = cue;
          newIdx = mid;
          break;
        }
        if (position < cue.start) {
          right = mid - 1;
        } else {
          left = mid + 1;
        }
      }
    }
    if (newIdx != _lastCueIndex) {
      _lastCueIndex = newIdx;
      _currentCueNotifier.value = found;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 幂等注册自定义字体（已注册则直接返回），确保 Exo 外挂字幕用上用户字体
    SubtitleFonts.ensureLoaded();
    return ValueListenableBuilder<SubtitleCue?>(
      valueListenable: _currentCueNotifier,
      builder: (context, cue, _) {
        if (cue == null) return const SizedBox.shrink();
        // 字幕位置修复：根据 fitMode 计算视频实际底部偏移，
        // 将字幕锚定到视频底部而非屏幕底部（修复适配宽度时字幕偏下）
        final videoBottomInset = _computeVideoBottomInset();
        final baseMargin = widget.screenHeight * widget.settings.subtitleBottomMargin;
        final effectiveMargin = baseMargin + videoBottomInset;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: effectiveMargin),
            child: _buildSubtitleText(cue.text),
          ),
        );
      },
    );
  }

  /// 字幕底部偏移：视频显示区底部在屏幕外的深度（像素）。
  ///
  /// contain/自适应：视频完整落在屏幕内 → 0，字幕锚定屏幕底 = 视频底。
  /// cover（填充）/fitWidth：视频按宽度铺满、上下溢出屏幕 → 底部有
  /// 一截沉到屏幕外，字幕若仍锚屏幕底就被裁。此时把字幕抬到视频
  /// 实际底缘之上。
  /// fill（拉伸）/fitHeight：视频高度铺满屏幕、没有上下溢出 → 0。
  double _computeVideoBottomInset() => subtitleBottomInset(
        fitMode: widget.fitMode,
        videoSize: widget.videoSize,
        screenWidth: widget.screenWidth,
        screenHeight: widget.screenHeight,
      );

  /// 字体解析：自定义字体文件优先，其次样式表字体，缺省系统字体
  String? _resolveFontFamily(PlayerSettings s) {
    if (SubtitleFonts.savedPath != null && SubtitleFonts.savedPath!.isNotEmpty) {
      return SubtitleFonts.fontFamily;
    }
    return s.subtitleFontFamily == 'system' ? null : s.subtitleFontFamily;
  }

  /// 构建字幕文本 Widget
  /// 支持多行（换行符分割）、描边、阴影、背景
  Widget _buildSubtitleText(String text) {
    final s = widget.settings;
    final fontSize = _calculateFontSize();

    // 支持多行
    final lines = text.split('\n');

    return Container(
      constraints: BoxConstraints(maxWidth: widget.screenWidth * 0.9),
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: s.subtitleBackgroundOpacity > 0
          ? BoxDecoration(
              color: Colors.black.withValues(alpha: s.subtitleBackgroundOpacity),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: lines.map((line) {
          return Stack(
            children: [
              // 描边层
              if (s.subtitleBorderWidth > 0)
                Text(
                  line,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: s.subtitleBold ? FontWeight.bold : FontWeight.normal,
                    fontFamily: _resolveFontFamily(s),
                    fontFamilyFallback: const ['Noto Sans CJK SC', 'sans-serif'],
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = s.subtitleBorderWidth
                      ..color = Color(s.subtitleBorderColor),
                  ),
                  textAlign: TextAlign.center,
                ),
              // 阴影层
              if (s.subtitleShadowOffset > 0)
                Text(
                  line,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: s.subtitleBold ? FontWeight.bold : FontWeight.normal,
                    fontFamily: _resolveFontFamily(s),
                    fontFamilyFallback: const ['Noto Sans CJK SC', 'sans-serif'],
                    color: Colors.transparent,
                    shadows: [
                      Shadow(
                        color: Color(s.subtitleShadowColor),
                        offset: Offset(s.subtitleShadowOffset, s.subtitleShadowOffset),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              // 主文字层
              Text(
                line,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: s.subtitleBold ? FontWeight.bold : FontWeight.normal,
                  fontFamily: _resolveFontFamily(s),
                  fontFamilyFallback: const ['Noto Sans CJK SC', 'sans-serif'],
                  color: Color(s.subtitleColor),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 根据屏幕高度和字号倍数计算实际字号
  /// 基准 6%：5.33% 偏小、8.5% 偏大、7% 仍偏大（三次实机反馈），
  /// 最终取 6%（1080p 横屏 ≈65px，清晰且不遮画面）
  double _calculateFontSize() {
    const baseRatio = 0.06;
    return widget.screenHeight * baseRatio * widget.settings.subtitleFontSizeScale;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _currentCueNotifier.dispose();
    super.dispose();
  }
}

/// 外挂字幕管理器
/// 负责加载字幕文件、管理 cue 列表、驱动字幕更新
class ExternalSubtitleManager {
  List<SubtitleCue> _cues = [];
  bool _loaded = false;
  String? _error;

  List<SubtitleCue> get cues => _cues;
  bool get isLoaded => _loaded;
  String? get error => _error;

  /// 从文件路径加载字幕
  Future<void> loadFromFile(String path) async {
    _loaded = false;
    _error = null;
    _cues = [];
    try {
      _cues = await SubtitleParser.parseFile(path);
      _loaded = _cues.isNotEmpty;
      if (!_loaded) {
        _error = '字幕文件为空或解析失败';
      }
    } catch (e) {
      _error = '加载字幕失败: $e';
    }
  }

  /// 从字符串加载字幕
  void loadFromContent(String content) {
    _loaded = false;
    _error = null;
    _cues = [];
    try {
      _cues = SubtitleParser.parseContent(content);
      _loaded = _cues.isNotEmpty;
      if (!_loaded) {
        _error = '字幕内容为空或解析失败';
      }
    } catch (e) {
      _error = '解析字幕失败: $e';
    }
  }

  /// 获取指定时间点的字幕（二分查找优化）
  SubtitleCue? getCueAt(Duration position) {
    if (_cues.isEmpty) return null;
    // 二分查找
    int left = 0;
    int right = _cues.length - 1;
    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final cue = _cues[mid];
      if (cue.contains(position)) return cue;
      if (position < cue.start) {
        right = mid - 1;
      } else {
        left = mid + 1;
      }
    }
    return null;
  }

  void clear() {
    _cues = [];
    _loaded = false;
    _error = null;
  }
}


/// 字幕底部抬升量(像素):视频显示区底部沉到屏幕外的深度。
/// 纯函数便于单测(test/subtitle_inset_test.dart)。
double subtitleBottomInset({
  required BoxFit fitMode,
  required Size videoSize,
  required double screenWidth,
  required double screenHeight,
}) {
  if (videoSize.width <= 0 || videoSize.height <= 0 || screenWidth <= 0) {
    return 0;
  }
  // contain/自适应:视频完整落在屏幕内(上下有留白或正好铺满)→ 无溢出;
  // fill(拉伸)/fitHeight(适配高度):高度铺满屏幕 → 无上下溢出。
  // 注意 contain 在"屏幕比视频更宽"时高度铺满、无溢出;在"屏幕更窄"时
  // 视频按宽适配、上下留白 → 字幕若贴屏幕底会低于视频底,但那是
  // contain 的固有形态(用户选择完整显示),不在此修正。
  if (fitMode == BoxFit.contain ||
      fitMode == BoxFit.fill ||
      fitMode == BoxFit.fitHeight) {
    return 0;
  }
  // cover(填充)与 fitWidth(适配宽度):视频宽铺满屏幕,
  // 显示高度 = 屏宽/视频宽高比,上下对称溢出(中心裁切)。
  final displayHeight = screenWidth / (videoSize.width / videoSize.height);
  final overflow = displayHeight - screenHeight;
  if (overflow <= 0) return 0;
  return overflow / 2;
}
