import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class DoubanListItem extends StatelessWidget {
  const DoubanListItem({
    super.key,
    this.title,
    this.content,
    required this.authorName,
    this.avatarPath,
    this.rating,
    this.createTime,
    this.usefulCount = 0,
    this.commentsCount = 0,
    this.url,
  });

  final String? title;
  final String? content;
  final String? authorName;
  final String? avatarPath;
  final double? rating;
  final String? createTime;
  final int usefulCount;
  final int commentsCount;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = url?.trim() ?? '';
    return GestureDetector(
      behavior: normalizedUrl.isEmpty
          ? HitTestBehavior.deferToChild
          : HitTestBehavior.opaque,
      onTap: normalizedUrl.isEmpty
          ? null
          : () => WebUtil.open(url: normalizedUrl),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title?.trim().isNotEmpty ?? false) ...[
              Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName ?? '豆瓣用户',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (createTime?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Text(
                          createTime!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.42),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildRating(rating),
              ],
            ),
            if (content?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text(
                content!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            if (usefulCount > 0 || commentsCount > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (usefulCount > 0)
                    _buildMeta(CupertinoIcons.hand_thumbsup, '$usefulCount 有用'),
                  if (usefulCount > 0 && commentsCount > 0)
                    const SizedBox(width: 14),
                  if (commentsCount > 0)
                    _buildMeta(CupertinoIcons.chat_bubble, '$commentsCount 回应'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final imageUrl = avatarPath == null
        ? null
        : ImageUtil.convertCacheImageUrl(avatarPath!);
    return ClipOval(
      child: SizedBox(
        width: 28,
        height: 28,
        child: imageUrl == null
            ? Container(
                color: Colors.white.withValues(alpha: 0.12),
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              )
            : CachedImage(imageUrl: imageUrl, width: 28, height: 28),
      ),
    );
  }

  Widget _buildRating(double? value) {
    final rating = value ?? 0;
    if (rating <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 5; index++)
          Icon(
            rating >= index + 1
                ? CupertinoIcons.star_fill
                : rating > index + 0.25
                ? CupertinoIcons.star_lefthalf_fill
                : CupertinoIcons.star,
            size: 9,
            color: rating > index
                ? const Color(0xFFFFD66B)
                : Colors.white.withValues(alpha: 0.24),
          ),
      ],
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.42)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
