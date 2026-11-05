import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_request_headers.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

/// 网络图片加载组件
/// 基于 cached_network_image 和 flutter_cache_manager
/// 统一处理缓存代理地址转换、缓存、请求头、尺寸解码与加载状态
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheManager,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 120),
    this.fadeOutDuration = const Duration(milliseconds: 80),
    this.cookie,
    this.convertProxyUrl = true,
  });

  /// 图片 URL
  final String imageUrl;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 图片适配方式
  final BoxFit fit;

  /// 占位符（加载中显示）
  final Widget? placeholder;

  /// 错误占位符（加载失败显示）
  final Widget? errorWidget;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 自定义缓存管理器
  final CacheManager? cacheManager;

  /// 内存缓存宽度（用于优化内存）
  final int? memCacheWidth;

  /// 内存缓存高度（用于优化内存）
  final int? memCacheHeight;

  /// 淡入动画时长
  final Duration fadeInDuration;

  /// 淡出动画时长
  final Duration fadeOutDuration;

  /// Cookie
  final String? cookie;

  /// 是否自动转换为缓存代理地址（默认开启）。
  /// 传入已转换过的地址时会被自动识别并透传，不会二次包裹。
  final bool convertProxyUrl;

  /// 解码尺寸的轻微余量。取值越大内存占用增长越快（近似平方），
  /// 而 BoxFit.cover 下超出部分并不会被看到，1.1 已足够覆盖取整误差。
  static const double _decodeOverscan = 1.1;
  static const int _minAutoCacheExtent = 64;
  static const int _maxAutoCacheExtent = 1600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildImage(context, constraints),
    );
  }

  Widget _buildImage(BuildContext context, BoxConstraints constraints) {
    final manager = cacheManager ?? AppImageCacheManager.instance;
    final autoCacheExtents = _autoCacheExtents(context, constraints);
    final effectiveMemCacheWidth = memCacheWidth ?? autoCacheExtents.width;
    final effectiveMemCacheHeight = memCacheHeight ?? autoCacheExtents.height;
    final resolvedUrl = _resolveUrl();
    final headers = kIsWeb
        ? null
        : buildImageRequestHeaders(resolvedUrl, cookie: cookie);
    final cacheKey = kIsWeb ? null : _buildCacheKey(resolvedUrl);
    final imageWidget = CachedNetworkImage(
      imageUrl: resolvedUrl,
      cacheKey: cacheKey,
      width: width,
      height: height,
      fit: fit,
      cacheManager: manager,
      memCacheWidth: effectiveMemCacheWidth,
      memCacheHeight: effectiveMemCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      errorListener: (error) {
        if (cacheKey != null && _isNotFound(error)) {
          _evictBrokenImage(manager, cacheKey);
        }
      },
      errorWidget: (context, url, error) {
        return errorWidget ?? _buildDefaultErrorWidget(error);
      },
      // 用静态 placeholder 而非 progressIndicatorBuilder：后者会让 octo_image
      // 挂上 loadingBuilder，每收到一个字节块就重建一次占位子树；海报网格里
      // 同时下载十几张时这是可观的无效重建。静态路径还能让同步命中的缓存图
      // 直接出图、完全不经过占位。
      placeholder: (context, url) =>
          placeholder ?? _buildLoadingPlaceholder(),
      placeholderFadeInDuration: const Duration(milliseconds: 120),
      httpHeaders: headers,
    );

    return _clipIfNeeded(imageWidget);
  }

  ({int? width, int? height}) _autoCacheExtents(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final logicalWidth =
        _finiteExtent(width) ?? _finiteExtent(constraints.maxWidth);
    final logicalHeight =
        _finiteExtent(height) ?? _finiteExtent(constraints.maxHeight);
    final cacheWidth = _scaledCacheExtent(context, logicalWidth);
    final cacheHeight = _scaledCacheExtent(context, logicalHeight);

    if (cacheWidth == null) return (width: null, height: cacheHeight);
    if (cacheHeight == null) return (width: cacheWidth, height: null);
    if (fit == BoxFit.cover && cacheHeight > cacheWidth) {
      return (width: null, height: cacheHeight);
    }
    return (width: cacheWidth, height: null);
  }

  int? _scaledCacheExtent(BuildContext context, double? logicalExtent) {
    if (logicalExtent == null || logicalExtent <= 0) return null;
    final raw =
        logicalExtent *
        MediaQuery.devicePixelRatioOf(context) *
        _decodeOverscan;
    return raw.ceil().clamp(_minAutoCacheExtent, _maxAutoCacheExtent);
  }

  double? _finiteExtent(double? value) {
    if (value == null || !value.isFinite) return null;
    return value;
  }

  Widget _clipIfNeeded(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  /// 只有明确「资源不存在」才删除缓存条目。
  /// 网络抖动、超时、TLS 中断等错误不应丢弃已下载好的文件，否则下次还得重下。
  static bool _isNotFound(Object error) => shouldEvictImageOnError(error);

  void _evictBrokenImage(CacheManager manager, String cacheKey) {
    if (cacheKey.isEmpty) return;
    unawaited(manager.removeFile(cacheKey).catchError((_) {}));
  }

  /// 构建默认加载占位。
  Widget _buildLoadingPlaceholder() {
    return _ImageStateSurface(width: width, height: height);
  }

  /// 构建默认错误占位符
  Widget _buildDefaultErrorWidget(Object error) {
    return _ImageStateSurface(width: width, height: height, isError: true);
  }

  /// 解析最终加载地址：默认自动套用缓存代理。
  /// 转换依赖 GetX 服务，未注册（如组件测试/极早期启动）时退回原始地址。
  String _resolveUrl() {
    if (kIsWeb || !convertProxyUrl || imageUrl.isEmpty) return imageUrl;
    try {
      return ImageUtil.convertCacheImageUrl(imageUrl);
    } catch (_) {
      return imageUrl;
    }
  }

  String _buildCacheKey(String url) {
    if (url.isEmpty) return url;
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return url;
    }
    final qp = uri.queryParameters;
    final inner = qp['url'] ?? qp['imgurl'];
    if (inner != null && inner.isNotEmpty) {
      return inner;
    }
    return url;
  }
}

