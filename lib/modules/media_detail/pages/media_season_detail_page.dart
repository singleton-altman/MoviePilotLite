import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_service.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_controller.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_notexists.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/season_episode_detail.dart';
import 'package:moviepilot_mobile/modules/search/pages/search_mid_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/media_source_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/app_glass_card.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class MediaSeasonDetailPage extends StatefulWidget {
  const MediaSeasonDetailPage({
    super.key,
    required this.reqPath,
    required this.subscribeMediaKey,
    required this.tmdbId,
    required this.seasonNumber,
    required this.title,
    required this.year,
    required this.doubanId,
    required this.mediaId,
    required this.subscribeItem,
    this.scrollController,
  });
  final String reqPath;
  final String subscribeMediaKey;
  final String tmdbId;
  final int seasonNumber;
  final String title;
  final String year;
  final String doubanId;
  final String mediaId;
  final SubscribeItem? subscribeItem;
  final ScrollController? scrollController;
  @override
  State<MediaSeasonDetailPage> createState() => _MediaSeasonDetailPageState();
}

class _MediaSeasonDetailPageState extends State<MediaSeasonDetailPage> {
  final _mediaDetailService = Get.find<MediaDetailService>();
  final _mediaDetailController = Get.find<MediaDetailController>();
  List<SeasonEpisodeDetail> _episodes = [];
  bool _loading = true;
  String? _error;
  String? get _tmdbId => widget.tmdbId;
  int? get _seasonNumber => widget.seasonNumber;
  String? get _title => widget.title;

  bool _submitting = false;
  String? get _reqPath => widget.reqPath;

  final _subscribeItem = Rx<SubscribeItem?>(null);

  bool get _isSubscribed =>
      _subscribeItem.value != null && _subscribeItem.value!.id != null;

  SeasonInfo? get _seasonInfo {
    final detail = _mediaDetailController.mediaDetail.value;
    final sn = _seasonNumber;
    if (detail?.season_info == null || sn == null) return null;
    return detail!.season_info!.firstWhereOrNull((s) => s.season_number == sn);
  }

  String? get _seasonPosterUrl {
    final raw = _seasonInfo?.poster_path ?? '';
    if (raw.trim().isEmpty) return null;
    return ImageUtil.convertMediaSeasonImageUrl(raw.trim());
  }

  String? get _mediaBackdropUrl {
    final detail = _mediaDetailController.mediaDetail.value;
    final raw = detail?.backdrop_path ?? '';
    if (raw.trim().isEmpty) return null;
    return ImageUtil.convertCacheImageUrl(raw.trim());
  }

  String get _seasonTitleText {
    final sn = _seasonNumber ?? 0;
    return '第 $sn 季';
  }

  @override
  void initState() {
    super.initState();
    _subscribeItem.value = widget.subscribeItem;
    _loadEpisodes();
    Future.delayed(const Duration(milliseconds: 1000), () {
      _loadSubscribeStatus();
    });
  }

  Future<void> _loadSubscribeStatus() async {
    final subscribeItem = await _mediaDetailService.getSubscribeMediaStatus(
      widget.subscribeMediaKey,
      season: _seasonNumber ?? 0,
      title: _title ?? '',
    );
    _subscribeItem.value = subscribeItem;
  }

  Future<void> _loadEpisodes() async {
    final tmdbId = _tmdbId ?? '';
    final seasonNumber = _seasonNumber ?? 0;
    if (tmdbId.isEmpty || seasonNumber < 0) {
      setState(() {
        _loading = false;
        _error = '参数缺失';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _mediaDetailService.getSeasonDetail(
        reqPath: _reqPath ?? '',
      );
      if (!mounted) return;
      setState(() {
        _episodes = list;
        _loading = false;
        _error = list.isEmpty ? '暂无集数信息' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _episodes = [];
        _loading = false;
        _error = '加载失败，请重试';
      });
    }
  }

  Future<void> _onSubscribeTap() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final wasSubscribed = _isSubscribed;
    final (success, isTv, subscribeId) = await _mediaDetailController
        .handleSubscribe(season: _seasonNumber);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!success) {
      ToastUtil.error('${wasSubscribed ? '取消' : ''}订阅失败');
      return;
    }
    if (_isSubscribed) {
      ToastUtil.success('${wasSubscribed ? '取消' : ''}订阅成功');
    } else {
      Get.back();
      Future.delayed(const Duration(seconds: 1), () {
        ToastUtil.success(
          '${_title ?? ''} 第 $_seasonNumber 季 订阅成功',
          title: '订阅成功',
          duration: const Duration(seconds: 3),
          mainButtonText: '编辑',
          onMainButtonPressed: () {
            Get.toNamed(
              '/subscribe-edit',
              arguments: SubscribeItem(id: subscribeId),
            );
          },
        );
      });
    }
    _loadSubscribeStatus();
  }

