import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class RecommendItemSimpleCard extends GetView<SubscribeService> {
  const RecommendItemSimpleCard({
    super.key,
    required this.item,
    this.onTap,
    required this.themeColor,
  });

  final RecommendApiItem? item;
  final VoidCallback? onTap;
  final Color themeColor;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          _buildBackground(context),
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(child: _buildPoster(context)),
          ),

          Align(alignment: Alignment.bottomCenter, child: _buildInfo(context)),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    final imageUrl = item?.poster_path;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [themeColor.withOpacity(0.8), themeColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            themeColor.withOpacity(0.1),
            themeColor.withOpacity(0.8),
            themeColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    final imageUrl = item?.poster_path;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container();
    }
    final poster = ImageUtil.convertCacheImageUrl(imageUrl);
    return CachedImage(
      imageUrl: poster,
      fit: BoxFit.cover,
      width: 100,
      height: 100,
      borderRadius: BorderRadius.circular(25),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final data = item;
    final title = data?.title ?? data?.en_title ?? '';
    final year = data?.year ?? '';
    final rating = data?.vote_average;
    final overview = data?.overview ?? '';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (rating != null && rating > 0) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Colors.amber.shade400,
                ),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ],
          ),
          if (year.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              year,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
          if (overview.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              overview,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
