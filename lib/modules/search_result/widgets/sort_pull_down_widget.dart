import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

/// 排序下拉控件：常态显示「正序/逆序」与当前条件，点击后弹出 pull menu。
/// 上方 section 为排序方向切换（正序/逆序），下方 section 为排序条件列表。
class SortPullDownWidget<T> extends StatelessWidget {
  const SortPullDownWidget({
    super.key,
    required this.isAscending,
    required this.currentValue,
    required this.options,
    required this.labelBuilder,
    required this.onDirectionChanged,
    required this.onValueChanged,
    this.showDirectionSection = true,
    this.directionLabelAsc = '正序',
    this.directionLabelDesc = '逆序',
    this.sectionTitleSort = '排序方向',
    this.sectionTitleCondition = '排序条件',
  });

  final bool showDirectionSection;

  /// 当前是否为正序（true=正序，false=逆序）
  final bool isAscending;

  /// 当前选中的排序条件
  final T currentValue;

  /// 所有排序条件选项
  final List<T> options;

  /// 将 T 转为展示文案
  final String Function(T) labelBuilder;

  /// 排序方向变化回调（true=正序，false=逆序）
  final ValueChanged<bool> onDirectionChanged;

  /// 排序条件选中回调
  final ValueChanged<T> onValueChanged;

  final String directionLabelAsc;
  final String directionLabelDesc;
  final String sectionTitleSort;
  final String sectionTitleCondition;

  /// 常态下显示的文案：逆序 · 默认
  String get _displayText {
    final cond = labelBuilder(currentValue);
    return cond;
  }

  IconData get _displayDirectionIcon {
    return isAscending ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down;
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.9);

    return GestureDetector(
      onTap: () => _showPullMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDirectionSection) ...[
              Icon(_displayDirectionIcon, size: 14, color: labelColor),
              const SizedBox(width: 6),
            ],
            Text(
              _displayText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPullMenu(BuildContext context) {
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SortPullMenu<T>(
        initialAscending: isAscending,
        currentValue: currentValue,
        options: options,
        labelBuilder: labelBuilder,
        showDirectionSection: showDirectionSection,
        onDirectionChanged: onDirectionChanged,
        onValueChanged: (value) {
          onValueChanged(value);
          Navigator.of(ctx).pop();
        },
        directionLabelAsc: directionLabelAsc,
        directionLabelDesc: directionLabelDesc,
        sectionTitleSort: sectionTitleSort,
        sectionTitleCondition: sectionTitleCondition,
      ),
    );
  }
}

class _SortPullMenu<T> extends StatefulWidget {
  const _SortPullMenu({
    required this.initialAscending,
    required this.currentValue,
    required this.options,
    required this.labelBuilder,
    required this.showDirectionSection,
    required this.onDirectionChanged,
    required this.onValueChanged,
    required this.directionLabelAsc,
    required this.directionLabelDesc,
    required this.sectionTitleSort,
    required this.sectionTitleCondition,
  });

  final bool initialAscending;
  final T currentValue;
  final List<T> options;
  final String Function(T) labelBuilder;
  final bool showDirectionSection;
  final ValueChanged<bool> onDirectionChanged;
  final ValueChanged<T> onValueChanged;
  final String directionLabelAsc;
  final String directionLabelDesc;
  final String sectionTitleSort;
  final String sectionTitleCondition;

  @override
  State<_SortPullMenu<T>> createState() => _SortPullMenuState<T>();
}

class _SortPullMenuState<T> extends State<_SortPullMenu<T>> {
  late bool _isAscending;

  @override
  void initState() {
    super.initState();
    _isAscending = widget.initialAscending;
  }

  @override
  Widget build(BuildContext context) {
    final groupedBg = CupertinoDynamicColor.resolve(
      CupertinoColors.secondarySystemGroupedBackground,
      context,
    );
    final dividerColor = CupertinoDynamicColor.resolve(
      CupertinoColors.separator,
      context,
    );
    final primary = context.primaryColor;
    final labelColor = CupertinoDynamicColor.resolve(
      CupertinoColors.label,
      context,
    );
    final secondaryColor = CupertinoDynamicColor.resolve(
      CupertinoColors.secondaryLabel,
      context,
    );
    return Material(
      child: BottomSheetWidget(
        header: SectionHeader(title: '排序'),
        builder: (context, scrollController) => ListView(
          padding: EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (widget.showDirectionSection) ...[
              Text(
                widget.sectionTitleSort,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: _isAscending,
                thumbColor: primary,
                backgroundColor: groupedBg,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                onValueChanged: (value) {
                  if (value != null && value != _isAscending) {
                    setState(() => _isAscending = value);
                    widget.onDirectionChanged(value);
                  }
                },
                children: {
                  true: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_up,
                          size: 14,
                          color: _isAscending
                              ? CupertinoColors.white
                              : secondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.directionLabelAsc,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isAscending
                                ? CupertinoColors.white
                                : labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  false: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_down,
                          size: 14,
                          color: !_isAscending
                              ? CupertinoColors.white
                              : secondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.directionLabelDesc,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: !_isAscending
                                ? CupertinoColors.white
                                : labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                },
              ),
              const SizedBox(height: 8),
            ],
            Text(
              widget.sectionTitleCondition,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: groupedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int i = 0; i < widget.options.length; i++) ...[
                    if (i > 0)
                      Container(
                        height: 1,
                        color: dividerColor,
                        margin: const EdgeInsets.only(left: 12),
                      ),
                    _ConditionTile<T>(
                      value: widget.options[i],
                      label: widget.labelBuilder(widget.options[i]),
                      isSelected: widget.options[i] == widget.currentValue,
                      primary: primary,
                      labelColor: labelColor,
                      onTap: () => widget.onValueChanged(widget.options[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionTile<T> extends StatelessWidget {
  const _ConditionTile({
    required this.value,
    required this.label,
    required this.isSelected,
    required this.primary,
    required this.labelColor,
    required this.onTap,
  });

  final T value;
  final String label;
  final bool isSelected;
  final Color primary;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onPressed: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: labelColor,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 22,
              color: primary,
            ),
        ],
      ),
    );
  }
}
