import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/controllers/settings_advanced_detail_controller.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_enums.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';
import 'package:moviepilot_mobile/modules/settings/widgets/settings_field_row.dart';

/// 高级设置详情页：按基础设置风格，区块展示 系统、媒体、网络、日志、实验室
class SettingsAdvancedDetailPage
    extends GetView<SettingsAdvancedDetailController> {
  const SettingsAdvancedDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.back(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text(
          '高级设置',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
          context,
        ),
        border: null,
      ),
      child: Obx(() {
        if (controller.isLoading.value && controller.envData.value == null) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (controller.errorText.value != null) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.errorText.value ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: controller.load,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        return CustomScrollView(
          slivers: [
            for (final section in controller.sections)
              _buildSection(context, header: section.$1, fields: section.$2),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      }),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String header,
    required List<SettingsFieldConfig> fields,
  }) {
    if (fields.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
          context,
        ),
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text(
            header,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        children: [for (final field in fields) _buildFieldRow(context, field)],
      ),
    );
  }

  Widget _buildFieldRow(BuildContext context, SettingsFieldConfig field) {
    final value = controller.valueFor(field);
    final controlType = _toControlType(field.type);
    String? enumLabel;
    if (field.type == SettingsFieldType.select && field.enumKey != null) {
      enumLabel = enumValueToLabel(field.enumKey!, value);
    }
    dynamic displayValue = value;
    if (value is List && value.isNotEmpty) {
      displayValue = value.map((e) => e?.toString()).join(', ');
    }
    return SettingsFieldRow(
      title: field.label,
      compact: true,
      editMode: false,
      editable: false,
      controlType: controlType,
      controlValue: displayValue ?? value,
      unit: field.unit,
      enumLabel: enumLabel,
    );
  }

  SettingsControlType _toControlType(SettingsFieldType t) {
    switch (t) {
      case SettingsFieldType.text:
        return SettingsControlType.text;
      case SettingsFieldType.number:
        return SettingsControlType.number;
      case SettingsFieldType.select:
        return SettingsControlType.select;
      case SettingsFieldType.toggle:
        return SettingsControlType.toggle;
      case SettingsFieldType.textCopy:
        return SettingsControlType.textCopy;
    }
  }
}
