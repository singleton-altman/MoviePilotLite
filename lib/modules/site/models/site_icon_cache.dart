import 'package:hive_ce/hive.dart';

part 'site_icon_cache.g.dart';

/// 站点图标本地缓存：以站点 url 为 key，base64 为 value，避免重复请求
@HiveType(typeId: 5)
class SiteIconCache {
  @HiveField(0)
  String url;

  @HiveField(1)
  String iconBase64;

  SiteIconCache(this.url, this.iconBase64);
}
