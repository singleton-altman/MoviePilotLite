import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/theme/section.dart';

class _PickerSheetScaffold extends StatelessWidget {
  const _PickerSheetScaffold({
    required this.child,
    this.height,
    this.maxHeightFactor,
  });

  final Widget child;
  final double? height;
  final double? maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: height,
      constraints: maxHeightFactor == null
          ? null
          : BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * maxHeightFactor!,
            ),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemGroupedBackground,
          context,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey3,
                context,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: child),
        ],
      ),
    );

    return Material(color: Colors.transparent, child: content);
  }
}

class _PickerSheetHeader extends StatelessWidget {
  const _PickerSheetHeader({
    required this.title,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.separator,
              context,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCancel,
            child: const Text('取消'),
          ),
          Expanded(
            child: Text(
              title.isEmpty ? '请选择' : title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.label,
                  context,
                ),
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onConfirm,
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _SelectionSummaryCard extends StatelessWidget {
  const _SelectionSummaryCard({
    required this.title,
    required this.subtitle,
    this.center = false,
  });

  final String title;
  final String subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.secondarySystemGroupedBackground,
          context,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: center ? TextAlign.center : TextAlign.start,
            maxLines: center ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.label,
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerActionButton extends StatelessWidget {
  const _PickerActionButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondarySystemGroupedBackground,
        context,
      ),
      borderRadius: BorderRadius.circular(12),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w600,
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.activeBlue,
            context,
          ),
        ),
      ),
    );
  }
}

class _MultiSelectPickerSheet extends StatefulWidget {
  const _MultiSelectPickerSheet({
    required this.label,
    required this.items,
    required this.initialValues,
    required this.onConfirm,
  });

  final String label;
  final List<SelectOption> items;
  final Set<dynamic> initialValues;
  final ValueChanged<Set<dynamic>> onConfirm;

  @override
  State<_MultiSelectPickerSheet> createState() =>
      _MultiSelectPickerSheetState();
}