  void _openSearch(BuildContext context) async {
    if (!Get.find<AppService>().canSearch) {
      ToastUtil.info('当前帐号无资源搜索权限');
      return;
    }
    final detail = _mediaDetailController.mediaDetail.value;
    final source = detail?.source;
    final searchKey = widget.subscribeMediaKey;
    final result = await Get.bottomSheet<({String area, List<int> sites})>(
      SiteSelectSheet(hasSegment: true),
      isScrollControlled: true,
    );
    if (result == null) return;
    final (area, sites) = (result.area, result.sites);
    if (sites.isEmpty) {
      ToastUtil.info('请至少选择一个站点');
      return;
    }
    final params = <String, String>{
      'mediaSearchKey': searchKey,
      'area': area,
      'sites': sites.join(','),
      'year': widget.year,
      'mtype': 'tv',
      'title': widget.title,
      'season': (_seasonNumber ?? 0).toString(),
      if ((detail?.backdrop_path ?? '').isNotEmpty)
        'backdrop': detail!.backdrop_path!,
      if (source != null) 'source': MediaSourceUtil.sourceValue(source),
    };
    Get.toNamed('/search-media-result', parameters: params);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seasonTitle = _seasonTitleText;
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          _buildImmersiveHeader(context, seasonTitle),
          SliverToBoxAdapter(child: _buildSeasonMeta(context)),
          SliverToBoxAdapter(child: _buildActionButtons(context)),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _episodes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadEpisodes,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildEpisodeCard(context, _episodes[index]),
                  ),
                  childCount: _episodes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  SliverAppBar _buildImmersiveHeader(BuildContext context, String seasonTitle) {
    final theme = Theme.of(context);
    final poster = _seasonPosterUrl;
    final backdrop = _mediaBackdropUrl;
    final bg = poster ?? backdrop;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 260,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: Get.back,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (bg != null)
              CachedImage(
                imageUrl: bg,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            else
              Container(color: theme.colorScheme.surfaceContainerHighest),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$seasonTitle · ${widget.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonMeta(BuildContext context) {
    final theme = Theme.of(context);
    final info = _seasonInfo;
    final overview = info?.overview?.trim();
    final score = info?.vote_average;
    final episodeCount = info?.episode_count ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('第 ${_seasonNumber ?? 0} 季'),
              if (episodeCount > 0) _chip('$episodeCount 集'),
              if (score != null && score > 0) _scoreChip(score),
              Obx(
                () => _isSubscribed
                    ? _chip('已订阅', accent: Colors.red)
                    : _chip('未订阅'),
              ),
            ],
          ),
          if (overview != null && overview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                overview,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Obx(() {
        final appService = Get.find<AppService>();
        final canSubscribe = appService.canSubscribe;
        final canSearch = appService.canSearch;
        if (!canSubscribe && !canSearch) {
          return const SizedBox.shrink();
        }
        final isLoading = _mediaDetailController.subscribeLoadingState.value;
        final subscribed = _isSubscribed;
        final children = <Widget>[];
        if (canSubscribe) {
          children.add(
            Expanded(
              child: FilledButton.icon(
                onPressed: (isLoading || _submitting) ? null : _onSubscribeTap,
                icon: subscribed
                    ? const Icon(CupertinoIcons.heart_fill)
                    : const Icon(CupertinoIcons.heart),
                label: Text(subscribed ? '已订阅' : '订阅'),
                style: FilledButton.styleFrom(
                  backgroundColor: subscribed ? cs.error : cs.primary,
                  foregroundColor: subscribed ? cs.onError : cs.onSecondary,
                  disabledBackgroundColor: Colors.grey,
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ),
          );
        }
        if (canSearch) {
          if (children.isNotEmpty) {
            children.add(const SizedBox(width: 12));
          }
          children.add(
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.secondary,
                  foregroundColor: cs.onSecondary,
                  disabledBackgroundColor: Colors.grey,
                  disabledForegroundColor: Colors.white,
                ),
                onPressed: _loading ? null : () => _openSearch(context),
                icon: const Icon(CupertinoIcons.search),
                label: const Text('搜索资源'),
              ),
            ),
          );
        }
        return Row(children: children);
      }),
    );
  }

