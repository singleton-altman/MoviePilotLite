import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_mappings.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/clean/plugin_clean_progress_sheet.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/alert_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/chart_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/cron_field_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/expansion_card_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/page_header_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/select_field_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/info_card_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/site_info_card_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/stat_card_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/switch_field_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/table_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/text_area_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/text_field_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/vuetify_renderer.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 展示项：单个区块 或 统计卡片网格（2x2）
sealed class _DisplayItem {}

class _DisplaySingle extends _DisplayItem {
  _DisplaySingle(this.block);
  final FormBlock block;
}

class _DisplayStatCardGrid extends _DisplayItem {
  _DisplayStatCardGrid(this.cards);
  final List<StatCardBlock> cards;
}

class DynamicFormPage extends GetView<DynamicFormController> {
  const DynamicFormPage({super.key, this.controllerTag});

  /// 与 binding 中 lazyPut 的 tag 一致，用于正确找到对应 controller（page / form 分离）
  final String? controllerTag;

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;
  static const double _statCardGridSpacing = 8;

  @override
  DynamicFormController get controller => Get.find<DynamicFormController>(
    tag:
        controllerTag ?? (Get.currentRoute.endsWith('/form') ? 'form' : 'page'),
  );

  List<_DisplayItem> _toDisplayItems(List<FormBlock> blocks) {
    final result = <_DisplayItem>[];
    var i = 0;
    while (i < blocks.length) {
      final block = blocks[i];
      if (block is StatCardBlock) {
        final cards = <StatCardBlock>[];
        while (i < blocks.length && blocks[i] is StatCardBlock) {
          cards.add(blocks[i] as StatCardBlock);
          i++;
        }
        result.add(_DisplayStatCardGrid(cards));
      } else {
        result.add(_DisplaySingle(block));
        i++;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.pageTitle ?? '动态表单'),
        centerTitle: false,
        actions: [
          if (controller.pluginAdapter is PluginFormAdapterWithClean)
            IconButton(
              icon: Icon(
                Icons.cleaning_services,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: '立即清理',
              onPressed: () => _onTriggerClean(context),
            ),
          if (!controller.formMode.value &&
              (controller.pluginAdapter?.actionList ?? []).isNotEmpty)
            _buildAppBarActionMenu(context),
          Obx(() {
            final showSave = controller.hasFormModel;
            if (showSave) {
              if (controller.isLoading.value) {
                return CupertinoActivityIndicator();
              }
              return IconButton(
                icon: Icon(
                  Icons.save,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: '保存',
                onPressed: onSave,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        final loading = controller.isLoading.value;
        final error = controller.errorText.value;
        final blocks = controller.effectiveBlocks;
        final pNodes = controller.effectivePageNodes;
        final hasContent = blocks.isNotEmpty || pNodes.isNotEmpty;

        if (loading && !hasContent) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (error != null && !hasContent) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: controller.load,
                      child: const Text('重试'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!hasContent) {
          return Center(
            child: Text(
              '暂无数据',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
              ),
            ),
          );
        }

        // page 模式且有原始节点：使用通用 VuetifyRenderer
        if (pNodes.isNotEmpty && !controller.isFormMode) {
          return VuetifyPageRenderer(nodes: pNodes, controller: controller);
        }

        // 默认：FormBlock 渲染
        final items = _toDisplayItems(blocks);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            12,
            _horizontalPadding,
            80,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? _cardSpacing : 0,
              ),
              child: _buildItem(context, item),
            );
          },
        );
      }),
      floatingActionButton: Obx(() {
        // 依赖 isLoading，以便 adapter 异步注入后能重新计算是否显示入口
        controller.isLoading.value;
        if (controller.formMode.value) return const SizedBox.shrink();
        final showEntry = controller.pluginAdapter?.supportsFormEntry ?? true;
        if (!showEntry) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: IconButton.filled(
            icon: const Icon(Icons.settings, color: CupertinoColors.white),
            onPressed: () {
              final args = {
                'id': controller.pluginId,
                'title': controller.pageTitle,
              };
              Get.toNamed('/plugin/dynamic-form/form', arguments: args);
            },
          ),
        );
      }),
    );
  }

  Widget _buildAppBarActionMenu(BuildContext context) {
    final adapter = controller.pluginAdapter!;
    final items = adapter.actionList ?? [];
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<AppBarActionItem>(
      tooltip: '更多操作',
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 10),
      icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.primary),
      onSelected: (item) async {
        await adapter.onAppBarAction(item.type);
      },
      itemBuilder: (_) => items.map((item) {
        final iconData = item.iconName != null
            ? VuetifyMappings.iconFromMdi(item.iconName)
            : null;
        final color = _resolveActionColor(context, item.iconColor);
        return PopupMenuItem<AppBarActionItem>(
          value: item,
          child: Row(
            children: [
              if (iconData != null) ...[
                Icon(iconData, size: 20, color: color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _resolveActionColor(BuildContext context, String? colorKey) {
    if (colorKey == null || colorKey.isEmpty) {
      return Theme.of(context).colorScheme.primary;
    }
    final hex = VuetifyMappings.colorFromHex(colorKey);
    if (hex != null) return hex;
    switch (colorKey.toLowerCase()) {
      case 'primary':
        return Theme.of(context).colorScheme.primary;
      case 'error':
        return CupertinoColors.destructiveRed;
      case 'success':
        return const Color(0xFF4CAF50);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _onTriggerClean(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => PluginCleanProgressSheet(controller: controller),
    );
  }

  onSave() async {
    try {
      ToastUtil.warning(
        '是否继续保存？',
        onConfirm: () async {
          final success = await controller.save();
          if (success) {
            ToastUtil.success('保存成功');
          } else {
            ToastUtil.error('保存失败');
          }
          Future.delayed(const Duration(seconds: 1), () {
            Get.back();
          });
        },
      );
    } catch (e) {
      ToastUtil.error('保存失败: $e');
    }
  }

  Widget _buildItem(BuildContext context, _DisplayItem item) {
    return switch (item) {
      _DisplaySingle(:final block) => _buildBlock(context, block),
      _DisplayStatCardGrid(:final cards) => _buildStatCardGrid(context, cards),
    };
  }

  Widget _buildStatCardGrid(BuildContext context, List<StatCardBlock> cards) {
    const double minItemWidth = 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final itemCount = cards.length;

        if (itemCount == 0) return const SizedBox();

        // 1️⃣ 计算一行最多能放多少个（满足最小宽度）
        int maxPerRow =
            (maxWidth + _statCardGridSpacing) ~/
            (minItemWidth + _statCardGridSpacing);

        maxPerRow = maxPerRow.clamp(1, itemCount);

        // 2️⃣ 如果一行能放下所有 item → 单行
        int crossCount;
        if (maxPerRow >= itemCount) {
          crossCount = itemCount;
        } else {
          // 3️⃣ 否则最多分两行，均分
          crossCount = (itemCount / 2).ceil();
        }

        // 4️⃣ 重新计算实际宽度
        final totalSpacing = _statCardGridSpacing * (crossCount - 1);
        final childWidth = (maxWidth - totalSpacing) / crossCount;

        return Wrap(
          spacing: _statCardGridSpacing,
          runSpacing: _statCardGridSpacing,
          children: cards.map((b) {
            return SizedBox(
              width: childWidth,
              child: StatCardWidget(block: b, compact: true),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBlock(BuildContext context, FormBlock block) {
    return block.map(
      statCard: (b) => StatCardWidget(block: b),
      chart: (b) => ChartWidget(block: b),
      table: (b) => TableWidget(
        block: b,
        actionLoading: controller.pluginAdapter?.actionLoading,
      ),
      switchField: (b) => Obx(
        () => SwitchFieldWidget(
          block: b,
          value: controller.hasFormModel
              ? controller.getBoolValue(b.name)
              : null,
          onChanged: b.name != null
              ? (v) => controller.updateField(b.name, v)
              : null,
        ),
      ),
      cronField: (b) => Obx(
        () => CronFieldWidget(
          block: b,
          value: controller.getValue(b.name)?.toString(),
          onChanged: b.name != null
              ? (v) => controller.updateField(b.name, v)
              : null,
        ),
      ),
      textField: (b) => Obx(
        () => TextFieldBlockWidget(
          block: b,
          value: controller.getValue(b.name)?.toString(),
          onChanged: b.name != null
              ? (v) => controller.updateField(b.name, v)
              : null,
        ),
      ),
      textArea: (b) => Obx(
        () => TextAreaFieldWidget(
          block: b,
          value: controller.getValue(b.name)?.toString(),
          onChanged: b.name != null
              ? (v) => controller.updateField(b.name, v)
              : null,
        ),
      ),
      selectField: (b) => Obx(
        () => SelectFieldWidget(
          block: b,
          value: controller.hasFormModel ? controller.getValue(b.name) : null,
          onChanged: b.name != null
              ? (v) => controller.updateField(b.name, v)
              : null,
        ),
      ),
      pageHeader: (b) => PageHeaderWidget(block: b),
      expansionCard: (b) => ExpansionCardWidget(block: b),
      alert: (b) => AlertWidget(block: b),
      siteInfoCard: (b) => SiteInfoCardWidget(block: b),
      infoCard: (b) => InfoCardWidget(block: b),
    );
  }
}
