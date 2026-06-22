import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_layout_support.dart';

class VuetifyCardView extends StatelessWidget {
  const VuetifyCardView({super.key, required this.spec, required this.child});

  final VuetifyCardSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: spec.margin,
      child: Container(
        width: double.infinity,
        decoration: spec.decoration,
        padding: spec.padding,
        child: child,
      ),
    );
  }
}

class VuetifyWrapRowView extends StatelessWidget {
  const VuetifyWrapRowView({
    super.key,
    required this.spec,
    required this.children,
  });

  final VuetifyRowSpec spec;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: spec.margin,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: children,
      ),
    );
  }
}

class VuetifyColView extends StatelessWidget {
  const VuetifyColView({super.key, required this.spec, required this.child});

  final VuetifyColSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final effectiveChild = spec.center ? Center(child: child) : child;
    if (spec.width != null) {
      return SizedBox(width: spec.width, child: effectiveChild);
    }
    return Expanded(child: effectiveChild);
  }
}

class VuetifyColumnView extends StatelessWidget {
  const VuetifyColumnView({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.expandWidth = false,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final bool expandWidth;

  @override
  Widget build(BuildContext context) {
    Widget child = Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    if (expandWidth) {
      child = SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}

class VuetifyFlexRowView extends StatelessWidget {
  const VuetifyFlexRowView({
    super.key,
    required this.padding,
    required this.mainAxisAlignment,
    required this.crossAxisAlignment,
    required this.children,
  });

  final EdgeInsets padding;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}
