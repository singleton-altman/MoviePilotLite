import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/media_source_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

class RecommendIosBannerCard extends StatelessWidget {
  const RecommendIosBannerCard({
    super.key,
    required this.item,
    this.onTap,
    this.themeColor,
  });

  final RecommendApiItem item;
  final VoidCallback? onTap;
  final Color? themeColor;

  static const double _stripHeight = 200;

  @override
  Widget build(BuildContext context) {
    final posterUrl = item.poster_path ?? item.backdrop_path;

    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackdrop(posterUrl ?? ''),
          _buildMask(context),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _stripHeight,
            child: _buildInfo(
              context,
              title: item.title ?? item.en_title ?? '',
              year: item.year,
              source: item.source,
              overview: item.overview,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop(String backdropUrl) {
    final overlay = themeColor ?? Colors.white;
    return SoftEdgeBlur(
      edges: [
        EdgeBlur(
          type: EdgeType.bottomEdge,
          size: 200,
          sigma: 30,
          controlPoints: [
            ControlPoint(position: 0.5, type: ControlPointType.visible),
            ControlPoint(position: 0.8, type: ControlPointType.visible),
            ControlPoint(position: 1, type: ControlPointType.transparent),
          ],
        ),
      ],
      child: backdropUrl.isNotEmpty
          ? CachedImage(
              imageUrl: ImageUtil.convertCacheImageUrl(backdropUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [overlay, overlay.withValues(alpha: 0.85)],
                ),
              ),
            ),
    );
  }

  Widget _buildInfo(
    BuildContext context, {
    String? year,
    String? source,
    required String title,
    String? overview,
    VoidCallback? onTap,
  }) {
    final sourceImage = source != null && source.isNotEmpty
        ? MediaSourceUtil.imageForSource(source)
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (year != null && year.isNotEmpty) ...[
            Text(
              year,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (sourceImage != null) ...[
                Image(
                  image: sourceImage.provider(),
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ],
              SizedBox(width: 12),

              Text(
                item.title ?? item.en_title ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (item.overview != null && item.overview!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.overview!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            height: 40,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: CupertinoColors.inactiveGray
                    .resolveFrom(context)
                    .withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 34),
              ),
              child: const Text(
                '查看',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMask(BuildContext context) {
    final colors = themeColor ?? Colors.white;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            colors.withValues(alpha: 0.2),
            colors.withValues(alpha: 0.5),
            colors.withValues(alpha: 1),
          ],
        ),
      ),
    );
  }
}
