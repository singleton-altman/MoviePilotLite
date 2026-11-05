import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/brush_flow_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/brush_flow/brush_flow_task_edit_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/brush_flow/brush_flow_task_form_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_form_row_builder.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:skeletonizer/skeletonizer.dart';

Future<bool?> openBrushFlowTaskEditPage({
  String? taskId,
  List<BrushFlowOption> sites = const [],
  List<BrushFlowOption> downloaders = const [],
}) async {
  return await Get.to<bool>(
    () => BrushFlowTaskEditPage(
      taskId: taskId,
      sites: sites,
      downloaders: downloaders,
    ),
  );
}

class BrushFlowTaskEditPage extends StatefulWidget {
  const BrushFlowTaskEditPage({
    super.key,
    this.taskId,
    this.sites = const [],
    this.downloaders = const [],
  });

  final String? taskId;
  final List<BrushFlowOption> sites;
  final List<BrushFlowOption> downloaders;

  @override
  State<BrushFlowTaskEditPage> createState() => _BrushFlowTaskEditPageState();
}

class _BrushFlowTaskEditPageState extends State<BrushFlowTaskEditPage> {
  late final String _tag;
  late final BrushFlowTaskEditController controller;

  @override
  void initState() {
    super.initState();
    _tag = 'brush_flow_task_edit_${widget.taskId ?? 'create'}_$hashCode';
    controller = Get.put(
      BrushFlowTaskEditController(
        taskId: widget.taskId,
        sites: widget.sites,
        downloaders: widget.downloaders,
      ),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<BrushFlowTaskEditController>(tag: _tag)) {
      Get.delete<BrushFlowTaskEditController>(tag: _tag);
    }
    super.dispose();
  }

  Future<void> _onSave() async {
    final ok = await controller.save();
    if (ok && mounted) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final rowBuilder = SettingsFormRowBuilder(
      form: controller.form,
      optionsOf: controller.optionsFor,
    );
    return Scaffold(
      backgroundColor: palette.pageBackground,
      appBar: AppBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.back(),
          child: const Icon(CupertinoIcons.back),
        ),
        title: Text(
          controller.isCreate ? '新建刷流任务' : '编辑刷流任务',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Obx(() {
            if (controller.isSaving.value) {
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(child: CupertinoActivityIndicator()),
              );
            }
            return TextButton(onPressed: _onSave, child: const Text('保存'));
          }),
        ],
      ),
      body: Obx(() {
        final loading = controller.isLoading.value && controller.config.value == null;
        final error = controller.errorText.value;
        if (error != null && controller.config.value == null && !loading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: controller.load,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        final segment = controller.segment.value;
        final fields = BrushFlowTaskFormConfig.fieldsBySegment[segment] ??
            const <SettingsFieldConfig>[];
        final displayFields = loading ? fields.take(5).toList() : fields;
        return Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                itemCount: BrushFlowTaskFormSegment.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = BrushFlowTaskFormSegment.values[index];
                  final selected = item == segment;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.segment.value = item,
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.primary.withValues(alpha: 0.14)
                                : palette.surfaceAlt,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? palette.primary
                                  : palette.tileBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? palette.primary
                                    : palette.mutedText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Skeletonizer(
                enabled: loading,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    Section(
                      padding: EdgeInsets.zero,
                      children: displayFields
                          .map(
                            (field) => rowBuilder.buildRow(
                              context,
                              field,
                              editMode: true,
                              readValue: (key) =>
                                  controller.form.effectiveValue(key),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
