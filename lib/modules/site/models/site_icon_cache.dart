import 'package:realm/realm.dart';

part 'site_icon_cache.realm.dart';

/// 站点图标本地缓存：以站点 url 为 key，base64 为 value，避免重复请求
@RealmModel()
class _SiteIconCache {
  @PrimaryKey()
  late String url;
  late String iconBase64;
}
