import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_palette_cache.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/ios_style/recommend_ios_banner_card.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_card.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_category_item_card.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_horizontal_card.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_now_playing_card.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_rank_card.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_item_simple_card.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommond_category_group_edit_pannel.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/http_path_builder_util.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum _SectionLayoutType {
  continueStyle,
  recommendStyle,
  horizontalList,
  hotStyle,
  rankStyle,
}

class RecommendPage extends GetView<RecommendController> {
  const RecommendPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const double _bannerHeight = 450;
  static const Color _backdropThemeColor = Color.fromRGBO(6, 24, 21, 1);

  _SectionLayoutType _layoutTypeForSectionIndex(
    int index, {
    String? subCategory,
  }) {
    if (index == 0) {
      return _SectionLayoutType.continueStyle;
    }
    if (index == 1) {
      return _SectionLayoutType.recommendStyle;
    }
    if (subCategory == null) {
      return _SectionLayoutType.horizontalList;
    }

    if (subCategory.toLowerCase().contains("top") ||
        subCategory.toLowerCase().contains("榜")) {
      return _SectionLayoutType.rankStyle;
    }

    if (subCategory.toLowerCase().contains("hot") ||
        subCategory.toLowerCase().contains("热门")) {
      return _SectionLayoutType.recommendStyle;
    }

    if (subCategory.toLowerCase().contains("new") ||
        subCategory.toLowerCase().contains("latest") ||
        subCategory.toLowerCase().contains("最新")) {
      return _SectionLayoutType.hotStyle;
    }
    return _SectionLayoutType.horizontalList;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _backdropThemeColor,
      child: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            left: false,
            right: false,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: _bannerHeight,
                  pinned: false,
                  stretch: true,
                  toolbarHeight: 0,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      // StretchMode.blurBackground,
                      StretchMode.fadeTitle,
                    ],
                    background: Obx(() => _buildBanner(context)),
                  ),
                ),
                CupertinoSliverRefreshControl(
                  onRefresh: () async => controller
                      .prefetchAllVisibleCategories(forceRefresh: true),
                ),
                SliverToBoxAdapter(child: _buildSectionList(context)),
                SliverToBoxAdapter(
                  child: SizedBox(height: _bottomSpacer(context)),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildImmersivePosterBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildImmersivePosterBar(BuildContext context) {
    return AppBar(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      title: Text(
        'Recommend',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {},
        child: const Icon(Icons.recommend_outlined),
      ),
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => RecommondCategoryGroupEditPannelWidget(
              sheetContext: context,
              controller: controller,
            ),
          ),
          child: const Icon(CupertinoIcons.slider_horizontal_3),
        ),
      ],
    );
  }

  double _bottomSpacer(BuildContext context) => 100;

  Widget _buildBanner(BuildContext context) {
    final subCategories = controller.allVisibleSubCategories;
    if (subCategories.isEmpty) {
      return Container(height: _bannerHeight, color: _backdropThemeColor);
    }
    final firstSub = subCategories.first;
    final items = controller.itemsForSubCategory(firstSub).take(5).toList();
    if (items.isEmpty) {
      return Container(height: _bannerHeight, color: _backdropThemeColor);
    }
    return Stack(
      children: [
        PageView.builder(
          controller: controller.bannerPageController,
          itemCount: items.length,
          onPageChanged: (i) => controller.bannerPageIndex.value = i,
          itemBuilder: (context, index) {
            final item = items[index];
            return RecommendIosBannerCard(
              item: item,
              themeColor: _backdropThemeColor,
              onTap: () => _openDetail(item),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Obx(() {
            final current = controller.bannerPageIndex.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == current;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSectionList(BuildContext context) {
    return Obx(() {
      final subCategories = controller.allVisibleSubCategories;
      if (subCategories.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            '暂无可展示的分组，请在筛选中开启。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        );
      }
      final sectionWidgets = subCategories.asMap().entries.map((entry) {
        final index = entry.key;
        final subCategory = entry.value;
        final layoutType = _layoutTypeForSectionIndex(
          index,
          subCategory: subCategory,
        );
        final items = controller.itemsForSubCategory(subCategory).toList();
        final themeColor = CupertinoColors.systemGrey;
        return KeyedSubtree(
          key: ValueKey(subCategory),
          child: _makeSection(
            context,
            themeColor: themeColor,
            layoutType: layoutType,
            title: subCategory,
            items: items,
          ),
        );
      }).toList();
      final insertAt = 2.clamp(0, sectionWidgets.length);
      sectionWidgets.insert(
        insertAt,
        KeyedSubtree(
          key: ValueKey('categories-section'),
          child: _buildCategoriesSection(context),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sectionWidgets,
      );
    });
  }

  Widget _makeSection(
    BuildContext context, {
    required _SectionLayoutType layoutType,
    List<RecommendApiItem>? items,
    String? title,
    required Color themeColor,
  }) {
    switch (layoutType) {
      case _SectionLayoutType.continueStyle:
        return _buildContinueStyleSection(context, title: title, items: items);
      case _SectionLayoutType.horizontalList:
        return _buildDefaultHorizontalList(context, title ?? '');
      case _SectionLayoutType.hotStyle:
        return _buildHotStyleSection(context, title ?? '');
      case _SectionLayoutType.rankStyle:
        return _buildRankStyleSection(context, title ?? '');
      case _SectionLayoutType.recommendStyle:
        return _buildRecommendStyleSection(
          context,
          title: title,
          items: items,
          themeColor: themeColor,
        );
    }
  }

  Widget _buildContinueStyleSection(
    BuildContext context, {
    String? title,
    List<RecommendApiItem>? items,
  }) {
    if (title == '正在热映') {
      return _buildNowPlayingSection(
        context,
        title: title ?? '',
        items: items ?? const [],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildSectionHeader(context, subCategory: title ?? ''),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (context, index) => SizedBox(width: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = items?[index];
              final posterUrl = item?.poster_path ?? item?.backdrop_path;
              if (posterUrl == null || posterUrl.isEmpty) {
                return SizedBox.shrink();
              }
              return SizedBox(
                width: 100,
                height: 100,
                child: RecommendItemCard(
                  item: item,
                  compact: true,
                  cardWidth: 100,
                  cardRadius: 25,
                  onTap: () => _openDetail(item!),
                ),
              );
            },
            itemCount: items?.length ?? 0,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNowPlayingSection(
    BuildContext context, {
    required String title,
    required List<RecommendApiItem> items,
  }) {
    final key = controller.keyForSubCategory(title);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          subCategory: title,
          onTapMore: () => _openCategoryList(key: key ?? '', title: title),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return RecommendNowPlayingCard(
                key: ValueKey(_itemKey(item)),
                item: item,
                onTap: () => _openDetail(item),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRecommendStyleSection(
    BuildContext context, {
    String? title,
    List<RecommendApiItem>? items,
    required Color themeColor,
  }) {
    final key = controller.keyForSubCategory(title ?? '');
    final screenWidth = MediaQuery.of(context).size.width;
    if (items == null || items.isEmpty) {
      return SizedBox.shrink();
    }
    final mainItem = items.firstOrNull;
    final sectionItem = items.elementAtOrNull(1);
    final thirdItem = items.elementAtOrNull(2);
    final cache = Get.find<PluginPaletteCache>();
    final url = ImageUtil.convertCacheImageUrl(mainItem?.poster_path ?? '');
    final color = cache.watchColor(url) ?? themeColor;

    final secondUrl = ImageUtil.convertCacheImageUrl(
      sectionItem?.poster_path ?? '',
    );
    final sectionThemeColor =
        cache.watchColor(secondUrl)?.withValues(alpha: 0.5) ?? Colors.blueGrey;
    return Column(
      children: [
        _buildSectionHeader(
          context,
          subCategory: title ?? '',
          onTapMore: () =>
              _openCategoryList(key: key ?? '', title: title ?? ''),
        ),
        if (screenWidth > 600) ...[
          SizedBox(
            height: 250,
            child: Row(
              children: [
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: RecommendItemSimpleCard(
                      item: mainItem,
                      onTap: () =>
                          mainItem != null ? _openDetail(mainItem) : null,
                      themeColor: color,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                    child: RecommendItemSimpleCard(
                      item: sectionItem,
                      onTap: () =>
                          sectionItem != null ? _openDetail(sectionItem) : null,
                      themeColor: sectionThemeColor,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                    child: RecommendItemCard(
                      cardHeight: 250,
                      item: thirdItem,
                      onTap: () =>
                          thirdItem != null ? _openDetail(thirdItem) : null,
                    ),
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        ] else ...[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 250,
                width: screenWidth - 36,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: RecommendItemSimpleCard(
                    item: mainItem,
                    onTap: () =>
                        mainItem != null ? _openDetail(mainItem) : null,
                    themeColor: color,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  if (sectionItem != null) ...[
                    SizedBox(width: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                      child: SizedBox(
                        height: 250,
                        width: (screenWidth - 44) / 2,
                        child: RecommendItemSimpleCard(
                          item: sectionItem,
                          onTap: () => _openDetail(sectionItem),
                          themeColor: sectionThemeColor,
                        ),
                      ),
                    ),
                  ],
                  if (thirdItem != null) ...[
                    SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                        child: RecommendItemCard(
                          cardHeight: 250,
                          item: thirdItem,
                          onTap: () => _openDetail(thirdItem),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultHorizontalList(BuildContext context, String subCategory) {
    final key = controller.keyForSubCategory(subCategory);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader(
          context,
          subCategory: subCategory,
          onTapMore: () =>
              _openCategoryList(key: key ?? '', title: subCategory),
        ),
        _buildPosterRail(context, subCategory),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String subCategory,
    VoidCallback? onTapMore,
  }) {
    final theme = Theme.of(context);
    final (title, subtitle, icon) = _parseSubCategory(subCategory);
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 16.0,
      ),
      child: InkWell(
        onTap: onTapMore,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Row(
                children: [
                  if (icon != null)
                    Image.asset(icon.path, width: 20, height: 20),
                  SizedBox(width: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                if (onTapMore != null) ...[
                  SizedBox(width: 12),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 15,
                    color: theme.primaryColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCategoryList({
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

  Widget _buildPosterRail(BuildContext context, String subCategory) {
    return Obx(() {
      final items = controller
          .itemsForSubCategory(subCategory)
          .take(8)
          .toList();
      final isLoading = controller.isLoadingForSubCategory(subCategory);
      final errorText = controller.errorForSubCategory(subCategory);
      if (items.isEmpty && errorText != null) {
        return _buildEmptyRail(context, errorText);
      }
      return Skeletonizer(
        enabled: isLoading,
        child: SizedBox(
          height: 200,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16),
            key: PageStorageKey<String>('recommend-rail-$subCategory'),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = items[index];
              return RecommendItemCard(
                key: ValueKey(_itemKey(item)),
                item: item,
                onTap: () => _openDetail(item),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: items.length,
          ),
        ),
      );
    });
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Obx(() {
      final categories = controller.allVisibleSubCategories;
      if (categories.isEmpty) return const SizedBox.shrink();
      final screenWidth = MediaQuery.of(context).size.width;
      final isNarrow = screenWidth <= 600;
      const cardHeight = 120.0;
      const horizontalPadding = 8.0;
      const spacing = 8.0;
      final contentWidth = screenWidth - horizontalPadding * 2;
      final crossCount = isNarrow ? 2 : 4;
      final rowCount = isNarrow ? 2 : 1;
      final perPage = crossCount * rowCount;
      final pageCount = (categories.length / perPage).ceil();
      final cellWidth =
          (contentWidth - spacing * (crossCount - 1)) / crossCount;
      final sectionHeight = rowCount * cardHeight + (rowCount - 1) * spacing;
      return SizedBox(
        height: sectionHeight,
        child: PageView.builder(
          controller: controller.categoryPageController,
          itemCount: pageCount,
          itemBuilder: (context, pageIndex) {
            final start = pageIndex * perPage;
            final end = (start + perPage).clamp(0, categories.length);
            final pageCategories = categories.sublist(start, end);
            Widget cardAt(int i) {
              if (i >= pageCategories.length) {
                return SizedBox(width: cellWidth, height: cardHeight);
              }
              final name = pageCategories[i];
              final key = controller.keyForSubCategory(name);
              final items = controller
                  .itemsForSubCategory(name)
                  .take(3)
                  .toList();
              return SizedBox(
                width: cellWidth,
                height: cardHeight,
                child: RecommendCategoryItemCard(
                  name: name,
                  items: items,
                  colorIndex: start + i,
                  onTap: (colorTheme, secondaryColor) => _openCategoryList(
                    key: key ?? '',
                    title: name,
                    themeColor: colorTheme,
                    secondaryColor: secondaryColor,
                  ),
                ),
              );
            }

            if (isNarrow) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: cardAt(0)),
                        SizedBox(width: spacing),
                        Expanded(child: cardAt(1)),
                      ],
                    ),
                    SizedBox(height: spacing),
                    Row(
                      children: [
                        Expanded(child: cardAt(2)),
                        SizedBox(width: spacing),
                        Expanded(child: cardAt(3)),
                      ],
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < crossCount; i++) ...[
                    if (i > 0) SizedBox(width: spacing),
                    Expanded(child: cardAt(i)),
                  ],
                ],
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildRankStyleSection(BuildContext context, String subCategory) {
    return Obx(() {
      final items = controller
          .itemsForSubCategory(subCategory)
          .take(4)
          .toList();
      final screenWidth = MediaQuery.of(context).size.width;
      final isNarrow = screenWidth <= 600;
      final isLoading = controller.isLoadingForSubCategory(subCategory);
      final errorText = controller.errorForSubCategory(subCategory);
      if (items.isEmpty && errorText != null) {
        return _buildEmptyRail(context, errorText);
      }
      return Skeletonizer(
        enabled: isLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(
              context,
              subCategory: subCategory,
              onTapMore: () => _openCategoryList(
                key: controller.keyForSubCategory(subCategory) ?? '',
                title: subCategory,
              ),
            ),
            if (isNarrow) ...[
              Row(
                children: [
                  SizedBox(width: 16),
                  Expanded(
                    child: items.isNotEmpty
                        ? RecommendItemRankCard(
                            item: items[0],
                            rank: 1,
                            onTap: () => _openDetail(items[0]),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: items.length > 1
                        ? RecommendItemRankCard(
                            item: items[1],
                            rank: 2,
                            onTap: () => _openDetail(items[1]),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(width: 16),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(width: 16),
                  Expanded(
                    child: items.length > 2
                        ? RecommendItemRankCard(
                            item: items[2],
                            rank: 3,
                            onTap: () => _openDetail(items[2]),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: items.length > 3
                        ? RecommendItemRankCard(
                            item: items[3],
                            rank: 4,
                            onTap: () => _openDetail(items[3]),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(width: 16),
                ],
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: items
                      .map(
                        (element) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: RecommendItemRankCard(
                              item: element,
                              rank: items.indexOf(element) + 1,
                              onTap: () => _openDetail(element),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      );
    });
  }

  Widget _buildHotStyleSection(BuildContext context, String subCategory) {
    return Obx(() {
      final items = controller
          .itemsForSubCategory(subCategory)
          .take(4)
          .toList();
      final screenWidth = MediaQuery.of(context).size.width;
      final isNarrow = screenWidth <= 600;
      final isLoading = controller.isLoadingForSubCategory(subCategory);
      final errorText = controller.errorForSubCategory(subCategory);
      if (items.isEmpty && errorText != null) {
        return _buildEmptyRail(context, errorText);
      }
      final mainItem = items.firstOrNull;
      if (mainItem == null) {
        return const SizedBox.shrink();
      }
      return Skeletonizer(
        enabled: isLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(
              context,
              subCategory: subCategory,
              onTapMore: () => _openCategoryList(
                key: controller.keyForSubCategory(subCategory) ?? '',
                title: subCategory,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: isNarrow
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RecommendItemCard(
                          cardHeight: 250,
                          item: mainItem,
                          onTap: () => _openDetail(mainItem),
                        ),
                        SizedBox(height: 8),
                        ...items
                            .sublist(1)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: RecommendItemHorizontalCard(
                                  item: item,
                                  onTap: () => _openDetail(item),
                                ),
                              ),
                            ),
                      ],
                    )
                  : SizedBox(
                      height: 250,
                      child: Row(
                        children: [
                          Expanded(
                            child: RecommendItemCard(
                              item: mainItem,
                              onTap: () => _openDetail(mainItem),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: [
                                ...items
                                    .sublist(1)
                                    .map(
                                      (item) => Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: RecommendItemHorizontalCard(
                                            item: item,
                                            onTap: () => _openDetail(item),
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  String _itemKey(RecommendApiItem item) {
    return HttpPathBuilderUtil.buildMediaPath(item);
  }

  Widget _buildEmptyRail(BuildContext context, String message) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _openDetail(RecommendApiItem item) {
    final path = _buildMediaPath(item);
    if (path == null) {
      ToastUtil.info('暂无可用详情信息');
      return;
    }
    final title = _bestTitle(item);
    final params = <String, String>{
      'path': path,
      if (title != null && title.isNotEmpty) 'title': title,
      if (item.year != null && item.year!.isNotEmpty) 'year': item.year!,
      if (item.type != null && item.type!.isNotEmpty) 'type_name': item.type!,
    };
    Get.toNamed('/media-detail', parameters: params);
  }

  String? _bestTitle(RecommendApiItem item) {
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

  String? _buildMediaPath(RecommendApiItem item) {
    return HttpPathBuilderUtil.buildMediaPath(item);
  }

  (String title, String? subtitle, AssetGenImage?) _parseSubCategory(
    String subCategory,
  ) {
    // 如果包含 TMDB 字样， 那么返回 剩余字符串
    if (subCategory.contains('TMDB')) {
      return (
        subCategory.replaceAll('TMDB', '').trim(),
        'TMDB',
        Assets.images.logos.tmdb,
      );
    }
    // 如果包含豆瓣字样， 那么返回 剩余字符串
    if (subCategory.contains('豆瓣')) {
      return (
        subCategory.replaceAll('豆瓣', '').trim(),
        '豆瓣',
        Assets.images.logos.douban,
      );
    }
    // 如果包含Bangumi字样， 那么返回 剩余字符串
    if (subCategory.contains('Bangumi')) {
      return (
        subCategory.replaceAll('Bangumi', '').trim(),
        'Bangumi',
        Assets.images.logos.bangumi,
      );
    }
    return (subCategory, null, null);
  }
}
