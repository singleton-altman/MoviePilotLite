import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DashboardPalette {
  DashboardPalette._();

  static DashboardPaletteData of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;
    return DashboardPaletteData(
      isDark: isDark,
      primary: primary,
      warmAccent: _shift(primary, hueDelta: 24, saturationDelta: 0.03),
      coolAccent: _shift(primary, hueDelta: -24, lightnessDelta: 0.06),
      successAccent: _mix(primary, scheme.secondary, 0.55),
      warningAccent: _shift(primary, hueDelta: 42, lightnessDelta: 0.08),
      pageBackground: isDark
          ? const Color(0xFF0F1115)
          : const Color(0xFFF5F7FB),
      pageBackgroundAlt: isDark
          ? const Color(0xFF171A21)
          : const Color(0xFFFFFFFF),
      appBarBackground: isDark
          ? const Color(0xE616181D)
          : const Color(0xEAFDFEFF),
      surface: isDark ? const Color(0xE21A1D24) : const Color(0xF7FFFFFF),
      surfaceAlt: isDark ? const Color(0xFF20242D) : const Color(0xFFF0F4FA),
      tileSurface: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFF8FBFF),
      tileBorder: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : scheme.outline.withValues(alpha: 0.16),
      shadow: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
      titleText: isDark ? Colors.white : const Color(0xFF152033),
      bodyText: isDark ? Colors.white : const Color(0xFF1B2940),
      mutedText: isDark
          ? Colors.white.withValues(alpha: 0.58)
          : const Color(0xFF6C7A90),
      faintText: isDark
          ? Colors.white.withValues(alpha: 0.42)
          : const Color(0xFF8B97A9),
      inverseText: isDark ? Colors.white : const Color(0xFF101828),
      divider: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE4EAF3),
      overlay: isDark
          ? Colors.black.withValues(alpha: 0.48)
          : Colors.white.withValues(alpha: 0.45),
    );
  }

  static Color _shift(
    Color color, {
    double hueDelta = 0,
    double saturationDelta = 0,
    double lightnessDelta = 0,
  }) {
    final hsl = HSLColor.fromColor(color);
    final hue = (hsl.hue + hueDelta) % 360;
    final saturation = (hsl.saturation + saturationDelta).clamp(0.0, 1.0);
    final lightness = (hsl.lightness + lightnessDelta).clamp(0.0, 1.0);
    return hsl
        .withHue(hue < 0 ? hue + 360 : hue)
        .withSaturation(saturation)
        .withLightness(lightness)
        .toColor();
  }

  static Color _mix(Color a, Color b, double amount) {
    return Color.lerp(a, b, amount) ?? a;
  }
}

class DashboardPaletteData {
  const DashboardPaletteData({
    required this.isDark,
    required this.primary,
    required this.warmAccent,
    required this.coolAccent,
    required this.successAccent,
    required this.warningAccent,
    required this.pageBackground,
    required this.pageBackgroundAlt,
    required this.appBarBackground,
    required this.surface,
    required this.surfaceAlt,
    required this.tileSurface,
    required this.tileBorder,
    required this.shadow,
    required this.titleText,
    required this.bodyText,
    required this.mutedText,
    required this.faintText,
    required this.inverseText,
    required this.divider,
    required this.overlay,
  });

  final bool isDark;
  final Color primary;
  final Color warmAccent;
  final Color coolAccent;
  final Color successAccent;
  final Color warningAccent;
  final Color pageBackground;
  final Color pageBackgroundAlt;
  final Color appBarBackground;
  final Color surface;
  final Color surfaceAlt;
  final Color tileSurface;
  final Color tileBorder;
  final Color shadow;
  final Color titleText;
  final Color bodyText;
  final Color mutedText;
  final Color faintText;
  final Color inverseText;
  final Color divider;
  final Color overlay;
}

class DashboardStitchSection extends StatelessWidget {
  const DashboardStitchSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onTapMore,
    this.padding = const EdgeInsets.all(16),
    this.accentColor,
    this.bottomSpacing = 32,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTapMore;
  final EdgeInsets padding;
  final Color? accentColor;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final tone = accentColor ?? palette.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: palette.isDark ? 0.12 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tone.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, size: 18, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: palette.titleText,
                  ),
                ),
              ),
              if (onTapMore != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onTapMore,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '查看全部',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tone,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(CupertinoIcons.arrow_right, size: 12, color: tone),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: palette.isDark ? 18 : 12,
                sigmaY: palette.isDark ? 18 : 12,
              ),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: palette.tileBorder),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.surface,
                      Color.alphaBlend(
                        tone.withValues(alpha: palette.isDark ? 0.05 : 0.04),
                        palette.pageBackgroundAlt,
                      ),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -60,
                      right: -40,
                      child: IgnorePointer(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                tone.withValues(
                                  alpha: palette.isDark ? 0.15 : 0.10,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardMetricTile extends StatelessWidget {
  const DashboardMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.trailing,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.tileSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: palette.faintText,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              height: 0.95,
              color: palette.titleText,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: palette.mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardProgressBar extends StatelessWidget {
  const DashboardProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor,
    this.height = 5,
  });

  final double value;
  final Color color;
  final Color? backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor:
            backgroundColor ??
            palette.divider.withValues(alpha: palette.isDark ? 1 : 0.9),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class DashboardInfoPill extends StatelessWidget {
  const DashboardInfoPill({
    super.key,
    required this.text,
    this.color,
    this.backgroundColor,
    this.icon,
  });

  final String text;
  final Color? color;
  final Color? backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final tone = color ?? palette.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            tone.withValues(alpha: palette.isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: tone),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: palette.tileSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.tileBorder),
              ),
              child: Icon(icon, color: palette.mutedText),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: palette.titleText,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: palette.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DashboardMiniStat extends StatelessWidget {
  const DashboardMiniStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: palette.faintText,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor ?? palette.titleText,
          ),
        ),
      ],
    );
  }
}
