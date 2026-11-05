import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import 'app_log.dart';

/// 自定义字幕字体管理
///
/// 用户选择的 .ttf/.otf 字体文件复制到应用文档目录，注册为全局字体
/// `LanSubtitleFont`，ExoPlayer 外挂字幕的 Flutter 层渲染使用。
///
/// - [ensureLoaded] 幂等：app 启动/播放器构建时调用，已注册则跳过
/// - MPV 内嵌字幕由 libass 原生渲染，自定义字体文件不生效（UI 已注明）
class SubtitleFonts {
  static const fontFamily = 'LanSubtitleFont';
  static const _keyPath = 'subtitle_font_path';
  static bool _loaded = false;
  static String? _loadedPath;

  /// 已保存的自定义字体路径（SharedPreferences）。
  ///
  /// 必须先问 [StorageService.isInitialized]：这个 getter 会被
  /// [ensureLoaded] 在 `SubtitleOverlay.build` 里同步调用，而
  /// `StorageService._prefs` 是 `late` 字段 —— 存储还没就绪时直读会抛
  /// LateInitializationError，那是在 build 里抛，整个播放器页面直接白屏。
  /// 存储服务本来就为此暴露了 [StorageService.ready]，这里退化为「还没就绪
  /// 就当没设自定义字体」，就绪后下一次 build 自然读到。
  static String? get savedPath =>
      StorageService.isInitialized ? StorageService.getString(_keyPath) : null;

  /// 字体文件名（用于 UI 展示）
  static String? get savedName {
    final p = savedPath;
    if (p == null || p.isEmpty) return null;
    return p.split(Platform.pathSeparator).last;
  }

  static Future<void> savePath(String path) => StorageService.setString(_keyPath, path);

  static Future<void> clear() async {
    await StorageService.setString(_keyPath, '');
    _loaded = false;
    _loadedPath = null;
  }

  /// 幂等注册：字体已加载且路径一致则跳过
  static Future<bool> ensureLoaded() async {
    final path = savedPath;
    if (path == null || path.isEmpty) return false;
    if (_loaded && _loadedPath == path) return true;
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      final loader = FontLoader(fontFamily)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      _loaded = true;
      _loadedPath = path;
      AppLog.i('SubtitleFonts', '自定义字体已注册: $path');
      return true;
    } catch (e) {
      AppLog.w('SubtitleFonts', '字体注册失败: $e');
      return false;
    }
  }

  /// 把选择的字体文件复制到应用文档目录，返回新路径
  static Future<String?> copyToAppDir(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory('${dir.path}/subtitle_fonts');
      if (!await fontsDir.exists()) await fontsDir.create(recursive: true);
      final name = sourcePath.split(Platform.pathSeparator).last;
      final dest = '${fontsDir.path}/$name';
      await File(sourcePath).copy(dest);
      return dest;
    } catch (e) {
      AppLog.w('SubtitleFonts', '复制字体失败: $e');
      return null;
    }
  }
}
