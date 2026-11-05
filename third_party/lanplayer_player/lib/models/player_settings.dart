import 'dart:convert';

class PlayerSettings {
  // 片头片尾
  final bool autoSkipIntro;
  final bool autoSkipOutro;
  final bool showSkipButton;

  // 播放
  final double defaultPlaybackSpeed;
  final String defaultQuality; // 'auto', '1080p', '4k', 'original'
  final bool enableHardwareAcceleration;
  final String playerKernel; // 'auto', 'exo', 'mpv'
  // 解码兼容模式(TV):true=hwdec 走 mediacodec-copy(每帧拷回内存,兼容但
  // 在弱芯 TV 上 72MB/s 原生分配把 NativeAlloc GC 逼到 2次/秒,全局掉帧);
  // false(默认)=mediacodec 直连,解码帧直达 GPU 纹理。黑屏/花屏设备的逃生门。
  final bool decodeCompatMode;

  // 弹幕
  final bool enableDanmakuByDefault;
  final int danmakuFontSize;
  final double danmakuOpacity;
  final double danmakuSpeed;
  final bool burnInSubtitle;            // 字幕烧录：请求服务器把字幕编码进视频流（需转码）

  // 字幕样式（视频内嵌字幕，区别于弹幕 danmaku*）
  final double subtitleFontSizeScale;     // 字号倍数 0.5-2.5（基于视频高度百分比缩放）
  final String subtitleFontFamily;        // 'system' | 'sans-serif' | 'serif' | 'monospace'
  final bool subtitleBold;
  final int subtitleColor;                // ARGB（默认 0xFFFFFFFF 白色）
  final int subtitleBorderColor;          // ARGB（默认 0xCC000000 80%黑）
  final double subtitleBorderWidth;       // 0-4
  final int subtitleShadowColor;          // ARGB（默认 0x80000000 50%黑）
  final double subtitleShadowOffset;      // 0-4
  final double subtitleBottomMargin;      // 视频高度百分比 0-0.3
  final double subtitleBackgroundOpacity; // 0-0.8
  final bool subtitleAssOverride;         // true=统一样式（sub-ass-override=force）
  final double subtitleDelaySeconds;      // 字幕延迟（秒，正=延后，负=提前）
  final String? subtitleFontPath;          // 自定义字幕字体文件路径（Exo 外挂字幕 Flutter 层渲染生效）

  // 详情页预设的默认轨（按语言匹配，跨剧集稳定，实现"应用到全部"）
  final String? defaultSubtitleLang;      // 如 'zho'/'eng'，null=未设置
  final String? defaultAudioLang;         // 如 'zho'/'eng'，null=未设置

  // 手势
  final bool enableGestureSeek;
  final bool enableGestureVolume;
  final bool enableGestureBrightness;
  final bool enableDoubleTapSeek;
  final int doubleTapSeekSeconds;

  // 高级
  final bool enableBackgroundPlay;
  final bool enablePiP;
  final bool enableProgressSync; // Emby/Jellyfin 进度同步

  const PlayerSettings({
    this.autoSkipIntro = false,
    this.autoSkipOutro = false,
    this.showSkipButton = true,
    this.defaultPlaybackSpeed = 1.0,
    this.defaultQuality = 'auto',
    this.enableHardwareAcceleration = true,
    this.playerKernel = 'auto',
    this.decodeCompatMode = false,
    this.enableDanmakuByDefault = true,
    this.danmakuFontSize = 17,
    this.danmakuOpacity = 1.0,
    this.danmakuSpeed = 12,
    this.burnInSubtitle = false,
    this.subtitleFontSizeScale = 1.0,
    this.subtitleFontFamily = 'system',
    this.subtitleBold = false,
    this.subtitleColor = 0xFFFFFFFF,
    this.subtitleBorderColor = 0xCC000000,
    this.subtitleBorderWidth = 3.0,
    this.subtitleShadowColor = 0x80000000,
    this.subtitleShadowOffset = 2.0,
    this.subtitleBottomMargin = 0.05,
    this.subtitleBackgroundOpacity = 0.0,
    this.subtitleAssOverride = true,
    this.subtitleDelaySeconds = 0.0,
    this.subtitleFontPath,
    this.defaultSubtitleLang,
    this.defaultAudioLang,

    this.enableGestureSeek = true,
    this.enableGestureVolume = true,
    this.enableGestureBrightness = true,
    this.enableDoubleTapSeek = true,
    this.doubleTapSeekSeconds = 10,
    this.enableBackgroundPlay = true,
    this.enablePiP = true,
    this.enableProgressSync = true,
  });

  static const PlayerSettings defaults = PlayerSettings();

