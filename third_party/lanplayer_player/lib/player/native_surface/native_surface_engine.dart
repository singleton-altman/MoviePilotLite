import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/player_engine.dart';
import '../core/mpv_subtitle_options.dart';
import 'mpv_track_list.dart';
import '../../models/player_settings.dart';
import '../../utils/app_log.dart';

/// 定制 libmpv 原生 Surface 引擎（弹幕卡顿根治内核）。
///
/// 视频经 mpv 直渲原生 SurfaceView（vo=gpu-next + gpu-context=android +
/// hwdec=mediacodec），完全绕开 Flutter 纹理管线 —— 视频帧不再引发
/// JNI 交接/GC 风暴，弹幕层独享 Flutter 渲染。
/// 字幕走独立 LibassBridge 叠加（特效完整），mpv 内置字幕关闭。
///
/// 与宿主的通道：MethodChannel('lanplayer/mpv_surface_$viewId')。
/// PlatformView(viewType: 'lanplayer/mpv_surface') 由 Kotlin 侧
/// MpvSurfacePlugin 提供（MainActivity 已注册）。
class NativeSurfaceEngine implements PlayerEngine {
  /// 解码兼容模式（与 MpvEngine 同款默认 true）。
  ///
  /// 直连硬解（mediacodec 零拷贝）在部分机型上走 AImageReader 交接，个别帧会
  /// 交接失败：真机实证（2026-09-27 蓝光 ISO）日志出现
  /// `[mpv/vo/gpu-next/aimagereader] Failed to render buffer: No such file...`
  /// 且解码器只跑 18~22fps、音频反复 underrun —— 而数据供给完全健康
  /// （远端抓取 0 失败、244MB/31s）。copy 路径把解码帧拷回内存再上屏，稳。
  static bool decodeCompatMode = true;

  MethodChannel? _channel;
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  PlayerState _state = const PlayerState(engineType: PlayerEngineType.nativeSurface);
  final ValueNotifier<BoxFit> _fitModeNotifier = ValueNotifier(BoxFit.contain);

  /// mpv 上报的**显示**尺寸（dwidth×dheight），画幅层据此算画布宽高比。
  /// Size.zero = 未知（mpv 未就绪），此时画布退回 16:9。
  final ValueNotifier<Size> _videoSizeNotifier =
      ValueNotifier<Size>(Size.zero);
  double _videoScale = 1.0;
  bool _pendingAutoPlay = false;
  String? _pendingUrl;
  Map<String, String>? _pendingHeaders;

  /// 最近一次字幕样式设置：通道未就绪时先挂起，attach 后补发。
  /// 见 [attachPlatformChannel] 的注释（不补发 = 内核停在 mpv 默认 38px@720）。
  PlayerSettings? _pendingStyle;

  @override
  PlayerEngineType get engineType => PlayerEngineType.nativeSurface;

  @override
  Stream<PlayerState> get stateStream => _stateController.stream;

  @override
  PlayerState get currentState => _state;

