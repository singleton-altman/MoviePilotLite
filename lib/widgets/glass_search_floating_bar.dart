import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GlassSearchFloatingBar extends StatelessWidget {
  const GlassSearchFloatingBar({
    super.key,
    required this.keyword,
    required this.onKeywordSubmitted,
    this.searchPlaceholder = '搜索…',
    this.leading,
    this.trailing,
  });

  static const double height = 52;

  final String keyword;
  final ValueChanged<String> onKeywordSubmitted;
  final String searchPlaceholder;
  final Widget? leading;
  final Widget? trailing;

  static Future<void> openKeywordSheet(
    BuildContext context, {
    required String initial,
    required ValueChanged<String> onSubmitted,
    required String placeholder,
  }) async {
    final controllerText = TextEditingController(text: initial);
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemBackground,
                ctx,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: CupertinoSearchTextField(
              controller: controllerText,
              autofocus: true,
              placeholder: placeholder,
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ),
        );
      },
    );
    controllerText.dispose();
    if (submitted == null) return;
    onSubmitted(submitted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onBar = theme.brightness == Brightness.dark
        ? Colors.white
        : scheme.onSurface;
    final barTint = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.2)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.88);

    final child = Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(
          child: GestureDetector(
            onTap: () => openKeywordSheet(
              context,
              initial: keyword,
              onSubmitted: onKeywordSubmitted,
              placeholder: searchPlaceholder,
            ),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  Icon(CupertinoIcons.search, size: 18, color: onBar),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      keyword.isEmpty ? searchPlaceholder : keyword,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: onBar.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
    final pill = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: barTint,
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: pill,
          ),
        ),
      ),
    );
  }
}