  Widget _chip(String text, {Color? accent}) {
    final color = accent ?? Colors.white;
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: accent == null ? 0.18 : 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _scoreChip(double score) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.star_fill, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeCard(BuildContext context, SeasonEpisodeDetail ep) {
    final theme = Theme.of(context);
    final stillUrl = ep.still_path != null && ep.still_path!.isNotEmpty
        ? ImageUtil.convertMediaSeasonImageUrl(ep.still_path!)
        : '';
    final episodeNumber = ep.episode_number ?? 0;
    final title = (ep.name?.trim().isNotEmpty ?? false)
        ? ep.name!.trim()
        : '未知标题';
    final overview = ep.overview?.trim() ?? '';
    final isMissing = _isEpisodeMissing(ep);
    final accent = isMissing
        ? const Color(0xFFFFB45C)
        : const Color(0xFF7DD3FC);

    return AppGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      blurSigma: 22,
      surfaceAlpha: 0.11,
      borderAlpha: 0.16,
      shadowAlpha: 0.22,
      accentColor: accent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _EpisodeCardGlowPainter(accent: accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final imageWidth = constraints.maxWidth < 360 ? 104.0 : 124.0;
                  const imageHeight = 74.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _episodeStill(
                            theme,
                            stillUrl,
                            episodeNumber,
                            imageWidth,
                            imageHeight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: [
                                    Obx(() {
                                      final app = Get.find<AppService>();
                                      if (!app
                                          .enableFetchMediaserverLibraryStatus
                                          .value) {
                                        return _libraryChipDisabled();
                                      }
                                      return isMissing
                                          ? _libraryChip(false)
                                          : _libraryChip(true);
                                    }),
                                    if (ep.air_date != null &&
                                        ep.air_date!.isNotEmpty)
                                      _episodeInfoChip(ep.air_date!),
                                    if (ep.runtime != null && ep.runtime! > 0)
                                      _episodeInfoChip('${ep.runtime} 分钟'),
                                    if (ep.vote_average != null &&
                                        ep.vote_average! > 0)
                                      _scoreChip(ep.vote_average!),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (overview.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          overview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            height: 1.38,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _episodeStill(
    ThemeData theme,
    String stillUrl,
    int episodeNumber,
    double width,
    double height,
  ) {
    final radius = BorderRadius.circular(14);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (stillUrl.isNotEmpty)
              CachedImage(
                imageUrl: stillUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorWidget: _episodePlaceholder(theme, width, height),
              )
            else
              _episodePlaceholder(theme, width, height),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 7,
              child: Container(
                constraints: const BoxConstraints(minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'E${episodeNumber.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _episodeInfoChip(String text) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.76),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  bool _isEpisodeMissing(SeasonEpisodeDetail ep) {
    final sn = _seasonNumber;
    final en = ep.episode_number;
    if (sn == null || en == null) return false;
    final list = _mediaDetailController.mediaNotExists;
    if (list.isEmpty) return false;
    MediaNotExists? notExists;
    for (final it in list) {
      if (it.season == sn) {
        notExists = it;
        break;
      }
    }
    if (notExists == null) return false;
    final episodes = notExists.episodes ?? const <int?>[];
    if (episodes.whereType<int>().contains(en)) return true;
    final start = notExists.start_episode ?? 0;
    final total = notExists.total_episode ?? 0;
    if (total > 0 && start > 0) {
      return en >= start && en <= total;
    }
    if (total > 0 && start <= 0) {
      return en <= total;
    }
    return false;
  }

  Widget _libraryChip(bool inLibrary) {
    final color = inLibrary ? const Color(0xFF86EFAC) : const Color(0xFFFFB45C);
    final text = inLibrary ? '已入库' : '未入库';
    final icon = inLibrary
        ? Icons.check_circle_rounded
        : Icons.info_outline_rounded;
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _libraryChipDisabled() {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_outlined, size: 14, color: Colors.white70),
          SizedBox(width: 4),
          Text(
            '入库状态关闭',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _episodePlaceholder(ThemeData theme, double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.13),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.tv_outlined,
        color: Colors.white.withValues(alpha: 0.48),
        size: 26,
      ),
    );
  }
}

class _EpisodeCardGlowPainter extends CustomPainter {
  const _EpisodeCardGlowPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final radius = Radius.circular(20);
    final rrect = RRect.fromRectAndRadius(bounds, radius);

    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.88, -0.76),
        radius: 1.08,
        colors: [
          Colors.white.withValues(alpha: 0.17),
          accent.withValues(alpha: 0.07),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(bounds);
    canvas.drawRRect(rrect, innerGlowPaint);

    final lowerGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.92, 0.88),
        radius: 0.9,
        colors: [accent.withValues(alpha: 0.13), Colors.transparent],
      ).createShader(bounds);
    canvas.drawRRect(rrect, lowerGlowPaint);

    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _EpisodeCardGlowPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
