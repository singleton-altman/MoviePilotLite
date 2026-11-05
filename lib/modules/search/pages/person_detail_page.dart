import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/search/controllers/person_detail_controller.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';

class PersonDetailPage extends GetView<PersonDetailController> {
  const PersonDetailPage({super.key});

  static const double _listPosterWidth = 78;
  static const double _listPosterHeight = 110;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: Obx(() {
        final isLoading = controller.isLoading.value;
        final error = controller.error.value;
        if (isLoading) {
          return Center(
            child: AppLoading(
              message: '正在加载演员详情',
              messageStyle: TextStyle(
                color: palette.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        if (error != null) {
          return _ErrorState(message: error, onBack: () => Get.back());
        }

        final backdropUrl = (controller.avatarUrl.value ?? '').trim();
        return Stack(
          fit: StackFit.expand,
          children: [
            if (backdropUrl.isNotEmpty)
              CachedImage(imageUrl: backdropUrl, fit: BoxFit.cover)
            else
              ColoredBox(color: palette.pageBackground),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.pageBackground.withValues(alpha: 0.18),
                    palette.pageBackground.withValues(alpha: 0.42),
                    palette.pageBackground.withValues(alpha: 0.82),
                    palette.pageBackground,
                  ],
                  stops: const [0, 0.28, 0.58, 0.82],
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _PersonIntro(controller: controller)),
                SliverToBoxAdapter(child: _WorksSectionHeader(controller: controller)),
                if (controller.works.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyWorks(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    sliver: SliverList.separated(
                      itemCount: controller.works.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final work = controller.works[index];
                        return _WorkListItem(
                          key: ValueKey(
                            '${work.tmdb_id ?? work.douban_id ?? work.media_id}_$index',
                          ),
                          item: work,
                          posterWidth: _listPosterWidth,
                          posterHeight: _listPosterHeight,
                          onTap: () => _openWorkDetail(work),
                        );
                      },
                    ),
                  ),
                if (controller.works.isNotEmpty)
                  Obx(
                    () => SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          MediaQuery.paddingOf(context).bottom + 24,
                        ),
                        child: LoadMoreFooter(
                          hasMore: controller.worksHasMore.value,
                          isLoading: controller.isLoadingMoreWorks.value,
                          hasItems: controller.works.isNotEmpty,
                          onLoadMore: controller.loadMoreWorks,
                          endLabel: '没有更多作品了',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }

  void _openWorkDetail(RecommendApiItem item) {
    final path = _buildMediaPath(item);
    if (path == null) return;
    HapticFeedback.selectionClick();
    final title = _bestTitle(item);
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
    };
    Get.toNamed('/media-detail', parameters: params);
  }

  String? _bestTitle(RecommendApiItem item) {
    final title = item.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final enTitle = item.en_title?.trim();
    if (enTitle != null && enTitle.isNotEmpty) return enTitle;
    final original = (item.original_title ?? item.original_name)?.trim();
    if (original != null && original.isNotEmpty) return original;
    return null;
  }

  String? _buildMediaPath(RecommendApiItem item) {
    final prefix = item.mediaid_prefix;
    final mediaId = item.media_id;
    if (prefix != null &&
        prefix.isNotEmpty &&
        mediaId != null &&
        mediaId.isNotEmpty) {
      return '$prefix:$mediaId';
    }
    final tmdbId = item.tmdb_id;
    if (tmdbId != null && tmdbId.isNotEmpty) return 'tmdb:$tmdbId';
    final doubanId = item.douban_id;
    if (doubanId != null && doubanId.isNotEmpty) return 'douban:$doubanId';
    final bangumiId = item.bangumi_id;
    if (bangumiId != null && bangumiId.isNotEmpty) return 'bangumi:$bangumiId';
    return null;
  }
}

class _PersonIntro extends StatelessWidget {
  const _PersonIntro({required this.controller});

  final PersonDetailController controller;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final title = (controller.name.value ?? '').trim().isEmpty
        ? '未知演员'
        : controller.name.value!.trim();
    final bio = (controller.biography.value ?? '').trim();
    final aliases = controller.alsoKnownAs
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();
    final meta = _metaLine(
      gender: controller.gender.value,
      source: controller.sourceLabel.value,
      aliases: aliases,
    );
    final worksCount = controller.works.length;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _CircleIconButton(
                  icon: CupertinoIcons.chevron_left,
                  onPressed: () => Get.back(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                height: 1.15,
                color: palette.titleText,
                shadows: [
                  Shadow(
                    color: palette.pageBackground.withValues(alpha: 0.7),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.bodyText.withValues(alpha: 0.82),
                ),
              ),
            ],
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: palette.mutedText,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: '作品',
                  value: '$worksCount',
                  color: palette.primary,
                ),
                if ((controller.sourceLabel.value ?? '').trim().isNotEmpty)
                  _MetricChip(
                    label: '来源',
                    value: controller.sourceLabel.value!.trim().toUpperCase(),
                    color: palette.coolAccent,
                  ),
                if (aliases.isNotEmpty)
                  _MetricChip(
                    label: '别名',
                    value: '${aliases.length}',
                    color: palette.successAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _metaLine({
    required int? gender,
    required String? source,
    required List<String> aliases,
  }) {
    final parts = <String>[
      if (_genderLabel(gender) != null) _genderLabel(gender)!,
      if ((source ?? '').trim().isNotEmpty) source!.trim().toUpperCase(),
      if (aliases.isNotEmpty) aliases.first,
    ];
    return parts.join(' · ');
  }

  String? _genderLabel(int? gender) {
    return switch (gender) {
      1 => '女',
      2 => '男',
      3 => '非二元',
      _ => null,
    };
  }
}

class _WorksSectionHeader extends StatelessWidget {
  const _WorksSectionHeader({required this.controller});

  final PersonDetailController controller;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final count = controller.works.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 16,
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '作品列表',
            style: TextStyle(
              color: palette.titleText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkListItem extends StatelessWidget {
  const _WorkListItem({
    super.key,
    required this.item,
    required this.posterWidth,
    required this.posterHeight,
    required this.onTap,
  });

  final RecommendApiItem item;
  final double posterWidth;
  final double posterHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final title = _titleOf(item);
    final year = _yearOf(item);
    final type = (item.type ?? '').trim();
    final vote = item.vote_average;
    final overview = (item.overview ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: palette.surface.withValues(alpha: palette.isDark ? 0.78 : 0.90),
            border: Border.all(color: palette.tileBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Poster(
                item: item,
                width: posterWidth,
                height: posterHeight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: posterHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.titleText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (type.isNotEmpty)
                            _MetaPill(label: type, color: palette.primary),
                          if (year.isNotEmpty)
                            Text(
                              year,
                              style: TextStyle(
                                color: palette.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (vote != null && vote > 0)
                            _MetaPill(
                              label: vote.toStringAsFixed(1),
                              color: palette.warningAccent,
                              icon: CupertinoIcons.star_fill,
                            ),
                        ],
                      ),
                      if (overview.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            overview,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.mutedText,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(top: (posterHeight - 18) / 2),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: palette.faintText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleOf(RecommendApiItem item) {
    final title = item.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final en = item.en_title?.trim();
    if (en != null && en.isNotEmpty) return en;
    final original = (item.original_title ?? item.original_name)?.trim();
    if (original != null && original.isNotEmpty) return original;
    return '未命名作品';
  }

  String _yearOf(RecommendApiItem item) {
    final year = item.year?.trim();
    if (year != null && year.isNotEmpty) return year;
    final release = (item.release_date ?? item.first_air_date)?.trim();
    if (release != null && release.length >= 4) return release.substring(0, 4);
    return '';
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.item,
    required this.width,
    required this.height,
  });

  final RecommendApiItem item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final raw = item.poster_path ?? item.backdrop_path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: raw != null && raw.isNotEmpty
          ? CachedImage(
              imageUrl: ImageUtil.convertCacheImageUrl(raw),
              width: width,
              height: height,
              fit: BoxFit.cover,
            )
          : Container(
              width: width,
              height: height,
              color: palette.surfaceAlt,
              child: Icon(CupertinoIcons.film, color: palette.faintText),
            ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.36),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _EmptyWorks extends StatelessWidget {
  const _EmptyWorks();

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.film, size: 36, color: palette.faintText),
          const SizedBox(height: 12),
          Text(
            '暂无作品',
            style: TextStyle(
              color: palette.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 40,
              color: palette.mutedText,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.mutedText),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onBack, child: const Text('返回')),
          ],
        ),
      ),
    );
  }
}
