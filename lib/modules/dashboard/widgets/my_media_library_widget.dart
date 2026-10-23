import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_skeletons.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/mediaserver/controllers/mediaserver_controller.dart';
import 'package:moviepilot_mobile/modules/mediaserver/models/library_model.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 我的媒体库组件
class MyMediaLibraryWidget extends StatelessWidget {
  const MyMediaLibraryWidget({super.key, this.onTap});
  final Function(MediaLibrary library)? onTap;

  Widget _buildInfo(BuildContext context) {
    final mediaServerController = Get.find<MediaServerController>();
    return Obx(() {
      final libraries = mediaServerController.mediaLibraries.value;

      if (libraries.isEmpty) {
        final dashboardController = Get.find<DashboardController>();
        if (dashboardController.isWidgetLoading('我的媒体库')) {
          return const DashboardPosterRailSkeleton();
        }
        return const _EmptyState(
          icon: CupertinoIcons.collections,
          title: '暂无媒体库数据',
          subtitle: '连接媒体服务器后会显示在这里',
        );
      }

      return SizedBox(
        height: 202,
        width: double.infinity,
        child: ListView.separated(
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: libraries.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final library = libraries[index];
            return SizedBox(
              width: 280,
              child: _LibraryCard(library: library, onTap: onTap),
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildInfo(context);
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.library, this.onTap});

  final MediaLibrary library;
  final Function(MediaLibrary library)? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final serverLabel = library.server_type.trim();
    final semanticLabel = [
      library.name.trim().isNotEmpty
          ? library.name.trim()
          : library.type.trim(),
      if (serverLabel.isNotEmpty) serverLabel,
    ].where((e) => e.isNotEmpty).join('，');

    return Semantics(
      button: true,
      label: semanticLabel.isEmpty ? '媒体库' : '$semanticLabel，媒体库',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onTap?.call(library),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.36),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: palette.surfaceAlt),
                  ),
                  _buildLibraryImage(library),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.58),
                        ],
                        stops: const [0.54, 0.82, 1.0],
                      ),
                    ),
                  ),
                  // 底图偏暗时圆角轮廓会和深色页面背景融在一起，用极细描边勾出卡片边界。
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: palette.isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: _LibraryCaption(library: library),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryImage(MediaLibrary library) {
    final imageUrl = _primaryImageUrl(library);

    if (imageUrl.isEmpty) {
      final palette = DashboardPalette.of(Get.context!);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.surfaceAlt,
              Color.alphaBlend(
                palette.primary.withValues(alpha: 0.16),
                palette.surfaceAlt,
              ),
              Color.alphaBlend(
                palette.coolAccent.withValues(alpha: 0.12),
                palette.surfaceAlt,
              ),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.collections,
            color: Colors.white.withValues(alpha: 0.55),
            size: 40,
          ),
        ),
      );
    }

    return CachedImage(imageUrl: imageUrl, fit: BoxFit.cover);
  }

  String _primaryImageUrl(MediaLibrary library) {
    final image = (library.image ?? '').trim();
    if (image.isNotEmpty) {
      return ImageUtil.convertInternalImageUrl(image);
    }
    for (final candidate in library.image_list ?? const <String>[]) {
      final trimmed = candidate.trim();
      if (trimmed.isNotEmpty) {
        return ImageUtil.convertInternalImageUrl(trimmed);
      }
    }
    return '';
  }
}

/// 卡片左下角的一行说明：媒体库名称 · 服务器类型
class _LibraryCaption extends StatelessWidget {
  const _LibraryCaption({required this.library});

  final MediaLibrary library;

  @override
  Widget build(BuildContext context) {
    final name = library.name.trim().isNotEmpty
        ? library.name.trim()
        : library.type.trim();
    final server = library.server_type.trim();

    if (name.isEmpty && server.isEmpty) return const SizedBox.shrink();

    const nameStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      height: 1.15,
      color: Colors.white,
    );
    final serverStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.72),
    );

    return Text.rich(
      TextSpan(
        children: [
          if (name.isNotEmpty) TextSpan(text: name, style: nameStyle),
          if (name.isNotEmpty && server.isNotEmpty) ...[
            TextSpan(text: ' · ', style: serverStyle),
            TextSpan(text: server, style: serverStyle),
          ] else if (server.isNotEmpty)
            TextSpan(text: server, style: nameStyle),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.tileSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.tileBorder),
              ),
              child: Icon(icon, color: palette.mutedText, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.titleText,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: palette.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
