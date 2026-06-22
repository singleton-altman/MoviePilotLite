import 'package:flutter/cupertino.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_css.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_form_parser.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_mappings.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_text_support.dart';

class VuetifyIconSpec {
  const VuetifyIconSpec({
    required this.iconData,
    required this.color,
    required this.size,
    required this.margin,
    required this.useBadgeBackground,
  });

  final IconData? iconData;
  final Color color;
  final double size;
  final EdgeInsets margin;
  final bool useBadgeBackground;
}

class VuetifyButtonSpec {
  const VuetifyButtonSpec({
    required this.text,
    required this.variant,
    required this.color,
    this.prependIconData,
  });

  final String text;
  final String variant;
  final Color color;
  final IconData? prependIconData;
}

class VuetifyAlertDisplaySpec {
  const VuetifyAlertDisplaySpec({
    required this.type,
    required this.bodyText,
    required this.margin,
  });

  final String type;
  final String bodyText;
  final EdgeInsets margin;
}

class VuetifyAlertVisualSpec {
  const VuetifyAlertVisualSpec({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
}

class VuetifyChipSpec {
  const VuetifyChipSpec({
    required this.text,
    required this.color,
    this.iconData,
  });

  final String text;
  final Color color;
  final IconData? iconData;
}

class VuetifyImageSpec {
  const VuetifyImageSpec({
    required this.src,
    this.height,
    this.aspectRatio,
    required this.fit,
  });

  final String src;
  final double? height;
  final double? aspectRatio;
  final BoxFit fit;
}

class VuetifyTonalStatCardSpec {
  const VuetifyTonalStatCardSpec({
    required this.color,
    this.iconData,
    required this.value,
    required this.label,
  });

  final Color color;
  final IconData? iconData;
  final String value;
  final String label;
}

class VuetifyTableSpec {
  const VuetifyTableSpec({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

class VuetifyTabItemSpec {
  const VuetifyTabItemSpec({
    required this.node,
    required this.label,
    required this.isSelected,
  });

  final FormNode node;
  final String label;
  final bool isSelected;
}

class VuetifyTabsSpec {
  const VuetifyTabsSpec({required this.items, required this.grow});

  final List<VuetifyTabItemSpec> items;
  final bool grow;
}

class VuetifyDisplaySupport {
  VuetifyDisplaySupport._();

  static VuetifyIconSpec resolveIconSpec(
    BuildContext context,
    FormNode node, {
    Color? inheritedColor,
    bool insideTonalCard = false,
  }) {
    final iconName =
        node.text?.toString().trim() ??
        node.props?['icon']?.toString().trim() ??
        '';
    final iconData = VuetifyMappings.iconFromMdi(iconName);
    final colorName = node.props?['color']?.toString();
    final color =
        VuetifyCss.resolveColor(colorName) ??
        inheritedColor ??
        CupertinoDynamicColor.resolve(CupertinoColors.label, context);
    final sizeStr = node.props?['size']?.toString() ?? '';
    final size = _parseIconSize(sizeStr);
    return VuetifyIconSpec(
      iconData: iconData,
      color: color,
      size: size,
      margin: VuetifyCss.parseMargin(node.props?['class']?.toString()),
      useBadgeBackground: size >= 32 || insideTonalCard,
    );
  }

  static VuetifyButtonSpec resolveButtonSpec(
    BuildContext context,
    FormNode node,
  ) {
    final colorName = node.props?['color']?.toString();
    final color =
        VuetifyCss.resolveColor(colorName) ??
        CupertinoDynamicColor.resolve(CupertinoColors.systemBlue, context);
    final prependIcon = node.props?['prepend-icon']?.toString();
    return VuetifyButtonSpec(
      text: VuetifyTextSupport.collectVisibleText(node),
      variant: node.props?['variant']?.toString() ?? '',
      color: color,
      prependIconData: VuetifyMappings.iconFromMdi(prependIcon),
    );
  }

  static VuetifyAlertDisplaySpec? resolveAlertDisplaySpec(FormNode node) {
    final alert = VuetifyFormParser.parseAlert(node);
    final bodyText = alert?.text ?? VuetifyTextSupport.collectVisibleText(node);
    if (bodyText.isEmpty) return null;
    return VuetifyAlertDisplaySpec(
      type: alert?.type.toLowerCase() ?? 'info',
      bodyText: bodyText,
      margin: VuetifyCss.parseMargin(node.props?['class']?.toString()),
    );
  }

  static VuetifyAlertVisualSpec resolveAlertVisual(String type) {
    return switch (type.toLowerCase()) {
      'success' => VuetifyAlertVisualSpec(
        backgroundColor: const Color(0xFF34C759).withValues(alpha: 0.12),
        foregroundColor: const Color(0xFF34C759),
        icon: CupertinoIcons.checkmark_circle_fill,
      ),
      'warning' => VuetifyAlertVisualSpec(
        backgroundColor: const Color(0xFFFF9500).withValues(alpha: 0.12),
        foregroundColor: const Color(0xFFFF9500),
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      ),
      'error' => VuetifyAlertVisualSpec(
        backgroundColor: const Color(0xFFFF3B30).withValues(alpha: 0.12),
        foregroundColor: const Color(0xFFFF3B30),
        icon: CupertinoIcons.exclamationmark_circle_fill,
      ),
      _ => VuetifyAlertVisualSpec(
        backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.12),
        foregroundColor: const Color(0xFF007AFF),
        icon: CupertinoIcons.info_circle_fill,
      ),
    };
  }

  static VuetifyChipSpec resolveChipSpec(FormNode node) {
    final colorName = node.props?['color']?.toString();
    final color = VuetifyCss.resolveColor(colorName) ?? const Color(0xFF007AFF);

    IconData? iconData;
    final textParts = <String>[];
    for (final child in node.content) {
      if (child.component == 'VIcon') {
        final name =
            child.text?.toString().trim() ??
            child.props?['icon']?.toString().trim();
        iconData ??= VuetifyMappings.iconFromMdi(name);
      } else {
        final text = VuetifyTextSupport.collectVisibleText(child).trim();
        if (text.isNotEmpty) {
          textParts.add(text);
        }
      }
    }
    if (textParts.isEmpty && node.text != null) {
      textParts.add(node.text.toString().trim());
    }
    return VuetifyChipSpec(
      text: textParts.join(' '),
      color: color,
      iconData: iconData,
    );
  }

  static VuetifyImageSpec? resolveImageSpec(FormNode node) {
    final src = node.props?['src']?.toString() ?? '';
    if (src.isEmpty) return null;
    final height = double.tryParse(node.props?['height']?.toString() ?? '');
    final aspectRatio = _parseAspectRatio(node.props?['aspect-ratio']);
    final cover = VuetifyFormParser.boolFromDynamic(node.props?['cover']);
    return VuetifyImageSpec(
      src: src,
      height: height,
      aspectRatio: aspectRatio,
      fit: cover ? BoxFit.cover : BoxFit.contain,
    );
  }

  static VuetifyTonalStatCardSpec? resolveTonalStatCardSpec(
    FormNode node,
    Color color,
  ) {
    if (node.content.isEmpty) return null;
    final cardText = node.content.firstWhere(
      (child) => child.component == 'VCardText',
      orElse: () => const FormNode(),
    );
    if (cardText.component.isEmpty) return null;

    FormNode? iconNode;
    FormNode? valueNode;
    FormNode? labelNode;

    for (final child in cardText.content) {
      if (child.component == 'VIcon' && iconNode == null) {
        iconNode = child;
        continue;
      }
      if (child.component != 'div') {
        continue;
      }
      final cls = child.props?['class']?.toString() ?? '';
      if (cls.contains('text-caption')) {
        labelNode ??= child;
      } else {
        valueNode ??= child;
      }
    }

    if (valueNode == null) return null;

    final iconName =
        iconNode?.text?.toString().trim() ??
        iconNode?.props?['icon']?.toString().trim();
    return VuetifyTonalStatCardSpec(
      color: color,
      iconData: VuetifyMappings.iconFromMdi(iconName),
      value: VuetifyTextSupport.collectVisibleText(valueNode),
      label: labelNode == null
          ? ''
          : VuetifyTextSupport.collectVisibleText(labelNode),
    );
  }

  static VuetifyTableSpec? resolveTableSpec(FormNode node) {
    final headers = <String>[];
    final rows = <List<String>>[];

    for (final section in node.content) {
      if (section.component == 'thead') {
        for (final tr in section.content) {
          if (tr.component == 'tr') {
            for (final th in tr.content) {
              if (th.component == 'th') {
                headers.add(VuetifyTextSupport.collectVisibleText(th));
              }
            }
          }
        }
      } else if (section.component == 'tbody') {
        for (final tr in section.content) {
          if (tr.component == 'tr') {
            final row = <String>[];
            for (final td in tr.content) {
              if (td.component == 'td') {
                row.add(VuetifyTextSupport.collectVisibleText(td));
              }
            }
            rows.add(row);
          }
        }
      }
    }

    if (headers.isEmpty && rows.isEmpty) return null;
    return VuetifyTableSpec(headers: headers, rows: rows);
  }

  static VuetifyTabsSpec? resolveTabsSpec(FormNode node) {
    final tabs = node.content
        .where((child) => child.component == 'VTab')
        .toList();
    if (tabs.isEmpty) return null;
    final selectedValue =
        node.props?['modelValue']?.toString() ??
        node.props?['value']?.toString();
    final items = tabs.map((tab) {
      final value = tab.props?['value']?.toString();
      return VuetifyTabItemSpec(
        node: tab,
        label: VuetifyTextSupport.collectVisibleText(tab),
        isSelected:
            selectedValue != null &&
            value != null &&
            value.isNotEmpty &&
            value == selectedValue,
      );
    }).toList();
    return VuetifyTabsSpec(
      items: items,
      grow: VuetifyFormParser.boolFromDynamic(node.props?['grow']),
    );
  }

  static double _parseIconSize(String size) {
    final numeric = double.tryParse(size);
    if (numeric != null) return numeric;
    return switch (size) {
      'x-small' => 16,
      'small' => 20,
      'large' => 32,
      'x-large' => 40,
      _ => 24,
    };
  }

  static double? _parseAspectRatio(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    if (raw.contains('/')) {
      final parts = raw.split('/');
      if (parts.length == 2) {
        final width = double.tryParse(parts[0].trim());
        final height = double.tryParse(parts[1].trim());
        if (width != null && height != null && height > 0) {
          return width / height;
        }
      }
    }
    final numeric = double.tryParse(raw);
    if (numeric != null && numeric > 0) {
      return numeric;
    }
    return null;
  }
}
