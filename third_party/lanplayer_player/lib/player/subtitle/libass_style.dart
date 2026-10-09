/// 交给 libass 的样式覆盖参数（纯函数，可单测）。
///
/// 为什么需要：外挂**普通字幕（SRT/VTT）**原先不走 libass —— Exo 内核下它们走
/// 原生 SubtitleView 或 Dart 叠加层，那两条路径用 `0.06 × 用户缩放` 的基准，
/// 用户缩放 0.5 一乘只剩 3% 视频高度（真机实证 2026-09-27：外挂明显小于内封）。
///
/// libass 的内置默认样式是 **18px @ PlayRes 288 = 视频高度的 6.25%**
/// （libass/ass.c: `set_default_style` → FontSize = 18），与 mpv 的默认一致；
/// 所以让普通字幕也走 libass，大小自然回到正常，无需另立基准。
///
/// 覆盖只开 `ASS_OVERRIDE_BIT_STYLE`（字体名/字号/颜色/描边/属性），
/// **不含定位与边距** —— 特效字幕的 \pos/\move/\k/\t 完全不受影响。
library;

import '../../models/player_settings.dart';


/// ARGB int → ASS 颜色 `&HAABBGGRR`：字节序与 ARGB 相反，alpha 在高位。
int argbToAssColor(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return (a << 24) | (b << 16) | (g << 8) | r;
}

/// libass 样式覆盖的字号基准：**23**（PlayRes 288 下的 8% 视频高度）。
///
/// 为什么不用 libass 默认的 18（6.25%）：用户实测「内封 ASS 特效字幕正常、
/// 外挂明显小」—— 内封走脚本自带字号（常见 7~10%），外挂（无自带样式）若按
/// 6.25% 再乘用户缩放（0.82）只剩 5.1%，观感明显偏小。基准对齐到脚本量级。
const int kLibassBaseFontSize = 23;

/// 字幕设置 → libass 覆盖参数（键名与 JNI 的 `nativeSetStyle` 一致）。
///
/// [forceStyle]：是否开启覆盖。普通字幕（SRT/VTT）没有自带样式 → 恒为 true；
/// ASS 由用户的「统一样式」设置决定（语义与 mpv 的 `sub-ass-override` 对齐）。
Map<String, Object> libassStyleArgs(
  PlayerSettings settings, {
  required bool forceStyle,
}) {
  final family = settings.subtitleFontFamily;
  return <String, Object>{
    // 字号：脚本单位。libass 的默认 18 对应 6.25% 视频高度，用户缩放乘上去
    'fontSize': (kLibassBaseFontSize * settings.subtitleFontSizeScale).round(),
    // 'system' 不是字体名，给 libass 的 Arial 兜底（它会在系统里做替换）
    'fontName': family == 'system' ? 'Arial' : family,
    'primaryColour': argbToAssColor(settings.subtitleColor),
    'outlineColour': argbToAssColor(settings.subtitleBorderColor),
    'backColour': argbToAssColor(settings.subtitleShadowColor),
    'bold': settings.subtitleBold ? 1 : 0,
    'outline': settings.subtitleBorderWidth,
    'shadow': settings.subtitleShadowOffset,
    'enabled': forceStyle ? 1 : 0,
  };
}
