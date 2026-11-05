import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_folder_models.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

Future<void> showPluginMarketSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (sheetContext, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: PluginMarketSheet(scrollController: scrollController),
      ),
    ),
  );
}

class PluginMarketSheet extends StatefulWidget {
  const PluginMarketSheet({
    super.key,
    required this.scrollController,
    this.controller,
  });
  final ScrollController scrollController;
  final PluginController? controller;

  @override
  State<PluginMarketSheet> createState() => _PluginMarketSheetState();
}

class _PluginMarketSheetState extends State<PluginMarketSheet> {
  late final _controller = widget.controller ?? Get.find<PluginController>();
  late final String _scope;
  PluginFolders? _folders;
  List<PluginRemote>? _remotes;
  String? _foldersError;
  String? _remotesError;
  bool _foldersLoading = false;
  bool _remotesLoading = false;
  bool _savingFolders = false;
  bool _editing = false;

  bool get _canEdit =>
      !_foldersLoading &&
      !_savingFolders &&
      !_editing &&
      _folders != null &&
      _foldersError == null;

  @override
  void initState() {
    super.initState();
    _scope = _controller.managementScope;
    _loadFolders();
    _loadRemotes();
  }

  Future<void> _loadFolders() async {
    if (_foldersLoading || _savingFolders || _editing) return;
    setState(() {
      _foldersLoading = true;
      _foldersError = null;
    });
    try {
      final folders = await _controller.fetchFolders(_scope);
      if (mounted) setState(() => _folders = folders);
    } catch (error) {
      if (mounted) setState(() => _foldersError = error.toString());
    } finally {
      if (mounted) setState(() => _foldersLoading = false);
    }
  }

  Future<void> _loadRemotes() async {
    if (_remotesLoading) return;
    setState(() {
      _remotesLoading = true;
      _remotesError = null;
    });
    try {
      final remotes = await _controller.fetchRemotes(_scope);
      if (mounted) setState(() => _remotes = remotes);
    } catch (error) {
      if (mounted) setState(() => _remotesError = error.toString());
    } finally {
      if (mounted) setState(() => _remotesLoading = false);
    }
  }

  Future<void> _save(PluginFolders updated) async {
    if (!mounted || _savingFolders || _folders == null) return;
    setState(() => _savingFolders = true);
    try {
      await _controller.saveFolders(
        expected: _folders!,
        updated: updated,
        scope: _scope,
      );
      if (!mounted) return;
      setState(() => _folders = updated);
      ToastUtil.success('已保存');
    } catch (error) {
      if (!mounted) return;
      // Keep the last good snapshot visible, but require a successful refresh
      // before another full-document write (timeouts can have committed).
      setState(() => _foldersError = error.toString());
      ToastUtil.error(error.toString());
    } finally {
      if (mounted) setState(() => _savingFolders = false);
    }
  }

  Future<void> _editName([String? oldName]) async {
    if (!_canEdit) return;
    setState(() => _editing = true);
    var name = oldName ?? '';
    final formKey = GlobalKey<FormState>();
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(oldName == null ? '新建文件夹' : '重命名文件夹'),
          content: Form(
            key: formKey,
            child: TextFormField(
              initialValue: name,
              autofocus: true,
              maxLength: 128,
              decoration: const InputDecoration(labelText: '文件夹名称'),
              onChanged: (value) => name = value,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return '请输入名称';
                if (trimmed.length > 128) return '名称不能超过 128 个字符';
                if (trimmed != oldName && _folders!.names.contains(trimmed)) {
                  return '文件夹已存在';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, name.trim());
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      );
      if (!mounted || result == null || result == oldName) return;
      await _save(
        oldName == null
            ? _folders!.create(result)
            : _folders!.rename(oldName, result),
      );
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<void> _deleteFolder(String name) async {
    if (!_canEdit) return;
    setState(() => _editing = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('删除文件夹'),
          content: Text('删除“$name”仅移除分组，不会卸载其中的插件。确定继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      if (mounted && confirmed == true) await _save(_folders!.delete(name));
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  Future<void> _editMembers(String name) async {
    if (!_canEdit) return;
    setState(() => _editing = true);
    final original = _folders!.pluginsIn(name);
    final selected = original.toSet();
    final installed = {
      for (final item in _controller.items) item.id: item.pluginName,
    };
    // Keep unknown/unavailable members visible and selected, never silently
    // remove IDs merely because the installed-plugin list is stale or failed.
    final ids = {...original, ...installed.keys}.toList();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, updateDialog) => AlertDialog(
            title: Text('管理“$name”中的插件'),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: ids.isEmpty
                  ? const Center(child: Text('暂无可分组的已安装插件'))
                  : ListView(
                      children: [
                        for (final id in ids)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(installed[id] ?? id),
                            subtitle: Text(
                              installed.containsKey(id)
                                  ? id
                                  : '$id（未在当前列表中，保留已有成员）',
                            ),
                            value: selected.contains(id),
                            onChanged: (value) => updateDialog(() {
                              if (value == true) {
                                selected.add(id);
                              } else {
                                selected.remove(id);
                              }
                            }),
                          ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || confirmed != true) return;
      final updated = _folders!.withPlugins(name, ids.where(selected.contains));
      if (!updated.sameAs(_folders!)) await _save(updated);
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('插件分组与组件'),
        actions: [
          IconButton(
            tooltip: '关闭',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('插件文件夹分组')),
                    IconButton(
                      tooltip: '刷新分组',
                      onPressed: _foldersLoading || _savingFolders || _editing
                          ? null
                          : _loadFolders,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      tooltip: '新建文件夹',
                      onPressed: _canEdit ? () => _editName() : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const Text('点击文件夹管理成员；删除分组不会卸载插件。'),
                if (_foldersLoading || _savingFolders)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                if (_foldersError != null) _error(_foldersError!, _loadFolders),
                if (!_foldersLoading && _folders?.isEmpty == true)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('暂无文件夹分组'),
                  ),
                for (final name in _folders?.names ?? <String>[])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.folder_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(name),
                    subtitle: Text(
                      '${_folders!.pluginsIn(name).length} 个插件 · 管理成员',
                    ),
                    onTap: _canEdit ? () => _editMembers(name) : null,
                    trailing: PopupMenuButton<String>(
                      enabled: _canEdit,
                      tooltip: '文件夹操作',
                      onSelected: (action) {
                        if (action == 'members') _editMembers(name);
                        if (action == 'rename') _editName(name);
                        if (action == 'delete') _deleteFolder(name);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'members', child: Text('管理成员')),
                        PopupMenuItem(value: 'rename', child: Text('重命名')),
                        PopupMenuItem(value: 'delete', child: Text('删除分组')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('插件联邦组件')),
                    IconButton(
                      tooltip: '刷新组件',
                      onPressed: _remotesLoading ? null : _loadRemotes,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const Text('已加载插件提供的 Vue 模块联邦入口，仅展示元数据，不执行远程组件。'),
                if (_remotesLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (_remotesError != null)
                  _error(_remotesError!, _loadRemotes)
                else if (_remotes?.isEmpty == true)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('暂无联邦组件'),
                  )
                else
                  for (final remote in _remotes ?? <PluginRemote>[])
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.hub_outlined),
                      title: Text(remote.name),
                      subtitle: SelectableText(
                        [
                          '插件 ID：${remote.id}',
                          if (remote.sourcePluginId != null)
                            '源码插件：${remote.sourcePluginId}',
                          '组件入口：${remote.url}',
                        ].join('\n'),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(String message, VoidCallback retry) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        TextButton(onPressed: retry, child: const Text('重试')),
      ],
    ),
  );
}
