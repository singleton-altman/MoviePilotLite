import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/recently_playing_widget.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'media_recommend_widget.dart';
import 'quick_actions_widget.dart';
import 'recent_imports_widget.dart';
import 'schedule_widget.dart';
import 'storage_widget.dart';
import 'media_stats_widget.dart';
import 'recently_added_widget.dart';
import 'real_time_speed_widget.dart';
import 'cpu_widget.dart';
import 'memory_widget.dart';
import 'network_traffic_widget.dart';
import 'my_media_library_widget.dart';
import 'recent_added_widget.dart';
import 'system_info_widget.dart';

/// Dashboard 组件工厂
class DashboardWidgets {
  /// 根据类型构建组件
  static Widget buildWidget(String widgetType) {
    switch (widgetType) {
      case '存储空间':
        return const StorageWidget();
      case '媒体统计':
        return const MediaStatsWidget();
      case '推荐媒体':
        return const MediaRecommendWidget();
      case '最近入库':
        return const RecentAddedWidget();
      case '实时速率':
        return const RealTimeSpeedWidget();
      case '后台任务':
        return const ScheduleWidget();
      case 'CPU':
        return const CpuWidget();
      case '内存':
        return const MemoryWidget();
      case '网络流量':
        return const NetworkTrafficWidget();
      case '我的媒体库':
        return MyMediaLibraryWidget(
          onTap: (library) {
            WebUtil.open(url: library.link);
          },
        );
      case '最近添加':
        return const RecentlyAddedWidget();
      case '继续观看':
        return const RecentlyPlayingWidget();
      case '近期整理':
        return const RecentImportsWidget();
      case '快捷操作':
        return const QuickActionsWidget();
      case '系统信息':
        return const SystemInfoWidget();
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          child: Text('未知组件: $widgetType'),
        );
    }
  }
}
