import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/validated_image_store.dart';

export '../utils/validated_image_store.dart'
    show ImageFileCache, DefaultImageFileCache, loadValidatedImageFile, looksLikeImageBytes;

/// 媒体服务器图片加载组件。
///
/// 下载与解码都走 [decodeValidatedUiImage]（见 validated_image_store.dart）：
/// - **魔数验货**：非图片内容（未鉴权时飞牛的 200+JSON 错误体）逐出缓存
///   重试一次，毒化条目在构造上进不了缓存；
/// - **显式解码**：`ui.instantiateImageCodec`（Palette 同款）—— MIUI ROM
///   的平台解码器解不了飞牛 webp（网格卡片走 ResizeImage 路径全灭、
///   详情页全尺寸路径正常，2026-09-06 真机实证），统一绕开。
///
/// [memCacheWidth] 按 `ScreenAdapter.cardWidth * devicePixelRatio` 传入，
/// 解码直接落在显示尺寸，避免全尺寸海报驻留内存。
class ServerImage extends StatefulWidget {
  final String imageUrl;
  final Map<String, String>? headers;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final Widget Function(BuildContext, String)? placeholder;
  final int? memCacheWidth;
  final Duration fadeInDuration;

  const ServerImage({
    super.key,
    required this.imageUrl,
    this.headers,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.placeholder,
    this.memCacheWidth,
    this.fadeInDuration = const Duration(milliseconds: 200),
  });

  @override
  State<ServerImage> createState() => _ServerImageState();
}

class _ServerImageState extends State<ServerImage> {
  ui.Image? _image;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ServerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.headers != widget.headers ||
        oldWidget.memCacheWidth != widget.memCacheWidth) {
      _load();
    }
  }

  Future<void> _load() async {
    final url = widget.imageUrl;
    if (url.isEmpty) return;
    _loading = true;
    if (mounted) setState(() {});
    try {
      final img = await decodeValidatedUiImage(
        url,
        headers: widget.headers,
        targetWidth: widget.memCacheWidth,
      );
      if (!mounted || url != widget.imageUrl) {
        img?.dispose(); // 已切走:解出来的图直接释放
        return;
      }
      setState(() {
        _image?.dispose();
        _image = img;
        _error = img == null ? '' : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || url != widget.imageUrl) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return _buildError(context, '', '');
    }
    if (_loading && _image == null) {
      return widget.placeholder?.call(context, widget.imageUrl) ??
          Container(color: Theme.of(context).cardColor);
    }
    final image = _image;
    if (image == null) {
      return _buildError(context, widget.imageUrl, _error ?? '');
    }
    final child = RawImage(
      image: image,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
    );
    return AnimatedOpacity(
      opacity: 1,
      duration: widget.fadeInDuration,
      child: child,
    );
  }

  Widget _buildError(BuildContext context, String url, Object? error) {
    return widget.errorWidget?.call(context, url, error ?? '') ??
        Container(
          color: Theme.of(context).cardColor,
          child: const Center(child: Icon(Icons.movie, color: Colors.white24)),
        );
  }
}
