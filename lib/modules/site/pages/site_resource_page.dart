import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/search_result_torrent_item.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_resource_controller.dart';
import 'package:moviepilot_mobile/modules/site/widgets/site_resource_filter_sheet.dart';

class SiteResourcePage extends GetView<SiteResourceController> {
  const SiteResourcePage({super.key});

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;
  static const double _floatingBarHeight = 52;

  @override
  Widget build(BuildContext context) {
    final title = controller.siteName.isNotEmpty
        ? '${controller.siteName} · 资源'
        : '站点资源';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: controller.loadResources,
            child: const Icon(CupertinoIcons.refresh),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      body: Obx(() => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final loading = controller.isLoading.value;
    final error = controller.errorText.value;
    final items = controller.visibleItems;
    final hasKeyword = controller.keyword.value.isNotEmpty;
    final hasFilter = controller.hasActiveFilters;

    return RefreshIndicator(
      onRefresh: controller.loadResources,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSummaryHeader(context, items.length)),
          if (loading && items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else if (error != null && items.isEmpty)
            SliverFillRemaining(
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
                        onPressed: controller.loadResources,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  hasKeyword || hasFilter ? '没有匹配的资源' : '暂无资源',
                  style: TextStyle(
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.secondaryLabel,
                      context,
                    ),
                  ),
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < items.length - 1 ? _cardSpacing : 0,
                    ),
                    child: SearchResultTorrentItem(item: items[index]),
                  );
                }, childCount: items.length),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: _floatingBarHeight + 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, int filteredCount) {
    final theme = Theme.of(context);
    final total = controller.items.length;
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final summaryText = controller.keyword.value.isEmpty
        ? controller.categoryFilterLabel
        : '关键词: ${controller.keyword.value}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.collections,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '当前分类: ${controller.categoryFilterLabel} · 共 $total 条 · 当前 $filteredCount 条',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: labelColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildFloatingSortButton(BuildContext context) {
    return Obx(
      () => SortPullDownWidget<SiteResourceSortKey>(
        isAscending:
            controller.sortDirection.value == SiteResourceSortDirection.asc,
        currentValue: controller.sortKey.value,
        options: SiteResourceSortKey.values,
        labelBuilder: _sortLabel,
        onDirectionChanged: controller.updateSortDirection,
        onValueChanged: controller.updateSortKey,
      ),
    );
  }

  Future<void> _openKeywordSheet(BuildContext context) async {
    final controllerText = TextEditingController(text: controller.keyword.value);
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: CupertinoSearchTextField(
              controller: controllerText,
              autofocus: true,
              placeholder: '筛选标题、描述、站点…',
              onSubmitted: (value) => Navigator.of(ctx).pop(value),
            ),
          ),
        );
      },
    );
    controllerText.dispose();
    if (submitted == null) return;
    controller.updateKeyword(submitted);
  }

  Future<void> _openFilterSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.4,
          child: Obx(
            () => SiteResourceFilterSheet(
              categories: controller.categories,
              selectedCategoryId: controller.selectedCategoryId.value,
              onSelectCategory: (id) {
                controller.setCategoryFilter(id);
                Navigator.of(sheetContext).pop();
                controller.loadResources();
              },
              onClear: () {
                controller.clearCategoryFilter();
                Navigator.of(sheetContext).pop();
                controller.loadResources();
              },
            ),
          ),
        );
      },
    );
  }

  static String _sortLabel(SiteResourceSortKey key) {
    switch (key) {
      case SiteResourceSortKey.defaultSort:
        return '默认';
      case SiteResourceSortKey.size:
        return '大小';
      case SiteResourceSortKey.seeders:
        return '做种数';
      case SiteResourceSortKey.pubdate:
        return '发布时间';
    }
  }
}
