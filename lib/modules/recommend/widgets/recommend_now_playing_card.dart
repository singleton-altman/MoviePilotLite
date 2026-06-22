import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_base_card.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class RecommendNowPlayingCard extends StatelessWidget {
  const RecommendNowPlayingCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final RecommendApiItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (item.title ?? item.en_title ?? '').trim();
    final rating = item.vote_average ?? 0;

    return RecommendItemBaseCard(
      item: item,
      child: Semantics(
        button: true,
        label: [
          title,
          if (rating > 0) '评分 ${rating.toStringAsFixed(1)}',
        ].join('，'),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 116,
              decoration: BoxDecoration(
                color: const Color(0xFF10211F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: const Color(0xFF0B1716),
                      child: _buildPoster(),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.52, 1],
                          colors: [Colors.transparent, Color(0xE6000000)],
                        ),
                      ),
                    ),
                    if (rating > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: _Badge(
                          icon: Icons.star_rounded,
                          label: rating.toStringAsFixed(1),
                          iconColor: Color(0xFFFFC857),
                        ),
                      ),
                    Positioned(
                      left: 9,
                      right: 9,
                      bottom: 9,
                      child: Text(
                        title.isEmpty ? '未命名影片' : title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final path = item.poster_path?.trim() ?? '';
    if (path.isEmpty) {
      return const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: Colors.white38,
          size: 30,
        ),
      );
    }
    return CachedImage(
      imageUrl: ImageUtil.convertCacheImageUrl(path),
      fit: BoxFit.contain,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
