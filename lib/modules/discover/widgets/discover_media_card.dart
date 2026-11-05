import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_base_card.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class DiscoverMediaCard extends StatelessWidget {
  const DiscoverMediaCard({
    super.key,
    required this.item,
    required this.onTap,
    this.cardAspectRatio = 0.62,
    this.previewMinWidth = 160,
    this.previewMaxWidth = 240,
    this.visualVariant = 0,
  });

  final RecommendApiItem item;
  final VoidCallback onTap;
  final double cardAspectRatio;
  final double previewMinWidth;
  final double previewMaxWidth;
  final int visualVariant;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl(item);
    final title = _bestTitle(item) ?? 'Untitled';
    final vote = item.vote_average;
    final year = item.year?.trim() ?? item.title_year?.trim() ?? '';

    return RecommendItemBaseCard(
      item: item,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasTightWidth
              ? constraints.maxWidth
              : constraints.maxWidth
                    .clamp(previewMinWidth, previewMaxWidth)
                    .toDouble();
          final height = constraints.hasTightHeight
              ? constraints.maxHeight
              : width / cardAspectRatio;
          return SizedBox(
            width: width,
            height: height,
            child: GestureDetector(
              onTap: onTap,
              child: DiscoverCardSurface(
                imageUrl: imageUrl,
                title: title,
                vote: vote,
                year: year,
                type: item.type,
                visualVariant: visualVariant,
              ),
            ),
          );
        },
      ),
    );
  }

  String _imageUrl(RecommendApiItem item) {
    final raw = item.poster_path ?? item.backdrop_path ?? '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return ImageUtil.convertCacheImageUrl(trimmed);
  }

  String? _bestTitle(RecommendApiItem item) {
    final title = item.title;
    if (title != null && title.trim().isNotEmpty) return title.trim();
    final enTitle = item.en_title;
    if (enTitle != null && enTitle.trim().isNotEmpty) return enTitle.trim();
    final original = item.original_title ?? item.original_name;
    if (original != null && original.trim().isNotEmpty) return original.trim();
    return null;
  }
}

class DiscoverCardSurface extends StatelessWidget {
  const DiscoverCardSurface({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.vote,
    required this.year,
    required this.type,
    this.surfaceColor,
    this.ratingColor,
    this.visualVariant = 0,
  });

  final String imageUrl;
  final String title;
  final double? vote;
  final String year;
  final String? type;
  final Color? surfaceColor;
  final Color? ratingColor;
  final int visualVariant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final variant = visualVariant % 3;
    final effectiveRatingColor =
        ratingColor ??
        (variant == 1 ? colorScheme.primary : colorScheme.secondary);
    final borderColor = variant == 2
        ? colorScheme.primary.withValues(alpha: 0.62)
        : colorScheme.outlineVariant.withValues(alpha: 0.7);
    final shadowColor = variant == 1
        ? colorScheme.primary.withValues(alpha: isDark ? 0.24 : 0.16)
        : Colors.black.withValues(alpha: isDark ? 0.32 : 0.12);
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: variant == 1 ? 24 : 18,
            offset: Offset(0, variant == 1 ? 12 : 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            CachedImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: const _PosterPlaceholder(),
              errorWidget: const _PosterPlaceholder(),
            )
          else
            const _PosterPlaceholder(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x33000000),
                  Color(0xEA000000),
                ],
                stops: [0.42, 0.68, 1],
              ),
            ),
          ),
          if (variant == 1)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
              ),
            ),
          if (variant == 2 && (type ?? '').trim().isNotEmpty)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  type!.trim(),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (vote != null && vote! > 0)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: effectiveRatingColor.withValues(alpha: 0.38),
                  ),
                ),
                child: Text(
                  '★ ${vote!.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: effectiveRatingColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.12,
                  ),
                ),
                if (year.isNotEmpty || (type ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (year.isNotEmpty) year,
                      if ((type ?? '').isNotEmpty) type,
                    ].whereType<String>().join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.42),
          size: 34,
        ),
      ),
    );
  }
}
