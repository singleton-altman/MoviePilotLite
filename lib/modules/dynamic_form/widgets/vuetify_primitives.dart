import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';

class VuetifyTonalStatCard extends StatelessWidget {
  const VuetifyTonalStatCard({
    super.key,
    required this.color,
    this.iconData,
    required this.value,
    required this.label,
  });

  final Color color;
  final IconData? iconData;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (iconData != null)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, size: 22, color: color),
            ),
          if (iconData != null) const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.label,
                context,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class VuetifyOutlinedButton extends StatelessWidget {
  const VuetifyOutlinedButton({
    super.key,
    required this.text,
    required this.color,
    this.iconData,
    this.onPressed,
  });

  final String text;
  final Color color;
  final IconData? iconData;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconData != null) ...[
              Icon(iconData, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VuetifyExpansionTile extends StatefulWidget {
  const VuetifyExpansionTile({
    super.key,
    this.titleNode,
    this.textNode,
    this.controller,
    required this.buildNode,
    required this.collectText,
  });

  final FormNode? titleNode;
  final FormNode? textNode;
  final DynamicFormController? controller;
  final Widget Function(FormNode node) buildNode;
  final String Function(FormNode node) collectText;

  @override
  State<VuetifyExpansionTile> createState() => _VuetifyExpansionTileState();
}

class _VuetifyExpansionTileState extends State<VuetifyExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    Widget titleWidget;
    if (widget.titleNode != null && widget.titleNode!.content.isNotEmpty) {
      titleWidget = widget.buildNode(widget.titleNode!);
    } else {
      final titleText = widget.titleNode != null
          ? widget.collectText(widget.titleNode!)
          : '';
      titleWidget = Text(
        titleText,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                Expanded(child: titleWidget),
                Icon(
                  _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 16,
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.tertiaryLabel,
                    context,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded && widget.textNode != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: widget.buildNode(widget.textNode!),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

class VuetifyTextInputField extends StatefulWidget {
  const VuetifyTextInputField({
    super.key,
    required this.label,
    this.hint,
    this.name,
    this.controller,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final String? name;
  final DynamicFormController? controller;
  final int maxLines;

  @override
  State<VuetifyTextInputField> createState() => _VuetifyTextInputFieldState();
}

class _VuetifyTextInputFieldState extends State<VuetifyTextInputField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final initial = widget.controller?.getValue(widget.name)?.toString() ?? '';
    _textController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.label,
                    context,
                  ),
                ),
              ),
            ),
          CupertinoTextField(
            controller: _textController,
            placeholder: widget.hint ?? widget.label,
            maxLines: widget.maxLines,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.tertiarySystemFill,
                context,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            onChanged: (value) {
              if (widget.name != null) {
                widget.controller?.updateField(widget.name, value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class VuetifyFormRow extends StatelessWidget {
  const VuetifyFormRow({
    super.key,
    required this.label,
    required this.trailing,
  });

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.label,
                  context,
                ),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
