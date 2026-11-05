import 'dart:ui';

import 'package:flutter/material.dart';

class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 18,
    this.accentColor,
    this.blurSigma = 18,
    this.surfaceAlpha,
    this.borderAlpha,
    this.shadowAlpha,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? accentColor;
  final double blurSigma;
  final double? surfaceAlpha;
  final double? borderAlpha;
  final double? shadowAlpha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);
    final accent = accentColor ?? colorScheme.primary;
    final resolvedSurfaceAlpha = surfaceAlpha ?? (isDark ? 0.58 : 0.76);
    final resolvedBorderAlpha = borderAlpha ?? (isDark ? 0.20 : 0.68);
    final resolvedShadowAlpha = shadowAlpha ?? (isDark ? 0.24 : 0.10);
    final surfaceColor = isDark
        ? colorScheme.surface.withValues(alpha: resolvedSurfaceAlpha)
        : Colors.white.withValues(alpha: resolvedSurfaceAlpha);

    final content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: resolvedShadowAlpha),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.018 : 0.36),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            painter: _GlassMaterialPainter(
              radius: borderRadius,
              surfaceColor: surfaceColor,
              accentColor: accent,
              outlineColor: isDark
                  ? Colors.white.withValues(alpha: resolvedBorderAlpha)
                  : colorScheme.outlineVariant.withValues(
                      alpha: resolvedBorderAlpha,
                    ),
              isDark: isDark,
            ),
            child: Material(
              color: Colors.transparent,
              child: onTap == null
                  ? content
                  : InkWell(
                      onTap: onTap,
                      borderRadius: radius,
                      splashColor: accent.withValues(alpha: 0.10),
                      highlightColor: accent.withValues(alpha: 0.06),
                      child: content,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassMaterialPainter extends CustomPainter {
  const _GlassMaterialPainter({
    required this.radius,
    required this.surfaceColor,
    required this.accentColor,
    required this.outlineColor,
    required this.isDark,
  });

  final double radius;
  final Color surfaceColor;
  final Color accentColor;
  final Color outlineColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(bounds, Radius.circular(radius));
    final innerRRect = rrect.deflate(0.8);
    final edgeRRect = rrect.deflate(1.4);

    canvas.drawRRect(rrect, Paint()..color = surfaceColor);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = outlineColor,
    );

    canvas.drawRRect(
      innerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(alpha: isDark ? 0.10 : 0.42),
    );

    canvas.drawRRect(
      edgeRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = (isDark ? Colors.black : Colors.white).withValues(
          alpha: isDark ? 0.18 : 0.24,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassMaterialPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.isDark != isDark;
  }
}
