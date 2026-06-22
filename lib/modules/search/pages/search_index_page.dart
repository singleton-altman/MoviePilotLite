import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_category_item_card.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../controllers/search_index_controller.dart';
import '../models/search_suggestion.dart';

class SearchIndexPage extends GetView<SearchIndexController> {
  const SearchIndexPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const double _scrollBottomGap = 96;
  static const String _defaultPagerSubcategory = 'TMDB 热门电影';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF4F7FB),
      body: Obx(() {
        final isQuery = controller.isEditing.value;
        return CustomScrollView(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _sliverAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: _historyStyleSearchBar(context),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (!isQuery)
              ..._buildIdleSlivers(context)
            else
              ..._buildSuggestionSlivers(context),
            SliverToBoxAdapter(
              child: SizedBox(height: _scrollBottomInset(context)),
            ),
          ],
        );
      }),
    );
  }

  Widget _sliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 88,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      automaticallyImplyLeading: false,
      actions: [
        TextButton.icon(
          onPressed: () => Get.toNamed('/search-result'),
          icon: Icon(
            Icons.history_rounded,
            size: 18,
            color: colorScheme.onSurface.withValues(alpha: 0.86),
          ),
          label: Text(
            '近期搜索',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -90,
              left: -70,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.fromRGBO(59, 130, 246, 0.2),
                      Color.fromRGBO(59, 130, 246, 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -130,
              right: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.fromRGBO(168, 85, 247, 0.16),
                      Color.fromRGBO(168, 85, 247, 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '搜索',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyStyleSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const barH = 52.0;
    const radius = 26.0;
    final textFontSize = theme.textTheme.bodyMedium?.fontSize ?? 14.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            height: barH,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.62 : 0.94,
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: controller.focusNode.hasFocus
                    ? colorScheme.primary.withValues(alpha: 0.45)
                    : colorScheme.outlineVariant.withValues(alpha: 0.72),
                width: controller.focusNode.hasFocus ? 1.2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: controller.textController,
                    focusNode: controller.focusNode,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    placeholder: '搜索媒体 / 订阅 / 站点资源',
                    placeholderStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.78,
                      ),
                      fontSize: textFontSize,
                      fontWeight: FontWeight.w400,
                    ),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: textFontSize,
                      fontWeight: FontWeight.w400,
                    ),
                    prefix: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 12,
                        end: 6,
                      ),
                      child: Icon(
                        CupertinoIcons.search,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    prefixMode: OverlayVisibilityMode.always,
                    suffix: Obx(() {
                      if (controller.keyword.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: Semantics(
                          button: true,
                          label: '清除搜索内容',
                          child: CupertinoButton(
                            minimumSize: const Size.square(32),
                            padding: EdgeInsets.zero,
                            onPressed: controller.textController.clear,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.onSurface.withValues(
                                  alpha: theme.brightness == Brightness.dark
                                      ? 0.12
                                      : 0.08,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    suffixMode: OverlayVisibilityMode.always,
                    padding: const EdgeInsetsDirectional.only(
                      top: 10,
                      bottom: 10,
                      end: 12,
                    ),
                    cursorColor: colorScheme.primary,
                    onChanged: (value) => controller.keyword.value = value,
                    onSubmitted: controller.submit,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 12,
                  endIndent: 12,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                ),
                Obx(() {
                  final enabled = Get.find<AppService>().showSearchButton.value;
                  if (!enabled) return const SizedBox.shrink();

                  return InkWell(
                    onTap: () => controller.submit(),
                    child: SizedBox(
                      width: 48,
                      height: barH,
                      child: Center(
                        child: Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: colorScheme.primary.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Obx(() {
          if (!controller.hasSearchFocus.value) {
            return const SizedBox.shrink();
          }
          final suggestions = controller.historyInputSuggestions;
          if (suggestions.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Material(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.08),
                ),
                itemBuilder: (context, index) {
                  final e = suggestions[index];
                  return InkWell(
                    onTap: () => controller.submit(e.keyword),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        e.keyword,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w300,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Widget> _buildIdleSlivers(BuildContext context) {
    return [
      SliverToBoxAdapter(child: _idleSectionTitle(context, '为你推荐')),
      SliverToBoxAdapter(child: _buildRecommendMediaPager(context)),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: _idleSectionTitle(context, '浏览')),
      SliverToBoxAdapter(child: _buildBrowseCategoriesGrid(context)),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
    ];
  }

  Widget _idleSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  String _pickRecommendPagerSubcategory(RecommendController rec) {
    final list = rec.allVisibleSubCategories;
    if (list.contains(_defaultPagerSubcategory)) {
      return _defaultPagerSubcategory;
    }
    if (list.isNotEmpty) return list.first;
    return _defaultPagerSubcategory;
  }

  Widget _buildRecommendMediaPager(BuildContext context) {
    final rec = Get.find<RecommendController>();
    final sub = _pickRecommendPagerSubcategory(rec);
    rec.ensureSubCategoryLoaded(sub);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Obx(() {
      final items = rec.itemsForSubCategory(sub);
      final loading = rec.isLoadingForSubCategory(sub);
      final err = rec.errorForSubCategory(sub);
      if (items.isEmpty && err != null) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            err,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      if (items.isEmpty && loading) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: SizedBox(
            height: 232,
            child: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          ),
        );
      }
      if (items.isEmpty) {
        return const SizedBox(height: 12);
      }
      final pageCount = (items.length / 3).ceil().clamp(1, 9999);
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: SizedBox(
          height: 232,
          child: Skeletonizer(
            enabled: loading,
            child: PageView.builder(
              controller: controller.recommendPagerController,
              itemCount: pageCount,
              itemBuilder: (context, pageIndex) {
                final start = pageIndex * 3;
                final end = (start + 3).clamp(0, items.length);
                final pageItems = items.sublist(start, end);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        Expanded(
                          child: i < pageItems.length
                              ? _buildRecommendRow(context, pageItems[i])
                              : const SizedBox.shrink(),
                        ),
                        if (i != 2 && i < pageItems.length - 1) ...[
                          const SizedBox(height: 6),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: colorScheme.outline.withValues(alpha: 0.08),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRecommendRow(BuildContext context, RecommendApiItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overview = item.overview?.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openRecommendMediaDetail(item),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _recommendPoster(item, colorScheme),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bestRecommendTitle(item) ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (overview != null && overview.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    overview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendPoster(RecommendApiItem item, ColorScheme colorScheme) {
    const w = 52.0;
    const h = 72.0;
    final raw = item.poster_path ?? item.backdrop_path;
    if (raw != null && raw.isNotEmpty) {
      final url = ImageUtil.convertCacheImageUrl(raw);
      return CachedImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: w,
        height: h,
        borderRadius: BorderRadius.circular(10),
      );
    }
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: const SizedBox(width: w, height: h),
    );
  }

  Widget _buildBrowseCategoriesGrid(BuildContext context) {
    final rec = Get.find<RecommendController>();
    return Obx(() {
      final categories = rec.allVisibleSubCategories;
      if (categories.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            const ratio = 1.55;
            const targetItemWidth = 150.0;
            final w = constraints.maxWidth;
            var crossAxisCount = ((w + spacing) / (targetItemWidth + spacing))
                .floor();
            crossAxisCount = crossAxisCount.clamp(2, 10);
            final cellW = (w - (crossAxisCount - 1) * spacing) / crossAxisCount;
            final cellH = cellW / ratio;
            final rows = (categories.length / crossAxisCount).ceil();
            final h = rows * cellH + (rows - 1) * spacing;
            return SizedBox(
              height: h,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: ratio,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final name = categories[index];
                  final key = rec.keyForSubCategory(name);
                  final items = rec.itemsForSubCategory(name).take(3).toList();
                  return RecommendCategoryItemCard(
                    name: name,
                    items: items,
                    colorIndex: index,
                    onTap: (c1, c2) => _openRecommendCategoryList(
                      key: key ?? '',
                      title: name,
                      themeColor: c1,
                      secondaryColor: c2,
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    });
  }

  void _openRecommendCategoryList({
    required String key,
    required String title,
    Color? themeColor,
    Color? secondaryColor,
  }) {
    final params = <String, String>{
      'key': key,
      'title': title,
      if (themeColor != null)
        'themeColor': themeColor.toARGB32().toRadixString(16),
      if (secondaryColor != null)
        'secondaryColor': secondaryColor.toARGB32().toRadixString(16),
    };
    Get.toNamed('/recommend-category-list', parameters: params);
  }

  void _openRecommendMediaDetail(RecommendApiItem item) {
    final path = HttpPathBuilderUtil.buildMediaPath(item);
    if (path.isEmpty) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = _bestRecommendTitle(item);
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
    };
    Get.toNamed('/media-detail', parameters: params);
  }

  String? _bestRecommendTitle(RecommendApiItem item) {
    final title = item.title;
    if (title != null && title.trim().isNotEmpty) return title.trim();
    final enTitle = item.en_title;
    if (enTitle != null && enTitle.trim().isNotEmpty) return enTitle.trim();
    final original = item.original_title ?? item.original_name;
    if (original != null && original.trim().isNotEmpty) {
      return original.trim();
    }
    return null;
  }

  List<Widget> _buildSuggestionSlivers(BuildContext context) {
    final mediaSuggestions = controller.mediaSuggestionItems;
    final siteSuggestions = controller.siteSuggestionItems;
    final historyItems = controller.localHistorySuggestionItems;
    final bottomPad = 16.0;

    final out = <Widget>[];

    void addSection(Widget section) {
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
            child: section,
          ),
        ),
      );
    }

    if (mediaSuggestions.isNotEmpty) {
      addSection(
        Section(
          color: Theme.of(context).colorScheme.surface,
          header: SectionHeader(title: '媒体推荐'),
          child: _buildSuggestionSection(
            context,
            title: '媒体推荐',
            items: mediaSuggestions,
          ),
        ),
      );
    }
    if (siteSuggestions.isNotEmpty) {
      addSection(
        Section(
          color: Theme.of(context).colorScheme.surface,
          header: SectionHeader(title: '站点资源'),
          child: _buildSuggestionSection(
            context,
            title: '站点资源',
            items: siteSuggestions,
          ),
        ),
      );
    }
    if (historyItems.isNotEmpty) {
      addSection(
        Section(
          color: Theme.of(context).colorScheme.surface,
          header: SectionHeader(title: '整理历史'),
          child: _buildSuggestionSection(
            context,
            title: '整理历史',
            items: historyItems,
          ),
        ),
      );
    }

    return out;
  }

  double _scrollBottomInset(BuildContext context) {
    return MediaQuery.viewPaddingOf(context).bottom + _scrollBottomGap;
  }

  Widget _buildSuggestionSection(
    BuildContext context, {
    required String title,
    required List<SearchSuggestionItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          const _EmptyState(title: '暂无内容', subtitle: '尝试输入其他关键字')
        else
          ...List.generate(items.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Divider(
                height: 0.5,
                thickness: 0.5,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.7),
              );
            }
            final item = items[index ~/ 2];
            return _SuggestionTile(
              item: item,
              onTap: () {
                controller.fillKeyword(item.keyword, focus: false);
                controller.openMediaSearch(item.keyword, suggestion: item);
              },
            );
          }),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.item, required this.onTap});

  final SearchSuggestionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodyMedium!;
    final highlightStyle = titleStyle.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: _highlightSpans(
                        item.title,
                        item.keyword,
                        titleStyle,
                        highlightStyle,
                      ),
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _highlightSpans(
    String text,
    String keyword,
    TextStyle base,
    TextStyle highlight,
  ) {
    if (keyword.isEmpty) {
      return [TextSpan(text: text, style: base)];
    }
    final lowerText = text.toLowerCase();
    final lowerKey = keyword.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    var index = lowerText.indexOf(lowerKey);
    if (index == -1) {
      return [TextSpan(text: text, style: base)];
    }
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: base));
      }
      final matchEnd = index + lowerKey.length;
      spans.add(
        TextSpan(text: text.substring(index, matchEnd), style: highlight),
      );
      start = matchEnd;
      index = lowerText.indexOf(lowerKey, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: base));
    }
    return spans;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
