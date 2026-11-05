import 'package:flutter/material.dart';

class AppScaffoldBackground extends StatelessWidget {
  const AppScaffoldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}
