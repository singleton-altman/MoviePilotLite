import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 艺术家详情：圆形头像与分页专辑目录。
class MusicArtistPage extends GetView<MusicArtistController> {
  const MusicArtistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MusicTheme(
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Obx(() {
              final artist = controller.artist.value;
              return Text(
                artist?.displayName ?? controller.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }),
            centerTitle: true,
          ),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) => CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: controller.reload),
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      context,
                      constraints.maxHeight < 500 ? 160 : 230,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: MusicSectionHeading(title: '专辑'),
                  ),
                  _buildAlbums(),
                  SliverToBoxAdapter(child: _buildFooter()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double artworkSize) {
    final theme = Theme.of(context);
    return Obx(() {
      final artist = controller.artist.value;
      final error = controller.artistError.value;
      final loading =
          controller.isLoading.value && artist == null && error == null;
      final detail =
          artist ??
          MusicArtistDetail(
            mediaSource: controller.mediaSource,
            mediaId: controller.mediaId,
            name: loading
                ? '加载中的艺术家'
                : controller.artistName.trim().isEmpty
                ? '艺术家'
                : controller.artistName,
          );
      final metaParts = <String>[
        if (detail.artistType?.trim().isNotEmpty == true)
          detail.artistType!.trim(),
        if (detail.country?.trim().isNotEmpty == true)
          detail.country!.trim()
        else if (detail.area?.trim().isNotEmpty == true)
          detail.area!.trim(),
        if (detail.lifeSpan?.trim().isNotEmpty == true) detail.lifeSpan!.trim(),
        if (detail.albumCount != null) '${detail.albumCount} 张专辑',
      ];
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              children: [
                Skeletonizer(
                  enabled: loading,
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) => MusicArtwork(
                          imageUrl: detail.imageUrl,
                          isArtist: true,
                          size: constraints.maxWidth
                              .clamp(0.0, artworkSize)
                              .toDouble(),
                          elevated: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          detail.displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      if (detail.disambiguation?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          detail.disambiguation!.trim(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (metaParts.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          metaParts.join(' · '),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (detail.genres.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          detail.genres.join(' · '),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    '艺术家详情暂不可用，仍可浏览下方专辑。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: MusicTheme.accentOf(context),
                    ),
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.reload,
                    icon: const Icon(CupertinoIcons.arrow_clockwise, size: 16),
                    label: const Text('重试艺术家详情'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAlbums() {
    return Obx(() {
      final error = controller.errorText.value;
      final albums = controller.albums.toList();
      if (controller.isLoading.value && albums.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CupertinoActivityIndicator()),
          ),
        );
      }
      if (error != null && albums.isEmpty) {
        return SliverToBoxAdapter(
          child: MusicStateView(
            title: '无法加载专辑',
            message: error,
            icon: CupertinoIcons.exclamationmark_circle,
            onRetry: controller.reload,
          ),
        );
      }
      if (albums.isEmpty) {
        return const SliverToBoxAdapter(
          child: MusicStateView(
            title: '暂无专辑',
            message: '此艺术家暂未提供专辑信息',
            icon: CupertinoIcons.music_albums,
          ),
        );
      }
      return MusicAlbumGrid(
        items: albums,
        onOpen: (album) => Get.toNamed(
          '/music/album',
          arguments: {
            'mediaId': album.mediaId,
            'mediaSource': album.mediaSource,
            'title': album.displayTitle,
          },
        ),
      );
    });
  }

  Widget _buildFooter() {
    return Obx(() {
      final error = controller.errorText.value;
      final loading =
          controller.isLoading.value || controller.isLoadingMore.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: error != null && controller.albums.isNotEmpty
            ? MusicStateView(
                title: '未能加载更多专辑',
                message: error,
                icon: CupertinoIcons.exclamationmark_circle,
                onRetry: loading ? null : controller.loadMore,
              )
            : LoadMoreFooter(
                hasMore: controller.hasMore.value,
                isLoading: loading,
                hasItems: controller.albums.isNotEmpty,
                onLoadMore: controller.loadMore,
              ),
      );
    });
  }
}
