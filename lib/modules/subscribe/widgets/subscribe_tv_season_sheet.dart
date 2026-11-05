import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_service.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_notexists.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class SubscribeTvSeasonSheet extends StatefulWidget {
  const SubscribeTvSeasonSheet({
    super.key,
    required this.tmdbId,
    required this.title,
    required this.year,
    required this.season,
    required this.mediaKey,
    this.itemInfo,
    this.scrollController,
    this.subscribedItems = const {},
  });
  final String? tmdbId;
  final String? title;
  final String? year;
  final String? season;
  final String mediaKey;
  final Map<String, dynamic>? itemInfo;
  final ScrollController? scrollController;
  final Map<int, SubscribeItem> subscribedItems;

  @override
  State<SubscribeTvSeasonSheet> createState() => _SubscribeTvSeasonSheetState();
}

class SeasonStateInfo {
  final SeasonInfo seasonInfo;
  final MediaNotExists? mediaNotExists;
  SeasonStateInfo({required this.seasonInfo, this.mediaNotExists});

  bool get isMissing =>
      mediaNotExists != null &&
      ((mediaNotExists!.episodes?.isNotEmpty ?? false) ||
          (mediaNotExists!.total_episode ?? 0) > 0);
}

class _SubscribeTvSeasonSheetState extends State<SubscribeTvSeasonSheet> {
  final _subscribeService = Get.put(SubscribeService());
  final _mediaDetailService = Get.find<MediaDetailService>();

  List<SeasonStateInfo> _seasonInfoList = [];
  final Map<int, SubscribeItem> _subscribedItems = {};
  bool _loading = true;
  String? _loadError;
  final Set<int> _updatingSeasons = {};
  final Map<int, int> _subscribeModes = {};

