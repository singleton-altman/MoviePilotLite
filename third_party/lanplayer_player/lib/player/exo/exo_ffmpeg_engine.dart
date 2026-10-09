import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../core/player_engine.dart';
import '../../models/player_settings.dart';
import '../../utils/app_log.dart';
import '../../theme/app_theme.dart';
import '../subtitle/subtitle_overlay.dart';
import '../subtitle/libass_bridge.dart';
import 'ffmpeg_audio_extension.dart';

/// ExoPlayer + FFmpeg 音频软解引擎
///
/// 使用 AndroidX Media3 ExoPlayer 作为视频解码器，
/// 通过 FFmpeg 扩展处理 ExoPlayer 不支持的音频格式（TrueHD/DTS-HD/EAC3 等）。
///
/// 与 [ExoPlayerEngine] 的区别：
/// - 音频解码失败时自动切换到 FFmpeg 软解，而非提示用户切换到 MPV
/// - 视频继续使用 MediaCodec 硬件解码，性能不受影响
/// - 通过 MethodChannel + AndroidView 与原生 ExoPlayer 通信
///
/// 参考：
/// - Jellyfin 的 jellyfin-androidx-media（FFmpeg 扩展编译方案）
/// - AndroidX Media3 的 media3-decoder-ffmpeg（Renderer 扩展接口）
class ExoFFmpegEngine implements PlayerEngine {
  // MethodChannel 通信
  static const MethodChannel _channel = MethodChannel('com.lanplayer/exo_ffmpeg');
  // 状态推送：原生 ExoPlayer 事件 + 250ms 定时推（替代 Dart 侧轮询 getState）
  static const EventChannel _stateChannel = EventChannel('com.lanplayer/exo_ffmpeg_state');
  static const String _viewType = 'com.lanplayer/exo_ffmpeg_view';

  bool _isInitialized = false;
  bool _isFFmpegAvailable = false;
  double _videoScale = 1.0;
  final ValueNotifier<BoxFit> _fitModeNotifier = ValueNotifier(BoxFit.contain);
  final ValueNotifier<Size> _videoSizeNotifier = ValueNotifier(const Size(0, 0));

  /// 外挂字幕管理器（Flutter 层字幕叠加渲染）
  final ExternalSubtitleManager _subtitleManager = ExternalSubtitleManager();

  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  PlayerState _state = const PlayerState(engineType: PlayerEngineType.exo);

  StreamSubscription<dynamic>? _stateSub;
  Timer? _positionTimer; // 兜底：EventChannel 不可用时降级到 400ms 轮询
  DateTime _lastPushTime = DateTime.now(); // 最近一次收到原生推送的时间

  @override
  PlayerEngineType get engineType => PlayerEngineType.exo;

  @override
  Stream<PlayerState> get stateStream => _stateController.stream;

  @override
  PlayerState get currentState => _state;

  /// FFmpeg 音频扩展是否可用
  bool get isFFmpegAvailable => _isFFmpegAvailable;

