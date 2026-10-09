import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../player/core/player_engine.dart';
import '../../player/core/prepare_phase.dart';
import '../../player/subtitle/libass_style.dart';
import '../../player/subtitle/ass_style_normalizer.dart';
import '../../player/core/player_manager.dart';
import '../../player/subtitle/subtitle_overlay.dart';
import '../../player/subtitle/libass_bridge.dart';
import '../../player/danmaku/danmaku_controller.dart';
import '../../player/danmaku/danmaku_renderer.dart';
import '../../player/danmaku/danmaku_models.dart';
import '../../theme/app_theme.dart';
import '../../models/media_models.dart';
import '../../services/media_server_service.dart';
import '../../services/danmaku_service.dart';
import '../../services/danmaku_matcher.dart';
import '../../services/danmaku_match_pipeline.dart';
import '../../widgets/danmaku_candidate_list.dart';
import '../../services/storage_service.dart';
import '../../database/database_service.dart';
import '../../services/http_client.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_log.dart';
import '../../utils/periodic_timer.dart';
import '../../utils/animation_config.dart';
import '../../theme/motion.dart';
import '../../utils/chinese_converter.dart';
import '../../utils/track_titles.dart';
import 'package:crypto/crypto.dart';
import '../../widgets/online_subtitle_sheet.dart';
import '../../services/opensubtitles_service.dart';
import '../../widgets/double_tap_ripple.dart';
import '../../widgets/custom_progress_bar.dart';
import '../../widgets/skip_button.dart';
import '../../widgets/track_right_panel.dart';
import '../../widgets/tap_feedback.dart';
import '../../widgets/player_side_panel.dart';
import '../../widgets/more_right_panel.dart';
import '../../widgets/right_panel_host.dart';
import 'subtitle_style_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  static const routeName = '/player';

  final MediaItem media;
  final String streamUrl;
  final Map<String, String>? httpHeaders;

  /// 服务器转码备用流（remux：视频拷贝+音频转码）。直连失败时自动切换。
  final String? transcodeUrl;
  final List<MediaItem>? episodes;
  final MediaServerService? service;
  final MediaServer? server;
  final int? resumePositionMs;

  const PlayerScreen({
    super.key,
    required this.media,
    // 允许为空：入口不再预解析（点即进播放页），由播放页自己解析地址
    this.streamUrl = '',
    this.httpHeaders,
    this.transcodeUrl,
    this.episodes,
    this.service,
    this.server,
    this.resumePositionMs,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  PlayerEngine? _engine;
  PlayerEngineType _engineType = PlayerEngineType.nativeSurface;
  StreamSubscription<PlayerState>? _stateSub;
  int _engineKey = 0; // 引擎切换时增加，强制视频 widget 重建

  bool _controlsVisible = true;
  bool _isPlaying = false;
  Timer? _progressTimer;
  Timer? _uiUpdateTimer;
  DateTime _lastStateTime = DateTime.now();
  int _lastReportedMs = 0;
  bool _playbackStartReported = false;
  bool _resumeApplied = false;
  bool _isBuffering = false;
  int _streamTick = 0;
  int _uiTick = 0;
  TapDownDetails? _doubleTapDetails;
  bool _showEpisodePanel = false;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  String _currentQuality = 'auto';   // 当前播放画质（播放器内可切换）
  // 当前实际播放的流地址：切集/切画质后 widget.streamUrl 已过时，
  // 服务端字幕下载需用它提取当前集的 MediaSourceId（否则会用上一集的
  // MediaSourceId 构造字幕 URL → 404 → "字幕下载失败"）。
  String _currentStreamUrl = '';
  bool _controlsLocked = false;      // 播放器锁定（防误触，Streama/CapyPlayer 同款）
  bool _danmakuEnabled = true;
  String? _initError;
  BoxFit _currentFitMode = BoxFit.contain;
  bool _isAutoFit = true; // 默认自适应画幅
  bool _isSeeking = false;
  // ── 直连失败 → 转码回退 ──
  // 服务器 PlaybackInfo 给的转码备用流（detail 传入；换源/换画质时更新）。
  // 直连报错（Source error / 解码器失败）时自动切过去，只试一次。
  String? _transcodeFallbackUrl;
  bool _transcodeTried = false;
  // ── libass 原生 ASS 特效渲染（外挂 ASS 专用,TV 端同款管线）──
  // Exo 内核播外挂 ASS 时接管渲染:RenderLoop 每 200ms 出一帧 ARGB,
  // 内容变化才解码/通知。MPV 内核不用（libmpv 内置 libass 已渲染特效）。
  final ValueNotifier<ui.Image?> _libassImage = ValueNotifier<ui.Image?>(null);
  Timer? _libassRenderTimer;
  bool _libassActive = false;
  bool _libassRendering = false;
  Uint8List? _libassLastPixels;
  int _libassWidth = 1920;
  int _libassHeight = 1080;

  final List<_FitModeOption> _fitModeOptions = [
    _FitModeOption(null, '自适应', Icons.auto_fix_high_rounded), // null = 自适应
    _FitModeOption(BoxFit.contain, '原始', Icons.aspect_ratio_rounded),
    _FitModeOption(BoxFit.cover, '填充', Icons.crop_square_rounded),
    _FitModeOption(BoxFit.fill, '拉伸', Icons.fit_screen_rounded),
    _FitModeOption(BoxFit.fitWidth, '适配宽度', Icons.align_horizontal_left_rounded),
    _FitModeOption(BoxFit.fitHeight, '适配高度', Icons.align_vertical_top_rounded),
  ];

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffer = Duration.zero;
  double _speed = 1.0;
  double _brightness = 1.0;
  double _volume = 1.0;
  // 画幅模式已替代简单缩放，_videoScale 不再使用

  Timer? _hideTimer;
  Timer? _brightnessHideTimer;
  Timer? _volumeHideTimer;

  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0];
  int _currentSpeedIndex = 2;

  double _screenWidth = 0;
  double _screenHeight = 0;
  DanmakuDisplaySettings _cachedDisplay = const DanmakuDisplaySettings();
  late final DanmakuController _danmakuController;

  int _currentSubtitleIndex = -1;
  List<Map<String, dynamic>> _subtitleTracks = [];
  // 是否已自动启用过文件标记的默认字幕轨（每个播放会话只自动一次，
  // 防止重复触发下载；切集时重置以便新一集自动启用其默认轨）
  bool _autoDefaultSubtitleApplied = false;
  // 是否已后台预取过常用服务端字幕（默认/中文/英文）；切集时重置以便新一集预取
  bool _subtitlePrefetched = false;
  // 用户是否显式关闭过字幕：视频本身带硬字幕（烧录进画面）的片源，
  // 再叠加软字幕就是双层。用户关过一次后本会话记住，不再自动启用。
  bool _userDisabledSubtitles = false;
  // 去重后的完整字幕轨列表（过滤前），供"显示全部字幕"展开用
  List<Map<String, dynamic>> _fullSubtitleTracks = [];
  // 是否已展开显示全部字幕轨（默认只显示 中/英/默认轨）
  bool _showAllSubtitleTracks = false;
  // 位图字幕（PGS/SUP）提示是否已弹出（轨道轮询会多次进入此块，只提示一次）
  bool _bitmapWarned = false;
  int _currentAudioIndex = 0;
  List<Map<String, dynamic>> _audioTracks = [];

  // 外挂字幕状态（Phase 2）
  bool _externalSubtitleLoaded = false;
  // 服务端字幕下载中（Emby/NAS 首次按需提取内嵌字幕可能很慢，给用户可见反馈）
  bool _serverSubtitleLoading = false;

  bool _isDisposed = false;

  // ── 进入播放的准备阶段（加载层）──
  // 加载层**延时**出现：普通文件点击即开（解析只是一次 API 往返），立刻转圈会
  // 凭空多一次闪烁；只有 ISO 解析/服务器转码这类真要等几秒的场景才看得见。
  PreparePhase? _preparePhase;
  bool _prepareVisible = false;
  Timer? _prepareDelayTimer;
  Timer? _prepareTimeoutTimer;

  /// 该媒体是不是原盘 ISO（决定加载文案是"正在解析原盘…"还是"正在连接服务端…"）
  bool get _mediaLooksLikeIso {
    final vt = widget.media.videoTracks;
    if (vt == null || vt.isEmpty) return false;
    return isIsoMediaSource(vt.first);
  }

  void _enterPreparePhase(PreparePhase phase) {
    _preparePhase = phase;
    AppLog.i('Player', '准备阶段: ${preparePhaseLabel(phase)}');
    _prepareDelayTimer ??= Timer(prepareOverlayDelay(phase), () {
      if (mounted && !_isDisposed && _preparePhase != null) {
        setState(() => _prepareVisible = true);
      }
    });
    // 兜底：服务端/网络异常时不能让用户对着转圈干等
    _prepareTimeoutTimer ??= Timer(const Duration(seconds: 20), () {
      if (!mounted || _isDisposed || _preparePhase == null) return;
      AppLog.w('Player', '准备阶段超时（20s）');
      setState(() {
        _prepareVisible = false;
        _preparePhase = null;
        _initError = '打开超时：服务端或网络响应过慢，请重试';
      });
    });
  }

  /// 准备结束：内核已拿到流（有时长）或已开播
  void _exitPreparePhase() {
    _prepareDelayTimer?.cancel();
    _prepareDelayTimer = null;
    _prepareTimeoutTimer?.cancel();
    _prepareTimeoutTimer = null;
    if (_preparePhase == null) return;
    if (_prepareVisible) {
      setState(() {
        _prepareVisible = false;
        _preparePhase = null;
      });
    } else {
      _preparePhase = null;
    }
  }
  bool _cleanupDone = false;
  bool _tracksLoaded = false;
  bool _showedAudioError = false;
  bool _danmakuLoading = false; // 弹幕加载中标志位，防止重复请求

  /// 已加载的弹幕条数与来源名，供弹幕面板首屏的「当前匹配」卡显示。
  int _loadedDanmakuCount = 0;
  String? _loadedDanmakuSource;

  // ── 弹幕候选（双路并行匹配产物，面板首屏/搜索子面板共用展示与切换） ──
  List<DanmakuMatchCandidate> _danmakuCandidates = const [];
  String? _selectedCandidateKey;
  final Map<String, DanmakuService> _danmakuServices = {};

  // ── 当前播放集数跟踪（切集后 widget.media 已过时） ──
  int _currentEpisodeIndex = 0;
  MediaItem? _currentMedia;
  MediaItem get _activeMedia => _currentMedia ?? widget.media;

  /// 是否有可用的选集列表（上一集/下一集按钮据此显示）
  bool get _hasEpisodeList {
    final eps = widget.episodes;
    return eps != null && eps.isNotEmpty && _currentEpisodeIndex >= 0;
  }

  /// 左下角视频信息：分辨率 · 编码 · 码率 · 帧率（数据来自服务端 MediaStreams）
  String? get _videoMetadata {
    final tracks = _activeMedia.videoTracks;
    if (tracks == null || tracks.isEmpty) return null;
    final t = tracks.first;
    final w = t['Width'] as num?;
    final h = t['Height'] as num?;
    final codec = t['Codec']?.toString().toUpperCase();
    final bitrate = t['BitRate'] as num?;
    final fps = t['FrameRate'] as num?;
    final parts = <String>[];
    if (w != null && h != null && w > 0 && h > 0) parts.add('${w.toInt()}×${h.toInt()}');
    if (codec != null && codec.isNotEmpty && codec != 'UNKNOWN') parts.add(codec);
    if (bitrate != null && bitrate > 0) {
      final mbps = bitrate / 1000000;
      parts.add(mbps >= 10 ? '${mbps.round()} Mbps' : '${mbps.toStringAsFixed(1)} Mbps');
    }
    if (fps != null && fps > 0) parts.add('${fps.round()} fps');
    return parts.isEmpty ? null : parts.join(' · ');
  }

  // ── 跳过片头/片尾 ──
  IntroSkip? _introSkip;
  String? _skipButtonLabel;       // '跳过片头' / '跳过片尾' / null
  bool _skipIntroHandled = false; // 本次播放是否已自动跳过片头

  // ── 双击涟漪 ──
  Offset _ripplePosition = Offset.zero;
  bool _rippleIsLeft = true;
  bool _ripplePlayPause = false; // 中间双击=播放/暂停涟漪（非 seek 圆弧）
  IconData _rippleIcon = Icons.pause_rounded;
  int _rippleTrigger = 0;
  bool _showRipple = false;

  // ── 右侧轨道面板 ──
  String? _rightPanelType; // 'audio' / 'subtitle' / null

  // ── 下一集倒计时 ──
  bool _showNextEpisode = false;
  bool _nextEpisodeCancelled = false;
  int _nextEpisodeCountdown = 15;
  Timer? _nextEpisodeTimer;
  // 正在自动切换下一集（防止倒计时回调与位置检测双重触发）
  bool _nextEpisodePlaying = false;
  // 音量持久化（写 SharedPreferences 防抖；亮度变化由手势直接保存）
  Timer? _volBriSaveTimer;
  double _lastSavedVolume = 1.0;

  // ── 进度条 seek 中的临时位置 ──

  // ── 选集面板动画 ──
  late AnimationController _episodePanelController;
  late Animation<Offset> _episodeSlideAnim;
  late Animation<double> _episodeFadeAnim;

  // ── 控制栏显隐动画（顶栏上滑 / 底栏下滑 + 淡出）──
  late AnimationController _controlsController;
  late Animation<double> _controlsAnim;

  // ── 中心播放键扩散光晕（按下时从按钮向外扩散一圈柔和光圈）──
  late AnimationController _playPulseController;

  // ── Trickplay 缩略图 ──
  TrickplayInfo? _trickplayInfo;

  // ── 章节标记（Emby/Jellyfin Chapters API）──
  List<int> _chapterMarkers = [];
  bool _chaptersLoaded = false;

  @override
  void initState() {
    super.initState();
    // 生命周期：退后台暂停引擎（与 TV 端同一规则,见 didChangeAppLifecycleState）
    WidgetsBinding.instance.addObserver(this);
    _currentQuality = ref.read(playerSettingsProvider).defaultQuality;
    _transcodeFallbackUrl = widget.transcodeUrl;
    // ── 选集面板动画初始化 ──
    // 入退场分设时长：退场必须快于入场（用户已经决定关掉它了，
    // 让它慢慢消失只是在挡路）。不设 reverseDuration 时 reverse()
    // 会复用正向时长，这正是改造前的问题。
    _episodePanelController = AnimationController(
      duration: AppMotion.enter,
      reverseDuration: AppMotion.exit,
      vsync: this,
    );
    _episodeSlideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _episodePanelController,
      curve: AppEase.enter,
      reverseCurve: AppEase.exit,
    ));
    _episodeFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _episodePanelController,
        curve: AppEase.enter,
        reverseCurve: AppEase.exit,
      ),
    );
    // ── 控制栏动画初始化（初始为可见）──
    // 同样入慢退快。控制栏藏起来是为了让位给画面，藏得拖沓最烦人。
    _controlsController = AnimationController(
      duration: AppMotion.enter,
      reverseDuration: AppMotion.exit,
      vsync: this,
      value: 1.0,
    );
    _controlsAnim = CurvedAnimation(
      parent: _controlsController,
      curve: AppEase.enter,
      reverseCurve: AppEase.exit,
    );
    // ── 播放键光晕动画控制器（按下时 forward(from:0) 重新扩散）──
    _playPulseController = AnimationController(
      duration: AppMotion.slowMin,
      vsync: this,
    );

    final settings = ref.read(playerSettingsProvider);
    _cachedDisplay = ref.read(danmakuDisplayProvider);
    _danmakuEnabled = settings.enableDanmakuByDefault;
    // 创建弹幕控制器并初始化（屏幕尺寸在 build 中更新）
    _danmakuController = DanmakuController(this);
    _danmakuController.init(
      screenWidth: 0,
      screenHeight: 0,
      config: DanmakuRenderConfig.fromSettings(_cachedDisplay, playbackSpeed: _speed),
    );
    _danmakuController.setEnabled(_danmakuEnabled);
    // 监听弹幕显示设置变化，同步到控制器
    ref.listenManual(danmakuDisplayProvider, (prev, next) {
      _cachedDisplay = next;
      _danmakuController.updateConfig(
        DanmakuRenderConfig.fromSettings(next, playbackSpeed: _speed),
      );
    });
    // 初始化当前集数跟踪（切集后 widget.media 已过时）
    final eps = widget.episodes;
    _currentEpisodeIndex =
        (eps == null || eps.isEmpty) ? 0 : eps.indexWhere((e) => e.id == widget.media.id);
    if (_currentEpisodeIndex < 0) _currentEpisodeIndex = 0;
    _currentMedia = widget.media;
    _initPlayer();
    _loadDanmaku();
    _loadIntroSkip();
    _loadTrickplayInfo();
    _loadChapters();
    // 控制栏初始可见，启动自动隐藏定时器
    _startHideTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 提前获取屏幕尺寸，确保弹幕更新时 _screenWidth != 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenWidth = MediaQuery.of(context).size.width;
        _screenHeight = MediaQuery.of(context).size.height;
        _danmakuController.updateScreenSize(_screenWidth, _screenHeight);
        // 传入设备像素比，确保弹幕位图缓存清晰不发虚
        _danmakuController.setDevicePixelRatio(MediaQuery.of(context).devicePixelRatio);
      }
    });
  }

  @override
  void deactivate() {
    _cleanup();
    super.deactivate();
  }

  /// 退后台（HOME/切应用/锁屏 → paused/hidden/detached）暂停引擎。
  /// 与 TV 端同一规则：人离开了,声音不能还在播;不自动恢复。
  /// inactive（弹窗/权限框瞬间）不暂停,避免误伤。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _engine?.pause();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _prepareDelayTimer?.cancel();
    _prepareDelayTimer = null;
    _prepareTimeoutTimer?.cancel();
    _prepareTimeoutTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  void _cleanup() {
    if (_cleanupDone) return;
    _cleanupDone = true;

    _stopLibass(); // 释放 libass 原生渲染资源(定时器/图像/原生桥)
    _progressTimer?.cancel();
    _uiUpdateTimer?.cancel();
    // 上报最终位置并关闭播放会话
    AppLog.i('Player',
        '_cleanup: 开始收尾 pos=${_position.inMilliseconds}ms itemId=${_activeMedia.id}');
    _reportProgress();
    try {
      final svc = ref.read(currentMediaServerServiceProvider);
      AppLog.i('Player', '_cleanup: svc 类型 = ${svc.runtimeType}');
      if (svc is EmbyService) {
        svc.reportPlaybackStopped(_activeMedia.id,
            positionMs: _position.inMilliseconds);
        AppLog.i('Player', '_cleanup: 已触发 Stopped 上报');
      } else {
        AppLog.w('Player', '_cleanup: svc 非 EmbyService,跳过 Stopped 上报');
      }
    } catch (e) {
      AppLog.e('Player', '_cleanup: 取 svc 失败(ProviderScope 可能已销毁): $e');
    }

    _danmakuController.dispose();

    _toastTimer?.cancel();
    _toastEntry?.remove();
    _toastEntry = null;

    _hideTimer?.cancel();
    _brightnessHideTimer?.cancel();
    _volumeHideTimer?.cancel();
    _nextEpisodeTimer?.cancel();
    _episodePanelController.dispose();
    _controlsController.dispose();
    _playPulseController.dispose();
    _stateSub?.cancel();
    _stateSub = null;
    
    // 移除画幅模式监听
    _engine?.fitModeNotifier.removeListener(_onFitModeChanged);

    try { ScreenBrightness().resetScreenBrightness(); } catch (_) {}

    _engine?.stop();
    final manager = ref.read(playerManagerProvider);
    manager.disposeEngine();
    _engine = null;

    _restoreOrientation();
  }

  // 防重入:快速重试/连点播放时并发 _initPlayer 会在 PlayerManager 里互踩
  bool _initPlayerRunning = false;

  Future<void> _initPlayer() async {
    if (_initPlayerRunning) {
      AppLog.w('Player', '播放初始化进行中,忽略重复触发');
      return;
    }
    _initPlayerRunning = true;
    final manager = ref.read(playerManagerProvider);

    try {
      // 入口不再预解析：地址为空时在这里解析（点即进播放页，等待期有真实进度）
      var url = widget.streamUrl;
      if (url.isEmpty) {
        final svc = widget.service;
        if (svc == null) {
          throw StateError('缺少 service，无法解析流地址');
        }
        final ps = ref.read(playerSettingsProvider);
        _enterPreparePhase(
            _mediaLooksLikeIso ? PreparePhase.openingIso : PreparePhase.resolving);
        url = await svc.getStreamUrl(
          widget.media.id,
          quality: ps.defaultQuality,
          burnInSubtitle: ps.burnInSubtitle,
        );
        if (!mounted || _isDisposed) return; // 解析期间用户可能已退出
        // 直连失败时的转码兜底流：原先在详情页解析后传入，现在这里取
        _transcodeFallbackUrl ??= svc.lastTranscodeUrl;
        AppLog.i('Player',
            '流地址自解析完成（${_mediaLooksLikeIso ? 'ISO原盘' : '普通'}）: ${url.length > 80 ? '${url.substring(0, 80)}…' : url}');
        _enterPreparePhase(PreparePhase.startingEngine);
      }

      _engine = await manager.createEngine(
        url: url,
        httpHeaders: widget.httpHeaders,
        autoPlay: true,
      );
      _engineType = _engine!.engineType;
      _engineKey++;
      _currentStreamUrl = url;

      // 恢复用户音量/亮度：持久化值优先，未设置过则读取系统当前值作为起点，
      // 保证 HUD 与系统实际状态对应（而不是从 100% 起跳）
      await _restoreVolumeBrightness();

      // 监听引擎状态
      _stateSub = _engine!.stateStream.listen((state) {
        if (mounted && !_isDisposed) {
          if (_streamTick++ % 20 == 0) AppLog.i("Player", "stateStream: playing=${state.isPlaying} pos=${state.position.inMilliseconds} dur=${state.duration.inMilliseconds}");
          // 内核已拿到流（有时长）或已开播 → 准备态结束（此后由 _isBuffering 接管）
          if (_preparePhase != null &&
              (state.duration > Duration.zero || state.isPlaying)) {
            _exitPreparePhase();
          }
          // 先同步弹幕时钟与位置 —— 独立于 setState，任何后续异常都不影响弹幕时间轴
          try {
            _danmakuController.updateConfig(
              DanmakuRenderConfig.fromSettings(_cachedDisplay, playbackSpeed: _speed),
            );
            _danmakuController.updateActive(state.position.inMilliseconds);
          } catch (_) {}
          setState(() {
            _isPlaying = state.isPlaying;
            _isBuffering = state.isBuffering;
            if (_isPlaying) {
              _startProgressReporting();
              _danmakuController.start();
              if (!_playbackStartReported) {
                _playbackStartReported = true;
                try {
                  final svc = ref.read(currentMediaServerServiceProvider);
                  if (svc is EmbyService) {
                    svc.refreshPlaySession();
                    svc.reportPlaybackStart(_activeMedia.id);
                  }
                } catch (_) {}
              }
            } else {
              _progressTimer?.cancel();
              _uiUpdateTimer?.cancel();
              _danmakuController.pause();
            }
            _position = state.position;
            _lastStateTime = DateTime.now();
            // 对于 ISO/HDMV 等容器格式，MPV 可能报告错误的时长（0 或极大缩水）
            // 当服务器提供已知时长且引擎时长明显异常时，使用服务器时长
            final engineDur = state.duration;
            final serverDurSec = _activeMedia.duration; // 服务器提供的时长（秒）
            if (serverDurSec > 0 && engineDur > Duration.zero) {
              final serverDurMs = serverDurSec * 1000;
              // 如果引擎时长不到服务器时长的一半，可能是 ISO/HDMV 格式，使用服务器时长
              if (engineDur.inMilliseconds < serverDurMs * 0.6) {
                _duration = Duration(seconds: serverDurSec);
              } else {
                _duration = engineDur;
              }
            } else {
              _duration = engineDur;
            }
            // 续播：首次获取到正确时长后 seek 到上次位置
            if (!_resumeApplied && widget.resumePositionMs != null && _duration.inMilliseconds > widget.resumePositionMs!) {
              _resumeApplied = true;
              final resumePos = Duration(milliseconds: widget.resumePositionMs!);
              AppLog.i('Player', 'Resume → seek to ${resumePos.inMinutes}:${(resumePos.inSeconds % 60).toString().padLeft(2, '0')}');
              _engine?.seek(resumePos);
              // 弹幕游标同步到续播位置，避免续播后弹幕时间轴错位
              _danmakuController.seekTo(resumePos);
            }
            _buffer = state.buffer;
            _speed = state.speed;
            _volume = state.volume;
            // 硬件音量键/系统音量变化时同步持久化（防抖），下次切集/重开沿用
            if ((_volume - _lastSavedVolume).abs() > 0.02) _saveVolumeBrightness();
            _engineType = state.engineType;
          });
          // ── 自适应画幅：视频尺寸变化时重新计算 ──
          if (_isAutoFit && state.videoWidth > 0 && state.videoHeight > 0) {
            final actual = _computeAutoFit();
            if (actual != _currentFitMode) {
              setState(() { _currentFitMode = actual; });
              _engine?.setFitMode(actual);
            }
          }
          // ── 跳过片头/片尾检测 ──
          _checkSkipState(state.position);

          // ── 下一集倒计时检测 ──
          _checkNextEpisode(state.position, state.duration);

          if (state.duration > Duration.zero && !_tracksLoaded) {
            _tracksLoaded = true;
            _loadTracks();
          }

          if (state.error?.isNotEmpty == true) {
            final err = state.error!.toLowerCase();
            final decodeFailed = err.contains('codec') ||
                err.contains('audio') ||
                err.contains('truehd') ||
                err.contains('dts') ||
                err.contains('decoder') ||
                err.contains('source error');
            // ── 直连失败自动回退转码流（只试一次）──
            // 原盘 TrueHD/PGS 在 Exo 报 Source error、在 MPV 报解码器失败；
            // 服务器 PlaybackInfo 给过转码地址的话直接切过去，不用手动换内核。
            //
            // 飞牛没有「探测时顺手给转码地址」这回事：转码会话要单独调 play/play
            // 建，而且停播后就 410。所以那边只能等真的解码失败了再去要地址，
            // 不能像 Emby 一样开播时先备一个 —— 否则每次播放都会在 NAS 上
            // 起一个用不上的 ffmpeg 会话。
            if (decodeFailed && !_transcodeTried && _engine != null) {
              _transcodeTried = true;
              _fallbackToTranscode(state.position, state.speed);
            } else if (decodeFailed && !_showedAudioError) {
              _showDecodeFailedHint();
            }
          }
        }
      });

      // 监听画幅模式变化
      _engine!.fitModeNotifier.addListener(_onFitModeChanged);

      // 自适应画幅：引擎就绪后根据视频尺寸自动选择最佳缩放
      if (_isAutoFit) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final actual = _computeAutoFit();
            setState(() { _currentFitMode = actual; });
            _engine?.setFitMode(actual);
          }
        });
      }

      // 应用用户配置的字幕样式（MPV 原生渲染 / ExoPlayer SubtitleView 渲染）
      _engine!.applySubtitleStyle(ref.read(playerSettingsProvider));

      // 监听引擎切换
      manager.engineChangeStream.listen((type) {
        if (!mounted) return;
        // manager 自己也会换内核（回退/HDR 判定）：宿主手里的引用必须跟着换，
        // 否则样式/选轨/音量这些控制全打在已停用的旧内核上（真机实证：
        // 「切换内核: Exo → 原生」之后那次样式下发石沉大海）。
        final current = manager.currentEngine;
        setState(() {
          _engineType = type;
          if (current != null) _engine = current;
        });
        _engine?.applySubtitleStyle(ref.read(playerSettingsProvider));
      });

      setState(() {});
    } catch (e) {
      AppLog.e('Player', '播放失败: $e');
      if (mounted) setState(() => _initError = e.toString());
    } finally {
      _initPlayerRunning = false;
    }
  }

  Future<void> _loadTracks({int retry = 0}) async {
    if (_engine == null) return;
    try {
      final subtitles = await _engine!.getSubtitleTracks();
      final audios = await _engine!.getAudioTracks();
      if (mounted && !_isDisposed) {
        // ── 服务器驱动轨道管线（linplayer 模式）──
        //
        // 面板列表以服务器 MediaStreams 为唯一真相源；引擎轨道只用来提供
        // nativeIndex（原生直切的落点），名字全部走三级命名：DisplayTitle →
        // Title → 「语言 编码 #N (内封/外挂)」。mpv/Exo 伪造的「音轨 N」从此
        // 进不了 UI；引擎轨与服务端轨不再做两源合并——同一条流只有列表里的
        // 一个条目，重复与详情页不一致从架构上消失。
        final serverSubsAll =
            _activeMedia.subtitleTracks ?? const <Map<String, dynamic>>[];
        final serverSubs = serverSubsAll.where((t) {
          // 图片字幕（PGS/DVDsub 等）无法走文本渲染管线，不提供假选项
          final c = (t['Codec'] ?? '').toString().toLowerCase();
          return !['pgssub', 'dvdsub', 'hdmv_pgs_subtitle', 'dvb_subtitle', 's_avi']
              .contains(c);
        }).toList();

        // 命名与详情页 TrackSelectorSheet 同一实现(trackDisplayTitle):
        // DisplayTitle/Title 可信则用之(占位串自动跳过),否则拼
        // 「语言 · 编码 · 声道 #同语言序号 (内封/外挂)」
        var engineLeft = List<int>.generate(subtitles.length, (i) => i);
        final merged = <Map<String, dynamic>>[];
        for (final s in serverSubs) {
          final map = Map<String, dynamic>.from(s);
          map['server'] = true;
          map['title'] =
              trackDisplayTitle(s, siblings: serverSubs, prefix: '字幕');
          final key = _subtitleMatchKey(s);
          final langKey = key.split('|').first;
          var mi = engineLeft
              .indexWhere((ei) => _subtitleMatchKey(subtitles[ei]) == key);
          // 编码命名各版本混乱（引擎 application/x-media3-cues vs 服务端 srt）
          // 时退而按语言兜底配对（linplayer 同款二遍法）
          if (mi < 0 && langKey.isNotEmpty) {
            mi = engineLeft
                .indexWhere((ei) => _subtitleMatchKey(subtitles[ei]) == '$langKey|');
          }
          int? nativeIndex;
          if (mi >= 0) {
            nativeIndex = engineLeft[mi];
            engineLeft.removeAt(mi);
            map['IsDefault'] = s['IsDefault'] ??
                s['isDefault'] ??
                subtitles[nativeIndex]['isDefault'] ??
                false;
          }
          map['nativeIndex'] = nativeIndex;
          merged.add(map);
        }
        // 引擎独有轨（服务器 MediaStreams 漏报的内嵌轨）兜底追加；
        // 引擎 title 常为 null/占位串，同样走 trackDisplayTitle 规范命名
        for (final ei in engineLeft) {
          final n = Map<String, dynamic>.from(subtitles[ei]);
          n['nativeIndex'] = ei;
          n['title'] = trackDisplayTitle(n, siblings: subtitles, prefix: '字幕');
          merged.add(n);
        }
        // 排序：默认轨最前 → 中文 → 英文 → 其他语言，避免 WEB-DL 多语言轨墙
        merged.sort((a, b) {
          int rank(Map<String, dynamic> t) {
            if (t['IsDefault'] == true || t['isDefault'] == true) return 0;
            final lang = (t['Language'] ?? t['language'] ?? '').toString().toLowerCase();
            if (const {'zho', 'chi', 'cmn', 'yue'}.contains(lang)) return 1;
            if (lang == 'eng') return 2;
            return 3;
          }

          return rank(a).compareTo(rank(b));
        });
        // 音轨同样服务器驱动：条目 = 服务器音频流 + nativeIndex 映射
        final serverAudios =
            _activeMedia.audioTracks ?? const <Map<String, dynamic>>[];
        var audioLeft = List<int>.generate(audios.length, (i) => i);
        final audiosMerged = <Map<String, dynamic>>[];
        for (final s in serverAudios) {
          final map = Map<String, dynamic>.from(s);
          map['server'] = true;
          map['title'] = trackDisplayTitle(s, siblings: serverAudios, prefix: '音轨');
          final key = _audioMatchKey(s);
          final langKey = key.split('|').first;
          var mi = audioLeft
              .indexWhere((ei) => _audioMatchKey(audios[ei]) == key);
          if (mi < 0 && langKey.isNotEmpty) {
            // 编码变体（dca/dts 等）兜底：按语言配对
            mi = audioLeft
                .indexWhere((ei) => _audioMatchKey(audios[ei]) == '$langKey|');
          }
          int? nativeIndex;
          if (mi >= 0) {
            nativeIndex = audioLeft[mi];
            audioLeft.removeAt(mi);
          }
          map['nativeIndex'] = nativeIndex;
          audiosMerged.add(map);
        }
        for (final ei in audioLeft) {
          final n = Map<String, dynamic>.from(audios[ei]);
          n['nativeIndex'] = ei;
          n['title'] = trackDisplayTitle(n, siblings: audios, prefix: '音轨');
          audiosMerged.add(n);
        }
        setState(() {
          _fullSubtitleTracks = merged;
          // 面板默认只显示 中/英/默认轨，其余语言收进"显示全部"，
          // 避免 WEB-DL 多语言轨墙（用户已展开过则保持全量显示）
          _subtitleTracks = _filterSubtitleList(merged);
          _audioTracks = audiosMerged;
        });
        // 详情页预设的默认字幕语言（剧集"应用到全部"）：优先按语言匹配选中，
        // 找不到（该语言轨被过滤/不存在）时回落到下面的自动默认轨逻辑。
        // ⚠️ 与"自动默认轨"同样要等引擎轨就绪（nativeReady/waitDone）：引擎轨
        // 未就绪时服务器条目全都没有 nativeIndex，此刻按偏好选中会走下载路径
        // 而非原生直切（真机实证：默认选中即不同步，手动改选原生轨才同步）。
        // 且偏好匹配用 _langKey 归一化（zho/zh 一族）。
        final nativeReady = subtitles.isNotEmpty;
        final waitDone = retry >= 4; // 最多等 ~8s 让原生轨就绪
        final prefSubLang = ref.read(playerSettingsProvider).defaultSubtitleLang;
        if (_currentSubtitleIndex == -1 &&
            !_autoDefaultSubtitleApplied &&
            !_userDisabledSubtitles &&
            prefSubLang != null &&
            (nativeReady || waitDone)) {
          final prefIdx = _subtitleTracks.indexWhere((t) =>
              _langKey((t['Language'] ?? t['language'] ?? '').toString()) ==
                  _langKey(prefSubLang) &&
              t['isBitmap'] != true);
          if (prefIdx >= 0) {
            _autoDefaultSubtitleApplied = true;
            AppLog.i('Player', '按详情页偏好启用字幕轨: lang=$prefSubLang index=$prefIdx');
            _applySubtitleTrack(prefIdx);
          }
        }
        // 详情页预设的默认音轨语言：按语言匹配自动切换（未在播放器内手动选过时）
        final prefAudioLang = ref.read(playerSettingsProvider).defaultAudioLang;
        if (prefAudioLang != null &&
            _audioTracks.length > 1 &&
            _currentAudioIndex == 0) {
          String langOf(Map<String, dynamic> t) =>
              (t['Language'] ?? t['language'] ?? '').toString().toLowerCase();
          if (langOf(_audioTracks[0]) != prefAudioLang.toLowerCase()) {
            final prefAudioIdx = _audioTracks
                .indexWhere((t) => langOf(t) == prefAudioLang.toLowerCase());
            if (prefAudioIdx >= 0) {
              AppLog.i('Player', '按详情页偏好启用音轨: lang=$prefAudioLang index=$prefAudioIdx');
              _applyAudioTrack(prefAudioIdx);
            }
          }
        }
        // 自动启用文件标记为默认的字幕轨（WEB-DL 通常默认简体中文）。
        // 原生轨（无需服务器提取、直接从视频流读取）就绪后优先选原生轨；
        // 原生轨始终未就绪（转码流/无内嵌轨）时等几轮后回退服务端轨。
        // 仅首次加载、用户未手动选择、且未显式关闭过字幕时生效
        // （视频带硬字幕的片源关闭一次后不再自动叠加）。
        if (_currentSubtitleIndex == -1 &&
            !_autoDefaultSubtitleApplied &&
            !_userDisabledSubtitles &&
            (nativeReady || waitDone)) {
          final defaultIdx = _subtitleTracks.indexWhere((t) =>
              (t['IsDefault'] == true || t['isDefault'] == true) &&
              t['isBitmap'] != true);
          if (defaultIdx >= 0) {
            _autoDefaultSubtitleApplied = true;
            final isNative = _subtitleTracks[defaultIdx]['nativeIndex'] != null;
            AppLog.i('Player', '自动启用默认字幕轨: index=$defaultIdx (${isNative ? "原生" : "服务端"})');
            _applySubtitleTrack(defaultIdx);
          }
        } else if (nativeReady &&
            _autoDefaultSubtitleApplied &&
            !_userDisabledSubtitles &&
            !_externalSubtitleLoaded) {
          // 原生轨迟到：自动默认选中的服务端轨尚未加载成功（服务器提取可能挂起，
          // FNNAS/Emby 对 mkv 内嵌字幕实测 >90s 无响应），列表更新后改选原生默认轨。
          final defaultIdx = _subtitleTracks.indexWhere((t) =>
              t['nativeIndex'] != null &&
              (t['IsDefault'] == true || t['isDefault'] == true) &&
              t['isBitmap'] != true);
          if (defaultIdx >= 0) {
            AppLog.i('Player', '原生轨就绪，改选原生默认轨: index=$defaultIdx');
            _applySubtitleTrack(defaultIdx);
          }
        }
        // 后台预取 默认/中文/英文 服务端字幕到本地缓存（不阻塞播放、不显示加载提示）。
        // 内嵌字幕已优先走原生渲染，这里只覆盖服务端独有轨（外挂 srt/ass 等）。
        if (!_subtitlePrefetched) {
          _prefetchServerSubtitles(merged);
        }
        // 检测位图字幕（PGS/DVDsub 等）并提示用户（只提示一次）
        final hasBitmap = subtitles.any((t) => t['isBitmap'] == true);
        if (hasBitmap && !_bitmapWarned) {
          _bitmapWarned = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('检测到图片字幕(PGS/SUP)，可能无法显示。建议使用外挂 SRT/ASS 字幕'),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(label: '知道了', onPressed: () {}),
                ),
              );
            }
          });
        }
      }
      // ExoPlayer 文本轨可能远晚于时长才就绪（慢速 NAS/大文件索引解析），
      // 甚至首次拿到的列表为空后就不再刷新 → 内嵌字幕轨永远进不了面板。
      // 轮询直到出现文本轨（最多 ~30s）：一旦出现立即重建合并列表（上方 setState），
      // 原生轨优先的去重/自动启用逻辑随即生效。服务端字幕轨不受影响。
      if (subtitles.isEmpty && retry < 15 && mounted && !_isDisposed) {
        if (retry % 2 == 0) {
          AppLog.i('Player', '原生字幕轨未就绪，继续轮询 retry=$retry');
        }
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isDisposed && _engine != null) {
            _loadTracks(retry: retry + 1);
          }
        });
      }
    } catch (_) {}
  }

  /// 语言规范化桶：同一语言在不同数据源写法不同（服务器 ISO-639-2 `zho`、
  /// 引擎 mkv 里常是 `zh`、Emby 旧数据 `chi`），原始比对配不上对 → 内嵌轨
  /// 拿不到 nativeIndex、被当纯服务端轨走下载渲染（时间轴不如原生准，且
  /// 引擎那条又作为独有轨追加 → 同一字幕出现两条）。真机日志 2026-08-29 实证。
  String _langKey(String? lang) {
    final l = (lang ?? '').trim().toLowerCase();
    if (l.isEmpty) return '';
    const zh = {'zh', 'zho', 'chi', 'cmn', 'chs', 'zh-hans', 'zh-cn', 'zh-sg', 'gb'};
    const zhHant = {'zh-hant', 'zh-tw', 'zh-hk', 'cht', 'big5'};
    if (zh.contains(l)) return 'zh';
    if (zhHant.contains(l)) return 'zh-hant';
    if (l == 'yue' || l == 'can') return 'yue';
    if (l == 'eng') return 'en';
    return l;
  }

  /// 字幕轨配对键：规范化语言 + 归一化编码，用于原生轨与服务端轨配对
  String _subtitleMatchKey(Map<String, dynamic> t) {
    final lang = _langKey((t['language'] ?? t['Language'] ?? '').toString());
    final codec = _normalizeSubtitleCodec((t['codec'] ?? t['Codec'] ?? '').toString());
    return '$lang|$codec';
  }

  /// 归一化字幕编码名：原生层返回 MIME（application/x-subrip），服务端返回短名
  /// （subrip），不归一化则同一条流配对不上、列表出现重复轨。
  String _normalizeSubtitleCodec(String codec) {
    final c = codec.toLowerCase().trim();
    if (c.isEmpty) return '';
    // Media3 1.8 把内嵌文本轨的 sampleMimeType 统一成 application/x-media3-cues
    // （内容仍是容器里的 srt/ass），不归一则与服务器的 srt 永远配不上对
    if (c.contains('media3-cues')) return 'subrip';
    if (c.contains('subrip') || c.contains('x-subrip') || c == 'srt') return 'subrip';
    if (c.contains('ssa') || c == 'ass' || c.contains('x-ssa')) return 'ass';
    if (c.contains('vtt') || c == 'webvtt' || c.contains('x-vtt')) return 'vtt';
    if (c.contains('pgs') || c.contains('hdmv_pgs')) return 'pgs';
    if (c.contains('dvdsub') || c.contains('vobsub')) return 'dvdsub';
    if (c.contains('dvb')) return 'dvb';
    if (c.contains('cea') || c.contains('eia')) return 'cea';
    if (c == 'text' || c.contains('tx3g') || c.contains('mov_text')) return 'text';
    return c;
  }

  /// 音轨合并服务端 MediaStreams：按 (语言,编码) 配对，把服务端 DisplayTitle/
  /// Title 贴到原生轨上（面板与 toast 显示规范名称而非"音轨 1/2"）。
  /// 编码命名不一致（mpv 'dts-hdma' vs 服务端 'dts'）时按语言兑底配对。
  /// 保持引擎顺序且不追加服务端独有轨：列表索引 == 引擎索引，切换不受影响。
  /// 音轨配对键：语言 + 编码（小写），与字幕轨同套（服务端大写 key 兼容）
  String _audioMatchKey(Map<String, dynamic> t) {
    final lang = _langKey((t['Language'] ?? t['language'] ?? '').toString());
    var codec = (t['Codec'] ?? t['codec'] ?? '').toString().toLowerCase().trim();
    // 编码别名/变体归一:dca→dts(Jellyfin 写法),'truehd atmos'→truehd
    codec = switch (codec) {
      'dca' || 'dts-hd' || 'dts-hdma' || 'dts-hd ma' => 'dts',
      'a_ac3' => 'ac3',
      _ => codec.split(RegExp(r'[\s+]')).first,
    };
    return '$lang|$codec';
  }

  /// 面板字幕列表：默认只保留 默认轨/中/英，其余语言收进"显示全部"占位轨。
  /// 占位轨索引在列表末尾，选择它时展开全量列表。
  List<Map<String, dynamic>> _filterSubtitleList(List<Map<String, dynamic>> full) {
    if (_showAllSubtitleTracks || full.length <= 3) return full;
    final preferred = full.where((t) {
      if (t['IsDefault'] == true || t['isDefault'] == true) return true;
      final lang = (t['Language'] ?? t['language'] ?? '').toString().toLowerCase();
      return const {'zho', 'chi', 'cmn', 'yue', 'eng'}.contains(lang);
    }).toList();
    if (preferred.length == full.length) return full;
    return [
      ...preferred,
      {
        'title': '显示全部 ${full.length} 条字幕',
        'showAll': true,
        'language': '',
      },
    ];
  }

  void _startProgressReporting() {
    // ⚠️ 两个定时器都必须**幂等**：本方法由状态回调高频调用（真机实测单次推送
    // ≈250ms），无条件 cancel+重建 = 倒计时重新开始。此前进度定时器就是这么写的，
    // 结果 30 秒永远等不到触发 —— Emby 的"继续观看"位置只有退出/拖动后才更新
    // （UI 定时器一直有 isActive 守卫，所以进度条本身是动的，掩盖了这个问题）。
    _progressTimer = ensurePeriodicTimer(
        _progressTimer, const Duration(seconds: 30), _reportProgress);
    // UI 更新 Timer：stateStream 频率可能太低，定期推算位置更新进度条
    if (_uiUpdateTimer == null || !_uiUpdateTimer!.isActive) {
      // 落点只在真正新建时刷新，别让每次推送都把基准时间往后推
      _lastStateTime = DateTime.now();
    }
    _uiUpdateTimer = ensurePeriodicTimer(
        _uiUpdateTimer, const Duration(milliseconds: 500), _tickUiPosition);
  }

  /// UI 定时器的每帧回调：按倍速推算位置，驱动进度条与跳过片头检测。
  void _tickUiPosition() {
    if (!_isPlaying || _isDisposed || _isSeeking) return;
    final now = DateTime.now();
    final elapsed = now.difference(_lastStateTime).inMilliseconds;
    if (elapsed >= 500) {
      final oldPos = _position.inMilliseconds;
      setState(() {
        _position = Duration(milliseconds: oldPos + (elapsed * _speed).round());
      });
      // 500ms 定时器内检测跳过状态，确保片头按钮秒级响应
      _checkSkipState(_position);
      _lastStateTime = now;
      _uiTick++;
      if (_uiTick % 20 == 0) {
        AppLog.i('Player', '_uiUpdateTimer: pos=${_position.inMilliseconds}ms (was $oldPos, elapsed=${elapsed}ms, speed=$_speed)');
      }
    }
  }


  /// 平滑推算的播放位置。
  ///
  /// [_position] 只在 500ms 的 UI 定时器（或引擎状态推送）上跳变。直接拿它
  /// 当字幕时间轴，字幕的出入点就被量化到 500ms —— 半秒的迟到是看得出来的。
  /// 这里按「上次落点 + 已过时间 × 倍速」补出中间值，读的人不用等下一次
  /// setState。暂停 / 拖动中不推算（那时 [_position] 才是权威值）。
  ///
  /// 刻意不做 clamp：越过片尾时二分查找自然落空，字幕消失即是正确结果。
  Duration get _smoothPosition {
    if (!_isPlaying || _isSeeking) return _position;
    final elapsed = DateTime.now().difference(_lastStateTime).inMilliseconds;
    if (elapsed <= 0) return _position;
    return _position + Duration(milliseconds: (elapsed * _speed).round());
  }

  Future<void> _reportProgress() async {
    if (_engine == null || _isDisposed) return;
    var pos = _position.inMilliseconds;
    final dur = _duration.inMilliseconds;
    if (pos <= 0 || dur <= 0) {
      // 不再静默 return：这里混着两种情况 —— 内核**根本没起播**（真机实证：
      // ISO 转码流 HTTP 500 → mpv "Failed to open"，位置/时长全空）与
      // 在播但读到 0（状态回读异常）。留痕后现场可直接区分。
      AppLog.w('Player',
          '跳过进度上报: pos=${pos}ms dur=${dur}ms（内核未起播或状态回读为空）');
      return;
    }
    // 防护:上报位置不得超过片长 95%——ISO/HDMV 等容器的引擎时长/位置偶发异常
    // (如瞬间跳到片尾),会让服务端把内容误标"已看"并从"继续观看"消失。
    if (pos > dur * 0.95) {
      pos = (dur * 0.95).round();
    }
    if (pos - _lastReportedMs < 10000) return; // 10s 内去重
    _lastReportedMs = pos;
    AppLog.i('Player', '_reportProgress: pos=${pos}ms dur=${dur}ms');
    try {
      final svc = ref.read(currentMediaServerServiceProvider);
      if (svc is EmbyService) {
        await svc.reportPlaybackProgress(_activeMedia.id, pos, isPlaying: _isPlaying);
      } else if (svc != null) {
        await svc.markWatched(_activeMedia.id, positionMs: pos);
      }
    } catch (_) {}
  }

  void _onSeekEnd() {
    _lastReportedMs = 0;
    _reportProgress();
    // Seek 后清理弹幕状态，根据新位置重置扫描游标
    _danmakuController.seekTo(_position);
  }

  /// 解码失败且拿不到转码流时的兜底提示（带「切换内核」动作）。
  void _showDecodeFailedHint() {
    if (_showedAudioError) return;
    _showedAudioError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('音频解码失败，建议切换到其他音轨或ExoPlayer内核'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '切换内核',
            onPressed: () {
              final manager = ref.read(playerManagerProvider);
              manager.switchEngine(PlayerEngineType.exo);
            },
          ),
        ),
      );
    });
  }

  /// 直连解码失败后切到服务器转码流。
  ///
  /// Emby/Jellyfin 在探测阶段就给了转码地址（`svc.lastTranscodeUrl`），直接用；
  /// 飞牛要现场调 `play/play` 建会话才有地址，所以这里是 async 的。
  Future<void> _fallbackToTranscode(Duration pos, double speed) async {
    var url = _transcodeFallbackUrl;
    if (url == null) {
      final svc = ref.read(currentMediaServerServiceProvider);
      if (svc is FnOSService) {
        AppLog.w('Player', '直连解码失败，向飞牛申请转码会话...');
        url = await svc.getTranscodeUrl(_activeMedia.id);
      }
    }
    if (url == null || _engine == null || _isDisposed) {
      AppLog.w('Player', '拿不到转码地址，保持直连并提示用户');
      _showDecodeFailedHint();
      return;
    }
    AppLog.w('Player', '自动切换转码流: $url');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('直连播放失败，已切换为服务器转码流'),
          duration: Duration(seconds: 4)));
    }
    await _engine!.open(url: url, httpHeaders: widget.httpHeaders, autoPlay: true);
    if (pos > Duration.zero) await _engine?.seek(pos);
    if (speed != 1.0) await _engine?.setSpeed(speed);
  }

  Future<void> _applyBrightness() async {
    try {
      await ScreenBrightness().setScreenBrightness(_brightness);
    } catch (_) {}
  }

  /// 恢复用户音量/亮度：优先取持久化值，未设置过则读取系统当前值作为起点，
  /// 保证应用内 HUD 与系统实际音量/亮度对应。
  Future<void> _restoreVolumeBrightness() async {
    await StorageService.ready;
    final savedBrightness = StorageService.getDouble('player_brightness');
    if (savedBrightness != null) {
      _brightness = savedBrightness.clamp(0.05, 1.0);
    } else {
      try {
        final sys = await ScreenBrightness().current;
        if (sys > 0) _brightness = sys.clamp(0.05, 1.0);
      } catch (_) {}
    }
    final savedVolume = StorageService.getDouble('player_volume');
    if (savedVolume != null) _volume = savedVolume.clamp(0.0, 1.0);
    _lastSavedVolume = _volume;
    await _applyBrightness();
    _engine?.setVolume(_volume);
  }

  /// 持久化音量/亮度（500ms 防抖，拖动/硬件音量键变化都会落到这里）
  void _saveVolumeBrightness() {
    _volBriSaveTimer?.cancel();
    _volBriSaveTimer = Timer(const Duration(milliseconds: 500), () async {
      _lastSavedVolume = _volume;
      await StorageService.setDouble('player_volume', _volume);
      await StorageService.setDouble('player_brightness', _brightness);
    });
  }

  /// 从 bangumi 详情响应中提取 bangumi 数据
  /// 兼容多种结构: { bangumi: {...} } / { data: { bangumi: {...} } } / { data: {...} }
  Map<String, dynamic>? _extractBangumiData(Map<String, dynamic> detail) {
    if (detail['bangumi'] is Map) {
      return detail['bangumi'] as Map<String, dynamic>;
    }
    if (detail['data'] is Map) {
      final data = detail['data'] as Map<String, dynamic>;
      if (data['bangumi'] is Map) {
        return data['bangumi'] as Map<String, dynamic>;
      }
      // data 本身就是 bangumi 数据（有 episodes 字段）
      if (data['episodes'] != null) {
        return data;
      }
    }
    // 响应本身就是 bangumi 数据
    if (detail['episodes'] != null) {
      return detail;
    }
    return null;
  }

  /// 匹配集号：兼容数字字符串 / int / 带前缀的格式
  bool _matchEpisodeNumber(dynamic ep, int target) {
    final num = ep['episodeNumber'] ?? ep['episode_number'] ?? ep['number'] ?? ep['ep'] ?? ep['index'];
    if (num == null) return false;
    final str = num.toString();
    return str == target.toString() || int.tryParse(str) == target;
  }

  /// 弹幕缓存目录
  Future<Directory> _danmakuCacheDir() async {
    final appCache = await getApplicationCacheDirectory();
    final dir = Directory('${appCache.path}/danmaku');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<Danmaku>?> _getCachedDanmaku(String episodeId) async {
    try {
      final dir = await _danmakuCacheDir();
      final file = File('${dir.path}/${_safeFileName(episodeId)}.json');
      if (!await file.exists()) return null;
      // TTL: 24 小时
      final modified = await file.lastModified();
      if (DateTime.now().difference(modified) > const Duration(hours: 24)) {
        await file.delete();
        return null;
      }
      final json = await file.readAsString();
      final data = jsonDecode(json);
      final ver = data['v'] as int? ?? 1;
      if (ver < 4) {
        await file.delete();
        return null;
      }
      final list = (data['danmaku'] as List).map((j) => Danmaku.fromJson(j)).toList();
      AppLog.i('Danmaku', '文件缓存命中: ${list.length} 条弹幕');
      return list;
    } catch (e) {
      AppLog.d('Danmaku', '读取缓存失败: $e');
      return null;
    }
  }

  Future<void> _cacheDanmaku(String episodeId, List<Danmaku> danmaku) async {
    try {
      final dir = await _danmakuCacheDir();
      final file = File('${dir.path}/${_safeFileName(episodeId)}.json');
      await file.writeAsString(jsonEncode({
        'v': 4,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'danmaku': danmaku.map((d) => d.toJson()).toList(),
      }));
      AppLog.i('Danmaku', '弹幕文件缓存写入: ${danmaku.length} 条');
      // 顺便清理过期缓存
      _cleanDanmakuCache();
    } catch (e) {
      AppLog.d('Danmaku', '写入缓存失败: $e');
    }
  }

  /// 清理超过 7 天的弹幕缓存文件
  Future<void> _cleanDanmakuCache() async {
    try {
      final dir = await _danmakuCacheDir();
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      await for (final entity in dir.list()) {
        if (entity is File) {
          final modified = await entity.lastModified();
          if (modified.isBefore(cutoff)) {
            await entity.delete();
          }
        }
      }
    } catch (_) {}
  }

  /// 将 episodeId 转为安全的文件名
  String _safeFileName(String id) {
    return id.replaceAll(RegExp(r'[^\w\-]'), '_');
  }

  /// 等待引擎报告有效时长（用于弹幕匹配）
  ///
  /// 当 widget.media.duration 为 0 时，等待引擎 stateStream 返回有效的 duration。
  /// 最多等待 [timeoutMs] 毫秒，返回秒数；超时返回 0。
  Future<int> _waitForEngineDuration({int timeoutMs = 8000}) async {
    // 先检查引擎是否已有有效时长
    if (_engine != null && _engine!.currentState.duration > Duration.zero) {
      return _engine!.currentState.duration.inSeconds;
    }
    // 等待引擎 stateStream 报告有效时长
    final completer = Completer<int>();
    StreamSubscription? sub;
    Timer? timer;
    sub = _engine?.stateStream.listen((state) {
      if (state.duration > Duration.zero && !completer.isCompleted) {
        completer.complete(state.duration.inSeconds);
        timer?.cancel();
        sub?.cancel();
      }
    });
    timer = Timer(Duration(milliseconds: timeoutMs), () {
      if (!completer.isCompleted) {
        completer.complete(0);
        sub?.cancel();
      }
    });
    return completer.future;
  }

  /// 计算视频文件前 16KB 的 MD5 哈希（用于弹幕精准匹配）
  Future<String?> _computeVideoHash() async {
    try {
      // 用当前实际地址：入口不再预解析时 widget.streamUrl 是空的（延迟解析后
      // 它也不会更新），改用切集/切画质后维护的 _currentStreamUrl
      final url = _currentStreamUrl;
      if (url.isEmpty) return null;
      final headers = widget.httpHeaders ?? {};
      // 只请求前 16KB（rhttp 优先，Dio 回退）
      final bytes = await HttpClient.getBytes(
        url,
        headers: {...headers, 'Range': 'bytes=0-16383'},
        timeout: const Duration(seconds: 5),
      );
      if (bytes.isNotEmpty) {
        final digest = md5.convert(bytes);
        return digest.toString();
      }
    } catch (e) {
      AppLog.d('Danmaku', '视频哈希计算失败: $e');
    }
    return null;
  }

  /// 获取已记住的弹幕选择（mediaId → episodeId）
  Future<String?> _getRememberedDanmakuId() async {
    final mediaId = _activeMedia.id;
    try {
      final sel = await DbService.getDanmakuSelection(mediaId);
      if (sel != null) return sel;
    } catch (_) {}
    return StorageService.getString('danmaku_sel_$mediaId');
  }

  /// 记住弹幕选择
  Future<void> _rememberDanmakuId(String episodeId) async {
    final mediaId = _activeMedia.id;
    try { await DbService.setDanmakuSelection(mediaId, episodeId); } catch (_) {}
    await StorageService.setString('danmaku_sel_$mediaId', episodeId);
  }

  /// 清除已记住的弹幕选择（弹幕为空时回退到重新匹配）
  Future<void> _clearRememberedDanmakuId() async {
    final mediaId = _activeMedia.id;
    try {
      await (DbService.db.delete(DbService.db.danmakuSelectionsTable)
        ..where((t) => t.mediaId.equals(mediaId))).go();
    } catch (_) {}
    await StorageService.remove('danmaku_sel_$mediaId');
  }

  /// 加载弹幕：已记住选择直载 → 全源双路并行匹配 → 依序尝试候选。
  Future<void> _loadDanmaku() async {
    if (_danmakuLoading) {
      AppLog.d('Danmaku', '弹幕加载中，跳过重复请求');
      return;
    }
    _danmakuLoading = true;
    try {
      // 0. 已记住的选择：直接加载，跳过匹配（旧语义保留：0 条就清掉重匹配）
      final rememberedId = await _getRememberedDanmakuId();
      if (rememberedId != null) {
        final remembered = await _pickRememberedSource();
        final service = remembered?.$2;
        if (service != null) {
          final loaded = await _loadDanmakuByEpisodeId(
            episodeId: rememberedId,
            service: service,
            sourceId: remembered!.$1.id,
            sourceName: remembered.$1.name,
            candidateKey: null,
          );
          if (loaded) return;
        }
        AppLog.w('Danmaku', '已记住的选择加载失败，清除并重新匹配');
        await _clearRememberedDanmakuId();
      }

      // 1. 全源双路并行匹配，得到跨源候选列表
      final candidates = await _matchDanmakuCandidates();
      if (!mounted) return;
      setState(() => _danmakuCandidates = candidates);
      if (candidates.isEmpty) {
        AppLog.i('Danmaku', '所有弹幕源均无候选');
        return;
      }

      // 2. 依序尝试前 3 个候选，直到真正加载到弹幕
      for (final c in candidates.take(3)) {
        final service = _danmakuServices[c.sourceId];
        if (service == null) continue;
        final episodeId = await _resolveCandidateEpisodeId(c, service);
        if (episodeId == null) continue;
        final loaded = await _loadDanmakuByEpisodeId(
          episodeId: episodeId,
          service: service,
          sourceId: c.sourceId,
          sourceName: c.sourceName,
          candidateKey: c.key,
        );
        if (loaded) return;
      }
      AppLog.i('Danmaku', '前 ${candidates.take(3).length} 个候选均未加载到弹幕');
    } catch (e) {
      AppLog.e('Danmaku', '加载弹幕失败: $e');
    } finally {
      _danmakuLoading = false;
    }
  }

  /// 构建所有启用源的服务并缓存（每次匹配重建，避免配置变更后用旧实例）。
  /// 返回 (配置列表, 上次使用的源 id)。
  Future<(List<DanmakuConfig>, String?)> _prepareSources() async {
    var configs = ref.read(danmakuConfigsProvider);
    // Provider 异步加载可能尚未完成，等待最多 2 秒（旧行为保留）
    if (configs.isEmpty) {
      AppLog.i('Danmaku', '弹幕配置尚未加载，等待...');
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        configs = ref.read(danmakuConfigsProvider);
        if (configs.isNotEmpty) break;
      }
    }
    final enabled =
        configs.where((c) => c.isEnabled && c.url.isNotEmpty).toList();
    _danmakuServices
      ..clear()
      ..addEntries(enabled.map((config) {
        final apiKey = config.apiKey?.isNotEmpty == true
            ? config.apiKey
            : DanmakuService.extractApiKeyFromUrl(config.url);
        return MapEntry(
            config.id, DanmakuService(baseUrl: config.url, apiKey: apiKey));
      }));
    final lastSourceId =
        await StorageService.getString('danmaku_src_${_activeMedia.id}');
    return (enabled, lastSourceId);
  }

  /// 全源双路并行匹配（对齐 LinPlayer matchAll：源之间并行、源内双路并行）。
  Future<List<DanmakuMatchCandidate>> _matchDanmakuCandidates() async {
    // 弹幕总开关(设置里可关):关了直接跳过,不再发起任何匹配/连接
    if (!ref.read(danmakuDisplayProvider).enabled) {
      AppLog.i('Danmaku', '弹幕总开关已关闭,跳过匹配');
      return const [];
    }
    final (enabled, lastSourceId) = await _prepareSources();
    if (enabled.isEmpty) {
      AppLog.i('Danmaku', '未配置弹幕服务或未启用，跳过匹配');
      return const [];
    }

    final isEpisode = _activeMedia.type == MediaType.episode;
    final rawTitle = isEpisode && _activeMedia.seriesTitle != null
        ? _activeMedia.seriesTitle!
        : _activeMedia.title;
    // 时长：引擎还没报就等最多 8 秒（/match 用）
    int durationSec = _activeMedia.duration > 0
        ? _activeMedia.duration
        : await _waitForEngineDuration(timeoutMs: 8000);
    final fileHash = await _computeVideoHash();
    final fileName = danmakuMatchFileName(
      filePath: _activeMedia.filePath,
      title: rawTitle,
      season: _activeMedia.seasonNumber,
      episode: _activeMedia.episodeNumber,
    );
    AppLog.i('Danmaku',
        '并行匹配: $rawTitle, 源=${enabled.length}, 文件名=$fileName, 哈希=${fileHash != null ? '有' : '无'}');

    final perSource = await Future.wait(enabled.map((config) {
      final service = _danmakuServices[config.id]!;
      return DanmakuMatchPipeline.matchSource(
        input: DanmakuMatchInput(
          sourceId: config.id,
          sourceName: config.name,
          queryTitle: rawTitle,
          matchFileName: fileName,
          fileHash: fileHash,
          durationSec: durationSec > 0 ? durationSec : null,
          season: _activeMedia.seasonNumber,
          episode: _activeMedia.episodeNumber,
        ),
        matchV2: (fileName, fileHash, duration) => service.matchV2(
            fileName: fileName, fileHash: fileHash, duration: duration),
        search: service.searchDanmaku,
      );
    }));
    return mergeDanmakuCandidates(perSource, preferredSourceId: lastSourceId);
  }

  /// 已记住的选择对应的源：优先 danmaku_src 记忆，缺省第一个启用源。
  Future<(DanmakuConfig, DanmakuService)?> _pickRememberedSource() async {
    final (enabled, lastSourceId) = await _prepareSources();
    if (enabled.isEmpty) return null;
    final idx = lastSourceId == null
        ? 0
        : enabled.indexWhere((c) => c.id == lastSourceId);
    final config = idx >= 0 ? enabled[idx] : enabled.first;
    final service = _danmakuServices[config.id];
    if (service == null) return null;
    return (config, service);
  }

  /// 候选 → 单集 ID：episodeId 直出；否则 bangumi 详情按集号定位（失败回退第一集）。
  Future<String?> _resolveCandidateEpisodeId(
      DanmakuMatchCandidate c, DanmakuService service) async {
    final direct = c.episodeId;
    if (direct != null && direct.isNotEmpty) return direct;
    try {
      final detail = await service.getBangumiDetail(c.bangumiId);
      if (detail == null) return c.bangumiId.isNotEmpty ? c.bangumiId : null;
      final bangumi = _extractBangumiData(detail);
      final episodes = (bangumi?['episodes'] as List?) ?? [];
      if (episodes.isNotEmpty) {
        final target = _activeMedia.episodeNumber ?? 1;
        final ep = episodes.firstWhere(
          (e) => _matchEpisodeNumber(e, target),
          orElse: () => episodes.first,
        ) as Map;
        final id =
            (ep['episodeId'] ?? ep['episode_id'] ?? ep['id'])?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (e) {
      AppLog.w('Danmaku', '候选[${c.title}]解析单集失败: $e');
    }
    return c.bangumiId.isNotEmpty ? c.bangumiId : null;
  }

  /// 按 episodeId 加载弹幕（缓存 → 网络 → 预处理 → 下发），成功后记住选择。
  Future<bool> _loadDanmakuByEpisodeId({
    required String episodeId,
    required DanmakuService service,
    required String sourceId,
    required String sourceName,
    required String? candidateKey,
  }) async {
    final cached = await _getCachedDanmaku(episodeId);
    List<Danmaku> danmaku;
    if (cached != null) {
      danmaku = cached;
      AppLog.i('Danmaku', '使用缓存弹幕: ${cached.length} 条');
    } else {
      danmaku = await service.getDanmaku(
          episodeId: episodeId, episode: _activeMedia.episodeNumber);
      if (danmaku.isNotEmpty) _cacheDanmaku(episodeId, danmaku);
    }
    if (danmaku.isEmpty) {
      AppLog.w('Danmaku', 'episodeId=$episodeId 无弹幕');
      return false;
    }
    AppLog.i('Danmaku', '获取弹幕成功: ${danmaku.length} 条 (源=$sourceName)');
    _preprocessDanmaku(danmaku);
    if (!mounted) return false;
    setState(() {
      _loadedDanmakuCount = danmaku.length;
      _loadedDanmakuSource = sourceName;
      _selectedCandidateKey = candidateKey;
    });
    _danmakuController.setData(danmaku);
    _danmakuController.updateActive(_position.inMilliseconds);
    // 安全网：引擎未就绪时 updateActive 可能空转，延迟补一次（旧行为保留）
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _danmakuEnabled) {
        _danmakuController.updateActive(_position.inMilliseconds);
      }
    });
    // 记住选择与来源：下次起播直接跳过匹配；来源 id 用于候选并列时的偏好微调
    _rememberDanmakuId(episodeId);
    await StorageService.setString('danmaku_src_${_activeMedia.id}', sourceId);
    return true;
  }

  /// 面板点击候选：解析单集 → 加载 → 记住（手动切换，与自动匹配共用加载管线）。
  Future<void> _switchDanmakuCandidate(DanmakuMatchCandidate c) async {
    if (_danmakuLoading) {
      AppLog.d('Danmaku', '切换候选时正在加载，忽略');
      return;
    }
    _danmakuLoading = true;
    try {
      var service = _danmakuServices[c.sourceId];
      if (service == null) {
        await _prepareSources();
        service = _danmakuServices[c.sourceId];
      }
      if (service == null) {
        AppLog.w('Danmaku', '候选来源[${c.sourceName}]已停用，无法切换');
        return;
      }
      final episodeId = await _resolveCandidateEpisodeId(c, service);
      if (episodeId == null) {
        AppLog.w('Danmaku', '候选[${c.title}]无法解析出单集');
        return;
      }
      await _loadDanmakuByEpisodeId(
        episodeId: episodeId,
        service: service,
        sourceId: c.sourceId,
        sourceName: c.sourceName,
        candidateKey: c.key,
      );
    } finally {
      _danmakuLoading = false;
    }
  }

  /// 弹幕数据预处理（排序 → 过滤空文本 → 屏蔽词 → 去重合并）
  List<Danmaku> _preprocessDanmaku(List<Danmaku> danmaku) {
    // 1. 排序
    danmaku.sort((a, b) => a.time.compareTo(b.time));
    // 2. 过滤空文本
    danmaku.removeWhere((d) => d.text.isEmpty || d.text.trim().isEmpty);
    // 3. 屏蔽词过滤
    final blockKeywords = ref.read(danmakuDisplayProvider).blockKeywords;
    if (blockKeywords.isNotEmpty) {
      final lowerKeywords = blockKeywords.map((k) => k.toLowerCase()).toList();
      danmaku.removeWhere((d) {
        final lowerText = d.text.toLowerCase();
        return lowerKeywords.any((kw) => lowerText.contains(kw));
      });
    }
    // 4. 去重合并：500ms 内相同文本只保留第一条
    if (danmaku.length > 1) {
      final seen = <String>{};
      danmaku.removeWhere((d) {
        final timeGroup = d.time ~/ 500;
        final key = '${d.text}_$timeGroup';
        if (seen.contains(key)) return true;
        seen.add(key);
        return false;
      });
    }
    // 5. 简繁转换
    final charConversion = ref.read(danmakuDisplayProvider).charConversion;
    if (charConversion != 'none' && danmaku.isNotEmpty) {
      for (int i = 0; i < danmaku.length; i++) {
        final d = danmaku[i];
        final converted = charConversion == 's2t'
            ? ChineseConverter.toTraditional(d.text)
            : ChineseConverter.toSimplified(d.text);
        if (converted != d.text) {
          danmaku[i] = Danmaku(
            id: d.id,
            text: converted,
            time: d.time,
            color: d.color,
            type: d.type,
            author: d.author,
            fontSize: d.fontSize,
          );
        }
      }
    }
    return danmaku;
  }

  /// 锁定/解锁播放器：锁定时隐藏控制层并禁用全部手势
  void _toggleLock() {
    setState(() {
      _controlsLocked = !_controlsLocked;
      if (_controlsLocked) _controlsVisible = false;
    });
    if (_controlsLocked) {
      _closeAllPanels();
      _hideTimer?.cancel();
    } else {
      _startHideTimer();
    }
  }

  /// 锁定/解锁按钮（常驻右缘）：同一个按钮原地切换状态，不额外生成解锁按钮。
  /// 未锁定 = 半透明空心（锁开）；锁定 = 主题色填充描边（锁闭），点击即解锁。
  Widget _buildLockToggle() {
    final locked = _controlsLocked;
    return TapFeedback(
      onTap: _toggleLock,
      scaleOnPress: 0.9,
      springBack: true,
      highlightColor: Colors.transparent,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: locked
              ? AppTheme.primary.withValues(alpha: 0.30)
              : Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
          border: locked ? Border.all(color: AppTheme.primary, width: 1.2) : null,
        ),
        child: Center(
          child: Icon(
            locked ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: locked ? AppTheme.primary : Colors.white.withValues(alpha: 0.6),
            size: 18,
          ),
        ),
      ),
    );
  }

  void _toggleControls() {
    // 如果有面板打开，点击只关闭面板，不切换控制栏
    if (_hasAnyPanelOpen) {
      _closeAllPanels();
      return;
    }
    setState(() => _controlsVisible = !_controlsVisible);
    _syncControlsAnim();
    if (_controlsVisible) _startHideTimer();
  }

  /// 把 _controlsVisible 同步到滑动/淡出动画控制器
  ///
  /// 减少动效时直接跳到终态 —— 控制栏该在的时候立刻在，该走的时候立刻走。
  void _syncControlsAnim() {
    if (context.reduceMotion) {
      _controlsController.value = _controlsVisible ? 1.0 : 0.0;
      return;
    }
    if (_controlsVisible) {
      _controlsController.forward();
    } else {
      _controlsController.reverse();
    }
  }

  /// 是否有任意面板打开（剧集面板 / 任何右侧滑入面板）
  bool get _hasAnyPanelOpen => _showEpisodePanel || _rightPanelType != null;

  /// 关闭所有面板
  void _closeAllPanels() {
    if (_showEpisodePanel) {
      _animateCloseEpisodePanel();
    } else {
      setState(() => _rightPanelType = null);
    }
  }

  /// 选集面板关闭动画
  void _animateCloseEpisodePanel() {
    if (!_episodePanelController.isAnimating && !_showEpisodePanel) return;
    if (context.reduceMotion) {
      _episodePanelController.value = 0.0;
      setState(() => _showEpisodePanel = false);
      return;
    }
    _episodePanelController.reverse().then((_) {
      if (mounted) setState(() => _showEpisodePanel = false);
    });
  }

  /// 切换面板（仅剧集面板使用）
  void _togglePanel(String panel) {
    if (panel == 'episode') {
      if (_showEpisodePanel) {
        _animateCloseEpisodePanel();
      } else {
        setState(() => _showEpisodePanel = true);
        if (context.reduceMotion) {
          _episodePanelController.value = 1.0;
        } else {
          _episodePanelController.forward();
        }
      }
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(AppMotion.controlsDwell, () {
      if (mounted) {
        setState(() => _controlsVisible = false);
        _syncControlsAnim();
      }
    });
  }


  void _togglePlay() {
    if (_isPlaying) {
      _engine?.pause();
    } else {
      _engine?.play();
    }
  }

  /// 通用底部抽屉（毛玻璃风格，与 TrackSelectorSheet 一致）
  void _showOptionSheet({
    required String title,
    required List<Map<String, dynamic>> options,
    required int currentIndex,
    required void Function(int index) onSelect,
  }) {
    _closeAllPanels();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      useSafeArea: true,
      builder: (_) => _OptionBottomSheet(
        title: title,
        options: options,
        currentIndex: currentIndex,
        onSelect: onSelect,
      ),
    );
  }

  /// 播放速度选择
  void _openSpeedSheet() {
    _showOptionSheet(
      title: '播放速度',
      options: _speeds.map((s) => {'label': '${s}x'}).toList(),
      currentIndex: _currentSpeedIndex,
      onSelect: (i) {
        _currentSpeedIndex = i;
        _speed = _speeds[i];
        _engine?.setSpeed(_speed);
        setState(() {});
      },
    );
  }

  String _qualityLabel(String q) => switch (q) {
        'auto' => '自动',
        '720p' => '720P',
        '1080p' => '1080P',
        '4k' => '4K',
        'original' => '原画',
        _ => q,
      };

  /// 切换画质：重新请求转码流（带码率上限）并保留播放进度
  Future<void> _setQuality(String q) async {
    if (q == _currentQuality) return;
    final svc = widget.service;
    if (svc == null) {
      setState(() => _currentQuality = q);
      return;
    }
    final oldQ = _currentQuality;
    setState(() => _currentQuality = q);
    try {
      final ps = ref.read(playerSettingsProvider);
      final url = await svc.getStreamUrl(_activeMedia.id, quality: q, burnInSubtitle: ps.burnInSubtitle);
      _transcodeFallbackUrl = svc.lastTranscodeUrl;
      _transcodeTried = false; // 换了新流,给新流一次直连机会
      if (!mounted) return;
      _currentStreamUrl = url; // 记录新画质流地址（MediaSourceId 可能随转码源变化）
      final pos = _position;
      final wasPlaying = _isPlaying;
      await _engine?.stop();
      await _engine?.open(url: url, httpHeaders: svc.streamHeaders, autoPlay: false);
      if (pos > Duration.zero) await _engine?.seek(pos);
      if (wasPlaying) await _engine?.play();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已切换画质：${_qualityLabel(q)}'), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      AppLog.w('Player', '切换画质失败: $e');
      if (mounted) {
        setState(() => _currentQuality = oldQ);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画质切换失败：$e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  /// 画幅模式选择（右侧滑入面板）
  void _openFitSheet() {
    _toggleRightPanel('fit');
  }

  /// 加载外挂字幕文件（Phase 2）
  /// ExoPlayer 引擎使用 Flutter 层叠加渲染
  /// MPV 引擎通过 libmpv sub-files 加载到原生层
  Future<void> _loadExternalSubtitle() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'vtt', 'ass', 'ssa'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;

      await _applyExternalSubtitleFile(path);
    } catch (e) {
      AppLog.e('Player', '加载外挂字幕异常: $e');
      if (mounted) _showTopToast('加载字幕异常: $e');
    }
  }

  /// 在线搜索字幕（OpenSubtitles）
  Future<void> _openOnlineSubtitleSearch() async {
    if (!OpenSubtitlesService.isConfigured) {
      _showTopToast('请先在 设置 → 播放设置 → 在线字幕 中配置 OpenSubtitles 账号与 API Key');
      return;
    }
    _closeAllPanels();
    final isEpisode = _activeMedia.type == MediaType.episode;
    if (!mounted) return;
    await OnlineSubtitleSearchSheet.show(
      context,
      service: OpenSubtitlesService(),
      initialQuery: _activeMedia.seriesTitle ?? _activeMedia.title,
      season: isEpisode ? _activeMedia.seasonNumber : null,
      episode: isEpisode ? _activeMedia.episodeNumber : null,
      onDownloaded: _applyExternalSubtitleFile,
    );
  }

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  /// 顶部浮动轻提示：不遮底部字幕/进度条，1.5s 自动淡出
  void _showTopToast(String msg) {
    _toastTimer?.cancel();
    _toastEntry?.remove();
    final overlay = Overlay.of(context);
    final topInset = MediaQuery.of(context).padding.top + 12;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: topInset,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
    _toastEntry = entry;
    overlay.insert(entry);
    _toastTimer = Timer(const Duration(milliseconds: 1500), () {
      entry.remove();
      if (_toastEntry == entry) _toastEntry = null;
    });
  }

  /// 把字幕文件交给引擎加载（本地挑选 / 在线下载共用）
  Future<void> _applyExternalSubtitleFile(String path) async {
    if (!mounted) return;
    // 外挂 ASS：**先归一化字号再交给内核**。mpv 在 sub-ass-override=no（保留脚本
    // 样式，用户设置）下 sub-font-size 对 ASS 完全不生效，而下载来的 ASS 常带
    // 小字号样式 → 外挂明显小于内封。这里只改文件的 Fontsize 字段，
    // \pos/\move/\k/	 等事件标签逐字节不变 —— 特效与定位不受影响。
    final isAssFile = path.toLowerCase().endsWith('.ass') ||
        path.toLowerCase().endsWith('.ssa');
    var effectivePath = path;
    if (isAssFile) {
      final normalized = await _normalizeAssFontSizeFile(path);
      if (normalized != null) effectivePath = normalized;
    }
    if (!mounted) return;
    // ⚠️ 顺序关键：**先关原生字幕轨，再加载外挂**。
    // 真机实证（2026-09-27）：此前只对 Exo 关原生轨，mpv 两内核不关 → 内封轨
    // 与外挂轨同时在选 → 屏幕上出现**两行字幕**（内封 ASS 大、外挂小）。
    // 旧注释担心"sid=no 会把刚加载的外挂一起隐藏"——那只在 sub-add **之后**
    // 才成立；放在加载之前，sub-add 的 select 会把外挂选回来，正好单轨显示。
    await _engine?.setSubtitleTrack(-1);
    if (!mounted) return;
    final success =
        await _engine?.loadExternalSubtitle(effectivePath) ?? false;
    if (!mounted) return;

    if (success) {
      // ── libass 特效渲染（Exo + 外挂 ASS/SSA）──
      // Exo 的 Media3 渲染 ASS 只出纯文本（无 libass）,Dart 层解析也只有
      // 基础样式——原生 libass 桥(jniLibs/libass.so)在 TV 端已验证,这里
      // 接管渲染得到完整特效(定位/卡拉OK/动画)。失败自动回退 Dart 叠加层。
      _stopLibass();
      final isAss = isAssFile;
      var libassOn = false;
      if (_engineType == PlayerEngineType.exo) {
        // **普通字幕（SRT/VTT）也交给 libass**：libass 内置默认样式是
        // 18px @ PlayRes 288 = 6.25% 视频高度（与 mpv 默认一致），而 Exo 原生
        // SubtitleView / Dart 叠加层那两条路径用 0.06×用户缩放，缩放设为 0.5
        // 就只剩 3% —— 真机实证「外挂普通字幕明显小于内封」。
        // ASS 是否强制统一样式由用户设置决定（语义与 mpv 的 sub-ass-override 对齐）。
        final force =
            !isAss || ref.read(playerSettingsProvider).subtitleAssOverride;
        libassOn =
            await _tryStartLibassFromFile(effectivePath, forceStyle: force);
      }
      if (!mounted) return;
      if (libassOn) {
        // libass 层接管:置 false 让 Dart cue 叠加层隐藏,防双层渲染
        setState(() => _externalSubtitleLoaded = false);
        _showTopToast('字幕已加载（ASS 特效渲染）');
        return;
      }
      // ExoPlayer 引擎：更新外挂字幕状态，触发 UI 叠加层渲染
      final manager = _engine?.externalSubtitleManager;
      if (manager != null) {
        setState(() {
          _externalSubtitleLoaded = true;
        });
      }
      // 轻提示：顶部浮动（去掉条数等调试信息，不遮底部字幕/进度条）
      _showTopToast('字幕已加载');
    } else {
      _showTopToast('字幕加载失败：${_engine?.externalSubtitleManager?.error ?? "未知错误"}');
    }
  }

  // ===== libass 原生 ASS 特效渲染（TV 端同款管线）=====

  /// 尝试用 libass 加载本地 ASS/SSA 字幕文件。成功返回 true 并启动渲染循环。
  /// 把外挂 ASS 的字号归一到「视频高度 8% × 用户缩放」，写入临时 .ass 返回路径。
  ///
  /// 失败/无需改写返回 null，调用方继续用原文件（绝不因它阻断播放）。
  Future<String?> _normalizeAssFontSizeFile(String path) async {
    try {
      final raw = await File(path).readAsString();
      final ratio =
          0.08 * ref.read(playerSettingsProvider).subtitleFontSizeScale;
      final out = normalizeAssFontSize(raw, ratio);
      if (out == raw) return null;
      final dir = await getTemporaryDirectory();
      final target = File('${dir.path}/sub_norm_${path.hashCode}.ass');
      await target.writeAsString(out, flush: true);
      AppLog.i('Player',
          '外挂 ASS 字号归一化: 目标 ${(ratio * 100).toStringAsFixed(1)}% 视频高度 → ${target.path}');
      return target.path;
    } catch (e) {
      AppLog.w('Player', '外挂 ASS 字号归一化失败（用原文件）: $e');
      return null;
    }
  }

  Future<bool> _tryStartLibassFromFile(String path,
      {bool forceStyle = true}) async {
    try {
      final state = _engine?.currentState;
      final vw = state?.videoWidth ?? 0;
      final vh = state?.videoHeight ?? 0;
      // ASS 的 PlayRes 坐标基于视频分辨率,取不到就退 1080p
      _libassWidth = vw > 0 ? vw : 1920;
      _libassHeight = vh > 0 ? vh : 1080;

      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) return false;
      final inited = await LibassBridge.init(width: _libassWidth, height: _libassHeight);
      if (!inited) {
        AppLog.w('Player', 'libass 不可用,回退 Dart 叠加层渲染');
        return false;
      }
      // 先下发样式覆盖再加载：普通字幕(SRT/VTT)靠它拿到 libass 的正常字号
      await LibassBridge.setStyle(libassStyleArgs(
        ref.read(playerSettingsProvider),
        forceStyle: forceStyle,
      ));
      final loaded = await LibassBridge.loadData(bytes);
      if (!loaded) {
        AppLog.w('Player', 'libass 加载字幕失败');
        await LibassBridge.release();
        return false;
      }
      if (!mounted) {
        await LibassBridge.release();
        return false;
      }
      setState(() => _libassActive = true);
      _startLibassRender();
      AppLog.i('Player', 'libass 特效字幕已激活: ${bytes.length} bytes, ${_libassWidth}x$_libassHeight');
      return true;
    } catch (e) {
      AppLog.w('Player', 'libass 加载异常: $e');
      return false;
    }
  }

  /// libass 渲染循环:200ms 一拍,三道闸防抖(TV 端同款)——
  /// ① 上一帧在飞就跳过(渲染慢于间隔时回调叠加);② 像素逐字节相同直接返回
  /// (省一次整帧解码);③ await 后复核状态,防停止后落地帧回填。
  void _startLibassRender() {
    _libassRenderTimer?.cancel();
    _libassRenderTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
      if (!_libassActive || _engine == null || !mounted) return;
      if (_libassRendering) return;
      _libassRendering = true;
      try {
        final posMs =
            _smoothPosition.inMilliseconds; // 平滑时钟,出入点不量化到半秒
        final pixels = await LibassBridge.render(posMs, _libassWidth, _libassHeight);
        if (pixels == null || pixels.isEmpty || !mounted) return;
        final prev = _libassLastPixels;
        if (prev != null && prev.length == pixels.length && _sameBytes(prev, pixels)) {
          return; // 字幕没变,这一拍什么都不做
        }
        _libassLastPixels = pixels;
        final completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          pixels,
          _libassWidth,
          _libassHeight,
          ui.PixelFormat.rgba8888,
          completer.complete,
        );
        final newImage = await completer.future;
        if (!mounted || !_libassActive) {
          newImage.dispose();
          return;
        }
        _libassImage.value?.dispose();
        _libassImage.value = newImage;
      } finally {
        _libassRendering = false;
      }
    });
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 停止 libass 渲染并释放原生资源（切轨/关字幕/换引擎/退出时调用）
  void _stopLibass() {
    _libassRenderTimer?.cancel();
    _libassRenderTimer = null;
    _libassImage.value?.dispose();
    _libassImage.value = null;
    _libassLastPixels = null;
    if (_libassActive) {
      _libassActive = false;
      LibassBridge.release();
    }
  }

  /// 字幕轨道选择统一处理（右侧面板 / 底部 sheet 共用）
  /// -1: 关闭；i >= 0: _subtitleTracks[i]（可能是原生轨或服务端轨）
  Future<void> _applySubtitleTrack(int i) async {
    if (i < 0) {
      // 关闭字幕：记住用户显式关闭的选择，本会话不再自动启用默认轨
      // （视频带硬字幕的片源，自动叠加软字幕会产生双层）
      _stopLibass(); // 关闭字幕同时停 libass 特效层
      _userDisabledSubtitles = true;
      _autoDefaultSubtitleApplied = true;
      if (_currentSubtitleIndex >= 0) {
        await _engine?.setSubtitleTrack(-1);
      }
      if (mounted) {
        setState(() {
          _currentSubtitleIndex = -1;
          _externalSubtitleLoaded = false;
        });
      }
      return;
    }
    if (i >= _subtitleTracks.length) return;
    final track = _subtitleTracks[i];
    AppLog.i('Player', 'applySubtitleTrack: index=$i, isServer=${track['server']}, lang=${track['Language'] ?? track['language']}, isDefault=${track['IsDefault'] ?? track['isDefault']}, title=${track['Title'] ?? track['title']}');
    // "显示全部 N 条字幕"占位轨：展开全量列表（不停 libass——这只是
    // 展开列表,不是切轨,否则正在看的特效字幕会凭空消失）
    if (track['showAll'] == true) {
      setState(() {
        _showAllSubtitleTracks = true;
        _subtitleTracks = _filterSubtitleList(_fullSubtitleTracks);
      });
      _showTopToast('已显示全部字幕轨');
      return;
    }
    // 用户主动选择了某条字幕轨 → 取消"已关闭"记忆;先停 libass(选中的
    // 又是外挂 ASS 时,_applyExternalSubtitleFile 会重新启动)
    _stopLibass();
    _userDisabledSubtitles = false;
    // 服务器驱动列表：nativeIndex 非空 = 引擎里有对应内嵌轨，直接原生直切
    // （Exo/mpv 从视频流读取，不依赖服务器按需提取）；为空 = 纯服务端轨
    // （外挂 srt/服务器独有），下载后走外挂字幕管线渲染。
    final hasNative = track['nativeIndex'] != null;
    if (!hasNative) {
      // 服务端字幕轨：转码流的内嵌轨不进入引擎 currentTracks，
      // 下载字幕数据后走外挂字幕管线（Flutter overlay / mpv 原生）渲染。
      // 先关闭原生字幕轨，避免原生 SubtitleView 与外挂 overlay 双层渲染同一句对白
      await _engine?.setSubtitleTrack(-1);
      final prevIndex = _currentSubtitleIndex;
      setState(() {
        _currentSubtitleIndex = i;
        _serverSubtitleLoading = true;
      });
      final path = await _downloadServerSubtitle(track);
      if (!mounted) return;
      setState(() => _serverSubtitleLoading = false);
      if (path != null) {
        await _applyExternalSubtitleFile(path);
      } else if (mounted) {
        // 服务端字幕下载失败：若该服务端轨有同语言同编码的原生配对轨
        // （内嵌字幕，Exo 直接从视频流读取、不依赖服务器提取），回退原生轨。
        final nativeIdx = track['nativeIndex'];
        if (nativeIdx is int &&
            nativeIdx >= 0 &&
            (_engineType == PlayerEngineType.exo ||
                _engineType == PlayerEngineType.nativeSurface)) {
          await _engine?.setSubtitleTrack(nativeIdx);
          if (mounted) {
            setState(() {
              _currentSubtitleIndex = i;
              _externalSubtitleLoaded = false;
            });
          }
          _showTopToast('服务端字幕不可用，已切换原生字幕轨');
          AppLog.w('Player', '服务端字幕下载失败，回退原生轨: nativeIndex=$nativeIdx');
          return;
        }
        // 失败：回退选中态，并给出具体原因便于排查
        setState(() => _currentSubtitleIndex = prevIndex);
        final reason = _subtitleDownloadError.isNotEmpty
            ? _subtitleDownloadError
            : '请检查服务器连接';
        _showTopToast('字幕下载失败：$reason');
      }
      return;
    }
    // 原生轨（排序/去重后 merged 索引 ≠ 引擎原生索引，用记录的真实索引切换）
    final nativeIdx = track['nativeIndex'];
    await _engine?.setSubtitleTrack(nativeIdx is int ? nativeIdx : i);
    if (mounted) {
      setState(() {
        _currentSubtitleIndex = i;
        // 切换原生轨时清除外挂字幕状态
        _externalSubtitleLoaded = false;
      });
      // 操作反馈：原生轨切换没有下载流程，用户看不到任何提示会误以为没生效
      final title = track['title']?.toString() ?? '字幕 $i';
      _showTopToast('字幕：$title');
    }
  }

  /// 切换音轨：i 为服务器驱动列表中的下标；引擎实际切换用 nativeIndex
  /// （引擎轨与服务器流的映射在 _loadTracks 中建立，MPV=类型内序号、
  /// Exo=引擎轨列表下标）。列表条目与引擎轨一一对应，nativeIndex 缺失时
  /// 按下标兜底（理论不可达）。
  Future<void> _applyAudioTrack(int i) async {
    if (i < 0 || i >= _audioTracks.length) return;
    final native = _audioTracks[i]['nativeIndex'];
    await _engine?.setAudioTrack(native is int ? native : i);
    if (mounted) setState(() => _currentAudioIndex = i);
  }

  /// 下载服务端字幕轨到本地缓存，返回文件路径；失败返回 null（原因写入 [_subtitleDownloadError]）
  /// 缓存键 = itemId|MediaSourceId|index|ext：同一字幕只下载一次，
  /// Emby 首次按需提取内嵌字幕可能要几十秒，缓存后重播/切回秒出。
  String _subtitleDownloadError = '';
  Future<String?> _downloadServerSubtitle(Map<String, dynamic> track) async {
    _subtitleDownloadError = '';
    try {
      final svc = widget.service;
      if (svc == null) return null;
      final codec = (track['Codec'] ?? track['codec'] ?? '').toString().toLowerCase();
      final ext = switch (codec) {
        'ass' || 'ssa' => 'ass',
        'vtt' || 'webvtt' => 'vtt',
        _ => 'srt',
      };
      final itemId = _activeMedia.id;
      final msId = Uri.tryParse(_currentStreamUrl)?.queryParameters['MediaSourceId'] ?? '';
      // 优先用服务端给的 DeliveryUrl；但 Emby/Jellyfin 的 Item 详情里 MediaStream
      // 常常不带 DeliveryUrl（只有 PlaybackInfo 才填充），此时按已知 id 自行构造，
      // 指向同一个官方字幕流端点：/Videos/{itemId}/{mediaSourceId}/Subtitles/{index}/Stream.{ext}
      var deliveryUrl = track['DeliveryUrl']?.toString() ?? '';
      if (deliveryUrl.isEmpty) {
        final index = (track['Index'] ?? track['index'])?.toString() ?? '0';
        deliveryUrl = '/Videos/$itemId/${msId.isEmpty ? itemId : msId}/Subtitles/$index/Stream.$ext';
        AppLog.d('Player', 'DeliveryUrl 为空，构造字幕 URL: $deliveryUrl (codec=$codec)');
      }
      final fullUrl = deliveryUrl.startsWith('http')
          ? deliveryUrl
          : '${svc.baseUrl}$deliveryUrl';
      // 认证：请求头 + api_key 查询参数双保险。部分服务器/代理会剥离自定义头，
      // 而图片一直靠 URL 里的 api_key 工作，字幕下载也应同样兼容。
      final apiKey = (svc is EmbyService) ? svc.apiKey : '';
      final headers = Map<String, String>.from(svc.streamHeaders);
      var url = fullUrl;
      if (apiKey.isNotEmpty && !Uri.parse(url).queryParameters.containsKey('api_key')) {
        url = '${url}${url.contains('?') ? '&' : '?'}api_key=$apiKey';
      }
      // 本地缓存命中直接返回，不再请求服务器
      final index = (track['Index'] ?? track['index'])?.toString() ?? '0';
      final cacheKey = md5.convert(utf8.encode('$itemId|$msId|$index|$ext')).toString();
      final cacheDir = Directory('${(await getApplicationSupportDirectory()).path}/subtitle_cache');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
      final cacheFile = File('${cacheDir.path}/$cacheKey.$ext');
      if (await cacheFile.exists() && await cacheFile.length() > 0) {
        AppLog.i('Player', '服务端字幕命中本地缓存: $cacheKey.$ext');
        return cacheFile.path;
      }
      // 下载（接收超时 60s：NAS/Emby 首次提取内嵌字幕可能极慢，默认 15s 会误判失败；
      // 超时后等 3s 重试一次——第一次请求往往已在服务器侧触发提取，重试即命中）
      var bytes = await _fetchSubtitleBytes(url, headers);
      // 兜底：若流 URL 缺 MediaSourceId 导致用了 itemId 当 mediaSourceId（部分
      // 服务器对错误路径返回空 200），换真实 MediaSourceId 形式重试一次。
      if (bytes.isEmpty && deliveryUrl.contains('/Videos/')) {
        if (msId.isNotEmpty && !deliveryUrl.contains('/$msId/')) {
          final altPath = '/Videos/$itemId/$msId/Subtitles/$index/Stream.$ext';
          final altUrl = '${svc.baseUrl}$altPath';
          AppLog.w('Player', '字幕空响应，回退重试: $altPath');
          bytes = await _fetchSubtitleBytes(altUrl, headers);
        }
      }
      if (bytes.isEmpty) {
        _subtitleDownloadError = '服务器返回空内容';
        AppLog.e('Player', '服务端字幕下载失败: 空内容 url=$url');
        return null;
      }
      await cacheFile.writeAsBytes(bytes);
      AppLog.i('Player', '服务端字幕已下载: ${bytes.length} bytes, codec=$codec (缓存 $cacheKey.$ext)');
      return cacheFile.path;
    } catch (e) {
      AppLog.e('Player', '服务端字幕下载失败: $e');
      if (e is DioException) {
        _subtitleDownloadError = 'HTTP ${e.response?.statusCode ?? '?'} ${e.type.name}';
      } else {
        _subtitleDownloadError = e.toString();
      }
      return null;
    }
  }  /// 字幕下载：单次 30s 接收超时（不重试）。内嵌字幕轨已优先走原生渲染，不经过这里；
  /// 服务端独有轨（外挂 srt/ass）正常应快速返回，30s 未响应说明服务器提取挂起
  /// （FNNAS/Emby 对 mkv 内嵌字幕实测 >90s 无响应），及时放弃避免"加载中"无限等待。
  Future<List<int>> _fetchSubtitleBytes(String url, Map<String, String> headers) async {
    return HttpClient.getBytes(url, headers: headers, timeout: const Duration(seconds: 30));
  }

  /// 后台预取常用服务端字幕（默认轨 + 中文 + 英文，最多 3 条）到本地缓存。
  /// 顺序下载避免同时打爆 NAS；不阻塞播放、不显示"字幕加载中"提示（那是用户主动
  /// 切换时才有的反馈）；已缓存/位图字幕自动跳过（[_downloadServerSubtitle] 内部处理）。
  /// 轨道尚未就绪时（首帧空列表）直接返回且不置位标志，留给 _loadTracks 重试。
  Future<void> _prefetchServerSubtitles(List<Map<String, dynamic>> tracks) async {
    if (_isDisposed || widget.service == null) return;
    final wanted = <Map<String, dynamic>>[];
    for (final t in tracks) {
      if (t['nativeIndex'] != null) continue; // 有原生配对的内嵌轨:原生直切,无需预取
      if (t['isBitmap'] == true) continue; // 位图字幕（PGS/SUP）无法渲染，跳过
      final lang = (t['Language'] ?? t['language'] ?? '').toString().toLowerCase();
      final isDefault = t['IsDefault'] == true || t['isDefault'] == true;
      if (isDefault ||
          const {'zho', 'chi', 'cmn', 'yue'}.contains(lang) ||
          lang == 'eng') {
        wanted.add(t);
      }
      if (wanted.length >= 3) break; // 默认 + 中文 + 英文 三条即可
    }
    if (wanted.isEmpty) return;
    _subtitlePrefetched = true; // 真正开始预取才置位，空列表时不影响后续重试
    final langs = wanted.map((t) => (t['Language'] ?? t['language'] ?? '?')).join(',');
    AppLog.i('Player', '后台预取字幕($langs): ${wanted.length} 条');
    for (final t in wanted) {
      if (_isDisposed) return;
      try {
        await _downloadServerSubtitle(t);
      } catch (e) {
        AppLog.w('Player', '后台预取字幕失败: $e');
      }
    }
    if (!_isDisposed) AppLog.i('Player', '后台预取字幕完成');
  }

  /// 打开/切换右侧面板（弹幕/更多）：同面板再次点击 = 关闭；其他面板打开时直接切换；
  /// 选集面板打开时先收起。顶栏「弹」「⋯」共用。
  void _toggleRightPanel(String type) {
    if (_showEpisodePanel) _animateCloseEpisodePanel();
    setState(() {
      _rightPanelType = _rightPanelType == type ? null : type;
    });
  }

  /// 渲染"更多"面板及其二级选项（画质/切换内核/字幕样式），全部右侧滑入、
  /// 带 ‹ 返回宫格。外挂字幕/在线搜索为系统弹窗，直接关闭面板后调用。
  ///
  /// [type] 由 RightPanelHost 传入而非直接读 `_rightPanelType` —— 退场动画
  /// 期间 `_rightPanelType` 已经是 null，宿主会用最后一个非空类型继续构建。
  Widget _buildMoreRightPanel(String type) {
    if (type == 'quality') {
      const options = ['auto', '720p', '1080p', '4k', 'original'];
      return RightOptionListPanel(
        title: '画质',
        options: options.map((q) => {'label': _qualityLabel(q)}).toList(),
        currentIndex: options.indexOf(_currentQuality).clamp(0, options.length - 1),
        onBack: () => setState(() => _rightPanelType = 'more'),
        onClose: () => setState(() => _rightPanelType = null),
        onSelect: (i) {
          setState(() => _rightPanelType = null);
          _setQuality(options[i]);
        },
      );
    }
    if (type == 'engine') {
      final engines = PlayerEngineType.values;
      return RightOptionListPanel(
        title: '切换内核',
        options: engines.map((e) => {'label': e.label}).toList(),
        currentIndex: engines.indexOf(_engineType),
        onBack: () => setState(() => _rightPanelType = 'more'),
        onClose: () => setState(() => _rightPanelType = null),
        onSelect: (i) async {
          setState(() => _rightPanelType = null);
          if (engines[i] != _engineType) await _switchEngine(engines[i]);
        },
      );
    }
    if (type == 'style') {
      return RightPanelShell(
        title: '字幕样式',
        width: 320,
        onBack: () => setState(() => _rightPanelType = 'more'),
        onClose: () => setState(() => _rightPanelType = null),
        body: SubtitleStyleContent(
          engine: _engine,
          onDone: () => setState(() => _rightPanelType = null),
        ),
      );
    }
    // 'more' 宫格
    return MoreRightPanel(
      qualityLabel: _qualityLabel(_currentQuality),
      engineLabel: _engineType.shortLabel,
      externalSubtitleLoaded: _externalSubtitleLoaded,
      onQuality: () => setState(() => _rightPanelType = 'quality'),
      onEngine: () => setState(() => _rightPanelType = 'engine'),
      onStyle: () => setState(() => _rightPanelType = 'style'),
      onExternalSubtitle: () {
        setState(() => _rightPanelType = null);
        _loadExternalSubtitle();
      },
      onOnlineSearch: () {
        setState(() => _rightPanelType = null);
        _openOnlineSubtitleSearch();
      },
      onMore: () => _showTopToast('更多功能开发中'),
      onClose: () => setState(() => _rightPanelType = null),
    );
  }

  void _seekRelative(int seconds) {
    final newPos = _position + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > _duration ? _duration : newPos);
    if (newPos < Duration.zero) {
      _engine?.seek(Duration.zero);
    } else if (newPos > _duration) {
      _engine?.seek(_duration);
    } else {
      _engine?.seek(newPos);
    }
    // 清理弹幕状态并重置扫描游标
    _danmakuController.seekTo(clamped);
  }

  void _toggleDanmaku() {
    setState(() {
      _danmakuEnabled = !_danmakuEnabled;
      _danmakuController.setEnabled(_danmakuEnabled);
    });
  }

  void _setFitMode(BoxFit? mode) {
    if (mode == null) {
      // 自适应模式：根据视频和屏幕宽高比自动选择
      _isAutoFit = true;
      final actual = _computeAutoFit();
      setState(() { _currentFitMode = actual; });
      _engine?.setFitMode(actual);
    } else {
      _isAutoFit = false;
      setState(() { _currentFitMode = mode; });
      _engine?.setFitMode(mode);
    }
  }

  /// 自适应：完整显示整幅画面，按屏幕可用空间等比缩放（contain）。
  ///
  /// 之前返回 fitWidth/fitHeight（铺满一边、裁掉另一边），与「自适应=
  /// 完整显示」的用户预期相反，看起来像没作用。黑边按屏幕留白自适应。
  BoxFit _computeAutoFit() {
    return BoxFit.contain;
  }

  void _onFitModeChanged() {
    if (mounted && _engine != null) {
      setState(() {
        _currentFitMode = _engine!.fitMode;
      });
    }
  }


  Future<void> _switchEngine(PlayerEngineType type) async {
    if (type == _engineType) return;
    if (_engine == null) return;
    _stopLibass(); // libass 层绑定当前引擎,切内核必须重建(新内核是 MPV 则自带特效渲染)
    final manager = ref.read(playerManagerProvider);
    try {
      _stateSub?.cancel();
      _stateSub = null;

      // 保存当前状态，引擎切换后恢复
      final oldEngine = _engine!;
      final restoredVolume = _volume;
      final restoredSpeed = _speed;
      final restoredFitMode = _currentFitMode;

      _tracksLoaded = false;
      _showedAudioError = false;
      // 切换内核时清空外挂字幕状态：旧引擎的 cue 列表/选中态对新引擎无意义，
      // 残留会导致原生轨与外挂 overlay 双层渲染或面板选中态错乱。
      _externalSubtitleLoaded = false;
      _currentSubtitleIndex = -1;

      // 解绑旧引擎的 fitMode 监听
      oldEngine.fitModeNotifier.removeListener(_onFitModeChanged);

      _engine = await manager.switchEngine(type);
      _engineType = type;
      _engineKey++; // 强制视频 widget 重建，避免旧 engine 残留引发 disposed 错误

      // 恢复音量、速度和画幅模式
      _engine?.setVolume(restoredVolume);
      _engine?.setSpeed(restoredSpeed);
      _engine?.setFitMode(restoredFitMode);
      // 字幕样式不跨引擎继承：不重发就退回内核默认（mpv 的 sub-font-size=38
      // ≈5.3% 屏高，比我们 58/720≈8% 的基准小 1.5 倍）—— 真机实证「切到
      // MPV原生 后外挂字幕明显小」。TV 端切换后本来就重发，手机端此前漏了。
      _engine?.applySubtitleStyle(ref.read(playerSettingsProvider));

      // 绑定新引擎的 fitMode 监听
      _engine?.fitModeNotifier.addListener(_onFitModeChanged);

      _stateSub = _engine!.stateStream.listen((state) {
        if (mounted && !_isDisposed) {
          // 先同步弹幕时钟与位置 —— 独立于 setState，任何后续异常都不影响弹幕时间轴
          try {
            _danmakuController.updateConfig(
              DanmakuRenderConfig.fromSettings(_cachedDisplay, playbackSpeed: _speed),
            );
            _danmakuController.updateActive(state.position.inMilliseconds);
          } catch (_) {}
          setState(() {
            _isPlaying = state.isPlaying;
            _isBuffering = state.isBuffering;
            if (_isPlaying) {
              _startProgressReporting();
              _danmakuController.start();
              if (!_playbackStartReported) {
                _playbackStartReported = true;
                try {
                  final svc = ref.read(currentMediaServerServiceProvider);
                  if (svc is EmbyService) {
                    svc.refreshPlaySession();
                    svc.reportPlaybackStart(_activeMedia.id);
                  }
                } catch (_) {}
              }
            } else {
              _progressTimer?.cancel();
              _uiUpdateTimer?.cancel();
              _danmakuController.pause();
            }
            _position = state.position;
            _lastStateTime = DateTime.now();
            // 对于 ISO/HDMV 等容器格式，MPV 可能报告错误的时长（0 或极大缩水）
            // 当服务器提供已知时长且引擎时长明显异常时，使用服务器时长
            final engineDur = state.duration;
            final serverDurSec = _activeMedia.duration; // 服务器提供的时长（秒）
            if (serverDurSec > 0 && engineDur > Duration.zero) {
              final serverDurMs = serverDurSec * 1000;
              // 如果引擎时长不到服务器时长的一半，可能是 ISO/HDMV 格式，使用服务器时长
              if (engineDur.inMilliseconds < serverDurMs * 0.6) {
                _duration = Duration(seconds: serverDurSec);
              } else {
                _duration = engineDur;
              }
            } else {
              _duration = engineDur;
            }
            // 续播：首次获取到正确时长后 seek 到上次位置
            if (!_resumeApplied && widget.resumePositionMs != null && _duration.inMilliseconds > widget.resumePositionMs!) {
              _resumeApplied = true;
              final resumePos = Duration(milliseconds: widget.resumePositionMs!);
              AppLog.i('Player', 'Resume → seek to ${resumePos.inMinutes}:${(resumePos.inSeconds % 60).toString().padLeft(2, '0')}');
              _engine?.seek(resumePos);
              // 弹幕游标同步到续播位置，避免续播后弹幕时间轴错位
              _danmakuController.seekTo(resumePos);
            }
            _buffer = state.buffer;
            _speed = state.speed;
            _volume = state.volume;
            // 硬件音量键/系统音量变化时同步持久化（防抖），下次切集/重开沿用
            if ((_volume - _lastSavedVolume).abs() > 0.02) _saveVolumeBrightness();
            _engineType = state.engineType;
          });
          // ── 自适应画幅：视频尺寸变化时重新计算 ──
          if (_isAutoFit && state.videoWidth > 0 && state.videoHeight > 0) {
            final actual = _computeAutoFit();
            if (actual != _currentFitMode) {
              setState(() { _currentFitMode = actual; });
              _engine?.setFitMode(actual);
            }
          }
          // ── 跳过片头/片尾检测 ──
          _checkSkipState(state.position);

          // ── 下一集倒计时检测 ──
          _checkNextEpisode(state.position, state.duration);

          if (state.duration > Duration.zero && !_tracksLoaded) {
            _tracksLoaded = true;
            _loadTracks();
          }

          if (state.error?.isNotEmpty == true) {
            final err = state.error!.toLowerCase();
            if (err.contains('codec') || err.contains('audio') || err.contains('truehd') || err.contains('dts')) {
              if (!_showedAudioError) {
                _showedAudioError = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_isDisposed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('音频解码失败，建议切换到其他音轨或ExoPlayer内核'),
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: '切换内核',
                          onPressed: () {
                            final mgr = ref.read(playerManagerProvider);
                            mgr.switchEngine(PlayerEngineType.exo);
                          },
                        ),
                      ),
                    );
                  }
                });
              }
            }
          }
        }
      });

      // 强制重建以清除旧 engine 的 widget
      if (mounted) setState(() {
        _subtitleTracks = [];
        _audioTracks = [];
      });

      // 旧 engine 已被 manager 接管，确保它不再被本 screen 引用
      oldEngine; // 标记引用防止 lint 警告

      if (mounted) setState(() {
        // 内核切换后重置控制栏
      });
    } catch (e) {
      AppLog.e('Player', '切换内核失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换内核失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 水平拖拽 seek 状态（累积亚像素，避免 round() 归零死区）
  double _accumulatedSeek = 0;
  bool _seekCapsuleVisible = false;
  String _seekCapsuleLabel = '';

  void _handleHorizontalDragStart(DragStartDetails d) {
    if (_duration.inMilliseconds <= 0) return;
    _accumulatedSeek = 0;
    setState(() {
      _seekCapsuleVisible = true;
      _seekCapsuleLabel = _formatTime(_position);
    });
  }

  void _handleHorizontalDrag(DragUpdateDetails d) {
    if (_duration.inMilliseconds <= 0) return;
    final delta = d.delta.dx;
    final sw = MediaQuery.of(context).size.width;
    _accumulatedSeek += (delta / sw) * 60;
    final whole = _accumulatedSeek.truncate();
    if (whole != 0) {
      _accumulatedSeek -= whole;
      _seekRelative(whole);
      // 本地预测位置，不依赖引擎流回传，避免拖拽滞后
      var predicted = _position + Duration(seconds: whole);
      if (predicted < Duration.zero) predicted = Duration.zero;
      if (predicted > _duration) predicted = _duration;
      setState(() {
        _position = predicted;
        _lastStateTime = DateTime.now();
        _seekCapsuleLabel = _formatTime(_position);
      });
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails d) {
    if (_seekCapsuleVisible) {
      setState(() => _seekCapsuleVisible = false);
    }
  }

  void _handleHorizontalDragCancel() {
    if (_seekCapsuleVisible) {
      setState(() => _seekCapsuleVisible = false);
    }
  }

  // 上下滑动手势状态
  bool _gestureVerticalActive = false;
  bool _gestureVerticalIsBrightness = false;
  double _gestureStartY = 0;
  double _gestureStartValue = 0;

  void _handleVerticalDrag(DragUpdateDetails details) {
    if (_hasAnyPanelOpen) return;

    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;

    // 控制栏可见时，避开顶栏和底部控制按钮区域，中间空白区仍可调节亮度/音量
    if (_controlsVisible) {
      final topBarHeight = MediaQuery.of(context).padding.top + 72;
      final bottomZone = _screenHeight - (MediaQuery.of(context).padding.bottom + 130);
      if (dy < topBarHeight || dy > bottomZone) return;
    }

    final isLeftSide = dx < _screenWidth * 0.5;

    if (!_gestureVerticalActive) {
      _gestureVerticalActive = true;
      _gestureStartY = dy;
      _gestureStartValue = isLeftSide ? _brightness : _volume;
      _gestureVerticalIsBrightness = isLeftSide;
      return;
    }

    final delta = _gestureStartY - dy;
    final sh = _screenHeight;
    if (sh <= 0) return;
    final ratio = delta / sh;
    final newValue = (_gestureStartValue + ratio).clamp(0.0, 1.0);

    if (_gestureVerticalIsBrightness) {
      final clamped = newValue.clamp(0.05, 1.0);
      if ((clamped - _brightness).abs() < 0.005) return;
      setState(() {
        _brightness = clamped;
        _showBrightnessIndicator = true;
        _showVolumeIndicator = false;
      });
      _applyBrightness();
    } else {
      if ((newValue - _volume).abs() < 0.005) return;
      setState(() {
        _volume = newValue;
        _showVolumeIndicator = true;
        _showBrightnessIndicator = false;
      });
      _engine?.setVolume(_volume);
    }
  }

  void _resetVerticalGesture() {
    if (_gestureVerticalActive) {
      _gestureVerticalActive = false;
      _saveVolumeBrightness(); // 手势结束：持久化音量/亮度
      if (_gestureVerticalIsBrightness) {
        _brightnessHideTimer?.cancel();
        _brightnessHideTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showBrightnessIndicator = false);
        });
      } else {
        _volumeHideTimer?.cancel();
        _volumeHideTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showVolumeIndicator = false);
        });
      }
    }
  }

  /// 双击三区（Streama DoubleTapLeft/Middle/Right）：
  /// 左 1/3 快退、中 1/3 播放/暂停、右 1/3 快进
  void _handleDoubleTap(TapDownDetails d) {
    final sw = MediaQuery.of(context).size.width;
    final x = d.localPosition.dx;
    if (x >= sw * 1 / 3 && x < sw * 2 / 3) {
      // 中间：播放/暂停（播放/暂停图标涟漪，不 seek、不显示快进快退圆弧）
      _togglePlay();
      if (mounted) {
        setState(() {
          _ripplePosition = d.localPosition;
          _rippleIsLeft = false;
          _ripplePlayPause = true;
          _rippleIcon = _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded;
          _rippleTrigger++;
          _showRipple = true;
        });
      }
      AppLog.i('Player', '双击中间：播放/暂停');
      return;
    }
    final isLeft = x < sw * 1 / 3;
    final seconds = isLeft ? -10 : 10;
    final newPos = _position + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > _duration ? _duration : newPos);
    AppLog.i('Player', '双击${isLeft ? "快退" : "快进"}: ${seconds > 0 ? "+" : ""}$seconds秒, pos=${_position.inMilliseconds}ms → ${clamped.inMilliseconds}ms');
    setState(() {
      _position = clamped;
      _lastStateTime = DateTime.now();
      // 触发涟漪动画
      _ripplePosition = d.localPosition;
      _rippleIsLeft = isLeft;
      _ripplePlayPause = false;
      _rippleTrigger++;
      _showRipple = true;
    });
    _engine?.seek(clamped);
    _danmakuController.seekTo(clamped);
  }

  String _formatTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _playEpisode(MediaItem episode) async {
    final svc = widget.service;
    if (svc == null) {
      setState(() => _showEpisodePanel = false);
      return;
    }

    try {
      final ps = ref.read(playerSettingsProvider);
      final url = await svc.getStreamUrl(episode.id, quality: ps.defaultQuality, burnInSubtitle: ps.burnInSubtitle);
      _transcodeFallbackUrl = svc.lastTranscodeUrl;
      _transcodeTried = false; // 换了新流,给新流一次直连机会
      if (!mounted) return;
      _currentStreamUrl = url; // 记录新一集的流地址（字幕下载据此取 MediaSourceId）

      final headers = svc.streamHeaders;

      // 停止当前播放
      await _engine?.stop();

      _tracksLoaded = false;
      _showedAudioError = false;
      _playbackStartReported = false;
      _lastReportedMs = 0;

      // 重新打开新集数
      await _engine?.open(url: url, httpHeaders: headers, autoPlay: true);

      // 新引擎音量默认重置为 1.0，重新应用用户音量（含持久化值）
      _engine?.setVolume(_volume);
      // 强制视频 widget 重建：旧 PlatformView 的 Surface 已被原生 release() 销毁，
      // 新播放器拿不到 Surface 会"有声音无画面"（画面停留在上一集）；
      // 重建后新 SurfaceView 的 surfaceCreated 会把新 Surface 绑定到新播放器。
      _engineKey++;

      // 更新当前集数跟踪（切集后 widget.media 已过时）
      _currentMedia = episode;
      final eps = widget.episodes;
      if (eps != null) {
        final idx = eps.indexWhere((e) => e.id == episode.id);
        if (idx >= 0) _currentEpisodeIndex = idx;
      }

      setState(() {
        _showEpisodePanel = false;
        _episodePanelController.reset();
        _danmakuController.setData([]);
        _subtitleTracks = [];
        _audioTracks = [];
        // 切集后上一集的外挂字幕/选中态全部失效，必须清空：
        // 否则旧 SRT cue 会残留叠加在新集画面上（双层/错位字幕），
        // 且 _currentSubtitleIndex 指向旧轨会让面板显示错误的选中态。
        _stopLibass(); // 切集:libass 特效层绑定上一集的字幕数据,一并释放
        _externalSubtitleLoaded = false;
        _serverSubtitleLoading = false;
        _currentSubtitleIndex = -1;
        _autoDefaultSubtitleApplied = false; // 新一集重新自动启用其默认字幕轨
        _subtitlePrefetched = false; // 新一集重新后台预取其常用字幕轨
        _showAllSubtitleTracks = false; // 新一集恢复常用语言过滤
        _showNextEpisode = false;
        _nextEpisodeCancelled = false;
        _nextEpisodeTimer?.cancel();
        _nextEpisodePlaying = false;
        _skipButtonLabel = null;
        _skipIntroHandled = false;
        _introSkip = null;
        _trickplayInfo = null;
        _chapterMarkers = [];
        _rightPanelType = null;
      });

      // 重新加载弹幕、片头片尾、缩略图、章节标记
      _chaptersLoaded = false;
      _chapterMarkers = [];
      _loadDanmaku();
      _loadIntroSkip();
      _loadTrickplayInfo();
      _loadChapters();
    } catch (e) {
      _nextEpisodePlaying = false; // 失败后允许再次触发自动连播
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换集数失败: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    _danmakuController.updateScreenSize(_screenWidth, _screenHeight);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cleanup();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Listener(
        onPointerCancel: (_) => _resetVerticalGesture(),
        behavior: HitTestBehavior.translucent,
        child: GestureDetector(
        // 锁定：点击只显示解锁提示，全部手势（拖动/双击）禁用防误触
        onTap: _controlsLocked ? null : _toggleControls,
        onHorizontalDragStart: _controlsLocked ? null : _handleHorizontalDragStart,
        onHorizontalDragUpdate: _controlsLocked ? null : _handleHorizontalDrag,
        onHorizontalDragEnd: _controlsLocked ? null : _handleHorizontalDragEnd,
        onHorizontalDragCancel: _controlsLocked ? null : _handleHorizontalDragCancel,
        onVerticalDragUpdate: _controlsLocked ? null : _handleVerticalDrag,
        onVerticalDragEnd: _controlsLocked ? null : (_) => _resetVerticalGesture(),
        onDoubleTapDown: _controlsLocked ? null : (details) => _doubleTapDetails = details,
        onDoubleTap: _controlsLocked ? null : () => _handleDoubleTap(_doubleTapDetails!),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频渲染层 — 通过引擎抽象接口获取
            if (_engine != null)
              KeyedSubtree(
                key: ValueKey('video_$_engineKey'),
                child: _engine!.buildVideoWidget(),
              ),
            // 准备中：延时出现的加载层（普通文件点击即开时看不到）
            if (_prepareVisible && _initError == null)
              Positioned.fill(child: _buildPrepareOverlay()),
            // 初始化错误显示
            if (_initError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red, size: 64),
                      SizedBox(height: 16),
                      Text('播放失败', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text(
                        _initError!,
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('返回', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            // 缓冲指示器
            if (_isBuffering)
              Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            // 服务端字幕下载中指示（Emby/NAS 首次按需提取内嵌字幕可能很慢，
            // 让用户知道字幕正在加载而非没反应）
            if (_serverSubtitleLoading)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                          ),
                          SizedBox(width: 8),
                          Text('字幕加载中…', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // 外挂字幕叠加层（仅 ExoPlayer 引擎使用 Flutter 层渲染；
            // libass 激活时由下方原生 ASS 层接管,这层自动隐藏）
            if (_externalSubtitleLoaded && _engineType == PlayerEngineType.exo)
              _buildExternalSubtitleLayer(),
            // libass 原生 ASS 特效渲染层（TV 端同款管线;外挂 ASS 且 libass
            // 可用时激活,渲染帧含透明通道,点击穿透,只订阅 _libassImage）
            if (_libassActive && _engineType == PlayerEngineType.exo)
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<ui.Image?>(
                    valueListenable: _libassImage,
                    builder: (context, img, _) => img == null
                        ? const SizedBox.shrink()
                        : RawImage(image: img, fit: BoxFit.contain),
                  ),
                ),
              ),
            _buildDanmakuLayer(),
            _buildVolumeIndicator(),
            _buildBrightnessIndicator(),
            // 右缘控制：锁定按钮常驻（同一个按钮原地切换锁定/解锁，不额外生成
            // 解锁按钮）；倍速步进器仅在控制栏可见且未锁定时出现。
            // 面板打开时整组隐藏防误触（与之前一致）。
            if (_rightPanelType == null)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLockToggle(),
                      if (_controlsVisible && !_controlsLocked) ...[
                        const SizedBox(width: 8),
                        _buildSpeedStepper(),
                      ],
                    ],
                  ),
                ),
              ),
            // 控制栏：顶栏向上滑出、底栏向下滑出，同时淡出。
            // 用 AnimatedBuilder 驱动，动画结束后整棵子树从渲染树移除
            // —— opacity:0 的 widget 仍参与渲染，里面 4 处 BackdropFilter
            // 会持续做高斯模糊（看 2 小时电影期间控制栏 99% 时间隐藏）。
            AnimatedBuilder(
              animation: _controlsAnim,
              builder: (context, child) {
                if (_controlsAnim.value == 0 && !_controlsVisible) {
                  return const SizedBox.shrink();
                }
                return Opacity(
                  opacity: _controlsAnim.value,
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: child,
                  ),
                );
              },
              child: Stack(
                children: [
                  Column(
                    children: [
                      // 顶栏：向上滑出
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -1),
                          end: Offset.zero,
                        ).animate(_controlsAnim),
                        child: _buildTopBar(),
                      ),
                      const Expanded(child: SizedBox()),
                      // 底栏：向下滑出
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(_controlsAnim),
                        child: _buildBottomControls(),
                      ),
                    ],
                  ),
                  // 中心传输行：⟲10 ▶ ⟳10（Streama 中心控制样式）
                  Positioned.fill(
                    child: Center(child: _buildCenterTransport()),
                  ),

                ],
              ),
            ),
            // 面板遮罩：有面板打开时全屏透明遮罩，点击关闭弹窗
            if (_showEpisodePanel || _episodePanelController.isAnimating)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeAllPanels,
                ),
              ),
            // ── 选集面板（带底部滑入动画）──
            if (_showEpisodePanel || _episodePanelController.isAnimating)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _episodePanelController,
                  builder: (context, child) {
                    if (!_showEpisodePanel && _episodePanelController.value == 0) {
                      return const SizedBox.shrink();
                    }
                    return SlideTransition(
                      position: _episodeSlideAnim,
                      child: FadeTransition(
                        opacity: _episodeFadeAnim,
                        child: child,
                      ),
                    );
                  },
                  child: _buildEpisodeSheet(),
                ),
              ),
            // ── 双击涟漪动画 ──
            if (_showRipple)
              DoubleTapRipple(
                tapPosition: _ripplePosition,
                isLeftSide: _rippleIsLeft,
                seconds: 10,
                trigger: _rippleTrigger,
                playPause: _ripplePlayPause,
                playPauseIcon: _rippleIcon,
                onComplete: () {
                  if (mounted) setState(() => _showRipple = false);
                },
              ),
            // ── 拖拽时间胶囊（水平 seek 反馈） ──
            if (_seekCapsuleVisible)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _seekCapsuleLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [ui.FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // ── 跳过片头/片尾浮动按钮 ──
            if (_skipButtonLabel != null)
              Positioned(
                right: 32,
                bottom: MediaQuery.of(context).padding.bottom + 100,
                child: SkipButton(
                  key: ValueKey(_skipButtonLabel),
                  label: _skipButtonLabel!,
                  onTap: () => _skipToIntroEnd(),
                  autoSkip: _skipButtonAutoSkip(),
                  onAutoExpire: () {
                    if (mounted) setState(() => _skipButtonLabel = null);
                  },
                ),
              ),
            // ── 下一集自动播放倒计时 ──
            if (_showNextEpisode && !_nextEpisodeCancelled)
              Positioned(
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 100,
                child: _buildNextEpisodeCard(),
              ),
            // ── 右侧面板（音频/字幕/弹幕/画面比例/更多及其二级选项）──
            //
            // 滑入滑出由 RightPanelHost 统一驱动：面板自己只管画内容。
            // 改造前每个面板各自 forward()、退场各行其是 —— MoreRightPanel
            // 干脆没有退场（被 setState 直接摘掉），TrackRightPanel 则是
            // 点关闭按钮有动画、点遮罩没有。现在只剩一条关闭路径。
            //
            // 遮罩不覆盖顶栏区域：面板打开时顶栏「弹」「⋯」仍可点，
            // 可直接切换弹幕/更多面板（全屏遮罩会吞掉顶栏点击）。
            RightPanelHost(
              panelType: _rightPanelType,
              scrimTop: MediaQuery.of(context).padding.top + 6 + 44 + 24,
              onScrimTap: () => setState(() => _rightPanelType = null),
              panelBuilder: (type) => switch (type) {
                'audio' || 'subtitle' => TrackRightPanel(
                    title: type == 'audio' ? '音频' : '字幕',
                    tracks: type == 'audio' ? _audioTracks : _subtitleTracks,
                    currentIndex: type == 'audio'
                        ? _currentAudioIndex
                        : _currentSubtitleIndex,
                    onSelect: (i) {
                      if (type == 'audio') {
                        if (i >= 0) {
                          _applyAudioTrack(i);
                        }
                      } else {
                        _applySubtitleTrack(i);
                      }
                    },
                    onClose: () => setState(() => _rightPanelType = null),
                  ),
                'danmaku' => _buildDanmakuPanel(),
                'fit' => _FitRightPanel(
                    currentMode: _currentFitMode,
                    isAutoFit: _isAutoFit,
                    options: _fitModeOptions,
                    onSelect: _setFitMode,
                    onClose: () => setState(() => _rightPanelType = null),
                  ),
                _ => _buildMoreRightPanel(type),
              },
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }

  void _restoreOrientation() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  Widget _buildTopBar() {
    // 全宽渐变 scrim：与底栏呼应的 Netflix/Streama 式顶部渐变压暗。
    // 贴顶不悬浮：按钮为纯白图标（仅阴影），去掉玻璃浮层感；
    // 信息层级对齐 Streama：返回 | 标题 + 剧集徽章 | 操作按钮。
    final showBadge = (_activeMedia.type == MediaType.series ||
            _activeMedia.type == MediaType.episode) &&
        _activeMedia.seasonNumber != null &&
        _activeMedia.episodeNumber != null;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.80),
            Colors.black.withValues(alpha: 0.42),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          left: 6,
          right: 6,
          bottom: 24, // 渐变在按钮下方继续淡出，形成信息区“贴顶”的视觉带
        ),
        child: Row(
          children: [
            _buildTopBarIcon(Icons.arrow_back_rounded, () => Navigator.pop(context), size: 24),
            const SizedBox(width: 4),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _activeMedia.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                      ),
                    ),
                  ),
                  if (showBadge) ...[
                    const SizedBox(width: 8),
                    // 徽章改纯文字（无容器，嵌入标题行）
                    Text(
                      'S${_activeMedia.seasonNumber}\u00B7E${_activeMedia.episodeNumber}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 弹幕按钮 — 徽章样式：开启=主题色圆徽章，关闭=空心（点开面板 · 长按开关）
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleRightPanel('danmaku'),
              onLongPress: _toggleDanmaku,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _danmakuEnabled
                      ? AppTheme.primary.withValues(alpha: 0.22)
                      : Colors.transparent,
                  border: Border.all(
                    color: _danmakuEnabled
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '弹',
                    style: TextStyle(
                      color: _danmakuEnabled
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                    ),
                  ),
                ),
              ),
            ),
            // 与「弹」按钮拉开 8dp 间距、缩小命中域，避免相邻误触
            const SizedBox(width: 8),
            // 锁定按钮已移到右缘控制簇（倍速步进器左侧），顶栏只留 ⋯
            // 与「弹」同规格圆形底按钮：之前是裸图标挨着带底的「弹」，
            // 一有一无视觉不统一
            TapFeedback(
              onTap: () => _toggleRightPanel('more'),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 22,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶栏扁平图标按钮（仅阴影、无玻璃底 —— 贴顶不悬浮）
  Widget _buildTopBarIcon(IconData icon, VoidCallback? onTap,
      {double size = 22, double tapSize = 44, Color? color}) {
    // 按压缩放 0.9 + 弹性回弹（无框扁平图标的手感）
    return TapFeedback(
      onTap: onTap,
      scaleOnPress: 0.9,
      springBack: true,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: tapSize,
        height: tapSize,
        child: Center(
          child: Icon(
            icon,
            color: color ?? Colors.white,
            size: size,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
        ),
      ),
    );
  }

  /// 弹幕设置面板（右侧滑入）
  Widget _buildDanmakuPanel() {
    // 手动搜索的默认词与自动匹配同口径：剧集搜剧名（弹幕库按剧组织），
    // 电影搜片名。用户仍可改写后回车搜索。
    final isEpisode = _activeMedia.type == MediaType.episode;
    final searchSeed = (isEpisode && _activeMedia.seriesTitle?.isNotEmpty == true)
        ? _activeMedia.seriesTitle!
        : _activeMedia.title;
    return _DanmakuRightPanel(
      danmakuEnabled: _danmakuEnabled,
      onToggleDanmaku: (v) {
        setState(() {
          _danmakuEnabled = v;
          _danmakuController.setEnabled(v);
        });
      },
      onClose: () => setState(() => _rightPanelType = null),
      danmakuCount: _loadedDanmakuCount,
      danmakuSourceName: _loadedDanmakuSource,
      initialSearchQuery: searchSeed,
      candidates: _danmakuCandidates,
      selectedCandidateKey: _selectedCandidateKey,
      onSwitchCandidate: _switchDanmakuCandidate,
    );
  }

  /// 播放器底部控制面板：悬浮玻璃面板（Netflix/Streama 风格）
  /// 两层结构：进度条 + 主控制行（左播放簇 / 右辅助簇）
  Widget _buildBottomControls() {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    // 底部布局（Netflix / Streama 式）：进度条独立在上、控制区直接嵌在底部渐变
    // scrim 上 —— 无玻璃面板、无按钮框，图标扁平融入画面。
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.78),
            Colors.black.withValues(alpha: 0.42),
            Colors.transparent,
          ],
          stops: const [0.0, 0.42, 0.72],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 进度区（无裁剪，拖拽缩略图可浮出到画面）──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左下元数据行：分辨率 · 编码 · 码率 · 帧率（参考 CapyPlayer / Hills）
                if (_videoMetadata != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 2),
                    child: Text(
                      _videoMetadata!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                _buildProgressBar(),
              ],
            ),
          ),
          // ── 底部单行：左=上/下集，右=音轨/字幕/画幅/选集（Hills / Capy 布局）──
          Padding(
            padding: EdgeInsets.fromLTRB(8, 2, 8, 6 + safeBottom),
            child: Row(
              children: [
                // 上一集 / 下一集（仅剧集有选集列表时显示）
                if (_hasEpisodeList) ...[    
                  _buildFlatIconButton(
                    Icons.skip_previous_rounded,
                    _currentEpisodeIndex > 0
                        ? () => _playEpisode(widget.episodes![_currentEpisodeIndex - 1])
                        : null,
                    size: 26,
                  ),
                  _buildFlatIconButton(
                    Icons.skip_next_rounded,
                    _currentEpisodeIndex < widget.episodes!.length - 1
                        ? () => _playEpisode(widget.episodes![_currentEpisodeIndex + 1])
                        : null,
                    size: 26,
                  ),
                ],
                const Spacer(),
                _buildControlIcon(
                  Icons.audiotrack_rounded,
                  () => _showRightPanel('audio'),
                  label: '音轨',
                ),
                const SizedBox(width: 12),
                _buildControlIcon(
                  Icons.subtitles_outlined,
                  () => _showRightPanel('subtitle'),
                  label: '字幕',
                ),
                const SizedBox(width: 12),
                _buildControlIcon(
                  Icons.aspect_ratio_rounded,
                  _openFitSheet,
                  label: '画幅',
                ),
                // 选集按钮（仅剧集时显示）
                if (_activeMedia.type == MediaType.series || _activeMedia.type == MediaType.episode) ...[  
                  const SizedBox(width: 12),
                  _buildControlIcon(
                    Icons.list_rounded,
                    () => _togglePanel('episode'),
                    label: '选集',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 中心传输行：⟲10 ▶ ⟳10（Streama 中心控制样式，画面垂直中心悬浮）
  Widget _buildCenterTransport() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFlatIconButton(Icons.replay_10_rounded, () => _seekRelative(-10), size: 32),
        const SizedBox(width: 22),
        // 播放/暂停 — 最大的主控制图标（带扩散光晕）
        _buildPlayPauseButton(),
        const SizedBox(width: 22),
        _buildFlatIconButton(Icons.forward_10_rounded, () => _seekRelative(10), size: 32),
      ],
    );
  }

  /// 中心播放/暂停键：按下时从按钮扩散出一圈柔和光晕 + 波纹环，
  /// 播放/暂停反馈更明确（参考 Netflix 中心按键的按压涟漪）
  Widget _buildPlayPauseButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 扩散光晕层：柔和径向渐变圆盘，随动画外扩并淡出
        AnimatedBuilder(
          animation: _playPulseController,
          builder: (_, __) {
            final t = Curves.easeOutCubic.transform(_playPulseController.value);
            final radius = 26 + 62 * t;
            final opacity = (1 - t) * 0.6;
            return IgnorePointer(
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: opacity * 0.85),
                      Colors.white.withValues(alpha: opacity * 0.22),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            );
          },
        ),
        // 波纹环：与光晕同步外扩的细白环，形成"水波"层次
        AnimatedBuilder(
          animation: _playPulseController,
          builder: (_, __) {
            final t = Curves.easeOut.transform(_playPulseController.value);
            final radius = 30 + 56 * t;
            final opacity = (1 - t) * 0.5;
            return IgnorePointer(
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: opacity),
                    width: 1.6,
                  ),
                ),
              ),
            );
          },
        ),
        // 图标本体（保留 0.9 按压缩放 + 弹性回弹）
        TapFeedback(
          onTap: () {
            _togglePlay();
            _playPulseController.forward(from: 0);
          },
          scaleOnPress: 0.9,
          springBack: true,
          highlightColor: Colors.transparent,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Center(
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 46,
                shadows: const [Shadow(color: Colors.black87, blurRadius: 10)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 扁平图标按钮（无框、无底，直接嵌入播放画面 —— 参考 Yamby / Hills / CapyPlayer）
  Widget _buildFlatIconButton(IconData icon, VoidCallback? onTap,
      {double size = 28, double tapSize = 54}) {
    final enabled = onTap != null;
    // 按压缩放 0.9 + 弹性回弹；禁用（首/末集等）时无按压视觉
    return TapFeedback(
      onTap: onTap,
      scaleOnPress: 0.9,
      springBack: true,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: tapSize,
        height: tapSize,
        child: Center(
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.white24,
            size: size,
            shadows: enabled ? const [Shadow(color: Colors.black87, blurRadius: 10)] : null,
          ),
        ),
      ),
    );
  }

  /// 右侧垂直倍速步进器：+ / 当前速率 / −（参考 AfuseKt / Hills 竖排面板，无描边嵌入画面）
  Widget _buildSpeedStepper() {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(Icons.add_rounded, () => _stepSpeed(0.25)),
          const SizedBox(height: 6),
          TapFeedback(
            onTap: _openSpeedSheet,
            scaleOnPress: 0.9,
            springBack: true,
            highlightColor: Colors.transparent,
            child: SizedBox(
              width: 46,
              height: 24,
              child: Center(
                child: Text(
                  '${_speed}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _stepperButton(Icons.remove_rounded, () => _stepSpeed(-0.25)),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    // 步进器 +/− 也带按压缩放反馈
    return TapFeedback(
      onTap: onTap,
      scaleOnPress: 0.9,
      springBack: true,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 46,
        height: 34,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  /// 步进倍速（0.5 ~ 4.0，步长 0.25），同步引擎与弹幕位移
  void _stepSpeed(double delta) {
    final next = (_speed + delta).clamp(0.5, 4.0);
    if ((next - _speed).abs() < 0.001) return;
    setState(() => _speed = next);
    _engine?.setSpeed(next);
    _danmakuController.updateConfig(
      DanmakuRenderConfig.fromSettings(_cachedDisplay, playbackSpeed: next),
    );
  }

  /// 扁平控制图标（无框，图标+标签直接嵌在玻璃面板上）
  Widget _buildControlIcon(IconData icon, VoidCallback? onTap,
      {String? label, bool enabled = true, double size = 22}) {
    // 按压缩放 0.9 + 弹性回弹
    return TapFeedback(
      onTap: enabled ? onTap : null,
      scaleOnPress: 0.9,
      springBack: true,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 46,
            height: 38,
            child: Center(
              child: Icon(
                icon,
                color: enabled ? Colors.white : Colors.white30,
                size: size,
                shadows: enabled ? const [Shadow(color: Colors.black87, blurRadius: 8)] : null,
              ),
            ),
          ),
          if (label != null) ...[    
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white.withValues(alpha: 0.75) : Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return CustomProgressBar(
      position: _position,
      duration: _duration,
      buffer: _buffer,
      canSeek: _duration.inMilliseconds > 0,
      formatTime: _formatTime,
      chapterMarkers: _chapterMarkers,
      // 弹幕热力图：开关开启且加载到弹幕数据时显示（密度分桶缓存，O(1) 查表）
      heatmap: ref.watch(danmakuDisplayProvider).heatmap
          ? _danmakuController.heatmapDensity
          : null,
      heatmapBucketMs: _danmakuController.heatmapBucketWidthMs,
      thumbnailProvider: (positionMs) {
        final trickplay = _trickplayInfo;
        final svc = widget.service;
        if (trickplay == null || svc is! JellyfinService) return null;
        if (trickplay.intervalMs <= 0 || trickplay.thumbnailCount <= 0) return null;
        // 帧索引（positionMs 对应第几张缩略图）
        final frameIndex = positionMs ~/ trickplay.intervalMs;
        // 精灵图索引（每张精灵图含 thumbnailCount 张缩略图）
        final sheetIndex = frameIndex ~/ trickplay.thumbnailCount;
        // 精灵图内的局部索引 → 行列位置
        final tileInSheet = frameIndex % trickplay.thumbnailCount;
        final col = tileInSheet % trickplay.tileWidth;
        final row = tileInSheet ~/ trickplay.tileWidth;
        return TrickplayTile(
          spriteSheetUrl: svc.getTrickplayTileUrl(_activeMedia.id, sheetIndex),
          col: col,
          row: row,
          gridWidth: trickplay.tileWidth,
          gridHeight: trickplay.tileHeight,
        );
      },
      onSeekStart: (v) {
        if (!_isSeeking) {
          _isSeeking = true;
          _danmakuController.setSeeking(true);
        }
        final newPos = Duration(
          milliseconds: (v * _duration.inMilliseconds).toInt(),
        );
        setState(() {
          _position = newPos;
        });
      },
      onSeekUpdate: (v) {
        final newPos = Duration(
          milliseconds: (v * _duration.inMilliseconds).toInt(),
        );
        setState(() {
          _position = newPos;
        });
      },
      onSeekEnd: (v) {
        _isSeeking = false;
        _danmakuController.setSeeking(false);
        final newPos = Duration(
          milliseconds: (v * _duration.inMilliseconds).toInt(),
        );
        _engine?.seek(newPos);
        _onSeekEnd();
        // Seek 结束后重启自动隐藏定时器
        if (_controlsVisible) _startHideTimer();
      },
    );
  }

  Widget _buildExternalSubtitleLayer() {
    if (!_externalSubtitleLoaded) return const SizedBox.shrink();
    final manager = _engine?.externalSubtitleManager;
    if (manager == null || !manager.isLoaded) return const SizedBox.shrink();
    // watch 而非 read：字幕样式面板调节字号/颜色时实时生效，无需重建页面
    final settings = ref.watch(playerSettingsProvider);
    return Positioned.fill(
      child: IgnorePointer(
        child: SubtitleOverlay(
          cues: manager.cues,
          // 字幕延迟：播放位置加上偏移（正=延后，负=提前），与 MPV 的 sub-delay 语义一致
          // 用 _smoothPosition 而非 _position：后者按 500ms 跳变，会把字幕
          // 出入点量化到半秒。
          currentPosition: () =>
              _smoothPosition +
              Duration(milliseconds: (settings.subtitleDelaySeconds * 1000).round()),
          settings: settings,
          screenWidth: _screenWidth,
          screenHeight: _screenHeight,
          fitMode: _currentFitMode,
          videoSize: Size(
            (_engine?.currentState.videoWidth ?? 1920).toDouble(),
            (_engine?.currentState.videoHeight ?? 1080).toDouble(),
          ),
        ),
      ),
    );
  }

  Widget _buildDanmakuLayer() {
    if (!_danmakuEnabled) {
      return const SizedBox.shrink();
    }
    final tapToSearch = ref.watch(danmakuDisplayProvider).tapToSearch;
    return Positioned.fill(
      // 点弹幕搜索：开启后点击弹幕命中检测，弹出复制/搜索操作（不拦截其他手势）
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: tapToSearch ? _onDanmakuTap : null,
        child: IgnorePointer(
          child: DanmakuRenderer(
            tickNotifier: _danmakuController.tickNotifier,
            getActiveDanmaku: () => _danmakuController.activeDanmaku,
            screenWidth: _screenWidth,
            screenHeight: _screenHeight,
            displayArea: ref.watch(danmakuDisplayProvider).displayArea,
          ),
        ),
      ),
    );
  }

  /// 点弹幕命中检测：显示该弹幕内容 + 复制/搜索操作
  void _onDanmakuTap(TapUpDetails details) {
    final hit = _danmakuController.hitTest(details.localPosition.dx, details.localPosition.dy);
    if (hit == null) return;
    final text = hit.danmaku.text;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 120),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('弹幕内容已复制'), duration: Duration(seconds: 2)));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white70),
                    label: const Text('复制', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _searchDanmaku(text);
                    },
                    icon: Icon(Icons.search_rounded, size: 18, color: AppTheme.primary),
                    label: Text('搜索', style: TextStyle(color: AppTheme.primary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 用弹幕内容打开浏览器搜索
  void _searchDanmaku(String text) {
    final uri = Uri.parse('https://www.baidu.com/s?wd=${Uri.encodeComponent(text)}');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// 准备阶段的加载层：**只有动画，不显示任何文字**（用户要求）。
  ///
  /// 阶段信息仍写进日志（见 _enterPreparePhase），排查时不靠界面文案。
  Widget _buildPrepareOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: Colors.white70),
    );
  }

  Widget _buildVolumeIndicator() {
    // 用 AnimatedSwitcher 做淡入 + 轻微缩放，而非 SizedBox.shrink 硬出硬消。
    // 每次调音量都会遇到，属于高频接触点。
    return Positioned(
      right: 40,
      top: _screenHeight * 0.25,
      child: _HudTransition(
        visible: _showVolumeIndicator,
        child: _showVolumeIndicator
            ? _VerticalBarIndicator(
                value: _volume,
                icon: _volume == 0
                    ? Icons.volume_off_rounded
                    : _volume < 0.4
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
              )
            : null,
      ),
    );
  }

  Widget _buildBrightnessIndicator() {
    return Positioned(
      left: 40,
      top: _screenHeight * 0.25,
      child: _HudTransition(
        visible: _showBrightnessIndicator,
        child: _showBrightnessIndicator
            ? _VerticalBarIndicator(
                value: _brightness,
                icon: _brightness < 0.4
                    ? Icons.brightness_low_rounded
                    : _brightness < 0.7
                        ? Icons.brightness_5_rounded
                        : Icons.brightness_high_rounded,
              )
            : null,
      ),
    );
  }

  Widget _buildEpisodeSheet() {
    if (!_showEpisodePanel) return const SizedBox.shrink();

    final episodes = widget.episodes ?? [];
    if (episodes.isEmpty) {
      // 没有剧集列表数据时，回退到数字选集
      return _buildSimpleEpisodeSheet();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('选集', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('  ·  共${episodes.length}集', style: TextStyle(color: Colors.white54, fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () => _animateCloseEpisodePanel(),
                child: Icon(Icons.close_rounded, color: Colors.white54, size: 22),
              ),
            ],
          ),
            SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final ep = episodes[index];
                  final epNum = ep.episodeNumber ?? (index + 1);
                  final isCurrent = ep.id == _activeMedia.id;
                  return GestureDetector(
                    onTap: () => _playEpisode(ep),
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 封面图（固定 16:9 比例，避免拉伸留白）
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(10),
                                      border: isCurrent ? Border.all(color: AppTheme.primary, width: 2) : null,
                                    ),
                                    child: ep.posterUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: ep.posterUrl,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 200,
                                          errorWidget: (_, __, ___) => Center(
                                            child: Text('$epNum', style: TextStyle(color: Colors.white70, fontSize: 28, fontWeight: FontWeight.bold)),
                                          ),
                                        )
                                      : Center(
                                          child: Text('$epNum', style: TextStyle(color: Colors.white70, fontSize: 28, fontWeight: FontWeight.bold)),
                                        ),
                                  ),
                                ),
                                // 底部渐变遮罩
                                Positioned(
                                  left: 0, right: 0, bottom: 0,
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black54],
                                      ),
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                    ),
                                  ),
                                ),
                                // 播放指示
                                if (isCurrent)
                                  Positioned(
                                    top: 6, right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6),
                          // 集数标签
                          Text(
                            '第${epNum}集',
                            style: TextStyle(
                              color: isCurrent ? AppTheme.primary : Colors.white,
                              fontSize: 12,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  // 简单数字选集（无剧集列表时的回退方案）
  Widget _buildSimpleEpisodeSheet() {
    final totalEpisodes = widget.media.totalEpisodes ?? 12;
    final currentEpisode = _activeMedia.episodeNumber ?? 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('选集', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('  ·  共$totalEpisodes集', style: TextStyle(color: Colors.white54, fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () => _animateCloseEpisodePanel(),
                child: Icon(Icons.close_rounded, color: Colors.white54, size: 22),
              ),
            ],
          ),
            SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: totalEpisodes,
                itemBuilder: (context, index) {
                  final ep = index + 1;
                  final isSelected = ep == currentEpisode;
                  return GestureDetector(
                    onTap: () => setState(() => _showEpisodePanel = false),
                    child: Container(
                      width: 52,
                      height: 52,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white10,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected ? Border.all(color: AppTheme.primary, width: 1.5) : null,
                      ),
                      child: Center(
                        child: Text('$ep', style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        )),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  // ════════════════════════════════════════════════
  // 右侧轨道面板
  // ════════════════════════════════════════════════

  void _showRightPanel(String type) {
    if (type == 'audio' && _audioTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有可选音轨')),
      );
      return;
    }
    _closeAllPanels();
    setState(() => _rightPanelType = type);
  }

  // ════════════════════════════════════════════════
  // 跳过片头/片尾
  // ════════════════════════════════════════════════

  Future<void> _loadIntroSkip() async {
    final svc = widget.service;
    if (svc == null) {
      AppLog.i('Player', 'IntroSkip: service 为空，跳过加载');
      return;
    }
    try {
      AppLog.i('Player', 'IntroSkip: 开始加载 (itemId=${_activeMedia.id}, svc=${svc.runtimeType})');
      final introSkip = await svc.getIntroSkipInfo(_activeMedia.id);
      if (mounted) {
        setState(() => _introSkip = introSkip);
        AppLog.i('Player', 'IntroSkip loaded: hasIntro=${introSkip?.hasIntro}, hasCredits=${introSkip?.hasCredits}');
      }
    } catch (e) {
      AppLog.i('Player', '加载片头片尾信息失败: $e');
    }
  }

  /// 加载 Trickplay 缩略图元数据（仅 Jellyfin 10.9+ 支持）
  Future<void> _loadTrickplayInfo() async {
    final svc = widget.service;
    if (svc is! JellyfinService) return;
    try {
      final info = await svc.getTrickplayInfo(_activeMedia.id);
      if (mounted && info != null) {
        setState(() => _trickplayInfo = info);
        AppLog.i('Player', 'Trickplay loaded: intervalMs=${info.intervalMs}, grid=${info.tileWidth}x${info.tileHeight}, thumbnails=${info.thumbnailCount}');
      }
    } catch (e) {
      AppLog.w('Player', '加载 Trickplay 信息失败: $e');
    }
  }

  /// 加载章节标记（Emby/Jellyfin Chapters API），在进度条上绘制 tick
  Future<void> _loadChapters() async {
    final svc = widget.service;
    if (svc == null || _chaptersLoaded) return;
    try {
      final chapters = await svc.getChapters(_activeMedia.id);
      if (!mounted || chapters.isEmpty) return;
      _chaptersLoaded = true;
      final markers = chapters
          .map((c) => c.startDuration.inMilliseconds)
          .where((ms) => ms > 1000)
          .toList();
      if (markers.isNotEmpty) {
        setState(() => _chapterMarkers = markers);
        AppLog.i('Player', '章节标记: ${markers.length} 个 (${chapters.map((c) => c.name).join(' / ')})');
      }
    } catch (e) {
      AppLog.d('Player', '加载章节标记失败: $e');
    }
  }

  /// 数据防御：introEnd 异常（≥ 总时长，部分服务器/插件返回错误区间）时
  /// 回退到总时长前 30s，避免"跳过片头"直接跳到片尾/结束（误跳整集）。
  Duration _clampIntroEnd(Duration target) {
    if (_duration > Duration.zero && target >= _duration) {
      final fallback = _duration - const Duration(seconds: 30);
      return fallback > Duration.zero ? fallback : Duration.zero;
    }
    return target;
  }

  void _checkSkipState(Duration position) {
    final introSkip = _introSkip;
    if (introSkip == null) return;
    final settings = ref.read(playerSettingsProvider);
    final posMs = position.inMilliseconds;

    // 片头检测
    if (introSkip.hasIntro) {
      final introStart = introSkip.introStartDuration.inMilliseconds;
      final introEnd = introSkip.introEndDuration.inMilliseconds;
      if (posMs >= introStart && posMs < introEnd) {
        if (settings.autoSkipIntro && !_skipIntroHandled) {
          _skipIntroHandled = true;
          final target = _clampIntroEnd(introSkip.introEndDuration);
          _engine?.seek(target);
          _danmakuController.seekTo(target);
          AppLog.i('Player', '自动跳过片头 → ${target.inMilliseconds}ms');
          return;
        }
        if (settings.showSkipButton && _skipButtonLabel != '跳过片头') {
          setState(() => _skipButtonLabel = '跳过片头');
        }
        return;
      } else if (posMs >= introEnd) {
        _skipIntroHandled = false;
      }
    }

    // 片尾检测
    if (introSkip.hasCredits) {
      final creditsStart = introSkip.creditsStartDuration?.inMilliseconds ?? 0;
      final introEnd = introSkip.hasIntro ? introSkip.introEndDuration.inMilliseconds : 0;
      // 数据防御：部分服务器/插件的 credits 起点早于/等于片头结束（区间重叠、
      // 字段错位），会导致刚跳过片头就立刻弹"跳过片尾"、误跳整集。
      // 有效起点取 max(creditsStart, introEnd + 1s)。
      final effectiveCreditsStart = (creditsStart > introEnd) ? creditsStart : (introEnd + 1000);
      if (effectiveCreditsStart > 0 &&
          posMs >= effectiveCreditsStart &&
          posMs < _duration.inMilliseconds) {
        if (settings.autoSkipOutro && _duration.inMilliseconds - posMs > 5000) {
          _engine?.seek(_duration);
          AppLog.i('Player', '自动跳过片尾');
          return;
        }
        if (settings.showSkipButton && _skipButtonLabel != '跳过片尾') {
          setState(() => _skipButtonLabel = '跳过片尾');
        }
        return;
      }
    }

    if (_skipButtonLabel != null) {
      setState(() => _skipButtonLabel = null);
    }
  }

  void _skipToIntroEnd() {
    final introSkip = _introSkip;
    if (introSkip == null) return;
    if (_skipButtonLabel == '跳过片头' && introSkip.hasIntro) {
      final target = _clampIntroEnd(introSkip.introEndDuration);
      _engine?.seek(target);
      _danmakuController.seekTo(target);
    } else if (_skipButtonLabel == '跳过片尾' && introSkip.hasCredits) {
      _engine?.seek(_duration);
    }
    setState(() => _skipButtonLabel = null);
  }

  /// 跳过按钮是否允许 10s 倒计时自动跳过：跟随「自动跳过片头/片尾」设置。
  /// 开关关闭时按钮纯手动（不会自己跳）。autoSkip 开着时按钮基本不会出现
  /// （自动路径先跳），但拖回片头区间等场景仍可能出现，此时保持倒计时行为。
  bool _skipButtonAutoSkip() {
    final ps = ref.read(playerSettingsProvider);
    return _skipButtonLabel == '跳过片尾' ? ps.autoSkipOutro : ps.autoSkipIntro;
  }

  // ════════════════════════════════════════════════
  // 下一集自动播放倒计时
  // ════════════════════════════════════════════════

  void _checkNextEpisode(Duration position, Duration duration) {
    if (_activeMedia.type != MediaType.series && _activeMedia.type != MediaType.episode) return;
    final episodes = widget.episodes;
    if (episodes == null || episodes.isEmpty) return;
    if (duration.inMilliseconds <= 0) return;
    if (_nextEpisodeCancelled || _nextEpisodePlaying) return;
    if (_currentEpisodeIndex < 0 || _currentEpisodeIndex >= episodes.length - 1) return;

    final remaining = duration - position;
    final remainingMs = remaining.inMilliseconds;

    // 已到达/越过结尾（自然播完、自动跳过片尾 seek 到结尾、手动拖到底）：
    // 倒计时流程未启动时直接切下一集。覆盖"自动跳过片尾"把位置直接跳到
    // duration 导致 remaining 瞬间归零、倒计时卡片永不出现、连播卡死的路径。
    if (remainingMs <= 0) {
      _playNextEpisode();
      return;
    }

    if (remainingMs <= 30000 && !_showNextEpisode) {
      setState(() {
        _showNextEpisode = true;
        _nextEpisodeCountdown = remaining.inSeconds.clamp(1, 30);
      });
      _startNextEpisodeTimer(duration);
    }

    if (_showNextEpisode && remaining.inSeconds != _nextEpisodeCountdown) {
      setState(() => _nextEpisodeCountdown = remaining.inSeconds);
    }
  }

  void _startNextEpisodeTimer(Duration duration) {
    _nextEpisodeTimer?.cancel();
    _nextEpisodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _nextEpisodeCancelled) {
        timer.cancel();
        return;
      }
      final remaining = duration - _position;
      if (remaining.inSeconds <= 0) {
        timer.cancel();
        _playNextEpisode();
      }
    });
  }

  void _playNextEpisode() {
    if (_nextEpisodePlaying) return; // 防重复触发（倒计时回调 + 位置检测可能同时命中）
    _nextEpisodePlaying = true;
    final episodes = widget.episodes;
    if (episodes == null || episodes.isEmpty) return;
    if (_currentEpisodeIndex < 0 || _currentEpisodeIndex >= episodes.length - 1) return;
    final nextEp = episodes[_currentEpisodeIndex + 1];
    setState(() => _showNextEpisode = false);
    _playEpisode(nextEp);
  }

  Widget _buildNextEpisodeCard() {
    final episodes = widget.episodes;
    if (episodes == null || episodes.isEmpty) return const SizedBox.shrink();
    if (_currentEpisodeIndex < 0 || _currentEpisodeIndex >= episodes.length - 1) {
      return const SizedBox.shrink();
    }
    final nextEp = episodes[_currentEpisodeIndex + 1];

    return NextEpisodeCard(
      title: nextEp.title.isNotEmpty ? nextEp.title : '第${nextEp.episodeNumber ?? _currentEpisodeIndex + 2}集',
      subtitle: nextEp.title.isNotEmpty ? '第${nextEp.episodeNumber ?? _currentEpisodeIndex + 2}集' : null,
      thumbnailUrl: nextEp.posterUrl.isNotEmpty ? nextEp.posterUrl : null,
      totalSeconds: 30,
      remainingSeconds: _nextEpisodeCountdown.clamp(0, 30),
      onPlay: () {
        _nextEpisodeTimer?.cancel();
        _playNextEpisode();
      },
      onCancel: () {
        _nextEpisodeTimer?.cancel();
        setState(() {
          _nextEpisodeCancelled = true;
          _showNextEpisode = false;
        });
      },
    );
  }
}

