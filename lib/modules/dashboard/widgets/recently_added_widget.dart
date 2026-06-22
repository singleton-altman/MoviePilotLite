import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/mediaserver/controllers/mediaserver_controller.dart';
import 'package:moviepilot_mobile/modules/mediaserver/models/latest_media_model.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 最近添加组件
class RecentlyAddedWidget extends StatelessWidget {
  const RecentlyAddedWidget({super.key});

  Widget _buildInfo(BuildContext context) {
    final mediaServerController = Get.find<MediaServerController>();
    return Obx(() {
      final latestMediaList = mediaServerController.latestMediaList;
      if (latestMediaList.value.isEmpty) {
        return const DashboardEmptyState(
          icon: CupertinoIcons.film,
          title: '暂无最近添加内容',
          subtitle: '新入库的媒体会展示在这里',
        );
      }

      return SizedBox(
        height: 228,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: latestMediaList.value.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final media = latestMediaList.value[index];
            return _buildMediaCard(media);
          },
        ),
      );
    });
  }

  Widget _buildMediaCard(LatestMedia media) {
    final palette = DashboardPalette.of(Get.context!);
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  media.image.isNotEmpty
                      ? CachedImage(
                          imageUrl: ImageUtil.convertInternalImageUrl(
                            media.image,
                          ),
                          fit: BoxFit.cover,
                        )
                      : Container(color: palette.surfaceAlt),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.58),
                        ],
                        stops: const [0.42, 1],
                      ),
                    ),
                  ),
                  if (media.type.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: DashboardInfoPill(
                        text: media.type.toUpperCase(),
                        color: Colors.white,
                        backgroundColor: palette.overlay.withValues(
                          alpha: 0.62,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            media.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.titleText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            media.subtitle.isNotEmpty ? media.subtitle : media.libraryName,
            style: TextStyle(fontSize: 11, color: palette.mutedText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildInfo(context);
  }
}
