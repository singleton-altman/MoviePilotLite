class BrushFlowOption {
  const BrushFlowOption({required this.title, required this.value});

  final String title;
  final dynamic value;

  factory BrushFlowOption.fromJson(Map<String, dynamic> json) {
    return BrushFlowOption(
      title: json['title']?.toString() ?? '',
      value: json['value'],
    );
  }
}

class BrushFlowStatistic {
  const BrushFlowStatistic({
    this.count = 0,
    this.deleted = 0,
    this.uploaded = 0,
    this.downloaded = 0,
    this.unarchived = 0,
    this.active = 0,
    this.activeUploaded = 0,
    this.activeDownloaded = 0,
  });

  final int count;
  final int deleted;
  final int uploaded;
  final int downloaded;
  final int unarchived;
  final int active;
  final int activeUploaded;
  final int activeDownloaded;

  factory BrushFlowStatistic.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BrushFlowStatistic();
    return BrushFlowStatistic(
      count: _asInt(json['count']),
      deleted: _asInt(json['deleted']),
      uploaded: _asInt(json['uploaded']),
      downloaded: _asInt(json['downloaded']),
      unarchived: _asInt(json['unarchived']),
      active: _asInt(json['active']),
      activeUploaded: _asInt(json['active_uploaded']),
      activeDownloaded: _asInt(json['active_downloaded']),
    );
  }
}

class BrushFlowSummary {
  const BrushFlowSummary({
    this.taskCount = 0,
    this.enabledCount = 0,
    this.activeCount = 0,
    this.uploaded = 0,
    this.downloaded = 0,
    this.seedingSize = 0,
  });

  final int taskCount;
  final int enabledCount;
  final int activeCount;
  final int uploaded;
  final int downloaded;
  final int seedingSize;

  factory BrushFlowSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BrushFlowSummary();
    return BrushFlowSummary(
      taskCount: _asInt(json['task_count']),
      enabledCount: _asInt(json['enabled_count']),
      activeCount: _asInt(json['active_count']),
      uploaded: _asInt(json['uploaded']),
      downloaded: _asInt(json['downloaded']),
      seedingSize: _asInt(json['seeding_size']),
    );
  }
}

class BrushFlowTask {
  const BrushFlowTask({
    required this.id,
    required this.name,
    this.enabled = false,
    this.siteId,
    this.siteName,
    this.downloader,
    this.brushInterval,
    this.checkInterval,
    this.cron,
    this.activeTimeRange,
    this.state,
    this.operation,
    this.lastError,
    this.nextRunAt,
    this.lastRun,
    this.statistic = const BrushFlowStatistic(),
    this.seedingSize = 0,
  });

  final String id;
  final String name;
  final bool enabled;
  final int? siteId;
  final String? siteName;
  final String? downloader;
  final int? brushInterval;
  final int? checkInterval;
  final String? cron;
  final String? activeTimeRange;
  final String? state;
  final String? operation;
  final String? lastError;
  final String? nextRunAt;
  final String? lastRun;
  final BrushFlowStatistic statistic;
  final int seedingSize;

  BrushFlowTask copyWith({
    String? id,
    String? name,
    bool? enabled,
    int? siteId,
    String? siteName,
    String? downloader,
    int? brushInterval,
    int? checkInterval,
    String? cron,
    String? activeTimeRange,
    String? state,
    String? operation,
    String? lastError,
    String? nextRunAt,
    String? lastRun,
    BrushFlowStatistic? statistic,
    int? seedingSize,
  }) {
    return BrushFlowTask(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      downloader: downloader ?? this.downloader,
      brushInterval: brushInterval ?? this.brushInterval,
      checkInterval: checkInterval ?? this.checkInterval,
      cron: cron ?? this.cron,
      activeTimeRange: activeTimeRange ?? this.activeTimeRange,
      state: state ?? this.state,
      operation: operation ?? this.operation,
      lastError: lastError ?? this.lastError,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      lastRun: lastRun ?? this.lastRun,
      statistic: statistic ?? this.statistic,
      seedingSize: seedingSize ?? this.seedingSize,
    );
  }

  factory BrushFlowTask.fromJson(Map<String, dynamic> json) {
    return BrushFlowTask(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      enabled: json['enabled'] == true,
      siteId: _asIntOrNull(json['site_id']),
      siteName: json['site_name']?.toString(),
      downloader: json['downloader']?.toString(),
      brushInterval: _asIntOrNull(json['brush_interval']),
      checkInterval: _asIntOrNull(json['check_interval']),
      cron: json['cron']?.toString(),
      activeTimeRange: json['active_time_range']?.toString(),
      state: json['state']?.toString(),
      operation: json['operation']?.toString(),
      lastError: json['last_error']?.toString(),
      nextRunAt: json['next_run_at']?.toString(),
      lastRun: json['last_run']?.toString(),
      statistic: BrushFlowStatistic.fromJson(
        json['statistic'] is Map
            ? Map<String, dynamic>.from(json['statistic'] as Map)
            : null,
      ),
      seedingSize: _asInt(json['seeding_size']),
    );
  }
}

