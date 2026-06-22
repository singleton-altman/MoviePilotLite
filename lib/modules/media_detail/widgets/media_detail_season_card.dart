import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart'
    show SeasonInfo;
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

class MediaDetailSeasonCard extends StatelessWidget {
  const MediaDetailSeasonCard({
    super.key,
    required this.season,
    required this.isSubscribed,
    required this.isMissing,
    required this.posterUrl,
    required this.seasonTitle,
    required this.seasonYear,
    required this.seasonEpisodeCount,
    required this.seasonVoteAverage,
    required this.seasonName,
    this.compact = false,
  });
  final SeasonInfo season;
  final bool isSubscribed;
  final bool isMissing;
  final String posterUrl;
  final String seasonTitle;
  final String seasonYear;
  final String seasonEpisodeCount;
  final String seasonVoteAverage;
  final String seasonName;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsedVote = double.tryParse(seasonVoteAverage);
    final voteText = parsedVote != null && parsedVote > 0
        ? parsedVote.toStringAsFixed(1)
        : (season.vote_average != null && season.vote_average! > 0
              ? season.vote_average!.toStringAsFixed(1)
              : null);
    final airDate = (season.air_date == null || season.air_date!.isEmpty)
        ? '未定档'
        : season.air_date!;
    final episodeText = seasonEpisodeCount.isEmpty
        ? ''
        : (seasonEpisodeCount.contains('集')
              ? seasonEpisodeCount
              : '$seasonEpisodeCount 集');

    if (compact) {
      final titleText = seasonTitle.isNotEmpty ? seasonTitle : seasonName;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedImage(
                    imageUrl: posterUrl,
                    fit: BoxFit.cover,
                    width: 52,
                    height: 72,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (voteText != null) ...[
                          _compactRatingBadge(theme, voteText),
                          const SizedBox(width: 8),
                          ],
                        Expanded(
                          child: Text(
                            titleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _pill(
                            airDate,
                            background: Colors.white.withOpacity(0.18),
                          ),
                          if (episodeText.isNotEmpty)
                            _pill(
                              episodeText,
                              background: Colors.white.withOpacity(0.18),
                            ),
                          _pill(
                            isSubscribed ? '已订阅' : '未订阅',
                            background: isSubscribed
                                ? CupertinoColors.systemRed.withOpacity(0.95)
                                : Colors.blueGrey.withOpacity(0.8),
                          ),
                          if (isMissing)
                            _pill(
                              '缺失',
                              background:
                                  theme.colorScheme.error.withOpacity(0.95),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        children: [
          SoftEdgeBlur(
            edges: [
              EdgeBlur(
                type: EdgeType.bottomEdge,
                size: 100,
                sigma: 10,
                controlPoints: [
                  ControlPoint(position: 0.5, type: ControlPointType.visible),
                  ControlPoint(position: 0.8, type: ControlPointType.visible),
                  ControlPoint(position: 1, type: ControlPointType.transparent),
                ],
              ),
            ],
            child: CachedImage(
              imageUrl: posterUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: voteText != null
                ? _pill(
                    '⭐ $voteText',
                    background: const Color(0xFF7C4DFF).withOpacity(0.9),
                  )
                : SizedBox.shrink(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 36, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.2, 0.45, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        seasonTitle.isNotEmpty ? seasonTitle : seasonName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      if (episodeText.isNotEmpty)
                        _pill(
                          episodeText,
                          background: Colors.white.withOpacity(0.18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _pill(
                        airDate,
                        background: Colors.white.withOpacity(0.18),
                      ),
                      _pill(
                        isSubscribed ? '已订阅' : '未订阅',
                        background: isSubscribed
                            ? CupertinoColors.systemRed.withOpacity(0.95)
                            : Colors.blueGrey.withOpacity(0.8),
                      ),
                      if (isMissing)
                        _pill(
                          '缺失',
                          background: theme.colorScheme.error.withOpacity(0.95),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, {required Color background}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactRatingBadge(ThemeData theme, String voteText) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: const Color(0xFF7C4DFF).withOpacity(0.18),
          border: Border.all(
            color: const Color(0xFF7C4DFF).withOpacity(0.28),
            width: 0.8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.star_fill,
                size: 12,
                color: const Color(0xFFBFA8FF),
              ),
              const SizedBox(width: 4),
              Text(
                voteText,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.0,
                  color: const Color(0xFFDED2FF),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
