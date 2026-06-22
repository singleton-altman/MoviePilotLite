import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_form_parser.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/vuetify_primitives.dart';

class VuetifySwitchField extends StatelessWidget {
  const VuetifySwitchField({super.key, required this.spec, this.controller});

  final VuetifySwitchFieldSpec spec;
  final DynamicFormController? controller;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;
    if (ctrl == null || spec.name == null) {
      return VuetifyFormRow(
        label: spec.label,
        trailing: CupertinoSwitch(value: spec.value, onChanged: null),
      );
    }

    return Obx(() {
      final value = ctrl.getBoolValue(spec.name);
      return VuetifyFormRow(
        label: spec.label,
        trailing: CupertinoSwitch(
          value: value,
          onChanged: (next) => ctrl.updateField(spec.name, next),
        ),
      );
    });
  }
}

class VuetifySelectField extends StatelessWidget {
  const VuetifySelectField({
    super.key,
    required this.spec,
    required this.controller,
  });

  final VuetifySelectFieldSpec spec;
  final DynamicFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.getValue(spec.name);
      final summary = _selectionSummary(current);
      final hasSelection = summary.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showPicker(context, current),
          child: Container(
            width: double.infinity,
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
                      if (spec.label.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            spec.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel,
                                context,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        hasSelection ? summary : '请选择',
                        maxLines: spec.multiple ? 2 : 1,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
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
                      if (spec.multiple && hasSelection) ...[
                        Text(
                          _selectionCountLabel(current),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
          ),
        ),
      );
    });
  }

  String _selectionSummary(dynamic current) {
    if (spec.multiple && current is Iterable) {
      final values = current.toSet();
      final titles = <String>[];
      for (final item in spec.items) {
        if (values.contains(item.value)) {
          titles.add(item.title);
        }
      }
      if (titles.isEmpty) return '';
      if (titles.length <= 2) return titles.join('、');
      return '${titles.take(2).join('、')} 等 ${titles.length} 项';
    }

    for (final item in spec.items) {
      if (item.value == current) {
        return item.title;
      }
    }
    return '';
  }

  String _selectionCountLabel(dynamic current) {
    if (current is! Iterable) return '';
    final count = current.length;
    if (count <= 0) return '';
    return '$count 项';
  }

  void _showPicker(BuildContext context, dynamic current) {
    if (spec.multiple) {
      _showMultiSelectPicker(context, current);
      return;
    }
    _showSingleSelectPicker(context, current);
  }

  void _showSingleSelectPicker(BuildContext context, dynamic current) {
    final currentIndex = spec.items.indexWhere((item) => item.value == current);
    final initialIndex = currentIndex >= 0 ? currentIndex : 0;

    showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _VuetifySingleSelectSheet(
        label: spec.label,
        items: spec.items,
        initialIndex: initialIndex,
        onConfirm: (selectedIndex) {
          controller.updateField(spec.name, spec.items[selectedIndex].value);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  void _showMultiSelectPicker(BuildContext context, dynamic current) {
    final initialValues = current is Iterable ? current.toSet() : <dynamic>{};

    showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _VuetifyMultiSelectSheet(
        label: spec.label,
        items: spec.items,
        initialValues: initialValues,
        onConfirm: (selected) {
          controller.updateField(spec.name, selected.toList());
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _VuetifySingleSelectSheet extends StatefulWidget {
  const _VuetifySingleSelectSheet({
    required this.label,
    required this.items,
    required this.initialIndex,
    required this.onConfirm,
  });

  final String label;
  final List<VuetifySelectOptionSpec> items;
  final int initialIndex;
  final ValueChanged<int> onConfirm;

  @override
  State<_VuetifySingleSelectSheet> createState() =>
      _VuetifySingleSelectSheetState();
}

class _VuetifySingleSelectSheetState extends State<_VuetifySingleSelectSheet> {
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
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemGroupedBackground,
            context,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _VuetifyPickerSheetHeader(
              title: widget.label,
              trailingText: '确定',
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: () => widget.onConfirm(_selectedIndex),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondarySystemGroupedBackground,
                    context,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.items[_selectedIndex].title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.label,
                      context,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: _scrollController,
                itemExtent: 44,
                selectionOverlay: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.tertiarySystemFill,
                      context,
                    ),
                    borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
}

class _VuetifyMultiSelectSheet extends StatefulWidget {
  const _VuetifyMultiSelectSheet({
    required this.label,
    required this.items,
    required this.initialValues,
    required this.onConfirm,
  });

  final String label;
  final List<VuetifySelectOptionSpec> items;
  final Set<dynamic> initialValues;
  final ValueChanged<Set<dynamic>> onConfirm;

  @override
  State<_VuetifyMultiSelectSheet> createState() =>
      _VuetifyMultiSelectSheetState();
}

class _VuetifyMultiSelectSheetState extends State<_VuetifyMultiSelectSheet> {
  late Set<dynamic> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = Set.of(widget.initialValues);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
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
            _VuetifyPickerSheetHeader(
              title: widget.label,
              trailingText: '确定',
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: () => widget.onConfirm(_selectedValues),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Text(
                    _selectedValues.isEmpty
                        ? '请选择项目'
                        : '已选择 ${_selectedValues.length} 项',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CupertinoDynamicColor.resolve(
                        _selectedValues.isEmpty
                            ? CupertinoColors.secondaryLabel
                            : CupertinoColors.activeBlue,
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
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
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoDynamicColor.resolve(
                          isSelected
                              ? CupertinoColors.activeBlue.withValues(
                                  alpha: 0.12,
                                )
                              : CupertinoColors
                                    .secondarySystemGroupedBackground,
                          context,
                        ),
                        borderRadius: BorderRadius.circular(14),
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
                                    ? FontWeight.w600
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
      ),
    );
  }
}

class _VuetifyPickerSheetHeader extends StatelessWidget {
  const _VuetifyPickerSheetHeader({
    required this.title,
    required this.trailingText,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String trailingText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              title.isEmpty ? '选择项目' : title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
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
            child: Text(trailingText),
          ),
        ],
      ),
    );
  }
}

class VuetifyCronField extends StatelessWidget {
  const VuetifyCronField({super.key, required this.spec, this.controller});

  final VuetifyCronFieldSpec spec;
  final DynamicFormController? controller;

  @override
  Widget build(BuildContext context) {
    return VuetifyTextInputField(
      label: spec.label,
      hint: spec.hint,
      name: spec.name,
      controller: controller,
      maxLines: 1,
    );
  }
}