/// 多选选择器弹窗
class _MultiSelectPickerSheetState extends State<_MultiSelectPickerSheet> {
  late Set<dynamic> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = Set.from(widget.initialValues);
  }

  void _selectAll() {
    setState(() {
      _selectedValues = widget.items.map((item) => item.value).toSet();
    });
  }

  void _invertSelection() {
    setState(() {
      final next = <dynamic>{};
      for (final item in widget.items) {
        if (!_selectedValues.contains(item.value)) {
          next.add(item.value);
        }
      }
      _selectedValues = next;
    });
  }

  String get _selectionSummary {
    final titles = widget.items
        .where((item) => _selectedValues.contains(item.value))
        .map((item) => item.title)
        .toList();
    if (titles.isEmpty) return '暂未选择任何选项';
    if (titles.length <= 3) return titles.join('、');
    return '${titles.take(3).join('、')} 等 ${titles.length} 项';
  }

  Widget _buildCompactToolbar(BuildContext context) {
    final helperText = _selectedValues.isEmpty
        ? '请选择一个或多个选项'
        : '已选择 ${_selectedValues.length} 项';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondarySystemGroupedBackground,
            context,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    helperText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.secondaryLabel,
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectionSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.label,
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _PickerActionButton(
              label: '全选',
              onPressed: _selectAll,
              compact: true,
            ),
            const SizedBox(width: 8),
            _PickerActionButton(
              label: '反选',
              onPressed: _invertSelection,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PickerSheetScaffold(
      maxHeightFactor: 0.86,
      child: Column(
        children: [
          _PickerSheetHeader(
            title: widget.label,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () => widget.onConfirm(_selectedValues),
          ),
          _buildCompactToolbar(context),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 16),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = _selectedValues.contains(item.value);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedValues.remove(item.value);
                      } else {
                        _selectedValues.add(item.value);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoDynamicColor.resolve(
                        isSelected
                            ? CupertinoColors.activeBlue.withValues(alpha: 0.12)
                            : CupertinoColors.secondarySystemGroupedBackground,
                        context,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoDynamicColor.resolve(
                          isSelected
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.separator,
                          context,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: CupertinoDynamicColor.resolve(
                                CupertinoColors.label,
                                context,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          isSelected
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.circle,
                          size: 20,
                          color: CupertinoDynamicColor.resolve(
                            isSelected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey3,
                            context,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleSelectPickerSheet extends StatefulWidget {
  const _SingleSelectPickerSheet({
    required this.label,
    required this.items,
    required this.initialIndex,
    required this.onConfirm,
  });

  final String label;
  final List<SelectOption> items;
  final int initialIndex;
  final ValueChanged<int> onConfirm;

  @override
  State<_SingleSelectPickerSheet> createState() =>
      _SingleSelectPickerSheetState();
}

class _SingleSelectPickerSheetState extends State<_SingleSelectPickerSheet> {
  late int _selectedIndex;
  late final FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _scrollController = FixedExtentScrollController(
      initialItem: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PickerSheetScaffold(
      height: 356,
      child: Column(
        children: [
          _PickerSheetHeader(
            title: widget.label,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () => widget.onConfirm(_selectedIndex),
          ),
          _SelectionSummaryCard(
            title: '当前选择',
            subtitle: widget.items[_selectedIndex].title,
            center: true,
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: _scrollController,
              itemExtent: 46,
              selectionOverlay: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.tertiarySystemFill,
                    context,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: widget.items.map((item) {
                return Center(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.label,
                        context,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 下拉选择表单项：标签 + 选择器（单选或多选）
class SelectFieldWidget extends StatelessWidget {
  const SelectFieldWidget({
    super.key,
    required this.block,
    this.value,
    this.onChanged,
  });

  final SelectFieldBlock block;
  final dynamic value;
  final ValueChanged<dynamic>? onChanged;

  String _getDisplayText() {
    if (value == null) return '请选择';
    if (block.multiple) {
      if (value is! List) return '请选择';
      final selected = (value as List).toSet();
      final titles = block.items
          .where((item) => selected.contains(item.value))
          .map((item) => item.title)
          .toList();
      if (titles.isEmpty) return '请选择';
      if (titles.length <= 2) return titles.join('、');
      return '${titles.take(2).join('、')} 等 ${titles.length} 项';
    } else {
      final item = block.items.firstWhere(
        (item) => item.value == value,
        orElse: () => block.items.first,
      );
      return item.title;
    }
  }

  String _getSelectionCountText() {
    if (!block.multiple || value is! List) return '';
    final count = (value as List).length;
    return count > 0 ? '$count 项' : '';
  }

  void _showPicker(BuildContext context) {
    if (block.multiple) {
      _showMultiSelectPicker(context);
    } else {
      _showSingleSelectPicker(context);
    }
  }

  void _showSingleSelectPicker(BuildContext context) {
    final currentIndex = block.items.indexWhere((item) => item.value == value);
    final selectedIndex = currentIndex >= 0 ? currentIndex : 0;

    showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (context) => _SingleSelectPickerSheet(
        label: block.label,
        items: block.items,
        initialIndex: selectedIndex,
        onConfirm: (index) {
          Navigator.of(context).pop();
          if (onChanged != null && index < block.items.length) {
            onChanged!(block.items[index].value);
          }
        },
      ),
    );
  }

  Widget _buildFieldCard(BuildContext context) {
    final displayText = _getDisplayText();
    final hasSelection = displayText != '请选择';
    final countText = _getSelectionCountText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.tertiarySystemFill,
          context,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.separator,
            context,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.secondaryLabel,
                      context,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayText,
                  maxLines: block.multiple ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: hasSelection
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: CupertinoDynamicColor.resolve(
                      hasSelection
                          ? CupertinoColors.label
                          : CupertinoColors.placeholderText,
                      context,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemBackground,
                context,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (countText.isNotEmpty) ...[
                  Text(
                    countText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.activeBlue,
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 14,
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondaryLabel,
                    context,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectPicker(BuildContext context) {
    final initialValues =
        (value is List ? (value as List).toSet() : <dynamic>{}).toSet();

    showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (context) => _MultiSelectPickerSheet(
        label: block.label,
        items: block.items,
        initialValues: initialValues,
        onConfirm: (selected) {
          Navigator.of(context).pop();
          if (onChanged != null) {
            onChanged!(selected.toList());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showPicker(context),
            child: _buildFieldCard(context),
          ),
        ],
      ),
    );
  }
}
