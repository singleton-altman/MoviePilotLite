import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 系统信息组件：主机名、操作系统、运行时间与版本，对应 Web 端仪表板的「系统信息」卡片
class SystemInfoWidget extends StatelessWidget {
  const SystemInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);

    return Obx(() {
      final info = controller.systemInfo.value;
      // 订阅分钟级心跳，使运行时间在两次请求之间也持续走动
      controller.runtimeTick.value;
      final loaded = info != null;
      final runtimeText = loaded
          ? _formatRuntime(controller.displayedRuntimeSeconds)
          : '—';

      return Skeletonizer(
        enabled: !loaded,
        child: DashboardMetricCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _InfoCell(
                      icon: CupertinoIcons.desktopcomputer,
                      label: '主机名称',
                      value: loaded && info.hostname.isNotEmpty
                          ? info.hostname
                          : '—',
                      tone: palette.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCell(
                      icon: CupertinoIcons.device_laptop,
                      label: '操作系统',
                      value: loaded && info.operatingSystem.isNotEmpty
                          ? info.operatingSystem
                          : '—',
                      tone: palette.coolAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCell(
                icon: CupertinoIcons.timer,
                label: '运行时间',
                value: runtimeText,
                tone: palette.successAccent,
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: palette.divider),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '版本',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.mutedText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loaded && info.version.isNotEmpty ? info.version : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: palette.titleText,
                      ),
                    ),
                  ),
                  Obx(() {
                    final checking = controller.isCheckingUpdate.value;
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      onPressed: checking || !loaded
                          ? null
                          : controller.checkSystemUpdate,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (checking)
                            const CupertinoActivityIndicator(radius: 7)
                          else
                            Icon(
                              CupertinoIcons.arrow_2_circlepath,
                              size: 13,
                              color: palette.primary,
                            ),
                          const SizedBox(width: 5),
                          Text(
                            '检查更新',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 将运行秒数压缩为「天 小时 分」三级文本
  static String _formatRuntime(int totalSeconds) {
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (days > 0) return '$days天 $hours小时 $minutes分';
    if (hours > 0) return '$hours小时 $minutes分';
    return '$minutes分';
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: palette.isDark ? 0.16 : 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 16, color: tone),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: palette.faintText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: palette.titleText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
