import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 媒体服务器图片的下载校验与解码（ServerImage 与媒体库预加载共用）。
///
/// 两台设备的实证（2026-09-06）：
/// - 未鉴权时飞牛 sys/img 返回 **HTTP 200 + JSON 错误体**（不是 401），
///   谁直接信 200 谁就把 43 字节 JSON 写进磁盘缓存 —— 同一 URL 永久
///   解码失败（真机 532 次 DecodeException）。所以下载后必须验魔数，
///   非图片逐出缓存重试一次。
/// - MIUI 这台 ROM 的 Flutter 平台解码器（android.graphics.ImageDecoder）
///   解不了飞牛 webp（'unimplemented'），而 `ui.instantiateImageCodec`
///   （Palette 取色同款）解同一内容成功 —— 网格卡片（带 cacheWidth 的
///   ResizeImage 路径）空白、详情页（全尺寸路径）正常，就是这个分叉。
///   解码统一走 instantiateImageCodec。

/// 图片磁盘缓存的最小接口（生产用 DefaultCacheManager，测试可注入假件）。
abstract class ImageFileCache {
  Future<File> getSingleFile(String url, {Map<String, String>? headers});
  Future<void> removeFile(String url);
}

class DefaultImageFileCache implements ImageFileCache {
  const DefaultImageFileCache();

  @override
  Future<File> getSingleFile(String url, {Map<String, String>? headers}) =>
      DefaultCacheManager().getSingleFile(url, headers: headers);

  @override
  Future<void> removeFile(String url) => DefaultCacheManager().removeFile(url);
}

/// 下载并校验图片魔数；非图片内容逐出缓存重试一次。
///
/// 返回 null 表示两次都不是图片（URL 失效/服务端持续异常），调用方走
/// 错误占位。逐出保证 200+非图片响应（鉴权错误页等）不会永久占位。
Future<File?> loadValidatedImageFile(
  String url, {
  Map<String, String>? headers,
  ImageFileCache? cache,
}) async {
  final store = cache ?? const DefaultImageFileCache();
  for (var attempt = 0; attempt < 2; attempt++) {
    try {
      final file = await store.getSingleFile(url, headers: headers);
      final head = await _readHead(file);
      if (looksLikeImageBytes(head)) return file;
      await store.removeFile(url);
    } catch (_) {
      return null; // 网络失败等,交给错误占位,下次构建重试
    }
  }
  return null;
}

/// 下载校验 + 解码为 [ui.Image]（调用方负责 dispose）。
///
/// 解码统一走 `ui.instantiateImageCodec`（Palette 同款、设备实证可用），
/// 不经 Image.file/ResizeImage 的平台解码器路径。
Future<ui.Image?> decodeValidatedUiImage(
  String url, {
  Map<String, String>? headers,
  int? targetWidth,
  ImageFileCache? cache,
}) async {
  final file = await loadValidatedImageFile(url, headers: headers, cache: cache);
  if (file == null) return null;
  try {
    final bytes = await file.readAsBytes();
    // 小图不放大：先读原始尺寸（只解析头部，不解码）
    int? width = targetWidth;
    if (width != null) {
      try {
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        final desc = await ui.ImageDescriptor.encoded(buffer);
        if (desc.width < width) width = null;
        buffer.dispose();
      } catch (_) {}
    }
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

Future<List<int>> _readHead(File file) async {
  try {
    final raf = await file.open();
    try {
      final bytes = await raf.read(12);
      return bytes.toList();
    } finally {
      await raf.close();
    }
  } catch (_) {
    return const <int>[];
  }
}

/// 魔数判断：webp/jpeg/png/gif/bmp。头不足 12 字节一律不算图片 ——
/// 飞牛未鉴权时的 43 字节 JSON 错误体就挡在这里。
bool looksLikeImageBytes(List<int> head) {
  if (head.length < 12) return false;
  final b = Uint8List.fromList(head);
  // JPEG: FF D8 FF
  if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return true;
  // PNG: 89 50 4E 47
  if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return true;
  // GIF: GIF8
  if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) return true;
  // BMP: BM
  if (b[0] == 0x42 && b[1] == 0x4D) return true;
  // WEBP: RIFF....WEBP
  if (b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
      b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
    return true;
  }
  return false;
}