/// 图片加载失败时是否应该丢弃磁盘缓存条目。
///
/// 只有服务端明确表示资源不存在（404/410）才值得删；网络抖动、超时、
/// TLS 中断等临时错误若也删缓存，已下载好的文件会被白白重下。
bool shouldEvictImageOnError(Object error) {
  if (error is HttpExceptionWithStatus) {
    return error.statusCode == 404 || error.statusCode == 410;
  }
  return false;
}

class _ImageStateSurface extends StatelessWidget {
  const _ImageStateSurface({this.width, this.height, this.isError = false});

  final double? width;
  final double? height;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    if (isError) {
      return SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: baseColor,
          child: Center(
            child: Icon(
              CupertinoIcons.photo,
              color: theme.colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
        ),
      );
    }
    return _ImageShimmerSurface(
      width: width,
      height: height,
      baseColor: baseColor,
      highlightColor: theme.colorScheme.surfaceContainerLow,
    );
  }
}

/// 加载态微光表面。
///
/// 相比转圈进度条，占位本身不暗示「等待」而只是「还没到」，图片淡入时
/// 观感更接近内容逐步显现。进度条也不再随下载字节数重建。
class _ImageShimmerSurface extends StatefulWidget {
  const _ImageShimmerSurface({
    this.width,
    this.height,
    required this.baseColor,
    required this.highlightColor,
  });

  final double? width;
  final double? height;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<_ImageShimmerSurface> createState() => _ImageShimmerSurfaceState();
}

class _ImageShimmerSurfaceState extends State<_ImageShimmerSurface>
    with SingleTickerProviderStateMixin {
  static const Duration _period = Duration(milliseconds: 1400);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  bool _animating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldAnimate = !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate == _animating) return;
    _animating = shouldAnimate;
    if (shouldAnimate) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // 光带从左侧滑到右侧，两侧留出余量避免边缘生硬出现。
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.6 + t * 3.2, 0),
                  end: Alignment(-0.6 + t * 3.2, 0),
                  colors: [
                    widget.baseColor,
                    widget.highlightColor,
                    widget.baseColor,
                  ],
                  stops: const [0.25, 0.5, 0.75],
                ),
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

/// 圆形头像图片组件
class CachedAvatar extends StatelessWidget {
  const CachedAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholder,
    this.errorWidget,
    this.cacheManager,
    this.cookie,
  });

  /// 图片 URL
  final String imageUrl;

  /// 半径
  final double radius;

  /// 占位符
  final Widget? placeholder;

  /// 错误占位符
  final Widget? errorWidget;

  /// 自定义缓存管理器
  final CacheManager? cacheManager;

  /// Cookie
  final String? cookie;

  @override
  Widget build(BuildContext context) {
    return CachedImage(
      imageUrl: imageUrl,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(radius),
      placeholder: placeholder ?? _buildDefaultPlaceholder(context),
      errorWidget: errorWidget ?? _buildDefaultErrorPlaceholder(context),
      cacheManager: cacheManager,
      cookie: cookie,
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return _buildAvatarState(context, isError: false);
  }

  Widget _buildDefaultErrorPlaceholder(BuildContext context) {
    return _buildAvatarState(context, isError: true);
  }

  Widget _buildAvatarState(BuildContext context, {required bool isError}) {
    return _AvatarStateSurface(radius: radius, isError: isError);
  }
}

class _AvatarStateSurface extends StatelessWidget {
  const _AvatarStateSurface({required this.radius, required this.isError});

  final double radius;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isError
        ? CupertinoColors.systemGrey.resolveFrom(context)
        : theme.colorScheme.primary;

    return ClipOval(
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Center(
            child: Icon(
              isError
                  ? CupertinoIcons.person_crop_circle
                  : CupertinoIcons.person_fill,
              color: foreground,
              size: (radius * 0.64).clamp(18.0, 30.0),
            ),
          ),
        ),
      ),
    );
  }
}
