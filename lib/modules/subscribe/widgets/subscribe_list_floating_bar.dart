import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:moviepilot_mobile/modules/subscribe/defines/subscribe_popular_filter_defines.dart';

class SubscribeListFloatingBar extends StatelessWidget {
  const SubscribeListFloatingBar({
    super.key,
    required this.hasActiveFilters,
    required this.onFilterTap,
    required this.keyword,
    required this.onKeywordSubmitted,
    required this.sortValue,
    required this.onSortChanged,
    this.searchPlaceholder = '搜索订阅名称…',
  });

  final bool hasActiveFilters;
  final VoidCallback onFilterTap;
  final String keyword;
  final ValueChanged<String> onKeywordSubmitted;
  final String sortValue;
  final ValueChanged<String> onSortChanged;
  final String searchPlaceholder;

  static const double height = 52;

  static String sortLabel(String value) {
    for (final o in SubscribePopularFilterDefines.sortOptions) {
      if (o.value == value) return o.label;
    }
    return SubscribePopularFilterDefines.sortOptions.first.label;
  }

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
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: onFilterTap,
          child: Icon(
            CupertinoIcons.slider_horizontal_3,
            size: 20,
            color: hasActiveFilters
                ? CupertinoDynamicColor.resolve(
                    CupertinoColors.activeBlue,
                    context,
                  )
                : onBar,
          ),
        ),
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
        SortPullDownWidget<String>(
          showDirectionSection: false,
          isAscending: true,
          currentValue: sortValue,
          options: [
            for (final o in SubscribePopularFilterDefines.sortOptions) o.value,
          ],
          labelBuilder: sortLabel,
          onDirectionChanged: (_) {},
          onValueChanged: onSortChanged,
        ),
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
