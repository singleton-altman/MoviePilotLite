import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

bool isMoviePilotResourceProxyImageUrl(String imageUrl) {
  if (imageUrl.isEmpty) return false;
  try {
    final u = Uri.parse(imageUrl);
    final p = u.path;
    return p.contains('/api/v1/system/img') ||
        p.contains('/api/v1/system/cache/image');
  } catch (_) {
    return false;
  }
}

/// 会话 Cookie 只允许发给 MoviePilot 自己的服务端。
///
/// 图片地址可能直接指向 `image.tmdb.org` 等第三方域（全局缓存关闭、或地址
/// 本身就是直链时），此时把会话 Cookie 带上就等于把登录态交给对方。
bool isSameOriginAsServer(String imageUrl, {String? serverBaseUrl}) {
  if (imageUrl.isEmpty) return false;
  Uri target;
  try {
    target = Uri.parse(imageUrl);
  } catch (_) {
    return false;
  }
  final base = serverBaseUrl ?? _serverBaseUrl();
  if (base == null || base.isEmpty) return false;
  Uri server;
  try {
    server = Uri.parse(base);
  } catch (_) {
    return false;
  }
  if (target.host.isEmpty || server.host.isEmpty) return false;
  return target.host.toLowerCase() == server.host.toLowerCase();
}

String? _serverBaseUrl() {
  try {
    if (Get.isRegistered<ApiClient>()) {
      return Get.find<ApiClient>().baseUrl;
    }
  } catch (_) {}
  try {
    if (Get.isRegistered<AppService>()) {
      return Get.find<AppService>().baseUrl;
    }
  } catch (_) {}
  return null;
}

/// 构建图片请求头。
///
/// Cookie 仅在同源时附带；其它情况返回空 map，避免凭据外泄。
Map<String, String> buildImageRequestHeaders(
  String imageUrl, {
  String? cookie,
  String? serverBaseUrl,
}) {
  if (!isSameOriginAsServer(imageUrl, serverBaseUrl: serverBaseUrl)) {
    return const <String, String>{};
  }
  final imageCookie = cookie ?? _appCookie();
  if (imageCookie == null || imageCookie.isEmpty) {
    return const <String, String>{};
  }
  return {'cookie': imageCookie};
}

String? _appCookie() {
  try {
    if (Get.isRegistered<AppService>()) {
      return Get.find<AppService>().cookie;
    }
  } catch (_) {}
  return null;
}
