import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';

class VuetifyTextSupport {
  VuetifyTextSupport._();

  /// Collect visible text from a node tree, skipping VIcon nodes
  /// because their text is usually an MDI icon name, not user-visible text.
  static String collectVisibleText(FormNode node) {
    if (node.component == 'VIcon') return '';
    if (node.text != null) return node.text.toString().trim();
    final buffer = StringBuffer();
    for (final child in node.content) {
      final text = collectVisibleText(child);
      if (buffer.isNotEmpty && text.isNotEmpty) {
        buffer.write(' ');
      }
      buffer.write(text);
    }
    return buffer.toString();
  }
}
