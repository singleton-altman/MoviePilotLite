import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 推荐媒体组件：横幅轮播展示当前来源的前几条推荐，对应 Web 端仪表板的「推荐媒体」卡片
class MediaRecommendWidget extends StatefulWidget {
  const MediaRecommendWidget({super.key});

  @override
  State<MediaRecommendWidget> createState() => _MediaRecommendWidgetState();
}

class _MediaRecommendWidgetState extends State<MediaRecommendWidget> {
  static const Duration _autoplayInterval = Duration(seconds: 8);
  static const Duration _slideDuration = Duration(milliseconds: 460);

  final DashboardController _controller = Get.find<DashboardController>();
  final PageController _pageController = PageController();
  Timer? _autoplayTimer;
  Worker? _itemsWorker;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _restartAutoplay();
    // 切换来源后条目整体替换，当前页索引可能越界，回到首页重新开始轮播
    _itemsWorker = ever<List<RecommendApiItem>>(_controller.recommendItems, (
      items,
    ) {
      if (!mounted || _activeIndex < items.length) return;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      setState(() => _activeIndex = 0);
      _restartAutoplay();
    });
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _itemsWorker?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _restartAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = Timer.periodic(_autoplayInterval, (_) {
      final count = _controller.recommendItems.length;
      if (count < 2 || !_pageController.hasClients) return;
      final next = (_activeIndex + 1) % count;
      _pageController.animateToPage(
        next,
        duration: _slideDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);

    return Obx(() {
      final items = _controller.recommendItems;
      final loading = _controller.isRecommendLoading.value;
      final error = _controller.recommendError.value;
      final sourceKey = _controller.recommendSourceKey.value;
      final source = DashboardController.recommendSources.firstWhere(
        (candidate) => candidate.key == sourceKey,
        orElse: () => DashboardController.recommendSources.first,
      );
      final activeIndex = _activeIndex < items.length ? _activeIndex : 0;

      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            border: Border.all(color: palette.tileBorder),
            borderRadius: BorderRadius.circular(22),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (items.isEmpty)
                  _buildPlaceholder(palette, loading: loading, error: error)
                else
                  PageView.builder(
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: (index) {
                      setState(() => _activeIndex = index);
                      _restartAutoplay();
                    },
                    itemBuilder: (context, index) => _RecommendSlide(
                      item: items[index],
                      onTap: () => _openDetail(items[index]),
                    ),
                  ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 12,
                  child: Row(
                    children: [
                      _buildSourceChip(source),
                      const Spacer(),
                      if (items.length > 1)
                        _buildDots(items.length, activeIndex),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSourceChip(DashboardRecommendSource source) {
    return PopupMenuButton<String>(
      tooltip: '选择推荐媒体来源',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: _controller.selectRecommendSource,
      itemBuilder: (context) => [
        for (final candidate in DashboardController.recommendSources)
          PopupMenuItem<String>(
            value: candidate.key,
            height: 40,
            child: Row(
              children: [
                Icon(
                  candidate.key == source.key
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  size: 16,
                  color: candidate.key == source.key
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 10),
                Text(candidate.name, style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.sparkles, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              source.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 10,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots(int count, int activeIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
              width: index == activeIndex ? 14 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: index == activeIndex ? 0.95 : 0.45,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(
    DashboardPaletteData palette, {
    required bool loading,
    required String? error,
  }) {
    if (loading) {
      return Skeletonizer(
        child: Container(
          color: palette.surfaceAlt,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone(
                width: 120,
                height: 20,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 10),
              Bone(
                width: double.infinity,
                height: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 6),
              Bone(
                width: 180,
                height: 12,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            error == null
                ? CupertinoIcons.film
                : CupertinoIcons.exclamationmark_circle,
            size: 26,
            color: palette.mutedText,
          ),
          const SizedBox(height: 8),
          Text(
            error ?? '当前来源暂无推荐媒体',
            style: TextStyle(fontSize: 12.5, color: palette.mutedText),
          ),
          if (error != null) ...[
            const SizedBox(height: 6),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              onPressed: () => _controller.loadRecommendMedia(force: true),
              child: Text(
                '重试',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openDetail(RecommendApiItem item) {
    final path = HttpPathBuilderUtil.buildMediaPath(item);
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = _RecommendSlide.titleOf(item);
    final year = item.year?.trim() ?? '';
    final type = item.type?.trim() ?? '';
    Get.toNamed(
      '/media-detail',
      parameters: {
        'path': path,
        if (title.isNotEmpty) 'title': title,
        if (year.isNotEmpty) 'year': year,
        if (type.isNotEmpty) 'type_name': type,
      },
    );
  }
}

class _RecommendSlide extends StatelessWidget {
  const _RecommendSlide({required this.item, required this.onTap});

  final RecommendApiItem item;
  final VoidCallback onTap;

  static String titleOf(RecommendApiItem item) {
    for (final candidate in [
      item.title,
      item.en_title,
      item.original_title,
      item.original_name,
    ]) {
      final text = candidate?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final image = (item.backdrop_path?.trim().isNotEmpty == true)
        ? item.backdrop_path!.trim()
        : (item.poster_path?.trim() ?? '');
    final meta = _buildMeta();
    final overview = item.overview?.trim() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.isEmpty)
            Container(color: palette.surfaceAlt)
          else
            CachedImage(imageUrl: image, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleOf(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
                if (overview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    overview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildMeta() {
    final parts = <String>[];
    final year = item.year?.trim() ?? '';
    if (year.isNotEmpty) parts.add(year);
    final type = item.type?.trim() ?? '';
    if (type.isNotEmpty) parts.add(type);
    final vote = item.vote_average ?? 0;
    if (vote > 0) parts.add('★ ${vote.toStringAsFixed(1)}');
    return parts.join(' · ');
  }
}
