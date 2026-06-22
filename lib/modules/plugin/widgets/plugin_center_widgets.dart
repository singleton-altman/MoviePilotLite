import 'package:flutter/material.dart';

class PluginCenterBackdrop extends StatelessWidget {
  const PluginCenterBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF111827), Color(0xFF0F172A), Color(0xFF0B1220)]
              : [
                  colorScheme.surface,
                  colorScheme.surfaceContainerLowest,
                  colorScheme.surfaceContainer,
                ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -90,
            child: _Glow(
              size: 300,
              color: colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.1),
            ),
          ),
          Positioned(
            top: 180,
            right: -140,
            child: _Glow(
              size: 340,
              color: colorScheme.tertiary.withValues(
                alpha: isDark ? 0.12 : 0.08,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PluginOverviewHeader extends StatelessWidget {
  const PluginOverviewHeader({
    super.key,
    required this.title,
    required this.count,
    this.secondaryCount,
    this.secondaryLabel,
    required this.icon,
  });

  final String title;
  final int count;
  final int? secondaryCount;
  final String? secondaryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.9 : 0.82,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.25),
                  colorScheme.tertiary.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          _MetricChip(value: '$count', label: '全部', color: colorScheme.primary),
          if (secondaryCount != null && secondaryLabel != null) ...[
            const SizedBox(width: 6),
            _MetricChip(
              value: '$secondaryCount',
              label: secondaryLabel!,
              color: colorScheme.tertiary,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
