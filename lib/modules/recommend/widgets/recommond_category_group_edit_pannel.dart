import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_controller.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

class RecommondCategoryGroupEditPannelWidget extends StatelessWidget {
  final BuildContext sheetContext;
  final RecommendController controller;
  final DraggableScrollableController scrollController =
      DraggableScrollableController();
  RecommondCategoryGroupEditPannelWidget({
    super.key,
    required this.sheetContext,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      header: _buildAppBar(context),
      scrollController: scrollController,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        children: [
          Obx(() {
            final messages = [
              controller.sourceLoadError.value,
              controller.preferenceSyncError.value,
            ].whereType<String>().join('\n');
            return ListTile(
              title: const Text('扩展推荐来源'),
              subtitle: Text(
                messages.isEmpty ? '包含服务端插件来源，分组偏好随账号同步' : messages,
              ),
              trailing: IconButton(
                tooltip: '刷新推荐来源',
                onPressed: controller.reloadSources,
                icon: const Icon(Icons.refresh),
              ),
            );
          }),
          ..._buildCategoryCardGroup(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SectionHeader(
      title: '分组管理',
      trailing: TextButton(
        onPressed: () => Navigator.of(sheetContext).pop(),
        child: Text(
          '完成',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryCardGroup(BuildContext context) {
    final categories = RecommendCategory.values
        .where((c) => c != RecommendCategory.all)
        .toList();
    return categories
        .map((category) => _buildCategoryTile(category, context))
        .toList();
  }

  Widget _buildCategoryTile(RecommendCategory category, BuildContext context) {
    return Obx(() {
      final isVisible = controller.isCategoryVisible(category);
      final theme = Theme.of(context);
      final cardColor = theme.scaffoldBackgroundColor;
      return CupertinoListSection.insetGrouped(
        backgroundColor: cardColor,
        header: CupertinoListTile(
          title: Text(
            category.label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          trailing: Switch(
            value: isVisible,
            onChanged: (value) {
              controller.setCategoryVisibility(category, value);
            },
          ),
        ),
        children: _buildSubCategoryTiles(category),
      );
    });
  }

  List<Widget> _buildSubCategoryTiles(RecommendCategory category) {
    final subCategories = controller.subCategoriesFor(category);
    return List.generate(subCategories.length, (index) {
      final subCategory = subCategories[index];
      final isSubVisible = controller.isSubCategoryVisible(
        category,
        subCategory,
      );
      final isLast = index == subCategories.length - 1;

      return Column(
        children: [
          CupertinoListTile(
            title: Text(
              subCategory,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            trailing: Switch(
              value: isSubVisible,
              onChanged: (value) {
                controller.setSubCategoryVisibility(
                  category,
                  subCategory,
                  value,
                );
              },
            ),
          ),
          if (!isLast) const SizedBox(height: 6),
        ],
      );
    });
  }
}
