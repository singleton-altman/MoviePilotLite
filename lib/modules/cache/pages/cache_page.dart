import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

import '../controllers/cache_controller.dart';
import '../models/cache_model.dart';
import '../widgets/site_filter_sheet.dart';

class CachePage extends GetView<CacheController> {
  const CachePage({super.key});

  static const double _floatingBarHeight = 52;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('缓存管理'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Get.back(),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: '缓存操作',
            icon: const Icon(CupertinoIcons.ellipsis_vertical, size: 20),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _runCacheAction(controller.refreshTorrentCache());
                case 'clear-torrent':
                  ToastUtil.warning(
                    '将清空全部种子缓存,重新搜索时需重建,确定继续吗?',
                    title: '清空种子缓存',
                    onConfirm: () =>
                        _runCacheAction(controller.clearTorrentCache()),
                  );
                case 'tmdb':
                  _showTmdbCacheSheet(context, controller);
                case 'clear-tmdb':
                  ToastUtil.warning(
                    '将清空全部 TMDB 识别缓存,确定继续吗?',
                    title: '清空 TMDB 识别缓存',
                    onConfirm: () => _runCacheAction(controller.clearTmdbCache()),
                  );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'refresh', child: Text('刷新种子缓存')),
              PopupMenuItem(value: 'clear-torrent', child: Text('清空种子缓存')),
              PopupMenuItem(value: 'tmdb', child: Text('查看 TMDB 识别缓存')),
              PopupMenuItem(value: 'clear-tmdb', child: Text('清空 TMDB 识别缓存')),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Obx(() => _buildBody(context, controller)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(() => _buildFloatingBar(context, controller)),
    );
  }

  Widget _buildBody(BuildContext context, CacheController controller) {
    final items = controller.filteredItems;
    final hasData = controller.cacheResponse.value != null;

    return CustomScrollView(
      slivers: [
        if (controller.errorText.value != null)
          SliverToBoxAdapter(child: _buildErrorBanner(context, controller)),
        if (controller.isLoading.value && !hasData)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(context, controller),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 108),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildSectionItem(
                  context,
                  items[index],
                  isLast: index == items.length - 1,
                );
              }, childCount: items.length),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, CacheController controller) {
    final colors = Theme.of(context).colorScheme;
    final error = colors.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: error.withValues(alpha: _isDark(context) ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: error.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: error,
              size: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.errorText.value ?? '',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, CacheController controller) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.38),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              controller.hasFilter
                  ? CupertinoIcons.search
                  : CupertinoIcons.archivebox,
              color: colors.onSurfaceVariant,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              controller.hasFilter ? '没有匹配的缓存' : '暂无缓存数据',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBar(BuildContext context, CacheController controller) {
    final sites = controller.siteOptions;
    final selectedCount = controller.selectedSites.length;
    final siteActive = controller.hasSiteFilter;
    final theme = Theme.of(context);
    final child = Row(
      children: [
        _buildFloatingFilterButton(
          context,
          controller,
          sites,
          isActive: siteActive,
          selectedCount: selectedCount,
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildKeywordTrigger(context, controller)),
        const SizedBox(width: 8),
        _buildActionGroup(context, controller),
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

  Widget _buildFloatingFilterButton(
    BuildContext context,
    CacheController controller,
    List<String> sites, {
    required bool isActive,
    required int selectedCount,
  }) {
    final color = isActive
        ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: sites.isEmpty
          ? null
          : () => _showSiteSelector(context, controller, sites),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: color),
          if (selectedCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$selectedCount',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeywordTrigger(
    BuildContext context,
    CacheController controller,
  ) {
    final theme = Theme.of(context);
    final keyword = controller.keyword.value.trim();
    final active = keyword.isNotEmpty;
    final textColor = active
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showKeywordSheet(context, controller),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Icon(CupertinoIcons.search, size: 16, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                active ? keyword : '搜索缓存',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (active)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  controller.keywordController.text = '';
                  controller.updateKeyword('');
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(CupertinoIcons.xmark_circle_fill, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showKeywordSheet(
    BuildContext context,
    CacheController controller,
  ) async {
    controller.closeActions();
    final textController = TextEditingController(
      text: controller.keyword.value,
    );
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Material(
              color: colors.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoSearchTextField(
                              controller: textController,
                              autofocus: true,
                              placeholder: '搜索标题、描述或资源信息',
                              backgroundColor: colors.surfaceContainerHighest
                                  .withValues(
                                    alpha: _isDark(sheetContext) ? 0.36 : 0.72,
                                  ),
                              onSubmitted: (value) =>
                                  Navigator.of(sheetContext).pop(value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            onPressed: () => Navigator.of(
                              sheetContext,
                            ).pop(textController.text),
                            child: const Text('完成'),
                          ),
                        ],
                      ),
                      if (textController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(sheetContext).pop(''),
                          child: const Text('清空搜索'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    textController.dispose();

    if (result == null) return;
    controller.keywordController.text = result;
    controller.updateKeyword(result);
  }

  Widget _buildActionGroup(BuildContext context, CacheController controller) {
    return Builder(
      builder: (buttonContext) {
        final isOpen = controller.showActions.value;
        final color = isOpen
            ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
            : Theme.of(context).colorScheme.onSurfaceVariant;
        return CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () {
            if (isOpen) {
              Navigator.of(buttonContext).maybePop();
              return;
            }
            _showActionMenu(buttonContext, controller);
          },
          child: Icon(
            isOpen ? CupertinoIcons.xmark : CupertinoIcons.ellipsis,
            size: 20,
            color: color,
          ),
        );
      },
    );
  }

  Future<void> _showActionMenu(
    BuildContext buttonContext,
    CacheController controller,
  ) async {
    controller.showActions.value = true;
    final overlay = Overlay.of(buttonContext);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final buttonBox = buttonContext.findRenderObject() as RenderBox?;
    if (overlayBox == null || buttonBox == null) return;

    const menuWidth = 170.0;
    const menuItemHeight = 44.0;
    const menuSpacing = 8.0;
    final menuHeight = menuItemHeight * 2 + 1;

    final position = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = buttonBox.size;
    final overlaySize = overlayBox.size;

    double left = position.dx + size.width - menuWidth;
    left = left.clamp(12.0, overlaySize.width - menuWidth - 12.0);
    final safeTop = MediaQuery.of(buttonContext).padding.top + 12;
    double top = position.dy - menuHeight - menuSpacing;
    if (top < safeTop) {
      top = position.dy + size.height + menuSpacing;
    }

    await showCupertinoModalPopup<void>(
      context: buttonContext,
      barrierDismissible: true,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: _buildActionMenuCard(
                  context,
                  width: menuWidth,
                  itemHeight: menuItemHeight,
                  onRefresh: () {
                    Navigator.of(context).pop();
                    controller.fetchCache();
                  },
                  onClear: () {
                    Navigator.of(context).pop();
                    controller.clearFilters();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (buttonContext.mounted) {
      controller.closeActions();
    }
  }

  Widget _buildActionMenuCard(
    BuildContext context, {
    required double width,
    required double itemHeight,
    required VoidCallback onRefresh,
    required VoidCallback onClear,
  }) {
    final background = CupertinoDynamicColor.resolve(
      CupertinoColors.systemBackground,
      context,
    ).withValues(alpha: 0.95);
    final dividerColor = CupertinoDynamicColor.resolve(
      CupertinoColors.separator,
      context,
    ).withValues(alpha: 0.35);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: background,
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(
                context,
                height: itemHeight,
                icon: CupertinoIcons.refresh,
                label: '刷新缓存',
                onTap: onRefresh,
              ),
              Container(height: 1, color: dividerColor),
              _buildMenuItem(
                context,
                height: itemHeight,
                icon: CupertinoIcons.clear,
                label: '清空筛选',
                onTap: onClear,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required double height,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = CupertinoDynamicColor.resolve(
      isDestructive ? CupertinoColors.systemRed : CupertinoColors.label,
      context,
    );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }

  void _showSiteSelector(
    BuildContext context,
    CacheController controller,
    List<String> sites,
  ) {
    controller.closeActions();
    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return SiteFilterSheet(
          sites: sites,
          selected: Set<String>.from(controller.selectedSites),
          onApply: controller.updateSelectedSites,
        );
      },
    );
  }

  Widget _buildCacheItem(
    BuildContext context,
    CacheItem item, {
    EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 10,
    ),
  }) {
    final title = _titleFor(item);
    final description = item.description?.trim() ?? '';
    final size = SizeFormatter.formatSize(item.size, 2);
    final date = _formatPubDate(item.pubdate);
    final site = _siteLabel(item) ?? '未知站点';
    final domain = item.domain?.trim();
    const posterWidth = 84.0;
    const posterHeight = 118.0;

    final tags = <_TagItem>[];
    if (item.mediaType != null && item.mediaType!.trim().isNotEmpty) {
      tags.add(_TagItem(item.mediaType!.trim(), _TagType.type));
    }
    if (item.mediaYear != null && item.mediaYear!.trim().isNotEmpty) {
      tags.add(_TagItem(item.mediaYear!.trim(), _TagType.year));
    }
    if (item.seasonEpisode != null && item.seasonEpisode!.trim().isNotEmpty) {
      tags.add(_TagItem(item.seasonEpisode!.trim(), _TagType.season));
    }
    if (item.resourceTerm != null && item.resourceTerm!.trim().isNotEmpty) {
      tags.add(_TagItem(item.resourceTerm!.trim(), _TagType.quality));
    }

    final link = (item.pageUrl?.trim().isNotEmpty ?? false)
        ? item.pageUrl
        : item.enclosure;
    final titleColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: link != null ? () => WebUtil.open(url: link) : null,
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPoster(
                context,
                item.posterPath ?? item.backdropPath,
                width: posterWidth,
                height: posterHeight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildTagChip(context, site, _TagType.site),
                        if (domain != null &&
                            domain.isNotEmpty &&
                            domain != site)
                          _buildPlainMetaText(context, domain),
                        for (final tag in tags)
                          _buildTagChip(context, tag.label, tag.type),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.34,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildInfoPill(context, CupertinoIcons.time, date),
                        _buildInfoPill(
                          context,
                          CupertinoIcons.arrow_down_circle,
                          size,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (link != null) ...[
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 16,
                  color: subtitleColor.withValues(alpha: 0.62),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlainMetaText(BuildContext context, String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 128),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoPill(BuildContext context, IconData icon, String text) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: _isDark(context) ? 0.28 : 0.52),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionItem(
    BuildContext context,
    CacheItem item, {
    required bool isLast,
  }) {
    final colors = Theme.of(context).colorScheme;
    final domain = item.domain?.trim() ?? '';
    final hash = item.hash?.trim() ?? '';
    final hasItemActions = domain.isNotEmpty && hash.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(
          alpha: _isDark(context) ? 0.22 : 0.42,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Stack(
        children: [
          _buildCacheItem(context, item, padding: const EdgeInsets.all(12)),
          if (hasItemActions)
            Positioned(
              top: 2,
              right: 0,
              child: PopupMenuButton<String>(
                tooltip: '缓存条目操作',
                padding: EdgeInsets.zero,
                icon: Icon(
                  CupertinoIcons.ellipsis_vertical,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      ToastUtil.warning(
                        '确定删除该条种子缓存吗?',
                        title: '删除缓存',
                        onConfirm: () => _runCacheAction(
                          controller.deleteTorrentCacheItem(domain, hash),
                        ),
                      );
                    case 'reidentify':
                      _runCacheAction(
                        controller.reidentifyTorrentCacheItem(domain, hash),
                      );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'delete', child: Text('删除缓存')),
                  PopupMenuItem(value: 'reidentify', child: Text('重新识别')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _runCacheAction(
    Future<({bool ok, String message})> action,
  ) async {
    ToastUtil.loading(message: '正在执行…');
    final result = await action;
    ToastUtil.dismiss();
    if (result.ok) {
      ToastUtil.success(result.message);
    } else {
      ToastUtil.error(result.message);
    }
  }

  Future<void> _showTmdbCacheSheet(
    BuildContext context,
    CacheController controller,
  ) async {
    ToastUtil.loading(message: '正在加载…');
    final items = await controller.loadTmdbCache();
    ToastUtil.dismiss();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (sheetContext, scrollController) => Container(
          color: Theme.of(sheetContext).colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('TMDB 识别缓存',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.clear, size: 20),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text('暂无识别缓存',
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(sheetContext)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = items[index];
                          final key = (entry['key'] ??
                                  entry['cache_key'] ??
                                  '')
                              .toString();
                          final title = (entry['title'] ??
                                  entry['name'] ??
                                  '未知条目')
                              .toString();
                          final year = entry['year']?.toString() ?? '';
                          return ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Theme.of(sheetContext)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.08),
                              ),
                            ),
                            title: Text(title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: year.isNotEmpty || key.isNotEmpty
                                ? Text(
                                    [if (year.isNotEmpty) year, key]
                                        .join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11))
                                : null,
                            trailing: key.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      CupertinoIcons.delete,
                                      size: 18,
                                      color: Theme.of(sheetContext)
                                          .colorScheme
                                          .error,
                                    ),
                                    onPressed: () => ToastUtil.warning(
                                      '确定删除该条识别缓存吗?',
                                      title: '删除识别缓存',
                                      onConfirm: () async {
                                        final result =
                                            await controller.deleteTmdbCacheItem(
                                          key,
                                        );
                                        if (result.ok) {
                                          ToastUtil.success('已删除');
                                          if (sheetContext.mounted) {
                                            Navigator.of(sheetContext).pop();
                                          }
                                        } else {
                                          ToastUtil.error(result.message);
                                        }
                                      },
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(
    BuildContext context,
    String? url, {
    double width = 72,
    double height = 102,
  }) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(
        CupertinoIcons.photo,
        size: 22,
        color: colors.onSurfaceVariant,
      ),
    );

    if (url == null || url.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(child: CupertinoActivityIndicator(radius: 8)),
          );
        },
      ),
    );
  }

  Widget _buildTagChip(BuildContext context, String label, _TagType type) {
    final baseColor = _tagColor(context, type);
    final bgColor = baseColor.withValues(alpha: _isDark(context) ? 0.14 : 0.08);
    final textColor = baseColor;
    final borderColor = baseColor.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _tagColor(BuildContext context, _TagType type) {
    final map = <_TagType, Color>{
      _TagType.site: CupertinoColors.systemBlue,
      _TagType.type: CupertinoColors.systemTeal,
      _TagType.year: CupertinoColors.systemPurple,
      _TagType.season: CupertinoColors.systemOrange,
      _TagType.quality: CupertinoColors.systemGreen,
    };
    return CupertinoDynamicColor.resolve(map[type]!, context);
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  String _formatPubDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '未知时间';
    final trimmed = raw.trim();
    final normalized = trimmed.contains('T')
        ? trimmed
        : trimmed.replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return trimmed;
    return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
  }

  String _titleFor(CacheItem item) {
    final title = item.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final media = item.mediaName?.trim();
    if (media != null && media.isNotEmpty) return media;
    return '未知标题';
  }

  String? _siteLabel(CacheItem item) {
    final site = item.siteName?.trim();
    if (site != null && site.isNotEmpty) return site;
    final domain = item.domain?.trim();
    if (domain != null && domain.isNotEmpty) return domain;
    return null;
  }
}

enum _TagType { site, type, year, season, quality }

class _TagItem {
  const _TagItem(this.label, this.type);

  final String label;
  final _TagType type;
}
