import 'dart:convert';

/// 服务端下载历史条目（GET /api/v1/history/download）。
/// 字段与服务端 DownloadHistory schema 对齐（snake_case 原样保留，
/// DELETE 时需将整个对象作为请求体回传）。
class DownloadHistoryItem {
  const DownloadHistoryItem({
    this.id,
    this.path,
    this.type,
    this.title,
    this.year,
    this.tmdbid,
    this.imdbid,
    this.tvdbid,
    this.doubanid,
    this.bangumiid,
    this.anilistid,
    this.mediaSource,
    this.mediaId,
    this.seasons,
    this.episodes,
    this.image,
    this.downloadHash,
    this.torrentName,
    this.torrentDescription,
    this.torrentSite,
    this.userid,
    this.username,
    this.channel,
    this.date,
    this.note,
    this.mediaCategory,
    this.episodeGroup,
    Map<String, dynamic> raw = const {},
  }) : _raw = raw;

  final Map<String, dynamic> _raw;

  final int? id;
  final String? path;
  final String? type;
  final String? title;
  final String? year;
  final int? tmdbid;
  final String? imdbid;
  final int? tvdbid;
  final String? doubanid;
  final int? bangumiid;
  final int? anilistid;
  final String? mediaSource;
  final String? mediaId;
  final String? seasons;
  final String? episodes;
  final String? image;
  final String? downloadHash;
  final String? torrentName;
  final String? torrentDescription;
  final String? torrentSite;
  final String? userid;
  final String? username;
  final String? channel;
  final String? date;
  final Object? note;
  final String? mediaCategory;
  final String? episodeGroup;

  factory DownloadHistoryItem.fromJson(Map<String, dynamic> json) {
    return DownloadHistoryItem(
      id: _integer(json['id']),
      path: json['path']?.toString(),
      type: json['type']?.toString(),
      title: json['title']?.toString(),
      year: json['year']?.toString(),
      tmdbid: _integer(json['tmdbid']),
      imdbid: json['imdbid']?.toString(),
      tvdbid: _integer(json['tvdbid']),
      doubanid: json['doubanid']?.toString(),
      bangumiid: _integer(json['bangumiid']),
      anilistid: _integer(json['anilistid']),
      mediaSource: json['media_source']?.toString(),
      mediaId: json['media_id']?.toString(),
      seasons: _sequence(json['seasons']),
      episodes: _sequence(json['episodes']),
      image: json['image']?.toString(),
      downloadHash: json['download_hash']?.toString(),
      torrentName: json['torrent_name']?.toString(),
      torrentDescription: json['torrent_description']?.toString(),
      torrentSite: json['torrent_site']?.toString(),
      userid: json['userid']?.toString(),
      username: json['username']?.toString(),
      channel: json['channel']?.toString(),
      date: json['date']?.toString(),
      note: json['note'],
      mediaCategory: json['media_category']?.toString(),
      episodeGroup: json['episode_group']?.toString(),
      raw: Map<String, dynamic>.from(jsonDecode(jsonEncode(json)) as Map),
    );
  }

  static int? _integer(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static String? _sequence(dynamic value) =>
      value is List ? value.join('/') : value?.toString();

  Map<String, dynamic> toJson() {
    if (_raw.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(jsonEncode(_raw)) as Map);
    }
    return <String, dynamic>{
      'id': id,
      'path': path,
      'type': type,
      'title': title,
      'year': year,
      'tmdbid': tmdbid,
      'imdbid': imdbid,
      'tvdbid': tvdbid,
      'doubanid': doubanid,
      'bangumiid': bangumiid,
      'anilistid': anilistid,
      'media_source': mediaSource,
      'media_id': mediaId,
      'seasons': seasons,
      'episodes': episodes,
      'image': image,
      'download_hash': downloadHash,
      'torrent_name': torrentName,
      'torrent_description': torrentDescription,
      'torrent_site': torrentSite,
      'userid': userid,
      'username': username,
      'channel': channel,
      'date': date,
      'note': note,
      'media_category': mediaCategory,
      'episode_group': episodeGroup,
    };
  }

  /// 展示标题：优先媒体标题，回退种子名。
  String get displayTitle {
    final t = title?.trim() ?? '';
    if (t.isNotEmpty) return t;
    return torrentName?.trim() ?? '未知标题';
  }

  /// 年份/类型/季集的元信息行。
  String buildMetaLine() {
    final parts = <String>[];
    if (year != null && year!.trim().isNotEmpty) parts.add(year!.trim());
    if (type != null && type!.trim().isNotEmpty) parts.add(type!.trim());
    if (seasons?.isNotEmpty == true) parts.add(seasons!);
    if (episodes?.isNotEmpty == true) parts.add(episodes!);
    return parts.join(' · ');
  }

  /// 服务端时间为 ISO 字符串，截取到分钟展示；解析失败原样返回。
  String get displayDate {
    final d = date?.trim() ?? '';
    if (d.isEmpty) return '';
    final parsed = DateTime.tryParse(d);
    if (parsed == null) return d;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)} '
        '${two(parsed.hour)}:${two(parsed.minute)}';
  }
}
