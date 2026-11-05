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
  const SharedSubscribeDetailSheet({
    super.key,
    required this.item,
    this.scrollController,
  });

  final SubscribeShareItem item;
  final ScrollController? scrollController;

  @override
  State<SharedSubscribeDetailSheet> createState() =>
      _SharedSubscribeDetailSheetState();
}

class _SharedSubscribeDetailSheetState
    extends State<SharedSubscribeDetailSheet> {
  final state = SharedSubscribeDetailSheetState.normal.obs;
  late final SubscribeController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = !Get.isRegistered<SubscribeController>();
    controller = _ownsController
        ? Get.put(SubscribeController())
        : Get.find<SubscribeController>();
    // controller.loadSharedSubscribeDetail(widget.item.id);
  }

  @override
  void dispose() {
    if (_ownsController && Get.isRegistered<SubscribeController>()) {
      Get.delete<SubscribeController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = ImageUtil.convertCacheImageUrl(widget.item.poster ?? '');
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name ?? '',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
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
                            Expanded(
                              child: Text('作者: ${widget.item.shareUser}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.comment,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.item.shareTitle ?? ''} / ${widget.item.shareComment}',
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
                              state.value =
                                  SharedSubscribeDetailSheetState.forking;
                              final resp = await controller.forkSubscribe(
                                item: widget.item,
                              );
                              if (mounted && resp.success == true) {
                                final isTv =
                                    (widget.item.type ?? '')
                                        .toLowerCase()
                                        .contains('tv') ||
                                    (widget.item.type ?? '').contains('电视剧');
                                final subscribeId = resp.data?.id;
                                if (isTv && subscribeId != null) {
                                  ToastUtil.success(
                                    resp.message ?? '订阅成功',
                                    title: '订阅成功',
                                    duration: const Duration(seconds: 3),
                                    mainButtonText: '编辑',
                                    onMainButtonPressed: () {
                                      Get.toNamed(
                                        '/subscribe-edit',
                                        arguments: SubscribeItem(
                                          id: subscribeId,
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  ToastUtil.success(resp.message ?? '订阅成功');
                                }
                                state.value =
                                    SharedSubscribeDetailSheetState.forked;
                                controller.loadAll();
                              } else {
                                ToastUtil.error(resp.message ?? '订阅失败');
                              }
                            },
                            icon: Icon(Icons.rss_feed_outlined, size: 18),
                            label:
                                state.value ==
                                    SharedSubscribeDetailSheetState.forking
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
                                    ).colorScheme.primary.withValues(alpha: 0.5)
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
          ),
        ],
      ),
    );
  }
}
