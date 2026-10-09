import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/player_settings.dart';
import '../../providers/app_providers.dart';
import '../../player/core/player_engine.dart';
import '../../utils/app_log.dart';
import '../../utils/subtitle_fonts.dart';

/// 字幕样式配置面板（深色沉浸式风格）
/// 在播放器"更多"菜单中调用，修改实时生效
class SubtitleStyleSheet extends ConsumerWidget {
  final PlayerEngine? engine;
  final VoidCallback? onClose;

  const SubtitleStyleSheet({super.key, this.engine, this.onClose});

  /// 显示字幕样式面板（底部抽屉模式）
  static void show(BuildContext context, WidgetRef ref, PlayerEngine? engine, {VoidCallback? onClose}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      useSafeArea: true,
      builder: (_) => SubtitleStyleSheet(engine: engine, onClose: onClose),
    ).then((_) => onClose?.call());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽手柄
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // 标题栏
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(children: [
                  const Text('字幕样式', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ]),
              ),
              // 内容区域
              Flexible(
                child: SubtitleStyleContent(engine: engine),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 字幕样式配置内容（底部抽屉与右侧二级面板共用）
/// onDone 为空时"完成"按钮走 Navigator.pop（抽屉模式）；
/// 右侧面板模式传入关闭回调，避免 pop 到播放器上层路由。
class SubtitleStyleContent extends ConsumerWidget {
  final PlayerEngine? engine;
  final VoidCallback? onDone;

  const SubtitleStyleContent({super.key, this.engine, this.onDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerSettingsProvider);
    final notifier = ref.read(playerSettingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 基础样式 ---
          _buildSectionTitle('基础样式'),
          _buildSlider(
            '字幕延迟(秒)', s.subtitleDelaySeconds, -15, 15,
            (v) => _apply(notifier, s.copyWith(subtitleDelaySeconds: double.parse(v.toStringAsFixed(1)))),
            formatLabel: (v) => v == 0 ? '同步' : '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)}s',
          ),
          _buildSlider(
            '字号倍数', s.subtitleFontSizeScale, 0.5, 2.5,
            (v) => _apply(notifier, s.copyWith(subtitleFontSizeScale: double.parse(v.toStringAsFixed(2)))),
            formatLabel: (v) => '${v.toStringAsFixed(2)}x',
          ),
          _buildOptionRow(
            '字体', ['system', 'sans-serif', 'serif', 'monospace'],
            s.subtitleFontFamily, ['系统', '无衬线', '衬线', '等宽'],
            (v) => _apply(notifier, s.copyWith(subtitleFontFamily: v)),
          ),
          _buildCustomFontRow(notifier, context, s),
          _buildSwitch(
            '加粗', s.subtitleBold,
            (v) => _apply(notifier, s.copyWith(subtitleBold: v)),
          ),
          const SizedBox(height: 16),

          // --- 颜色样式 ---
          _buildSectionTitle('颜色样式'),
          _buildColorPalette(
            '文字颜色', s.subtitleColor,
            (v) => _apply(notifier, s.copyWith(subtitleColor: v)),
          ),
          _buildColorPalette(
            '描边颜色', s.subtitleBorderColor,
            (v) => _apply(notifier, s.copyWith(subtitleBorderColor: v)),
          ),
          _buildSlider(
            '描边粗细', s.subtitleBorderWidth, 0, 4,
            (v) => _apply(notifier, s.copyWith(subtitleBorderWidth: double.parse(v.toStringAsFixed(1)))),
            formatLabel: (v) => v.toStringAsFixed(1),
          ),
          const SizedBox(height: 16),

          // --- 阴影 ---
          _buildSectionTitle('阴影'),
          _buildColorPalette(
            '阴影颜色', s.subtitleShadowColor,
            (v) => _apply(notifier, s.copyWith(subtitleShadowColor: v)),
          ),
          _buildSlider(
            '阴影偏移', s.subtitleShadowOffset, 0, 4,
            (v) => _apply(notifier, s.copyWith(subtitleShadowOffset: double.parse(v.toStringAsFixed(1)))),
            formatLabel: (v) => v.toStringAsFixed(1),
          ),
          const SizedBox(height: 16),

          // --- 位置布局 ---
          _buildSectionTitle('位置布局'),
          _buildSlider(
            '底部边距', s.subtitleBottomMargin, 0, 0.3,
            (v) => _apply(notifier, s.copyWith(subtitleBottomMargin: double.parse(v.toStringAsFixed(2)))),
            formatLabel: (v) => '${(v * 100).toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 16),

          // --- ASS 字幕 ---
          _buildSectionTitle('ASS/SSA 特效字幕'),
          _buildSwitch(
            '强制统一样式', s.subtitleAssOverride,
            (v) => _apply(notifier, s.copyWith(subtitleAssOverride: v)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              s.subtitleAssOverride
                  ? '开启：所有字幕使用统一样式（覆盖 ASS 特效）'
                  : '关闭：ASS/SSA 字幕保留原始特效样式',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
            ),
          ),
          const SizedBox(height: 24),

          // --- 预览与重置 ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '字幕预览效果',
                style: TextStyle(
                  color: Color(s.subtitleColor),
                  fontSize: 18 * s.subtitleFontSizeScale,
                  fontWeight: s.subtitleBold ? FontWeight.bold : FontWeight.normal,
                  shadows: s.subtitleShadowOffset > 0
                      ? [Shadow(
                          color: Color(s.subtitleShadowColor),
                          offset: Offset(s.subtitleShadowOffset, s.subtitleShadowOffset),
                        )]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _buildButton(
                '重置默认',
                () {
                  notifier.update((cur) => cur.copyWith(
                    subtitleFontSizeScale: 1.5,
                    subtitleFontFamily: 'system',
                    subtitleBold: false,
                    subtitleColor: 0xFFFFFFFF,
                    subtitleBorderColor: 0xCC000000,
                    subtitleBorderWidth: 3.0,
                    subtitleShadowColor: 0x80000000,
                    subtitleShadowOffset: 2.0,
                    subtitleBottomMargin: 0.05,
                    subtitleBackgroundOpacity: 0.0,
                    subtitleAssOverride: true,
                  ));
                  // 应用到引擎
                  const newSettings = PlayerSettings.defaults;
                  engine?.applySubtitleStyle(newSettings);
                },
                isPrimary: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                '完成',
                () {
                  if (onDone != null) {
                    onDone!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                isPrimary: true,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  /// 应用设置并同步到引擎
  void _apply(PlayerSettingsNotifier notifier, PlayerSettings newSettings) {
    notifier.update((cur) => newSettings);
    engine?.applySubtitleStyle(newSettings);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, Function(double) onChanged, {String Function(double)? formatLabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text(formatLabel != null ? formatLabel(value) : value.toStringAsFixed(1),
                style: TextStyle(color: AppTheme.primary, fontSize: 13)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            thumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primary,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildOptionRow(String title, List<String> options, String current, List<String> labels, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const Spacer(),
          DropdownButton<String>(
            value: current,
            dropdownColor: const Color(0xFF1A1A24),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            underline: Container(height: 1, color: Colors.white38),
            items: options.asMap().entries.map((e) => DropdownMenuItem(
              value: e.value,
              child: Text(labels[e.key]),
            )).toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ],
      ),
    );
  }

  /// 自定义字体文件行：选择 .ttf/.otf → 复制到应用目录 → 注册全局字体
  /// 注：仅对 ExoPlayer 外挂字幕（Flutter 层渲染）生效；MPV 内嵌字幕走 libass 原生渲染
  Widget _buildCustomFontRow(PlayerSettingsNotifier notifier, BuildContext context, PlayerSettings s) {
    final current = SubtitleFonts.savedName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('自定义字体', style: TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  current != null ? current : '未设置',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: current != null ? AppTheme.primary : Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickCustomFont(notifier, context, s),
                  icon: Icon(Icons.font_download_rounded, size: 16, color: AppTheme.primary),
                  label: Text('选择字体文件', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (current != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    await SubtitleFonts.clear();
                    _apply(notifier, s); // 触发重建刷新 UI
                  },
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                  tooltip: '清除自定义字体',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomFont(PlayerSettingsNotifier notifier, BuildContext context, PlayerSettings s) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;
      final dest = await SubtitleFonts.copyToAppDir(path);
      if (dest == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('字体文件复制失败'), duration: Duration(seconds: 2)));
        }
        return;
      }
      await SubtitleFonts.savePath(dest);
      final ok = await SubtitleFonts.ensureLoaded();
      _apply(notifier, s); // 触发重建刷新 UI（应用引擎样式）
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '自定义字体已生效（Exo 外挂字幕）' : '字体注册失败，请检查文件格式'), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      AppLog.w('Subtitle', '选择字体失败: $e');
    }
  }

  Widget _buildColorPalette(String label, int currentColor, Function(int) onChanged) {
    const colors = <int, String>{
      0xFFFFFFFF: '白',
      0xFFFFFF00: '黄',
      0xFF00FFFF: '青',
      0xFF00FF00: '绿',
      0xFFFF0000: '红',
      0xFF0000FF: '蓝',
      0xFF000000: '黑',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.entries.map((e) {
              final sel = e.key == currentColor;
              return GestureDetector(
                onTap: () => onChanged(e.key),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Color(e.key),
                    shape: BoxShape.circle,
                    border: sel ? Border.all(color: Colors.white, width: 3) : Border.all(color: Colors.white24, width: 1),
                  ),
                  child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onTap, {required bool isPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primary : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
