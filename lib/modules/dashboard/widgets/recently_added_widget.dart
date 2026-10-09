import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/mediaserver/controllers/mediaserver_controller.dart';
import 'package:moviepilot_mobile/modules/player/controllers/player_launch_controller.dart';
import 'package:moviepilot_mobile/modules/mediaserver/models/latest_media_model.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 最近添加组件
class RecentlyAddedWidget extends StatelessWidget {
  const RecentlyAddedWidget({super.key});

  static const int _previewLimit = 9;
  static const double _narrowBreakpoint = 600;

  static Future<void> showAllSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: const _RecentlyAddedSheet(),
        );
      },
    );
  }

  Widget _buildInfo(BuildContext context) {
    final mediaServerController = Get.find<MediaServerController>();
    return Obx(() {
      final latestMediaList = mediaServerController.latestMediaList;
      if (latestMediaList.value.isEmpty) {
        return const _EmptyState(
          icon: CupertinoIcons.film,
          title: '暂无最近添加内容',
          subtitle: '新入库的媒体会展示在这里',
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final mediaItems = latestMediaList.value;
          final previewItems = mediaItems.take(_previewLimit).toList();
          final grid = width < _narrowBreakpoint
              ? _buildCompactGrid(width, previewItems)
              : _buildWideGrid(width, previewItems);
          if (mediaItems.length <= _previewLimit) return grid;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              grid,
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _ViewAllButton(
                  count: mediaItems.length,
                  onTap: () => showAllSheet(context),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildInfo(context);
  }

  Widget _buildCompactGrid(double width, List<LatestMedia> mediaItems) {
    const gap = 8.0;
    const horizontalPadding = 6.0;
    const columnCount = 3;
    final itemWidth =
        (width - horizontalPadding * 2 - gap * (columnCount - 1)) / columnCount;
    final itemHeight = itemWidth * 1.32;
    final rowCount = (mediaItems.length / columnCount).ceil();
    final totalHeight = rowCount * itemHeight + (rowCount - 1) * gap;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SizedBox(
        height: totalHeight,
        child: Column(
          children: [
            for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
              SizedBox(
                height: itemHeight,
                child: Row(
                  children: [
                    for (
                      var columnIndex = 0;
                      columnIndex < columnCount;
                      columnIndex++
                    ) ...[
                      Expanded(
                        child: _CompactGridSlot(
                          items: mediaItems,
                          index: rowIndex * columnCount + columnIndex,
                        ),
                      ),
                      if (columnIndex != columnCount - 1)
                        const SizedBox(width: gap),
                    ],
                  ],
                ),
              ),
              if (rowIndex != rowCount - 1) const SizedBox(height: gap),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWideGrid(double width, List<LatestMedia> mediaItems) {
    const gap = 12.0;
    const minSecondRowItemWidth = 230.0;
    const horizontalPadding = 6.0;
    final availableWidth = width - horizontalPadding * 2;
    final firstRowItems = mediaItems.take(3).toList();
    final remainingItems = mediaItems.skip(3).toList();
    final firstRowHeight = (availableWidth * 0.32).clamp(204.0, 260.0);
    final secondRowCount = remainingItems.isEmpty
        ? 0
        : ((availableWidth + gap) / (minSecondRowItemWidth + gap))
              .floor()
              .clamp(1, remainingItems.length);
    final secondRowItemWidth = secondRowCount == 0
        ? 0.0
        : (availableWidth - gap * (secondRowCount - 1)) / secondRowCount;
    final secondRowHeight = secondRowCount == 0
        ? 0.0
        : (secondRowItemWidth * 1.34).clamp(178.0, 226.0);
    final secondRows = _chunkMediaItems(remainingItems, secondRowCount);
    final totalHeight =
        firstRowHeight +
        (secondRows.isEmpty
            ? 0
            : gap +
                  secondRows.length * secondRowHeight +
                  (secondRows.length - 1) * gap);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SizedBox(
        height: totalHeight,
        child: Column(
          children: [
            SizedBox(
              height: firstRowHeight,
              child: _WideFeatureRow(items: firstRowItems, gap: gap),
            ),
            if (secondRows.isNotEmpty) ...[
              const SizedBox(height: gap),
              for (
                var rowIndex = 0;
                rowIndex < secondRows.length;
                rowIndex++
              ) ...[
                SizedBox(
                  height: secondRowHeight,
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < secondRows[rowIndex].length;
                        index++
                      ) ...[
                        SizedBox(
                          width: secondRowItemWidth,
                          child: _PosterCard(
                            media: secondRows[rowIndex][index],
                          ),
                        ),
                        if (index != secondRows[rowIndex].length - 1)
                          const SizedBox(width: gap),
                      ],
                    ],
                  ),
                ),
                if (rowIndex != secondRows.length - 1)
                  const SizedBox(height: gap),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<List<LatestMedia>> _chunkMediaItems(
    List<LatestMedia> items,
    int chunkSize,
  ) {
    final chunks = <List<LatestMedia>>[];
    for (var index = 0; index < items.length; index += chunkSize) {
      chunks.add(items.skip(index).take(chunkSize).toList());
    }
    return chunks;
  }
}

class _CompactGridSlot extends StatelessWidget {
  const _CompactGridSlot({required this.items, required this.index});

  final List<LatestMedia> items;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (index >= items.length) return const SizedBox.shrink();
    return _PosterCard(media: items[index], compact: true);
  }
}

class _RecentlyAddedSheet extends StatefulWidget {
  const _RecentlyAddedSheet();

  @override
  State<_RecentlyAddedSheet> createState() => _RecentlyAddedSheetState();
}

class _RecentlyAddedSheetState extends State<_RecentlyAddedSheet> {
  bool _isRefreshing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Get.find<MediaServerController>().refreshLatestMediaList();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: palette.pageBackgroundAlt,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.86,
          child: Obx(() {
            final items =
                Get.find<MediaServerController>().latestMediaList.value;
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '全部新增',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: palette.titleText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isRefreshing && items.isEmpty
                                  ? '正在加载...'
                                  : '${items.length} 个媒体项目',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isRefreshing)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CupertinoActivityIndicator(
                            color: palette.primary,
                          ),
                        ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: palette.mutedText,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isRefreshing && items.isEmpty
                      ? Center(
                          child: CupertinoActivityIndicator(
                            color: palette.primary,
                          ),
                        )
                      : items.isEmpty
                      ? const _EmptyState(
                          icon: CupertinoIcons.film,
                          title: '暂无最近添加内容',
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            const gap = 12.0;
                            const horizontalPadding = 16.0;
                            final isNarrow =
                                constraints.maxWidth <
                                RecentlyAddedWidget._narrowBreakpoint;
                            final columnCount = isNarrow
                                ? 3
                                : (((constraints.maxWidth + gap) / (150 + gap))
                                          .floor())
                                      .clamp(2, 6);
                            final itemWidth =
                                (constraints.maxWidth -
                                    horizontalPadding * 2 -
                                    gap * (columnCount - 1)) /
                                columnCount;
                            final itemHeight = itemWidth * 1.34;

                            return GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                0,
                                horizontalPadding,
                                bottomInset + 18,
                              ),
                              itemCount: items.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columnCount,
                                    mainAxisSpacing: gap,
                                    crossAxisSpacing: gap,
                                    mainAxisExtent: itemHeight,
                                  ),
                              itemBuilder: (context, index) {
                                return _PosterCard(
                                  media: items[index],
                                  compact: isNarrow,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: palette.tileSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.tileBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '查看全部数据',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.mutedText,
              ),
            ),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_up, color: palette.primary, size: 14),
          ],
        ),
      ),
    );
  }
}

class _WideFeatureRow extends StatelessWidget {
  const _WideFeatureRow({required this.items, required this.gap});

  final List<LatestMedia> items;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    if (items.length == 1) return _PosterCard(media: items.first);
    if (items.length == 2) {
      return Row(
        children: [
          Expanded(child: _PosterCard(media: items[0], featured: true)),
          SizedBox(width: gap),
          Expanded(child: _PosterCard(media: items[1])),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 2, child: _PosterCard(media: items[0], featured: true)),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            children: [
              Expanded(child: _PosterCard(media: items[1], compact: true)),
              SizedBox(height: gap),
              Expanded(child: _PosterCard(media: items[2], compact: true)),
            ],
          ),
        ),
      ],
    );
  }
}


/// 卡片点击:进入 MP 媒体详情页;继续观看卡片携带媒体服务器续播上下文,
/// 详情页播放区消费后可一键续播(原生播放)或回退网页播放。
Future<void> _openMediaDetail(LatestMedia media, {bool withResume = false}) async {
  final launch = PlayerLaunchController.to;
  if (!launch.canNativePlay) {
    await launch.webPlay(media.id);
    return;
  }
  try {
    // 从媒体服务器反查 TMDB 身份,带媒体标识进详情页(详情接口必需)
    final item = await launch.fetchKitItem(
      itemId: media.id,
      serverName: media.libraryName,
      serverType: media.serverType,
    );
    final tmdbId = item?.tmdbId;
    // 条目身份先写进上下文:详情页据此立即渲染播放与选集按钮并可直接开播
    // (播放入口只需要条目 id),不必等 MP 详情加载完、也不必等媒体服务器探测。
    // 「继续观看」入口额外带上进度,用于详情页的续播进度行。
    if (tmdbId != null && tmdbId > 0) {
      launch.resumeContexts['tmdb:$tmdbId'] = ResumeContext(
        itemId: media.id,
        serverName: media.libraryName,
        serverType: media.serverType,
        percent: withResume && media.percent != null
            ? media.percent! / 100
            : null,
        label: withResume && media.subtitle.isNotEmpty
            ? media.subtitle
            : null,
        isSeries: media.type.contains('剧') ||
            media.type.toLowerCase().contains('tv'),
      );
    }
    if (tmdbId != null && tmdbId > 0) {
      Get.toNamed('/media-detail', parameters: {
        'path': 'tmdb:$tmdbId',
        'title': media.title,
        if (media.type.isNotEmpty) 'type_name': media.type,
      });
      return;
    }
    // 无 TMDB 映射:直接起播
    await launch.playByItemId(
      itemId: media.id,
      serverName: media.libraryName,
      serverType: media.serverType,
      title: media.title,
      subtitle: media.type.isNotEmpty ? media.type : null,
    );
  } catch (e) {
    ToastUtil.error('获取媒体信息失败: $e');
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.media,
    this.compact = false,
    this.featured = false,
  });

  final LatestMedia media;
  final bool compact;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final titleSize = featured ? 17.0 : (compact ? 12.0 : 13.5);
    final iconSize = compact ? 9.0 : 10.0;
    final metaSize = compact ? 9.0 : 10.0;
    final contentInset = compact ? 9.0 : 12.0;

    return Semantics(
      button: true,
      label: '${media.title}，最近添加',
      child: GestureDetector(
          onTap: () => _openMediaDetail(media, withResume: true),
          child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: palette.surfaceAlt),
              ),
              media.image.isNotEmpty
                  ? CachedImage(
                      imageUrl: ImageUtil.convertInternalImageUrl(media.image),
                      fit: BoxFit.cover,
                    )
                  : _PosterFallback(palette: palette),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: compact ? 0.42 : 0.48),
                    ],
                    stops: const [0.0, 0.58, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: contentInset,
                top: contentInset,
                right: contentInset,
                child: Row(
                  children: [
                    if (media.type.isNotEmpty)
                      Flexible(
                        child: _GlassPill(
                          text: media.type.toUpperCase(),
                          icon: CupertinoIcons.sparkles,
                          compact: compact,
                        ),
                      ),
                    const Spacer(),
                    if (!compact)
                      _CircleButton(icon: CupertinoIcons.plus, size: 28),
                  ],
                ),
              ),
              Positioned(
                left: contentInset,
                right: contentInset,
                bottom: contentInset + 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      media.title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: Colors.white,
                      ),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 6),
                      _MetaLine(
                        text: media.subtitle.isNotEmpty
                            ? media.subtitle
                            : media.libraryName,
                        iconSize: iconSize,
                        fontSize: metaSize,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.text, this.icon, this.compact = false});

  final String text;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 54 : 58),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 9 : 10, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 9 : 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.size = 28});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.text, this.iconSize = 10, this.fontSize = 10});

  final String text;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          CupertinoIcons.rectangle_stack,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.68),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.palette});

  final DashboardPaletteData palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.surfaceAlt,
            Color.alphaBlend(
              palette.primary.withValues(alpha: 0.16),
              palette.surfaceAlt,
            ),
            Color.alphaBlend(
              palette.coolAccent.withValues(alpha: 0.12),
              palette.surfaceAlt,
            ),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.film,
          color: Colors.white.withValues(alpha: 0.55),
          size: 34,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: palette.tileSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.tileBorder),
              ),
              child: Icon(icon, color: palette.mutedText, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.titleText,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: palette.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
