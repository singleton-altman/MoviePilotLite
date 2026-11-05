/// 出站请求的目标主机安全校验。
///
/// 用户可自定义加速源地址，发请求前必须先确认目标是公网 http/https 主机，
/// 避免把请求打到本机或内网服务上。
library;

/// 是否为可安全发起出站请求的公网主机。
///
/// 拒绝：非 http/https、本机名、单标签主机名、回环/私有/保留/组播地址。
bool isSafeRemoteHost(String host) {
  final normalized = host.trim().toLowerCase();
  if (normalized.isEmpty) return false;

  if (normalized == 'localhost' ||
      normalized.endsWith('.localhost') ||
      normalized.endsWith('.local') ||
      normalized.endsWith('.internal') ||
      normalized.endsWith('.lan') ||
      normalized.endsWith('.home.arpa')) {
    return false;
  }

  final address = normalized.startsWith('[') && normalized.endsWith(']')
      ? normalized.substring(1, normalized.length - 1)
      : normalized;

  if (address.contains(':')) return _isPublicIpv6(address);
  if (_isIpv4Literal(address)) return _isPublicIpv4(address);

  // 单标签主机名（如 intranet、nas）通常指向内网，按不安全处理。
  return address.contains('.');
}

/// 校验完整 URL：仅 http/https，且主机必须通过 [isSafeRemoteHost]。
bool isSafeRemoteUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  return isSafeRemoteHost(uri.host);
}

bool _isIpv4Literal(String value) {
  return RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(value);
}

bool _isPublicIpv4(String value) {
  final parts = value.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.any((part) => part == null)) return false;
  final octets = parts.cast<int>();
  if (octets.any((octet) => octet < 0 || octet > 255)) return false;
  final [a, b, c, _] = octets;

  if (a == 0) return false; // 0.0.0.0/8
  if (a == 10) return false; // 私有
  if (a == 127) return false; // 回环
  if (a == 169 && b == 254) return false; // 链路本地
  if (a == 172 && b >= 16 && b <= 31) return false; // 私有
  if (a == 192 && b == 168) return false; // 私有
  if (a == 192 && b == 0 && (c == 0 || c == 2)) return false; // 保留/文档
  if (a == 198 && (b == 18 || b == 19)) return false; // 基准测试
  if (a == 198 && b == 51 && c == 100) return false; // 文档
  if (a == 203 && b == 0 && c == 113) return false; // 文档
  if (a == 100 && b >= 64 && b <= 127) return false; // 运营商级 NAT
  if (a >= 224) return false; // 组播与保留
  return true;
}

bool _isPublicIpv6(String value) {
  var address = value;
  // IPv4 映射地址按其 IPv4 规则判断。
  if (address.startsWith('::ffff:')) {
    final mapped = address.substring('::ffff:'.length);
    return _isIpv4Literal(mapped) && _isPublicIpv4(mapped);
  }
  if (address == '::' || address == '::1') return false;
  if (address.startsWith('fe8') ||
      address.startsWith('fe9') ||
      address.startsWith('fea') ||
      address.startsWith('feb')) {
    return false; // 链路本地 fe80::/10
  }
  final first = address.split(':').first;
  if (first.startsWith('fc') || first.startsWith('fd')) return false; // ULA
  if (first.startsWith('ff')) return false; // 组播
  return true;
}
