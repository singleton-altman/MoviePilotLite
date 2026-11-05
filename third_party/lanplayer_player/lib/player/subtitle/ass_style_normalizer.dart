/// 外挂 ASS/SSA 字号归一化：**只改 `[V4+ Styles]` 的 Fontsize 字段**。
///
/// 为什么这样做（真机实证 2026-09-27）：mpv 在 `--sub-ass-override=no`
/// （保留脚本样式，用户的设置）下 **`sub-font-size` 对 ASS 完全不生效**，而下载
/// 来的 ASS 常带小字号样式 → 外挂字幕明显小于内封。改用 `yes/scale/force` 去
/// 覆盖会改掉脚本的字体/颜色/描边（用户要求"不影响特效字幕"）。
///
/// 所以改成动文件本身：文字按目标比例放大，而 `\pos`/`\move`/`\k`/`\t` 等
/// **事件标签、时间轴、正文一律逐字节不变** —— 定位/动画/卡拉OK 不受影响。
library;

/// 目标字号 = PlayResY × [targetRatio]（ratio 由调用方给出：视频高度比例 × 用户缩放）。
///
/// 找不到 styles 段或不是 ASS/SSA 内容时**原样返回**（绝不破坏文件）。
String normalizeAssFontSize(String content, double targetRatio) {
  if (targetRatio <= 0 || content.isEmpty) return content;
  if (!content.contains('[Script Info]') &&
      !content.contains('[V4+ Styles]') &&
      !content.contains('[V4 Styles]')) {
    return content; // 不是 ASS/SSA（SRT/VTT 走各自路径）
  }

  final lines = content.split('\n');
  // PlayResY：ASS 坐标系的纵向基准，缺省 288（libass 的默认）
  var playResY = 288.0;
  var inStyles = false;
  var fontSizeIdx = -1;
  var changed = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();
    if (trimmed.startsWith('PlayResY:')) {
      playResY = double.tryParse(trimmed.substring(9).trim()) ?? playResY;
      continue;
    }
    if (trimmed.startsWith('[')) {
      inStyles = trimmed.startsWith('[V4+ Styles]') ||
          trimmed.startsWith('[V4 Styles]');
      fontSizeIdx = -1;
      continue;
    }
    if (!inStyles) continue;
    // Format 行：定位 Fontsize 是第几个字段（各文件字段顺序/数量不一）
    if (trimmed.startsWith('Format:')) {
      final fields = trimmed.substring(7).split(',').map((f) => f.trim()).toList();
      fontSizeIdx = fields.indexOf('Fontsize');
      continue;
    }
    if (!trimmed.startsWith('Style:') || fontSizeIdx < 0) continue;
    final head = line.substring(0, line.indexOf('Style:') + 6);
    final body = line.substring(line.indexOf('Style:') + 6);
    final parts = body.split(',');
    if (fontSizeIdx >= parts.length) continue;
    // 目标字号：PlayResY × 比例。保留一位小数（ASS 的常见写法）
    final target = playResY * targetRatio;
    final formatted = target == target.roundToDouble()
        ? '${target.toStringAsFixed(1)}'
        : target.toStringAsFixed(1);
    parts[fontSizeIdx] = formatted;
    lines[i] = '$head${parts.join(',')}';
    changed = true;
  }
  return changed ? lines.join('\n') : content;
}
