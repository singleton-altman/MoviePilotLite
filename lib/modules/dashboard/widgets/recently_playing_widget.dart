import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/mediaserver/controllers/mediaserver_controller.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 最近播放组件
class RecentlyPlayingWidget extends StatelessWidget {
  const RecentlyPlayingWidget({super.key});

  Widget _buildInfo(BuildContext context) {
    final mediaServerController = Get.find<MediaServerController>();
    return Obx(() {
      final playingMedia = mediaServerController.playingMedia;
      if (playingMedia.value == null || playingMedia.value!.isEmpty) {
        return const DashboardEmptyState(
          icon: CupertinoIcons.play_rectangle,
          title: '暂无继续观看内容',
          subtitle: '开始播放后会在这里继续追看',
        );
      }

      return SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: playingMedia.value!.length,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final media = playingMedia.value![index];
            return SizedBox(width: 272, child: _buildMediaCard(media));
          },
        ),
      );
    });
  }

  Widget _buildMediaCard(dynamic media) {
    final palette = DashboardPalette.of(Get.context!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          media.image.isNotEmpty
              ? CachedImage(
                  imageUrl: ImageUtil.convertInternalImageUrl(media.image),
                  fit: BoxFit.cover,
                )
              : Container(color: palette.surfaceAlt),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.24),
                  Colors.black.withValues(alpha: 0.78),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: DashboardInfoPill(
              text: media.type.isEmpty ? '播放中' : media.type,
              color: Colors.white,
              backgroundColor: palette.overlay.withValues(alpha: 0.68),
            ),
          ),
          const Positioned(
            right: 14,
            top: 14,
            child: Icon(
              CupertinoIcons.play_circle_fill,
              color: Colors.white,
              size: 28,
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  media.libraryName.isNotEmpty
                      ? media.libraryName
                      : media.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
                const SizedBox(height: 10),
                DashboardProgressBar(
                  value: 0.66,
                  color: palette.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.32),
                  height: 4,
                ),
              ],
            ),
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
