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

/// 继续观看组件
class RecentlyPlayingWidget extends StatelessWidget {
  const RecentlyPlayingWidget({super.key});

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
          child: const _RecentlyPlayingSheet(),
        );
      },
    );
  }

  Widget _buildInfo(BuildContext context) {
    final mediaServerController = Get.find<MediaServerController>();
    return Obx(() {
      final playingMedia = mediaServerController.playingMedia.value ?? const [];
      if (playingMedia.isEmpty) {
        return const _EmptyState(
          icon: CupertinoIcons.play_rectangle,
          title: '暂无继续观看内容',
          subtitle: '开始播放后会在这里继续追看',
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final previewItems = playingMedia.take(_previewLimit).toList();
          final grid = width < _narrowBreakpoint
              ? _buildCompactGrid(width, previewItems)
              : _buildWideGrid(width, previewItems);
          if (playingMedia.length <= _previewLimit) return grid;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              grid,
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _ViewAllButton(
                  count: playingMedia.length,
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
                          child: _ContinuePosterCard(
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
    return _ContinuePosterCard(media: items[index], compact: true);
  }
}

class _RecentlyPlayingSheet extends StatefulWidget {
  const _RecentlyPlayingSheet();

  @override
  State<_RecentlyPlayingSheet> createState() => _RecentlyPlayingSheetState();
}

class _RecentlyPlayingSheetState extends State<_RecentlyPlayingSheet> {
  bool _isRefreshing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Get.find<MediaServerController>().refreshPlayingMedia();
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
                Get.find<MediaServerController>().playingMedia.value ??
                const [];
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
                              '全部继续观看',
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
                          icon: CupertinoIcons.play_rectangle,
                          title: '暂无继续观看内容',
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            const gap = 12.0;
                            const horizontalPadding = 16.0;
                            final isNarrow =
                                constraints.maxWidth <
                                RecentlyPlayingWidget._narrowBreakpoint;
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
                                return _ContinuePosterCard(
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
    if (items.length == 1) return _ContinuePosterCard(media: items.first);
    if (items.length == 2) {
      return Row(
        children: [
          Expanded(child: _ContinuePosterCard(media: items[0], featured: true)),
          SizedBox(width: gap),
          Expanded(child: _ContinuePosterCard(media: items[1])),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _ContinuePosterCard(media: items[0], featured: true),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _ContinuePosterCard(media: items[1], compact: true),
              ),
              SizedBox(height: gap),
              Expanded(
                child: _ContinuePosterCard(media: items[2], compact: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


/// 卡片点击:继续观看统一直接播放(原生/网页回退)。
Future<void> _openMediaDetail(LatestMedia media, {bool withResume = false}) async {
  final launch = PlayerLaunchController.to;
  if (!launch.canNativePlay) {
    await launch.webPlay(media.id);
    return;
  }
  // 继续观看统一直接播放:剧集自动定位「下一集未看完的单集」,
  // 续播位置由媒体服务器的观看进度决定
  await launch.playByItemId(
    itemId: media.id,
    serverName: media.libraryName,
    serverType: media.serverType,
    title: media.title,
    subtitle: media.type.isNotEmpty ? media.type : null,
  );
}

class _ContinuePosterCard extends StatelessWidget {
  const _ContinuePosterCard({
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
    final progress = ((media.percent ?? 0) / 100).clamp(0.0, 1.0);
    final titleSize = featured ? 17.0 : (compact ? 12.0 : 13.5);
    final iconSize = compact ? 9.0 : 10.0;
    final metaSize = compact ? 9.0 : 10.0;
    final contentInset = compact ? 9.0 : 12.0;

    return Semantics(
      button: true,
      label: '${media.title}，继续观看',
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
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: compact ? 0.46 : 0.54),
                    ],
                    stops: const [0.0, 0.56, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: contentInset,
                top: contentInset,
                right: contentInset,
                child: Row(
                  children: [
                    Flexible(
                      child: _GlassPill(
                        text: media.type.isEmpty ? '继续观看' : media.type,
                        icon: CupertinoIcons.play_fill,
                        compact: compact,
                      ),
                    ),
                    const Spacer(),
                    if (!compact)
                      _CircleButton(
                        icon: CupertinoIcons.play_arrow_solid,
                        size: 28,
                      ),
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
                      Row(
                        children: [
                          Expanded(
                            child: _MetaLine(
                              text: media.libraryName.isNotEmpty
                                  ? media.libraryName
                                  : media.subtitle,
                              iconSize: iconSize,
                              fontSize: metaSize,
                            ),
                          ),
                          if (progress > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    _ProgressBar(
                      value: progress > 0 ? progress : 0.08,
                      color: palette.warningAccent,
                    ),
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

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 3.5,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
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
              palette.warningAccent.withValues(alpha: 0.16),
              palette.surfaceAlt,
            ),
            Color.alphaBlend(
              palette.primary.withValues(alpha: 0.12),
              palette.surfaceAlt,
            ),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.play_rectangle,
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
