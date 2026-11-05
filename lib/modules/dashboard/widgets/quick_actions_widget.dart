import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_shortcuts.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/shortcut_popover.dart';

/// 快捷操作组件：以 4 列网格平铺常用工具入口，对应 Web 端仪表板的「快捷操作」卡片
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  static const int _columns = 4;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final items = DashboardShortcuts.quickActionItems(context);
    final tones = <Color>[
      palette.primary,
      palette.successAccent,
      palette.warningAccent,
      palette.coolAccent,
      palette.warmAccent,
      palette.primary,
      palette.successAccent,
      palette.coolAccent,
    ];

    return DashboardMetricCard(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _columns;
          return Wrap(
            runSpacing: 6,
            children: [
              for (var index = 0; index < items.length; index++)
                SizedBox(
                  width: itemWidth,
                  child: _QuickActionTile(
                    item: items[index],
                    tone: tones[index % tones.length],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.item, required this.tone});

  final ShortcutItem item;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: palette.isDark ? 0.18 : 0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tone.withValues(alpha: 0.2)),
                ),
                child: Icon(item.icon, size: 20, color: tone),
              ),
              const SizedBox(height: 7),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.bodyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
