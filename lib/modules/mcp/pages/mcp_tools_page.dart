import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/mcp/controllers/mcp_tools_controller.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/constrained_page_content.dart';
import 'package:moviepilot_mobile/widgets/glass_search_floating_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

class McpToolsPage extends StatefulWidget {
  const McpToolsPage({super.key});

  @override
  State<McpToolsPage> createState() => _McpToolsPageState();
}

class _McpToolsPageState extends State<McpToolsPage>
    with SingleTickerProviderStateMixin {
  McpToolsController get controller => Get.find<McpToolsController>();
  late final TabController _tabs;
  int _section = 0;
  String _toolSearch = '';
  String _serverSearch = '';
  bool? _enabledFilter;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_section != _tabs.index) {
        setState(() => _section = _tabs.index);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTools = _section == 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP 工具'),
        actions: [
          if (!isTools)
            Obx(() {
              final canEdit =
                  controller.serversLoaded.value &&
                  controller.serversError.value == null &&
                  !controller.isLoadingServers.value &&
                  !controller.isSavingServers.value;
              return IconButton(
                tooltip: '添加服务器',
                onPressed: canEdit ? () => _editServer(context) : null,
                icon: const Icon(CupertinoIcons.add),
              );
            }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: ConstrainedPageContent.maxWidth,
        child: GlassSearchFloatingBar(
          keyword: isTools ? _toolSearch : _serverSearch,
          searchPlaceholder: isTools ? '搜索工具名称或描述' : '搜索名称、ID 或传输方式',
          onKeywordSubmitted: (value) {
            if (!mounted) return;
            setState(() {
              if (isTools) {
                _toolSearch = value.trim();
              } else {
                _serverSearch = value.trim();
              }
            });
          },
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ConstrainedPageContent(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: _SegmentPicker<int>(
                  value: _section,
                  options: const {0: '工具', 1: '服务器'},
                  onChanged: _tabs.animateTo,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [_toolsTab(context), _serversTab(context)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolsTab(BuildContext context) => Obx(() {
    final loading = controller.isLoadingTools.value;
    final error = controller.toolsError.value;
    final tools = controller.tools.toList();
    final query = _toolSearch.toLowerCase();
    final filtered = tools
        .where(
          (tool) =>
              tool.name.toLowerCase().contains(query) ||
              (tool.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();
    final initialLoading = loading && tools.isEmpty;
    return RefreshIndicator(
      onRefresh: controller.loadTools,
      child: CustomScrollView(
        key: const PageStorageKey('mcp-tools'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ListHeading(
                  title: initialLoading || (error != null && tools.isEmpty)
                      ? '可用工具'
                      : '可用工具 · ${tools.length}',
                  subtitle: query.isEmpty
                      ? '点击工具查看详情'
                      : '找到 ${filtered.length} 个工具',
                  loading: loading,
                  onRefresh: controller.loadTools,
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorNotice(message: error, retry: controller.loadTools),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (initialLoading)
            SliverToBoxAdapter(
              child: Skeletonizer(
                child: Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: _ToolCard(
                        tool: McpToolInfo(
                          name: '工具名称',
                          description: '正在获取工具的说明与参数信息',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (tools.isEmpty && error == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                icon: Icons.extension_outlined,
                title: '暂无可用工具',
                description: '暂无可用工具，可下拉刷新',
              ),
            )
          else if (filtered.isEmpty && tools.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                icon: Icons.search_off_rounded,
                title: '没有匹配的工具',
                description: '试试其他名称或描述关键词。',
                action: TextButton(
                  onPressed: () => setState(() => _toolSearch = ''),
                  child: const Text('清除搜索'),
                ),
              ),
            )
          else
            SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _ToolCard(
                tool: filtered[index],
                onTap: () => _showMcpSheet(
                  context,
                  _ToolDetail(controller: controller, tool: filtered[index]),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  GlassSearchFloatingBar.height +
                  32 +
                  MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  });

  Widget _serversTab(BuildContext context) => Obx(() {
    final loading = controller.isLoadingServers.value;
    final error = controller.serversError.value;
    final busy = controller.isSavingServers.value || loading;
    final testing = controller.isTestingServer.value;
    final canEdit = controller.serversLoaded.value && error == null && !busy;
    final servers = controller.servers.toList();
    final query = _serverSearch.toLowerCase();
    final filtered = servers
        .where(
          (server) =>
              (_enabledFilter == null || server.enabled == _enabledFilter) &&
              (server.name.toLowerCase().contains(query) ||
                  server.id.toLowerCase().contains(query) ||
                  (server.transport?.toLowerCase().contains(query) ?? false)),
        )
        .toList();
    final initialLoading = loading && servers.isEmpty;
    final countKnown = controller.serversLoaded.value && error == null;
    return RefreshIndicator(
      onRefresh: controller.loadServers,
      child: CustomScrollView(
        key: const PageStorageKey('mcp-servers'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SegmentPicker<int>(
                  value: _enabledFilter == null ? 0 : (_enabledFilter! ? 1 : 2),
                  options: const {0: '全部', 1: '已启用', 2: '已停用'},
                  onChanged: (value) => setState(
                    () => _enabledFilter = value == 0 ? null : value == 1,
                  ),
                ),
                const SizedBox(height: 12),
                _ListHeading(
                  title: countKnown
                      ? '服务器配置 · ${filtered.length}/${servers.length}'
                      : '服务器配置',
                  subtitle: '启用不代表连接正常，请使用测试连接验证',
                  loading: loading,
                  onRefresh: busy ? null : controller.loadServers,
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorNotice(message: error, retry: controller.loadServers),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (initialLoading)
            const SliverToBoxAdapter(
              child: Skeletonizer(
                child: _ToolCard(
                  tool: McpToolInfo(name: '服务器名称', description: '正在读取完整服务器配置'),
                ),
              ),
            )
          else if (servers.isEmpty && error == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                icon: Icons.dns_outlined,
                title: '还没有外部服务器',
                description: '添加 MCP 服务器，接入更多工具与服务。',
              ),
            )
          else if (filtered.isEmpty && servers.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: '没有匹配的服务器',
                description: '尝试更换关键词，或查看全部配置。',
                action: TextButton(
                  onPressed: () {
                    setState(() {
                      _serverSearch = '';
                      _enabledFilter = null;
                    });
                  },
                  child: const Text('重置筛选'),
                ),
              ),
            )
          else
            SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final server = filtered[index];
                return _serverCard(
                  context,
                  server,
                  canEdit: canEdit,
                  busy: busy,
                  testing: testing,
                );
              },
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  GlassSearchFloatingBar.height +
                  32 +
                  MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  });

  Widget _serverCard(
    BuildContext context,
    McpServerConfig server, {
    required bool canEdit,
    required bool busy,
    required bool testing,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _Surface(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconTile(
                  icon: server.transport == 'stdio'
                      ? Icons.terminal_rounded
                      : Icons.dns_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID · ${server.id}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  label: '${server.name}启用状态',
                  child: Switch.adaptive(
                    value: server.enabled,
                    onChanged: canEdit
                        ? (value) async {
                            final error = await controller.setServerEnabled(
                              server,
                              value,
                            );
                            if (!context.mounted) return;
                            _showSaveResult(error, value ? '已启用' : '已停用');
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  icon: server.enabled
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                  label: server.enabled ? '已启用' : '已停用',
                  muted: !server.enabled,
                ),
                if (server.transport?.isNotEmpty == true)
                  _Badge(
                    icon: Icons.swap_horiz_rounded,
                    label: server.transport!.toUpperCase(),
                    muted: true,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: colors.outlineVariant),
            const SizedBox(height: 4),
            // URLs and configuration credentials must stay out of the list.
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: busy || testing
                      ? null
                      : () => _testServer(context, server),
                  icon: const Icon(Icons.network_check_rounded, size: 18),
                  label: const Text('测试连接'),
                ),
                TextButton.icon(
                  onPressed: canEdit
                      ? () => _editServer(context, server)
                      : null,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('编辑 JSON'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  onPressed: canEdit
                      ? () => _deleteServer(context, server)
                      : null,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('删除'),
                ),
              ],
            ),
            if (testing)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('正在测试连接，请稍候…'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testServer(BuildContext context, McpServerConfig server) async {
    final confirmed = await _confirm(
      context,
      title: '测试服务器连接？',
      message: '将连接 ${server.name} 并读取工具列表。stdio 配置可能在服务端启动进程。',
      action: '确认测试',
    );
    if (!confirmed || !context.mounted) return;
    final result = await controller.testServer(server);
    if (!context.mounted) return;
    if (result.ok) {
      ToastUtil.success(result.message);
    } else {
      ToastUtil.error(result.message);
    }
  }

  Future<void> _editServer(BuildContext context, [McpServerConfig? server]) =>
      _showMcpSheet(
        context,
        _ServerEditor(controller: controller, server: server),
      );

  Future<void> _deleteServer(
    BuildContext context,
    McpServerConfig server,
  ) async {
    final confirmed = await _confirm(
      context,
      title: '删除 MCP 服务器？',
      message: '将删除 ${server.name}（${server.id}）的完整配置并保存到服务端。',
      action: '确认删除',
    );
    if (!confirmed || !context.mounted) return;
    final error = await controller.deleteServer(server);
    if (!context.mounted) return;
    _showSaveResult(error, '已删除');
  }

  static void _showSaveResult(String? error, String success) {
    if (error != null) {
      ToastUtil.error(error);
    } else {
      ToastUtil.success(success);
    }
  }
}

class _SegmentPicker<T extends Object> extends StatelessWidget {
  const _SegmentPicker({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.7),
        thumbColor: theme.cardColor,
        padding: const EdgeInsets.all(4),
        onValueChanged: (next) {
          if (next != null) onChanged(next);
        },
        children: {
          for (final option in options.entries)
            option.key: Semantics(
              selected: option.key == value,
              button: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Text(
                  option.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: option.key == value
                        ? colors.primary
                        : colors.onSurfaceVariant,
                    fontWeight: option.key == value
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, this.muted = false});
  final IconData icon;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = muted ? colors.onSurfaceVariant : colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: muted
            ? colors.surfaceContainerHighest
            : colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListHeading extends StatelessWidget {
  const _ListHeading({
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onRefresh,
  });
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      if (loading)
        const SizedBox(
          width: 48,
          height: 48,
          child: Center(child: CupertinoActivityIndicator()),
        )
      else
        IconButton(
          tooltip: '刷新$title',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
    ],
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).cardColor,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, this.onTap});
  final McpToolInfo tool;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final properties = tool.inputSchema?['properties'];
    final description = tool.description?.trim();
    return _Surface(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _IconTile(icon: Icons.extension_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tool.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description == null || description.isEmpty
                    ? '暂无工具说明，点击查看参数与调用方式。'
                    : description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (properties is Map)
                    _Badge(
                      icon: Icons.data_object_rounded,
                      label: '${properties.length} 个参数',
                      muted: true,
                    )
                  else
                    Text('查看详情与参数', style: theme.textTheme.bodySmall),
                  Text(
                    '打开工具',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IconTile(icon: icon),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        if (action != null) ...[const SizedBox(height: 8), action!],
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.error = false, this.action});
  final String message;
  final bool error;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? colors.errorContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.shield_outlined,
            size: 20,
            color: error ? colors.onErrorContainer : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: error
                        ? colors.onErrorContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => _Notice(
    message: message,
    error: true,
    action: TextButton(onPressed: retry, child: const Text('重试')),
  );
}

Future<void> _showMcpSheet(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      constraints: const BoxConstraints(maxWidth: 720),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => child,
    );

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class _SheetLayout extends StatelessWidget {
  const _SheetLayout({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    required this.action,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final Widget action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: FractionallySizedBox(
      heightFactor: 0.92,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  _IconTile(icon: icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: children,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              width: double.infinity,
              child: action,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ToolDetail extends StatefulWidget {
  const _ToolDetail({required this.controller, required this.tool});
  final McpToolsController controller;
  final McpToolInfo tool;
  @override
  State<_ToolDetail> createState() => _ToolDetailState();
}

class _ToolDetailState extends State<_ToolDetail> {
  final _arguments = TextEditingController(text: '{}');
  Map<String, dynamic>? _schema;
  String? _result;
  String? _schemaError;
  bool _ok = false;
  bool _busy = false;
  bool _loadingSchema = false;

  @override
  void dispose() {
    _arguments.dispose();
    super.dispose();
  }

  Future<void> _loadSchema() async {
    if (_loadingSchema) return;
    setState(() {
      _loadingSchema = true;
      _schemaError = null;
    });
    final schema = await widget.controller.fetchToolSchema(widget.tool.name);
    if (!mounted) return;
    setState(() {
      _loadingSchema = false;
      _schema = schema;
      if (schema == null) _schemaError = '加载 Schema 失败';
    });
  }

  Future<void> _call() async {
    if (_busy || widget.controller.isCallingTool.value) return;
    // Freeze the exact arguments that the user reviews in the confirmation.
    final text = _arguments.text;
    try {
      if (jsonDecode(text.trim().isEmpty ? '{}' : text) is! Map) {
        throw const FormatException();
      }
    } catch (_) {
      setState(() {
        _result = '参数必须是有效 JSON 对象';
        _ok = false;
      });
      return;
    }
    setState(() => _busy = true);
    final confirmed = await _confirm(
      context,
      title: '确认执行工具？',
      message:
          '工具 ${widget.tool.name} 具有管理员权限，可能修改订阅、下载、文件或服务端设置。\n\n调用参数：\n$text',
      action: '确认执行',
    );
    if (!mounted) return;
    if (!confirmed) {
      setState(() => _busy = false);
      return;
    }
    final result = await widget.controller.callTool(
      widget.tool.name,
      text,
      confirmed: true,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result.result;
      _ok = result.ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = _schema ?? widget.tool.inputSchema;
    return _SheetLayout(
      title: widget.tool.name,
      subtitle: '工具详情与调试',
      icon: Icons.extension_outlined,
      action: Obx(
        () => FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: widget.controller.isCallingTool.value || _busy
              ? null
              : _call,
          icon: _busy
              ? const _SmallProgress()
              : const Icon(Icons.play_arrow_rounded),
          label: Text(_busy ? '正在处理…' : '调用工具'),
        ),
      ),
      children: [
        if (widget.tool.description?.trim().isNotEmpty == true) ...[
          Text(
            widget.tool.description!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
        ],
        _Surface(
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(Icons.data_object_rounded, size: 20),
            title: const Text('参数定义'),
            subtitle: Text(
              schema == null ? '加载 Schema，了解工具输入要求' : '查看输入 Schema',
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (schema != null) _JsonPanel(text: _pretty(schema)),
              if (_schemaError != null)
                _ErrorNotice(message: _schemaError!, retry: _loadSchema),
              TextButton.icon(
                onPressed: _loadingSchema ? null : _loadSchema,
                icon: _loadingSchema
                    ? const _SmallProgress()
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(_loadingSchema ? '正在加载…' : '加载 Schema'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('调用参数', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Text('填写 JSON 对象；无需参数时保留 {}。', style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        _JsonEditor(
          controller: _arguments,
          enabled: !_busy,
          minLines: 4,
          maxLines: 10,
          label: '调用参数（JSON 对象）',
        ),
        const SizedBox(height: 16),
        const _Notice(message: '工具以管理员权限运行，可能修改服务端数据。执行前请核对参数。'),
        if (_result != null) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                _ok
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                color: _ok
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _ok ? '执行结果' : '执行失败',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: '复制结果',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _result!));
                  if (mounted) ToastUtil.success('已复制结果');
                },
                icon: const Icon(Icons.copy_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _JsonPanel(text: _result!),
        ],
      ],
    );
  }
}

class _ServerEditor extends StatefulWidget {
  const _ServerEditor({required this.controller, this.server});
  final McpToolsController controller;
  final McpServerConfig? server;
  @override
  State<_ServerEditor> createState() => _ServerEditorState();
}

class _ServerEditorState extends State<_ServerEditor> {
  late final _text = TextEditingController(
    text: _pretty(
      widget.server?.toJson() ??
          {
            'id': '',
            'name': '',
            'enabled': true,
            'transport': 'stdio',
            'command': '',
            'args': <String>[],
            'env': <String, String>{},
            'headers': <String, String>{},
            'timeout': 30,
            'require_admin': true,
          },
    ),
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _format() {
    try {
      final formatted = _pretty(jsonDecode(_text.text));
      _text.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      setState(() => _error = null);
    } catch (_) {
      setState(() => _error = '配置 JSON 格式错误，无法格式化');
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final text = _text.text;
    try {
      McpServerConfig.parseEditorJson(text);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final confirmed = await _confirm(
      context,
      title: '保存 MCP 配置？',
      message: '完整配置将保存到服务端，可能连接外部服务或启动 stdio 进程。配置中的凭据仅应分享给可信服务。',
      action: '确认保存',
    );
    if (!mounted) return;
    if (!confirmed) {
      setState(() => _busy = false);
      return;
    }
    final error = await widget.controller.upsertServerJson(
      text,
      original: widget.server,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetLayout(
    title: widget.server == null ? '添加 MCP 服务器' : '编辑 MCP 服务器',
    subtitle: '完整配置 · JSON 编辑',
    icon: Icons.dns_outlined,
    action: FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: _busy ? null : _save,
      icon: _busy ? const _SmallProgress() : const Icon(Icons.check_rounded),
      label: Text(_busy ? '正在处理…' : '保存配置'),
    ),
    children: [
      const _Notice(message: '配置可能包含密钥等凭据，请仅连接可信服务。stdio 配置可能在服务端启动进程。'),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Text('服务器配置', style: Theme.of(context).textTheme.titleSmall),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _format,
            icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
            label: const Text('格式化'),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        '未编辑字段及未知字段会原样保留；删除字段会提交该删除。',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
      ),
      const SizedBox(height: 12),
      _JsonEditor(
        controller: _text,
        enabled: !_busy,
        minLines: 14,
        maxLines: 28,
        label: '完整 JSON 配置',
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        _Notice(message: _error!, error: true),
      ],
    ],
  );
}

class _JsonEditor extends StatelessWidget {
  const _JsonEditor({
    required this.controller,
    required this.enabled,
    required this.minLines,
    required this.maxLines,
    required this.label,
  });
  final TextEditingController controller;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    minLines: minLines,
    maxLines: maxLines,
    autocorrect: false,
    enableSuggestions: false,
    smartDashesType: SmartDashesType.disabled,
    smartQuotesType: SmartQuotesType.disabled,
    keyboardType: TextInputType.multiline,
    style: TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.6,
      color: Theme.of(context).colorScheme.onSurface,
    ),
    decoration: InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _JsonPanel extends StatelessWidget {
  const _JsonPanel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: SelectableText(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.6,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class _SmallProgress extends StatelessWidget {
  const _SmallProgress();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

String _pretty(dynamic value) =>
    const JsonEncoder.withIndent('  ').convert(value);
