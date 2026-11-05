import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:moviepilot_mobile/modules/subscribe/defines/subscribe_popular_filter_defines.dart';
import 'package:moviepilot_mobile/widgets/glass_search_floating_bar.dart';

class SubscribeListFloatingBar extends StatelessWidget {
  const SubscribeListFloatingBar({
    super.key,
    required this.hasActiveFilters,
    required this.onFilterTap,
    required this.keyword,
    required this.onKeywordSubmitted,
    this.sortValue,
    this.onSortChanged,
    this.sortOptions,
    this.sortLabelBuilder,
    this.isSortAscending = true,
    this.onSortDirectionChanged,
    this.showSortDirection = false,
    this.searchPlaceholder = '搜索订阅名称…',
  });

  final bool hasActiveFilters;
  final VoidCallback onFilterTap;
  final String keyword;
  final ValueChanged<String> onKeywordSubmitted;
  final String? sortValue;
  final ValueChanged<String>? onSortChanged;
  final List<String>? sortOptions;
  final String Function(String value)? sortLabelBuilder;
  final bool isSortAscending;
  final ValueChanged<bool>? onSortDirectionChanged;
  final bool showSortDirection;
  final String searchPlaceholder;

  static const double height = GlassSearchFloatingBar.height;

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
  }) {
    return GlassSearchFloatingBar.openKeywordSheet(
      context,
      initial: initial,
      onSubmitted: onSubmitted,
      placeholder: placeholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBar = theme.brightness == Brightness.dark
        ? Colors.white
        : theme.colorScheme.onSurface;

    return GlassSearchFloatingBar(
      keyword: keyword,
      onKeywordSubmitted: onKeywordSubmitted,
      searchPlaceholder: searchPlaceholder,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
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
      trailing: sortValue != null && onSortChanged != null
          ? SortPullDownWidget<String>(
              showDirectionSection: showSortDirection,
              isAscending: isSortAscending,
              currentValue: sortValue!,
              options:
                  sortOptions ??
                  [
                    for (final o in SubscribePopularFilterDefines.sortOptions)
                      o.value,
                  ],
              labelBuilder: sortLabelBuilder ?? sortLabel,
              onDirectionChanged: onSortDirectionChanged ?? (_) {},
              onValueChanged: onSortChanged!,
            )
          : null,
    );
  }
}
