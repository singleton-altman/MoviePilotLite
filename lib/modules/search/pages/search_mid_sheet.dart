import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_controller.dart';
import 'package:moviepilot_mobile/modules/site/models/site_models.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SiteSelectSheet extends StatefulWidget {
  const SiteSelectSheet({super.key, this.hasSegment = false});
  final bool hasSegment;
  @override
  State<SiteSelectSheet> createState() => _SiteSelectSheetState();
}

class _SiteSelectSheetState extends State<SiteSelectSheet> {
  final siteController = Get.put(SiteController());
  final appService = Get.find<AppService>();
  final selectedSite = <int>[].obs;
  final area = 'title'.obs;
  final _iconFutures = <int, Future<List<int>?>>{};
  late final Worker _siteItemsWorker;

  static const _prefsKeyPrefix = 'site_select_last';

  void _done() {
    _persistSelection();
    // 使用 Navigator.pop 确保关闭当前 bottom sheet 并返回结果。
    // Get.back() 会优先关闭 snackbar，导致 bottom sheet 不会被 pop，await 永不完结。
    Navigator.of(context).pop((area: area.value, sites: selectedSite.toList()));
  }

  @override
  void initState() {
    super.initState();
    _loadSelection();
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
    final prefs = await SharedPreferences.getInstance();
    final key = _buildPrefsKey();
    final values = selectedSite.map((e) => e.toString()).toList();
    await prefs.setStringList(key, values);
  }

  String _buildPrefsKey() {
    final baseUrl = appService.baseUrl ?? 'unknown';
    final userId = appService.loginResponse?.userId ?? 0;
    return '$_prefsKeyPrefix:$baseUrl:$userId';
  }

  void _filterSelection() {
    if (siteController.items.isEmpty) {
      return;
    }
    final ids = siteController.items.map((e) => e.site.id).toSet();
    final filtered = selectedSite.where(ids.contains).toList();
    if (filtered.length != selectedSite.length) {
      selectedSite.assignAll(filtered);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // 顶部操作栏
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
                Obx(
                  () => FilledButton(
                    onPressed: selectedSite.isEmpty ? null : _done,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: selectedSite.isEmpty
                          ? null
                          : theme.colorScheme.primary,
                    ),
                    child: Text(
                      '搜索',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 轻量化的选择信息栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
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
                        '已选择 ${selectedSite.length}/${siteController.items.length} 个站点',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => InkWell(
                      onTap: () {
                        if (selectedSite.length ==
                            siteController.items.length) {
                          selectedSite.clear();
                        } else {
                          selectedSite.assignAll(
                            siteController.items.map((e) => e.site.id),
                          );
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
                              selectedSite.length == siteController.items.length
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              selectedSite.length == siteController.items.length
                                  ? '清空'
                                  : '全选',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Obx(
                () => GridView.builder(
                  itemCount: siteController.items.length,
                  itemBuilder: (context, index) {
                    final item = siteController.items[index];
                    return _buildSiteItem(context, item);
                  },
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 44,
                  ),
                ),
              ),
            ),
          ),
        ],
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

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
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
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSiteIcon(item),
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
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
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
