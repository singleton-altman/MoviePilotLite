import 'package:flutter/material.dart';
import 'package:lanplayer_player/lanplayer_player.dart' as kit;

import '../controllers/player_launch_controller.dart';

/// MP 实色选集底部弹层(与订阅文件统计同风格):
/// 头部剧集海报 + 集数统计,季胶囊行,集行(缩略剧照/大字集数/标题/时长/看完勾)。
/// 返回用户选中的分集;点击任一集由 [onPlayEpisode] 直连起播并关闭。
Future<kit.MediaItem?> showEpisodePickerSheet({
  required BuildContext context,
  required kit.MediaServerService service,
  required kit.MediaServer server,
  required kit.MediaItem series,
  required int? currentSeason,
}) {
  return showModalBottomSheet<kit.MediaItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EpisodePickerSheet(
      service: service,
      server: server,
      series: series,
      currentSeason: currentSeason,
    ),
  );
}

class _EpisodePickerSheet extends StatefulWidget {
  final kit.MediaServerService service;
  final kit.MediaServer server;
  final kit.MediaItem series;
  final int? currentSeason;

  const _EpisodePickerSheet({
    required this.service,
    required this.server,
    required this.series,
    this.currentSeason,
  });

  @override
  State<_EpisodePickerSheet> createState() => _EpisodePickerSheetState();
}

class _EpisodePickerSheetState extends State<_EpisodePickerSheet> {
  bool _loading = true;
  String? _error;
  List<kit.MediaItem> _episodes = [];

  /// 当前选中的季。详情页给了季号就先记着,加载完成后按数据校正
  /// (给的季不存在时兜底切换,避免面板空白)。
  int? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.currentSeason;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final eps = await widget.service
          .getEpisodes(widget.series.id, seasonId: null)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      final season = _pickInitialSeason(eps);
      // ignore: avoid_print
      print('[EpisodePicker] 剧集=${widget.series.id} 共加载=${eps.length} 集 '
          '实际季=${eps.map((e) => e.seasonNumber).toSet().toList()} '
          '选中季=$season 详情季=${widget.currentSeason}');
      setState(() {
        _episodes = eps;
        _selectedSeason = season;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // ignore: avoid_print
      print('[EpisodePicker] 加载失败: $e');
      setState(() {
        _error = '分集加载失败';
        _loading = false;
      });
    }
  }

  /// 决定面板初始选中的季。
  ///
  /// 真机案例:MP 详情页不提供季号,而媒体库里只有第 2 季——原来硬编码默认
  /// 第 1 季,按季过滤后一集都显示不出来(面板一片空白)。规则:
  /// 1) 详情页给了季号且该季真实存在 → 用它;
  /// 2) 否则优先落在「正在看的那一集」所在的季;
  /// 3) 再否则取数据里第一个存在的季。
  int _pickInitialSeason(List<kit.MediaItem> eps) {
    final available = <int>{};
    for (final e in eps) {
      final n = e.seasonNumber ?? 1;
      available.add(n > 0 ? n : 1);
    }
    final sorted = available.toList()..sort();
    final preferred = widget.currentSeason;
    if (preferred != null && available.contains(preferred)) return preferred;
    if (sorted.isEmpty) return preferred ?? 1;
    final inProgress = eps
        .where((e) => (e.watchProgress ?? 0) > 0 && (e.watchProgress ?? 0) < 1)
        .toList();
    if (inProgress.isNotEmpty) {
      final n = inProgress.first.seasonNumber ?? 1;
      if (available.contains(n)) return n;
    }
    return sorted.first;
  }

  List<int> get _seasons {
    final set = <int>{};
    for (final e in _episodes) {
      final n = e.seasonNumber ?? 1;
      set.add(n > 0 ? n : 1);
    }
    final list = set.toList()..sort();
    return list.isEmpty ? const [1] : list;
  }

  List<kit.MediaItem> get _currentEpisodes {
    final target = _selectedSeason;
    if (target == null) return const [];
    return _episodes.where((e) => (e.seasonNumber ?? 1) == target).toList();
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B1E27),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildSeriesHeader(),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('重试')),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildSeasonChips(),
                    if (_currentEpisodes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 44),
                        child: Center(
                          child: Text(
                            '该季暂无分集',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.45),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._buildEpisodeRows(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesHeader() {
    final series = widget.series;
    final watched = _episodes.where((e) => (e.watchProgress ?? 0) >= 1).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kit.ServerImage(
              imageUrl: series.posterUrl,
              headers: widget.service.streamHeaders,
              width: 56,
              height: 80,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 56,
                height: 80,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  series.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '共 ${_episodes.isEmpty ? series.totalEpisodes ?? 0 : _episodes.length} 集 · 已看 $watched',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withOpacity(0.55)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonChips() {
    final seasons = _seasons;
    if (seasons.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: seasons
            .map((n) => GestureDetector(
                  onTap: () => setState(() => _selectedSeason = n),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: n == _selectedSeason
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.16)
                          : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: n == _selectedSeason
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '第 $n 季',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: n == _selectedSeason
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  List<Widget> _buildEpisodeRows() {
    final episodes = _currentEpisodes;
    final primary = Theme.of(context).colorScheme.primary;
    return episodes.map((ep) {
      final progress = (ep.watchProgress ?? 0).clamp(0.0, 1.0);
      final done = progress >= 1;
      final isCurrentResume = progress > 0 && !done;
      return InkWell(
        onTap: () async {
          Navigator.of(context).pop(ep);
          await PlayerLaunchController.to.playEpisodeItem(
            service: widget.service,
            server: widget.server,
            episode: ep,
            episodes: episodes,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrentResume ? primary.withOpacity(0.16) : null,
            borderRadius: BorderRadius.circular(12),
            border: isCurrentResume
                ? Border.all(color: primary, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 40,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      kit.ServerImage(
                        imageUrl: ep.posterUrl,
                        headers: widget.service.streamHeaders,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      if (progress > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor:
                                Colors.white.withOpacity(0.25),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${ep.episodeNumber ?? 0}',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isCurrentResume ? primary : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ep.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ep.duration > 0
                          ? '${_formatDuration(ep.duration)}${done ? ' · 已看完' : progress > 0 ? ' · 观看至 ${(progress * 100).round()}%' : ''}'
                          : (done ? '已看完' : ''),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              done
                  ? Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF81C784),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 12, color: Color(0xFF04250F)),
                    )
                  : Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
