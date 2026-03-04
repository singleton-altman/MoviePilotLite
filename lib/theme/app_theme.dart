import 'package:flutter/material.dart';

/// 应用主题配置
class AppTheme {
  AppTheme._();

  static const double defaultBorderRadius = 12;

  /// 主题色 - 主色调 (iOS 蓝色)
  static const Color primaryColor = Color(0xFF007AFF);

  /// 主题色 - 次要色 (淡绿色)
  static const Color secondaryColor = Color(0xFF34C759);

  /// 成功色
  static const Color successColor = Color(0xFF34C759);

  /// 错误色
  static const Color errorColor = Color(0xFFFF3B30);

  /// 警告色
  static const Color warningColor = Color(0xFFFF9500);

  /// 信息色
  static const Color infoColor = Color(0xFF007AFF);

  /// 背景色（浅色主题）
  static const Color lightBackgroundColor = Color.fromRGBO(245, 245, 245, 1);

  /// 卡片背景色（浅色主题）
  static const Color lightCardBackgroundColor = Colors.white;

  /// 背景色（深色主题）
  static const Color darkCardBackgroundColor = Color.fromRGBO(44, 44, 46, 1);

  /// 卡片背景色（深色主题）
  static const Color darkBackgroundColor = Color.fromRGBO(20, 20, 20, 1);

  /// 文本主色（浅色主题）
  static const Color lightTextPrimaryColor = Color.fromRGBO(28, 28, 28, 1);

  /// 文本主色（深色主题）
  static const Color darkTextPrimaryColor = Colors.white;

  /// 文本次要色
  static const Color textSecondaryColor = Color(0xFF8E8E93);

  /// 边框色
  static const Color borderColor = Color(0xFFC6C6C8);

  /// 分隔线颜色
  static const Color dividerColor = Color(0xFFC6C6C8);

  /// 获取浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      primaryColor: primaryColor,
      secondaryHeaderColor: secondaryColor,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackgroundColor,
      cardColor: lightCardBackgroundColor,
      cardTheme: CardThemeData(
        color: lightCardBackgroundColor,
        elevation: 0,
        // 固定的卡片外边距，模拟 iOS 卡片与屏幕边缘的留白
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: lightTextPrimaryColor, fontSize: 17),
        bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 14),
        titleLarge: TextStyle(
          color: lightTextPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: lightTextPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: lightTextPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackgroundColor,
        foregroundColor: lightTextPrimaryColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: lightTextPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        background: lightBackgroundColor,
        surface: lightCardBackgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: lightTextPrimaryColor,
        onSurface: lightTextPrimaryColor,
      ),
    );
  }

  /// 获取深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      primaryColor: primaryColor,
      secondaryHeaderColor: secondaryColor,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: darkCardBackgroundColor,
      cardTheme: CardThemeData(
        color: darkCardBackgroundColor,
        elevation: 0,
        // 固定的卡片外边距，模拟 iOS 卡片与屏幕边缘的留白
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: darkTextPrimaryColor, fontSize: 17),
        bodyMedium: TextStyle(color: textSecondaryColor, fontSize: 14),
        titleLarge: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackgroundColor,
        foregroundColor: darkTextPrimaryColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: darkTextPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        background: darkBackgroundColor,
        surface: darkCardBackgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: darkTextPrimaryColor,
        onSurface: darkTextPrimaryColor,
      ),
    );
  }
}

/// 主题扩展方法，方便获取主题色
extension ThemeExtension on BuildContext {
  /// 获取主题主色
  Color get primaryColor => Theme.of(this).primaryColor;

  /// 获取背景色
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;

  /// 获取文本主色
  Color get textPrimaryColor =>
      Theme.of(this).textTheme.bodyLarge?.color ??
      AppTheme.lightTextPrimaryColor;

  /// 获取文本次要色
  Color get textSecondaryColor => AppTheme.textSecondaryColor;

  /// 获取主题次要色
  Color get secondaryColor => AppTheme.secondaryColor;
}
