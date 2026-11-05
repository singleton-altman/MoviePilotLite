import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_list_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

import '../controllers/plugin_controller.dart';

Future<void> showPluginInfoSheet(BuildContext context, PluginItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.36,
        maxChildSize: 1,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: PluginInfoSheet(
              item: item,
              scrollController: scrollController,
            ),
          );
        },
      );
    },
  );
}

class PluginInfoSheet extends StatefulWidget {
  const PluginInfoSheet({super.key, required this.item, this.scrollController});

  final PluginItem item;
  final ScrollController? scrollController;

  @override
  State<PluginInfoSheet> createState() => _PluginInfoSheetState();
}

enum PluginInfoSheetState { normal, installing, installed }

class _PluginSheetHeader extends StatelessWidget {
  const _PluginSheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ) ??
                            TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClose,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: cs.onSurfaceVariant,
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
}

class _PluginInfoSheetState extends State<PluginInfoSheet> {
  final controller = Get.find<PluginController>();
  final isInstalling = PluginInfoSheetState.normal.obs;

  PluginListController? get pluginListController =>
      Get.isRegistered<PluginListController>()
      ? Get.find<PluginListController>()
      : null;

  @override
  void initState() {
    super.initState();
    isInstalling.value = widget.item.installed
        ? PluginInfoSheetState.installed
        : PluginInfoSheetState.normal;
  }

