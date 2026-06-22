import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_controller.dart';
import 'package:moviepilot_mobile/modules/site/models/site_models.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SiteSelectScene { search, subscribe }

class SiteSelectSheet extends StatefulWidget {
  const SiteSelectSheet({
    super.key,
    this.hasSegment = false,
    this.scene = SiteSelectScene.search,
    this.initialSelectedIds,
    this.disabledIds,
    this.seasons,
    this.mediaSearchKey,
  });
  final bool hasSegment;
  final SiteSelectScene scene;
  final List<int>? initialSelectedIds;
  final List<int>? disabledIds;
  final List<int>? seasons;
  final String? mediaSearchKey;
  @override
  State<SiteSelectSheet> createState() => _SiteSelectSheetState();
}

class _SiteSelectSheetState extends State<SiteSelectSheet> {
  final siteController = Get.put(SiteController());
  final appService = Get.find<AppService>();
  final selectedSite = <int>[].obs;
  final area = 'title'.obs;
  final season = 0.obs;
  final _iconFutures = <int, Future<List<int>?>>{};
  late final Worker _siteItemsWorker;

  static const _prefsKeyPrefix = 'site_select_last';
  static const _prefsKeyPrefixSeason = 'media_search_last_season';

  void _done() {
    if (widget.scene == SiteSelectScene.search) {
      _persistSelection();
      _persistSeason();
    }
    // 使用 Navigator.pop 确保关闭当前 bottom sheet 并返回结果。
    // Get.back() 会优先关闭 snackbar，导致 bottom sheet 不会被 pop，await 永不完结。
    Navigator.of(context).pop((area: area.value, sites: selectedSite.toList()));
  }

  @override
  void initState() {
    super.initState();
    if (widget.scene == SiteSelectScene.search) {
      _loadSelection();
      _loadSeason();
    } else {
      selectedSite.assignAll(widget.initialSelectedIds ?? const <int>[]);
      _filterSelection();
    }
    _siteItemsWorker = ever<List<SiteItem>>(
      siteController.items,
      (_) => _filterSelection(),
    );
  }

  @override
  void dispose() {
    _siteItemsWorker.dispose();
    super.dispose();
  }

  Future<void> _loadSelection() async {
    if (widget.scene != SiteSelectScene.search) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _buildPrefsKey();
    final raw = prefs.getStringList(key) ?? const <String>[];
    if (raw.isEmpty) return;
    final ids = raw.map((e) => int.tryParse(e)).whereType<int>().toList();
    if (ids.isEmpty) return;
    selectedSite.assignAll(ids);
    _filterSelection();
  }

  Future<void> _persistSelection() async {
    if (widget.scene != SiteSelectScene.search) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _buildPrefsKey();
    final values = selectedSite.map((e) => e.toString()).toList();
    await prefs.setStringList(key, values);
  }

  Future<void> _loadSeason() async {
    if (widget.scene != SiteSelectScene.search) return;
    final seasons = widget.seasons ?? const <int>[];
    final key = widget.mediaSearchKey?.trim();
    if (seasons.length <= 1 || key == null || key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_buildSeasonPrefsKey(key));
    if (raw == null) return;
    if (raw == 0 || seasons.contains(raw)) {
      season.value = raw;
    }
  }

  Future<void> _persistSeason() async {
    if (widget.scene != SiteSelectScene.search) return;
    final seasons = widget.seasons ?? const <int>[];
    final key = widget.mediaSearchKey?.trim();
    if (seasons.length <= 1 || key == null || key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_buildSeasonPrefsKey(key), season.value);
  }

  String _buildSeasonPrefsKey(String mediaSearchKey) {
    final baseUrl = appService.baseUrl ?? 'unknown';
    final userId = appService.loginResponse?.userId ?? 0;
    return '$_prefsKeyPrefixSeason:$baseUrl:$userId:$mediaSearchKey';
  }