/// 通用底部抽屉（毛玻璃风格，用于速度/内核/画幅等选项选择）
class _OptionBottomSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final int currentIndex;
  final void Function(int index) onSelect;

  const _OptionBottomSheet({
    required this.title,
    required this.options,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.5;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24).withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽手柄
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ]),
              ),
              // 选项列表
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (_, i) {
                    final opt = options[i];
                    final label = opt['label']?.toString() ?? '';
                    final isSelected = i == currentIndex;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onSelect(i);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(children: [
                            if (isSelected)
                              Container(
                                width: 4, height: 20, margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)),
                              )
                            else
                              const SizedBox(width: 16),
                            Expanded(
                              child: Text(label, style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              )),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              color: isSelected ? AppTheme.primary : Colors.white24,
                              size: 22,
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FitModeOption {
  final BoxFit? mode; // null = 自适应
  final String label;
  final IconData icon;

  const _FitModeOption(this.mode, this.label, this.icon);
}

/// 播放器 HUD（音量/亮度指示器）出现消失过渡。
///
/// 出现：150ms 淡入 + 0.9→1.0 缩放（接近 iOS 音量 HUD 质感）
/// 消失：淡出 + 轻微缩小
/// 不可见时返回零尺寸占位，不参与渲染。
class _HudTransition extends StatelessWidget {
  final bool visible;
  final Widget? child;

  const _HudTransition({required this.visible, this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppAnimations.fast,
      switchInCurve: AppAnimations.easeOut,
      switchOutCurve: AppAnimations.easeIn,
      transitionBuilder: (c, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
          child: c,
        ),
      ),
      child: visible && child != null
          ? child!
          : const SizedBox.shrink(key: ValueKey('hud_hidden')),
    );
  }
}

