import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/pages/subscribe_files_page.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_filter_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_item_card.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_list_floating_bar.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_music_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_popular_item_card.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/constrained_page_content.dart';

/// 订阅页顶栏"更多操作"菜单项
enum _SubscribeAppBarAction { share, history, popular, rules, maintenance }

class SubscribePage extends GetView<SubscribeController> {
  const SubscribePage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const double _cardSpacing = 12;
  static const double _narrowRecommendationCardWidth = 140;
  static const double _narrowRecommendationCardHeight = 212;
  static const double _gridChildAspectRatio = 0.84;

  double _subscribeGridAspectRatio(int crossAxisCount) {
    if (crossAxisCount >= 4) return 0.86;
    if (crossAxisCount >= 3) return 0.84;
    return _gridChildAspectRatio;
  }

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
      floatingActionButton: Obx(
        () => SubscribeListFloatingBar(
          hasActiveFilters: controller.hasActiveFilters,
          onFilterTap: () => _openFilterSheet(context),
          keyword: controller.keyword.value,
          onKeywordSubmitted: controller.updateKeyword,
          sortValue: controller.sortValue,
          sortOptions: SubscribeSortKey.values.map((key) => key.name).toList(),
          sortLabelBuilder: _sortLabel,
          isSortAscending: controller.sortAscending.value,
          onSortDirectionChanged: controller.setSortDirection,
          onSortChanged: controller.setSortValue,
          showSortDirection: true,
        ),
      ),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          _buildSliverContent(context),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  MediaQuery.paddingOf(context).bottom +
                  SubscribeListFloatingBar.height +
                  32,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isMusic = controller.subscribeType == SubscribeType.music;
    return AppBar(
      title: Text(controller.subscribeType.displayName),
      centerTitle: false,
      actions: [
        if (!isMusic)
          _appBarChip(
            icon: CupertinoIcons.flame_fill,
            label: '热门订阅',
            foreground: const Color(0xFFFF9F0A),
            onTap: () => Get.toNamed(
              '/subscribe-popular',
              arguments: controller.subscribeType,
            ),
          ),
        PopupMenuButton<_SubscribeAppBarAction>(
          tooltip: '更多操作',
          onSelected: (action) => _handleAppBarAction(action),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          offset: const Offset(0, 10),
          surfaceTintColor: Colors.white,
          itemBuilder: (context) => [
            _appMenuItem(
              _SubscribeAppBarAction.share,
              CupertinoIcons.paperplane_fill,
              '订阅分享',
              const Color(0xFF0A84FF),
            ),
            _appMenuItem(
              _SubscribeAppBarAction.history,
              CupertinoIcons.clock_fill,
              '历史订阅',
              const Color(0xFF64D2FF),
            ),
            if (!isMusic)
              _appMenuItem(
                _SubscribeAppBarAction.rules,
                CupertinoIcons.slider_horizontal_3,
                '默认规则',
                theme.colorScheme.primary,
              ),
            _appMenuItem(
              _SubscribeAppBarAction.maintenance,
              CupertinoIcons.arrow_2_circlepath,
              '订阅维护',
              const Color(0xFF30D158),
            ),
          ],
          child: Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
            ),
            child: Icon(
              CupertinoIcons.ellipsis,
              size: 17,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _appBarChip({
    required IconData icon,
    required String label,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_SubscribeAppBarAction> _appMenuItem(
    _SubscribeAppBarAction action,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _handleAppBarAction(_SubscribeAppBarAction action) {
    switch (action) {
      case _SubscribeAppBarAction.share:
        Get.toNamed('/subscribe-share', arguments: controller.subscribeType);
      case _SubscribeAppBarAction.history:
        Get.toNamed('/subscribe-history', arguments: controller.subscribeType);
      case _SubscribeAppBarAction.popular:
        Get.toNamed('/subscribe-popular', arguments: controller.subscribeType);
      case _SubscribeAppBarAction.rules:
        controller.openDefaultRules();
      case _SubscribeAppBarAction.maintenance:
        _openMaintenanceSheet();
    }
  }

  /// V2/V3 均保留维护入口；刷新与检查仅管理员可用。
  Future<void> _openMaintenanceSheet() async {
    final service = Get.find<SubscribeService>();
    if (!await service.maintenanceSupported()) {
      ToastUtil.info('当前帐号无订阅维护权限');
      return;
    }
    await Get.bottomSheet<void>(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Builder(
              builder: (sheetContext) => Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (service.canMaintainAll) _buildMaintenanceAction(
              icon: CupertinoIcons.arrow_2_circlepath,
              title: '刷新订阅',
              subtitle: '搜索订阅缺失的资源',
              onTap: () => _runMaintenance(
                service.refreshSubscribes,
                '正在刷新订阅…',
              ),
            ),
            if (service.canMaintainAll) _buildMaintenanceAction(
              icon: CupertinoIcons.doc_text_search,
              title: '刷新订阅信息',
              subtitle: '重新拉取 TMDB 元数据',
              onTap: () => _runMaintenance(
                service.checkSubscribes,
                '正在刷新订阅信息…',
              ),
            ),
            if (service.canSearchSubscriptions) _buildMaintenanceAction(
              icon: CupertinoIcons.search,
              title: service.canMaintainAll ? '搜索所有订阅' : '搜索我的订阅',
              subtitle: '搜索当前帐号可管理的待搜索订阅',
              onTap: () => _runMaintenance(
                service.searchSubscribes,
                '正在搜索订阅…',
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      backgroundColor:
          (Get.context != null ? Theme.of(Get.context!).colorScheme.surface : null),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
    );
  }

  Widget _buildMaintenanceAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return ListTile(
          leading: Icon(icon, size: 22, color: theme.colorScheme.primary),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle,
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
        );
      },
    );
  }

  Future<void> _runMaintenance(
    Future<({bool ok, String message})> Function() action,
    String loadingText,
  ) async {
    if (Get.find<SubscribeService>().maintenanceBusy.value) return;
    ToastUtil.loading(message: loadingText);
    ({bool ok, String message}) result;
    try {
      result = await action();
    } catch (_) {
      result = (ok: false, message: '提交维护任务失败，请稍后重试');
    } finally {
      ToastUtil.dismiss();
    }
    if (controller.isClosed) return;
    if (result.ok) {
      ToastUtil.success(result.message);
    } else {
      ToastUtil.error(result.message);
    }
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
      return _wrapConstrainedSliver(
        context,
        SliverMainAxisGroup(
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
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
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

  static String _sortLabel(String value) {
    final key = SubscribeSortKey.values.firstWhereOrNull(
      (item) => item.name == value,
    );
    return key?.displayName ?? SubscribeSortKey.addedAt.displayName;
  }

  Widget _wrapConstrainedSliver(BuildContext context, Widget sliver) {
    final side = _pageContentSideInset(context);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(side, 12, side, 0),
      sliver: sliver,
    );
  }

  double _pageContentWidth(BuildContext context) {
    final isWide = ConstrainedPageContent.isWideScreen(context);
    final horizontal = isWide ? 24.0 : 16.0;
    final available = MediaQuery.sizeOf(context).width - horizontal * 2;
    return isWide
        ? available.clamp(0.0, ConstrainedPageContent.maxWidth)
        : available;
  }

  double _pageContentSideInset(BuildContext context) {
    final isWide = ConstrainedPageContent.isWideScreen(context);
    final horizontal = isWide ? 24.0 : 16.0;
    if (!isWide) return horizontal;

    final available = MediaQuery.sizeOf(context).width - horizontal * 2;
    final contentWidth = available.clamp(0.0, ConstrainedPageContent.maxWidth);
    return horizontal + (available - contentWidth) / 2;
  }

  int _subscribeGridCrossAxisCount(double width) {
    if (width >= 900) return 4;
    if (width >= 720) return 3;
    return 2;
  }

  ({double width, double height}) _recommendationCardSize(
    BuildContext context,
  ) {
    if (!ConstrainedPageContent.isWideScreen(context)) {
      return (
        width: _narrowRecommendationCardWidth,
        height: _narrowRecommendationCardHeight,
      );
    }
    final contentWidth = _pageContentWidth(context);
    final width = ((contentWidth - _cardSpacing * 4) / 5).clamp(156.0, 176.0);
    final height =
        width *
        (_narrowRecommendationCardHeight / _narrowRecommendationCardWidth);
    return (width: width, height: height);
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
    if (controller.subscribeType == SubscribeType.music) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < items.length - 1 ? _cardSpacing : 0,
            ),
            child: _buildMusicSubscribeCard(context, item),
          );
        }, childCount: items.length),
      );
    }

    final isWide = ConstrainedPageContent.isWideScreen(context);
    if (isWide) {
      final crossAxisCount = _subscribeGridCrossAxisCount(
        _pageContentWidth(context),
      );
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: _cardSpacing,
          crossAxisSpacing: _cardSpacing,
          childAspectRatio: _subscribeGridAspectRatio(crossAxisCount),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildSubscribeItemCard(
            context,
            items[index],
            SubscribeItemCardLayout.grid,
          ),
          childCount: items.length,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < items.length - 1 ? _cardSpacing : 0,
          ),
          child: _buildSubscribeItemCard(
            context,
            item,
            SubscribeItemCardLayout.list,
          ),
        );
      }, childCount: items.length),
    );
  }

  void _handleItemAction(
    BuildContext context,
    SubscribeItem item,
    SubscribeItemCardType type,
  ) {
    final isMusic = controller.subscribeType == SubscribeType.music;
    switch (type) {
      case SubscribeItemCardType.edit:
        _openEditSheet(context, item);
        break;
      case SubscribeItemCardType.detail:
        _mediaDetail(context, item);
        break;
      case SubscribeItemCardType.files:
        _openFiles(context, item);
        break;
      case SubscribeItemCardType.activity:
      case SubscribeItemCardType.logs:
        _openExecutionPage(type, item);
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
        if (isMusic) {
          final keyword = (item.name ?? '').trim();
          if (keyword.isEmpty) {
            ToastUtil.info('订阅缺少名称，无法搜索');
            return;
          }
          Get.toNamed('/music/search', parameters: {'keyword': keyword});
          return;
        }
        _searchSubscribe(context, item);
        break;
    }
  }

  Widget _buildSubscribeItemCard(
    BuildContext context,
    SubscribeItem item,
    SubscribeItemCardLayout layout,
  ) {
    final isMusic = controller.subscribeType == SubscribeType.music;
    return SubscribeItemCard(
      item: item,
      isTv: controller.isTv,
      isMusic: isMusic,
      layout: layout,
      showExecutionEntries: controller.executionEntriesVisible.value,
      onTap: () => isMusic
          ? showSubscribeMusicSheet(context, item)
          : _openFiles(context, item),
      onMoreTap: (type) => _handleItemAction(context, item, type),
    );
  }

  /// 音乐订阅专属条目卡：横向封面行卡，与影视海报卡区分
  Widget _buildMusicSubscribeCard(BuildContext context, SubscribeItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final violet = const Color(0xFF8B5CF6);
    final stateLabel = _musicStateLabel(item.state);
    final stateColor = _musicStateColor(context, item.state);
    final subtitle = [
      '音乐专辑',
      if ((item.year ?? '').trim().isNotEmpty) item.year!.trim(),
    ].join(' · ');
    final raw = item.id == null
        ? null
        : controller.rawSubscribeById['${item.id}'];
    int? rawInt(String key) {
      final v = raw?[key];
      if (v is int) return v;
      return int.tryParse('${v ?? ''}');
    }

    final totalTracks = rawInt('total_tracks') ?? 0;
    final downloadedTracks = rawInt('downloaded_tracks') ?? 0;
    final showTracks = totalTracks > 0;
    final trackProgress = showTracks
        ? (downloadedTracks / totalTracks).clamp(0.0, 1.0)
        : 0.0;
    final hasCover = item.poster?.trim().isNotEmpty == true;
    final trackColor = isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);

    return Semantics(
      button: true,
      label: '${item.name ?? '未知专辑'}，$stateLabel',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              violet.withValues(alpha: isDark ? 0.10 : 0.07),
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
            ],
          ),
          border: Border.all(
            color: violet.withValues(alpha: isDark ? 0.22 : 0.14),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned(
                right: -14,
                bottom: -32,
                child: Icon(
                  Icons.library_music_rounded,
                  size: 124,
                  color: violet.withValues(alpha: isDark ? 0.07 : 0.05),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showSubscribeMusicSheet(context, item),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: violet.withValues(
                                  alpha: isDark ? 0.32 : 0.22,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: hasCover
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CachedImage(
                                    imageUrl: item.poster!.trim(),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.library_music_rounded,
                                  size: 28,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name ?? '未知专辑',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: stateColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      stateLabel,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(color: stateColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.time,
                                    size: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    SubscribeController.formatRelativeTime(
                                      item.lastUpdate ?? item.date,
                                    ),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if ((item.username ?? '').trim().isNotEmpty)
                                    ...[
                                      const SizedBox(width: 10),
                                      Icon(
                                        CupertinoIcons.person_fill,
                                        size: 10,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        item.username!.trim(),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                ],
                              ),
                              if (showTracks) ...[
                                const SizedBox(height: 9),
                                Row(
                                  children: [
                                    Text(
                                      '音轨 $downloadedTracks / $totalTracks',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: trackColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${((downloadedTracks / totalTracks) * 100).round()}%',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: trackProgress,
                                    minHeight: 5,
                                    backgroundColor: theme
                                        .colorScheme.outlineVariant
                                        .withValues(alpha: 0.35),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<SubscribeItemCardType>(
                          onSelected: (type) =>
                              _handleItemAction(context, item, type),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 8,
                          shadowColor:
                              Colors.black.withValues(alpha: 0.12),
                          offset: const Offset(0, 10),
                          surfaceTintColor: Colors.white,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context) {
                            final isPaused =
                                item.state?.toUpperCase() == 'S';
                            final isRunning =
                                item.state?.toUpperCase() == 'R';
                            return [
                              _musicMenuItem(
                                SubscribeItemCardType.search,
                                Icons.search,
                                '搜索资源',
                                const Color(0xFF0A84FF),
                              ),
                              if (isPaused)
                                _musicMenuItem(
                                  SubscribeItemCardType.resume,
                                  Icons.play_arrow,
                                  '继续',
                                  Colors.green,
                                ),
                              if (isRunning)
                                _musicMenuItem(
                                  SubscribeItemCardType.pause,
                                  Icons.pause,
                                  '暂停',
                                  Colors.orange,
                                ),
                              _musicMenuItem(
                                SubscribeItemCardType.delete,
                                Icons.delete,
                                '删除',
                                Colors.red,
                              ),
                            ];
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.more_horiz,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
      ),
    );
  }

  PopupMenuItem<SubscribeItemCardType> _musicMenuItem(
    SubscribeItemCardType action,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _musicStateLabel(String? state) {
    switch (state?.trim().toUpperCase()) {
      case 'R':
        return '订阅中';
      case 'N':
        return '未开始';
      case 'S':
      case 'P':
        return '已暂停';
      default:
        return '待定';
    }
  }

  Color _musicStateColor(BuildContext context, String? state) {
    switch (state?.trim().toUpperCase()) {
      case 'R':
        return const Color(0xFF16A34A);
      case 'N':
        return const Color(0xFF0284C7);
      case 'S':
      case 'P':
        return const Color(0xFFF59E0B);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  void _openFiles(BuildContext context, SubscribeItem item) {
    showSubscribeFilesSheet(context, item);
  }

  /// 打开 v3 订阅执行可观测页（活动记录/运行日志）
  void _openExecutionPage(SubscribeItemCardType type, SubscribeItem item) {
    if (item.id == null || item.id! <= 0) {
      ToastUtil.info('无效的订阅');
      return;
    }
    final name = (item.name ?? '').trim();
    final route = type == SubscribeItemCardType.activity
        ? '/subscribe-activity'
        : '/subscribe-logs';
    Get.toNamed(
      route,
      arguments: {'id': item.id, 'title': name},
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
    final size = _recommendationCardSize(context);
    return SizedBox(
      height: size.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: size.width,
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