class BrushFlowTaskConfig {
  const BrushFlowTaskConfig({
    this.id = '',
    this.name = '',
    this.enabled = true,
    this.notify = true,
    this.siteId,
    this.downloader,
    this.brushInterval = 10,
    this.checkInterval = 5,
    this.cron,
    this.activeTimeRange,
    this.disksize,
    this.maxupspeed,
    this.maxdlspeed,
    this.maxdlcount,
    this.freeleech = 'free',
    this.hr = 'yes',
    this.include,
    this.exclude,
    this.size,
    this.seeder,
    this.timezoneOffset = 0,
    this.pubtime,
    this.seedTime,
    this.hrSeedTime,
    this.seedRatio,
    this.seedSize,
    this.downloadTime,
    this.seedAvgspeed,
    this.seedInactivetime,
    this.deleteSizeRange,
    this.upSpeed,
    this.dlSpeed,
    this.autoArchiveDays,
    this.savePath,
    this.deleteExceptTags,
    this.exceptSubscribe = true,
    this.proxyDelete = false,
    this.delNoFree = false,
    this.qbCategory,
    this.siteHrActive = false,
    this.siteSkipTips = false,
    this.rssSupport = false,
  });

  final String id;
  final String name;
  final bool enabled;
  final bool notify;
  final int? siteId;
  final String? downloader;
  final int? brushInterval;
  final int? checkInterval;
  final String? cron;
  final String? activeTimeRange;
  final num? disksize;
  final num? maxupspeed;
  final num? maxdlspeed;
  final int? maxdlcount;
  final String? freeleech;
  final String? hr;
  final String? include;
  final String? exclude;
  final String? size;
  final String? seeder;
  final num? timezoneOffset;
  final String? pubtime;
  final num? seedTime;
  final num? hrSeedTime;
  final num? seedRatio;
  final num? seedSize;
  final num? downloadTime;
  final num? seedAvgspeed;
  final num? seedInactivetime;
  final String? deleteSizeRange;
  final num? upSpeed;
  final num? dlSpeed;
  final num? autoArchiveDays;
  final String? savePath;
  final String? deleteExceptTags;
  final bool exceptSubscribe;
  final bool proxyDelete;
  final bool delNoFree;
  final String? qbCategory;
  final bool siteHrActive;
  final bool siteSkipTips;
  final bool rssSupport;

