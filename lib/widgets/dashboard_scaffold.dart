import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = true,
    this.includeUserBackground = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final bool includeUserBackground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DashboardPageBackground(
              includeUserBackground: includeUserBackground,
            ),
          ),
          body,
        ],
      ),
    );
  }
}

class DashboardPageBackground extends StatelessWidget {
  const DashboardPageBackground({super.key, this.includeUserBackground = true});

  final bool includeUserBackground;

  @override
  Widget build(BuildContext context) {
    final appService = Get.find<AppService>();
    final palette = DashboardPalette.of(context);

    return Obx(() {
      final backgroundBytes = appService.backgroundImageBytes.value;
      final backgroundOpacity = appService.backgroundImageOpacity.value;
      final gradientTop = appService.backgroundImageGradientTop.value;
      final gradientBottom = appService.backgroundImageGradientBottom.value;
      final hasUserBackground =
          includeUserBackground &&
          appService.backgroundImageEnabled.value &&
          backgroundBytes != null;

      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: palette.pageBackground),
          if (hasUserBackground)
            _DashboardBackgroundImage(
              bytes: backgroundBytes,
              opacity: backgroundOpacity,
              gradientTop: gradientTop,
              gradientBottom: gradientBottom,
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.overlay.withValues(
                      alpha: palette.isDark ? 0.18 : 0.08,
                    ),
                    palette.pageBackgroundAlt,
                    palette.pageBackground,
                  ],
                  stops: const [0, 0.68, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      palette.primary.withValues(
                        alpha: palette.isDark ? 0.18 : 0.10,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _DashboardBackgroundImage extends StatefulWidget {
  const _DashboardBackgroundImage({
    required this.bytes,
    required this.opacity,
    required this.gradientTop,
    required this.gradientBottom,
  });

  final Uint8List? bytes;
  final double opacity;
  final Color gradientTop;
  final Color gradientBottom;

  @override
  State<_DashboardBackgroundImage> createState() =>
      _DashboardBackgroundImageState();
}

class _DashboardBackgroundImageState extends State<_DashboardBackgroundImage> {
  Uint8List? _bytes;
  ImageProvider? _imageProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncImageProvider();
  }

  @override
  void didUpdateWidget(covariant _DashboardBackgroundImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      _syncImageProvider();
    }
  }

  void _syncImageProvider() {
    final bytes = widget.bytes;
    if (bytes == null) {
      _bytes = null;
      _imageProvider = null;
      return;
    }
    if (identical(_bytes, bytes) && _imageProvider != null) return;
    _bytes = bytes;
    // 用户相册里的原图动辄上千万像素，按原尺寸解码既慢又吃内存；
    // 全屏 cover 显示时只需要高度覆盖屏幕长边，按这个尺寸解码即可（不放大）。
    final mediaQuery = MediaQuery.maybeOf(context);
    final memoryImage = MemoryImage(bytes);
    final ImageProvider provider;
    if (mediaQuery == null || mediaQuery.size.longestSide <= 0) {
      provider = memoryImage;
    } else {
      final targetHeight =
          (mediaQuery.size.longestSide * mediaQuery.devicePixelRatio).ceil();
      provider = ResizeImage(memoryImage, height: targetHeight);
    }
    _imageProvider = provider;
    precacheImage(provider, context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider;
    if (provider == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: widget.opacity,
            child: Image(
              image: provider,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [widget.gradientTop, widget.gradientBottom],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
