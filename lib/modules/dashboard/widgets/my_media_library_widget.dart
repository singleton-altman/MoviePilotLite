import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_section.dart';
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
        return const Center(child: Text('暂无媒体库数据'));
      }

      return SizedBox(
        height: 160,
        width: double.infinity,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: libraries.length,
          itemBuilder: (context, index) {
            final library = libraries[index];
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(width: 240, child: _buildLibraryCard(library)),
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: '我的媒体库',
      icon: CupertinoIcons.collections,
      child: _buildInfo(context),
    );
  }

  Widget _buildLibraryCard(MediaLibrary library) {
    return InkWell(
      onTap: () => onTap?.call(library),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildLibraryImage(library),
            // 渐变遮罩，确保文字清晰可见
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            // 文本信息显示在图片上方
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    library.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        library.type,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        library.server_type,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
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
    // 封面图作为背景
    return MixedImgWidget(
      imageUrls: imageUrls
          .map((e) => ImageUtil.convertInternalImageUrl(e))
          .toList(),
    );
  }
}
