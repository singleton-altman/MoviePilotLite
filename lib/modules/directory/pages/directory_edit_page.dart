import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/directory/controllers/directory_edit_controller.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_option_visuals.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_field_state.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_form_row_builder.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/file_storage_utils.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

class DirectoryEditPage extends GetView<DirectoryEditController> {
  const DirectoryEditPage({super.key});

  SliverToBoxAdapter _buildSection(
    BuildContext context, {
    required String header,
    required List<String> envKeys,
    required SettingsFormRowBuilder rowBuilder,
  }) {
    final fields = controller.form.fields
        .where((f) => envKeys.contains(f.envKey))
        .toList();
    if (fields.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Section(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        header: SectionHeader(title: header),
        children: [
          for (final f in fields)
            rowBuilder.buildRow(
              context,
              f,
              editMode: true,
              readValue: (_) => null,
            ),
        ],
      ),
    );
  }

  Future<void> _confirmSave() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: Get.context!,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('保存'),
        content: const Text('确定保存修改？'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await controller.save();
      if (ok && Get.context != null) {
        Get.back(result: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rowBuilder = SettingsFormRowBuilder(
      form: controller.form,
      optionsOf: controller.optionsFor,
      optionLeadingOf: (ctx, enumKey, value) {
        if (enumKey == 'DIR_STORAGE') {
          return FileStorageUtils.storageIconWidget(value, size: 18);
        }
        return buildSettingsOptionLeading(ctx, enumKey, value);
      },
    );
    return Scaffold(
      appBar: AppBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.back(),
          child: const Icon(CupertinoIcons.back),
        ),
        title: const Text(
          '编辑目录',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isSaving.value ? null : _confirmSave,
              child: controller.isSaving.value
                  ? const CupertinoActivityIndicator()
                  : const Text('保存'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final mediaType = controller.form
              .state<SettingsSelectFieldState>('media_type')
              .value
              .value
              .trim();
          final mediaCategory = controller.form
              .state<SettingsSelectFieldState>('media_category')
              .value
              .value
              .trim();
          final monitorType = controller.form
              .state<SettingsSelectFieldState>('monitor_type')
              .value
              .value
              .trim()
              .toLowerCase();

          final showTypeFolder = mediaType.isEmpty && mediaCategory.isEmpty;
          final showCategoryFolder = mediaCategory.isEmpty; // 全部时允许按类别分类
          final isNoOrganize = monitorType == 'none';

          return CustomScrollView(
            slivers: [
              _buildSection(
                context,
                header: '基础信息',
                envKeys: ['name', 'priority', if (!isNoOrganize) 'notify'],
                rowBuilder: rowBuilder,
              ),
              _buildSection(
                context,
                header: '来源',
                envKeys: [
                  'media_type',
                  'media_category',
                  'storage',
                  'download_path',
                  if (showTypeFolder) 'download_type_folder',
                  if (showCategoryFolder) 'download_category_folder',
                ],
                rowBuilder: rowBuilder,
              ),
              _buildSection(
                context,
                header: '监控',
                envKeys: [
                  'monitor_type',
                  if (monitorType == 'monitor') 'monitor_mode',
                ],
                rowBuilder: rowBuilder,
              ),
              if (!isNoOrganize) ...[
                _buildSection(
                  context,
                  header: '媒体库',
                  envKeys: ['library_storage', 'library_path'],
                  rowBuilder: rowBuilder,
                ),
                _buildSection(
                  context,
                  header: '传输与覆盖',
                  envKeys: ['transfer_type', 'overwrite_mode'],
                  rowBuilder: rowBuilder,
                ),
                _buildSection(
                  context,
                  header: '分类与行为',
                  envKeys: [
                    'library_type_folder',
                    'library_category_folder',
                    'renaming',
                    'scraping',
                  ],
                  rowBuilder: rowBuilder,
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        }),
      ),
    );
  }
}
