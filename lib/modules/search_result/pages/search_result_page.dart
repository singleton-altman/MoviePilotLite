import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/search_result_filter_sheet.dart'
    show
        SearchResultFilterSectionConfig,
        SearchResultFilterSheet,
        chipColorForType;
import 'package:moviepilot_mobile/modules/search_result/widgets/search_result_torrent_item.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchResultPage extends GetView<SearchResultController> {
  const SearchResultPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;
  static const int _skeletonCardCount = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildNavigationBar(context),
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
                vertical: 15,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildSearchAndToolbar(context),
              ),
            ),
            if (showSkeleton)
              _buildSkeletonSliver(context)
            else if (errorText != null)
              SliverToBoxAdapter(child: _buildErrorState(context, errorText))
            else if (items.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState(context))
            else
              _buildResults(context, items, viewMode),
            SliverToBoxAdapter(child: SizedBox(height: _bottomSpacer(context))),
          ],
        );
      }),
    );
  }

  AppBar _buildNavigationBar(BuildContext context) {
    return AppBar(title: const Text('搜索结果'), centerTitle: false);
  }

  Widget _buildSearchAndToolbar(BuildContext context) {
    return Section(
      child: Column(
        children: [
          CupertinoSearchTextField(
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill,
              borderRadius: BorderRadius.circular(24),
            ),
            onSubmitted: controller.updateKeyword,
            placeholder: '搜索标题、描述、站点…',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          ),
          const SizedBox(height: 10),
          _buildToolbar(context),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Obx(
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
          ),
          const SizedBox(width: 6),
          Expanded(child: _buildFilterBar(context)),
          const SizedBox(width: 6),
          _buildFilterButton(context),
        ],
      ),
    );
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

  Widget _buildFilterButton(BuildContext context) {
    return Obx(() {
      final hasFilters = controller.hasActiveFilters;
      final accent = context.primaryColor;
      return CupertinoButton(
        padding: const EdgeInsets.all(6),
        minSize: 0,
        pressedOpacity: 0.7,
        onPressed: () => _openFilterSheet(context),
        child: _buildLightChip(
          context,
          isActive: hasFilters,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                CupertinoIcons.slider_horizontal_3,
                size: 16,
                color: hasFilters
                    ? accent
                    : CupertinoDynamicColor.resolve(
                        CupertinoColors.tertiaryLabel,
                        context,
                      ),
              ),
              if (hasFilters)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLightChip(
    BuildContext context, {
    required Widget child,
    bool isActive = false,
  }) {
    final baseColor = CupertinoDynamicColor.resolve(
      CupertinoColors.tertiarySystemFill,
      context,
    );
    final activeTint = context.primaryColor.withOpacity(isActive ? 0.2 : 0);
    final bgColor = Color.alphaBlend(activeTint, baseColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: context.primaryColor.withOpacity(0.3), width: 1)
            : null,
      ),
      child: child,
    );
  }

  Widget _buildCountBadge(BuildContext context, int count, [Color? color]) {
    final c = color ?? context.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: CupertinoColors.white,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
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

  Widget _buildFilterBar(BuildContext context) {
    return Obx(() {
      final items = [
        _FilterChipItem(
          filterType: SearchResultFilterType.site,
          label: _filterSectionTitles[SearchResultFilterType.site]!,
          icon: CupertinoIcons.cube_box,
          count: controller.selectedSites.length,
        ),
        _FilterChipItem(
          filterType: SearchResultFilterType.season,
          label: _filterSectionTitles[SearchResultFilterType.season]!,
          icon: CupertinoIcons.tv,
          count: controller.selectedSeasons.length,
        ),
        _FilterChipItem(
          filterType: SearchResultFilterType.promotion,
          label: _filterSectionTitles[SearchResultFilterType.promotion]!,
          icon: CupertinoIcons.tag,
          count: controller.selectedPromotions.length,
        ),
        _FilterChipItem(
          filterType: SearchResultFilterType.videoEncode,
          label: _filterSectionTitles[SearchResultFilterType.videoEncode]!,
          icon: CupertinoIcons.film,
          count: controller.selectedVideoEncodes.length,
        ),
        _FilterChipItem(
          filterType: SearchResultFilterType.quality,
          label: _filterSectionTitles[SearchResultFilterType.quality]!,
          icon: CupertinoIcons.star,
          count: controller.selectedQualities.length,
        ),
        _FilterChipItem(
          filterType: SearchResultFilterType.resolution,
          label: _filterSectionTitles[SearchResultFilterType.resolution]!,
          icon: CupertinoIcons.rectangle,
          count: controller.selectedResolutions.length,
        ),
        _FilterChipItem(
          filterType: SearchResultFilterType.team,
          label: _filterSectionTitles[SearchResultFilterType.team]!,
          icon: CupertinoIcons.person_2,
          count: controller.selectedTeams.length,
        ),
      ];

      return SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildFilterPill(context, item);
          },
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemCount: items.length,
        ),
      );
    });
  }

  Widget _buildFilterPill(BuildContext context, _FilterChipItem item) {
    final hasCount = item.count > 0;
    final chipColor = chipColorForType(item.filterType, selected: hasCount);
    final bgColor = hasCount ? chipColor : chipColor.withValues(alpha: 0.12);
    final borderColor = hasCount
        ? chipColor
        : chipColor.withValues(alpha: 0.35);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      pressedOpacity: 0.7,
      onPressed: () => _openFilterSheet(context, item.filterType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 14,
              color: hasCount ? Colors.white : chipColor,
            ),
            const SizedBox(width: 4),
            Text(
              item.label,
              style: TextStyle(
                color: hasCount ? Colors.white : chipColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasCount) ...[
              const SizedBox(width: 4),
              _buildCountBadge(context, item.count, chipColor),
            ],
          ],
        ),
      ),
    );
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

  double _bottomSpacer(BuildContext context) {
    return MediaQuery.of(context).padding.bottom + 70;
  }

  Future<void> _openFilterSheet(
    BuildContext context, [
    SearchResultFilterType? filterMode,
  ]) {
    final sheetTitle = '筛选';
    final clearLabel = '清空';
    return showCupertinoModalBottomSheet<void>(
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
