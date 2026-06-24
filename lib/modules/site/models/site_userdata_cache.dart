import 'package:hive_ce/hive.dart';

part 'site_userdata_cache.g.dart';

/// 站点用户数据（latest）本地缓存，按 domain 关联
@HiveType(typeId: 7)
class SiteUserDataCache {
  @HiveField(0)
  String domain;
  @HiveField(1)
  String username;
  @HiveField(2)
  String userid;
  @HiveField(3)
  String userLevel;
  @HiveField(4)
  String joinAt;
  @HiveField(5)
  double bonus;
  @HiveField(6)
  int upload;
  @HiveField(7)
  int download;
  @HiveField(8)
  double ratio;
  @HiveField(9)
  int seeding;
  @HiveField(10)
  int leeching;
  @HiveField(11)
  int seedingSize;
  @HiveField(12)
  int leechingSize;
  @HiveField(13)
  int messageUnread;
  @HiveField(14)
  String errMsg;
  @HiveField(15)
  String updatedDay;
  @HiveField(16)
  String updatedTime;

  SiteUserDataCache(
    this.domain,
    this.username,
    this.userid,
    this.userLevel,
    this.joinAt,
    this.bonus,
    this.upload,
    this.download,
    this.ratio,
    this.seeding,
    this.leeching,
    this.seedingSize,
    this.leechingSize,
    this.messageUnread,
    this.errMsg,
    this.updatedDay,
    this.updatedTime,
  );
}
