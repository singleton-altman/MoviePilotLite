import 'package:freezed_annotation/freezed_annotation.dart';

part 'dynamic_form_models.freezed.dart';
part 'dynamic_form_models.g.dart';

/// 动态表单顶层响应（支持 page 展示页 或 conf+model 配置表单）
@freezed
class DynamicFormResponse with _$DynamicFormResponse {
  const factory DynamicFormResponse({
    String? render_mode,
    @Default([]) List<FormNode> page,
    @Default([]) List<FormNode> conf,
    Map<String, dynamic>? model,
  }) = _DynamicFormResponse;

  factory DynamicFormResponse.fromJson(Map<String, dynamic> json) =>
      _$DynamicFormResponseFromJson(json);
}

String _stringFromJson(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

/// 宽容解析:部分插件不按 List[dict] 约定返回,单个 dict 视为单节点包成列表,
/// 列表里的非 Map 条目跳过而不是让整个表单清空。
List<FormNode> _contentFromJson(Object? value) {
  if (value is Map) {
    return [FormNode.fromJson(Map<String, dynamic>.from(value))];
  }
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => FormNode.fromJson(Map<String, dynamic>.from(entry)))
      .toList();
}

/// 标准化 FormNode JSON，兼容 type-based 与 component-based 两种结构：
/// - type-based: {"type": "div", "class": "dashboard-stats", "content": [...]}
/// - component-based: {"component": "VCard", "props": {...}, "content": [...]}
Map<String, dynamic> _normalizeFormNodeJson(Map<String, dynamic> json) {
  final map = Map<String, dynamic>.from(json);
  if ((map['component'] == null || map['component'] == '') &&
      map['type'] != null) {
    map['component'] = map['type'];
  }
  final props = Map<String, dynamic>.from(map['props'] ?? {});
  for (final k in ['class', 'style']) {
    if (map[k] != null) props[k] = map[k];
  }
  if (props.isNotEmpty) map['props'] = props;
  if (map['content'] is String) {
    map['text'] ??= map['content'];
    map['content'] = null;
  }
  return map;
}

/// 递归表单节点（component / props / content / text / events）
@freezed
class FormNode with _$FormNode {
  const factory FormNode({
    @JsonKey(fromJson: _stringFromJson) @Default('') String component,
    Map<String, dynamic>? props,
    @JsonKey(fromJson: _contentFromJson) @Default([]) List<FormNode> content,
    dynamic text,
    Map<String, dynamic>? events,
  }) = _FormNode;

  factory FormNode.fromJson(Map<String, dynamic> json) =>
      _$FormNodeFromJson(_normalizeFormNodeJson(json));
}
