import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/music/controllers/music_library_controller.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_discovery_sections.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MusicLibraryPage extends GetView<MusicLibraryController> {
  const MusicLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MusicTheme(child: _LibraryScaffold(controller: controller));
  }
}

/// iOS 大标题行为：顶部只显示大标题，滚动越过标题后导航栏才出现紧凑标题，
/// 避免大标题与导航栏标题同时可见造成重复。
class _LibraryScaffold extends StatefulWidget {
  const _LibraryScaffold({required this.controller});

  final MusicLibraryController controller;

  @override
  State<_LibraryScaffold> createState() => _LibraryScaffoldState();
}

class _LibraryScaffoldState extends State<_LibraryScaffold> {
  static const double _compactThreshold = 56;
  bool _showCompactTitle = false;

  MusicLibraryController get controller => widget.controller;

  bool _handleScroll(ScrollNotification notification) {
    final showCompact = notification.metrics.pixels > _compactThreshold;
    if (showCompact != _showCompactTitle) {
      setState(() => _showCompactTitle = showCompact);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showCompactTitle ? const Text('音乐') : null,
        actions: [
          IconButton(
            tooltip: '切换音乐来源',
            icon: const Icon(CupertinoIcons.music_note_list),
            onPressed: _showSourcePicker,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScroll,
          child: Obx(() {
            final supported = controller.supported.value;
            final error = controller.errorText.value;
            if (supported == null) {
              if (error != null && !controller.isLoading.value) {
                return MusicStateView(
                  title: '暂时无法载入音乐',
                  message: error,
                  onRetry: controller.reload,
                );
              }
              return const Center(child: CupertinoActivityIndicator());
            }
            if (!supported) {
              return const MusicStateView(
                title: '音乐功能需要 MoviePilot v3 服务端',
                message: '当前服务器版本不支持音乐模块',
                icon: CupertinoIcons.music_albums,
              );
            }
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: controller.reload),
                SliverToBoxAdapter(child: _header(context)),
                ..._discoverySections(),
                if (controller.availableGenres.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: MusicSectionHeading(
                      title: '风格漫游',
                      subtitle: '选择一种风格，探索下方专辑',
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MusicGenrePicker(
                      genres: controller.availableGenres,
                      selected: controller.selectedGenre.value,
                      onSelected: controller.selectGenre,
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: MusicSectionHeading(
                    title: controller.selectedGenre.value == null
                        ? '探索专辑'
                        : '${controller.selectedGenre.value} · 专辑',
                    subtitle: controller.selectedGenre.value == null
                        ? '继续探索 · 已载入 ${controller.items.length} 项音乐资料'
                        : '当前已载入内容中的风格筛选',
                  ),
                ),
                _content(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      children: [
                        if (error != null && controller.items.isNotEmpty)
                          TextButton(
                            onPressed: controller.loadMore,
                            child: Text('$error · 重试'),
                          ),
                        LoadMoreFooter(
                          hasMore: controller.hasMore.value,
                          isLoading: controller.isLoading.value,
                          hasItems: controller.items.isNotEmpty,
                          onLoadMore: controller.loadMore,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// SwiftUI searchable 位置：搜索框紧跟大标题，其余内容在其下方。
  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const Text(
              '音乐库',
              style: TextStyle(
                fontSize: 34,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          MusicSearchField(
            onSubmitted: (term) =>
                Get.toNamed('/music/search', parameters: {'keyword': term}),
          ),
        ],
      ),
    );
  }

  /// iOS 原生动作面板：当前来源带选中语义与对勾，选择后立即切换。
  void _showSourcePicker() {
    final current = controller.selectedSource.value;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('音乐来源'),
        actions: [
          for (final source in kMusicExploreSources)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                controller.selectSource(source.id);
              },
              child: Semantics(
                selected: source.id == current,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (source.id == current) ...[
                      const Icon(CupertinoIcons.check_mark, size: 17),
                      const SizedBox(width: 6),
                    ],
                    Text(source.label),
                  ],
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  List<Widget> _discoverySections() {
    final albums = controller.featuredAlbums;
    if (albums.isEmpty) return const [];
    final source = kMusicExploreSources
        .firstWhere((source) => source.id == controller.selectedSource.value)
        .label;
    return [
      SliverToBoxAdapter(
        child: MusicSectionHeading(
          title: '值得一听',
          subtitle: '$source · 从专辑开始，发现新的声音',
        ),
      ),
      SliverToBoxAdapter(
        child: MusicFeaturedShelf(
          key: ValueKey('featured-${controller.selectedSource.value}'),
          items: albums,
          onOpen: _openItem,
        ),
      ),
      if (controller.discoveryAlbums.length > 1) ...[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Divider(height: 1),
          ),
        ),
        SliverToBoxAdapter(
          child: MusicSectionHeading(
            title: '发现 TOP ${controller.discoveryAlbums.length}',
            subtitle: '按来源返回顺序展示 · 序号非官方榜单名次',
          ),
        ),
        SliverToBoxAdapter(
          child: MusicDiscoveryRanking(
            key: ValueKey('ranking-${controller.selectedSource.value}'),
            items: controller.discoveryAlbums,
            onOpen: _openItem,
          ),
        ),
      ],
    ];
  }

  Widget _content() {
    final items = controller.visibleItems;
    if (controller.isLoading.value && controller.items.isEmpty) {
      return Skeletonizer.sliver(
        enabled: true,
        child: MusicAlbumGrid(
          items: List.generate(
            6,
            (index) => MusicExploreItem(
              musicType: 'album',
              mediaSource: 'musicbrainz',
              mediaId: 'skeleton-$index',
              title: '加载中的专辑',
              artist: '加载中的艺人',
            ),
          ),
        ),
      );
    }
    final error = controller.errorText.value;
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: error == null
            ? const MusicStateView(title: '暂无音乐内容', message: '试试切换音乐来源，或下拉刷新。')
            : MusicStateView(
                title: '暂时无法载入音乐',
                message: error,
                onRetry: controller.reload,
              ),
      );
    }
    return MusicAlbumGrid(items: items, onOpen: _openItem);
  }

  void _openItem(MusicExploreItem item) {
    if (item.isArtist) {
      Get.toNamed(
        '/music/artist',
        arguments: {
          'mediaId': item.mediaId,
          'mediaSource': item.mediaSource,
          'name': item.displayTitle,
        },
      );
    } else if (item.isAlbum) {
      Get.toNamed(
        '/music/album',
        arguments: {
          'mediaId': item.mediaId,
          'mediaSource': item.mediaSource,
          'title': item.displayTitle,
        },
      );
    }
  }
}