  @override
  void dispose() {
    isInstalling.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconUrl =
        widget.item.pluginIcon != null && widget.item.pluginIcon!.isNotEmpty
        ? ImageUtil.convertPluginIconUrl(widget.item.pluginIcon!)
        : '';
    return Material(
      color: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          children: [
            _PluginSheetHeader(
              title: widget.item.pluginName,
              onClose: Get.back,
            ),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  Center(
                    child: CachedImage(
                      imageUrl: iconUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
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
                            const Icon(Icons.person),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('作者: ${widget.item.pluginAuthor}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.code),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('版本: ${widget.item.pluginVersion}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.download),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('下载量: ${widget.item.installCount}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!Get.find<AppService>().canManage) {
                        ToastUtil.info('当前帐号无管理权限');
                        return;
                      }
                      if (isInstalling.value ==
                              PluginInfoSheetState.installing ||
                          isInstalling.value ==
                              PluginInfoSheetState.installed) {
                        return;
                      }

                      isInstalling.value = PluginInfoSheetState.installing;
                      final result = await controller.installPlugin(
                        widget.item,
                      );
                      if (mounted && result.success) {
                        ToastUtil.success('安装成功');
                        isInstalling.value = PluginInfoSheetState.installed;
                        controller.load(force: true);
                        pluginListController?.load(force: true);
                      } else {
                        isInstalling.value = PluginInfoSheetState.normal;
                        ToastUtil.error(result.message ?? '安装失败');
                      }
                    },
                    icon: const Icon(Icons.install_desktop, size: 18),
                    label: isInstalling.value == PluginInfoSheetState.installing
                        ? const CupertinoActivityIndicator()
                        : Text(_buildInstallButtonLabel(isInstalling.value)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isInstalling.value == PluginInfoSheetState.installing
                          ? colorScheme.primary.withValues(alpha: 0.5)
                          : colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
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

class SpecifiedPluginInstallSheet extends StatefulWidget {
  const SpecifiedPluginInstallSheet({
    super.key,
    this.initialRepoUrl = '',
    this.scrollController,
  });

  final String initialRepoUrl;
  final ScrollController? scrollController;

  @override
  State<SpecifiedPluginInstallSheet> createState() =>
      _SpecifiedPluginInstallSheetState();
}

class _SpecifiedPluginInstallSheetState
    extends State<SpecifiedPluginInstallSheet> {
  static const _defaultPluginRepoUrl =
      'https://github.com/singleton-altman/MoviePilot-Plugins';

  final _repoController = TextEditingController();
  final _repoFocusNode = FocusNode();
  final _controller = Get.find<PluginController>();

  bool _isLoading = false;
  String? _errorText;
  String? _resolvedRepoUrl;
  List<PluginItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _repoController.text = widget.initialRepoUrl;
  }

  @override
  void dispose() {
    _repoController.dispose();
    _repoFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final sheetColor = Theme.of(context).colorScheme.surface;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
        color: sheetColor,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              _PluginSheetHeader(
                title: '指定仓库安装',
                onClose: () {
                  FocusScope.of(context).unfocus();
                  Get.back();
                },
              ),
              Expanded(
                child: ListView(
                  controller: widget.scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    20 + bottomSafeArea + bottomInset,
                  ),
                  children: [
                    _buildInputSection(context),
                    const SizedBox(height: 16),
                    _buildStatusSection(context),
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildResultSection(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '输入 GitHub 插件仓库地址，点击获取后展示仓库内可安装插件。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _repoController,
            maxLines: 3,
            focusNode: _repoFocusNode,
            placeholder:
                '例如: https://github.com/singleton-altman/MoviePilot-Plugins.git',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            clearButtonMode: OverlayVisibilityMode.editing,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _loadRepoPlugins(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isLoading ? null : _fillDefaultPluginRepo,
              icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
              label: const Text('APPLitePush'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadRepoPlugins,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CupertinoActivityIndicator(),
                    )
                  : const Icon(Icons.cloud_download_outlined, size: 18),
              label: Text(_isLoading ? '获取中...' : '获取仓库插件'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    if (_isLoading) {
      return Section(
        child: Row(
          children: [
            const CupertinoActivityIndicator(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '正在读取仓库插件清单...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorText != null) {
      return Section(
        child: Text(
          _errorText!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            height: 1.4,
          ),
        ),
      );
    }

    if (_resolvedRepoUrl == null) {
      return Section(
        child: Text(
          '支持公开 GitHub 插件市场仓库，仅读取根目录 package.json / package.v2.json。'
          '请勿填写 MoviePilotLite 等 App 源码仓库。',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.72),
            height: 1.4,
          ),
        ),
      );
    }

    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('已解析仓库', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            _resolvedRepoUrl!,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '共发现 ${_items.length} 个插件，点击条目可继续安装。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(BuildContext context) {
    return Section(
      child: Column(
        children: [
          for (var index = 0; index < _items.length; index++) ...[
            _buildPluginListItem(context, _items[index]),
            if (index != _items.length - 1)
              Divider(
                height: 20,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.12),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPluginListItem(BuildContext context, PluginItem item) {
    final iconUrl = item.pluginIcon != null && item.pluginIcon!.isNotEmpty
        ? ImageUtil.convertPluginIconUrl(item.pluginIcon!)
        : '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openPluginDetail(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedImage(
                  imageUrl: iconUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.pluginName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildInstalledTag(context, item.installed),
                      ],
                    ),
                    if (item.pluginDesc != null &&
                        item.pluginDesc!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.pluginDesc!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.72),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildMetaChip(
                          context,
                          Icons.person_outline,
                          item.pluginAuthor?.trim().isNotEmpty == true
                              ? item.pluginAuthor!
                              : '未知作者',
                        ),
                        _buildMetaChip(
                          context,
                          Icons.code,
                          item.pluginVersion?.trim().isNotEmpty == true
                              ? 'v${item.pluginVersion}'
                              : '未标注版本',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstalledTag(BuildContext context, bool installed) {
    final cs = Theme.of(context).colorScheme;
    final color = installed ? Colors.green : cs.primary;
    final text = installed ? '已安装' : '去安装';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaChip(BuildContext context, IconData icon, String text) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.62);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Future<void> _openPluginDetail(PluginItem item) async {
    await showPluginInfoSheet(context, item);
    await _controller.load(force: true);
    if (!mounted) return;
    setState(() {
      _items = _applyInstalledState(_items);
    });
  }

  void _fillDefaultPluginRepo() {
    _repoController
      ..text = _defaultPluginRepoUrl
      ..selection = TextSelection.collapsed(
        offset: _defaultPluginRepoUrl.length,
      );
    _repoFocusNode.requestFocus();
  }

  Future<void> _loadRepoPlugins() async {
    FocusScope.of(context).unfocus();
    final repoUrl = _repoController.text.trim();
    if (repoUrl.isEmpty) {
      setState(() {
        _errorText = '请输入插件仓库地址';
        _resolvedRepoUrl = null;
        _items = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _resolvedRepoUrl = null;
      _items = const [];
    });

    try {
      final result = await _fetchRepoPlugins(repoUrl);
      if (!mounted) return;
      setState(() {
        _resolvedRepoUrl = result.repoUrl;
        _items = _applyInstalledState(result.items);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resolvedRepoUrl = null;
        _items = const [];
        _errorText = _friendlyRepoError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<_RepoPluginLoadResult> _fetchRepoPlugins(String rawRepoUrl) async {
    final repo = _parseGitHubRepository(rawRepoUrl);
    if (repo == null) {
      throw Exception('暂只支持公开 GitHub 仓库地址');
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {
          'accept': 'application/vnd.github+json',
          'x-github-api-version': '2022-11-28',
          'user-agent': 'MoviePilot-Mobile',
        },
        validateStatus: (_) => true,
      ),
    );

    final repoMetaResponse = await dio.get<dynamic>(repo.apiUrl);
    final repoMetaStatus = repoMetaResponse.statusCode ?? 0;
    if (repoMetaStatus >= 400 || repoMetaResponse.data is! Map) {
      throw Exception('仓库不存在或无法访问');
    }
    final repoMeta = Map<String, dynamic>.from(repoMetaResponse.data as Map);
    final defaultBranch =
        repoMeta['default_branch']?.toString().trim().isNotEmpty == true
        ? repoMeta['default_branch'].toString().trim()
        : 'master';
    final cloneUrl = repoMeta['clone_url']?.toString().trim().isNotEmpty == true
        ? repoMeta['clone_url'].toString().trim()
        : repo.cloneUrl;
    final htmlUrl = repoMeta['html_url']?.toString().trim().isNotEmpty == true
        ? repoMeta['html_url'].toString().trim()
        : repo.htmlUrl;

    final resolvedRepo = repo.copyWith(
      branch: defaultBranch,
      cloneUrl: cloneUrl,
      htmlUrl: htmlUrl,
    );

    final packageData = await _fetchPackageMap(
      dio,
      resolvedRepo,
      'package.json',
    );
    final packageV2Data = await _fetchPackageMap(
      dio,
      resolvedRepo,
      'package.v2.json',
    );
    final mergedPackageData = _mergePackageMaps(packageData, packageV2Data);

    final items = mergedPackageData.isEmpty
        ? const <PluginItem>[]
        : _mapPackageItems(resolvedRepo, mergedPackageData);

    if (items.isEmpty) {
      throw Exception(
        '仓库根目录未找到可用的 package.json / package.v2.json。'
        '请使用插件市场仓库（例如 MoviePilot-Plugins），'
        '而不是 App 源码仓库（如 MoviePilotLite）。',
      );
    }

    items.sort(
      (a, b) =>
          a.pluginName.toLowerCase().compareTo(b.pluginName.toLowerCase()),
    );
    return _RepoPluginLoadResult(repoUrl: resolvedRepo.htmlUrl, items: items);
  }

  Future<Map<String, dynamic>?> _fetchPackageMap(
    Dio dio,
    _GitHubRepository repo,
    String path,
  ) async {
    final response = await dio.get<dynamic>(
      'https://api.github.com/repos/${repo.owner}/${repo.name}/contents/$path',
      queryParameters: {'ref': repo.branch},
    );
    final status = response.statusCode ?? 0;
    if (status == 404) {
      return null;
    }
    if (status >= 400 || response.data is! Map) {
      throw Exception('读取仓库插件清单失败');
    }

    final payload = Map<String, dynamic>.from(response.data as Map);
    final content = payload['content']?.toString() ?? '';
    if (content.trim().isEmpty) {
      return null;
    }

    try {
      final normalized = content.replaceAll(RegExp(r'\s'), '');
      final decoded = utf8.decode(base64Decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return json;
      }
      if (json is Map) {
        return Map<String, dynamic>.from(json);
      }
      return null;
    } on FormatException {
      throw Exception('插件清单解析失败，请确认 package.json / package.v2.json 内容有效');
    }
  }

  String _friendlyRepoError(Object error) {
    if (error is FormatException) {
      return '插件清单解析失败，请确认仓库根目录的 package.json / package.v2.json 格式正确';
    }
    final text = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (text.contains('FormatException') ||
        text.contains('Unexpected character')) {
      return '插件清单解析失败，请确认仓库根目录的 package.json / package.v2.json 格式正确';
    }
    return text;
  }

  List<PluginItem> _mapPackageItems(
    _GitHubRepository repo,
    Map<String, dynamic> packageData,
  ) {
    final itemsById = <String, PluginItem>{};
    for (final entry in packageData.entries) {
      final pluginId = entry.key.trim();
      if (pluginId.isEmpty) continue;
      if (entry.value is! Map) continue;
      final meta = Map<String, dynamic>.from(entry.value as Map);
      final labels = meta['labels'];
      final history = meta['history'];
      itemsById[pluginId] = PluginItem(
        id: pluginId,
        pluginName: _stringValue(meta['name']) ?? pluginId,
        pluginDesc: _stringValue(meta['description']),
        pluginIcon: _resolvePluginIconUrl(repo, _stringValue(meta['icon'])),
        pluginVersion: _stringValue(meta['version']),
        pluginLabel: _stringifyLabels(labels),
        pluginAuthor: _stringValue(meta['author']) ?? repo.owner,
        authorUrl: _stringValue(meta['author_url']) ?? repo.htmlUrl,
        pluginConfigPrefix: _stringValue(meta['plugin_config_prefix']),
        pluginOrder: _intValue(meta['order']),
        authLevel: _intValue(meta['level'], fallback: 1),
        installed: false,
        state: false,
        hasPage: meta['has_page'] == true,
        hasUpdate: false,
        isLocal: false,
        repoUrl: repo.htmlUrl,
        installCount: 0,
        history: history is Map
            ? Map<String, dynamic>.from(history)
            : const <String, dynamic>{},
        addTime: 0,
        pluginPublicKey: _stringValue(meta['plugin_public_key']),
      );
    }
    return itemsById.values.toList();
  }

  Map<String, dynamic> _mergePackageMaps(
    Map<String, dynamic>? packageData,
    Map<String, dynamic>? packageV2Data,
  ) {
    final merged = <String, dynamic>{};
    if (packageData != null) {
      merged.addAll(packageData);
    }
    if (packageV2Data != null) {
      merged.addAll(packageV2Data);
    }
    return merged;
  }

  List<PluginItem> _applyInstalledState(List<PluginItem> items) {
    final installedIds = _controller.items.map((item) => item.id).toSet();
    return items
        .map(
          (item) => item.copyWith(
            installed: installedIds.contains(item.id),
            state: installedIds.contains(item.id),
          ),
        )
        .toList();
  }

  String? _resolvePluginIconUrl(_GitHubRepository repo, String? icon) {
    if (icon == null || icon.trim().isEmpty) return null;
    final raw = icon.trim();
    if (raw.toLowerCase().startsWith('http')) {
      return raw;
    }
    final normalized = raw.startsWith('/')
        ? raw.substring(1)
        : raw.startsWith('icons/') || raw.startsWith('plugins/')
        ? raw
        : 'icons/$raw';
    return repo.rawFileUrl(normalized);
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _stringifyLabels(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final labels = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      return labels.isEmpty ? null : labels.join(',');
    }
    return _stringValue(value);
  }

  int _intValue(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  _GitHubRepository? _parseGitHubRepository(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    String normalized = trimmed;
    if (trimmed.startsWith('git@github.com:')) {
      normalized =
          'https://github.com/${trimmed.substring('git@github.com:'.length)}';
    } else if (!trimmed.contains('://') &&
        RegExp(r'^[^/\s]+/[^/\s]+$').hasMatch(trimmed)) {
      normalized = 'https://github.com/$trimmed';
    } else if (!trimmed.contains('://')) {
      normalized = 'https://$trimmed';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host != 'github.com' && host != 'www.github.com') {
      return null;
    }

    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.length < 2) return null;
    final owner = segments[0].trim();
    final name = segments[1].trim().replaceFirst(RegExp(r'\.git$'), '');
    if (owner.isEmpty || name.isEmpty) return null;

    return _GitHubRepository(owner: owner, name: name);
  }
}

class _RepoPluginLoadResult {
  const _RepoPluginLoadResult({required this.repoUrl, required this.items});

  final String repoUrl;
  final List<PluginItem> items;
}

class _GitHubRepository {
  const _GitHubRepository({
    required this.owner,
    required this.name,
    this.branch = 'master',
    String? cloneUrl,
    String? htmlUrl,
  }) : cloneUrl = cloneUrl ?? 'https://github.com/$owner/$name.git',
       htmlUrl = htmlUrl ?? 'https://github.com/$owner/$name';

  final String owner;
  final String name;
  final String branch;
  final String cloneUrl;
  final String htmlUrl;

  String get apiUrl => 'https://api.github.com/repos/$owner/$name';

  String rawFileUrl(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.https(
      'raw.githubusercontent.com',
      '/$owner/$name/$branch/$normalized',
    ).toString();
  }

  _GitHubRepository copyWith({
    String? branch,
    String? cloneUrl,
    String? htmlUrl,
  }) {
    return _GitHubRepository(
      owner: owner,
      name: name,
      branch: branch ?? this.branch,
      cloneUrl: cloneUrl ?? this.cloneUrl,
      htmlUrl: htmlUrl ?? this.htmlUrl,
    );
  }
}
