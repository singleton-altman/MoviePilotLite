import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/schedule_model.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';

enum _TaskSortKey { name, provider, status, nextRun }

/// 后台任务列表页面
class BackgroundTaskListPage extends StatefulWidget {
  const BackgroundTaskListPage({super.key});

  @override
  State<BackgroundTaskListPage> createState() => _BackgroundTaskListPageState();
}

class _BackgroundTaskListPageState extends State<BackgroundTaskListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedProviders = {};
  Set<String> _selectedStatuses = {};
  _TaskSortKey _sortKey = _TaskSortKey.nextRun;
  bool _sortAscending = true;

  Timer? _scheduleRefreshTimer;
  static const _timerInterval = Duration(seconds: 10);
  static const double _floatingBarHeight = 52;

  /// 启动/重启 10 秒定时器，刷新后台任务列表
  void _startScheduleTimer() {
    _scheduleRefreshTimer?.cancel();
    final controller = Get.find<DashboardController>();
    _scheduleRefreshTimer = Timer.periodic(_timerInterval, (_) {
      controller.loadScheduleData();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<DashboardController>();
      controller.loadScheduleData();
      _startScheduleTimer();
    });
  }

  /// 按 provider 分组
  Map<String, List<ScheduleModel>> _groupByProvider(List<ScheduleModel> list) {
    final map = <String, List<ScheduleModel>>{};
    for (final s in list) {
      final key = s.provider.isEmpty ? '未分类' : s.provider;
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  bool get _hasActiveFilters =>
      _selectedProviders.isNotEmpty || _selectedStatuses.isNotEmpty;

  List<ScheduleModel> _visibleSchedules(List<ScheduleModel> scheduleList) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = scheduleList.where((schedule) {
      final provider = schedule.provider.isEmpty ? '未分类' : schedule.provider;
      final status = schedule.status.isEmpty ? '待机' : schedule.status;
      final matchesKeyword =
          query.isEmpty ||
          schedule.name.toLowerCase().contains(query) ||
          provider.toLowerCase().contains(query) ||
          status.toLowerCase().contains(query);
      final matchesProvider =
          _selectedProviders.isEmpty || _selectedProviders.contains(provider);
      final matchesStatus =
          _selectedStatuses.isEmpty || _selectedStatuses.contains(status);
      return matchesKeyword && matchesProvider && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final result = _compareSchedule(a, b);
      return _sortAscending ? result : -result;
    });
    return filtered;
  }

  int _compareSchedule(ScheduleModel a, ScheduleModel b) {
    switch (_sortKey) {
      case _TaskSortKey.name:
        return a.name.compareTo(b.name);
      case _TaskSortKey.provider:
        return _providerName(a).compareTo(_providerName(b));
      case _TaskSortKey.status:
        return _statusText(a).compareTo(_statusText(b));
      case _TaskSortKey.nextRun:
        return a.next_run.compareTo(b.next_run);
    }
  }

  String _providerName(ScheduleModel schedule) {
    return schedule.provider.isEmpty ? '未分类' : schedule.provider;
  }

  String _statusText(ScheduleModel schedule) {
    return schedule.status.isEmpty ? '待机' : schedule.status;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      appBar: AppBar(
        title: const Text('后台任务'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.appBarBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: Obx(() {
        final scheduleList = controller.scheduleData.value;
        final loadError = controller.scheduleError.value;
        final filteredList = _visibleSchedules(scheduleList);

        final grouped = _groupByProvider(filteredList);
        final sections = grouped.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                final c = Get.find<DashboardController>();
                await c.loadScheduleData();
                _startScheduleTimer();
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildOverviewCard(context, scheduleList)],
                ),
              ),
            ),
            if (filteredList.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, loadError),
              )
            else
              ...sections.map(
                (entry) => SliverToBoxAdapter(
                  child: _buildProviderSection(
                    context,
                    entry.key,
                    entry.value,
                    controller,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: _bottomSpacer(context))),
          ],
        );
      }),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    List<ScheduleModel> scheduleList,
  ) {
    final palette = DashboardPalette.of(context);
    final running = scheduleList
        .where(DashboardController.isScheduleRunning)
        .length;
    final waiting = scheduleList.where((item) => item.status == '等待').length;
    final failed = scheduleList.where((item) => item.status == '失败').length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(
                    alpha: palette.isDark ? 0.18 : 0.11,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  CupertinoIcons.gear_alt_fill,
                  color: palette.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '任务队列',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.titleText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '每 10 秒自动刷新，可下拉立即同步',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              DashboardInfoPill(
                text: '${scheduleList.length} 项',
                color: palette.primary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  context,
                  label: '运行中',
                  value: '$running',
                  color: _getStatusColor('运行中'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryTile(
                  context,
                  label: '等待',
                  value: '$waiting',
                  color: _getStatusColor('等待'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryTile(
                  context,
                  label: '失败',
                  value: '$failed',
                  color: _getStatusColor('失败'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final palette = DashboardPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.13 : 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.titleText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBar(BuildContext context) {
    final theme = Theme.of(context);
    final pill = Container(
      height: _floatingBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          _buildFloatingFilterButton(context),
          const SizedBox(width: 8),
          Expanded(child: _buildFakeSearchBar(context)),
          const SizedBox(width: 8),
          _buildFloatingSortButton(context),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: pill,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingFilterButton(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final color = _hasActiveFilters ? palette.primary : palette.titleText;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => _openFilterSheet(context),
      child: Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: color),
    );
  }

  Widget _buildFakeSearchBar(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final text = _searchQuery.trim().isEmpty ? '搜索任务、服务或状态' : _searchQuery;
    return GestureDetector(
      onTap: () => _openKeywordSheet(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Icon(CupertinoIcons.search, size: 18, color: palette.titleText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _searchQuery.trim().isEmpty
                      ? palette.mutedText
                      : palette.titleText,
                ),
              ),
            ),
            if (_searchQuery.trim().isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 16,
                  color: palette.mutedText,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSortButton(BuildContext context) {
    return SortPullDownWidget<_TaskSortKey>(
      isAscending: _sortAscending,
      currentValue: _sortKey,
      options: _TaskSortKey.values,
      labelBuilder: _sortLabel,
      onDirectionChanged: (asc) => setState(() => _sortAscending = asc),
      onValueChanged: (key) => setState(() => _sortKey = key),
    );
  }

  Future<void> _openKeywordSheet(BuildContext context) async {
    final controllerText = TextEditingController(text: _searchQuery);
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemBackground,
                ctx,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: CupertinoSearchTextField(
              controller: controllerText,
              autofocus: true,
              placeholder: '搜索任务、服务或状态',
              onSubmitted: (value) => Navigator.of(ctx).pop(value),
            ),
          ),
        );
      },
    );
    controllerText.dispose();
    if (submitted == null) return;
    _searchController.text = submitted;
    setState(() => _searchQuery = submitted);
  }

  Future<void> _openFilterSheet(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Obx(() {
            final schedules = controller.scheduleData.value;
            final providers = schedules.map(_providerName).toSet().toList()
              ..sort();
            final statuses = schedules.map(_statusText).toSet().toList()
              ..sort();

            return _TaskFilterSheet(
              providers: providers,
              statuses: statuses,
              selectedProviders: _selectedProviders,
              selectedStatuses: _selectedStatuses,
              onToggleProvider: (value) {
                setState(() {
                  _selectedProviders = {..._selectedProviders};
                  _selectedProviders.contains(value)
                      ? _selectedProviders.remove(value)
                      : _selectedProviders.add(value);
                });
              },
              onToggleStatus: (value) {
                setState(() {
                  _selectedStatuses = {..._selectedStatuses};
                  _selectedStatuses.contains(value)
                      ? _selectedStatuses.remove(value)
                      : _selectedStatuses.add(value);
                });
              },
              onClear: () {
                setState(() {
                  _selectedProviders = {};
                  _selectedStatuses = {};
                });
              },
            );
          }),
        );
      },
    );
  }

  double _bottomSpacer(BuildContext context) {
    return MediaQuery.of(context).padding.bottom + _floatingBarHeight + 34;
  }

  static String _sortLabel(_TaskSortKey key) {
    switch (key) {
      case _TaskSortKey.name:
        return '名称';
      case _TaskSortKey.provider:
        return '服务';
      case _TaskSortKey.status:
        return '状态';
      case _TaskSortKey.nextRun:
        return '下次运行';
    }
  }

  Widget _buildEmptyState(BuildContext context, String? loadError) {
    final palette = DashboardPalette.of(context);
    final hasQueryOrFilter =
        _searchQuery.trim().isNotEmpty || _hasActiveFilters;
    final isPermissionError =
        loadError == DashboardController.schedulePermissionMessage;

    final IconData icon;
    final String title;
    final String subtitle;
    if (hasQueryOrFilter) {
      icon = CupertinoIcons.search;
      title = '未找到匹配的任务';
      subtitle = '调整关键词或筛选条件再试试';
    } else if (isPermissionError) {
      icon = CupertinoIcons.lock_shield;
      title = DashboardController.schedulePermissionMessage;
      subtitle = '后台任务仅管理员账号可查看';
    } else if (loadError != null) {
      icon = CupertinoIcons.exclamationmark_triangle;
      title = '后台任务加载失败';
      subtitle = '$loadError，下拉可重试';
    } else {
      icon = CupertinoIcons.calendar_badge_minus;
      title = '暂无后台任务数据';
      subtitle = '任务同步后会显示在这里';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: palette.tileSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.tileBorder),
              ),
              child: Icon(icon, color: palette.mutedText, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.titleText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.mutedText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSection(
    BuildContext context,
    String provider,
    List<ScheduleModel> items,
    DashboardController controller,
  ) {
    final palette = DashboardPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    provider,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: palette.mutedText,
                    ),
                  ),
                ),
                DashboardInfoPill(
                  text: '${items.length}',
                  color: palette.mutedText,
                ),
              ],
            ),
          ),
          Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _buildScheduleItem(context, items[index], controller),
                if (index != items.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    ScheduleModel schedule,
    DashboardController controller,
  ) {
    final palette = DashboardPalette.of(context);
    final statusColor = _getStatusColor(schedule.status);
    final statusText = schedule.status.isEmpty ? '待机' : schedule.status;

    return Semantics(
      button: true,
      label: '${schedule.name}，$statusText',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.tileSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.tileBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor.withValues(
                  alpha: palette.isDark ? 0.16 : 0.1,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _getStatusIcon(schedule.status),
                color: statusColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.titleText,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MetaChip(
                        icon: CupertinoIcons.clock,
                        text: schedule.next_run.isEmpty
                            ? '等待调度'
                            : schedule.next_run,
                      ),
                      _StatusChip(text: statusText, color: statusColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              color: palette.primary,
              borderRadius: BorderRadius.circular(10),
              onPressed: () async {
                await controller.runScheduler(schedule.id);
                _startScheduleTimer();
              },
              child: const Text(
                '执行',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据状态获取颜色；服务端列表接口的运行态文案是「正在运行」
  Color _getStatusColor(String status) {
    switch (status) {
      case '正在运行':
      case '运行中':
        return CupertinoColors.activeBlue;
      case '等待':
        return CupertinoColors.systemYellow;
      case '完成':
        return CupertinoColors.activeGreen;
      case '失败':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case '正在运行':
      case '运行中':
        return CupertinoIcons.time_solid;
      case '等待':
        return CupertinoIcons.hourglass;
      case '完成':
        return CupertinoIcons.check_mark_circled_solid;
      case '失败':
        return CupertinoIcons.exclamationmark_triangle_fill;
      default:
        return CupertinoIcons.circle_grid_3x3_fill;
    }
  }

  @override
  void dispose() {
    _scheduleRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: palette.faintText),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.mutedText,
          ),
        ),
      ],
    );
  }
}

