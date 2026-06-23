import 'package:realm/realm.dart';

part 'site_userdata_cache.realm.dart';

/// 站点用户数据（latest）本地缓存，按 domain 关联
@RealmModel()
class _SiteUserDataCache {
  @PrimaryKey()
  late String domain;
  late String username;
  late String userid;
  late String userLevel;
  late String joinAt;
  late double bonus;
  late int upload;
  late int download;
  late double ratio;
  late int seeding;
  late int leeching;
  late int seedingSize;
  late int leechingSize;
  late int messageUnread;
  late String errMsg;
  late String updatedDay;
  late String updatedTime;
}
