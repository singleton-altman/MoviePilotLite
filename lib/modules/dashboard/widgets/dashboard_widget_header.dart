import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardWidgetHeader extends StatelessWidget {
  const DashboardWidgetHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onTapMore,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onTapMore;
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Skeletonizer(
      enabled: title.isEmpty,
      child: Row(
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (onTapMore != null) ...[
            Spacer(),
            InkWell(
              onTap: onTapMore,
              child: Row(
                children: [
                  Text(
                    '查看',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: color),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
