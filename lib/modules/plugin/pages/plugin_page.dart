import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/pages/plugin_info_sheet.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/modules/plugin/widgets/plugin_item_card.dart';
import 'package:moviepilot_mobile/modules/plugin/widgets/plugin_center_widgets.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class PluginPage extends GetView<PluginController> {
  const PluginPage({super.key});

  static const double _wideBreakpoint = 500;
  static const double _itemWidth = 250;
  static const double _horizontalPadding = 16;
  static const double _gridSpacing = 12;
  static const double _floatingBarHeight = 52;

  double _bottomInset(BuildContext context) {
    return _floatingBarHeight + 24 + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.find<AppService>().canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('插件'), centerTitle: false),
        body: const Center(
          child: Text(
            '当前帐号无管理权限',
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '已安装插件',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: '指定仓库安装',
            onPressed: () => _openRepoInstallSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.store_outlined),
            tooltip: '插件列表',
            onPressed: () => Get.toNamed('/plugin-list'),
          ),
          Obx(() {
            if (!controller.isLoading.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Stack(
          children: [
            const Positioned.fill(child: PluginCenterBackdrop()),
            CustomScrollView(
              cacheExtent: 200,
              slivers: [
                SliverToBoxAdapter(child: _buildOverviewHeader(context)),
                _buildSliverContent(context),
                SliverToBoxAdapter(
                  child: SizedBox(height: _bottomInset(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewHeader(BuildContext context) {
    return Obx(() {
      final items = controller.items;
      final active = items.where((item) => item.state).length;
      return PluginOverviewHeader(
        title: '你的插件空间',
        count: items.length,
        secondaryCount: active,
        secondaryLabel: '运行中',
        icon: Icons.extension_rounded,
      );
    });
  }

  Widget _buildFloatingBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(
              height: _floatingBarHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: cs.surface.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: _buildFakeSearchBar(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFakeSearchBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _openKeywordSheet(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: cs.onSurface.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => Text(
                  controller.keyword.value.isEmpty
                      ? '搜索已安装插件名称、描述、作者…'
                      : controller.keyword.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: controller.keyword.value.isEmpty
                        ? cs.onSurface.withValues(alpha: 0.45)
                        : cs.onSurface.withValues(alpha: 0.88),
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
    final textController = TextEditingController(
      text: controller.keyword.value,
    );
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
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
              controller: textController,
              autofocus: true,
              placeholder: '搜索已安装插件名称、描述、作者…',
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ),
        );
      },
    );
    textController.dispose();
    if (submitted == null) return;
    controller.updateKeyword(submitted);
  }

  Future<void> _openRepoInstallSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SpecifiedPluginInstallSheet(),
    );
  }

  Widget _buildSliverContent(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final error = controller.errorText.value;
      final items = controller.visibleItems;

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
                    onPressed: controller.load,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              controller.keyword.value.trim().isEmpty ? '暂无已安装插件' : '未找到匹配的插件',
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

      final width = MediaQuery.sizeOf(context).width;
      final useGrid = width > _wideBreakpoint;

      if (useGrid) {
        final availableWidth = width - _horizontalPadding * 2;
        final crossAxisCount = (availableWidth / (_itemWidth + _gridSpacing))
            .floor()
            .clamp(1, 10);

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            8,
            _horizontalPadding,
            0,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: _gridSpacing,
              crossAxisSpacing: _gridSpacing,
              mainAxisExtent: 148,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCard(context, items[index]),
              childCount: items.length,
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _horizontalPadding,
          8,
          _horizontalPadding,
          0,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: _gridSpacing),
              child: _buildCard(context, items[index]),
            ),
            childCount: items.length,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
          ),
        ),
      );
    });
  }

  Widget _buildCard(BuildContext context, PluginItem item) {
    final iconUrl = item.pluginIcon != null && item.pluginIcon!.isNotEmpty
        ? ImageUtil.convertPluginIconUrl(item.pluginIcon!)
        : '';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.hasPage) {
          Get.toNamed(
            '/plugin/dynamic-form/page',
            arguments: {'id': item.id, 'title': item.pluginName},
          );
        } else {
          Get.toNamed(
            '/plugin/dynamic-form/form',
            arguments: {'id': item.id, 'title': item.pluginName},
          );
        }
      },
      child: PluginItemCard(
        onHandleTap: (type) {
          switch (type) {
            case PluginHandleType.web:
              if (item.authorUrl != null && item.authorUrl!.isNotEmpty) {
                WebUtil.open(url: item.authorUrl!);
              }
              break;
            case PluginHandleType.settings:
              if (item.pluginConfigPrefix != null &&
                  item.pluginConfigPrefix!.isNotEmpty) {
                Get.toNamed(
                  '/plugin/dynamic-form/page',
                  arguments: {'id': item.id, 'title': item.pluginName},
                );
              }
              break;
            case PluginHandleType.log:
              _showLog(item);
              break;
            case PluginHandleType.reset:
              _resetPlugin(item);
              break;
            case PluginHandleType.uninstall:
              _uninstallPlugin(item);
              break;
          }
        },
        item: item,
        iconUrl: iconUrl,
        installCount: item.installCount,
      ),
    );
  }

  void _resetPlugin(PluginItem item) {
    ToastUtil.warning(
      '是否重置插件？',
      onConfirm: () {
        controller
            .resetPlugin(item.id)
            .then((success) {
              if (success) {
                controller.load();
              }
            })
            .catchError((error) {
              ToastUtil.error('重置插件失败: $error');
            });
      },
    );
  }

  void _uninstallPlugin(PluginItem item) {
    ToastUtil.warning(
      '是否卸载插件？',
      onConfirm: () {
        controller
            .uninstallPlugin(item.id)
            .then((success) {
              if (success) {
                controller.load();
              }
            })
            .catchError((error) {
              ToastUtil.error('卸载插件失败: $error');
            });
      },
    );
  }

  void _showLog(PluginItem item) {
    Get.toNamed(
      '/plugin/dynamic-form/log',
      arguments: {'id': item.id, 'title': item.pluginName},
    );
  }
}
