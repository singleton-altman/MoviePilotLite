import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_enums.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_form_row_builder.dart';
import 'package:moviepilot_mobile/modules/settings/widgets/settings_field_row.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_edit_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_media_enums.dart';
import 'package:moviepilot_mobile/modules/subscribe/pages/priority_rule_order_picker_page.dart'
    show PriorityRulePickerSheet;
import 'package:moviepilot_mobile/modules/search/pages/search_mid_sheet.dart'
    show SiteSelectSheet, SiteSelectScene;
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 订阅编辑页
class SubscribeEditPage extends GetView<SubscribeEditController> {
  const SubscribeEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rowBuilder = SettingsFormRowBuilder(
      form: controller.form,
      optionsOf: (k) {
        switch (k) {
          case 'SUB_QUALITY':
            return MediaQuality.selectOptions;
          case 'SUB_RESOLUTION':
            return MediaResolution.selectOptions;
          case 'SUB_EFFECT':
            return MediaEffect.selectOptions;
          case 'SUB_DOWNLOADER':
            return [
              const SettingsEnumOption(value: '', label: '默认'),
              ...controller.downloaders.map(
                (s) => SettingsEnumOption(value: s, label: s),
              ),
            ];
          case 'SUB_SAVE_PATH':
            return [
              const SettingsEnumOption(value: '', label: '自动'),
              ...controller.savePaths.map(
                (s) => SettingsEnumOption(value: s, label: s),
              ),
            ];
          default:
            return settingsEnums[k] ?? const [];
        }
      },
      onCopied: (_) => ToastUtil.success('已复制'),
    );