  factory BrushFlowTaskConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BrushFlowTaskConfig();
    return BrushFlowTaskConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      enabled: json['enabled'] == true,
      notify: json['notify'] == true,
      siteId: _asIntOrNull(json['site_id']),
      downloader: json['downloader']?.toString(),
      brushInterval: _asIntOrNull(json['brush_interval']),
      checkInterval: _asIntOrNull(json['check_interval']),
      cron: _asNullableString(json['cron']),
      activeTimeRange: _asNullableString(json['active_time_range']),
      disksize: _asNumOrNull(json['disksize']),
      maxupspeed: _asNumOrNull(json['maxupspeed']),
      maxdlspeed: _asNumOrNull(json['maxdlspeed']),
      maxdlcount: _asIntOrNull(json['maxdlcount']),
      freeleech: _asNullableString(json['freeleech']),
      hr: _asNullableString(json['hr']),
      include: _asNullableString(json['include']),
      exclude: _asNullableString(json['exclude']),
      size: _asNullableString(json['size']),
      seeder: _asNullableString(json['seeder']),
      timezoneOffset: _asNumOrNull(json['timezone_offset']) ?? 0,
      pubtime: _asNullableString(json['pubtime']),
      seedTime: _asNumOrNull(json['seed_time']),
      hrSeedTime: _asNumOrNull(json['hr_seed_time']),
      seedRatio: _asNumOrNull(json['seed_ratio']),
      seedSize: _asNumOrNull(json['seed_size']),
      downloadTime: _asNumOrNull(json['download_time']),
      seedAvgspeed: _asNumOrNull(json['seed_avgspeed']),
      seedInactivetime: _asNumOrNull(json['seed_inactivetime']),
      deleteSizeRange: _asNullableString(json['delete_size_range']),
      upSpeed: _asNumOrNull(json['up_speed']),
      dlSpeed: _asNumOrNull(json['dl_speed']),
      autoArchiveDays: _asNumOrNull(json['auto_archive_days']),
      savePath: _asNullableString(json['save_path']),
      deleteExceptTags: _asNullableString(json['delete_except_tags']),
      exceptSubscribe: json['except_subscribe'] == true,
      proxyDelete: json['proxy_delete'] == true,
      delNoFree: json['del_no_free'] == true,
      qbCategory: _asNullableString(json['qb_category']),
      siteHrActive: json['site_hr_active'] == true,
      siteSkipTips: json['site_skip_tips'] == true,
      rssSupport: json['rss_support'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'notify': notify,
      'site_id': siteId,
      'downloader': downloader,
      'brush_interval': brushInterval,
      'check_interval': checkInterval,
      'cron': cron,
      'active_time_range': activeTimeRange,
      'disksize': disksize,
      'maxupspeed': maxupspeed,
      'maxdlspeed': maxdlspeed,
      'maxdlcount': maxdlcount,
      'freeleech': freeleech,
      'hr': hr,
      'include': include,
      'exclude': exclude,
      'size': size,
      'seeder': seeder,
      'timezone_offset': timezoneOffset,
      'pubtime': pubtime,
      'seed_time': seedTime,
      'hr_seed_time': hrSeedTime,
      'seed_ratio': seedRatio,
      'seed_size': seedSize,
      'download_time': downloadTime,
      'seed_avgspeed': seedAvgspeed,
      'seed_inactivetime': seedInactivetime,
      'delete_size_range': deleteSizeRange,
      'up_speed': upSpeed,
      'dl_speed': dlSpeed,
      'auto_archive_days': autoArchiveDays,
      'save_path': savePath,
      'delete_except_tags': deleteExceptTags,
      'except_subscribe': exceptSubscribe,
      'proxy_delete': proxyDelete,
      'del_no_free': delNoFree,
      'qb_category': qbCategory,
      'site_hr_active': siteHrActive,
      'site_skip_tips': siteSkipTips,
      'rss_support': rssSupport,
    };
  }

  dynamic valueFor(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'enabled':
        return enabled;
      case 'notify':
        return notify;
      case 'site_id':
        return siteId?.toString();
      case 'downloader':
        return downloader;
      case 'brush_interval':
        return brushInterval;
      case 'check_interval':
        return checkInterval;
      case 'cron':
        return cron;
      case 'active_time_range':
        return activeTimeRange;
      case 'disksize':
        return disksize;
      case 'maxupspeed':
        return maxupspeed;
      case 'maxdlspeed':
        return maxdlspeed;
      case 'maxdlcount':
        return maxdlcount;
      case 'freeleech':
        return freeleech;
      case 'hr':
        return hr;
      case 'include':
        return include;
      case 'exclude':
        return exclude;
      case 'size':
        return size;
      case 'seeder':
        return seeder;
      case 'timezone_offset':
        return timezoneOffset;
      case 'pubtime':
        return pubtime;
      case 'seed_time':
        return seedTime;
      case 'hr_seed_time':
        return hrSeedTime;
      case 'seed_ratio':
        return seedRatio;
      case 'seed_size':
        return seedSize;
      case 'download_time':
        return downloadTime;
      case 'seed_avgspeed':
        return seedAvgspeed;
      case 'seed_inactivetime':
        return seedInactivetime;
      case 'delete_size_range':
        return deleteSizeRange;
      case 'up_speed':
        return upSpeed;
      case 'dl_speed':
        return dlSpeed;
      case 'auto_archive_days':
        return autoArchiveDays;
      case 'save_path':
        return savePath;
      case 'delete_except_tags':
        return deleteExceptTags;
      case 'except_subscribe':
        return exceptSubscribe;
      case 'proxy_delete':
        return proxyDelete;
      case 'del_no_free':
        return delNoFree;
      case 'qb_category':
        return qbCategory;
      case 'site_hr_active':
        return siteHrActive;
      case 'site_skip_tips':
        return siteSkipTips;
      case 'rss_support':
        return rssSupport;
      default:
        return null;
    }
  }
}

class BrushFlowTorrent {
  const BrushFlowTorrent({
    required this.title,
    this.site,
    this.siteName,
    this.size = 0,
    this.pubdate,
    this.description,
    this.imdbid,
    this.pageUrl,
    this.freedate,
    this.volumeFactor,
    this.freedateDiff,
    this.ratio = 0,
    this.downloaded = 0,
    this.uploaded = 0,
    this.seedingTime = 0,
    this.deleted = false,
    this.hitAndRun = false,
    this.taskId,
    this.taskName,
  });

  final String title;
  final int? site;
  final String? siteName;
  final int size;
  final String? pubdate;
  final String? description;
  final String? imdbid;
  final String? pageUrl;
  final String? freedate;
  final String? volumeFactor;
  final String? freedateDiff;
  final double ratio;
  final int downloaded;
  final int uploaded;
  final int seedingTime;
  final bool deleted;
  final bool hitAndRun;
  final String? taskId;
  final String? taskName;

