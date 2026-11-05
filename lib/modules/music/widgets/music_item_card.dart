import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/music/widgets/music_ui.dart';

class MusicItemCard extends StatelessWidget {
  const MusicItemCard({
    super.key,
    required this.item,
    required this.cardWidth,
    this.onTap,
  });

  final MusicExploreItem item;
  final double cardWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      if (item.isArtist) '艺人',
      if (!item.isArtist && item.displayArtist.isNotEmpty) item.displayArtist,
      if (item.year != null) item.year.toString(),
    ].join(' · ');
    final content = SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MusicArtwork(imageUrl: item.coverUrl, isArtist: item.isArtist),
          const SizedBox(height: 10),
          Text(
            item.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      onTap: onTap,
      label: [item.displayTitle, subtitle].where((e) => e.isNotEmpty).join('，'),
      child: ExcludeSemantics(
        child: onTap == null
            ? content
            : CupertinoButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.topLeft,
                onPressed: onTap,
                child: content,
              ),
      ),
    );
  }
}
