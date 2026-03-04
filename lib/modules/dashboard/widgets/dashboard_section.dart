import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_header.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/theme/section.dart';

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.child,
    required this.title,
    required this.icon,
    this.onTapMore,
    this.children,
    this.padding = const EdgeInsets.all(AppTheme.defaultBorderRadius),
  });
  final Widget child;
  final String title;
  final IconData icon;
  final VoidCallback? onTapMore;
  final List<Widget>? children;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DashboardWidgetHeader(
            title: title,
            icon: icon,
            onTapMore: onTapMore,
          ),
        ),
        Section(padding: padding, child: child),
        SizedBox(height: 16),
      ],
    );
  }
}
