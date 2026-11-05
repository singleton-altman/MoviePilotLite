import 'package:flutter/material.dart';

/// A built-in launcher icon that can be selected from the app theme settings.
class AppIconOption {
  const AppIconOption({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.previewColor,
  });

  final String id;
  final String name;
  final String description;
  final String assetPath;
  final Color previewColor;
}

const appIconOptions = <AppIconOption>[
  AppIconOption(
    id: 'default',
    name: '经典紫',
    description: 'MoviePilot 原色',
    assetPath: 'assets/app_icons/icon_default.png',
    previewColor: Color(0xFF9B6BFF),
  ),
  AppIconOption(
    id: 'midnight',
    name: '午夜蓝',
    description: '深邃沉浸',
    assetPath: 'assets/app_icons/icon_midnight.png',
    previewColor: Color(0xFF202A62),
  ),
  AppIconOption(
    id: 'sunset',
    name: '落日橙',
    description: '温暖醒目',
    assetPath: 'assets/app_icons/icon_sunset.png',
    previewColor: Color(0xFFEF6C4D),
  ),
  AppIconOption(
    id: 'mint',
    name: '薄荷青',
    description: '清爽明亮',
    assetPath: 'assets/app_icons/icon_mint.png',
    previewColor: Color(0xFF2BAFAD),
  ),
  AppIconOption(
    id: 'neon',
    name: '霓虹影院',
    description: '夜间观影',
    assetPath: 'assets/app_icons/icon_neon.png',
    previewColor: Color(0xFF101936),
  ),
  AppIconOption(
    id: 'aurora',
    name: '极光玻璃',
    description: '通透未来',
    assetPath: 'assets/app_icons/icon_aurora.png',
    previewColor: Color(0xFF26134F),
  ),
  AppIconOption(
    id: 'sunset_pop',
    name: '落日跃动',
    description: '热烈鲜活',
    assetPath: 'assets/app_icons/icon_sunset_pop.png',
    previewColor: Color(0xFF5C071E),
  ),
  AppIconOption(
    id: 'mono',
    name: '黑白工作室',
    description: '极简质感',
    assetPath: 'assets/app_icons/icon_mono.png',
    previewColor: Color(0xFFF8F6F2),
  ),
];
