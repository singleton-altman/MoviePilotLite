import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/player_engine.dart';
import '../../models/player_settings.dart';
import '../../utils/app_log.dart';
import '../../theme/app_theme.dart';
import '../subtitle/subtitle_overlay.dart';

/// ExoPlayer 播放器引擎实现（基于 video_player，Android 原生 ExoPlayer）
/// 优势：流媒体协议支持好（HLS/DASH）、自适应码率成熟、系统集成度高
class ExoPlayerEngine implements PlayerEngine {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  double _videoScale = 1.0;
  final ValueNotifier<BoxFit> _fitModeNotifier = ValueNotifier(BoxFit.contain);
  
  /// 外挂字幕管理器（Phase 2：Flutter 层字幕叠加渲染）
  final ExternalSubtitleManager _subtitleManager = ExternalSubtitleManager();
  
  final StreamController<PlayerState> _stateController = StreamController<PlayerState>.broadcast();
  PlayerState _state = const PlayerState(engineType: PlayerEngineType.exo);
  
  StreamSubscription? _positionSub;
  Timer? _positionTimer;

  @override
  PlayerEngineType get engineType => PlayerEngineType.exo;

  @override
  Stream<PlayerState> get stateStream => _stateController.stream;

  @override
  PlayerState get currentState => _state;

  @override
  Widget buildVideoWidget() {
    if (_controller == null || !_isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    return ClipRect(
      child: ValueListenableBuilder<BoxFit>(
        valueListenable: _fitModeNotifier,
        builder: (context, fit, child) {
          return FittedBox(
            fit: fit,
            child: child,
          );
        },
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  void _updateState(PlayerState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  @override
  Future<void> open({
    required String url,
    Map<String, String>? httpHeaders,
    bool autoPlay = true,
  }) async {
    try {
      await _controller?.dispose();
      _isInitialized = false;

      final uri = Uri.parse(url);
      
      if (httpHeaders != null && httpHeaders.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(
          uri,
          httpHeaders: httpHeaders,
        );
      } else if (url.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(uri);
      } else {
        _controller = VideoPlayerController.asset(url);
      }

      await _controller!.initialize();
      _isInitialized = true;

      _controller!.addListener(_onVideoUpdate);

      if (autoPlay) {
        await _controller!.play();
      }

      _updateState(_state.copyWith(
        duration: _controller!.value.duration,
        isPlaying: _controller!.value.isPlaying,
      ));

      // 启动位置更新定时器
      _startPositionTimer();
    } catch (e) {
      AppLog.e('ExoEngine', '打开失败: $e');
      _updateState(_state.copyWith(error: e.toString()));
    }
  }

  void _onVideoUpdate() {
    if (_controller == null || !_isInitialized) return;
    final value = _controller!.value;
    
    _updateState(_state.copyWith(
      isPlaying: value.isPlaying,
      isBuffering: value.isBuffering,
      duration: value.duration,
      position: value.position,
      error: value.errorDescription,
    ));
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_controller != null && _isInitialized && !_stateController.isClosed) {
        final pos = _controller!.value.position;
        final buffered = _controller!.value.buffered.isNotEmpty
            ? _controller!.value.buffered.last.end
            : Duration.zero;
        _updateState(_state.copyWith(
          position: pos,
          buffer: buffered,
        ));
      }
    });
  }

  @override
  Future<void> play() async {
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed);
    _updateState(_state.copyWith(speed: speed));
  }

  @override
  Future<void> setVolume(double volume) async {
    await _controller?.setVolume(volume);
    _updateState(_state.copyWith(volume: volume));
  }

  @override
  Future<void> stop() async {
    await _controller?.pause();
    await _controller?.seekTo(Duration.zero);
  }

  @override
  Future<void> dispose() async {
    _positionTimer?.cancel();
    await _positionSub?.cancel();
    _controller?.removeListener(_onVideoUpdate);
    await _controller?.dispose();
    await _stateController.close();
  }

  @override
  Future<List<Map<String, dynamic>>> getAudioTracks() async {
    if (_controller == null) return [];
    final tracks = await _controller!.getAudioTracks();
    return tracks.map((t) => {
      'id': t.id,
      // 只透传原始字段，不在这里兜底成语言码或 '音轨' ——
      // 拼可读名是 trackDisplayTitle 的职责，这里塞占位串会把它挡掉。
      'title': t.label ?? '',
      'language': t.language ?? '',
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getSubtitleTracks() async {
    // video_player 2.11.1 仍不支持字幕轨 API
    return [];
  }

  @override
  Future<void> setAudioTrack(int index) async {
    if (_controller == null) return;
    final tracks = await _controller!.getAudioTracks();
    if (index >= 0 && index < tracks.length) {
      await _controller!.selectAudioTrack(tracks[index].id);
    }
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    // video_player 不支持切换字幕轨
  }

  @override
  Future<void> applySubtitleStyle(PlayerSettings settings) async {
    // ExoPlayer 引擎的字幕样式由 Flutter 层 SubtitleOverlay 读取 PlayerSettings 渲染
    // 这里无需额外操作，SubtitleOverlay 会响应式更新
  }

  @override
  Future<bool> loadExternalSubtitle(String path) async {
    await _subtitleManager.loadFromFile(path);
    if (_subtitleManager.isLoaded) {
      AppLog.i('ExoEngine', '外挂字幕加载成功: ${_subtitleManager.cues.length} 条, $path');
    } else {
      AppLog.w('ExoEngine', '外挂字幕加载失败: ${_subtitleManager.error}');
    }
    return _subtitleManager.isLoaded;
  }

  @override
  ExternalSubtitleManager get externalSubtitleManager => _subtitleManager;

  @override
  double get videoScale => _videoScale;

  @override
  void setVideoScale(double scale) {
    _videoScale = scale.clamp(1.0, 2.0);
  }

  @override
  BoxFit get fitMode => _fitModeNotifier.value;

  @override
  ValueNotifier<BoxFit> get fitModeNotifier => _fitModeNotifier;

  @override
  void setFitMode(BoxFit mode) {
    _fitModeNotifier.value = mode;
  }

  @override
  Future<Uint8List?> captureFrame() async {
    // video_player 不支持截图
    return null;
  }

  @override
  PlayerEngineCapabilities get capabilities => const PlayerEngineCapabilities(
        supportsFrameCapture: false,
        supportsHardwareDecode: true,
        supportsExternalSubtitle: true,
        supportsTrackSwitching: false,
      );

  /// 获取原始 VideoPlayerController 实例
  VideoPlayerController? get rawController => _controller;
}
