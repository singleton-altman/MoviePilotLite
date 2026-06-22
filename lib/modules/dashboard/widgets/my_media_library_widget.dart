import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/mixed_img_widget.dart';
import 'package:moviepilot_mobile/modules/mediaserver/controllers/mediaserver_controller.dart';
import 'package:moviepilot_mobile/modules/mediaserver/models/library_model.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

/// 我的媒体库组件
class MyMediaLibraryWidget extends StatelessWidget {
  const MyMediaLibraryWidget({super.key, this.onTap});
  final Function(MediaLibrary library)? onTap;

  Widget _buildInfo(BuildContext context) {
    final mediaServerController = Get.find<MediaServerController>();
    return Obx(() {
      final libraries = mediaServerController.mediaLibraries.value;

      if (libraries.isEmpty) {
        return const DashboardEmptyState(
          icon: CupertinoIcons.collections,
          title: '暂无媒体库数据',
          subtitle: '连接媒体服务器后会显示在这里',
        );
      }

      return SizedBox(
        height: 184,
        width: double.infinity,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: libraries.length,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final library = libraries[index];
            return SizedBox(width: 256, child: _buildLibraryCard(library));
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildInfo(context);
  }

  Widget _buildLibraryCard(MediaLibrary library) {
    final palette = DashboardPalette.of(Get.context!);
    return InkWell(
      onTap: () => onTap?.call(library),
      borderRadius: BorderRadius.circular(22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildLibraryImage(library),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.16),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: DashboardInfoPill(
                text: library.type.toUpperCase(),
                color: Colors.white,
                backgroundColor: palette.overlay.withValues(alpha: 0.62),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: DashboardInfoPill(
                text: library.server_type.toUpperCase(),
                color: palette.warningAccent,
                backgroundColor: palette.overlay.withValues(alpha: 0.6),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    library.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${library.type} · ${library.server_type}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryImage(MediaLibrary library) {
    final imageUrls = library.image_list?.isNotEmpty == true
        ? library.image_list!
        : [library.image ?? ''];
    return MixedImgWidget(
      imageUrls: imageUrls
          .map((e) => ImageUtil.convertInternalImageUrl(e))
          .toList(),
    );
  }
}
