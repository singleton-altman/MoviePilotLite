import 'package:realm/realm.dart';

part 'site_model_cache.realm.dart';

/// 站点信息本地缓存，用于加速启动时先展示
@RealmModel()
class _SiteModelCache {
  @PrimaryKey()
  late int id;
  late String name;
  late String domain;
  late String url;
  late int pri;
  late String rss;
  late String cookie;
  late String ua;
  late String apikey;
  late String token;
  late int proxy;
  late String filter;
  late int render;
  late int public;
  late String note;
  late int timeout;
  late int limitInterval;
  late int limitCount;
  late int limitSeconds;
  late bool isActive;
  late String downloader;
}
