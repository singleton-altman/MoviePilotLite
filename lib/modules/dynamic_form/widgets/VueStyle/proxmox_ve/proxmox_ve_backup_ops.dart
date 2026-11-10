import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/proxmox_ve_backup_form_controller.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// PVE 守护神运维动作/对话框工具：供各卡片（主机概况 / 备份文件 / 虚机列表）调用。
///
/// 对齐 Web 端 AppPage.vue 的按钮归属：
/// - 主机概况卡：清理日志 / 清理临时 / 重启 / 关机 / 终端
/// - 备份文件卡：立即备份 / 清空历史 / 行内下载-恢复-删除
/// - 虚机/容器卡：全部停止 / 行内启动-停止-重启-快照-画面
abstract final class ProxmoxOps {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '确定',
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ============ 主机概况卡动作 ============

  static Future<void> cleanupLogs(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
  ) async {
    final ok = await confirm(
      context,
      title: '清理 PVE 系统日志',
      message: '将按日志保留配置清理 PVE 系统日志，确定继续？',
    );
    if (ok) await controller.cleanupLogs();
  }

  static Future<void> cleanupTmp(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
  ) async {
    final ok = await confirm(
      context,
      title: '清理 PVE 临时空间',
      message: '将清理 PVE 上的临时文件，确定继续？',
    );
    if (ok) await controller.cleanupTmp();
  }

  static Future<void> hostReboot(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
  ) async {
    final ok = await confirm(
      context,
      title: '重启 PVE 主机',
      message: '确认重启 PVE 主机？所有虚拟机将受影响！',
      confirmLabel: '重启',
      danger: true,
    );
    if (ok) await controller.hostAction('reboot');
  }

  static Future<void> hostShutdown(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
  ) async {
    final ok = await confirm(
      context,
      title: '关闭 PVE 主机',
      message: '确认关闭 PVE 主机？所有虚拟机将关机！',
      confirmLabel: '关机',
      danger: true,
    );
    if (ok) await controller.hostAction('shutdown');
  }

  // ============ 备份文件卡动作 ============

  static Future<void> runBackup(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
  ) async {
    await controller.runBackup();
  }

  static Future<void> stopAllTasks(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
  ) async {
    final ok = await confirm(
      context,
      title: '停止所有任务',
      message: '将释放备份/恢复任务锁并中断当前任务，确定继续？',
      confirmLabel: '停止',
      danger: true,
    );
    if (ok) await controller.stopAllTasks();
  }

  static Future<void> clearHistory(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
  ) async {
    final ok = await confirm(
      context,
      title: '清空历史记录',
      message: '确认清空所有备份与恢复历史记录？',
      confirmLabel: '清空',
      danger: true,
    );
    if (ok) await controller.clearHistory();
  }

  static Future<void> confirmDeleteBackup(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
    Map<String, dynamic> item,
  ) async {
    final filename = item['filename']?.toString() ?? '';
    final ok = await confirm(
      context,
      title: '删除备份',
      message: '确认删除 ${item['source'] ?? '本地备份'} 中的 $filename？此操作不可恢复！',
      confirmLabel: '删除',
      danger: true,
    );
    if (ok) await controller.deleteBackup(item);
  }

