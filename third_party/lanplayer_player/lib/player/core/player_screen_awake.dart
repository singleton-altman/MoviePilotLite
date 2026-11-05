import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../utils/app_log.dart';
import 'player_engine.dart';

class PlayerScreenAwake {
  PlayerScreenAwake({
    Future<void> Function(bool enabled)? setEnabled,
    AppLifecycleState? initialLifecycleState,
  }) : _output = setEnabled == null
           ? _sharedOutput
           : _ScreenAwakeOutput(setEnabled),
       _foreground = !_isBackground(initialLifecycleState);

  static final _sharedOutput = _ScreenAwakeOutput(
    (enabled) => WakelockPlus.toggle(enable: enabled),
  );

  final _ScreenAwakeOutput _output;
  StreamSubscription<PlayerState>? _subscription;
  PlayerEngine? _engine;
  PlayerState _state = const PlayerState();
  bool _isAudio = false;
  bool _foreground;
  bool _disposed = false;

  Future<void> get settled => _output.settled;

  void bind(PlayerEngine? engine, {required bool isAudio}) {
    if (_disposed) return;
    if (identical(engine, _engine) && isAudio == _isAudio) return;
    _subscription?.cancel();
    _subscription = null;
    _engine = engine;
    _isAudio = isAudio;
    _state = _foreground && engine != null
        ? engine.currentState
        : const PlayerState();
    _sync();
    if (engine == null) return;
    _subscription = engine.stateStream.listen(
      (state) {
        if (_disposed || !identical(_engine, engine) || !_foreground) return;
        _state = state;
        _sync();
      },
      onError: (Object error, StackTrace stack) {
        if (!identical(_engine, engine)) return;
        _state = const PlayerState();
        _sync();
      },
      onDone: () {
        if (!identical(_engine, engine)) return;
        _state = const PlayerState();
        _sync();
      },
    );
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (_isBackground(state)) {
      _foreground = false;
      _state = const PlayerState();
    } else if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _output.invalidate();
    }
    _sync();
  }

  static bool _isBackground(AppLifecycleState? state) =>
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.hidden ||
      state == AppLifecycleState.detached;

  void _sync() {
    final playing =
        _state.isPlaying ||
        (_state.isBuffering && _state.playWhenReady == true);
    _output.request(
      this,
      !_disposed &&
          _foreground &&
          !_isAudio &&
          playing &&
          !_state.isCompleted &&
          _state.error?.isNotEmpty != true,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _engine = null;
    _subscription?.cancel();
    _subscription = null;
    _sync();
  }
}

// 常亮是应用级状态：旧页面的异步释放不能关闭新页面仍在使用的常亮。
class _ScreenAwakeOutput {
  _ScreenAwakeOutput(this._setEnabled);

  final Future<void> Function(bool enabled) _setEnabled;
  final Set<PlayerScreenAwake> _owners = {};
  bool? _applied = false;
  Future<void>? _pending;
  int _revision = 0;

  Future<void> get settled => _pending ?? Future<void>.value();

  void invalidate() {
    _revision++;
    _applied = null;
  }

  void request(PlayerScreenAwake owner, bool enabled) {
    if (enabled) {
      _owners.add(owner);
    } else {
      _owners.remove(owner);
    }
    if (_pending != null || _applied == _owners.isNotEmpty) return;
    _pending = _apply().whenComplete(() => _pending = null);
  }

  Future<void> _apply() async {
    while (_applied != _owners.isNotEmpty) {
      final enabled = _owners.isNotEmpty;
      final revision = _revision;
      try {
        await _setEnabled(enabled);
        _applied = revision == _revision ? enabled : null;
      } catch (error) {
        _applied = null;
        AppLog.w('Player', '更新播放常亮失败: $error');
        // 开启失败期间可能已退出；仍需补发释放，不能留下迟到的开启请求。
        if (enabled && _owners.isEmpty) continue;
        return;
      }
    }
  }
}
