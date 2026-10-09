import 'package:flutter/material.dart';
import '../services/danmaku_matcher.dart';
import '../theme/app_theme.dart';
import 'tap_feedback.dart';

/// 弹幕匹配候选列表。
///
/// 首屏「当前匹配」卡与搜索子面板「自动匹配候选」区共用：展示
/// 「标题 + 来源·理由·弹幕量」两行，选中行主题色高亮并带已加载徽章，
/// 点击即切换加载（回调由宿主实现真正的加载动作）。
class DanmakuCandidateList extends StatelessWidget {
  const DanmakuCandidateList({
    super.key,
    required this.candidates,
    required this.onSelect,
    this.selectedKey,
    this.loadedCount,
    this.maxHeight = 220,
  });

  final List<DanmakuMatchCandidate> candidates;
  final ValueChanged<DanmakuMatchCandidate> onSelect;

  /// 当前已加载候选的 key（`c.key`）；null 表示没有选中行。
  final String? selectedKey;

  /// 已加载弹幕条数（选中行右侧徽章）。
  final int? loadedCount;

  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: candidates.length,
        itemBuilder: (context, i) {
          final c = candidates[i];
          final selected = c.key == selectedKey;
          return TapFeedback(
            onTap: () => onSelect(c),
            borderRadius: BorderRadius.circular(8),
            child: _CandidateRow(
              candidate: c,
              selected: selected,
              loadedCount: selected ? loadedCount : null,
            ),
          );
        },
      ),
    );
  }
}

/// 单行候选：标题 + 元信息，选中时主题色高亮并带「已加载」徽章。
class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.selected,
    this.loadedCount,
  });

  final DanmakuMatchCandidate candidate;
  final bool selected;
  final int? loadedCount;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final subtitle = '${c.sourceName} · ${c.reason} · ${c.danmakuCount}条';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: selected
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.45))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.episodeTitle.isNotEmpty
                      ? '${c.title} · ${c.episodeTitle}'
                      : c.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (loadedCount != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '已加载·$loadedCount条',
                style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
