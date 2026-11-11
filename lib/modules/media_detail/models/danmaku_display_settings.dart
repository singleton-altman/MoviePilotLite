import 'package:flutter/material.dart';

enum DanmakuColorMode { multi, white, yellow, blue, pink, mint, purple, orange }

extension DanmakuColorModeX on DanmakuColorMode {
  String get label {
    return switch (this) {
      DanmakuColorMode.multi => '多彩',
      DanmakuColorMode.white => '白色',
      DanmakuColorMode.yellow => '黄色',
      DanmakuColorMode.blue => '蓝色',
      DanmakuColorMode.pink => '粉色',
      DanmakuColorMode.mint => '薄荷',
      DanmakuColorMode.purple => '紫色',
      DanmakuColorMode.orange => '橙色',
    };
  }

  Color? get color {
    return switch (this) {
      DanmakuColorMode.multi => null,
      DanmakuColorMode.white => const Color(0xFFFFFFFF),
      DanmakuColorMode.yellow => const Color(0xFFFDE68A),
      DanmakuColorMode.blue => const Color(0xFF93C5FD),
      DanmakuColorMode.pink => const Color(0xFFF9A8D4),
      DanmakuColorMode.mint => const Color(0xFF6EE7B7),
      DanmakuColorMode.purple => const Color(0xFFC4B5FD),
      DanmakuColorMode.orange => const Color(0xFFFDBA74),
    };
  }
}

@immutable
class DanmakuDisplaySettings {
  const DanmakuDisplaySettings({
    this.speedScale = 1,
    this.fontScale = 1,
    this.opacity = 1,
    this.colorMode = DanmakuColorMode.multi,
  });

  static const defaults = DanmakuDisplaySettings();

  final double speedScale;
  final double fontScale;
  final double opacity;
  final DanmakuColorMode colorMode;

  DanmakuDisplaySettings copyWith({
    double? speedScale,
    double? fontScale,
    double? opacity,
    DanmakuColorMode? colorMode,
  }) {
    return DanmakuDisplaySettings(
      speedScale: speedScale ?? this.speedScale,
      fontScale: fontScale ?? this.fontScale,
      opacity: opacity ?? this.opacity,
      colorMode: colorMode ?? this.colorMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speedScale': speedScale,
      'fontScale': fontScale,
      'opacity': opacity,
      'colorMode': colorMode.name,
    };
  }

  factory DanmakuDisplaySettings.fromJson(Map<String, dynamic> json) {
    final colorName = json['colorMode']?.toString();
    final colorMode = DanmakuColorMode.values.firstWhere(
      (mode) => mode.name == colorName,
      orElse: () => DanmakuColorMode.multi,
    );
    return DanmakuDisplaySettings(
      speedScale: _number(json['speedScale'], 1, 0.6, 1.8),
      fontScale: _number(json['fontScale'], 1, 0.8, 1.4),
      opacity: _number(json['opacity'], 1, 0.4, 1),
      colorMode: colorMode,
    );
  }
}

double _number(dynamic value, double fallback, double min, double max) {
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed.isNaN || parsed.isInfinite) return fallback;
  return parsed.clamp(min, max).toDouble();
}
