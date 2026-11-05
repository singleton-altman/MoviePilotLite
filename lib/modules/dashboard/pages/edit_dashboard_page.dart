import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';

import '../controllers/dashboard_controller.dart';

class EditDashboardPage extends StatefulWidget {
  const EditDashboardPage({super.key});

  @override
  State<EditDashboardPage> createState() => _EditDashboardPageState();
}

class _EditDashboardPageState extends State<EditDashboardPage> {
  late final List<String> _allWidgets;
  final DashboardController controller = Get.find<DashboardController>();
  final _isLoading = false.obs;
  final Set<String> _selectedWidgets = <String>{};

  static const Map<String, IconData> _widgetIcons = {
    '存储空间': CupertinoIcons.folder_fill,
    '媒体统计': CupertinoIcons.chart_pie_fill,
    '推荐媒体': CupertinoIcons.sparkles,
    '最近入库': CupertinoIcons.chart_bar_alt_fill,
    '实时速率': CupertinoIcons.speedometer,
    '后台任务': CupertinoIcons.list_bullet_below_rectangle,
    'CPU': CupertinoIcons.gauge,
    '内存': CupertinoIcons.memories,
    '网络流量': CupertinoIcons.arrow_up_arrow_down,
    '我的媒体库': CupertinoIcons.rectangle_stack_fill,
    '继续观看': CupertinoIcons.play_circle_fill,
    '最近添加': CupertinoIcons.film_fill,
    '近期整理': CupertinoIcons.checkmark_seal_fill,
    '快捷操作': CupertinoIcons.square_grid_2x2_fill,
    '系统信息': CupertinoIcons.info_circle_fill,
  };

  static const Map<String, String> _widgetDescriptions = {
    '存储空间': '总容量与使用率',
    '媒体统计': '电影、剧集与本月新增',
    '推荐媒体': '热门榜单横幅轮播',
    '最近入库': '近 7 天入库趋势',
    '实时速率': '下载器上传下载速率',
    '后台任务': '定时服务与整理队列',
    'CPU': '处理器负载曲线',
    '内存': '内存占用曲线',
    '网络流量': '上下行流量',
    '我的媒体库': '媒体服务器媒体库',
    '继续观看': '从上次进度继续',
    '最近添加': '媒体服务器最新入库',
    '近期整理': '最近整理成功记录',
    '快捷操作': '常用工具入口',
    '系统信息': '主机、系统与版本',
  };

  @override
  void initState() {
    super.initState();
    _allWidgets = List<String>.from(DashboardController.availableWidgets);
    _selectedWidgets.addAll(controller.displayedWidgets);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BottomSheetWidget(
      header: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('编辑 Dashboard'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _toggleAll,
            child: Text(
              _selectedWidgets.length == _allWidgets.length ? '全不选' : '全选',
            ),
          ),
          Obx(
            () => _isLoading.value
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoActivityIndicator(),
                  )
                : IconButton(
                    icon: const Icon(Icons.done_rounded),
                    onPressed: _saveChanges,
                  ),
          ),
        ],
      ),
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          controller: scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.35,
          ),
          itemCount: _allWidgets.length,
          itemBuilder: (context, index) {
            final widgetName = _allWidgets[index];
            final isSelected = _selectedWidgets.contains(widgetName);
            return _buildWidgetItem(context, widgetName, isSelected);
          },
        ),
      ),
    );
  }

  void _toggleAll() {
    setState(() {
      if (_selectedWidgets.length == _allWidgets.length) {
        _selectedWidgets.clear();
      } else {
        _selectedWidgets.addAll(_allWidgets);
      }
    });
  }

  Widget _buildWidgetItem(
    BuildContext context,
    String widgetName,
    bool isSelected,
  ) {
    final primaryColor = context.primaryColor;
    final theme = Theme.of(context);
    final icon = _widgetIcons[widgetName] ?? CupertinoIcons.square_fill;
    final description = _widgetDescriptions[widgetName] ?? '';
    final foreground = isSelected ? primaryColor : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedWidgets.remove(widgetName);
            } else {
              _selectedWidgets.add(widgetName);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.08)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.14)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: foreground),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DashboardController.displayNameOf(widgetName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: isSelected
                    ? primaryColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    _isLoading.value = true;
    try {
      final visible = _allWidgets
          .where((name) => _selectedWidgets.contains(name))
          .toList();

      await controller.applyLocalDashboardLayout(visible);
      Get.back();
    } catch (_) {
      Get.snackbar('保存失败', '更新 Dashboard 配置失败，请重试');
    } finally {
      _isLoading.value = false;
    }
  }
}
