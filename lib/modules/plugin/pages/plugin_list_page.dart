import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_list_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/defines/plugin_list_filter_defines.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/pages/plugin_info_sheet.dart';
import 'package:moviepilot_mobile/modules/plugin/widgets/plugin_item_card.dart';
import 'package:moviepilot_mobile/modules/plugin/widgets/plugin_center_widgets.dart';
import 'package:moviepilot_mobile/modules/plugin/widgets/plugin_list_filter_sheet.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

class PluginListPage extends GetView<PluginListController> {
  const PluginListPage({super.key});

  static const double _wideBreakpoint = 500;
  static const double _itemWidth = 250;
  static const double _horizontalPadding = 16;
  static const double _gridSpacing = 12;
  static const double _floatingBarHeight = 52;

  static const Map<PluginListFilterType, String> _filterSectionTitles = {
    PluginListFilterType.author: '作者',
    PluginListFilterType.label: '标签',
    PluginListFilterType.repo: '仓库',
  };

  double _bottomInset(BuildContext context) {
    return _floatingBarHeight + 24 + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.find<AppService>().canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('插件列表'), centerTitle: false),
        body: const Center(
          child: Text(
            '当前帐号无管理权限',
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '插件市场',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          Obx(() {
            if (!controller.isLoading.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Stack(
          children: [
            const Positioned.fill(child: PluginCenterBackdrop()),
            CustomScrollView(
              controller: controller.scrollController,
              cacheExtent: 200,
              slivers: [
                SliverToBoxAdapter(child: _buildOverviewHeader(context)),
                _buildSliverContent(context),
                SliverToBoxAdapter(
                  child: SizedBox(height: _bottomInset(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewHeader(BuildContext context) {
    return Obx(() {
      final items = controller.items;
      return PluginOverviewHeader(
        title: '探索扩展能力',
        count: items.length,
        icon: Icons.storefront_rounded,
      );
    });
  }

  Widget _buildFloatingBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(
              height: _floatingBarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: cs.surface.withValues(alpha: 0.55),
              child: Row(
                children: [
                  _buildFloatingFilterButton(context),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFakeSearchBar(context)),
                  const SizedBox(width: 8),
                  _buildFloatingSortButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingFilterButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final has = controller.hasActiveFilters;
      final color = has ? cs.primary : cs.onSurface.withValues(alpha: 0.75);
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () => _openFilterSheet(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(CupertinoIcons.slider_horizontal_3, size: 22, color: color),
            if (has)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 1),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFloatingSortButton(BuildContext context) {
    return Obx(
      () => SortPullDownWidget<PluginListSortKey>(
        isAscending: controller.sortAscending.value,
        currentValue: controller.sortKey.value,
        options: PluginListSortKey.values,
        labelBuilder: _sortLabel,
        onDirectionChanged: (asc) {
          if (controller.sortAscending.value != asc) {
            controller.toggleSortDirection();
          }
        },
        onValueChanged: controller.updateSortKey,
      ),
    );
  }

  Widget _buildFakeSearchBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _openKeywordSheet(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: cs.onSurface.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => Text(
                  controller.keyword.value.isEmpty
                      ? '搜索名称、描述、作者…'
                      : controller.keyword.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: controller.keyword.value.isEmpty
                        ? cs.onSurface.withValues(alpha: 0.45)
                        : cs.onSurface.withValues(alpha: 0.88),
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
    final textController = TextEditingController(
      text: controller.keyword.value,
    );
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
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
              controller: textController,
              autofocus: true,
              placeholder: '搜索插件名称、描述、作者…',
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ),
        );
      },
    );
    textController.dispose();
    if (submitted == null) return;
    controller.updateKeyword(submitted);
  }

  static String _sortLabel(PluginListSortKey key) {
    switch (key) {
      case PluginListSortKey.defaultSort:
        return '默认';
      case PluginListSortKey.installCount:
        return '安装量';
      case PluginListSortKey.pluginName:
        return '名称';
      case PluginListSortKey.addTime:
        return '添加时间';
    }
  }

  List<PluginListFilterSectionConfig> _buildFilterSections() {
    return [
      PluginListFilterSectionConfig(
        filterType: PluginListFilterType.author,
        title: _filterSectionTitles[PluginListFilterType.author]!,
        options: controller.availableAuthors,
        selected: controller.selectedAuthors.toSet(),
        onToggle: (v) =>
            controller.toggleFilter(PluginListFilterType.author, v),
      ),
      PluginListFilterSectionConfig(
        filterType: PluginListFilterType.label,
        title: _filterSectionTitles[PluginListFilterType.label]!,
        options: controller.availableLabels,
        selected: controller.selectedLabels.toSet(),
        onToggle: (v) => controller.toggleFilter(PluginListFilterType.label, v),
      ),
      PluginListFilterSectionConfig(
        filterType: PluginListFilterType.repo,
        title: _filterSectionTitles[PluginListFilterType.repo]!,
        options: controller.availableRepos,
        selected: controller.selectedRepos.toSet(),
        onToggle: (v) => controller.toggleFilter(PluginListFilterType.repo, v),
      ),
    ];
  }

  Future<void> _openFilterSheet(
    BuildContext context, [
    PluginListFilterType? filterMode,
  ]) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.78,
          child: Obx(
            () => PluginListFilterSheet(
              title: '筛选',
              clearLabel: '清空',
              onClear: controller.clearFilters,
              sections: _buildFilterSections(),
              filterMode: filterMode,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverContent(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final error = controller.errorText.value;
      final items = controller.visibleItems;

      if (loading && items.isEmpty && controller.items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      if (error != null && controller.items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: controller.load,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              controller.keyword.value.trim().isEmpty &&
                      !controller.hasActiveFilters
                  ? '暂无插件'
                  : '未找到匹配的插件',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
            ),
          ),
        );
      }

      final width = MediaQuery.sizeOf(context).width;
      final useGrid = width > _wideBreakpoint;

      return SliverMainAxisGroup(
        slivers: [
          if (useGrid)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                8,
                _horizontalPadding,
                0,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      ((width - _horizontalPadding * 2) /
                              (_itemWidth + _gridSpacing))
                          .floor()
                          .clamp(1, 10)
                          .toInt(),
                  mainAxisSpacing: _gridSpacing,
                  crossAxisSpacing: _gridSpacing,
                  mainAxisExtent: 148,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCard(context, items[index]),
                  childCount: items.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                8,
                _horizontalPadding,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: _gridSpacing),
                    child: _buildCard(context, items[index]),
                  ),
                  childCount: items.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
          SliverToBoxAdapter(child: _buildLoadMoreFooter(context)),
        ],
      );
    });
  }

  Widget _buildLoadMoreFooter(BuildContext context) {
    return Obx(() {
      if (controller.visibleItems.isEmpty) return const SizedBox.shrink();
      if (!controller.hasMore) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Center(
            child: Text(
              '没有更多了',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
            ),
          ),
        );
      }
      final loading = controller.isLoadingMore.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : CupertinoButton(
                  onPressed: controller.loadMore,
                  child: Text(
                    '加载更多',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildCard(BuildContext context, PluginItem item) {
    final iconUrl = item.pluginIcon != null && item.pluginIcon!.isNotEmpty
        ? ImageUtil.convertPluginIconUrl(item.pluginIcon!)
        : '';
    return GestureDetector(
      onTap: () {
        Get.bottomSheet(PluginInfoSheet(item: item));
      },
      child: PluginItemCard(
        item: item,
        iconUrl: iconUrl,
        installCount: item.installCount,
      ),
    );
  }
}
