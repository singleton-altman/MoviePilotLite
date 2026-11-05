import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_history_controller.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class SubscribeHistoryItemCard extends StatelessWidget {
  const SubscribeHistoryItemCard({
    super.key,
    required this.entry,
    required this.isTv,
    this.onTap,
    this.onResubscribe,
    this.onDelete,
  });

  final SubscribeHistoryEntry entry;
  final bool isTv;
  final VoidCallback? onTap;
  final VoidCallback? onResubscribe;
  final VoidCallback? onDelete;

  static const double _radius = 12;
  static const double _posterW = 56;
  static const double _posterH = 84;
  static const double _cardHeight = _posterH + 20;

  @override
  Widget build(BuildContext context) {
    final card = _buildRow(context);
    return CupertinoContextMenu.builder(
      enableHapticFeedback: true,
      actions: [
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.arrow_clockwise,
          onPressed: () {
            Navigator.of(context).pop();
            onResubscribe?.call();
          },
          child: const Text('重新订阅'),
        ),
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          trailingIcon: CupertinoIcons.delete,
          onPressed: () {
            Navigator.of(context).pop();
            onDelete?.call();
          },
          child: const Text('删除'),
        ),
      ],
      builder: (context, animation) {
        final maxWidth = MediaQuery.sizeOf(context).width - 32;
        return SizedBox(
          width: maxWidth,
          height: _cardHeight,
          child: card,
        );
      },
    );
  }

  Widget _buildRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: onTap,
        child: Container(
          height: _cardHeight,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: _posterW,
                  height: _posterH,
                  child: _buildPoster(scheme),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                    if (_meta.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.48),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(ColorScheme scheme) {
    final url = entry.item.poster;
    if (url != null && url.isNotEmpty) {
      return CachedImage(
        imageUrl: ImageUtil.convertCacheImageUrl(url),
        fit: BoxFit.cover,
        width: _posterW,
        height: _posterH,
      );
    }
    return ColoredBox(color: scheme.surfaceContainerHighest);
  }

  String get _title {
    final name = entry.item.name?.trim() ?? '未知';
    final season = entry.item.season;
    if (isTv && season != null && season > 0) {
      return '$name S$season';
    }
    return name;
  }

  String get _subtitle {
    final parts = <String>[];
    final year = entry.item.year?.trim();
    if (year != null && year.isNotEmpty) parts.add(year);
    final vote = entry.item.vote;
    if (vote != null && vote > 0) {
      parts.add('★ ${vote.toStringAsFixed(1)}');
    }
    final completed = entry.completedEpisode;
    if (isTv && completed != null && completed > 0) {
      parts.add('完成 $completed 集');
    }
    return parts.isEmpty ? '历史订阅' : parts.join(' · ');
  }

  String get _meta {
    final date = entry.item.date;
    if (date == null || date.isEmpty) return '';
    return SubscribeController.formatRelativeTime(date);
  }
}
