import 'package:flutter/cupertino.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_layout_support.dart';

class VuetifyTextView extends StatelessWidget {
  const VuetifyTextView({
    super.key,
    required this.text,
    required this.style,
    this.padding = EdgeInsets.zero,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle style;
  final EdgeInsets padding;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
    if (padding == EdgeInsets.zero) return child;
    return Padding(padding: padding, child: child);
  }
}

class VuetifyHeadingView extends StatelessWidget {
  const VuetifyHeadingView({super.key, required this.spec});

  final VuetifyHeadingSpec spec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        spec.text,
        style: TextStyle(
          fontSize: spec.fontSize,
          fontWeight: FontWeight.bold,
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
        ),
      ),
    );
  }
}
