import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_base_card.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class RecommendItemCard extends GetView<SubscribeService> {
  const RecommendItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.compact = false,
    this.cardRadius = 10,
    this.cardWidth = 150,
    this.cardHeight,
    this.inLibrary = false,
  }) : isPlaceholder = false;

  const RecommendItemCard.placeholder({
    super.key,
    this.compact = false,
    this.cardRadius = 10,
    this.cardWidth = 150,
    this.cardHeight,
  }) : item = null,
       isPlaceholder = true,
       onTap = null,
       inLibrary = false;

  final bool compact;
  final double cardRadius;
  final RecommendApiItem? item;
  final bool isPlaceholder;
  final VoidCallback? onTap;
  final double cardWidth;
  final double? cardHeight;
  final bool inLibrary;

  static const double _defaultAspectRatio = 200 / 150;

  @override
  Widget build(BuildContext context) {
    if (isPlaceholder || item == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final size = _resolveSize(constraints);
          return _buildPlaceholder(size.width, size.height);
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _resolveSize(constraints);
        return RecommendItemBaseCard(
          item: item,
          child: GestureDetector(
            onTap: onTap,
            child: _buildContent(size.width, size.height),
          ),
        );
      },
    );
  }

  Size _resolveSize(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : cardWidth;
    final width = maxWidth;
    final height = cardHeight ?? width * _defaultAspectRatio;
    return Size(width, height);
  }

  Widget _buildContent(double width, double height) {
    final data = item;
    if (compact) {
      return _buildCompactContent(width, height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          _buildPoster(data, width, height),
          if (data?.type != null && data!.type!.isNotEmpty)
            Positioned(left: 10, top: 10, child: _buildPill(data.type!)),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildTitle(
              data?.title ?? '',
              year: _displayYear(data),
              overview: data?.overview ?? '',
              inLibrary: inLibrary,
            ),
          ),
          if (data?.vote_average != null && data!.vote_average! > 0)
            Positioned(
              right: 10,
              top: 10,
              child: _buildPill(
                data.vote_average?.toStringAsFixed(1) ?? '',
                background: const Color(0xFF7C4DFF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactContent(double width, double height) {
    return _buildPoster(item, width, height);
  }

  String _displayYear(RecommendApiItem? data) {
    final year = data?.year?.trim() ?? '';
    if (year.isNotEmpty) return year;
    final titleYear = data?.title_year?.trim() ?? '';
    return titleYear;
  }

  Widget _buildTitle(
    String title, {
    String? year,
    String? overview,
    bool inLibrary = false,
  }) {
    return Container(
      // height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(cardRadius),
          bottomRight: Radius.circular(cardRadius),
        ),
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.5), Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (inLibrary) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Color(0xFF81C784),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if ((year ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              year!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.82),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 3),
          Text(
            overview?.trim() ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3),
        ],
      ),
    );
  }

  Widget _buildPoster(RecommendApiItem? data, double width, double height) {
    var imageUrl = data?.poster_path;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageUrl = ImageUtil.convertCacheImageUrl(imageUrl);
      return CachedImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(cardRadius),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9FA8DA), Color(0xFF5C6BC0)],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE1E3EA),
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String text, {Color background = const Color(0xFF4C6FFF)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
