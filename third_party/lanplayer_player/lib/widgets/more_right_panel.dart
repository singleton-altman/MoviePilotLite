import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tap_feedback.dart';

/// 右侧滑入面板通用外壳：毛玻璃容器 + 头部（可选 ‹ 返回 / ✕ 关闭）。
/// 与 TrackRightPanel 同一套交互语言（右侧滑入、玻璃质感），供"更多"宫格及其
/// 二级选项面板（画质/切换内核/字幕样式）共用。
///
/// 滑入/滑出动画**不在这里**：由 [RightPanelHost] 统一驱动。原因见
/// `lib/widgets/right_panel_host.dart` 的文档 —— 面板控制不了自己什么时候被
/// 卸载，所以退场动画放在面板内部必然做不全（改造前这个 shell 只有
/// `forward()` 没有 `reverse()`，关闭时被宿主直接摘掉，凭空消失）。
class RightPanelShell extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onBack; // 非空时头部显示 ‹ 返回箭头（二级面板返回宫格）
  final VoidCallback onClose;
  final double width;

  const RightPanelShell({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    required this.onClose,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 76, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1A).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 头部：‹ 返回 | 标题 | ✕
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 8),
                  child: Row(
                    children: [
                      if (onBack != null) ...[
                        TapFeedback(
                          onTap: onBack,
                          scaleOnPress: 0.9,
                          springBack: true,
                          highlightColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white.withValues(alpha: 0.75),
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white70, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "更多"宫格面板：3×2 图标瓦片（画质/切换内核/字幕样式/外挂字幕/在线搜索 + 虚线扩展位），
/// 当前值以角标形式显示在瓦片右上角。
class MoreRightPanel extends StatelessWidget {
  final String qualityLabel; // 画质当前值（如 自动 / 4K / 原画）
  final String engineLabel; // 内核当前值（Exo / MPV / 自动）
  final bool externalSubtitleLoaded; // 外挂字幕是否已加载
  final VoidCallback onQuality;
  final VoidCallback onEngine;
  final VoidCallback onStyle;
  final VoidCallback onExternalSubtitle;
  final VoidCallback onOnlineSearch;
  final VoidCallback onClose;
  final VoidCallback? onMore; // 虚线扩展位（预留）

  const MoreRightPanel({
    super.key,
    required this.qualityLabel,
    required this.engineLabel,
    required this.externalSubtitleLoaded,
    required this.onQuality,
    required this.onEngine,
    required this.onStyle,
    required this.onExternalSubtitle,
    required this.onOnlineSearch,
    required this.onClose,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return RightPanelShell(
      title: '更多',
      onClose: onClose,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.3,
          children: [
            _MoreTile(
              icon: Icons.hd_rounded,
              label: '画质',
              badge: qualityLabel,
              onTap: onQuality,
            ),
            _MoreTile(
              icon: Icons.movie_filter_rounded,
              label: '切换内核',
              badge: engineLabel,
              badgeGray: true,
              onTap: onEngine,
            ),
            _MoreTile(
              icon: Icons.text_fields_rounded,
              label: '字幕样式',
              onTap: onStyle,
            ),
            _MoreTile(
              icon: Icons.subtitles_rounded,
              label: '外挂字幕',
              badge: externalSubtitleLoaded ? '已加载' : null,
              onTap: onExternalSubtitle,
            ),
            _MoreTile(
              icon: Icons.language_rounded,
              label: '在线搜索',
              onTap: onOnlineSearch,
            ),
            _MoreTile(
              icon: Icons.add_rounded,
              label: '更多',
              dashed: true,
              onTap: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool badgeGray;
  final bool dashed;
  final VoidCallback? onTap;

  const _MoreTile({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeGray = false,
    this.dashed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: dashed ? Colors.transparent : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(13),
          border: dashed
              ? Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1)
              : Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: dashed
                        ? Colors.white.withValues(alpha: 0.32)
                        : Colors.white.withValues(alpha: 0.82),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: dashed
                          ? Colors.white.withValues(alpha: 0.32)
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null && badge!.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeGray
                        ? Colors.white.withValues(alpha: 0.18)
                        : AppTheme.primary.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: badgeGray
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 右侧二级选项列表面板（画质/切换内核等）：带 ‹ 返回宫格。
class RightOptionListPanel extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> options; // {label, hint}
  final int currentIndex;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final void Function(int index) onSelect;

  const RightOptionListPanel({
    super.key,
    required this.title,
    required this.options,
    required this.currentIndex,
    required this.onBack,
    required this.onClose,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return RightPanelShell(
      title: title,
      onBack: onBack,
      onClose: onClose,
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 14),
        shrinkWrap: true,
        itemCount: options.length,
        itemBuilder: (_, i) {
          final opt = options[i];
          final label = opt['label']?.toString() ?? '';
          final hint = opt['hint']?.toString();
          final isSelected = i == currentIndex;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13.5,
                      ),
                    ),
                    if (hint != null && hint.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        hint,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: 18,
                      child: isSelected
                          ? Icon(Icons.check_rounded, color: AppTheme.primary, size: 16)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
