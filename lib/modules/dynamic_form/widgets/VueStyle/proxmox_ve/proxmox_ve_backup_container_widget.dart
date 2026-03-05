import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

class ProxmoxVeBackupContainerWidget extends StatelessWidget {
  const ProxmoxVeBackupContainerWidget({super.key, required this.container});
  final Map<String, dynamic> container;
  @override
  Widget build(BuildContext context) {
    final displayName = container['displayName'];
    final id = container['vmid'];
    final updateTime = container['updateTime'];
    final type = container['type'];
    final status = container['status'];
    return Section(
      header: SectionHeader(title: displayName, subtitle: 'ID: $id'),
      children: [
        Row(
          children: [
            _buildChip(type, Colors.blue),
            _buildChip(status, Colors.green),
          ],
        ),
        Text(formatUptime(updateTime)),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.2),
    );
  }

  String formatUptime(int uptime) {
    final d = Duration(seconds: uptime);

    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;

    return "已运行 ${days}天${hours}小时${minutes}分";
  }
}
