import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/utils/media_source_util.dart';

class DiscoverSourceVisual {
  DiscoverSourceVisual._();

  static Color brandOf(DiscoverSourceEntry source) {
    switch (source.localSource) {
      case DiscoverSource.tmdb:
        return const Color(0xFF01B4E4);
      case DiscoverSource.douban:
        return const Color(0xFF00B51D);
      case DiscoverSource.bangumi:
        return const Color(0xFFF09199);
      case DiscoverSource.anilist:
        return const Color(0xFF02A9FF);
      case null:
        break;
    }
    final lower = source.label.toLowerCase();
    if (lower.contains('tmdb') || lower.contains('themovie')) {
      return const Color(0xFF01B4E4);
    }
    if (lower.contains('豆瓣') || lower.contains('douban')) {
      return const Color(0xFF00B51D);
    }
    if (lower.contains('bangumi')) {
      return const Color(0xFFF09199);
    }
    if (lower.contains('anilist')) {
      return const Color(0xFF02A9FF);
    }
    return const Color(0xFF6366F1);
  }

  static Widget logoWidget(
    DiscoverSourceEntry source, {
    double size = 18,
    Color? fallbackColor,
  }) {
    switch (source.localSource) {
      case DiscoverSource.tmdb:
        return Assets.images.logos.tmdb.image(
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      case DiscoverSource.douban:
        return Assets.images.logos.douban.image(
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      case DiscoverSource.bangumi:
        return Assets.images.logos.bangumi.image(
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      case DiscoverSource.anilist:
        return Assets.images.logos.anilist.svg(
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            fallbackColor ?? const Color(0xFF02A9FF),
            BlendMode.srcIn,
          ),
        );
      case null:
        break;
    }

    final byId = MediaSourceUtil.imageForSource(
      source.id.replaceFirst('dynamic:', ''),
    );
    if (byId != null) {
      return byId.image(width: size, height: size, fit: BoxFit.contain);
    }
    final lower = source.label.toLowerCase();
    if (lower.contains('anilist')) {
      return Assets.images.logos.anilist.svg(
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          fallbackColor ?? const Color(0xFF02A9FF),
          BlendMode.srcIn,
        ),
      );
    }
    if (lower.contains('tmdb') || lower.contains('themovie')) {
      return Assets.images.logos.tmdb.image(
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    if (lower.contains('豆瓣') || lower.contains('douban')) {
      return Assets.images.logos.douban.image(
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    if (lower.contains('bangumi')) {
      return Assets.images.logos.bangumi.image(
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Icon(
      Icons.auto_awesome_rounded,
      size: size * 0.92,
      color: fallbackColor,
    );
  }
}

class DiscoverSourceChip extends StatelessWidget {
  const DiscoverSourceChip({
    super.key,
    required this.source,
    required this.selected,
    required this.onTap,
  });

  final DiscoverSourceEntry source;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = DashboardPalette.of(context);
    final brand = DiscoverSourceVisual.brandOf(source);
    final accent = Color.lerp(palette.primary, brand, 0.45) ?? palette.primary;
    final bg = selected
        ? Color.alphaBlend(
            accent.withValues(alpha: palette.isDark ? 0.28 : 0.14),
            palette.pageBackgroundAlt,
          )
        : palette.pageBackgroundAlt;

    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        button: true,
        selected: selected,
        label: '探索来源 ${source.label}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 40,
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? accent.withValues(alpha: 0.65)
                      : palette.tileBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: selected
                          ? Color.alphaBlend(
                              Colors.white.withValues(
                                alpha: palette.isDark ? 0.12 : 0.95,
                              ),
                              bg,
                            )
                          : palette.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: DiscoverSourceVisual.logoWidget(
                      source,
                      size: 16,
                      fallbackColor: selected ? accent : palette.mutedText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    source.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected ? accent : palette.titleText,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
