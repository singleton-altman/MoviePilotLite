/// Site user data (latest snapshot) local cache, keyed by domain.
class SiteUserDataCache {
  final String domain;
  final String username;
  final String userid;
  final String userLevel;
  final String joinAt;
  final double bonus;
  final int upload;
  final int download;
  final double ratio;
  final int seeding;
  final int leeching;
  final int seedingSize;
  final int leechingSize;
  final int messageUnread;
  final String errMsg;
  final String updatedDay;
  final String updatedTime;

  const SiteUserDataCache({
    required this.domain,
    required this.username,
    required this.userid,
    required this.userLevel,
    required this.joinAt,
    required this.bonus,
    required this.upload,
    required this.download,
    required this.ratio,
    required this.seeding,
    required this.leeching,
    required this.seedingSize,
    required this.leechingSize,
    required this.messageUnread,
    required this.errMsg,
    required this.updatedDay,
    required this.updatedTime,
  });
}
