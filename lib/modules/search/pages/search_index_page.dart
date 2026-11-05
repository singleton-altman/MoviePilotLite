import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/music/models/music_models.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_category_item_card.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/constrained_page_content.dart';
import 'package:moviepilot_mobile/widgets/dashboard_scaffold.dart';
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
    return DashboardScaffold(
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
              child: ConstrainedPageContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _historyStyleSearchBar(context),
                    const SizedBox(height: 12),
                    if (!isQuery)
                      ..._buildIdleContent(context)
                    else
                      ..._buildSuggestionContent(context),
                  ],
                ),
              ),
            ),
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
    final canSearch = Get.find<AppService>().canSearch;
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
        if (canSearch)
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
    return RawAutocomplete<SearchInputPick>(
      textEditingController: controller.textController,
      focusNode: controller.focusNode,
      displayStringForOption: (option) => option.keyword,
      optionsBuilder: (textEditingValue) =>
          controller.historyInputSuggestionsFor(textEditingValue.text),
      onSelected: controller.applyHistorySuggestion,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return Obx(() {
              final hasFocus = controller.hasSearchFocus.value;
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Container(
                  height: barH,
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.62 : 0.94,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: hasFocus
                          ? colorScheme.primary.withValues(alpha: 0.45)
                          : colorScheme.outlineVariant.withValues(alpha: 0.72),
                      width: hasFocus ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
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
                                  onPressed: textEditingController.clear,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.onSurface.withValues(
                                        alpha:
                                            theme.brightness == Brightness.dark
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
                          onChanged: (value) =>
                              controller.keyword.value = value,
                          onSubmitted: controller.submit,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        indent: 12,
                        endIndent: 12,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.72,
                        ),
                      ),
                      Obx(() {
                        final enabled =
                            Get.find<AppService>().showSearchButton.value;
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
                                color: colorScheme.primary.withValues(
                                  alpha: 0.95,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            });
          },
      optionsViewBuilder: (context, onSelected, options) {
        return _SearchInputOptionsView(
          options: options.toList(growable: false),
          onSelected: onSelected,
        );
      },
    );
  }

  List<Widget> _buildIdleContent(BuildContext context) {
    final canDiscovery = Get.find<AppService>().canDiscovery;
    // 音乐库入口只挂在「浏览」宫格末尾，且不依赖发现权限，
    // 所以无发现权限时宫格仍要保留给音乐卡。
    final showBrowse = canDiscovery || controller.musicBrowseSupported.value;
    return [
      if (canDiscovery) ...[
        _idleSectionTitle(context, '为你推荐'),
        _buildRecommendMediaPager(context),
        const SizedBox(height: 18),
      ],
      if (showBrowse) ...[
        _idleSectionTitle(context, '浏览'),
        _buildBrowseCategoriesGrid(
          context,
          includeRecommendCategories: canDiscovery,
        ),
        const SizedBox(height: 18),
      ],
    ];
  }

  Widget _idleSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            height: 232,
            child: const Center(child: AppLoading()),
          ),
        );
      }
      if (items.isEmpty) {
        return const SizedBox(height: 12);
      }
      final pageCount = (items.length / 3).ceil().clamp(1, 9999);
      return Padding(
        padding: const EdgeInsets.only(top: 4),
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

  Widget _buildBrowseCategoriesGrid(
    BuildContext context, {
    required bool includeRecommendCategories,
  }) {
    // 无发现权限时不触碰 RecommendController，避免为不可访问的内容发起加载。
    final rec = includeRecommendCategories
        ? Get.find<RecommendController>()
        : null;
    controller.ensureMusicBrowseLoaded();
    return Obx(() {
      final categories = rec?.allVisibleSubCategories ?? const <String>[];
      final showMusic = controller.musicBrowseSupported.value;
      if (categories.isEmpty && !showMusic) return const SizedBox.shrink();
      final musicItems = controller.musicExploreItems.take(2).toList();
      final total = categories.length + (showMusic ? 1 : 0);
      return Padding(
        padding: const EdgeInsets.only(top: 4),
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
            final rows = (total / crossAxisCount).ceil();
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
                itemCount: total,
                itemBuilder: (context, index) {
                  if (showMusic && index == categories.length) {
                    return _MusicBrowseCard(items: musicItems);
                  }
                  final name = categories[index];
                  final recommend = rec!;
                  final key = recommend.keyForSubCategory(name);
                  final items =
                      recommend.itemsForSubCategory(name).take(3).toList();
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

  List<Widget> _buildSuggestionContent(BuildContext context) {
    final mediaSuggestions = controller.mediaSuggestionItems;
    final musicSuggestions = controller.musicSuggestionItems;
    final siteSuggestions = controller.siteSuggestionItems;
    final historyItems = controller.localHistorySuggestionItems;
    final groups = <_SearchSuggestionGroup>[];

    if (mediaSuggestions.isNotEmpty) {
      groups.add(
        _SearchSuggestionGroup(
          title: '媒体推荐',
          subtitle: '片名、合集、演员、分享与订阅',
          icon: CupertinoIcons.film,
          color: const Color(0xFF2563EB),
          items: mediaSuggestions,
        ),
      );
    }
    if (musicSuggestions.isNotEmpty) {
      groups.add(
        _SearchSuggestionGroup(
          title: '音乐推荐',
          subtitle: '音乐人、专辑与单曲',
          icon: CupertinoIcons.music_note,
          color: const Color(0xFF8B5CF6),
          items: musicSuggestions,
        ),
      );
    }
    if (siteSuggestions.isNotEmpty) {
      groups.add(
        _SearchSuggestionGroup(
          title: '站点资源',
          subtitle: '跨站点检索资源结果',
          icon: CupertinoIcons.globe,
          color: const Color(0xFF0EA5E9),
          items: siteSuggestions,
        ),
      );
    }
    if (historyItems.isNotEmpty) {
      groups.add(
        _SearchSuggestionGroup(
          title: '整理历史',
          subtitle: '从本地记录继续整理',
          icon: CupertinoIcons.clock,
          color: const Color(0xFF7C3AED),
          items: historyItems,
        ),
      );
    }

    if (groups.isEmpty) return [const SizedBox(height: 12)];

    return [
      _buildSearchMethodPanel(context, groups),
      const SizedBox(height: 8),
    ];
  }

  double _scrollBottomInset(BuildContext context) {
    return MediaQuery.viewPaddingOf(context).bottom + _scrollBottomGap;
  }

  Widget _buildSearchMethodPanel(
    BuildContext context,
    List<_SearchSuggestionGroup> groups,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: isDark ? 0.72 : 0.98),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.34 : 0.70,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildSearchMethodGroup(context, group: groups[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchMethodGroup(
    BuildContext context, {
    required _SearchSuggestionGroup group,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: group.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(group.icon, size: 15, color: group.color),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    group.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${group.items.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final useTwoColumn =
                constraints.maxWidth >= 560 && group.items.length > 1;
            final itemWidth = useTwoColumn
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in group.items)
                  SizedBox(
                    width: itemWidth,
                    child: _SuggestionTile(
                      item: item,
                      icon: _suggestionIcon(item.category),
                      accentColor: group.color,
                      compact: useTwoColumn,
                      onTap: () {
                        controller.fillKeyword(item.keyword, focus: false);
                        controller.openMediaSearch(
                          item.keyword,
                          suggestion: item,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  IconData _suggestionIcon(SearchSuggestionCategory category) {
    switch (category) {
      case SearchSuggestionCategory.mediaTitle:
        return CupertinoIcons.search;
      case SearchSuggestionCategory.mediaCollection:
        return CupertinoIcons.square_stack_3d_up;
      case SearchSuggestionCategory.actor:
        return CupertinoIcons.person_2;
      case SearchSuggestionCategory.music:
        return CupertinoIcons.music_note;
      case SearchSuggestionCategory.share:
        return CupertinoIcons.arrowshape_turn_up_right;
      case SearchSuggestionCategory.history:
        return CupertinoIcons.clock;
      case SearchSuggestionCategory.subscription:
        return CupertinoIcons.heart;
      case SearchSuggestionCategory.site:
        return CupertinoIcons.globe;
    }
  }
}

class _SearchSuggestionGroup {
  const _SearchSuggestionGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<SearchSuggestionItem> items;
}

class _SearchInputOptionsView extends StatelessWidget {
  const _SearchInputOptionsView({
    required this.options,
    required this.onSelected,
  });

  final List<SearchInputPick> options;
  final AutocompleteOnSelected<SearchInputPick> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final horizontal = size.width > ConstrainedPageContent.wideBreakpoint
        ? 24.0
        : 16.0;
    final maxWidth = size.width > ConstrainedPageContent.wideBreakpoint
        ? ConstrainedPageContent.maxWidth
        : size.width - horizontal * 2;
    final width = (size.width - horizontal * 2).clamp(0.0, maxWidth);

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: width,
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: isDark ? 0.96 : 1),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.26 : 0.70,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  color: colorScheme.outline.withValues(alpha: 0.08),
                ),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final highlighted =
                      AutocompleteHighlightedOption.of(context) == index;
                  return _SearchInputOptionTile(
                    option: option,
                    highlighted: highlighted,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchInputOptionTile extends StatelessWidget {
  const _SearchInputOptionTile({
    required this.option,
    required this.highlighted,
    required this.onTap,
  });

  final SearchInputPick option;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHistory = option.sourceEntry != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: highlighted
            ? colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isHistory ? CupertinoIcons.clock : CupertinoIcons.search,
                size: 15,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.keyword,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.arrow_up_left,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.item,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.compact = false,
  });

  final SearchSuggestionItem item;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleStyle = theme.textTheme.bodyMedium!;
    final highlightStyle = titleStyle.copyWith(
      color: accentColor,
      fontWeight: FontWeight.w800,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 86 : 78),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.30 : 0.46,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.20 : 0.62,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: _highlightSpans(
                        item.title,
                        item.keyword,
                        titleStyle.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        highlightStyle,
                      ),
                    ),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: colorScheme.outline,
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

/// "浏览"宫格末尾的音乐入口卡片：展示探索专辑封面，点击进入音乐库
class _MusicBrowseCard extends StatelessWidget {
  const _MusicBrowseCard({required this.items});

  final List<MusicExploreItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.deepPurple.shade600, Colors.indigo.shade800];
    return GestureDetector(
      onTap: () => Get.toNamed('/music'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors[0].withValues(alpha: 0.9),
              colors[1].withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            if (items.isNotEmpty)
              Positioned(top: 12, right: 12, child: _buildCoverStack(items))
            else
              Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.library_music_rounded,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            const Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '音乐',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverStack(List<MusicExploreItem> items) {
    const size = 48.0;
    const radius = 10.0;
    const angles = [-15.0, 15.0];
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final url = items[i].coverUrl;
      if (url == null || url.isEmpty) continue;
      final angle = angles[i % 2] * math.pi / 180;
      widgets.add(
        Positioned(
          left: i * 28.0,
          top: i * 5,
          child: Transform.rotate(
            angle: angle,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: CachedImage(
                imageUrl: ImageUtil.convertCacheImageUrl(url),
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }
    if (widgets.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: size + (widgets.length > 1 ? 28.0 : 0),
      height: size + 12,
      child: Stack(children: widgets.reversed.toList()),
    );
  }
}
