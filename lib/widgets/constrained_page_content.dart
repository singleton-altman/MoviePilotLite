import 'package:flutter/material.dart';

class ConstrainedPageContent extends StatelessWidget {
  const ConstrainedPageContent({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  static const double wideBreakpoint = 600;
  static const double maxWidth = 960;

  final Widget child;
  final EdgeInsetsGeometry padding;

  static bool isWideScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width > wideBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = isWideScreen(context);
    final horizontal = isWide ? 24.0 : 16.0;
    final extra = padding.resolve(Directionality.of(context));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal + extra.left,
        extra.top,
        horizontal + extra.right,
        extra.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? maxWidth : double.infinity,
          ),
          child: child,
        ),
      ),
    );
  }
}
