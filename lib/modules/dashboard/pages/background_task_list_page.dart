import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/schedule_model.dart';
import 'package:moviepilot_mobile/theme/section.dart';

/// 后台任务列表页面
class BackgroundTaskListPage extends StatefulWidget {
  const BackgroundTaskListPage({super.key});

  @override
  State<BackgroundTaskListPage> createState() => _BackgroundTaskListPageState();
}

class _BackgroundTaskListPageState extends State<BackgroundTaskListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Timer? _scheduleRefreshTimer;
  static const _timerInterval = Duration(seconds: 10);

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

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(title: const Text('服务'), centerTitle: false),
      body: SafeArea(
        child: Obx(() {
          final scheduleList = controller.scheduleData.value;
          final filteredList = scheduleList.where((schedule) {
            return schedule.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                schedule.provider.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                schedule.status.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();

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
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: '搜索任务...',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onSubmitted: (value) =>
                        setState(() => _searchQuery = value),
                  ),
                ),
              ),
              if (filteredList.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        _searchQuery.isEmpty ? '暂无后台任务数据' : '未找到匹配的任务',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ),
                  ),
                )
              else
                ...sections.map(
                  (e) => SliverToBoxAdapter(
                    child: Section(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: EdgeInsets.all(0),
                      separatorBuilder: (context) {
                        return Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        );
                      },
                      header: Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          bottom: 6,
                          top: 2,
                        ),
                        child: Text(
                          '${e.key} · ${e.value.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      children: e.value
                          .map(
                            (schedule) => _buildScheduleItem(
                              context,
                              schedule,
                              controller,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  /// 构建任务项：单行显示 name - date - status - button，name 最多 2 行
  Widget _buildScheduleItem(
    BuildContext context,
    ScheduleModel schedule,
    DashboardController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              schedule.name,
              style: const TextStyle(fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            schedule.next_run,
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            schedule.status,
            style: TextStyle(
              fontSize: 13,
              color: _getStatusColor(schedule.status),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minSize: 28,
            borderRadius: BorderRadius.circular(4),
            onPressed: () async {
              await controller.runScheduler(schedule.id);
              _startScheduleTimer();
            },
            child: const Text('执行', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// 根据状态获取颜色
  Color _getStatusColor(String status) {
    switch (status) {
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

  @override
  void dispose() {
    _scheduleRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
