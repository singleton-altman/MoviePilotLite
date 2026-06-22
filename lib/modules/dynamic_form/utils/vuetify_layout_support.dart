import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_css.dart';

class VuetifyRenderContext {
  const VuetifyRenderContext({
    this.centerContent = false,
    this.parentColor,
    this.insideTonalCard = false,
  });

  final bool centerContent;
  final Color? parentColor;
  final bool insideTonalCard;

  VuetifyRenderContext copyWith({
    bool? centerContent,
    Color? parentColor,
    bool? insideTonalCard,
  }) {
    return VuetifyRenderContext(
      centerContent: centerContent ?? this.centerContent,
      parentColor: parentColor ?? this.parentColor,
      insideTonalCard: insideTonalCard ?? this.insideTonalCard,
    );
  }
}

class VuetifyCardSpec {
  const VuetifyCardSpec({
    required this.margin,
    required this.padding,
    required this.decoration,
    required this.childContext,
  });

  final EdgeInsets margin;
  final EdgeInsets padding;
  final BoxDecoration decoration;
  final VuetifyRenderContext childContext;
}

class VuetifyRowSpec {
  const VuetifyRowSpec({required this.margin, required this.colCount});

  final EdgeInsets margin;
  final int colCount;
}

class VuetifyColSpec {
  const VuetifyColSpec({
    required this.width,
    required this.center,
    required this.childContext,
  });

  final double? width;
  final bool center;
  final VuetifyRenderContext childContext;
}

class VuetifyDivSpec {
  const VuetifyDivSpec({
    required this.margin,
    required this.padding,
    required this.textStyle,
    required this.isCenter,
    required this.isDFlex,
    required this.mainAxis,
    required this.crossAxis,
    required this.childContext,
  });

  final EdgeInsets margin;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final bool isCenter;
  final bool isDFlex;
  final MainAxisAlignment mainAxis;
  final CrossAxisAlignment crossAxis;
  final VuetifyRenderContext childContext;
}

class VuetifyTextSpec {
  const VuetifyTextSpec({
    required this.text,
    required this.margin,
    required this.style,
  });

  final String text;
  final EdgeInsets margin;
  final TextStyle style;
}

class VuetifyHeadingSpec {
  const VuetifyHeadingSpec({required this.text, required this.fontSize});

  final String text;
  final double fontSize;
}

class VuetifyLayoutSupport {
  VuetifyLayoutSupport._();

  static const double colMinWidth = 75;
  static const double _smBreakpoint = 600;
  static const double _mdBreakpoint = 960;

