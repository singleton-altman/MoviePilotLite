import 'package:flutter/cupertino.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_mappings.dart';

/// Vuetify CSS class 解析工具：将 Vuetify 的 class 字符串转换为 Flutter 样式值
class VuetifyCss {
  VuetifyCss._();

  static const double _unit = 4.0;

  static List<String> classTokens(String? cls) {
    if (cls == null || cls.trim().isEmpty) return const [];
    return cls
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  static bool hasClass(String? cls, String className) =>
      classTokens(cls).contains(className);

  /// 从 props['class'] 解析 EdgeInsets（margin 类：ma-/mt-/mb-/ml-/mr-/mx-/my-）
  static EdgeInsets parseMargin(String? cls) =>
      _parseSpacing(cls, _marginPrefixes);

  /// 从 props['class'] 解析 EdgeInsets（padding 类：pa-/pt-/pb-/pl-/pr-/px-/py-）
  static EdgeInsets parsePadding(String? cls) =>
      _parseSpacing(cls, _paddingPrefixes);

  static final _marginPrefixes = _SpacingPrefixes(
    'ma-',
    'mt-',
    'mb-',
    'ml-',
    'mr-',
    'mx-',
    'my-',
  );
  static final _paddingPrefixes = _SpacingPrefixes(
    'pa-',
    'pt-',
    'pb-',
    'pl-',
    'pr-',
    'px-',
    'py-',
  );

  static EdgeInsets _parseSpacing(String? cls, _SpacingPrefixes p) {
    if (cls == null || cls.isEmpty) return EdgeInsets.zero;
    double top = 0, bottom = 0, left = 0, right = 0;
    for (final token in cls.split(RegExp(r'\s+'))) {
      double? val;
      if (token.startsWith(p.all)) {
        val = _spacingValue(token, p.all.length);
        if (val != null) {
          top = val;
          bottom = val;
          left = val;
          right = val;
        }
      } else if (token.startsWith(p.top)) {
        val = _spacingValue(token, p.top.length);
        if (val != null) top = val;
      } else if (token.startsWith(p.bottom)) {
        val = _spacingValue(token, p.bottom.length);
        if (val != null) bottom = val;
      } else if (token.startsWith(p.left)) {
        val = _spacingValue(token, p.left.length);
        if (val != null) left = val;
      } else if (token.startsWith(p.right)) {
        val = _spacingValue(token, p.right.length);
        if (val != null) right = val;
      } else if (token.startsWith(p.x)) {
        val = _spacingValue(token, p.x.length);
        if (val != null) {
          left = val;
          right = val;
        }
      } else if (token.startsWith(p.y)) {
        val = _spacingValue(token, p.y.length);
        if (val != null) {
          top = val;
          bottom = val;
        }
      }
    }
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  static double? _spacingValue(String token, int prefixLen) {
    final num = int.tryParse(token.substring(prefixLen));
    return num != null ? num * _unit : null;
  }

  /// 从 class 解析 TextStyle（text-h1~h6 / text-caption / text-subtitle / font-weight-*）
  static TextStyle parseTextStyle(String? cls, BuildContext context) {
    if (cls == null || cls.isEmpty) {
      return TextStyle(
        color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
      );
    }
    final tokens = classTokens(cls);
    double? fontSize;
    FontWeight? fontWeight;

    for (final t in tokens) {
      switch (t) {
        case 'text-h1':
          fontSize = 96;
        case 'text-h2':
          fontSize = 60;
        case 'text-h3':
          fontSize = 48;
        case 'text-h4':
          fontSize = 34;
        case 'text-h5':
          fontSize = 24;
        case 'text-h6':
          fontSize = 20;
        case 'text-subtitle-1':
          fontSize = 16;
        case 'text-subtitle-2':
          fontSize = 14;
        case 'text-body-1':
          fontSize = 16;
        case 'text-body-2':
          fontSize = 14;
        case 'text-caption':
          fontSize = 12;
        case 'text-overline':
          fontSize = 10;
        case 'font-weight-bold':
          fontWeight = FontWeight.bold;
        case 'font-weight-medium':
          fontWeight = FontWeight.w500;
        case 'font-weight-regular':
          fontWeight = FontWeight.w400;
        case 'font-weight-light':
          fontWeight = FontWeight.w300;
        case 'font-weight-thin':
          fontWeight = FontWeight.w100;
      }
    }

    final explicitColor = resolveTextColorFromClasses(cls);
    Color color =
        explicitColor ??
        CupertinoDynamicColor.resolve(CupertinoColors.label, context);
    if (explicitColor == null &&
        (fontSize == 12 || tokens.contains('text-caption'))) {
      color = CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      );
    }

    return TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }

  /// 是否包含 text-center
  static bool isTextCenter(String? cls) => hasClass(cls, 'text-center');

  /// 是否 d-flex
  static bool isDFlex(String? cls) => hasClass(cls, 'd-flex');

  static bool isDashboardStats(String? cls) => hasClass(cls, 'dashboard-stats');

  static bool isDashboardStatsItem(String? cls) =>
      hasClass(cls, 'dashboard-stats__item');

  static bool isDashboardStatsTitle(String? cls) =>
      hasClass(cls, 'dashboard-stats__title');

  static bool isDashboardStatsValue(String? cls) =>
      hasClass(cls, 'dashboard-stats__value');

  static Color? resolveTextColorFromClasses(String? cls) {
    for (final token in classTokens(cls)) {
      if (token.endsWith('--text')) {
        final color = resolveColor(token.substring(0, token.length - 6));
        if (color != null) return color;
      }
      if (token == 'text-grey' || token.startsWith('text-grey-')) {
        return resolveColor(token.replaceFirst('text-', ''));
      }
      if (token.startsWith('text-')) {
        final color = resolveColor(token.substring(5));
        if (color != null) return color;
      }
    }
    return null;
  }

  /// d-flex 时的 MainAxisAlignment
  static MainAxisAlignment parseMainAxisAlignment(String? cls) {
    if (cls == null) return MainAxisAlignment.start;
    final tokens = classTokens(cls);
    if (tokens.contains('justify-center')) return MainAxisAlignment.center;
    if (tokens.contains('justify-end')) return MainAxisAlignment.end;
    if (tokens.contains('justify-space-between')) {
      return MainAxisAlignment.spaceBetween;
    }
    if (tokens.contains('justify-space-around')) {
      return MainAxisAlignment.spaceAround;
    }
    return MainAxisAlignment.start;
  }

  /// d-flex 时的 CrossAxisAlignment
  static CrossAxisAlignment parseCrossAxisAlignment(String? cls) {
    if (cls == null) return CrossAxisAlignment.start;
    final tokens = classTokens(cls);
    if (tokens.contains('align-center')) return CrossAxisAlignment.center;
    if (tokens.contains('align-end')) return CrossAxisAlignment.end;
    if (tokens.contains('align-start')) return CrossAxisAlignment.start;
    return CrossAxisAlignment.start;
  }

  /// 解析 Vuetify 颜色名（含 -lighten / -darken 后缀）
  static Color? resolveColor(String? name) {
    if (name == null || name.isEmpty) return null;
    return VuetifyMappings.colorFromVuetify(name) ?? _extendedColor(name);
  }

  static Color? _extendedColor(String name) {
    final key = name.toLowerCase().replaceAll('-', '');
    return _extendedColorMap[key];
  }

  static const Map<String, Color> _extendedColorMap = {
    'amber': Color(0xFFFFC107),
    'cyan': Color(0xFF00BCD4),
    'purple': Color(0xFF9C27B0),
    'teal': Color(0xFF009688),
    'indigo': Color(0xFF3F51B5),
    'pink': Color(0xFFE91E63),
    'lime': Color(0xFFCDDC39),
    'brown': Color(0xFF795548),
    'blue': Color(0xFF2196F3),
    'green': Color(0xFF4CAF50),
    'red': Color(0xFFF44336),
    'orange': Color(0xFFFF9800),
    'yellow': Color(0xFFFFEB3B),
    'greylighten1': Color(0xFFBDBDBD),
    'greylighten2': Color(0xFFE0E0E0),
    'greylighten3': Color(0xFFEEEEEE),
    'grey': Color(0xFF9E9E9E),
    'greydarken1': Color(0xFF757575),
    'bluedarken1': Color(0xFF1E88E5),
    'bluegrey': Color(0xFF607D8B),
    'deeppurple': Color(0xFF673AB7),
    'deeporange': Color(0xFFFF5722),
    'lightblue': Color(0xFF03A9F4),
    'lightgreen': Color(0xFF8BC34A),
  };

  /// VCol 的 cols 属性转为宽度比例 (0.0 ~ 1.0)。
  /// 返回 null 表示 cols 未指定（auto-size）。
  /// 支持: int (3), double (1.7), String ("3"), Map ({"cols":4,"md":3})
  static double? colsFraction(dynamic cols) {
    if (cols == null) return null;
    // Responsive breakpoint object: {"cols": 4, "md": 3} — use mobile value
    if (cols is Map) {
      final inner = cols['cols'];
      if (inner == null) return null;
      return colsFraction(inner);
    }
    final n = cols is num
        ? cols.toDouble()
        : (double.tryParse(cols.toString()) ?? 12.0);
    return (n.clamp(1, 12) / 12);
  }
}

class _SpacingPrefixes {
  const _SpacingPrefixes(
    this.all,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.x,
    this.y,
  );
  final String all, top, bottom, left, right, x, y;
}
