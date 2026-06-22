import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_display_support.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/vuetify_primitives.dart';

class VuetifyIconView extends StatelessWidget {
  const VuetifyIconView({super.key, required this.spec});

  final VuetifyIconSpec spec;

  @override
  Widget build(BuildContext context) {
    if (spec.iconData == null) return const SizedBox.shrink();

    if (spec.useBadgeBackground) {
      final bgSize = spec.size + 16;
      return Padding(
        padding: spec.margin,
        child: Container(
          width: bgSize,
          height: bgSize,
          decoration: BoxDecoration(
            color: spec.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(bgSize * 0.28),
          ),
          child: Icon(spec.iconData, size: spec.size * 0.7, color: spec.color),
        ),
      );
    }

    return Padding(
      padding: spec.margin,
      child: Icon(spec.iconData, size: spec.size, color: spec.color),
    );
  }
}

class VuetifyButtonView extends StatelessWidget {
  const VuetifyButtonView({super.key, required this.spec, this.onPressed});

  final VuetifyButtonSpec spec;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (spec.variant == 'outlined') {
      return VuetifyOutlinedButton(
        text: spec.text,
        color: spec.color,
        iconData: spec.prependIconData,
        onPressed: onPressed,
      );
    }

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: spec.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spec.prependIconData != null) ...[
            Icon(spec.prependIconData, size: 18, color: spec.color),
            const SizedBox(width: 6),
          ],
          Text(
            spec.text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: spec.color,
            ),
          ),
        ],
      ),
    );
  }
}

class VuetifyAlertView extends StatelessWidget {
  const VuetifyAlertView({
    super.key,
    required this.spec,
    required this.palette,
  });

  final VuetifyAlertDisplaySpec spec;
  final VuetifyAlertVisualSpec palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: spec.margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(palette.icon, size: 20, color: palette.foregroundColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              spec.bodyText,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: palette.foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VuetifyChipView extends StatelessWidget {
  const VuetifyChipView({super.key, required this.spec});

  final VuetifyChipSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spec.iconData != null) ...[
            Icon(spec.iconData, size: 14, color: spec.color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              spec.text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: spec.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class VuetifyImageView extends StatelessWidget {
  const VuetifyImageView({super.key, required this.spec});

  final VuetifyImageSpec spec;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      spec.src,
      height: spec.height,
      fit: spec.fit,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
    if (spec.height == null && spec.aspectRatio != null) {
      image = AspectRatio(aspectRatio: spec.aspectRatio!, child: image);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(8), child: image);
  }
}

class VuetifyTableView extends StatelessWidget {
  const VuetifyTableView({super.key, required this.spec});

  final VuetifyTableSpec spec;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < spec.rows.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.tertiarySystemGroupedBackground,
                context,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < spec.rows[i].length; j++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: j < spec.rows[i].length - 1 ? 4 : 0,
                    ),
                    child: Row(
                      children: [
                        if (j < spec.headers.length)
                          Text(
                            '${spec.headers[j]}:  ',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel,
                                context,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            spec.rows[i][j],
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoDynamicColor.resolve(
                                CupertinoColors.label,
                                context,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class VuetifyTabsView extends StatelessWidget {
  const VuetifyTabsView({super.key, required this.spec, this.onTapTab});

  final VuetifyTabsSpec spec;
  final ValueChanged<FormNode>? onTapTab;

  @override
  Widget build(BuildContext context) {
    Widget buildTabRow({required bool expandTabs}) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.tertiarySystemFill,
            context,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: expandTabs ? MainAxisSize.max : MainAxisSize.min,
          children: spec.items.map((item) {
            final tab = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _VuetifyTabButton(
                label: item.label,
                selected: item.isSelected,
                onPressed: onTapTab == null ? null : () => onTapTab!(item.node),
              ),
            );
            if (!expandTabs) return tab;
            return Expanded(child: tab);
          }).toList(),
        ),
      );
    }

    if (spec.grow) {
      return buildTabRow(expandTabs: true);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: buildTabRow(expandTabs: false),
    );
  }
}

class _VuetifyTabButton extends StatelessWidget {
  const _VuetifyTabButton({
    required this.label,
    required this.selected,
    this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: Size.zero,
        borderRadius: BorderRadius.circular(10),
        color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected
                ? color
                : CupertinoDynamicColor.resolve(
                    CupertinoColors.secondaryLabel,
                    context,
                  ),
          ),
        ),
      ),
    );
  }
}
