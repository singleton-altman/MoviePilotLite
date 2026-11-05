import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
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
import 'package:moviepilot_mobile/utils/open_url.dart';
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
          Obx(() {
            final applying = controller.isApplyingPushAlias.value;
            if (!controller.showApplyPushAliasAction) {
              return const SizedBox.shrink();
            }
            return TextButton(
              onPressed: applying ? null : _onApplyPushAlias,
              child: applying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CupertinoActivityIndicator(radius: 8),
                    )
                  : const Text('应用'),
            );
          }),
          Obx(() {
            // 依赖 isLoading，以便 adapter 注入后能重新计算并显示右侧操作（清理、actionList）
            controller.isLoading.value;
            final adapter = controller.pluginAdapter;
            final showCleanAction = adapter is PluginFormAdapterWithClean;
            final showMenuAction =
                !controller.formMode.value &&
                (adapter?.actionList ?? []).isNotEmpty;
            if (!showCleanAction && !showMenuAction) {
              return const SizedBox.shrink();
            }
            return Wrap(
              spacing: 0,
              children: [
                if (showCleanAction)
                  IconButton(
                    icon: Icon(
                      Icons.cleaning_services,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: '立即清理',
                    onPressed: () => _onTriggerClean(context),
                  ),
                if (showMenuAction) _buildAppBarActionMenu(context),
              ],
            );
          }),
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
          Obx(() {
            controller.isLoading.value;
            if (controller.formMode.value) return const SizedBox.shrink();
            if (controller.isAppLitePushPlugin) return const SizedBox.shrink();
            final showEntry =
                controller.pluginAdapter?.supportsFormEntry ?? true;
            if (!showEntry) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: '插件配置',
              onPressed: () {
                Get.toNamed(
                  '/plugin/dynamic-form/form',
                  arguments: {
                    'id': controller.pluginId,
                    'title': controller.pageTitle,
                  },
                );
              },
            );
          }),
        ],
      ),
      body: Obx(() {
        final loading = controller.isLoading.value;
        final error = controller.errorText.value;
        final theme = Theme.of(context);
        final blocks = controller.effectiveBlocks;
        final pNodes = controller.effectivePageNodes;
        final hasContent = blocks.isNotEmpty || pNodes.isNotEmpty;
        final customRenderer = controller.pluginId == null
            ? null
            : PluginFormAdapterRegistry.getCustomRenderer(controller.pluginId!);

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
        if (customRenderer != null &&
            (hasContent ||
                controller.hasFormModel ||
                controller.isAppLitePushPlugin)) {
          return customRenderer(
            context,
            blocks,
            controller,
            controller.formMode.value,
            _buildBlock,
          );
        }
        if (!hasContent && controller.isUnsupportedVuePlugin) {
          return _VueOnlyPlaceholder(webUrl: controller.serverWebUrl);
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

        // page 模式且原始节点仍落在通用子集内时，使用原始 VuetifyRenderer；
        // 否则回退到 FormBlock 渲染，避免 web 端新节点直接导致页面空白。
        if (pNodes.isNotEmpty &&
            !controller.formMode.value &&
            controller.canUseRawPageRenderer) {
          return VuetifyPageRenderer(nodes: pNodes, controller: controller);
        }

        // 默认：FormBlock 渲染
        final items = _toDisplayItems(blocks);
        final unsupported = controller.unsupportedFormComponents;
        return Column(
          children: [
            if (unsupported.isNotEmpty)
              Material(
                color: theme.colorScheme.surfaceContainerHighest,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.tertiary,
                  ),
                  title: Text(
                    '部分组件暂不支持在移动端配置（${unsupported.join('、')}），请在 Web 端调整',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
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
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAppBarActionMenu(BuildContext context) {
    final adapter = controller.pluginAdapter!;
    final items = adapter.actionList ?? [];
    if (items.isEmpty) return const SizedBox.shrink();
    if (items.length == 1) {
      final item = items.first;
      final iconData = item.iconName != null
          ? VuetifyMappings.iconFromMdi(item.iconName)
          : Icons.more_horiz;
      final color = _resolveActionColor(context, item.iconColor);
      return IconButton(
        tooltip: item.label,
        icon: Icon(iconData ?? Icons.more_horiz, color: color),
        onPressed: () => adapter.onAppBarAction(item.type),
      );
    }
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

  Future<void> _onApplyPushAlias() async {
    final outcome = await controller.applyCurrentPushTokenAsAlias();
    if (!outcome.isSuccess) {
      ToastUtil.error(outcome.errorMessage ?? '应用失败');
      return;
    }
    ToastUtil.success('已将当前 App Push Token 应用为 JPush Alias');
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

/// vue 模式插件未注册原生适配器时的引导占位。
/// 适配策略:特殊插件 ID 走原生适配器,vuetify 走通用渲染,
/// 其余 vue 插件留待逐插件适配,在此之前引导到 Web 端配置。
class _VueOnlyPlaceholder extends StatelessWidget {
  const _VueOnlyPlaceholder({this.webUrl});

  final String? webUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = webUrl?.trim() ?? '';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('该插件使用自定义界面', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '此插件的界面由 Web 前端组件渲染，App 暂未适配。请前往 Web 端完成配置或查看数据。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 16),
              SelectableText(
                url,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: url));
                      ToastUtil.success('已复制服务器地址');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('复制地址'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => WebUtil.open(url: url),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    label: const Text('打开 Web 端'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
