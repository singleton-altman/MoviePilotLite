import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';
import 'package:moviepilot_mobile/modules/search/pages/search_mid_sheet.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 单曲详情：曲目主信息 + 所属专辑曲目表（当前曲目高亮）。
/// 对齐 v3 MusicDetailView：recognize 取实体，album_id 补全整张专辑。
class MusicRecordingPage extends GetView<MusicRecordingController> {
  const MusicRecordingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MusicTheme(
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Obx(() {
              final title =
                  controller.recording.value?.displayTitle ??
                  controller.seedTitle;
              return Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }),
            centerTitle: true,
            actions: [
              Obx(() {
                if (controller.recording.value?.detailLink?.isNotEmpty != true) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  tooltip: '在数据源查看',
                  icon: const Icon(CupertinoIcons.link, size: 20),
                  onPressed: () => WebUtil.open(
                    url: controller.recording.value?.detailLink,
                  ),
                );
              }),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.recording.value == null) {
                return IgnorePointer(
                  child: Skeletonizer(
                    enabled: true,
                    child: _buildBody(
                      context,
                      _skeleton,
                      artworkSize: 240,
                    ),
                  ),
                );
              }
              final error = controller.errorText.value;
              final detail = controller.recording.value;
              if (detail == null) {
                return MusicStateView(
                  title: error == null ? '暂无单曲信息' : '无法加载单曲',
                  message: error,
                  icon: error == null
                      ? CupertinoIcons.music_note_2
                      : CupertinoIcons.exclamationmark_circle,
                  onRetry: controller.load,
                );
              }
              return RefreshIndicator(
                onRefresh: controller.load,
                child: LayoutBuilder(
                  builder: (context, constraints) => _buildBody(
                    context,
                    detail,
                    artworkSize: constraints.maxHeight < 500 ? 180.0 : 250.0,
                    error: error,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MusicRecordingDetail detail, {
    required double artworkSize,
    String? error,
  }) {
    final theme = Theme.of(context);
    final tracks = controller.album.value?.tracks ?? const <MusicTrack>[];
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
                    _buildHeader(context, detail, artworkSize),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildActions(context, detail),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 20),
                      MusicStateView(
                        title: '单曲更新失败',
                        message: error,
                        icon: CupertinoIcons.exclamationmark_circle,
                        onRetry: controller.load,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (tracks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: MusicSectionHeading(
                  title: controller.album.value?.displayTitle ?? '所属专辑',
                  subtitle: '${tracks.length} 首歌曲',
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTrackRow(
                      context,
                      tracks[index],
                      index,
                      active: tracks[index].mediaId == detail.mediaId,
                      isLast: index == tracks.length - 1,
                    ),
                    childCount: tracks.length,
                  ),
                ),
              ),
            ],
            if ((detail.albumId ?? '').isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    '该单曲未关联专辑信息',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
    MusicRecordingDetail detail,
    double artworkSize,
  ) {
    final theme = Theme.of(context);
    final metaParts = <String>[
      if ((detail.albumType ?? '').trim().isNotEmpty)
        detail.albumType!.trim(),
      if ((detail.releaseDate ?? '').trim().isNotEmpty)
        detail.releaseDate!.trim()
      else if (detail.year != null)
        detail.year.toString(),
      if ((detail.album ?? '').trim().isNotEmpty) detail.album!.trim(),
      if (detail.totalTracks != null) '${detail.totalTracks} 首歌曲',
      if (detail.displayDuration.isNotEmpty) detail.displayDuration,
      if (detail.displayTrackNumber.isNotEmpty)
        '第 ${detail.displayTrackNumber} 轨',
      if (detail.isrc?.isNotEmpty == true) 'ISRC ${detail.isrc}',
    ];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => MusicArtwork(
            imageUrl: detail.coverUrl,
            size: constraints.maxWidth.clamp(0.0, artworkSize).toDouble(),
            elevated: true,
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            detail.displayTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (detail.displayArtist.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            detail.displayArtist,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              height: 1.3,
              color: MusicTheme.accentOf(context),
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
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildActions(BuildContext context, MusicRecordingDetail detail) {
    final accent = MusicTheme.accentOf(context);
    return Obx(() {
      final operating = controller.isOperating.value;
      final busy = operating || controller.isLoading.value;
      final subscribed = controller.isSubscribed.value == true;
      final subscribeButton = FilledButton.icon(
        onPressed: (!busy && controller.canSubscribe)
            ? () async {
                final error = await controller.toggleSubscribe();
                if (!context.mounted) return;
                if (error == null) {
                  ToastUtil.success(
                    subscribed ? '已取消单曲订阅' : '已提交单曲订阅',
                  );
                } else {
                  ToastUtil.error(error);
                }
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: subscribed ? accent : accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: operating
            ? const CupertinoActivityIndicator(radius: 9)
            : Icon(
                subscribed
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                size: 18,
              ),
        label: Text(
          subscribed ? '取消订阅' : '订阅',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
      final resourceButton = TextButton.icon(
        onPressed: (!busy && controller.canSearch)
            ? () => _openResourceSearch(detail)
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
        icon: const Icon(CupertinoIcons.search, size: 18),
        label: const Text(
          '搜索资源',
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
                subscribeButton,
                const SizedBox(height: 10),
                resourceButton,
              ],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: subscribeButton),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: resourceButton),
            ],
          );
        },
      );
    });
  }

  /// 只列出支持音乐搜索的站点，确认后按 v3 契约带 media_source 与 music_type。
  Future<void> _openResourceSearch(MusicRecordingDetail detail) async {
    final limited = await controller.musicSiteIds();
    final result = await Get.bottomSheet<({String area, List<int> sites})>(
      SiteSelectSheet(
        hasSegment: false,
        mediaSearchKey: '${detail.mediaSource}:${detail.mediaId}',
      ),
      isScrollControlled: true,
    );
    if (result == null) return;
    final sites = result.sites.where((id) => limited?.contains(id) ?? true);
    if (sites.isEmpty) {
      ToastUtil.info('请至少选择一个支持音乐搜索的站点');
      return;
    }
    Get.toNamed(
      '/search-media-result',
      parameters: {
        'mediaSearchKey': '${detail.mediaSource}:${detail.mediaId}',
        'area': 'title',
        'sites': sites.join(','),
        'year': detail.year?.toString() ?? '',
        'mtype': '音乐',
        'music_type': detail.isAlbum ? 'album' : 'recording',
        'title': detail.displayTitle,
      },
    );
  }

  Widget _buildTrackRow(
    BuildContext context,
    MusicTrack track,
    int index, {
    required bool active,
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
    final accent = MusicTheme.accentOf(context);
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
              style: secondaryStyle.copyWith(
                fontSize: 15,
                color: active ? accent : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.displayTitle,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: active ? FontWeight.w600 : null,
                    color: active ? accent : null,
                  ),
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
    final trackId = track.mediaId?.trim() ?? '';
    if (trackId.isEmpty || active) {
      return MergeSemantics(child: content);
    }
    return MergeSemantics(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Get.toNamed(
          '/music/detail',
          arguments: {
            'mediaId': trackId,
            'mediaSource': controller.recording.value?.mediaSource.isNotEmpty ==
                    true
                ? controller.recording.value!.mediaSource
                : controller.mediaSource,
            'title': track.displayTitle,
          },
        ),
        child: content,
      ),
    );
  }

  static const MusicRecordingDetail _skeleton = MusicRecordingDetail(
    mediaSource: 'musicbrainz',
    mediaId: 'skeleton',
    title: '加载中的单曲',
    artist: '加载中的艺术家',
    album: '加载中的专辑',
    year: 2026,
    trackNumber: 1,
    totalTracks: 10,
    duration: 245,
  );
}
