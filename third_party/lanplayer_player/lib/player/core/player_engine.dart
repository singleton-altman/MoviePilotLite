import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import '../../models/player_settings.dart';

/// 播放器内核类型
enum PlayerEngineType {
  exo,
  auto,

  /// 定制 libmpv 原生 Surface 直渲（弹幕卡顿根治内核，实验）
  nativeSurface;

  String get label {
    switch (this) {
      case PlayerEngineType.exo:
        return 'ExoPlayer';
      case PlayerEngineType.auto:
        return '自动选择';
      case PlayerEngineType.nativeSurface:
        return 'MPV原生(Surface)';
    }
  }

  String get shortLabel {
    switch (this) {
      case PlayerEngineType.exo:
        return 'Exo';
      case PlayerEngineType.auto:
        return '自动';
      case PlayerEngineType.nativeSurface:
        return '原生';
    }
  }
}

/// 播放器状态
class PlayerState {
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final double speed;
  final double volume;
  final String? error;
  final PlayerEngineType engineType;
  final bool isHdr;
  final int videoWidth;
  final int videoHeight;

  const PlayerState({
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = Duration.zero,
    this.speed = 1.0,
    this.volume = 1.0,
    this.error,
    this.engineType = PlayerEngineType.nativeSurface,
    this.isHdr = false,
    this.videoWidth = 0,
    this.videoHeight = 0,
  });

  PlayerState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    Duration? buffer,
    double? speed,
    double? volume,
    String? error,
    PlayerEngineType? engineType,
    bool? isHdr,
    int? videoWidth,
    int? videoHeight,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffer: buffer ?? this.buffer,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      error: error ?? this.error,
      engineType: engineType ?? this.engineType,
      isHdr: isHdr ?? this.isHdr,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
    );
  }
}

/// 播放器内核能力表 — UI 按能力降级，避免出现「点了没反应」的假功能
class PlayerEngineCapabilities {
  /// 是否支持截取当前视频帧（mpv 受 media_kit 限制不支持）
  final bool supportsFrameCapture;

  /// 是否支持硬件解码
  final bool supportsHardwareDecode;

  /// 是否支持外挂字幕
  final bool supportsExternalSubtitle;

  /// 是否支持音频/字幕轨动态切换
  final bool supportsTrackSwitching;

  const PlayerEngineCapabilities({
    this.supportsFrameCapture = false,
    this.supportsHardwareDecode = true,
    this.supportsExternalSubtitle = true,
    this.supportsTrackSwitching = true,
  });
}

/// 播放器内核抽象接口
/// 所有播放器实现（MPV/ExoPlayer）必须实现此接口
abstract class PlayerEngine {
  /// 当前内核类型
  PlayerEngineType get engineType;

  /// 状态流
  Stream<PlayerState> get stateStream;

  /// 当前状态
  PlayerState get currentState;

  /// 视频渲染 Widget
  Widget buildVideoWidget();

  /// 初始化并打开媒体
  Future<void> open({
    required String url,
    Map<String, String>? httpHeaders,
    bool autoPlay = true,
  });

  /// 播放
  Future<void> play();

  /// 暂停
  Future<void> pause();

  /// 跳转
  Future<void> seek(Duration position);

  /// 设置播放速度
  Future<void> setSpeed(double speed);

  /// 设置音量 (0.0 - 1.0)
  Future<void> setVolume(double volume);

  /// 停止播放
  Future<void> stop();

  /// 释放资源
  Future<void> dispose();

  /// 获取音轨列表
  Future<List<Map<String, dynamic>>> getAudioTracks();

  /// 获取字幕轨列表
  Future<List<Map<String, dynamic>>> getSubtitleTracks();

  /// 设置音轨
  Future<void> setAudioTrack(int index);

  /// 设置字幕轨
  Future<void> setSubtitleTrack(int index);

  /// 应用字幕样式（运行时可调用，立即生效）
  /// MPV 引擎通过 libmpv sub-* 参数实时生效
  /// ExoPlayer 引擎暂不支持（Phase 2/3 实现）
  Future<void> applySubtitleStyle(PlayerSettings settings);

  /// 加载外挂字幕文件
  /// MPV 引擎通过 sub-add 命令加载到原生层
  /// ExoPlayer 引擎在 Flutter 层叠加渲染（Phase 2）
  /// 返回 true 表示加载成功
  Future<bool> loadExternalSubtitle(String path);

  /// 获取当前外挂字幕管理器（仅 ExoPlayer 引擎使用 Flutter 层渲染时有效）
  /// MPV 引擎返回 null（字幕由原生层渲染）
  dynamic get externalSubtitleManager => null;

  /// 当前视频缩放比例 (1.0 = contain, >1.0 = zoom in/cover)
  double get videoScale;

  /// 设置视频缩放比例
  void setVideoScale(double scale);

  /// 当前画幅模式
  BoxFit get fitMode;

  /// 画幅模式变化通知
  ValueNotifier<BoxFit> get fitModeNotifier;

  /// 设置画幅模式
  void setFitMode(BoxFit mode);

  /// 截取当前帧
  Future<Uint8List?> captureFrame();

  /// 内核能力表
  PlayerEngineCapabilities get capabilities;
}
