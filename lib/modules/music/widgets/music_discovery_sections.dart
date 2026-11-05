import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_item_card.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';

class MusicFeaturedShelf extends StatelessWidget {
  const MusicFeaturedShelf({super.key, required this.items, this.onOpen});

  final List<MusicExploreItem> items;
  final ValueChanged<MusicExploreItem>? onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(340.0, (constraints.maxWidth - 56) * 0.88);
        final scaler = MediaQuery.textScalerOf(context);
        final height =
            width + 20 + scaler.scale(15) * 2 * 1.3 + scaler.scale(13) * 1.35;
        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) => MusicItemCard(
              item: items[index],
              cardWidth: width,
              onTap: onOpen == null ? null : () => onOpen!(items[index]),
            ),
          ),
        );
      },
    );
  }
}

class MusicDiscoveryRanking extends StatelessWidget {
  const MusicDiscoveryRanking({super.key, required this.items, this.onOpen});

  final List<MusicExploreItem> items;
  final ValueChanged<MusicExploreItem>? onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        final rowHeight = math.max(
          86.0,
          28 + scaler.scale(15) * 2 * 1.3 + scaler.scale(13) * 1.35,
        );
        final columnWidth = math.min(420.0, constraints.maxWidth - 52);
        final rowCount = math.min(3, items.length);
        return SizedBox(
          height: rowHeight * rowCount,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: (items.length / 3).ceil(),
            separatorBuilder: (_, _) => const SizedBox(width: 24),
            itemBuilder: (context, column) => SizedBox(
              width: columnWidth,
              child: Column(
                children: [
                  for (var row = 0; row < rowCount; row++)
                    if (column * 3 + row < items.length)
                      SizedBox(
                        height: rowHeight,
                        child: _RankedAlbum(
                          item: items[column * 3 + row],
                          number: column * 3 + row + 1,
                          onOpen: onOpen,
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RankedAlbum extends StatelessWidget {
  const _RankedAlbum({required this.item, required this.number, this.onOpen});

  final MusicExploreItem item;
  final int number;
  final ValueChanged<MusicExploreItem>? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      if (item.displayArtist.isNotEmpty) item.displayArtist,
      if (item.year != null) item.year.toString(),
    ].join(' · ');
    void open() => onOpen?.call(item);
    final content = Row(
      children: [
        MusicArtwork(imageUrl: item.coverUrl, size: 60),
        SizedBox(
          width: MediaQuery.textScalerOf(context).scale(23) + 16,
          child: Text(
            number.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: number <= 3 ? scheme.primary : scheme.onSurfaceVariant,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
    return Semantics(
      button: onOpen != null,
      onTap: onOpen == null ? null : open,
      label: '浏览序号 $number，${item.displayTitle}，$subtitle',
      child: ExcludeSemantics(
        child: onOpen == null
            ? content
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: open,
                child: content,
              ),
      ),
    );
  }
}

class MusicGenrePicker extends StatelessWidget {
  const MusicGenrePicker({
    super.key,
    required this.genres,
    required this.selected,
    required this.onSelected,
  });

  final List<String> genres;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final genre in <String?>[null, ...genres])
            Semantics(
              selected: selected == genre,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                color: selected == genre
                    ? scheme.primary.withValues(alpha: 0.1)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
                onPressed: () => onSelected(genre),
                child: Text(
                  genre ?? '全部风格',
                  style: TextStyle(
                    color: selected == genre
                        ? scheme.primary
                        : scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
