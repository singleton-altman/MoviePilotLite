import '../../models/player_settings.dart';

/// mpv 字幕样式选项映射 —— **「MPV」与「MPV原生(Surface)」两个内核共用一份**。
///
/// 两个内核跑的都是 libmpv，同一份用户设置必须映射出逐项相同的选项；否则同一
/// 片源在两个内核下字幕大小/位置/描边不一致（这类「内核间行为漂移」在本项目
/// 已被真机实证过多次）。映射只留这一份，另一个内核直接遍历下发。
///
/// 返回的是「选项名 → 值」的字符串表，值类型与 mpv 的字面量一致。
Map<String, String> mpvSubtitleStyleOptions(PlayerSettings settings) {
  // 字号基准 **58**：mpv 的单位是"窗口高 720 时的缩放像素"，58/720 ≈ 8.06%
  // 视频高度。为什么是 8%：用户实测「内封 ASS 特效字幕正常、外挂明显小」——
  // 内封走的是**脚本自带字号**（常见 7~10%），而外挂（无自带样式）此前用
  // libass 默认的 6.25%，再乘用户缩放 0.82 只剩 5.1%，所以看着小。
  // 基准对齐到脚本量级（8%），用户缩放继续叠加（设回 1.0 即 8%）。
  const baseFontSize = 58;
  return {
    'sub-font-size': '$baseFontSize',
    'sub-scale': '${settings.subtitleFontSizeScale}',
    // 延迟始终下发：用户把延迟改回 0 时要能生效（只在下发非零值时旧值会残留）
    'sub-delay': '${settings.subtitleDelaySeconds}',
    // 底部边距：mpv 以视频高度为 100 个单位，设置里是 0-0.3 的百分比
    'sub-margin-y': '${(settings.subtitleBottomMargin * 100).round()}',
    'sub-color': argbToMpvHex(settings.subtitleColor),
    'sub-border-color': argbToMpvHex(settings.subtitleBorderColor),
    'sub-border-size': '${settings.subtitleBorderWidth}',
    'sub-shadow-color': argbToMpvHex(settings.subtitleShadowColor),
    'sub-shadow-offset': '${settings.subtitleShadowOffset}',
    'sub-bold': settings.subtitleBold ? 'yes' : 'no',
    // 'system' 不是字体名，下发会让 fontconfig 找不到而退回默认
    if (settings.subtitleFontFamily != 'system')
      'sub-font': settings.subtitleFontFamily,
    // ASS/SSA 特效字幕：force=统一样式（sub-font-size 对 ASS 也生效），
    // no=脚本自带样式优先（卡拉OK/定位/动画完整保留）
    'sub-ass-override': settings.subtitleAssOverride ? 'force' : 'no',
    // 原盘(m2ts/ISO)按蓝光惯例自动选轨：给出语言优先序，命中用户偏好。
    // 普通文件无副作用——无匹配语言时 mpv 保持默认选轨行为。
    if (settings.defaultAudioLang?.isNotEmpty == true)
      'alang': settings.defaultAudioLang!,
    if (settings.defaultSubtitleLang?.isNotEmpty == true)
      'slang': settings.defaultSubtitleLang!,
  };
}

/// ARGB int → mpv 颜色字面量 `#AARRGGBB`。
String argbToMpvHex(int argb) {
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return '#${hex(a)}${hex(r)}${hex(g)}${hex(b)}'.toUpperCase();
}
