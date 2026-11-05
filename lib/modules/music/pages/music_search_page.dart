import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/music/controllers/music_search_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class MusicSearchPage extends GetView<MusicSearchController> {
  const MusicSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MusicTheme(
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('音乐搜索')),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  child: MusicSearchField(
                    initialValue: controller.keyword.value,
                    onSubmitted: (value) =>
                        controller.search(keywordOverride: value),
                  ),
                ),
                Expanded(child: Obx(() => _results(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    final items = controller.items.toList();
    final loading = controller.isLoading.value;
    final error = controller.errorText.value;
    if (loading && items.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (controller.supported.value == false) {
      return const MusicStateView(
        title: '音乐功能需要 MoviePilot v3 服务端',
        message: '当前服务器版本不支持音乐模块',
      );
    }
    if (items.isEmpty) {
      if (controller.keyword.value.isEmpty) {
        return const MusicStateView(
          title: '寻找你的下一首心动',
          message: '搜索艺人、专辑或歌曲，探索更多音乐。',
          icon: CupertinoIcons.search,
        );
      }
      return MusicStateView(
        title: error == '没有找到匹配的音乐' ? '没有找到匹配的音乐' : '暂时无法载入搜索结果',
        message: error == '没有找到匹配的音乐' ? '换个关键词，再发现一些新声音。' : error,
        onRetry: error == '没有找到匹配的音乐' ? null : () => controller.search(),
        icon: CupertinoIcons.search,
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 &&
            notification is ScrollUpdateNotification &&
            notification.metrics.extentAfter < 240 &&
            error == null) {
          controller.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index < items.length) return _MusicSearchTile(item: items[index]);
          if (error != null) {
            return TextButton(
              onPressed: controller.loadMore,
              child: Text('$error · 重试'),
            );
          }
          if (loading) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          if (controller.hasMore.value) {
            return CupertinoButton(
              onPressed: controller.loadMore,
              child: const Text('加载更多'),
            );
          }
          return const SizedBox(height: 16);
        },
      ),
    );
  }
}

class _MusicSearchTile extends StatelessWidget {
  const _MusicSearchTile({required this.item});

  final MusicExploreItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = item.isArtist
        ? '艺人'
        : item.isAlbum
        ? '专辑'
        : '单曲';
    final subtitle = [
      type,
      if (item.displayArtist.isNotEmpty) item.displayArtist,
      if (item.year != null) '${item.year}',
    ].join(' · ');
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            MusicArtwork(
              imageUrl: item.coverUrl,
              isArtist: item.isArtist,
              size: 60,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final args = <String, String>{
      'mediaId': item.mediaId,
      'mediaSource': item.mediaSource,
    };
    switch (item.musicType) {
      case 'artist':
        args['name'] = item.displayTitle;
        Get.toNamed('/music/artist', arguments: args);
      case 'album':
        args['title'] = item.displayTitle;
        Get.toNamed('/music/album', arguments: args);
      default:
        // 单曲详情会按 recognize 结果自行补全所属专辑；缺少标准 ID 时退回专辑。
        if (item.mediaId.isEmpty) {
          if (item.albumId?.isNotEmpty == true) {
            args['mediaId'] = item.albumId!;
            args['title'] = item.album ?? item.displayTitle;
            Get.toNamed('/music/album', arguments: args);
            return;
          }
          ToastUtil.info('该单曲缺少可用标识，暂时无法打开');
          return;
        }
        args['title'] = item.displayTitle;
        if (item.displayArtist.isNotEmpty) {
          args['artist'] = item.displayArtist;
        }
        Get.toNamed('/music/detail', arguments: args);
    }
  }
}
