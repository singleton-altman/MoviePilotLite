import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';

class VuetifyAlertSpec {
  const VuetifyAlertSpec({required this.type, required this.text});

  final String type;
  final String text;
}

class VuetifySwitchFieldSpec {
  const VuetifySwitchFieldSpec({
    required this.label,
    required this.name,
    required this.value,
  });

  final String label;
  final String? name;
  final bool value;
}

class VuetifyCronFieldSpec {
  const VuetifyCronFieldSpec({
    required this.label,
    required this.name,
    required this.value,
    required this.hint,
  });

  final String label;
  final String? name;
  final String value;
  final String hint;
}

class VuetifyTextFieldSpec {
  const VuetifyTextFieldSpec({
    required this.label,
    required this.name,
    required this.value,
    this.hint,
    this.maxLines = 1,
  });

  final String label;
  final String? name;
  final String value;
  final String? hint;
  final int maxLines;
}

class VuetifySelectOptionSpec {
  const VuetifySelectOptionSpec({required this.title, required this.value});

  final String title;
  final dynamic value;
}

class VuetifySelectFieldSpec {
  const VuetifySelectFieldSpec({
    required this.label,
    required this.name,
    required this.items,
    required this.value,
    required this.multiple,
  });

  final String label;
  final String? name;
  final List<VuetifySelectOptionSpec> items;
  final dynamic value;
  final bool multiple;
}

class VuetifyChartSpec {
  const VuetifyChartSpec({
    required this.title,
    required this.labels,
    required this.series,
    required this.chartType,
  });

  final String? title;
  final List<String> labels;
  final List<num> series;
  final String chartType;
}

class VuetifyFormParser {
  VuetifyFormParser._();

  static bool boolFromDynamic(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is num) return value != 0;
    return false;
  }

  static dynamic valueFromModel(
    Map<String, dynamic>? model,
    String? key,
    dynamic fallback,
  ) {
    if (key == null || key.isEmpty || model == null) return fallback;
    return model[key] ?? fallback;
  }

  static String? fieldName(FormNode node) =>
      node.props?['model']?.toString() ?? node.props?['name']?.toString();

  static String fieldLabel(FormNode node) =>
      node.props?['label']?.toString().trim() ?? '';

  static String? fieldHint(FormNode node) =>
      node.props?['placeholder']?.toString() ?? node.props?['hint']?.toString();

  static VuetifyAlertSpec? parseAlert(FormNode node) {
    final props = node.props;
    if (props == null) return null;
    final type = props['type']?.toString().trim() ?? 'info';
    final text = props['text']?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return VuetifyAlertSpec(type: type, text: text);
  }

  static VuetifySwitchFieldSpec? parseSwitch(
    FormNode node, {
    Map<String, dynamic>? model,
  }) {
    final props = node.props;
    if (props == null) return null;
    final name = fieldName(node);
    final raw = valueFromModel(
      model,
      name,
      props['modelValue'] ?? props['value'],
    );
    return VuetifySwitchFieldSpec(
      label: fieldLabel(node),
      name: name,
      value: boolFromDynamic(raw),
    );
  }

  static VuetifyCronFieldSpec? parseCron(
    FormNode node, {
    Map<String, dynamic>? model,
  }) {
    final props = node.props;
    if (props == null) return null;
    final name = fieldName(node);
    final value = valueFromModel(
      model,
      name,
      props['modelValue'] ?? props['value'] ?? '',
    ).toString();
    return VuetifyCronFieldSpec(
      label: fieldLabel(node),
      name: name,
      value: value,
      hint: props['hint']?.toString() ?? '0 0 * * *',
    );
  }

  static VuetifyTextFieldSpec? parseTextField(
    FormNode node, {
    Map<String, dynamic>? model,
  }) {
    final props = node.props;
    if (props == null) return null;
    final name = fieldName(node);
    final value = valueFromModel(
      model,
      name,
      props['modelValue'] ?? props['value'] ?? '',
    ).toString();
    return VuetifyTextFieldSpec(
      label: fieldLabel(node),
      name: name,
      value: value,
      hint: fieldHint(node),
    );
  }

  static VuetifyTextFieldSpec? parseTextArea(
    FormNode node, {
    Map<String, dynamic>? model,
  }) {
    final props = node.props;
    if (props == null) return null;
    final name = fieldName(node);
    final value = valueFromModel(
      model,
      name,
      props['modelValue'] ?? props['value'] ?? '',
    ).toString();
    final rowsRaw = props['rows'];
    final rows = rowsRaw is int
        ? rowsRaw
        : (int.tryParse(rowsRaw?.toString() ?? '') ?? 3);
    return VuetifyTextFieldSpec(
      label: fieldLabel(node),
      name: name,
      value: value,
      hint: fieldHint(node),
      maxLines: rows.clamp(2, 10),
    );
  }

  static VuetifySelectFieldSpec? parseSelect(
    FormNode node, {
    Map<String, dynamic>? model,
  }) {
    final props = node.props;
    if (props == null) return null;
    final itemsRaw = props['items'];
    if (itemsRaw is! List) return null;
    final items = <VuetifySelectOptionSpec>[];
    for (final item in itemsRaw) {
      if (item is Map<String, dynamic>) {
        final title = item['title']?.toString() ?? '';
        if (title.isNotEmpty) {
          items.add(
            VuetifySelectOptionSpec(title: title, value: item['value']),
          );
        }
      }
    }
    if (items.isEmpty) return null;
    final name = fieldName(node);
    final raw = valueFromModel(
      model,
      name,
      props['modelValue'] ?? props['value'],
    );
    return VuetifySelectFieldSpec(
      label: fieldLabel(node),
      name: name,
      items: items,
      value: raw,
      multiple: boolFromDynamic(props['multiple'] ?? false),
    );
  }

  static VuetifyChartSpec? parseChart(FormNode node) {
    final props = node.props;
    if (props == null) return null;
    final optionsRaw = props['options'];
    if (optionsRaw is! Map) return null;
    final options = Map<String, dynamic>.from(optionsRaw);
    final chartRaw = options['chart'];
    final chartType = chartRaw is Map
        ? chartRaw['type']?.toString().trim().toLowerCase() ?? 'pie'
        : 'pie';
    final titleRaw = options['title'];
    final title = titleRaw is Map ? titleRaw['text']?.toString().trim() : null;
    final labelsRaw = options['labels'];
    final labels = labelsRaw is List
        ? labelsRaw.map((item) => item?.toString() ?? '').toList()
        : <String>[];
    final seriesRaw = props['series'];
    final series = seriesRaw is List
        ? seriesRaw
              .map(
                (item) => item is num
                    ? item
                    : (num.tryParse(item?.toString() ?? '') ?? 0),
              )
              .toList()
        : <num>[];
    if (series.isEmpty) return null;
    return VuetifyChartSpec(
      title: title,
      labels: labels,
      series: series,
      chartType: chartType,
    );
  }
}
