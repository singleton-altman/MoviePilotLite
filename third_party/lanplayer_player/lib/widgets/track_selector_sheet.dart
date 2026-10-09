import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../utils/track_titles.dart';

/// 底部抽屉样式的轨道选择面板（字幕/音频通用）
///
/// - 支持任意数量轨道（内部 ListView.builder）
/// - 支持搜索过滤（超过 5 条时显示搜索框）
/// - 毛玻璃背景 + 圆角 + 拖拽手柄
class TrackSelectorSheet extends StatefulWidget {
  /// 标题（"字幕" / "音频"）
  final String title;

  /// 轨道列表，每项包含 title/language/codec 等可选字段
  final List<Map<String, dynamic>> tracks;

  /// 当前选中的轨道索引（-1 表示关闭）
  final int currentIndex;

  /// 选中回调（-1 表示关闭）
  final void Function(int index) onSelect;

  /// 是否显示搜索框（>5 条时自动显示）
  final bool showSearch;

  const TrackSelectorSheet({
    super.key,
    required this.title,
    required this.tracks,
    required this.currentIndex,
    required this.onSelect,
    this.showSearch = true,
  });

  /// 弹出底部抽屉
  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> tracks,
    required int currentIndex,
    required void Function(int index) onSelect,
    bool showSearch = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      useSafeArea: true,
      builder: (_) => TrackSelectorSheet(
        title: title,
        tracks: tracks,
        currentIndex: currentIndex,
        onSelect: onSelect,
        showSearch: showSearch,
      ),
    );
  }

  @override
  State<TrackSelectorSheet> createState() => _TrackSelectorSheetState();
}

class _TrackSelectorSheetState extends State<TrackSelectorSheet> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return widget.tracks;
    final q = _query.toLowerCase();
    return widget.tracks.where((t) {
      final title = (t['title'] ?? '').toString().toLowerCase();
      final lang = (t['language'] ?? '').toString().toLowerCase();
      final codec = (t['codec'] ?? t['Codec'] ?? '').toString().toLowerCase();
      return title.contains(q) || lang.contains(q) || codec.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * 0.65;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxH),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24).withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽手柄 + 标题
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.tracks.length} 条',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // 搜索框（>=6 条时显示）
              if (widget.showSearch && widget.tracks.length >= 6)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: AppTheme.primary,
                    decoration: InputDecoration(
                      hintText: '搜索字幕/语言…',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.5), size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.6), width: 1.5),
                      ),
                    ),
                  ),
                ),

              // 关闭选项
              _buildOption('关闭', -1, widget.currentIndex == -1),

              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            '没有匹配的${widget.title}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        shrinkWrap: true,
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final t = _filtered[i];
                          // 计算真实 index（如果经过搜索过滤）
                          final realIndex = widget.tracks.indexOf(t);
                          return _buildRow(t, realIndex);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(String label, int trackIndex, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onSelect(trackIndex);
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              if (isSelected)
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 4),
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: isSelected ? AppTheme.primary : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> track, int realIndex) {
    final title =
        trackDisplayTitle(track, index: realIndex, siblings: widget.tracks);
    final lang = (track['language'] ?? '').toString();
    final codec = (track['codec'] ?? track['Codec'] ?? '').toString();
    final isDefault = track['isDefault'] == true || track['IsDefault'] == true;
    final isForced = track['isForced'] == true || track['IsForced'] == true;
    final isBitmap = track['isBitmap'] == true;
    final isSelected = widget.currentIndex == realIndex;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onSelect(realIndex);
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              if (isSelected)
                Container(
                  width: 4,
                  height: 20,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 6),
                          _badge('默认', AppTheme.primary),
                        ],
                        if (isForced) ...[
                          const SizedBox(width: 6),
                          _badge('强制', const Color(0xFFF59E0B)),
                        ],
                        if (isBitmap) ...[
                          const SizedBox(width: 6),
                          _badge('位图', const Color(0xFFEF4444)),
                        ],
                      ],
                    ),
                    if (lang.isNotEmpty || codec.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (lang.isNotEmpty)
                            Text(
                              lang,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                            ),
                          if (lang.isNotEmpty && codec.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('·', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                            ),
                          if (codec.isNotEmpty)
                            Text(
                              codec,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: isSelected ? AppTheme.primary : Colors.white24,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