  @override
  void initState() {
    super.initState();
    _subscribedItems.addAll(widget.subscribedItems);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final seasonInfo = await _mediaDetailService.getMediaSeasons(
        mediaId: widget.mediaKey,
        title: widget.title ?? '',
        year: widget.year ?? '',
      );
      final mediaNotExists = await _mediaDetailService.getMediaNotExists(
        widget.itemInfo ?? {},
      );
      final resolvedSubscribedItems = <int, SubscribeItem>{..._subscribedItems};
      final statusResults = await Future.wait(
        seasonInfo.where((e) => e.season_number != null).map((season) async {
          final item = await _mediaDetailService.getSubscribeMediaStatus(
            widget.mediaKey,
            season: season.season_number,
            title: widget.title,
          );
          return (season.season_number!, item);
        }),
      );
      for (final (seasonNumber, item) in statusResults) {
        if (item != null) {
          resolvedSubscribedItems[seasonNumber] = item;
        }
      }
      final merged = <SeasonStateInfo>[];
      for (final el in seasonInfo) {
        final sn = el.season_number;
        MediaNotExists? notExists;
        if (sn != null) {
          try {
            notExists = mediaNotExists.where((e) => e.season == sn).first;
          } catch (_) {}
        }
        merged.add(SeasonStateInfo(seasonInfo: el, mediaNotExists: notExists));
      }
      if (!mounted) return;
      setState(() {
        _subscribedItems
          ..clear()
          ..addAll(resolvedSubscribedItems);
        _seasonInfoList = merged;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _seasonInfoList = [];
        _loading = false;
        _loadError = '加载季信息失败，请稍后重试';
      });
    }
  }

  Future<void> _toggleSubscription(SeasonInfo season, bool subscribe) async {
    final seasonNumber = season.season_number;
    if (seasonNumber == null || _updatingSeasons.contains(seasonNumber)) {
      return;
    }
    setState(() => _updatingSeasons.add(seasonNumber));
    final item = widget.itemInfo ?? {};
    final doubanId = item['douban_id']?.toString() ?? '';
    final name = widget.title ?? item['name']?.toString() ?? '';
    final tmdbId = widget.tmdbId ?? item['tmdb_id']?.toString() ?? '';
    final year = widget.year ?? item['year']?.toString() ?? '';
    final mediaId = item['media_id']?.toString() ?? '';

    try {
      if (subscribe) {
        final response = await _subscribeService.submitTvSubscribe(
          doubanid: doubanId,
          mediaid: mediaId.isEmpty ? '' : mediaId,
          name: name,
          season: seasonNumber,
          tmdbid: tmdbId.isEmpty ? null : tmdbId,
          year: year.isEmpty ? null : year,
          bestVersion: _bestVersionFor(seasonNumber),
          bestVersionFull: _bestVersionFullFor(seasonNumber),
        );
        if (response.success != true) {
          Get.snackbar('订阅失败', response.message ?? '请稍后重试');
          return;
        }
        final id = response.data?.id;
        if (!mounted) return;
        setState(() {
          _subscribedItems[seasonNumber] = SubscribeItem(
            id: id,
            season: seasonNumber,
          );
        });
        Get.snackbar('订阅成功', '已订阅第 $seasonNumber 季');
      } else {
        final existing = _subscribedItems[seasonNumber];
        final success = existing?.id != null
            ? await _subscribeService.deleteSubscribes(existing!.id.toString())
            : await _subscribeService.deleteMediaSubscribe(
                widget.mediaKey,
                season: seasonNumber.toString(),
              );
        if (!success) {
          Get.snackbar('取消订阅失败', '第 $seasonNumber 季请稍后重试');
          return;
        }
        if (!mounted) return;
        setState(() => _subscribedItems.remove(seasonNumber));
        Get.snackbar('取消订阅成功', '已取消第 $seasonNumber 季');
      }
    } catch (e) {
      Get.snackbar('操作失败', '第 $seasonNumber 季更新失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _updatingSeasons.remove(seasonNumber));
    }
  }

  int _bestVersionFor(int seasonNumber) {
    final mode = _subscribeModes[seasonNumber] ?? 0;
    return mode == 0 ? 0 : 1;
  }

  int _bestVersionFullFor(int seasonNumber) {
    final mode = _subscribeModes[seasonNumber] ?? 0;
    return mode == 0 || mode == 2 ? 1 : 0;
  }

  static String _formatAirDate(String? airDate) {
    if (airDate == null || airDate.isEmpty) return '';
    final parts = airDate.split('-');
    if (parts.length >= 3) {
      return '首播于 ${parts[0]}年${parts[1]}月${parts[2]}日';
    }
    return airDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('订阅季度'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 720
              ? 680.0
              : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: _buildBodyState(theme))],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBodyState(ThemeData theme) {
    if (_loading) {
      return const AppLoadingCenter(message: '正在读取季度信息');
    }
    if (_loadError != null) {
      return _buildStateMessage(
        theme,
        icon: Icons.cloud_off_rounded,
        title: '加载失败',
        message: _loadError!,
        actionLabel: '重试',
        onAction: _loadData,
      );
    }
    if (_seasonInfoList.isEmpty) {
      return _buildStateMessage(
        theme,
        icon: Icons.tv_off_rounded,
        title: '暂无季度',
        message: '当前媒体没有可订阅的季度信息',
      );
    }
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _seasonInfoList.length,
      itemBuilder: (context, index) =>
          _buildSeasonItem(context, _seasonInfoList[index]),
    );
  }

  Widget _buildStateMessage(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 46,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonItem(BuildContext context, SeasonStateInfo state) {
    final theme = Theme.of(context);
    final s = state.seasonInfo;
    final seasonNum = s.season_number ?? -1;
    final selected = _subscribedItems.containsKey(seasonNum);
    final isUpdating = _updatingSeasons.contains(seasonNum);
    final imageUrl = ImageUtil.convertMediaSeasonImageUrl(s.poster_path ?? '');
    final year = s.air_date != null && s.air_date!.length >= 4
        ? s.air_date!.substring(0, 4)
        : '';
    final episodeCount = s.episode_count ?? 0;
    final rating = s.vote_average;

    final metaParts = <String>[
      if (year.isNotEmpty) year,
      if (episodeCount > 0) '$episodeCount 集',
      if (rating != null && rating > 0) '评分 ${rating.toStringAsFixed(1)}',
    ];
    final airDate = _formatAirDate(s.air_date);
    final surfaceColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.16)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.62);
    final borderColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.42)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.42);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: null,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedImage(
                          imageUrl: imageUrl,
                          width: 80,
                          height: 124,
                          fit: BoxFit.cover,
                          errorWidget: _buildPosterFallback(theme),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  s.name ?? '第 $seasonNum 季',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    metaParts.isEmpty
                                        ? '暂无剧集信息'
                                        : metaParts.join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                selected
                                    ? _buildSubscribedPill(theme)
                                    : state.isMissing
                                    ? _buildMissingPill(theme)
                                    : Flexible(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.event_rounded,
                                              size: 14,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.72),
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                airDate.isEmpty
                                                    ? '暂无首播日期'
                                                    : airDate,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                Spacer(),
                                Semantics(
                                  label: '第 $seasonNum 季订阅',
                                  value: selected ? '已订阅' : '未订阅',
                                  child: isUpdating
                                      ? const SizedBox(
                                          width: 48,
                                          height: 32,
                                          child: Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Switch(
                                          value: selected,
                                          onChanged: (value) =>
                                              _toggleSubscription(s, value),
                                          activeThumbColor:
                                              theme.colorScheme.primary,
                                          activeTrackColor: theme
                                              .colorScheme
                                              .primaryContainer,
                                          inactiveThumbColor:
                                              theme.colorScheme.outline,
                                          inactiveTrackColor: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: CupertinoSlidingSegmentedControl<int>(
                                groupValue: _subscribeModes[seasonNum] ?? 0,
                                padding: const EdgeInsets.all(2),
                                children: const {
                                  0: Text('普通'),
                                  1: Text('分集洗版'),
                                  2: Text('全集洗版'),
                                },
                                onValueChanged: (value) {
                                  if (selected || value == null) {
                                    return;
                                  }
                                  setState(
                                    () => _subscribeModes[seasonNum] = value,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterFallback(ThemeData theme) {
    return Container(
      width: 82,
      height: 116,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.50 : 0.76,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.tv_rounded,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.68),
        size: 32,
      ),
    );
  }

  Widget _buildMissingPill(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        '缺失',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSubscribedPill(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '已订阅',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
