import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 列表底部分页「加载更多」/footer 状态展示。
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.hasMore,
    required this.onLoadMore,
    this.isLoading = false,
    this.hasItems = true,
    this.total,
    this.padding,
    this.label = '加载更多',
    this.endLabel = '没有更多了',
  });

  final bool hasMore;
  final bool isLoading;
  final bool hasItems;
  final int? total;
  final VoidCallback? onLoadMore;
  final EdgeInsetsGeometry? padding;
  final String label;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    if (!hasItems) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectivePadding =
        padding ?? const EdgeInsets.fromLTRB(0, 12, 0, 4);

    if (!hasMore) {
      return Padding(
        padding: effectivePadding,
        child: Center(
          child: Text(
            endLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
          ),
        ),
      );
    }

    final enabled = !isLoading && onLoadMore != null;
    final actionLabel = total == null ? label : '$label · 共 $total';

    return Padding(
      padding: effectivePadding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          minSize: 44,
          onPressed: enabled ? onLoadMore : null,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                CupertinoActivityIndicator(
                  radius: 9,
                  color: scheme.primary,
                )
              else
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 18,
                  color: scheme.primary.withValues(alpha: 0.92),
                ),
              const SizedBox(width: 8),
              Text(
                isLoading ? '加载中…' : actionLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: enabled ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
