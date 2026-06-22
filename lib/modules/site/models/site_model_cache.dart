/// Site info local cache for fast startup display.
class SiteModelCache {
  final int id;
  final String name;
  final String domain;
  final String url;
  final int pri;
  final String rss;
  final String cookie;
  final String ua;
  final String apikey;
  final String token;
  final int proxy;
  final String filter;
  final int render;
  final int public;
  final String note;
  final int timeout;
  final int limitInterval;
  final int limitCount;
  final int limitSeconds;
  final bool isActive;
  final String downloader;

  const SiteModelCache({
    required this.id,
    required this.name,
    required this.domain,
    required this.url,
    required this.pri,
    required this.rss,
    required this.cookie,
    required this.ua,
    required this.apikey,
    required this.token,
    required this.proxy,
    required this.filter,
    required this.render,
    required this.public,
    required this.note,
    required this.timeout,
    required this.limitInterval,
    required this.limitCount,
    required this.limitSeconds,
    required this.isActive,
    required this.downloader,
  });
}