  factory BrushFlowTorrent.fromJson(Map<String, dynamic> json) {
    return BrushFlowTorrent(
      title: json['title']?.toString() ?? '',
      site: _asIntOrNull(json['site']),
      siteName: json['site_name']?.toString(),
      size: _asInt(json['size']),
      pubdate: json['pubdate']?.toString(),
      description: json['description']?.toString(),
      imdbid: json['imdbid']?.toString(),
      pageUrl: json['page_url']?.toString(),
      freedate: json['freedate']?.toString(),
      volumeFactor: json['volume_factor']?.toString(),
      freedateDiff: json['freedate_diff']?.toString(),
      ratio: _asDouble(json['ratio']),
      downloaded: _asInt(json['downloaded']),
      uploaded: _asInt(json['uploaded']),
      seedingTime: _asInt(json['seeding_time']),
      deleted: json['deleted'] == true,
      hitAndRun: json['hit_and_run'] == true,
      taskId: json['task_id']?.toString(),
      taskName: json['task_name']?.toString(),
    );
  }
}

class BrushFlowTorrentPage {
  const BrushFlowTorrentPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 50,
    this.state = 'active',
  });

  final List<BrushFlowTorrent> items;
  final int total;
  final int page;
  final int pageSize;
  final String state;

  bool get hasMore => items.length < total;

  factory BrushFlowTorrentPage.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BrushFlowTorrentPage();
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (e) => BrushFlowTorrent.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <BrushFlowTorrent>[];
    return BrushFlowTorrentPage(
      items: items,
      total: _asInt(json['total']),
      page: _asInt(json['page'], fallback: 1),
      pageSize: _asInt(json['page_size'], fallback: 50),
      state: json['state']?.toString() ?? 'active',
    );
  }
}

class BrushFlowStatusData {
  const BrushFlowStatusData({
    this.enabled = false,
    this.showSidebarNav = false,
    this.summary = const BrushFlowSummary(),
    this.tasks = const [],
    this.sites = const [],
    this.downloaders = const [],
  });

  final bool enabled;
  final bool showSidebarNav;
  final BrushFlowSummary summary;
  final List<BrushFlowTask> tasks;
  final List<BrushFlowOption> sites;
  final List<BrushFlowOption> downloaders;

  BrushFlowStatusData copyWith({
    bool? enabled,
    bool? showSidebarNav,
    BrushFlowSummary? summary,
    List<BrushFlowTask>? tasks,
    List<BrushFlowOption>? sites,
    List<BrushFlowOption>? downloaders,
  }) {
    return BrushFlowStatusData(
      enabled: enabled ?? this.enabled,
      showSidebarNav: showSidebarNav ?? this.showSidebarNav,
      summary: summary ?? this.summary,
      tasks: tasks ?? this.tasks,
      sites: sites ?? this.sites,
      downloaders: downloaders ?? this.downloaders,
    );
  }

  factory BrushFlowStatusData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BrushFlowStatusData();
    final options = json['options'] is Map
        ? Map<String, dynamic>.from(json['options'] as Map)
        : <String, dynamic>{};
    return BrushFlowStatusData(
      enabled: json['enabled'] == true,
      showSidebarNav: json['show_sidebar_nav'] == true,
      summary: BrushFlowSummary.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : null,
      ),
      tasks: json['tasks'] is List
          ? (json['tasks'] as List)
                .whereType<Map>()
                .map((e) => BrushFlowTask.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
      sites: options['sites'] is List
          ? (options['sites'] as List)
                .whereType<Map>()
                .map(
                  (e) => BrushFlowOption.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      downloaders: options['downloaders'] is List
          ? (options['downloaders'] as List)
                .whereType<Map>()
                .map(
                  (e) => BrushFlowOption.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

class BrushFlowTaskDetail {
  const BrushFlowTaskDetail({
    this.task = const BrushFlowTaskConfig(),
    this.summary,
    this.torrents = const BrushFlowTorrentPage(),
  });

  final BrushFlowTaskConfig task;
  final BrushFlowTask? summary;
  final BrushFlowTorrentPage torrents;

  factory BrushFlowTaskDetail.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BrushFlowTaskDetail();
    return BrushFlowTaskDetail(
      task: BrushFlowTaskConfig.fromJson(
        json['task'] is Map
            ? Map<String, dynamic>.from(json['task'] as Map)
            : null,
      ),
      summary: json['summary'] is Map
          ? BrushFlowTask.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            )
          : null,
      torrents: BrushFlowTorrentPage.fromJson(
        json['torrents'] is Map
            ? Map<String, dynamic>.from(json['torrents'] as Map)
            : null,
      ),
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

num? _asNumOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
