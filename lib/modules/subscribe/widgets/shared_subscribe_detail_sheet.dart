import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

enum SharedSubscribeDetailSheetState { normal, forking, forked }

class SharedSubscribeDetailSheet extends StatefulWidget {
  const SharedSubscribeDetailSheet({super.key, required this.item});

  final SubscribeShareItem item;

  @override
  State<SharedSubscribeDetailSheet> createState() =>
      _SharedSubscribeDetailSheetState();
}

class _SharedSubscribeDetailSheetState
    extends State<SharedSubscribeDetailSheet> {
  final controller = Get.put(SubscribeController());
  final state = SharedSubscribeDetailSheetState.normal.obs;
  @override
  void initState() {
    super.initState();
    // controller.loadSharedSubscribeDetail(widget.item.id);
  }

  @override
  void dispose() {
    Get.delete<SubscribeController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = ImageUtil.convertCacheImageUrl(widget.item.poster ?? '');
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  widget.item.name ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            CachedImage(
              imageUrl: posterUrl,
              width: 100,
              height: 150,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 16),
            Text(
              widget.item.description ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Section(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('作者: ${widget.item.shareUser}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.comment,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.item.shareTitle ?? ''} / ${widget.item.shareComment}',
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.paperplane_fill,
                        color: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 8),
                      Text('复用人数: ${widget.item.count}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Obx(
                  () => Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (state.value ==
                                SharedSubscribeDetailSheetState.forking ||
                            state.value ==
                                SharedSubscribeDetailSheetState.forked) {
                          return;
                        }
                        state.value = SharedSubscribeDetailSheetState.forking;
                        final resp = await controller.forkSubscribe(
                          item: widget.item,
                        );
                        if (mounted && resp.success == true) {
                          ToastUtil.success(resp.message ?? '订阅成功');
                          state.value = SharedSubscribeDetailSheetState.forked;
                          controller.loadAll();
                        } else {
                          ToastUtil.error(resp.message ?? '订阅失败');
                        }
                      },
                      icon: Icon(Icons.rss_feed_outlined, size: 18),
                      label:
                          state.value == SharedSubscribeDetailSheetState.forking
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : Text('订阅'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            state.value ==
                                SharedSubscribeDetailSheetState.forking
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5)
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
