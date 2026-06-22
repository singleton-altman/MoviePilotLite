import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_file_service_factory_stub.dart'
 if (dart.library.io) 'package:moviepilot_mobile/utils/image_file_service_factory_io.dart'
    if (dart.library.js_interop) 'package:moviepilot_mobile/utils/image_file_service_factory_web.dart';

/// 全局图片缓存管理器（缓存 14 天）
class AppImageCacheManager {
  AppImageCacheManager._();

  static final CacheManager instance = CacheManager(
    Config(
      'appImageCache',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 1000,
      fileService: createAppImageFileService(),
    ),
  );
}
