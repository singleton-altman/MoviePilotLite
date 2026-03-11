import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/image_cache_manager.dart';
import 'package:get/get.dart';

/// 网络图片加载组件
/// 基于 cached_network_image 和 flutter_cache_manager
/// 使用 iOS 风格的 loading 显示进度
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
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.cookie,
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

  @override
  Widget build(BuildContext context) {
    // 构建请求头
    final headers = <String, String>{};
    // 获取cookie，如果没有提供则从AppService获取
    final imageCookie = cookie ?? Get.find<AppService>().cookie;
    if (imageCookie != null && imageCookie.isNotEmpty) {
      headers['cookie'] = imageCookie;
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: cacheManager ?? AppImageCacheManager.instance,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      errorWidget: (context, url, error) {
        return errorWidget ?? _buildDefaultErrorWidget(error);
      },
      progressIndicatorBuilder: (context, url, progress) =>
          placeholder ?? _buildProgressIndicator(progress),
      httpHeaders: headers.isNotEmpty ? headers : null,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  /// 构建进度指示器（iOS 风格）
  Widget _buildProgressIndicator(dynamic progress) {
    double? progressValue;
    if (progress is DownloadProgress) {
      progressValue = progress.progress;
    } else if (progress is double) {
      progressValue = progress;
    }
    return Container(
      width: width,
      height: height,
      color: CupertinoColors.systemGrey6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(color: Colors.white),
            if (progressValue != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 60,
                child: CupertinoActivityIndicator.partiallyRevealed(
                  progress: progressValue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progressValue * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建默认错误占位符（iOS 风格）
  Widget _buildDefaultErrorWidget(Object error) {
    return Container(
      width: width,
      height: height,
      color: CupertinoColors.systemGrey6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo,
              size: 48,
              color: CupertinoColors.systemGrey3,
            ),
            const SizedBox(height: 8),
            Text(
              '加载失败 ${error.toString()}',
              style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ],
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
      placeholder: placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: errorWidget ?? _buildDefaultErrorPlaceholder(),
      cacheManager: cacheManager,
      cookie: cookie,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: CupertinoColors.systemGrey5,
      child: Icon(CupertinoIcons.person, color: CupertinoColors.systemGrey),
    );
  }

  Widget _buildDefaultErrorPlaceholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: CupertinoColors.systemGrey5,
      child: Icon(CupertinoIcons.person, color: CupertinoColors.systemGrey),
    );
  }
}