  @override
  Widget buildVideoWidget() {
    if (!_isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    // 使用 PlatformViewLink + AndroidViewSurface（Hybrid Composition 模式）
    // SurfaceView 拥有独立硬件图层，解码器零拷贝直出，4K HDR 性能最优
    return ClipRect(
      child: ValueListenableBuilder<BoxFit>(
        valueListenable: _fitModeNotifier,
        builder: (context, fit, child) {
          return FittedBox(
            fit: fit,
            child: child,
          );
        },
        child: ValueListenableBuilder<Size>(
          valueListenable: _videoSizeNotifier,
          builder: (context, size, child) {
            // 关键修复：PlatformView（Hybrid Composition SurfaceView）会按
            // “Flutter 逻辑尺寸 × devicePixelRatio” 创建原生 Surface。
            // 若直接用视频原始分辨率（4K = 3840×2160），Surface 会变成
            // 10800×6075px，远超 GPU/合成器上限（4096~8192），导致合成
            // 损坏——画面错位、比例错误、两侧出现异常黑边。
            // 这里固定一个适中的“虚拟画布”（保持视频宽高比，高 384 逻辑
            // px ≈ 1080 物理 px），由外层 FittedBox 完成最终缩放，
            // Surface 尺寸始终受控在硬件安全范围内。
            final aspect = (size.width > 0 && size.height > 0)
                ? size.width / size.height
                : 16 / 9;
            const canvasHeight = 384.0; // 虚拟画布高（逻辑 px）
            return SizedBox(
              width: canvasHeight * aspect,
              height: canvasHeight,
              child: child,
            );
          },
          child: AbsorbPointer(
            child: PlatformViewLink(
              viewType: _viewType,
              surfaceFactory: (context, controller) {
                return AndroidViewSurface(
                  controller: controller as AndroidViewController,
                  gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
                  hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                );
              },
              onCreatePlatformView: (params) {
                return PlatformViewsService.initSurfaceAndroidView(
                  id: params.id,
                  viewType: _viewType,
                  layoutDirection: TextDirection.ltr,
                  creationParamsCodec: const StandardMessageCodec(),
                )
                  ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
                  ..create();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> open({
    required String url,
    Map<String, String>? httpHeaders,
    bool autoPlay = true,
  }) async {
    try {
      // 检查 FFmpeg 扩展是否可用
      _isFFmpegAvailable = await FFmpegAudioExtension.isAvailable();
      AppLog.i('ExoFFmpeg', 'FFmpeg 音频扩展可用: $_isFFmpegAvailable');

      // 通过 MethodChannel 创建原生 ExoPlayer 实例
      final result = await _channel.invokeMethod<Map>('open', {
        'url': url,
        'headers': httpHeaders ?? {},
        'autoPlay': autoPlay,
        'enableFFmpeg': _isFFmpegAvailable,
      });

      if (result == null) {
        throw Exception('原生 ExoPlayer 创建失败');
      }

      _isInitialized = true;

      // 获取初始状态
      final durationMs = result['durationMs'] as int? ?? 0;
      final isPlaying = result['isPlaying'] as bool? ?? false;

      _updateState(_state.copyWith(
        duration: Duration(milliseconds: durationMs),
        isPlaying: isPlaying,
      ));

      // 订阅原生状态推送（EventChannel）。原生不可用（旧包）时自动降级到轮询。
      _subscribeStateChannel();
      _startPositionTimer();
      AppLog.i('ExoFFmpeg', '播放已打开: duration=${durationMs}ms');
    } catch (e, st) {
      AppLog.e('ExoFFmpeg', '打开失败: $e');
      AppLog.w('ExoFFmpeg', '打开失败堆栈: $st');
      _updateState(_state.copyWith(error: e.toString()));
      // 向上抛出，让 PlayerManager 捕获并自动回退到 MPV 内核
      rethrow;
    }
  }

  void _updateState(PlayerState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  /// 订阅原生 EventChannel 状态推送（事件 + 250ms 定时）
  void _subscribeStateChannel() {
    _stateSub?.cancel();
    _stateSub = _stateChannel.receiveBroadcastStream().listen(
      (data) {
        if (data is Map && _isInitialized && !_stateController.isClosed) {
          _lastPushTime = DateTime.now();
          _applyStateMap(Map<String, dynamic>.from(data));
        }
      },
      onError: (_) {
        // EventChannel 不可用（原生未实现），依赖兜底轮询
      },
    );
  }

  /// 将原生状态 Map 应用到 _state（EventChannel 推送与 getState 轮询共用）
  void _applyStateMap(Map<String, dynamic> result) {
    final vw = result['videoWidth'] as int? ?? 0;
    final vh = result['videoHeight'] as int? ?? 0;
    // 视频尺寸变化时更新 _videoSizeNotifier（FittedBox 据此缩放）
    if (vw > 0 && vh > 0) {
      final newSize = Size(vw.toDouble(), vh.toDouble());
      if (_videoSizeNotifier.value != newSize) {
        _videoSizeNotifier.value = newSize;
        AppLog.i('ExoFFmpeg', '视频尺寸: ${vw}x$vh');
      }
    }
    _updateState(_state.copyWith(
      isPlaying: result['isPlaying'] as bool? ?? false,
      isBuffering: result['isBuffering'] as bool? ?? false,
      position: Duration(milliseconds: result['positionMs'] as int? ?? 0),
      duration: Duration(milliseconds: result['durationMs'] as int? ?? 0),
      buffer: Duration(milliseconds: result['bufferedMs'] as int? ?? 0),
      speed: (result['speed'] as num?)?.toDouble() ?? 1.0,
      volume: (result['volume'] as num?)?.toDouble() ?? 1.0,
      isHdr: result['isHdr'] as bool? ?? false,
      videoWidth: vw,
      videoHeight: vh,
      // 原生层"有声无画"检测（设备缺解码器时 ExoPlayer 静默只播音频）
      error: result['error'] as String?,
    ));
  }

  /// 兜底轮询：仅当 EventChannel 无推送（约 1s 无事件）时启用，
  /// 保证旧原生包（无 EventChannel）仍可工作。
  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      if (!_isInitialized || _stateController.isClosed) return;
      // 有 EventChannel 推送则跳过轮询（推送间隔 250ms，1s 无推送才轮询兜底）
      if (DateTime.now().difference(_lastPushTime) < const Duration(seconds: 1)) return;
      try {
        final result = await _channel.invokeMethod<Map>('getState');
        if (result != null) {
          _lastPushTime = DateTime.now();
          _applyStateMap(Map<String, dynamic>.from(result));
        }
      } catch (_) {}
    });
  }

  @override
  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  @override
  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  @override
  Future<void> seek(Duration position) async {
    await _channel.invokeMethod('seekTo', {'positionMs': position.inMilliseconds});
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _channel.invokeMethod('setSpeed', {'speed': speed});
    _updateState(_state.copyWith(speed: speed));
  }

  @override
  Future<void> setVolume(double volume) async {
    await _channel.invokeMethod('setVolume', {'volume': volume});
    _updateState(_state.copyWith(volume: volume));
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  @override
  Future<void> dispose() async {
    _positionTimer?.cancel();
    await _stateSub?.cancel();
    _videoSizeNotifier.dispose();
    await _channel.invokeMethod('dispose');
    await _stateController.close();
  }

  @override
  Future<List<Map<String, dynamic>>> getAudioTracks() async {
    final result = await _channel.invokeMethod<List>('getAudioTracks');
    if (result == null) return [];
    return result.map((t) => Map<String, dynamic>.from(t as Map)).toList();
  }

  static const _bitmapSubCodecs = {'application/pgs', 'application/x-pgs', 'pgs_sub', 'hdmv_pgs_subtitle', 'dvd_subtitle', 'dvb_subtitle', 'vobsub'};

  @override
  Future<List<Map<String, dynamic>>> getSubtitleTracks() async {
    final result = await _channel.invokeMethod<List>('getSubtitleTracks');
    if (result == null) return [];
    return result.map((t) {
      final track = Map<String, dynamic>.from(t as Map);
      final codec = (track['codec'] as String?) ?? '';
      track['isBitmap'] = _bitmapSubCodecs.contains(codec.toLowerCase());
      return track;
    }).toList();
  }

  @override
  Future<void> setAudioTrack(int index) async {
    await _channel.invokeMethod('setAudioTrack', {'index': index});
  }

  @override
  Future<void> setSubtitleTrack(int index) async {
    AppLog.i('ExoFFmpeg', '请求切换字幕: index=$index');
    await _channel.invokeMethod('setSubtitleTrack', {'index': index});
    AppLog.i('ExoFFmpeg', '字幕切换完成: index=$index');
  }

  @override
  Future<void> applySubtitleStyle(PlayerSettings settings) async {
    // 外挂字幕走原生 libass 层渲染（含普通字幕）→ 样式改动要同步过去，
    // 否则改字号/颜色只对内封生效、外挂不变
    await LibassBridge.applySettings(settings);
    // 推送字幕样式到原生 SubtitleView（内嵌字幕渲染）
    AppLog.i(
      'ExoFFmpeg',
      '应用字幕样式: scale=${settings.subtitleFontSizeScale}, '
      'bold=${settings.subtitleBold}, borderWidth=${settings.subtitleBorderWidth}, '
      'backgroundOpacity=${settings.subtitleBackgroundOpacity}',
    );
    try {
      await _channel.invokeMethod('setSubtitleStyle', {
        'fontColor': settings.subtitleColor,
        'borderColor': settings.subtitleBorderColor,
        'borderWidth': settings.subtitleBorderWidth,
        'backgroundColor': settings.subtitleBackgroundOpacity > 0
            ? (0x00000000 | ((settings.subtitleBackgroundOpacity * 255).round() << 24))
            : 0,
        'fontSizeScale': settings.subtitleFontSizeScale,
        'bold': settings.subtitleBold,
      });
      AppLog.i('ExoFFmpeg', '字幕样式参数已发送到原生层');
    } catch (e) {
      // 样式推送失败只影响外观，不该以未处理异常的形式打断播放流程
      AppLog.w('ExoFFmpeg', '字幕样式推送失败: $e');
    }
  }

  @override
  Future<bool> loadExternalSubtitle(String path) async {
    await _subtitleManager.loadFromFile(path);
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
    final result = await _channel.invokeMethod<Uint8List>('captureFrame');
    return result;
  }

  @override
  PlayerEngineCapabilities get capabilities => const PlayerEngineCapabilities(
        supportsFrameCapture: true,
        supportsHardwareDecode: true,
        supportsExternalSubtitle: true,
        supportsTrackSwitching: true,
      );
}
