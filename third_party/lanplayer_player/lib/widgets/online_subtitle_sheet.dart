import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/opensubtitles_service.dart';
import '../theme/app_theme.dart';

/// 在线字幕搜索面板（OpenSubtitles）
///
/// 流程：输入标题 → 搜索 → 点选结果 → 下载 → 写入临时文件 → 回调路径交给引擎加载
class OnlineSubtitleSearchSheet extends StatefulWidget {
  final OpenSubtitlesService service;
  final String initialQuery;
  final int? season;
  final int? episode;

  const OnlineSubtitleSearchSheet({
    super.key,
    required this.service,
    required this.initialQuery,
    this.season,
    this.episode,
  });

  static Future<void> show(
    BuildContext context, {
    required OpenSubtitlesService service,
    required String initialQuery,
    int? season,
    int? episode,
    required Future<void> Function(String path) onDownloaded,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => OnlineSubtitleSearchSheet(
        service: service,
        initialQuery: initialQuery,
        season: season,
        episode: episode,
      ),
    ).then((path) {
      if (path is String && path.isNotEmpty) {
        return onDownloaded(path);
      }
    });
  }

  @override
  State<OnlineSubtitleSearchSheet> createState() => _OnlineSubtitleSearchSheetState();
}

class _OnlineSubtitleSearchSheetState extends State<OnlineSubtitleSearchSheet> {
  late final TextEditingController _queryController;
  bool _searching = false;
  bool _downloading = false;
  String? _error;
  List<OpenSubtitleItem> _results = [];

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryController.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });
    try {
      final results = await widget.service.search(query: q, season: widget.season, episode: widget.episode);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
        if (results.isEmpty) _error = '没有找到匹配的字幕，试试更精确的标题';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e is OpenSubtitlesException ? e.message : '搜索失败: $e';
      });
    }
  }

  Future<void> _download(OpenSubtitleItem item) async {
    setState(() => _downloading = true);
    try {
      final content = await widget.service.download(item);
      if (!mounted) return;
      final dir = await getTemporaryDirectory();
      final ext = item.fileName.toLowerCase().endsWith('.ass') ? 'ass' : 'srt';
      final file = File('${dir.path}/lanplayer_os_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await file.writeAsString(content);
      if (mounted) Navigator.of(context).pop(file.path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is OpenSubtitlesException ? e.message : '下载失败: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Color(0xFF14141D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.language_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text('在线搜索字幕', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('OpenSubtitles', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: '输入片名（电视剧自动带上季集）',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _searching ? null : _search,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: _searching
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('搜索', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.season != null || widget.episode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '当前剧集：${widget.season != null ? '第${widget.season}季' : ''}${widget.episode != null ? ' 第${widget.episode}集' : ''}',
                style: TextStyle(color: AppTheme.primary, fontSize: 12),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12))),
                ],
              ),
            ),
          if (_downloading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primary),
                  SizedBox(height: 12),
                  Text('正在下载字幕…', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ]),
              ),
            )
          else if (_results.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: _results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = _results[i];
                  return Material(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _download(item),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.download_rounded, color: Colors.white38, size: 12),
                                      const SizedBox(width: 4),
                                      Text('${item.downloads}', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                      if (item.uploader.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 12),
                                        const SizedBox(width: 4),
                                        Flexible(child: Text(item.uploader, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white38, fontSize: 11))),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.download_rounded, color: AppTheme.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.subtitles_off_rounded, color: Colors.white24, size: 40),
                  const SizedBox(height: 8),
                  Text(_searching ? '搜索中…' : '输入片名开始搜索', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ]),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
