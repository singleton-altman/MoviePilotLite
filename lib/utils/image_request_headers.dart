import 'package:get/get.dart';
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

Map<String, String> buildImageRequestHeaders(
  String imageUrl, {
  String? cookie,
}) {
  final headers = <String, String>{};
  final imageCookie = cookie ?? Get.find<AppService>().cookie;
  if (imageCookie != null && imageCookie.isNotEmpty) {
    headers['cookie'] = imageCookie;
  }
  return headers;
}
