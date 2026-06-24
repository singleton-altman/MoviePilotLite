import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/controllers/search_controller.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/search_result_filter_sheet.dart'
    show SearchResultFilterSectionConfig, SearchResultFilterSheet;
import 'package:moviepilot_mobile/modules/search_result/widgets/search_result_torrent_item.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchMediaResultPage extends GetView<SearchMediaController> {
  const SearchMediaResultPage({super.key});

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;
  static const int _skeletonCardCount = 4;
  static const double _immersiveHeaderHeight = 250;
  static const double _floatingBarHeight = 52;

  bool get immersive =>
      (controller.prefillBackdrop ?? '').trim().isNotEmpty &&
      (controller.prefillTitle ?? '').trim().isNotEmpty;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: immersive ? AppTheme.darkBackgroundColor : null,
      appBar: immersive ? null : _buildNavigationBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      body: _buildBody(context, immersive: immersive),
    );
  }

  /// 构建 SSE 进度指示器
  Widget _buildProgressIndicator(BuildContext context) {
    return Obx(() {
      if (!controller.isProgressActive.value) {
        return const SizedBox.shrink();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 线性进度条
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: controller.searchProgress.value,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value > 0 ? value : null,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(controller.progressStatus.value),
                ),
                minHeight: 3,
              );
            },
          ),
          // 进度信息卡片
          if (controller.progressMessage.value.isNotEmpty)
            _buildProgressInfoCard(context),
        ],
      );
    });
  }

  /// 构建进度信息卡片
  Widget _buildProgressInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(controller.progressStatus.value),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.progressMessage.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (controller.progressSource.value.isNotEmpty)
                  Text(
                    controller.progressSource.value,
                    style: TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            controller.formattedProgress,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 根据状态获取进度条颜色
  Color _getProgressColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'failed':
      case 'error':
        return Colors.red;
      case 'searching':
      default:
        return Colors.blue;
    }
  }

  Widget _buildBody(BuildContext context, {required bool immersive}) {
    return Obx(() {
      if (controller.isClosed) return const SizedBox.shrink();
      final items = controller.visibleItems;
      final isLoading = controller.isLoading.value;
      final errorText = controller.errorText.value;

      final showSkeleton = isLoading && controller.items.isEmpty;
      return CustomScrollView(
        slivers: [
          if (immersive)
            _buildImmersiveHeader(context)
          else
            const SliverToBoxAdapter(child: SizedBox.shrink()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: 15,
            ),
            sliver: SliverToBoxAdapter(
              child: immersive
                  ? _buildSearchMetaChips(context)
                  : _buildSearchAndToolbar(context),
            ),
          ),
          if (errorText != null)
            SliverToBoxAdapter(
              child: _buildErrorState(context, errorText, immersive: immersive),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
              ),
              sliver: Skeletonizer.sliver(
                enabled: showSkeleton,
                child: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: _cardSpacing),
                      child: _buildListCard(context, items[index]),
                    ),
                    childCount: items.length,
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: immersive
                  ? _floatingBarHeight + 32
                  : _bottomSpacer(context),
            ),
          ),
        ],
      );
    });
  }

  SliverAppBar _buildImmersiveHeader(BuildContext context) {
    final backdrop = (controller.prefillBackdrop ?? '').trim();
    return SliverAppBar(
      pinned: true,
      expandedHeight: _immersiveHeaderHeight,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: Get.back,
      ),
      // title: Text(title, style: const TextStyle(color: Colors.white)),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedImage(
              imageUrl: ImageUtil.convertCacheImageUrl(backdrop),
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    AppTheme.darkBackgroundColor,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBar(BuildContext context) {
    return Obx(() {
      final inSearching = controller.isProgressActive.value;
      final child = inSearching
          ? _buildProgressIndicator(context)
          : Row(
              children: [
                _buildFloatingFilterButton(context),
                const SizedBox(width: 8),
                Expanded(child: _buildFakeSearchBar(context)),
                const SizedBox(width: 8),
                _buildFloatingSortButton(context),
              ],
            );
      final pill = Container(
        height: _floatingBarHeight,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        child: child,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: pill,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFloatingFilterButton(BuildContext context) {
    return Obx(() {
      final has = controller.hasActiveFilters;
      final color = has
          ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
          : CupertinoDynamicColor.resolve(Colors.white, context);
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: () => _openFilterSheet(context),
        child: Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: color),
      );
    });
  }

  Widget _buildFloatingSortButton(BuildContext context) {
    return Obx(
      () => SortPullDownWidget<SearchResultSortKey>(
        isAscending: controller.sortDirection.value == SortDirection.asc,
        currentValue: controller.sortKey.value,
        options: SearchResultSortKey.values,
        labelBuilder: _sortLabel,
        onDirectionChanged: (asc) {
          final want = asc ? SortDirection.asc : SortDirection.desc;
          if (controller.sortDirection.value != want) {
            controller.toggleSortDirection();
          }
        },
        onValueChanged: controller.updateSortKey,
      ),
    );
  }

  Widget _buildFakeSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => _openKeywordSheet(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 18,
              color: CupertinoDynamicColor.resolve(Colors.white, context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => Text(
                  controller.keyword.value.isEmpty
                      ? '筛选标题、描述、站点…'
                      : controller.keyword.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openKeywordSheet(BuildContext context) async {
    final controllerText = TextEditingController(
      text: controller.keyword.value,
    );
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemBackground,
                ctx,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: CupertinoSearchTextField(
              controller: controllerText,
              autofocus: true,
              placeholder: '筛选标题、描述、站点…',
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ),
        );
      },
    );
    controllerText.dispose();
    if (submitted == null) return;
    controller.updateKeyword(submitted);
  }

  static String _sortLabel(SearchResultSortKey key) {
    switch (key) {
      case SearchResultSortKey.defaultSort:
        return '默认';
      case SearchResultSortKey.site:
        return '站点';
      case SearchResultSortKey.size:
        return '大小';
      case SearchResultSortKey.seeders:
        return '做种数';
      case SearchResultSortKey.pubdate:
        return '发布时间';
    }
  }

  AppBar _buildNavigationBar(BuildContext context) {
    return AppBar(title: const Text('搜索结果'), centerTitle: false);
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    bool valueOnly = false,
  }) {
    final text = valueOnly ? label : (value.isEmpty ? label : '$label: $value');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color.withValues(alpha: 0.95),
        ),
      ),
    );
  }

  Widget _buildSearchMetaChips(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              context,
              label: '媒体',
              value: controller.mediaSearchKey,
              color: Theme.of(context).colorScheme.primary,
            ),
            _buildFilterChip(
              context,
              label: '搜索: ${controller.area == 'title' ? '标题' : 'IMDB'}',
              value: '',
              color: const Color(0xFF34C759),
              valueOnly: true,
            ),
            if (controller.sites.isNotEmpty)
              _buildFilterChip(
                context,
                label: '站点',
                value: '${controller.sites.length} 个',
                color: const Color(0xFFFF9500),
              ),
            if (controller.year.isNotEmpty)
              _buildFilterChip(
                context,
                label: '年份',
                value: controller.year,
                color: const Color(0xFFAF52DE),
              ),
            if (controller.season != null && controller.season!.isNotEmpty)
              _buildFilterChip(
                context,
                label: '季',
                value: controller.season!,
                color: const Color(0xFF5AC8FA),
              ),
            _buildFilterChip(
              context,
              label: '类型',
              value: controller.mtype,
              color: const Color(0xFF8E8E93),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndToolbar(BuildContext context) {
    return Section(
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              context,
              label: '媒体',
              value: controller.mediaSearchKey,
              color: Theme.of(context).colorScheme.primary,
            ),
            _buildFilterChip(
              context,
              label: controller.area == 'title' ? '标题' : 'IMDB',
              value: '',
              color: const Color(0xFF34C759),
              valueOnly: true,
            ),
            if (controller.sites.isNotEmpty)
              _buildFilterChip(
                context,
                label: '站点',
                value: '${controller.sites.length} 个',
                color: const Color(0xFFFF9500),
              ),
            if (controller.year.isNotEmpty)
              _buildFilterChip(
                context,
                label: '年份',
                value: controller.year,
                color: const Color(0xFFAF52DE),
              ),
            if (controller.season != null && controller.season!.isNotEmpty)
              _buildFilterChip(
                context,
                label: '季',
                value: controller.season!,
                color: const Color(0xFF5AC8FA),
              ),
            _buildFilterChip(
              context,
              label: '类型',
              value: controller.mtype,
              color: const Color(0xFF8E8E93),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, SearchResultItem item) {
    return SearchResultTorrentItem(item: item, immersive: immersive);
  }

  Widget _buildErrorState(
    BuildContext context,
    String message, {
    required bool immersive,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: immersive ? Colors.white70 : null,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: controller.performSearch,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  static const Map<SearchResultFilterType, String> _filterSectionTitles = {
    SearchResultFilterType.site: '站点',
    SearchResultFilterType.season: '季',
    SearchResultFilterType.promotion: '促销状态',
    SearchResultFilterType.videoEncode: '视频编码',
    SearchResultFilterType.quality: '质量',
    SearchResultFilterType.resolution: '分辨率',
    SearchResultFilterType.team: '制作组',
  };

  List<SearchResultFilterSectionConfig> _buildFilterSections() {
    return [
      SearchResultFilterSectionConfig(
        filterType: SearchResultFilterType.site,
        title: _filterSectionTitles[SearchResultFilterType.site]!,
        options: controller.availableSites,
        selected: controller.selectedSites.toSet(),
        onToggle: (v) =>
            controller.toggleFilter(SearchResultFilterType.site, v),
      ),
      SearchResultFilterSectionConfig(
        filterType: SearchResultFilterType.season,
        title: _filterSectionTitles[SearchResultFilterType.season]!,
        options: controller.availableSeasons,
        selected: controller.selectedSeasons.toSet(),
        onToggle: (v) =>
            controller.toggleFilter(SearchResultFilterType.season, v),
      ),
      SearchResultFilterSectionConfig(
        filterType: SearchResultFilterType.promotion,
        title: _filterSectionTitles[SearchResultFilterType.promotion]!,
        options: controller.availablePromotions,
        selected: controller.selectedPromotions.toSet(),
        onToggle: (v) =>
            controller.toggleFilter(SearchResultFilterType.promotion, v),
      ),
      SearchResultFilterSectionConfig(
        filterType: SearchResultFilterType.videoEncode,
        title: _filterSectionTitles[SearchResultFilterType.videoEncode]!,
        options: controller.availableVideoEncodes,
        selected: controller.selectedVideoEncodes.toSet(),
        onToggle: (v) =>
            controller.toggleFilter(SearchResultFilterType.videoEncode, v),
      ),
      SearchResultFilterSectionConfig(
        filterType: SearchResultFilterType.quality,
        title: _filterSectionTitles[SearchResultFilterType.quality]!,
        options: controller.availableQualities,
        selected: controller.selectedQualities.toSet(),
        onToggle: (v) =>
            controller.toggleFilter(SearchResultFilterType.quality, v),
      ),
      SearchResultFilterSectionConfig(
        filterType: SearchResultFilterType.resolution,
        title: _filterSectionTitles[SearchResultFilterType.resolution]!,
        options: controller.availableResolutions,
        selected: controller.selectedResolutions.toSet(),
        onToggle: (v) =>
            controller.toggleFilter(SearchResultFilterType.resolution, v),
      ),
      SearchResultFilterSectionConfig(
        filterType: SearchResultFilterType.team,
        title: _filterSectionTitles[SearchResultFilterType.team]!,
        options: controller.availableTeams,
        selected: controller.selectedTeams.toSet(),
        onToggle: (v) =>
            controller.toggleFilter(SearchResultFilterType.team, v),
      ),
    ];
  }

  Widget _buildEmptyState(BuildContext context, {required bool immersive}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        '暂无搜索结果',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: immersive ? Colors.white70 : null,
        ),
      ),
    );
  }

  double _bottomSpacer(BuildContext context) {
    return MediaQuery.of(context).padding.bottom + 70;
  }

  Future<void> _openFilterSheet(
    BuildContext context, [
    SearchResultFilterType? filterMode,
  ]) {
    final sheetTitle = '筛选';
    final clearLabel = '清空';
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.78,
          child: Obx(
            () => SearchResultFilterSheet(
              title: sheetTitle,
              clearLabel: clearLabel,
              onClear: controller.clearFilters,
              sections: _buildFilterSections(),
              filterMode: filterMode,
            ),
          ),
        );
      },
    );
  }
}
