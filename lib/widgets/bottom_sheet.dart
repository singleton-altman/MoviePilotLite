import 'package:flutter/material.dart';

class BottomSheetWidget extends StatelessWidget {
  const BottomSheetWidget({
    super.key,
    this.child,
    this.header,
    this.scrollController,
    this.builder,
    this.snap = true,
    this.snapSizes = const [0.5, 0.7, 0.8],
    this.initialChildSize = 0.7,
    this.minChildSize = 0.3,
    this.maxChildSize = 0.8,
  });
  final Widget? child;
  final Widget? header;
  final DraggableScrollableController? scrollController;
  final bool snap;
  final List<double> snapSizes;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
  )?
  builder;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.scaffoldBackgroundColor;
    return DraggableScrollableSheet(
      controller: scrollController,
      snap: snap,
      snapSizes: snapSizes,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(color: cardColor),
        child: Column(
          children: [
            if (header != null) header!,
            Divider(height: 1, color: theme.dividerColor),
            if (builder != null)
              Expanded(child: builder!(context, scrollController))
            else
              Expanded(child: child ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