  static Future<void> showRestoreDialog(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
    Map<String, dynamic> item,
  ) async {
    final vmidController = TextEditingController(
      text: '${controller.formModel.value['restore_vmid'] ?? ''}',
    );
    var force = controller.formModel.value['restore_force'] == true;
    var skipExisting =
        controller.formModel.value['restore_skip_existing'] != false;
    final filename = item['filename']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('恢复备份'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(filename, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: vmidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '恢复为 VMID（留空用原 VMID）',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('强制恢复', style: TextStyle(fontSize: 14)),
                  subtitle: const Text(
                    '目标已存在时覆盖',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: force,
                  onChanged: (v) => setState(() => force = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('跳过已存在', style: TextStyle(fontSize: 14)),
                  value: skipExisting,
                  onChanged: (v) => setState(() => skipExisting = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('开始恢复'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await controller.restoreBackup(
        item,
        force: force,
        skipExisting: skipExisting,
        vmid: vmidController.text.trim(),
      );
    }
    vmidController.dispose();
  }

  static Future<void> downloadBackup(
    ProxmoxVEBackupFormController controller,
    Map<String, dynamic> item,
  ) async {
    final path = await controller.downloadBackup(item);
    if (path == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'PVE 备份：${item['filename'] ?? ''}',
      ),
    );
  }

  // ============ 虚机/容器卡动作 ============

  /// 虚机状态对应操作：运行中 → 重启/停止/快照；已停止 → 启动
  static List<({String action, String label, IconData icon, Color color})>
  vmActions(bool running) {
    if (running) {
      return const [
        (action: 'reboot', label: '重启', icon: Icons.restart_alt, color: Color(0xFFFB8C00)),
        (action: 'stop', label: '停止', icon: Icons.stop_rounded, color: Color(0xFFE53935)),
        (action: 'snapshot', label: '快照', icon: Icons.camera_alt_outlined, color: Color(0xFF00897B)),
      ];
    }
    return const [
      (action: 'start', label: '启动', icon: Icons.play_arrow_rounded, color: Color(0xFF2E9E5B)),
    ];
  }

  static Future<void> vmAction(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
    Map<String, dynamic> vm,
    String action,
  ) async {
    final vmid = vm['vmid']?.toString() ?? '';
    final type = vm['type']?.toString() ?? 'qemu';
    if (vmid.isEmpty) return;
    if (action == 'stop' || action == 'reboot') {
      final ok = await confirm(
        context,
        title: action == 'stop' ? '停止虚机' : '重启虚机',
        message: '确认对 ${vm['displayName'] ?? vm['name'] ?? vmid}（#$vmid）执行'
            '${action == 'stop' ? '停止' : '重启'}？',
        confirmLabel: action == 'stop' ? '停止' : '重启',
        danger: true,
      );
      if (!ok) return;
    }
    await controller.runVmAction(vmid: vmid, type: type, action: action);
  }

  // ============ 终端 / 虚机画面对话框 ============

  static Future<void> showTerminalDialog(
    BuildContext context,
    ProxmoxVEBackupFormController controller,
  ) async {
    final input = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('宿主机终端'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '在 PVE 宿主机上执行单条命令（非交互，超时 20 秒）',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: input,
                decoration: const InputDecoration(
                  hintText: '例如：pvesm status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _runTerminal(controller, input.text),
              ),
              const SizedBox(height: 12),
              Obx(() {
                  if (controller.terminalRunning.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(minHeight: 2),
                    );
                  }
                  final output = controller.terminalOutput.value;
                  if (output == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 240),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        output,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () => _runTerminal(controller, input.text),
            child: const Text('执行'),
          ),
        ],
      ),
    );
    input.dispose();
  }

  static Future<void> _runTerminal(
    ProxmoxVEBackupFormController controller,
    String command,
  ) async {
    final cmd = command.trim();
    if (cmd.isEmpty) {
      ToastUtil.error('请输入命令');
      return;
    }
    await controller.runTerminal(cmd);
  }

  static Future<void> showScreenDialog(
    BuildContext context,
    ProxmoxVEBackupFormController controller, {
    String? initialVmid,
  }) async {
    final qemuList = controller.containers
        .where((c) => c['type']?.toString() == 'qemu')
        .toList();
    if (qemuList.isEmpty) {
      ToastUtil.error('未找到虚拟机（容器暂不支持实时画面）');
      return;
    }
    final vmidController = TextEditingController(
      text: initialVmid ?? qemuList.first['vmid']?.toString() ?? '',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('虚机实时画面'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: vmidController.text.isEmpty
                          ? null
                          : vmidController.text,
                      decoration: const InputDecoration(
                        labelText: '虚拟机',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: qemuList
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['vmid']?.toString() ?? '',
                              child: Text(
                                '${c['displayName'] ?? c['name'] ?? ''} '
                                '(${c['vmid']})',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => vmidController.text = v ?? '',
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        controller.fetchScreen(vmidController.text.trim()),
                    child: const Text('截图'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() {
                final loading = controller.screenLoading.value;
                final bytes = controller.screenBytes.value;
                if (loading && bytes == null) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (bytes == null) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        '点击「截图」获取当前画面',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Image.memory(bytes, fit: BoxFit.contain),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    vmidController.dispose();
  }
}
