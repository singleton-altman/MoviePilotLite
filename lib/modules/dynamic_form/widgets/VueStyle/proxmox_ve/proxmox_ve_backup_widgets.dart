import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/proxmox_ve_backup_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/VueStyle/proxmox_ve/proxmox_ve_backup_header.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

/// 向注册表注册 ProxmoxVEBackup 自定义渲染器
void registerProxmoxVeBackupRenderer() {
  PluginFormAdapterRegistry.registerRenderer('ProxmoxVEBackup', (
    context,
    blocks,
    controller,
    formMode,
    buildBlock,
  ) {
    Widget proxmoxBuildBlock(BuildContext ctx, FormBlock b) {
      if (formMode && b is PageHeaderBlock) {
        return SectionHeader(title: b.title, subtitle: b.subtitle);
      }
      return buildBlock(ctx, b);
    }

    return formMode
        ? ProxmoxFormRenderer(
            blocks: blocks,
            controller: controller,
            buildBlock: proxmoxBuildBlock,
          )
        : ProxmoxPageRenderer(
            blocks: blocks,
            controller: controller,
            buildBlock: buildBlock,
          );
  });
}

/// Proxmox 页面/表单内容渲染器：顶部 ProxmoxVeBackupHeader + 下方区块列表
class ProxmoxPageRenderer extends StatelessWidget {
  const ProxmoxPageRenderer({
    super.key,
    required this.blocks,
    required this.controller,
    required this.buildBlock,
  });

  final List<FormBlock> blocks;
  final DynamicFormController controller;
  final Widget Function(BuildContext context, FormBlock block) buildBlock;

  @override
  Widget build(BuildContext context) {
    final proxmoxAdapter =
        controller.pluginAdapter is ProxmoxVEBackupFormController
        ? controller.pluginAdapter! as ProxmoxVEBackupFormController
        : null;

    return Obx(() {
      final pveStatusValue = proxmoxAdapter?.pveStatus.value;
      final showHeader = pveStatusValue != null && pveStatusValue.isNotEmpty;

      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: showHeader ? 0 : 12, bottom: 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                blocks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final block = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: index < blocks.length - 1 ? 8 : 0,
                    ),
                    child: Section(child: buildBlock(context, block)),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Proxmox 表单内容渲染器：对表单控件使用增强样式
class ProxmoxFormRenderer extends StatelessWidget {
  const ProxmoxFormRenderer({
    super.key,
    required this.blocks,
    required this.controller,
    required this.buildBlock,
  });

  final List<FormBlock> blocks;
  final DynamicFormController controller;
  final Widget Function(BuildContext context, FormBlock block) buildBlock;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemCount: blocks.length,
      itemBuilder: (context, index) => buildBlock(context, blocks[index]),
    );
  }
}
