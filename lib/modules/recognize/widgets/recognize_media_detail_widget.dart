import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/mixed_img_widget.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

import '../models/recognize_model.dart';

/// 识别结果媒体详情卡片 - 可复用于 RecognizePage 和 FileRecognizeResultSheet
class RecognizeMediaDetailWidget extends StatelessWidget {
  const RecognizeMediaDetailWidget({super.key, required this.media});

  final MediaInfo media;

  @override
  Widget build(BuildContext context) {
    final posters = _collectPosterUrls(media);
    final posterUrl =
        _resolveImageUrl(media, media.poster_path) ??
        (posters.isNotEmpty ? posters.first : null);
    final backdropUrl = _resolveImageUrl(media, media.backdrop_path);
    final title = _buildTitle(media);
    final accentColor = _accentColorForLabel(title);
    final indexAccent = _secondaryAccentColor(title);
    final subtitle = _buildSubtitle(media);
    final seasonSummary = _buildSeasonSummary(media);
    final voteText = _formatVote(media.vote_average);
    final actorsText = _buildActors(media.actors);
    final genres = _buildGenres(media.genres);
    final altNames = _buildAltNames(media.names);

    final cardColor = Theme.of(context).cardColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPosterWall(
              media,
              posters: posters,
              posterUrl: posterUrl,
              backdropUrl: backdropUrl,
              title: title,
              subtitle: subtitle,
              seasonSummary: seasonSummary,
              voteText: voteText,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionCard(
                  title: '媒体信息',
                  accentColor: accentColor,
                  children: [
                    _buildInfoRow('类型', media.type, color: accentColor),
                    _buildInfoRow('分类', media.category, color: accentColor),
                    _buildInfoRow(
                      '首播',
                      media.first_air_date,
                      color: accentColor,
                    ),
                    _buildInfoRow(
                      '完结',
                      media.last_air_date,
                      color: accentColor,
                    ),
                    _buildInfoRow('状态', media.status, color: accentColor),
                    if (media.overview != null &&
                        media.overview!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildOverviewBox(media.overview!, accentColor),
                    ],
                    if (genres.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildChipGroup('题材', genres, accentColor),
                    ],
                    if (actorsText != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow('主演', actorsText, color: accentColor),
                    ],
                    if (altNames.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildChipGroup('别名', altNames, accentColor),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  title: '索引信息',
                  accentColor: indexAccent,
                  children: [
                    _buildInfoRow('来源', media.source, color: indexAccent),
                    _buildInfoRow(
                      'TMDB',
                      media.tmdb_id?.toString(),
                      color: indexAccent,
                    ),
                    _buildInfoRow('IMDB', media.imdb_id, color: indexAccent),
                    _buildInfoRow(
                      'TVDB',
                      media.tvdb_id?.toString(),
                      color: indexAccent,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterWall(
    MediaInfo media, {
    required List<String> posters,
    required String? posterUrl,
    required String? backdropUrl,
    required String title,
    required String? subtitle,
    required String? seasonSummary,
    required String? voteText,
  }) {
    const wallHeight = 240.0;
    final heroPoster = posterUrl ?? (posters.isNotEmpty ? posters.first : null);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          SizedBox(
            height: wallHeight,
            child: posters.isNotEmpty
                ? _buildPosterGrid(posters)
                : _buildBackdropFallback(backdropUrl),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildHeroPoster(heroPoster),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeroText(
                      media,
                      title: title,
                      subtitle: subtitle,
                      seasonSummary: seasonSummary,
                      voteText: voteText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (voteText != null)
            Positioned(top: 12, right: 12, child: _buildRatingChip(voteText)),
        ],
      ),
    );
  }

  Widget _buildPosterGrid(List<String> posters) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = max(2, (constraints.maxWidth / 90).floor());
        final targetCount = columns * 3;
        final items = posters.length >= targetCount
            ? posters.take(targetCount).toList()
            : List<String>.generate(
                targetCount,
                (index) => posters[index % posters.length],
              );

        return MixedImgWidget(imageUrls: items);
      },
    );
  }

  Widget _buildBackdropFallback(String? backdropUrl) {
    if (backdropUrl == null) {
      return Container(color: CupertinoColors.systemGrey5);
    }
    return CachedImage(imageUrl: backdropUrl, fit: BoxFit.cover);
  }

  Widget _buildHeroPoster(String? posterUrl) {
    if (posterUrl == null) {
      return Container(
        width: 96,
        height: 140,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          CupertinoIcons.film,
          color: CupertinoColors.systemGrey,
          size: 32,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedImage(
        imageUrl: posterUrl,
        width: 96,
        height: 140,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildHeroText(
    MediaInfo media, {
    required String title,
    required String? subtitle,
    required String? seasonSummary,
    required String? voteText,
  }) {
    final labelColor = CupertinoColors.white.withValues(alpha: 0.9);
    final valueColor = CupertinoColors.white;
    final tmdbUrl = _buildTmdbUrl(media);
    const shadow = [
      Shadow(color: Color(0xBF000000), blurRadius: 8, offset: Offset(0, 2)),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.white,
          ).copyWith(shadows: shadow),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
            ).copyWith(shadows: shadow),
          ),
        ],
        if (seasonSummary != null) ...[
          const SizedBox(height: 4),
          Text(
            seasonSummary,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
            ).copyWith(shadows: shadow),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            if (media.type != null && media.type!.trim().isNotEmpty)
              _buildBadge(media.type!, valueColor),
            if (media.category != null &&
                media.category!.trim().isNotEmpty) ...[
              const SizedBox(width: 12),
              _buildBadge(media.category!, valueColor),
            ],
            if (tmdbUrl != null) ...[
              const Spacer(),
              IconButton.filled(
                icon: const Icon(
                  CupertinoIcons.link,
                  size: 16,
                  color: CupertinoColors.activeBlue,
                ),
                onPressed: () => WebUtil.open(url: tmdbUrl),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  Widget _buildRatingChip(String score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C518),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            score,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {Color? color}) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final dotColor = color ?? _accentColorForLabel(label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 6),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildChipGroup(String label, List<String> items, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: accentColor.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .asMap()
              .entries
              .map(
                (entry) => _buildChip(
                  entry.value,
                  _accentPalette[entry.key % _accentPalette.length],
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildChip(String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: accentColor)),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAccentHeader(title, accentColor),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAccentHeader(String title, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildOverviewBox(String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
    );
  }

  static String _buildTitle(MediaInfo media) {
    final name = media.title?.trim();
    final fallback = media.original_title?.trim();
    final year = media.year?.trim();
    if (name != null && name.isNotEmpty) {
      return year == null || year.isEmpty ? name : '$name ($year)';
    }
    if (fallback != null && fallback.isNotEmpty) {
      return year == null || year.isEmpty ? fallback : '$fallback ($year)';
    }
    return year == null || year.isEmpty ? '未知标题' : '未知标题 ($year)';
  }

  static String? _buildSubtitle(MediaInfo media) {
    final en = media.en_title?.trim();
    final original = media.original_title?.trim();
    final titleYear = media.title_year?.trim();
    final parts = <String>[];
    if (en != null && en.isNotEmpty) parts.add(en);
    if (original != null && original.isNotEmpty && original != en) {
      parts.add(original);
    }
    if (titleYear != null && titleYear.isNotEmpty) parts.add(titleYear);
    if (parts.isEmpty) return null;
    return parts.join(' / ');
  }

  static String? _buildSeasonSummary(MediaInfo media) {
    final seasons = media.number_of_seasons;
    final episodes = media.number_of_episodes;
    if (seasons == null && episodes == null) return null;
    final parts = <String>[];
    if (seasons != null) parts.add('$seasons季');
    if (episodes != null) parts.add('$episodes集');
    return parts.join(' · ');
  }

  static String? _formatVote(double? value) {
    if (value == null) return null;
    return value.toStringAsFixed(1);
  }

  static String? _buildActors(List<Actor>? actors) {
    if (actors == null || actors.isEmpty) return null;
    final names = actors
        .map((actor) => actor.name?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) return null;
    return names.take(6).join(' / ');
  }

  static List<String> _buildGenres(List<Genre>? genres) {
    if (genres == null || genres.isEmpty) return const [];
    return genres
        .map((genre) => genre.name?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static List<String> _buildAltNames(List<String>? names) {
    if (names == null || names.isEmpty) return const [];
    return names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static String? _resolveImageUrl(MediaInfo media, String? path) {
    if (path == null) return null;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;
    if (media.source == 'themoviedb' && trimmed.startsWith('/')) {
      return 'https://image.tmdb.org/t/p/original$trimmed';
    }
    return trimmed;
  }

  static String? _buildTmdbUrl(MediaInfo media) {
    final detailLink = media.detail_link?.trim();
    if (detailLink != null && detailLink.isNotEmpty) {
      return detailLink;
    }
    final id = media.tmdb_id;
    if (id == null) return null;
    final type = _tmdbTypeFromMedia(media);
    return 'https://www.themoviedb.org/$type/$id';
  }

  static String _tmdbTypeFromMedia(MediaInfo media) {
    final raw = (media.type ?? '').toLowerCase();
    if (raw.contains('tv') ||
        raw.contains('电视剧') ||
        raw.contains('剧集') ||
        raw.contains('series')) {
      return 'tv';
    }
    return 'movie';
  }

  Color _accentColorForLabel(String label) {
    if (label.isEmpty) return _accentPalette.first;
    final hash = label.codeUnits.fold<int>(0, (p, c) => p + c);
    return _accentPalette[hash % _accentPalette.length];
  }

  Color _secondaryAccentColor(String seed) {
    if (seed.isEmpty) return _accentPalette.last;
    final hash = seed.codeUnits.fold<int>(0, (p, c) => p + c);
    final base = hash % _accentPalette.length;
    return _accentPalette[(base + 2) % _accentPalette.length];
  }

  static const List<Color> _accentPalette = [
    Color(0xFFF5C518),
    Color(0xFF60A5FA),
    Color(0xFF34D399),
    Color(0xFFF97316),
    Color(0xFFA78BFA),
    Color(0xFFEC4899),
  ];

  static List<String> _collectPosterUrls(MediaInfo media) {
    final urls = <String>[];
    final poster = _resolveImageUrl(media, media.poster_path);
    if (poster != null) urls.add(poster);
    final seasonPosters =
        media.season_info
            ?.map((season) => _resolveImageUrl(media, season.poster_path))
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        [];
    urls.addAll(seasonPosters);

    final unique = <String>{};
    final result = <String>[];
    for (final url in urls) {
      if (unique.add(url)) {
        result.add(url);
      }
    }
    return result;
  }
}
