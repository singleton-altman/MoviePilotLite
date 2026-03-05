import 'package:flutter/cupertino.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/theme/section.dart';

/// 开关表单项：标签 + Switch
class SwitchFieldWidget extends StatelessWidget {
  const SwitchFieldWidget({
    super.key,
    required this.block,
    this.value,
    this.onChanged,
  });

  final SwitchFieldBlock block;
  final bool? value;
  final ValueChanged<bool>? onChanged;

  bool get _effectiveValue => value ?? block.value;

  @override
  Widget build(BuildContext context) {
    return Section(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              block.label,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.label,
                  context,
                ),
              ),
            ),
          ),
          CupertinoSwitch(value: _effectiveValue, onChanged: onChanged),
        ],
      ),
    );
  }
}