  static VuetifyCardSpec resolveCardSpec(
    BuildContext context,
    FormNode node,
    VuetifyRenderContext renderContext,
  ) {
    final cls = node.props?['class']?.toString() ?? '';
    final variant = node.props?['variant']?.toString() ?? '';
    final colorName = node.props?['color']?.toString();
    final color = VuetifyCss.resolveColor(colorName);
    final elevation = _parseElevation(node.props?['elevation']);
    final margin = VuetifyCss.parseMargin(cls);
    final rawPadding = VuetifyCss.parsePadding(cls);
    final hasCardSubComponent = node.content.any(
      (child) =>
          child.component == 'VCardText' || child.component == 'VCardTitle',
    );
    final padding = rawPadding != EdgeInsets.zero
        ? rawPadding
        : hasCardSubComponent
        ? EdgeInsets.zero
        : const EdgeInsets.all(14);

    late final BoxDecoration decoration;
    var childContext = renderContext;

    if (variant == 'outlined') {
      decoration = BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.secondarySystemGroupedBackground,
          context,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.separator,
            context,
          ),
        ),
        boxShadow: _buildShadow(elevation > 0 ? elevation : 0.5, tint: color),
      );
    } else if (variant == 'tonal' && color != null) {
      decoration = BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      );
      childContext = childContext.copyWith(
        insideTonalCard: true,
        parentColor: color,
      );
    } else if (variant == 'flat') {
      decoration = BoxDecoration(
        color:
            color?.withValues(alpha: 0.10) ??
            CupertinoDynamicColor.resolve(
              CupertinoColors.secondarySystemGroupedBackground,
              context,
            ),
        borderRadius: BorderRadius.circular(14),
        border: color == null
            ? null
            : Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: _buildShadow(elevation, tint: color),
      );
    } else {
      decoration = BoxDecoration(
        color:
            color?.withValues(alpha: 0.10) ??
            CupertinoDynamicColor.resolve(
              CupertinoColors.secondarySystemGroupedBackground,
              context,
            ),
        borderRadius: BorderRadius.circular(14),
        border: color == null
            ? null
            : Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: _buildShadow(elevation > 0 ? elevation : 1, tint: color),
      );
    }

    return VuetifyCardSpec(
      margin: margin,
      padding: padding,
      decoration: decoration,
      childContext: childContext,
    );
  }

  static VuetifyRowSpec resolveRowSpec(FormNode node) {
    final cls = node.props?['class']?.toString() ?? '';
    final margin = VuetifyCss.parseMargin(cls);
    final colCount = node.content
        .where((child) => child.component == 'VCol')
        .length;
    return VuetifyRowSpec(margin: margin, colCount: colCount);
  }

  static VuetifyColSpec resolveColSpec({
    required FormNode node,
    required double? parentWidth,
    required int? siblingCount,
    required VuetifyRenderContext renderContext,
  }) {
    final cls = node.props?['class']?.toString() ?? '';
    final center = VuetifyCss.isTextCenter(cls) || renderContext.centerContent;
    final childContext = center
        ? renderContext.copyWith(centerContent: true)
        : renderContext;

    double? width;
    if (parentWidth != null) {
      final fraction = _resolveResponsiveColsFraction(node, parentWidth);
      if (fraction != null) {
        final raw = parentWidth * fraction - 8 * (1 - fraction);
        width = raw.clamp(colMinWidth, parentWidth);
      } else if (siblingCount != null && siblingCount > 1) {
        final totalSpacing = 8.0 * (siblingCount - 1);
        final raw = (parentWidth - totalSpacing) / siblingCount;
        width = raw.clamp(colMinWidth, parentWidth);
      }
    }

    return VuetifyColSpec(
      width: width,
      center: center,
      childContext: childContext,
    );
  }

  static double? _resolveResponsiveColsFraction(
    FormNode node,
    double availableWidth,
  ) {
    final props = node.props;
    if (props == null) return null;
    if (availableWidth >= _mdBreakpoint && props['md'] != null) {
      return VuetifyCss.colsFraction(props['md']);
    }
    if (availableWidth >= _smBreakpoint && props['sm'] != null) {
      return VuetifyCss.colsFraction(props['sm']);
    }
    return VuetifyCss.colsFraction(props['cols'] ?? props['sm'] ?? props['md']);
  }

  static double _parseElevation(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static List<BoxShadow>? _buildShadow(double elevation, {Color? tint}) {
    if (elevation <= 0) return null;
    final blurRadius = 4 + elevation * 2.5;
    final verticalOffset = 1 + elevation * 0.5;
    final baseColor = tint ?? Colors.black;
    final opacity = tint == null ? 0.04 + elevation * 0.01 : 0.08;
    return [
      BoxShadow(
        color: baseColor.withValues(alpha: opacity.clamp(0.04, 0.16)),
        blurRadius: blurRadius,
        offset: Offset(0, verticalOffset),
      ),
    ];
  }

  static VuetifyDivSpec resolveDivSpec(
    BuildContext context,
    FormNode node,
    VuetifyRenderContext renderContext,
  ) {
    final cls = node.props?['class']?.toString() ?? '';
    final isCenter =
        VuetifyCss.isTextCenter(cls) || renderContext.centerContent;
    final childContext = isCenter
        ? renderContext.copyWith(centerContent: true)
        : renderContext;
    return VuetifyDivSpec(
      margin: VuetifyCss.parseMargin(cls),
      padding: VuetifyCss.parsePadding(cls),
      textStyle: VuetifyCss.parseTextStyle(cls, context),
      isCenter: isCenter,
      isDFlex: VuetifyCss.isDFlex(cls),
      mainAxis: VuetifyCss.parseMainAxisAlignment(cls),
      crossAxis: VuetifyCss.parseCrossAxisAlignment(cls),
      childContext: childContext,
    );
  }

  static VuetifyTextSpec resolveSpanSpec(
    BuildContext context,
    FormNode node,
    String text,
  ) {
    final cls = node.props?['class']?.toString() ?? '';
    return VuetifyTextSpec(
      text: text,
      margin: VuetifyCss.parseMargin(cls),
      style: VuetifyCss.parseTextStyle(cls, context),
    );
  }

  static VuetifyHeadingSpec? resolveHeadingSpec(FormNode node, String text) {
    if (text.isEmpty) return null;
    final level = int.tryParse(node.component.substring(1)) ?? 2;
    final fontSize = switch (level) {
      1 => 28.0,
      2 => 22.0,
      _ => 18.0,
    };
    return VuetifyHeadingSpec(text: text, fontSize: fontSize);
  }
}