  /// PlatformView 创建后由宿主回调绑定通道（此刻才能下发命令）。
  void attachPlatformChannel(int viewId) {
    _channel = MethodChannel('lanplayer/mpv_surface_$viewId');
    _channel!.setMethodCallHandler(_onMethodCall);
    AppLog.i('NativeSurface', 'PlatformView 就绪: viewId=$viewId');
    // attach 到来:若 open() 先行(pending),此刻补发 create
    if (_pendingUrl != null) {
      _createWhenReady(_pendingUrl!, _pendingHeaders, _pendingAutoPlay);
    }
    // 同理补发样式:createEngine 返回时通道往往还没建立(日志实证
    // 「PlatformView 未就绪,create 挂起等待 attach」→「mpv create: ok=true」),
    // 宿主那次 applySubtitleStyle 撞上空通道被丢弃,此后无人重发 ——
    // 内核就一路用 mpv 默认 sub-font-size=38(≈5.3% 屏高),比我们 8% 的基准
    // 小 1.5 倍,真机表现为「字幕很小」。
    final style = _pendingStyle;
    if (style != null) {
      unawaited(_pushSubtitleStyle(style, resent: true));
    }
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onEnded':
        _updateState(_state.copyWith(isPlaying: false));
    }
    return null;
  }

  void _updateState(PlayerState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  Future<void> _createWhenReady(
      String url, Map<String, String>? headers, bool autoPlay) async {
    // PlatformView 由 widget 树 build 驱动(AndroidView 挂载 →
    // onPlatformViewCreated → attachPlatformChannel)。open() 先于 view
    // 创建时仅保持 pending,由 attach 回调触发 create —— 严禁超时放弃:
    // 放弃后 attach 到来时 pending 已清,视频永远不播(首版实证)。
    if (_channel == null) {
      AppLog.i('NativeSurface', 'PlatformView 未就绪,create 挂起等待 attach');
      return;
    }
    try {
      final ok = await _channel!.invokeMethod<bool>('create', {
        'url': url,
        'headers': headers,
        'autoPlay': autoPlay,
        // 硬解路径由 Dart 侧决定（Kotlin 的 create 接受 hwdec 参数）：
        // 直连 vs copy 的差别在真机上很实在，见 decodeCompatMode 的注释
        'hwdec': decodeCompatMode ? 'mediacodec-copy' : 'mediacodec',
      });
      AppLog.i('NativeSurface', 'mpv create: ok=$ok url=${url.length > 60 ? '…' : url}');
      _startPolling();
    } catch (e) {
      AppLog.e('NativeSurface', 'mpv create 失败: $e');
      _updateState(_state.copyWith(error: e.toString()));
    }
  }

  Timer? _pollTimer;
  bool _loggedFirstState = false;
  int _pollTicks = 0;
  void _startPolling() {
    _pollTimer?.cancel();
    // 状态回读：Kotlin 侧一次把 mpv 的原始属性字符串吐回来，换算与决策全在
    // Dart(NativeSurfaceSnapshot) —— 属性名/单位只有一处，可被单测覆盖。
    // 画布宽高比靠 dwidth/dheight，所以这份快照同时是**画幅**的数据源；
    // 位置/时长驱动进度条与下一集倒计时。
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final channel = _channel;
      if (channel == null) return;
      try {
        final raw =
            await channel.invokeMethod<Map<dynamic, dynamic>>('getPlaybackState');
        if (raw == null) return;
        final snap = NativeSurfaceSnapshot.fromRaw(raw);
        if (snap.videoSize != _videoSizeNotifier.value) {
          _videoSizeNotifier.value = snap.videoSize;
          // 画布尺寸（逻辑 px）与 Kotlin 侧 surfaceChanged 打印的 Surface 尺寸
          // （物理 px = 逻辑 × DPR）互为对照 —— 画幅再出问题时一眼看出是哪一侧。
          final canvas = nativeSurfaceCanvasSize(snap.videoSize);
          AppLog.i('NativeSurface',
              '画幅更新: 视频 ${snap.videoSize.width.round()}×${snap.videoSize.height.round()} '
              '→ 画布 ${canvas.width.toStringAsFixed(1)}×${canvas.height.toStringAsFixed(0)} 逻辑px');
        }
        if (!_loggedFirstState && snap.duration > Duration.zero) {
          // 一次性:证明 getPlaybackState 链路通(时长/画幅都到 Dart 了)。
          // 画幅再出问题时,这行日志直接区分「mpv 没报尺寸」与「widget 没用上」。
          _loggedFirstState = true;
          AppLog.i('NativeSurface', '状态回读就绪: 时长 ${snap.duration.inSeconds}s');
        }
        _updateState(_state.copyWith(
          position: snap.position,
          duration: snap.duration,
          isPlaying: snap.isPlaying ?? _state.isPlaying,
          videoWidth: snap.videoSize.width.round(),
          videoHeight: snap.videoSize.height.round(),
          // 音量/倍速必须回读：宿主每个状态帧都执行 `_volume/_speed =
          // state.xxx`，缺了就会把用户刚设的值打回默认（真机实证：原生内核下
          // 音量条自己跳到 100%，切换引擎时又按这个值 setVolume 回去）
          volume: snap.volume ?? _state.volume,
          speed: snap.speed ?? _state.speed,
          // 缓冲位置：进度条的缓冲区间靠它（此前一直没回，所以缓冲条永远空着 ——
          // 缓存其实一直在工作，mpv 的 demuxer 缓存被 4MB 大块抓取灌得满满的）
          buffer: snap.buffered,
        ));
        // 每 ~10 秒汇总一次 mpv 侧丢帧统计：卡顿排查时这是"到底哪一环在丢"
        // 的硬指标（解码器丢帧 / 时基不匹配 / 渲染延迟），比看 fps 猜测靠谱
        if (++_pollTicks % 20 == 0) {
          AppLog.i('NativeSurface',
              '播放统计: pos=${snap.position.inSeconds}s 丢帧=${snap.droppedFrames ?? '-'} '
              '时基不匹配=${snap.mistimedFrames ?? '-'} 渲染延迟=${snap.delayedFrames ?? '-'}');
        }
      } catch (_) {}
    });
  }

  @override
  Widget buildVideoWidget() {
    // ⚠️ 必须无条件构建 AndroidView:attachPlatformChannel(通道绑定)
    // 依赖 onPlatformViewCreated 回调,而回调只在 AndroidView 挂载后触发。
    // 若以「控制器未就绪」为由显示 spinner,即成死锁(首版实证)。
    return ValueListenableBuilder<BoxFit>(
      valueListenable: _fitModeNotifier,
      builder: (context, fit, _) => ValueListenableBuilder<Size>(
        valueListenable: _videoSizeNotifier,
        builder: (context, videoSize, _) => nativeSurfaceFrame(
          fit: fit,
          videoSize: videoSize,
          platformView: AndroidView(
            viewType: 'lanplayer/mpv_surface',
            onPlatformViewCreated: attachPlatformChannel,
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
    _pendingUrl = url;
    _pendingHeaders = httpHeaders;
    _pendingAutoPlay = autoPlay;
    await _createWhenReady(url, httpHeaders, autoPlay);
  }

  @override
  Future<void> play() async => _channel?.invokeMethod('command', 'set pause no');

  @override
  Future<void> pause() async =>
      _channel?.invokeMethod('command', 'set pause yes');

  @override
  Future<void> seek(Duration position) async => _channel?.invokeMethod(
      'command', 'seek ${(position.inMilliseconds / 1000).toStringAsFixed(3)} absolute');

  @override
  Future<void> setSpeed(double speed) async {
    // 同 setVolume：立即回写状态，否则会被下一条状态打回默认 1.0x
    _updateState(_state.copyWith(speed: speed));
    await _channel?.invokeMethod(
        'setProperty', {'name': 'speed', 'value': '$speed'});
  }

  @override
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    // 立即回写状态：宿主的状态监听里 `_volume = state.volume`，
    // 不回写就会被下一条状态打回默认 1.0（音量条自己跳的根因）
    _updateState(_state.copyWith(volume: clamped));
    await _channel?.invokeMethod('setProperty', {
      'name': 'volume',
      'value': (clamped * 100).toStringAsFixed(2),
    });
  }

  @override
  Future<void> stop() async => _channel?.invokeMethod('command', 'stop');

  @override
  Future<void> dispose() async {
    _pollTimer?.cancel();
    try {
      await _channel?.invokeMethod('destroy');
    } catch (_) {}
    await _stateController.close();
    _channel = null;
  }

  // ── 轨道 / 字幕：直接复用 libmpv 自己的能力 ──
  //
  // 这个内核就是 libmpv，所以字幕与轨道都交给 mpv 自己做：字幕由内核内置的
  // libass 渲染进视频 Surface（ASS 定位/卡拉OK/动画完整，PGS 位图也能出），
  // 不经过 Flutter 层 —— 弹幕层因此零额外成本（TV 弱芯正是卡在这里）。
  // 轨道列表来自 mpv 的 track-list 属性，解析在 Dart（MpvTrackList，可单测）。

  MpvTrackList _tracks = MpvTrackList.empty;

  /// 拉一次 mpv 轨道列表。宿主在视频就绪（duration>0）后调用 getXxxTracks，
  /// 之后用返回列表的**下标**作为 nativeIndex 切轨。
  Future<MpvTrackList> _refreshTracks() async {
    final channel = _channel;
    if (channel == null) return _tracks;
    try {
      _tracks = MpvTrackList.parse(await channel.invokeMethod<String>('getTracks'));
    } catch (e) {
      AppLog.w('NativeSurface', '轨道列表读取失败: $e');
    }
    return _tracks;
  }

  @override
  Future<List<Map<String, dynamic>>> getAudioTracks() async =>
      (await _refreshTracks()).audio;

  @override
  Future<List<Map<String, dynamic>>> getSubtitleTracks() async =>
      (await _refreshTracks()).subtitle;

  @override
  Future<void> setAudioTrack(int index) =>
      _selectTrack('aid', index, (t) => t.audio);

  @override
  Future<void> setSubtitleTrack(int index) =>
      _selectTrack('sid', index, (t) => t.subtitle);

  /// 切轨：index 是 [getAudioTracks]/[getSubtitleTracks] 的列表下标（宿主约定），
  /// -1 = 关闭。下标要换成 mpv 的真实 id 再下发 —— 外挂轨/未选中轨会让两者错位。
  Future<void> _selectTrack(
    String property,
    int index,
    List<Map<String, dynamic>> Function(MpvTrackList) pick,
  ) async {
    final channel = _channel;
    if (channel == null) {
      AppLog.w('NativeSurface', '切轨丢弃(通道未就绪): $property[$index]');
      return;
    }
    if (index < 0) {
      await channel.invokeMethod('setProperty', {'name': property, 'value': 'no'});
      return;
    }
    var tracks = pick(_tracks);
    if (index >= tracks.length) {
      // 列表还没拉过（宿主先切轨后拉列表）：补拉一次，避免静默失败
      tracks = pick(await _refreshTracks());
      if (index >= tracks.length) {
        AppLog.w('NativeSurface', '切轨越界: $property[$index]，共 ${tracks.length} 条');
        return;
      }
    }
    await channel.invokeMethod(
        'setProperty', {'name': property, 'value': '${tracks[index]['id']}'});
  }

  @override
  Future<void> applySubtitleStyle(PlayerSettings settings) async {
    // 无论通道是否就绪都记住：通道晚到时由 attachPlatformChannel 补发
    _pendingStyle = settings;
    await _pushSubtitleStyle(settings, resent: false);
  }

  /// 逐项下发到 mpv。映射表与 MpvEngine 共用一份：两个内核跑的都是 libmpv，
  /// 同一份设置必须映射出逐项相同的选项（否则内核间字幕大小/位置漂移）。
  Future<void> _pushSubtitleStyle(PlayerSettings settings,
      {required bool resent}) async {
    final channel = _channel;
    final options = mpvSubtitleStyleOptions(settings);
    if (channel == null) {
      AppLog.w('NativeSurface',
          '字幕样式待补发(通道未就绪): ${options.length} 项，attach 后自动下发');
      return;
    }
    for (final entry in options.entries) {
      try {
        await channel
            .invokeMethod('setProperty', {'name': entry.key, 'value': entry.value});
      } catch (_) {}
    }
    AppLog.i('NativeSurface',
        '字幕样式已应用${resent ? '(补发)' : ''}: ${options.length} 项');
  }

  @override
  Future<bool> loadExternalSubtitle(String path) async {
    final channel = _channel;
    if (channel == null) {
      AppLog.w('NativeSurface', '外挂字幕未加载(通道未就绪): $path');
      return false;
    }
    // sub-add select：外挂 ASS/SSA 同样由内核 libass 出特效，
    // 且与 mpv 内核走同一条路径（宿主已有对应护栏）。
    // ⚠️ 这里不能像 Exo 那样补一发 sid=no —— mpv 的 sid=no 会把刚加的外挂轨
    // 一起隐藏掉（player_screen 里有同款注释）。
    final tracksBefore = _tracks.subtitle.length;
    final ok =
        await channel.invokeMethod<bool>('command', 'sub-add "$path" select') ?? false;
    if (!ok) {
      // 真机实证:这条命令曾经"看起来成功但内核没有新轨"（宿主无从判断），
      // 现在失败必定留痕，现场可直接区分「加载失败」与「加载了但没显示」
      AppLog.e('NativeSurface', '外挂字幕加载失败: sub-add 返回 false, path=$path');
      return false;
    }
    await _refreshTracks(); // 外挂轨也要进字幕列表
    // 条数必须增加:mpv 每次 sub-add 都会追加一条 sid，没增加说明命令被吞了
    AppLog.i('NativeSurface',
        '外挂字幕已进内核: ${_tracks.subtitle.length} 条字幕轨(加载前 $tracksBefore)');
    return true;
  }

  @override
  dynamic get externalSubtitleManager => null;

  @override
  double get videoScale => _videoScale;

  @override
  void setVideoScale(double scale) => _videoScale = scale.clamp(1.0, 2.0);

  @override
  BoxFit get fitMode => _fitModeNotifier.value;

  @override
  ValueNotifier<BoxFit> get fitModeNotifier => _fitModeNotifier;

  @override
  void setFitMode(BoxFit mode) => _fitModeNotifier.value = mode;

  @override
  Future<Uint8List?> captureFrame() async => null;

  @override
  PlayerEngineCapabilities get capabilities => const PlayerEngineCapabilities(
        supportsFrameCapture: false,
        supportsHardwareDecode: true,
        supportsExternalSubtitle: true,
        supportsTrackSwitching: true,
      );
}

// ────────────────────────────── 画幅层 ──────────────────────────────

/// 虚拟画布高度（逻辑 px）。对照 ExoFFmpegEngine：PlatformView 的原生 Surface
/// 按「Flutter 逻辑尺寸 × devicePixelRatio」创建，直接用片源原始分辨率
/// （4K = 3840×2160）会把 Surface 撑到合成器上限之上，出现画面错位/异常黑边。
/// 固定画布高度、由外层 FittedBox 完成最终缩放，Surface 尺寸始终受控。
const double kNativeSurfaceCanvasHeight = 384.0;

/// 按视频显示宽高比算画布尺寸；尺寸未知时退回 16:9（与 Exo 内核同款兜底）。
Size nativeSurfaceCanvasSize(Size videoSize) {
  final aspect = (videoSize.width > 0 && videoSize.height > 0)
      ? videoSize.width / videoSize.height
      : 16 / 9;
  return Size(kNativeSurfaceCanvasHeight * aspect, kNativeSurfaceCanvasHeight);
}

/// 画幅层。与 [ExoFFmpegEngine.buildVideoWidget] 同构，两个内核的画幅行为
/// 因此逐像素一致：
/// - `fit` 直传 FittedBox（旧实现把 5 种模式压成 contain/fill 两种，
///   「填充/适配宽度/适配高度」全变成拉伸）；
/// - `ClipRect` 裁掉 cover/fitWidth/fitHeight 放大后的溢出；
/// - 画布宽高比跟随视频真实显示尺寸（旧实现写死 1920×1080，宽银幕片源
///   被 mpv 在画布内二次 letterbox，黑边比 Exo 多一圈）；
/// - `AbsorbPointer` 让原生视图不吃指针事件 —— 否则 Flutter 命中测试判定
///   PlatformView 被命中就把事件转发给原生视图，播放页的单击呼出控制条在
///   画幅内完全失效（真机实证：只有画幅外能点出来）。
@visibleForTesting
Widget nativeSurfaceFrame({
  required Widget platformView,
  required BoxFit fit,
  required Size videoSize,
}) {
  return ClipRect(
    child: FittedBox(
      fit: fit,
      child: SizedBox.fromSize(
        size: nativeSurfaceCanvasSize(videoSize),
        child: AbsorbPointer(child: platformView),
      ),
    ),
  );
}

/// mpv 单次状态快照。Kotlin 侧原样回传 mpv 属性字符串，换算全部收敛在这里 ——
/// 单位（`time-pos`/`duration` 是**秒**）与布尔约定（`pause` 是 yes/no）只有一处，
/// 可被单测覆盖。
class NativeSurfaceSnapshot {
  const NativeSurfaceSnapshot({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying,
    this.videoSize = Size.zero,
    this.volume,
    this.speed,
    this.droppedFrames,
    this.mistimedFrames,
    this.delayedFrames,
    this.buffered = Duration.zero,
  });

  final Duration position;
  final Duration duration;

  /// null = 未知（属性缺失或非 yes/no），调用方应保持原状态，
  /// 而不是把「没读到」当成「暂停了」。
  final bool? isPlaying;

  /// mpv 的显示尺寸（dwidth×dheight，已含 PAR 与旋转）。
  /// Size.zero = 未知（mpv idle/未就绪）。
  final Size videoSize;

  /// mpv 音量百分比换算成宿主的 0-1。
  /// null = 读不到 → 调用方保持当前音量（当 0 会直接静音）。
  final double? volume;

  /// 播放倍速（1.0 = 原速）。
  /// null = 读不到 → 调用方保持当前倍速。
  final double? speed;

  /// mpv 侧丢帧统计（供诊断"卡顿到底卡在哪一环"）：
  /// 解码器丢帧 / 时基不匹配帧 / 渲染延迟帧。null = 读不到。
  final int? droppedFrames;
  final int? mistimedFrames;
  final int? delayedFrames;

  /// 已缓冲到的**绝对位置**（mpv 的 demuxer-cache-time，单位秒）。
  /// 进度条的缓冲区间按 `buffer / duration` 画，所以需要的是绝对位置而不是
  /// "还剩多少秒"。读不到/缓存为空时为零 = 不画缓冲区间。
  final Duration buffered;

  factory NativeSurfaceSnapshot.fromRaw(Map<dynamic, dynamic> raw) {
    return NativeSurfaceSnapshot(
      position: _seconds(raw['timePos']),
      duration: _seconds(raw['duration']),
      isPlaying: _playing(raw['paused']),
      videoSize: _displaySize(raw['dwidth'], raw['dheight']),
      volume: _volume(raw['volume']),
      speed: _speed(raw['speed']),
      droppedFrames: _count(raw['dropFrameCount']),
      mistimedFrames: _count(raw['mistimedFrameCount']),
      delayedFrames: _count(raw['delayedFrameCount']),
      buffered: _seconds(raw['cacheTime']),
    );
  }

  static Duration _seconds(Object? raw) {
    final seconds = double.tryParse(raw?.toString() ?? '');
    if (seconds == null || !seconds.isFinite || seconds <= 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: (seconds * 1000).round());
  }

  static bool? _playing(Object? raw) {
    switch (raw?.toString()) {
      case 'yes':
        return false; // pause=yes → 未播放
      case 'no':
        return true;
      default:
        return null;
    }
  }

  static Size _displaySize(Object? rawWidth, Object? rawHeight) {
    final width = int.tryParse(rawWidth?.toString() ?? '') ?? 0;
    final height = int.tryParse(rawHeight?.toString() ?? '') ?? 0;
    if (width <= 0 || height <= 0) return Size.zero;
    return Size(width.toDouble(), height.toDouble());
  }

  /// mpv 的 `volume` 是 0-100 的百分比（volume-max 可到 130），映射成宿主的
  /// 0-1；读不到返回 null（宿主保持当前音量，不能当 0 —— 那会直接静音）。
  static double? _volume(Object? raw) {
    final percent = double.tryParse(raw?.toString() ?? '');
    if (percent == null || !percent.isFinite) return null;
    return (percent / 100).clamp(0.0, 1.0).toDouble();
  }

  /// 播放倍速：非正值（mpv 暂停时会报 0）与读不到都返回 null。
  static double? _speed(Object? raw) {
    final speed = double.tryParse(raw?.toString() ?? '');
    if (speed == null || !speed.isFinite || speed <= 0) return null;
    return speed;
  }

  /// 计数器类属性：非负整数，其余一律 null（读不到就别假装是 0）
  static int? _count(Object? raw) {
    final value = int.tryParse(raw?.toString() ?? '');
    if (value == null || value < 0) return null;
    return value;
  }
}