/// 竖向进度条指示器（音量/亮度通用）
/// 单一 CustomPaint 绘制，从源头避免"两条进度条"问题
class _VerticalBarIndicator extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final IconData icon;

  const _VerticalBarIndicator({
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.clamp(0.0, 1.0)),
      duration: AppAnimations.normal,
      curve: AppAnimations.easeOut,
      builder: (context, animatedValue, _) => _buildIndicator(animatedValue),
    );
  }

  Widget _buildIndicator(double animatedValue) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 10),
          SizedBox(
            width: 24,
            height: 120,
            child: CustomPaint(
              painter: _VerticalBarPainter(value: animatedValue),
              size: const Size(24, 120),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(animatedValue * 100).round()}%',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 竖向进度条绘制器
/// 一次性绘制：背景轨道 + 前景填充
class _VerticalBarPainter extends CustomPainter {
  final double value;

  _VerticalBarPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final trackColor = Colors.white.withValues(alpha: 0.25);
    final fillColor = AppTheme.primary;
    final width = 4.0;
    final cx = size.width / 2;
    final top = 0.0;
    final bottom = size.height;

    // 背景轨道（从顶到底）
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;
    canvas.drawLine(Offset(cx, top), Offset(cx, bottom), trackPaint);

    // 前景填充（从 (1-value) 到底）
    final fillTop = bottom * (1 - value);
    if (fillTop < bottom) {
      final fillPaint = Paint()
        ..color = fillColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width;
      canvas.drawLine(Offset(cx, fillTop), Offset(cx, bottom), fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalBarPainter old) => old.value != value;
}

/// 弹幕设置右侧滑入面板 — Miuix 风格（圆角卡片分组 + 标题摘要 + 弹幕源搜索）
class _DanmakuRightPanel extends ConsumerStatefulWidget {
  final bool danmakuEnabled;
  final ValueChanged<bool> onToggleDanmaku;
  final VoidCallback onClose;

  /// 已加载的弹幕条数。首屏「当前匹配」卡用它区分已加载/未匹配两种状态。
  final int danmakuCount;

  /// 当前弹幕来源名（已加载时显示在匹配卡里）。
  final String? danmakuSourceName;

  /// 搜索框默认词（当前影视名）；null 则留空。
  final String? initialSearchQuery;

  /// 双路并行匹配的候选列表（首屏匹配卡 + 搜索子面板共用展示）。
  final List<DanmakuMatchCandidate> candidates;

  /// 当前已加载候选的 key。
  final String? selectedCandidateKey;

  /// 切换候选（解析单集 → 加载 → 记住）。
  final Future<void> Function(DanmakuMatchCandidate) onSwitchCandidate;

  const _DanmakuRightPanel({
    required this.danmakuEnabled,
    required this.onToggleDanmaku,
    required this.onClose,
    this.danmakuCount = 0,
    this.danmakuSourceName,
    this.initialSearchQuery,
    this.candidates = const [],
    this.selectedCandidateKey,
    required this.onSwitchCandidate,
  });

  @override
  ConsumerState<_DanmakuRightPanel> createState() => _DanmakuRightPanelState();
}

/// 弹幕面板的三个屏。
///
/// 面板内部自己维护这一层导航，而不是让 `RightPanelHost` 管 ——
/// 宿主负责的是「整块面板滑入/滑出」，屏与屏之间的切换是面板自己的事。
enum _DanmakuPage { home, search, settings }

/// 首屏用的圆角卡片（总开关、当前匹配都用它）。
class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(13),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return TapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: card,
    );
  }
}

