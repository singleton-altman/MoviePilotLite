import 'package:moviepilot_mobile/modules/discover/defines/discover_filter_defines.dart';

class DiscoverDynamicSource {
  const DiscoverDynamicSource({
    required this.id,
    required this.name,
    required this.mediaidPrefix,
    required this.apiPath,
    required this.filterParams,
    required this.groups,
    required this.depends,
  });

  final String id;
  final String name;
  final String mediaidPrefix;
  final String apiPath;
  final Map<String, dynamic> filterParams;
  final List<DiscoverDynamicFilterGroup> groups;
  final Map<String, List<String>> depends;

  factory DiscoverDynamicSource.fromJson(Map<String, dynamic> json) {
    final name = _stringValue(json['name']);
    final mediaidPrefix = _stringValue(json['mediaid_prefix']);
    final apiPath = _stringValue(json['api_path']);
    final groups = _parseGroups(json['filter_ui']);
    return DiscoverDynamicSource(
      id: mediaidPrefix.isNotEmpty ? mediaidPrefix : name,
      name: name.isNotEmpty ? name : mediaidPrefix,
      mediaidPrefix: mediaidPrefix,
      apiPath: apiPath,
      filterParams: _stringKeyMap(json['filter_params']),
      groups: groups,
      depends: _parseDepends(json['depends']),
    );
  }

  DiscoverDynamicFilters defaultFilters() {
    for (final group in groups) {
      if (group.options.isNotEmpty) {
        return DiscoverDynamicFilters(
          values: {group.model: group.options.first.value},
        );
      }
    }
    return const DiscoverDynamicFilters();
  }

  bool isFirstGroup(String model) {
    if (groups.isEmpty) return false;
    return groups.first.model == model;
  }

  DiscoverDynamicFilters selectValue(
    DiscoverDynamicFilters current,
    String model,
    String value,
  ) {
    final values = Map<String, String>.from(current.values);
    final currentValue = values[model];
    if (currentValue == value) {
      if (!isFirstGroup(model)) {
        values.remove(model);
      }
      return DiscoverDynamicFilters(values: values);
    }

    values[model] = value;
    for (final entry in depends.entries) {
      if (entry.value.contains(model) && entry.key != model) {
        values.remove(entry.key);
      }
    }
    return DiscoverDynamicFilters(values: values);
  }

  bool isGroupVisible(
    DiscoverDynamicFilterGroup group,
    DiscoverDynamicFilters filters,
  ) {
    final condition = group.showCondition;
    if (condition == null) return true;
    return filters.values[condition.model] == condition.value;
  }

  Iterable<DiscoverDynamicFilterGroup> visibleGroups(
    DiscoverDynamicFilters filters,
  ) {
    return groups.where((group) => isGroupVisible(group, filters));
  }

  Map<String, String> visibleQueryValues(DiscoverDynamicFilters filters) {
    final visibleModels = visibleGroups(
      filters,
    ).map((group) => group.model).toSet();
    final result = <String, String>{};
    for (final entry in filters.values.entries) {
      if (visibleModels.contains(entry.key) && entry.value.trim().isNotEmpty) {
        result[entry.key] = entry.value.trim();
      }
    }
    return result;
  }

  List<String> summaryParts(DiscoverDynamicFilters filters) {
    final parts = <String>[name];
    for (final group in visibleGroups(filters)) {
      final value = filters.values[group.model];
      if (value == null || value.isEmpty) continue;
      final label = group.labelFor(value);
      if (label.isNotEmpty) {
        parts.add(label);
      }
    }
    return parts;
  }

  String fallbackMediaType(DiscoverDynamicFilters filters) {
    final value = filters.values['mtype'];
    if (value == null || value.isEmpty) return name;
    for (final group in groups) {
      if (group.model != 'mtype') continue;
      final label = group.labelFor(value);
      if (label.isNotEmpty) return label;
    }
    return name;
  }

  static List<DiscoverDynamicFilterGroup> _parseGroups(dynamic raw) {
    if (raw is! List) return const [];
    final groups = <DiscoverDynamicFilterGroup>[];
    for (final node in raw) {
      if (node is Map) {
        _collectGroups(_stringKeyMap(node), groups);
      }
    }
    return groups;
  }

