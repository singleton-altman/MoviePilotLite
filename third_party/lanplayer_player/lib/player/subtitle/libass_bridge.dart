import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../../utils/app_log.dart';
import '../../models/player_settings.dart';
import 'libass_style.dart';

/// libass 原生桥接 — ASS/SSA 字幕渲染
///
/// 通过 JNI 调用 C++ 原生 libass 库，实现高性能 ASS 字幕渲染。
/// 需要编译时启用 HAS_LIBASS（通过 build_native_deps.sh 交叉编译）。
///
/// 当 libass 不可用时，回退到 Flutter 层的 SubtitleOverlay 渲染。
class LibassBridge {
  /// 当前这批字幕是否强制统一样式（SRT/VTT 恒 true；ASS 由用户设置决定）。
  /// 记住它是为了"改样式后重下发"时保持同一语义（见 [applySettings]）。
  static bool _forceStyle = true;

  /// 下发字幕样式覆盖给 libass（只覆盖字体名/字号/颜色/描边/属性，
  /// **不含定位与边距** —— 特效字幕的 \pos/\move/\k/	 不受影响）。
  static Future<void> setStyle(Map<String, Object> args) async {
    _forceStyle = (args['enabled'] as int? ?? 1) == 1;
    try {
      await _channel.invokeMethod<void>('setStyle', args);
      AppLog.i('LibassBridge',
          '样式覆盖已下发: fontSize=${args['fontSize']} enabled=${args['enabled']}');
    } catch (e) {
      AppLog.w('LibassBridge', '样式覆盖下发失败: $e');
    }
  }

  /// 按当前设置重下发（改样式时调用；forceStyle 沿用当前字幕类型）
  static Future<void> applySettings(PlayerSettings settings) =>
      setStyle(libassStyleArgs(settings, forceStyle: _forceStyle));

  static const MethodChannel _channel = MethodChannel('com.lanplayer/libass');
  static bool _initialized = false;
  static bool _libassAvailable = false;

  /// libass 是否可用
  static bool get isAvailable => _libassAvailable;

  /// 初始化 libass 渲染器
  ///
  /// [width]/[height] 为渲染帧尺寸（通常与视频分辨率一致）
  static Future<bool> init({required int width, required int height}) async {
    try {
      final result = await _channel.invokeMethod<bool>('init', {
        'width': width,
        'height': height,
      });
      _initialized = result ?? false;
      _libassAvailable = _initialized;
      if (_initialized) {
        AppLog.i('LibassBridge', 'libass 初始化成功: ${width}x$height');
      }
      return _initialized;
    } catch (e) {
      AppLog.w('LibassBridge', 'libass 不可用: $e');
      _libassAvailable = false;
      return false;
    }
  }

  /// 加载 ASS/SSA 字幕文件
  static Future<bool> loadFile(String filePath) async {
    if (!_initialized) return false;
    try {
      final result = await _channel.invokeMethod<bool>('loadFile', {
        'path': filePath,
      });
      return result ?? false;
    } catch (e) {
      AppLog.e('LibassBridge', '加载字幕失败: $e');
      return false;
    }
  }

  /// 从字节数据加载 ASS 字幕
  static Future<bool> loadData(Uint8List data) async {
    if (!_initialized) return false;
    try {
      final result = await _channel.invokeMethod<bool>('loadData', {
        'data': data,
      });
      return result ?? false;
    } catch (e) {
      AppLog.e('LibassBridge', '加载字幕数据失败: $e');
      return false;
    }
  }

  /// 渲染指定时间点的字幕帧
  ///
  /// 返回 ARGB 像素数据（width * height * 4 字节），
  /// 可转换为 Flutter Image 叠加在视频上方。
  static Future<Uint8List?> render(int timeMs, int width, int height) async {
    if (!_initialized) return null;
    try {
      final result = await _channel.invokeMethod<Uint8List>('render', {
        'timeMs': timeMs,
        'width': width,
        'height': height,
      });
      return result;
    } catch (e) {
      AppLog.d('LibassBridge', '渲染失败: $e');
      return null;
    }
  }

  /// 获取字幕事件总数
  static Future<int> getEventCount() async {
    if (!_initialized) return 0;
    try {
      final result = await _channel.invokeMethod<int>('getEventCount');
      return result ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 释放资源
  static Future<void> release() async {
    try {
      await _channel.invokeMethod('release');
      _initialized = false;
      AppLog.i('LibassBridge', 'libass 已释放');
    } catch (_) {}
  }
}
