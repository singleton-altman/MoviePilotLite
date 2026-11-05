import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/track_titles.dart';

/// 右侧滑入的轨道选择面板（音频/字幕通用）
/// Netflix 风格：从右侧滑入，半透明毛玻璃背景
/// 显示更丰富的轨道信息：语言、编码、声道数
class TrackRightPanel extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> tracks;
  final int currentIndex;
  final void Function(int index) onSelect;
  final VoidCallback onClose;

  const TrackRightPanel({
    super.key,
    required this.title,
    required this.tracks,
    required this.currentIndex,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<TrackRightPanel> createState() => _TrackRightPanelState();
}

class _TrackRightPanelState extends State<TrackRightPanel> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// 关闭面板。
  ///
  /// 滑出动画由 [RightPanelHost] 负责（它会让面板留在树上播完再卸载），
  /// 这里只需通知宿主。改造前这里 `await _controller.reverse()` 自己播退场，
  /// 但宿主的遮罩点击绕过了它 —— 点关闭按钮有动画、点遮罩没有。
  void _animateClose() => widget.onClose();

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
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 60, horizontal: 12),
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
                // 标题栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
                  child: Row(
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.tracks.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _animateClose,
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

                // 搜索框（>=5 条时显示）
                if (widget.tracks.length >= 5)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      cursorColor: AppTheme.primary,
                      decoration: InputDecoration(
                        hintText: '\u641C\u7D22\u2026',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.6), width: 1.5),
                        ),
                      ),
                    ),
                  ),

                // 关闭选项
                _buildOption('\u5173\u95ED', -1, widget.currentIndex == -1),

                // 轨道列表
                Flexible(
                  child: _filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              '\u6CA1\u6709\u5339\u914D\u7684${widget.title}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final t = _filtered[i];
                            final realIndex = widget.tracks.indexOf(t);
                            return _buildTrackRow(t, realIndex);
                          },
                        ),
                ),
              ],
            ),
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
          // "显示全部"占位轨:只展开列表,面板保持打开
          final isShowAll = trackIndex >= 0 &&
              trackIndex < widget.tracks.length &&
              widget.tracks[trackIndex]['showAll'] == true;
          if (!isShowAll) _animateClose();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: isSelected ? AppTheme.primary : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackRow(Map<String, dynamic> track, int realIndex) {
    // 传 siblings：同语言多轨时才能拼出「中文 #1」「中文 #2」，
    // 否则两条中文字幕在列表里长得一模一样、没法选。
    final title =
        trackDisplayTitle(track, index: realIndex, siblings: widget.tracks);
    final lang = (track['language'] ?? '').toString();
    final codec = (track['codec'] ?? track['Codec'] ?? '').toString();
    final channels = (track['channels'] ?? track['Channels'] ?? '').toString();
    final bitrate = track['bitrate'] ?? track['Bitrate'];
    final isDefault = track['isDefault'] == true || track['IsDefault'] == true;
    final isForced = track['isForced'] == true || track['IsForced'] == true;
    final isSelected = widget.currentIndex == realIndex;

    // 构建丰富的副标题信息
    final metaParts = <String>[];
    if (lang.isNotEmpty) metaParts.add(lang);
    if (codec.isNotEmpty) metaParts.add(codec);
    if (channels.isNotEmpty) metaParts.add(channels);
    if (bitrate != null && bitrate is int && bitrate > 0) {
      final kbps = bitrate > 10000 ? '${(bitrate / 1000).round()} kbps' : '$bitrate bps';
      metaParts.add(kbps);
    }
    final meta = metaParts.join(' \u00B7 ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onSelect(realIndex);
          // "显示全部"占位轨:只展开列表,面板保持打开
          final isShowAll = realIndex >= 0 &&
              realIndex < widget.tracks.length &&
              widget.tracks[realIndex]['showAll'] == true;
          if (!isShowAll) _animateClose();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              // 选中指示器
              if (isSelected)
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 13),
              // 轨道信息
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
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 6),
                          _badge('\u9ED8\u8BA4', AppTheme.primary),
                        ],
                        if (isForced) ...[
                          const SizedBox(width: 6),
                          _badge('\u5F3A\u5236', const Color(0xFFF59E0B)),
                        ],
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: isSelected ? AppTheme.primary : Colors.white24,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