  PlayerSettings copyWith({
    bool? autoSkipIntro,
    bool? autoSkipOutro,
    bool? showSkipButton,
    double? defaultPlaybackSpeed,
    String? defaultQuality,
    bool? enableHardwareAcceleration,
    String? playerKernel,
    bool? decodeCompatMode,
    bool? enableDanmakuByDefault,
    int? danmakuFontSize,
    double? danmakuOpacity,
    double? danmakuSpeed,
    bool? burnInSubtitle,
    double? subtitleFontSizeScale,
    String? subtitleFontFamily,
    bool? subtitleBold,
    int? subtitleColor,
    int? subtitleBorderColor,
    double? subtitleBorderWidth,
    int? subtitleShadowColor,
    double? subtitleShadowOffset,
    double? subtitleBottomMargin,
    double? subtitleBackgroundOpacity,
    bool? subtitleAssOverride,
    double? subtitleDelaySeconds,
    String? subtitleFontPath,
    String? defaultSubtitleLang,
    String? defaultAudioLang,
    bool? enableGestureSeek,
    bool? enableGestureVolume,
    bool? enableGestureBrightness,
    bool? enableDoubleTapSeek,
    int? doubleTapSeekSeconds,
    bool? enableBackgroundPlay,
    bool? enablePiP,
    bool? enableProgressSync,
  }) {
    return PlayerSettings(
      autoSkipIntro: autoSkipIntro ?? this.autoSkipIntro,
      autoSkipOutro: autoSkipOutro ?? this.autoSkipOutro,
      showSkipButton: showSkipButton ?? this.showSkipButton,
      defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      enableHardwareAcceleration: enableHardwareAcceleration ?? this.enableHardwareAcceleration,
      playerKernel: playerKernel ?? this.playerKernel,
      decodeCompatMode: decodeCompatMode ?? this.decodeCompatMode,
      enableDanmakuByDefault: enableDanmakuByDefault ?? this.enableDanmakuByDefault,
      danmakuFontSize: danmakuFontSize ?? this.danmakuFontSize,
      danmakuOpacity: danmakuOpacity ?? this.danmakuOpacity,
      danmakuSpeed: danmakuSpeed ?? this.danmakuSpeed,
      burnInSubtitle: burnInSubtitle ?? this.burnInSubtitle,
      subtitleFontSizeScale: subtitleFontSizeScale ?? this.subtitleFontSizeScale,
      subtitleFontFamily: subtitleFontFamily ?? this.subtitleFontFamily,
      subtitleBold: subtitleBold ?? this.subtitleBold,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      subtitleBorderColor: subtitleBorderColor ?? this.subtitleBorderColor,
      subtitleBorderWidth: subtitleBorderWidth ?? this.subtitleBorderWidth,
      subtitleShadowColor: subtitleShadowColor ?? this.subtitleShadowColor,
      subtitleShadowOffset: subtitleShadowOffset ?? this.subtitleShadowOffset,
      subtitleBottomMargin: subtitleBottomMargin ?? this.subtitleBottomMargin,
      subtitleBackgroundOpacity: subtitleBackgroundOpacity ?? this.subtitleBackgroundOpacity,
      subtitleAssOverride: subtitleAssOverride ?? this.subtitleAssOverride,
      subtitleDelaySeconds: subtitleDelaySeconds ?? this.subtitleDelaySeconds,
      subtitleFontPath: subtitleFontPath ?? this.subtitleFontPath,
      defaultSubtitleLang: defaultSubtitleLang ?? this.defaultSubtitleLang,
      defaultAudioLang: defaultAudioLang ?? this.defaultAudioLang,
      enableGestureSeek: enableGestureSeek ?? this.enableGestureSeek,
      enableGestureVolume: enableGestureVolume ?? this.enableGestureVolume,
      enableGestureBrightness: enableGestureBrightness ?? this.enableGestureBrightness,
      enableDoubleTapSeek: enableDoubleTapSeek ?? this.enableDoubleTapSeek,
      doubleTapSeekSeconds: doubleTapSeekSeconds ?? this.doubleTapSeekSeconds,
      enableBackgroundPlay: enableBackgroundPlay ?? this.enableBackgroundPlay,
      enablePiP: enablePiP ?? this.enablePiP,
      enableProgressSync: enableProgressSync ?? this.enableProgressSync,
    );
  }

