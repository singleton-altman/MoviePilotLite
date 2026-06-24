import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/search_result_filter_sheet.dart'
    show SearchResultFilterSectionConfig, SearchResultFilterSheet;
import 'package:moviepilot_mobile/modules/search_result/widgets/search_result_torrent_item.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchResultPage extends GetView<SearchResultController> {
  const SearchResultPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;
  static const int _skeletonCardCount = 4;
  static const double _floatingBarHeight = 52;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildNavigationBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      body: Obx(() {
        if (controller.isClosed) return const SizedBox.shrink();
        final items = controller.visibleItems;
        final isLoading = controller.isLoading.value;
        final errorText = controller.errorText.value;
        final viewMode = controller.viewMode.value;

        final showSkeleton = isLoading && items.isEmpty;
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            if (showSkeleton)
              _buildSkeletonSliver(context)
            else if (errorText != null)
              SliverToBoxAdapter(child: _buildErrorState(context, errorText))
            else if (items.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState(context))
            else
              _buildResults(context, items, viewMode),
            const SliverToBoxAdapter(
              child: SizedBox(height: _floatingBarHeight + 32),
            ),
          ],
        );
      }),
    );
  }

  AppBar _buildNavigationBar(BuildContext context) {
    return AppBar(title: const Text('搜索结果'), centerTitle: false);
  }

  Widget _buildFloatingBar(BuildContext context) {
    final theme = Theme.of(context);
    final child = Row(
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: theme.colorScheme.surface.withValues(alpha: 0.2),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
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
  }

  Widget _buildFloatingFilterButton(BuildContext context) {
    return Obx(() {
      final hasFilters = controller.hasActiveFilters;
      final color = hasFilters
          ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
          : CupertinoDynamicColor.resolve(
              CupertinoColors.secondaryLabel,
              context,
            );
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
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
    final theme = Theme.of(context);
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
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

  Widget _buildResults(
    BuildContext context,
    List<SearchResultItem> items,
    SearchResultViewMode mode,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: _cardSpacing),
            child: _buildListCard(context, items[index]),
          ),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildSkeletonSliver(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      sliver: Skeletonizer.sliver(
        enabled: true,
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: _cardSpacing),
              child: _buildSkeletonCard(context),
            ),
            childCount: _skeletonCardCount,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Bone(height: 20, borderRadius: BorderRadius.circular(6)),
              ),
              const SizedBox(width: 8),
              Bone(
                width: 64,
                height: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Bone(
                width: 100,
                height: 14,
                borderRadius: BorderRadius.circular(6),
              ),
              const Spacer(),
              Bone(
                width: 40,
                height: 14,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Bone.multiText(lines: 2, width: double.infinity),
          const SizedBox(height: 12),
          Row(
            children: [
              Bone(
                width: 70,
                height: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(width: 6),
              Bone(
                width: 60,
                height: 12,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Bone(
                width: 80,
                height: 18,
                borderRadius: BorderRadius.circular(8),
              ),
              const Spacer(),
              Bone.icon(size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context, SearchResultItem item) {
    return SearchResultTorrentItem(item: item);
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: controller.loadLatest,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text('暂无搜索结果', style: Theme.of(context).textTheme.bodyMedium),
    );
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

// ignore: unused_element
class _FilterChipItem {
  const _FilterChipItem({
    required this.filterType,
    required this.label,
    required this.icon,
    required this.count,
  });

  final SearchResultFilterType filterType;
  final String label;
  final IconData icon;
  final int count;
}
