import 'package:flutter/foundation.dart';
import 'package:moviepilot_mobile/utils/remote_host_guard.dart';

/// 自更新下载线路：直连或经 GitHub 加速源。
@immutable
class UpdateMirror {
  const UpdateMirror({
    required this.id,
    required this.label,
    required this.template,
    this.builtin = false,
    this.isDirect = false,
  });

  const UpdateMirror.direct()
    : id = directId,
      label = '直连 GitHub',
      template = '',
      builtin = true,
      isDirect = true;

  static const String directId = 'direct';
  static const String urlPlaceholder = '{url}';

  final String id;
  final String label;

  /// 前缀式（`https://ghproxy.net/`）或占位符式（`https://x/{url}`）。
  final String template;
  final bool builtin;
  final bool isDirect;

  /// 把 GitHub 原始下载地址转换为该线路的实际下载地址。
  String resolve(String sourceUrl) {
    if (isDirect) return sourceUrl;
    final trimmed = template.trim();
    if (trimmed.isEmpty) return sourceUrl;
    if (trimmed.contains(urlPlaceholder)) {
      return trimmed.replaceAll(urlPlaceholder, sourceUrl);
    }
    return trimmed.endsWith('/') ? '$trimmed$sourceUrl' : '$trimmed/$sourceUrl';
  }

  /// 校验用户输入，返回错误文案；合法时返回 null。
  static String? validateTemplate(String raw) => _templateError(raw);

  /// 把用户输入规整成可直接保存的前缀式模板；非法时返回 null。
  ///
  /// 用户常见的写法差异（缺协议、裸域名、多余空格）在这里统一补全，
  /// 避免「能拼出正确地址却被判非法」。
  static String? normalizeTemplate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (_templateError(value) != null) return null;
    if (value.contains(urlPlaceholder)) return value;
    final withScheme = _hasScheme(value) ? value : 'https://$value';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) return null;
    // 前缀式：没有路径时补结尾斜杠，保证拼接结果不带多余分隔。
    if (uri.path.isEmpty && !withScheme.endsWith('/')) return '$withScheme/';
    return withScheme;
  }

  static bool _hasScheme(String value) =>
      RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://').hasMatch(value);

  static String? _templateError(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '请输入加速源地址';
    if (!value.contains(urlPlaceholder) && !_hasScheme(value)) {
      value = 'https://$value';
    }
    final sample = value.replaceAll(urlPlaceholder, 'https://example.com/a.apk');
    final uri = Uri.tryParse(sample);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return '地址格式不正确';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return '仅支持 http/https 地址';
    }
    if (!isSafeRemoteHost(uri.host)) {
      return '不允许使用本机或内网地址';
    }
    if (value.contains(urlPlaceholder)) return null;
    // 前缀式：裸主机名或单段路径都能拼接，其余交给 normalizeTemplate 补斜杠。
    return null;
  }

  /// 用户未填写名称时，用域名作为展示名。
  static String labelFromTemplate(String raw) {
    final value = raw.trim();
    final sample = value.replaceAll(urlPlaceholder, '');
    final withScheme = _hasScheme(sample) ? sample : 'https://$sample';
    final uri = Uri.tryParse(withScheme);
    final host = uri?.host ?? '';
    return host.isEmpty ? value : host;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'template': template,
  };

  static UpdateMirror? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString().trim() ?? '';
    final template = raw['template']?.toString().trim() ?? '';
    if (id.isEmpty || template.isEmpty) return null;
    final label = raw['label']?.toString().trim() ?? '';
    return UpdateMirror(
      id: id,
      label: label.isEmpty ? labelFromTemplate(template) : label,
      template: template,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UpdateMirror &&
      other.id == id &&
      other.label == label &&
      other.template == template &&
      other.isDirect == isDirect;

  @override
  int get hashCode => Object.hash(id, label, template, isDirect);
}
