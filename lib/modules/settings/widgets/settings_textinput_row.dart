import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsTextInputRow extends StatefulWidget {
  const SettingsTextInputRow({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.iconColor,
    required this.editable,
    this.textController,
    this.obscureText = false,
    this.onTextChanged,
    this.onTextSubmitted,
    this.maxLines,
    this.keyboardType,
    this.countableLength,
    this.enabled = true,
    this.suffix,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Color? iconColor;

  final bool editable;
  final TextEditingController? textController;
  final bool obscureText;
  final ValueChanged<String>? onTextChanged;
  final ValueChanged<String>? onTextSubmitted;
  final int? maxLines;
  final TextInputType? keyboardType;
  final int? countableLength;
  final bool enabled;

  final Widget? suffix;

  @override
  State<SettingsTextInputRow> createState() => _SettingsTextInputRowState();
}

class _SettingsTextInputRowState extends State<SettingsTextInputRow> {
  bool _plainText = false;

  String? get _helperText {
    final s = widget.description?.trim();
    if (s == null || s.isEmpty) return null;
    return widget.description;
  }

  InputDecoration _decoration(
    BuildContext context, {
    bool alignEnd = false,
    String? hintText,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
      ),
    );
    final fucusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
      ),
    );
    return InputDecoration(
      labelText: widget.title,
      helperText: _helperText,
      helperMaxLines: 2,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: fucusBorder,
      focusedBorder: border,
      border: border,
      filled: true,
      fillColor: Colors.transparent,
      alignLabelWithHint: alignEnd,
      counterText: widget.countableLength != null
          ? '${widget.textController?.text.length ?? 0}/${widget.countableLength}'
          : null,
      suffixIcon: _buildSuffixIcon(context),
      suffixIconConstraints: widget.suffix != null || widget.obscureText
          ? const BoxConstraints(minWidth: 58, minHeight: 48)
          : null,
      prefixIcon: _buildPrefixIcon(context),
    );
  }

  Widget? _buildPrefixIcon(BuildContext context) {
    return widget.icon != null
        ? Icon(widget.icon, color: widget.iconColor, size: 15)
        : null;
  }

  Widget? _buildSuffixIcon(BuildContext context) {
    if (widget.suffix != null) return widget.suffix;
    if (widget.obscureText) {
      return TextButton(
        onPressed: () => setState(() => _plainText = !_plainText),
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 36),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(_plainText ? '隐藏' : '明文'),
      );
    }
    return null;
  }

  Widget _buildSingleLineInput(BuildContext context) {
    final effectiveObscure = widget.obscureText && !_plainText;
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          readOnly: !widget.editable,
          enabled: true,
          maxLines: effectiveObscure ? 1 : widget.maxLines,
          keyboardType: widget.keyboardType,
          controller: widget.textController,
          obscureText: effectiveObscure,
          onChanged: widget.onTextChanged,
          onSubmitted: widget.onTextSubmitted,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
          decoration: _decoration(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSingleLineInput(context);
  }
}