  String _buildPrefsKey() {
    if (widget.scene != SiteSelectScene.search) {
      return _prefsKeyPrefix;
    }
    final baseUrl = appService.baseUrl ?? 'unknown';
    final userId = appService.loginResponse?.userId ?? 0;
    return '$_prefsKeyPrefix:$baseUrl:$userId';
  }

  void _filterSelection() {
    if (siteController.items.isEmpty) {
      return;
    }
    final ids = siteController.items.map((e) => e.site.id).toSet();
    final disabled = (widget.disabledIds ?? const <int>[]).toSet();
    final filtered = selectedSite
        .where((id) => ids.contains(id) && !disabled.contains(id))
        .toList();
    if (filtered.length != selectedSite.length) {
      selectedSite.assignAll(filtered);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.8;
    return SizedBox(
      height: maxHeight,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.7,
        maxChildSize: 1,
        builder: (context, scrollController) {
          return Material(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.hasSegment)
                        Expanded(
                          child: Obx(
                            () => Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: _buildSegmentTab(
                                      theme,
                                      'title',
                                      '标题',
                                      area.value == 'title',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSegmentTab(
                                      theme,
                                      'imdb',
                                      'IMDB',
                                      area.value == 'imdb',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Spacer(),
                      const SizedBox(width: 8),
                      Obx(() {
                        final selLen = selectedSite.length;
                        final canSubmit = !widget.hasSegment || selLen > 0;
                        return FilledButton(
                          onPressed: canSubmit ? _done : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: canSubmit
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          child: Text(
                            widget.hasSegment ? '搜索' : '确定',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            if ((widget.seasons ?? const <int>[]).length > 1)
                              _buildSeasonPicker(theme),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Obx(
                                        () => Text(
                                          () {
                                            final disabled =
                                                (widget.disabledIds ??
                                                        const <int>[])
                                                    .toSet();
                                            final enabledCount = siteController
                                                .items
                                                .where(
                                                  (e) => !disabled.contains(
                                                    e.site.id,
                                                  ),
                                                )
                                                .length;
                                            return '已选择 ${selectedSite.length}/$enabledCount 个站点';
                                          }(),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Obx(
                                      () => InkWell(
                                        onTap: () {
                                          final disabled =
                                              (widget.disabledIds ??
                                                      const <int>[])
                                                  .toSet();
                                          final enabledIds = siteController
                                              .items
                                              .map((e) => e.site.id)
                                              .where(
                                                (id) => !disabled.contains(id),
                                              )
                                              .toList();
                                          if (enabledIds.isNotEmpty &&
                                              selectedSite.length ==
                                                  enabledIds.length) {
                                            selectedSite.clear();
                                          } else {
                                            selectedSite.assignAll(enabledIds);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                () {
                                                  final disabled =
                                                      (widget.disabledIds ??
                                                              const <int>[])
                                                          .toSet();
                                                  final enabledCount =
                                                      siteController.items
                                                          .where(
                                                            (e) => !disabled
                                                                .contains(
                                                                  e.site.id,
                                                                ),
                                                          )
                                                          .length;
                                                  return selectedSite.length ==
                                                          enabledCount
                                                      ? Icons.check_box
                                                      : Icons
                                                            .check_box_outline_blank;
                                                }(),
                                                size: 16,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                () {
                                                  final disabled =
                                                      (widget.disabledIds ??
                                                              const <int>[])
                                                          .toSet();
                                                  final enabledCount =
                                                      siteController.items
                                                          .where(
                                                            (e) => !disabled
                                                                .contains(
                                                                  e.site.id,
                                                                ),
                                                          )
                                                          .length;
                                                  return selectedSite.length ==
                                                          enabledCount
                                                      ? '清空'
                                                      : '全选';
                                                }(),
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: theme
                                                          .colorScheme
                                                          .primary,
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
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          mediaQuery.padding.bottom + 16,
                        ),
                        sliver: Obx(
                          () => SliverGrid(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = siteController.items[index];
                              return _buildSiteItem(context, item);
                            }, childCount: siteController.items.length),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  mainAxisExtent: 44,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeasonPicker(ThemeData theme) {
    final seasons = (widget.seasons ?? const <int>[]).toList()..sort();
    const listHeight = 76.0;
    final usePagedGrid = seasons.length > 5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '季',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (!usePagedGrid)
              LayoutBuilder(
                builder: (context, constraints) {
                  final allValues = <int>[0, ...seasons];
                  final useExpandedRow = allValues.length <= 4;
                  return Obx(() {
                    if (useExpandedRow) {
                      return Row(
                        children: [
                          for (
                            var index = 0;
                            index < allValues.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _buildSeasonChip(
                                theme,
                                allValues[index],
                                allValues[index] == 0
                                    ? '全部季'
                                    : 'S${allValues[index].toString().padLeft(2, '0')}',
                                active: season.value == allValues[index],
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          children: [
                            _buildSeasonChip(
                              theme,
                              0,
                              '全部季',
                              active: season.value == 0,
                            ),
                            const SizedBox(width: 8),
                            ...seasons.map((s) {
                              final label = 'S${s.toString().padLeft(2, '0')}';
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildSeasonChip(
                                  theme,
                                  s,
                                  label,
                                  active: season.value == s,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  });
                },
              )
            else
              SizedBox(
                height: listHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final all = <int>[0, ...seasons];
                    final perRow = (constraints.maxWidth / 86).floor().clamp(
                      3,
                      8,
                    );
                    final perPage = perRow * 2;
                    final pageCount = (all.length / perPage).ceil().clamp(
                      1,
                      999,
                    );
                    return Obx(() {
                      final selected = season.value;
                      return PageView.builder(
                        controller: PageController(viewportFraction: 1),
                        itemCount: pageCount,
                        itemBuilder: (context, pageIndex) {
                          final start = pageIndex * perPage;
                          final end = (start + perPage).clamp(0, all.length);
                          final chunk = all.sublist(start, end);
                          return GridView.builder(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: perRow,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  mainAxisExtent: 34,
                                ),
                            itemCount: chunk.length,
                            itemBuilder: (context, index) {
                              final value = chunk[index];
                              final label = value == 0
                                  ? '全部季'
                                  : 'S${value.toString().padLeft(2, '0')}';
                              return _buildSeasonChip(
                                theme,
                                value,
                                label,
                                active: value == selected,
                              );
                            },
                          );
                        },
                      );
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonChip(
    ThemeData theme,
    int value,
    String label, {
    required bool active,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => season.value = value,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary.withValues(alpha: 0.25)
                : theme.colorScheme.outline.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentTab(
    ThemeData theme,
    String value,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          area.value = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSiteItem(BuildContext context, SiteItem item) {
    final theme = Theme.of(context);
    return Obx(() {
      final isSelected = selectedSite.contains(item.site.id);
      final disabled = (widget.disabledIds ?? const <int>[]).toSet().contains(
        item.site.id,
      );

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled
              ? null
              : () {
                  if (isSelected) {
                    selectedSite.remove(item.site.id);
                  } else {
                    selectedSite.add(item.site.id);
                  }
                },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: disabled
                  ? theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.9,
                    )
                  : isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: disabled
                    ? theme.colorScheme.outline.withValues(alpha: 0.45)
                    : isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: disabled ? 1 : (isSelected ? 1.5 : 1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: disabled ? 0.35 : 1,
                  child: _buildSiteIcon(item),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.site.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: disabled
                          ? theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.55,
                            )
                          : isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (disabled) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.block,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.55,
                    ),
                  ),
                ],
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSiteIcon(SiteItem item) {
    final bytes = item.iconBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return _imageFromBytes(bytes);
    }

    final future = _iconFutures.putIfAbsent(
      item.site.id,
      () => siteController.loadIcon(item.site),
    );

    return FutureBuilder<List<int>?>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null && data.isNotEmpty) {
          return _imageFromBytes(data);
        }
        return _placeholderIcon();
      },
    );
  }

  Widget _imageFromBytes(List<int> bytes) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.memory(
        Uint8List.fromList(bytes),
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _placeholderIcon(),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.public,
        size: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
