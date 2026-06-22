import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/directory/controllers/directory_display_utils.dart';
import 'package:moviepilot_mobile/modules/directory/controllers/directory_edit_controller.dart';
import 'package:moviepilot_mobile/modules/directory/controllers/directory_list_controller.dart';
import 'package:moviepilot_mobile/modules/setting/models/setting_models.dart';
import 'package:moviepilot_mobile/modules/directory/pages/directory_edit_page.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/file_storage_utils.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 目录列表页
/// 纯展示列表，点击进入编辑页
class DirectoryListPage extends GetView<DirectoryListController> {
  const DirectoryListPage({super.key});

  Widget _buildStatusView(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: onRetry,
                child: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.back(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('目录', style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: Obx(() {
          if (!controller.isLoading.value) return const SizedBox.shrink();
          return const Padding(
            padding: EdgeInsets.only(right: 8),
            child: CupertinoActivityIndicator(),
          );
        }),
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
          context,
        ),
        border: null,
      ),
      body: SafeArea(
        child: Obx(() {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () => controller.loadDirectories(force: true),
              ),
              if (controller.errorText.value != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildStatusView(
                    context,
                    message: controller.errorText.value ?? '',
                    onRetry: () => controller.loadDirectories(force: true),
                  ),
                )
              else if (controller.directories.isEmpty &&
                  !controller.isLoading.value)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildStatusView(context, message: '暂无目录配置'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  sliver: SliverToBoxAdapter(
                    child: controller.directories.isEmpty
                        ? const SizedBox.shrink()
                        : Section(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: EdgeInsets.zero,
                            separatorBuilder: (ctx) => Divider(
                              height: 1,
                              thickness: 0.6,
                              color: CupertinoColors.separator
                                  .resolveFrom(ctx)
                                  .withValues(alpha: 0.25),
                            ),
                            children: [
                              for (
                                var i = 0;
                                i < controller.directories.length;
                                i++
                              )
                                _DirectoryListTile(
                                  index: i,
                                  directory: controller.directories[i],
                                ),
                            ],
                          ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _DirectoryListTile extends StatelessWidget {
  const _DirectoryListTile({required this.index, required this.directory});

  final int index;
  final DirectorySetting directory;

  Color _monitorColor(BuildContext context) {
    final t = directory.monitorType.trim().toLowerCase();
    if (t == 'monitor') return CupertinoColors.activeGreen.resolveFrom(context);
    if (t == 'downloader') {
      return CupertinoColors.activeBlue.resolveFrom(context);
    }
    if (t == 'manual') return CupertinoColors.activeOrange.resolveFrom(context);
    return CupertinoColors.tertiaryLabel.resolveFrom(context);
  }

  Widget _sIcon(IconData icon, Color color) {
    return Icon(icon, size: 14, color: color);
  }

  Widget _kv(
    BuildContext context, {
    required String k,
    required String v,
    Widget? leading,
  }) {
    final kColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final vColor = CupertinoColors.label.resolveFrom(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 4)],
        Text('$k ', style: TextStyle(fontSize: 12, color: kColor)),
        Text(
          v,
          style: TextStyle(fontSize: 12, color: vColor),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _dotSep(BuildContext context, List<Widget> parts) {
    final dotColor = CupertinoColors.tertiaryLabel.resolveFrom(context);
    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      if (i != 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('·', style: TextStyle(color: dotColor)),
          ),
        );
      }
      children.add(Flexible(child: parts[i]));
    }
    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final title = DirectoryDisplayUtils.formatDirectoryName(directory);
    final monitorLabel = DirectoryDisplayUtils.formatMonitorType(directory);
    final storageLabel = DirectoryDisplayUtils.formatStorageName(directory);
    final transferLabel = directory.transferType.isEmpty
        ? null
        : DirectoryDisplayUtils.formatTransferType(directory);
    final mediaTypeLabel = directory.mediaType.isEmpty
        ? '全部'
        : directory.mediaType;
    final mediaLabel = directory.mediaCategory.isEmpty
        ? mediaTypeLabel
        : '$mediaTypeLabel/${directory.mediaCategory}';

    final hasLibrary = directory.libraryPath.isNotEmpty;
    final fromText = directory.downloadPath.isNotEmpty
        ? directory.downloadPath
        : '未设置资源目录';
    final toText = directory.libraryPath.isNotEmpty
        ? directory.libraryPath
        : '未设置媒体库目录';

    final flags = <String>[];
    if (directory.notify) flags.add('通知');
    if (directory.downloadTypeFolder) flags.add('源按类型');
    if (directory.downloadCategoryFolder) flags.add('源按类别');
    if (directory.libraryTypeFolder) flags.add('库按类型');
    if (directory.libraryCategoryFolder) flags.add('库按类别');
    if (directory.renaming) flags.add('重命名');
    if (directory.scraping) flags.add('刮削');

    final monitorColor = _monitorColor(context);
    final cardBg = CupertinoColors.systemGrey6.resolveFrom(context);
    final cardBorder = CupertinoColors.separator
        .resolveFrom(context)
        .withValues(alpha: 0.15);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final ok = await Get.to(
          () => const DirectoryEditPage(),
          binding: BindingsBuilder(() {
            Get.put(DirectoryEditController());
          }),
          arguments: {'index': index},
        );
        if (ok == true) {
          ToastUtil.success('保存成功');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.dot_radiowaves_left_right,
                  size: 14,
                  color: monitorColor,
                ),
                const SizedBox(width: 4),
                Text(
                  monitorLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: monitorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _dotSep(context, [
              _kv(
                context,
                k: '媒体',
                v: mediaLabel,
                leading: _sIcon(
                  CupertinoIcons.film,
                  CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              _kv(
                context,
                k: '存储',
                v: storageLabel,
                leading: _sIcon(
                  CupertinoIcons.folder,
                  CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              if (transferLabel != null)
                _kv(
                  context,
                  k: '整理',
                  v: transferLabel,
                  leading: _sIcon(
                    CupertinoIcons.arrow_turn_up_right,
                    CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FileStorageUtils.storageIconWidget(
                        directory.storage,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fromText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasLibrary) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 26,
                        top: 6,
                        bottom: 6,
                      ),
                      child: Icon(
                        CupertinoIcons.arrow_down_right,
                        size: 14,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        FileStorageUtils.storageIconWidget(
                          directory.libraryStorage,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            toText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (flags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sIcon(
                          CupertinoIcons.slider_horizontal_3,
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            flags.join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.25,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
