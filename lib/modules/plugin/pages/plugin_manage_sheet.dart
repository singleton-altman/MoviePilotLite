import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_controller.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_management_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 插件管理面板：更新说明（history）/ 版本列表（releases）/ 评分（rating）。
/// 顶部提供重载动作（v2 GET / v3 POST /plugin/reload/{id}）。
Future<void> showPluginManageSheet(
  BuildContext context,
  PluginItem item, {
  String initialTab = 'history',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (sheetContext, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: PluginManageSheet(
          item: item,
          initialTab: initialTab,
          scrollController: scrollController,
        ),
      ),
    ),
  );
}

class PluginManageSheet extends StatefulWidget {
  const PluginManageSheet({
    super.key,
    required this.item,
    required this.initialTab,
    required this.scrollController,
  });

  final PluginItem item;
  final String initialTab;
  final ScrollController scrollController;

  @override
  State<PluginManageSheet> createState() => _PluginManageSheetState();
}

class _PluginManageSheetState extends State<PluginManageSheet>
    with SingleTickerProviderStateMixin {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();

  late final TabController _tabController;

  // history: 版本 -> 更新说明
  Map<String, dynamic>? _history;
  String? _historyError;
  bool _historyLoading = false;

  // releases
  Map<String, dynamic>? _releases;
  String? _releasesError;
  bool _releasesLoading = false;

  // rating
  double? _averageRating;
  int? _ratingCount;
  double? _userRating;
  String? _ratingError;
  bool _ratingLoading = false;
  bool _ratingLoaded = false;
  double _ratingInput = 4.0;
  bool _submittingRating = false;

  bool _reloading = false;
  bool _cloning = false;
  late final String _scope;
  final _controller = Get.find<PluginController>();

  bool get _busy => _reloading || _cloning || _submittingRating;

  @override
  void initState() {
    super.initState();
    _scope = _controller.managementScope;
    final index = ['history', 'releases', 'rating'].indexOf(widget.initialTab);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: index < 0 ? 0 : index,
    );
    _tabController.addListener(_onTabChanged);
    _loadCurrentTab();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
    _loadCurrentTab();
  }

  void _loadCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _loadHistory();
      case 1:
        _loadReleases();
      case 2:
        _loadRating();
    }
  }

  Future<void> _loadHistory() async {
    if (_historyLoading || _history != null || _historyError != null) return;
    setState(() => _historyLoading = true);
    try {
      _checkScope();
      final response = await _apiClient.get<dynamic>(
        '/api/v1/plugin/history/${widget.item.id}',
        queryParameters: {'force': true},
      );
      if (!mounted) return;
      _requireSuccess(response.statusCode, response.data);
      final map = _extractMap(response.data);
      final history = map['history'];
      setState(() {
        _history = history is Map ? Map<String, dynamic>.from(history) : {};
      });
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取插件更新说明失败');
      if (mounted) setState(() => _historyError = e.toString());
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _loadReleases() async {
    if (_releasesLoading || _releases != null || _releasesError != null) return;
    setState(() => _releasesLoading = true);
    try {
      _checkScope();
      final response = await _apiClient.get<dynamic>(
        '/api/v1/plugin/releases/${widget.item.id}',
        queryParameters: {
          if ((widget.item.repoUrl ?? '').trim().isNotEmpty)
            'repo_url': widget.item.repoUrl!.trim(),
        },
      );
      if (!mounted) return;
      _requireSuccess(response.statusCode, response.data);
      setState(() {
        _releases = _extractMap(response.data);
      });
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取插件版本列表失败');
      if (mounted) setState(() => _releasesError = e.toString());
    } finally {
      if (mounted) setState(() => _releasesLoading = false);
    }
  }

  Future<void> _loadRating() async {
    if (_ratingLoading || _ratingLoaded || _ratingError != null) return;
    setState(() => _ratingLoading = true);
    try {
      _checkScope();
      final response = await _apiClient.get<dynamic>(
        '/api/v1/plugin/rating/${widget.item.id}',
      );
      if (!mounted) return;
      _requireSuccess(response.statusCode, response.data);
      final map = _extractMap(response.data);
      setState(() {
        _ratingLoaded = true;
        _averageRating = (map['average_rating'] as num?)?.toDouble();
        _ratingCount = (map['rating_count'] as num?)?.toInt();
        final user = (map['user_rating'] as num?)?.toDouble();
        _userRating = user;
        if (user != null && user.isFinite && user > 0) {
          _ratingInput = user.clamp(0.5, 5.0).toDouble();
        }
      });
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取插件评分失败');
      if (mounted) setState(() => _ratingError = e.toString());
    } finally {
      if (mounted) setState(() => _ratingLoading = false);
    }
  }

  Future<void> _submitRating() async {
    if (_busy) return;
    setState(() => _submittingRating = true);
    try {
      _checkScope();
      final response = await _apiClient.post<dynamic>(
        '/api/v1/plugin/rating/${widget.item.id}',
        data: {'rating': _ratingInput},
      );
      if (!mounted) return;
      _requireSuccess(response.statusCode, response.data);
      if (response.data is! Map || response.data['success'] != true) {
        throw const PluginManagementException('服务器未确认评分成功');
      }
      ToastUtil.success('评分已提交');
      setState(() {
        _ratingLoaded = false;
        _averageRating = null;
        _ratingCount = null;
        _userRating = null;
        _ratingError = null;
      });
      _loadRating();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '提交插件评分失败');
      if (mounted) ToastUtil.error(e.toString());
    } finally {
      if (mounted) setState(() => _submittingRating = false);
    }
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is! Map) throw const FormatException('服务器响应格式无效');
    final data = raw['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(raw);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: _buildHeader(context, theme),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '更新说明'),
              Tab(text: '版本列表'),
              Tab(text: '评分'),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
          ),
          Expanded(
            child: switch (_tabController.index) {
              0 => _buildHistoryTab(theme),
              1 => _buildReleasesTab(theme),
              _ => _buildRatingTab(theme),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.pluginName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((widget.item.pluginVersion ?? '').isNotEmpty)
                  Text(
                    '当前版本 ${widget.item.pluginVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _confirmReload,
            icon: _reloading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('重载'),
          ),
          TextButton(
            onPressed: _busy ? null : _showCloneDialog,
            child: const Text('分身'),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showCloneDialog() async {
    if (_busy) return;
    setState(() => _cloning = true);
    var suffix = '';
    final formKey = GlobalKey<FormState>();
    try {
      final submitted = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('创建插件分身'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('创建独立配置实例。服务端会将分身加入原插件所在的首个文件夹。'),
                const SizedBox(height: 12),
                TextFormField(
                  autofocus: true,
                  maxLength: 20,
                  decoration: const InputDecoration(labelText: '后缀（字母或数字，如 2）'),
                  onChanged: (value) => suffix = value,
                  validator: (value) =>
                      RegExp(
                        r'^[A-Za-z0-9]{1,20}$',
                      ).hasMatch(value?.trim() ?? '')
                      ? null
                      : '请输入 1–20 个 ASCII 字母或数字',
                ),
              ],
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
                  Navigator.pop(dialogContext, suffix.trim());
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      );
      if (!mounted || submitted == null) return;
      _checkScope();
      final message = await _controller.clonePlugin(widget.item.id, submitted);
      if (mounted) ToastUtil.success(message);
    } catch (error, stackTrace) {
      _log.handle(error, stackTrace: stackTrace, message: '创建插件分身失败');
      if (mounted) ToastUtil.error('$error；请刷新列表确认后再试');
    } finally {
      if (mounted) setState(() => _cloning = false);
    }
  }

  Future<void> _confirmReload() async {
    if (_busy) return;
    setState(() => _reloading = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('重载插件'),
          content: const Text('重载会临时停止并重新加载插件，确定继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('重载'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      _checkScope();
      await _controller.reloadPlugin(widget.item.id);
      if (mounted) ToastUtil.success('已重载');
    } catch (error, stackTrace) {
      _log.handle(error, stackTrace: stackTrace, message: '重载插件失败');
      if (mounted) ToastUtil.error(error.toString());
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  void _checkScope() {
    if (_controller.managementScope != _scope) {
      throw const PluginManagementException('服务器或帐号已切换，请重新打开面板');
    }
  }

  void _requireSuccess(int? status, dynamic data) {
    _checkScope();
    if (status == null ||
        status < 200 ||
        status >= 300 ||
        (data is Map && data['success'] == false)) {
      throw PluginManagementException(
        data is Map
            ? (data['message'] ?? data['detail'] ?? '请求失败 (HTTP $status)')
                  .toString()
            : '请求失败 (HTTP $status)',
      );
    }
  }

  Widget _buildLoading() => const Center(child: CupertinoActivityIndicator());

  Widget _buildError(ThemeData theme, String message, VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: retry, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    if (_historyLoading) return _buildLoading();
    if (_historyError != null) {
      return _buildError(theme, _historyError!, () {
        setState(() => _historyError = null);
        _loadHistory();
      });
    }
    final entries = _history?.entries.toList() ?? const [];
    if (entries.isEmpty) {
      return Center(
        child: Text(
          '暂无更新说明',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = entries[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'v${e.key}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (e.value != null && e.value.toString().trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  e.value.toString(),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReleasesTab(ThemeData theme) {
    if (_releasesLoading) return _buildLoading();
    if (_releasesError != null) {
      return _buildError(theme, _releasesError!, () {
        setState(() => _releasesError = null);
        _loadReleases();
      });
    }
    final data = _releases;
    if (data == null) {
      return Center(
        child: Text(
          '暂无版本信息',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    final supported = data['release_supported'] == true;
    final latest = data['latest_version']?.toString() ?? '';
    final current = data['current_version']?.toString() ?? '';
    final versions = data['items'];
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        if (!supported)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '该插件仓库不支持 Release 版本安装',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else ...[
          if (latest.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '最新版本',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              trailing: Text(
                latest == current ? '$latest（已是最新）' : latest,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (versions is List && versions.isNotEmpty) ...[
            const Divider(height: 16),
            for (final v in versions)
              if (v is Map)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    (v['version'] ?? v['tag'] ?? v['name'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: (v['date'] ?? v['published_at']) != null
                      ? Text(
                          (v['date'] ?? v['published_at']).toString(),
                          style: const TextStyle(fontSize: 11.5),
                        )
                      : null,
                ),
          ],
        ],
      ],
    );
  }

  Widget _buildRatingTab(ThemeData theme) {
    if (_ratingLoading) return _buildLoading();
    if (_ratingError != null) {
      return _buildError(theme, _ratingError!, () {
        setState(() => _ratingError = null);
        _loadRating();
      });
    }
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _starRow(theme, _averageRating ?? 0, size: 26),
            const SizedBox(width: 10),
            Text(
              _averageRating != null ? _averageRating!.toStringAsFixed(1) : '-',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _ratingCount != null ? '$_ratingCount 人评分' : '暂无评分',
            style: TextStyle(
              fontSize: 12.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (_userRating != null && _userRating! > 0) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              '我的评分：${_userRating!.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
        const Divider(height: 32),
        Center(
          child: Text(
            '我的评分：${_ratingInput.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Slider(
          value: _ratingInput,
          min: 0.5,
          max: 5,
          divisions: 9,
          label: _ratingInput.toStringAsFixed(1),
          activeColor: theme.colorScheme.primary,
          onChanged: _busy ? null : (v) => setState(() => _ratingInput = v),
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: _busy ? null : _submitRating,
          child: _submittingRating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('提交评分'),
        ),
      ],
    );
  }

  Widget _starRow(ThemeData theme, double value, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i
                ? Icons.star_rounded
                : (value >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: size,
            color: const Color(0xFFFFB300),
          ),
      ],
    );
  }
}