class _TaskFilterSheet extends StatelessWidget {
  const _TaskFilterSheet({
    required this.providers,
    required this.statuses,
    required this.selectedProviders,
    required this.selectedStatuses,
    required this.onToggleProvider,
    required this.onToggleStatus,
    required this.onClear,
  });

  final List<String> providers;
  final List<String> statuses;
  final Set<String> selectedProviders;
  final Set<String> selectedStatuses;
  final ValueChanged<String> onToggleProvider;
  final ValueChanged<String> onToggleStatus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Material(
      color: palette.pageBackgroundAlt,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '筛选任务',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: palette.titleText,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 32),
                      onPressed: onClear,
                      child: Text(
                        '清空',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _FilterSection(
                      title: '服务',
                      values: providers,
                      selected: selectedProviders,
                      onToggle: onToggleProvider,
                    ),
                    const SizedBox(height: 22),
                    _FilterSection(
                      title: '状态',
                      values: statuses,
                      selected: selectedStatuses,
                      onToggle: onToggleStatus,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> values;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: palette.mutedText,
          ),
        ),
        const SizedBox(height: 10),
        if (values.isEmpty)
          Text(
            '暂无可用选项',
            style: TextStyle(fontSize: 13, color: palette.faintText),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: values.map((value) {
              final active = selected.contains(value);
              return GestureDetector(
                onTap: () => onToggle(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? palette.primary.withValues(alpha: 0.14)
                        : palette.tileSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? palette.primary.withValues(alpha: 0.32)
                          : palette.tileBorder,
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? palette.primary : palette.bodyText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: palette.isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
