import 'package:flutter/material.dart';

/// 应用主题配置
class AppTheme {
  AppTheme._();

  static const double defaultBorderRadius = 12;

  /// 主题色 - 主色调
  static const Color primaryColor = Color(0xFF1677FF);

  /// 主题色 - 次要色
  static const Color secondaryColor = Color(0xFF21B67A);

  /// 成功色
  static const Color successColor = Color(0xFF22C55E);

  /// 错误色
  static const Color errorColor = Color(0xFFFF5A52);

  /// 警告色
  static const Color warningColor = Color(0xFFFFB020);

  /// 信息色
  static const Color infoColor = Color(0xFF2395FF);

  /// 背景色（浅色主题）
  static const Color lightBackgroundColor = Color(0xFFF4F7FB);

  /// 卡片背景色（浅色主题）
  static const Color lightCardBackgroundColor = Color(0xFFFFFFFF);

  /// 卡片背景色（深色主题）
  static const Color darkCardBackgroundColor = Color(0xFF172130);

  /// 背景色（深色主题）
  static const Color darkBackgroundColor = Color(0xFF0D141F);

  /// 文本主色（浅色主题）
  static const Color lightTextPrimaryColor = Color(0xFF111827);

  /// 文本主色（深色主题）
  static const Color darkTextPrimaryColor = Color(0xFFF8FAFC);

  /// 文本次要色（浅色主题）
  static const Color lightTextSecondaryColor = Color(0xFF667085);

  /// 文本次要色（深色主题）
  static const Color darkTextSecondaryColor = Color(0xFF98A2B3);

  /// 文本次要色
  static const Color textSecondaryColor = lightTextSecondaryColor;

  /// 边框色（浅色主题）
  static const Color lightBorderColor = Color(0xFFD7DFEA);

  /// 边框色（深色主题）
  static const Color darkBorderColor = Color(0xFF2A3545);

  /// 边框色
  static const Color borderColor = lightBorderColor;

  /// 分隔线颜色（浅色主题）
  static const Color lightDividerColor = Color(0xFFE4EAF2);

  /// 分隔线颜色（深色主题）
  static const Color darkDividerColor = Color(0xFF202B3A);

  /// 分隔线颜色
  static const Color dividerColor = lightDividerColor;

  /// 使用自定义主题色的浅色主题
  static ThemeData lightThemeWithPrimary(Color primary) {
    return _buildTheme(primary: primary, brightness: Brightness.light);
  }

  /// 使用自定义主题色的深色主题
  static ThemeData darkThemeWithPrimary(Color primary) {
    return _buildTheme(primary: primary, brightness: Brightness.dark);
  }

  /// 获取浅色主题
  static ThemeData get lightTheme => lightThemeWithPrimary(primaryColor);

  /// 获取深色主题
  static ThemeData get darkTheme => darkThemeWithPrimary(primaryColor);

  static ThemeData _buildTheme({
    required Color primary,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _buildColorScheme(primary: primary, isDark: isDark);
    final cardBackground = isDark
        ? darkCardBackgroundColor
        : lightCardBackgroundColor;
    final background = isDark ? darkBackgroundColor : lightBackgroundColor;
    final divider = isDark ? darkDividerColor : lightDividerColor;
    final border = isDark ? darkBorderColor : lightBorderColor;

    return ThemeData(
      useMaterial3: false,
      primaryColor: primary,
      secondaryHeaderColor: colorScheme.secondary,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: cardBackground,
      dividerColor: divider,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
      splashColor: primary.withValues(alpha: isDark ? 0.14 : 0.10),
      highlightColor: primary.withValues(alpha: isDark ? 0.10 : 0.06),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: isDark ? 0.6 : 0.5),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 0.8, space: 1),
      textTheme: _buildTextTheme(isDark: isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: primary),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primary,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          shadowColor: Colors.black.withValues(alpha: isDark ? 0.24 : 0.12),
        ),
      ),
      colorScheme: colorScheme,
    );
  }

  static TextTheme _buildTextTheme({required bool isDark}) {
    final primary = isDark ? darkTextPrimaryColor : lightTextPrimaryColor;
    final secondary = isDark ? darkTextSecondaryColor : lightTextSecondaryColor;

    return TextTheme(
      bodyLarge: TextStyle(color: primary, fontSize: 17),
      bodyMedium: TextStyle(color: secondary, fontSize: 14),
      bodySmall: TextStyle(color: secondary, fontSize: 13),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: TextStyle(
        color: primary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: secondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static ColorScheme _buildColorScheme({
    required Color primary,
    required bool isDark,
  }) {
    if (isDark) {
      return ColorScheme.dark(
        primary: primary,
        secondary: secondaryColor,
        tertiary: infoColor,
        error: errorColor,
        // ignore: deprecated_member_use
        background: darkBackgroundColor,
        surface: darkCardBackgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        // ignore: deprecated_member_use
        onBackground: darkTextPrimaryColor,
        onSurface: darkTextPrimaryColor,
      ).copyWith(
        onSurfaceVariant: darkTextSecondaryColor,
        outline: darkBorderColor,
        outlineVariant: darkDividerColor,
        shadow: Colors.black.withValues(alpha: 0.32),
        scrim: Colors.black.withValues(alpha: 0.48),
        inverseSurface: lightCardBackgroundColor,
        onInverseSurface: lightTextPrimaryColor,
        inversePrimary: primary.withValues(alpha: 0.84),
        surfaceTint: primary,
        surfaceDim: const Color(0xFF111B28),
        surfaceBright: const Color(0xFF223046),
        surfaceContainerLowest: const Color(0xFF0B121C),
        surfaceContainerLow: const Color(0xFF121C29),
        surfaceContainer: const Color(0xFF182332),
        surfaceContainerHigh: const Color(0xFF223044),
        surfaceContainerHighest: const Color(0xFF2A3A52),
      );
    }

    return ColorScheme.light(
      primary: primary,
      secondary: secondaryColor,
      tertiary: infoColor,
      error: errorColor,
      // ignore: deprecated_member_use
      background: lightBackgroundColor,
      surface: lightCardBackgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onError: Colors.white,
      // ignore: deprecated_member_use
      onBackground: lightTextPrimaryColor,
      onSurface: lightTextPrimaryColor,
    ).copyWith(
      onSurfaceVariant: lightTextSecondaryColor,
      outline: lightBorderColor,
      outlineVariant: lightDividerColor,
      shadow: Colors.black.withValues(alpha: 0.12),
      scrim: Colors.black.withValues(alpha: 0.28),
      inverseSurface: darkCardBackgroundColor,
      onInverseSurface: darkTextPrimaryColor,
      inversePrimary: primary.withValues(alpha: 0.82),
      surfaceTint: primary,
      surfaceDim: const Color(0xFFE3E9F2),
      surfaceBright: const Color(0xFFFFFFFF),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF8FAFC),
      surfaceContainer: const Color(0xFFF2F5F9),
      surfaceContainerHigh: const Color(0xFFEDF2F8),
      surfaceContainerHighest: const Color(0xFFE6EDF5),
    );
  }
}

/// 主题扩展方法，方便获取主题色
extension ThemeExtension on BuildContext {
  /// 获取主题主色
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// 获取背景色
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;

  /// 获取文本主色
  Color get textPrimaryColor => Theme.of(this).colorScheme.onSurface;

  /// 获取文本次要色
  Color get textSecondaryColor => Theme.of(this).colorScheme.onSurfaceVariant;

  /// 获取主题次要色
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
}
