import 'package:flutter/widgets.dart';
import '../services/storage_service.dart';

/// 玻璃效果等级（全局设置，作用于所有毛玻璃模糊）
/// - 高：完整模糊（默认）
/// - 低：模糊上限 6，省电（低端机）
/// - 关：无模糊，仅半透明底色
enum GlassQualityLevel { high, low, off }

class GlassQuality {
  GlassQuality._();

  static const _key = 'glass_quality';

  static GlassQualityLevel get current {
    final v = StorageService.getInt(_key);
    return switch (v) {
      1 => GlassQualityLevel.low,
      2 => GlassQualityLevel.off,
      _ => GlassQualityLevel.high,
    };
  }

  static Future<void> set(GlassQualityLevel level) =>
      StorageService.setInt(_key, level.index);

  /// 计算实际模糊半径：
  /// - 关闭 → 0（无模糊）
  /// - 低 → 上限 6
  /// - 高 → 原始值；系统开启「减少动画」时减半（低端/无障碍降级）
  static double scaleBlur(double requested, BuildContext context) {
    switch (current) {
      case GlassQualityLevel.off:
        return 0;
      case GlassQualityLevel.low:
        return requested.clamp(0.0, 6.0);
      case GlassQualityLevel.high:
        if (MediaQuery.of(context).disableAnimations) {
          return requested * 0.5;
        }
        return requested;
    }
  }

  /// 是否启用模糊（关闭档返回 false，用于跳过 BackdropFilter）
  static bool get blurEnabled => current != GlassQualityLevel.off;
}
