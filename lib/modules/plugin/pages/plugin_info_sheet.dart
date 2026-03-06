import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_list_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

import '../controllers/plugin_controller.dart';

class PluginInfoSheet extends StatefulWidget {
  const PluginInfoSheet({super.key, required this.item});
  final PluginItem item;
  @override
  State<PluginInfoSheet> createState() => _PluginInfoSheetState();
}

enum PluginInfoSheetState { normal, installing, installed }

class _PluginInfoSheetState extends State<PluginInfoSheet> {
  final controller = Get.find<PluginController>();
  final pluginListController = Get.put(PluginListController());
  final isInstalling = PluginInfoSheetState.normal.obs;
  @override
  Widget build(BuildContext context) {
    final iconUrl =
        widget.item.pluginIcon != null && widget.item.pluginIcon!.isNotEmpty
        ? ImageUtil.convertPluginIconUrl(widget.item.pluginIcon!)
        : '';
    return Material(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            SectionHeader(
              title: widget.item.pluginName,
              trailing: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  Get.back();
                },
              ),
            ),
            CachedImage(
              imageUrl: iconUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text(
              widget.item.pluginDesc ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Section(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person),
                      const SizedBox(width: 8),
                      Text('作者: ${widget.item.pluginAuthor}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.code),
                      const SizedBox(width: 8),
                      Text('版本: ${widget.item.pluginVersion}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.download),
                      const SizedBox(width: 8),
                      Text('下载量: ${widget.item.installCount}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Obx(
                  () => Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (isInstalling.value ==
                                PluginInfoSheetState.installing ||
                            isInstalling.value ==
                                PluginInfoSheetState.installed) {
                          return;
                        }

                        isInstalling.value = PluginInfoSheetState.installing;
                        final success = await controller.installPlugin(
                          widget.item,
                        );
                        if (mounted && success) {
                          ToastUtil.success('安装成功');
                          isInstalling.value = PluginInfoSheetState.installed;
                          controller.load(force: true);
                          pluginListController.load(force: true);
                        } else {
                          ToastUtil.error('安装失败');
                        }
                      },
                      icon: Icon(Icons.install_desktop, size: 18),
                      label:
                          isInstalling.value == PluginInfoSheetState.installing
                          ? const CupertinoActivityIndicator()
                          : Text(_buildInstallButtonLabel(isInstalling.value)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isInstalling.value ==
                                PluginInfoSheetState.installing
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5)
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildInstallButtonLabel(PluginInfoSheetState state) {
    switch (state) {
      case PluginInfoSheetState.normal:
        return '安装';
      case PluginInfoSheetState.installing:
        return '安装中...';
      case PluginInfoSheetState.installed:
        return '已安装';
    }
  }
}
