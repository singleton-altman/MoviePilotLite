import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';

class Section extends StatelessWidget {
  const Section({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(AppTheme.defaultBorderRadius),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppTheme.defaultBorderRadius),
    ),
    this.header,
    this.children,
    this.margin = EdgeInsets.zero,
    this.separatorBuilder,
  });

  final Widget? child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Widget? header;
  final List<Widget>? children;
  final EdgeInsets? margin;
  final Function(BuildContext context)? separatorBuilder;
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).cardColor;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) header!,
          Container(
            padding: padding,
            decoration: BoxDecoration(color: color, borderRadius: borderRadius),
            child: children != null
                ? ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => children![index],
                    separatorBuilder: (context, index) =>
                        separatorBuilder != null
                        ? separatorBuilder!(context)
                        : SizedBox(height: 10),
                    itemCount: children!.length,
                  )
                : child,
          ),
        ],
      ),
    );
  }
}