/// 首屏的功能入口按钮（「搜索弹幕 →」「弹幕设置 →」）。
class _PanelEntryButton extends StatelessWidget {
  const _PanelEntryButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// 主要入口用主题色图标底，次要入口用中性灰 —— 两个入口并列时
  /// 需要一个视觉主次，否则用户不知道该先点哪个。
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapFeedback(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: accent ? 0.06 : 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withValues(alpha: accent ? 0.10 : 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent
                      ? AppTheme.primary.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon,
                    size: 17,
                    color: accent ? AppTheme.primary : Colors.white),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.42),
                            fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.45)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 子面板顶部的返回行。
///
/// 设计稿去掉了标题栏，但子面板仍需要一条回首屏的路 —— 不能只靠"点面板外
/// 关闭再重新打开"，那等于把两级导航退化成一级。
class _PanelBackRow extends StatelessWidget {
  const _PanelBackRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TapFeedback(
        onTap: onBack,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left_rounded,
                  size: 20, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 2),
              Text('返回',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DanmakuRightPanelState extends ConsumerState<_DanmakuRightPanel> {
  /// 当前屏。首屏 230 宽，两个子面板 320 宽。
  _DanmakuPage _page = _DanmakuPage.home;

  // 弹幕源搜索
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<DanmakuMatch> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  // 手动搜索所用源的 id/名：结果被选中时构造候选走切换管线需要
  String? _searchSourceId;
  String? _searchSourceName;

  @override
  void initState() {
    super.initState();
    // 搜索框默认填当前影视名（剧集为剧名）：用户点开搜索面板时
    // 不用再手打一遍，直接回车或点放大镜即可搜。
    _searchController.text = widget.initialSearchQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 关闭面板；滑出动画由 [RightPanelHost] 负责。
  void _animateClose() => widget.onClose();

  Future<void> _searchDanmaku(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = true; _showResults = true; });
    try {
      final configs = ref.read(danmakuConfigsProvider);
      final enabledConfig = configs.where((c) => c.isEnabled).toList();
      if (enabledConfig.isEmpty) {
        setState(() { _isSearching = false; });
        return;
      }
      _searchSourceId = enabledConfig.first.id;
      _searchSourceName = enabledConfig.first.name;
      final svc = DanmakuService(baseUrl: enabledConfig.first.url, apiKey: enabledConfig.first.apiKey);
      final results = await svc.searchDanmaku(query);
      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (_) {
      if (mounted) setState(() { _isSearching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 三屏结构（对照 player_panels_prototype.html）：
    //   首屏 230 宽：总开关 + 当前匹配 + 两个功能入口
    //   搜索/设置子面板 320 宽
    // 首屏窄是有意的 —— 它只承载"看一眼当前状态 + 决定去哪"，
    // 320 宽的一整屏设置项摆在那里会让人每次都要先滑过一遍才找到入口。
    return PlayerSidePanel(
      // 无标题栏，关闭靠点面板外侧（RightPanelHost 的遮罩）。
      onClose: _animateClose,
      width: _page == _DanmakuPage.home ? 230 : 320,
      maxHeightFactor: 0.85,
      verticalMargin: 48,
      child: AnimatedSwitcher(
        duration: context.motion(AppMotion.enter),
        switchInCurve: AppEase.enter,
        switchOutCurve: AppEase.exit,
        // 子面板切换用横向位移 + 淡入，方向暗示"进入下一层 / 退回上一层"。
        transitionBuilder: (child, anim) {
          final incoming = child.key == ValueKey(_page);
          final dx = incoming
              ? (_page == _DanmakuPage.home ? -0.06 : 0.06)
              : (_page == _DanmakuPage.home ? 0.06 : -0.06);
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_page),
          child: switch (_page) {
            _DanmakuPage.home => _buildHomePage(),
            _DanmakuPage.search => _buildSearchPage(),
            _DanmakuPage.settings => _buildSettingsPage(),
          },
        ),
      ),
    );
  }

  /// 首屏：总开关 + 当前匹配 + 功能入口。
  Widget _buildHomePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      shrinkWrap: true,
      children: [
        // 总开关从原先的设置列表顶部移到首屏 —— 它是最高频的操作，
        // 不该藏在一屏设置项的上面等人滑。
        _HomeCard(
          onTap: () => widget.onToggleDanmaku(!widget.danmakuEnabled),
          child: Row(
            children: [
              const Expanded(
                child: Text('启用弹幕',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              Switch(
                value: widget.danmakuEnabled,
                activeTrackColor: AppTheme.primary,
                onChanged: widget.onToggleDanmaku,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildMatchCard(),
        const SizedBox(height: 10),
        _PanelEntryButton(
          icon: Icons.search_rounded,
          title: '搜索弹幕',
          subtitle: '自动匹配 · 换源 · 本地导入',
          accent: true,
          onTap: () => setState(() => _page = _DanmakuPage.search),
        ),
        _PanelEntryButton(
          icon: Icons.tune_rounded,
          title: '弹幕设置',
          subtitle: '显示 · 布局 · 样式 · 热力图',
          onTap: () => setState(() => _page = _DanmakuPage.settings),
        ),
      ],
    );
  }

  /// 首屏的「当前匹配」卡：可切换候选列表。
  /// 有候选 → 列表（选中行高亮）；无候选且已加载（记住的选择直载）→ 来源行；
  /// 无候选未加载 → 空态引导。
  Widget _buildMatchCard() {
    final loaded = widget.danmakuCount > 0;
    final hasCandidates = widget.candidates.isNotEmpty;
    final badgeText = loaded
        ? '已加载 · ${widget.danmakuCount}条'
        : (hasCandidates ? '待选择' : '未匹配');
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radio_button_checked,
                  size: 13, color: AppTheme.primary),
              const SizedBox(width: 6),
              const Text('当前匹配',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (loaded ? AppTheme.success : const Color(0xFFE8B341))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badgeText,
                    style: TextStyle(
                      color: loaded ? AppTheme.success : const Color(0xFFE8B341),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasCandidates)
            _buildSelectedCandidateRow()
          else if (loaded)
            Text(
              widget.danmakuSourceName ?? '弹幕源',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('未找到匹配弹幕',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('点击下方「搜索弹幕」手动搜索',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.28),
                          fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 首屏只显示当前加载的那一条候选（单行）。
  ///
  /// 完整候选列表放在搜索子面板——之前首屏放整个列表有两个问题：
  /// 嵌套 ListView 吞掉滚动手势导致首屏滑不到底部，且多行候选把 230 宽的
  /// 卡片挤爆。点行内任意处进入搜索页切换。
  Widget _buildSelectedCandidateRow() {
    final selected = widget.candidates.firstWhere(
      (c) => c.key == widget.selectedCandidateKey,
      orElse: () => widget.candidates.first,
    );
    final loaded = widget.danmakuCount > 0;
    return TapFeedback(
      onTap: () => setState(() => _page = _DanmakuPage.search),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selected.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${selected.sourceName} · ${selected.reason}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (loaded) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('已加载·${widget.danmakuCount}条',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(width: 4),
            Text('切换',
                style: TextStyle(
                    color: AppTheme.primary.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: AppTheme.primary.withValues(alpha: 0.9)),
          ],
        ),
      ),
    );
  }

  /// 搜索子面板：自动匹配候选 + 手动搜索 + 本地导入。
  Widget _buildSearchPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      children: [
        _PanelBackRow(onBack: () => setState(() => _page = _DanmakuPage.home)),
        const SizedBox(height: 8),
        _buildDanmakuSourceStatus(),
        const SizedBox(height: 10),
        _buildSearchBar(),
        const SizedBox(height: 6),
        _buildAutoMatchSection(),
        if (_showResults) _buildSearchResults(),
      ],
    );
  }

  /// 自动匹配候选区：复用首屏的候选列表；无候选给一句引导。
  Widget _buildAutoMatchSection() {
    if (widget.candidates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('暂无自动匹配候选，可在下方手动搜索',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('自动匹配候选',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        DanmakuCandidateList(
          candidates: widget.candidates,
          selectedKey: widget.selectedCandidateKey,
          loadedCount: widget.danmakuCount,
          onSelect: (c) => widget.onSwitchCandidate(c),
          maxHeight: 160,
        ),
      ],
    );
  }

  /// 设置子面板：原先那一整套分组卡片。
  Widget _buildSettingsPage() {
    final display = ref.watch(danmakuDisplayProvider);
    final dn = ref.read(danmakuDisplayProvider.notifier);

    if (!widget.danmakuEnabled) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PanelBackRow(
              onBack: () => setState(() => _page = _DanmakuPage.home)),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text('弹幕已关闭',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      children: [
        _PanelBackRow(onBack: () => setState(() => _page = _DanmakuPage.home)),
        const SizedBox(height: 8),
        // ── 👁 显示 ──
        _miuixCard(
          icon: Icons.visibility_rounded, title: '显示', children: [
                                _miuixToggle('顶部弹幕', '显示在画面顶部的固定弹幕', display.showTop, (v) => dn.update(display.copyWith(showTop: v))),
                                _miuixToggle('底部弹幕', '显示在画面底部的固定弹幕', display.showBottom, (v) => dn.update(display.copyWith(showBottom: v))),
                                _miuixToggle('滚动弹幕', '从右向左滚动的弹幕', display.showScroll, (v) => dn.update(display.copyWith(showScroll: v))),
                                _miuixToggle('合并重复', '相同内容的弹幕只显示一条', display.mergeDuplicates, (v) => dn.update(display.copyWith(mergeDuplicates: v))),
                                _miuixToggle('进度条热力图', '在进度条上显示弹幕密度', display.heatmap, (v) => dn.update(display.copyWith(heatmap: v))),
                                _miuixToggle('点击弹幕搜索', '点击弹幕弹出复制/搜索', display.tapToSearch, (v) => dn.update(display.copyWith(tapToSearch: v))),
                                _danmakuSlider('显示区域', '弹幕占据屏幕高度的比例', display.displayArea, 0.5, 1.0, (v) => display.copyWith(displayArea: double.parse(v.toStringAsFixed(2)))),
                              ],
                            ),
                            // ── 📐 布局 ──
                            _miuixCard(
                              icon: Icons.dashboard_customize_rounded, title: '布局', children: [
                                _danmakuSlider('滚动行数', '同时显示的滚动弹幕最大行数', display.maxScrollLines.toDouble(), 1, 12, (v) => display.copyWith(maxScrollLines: v.round()), isInt: true),
                                _danmakuSlider('顶部行数', '同时显示的顶部弹幕最大行数', display.maxTopLines.toDouble(), 1, 8, (v) => display.copyWith(maxTopLines: v.round()), isInt: true),
                                _danmakuSlider('底部行数', '同时显示的底部弹幕最大行数', display.maxBottomLines.toDouble(), 1, 8, (v) => display.copyWith(maxBottomLines: v.round()), isInt: true),
                                _danmakuSlider('最大屏幕数', '屏幕上同时显示的弹幕上限（0=默认50）', display.maxScreen.toDouble(), 0, 200, (v) => display.copyWith(maxScreen: v.round()), isInt: true),
                                _danmakuSlider('最短长度', '低于此字数的弹幕不显示（0=不过滤）', display.minimumLength.toDouble(), 0, 20, (v) => display.copyWith(minimumLength: v.round()), isInt: true),
                                _miuixToggle('防止重叠', '弹幕之间保持安全间距', display.preventOverlap, (v) => dn.update(display.copyWith(preventOverlap: v))),
                              ],
                            ),
                            // ── 🎨 样式 ──
                            _miuixCard(
                              icon: Icons.palette_rounded, title: '样式', children: [
                                _danmakuSlider('字体大小', '弹幕文字的显示大小', display.fontSize, 17, 40, (v) => display.copyWith(fontSize: double.parse(v.toStringAsFixed(0))), suffix: 'px'),
                                _danmakuSlider('透明度', '弹幕的显示透明度', display.opacity, 0.2, 1.0, (v) => display.copyWith(opacity: double.parse(v.toStringAsFixed(2)))),
                                _danmakuSlider('弹幕速度', '滚动弹幕的移动速度', display.speed, 6, 24, (v) => display.copyWith(speed: double.parse(v.toStringAsFixed(0)))),
                                _danmakuSlider('同步偏移', '弹幕与视频的时间偏移', display.syncDelay, -5.0, 5.0, (v) => display.copyWith(syncDelay: double.parse(v.toStringAsFixed(1))), suffix: 's'),
                                _miuixToggle('粗体', '使用粗体显示弹幕', display.bold, (v) => dn.update(display.copyWith(bold: v))),
                              ],
                            ),
        // ── 恢复默认 ──
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => dn.update(const DanmakuDisplaySettings()),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('恢复默认', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // Miuix 风格组件
  // ═══════════════════════════════════════════

  /// Miuix 圆角卡片分组。
  ///
  /// 图标用 [IconData] 而不是 emoji 字面量：TV 盒子和精简 ROM 常常没装 emoji
  /// 字体，📡👁📐🎨 在那些设备上会渲染成豆腐块。这个项目有 TV 端，风险是实的。
  Widget _miuixCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppTheme.primary.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: AppTheme.primary.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  /// Miuix 开关项（标题 + 摘要 + Switch）
  Widget _miuixToggle(String label, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            height: 26,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppTheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  /// Miuix 滑块项（标题 + 摘要 + 数值徽章 + Slider）
  Widget _miuixSlider(String label, String subtitle, double value, double min, double max, ValueChanged<double> onChanged, {String suffix = '', bool isInt = false, ValueChanged<double>? onChangeEnd}) {
    return _SettingSlider(
      label: label,
      subtitle: subtitle,
      value: value,
      min: min,
      max: max,
      suffix: suffix,
      isInt: isInt,
      onPreview: onChanged,
      onCommit: onChangeEnd ?? onChanged,
    );
  }

  /// 弹幕设置滑块。
  ///
  /// [build] 由滑块值算出新的设置对象，preview / commit 两条路径共用它 ——
  /// 否则同一个 copyWith 表达式要写两遍，改一处漏一处就变成"拖动预览的是
  /// A、松手存下的是 B"。
  Widget _danmakuSlider(
    String label,
    String subtitle,
    double value,
    double min,
    double max,
    DanmakuDisplaySettings Function(double v) build, {
    String suffix = '',
    bool isInt = false,
  }) {
    final dn = ref.read(danmakuDisplayProvider.notifier);
    return _miuixSlider(
      label,
      subtitle,
      value,
      min,
      max,
      (v) => dn.preview(build(v)),
      onChangeEnd: (v) => dn.commit(build(v)),
      suffix: suffix,
      isInt: isInt,
    );
  }

  // ═══════════════════════════════════════════
  // 弹幕源区域
  // ═══════════════════════════════════════════

  Widget _buildDanmakuSourceStatus() {
    final configs = ref.watch(danmakuConfigsProvider);
    final enabled = configs.where((c) => c.isEnabled).toList();
    if (enabled.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text('已连接: ${enabled.first.name}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12), overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.orange.withValues(alpha: 0.8), size: 14),
          const SizedBox(width: 8),
          Text('未配置弹幕源', style: TextStyle(color: Colors.orange.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.38), size: 18),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              cursorColor: AppTheme.primary,
              decoration: InputDecoration(
                // 全局主题给所有输入框强制了亮色填充（app_theme inputDecorationTheme
                // fillColor=surf），浅色模式下这里是白底白字——预填的影视名直接
                // 隐身。显式覆盖为与面板一致的玻璃深底。
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                hintText: '搜索番剧名...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              onSubmitted: _searchDanmaku,
            ),
          ),
          IconButton(
            icon: Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
            onPressed: () => _searchDanmaku(_searchController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)));
    }
    if (_searchResults.isEmpty) {
      return Padding(padding: const EdgeInsets.all(16), child: Center(child: Text('未找到匹配结果', style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13))));
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10)),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, i) {
          final r = _searchResults[i];
          return InkWell(
            onTap: () {
              // 手动搜索结果也是候选：走同一条切换管线
              // （解析 bangumi → 集号定位 → 加载 → 记住选择）
              final sourceId = _searchSourceId;
              if (sourceId == null) return;
              widget.onSwitchCandidate(DanmakuMatchCandidate(
                sourceId: sourceId,
                sourceName: _searchSourceName ?? '弹幕源',
                bangumiId: r.bangumiId,
                title: r.title,
                danmakuCount: r.count,
                score: 1.0,
                reason: '手动搜索',
              ));
              _searchController.clear();
              setState(() { _showResults = false; _searchResults = []; });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.movie_rounded, color: AppTheme.primary.withValues(alpha: 0.6), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('第${r.episodeNumber}集 · ${r.count}条弹幕', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 画幅模式右侧滑入面板 — Miuix 风格
/// 设置面板里的滑块：拖动中只预览，松手才落盘。
///
/// ## 为什么要单独一个 StatefulWidget
///
/// 改造前滑块把「写数据库 + 写 SharedPreferences」的回调直接接在
/// `Slider.onChanged` 上，而那是**每一拖动帧**都触发的。拖两秒字体大小滑块
/// ≈ 一百多次 sqlite 写入 + 一百多次 SharedPreferences 写入，拖动因此发涩。
///
/// 拆开之后：
/// - 拖动中走 [onPreview]（只改内存 state），弹幕层立刻能看到效果；
/// - 松手走 [onCommit]（落盘），全程只写一次。
///
/// 拖动位置由本组件自己持有（[_dragValue]）而不是回读外部 value ——
/// 外部 state 是异步更新的，回读会让滑块在手指底下抖。
class _SettingSlider extends StatefulWidget {
  const _SettingSlider({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onPreview,
    required this.onCommit,
    this.suffix = '',
    this.isInt = false,
  });

  final String label;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onPreview;
  final ValueChanged<double> onCommit;
  final String suffix;
  final bool isInt;

  @override
  State<_SettingSlider> createState() => _SettingSliderState();
}

class _SettingSliderState extends State<_SettingSlider> {
  /// 拖动中的本地值；null = 没在拖，用外部值。
  double? _dragValue;

  double get _current =>
      (_dragValue ?? widget.value).clamp(widget.min, widget.max);

  String get _display {
    final v = _current;
    if (widget.isInt) return v.round().toString();
    return v.toStringAsFixed(
        widget.suffix == 's' ? 1 : (widget.suffix == 'px' ? 0 : 2));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$_display${widget.suffix}', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: Colors.white12,
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _current,
              min: widget.min,
              max: widget.max,
              onChanged: (v) {
                setState(() => _dragValue = v);
                widget.onPreview(v);
              },
              onChangeEnd: (v) {
                setState(() => _dragValue = null);
                widget.onCommit(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FitRightPanel extends StatefulWidget {  final BoxFit? currentMode; // null = 自适应
  final bool isAutoFit;
  final List<_FitModeOption> options;
  final ValueChanged<BoxFit?> onSelect;
  final VoidCallback onClose;

  const _FitRightPanel({
    this.currentMode,
    this.isAutoFit = true,
    required this.options,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<_FitRightPanel> createState() => _FitRightPanelState();
}

class _FitRightPanelState extends State<_FitRightPanel> {
  /// 关闭面板；滑出动画由 [RightPanelHost] 负责。
  void _animateClose() => widget.onClose();

  /// 自适应档要显示"当前实际是哪一档"。
  ///
  /// 改造前面板只在自适应那行打个勾，不告诉你它解析成了什么 —— 用户看到
  /// 「自适应 ✓」却不知道画面现在是按"适配宽度"还是"原始"在放，也就无从
  /// 判断该不该手动改。
  String? get _autoResolvedLabel {
    if (!widget.isAutoFit) return null;
    for (final o in widget.options) {
      if (o.mode == widget.currentMode) return o.label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PlayerSidePanel(
      // 无标题栏：设计稿去掉了「画幅模式 ✕」那一行。关闭靠点面板外侧，
      // 省下的 44px 高度还给选项 —— 这个面板只有 6 行，标题栏占比太重。
      onClose: _animateClose,
      width: 230,
      maxHeightFactor: 0.7,
      verticalMargin: 56,
      child: ListView(
        padding: const EdgeInsets.all(10),
        // 高度自适应：内容不足时不撑满，让面板贴着选项收口。
        shrinkWrap: true,
        children: widget.options.map((f) {
          final isSelected = widget.isAutoFit
              ? f.mode == null
              : f.mode == widget.currentMode;
          // 自适应选中时，把解析结果标在对应的那一档上，
          // 让用户看得见"自适应现在等于哪一档"。
          final isAutoTarget = widget.isAutoFit &&
              f.mode != null &&
              f.mode == widget.currentMode;
          return _FitOptionTile(
            option: f,
            selected: isSelected,
            autoTarget: isAutoTarget,
            trailingLabel: f.mode == null ? _autoResolvedLabel : null,
            onTap: () {
              widget.onSelect(f.mode);
              _animateClose();
            },
          );
        }).toList(),
      ),
    );
  }
}

/// 画幅面板的一行。
class _FitOptionTile extends StatelessWidget {
  const _FitOptionTile({
    required this.option,
    required this.selected,
    required this.autoTarget,
    required this.onTap,
    this.trailingLabel,
  });

  final _FitModeOption option;
  final bool selected;

  /// 自适应当前解析到的那一档（自身不是"选中"，但要标出来）。
  final bool autoTarget;

  /// 「自适应」这一行右侧显示的解析结果，如「适配宽度」。
  final String? trailingLabel;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.primary;
    return TapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: accent.withValues(alpha: 0.3))
              // 自适应解析到的那档给条虚线似的弱边，区别于真正的选中
              : autoTarget
                  ? Border.all(color: Colors.white.withValues(alpha: 0.18))
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(option.icon,
                  color:
                      selected ? accent : Colors.white.withValues(alpha: 0.7),
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (trailingLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '当前：$trailingLabel',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, color: accent, size: 20)
            else if (autoTarget)
              Text(
                '自适应',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