    return Obx(() {
      final item = controller.item;
      return Scaffold(
        appBar: AppBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              if (controller.hasUnsavedEdits) {
                final discard = await showCupertinoDialog<bool>(
                  context: Get.context!,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('返回'),
                    content: const Text('有未保存修改，是否放弃？'),
                    actions: [
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('继续编辑'),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('放弃'),
                      ),
                    ],
                  ),
                );
                if (discard != true) return;
              }
              Get.back();
            },
            child: const Icon(CupertinoIcons.back),
          ),
          title: Row(
            children: [
              CachedImage(
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(28),
                imageUrl: ImageUtil.convertCacheImageUrl(item.poster ?? ''),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name ?? '订阅编辑',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (controller.isDetailLoading.value) ...[
                const SizedBox(width: 8),
                const CupertinoActivityIndicator(radius: 8),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ToastUtil.warning(
                  '确定取消订阅吗？',
                  onConfirm: () async {
                    final ok = await controller.deleteSubscribe();
                    if (ok && context.mounted) {
                      Future.delayed(const Duration(seconds: 1), () {
                        ToastUtil.success('订阅 ${controller.item.name} 取消订阅成功');
                      });
                      Get.back(result: true);
                    }
                  },
                );
              },
              child: Text(
                '取消订阅',
                style: TextStyle(
                  color: CupertinoColors.destructiveRed.resolveFrom(context),
                ),
              ),
            ),
            Obx(
              () => TextButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                        final ok = await controller.save();
                        if (ok && context.mounted) {
                          Future.delayed(const Duration(seconds: 1), () {
                            ToastUtil.success(
                              '订阅 ${controller.item.name} 编辑成功',
                            );
                          });
                          Get.back(result: true);
                        }
                      },
                child: controller.isSaving.value
                    ? const CupertinoActivityIndicator()
                    : const Text('保存'),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refreshPage,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const SizedBox(height: 8),
                  ..._buildSections(context, rowBuilder),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (controller.isSaving.value)
              Container(
                color: CupertinoColors.black.withValues(alpha: 0.12),
                child: const Center(child: CupertinoActivityIndicator()),
              ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildSections(
    BuildContext context,
    SettingsFormRowBuilder rowBuilder,
  ) {
    final isTv = controller.item.type?.contains('电视') == true;

    List<SettingsFieldConfig> byKeys(List<String> keys) {
      return SubscribeEditController.formFields
          .where((f) => keys.contains(f.envKey))
          .toList();
    }

    Widget section(String header, List<Widget> children) {
      return Section(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        header: SectionHeader(
          title: header,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        children: children,
      );
    }

    final widgets = <Widget>[];

    widgets.add(
      section('搜索', [
        for (final f in byKeys(['keyword']))
          rowBuilder.buildRow(
            context,
            f,
            editMode: controller.isEditing.value,
            readValue: (_) => null,
          ),
      ]),
    );

    if (isTv) {
      widgets.add(
        section('剧集信息', [
          for (final f in byKeys(['total_episode', 'start_episode']))
            rowBuilder.buildRow(
              context,
              f,
              editMode: controller.isEditing.value,
              readValue: (_) => null,
            ),
        ]),
      );
    }

    widgets.add(
      section('订阅资源属性', [
        for (final f in byKeys(['quality', 'resolution', 'effect']))
          rowBuilder.buildRow(
            context,
            f,
            editMode: controller.isEditing.value,
            readValue: (_) => null,
          ),
      ]),
    );

    widgets.add(section('订阅站点', [_buildSitePicker(context)]));

    widgets.add(
      section('下载设置', [
        for (final f in byKeys(['downloader', 'save_path']))
          rowBuilder.buildRow(
            context,
            f,
            editMode: controller.isEditing.value,
            readValue: (_) => null,
          ),
      ]),
    );

    widgets.add(
      section('开关设置', [
        for (final f in byKeys(['best_version', 'search_imdbid']))
          rowBuilder.buildRow(
            context,
            f,
            editMode: controller.isEditing.value,
            readValue: (_) => null,
          ),
      ]),
    );

    widgets.add(
      section('包含/排除规则', [
        for (final f in byKeys(['include', 'exclude']))
          rowBuilder.buildRow(
            context,
            f,
            editMode: controller.isEditing.value,
            readValue: (_) => null,
          ),
      ]),
    );

    widgets.add(section('优先级规则', [_buildPriorityRulePicker(context)]));

    if (isTv) {
      widgets.add(
        section('剧集/季指定', [
          for (final f in byKeys(['episode_group', 'season']))
            rowBuilder.buildRow(
              context,
              f,
              editMode: controller.isEditing.value,
              readValue: (_) => null,
            ),
        ]),
      );
    }

    widgets.add(
      section('自定义', [
        for (final f in byKeys(['media_category', 'custom_words']))
          rowBuilder.buildRow(
            context,
            f,
            editMode: controller.isEditing.value,
            readValue: (_) => null,
          ),
      ]),
    );

    return widgets;
  }

  // legacy row builders removed

  Widget _buildSitePicker(BuildContext context) {
    return Obx(() {
      final allSites = controller.allSites;
      final selectedIds = controller.selectedSiteIds.toList();
      final names = selectedIds
          .map(
            (id) =>
                allSites.where((s) => s.id == id).firstOrNull?.name ??
                id.toString(),
          )
          .where((s) => s.isNotEmpty)
          .toList();
      final display = names.isEmpty ? '不选使用系统设置' : names.join('、');
      return SettingsFieldRow(
        title: '订阅站点',
        description: '订阅的站点范围，不选使用系统设置',
        control: _buildNavControl(
          context,
          display: display.length > 14
              ? '${display.substring(0, 14)}…'
              : display,
          onTap: () async {
            final result =
                await showModalBottomSheet<({String area, List<int> sites})>(
              context: context,
              builder: (ctx) {
                final allIds = controller.allSites.map((s) => s.id).toSet();
                final selectable = controller.selectableSiteIds;
                final disabled = (selectable == null || selectable.isEmpty)
                    ? const <int>[]
                    : allIds.difference(selectable).toList();
                return SiteSelectSheet(
                  hasSegment: false,
                  scene: SiteSelectScene.subscribe,
                  initialSelectedIds: selectedIds,
                  disabledIds: disabled,
                );
              },
            );
            if (result != null) controller.setSelectedSites(result.sites);
          },
        ),
      );
    });
  }

  // legacy pickers removed

  Widget _buildPriorityRulePicker(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedPriorityRuleNames.toList();
      final display = selected.isEmpty ? '未选择' : '${selected.length} 项';
      return SettingsFieldRow(
        title: '优先级规则组',
        description: '按选定的过滤规则组对订阅进行过滤',
        control: _buildNavControl(
          context,
          display: display,
          onTap: () async {
            final result = await PriorityRulePickerSheet.show(
              context,
              rules: controller.priorityRules,
              initialSelectedNames: selected,
            );
            if (result != null) controller.setPriorityRuleNames(result);
          },
        ),
      );
    });
  }

  // legacy season picker removed

  /// iOS 设置风格：右箭头 + 可点击进入详情
  Widget _buildNavControl(
    BuildContext context, {
    required String display,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              display,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.activeBlue.resolveFrom(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 12,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
        ],
      ),
    );
  }
}
