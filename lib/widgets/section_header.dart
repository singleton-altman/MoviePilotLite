import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.style,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(width: 16),
            Container(
              width: 5,
              height: 20,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style:
                  style ?? TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),

            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
            if (trailing != null) trailing!,
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
