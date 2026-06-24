import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_filter_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_item_card.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_popular_item_card.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class SubscribePage extends GetView<SubscribeController> {
  const SubscribePage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;
  static const double _floatingBarHeight = 52;
  static const double _recommendationCardWidth = 140;
  static const double _recommendationCardHeight = 212;

  @override
  Widget build(BuildContext context) {
    if (!Get.find<AppService>().canSubscribe) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(
          child: Text(
            '当前帐号无订阅权限',
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: _buildAppBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          _buildSliverContent(context),
          const SliverToBoxAdapter(
            child: SizedBox(height: _floatingBarHeight + 32),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return AppBar(
      title: Text(controller.subscribeType.displayName),
      centerTitle: false,
      actions: [
        if (controller.isTv) ...[
          _buildAppBarAction(
            context,
            icon: CupertinoIcons.paperplane_fill,
            tooltip: '订阅分享',
            iconColor: const Color(0xFF0A84FF),
            onPressed: () => Get.toNamed(
              '/subscribe-share',
              arguments: controller.subscribeType,
            ),
          ),
          const SizedBox(width: 4),
        ],
        _buildAppBarAction(
          context,
          icon: CupertinoIcons.flame_fill,
          tooltip: '热门订阅',
          iconColor: const Color(0xFFFF9F0A),
          onPressed: () => Get.toNamed(
            '/subscribe-popular',
            arguments: controller.subscribeType,
          ),
        ),
        const SizedBox(width: 4),
        _buildAppBarAction(
          context,
          icon: CupertinoIcons.slider_horizontal_3,
          tooltip: '默认规则',
          iconColor: primary,
          onPressed: controller.openDefaultRules,
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildAppBarAction(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        splashRadius: 20,
        icon: Icon(icon, size: 20, color: iconColor),
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
                      ? '搜索订阅名称…'
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
              placeholder: '搜索订阅名称…',
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

  Widget _buildSliverContent(BuildContext context) {
    return Obx(() {
      final loading = controller.userLoading.value;
      final error = controller.errorText.value;
      final items = controller.filteredUserItems;
      final hasFilters =
          controller.keyword.value.trim().isNotEmpty ||
          controller.selectedStates.isNotEmpty;
      if (loading && items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
      if (error != null && items.isEmpty) {
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
                    onPressed: controller.loadUserSubscribes,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      final shouldShowRecommendationArea =
          controller.shouldShowRecommendationSection ||
          controller.shouldShowRecommendationLoading;
      if (items.isEmpty && hasFilters) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '没有符合条件的订阅',
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
      if (items.isEmpty && !shouldShowRecommendationArea) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              '暂无订阅',
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
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _horizontalPadding,
          12,
          _horizontalPadding,
          0,
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            if (controller.shouldShowRecommendationSection) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 22, bottom: 12),
                  child: _buildRecommendationHeader(context),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildRecommendationCarousel(
                  context,
                  controller.recommendationItems,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],

            if (controller.canShowCollectionTabs)
              SliverToBoxAdapter(child: _buildCollectionHeader(context)),
            if (controller.shouldShowRecommendationLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: _buildRecommendationLoading(context),
                ),
              ),

            if (controller.currentTabItems.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      controller.shouldShowRecommendationSection ||
                          controller.shouldShowRecommendationLoading
                      ? 10
                      : 0,
                ),
              ),
            if (controller.currentTabItems.isNotEmpty)
              _buildSubscribeListSliver(context, controller.currentTabItems)
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildTabEmptyState(context),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCollectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildCollectionChip(
              context,
              title: '持续关注',
              count: controller.followingItemCount,
              selected:
                  controller.effectiveCollectionTab ==
                  SubscribeCollectionTab.following,
              onTap: () =>
                  controller.setCollectionTab(SubscribeCollectionTab.following),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildCollectionChip(
              context,
              title: '刷版收藏',
              count: controller.washingItemCount,
              selected:
                  controller.effectiveCollectionTab ==
                  SubscribeCollectionTab.washing,
              onTap: () =>
                  controller.setCollectionTab(SubscribeCollectionTab.washing),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionChip(
    BuildContext context, {
    required String title,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.78)
                : scheme.surfaceContainer.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.18)
                  : scheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabEmptyState(BuildContext context) {
    if (controller.userItems.isEmpty) {
      final theme = Theme.of(context);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.36),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          '还没有订阅内容，先看看下面的推荐订阅吧',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
          ),
        ),
      );
    }
    final hasAlternateTabItems = controller.isFollowingTab
        ? controller.washingItems.isNotEmpty
        : controller.followingItems.isNotEmpty;
    final nextTab = controller.isFollowingTab
        ? SubscribeCollectionTab.washing
        : SubscribeCollectionTab.following;
    final switchLabel = controller.isFollowingTab ? '刷版收藏' : '持续关注';
    final title = controller.isFollowingTab ? '当前没有持续关注内容' : '当前没有刷版收藏内容';
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.36),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
              ),
            ),
          ),
          if (hasAlternateTabItems) ...[
            const SizedBox(width: 12),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              onPressed: () => controller.setCollectionTab(nextTab),
              child: Text('查看$switchLabel'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscribeListSliver(
    BuildContext context,
    List<SubscribeItem> items,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < items.length - 1 ? _cardSpacing : 0,
          ),
          child: SubscribeItemCard(
            item: item,
            isTv: controller.isTv,
            layout: SubscribeItemCardLayout.list,
            onTap: () => _openEditSheet(context, item),
            onMoreTap: (type) {
              switch (type) {
                case SubscribeItemCardType.edit:
                  _openEditSheet(context, item);
                  break;
                case SubscribeItemCardType.detail:
                  _mediaDetail(context, item);
                  break;
                case SubscribeItemCardType.pause:
                  _pauseSubscribe(context, item);
                  break;
                case SubscribeItemCardType.resume:
                  _resumeSubscribe(context, item);
                  break;
                case SubscribeItemCardType.reset:
                  _resetSubscribeState(context, item);
                  break;
                case SubscribeItemCardType.shared:
                  _shareSubscribe(context, item);
                  break;
                case SubscribeItemCardType.delete:
                  _deleteSubscribe(context, item);
                  break;
                case SubscribeItemCardType.search:
                  _searchSubscribe(context, item);
                  break;
              }
            },
          ),
        );
      }, childCount: items.length),
    );
  }

  Widget _buildRecommendationHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '订阅推荐',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () => Get.toNamed(
            '/subscribe-popular',
            arguments: controller.subscribeType,
          ),
          child: Text(
            '更多',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCarousel(
    BuildContext context,
    List<RecommendApiItem> items,
  ) {
    return SizedBox(
      height: _recommendationCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: _recommendationCardWidth,
            child: SubscribePopularItemCard(
              item: item,
              onTap: () => _openRecommendationDetail(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationLoading(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.34),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(width: 10),
          Text(
            '正在加载推荐',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, SubscribeItem item) {
    Get.toNamed('/subscribe-edit', arguments: item);
  }

  _pauseSubscribe(BuildContext context, SubscribeItem item) {
    ToastUtil.warning(
      '确定暂停该订阅吗？',
      onConfirm: () async {
        try {
          final result = await controller.pauseSubscribe(item.id.toString());
          if (context.mounted && result) {
            ToastUtil.success('暂停成功');
            controller.loadUserSubscribes();
          }
        } catch (e) {
          ToastUtil.error('暂停失败: $e');
        }
      },
    );
  }

  _resumeSubscribe(BuildContext context, SubscribeItem item) {
    ToastUtil.warning(
      '确定继续该订阅吗？',
      onConfirm: () async {
        final result = await controller.resumeSubscribe(item.id.toString());
        if (context.mounted && result) {
          ToastUtil.success('继续成功');
          controller.loadUserSubscribes();
        }
      },
    );
  }

  _resetSubscribeState(BuildContext context, SubscribeItem item) {
    ToastUtil.warning(
      '确定重置该订阅状态吗？',
      onConfirm: () async {
        final result = await controller.resetSubscribeState(item.id.toString());
        if (context.mounted && result) {
          ToastUtil.success('重置成功');
          controller.loadUserSubscribes();
        }
      },
    );
  }

  _mediaDetail(BuildContext context, SubscribeItem item) {
    final path = HttpPathBuilderUtil.buildHttpPath(
      DiscoverSource.tmdb,
      item.tmdbid.toString(),
    );
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = item.name;
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
    };
    Get.toNamed('/media-detail', parameters: params);
  }

  void _openRecommendationDetail(RecommendApiItem item) {
    final path = HttpPathBuilderUtil.buildMediaPath(item);
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = item.title;
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
    };
    Get.toNamed('/media-detail', parameters: params);
  }

  _shareSubscribe(BuildContext context, SubscribeItem item) {
    final path = HttpPathBuilderUtil.buildHttpPath(
      DiscoverSource.tmdb,
      item.tmdbid.toString(),
    );
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = item.name;
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
    };
    Get.toNamed('/media-detail', parameters: params);
  }

  _deleteSubscribe(BuildContext context, SubscribeItem item) {
    ToastUtil.warning(
      '确定删除该订阅吗？',
      onConfirm: () async {
        final result = await controller.deleteSubscribes(item.id.toString());
        if (context.mounted && result) {
          ToastUtil.success('删除成功');
          controller.loadUserSubscribes();
        }
      },
    );
  }

  _searchSubscribe(BuildContext context, SubscribeItem item) async {
    final result = await controller.searchSubscribe(item.id.toString());
    if (context.mounted && result) {
      ToastUtil.success('搜索任务已创建');
    }
  }

  Future<void> _openFilterSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.4,
          child: Obx(
            () => SubscribeFilterSheet(
              states: controller.availableStates,
              selected: controller.selectedStates.toSet(),
              onToggle: controller.toggleStateFilter,
              onClear: controller.clearStateFilters,
            ),
          ),
        );
      },
    );
  }
}
