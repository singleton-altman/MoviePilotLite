import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 订阅分享项卡片：与订阅页 SubscribeItemCard 同 list 风格（固定高度 180、backdrop、海报、标题、分享信息）
class SubscribeShareItemCard extends StatelessWidget {
  const SubscribeShareItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onMoreTap,
    this.isFollowed = false,
    this.onFollowTap,
  });

  final SubscribeShareItem item;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool isFollowed;
  final VoidCallback? onFollowTap;

  static const double _cardRadius = 12;
  static const double _posterWidth = 80;
  static const double _posterHeight = 120;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackdrop(),
              Positioned.fill(child: _buildGradientOverlay()),
              Positioned(
                left: 12,
                top: 12,
                right: 12,
                child: _buildContent(context),
              ),
              Positioned(bottom: 20, left: 12, child: _buildShareInfo()),
              Positioned(bottom: 20, right: 12, child: _buildDate()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackdrop() {
    var url = item.backdrop;
    if (url == null || url.isEmpty) url = item.poster;
    if (url != null && url.isNotEmpty) {
      url = ImageUtil.convertCacheImageUrl(url);
      return CachedImage(imageUrl: url, fit: BoxFit.cover);
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF5C6BC0), const Color(0xFF3949AB)],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.75),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPosterThumb(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (item.year != null && item.year!.isNotEmpty)
                Text(
                  item.year!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                _displayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.shareComment ?? '',
                style: TextStyle(fontSize: 12, color: Colors.white),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.shareUser != null && item.shareUser!.isNotEmpty) ...[
          Icon(
            CupertinoIcons.person_solid,
            size: 14,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 4),
          Text(
            item.shareUser!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (onFollowTap != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onFollowTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFollowed
                          ? CupertinoIcons.person_badge_plus_fill
                          : CupertinoIcons.person_badge_plus,
                      size: 15,
                      color: isFollowed
                          ? const Color(0xFF30D158)
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      isFollowed ? '已关注' : '关注',
                      style: TextStyle(
                        fontSize: 11,
                        color: isFollowed
                            ? const Color(0xFF30D158)
                            : Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
        ],
        if (item.count != null && item.count! > 0) ...[
          Icon(
            CupertinoIcons.flame_fill,
            size: 14,
            color: const Color(0xFFFF9F0A),
          ),
          const SizedBox(width: 4),
          Text(
            item.count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDate() {
    return Text(
      SubscribeController.formatRelativeTime(item.date),
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildPosterThumb() {
    var url = item.poster;
    if (url != null && url.isNotEmpty) {
      url = ImageUtil.convertCacheImageUrl(url);
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: _posterWidth,
          height: _posterHeight,
        ),
      );
    }
    return Container(
      width: _posterWidth,
      height: _posterHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }

  /// 优先使用 share_title（API 返回的带季信息标题），否则 name + season
  String get _displayTitle {
    if (item.shareTitle != null && item.shareTitle!.trim().isNotEmpty) {
      return item.shareTitle!.trim();
    }
    final name = item.name ?? '未知';
    if (item.season != null && item.season! > 0) {
      return '$name S${item.season.toString().padLeft(2, '0')}';
    }
    return name;
  }
}
