import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/controllers/system_maintenance_controller.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 系统维护页：服务端重启与版本升级（危险操作,均需二次确认）。
class SystemMaintenancePage extends GetView<SystemMaintenanceController> {
  const SystemMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('系统维护'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Obx(() {
            final operating = controller.isOperating.value;
            return Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('服务端维护',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    '重启或升级会使服务短暂不可用,进行中的任务会被中断。App 需在服务恢复后重新连接。',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: operating ? null : _confirmRestart,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('重启服务'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: operating ? null : _confirmUpgrade,
                    icon: const Icon(Icons.system_update_alt_rounded, size: 18),
                    label: const Text('升级并重启'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _confirmRestart() {
    ToastUtil.warning(
      '重启期间服务将不可用,确定继续吗?',
      title: '重启服务',
      onConfirm: () => _run(controller.restart, '正在重启…'),
    );
  }

  void _confirmUpgrade() {
    ToastUtil.warning(
      '将拉取最新版本并重启服务,确定继续吗?',
      title: '升级服务',
      onConfirm: () => _run(controller.upgrade, '正在升级…'),
    );
  }

  Future<void> _run(
    Future<({bool ok, String message})> Function() action,
    String loadingText,
  ) async {
    ToastUtil.loading(message: loadingText);
    final result = await action();
    ToastUtil.dismiss();
    if (result.ok) {
      ToastUtil.success(result.message);
    } else {
      ToastUtil.error(result.message);
    }
  }
}
