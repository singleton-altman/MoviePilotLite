import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/settings/models/system_env_model.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 图片工具类
class ImageUtil extends GetxService {
  final globalCachedEnabled = false.obs;
  final _apiClient = Get.find<ApiClient>();
  loadGlobalCachedConfig() async {
    globalCachedEnabled.value = await _loadGlobalCachedEnabled();
    final resp = await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/system/env',
    );
    if (resp.statusCode != null &&
        resp.statusCode! >= 200 &&
        resp.statusCode! < 300) {
      final body = resp.data;
      if (body != null) {
        final parsed = SystemEnvResponse.fromJson(body);
        if (parsed.success && parsed.data != null) {
          globalCachedEnabled.value = parsed.data?.globalImageCache ?? false;
          return;
        }
      }
    }
  }

  Future<bool> _loadGlobalCachedEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(kGlobalCachedEnabledKey);
    if (stored == null) return false;
    return stored;
  }

  Future<void> saveGlobalCachedEnabled(bool value) async {
    globalCachedEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kGlobalCachedEnabledKey, value);
  }

  /// 将内网图片地址转换为可访问的外部地址
  ///
  /// [imageUrl] 内网图片地址，例如：http://192.168.31.173:8096/Items/6100/Images/Primary
  /// [baseUrl] 基础URL，例如：https://xx.x.ddnsto.com
  ///
  /// 返回拼接后的外部访问地址，例如：https://xx.x.ddnsto.com/api/v1/system/img/0?imgurl=http%3A%2F%2F192.168.31.173%3A8096%2FItems%2F6100%2FImages%2FPrimary
  static String convertInternalImageUrl(String imageUrl, {String? baseUrl}) {
    if (imageUrl.isEmpty) return '';
    final apiClient = Get.find<ApiClient>();

    // final imageUtil = Get.find<ImageUtil>();
    // if (!imageUtil.globalCachedEnabled.value) {
    //   return imageUrl;
    // }

    // 如果没有提供baseUrl，则从AppService读取
    baseUrl ??= apiClient.baseUrl ?? '';

    // 编码图片地址
    final encodedImageUrl = Uri.encodeComponent(imageUrl);

    // 拼接外部访问地址
    final url =
        '$baseUrl/api/v1/system/img/0?imgurl=$encodedImageUrl&use_cookies=true';
    return url;
  }

  /// 将图片地址转换为缓存代理地址
  ///
  /// [imageUrl] 原始图片地址
  /// [baseUrl] 基础URL，例如：https://xx.x.ddnsto.com
  ///
  /// 返回拼接后的缓存访问地址，例如：
  /// https://xx.x.ddnsto.com/api/v1/system/cache/image?url=https%3A%2F%2Fimage.tmdb.org%2F...
  static String convertCacheImageUrl(String imageUrl, {String? baseUrl}) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.contains('/api/v1/system/cache/image')) {
      return imageUrl;
    }
    final imageUtil = Get.find<ImageUtil>();
    if (!imageUtil.globalCachedEnabled.value) {
      return imageUrl;
    }
    final apiClient = Get.find<ApiClient>();
    baseUrl ??= apiClient.baseUrl ?? '';
    if (baseUrl.isEmpty) return imageUrl;

    final sanitizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final encodedImageUrl = Uri.encodeComponent(imageUrl);
    return '$sanitizedBase/api/v1/system/cache/image?url=$encodedImageUrl';
  }

  /// 将插件图标地址转换为可访问的 URL
  ///
  /// [pluginIcon] 插件图标：若以 http 开头，则通过 api/v1/system/img/1 代理；否则使用 baseUrl/plugin_icon/{pluginIcon}
  static String convertPluginIconUrl(String pluginIcon, {String? baseUrl}) {
    if (pluginIcon.isEmpty) return '';
    final imageUtil = Get.find<ImageUtil>();
    if (!imageUtil.globalCachedEnabled.value) {
      return pluginIcon;
    }
    final apiClient = Get.find<ApiClient>();
    baseUrl ??= apiClient.baseUrl ?? '';
    if (baseUrl.isEmpty) return pluginIcon;
    final sanitizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (pluginIcon.toLowerCase().startsWith('http')) {
      final encoded = Uri.encodeComponent(pluginIcon);
      return '$sanitizedBase/api/v1/system/img/1?imgurl=$encoded';
    }
    return '$sanitizedBase/plugin_icon/$pluginIcon';
  }

  static String convertMediaSeasonImageUrl(String imageUrl, {String? baseUrl}) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.contains('/api/v1/system/cache/image')) {
      return imageUrl;
    }

    baseUrl ??= 'https://image.tmdb.org/t/p/w500/';
    if (baseUrl.isEmpty) return imageUrl;

    return '$baseUrl$imageUrl';
  }
}