  static void _collectGroups(
    Map<String, dynamic> node,
    List<DiscoverDynamicFilterGroup> groups,
  ) {
    final chipGroup = _findComponent(node, 'VChipGroup');
    if (chipGroup != null) {
      final model = _stringValue(_propsOf(chipGroup)['model']);
      if (model.isNotEmpty) {
        final title = _labelTextOf(node);
        final options = _chipOptionsOf(chipGroup);
        if (options.isNotEmpty) {
          groups.add(
            DiscoverDynamicFilterGroup(
              title: title.isNotEmpty ? title : model,
              model: model,
              options: options,
              showCondition: _parseShowCondition(_propsOf(node)['show']),
            ),
          );
          return;
        }
      }
    }

    for (final child in _childrenOf(node)) {
      _collectGroups(child, groups);
    }
  }

  static List<DiscoverFilterOption> _chipOptionsOf(Map<String, dynamic> node) {
    final options = <DiscoverFilterOption>[];
    for (final child in _childrenOf(node)) {
      if (_stringValue(child['component']) != 'VChip') continue;
      final value = _stringValue(_propsOf(child)['value']);
      if (value.isEmpty) continue;
      final label = _stringValue(child['text']);
      options.add(
        DiscoverFilterOption(
          label: label.isNotEmpty ? label : value,
          value: value,
        ),
      );
    }
    return options;
  }

  static DiscoverDynamicShowCondition? _parseShowCondition(dynamic raw) {
    final text = _stringValue(raw).trim();
    if (text.isEmpty) return null;
    final match = RegExp(
      r'''\{\{\s*([A-Za-z0-9_]+)\s*==\s*['"]([^'"]+)['"]\s*\}\}''',
    ).firstMatch(text);
    if (match == null) return null;
    final model = match.group(1) ?? '';
    final value = match.group(2) ?? '';
    if (model.isEmpty || value.isEmpty) return null;
    return DiscoverDynamicShowCondition(model: model, value: value);
  }

  static Map<String, List<String>> _parseDepends(dynamic raw) {
    final map = _stringKeyMap(raw);
    final result = <String, List<String>>{};
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is! List) continue;
      final list = value
          .map(_stringValue)
          .where((item) => item.isNotEmpty)
          .toList();
      if (list.isNotEmpty) {
        result[entry.key] = list;
      }
    }
    return result;
  }

  static Map<String, dynamic>? _findComponent(
    Map<String, dynamic> node,
    String component,
  ) {
    if (_stringValue(node['component']) == component) return node;
    for (final child in _childrenOf(node)) {
      final found = _findComponent(child, component);
      if (found != null) return found;
    }
    return null;
  }

  static String _labelTextOf(Map<String, dynamic> node) {
    final label = _findComponent(node, 'VLabel');
    if (label == null) return '';
    return _stringValue(label['text']);
  }

  static Map<String, dynamic> _propsOf(Map<String, dynamic> node) {
    return _stringKeyMap(node['props']);
  }

  static List<Map<String, dynamic>> _childrenOf(Map<String, dynamic> node) {
    final content = node['content'];
    if (content is! List) return const [];
    return content.whereType<Map>().map(_stringKeyMap).toList();
  }

  static Map<String, dynamic> _stringKeyMap(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      if (key != null) {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}

class DiscoverDynamicFilterGroup {
  const DiscoverDynamicFilterGroup({
    required this.title,
    required this.model,
    required this.options,
    this.showCondition,
  });

  final String title;
  final String model;
  final List<DiscoverFilterOption> options;
  final DiscoverDynamicShowCondition? showCondition;

  String labelFor(String value) {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return value;
  }
}

class DiscoverDynamicShowCondition {
  const DiscoverDynamicShowCondition({
    required this.model,
    required this.value,
  });

  final String model;
  final String value;
}

class DiscoverDynamicFilters {
  const DiscoverDynamicFilters({this.values = const <String, String>{}});

  final Map<String, String> values;

  String signature() {
    final keys = values.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in keys) {
      buffer.write('$key=${values[key]};');
    }
    return buffer.toString();
  }
}
