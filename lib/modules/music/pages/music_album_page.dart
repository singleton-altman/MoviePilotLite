import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 专辑详情：封面、媒体库操作与曲目。
class MusicAlbumPage extends GetView<MusicAlbumController> {
  const MusicAlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MusicTheme(
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Obx(() {
              final album = controller.album.value;
              return Text(
                album?.displayTitle ?? controller.albumTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }),
            centerTitle: true,
          ),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final artworkSize = constraints.maxHeight < 500 ? 190.0 : 270.0;
                return Obx(() {
                  if (controller.isLoading.value) {
                    return IgnorePointer(
                      child: Skeletonizer(
                        enabled: true,
                        child: _buildBody(context, _skeletonAlbum, artworkSize),
                      ),
                    );
                  }
                  final error = controller.errorText.value;
                  final album = controller.album.value;
                  if (album == null) {
                    return Center(
                      child: MusicStateView(
                        title: error == null ? '暂无专辑信息' : '无法加载专辑',
                        message: error,
                        icon: error == null
                            ? CupertinoIcons.music_albums
                            : CupertinoIcons.exclamationmark_circle,
                        onRetry: controller.load,
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: controller.load,
                    child: _buildBody(
                      context,
                      album,
                      artworkSize,
                      error: error,
                    ),
                  );
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MusicAlbumDetail album,
    double artworkSize, {
    String? error,
  }) {
    final theme = Theme.of(context);
    final tracks = album.tracks;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildHeader(context, album, artworkSize),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildActions(context),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 20),
                      MusicStateView(
                        title: '专辑更新失败',
                        message: error,
                        icon: CupertinoIcons.exclamationmark_circle,
                        onRetry: controller.load,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: MusicSectionHeading(
                title: '曲目',
                subtitle: tracks.isEmpty ? null : '${tracks.length} 首歌曲',
              ),
            ),
            if (tracks.isEmpty)
              const SliverToBoxAdapter(
                child: MusicStateView(title: '暂无曲目信息', message: '此专辑暂未提供曲目列表'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTrackRow(
                      context,
                      tracks[index],
                      index,
                      isLast: index == tracks.length - 1,
                    ),
                    childCount: tracks.length,
                  ),
                ),
              ),
            if (album.overview?.trim().isNotEmpty == true)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MusicSectionHeading(title: '专辑简介'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        album.overview!.trim(),
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.65,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    MusicAlbumDetail album,
    double artworkSize,
  ) {
    final theme = Theme.of(context);
    final metaParts = <String>[
      '专辑',
      if (album.year != null) album.year.toString(),
      if (album.totalTracks != null) '${album.totalTracks} 首歌曲',
      if ((album.rating ?? 0) > 0) '评分 ${album.rating!.toStringAsFixed(1)}',
    ];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => MusicArtwork(
            imageUrl: album.coverUrl,
            size: constraints.maxWidth.clamp(0.0, artworkSize).toDouble(),
            elevated: true,
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            album.displayTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (album.displayArtist.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            album.displayArtist,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              height: 1.3,
              color: MusicTheme.accentOf(context),
            ),
          ),
        ],
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
        if (album.genres.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            album.genres.join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final accent = MusicTheme.accentOf(context);
    return Obx(() {
      final operating = controller.isOperating.value;
      final playEnabled =
          !operating &&
          !controller.isLoading.value &&
          controller.canPlayInLibrary;
      final subscribeEnabled =
          !operating && !controller.isLoading.value && controller.canSubscribe;
      final playButton = FilledButton.icon(
        onPressed: playEnabled
            ? () async {
                final error = await controller.playInLibrary();
                if (context.mounted && error != null) {
                  ToastUtil.info(error);
                }
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD92D46),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: operating
            ? const CupertinoActivityIndicator(radius: 9)
            : const Icon(CupertinoIcons.play_fill, size: 18),
        label: const Text(
          '媒体库播放',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
      final subscribeButton = TextButton.icon(
        onPressed: subscribeEnabled
            ? () async {
                final error = await controller.subscribeAlbum();
                if (!context.mounted) return;
                if (error == null) {
                  ToastUtil.success('已提交音乐订阅');
                } else {
                  ToastUtil.error(error);
                }
              }
            : null,
        style: TextButton.styleFrom(
          foregroundColor: accent,
          backgroundColor: accent.withValues(alpha: 0.1),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          operating ? CupertinoIcons.arrow_2_circlepath : CupertinoIcons.bell,
          size: 18,
        ),
        label: const Text(
          '订阅',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(15) > 21) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                playButton,
                const SizedBox(height: 10),
                subscribeButton,
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: playButton),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: subscribeButton),
            ],
          );
        },
      );
    });
  }

  Widget _buildTrackRow(
    BuildContext context,
    MusicTrack track,
    int index, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final duration = track.displayDuration;
    final artists = track.artists.join(' / ');
    final largeText = MediaQuery.textScalerOf(context).scale(15) > 22;
    final secondaryStyle = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final trackId = track.mediaId?.trim() ?? '';
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              (track.trackNumber ?? index + 1).toString(),
              textAlign: TextAlign.center,
              style: secondaryStyle.copyWith(fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.displayTitle,
                  style: const TextStyle(fontSize: 16, height: 1.35),
                ),
                if (artists.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(artists, style: secondaryStyle),
                ],
                if (largeText && duration.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(duration, style: secondaryStyle),
                ],
              ],
            ),
          ),
          if (!largeText && duration.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(duration, style: secondaryStyle),
            ),
        ],
      ),
    );
    if (trackId.isEmpty) return MergeSemantics(child: content);
    final source = controller.album.value?.mediaSource.trim().isNotEmpty == true
        ? controller.album.value!.mediaSource
        : controller.mediaSource;
    return MergeSemantics(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Get.toNamed(
          '/music/detail',
          arguments: {
            'mediaId': trackId,
            'mediaSource': source,
            'title': track.displayTitle,
          },
        ),
        child: content,
      ),
    );
  }

  static final MusicAlbumDetail _skeletonAlbum = MusicAlbumDetail(
    mediaSource: 'musicbrainz',
    mediaId: 'skeleton',
    title: '加载中的专辑',
    artist: '加载中的艺术家',
    year: 2026,
    totalTracks: 8,
    tracks: [
      for (var i = 0; i < 8; i++)
        MusicTrack(title: '加载中的曲目', trackNumber: i + 1, duration: 240),
    ],
  );
}
