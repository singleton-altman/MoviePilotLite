import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/subtitle/controllers/subtitle_search_controller.dart';
import 'package:moviepilot_mobile/modules/subtitle/widgets/subtitle_search_item_card.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class SubtitleSearchResultPage extends GetView<SubtitleSearchController> {
  const SubtitleSearchResultPage({super.key});

  static const double _horizontalPadding = 16;

  bool get immersive =>
      (controller.prefillBackdrop ?? '').trim().isNotEmpty &&
      (controller.prefillTitle ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: immersive ? AppTheme.darkBackgroundColor : null,
      appBar: immersive ? null : _buildAppBar(context),
      body: immersive ? _buildImmersiveBody(context) : _buildPlainBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        controller.prefillTitle?.trim().isNotEmpty == true
            ? '字幕 · ${controller.prefillTitle}'
            : '字幕搜索',
      ),
      actions: [
        IconButton(
          onPressed: () => controller.startSearch(),
          icon: const Icon(CupertinoIcons.refresh),
        ),
      ],
    );
  }

  Widget _buildImmersiveBody(BuildContext context) {
    final rawBackdrop = controller.prefillBackdrop!.trim();
    final backdrop = rawBackdrop.isEmpty
        ? null
        : ImageUtil.convertCacheImageUrl(rawBackdrop);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (backdrop != null && backdrop.isNotEmpty)
          CachedImage(imageUrl: backdrop, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                AppTheme.darkBackgroundColor.withValues(alpha: 0.92),
                AppTheme.darkBackgroundColor,
              ],
              stops: const [0, 0.28, 0.55],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildImmersiveHeader(context),
              Expanded(child: _buildListArea(context, dark: true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImmersiveHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(CupertinoIcons.back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              controller.prefillTitle ?? '字幕搜索',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => controller.startSearch(),
            icon: const Icon(CupertinoIcons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPlainBody(BuildContext context) {
    return _buildListArea(context, dark: false);
  }

  Widget _buildListArea(BuildContext context, {required bool dark}) {
    return Column(
      children: [
        _buildProgressBar(context, dark: dark),
        Expanded(
          child: Obx(() {
            final loading = controller.isLoading.value;
            final items = controller.items.toList();
            final error = controller.errorText.value;
            if (loading && items.isEmpty) {
              return const Center(child: AppLoading(message: '正在搜索字幕'));
            }
            if (!loading && items.isEmpty) {
              return _buildEmpty(context, error: error, dark: dark);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                12,
                _horizontalPadding,
                28,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 12,
                  ),
                  child: SubtitleSearchItemCard(
                    key: ValueKey(item.key),
                    item: item,
                    immersive: dark,
                    downloading: controller.downloadingKeys.contains(item.key),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, {required bool dark}) {
    return Obx(() {
      if (!controller.isProgressActive.value &&
          controller.progressMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }
      final progress = controller.searchProgress.value;
      final message = controller.progressMessage.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: controller.isProgressActive.value
                ? (progress > 0 ? progress : null)
                : 1,
            minHeight: 3,
            backgroundColor: dark ? Colors.white.withValues(alpha: 0.12) : null,
          ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: dark
                        ? Colors.white70
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildEmpty(
    BuildContext context, {
    required String? error,
    required bool dark,
  }) {
    final color = dark
        ? Colors.white70
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error == null
                  ? CupertinoIcons.text_bubble
                  : CupertinoIcons.exclamationmark_circle,
              size: 42,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              error ?? '未找到字幕',
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 15),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: controller.startSearch,
              child: const Text('重新搜索'),
            ),
          ],
        ),
      ),
    );
  }
}
