import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moviepilot_mobile/modules/media_organize/controllers/media_organize_controller.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/media_organize/widgets/media_organize_detail_sheet.dart';
import 'package:moviepilot_mobile/modules/media_organize/widgets/media_organize_item_card.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

enum _MediaOrganizeDeleteAction {
  recordOnly,
  recordAndSource,
  recordAndLibrary,
  recordAndSourceAndLibrary,
}

enum _MediaOrganizeGroupAction { selectAll, invertSelection, clearSelection }

class MediaOrganizePage extends GetView<MediaOrganizeController> {
  const MediaOrganizePage({super.key});

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 0;
  static const double _floatingBarHeight = 52;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([controller.loadStorages(), controller.load()]);
        },
        child: Obx(() => _buildBody(context)),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: const Text('媒体整理'),
      centerTitle: false,
      actions: [
        Obx(() {
          final mode = controller.viewMode.value;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: '切换显示方式',
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: controller.toggleViewMode,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            RotationTransition(
                              turns: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: Icon(
                          _viewModeIcon(mode),
                          key: ValueKey(mode),
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _viewModeActionLabel(mode),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final loading = controller.isLoading.value;
    final error = controller.errorText.value;
    final items = controller.filteredItems;
    final groups = controller.groupedItems;
    final hasQuery = controller.keyword.value.isNotEmpty;
    final hasFilter = controller.hasActiveFilters;
    final viewMode = controller.viewMode.value;
    final isSelectionMode = controller.isGroupedView && controller.hasSelection;

    return CustomScrollView(
      controller: controller.scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildSummaryHeader(context, items.length)),
        if (!isSelectionMode)
          SliverToBoxAdapter(child: _buildQuickTitlePicker(context)),
        if (loading && controller.items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        else if (error != null && controller.items.isEmpty)
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
                      onPressed: controller.load,
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
                hasQuery || hasFilter ? '没有匹配的整理记录' : '暂无整理记录',
                style: TextStyle(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondaryLabel,
                    context,
                  ),
                ),
              ),
            ),
          )
        else if (viewMode == MediaOrganizeViewMode.itemList)
          _buildItemListSliver(context, items)
        else
          _buildGroupedListSliver(context, groups),
        SliverToBoxAdapter(child: _buildLoadMore(context, items.isNotEmpty)),
        const SliverToBoxAdapter(
          child: SizedBox(height: _floatingBarHeight + 32),
        ),
      ],
    );
  }

  Widget _buildItemListSliver(
    BuildContext context,
    List<MediaOrganizeTransferItem> items,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        8,
        _horizontalPadding,
        0,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: _cardSpacing),
            child: _buildItemCard(context, item),
          );
        }, childCount: items.length),
      ),
    );
  }

  Widget _buildGroupedListSliver(
    BuildContext context,
    List<MediaOrganizeTitleGroup> groups,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        8,
        _horizontalPadding,
        0,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          groups
              .map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildGroupCard(context, group),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, MediaOrganizeTitleGroup group) {
    final theme = Theme.of(context);
    final selectedCount = controller.selectedCountForGroup(group);
    final collapsed = controller.isGroupCollapsed(group.title);
    final isSelectionMode = controller.isGroupedView && controller.hasSelection;
    final checkboxValue = controller.isGroupFullySelected(group)
        ? true
        : selectedCount == 0
        ? false
        : null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Checkbox(
                  value: checkboxValue,
                  tristate: true,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) => controller.toggleGroupSelection(group),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.toggleGroupCollapsed(group.title),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _buildGroupSubtitle(group, selectedCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<_MediaOrganizeGroupAction>(
                  tooltip: '分组选择操作',
                  offset: const Offset(0, 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: theme.colorScheme.surface,
                  onSelected: (action) =>
                      _handleGroupAction(group: group, action: action),
                  itemBuilder: (context) => [
                    _buildGroupActionMenuItem(
                      context,
                      value: _MediaOrganizeGroupAction.selectAll,
                      label: '全选本组',
                      icon: CupertinoIcons.check_mark_circled,
                    ),
                    _buildGroupActionMenuItem(
                      context,
                      value: _MediaOrganizeGroupAction.invertSelection,
                      label: '反选本组',
                      icon: Icons.swap_horiz_rounded,
                    ),
                    _buildGroupActionMenuItem(
                      context,
                      value: _MediaOrganizeGroupAction.clearSelection,
                      label: '清空本组',
                      icon: CupertinoIcons.clear_circled,
                      destructive: true,
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '选择',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: collapsed ? '展开分组' : '折叠分组',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => controller.toggleGroupCollapsed(group.title),
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: collapsed ? 0.5 : 0,
                    child: const Icon(CupertinoIcons.chevron_down, size: 18),
                  ),
                ),
              ],
            ),
          ),
          if (!collapsed) ...[
            Divider(
              height: 1,
              thickness: 0.5,
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Column(
                children: group.items
                    .map(
                      (item) => _buildItemCard(
                        context,
                        item,
                        selectionEnabled: true,
                        showPopupMenu: !isSelectionMode,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    MediaOrganizeTransferItem item, {
    bool selectionEnabled = false,
    bool showPopupMenu = true,
  }) {
    return MediaOrganizeItemCard(
      item: item,
      srcStorageName: controller.getStorageName(item.src_storage),
      destStorageName: controller.getStorageName(item.dest_storage),
      margin: selectionEnabled
          ? const EdgeInsets.only(bottom: 6)
          : const EdgeInsets.only(bottom: 12),
      selectionEnabled: selectionEnabled,
      showPopupMenu: showPopupMenu,
      selected: selectionEnabled && controller.isItemSelected(item),
      onTap: selectionEnabled
          ? () => controller.toggleItemSelection(item)
          : () => MediaOrganizeDetailSheet.show(
              context,
              item: item,
              srcStorageName: controller.getStorageName(item.src_storage),
              destStorageName: controller.getStorageName(item.dest_storage),
            ),
      onSelectionChanged: selectionEnabled
          ? (_) => controller.toggleItemSelection(item)
          : null,
      onDeleteTransferRecordOnly: () =>
          _deleteTransferRecord(item, deletesrc: false, deletedest: false),
      onDeleteTransferRecordAndSourceFile: () =>
          _deleteTransferRecord(item, deletesrc: true, deletedest: false),
      onDeleteTransferRecordAndMediaLibraryFile: () =>
          _deleteTransferRecord(item, deletesrc: false, deletedest: true),
      onDeleteTransferRecordAndSourceFileAndMediaLibraryFile: () =>
          _deleteTransferRecord(item, deletesrc: true, deletedest: true),
    );
  }

  Widget _buildQuickTitlePicker(BuildContext context) {
    final titles = controller.titleOptions;
    if (titles.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeTitle = controller.keyword.value.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: titles.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              final active = activeTitle.isEmpty;
              return _buildQuickTitleChip(
                context,
                label: '全部',
                active: active,
                onTap: () => controller.updateKeyword(''),
              );
            }

            final title = titles[index - 1];
            final active = activeTitle == title;
            return _buildQuickTitleChip(
              context,
              label: title,
              active: active,
              onTap: () => controller.updateKeyword(active ? '' : title),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickTitleChip(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? primary
                : theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, int filteredCount) {
    final theme = Theme.of(context);
    final total = controller.items.length;
    final loading = controller.isLoading.value;
    final labelColor = theme.colorScheme.onSurfaceVariant;
    final statusText = _statusFilterLabel(controller.statusFilter.value);
    final summaryText = controller.keyword.value.isEmpty
        ? '全部记录'
        : '关键词: ${controller.keyword.value}';
    final viewModeText =
        controller.viewMode.value == MediaOrganizeViewMode.itemList
        ? '单项列表'
        : '按标题聚合';

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
              child: loading
                  ? const Center(child: CupertinoActivityIndicator(radius: 10))
                  : Icon(
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
                    '状态: $statusText · 视图: $viewModeText · 共 $total 条 · 当前 $filteredCount 条',
                    maxLines: 2,
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

  Widget _buildLoadMore(BuildContext context, bool hasItems) {
    if (!hasItems) return const SizedBox.shrink();
    if (!controller.hasMore.value) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
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
    final loading = controller.isLoading.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Center(
        child: CupertinoButton(
          onPressed: loading ? null : controller.loadMore,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Text(
                  '加载更多',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFloatingBar(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final showSelectionBar =
          controller.isGroupedView && controller.hasSelection;
      final child = showSelectionBar
          ? _buildSelectionActionBar(context)
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
    });
  }

  Widget _buildSelectionActionBar(BuildContext context) {
    final theme = Theme.of(context);
    final count = controller.selectedCount;
    return Row(
      children: [
        Icon(
          CupertinoIcons.check_mark_circled_solid,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '已选择 $count 项',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          onPressed: controller.clearSelection,
          child: Text(
            '清空',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        PopupMenuButton<_MediaOrganizeDeleteAction>(
          tooltip: '删除已选记录',
          onSelected: (action) => _confirmDeleteSelected(context, action),
          itemBuilder: (context) => _buildDeleteMenuItems(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.delete,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Text(
                  '删除',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingFilterButton(BuildContext context) {
    final hasFilters = controller.hasActiveFilters;
    final color = hasFilters
        ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => _openFilterSheet(context),
      child: Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: color),
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
                      ? '搜索标题、路径、错误信息…'
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
      () => SortPullDownWidget<MediaOrganizeSortKey>(
        isAscending: controller.isSortAscending.value,
        currentValue: controller.sortKey.value,
        options: MediaOrganizeSortKey.values,
        labelBuilder: _sortLabel,
        onDirectionChanged: controller.updateSortDirection,
        onValueChanged: controller.updateSortKey,
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
              placeholder: '搜索标题、路径、错误信息…',
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
    return showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Obx(
        () => _MediaOrganizeFilterSheet(
          selected: controller.statusFilter.value,
          onSelected: (value) {
            controller.updateStatusFilter(value);
            Navigator.of(ctx).pop();
          },
          onClear: () {
            controller.updateStatusFilter(MediaOrganizeStatusFilter.all);
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  void _handleGroupAction({
    required MediaOrganizeTitleGroup group,
    required _MediaOrganizeGroupAction action,
  }) {
    switch (action) {
      case _MediaOrganizeGroupAction.selectAll:
        controller.selectGroup(group);
        break;
      case _MediaOrganizeGroupAction.invertSelection:
        controller.invertGroupSelection(group);
        break;
      case _MediaOrganizeGroupAction.clearSelection:
        controller.clearGroupSelection(group);
        break;
    }
  }

  PopupMenuItem<_MediaOrganizeGroupAction> _buildGroupActionMenuItem(
    BuildContext context, {
    required _MediaOrganizeGroupAction value,
    required String label,
    required IconData icon,
    bool destructive = false,
  }) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return PopupMenuItem<_MediaOrganizeGroupAction>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<_MediaOrganizeDeleteAction>> _buildDeleteMenuItems() {
    return [
      _buildDeleteActionButton(
        action: _MediaOrganizeDeleteAction.recordOnly,
        label: '仅删除转移记录',
        icon: Icons.delete_outline,
        color: CupertinoColors.systemPurple,
      ),
      _buildDeleteActionButton(
        action: _MediaOrganizeDeleteAction.recordAndSource,
        label: '删除转移记录和源文件',
        icon: Icons.delete_outline,
        color: CupertinoColors.systemYellow,
      ),
      _buildDeleteActionButton(
        action: _MediaOrganizeDeleteAction.recordAndLibrary,
        label: '删除转移记录和媒体库文件',
        icon: Icons.delete_outline,
        color: CupertinoColors.systemCyan,
      ),
      _buildDeleteActionButton(
        action: _MediaOrganizeDeleteAction.recordAndSourceAndLibrary,
        label: '删除转移记录、源文件和媒体库文件',
        icon: Icons.delete_outline,
        color: CupertinoColors.systemRed,
      ),
    ];
  }

  PopupMenuItem<_MediaOrganizeDeleteAction> _buildDeleteActionButton({
    required _MediaOrganizeDeleteAction action,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return PopupMenuItem<_MediaOrganizeDeleteAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    _MediaOrganizeDeleteAction action,
  ) async {
    final count = controller.selectedCount;
    if (count == 0) return;
    final label = _deleteActionLabel(action);
    ToastUtil.warning(
      '确定要对已选择的 $count 条记录执行“$label”吗？',
      onConfirm: () async {
        final result = await controller.deleteSelectedTransferRecords(
          deletesrc: _deleteSource(action),
          deletedest: _deleteLibrary(action),
        );
        if (!context.mounted) return;
        if (result.successCount == 0) {
          ToastUtil.error('批量删除失败');
          return;
        }
        await controller.resetFiltersToAll();
        if (!context.mounted) return;
        if (result.allSuccess) {
          ToastUtil.success('已删除 ${result.successCount} 条整理记录');
          return;
        }
        ToastUtil.error(
          '已删除 ${result.successCount} 条，${result.failureCount} 条删除失败',
        );
      },
    );
  }

  static String _sortLabel(MediaOrganizeSortKey key) {
    switch (key) {
      case MediaOrganizeSortKey.date:
        return '时间';
      case MediaOrganizeSortKey.title:
        return '标题';
      case MediaOrganizeSortKey.size:
        return '大小';
    }
  }

  static String _statusFilterLabel(MediaOrganizeStatusFilter filter) {
    switch (filter) {
      case MediaOrganizeStatusFilter.all:
        return '全部';
      case MediaOrganizeStatusFilter.success:
        return '成功';
      case MediaOrganizeStatusFilter.failed:
        return '失败';
    }
  }

  static String _viewModeActionLabel(MediaOrganizeViewMode mode) {
    switch (mode) {
      case MediaOrganizeViewMode.itemList:
        return '切到聚合';
      case MediaOrganizeViewMode.titleGrouped:
        return '切到列表';
    }
  }

  static IconData _viewModeIcon(MediaOrganizeViewMode mode) {
    switch (mode) {
      case MediaOrganizeViewMode.itemList:
        return CupertinoIcons.square_list;
      case MediaOrganizeViewMode.titleGrouped:
        return CupertinoIcons.square_stack_3d_up;
    }
  }

  static String _deleteActionLabel(_MediaOrganizeDeleteAction action) {
    switch (action) {
      case _MediaOrganizeDeleteAction.recordOnly:
        return '仅删除转移记录';
      case _MediaOrganizeDeleteAction.recordAndSource:
        return '删除转移记录和源文件';
      case _MediaOrganizeDeleteAction.recordAndLibrary:
        return '删除转移记录和媒体库文件';
      case _MediaOrganizeDeleteAction.recordAndSourceAndLibrary:
        return '删除转移记录、源文件和媒体库文件';
    }
  }

  static bool _deleteSource(_MediaOrganizeDeleteAction action) {
    switch (action) {
      case _MediaOrganizeDeleteAction.recordOnly:
      case _MediaOrganizeDeleteAction.recordAndLibrary:
        return false;
      case _MediaOrganizeDeleteAction.recordAndSource:
      case _MediaOrganizeDeleteAction.recordAndSourceAndLibrary:
        return true;
    }
  }

  static bool _deleteLibrary(_MediaOrganizeDeleteAction action) {
    switch (action) {
      case _MediaOrganizeDeleteAction.recordOnly:
      case _MediaOrganizeDeleteAction.recordAndSource:
        return false;
      case _MediaOrganizeDeleteAction.recordAndLibrary:
      case _MediaOrganizeDeleteAction.recordAndSourceAndLibrary:
        return true;
    }
  }

  String _buildGroupSubtitle(MediaOrganizeTitleGroup group, int selectedCount) {
    final parts = <String>[
      '共 ${group.items.length} 条',
      '已选 $selectedCount 条',
      '成功 ${group.successCount} 条',
    ];
    return parts.join(' · ');
  }

  Future<void> _deleteTransferRecord(
    MediaOrganizeTransferItem item, {
    required bool deletesrc,
    required bool deletedest,
  }) async {
    try {
      final success = await controller.deleteTransferRecord(
        item,
        deletesrc: deletesrc,
        deletedest: deletedest,
      );
      if (success) {
        await controller.resetFiltersToAll();
        ToastUtil.success('删除整理历史成功');
      } else {
        ToastUtil.error('删除整理历史失败');
      }
    } catch (e) {
      ToastUtil.error('删除整理历史失败: $e');
    }
  }
}

class _MediaOrganizeFilterSheet extends StatelessWidget {
  const _MediaOrganizeFilterSheet({
    required this.selected,
    required this.onSelected,
    required this.onClear,
  });

  final MediaOrganizeStatusFilter selected;
  final ValueChanged<MediaOrganizeStatusFilter> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      child: BottomSheetWidget(
        header: SectionHeader(
          title: '筛选',
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onClear,
            child: const Text('重置'),
          ),
        ),
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              '按整理结果筛选',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: MediaOrganizeStatusFilter.values.map((filter) {
                final isActive = filter == selected;
                return GestureDetector(
                  onTap: () => onSelected(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? primary
                          : primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? primary
                            : primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      MediaOrganizePage._statusFilterLabel(filter),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
