import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/pages/plugin_backup_restore_sheet.dart';
import 'package:moviepilot_mobile/modules/plugin/pages/plugin_info_sheet.dart';
import 'package:moviepilot_mobile/modules/plugin/pages/plugin_manage_sheet.dart';
import 'package:moviepilot_mobile/modules/plugin/pages/plugin_market_sheet.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/modules/plugin/widgets/plugin_item_card.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/glass_search_floating_bar.dart';

class PluginPage extends GetView<PluginController> {
  const PluginPage({super.key});

  static const double _wideBreakpoint = 500;
  static const double _itemWidth = 250;
  static const double _horizontalPadding = 16;
  static const double _gridSpacing = 12;

  double _bottomInset(BuildContext context) {
    return GlassSearchFloatingBar.height +
        24 +
        MediaQuery.paddingOf(context).bottom;
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
    final palette = DashboardPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const Text('已安装插件'),
        centerTitle: false,
        actions: [
          _buildAppBarActionButton(
            context,
            icon: Icons.folder_copy_outlined,
            tooltip: '分组与组件',
            accent: palette.primary,
            onPressed: () => showPluginMarketSheet(context),
          ),
          _buildAppBarActionButton(
            context,
            icon: Icons.add_rounded,
            tooltip: '指定仓库安装',
            accent: palette.primary,
            onPressed: () => _openRepoInstallSheet(context),
          ),
          _buildAppBarActionButton(
            context,
            icon: Icons.settings_backup_restore_rounded,
            tooltip: '备份中心',
            accent: palette.coolAccent,
            onPressed: () => showPluginBackupCenterSheet(context),
          ),
          _buildAppBarActionButton(
            context,
            icon: Icons.storefront_rounded,
            tooltip: '插件市场',
            accent: palette.warmAccent,
            onPressed: () => Get.toNamed('/plugin-list'),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Obx(
        () => GlassSearchFloatingBar(
          keyword: controller.keyword.value,
          onKeywordSubmitted: controller.updateKeyword,
          searchPlaceholder: '搜索已安装插件名称、描述、作者…',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: CustomScrollView(
          cacheExtent: 200,
          slivers: [
            _buildSliverContent(context),
            SliverToBoxAdapter(
              child: SizedBox(height: _bottomInset(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color accent,
    required VoidCallback? onPressed,
  }) {
    final palette = DashboardPalette.of(context);
    final enabled = onPressed != null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: accent.withValues(alpha: palette.isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                icon,
                size: 20,
                color: accent.withValues(alpha: enabled ? 1 : 0.38),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRepoInstallSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.36,
        maxChildSize: 1,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SpecifiedPluginInstallSheet(
              scrollController: scrollController,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverContent(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final error = controller.errorText.value;
      final items = controller.visibleItems;
      final unavailableCount = controller.unavailableItems.length;
      final cleaning = controller.isCleaningUnavailable.value;
      controller.availabilityById.length;

      if (loading && items.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: AppLoadingCenter(message: '正在加载已安装插件…'),
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
      final listSliver = useGrid
          ? SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                8,
                _horizontalPadding,
                0,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ((width - _horizontalPadding * 2) /
                          (_itemWidth + _gridSpacing))
                      .floor()
                      .clamp(1, 10),
                  mainAxisSpacing: _gridSpacing,
                  crossAxisSpacing: _gridSpacing,
                  mainAxisExtent: 160,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCard(context, items[index]),
                  childCount: items.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                ),
              ),
            )
          : SliverPadding(
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

      return SliverMainAxisGroup(
        slivers: [
          if (unavailableCount > 2)
            SliverToBoxAdapter(
              child: _buildUnavailableCleanupBar(
                context,
                unavailableCount,
                cleaning,
              ),
            ),
          listSliver,
        ],
      );
    });
  }

  Widget _buildUnavailableCleanupBar(
    BuildContext context,
    int count,
    bool cleaning,
  ) {
    final palette = DashboardPalette.of(context);
    final accent = palette.warningAccent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        8,
        _horizontalPadding,
        0,
      ),
      child: Material(
        color: accent.withValues(alpha: palette.isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '发现 $count 个不可用插件',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.titleText,
                  ),
                ),
              ),
              TextButton(
                onPressed: cleaning ? null : () => _cleanUnavailable(count),
                child: cleaning
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      )
                    : Text(
                        '一键清理',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cleanUnavailable(int count) {
    ToastUtil.warning(
      '将卸载 $count 个不可用插件，此操作不可撤销。',
      title: '一键清理',
      onConfirm: () {
        controller.uninstallUnavailablePlugins().then((result) {
          if (result.fail == 0) {
            ToastUtil.success('已清理 ${result.ok} 个不可用插件');
          } else {
            ToastUtil.error('清理完成：成功 ${result.ok}，失败 ${result.fail}');
          }
        }).catchError((error) {
          ToastUtil.error('清理失败: $error');
        });
      },
    );
  }

  Widget _buildCard(BuildContext context, PluginItem item) {
    final availability = controller.availabilityOf(item.id);
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
        unavailable: availability.unavailable,
        unavailableLabel: availability.label,
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
            case PluginHandleType.manage:
              showPluginManageSheet(context, item);
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
