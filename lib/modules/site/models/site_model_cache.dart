import 'package:hive_ce/hive.dart';

part 'site_model_cache.g.dart';

/// 站点信息本地缓存，用于加速启动时先展示
@HiveType(typeId: 6)
class SiteModelCache {
  @HiveField(0)
  int id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String domain;
  @HiveField(3)
  String url;
  @HiveField(4)
  int pri;
  @HiveField(5)
  String rss;
  @HiveField(6)
  String cookie;
  @HiveField(7)
  String ua;
  @HiveField(8)
  String apikey;
  @HiveField(9)
  String token;
  @HiveField(10)
  int proxy;
  @HiveField(11)
  String filter;
  @HiveField(12)
  int render;
  @HiveField(13)
  int public;
  @HiveField(14)
  String note;
  @HiveField(15)
  int timeout;
  @HiveField(16)
  int limitInterval;
  @HiveField(17)
  int limitCount;
  @HiveField(18)
  int limitSeconds;
  @HiveField(19)
  bool isActive;
  @HiveField(20)
  String downloader;

  SiteModelCache(
    this.id,
    this.name,
    this.domain,
    this.url,
    this.pri,
    this.rss,
    this.cookie,
    this.ua,
    this.apikey,
    this.token,
    this.proxy,
    this.filter,
    this.render,
    this.public,
    this.note,
    this.timeout,
    this.limitInterval,
    this.limitCount,
    this.limitSeconds,
    this.isActive,
    this.downloader,
  );
}