  Map<String, dynamic> toJson() => {
    'autoSkipIntro': autoSkipIntro,
    'autoSkipOutro': autoSkipOutro,
    'showSkipButton': showSkipButton,
    'defaultPlaybackSpeed': defaultPlaybackSpeed,
    'defaultQuality': defaultQuality,
    'enableHardwareAcceleration': enableHardwareAcceleration,
    'playerKernel': playerKernel,
    'decodeCompatMode': decodeCompatMode,
    'enableDanmakuByDefault': enableDanmakuByDefault,
    'danmakuFontSize': danmakuFontSize,
    'danmakuOpacity': danmakuOpacity,
    'danmakuSpeed': danmakuSpeed,
    'burnInSubtitle': burnInSubtitle,
    'subtitleFontSizeScale': subtitleFontSizeScale,
    'subtitleFontFamily': subtitleFontFamily,
    'subtitleBold': subtitleBold,
    'subtitleColor': subtitleColor,
    'subtitleBorderColor': subtitleBorderColor,
    'subtitleBorderWidth': subtitleBorderWidth,
    'subtitleShadowColor': subtitleShadowColor,
    'subtitleShadowOffset': subtitleShadowOffset,
    'subtitleBottomMargin': subtitleBottomMargin,
    'subtitleBackgroundOpacity': subtitleBackgroundOpacity,
    'subtitleAssOverride': subtitleAssOverride,
    'subtitleDelaySeconds': subtitleDelaySeconds,
    'subtitleFontPath': subtitleFontPath,
    'defaultSubtitleLang': defaultSubtitleLang,
    'defaultAudioLang': defaultAudioLang,
    'enableGestureSeek': enableGestureSeek,
    'enableGestureVolume': enableGestureVolume,
    'enableGestureBrightness': enableGestureBrightness,
    'enableDoubleTapSeek': enableDoubleTapSeek,
    'doubleTapSeekSeconds': doubleTapSeekSeconds,
    'enableBackgroundPlay': enableBackgroundPlay,
    'enablePiP': enablePiP,
    'enableProgressSync': enableProgressSync,
  };

  factory PlayerSettings.fromJson(Map<String, dynamic> json) {
    return PlayerSettings(
      autoSkipIntro: json['autoSkipIntro'] ?? false,
      autoSkipOutro: json['autoSkipOutro'] ?? false,
      showSkipButton: json['showSkipButton'] ?? true,
      defaultPlaybackSpeed: (json['defaultPlaybackSpeed'] ?? 1.0).toDouble(),
      defaultQuality: json['defaultQuality'] ?? 'auto',
      enableHardwareAcceleration: json['enableHardwareAcceleration'] ?? true,
      playerKernel: json['playerKernel'] ?? 'auto',
      decodeCompatMode: json['decodeCompatMode'] ?? false,
      enableDanmakuByDefault: json['enableDanmakuByDefault'] ?? true,
      danmakuFontSize: json['danmakuFontSize'] ?? 17,
      danmakuOpacity: (json['danmakuOpacity'] ?? 1.0).toDouble(),
      danmakuSpeed: (json['danmakuSpeed'] ?? 12).toDouble(),
      burnInSubtitle: json['burnInSubtitle'] ?? false,
      subtitleFontSizeScale: (json['subtitleFontSizeScale'] ?? 1.0).toDouble(),
      subtitleFontFamily: json['subtitleFontFamily'] ?? 'system',
      subtitleBold: json['subtitleBold'] ?? false,
      subtitleColor: json['subtitleColor'] ?? 0xFFFFFFFF,
      subtitleBorderColor: json['subtitleBorderColor'] ?? 0xCC000000,
      subtitleBorderWidth: (json['subtitleBorderWidth'] ?? 3.0).toDouble(),
      subtitleShadowColor: json['subtitleShadowColor'] ?? 0x80000000,
      subtitleShadowOffset: (json['subtitleShadowOffset'] ?? 2.0).toDouble(),
      subtitleBottomMargin: (json['subtitleBottomMargin'] ?? 0.05).toDouble(),
      subtitleBackgroundOpacity: (json['subtitleBackgroundOpacity'] ?? 0.0).toDouble(),
      subtitleAssOverride: json['subtitleAssOverride'] ?? true,
      subtitleDelaySeconds: (json['subtitleDelaySeconds'] ?? 0.0).toDouble(),
      subtitleFontPath: json['subtitleFontPath'] as String?,
      defaultSubtitleLang: json['defaultSubtitleLang'] as String?,
      defaultAudioLang: json['defaultAudioLang'] as String?,

      enableGestureSeek: json['enableGestureSeek'] ?? true,
      enableGestureVolume: json['enableGestureVolume'] ?? true,
      enableGestureBrightness: json['enableGestureBrightness'] ?? true,
      enableDoubleTapSeek: json['enableDoubleTapSeek'] ?? true,
      doubleTapSeekSeconds: json['doubleTapSeekSeconds'] ?? 10,
      enableBackgroundPlay: json['enableBackgroundPlay'] ?? true,
      enablePiP: json['enablePiP'] ?? true,
      enableProgressSync: json['enableProgressSync'] ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PlayerSettings.fromJsonString(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return PlayerSettings.fromJson(map);
  }
}


