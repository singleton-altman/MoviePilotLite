class SubtitleSearchItem {
  const SubtitleSearchItem({
    required this.raw,
    this.site,
    this.siteName,
    this.title,
    this.language,
    this.languageIcon,
    this.size,
    this.pubdate,
    this.dateElapsed,
    this.grabs,
    this.uploader,
    this.enclosure,
    this.torrentId,
    this.subtitleId,
    this.fileName,
  });

  factory SubtitleSearchItem.fromJson(Map<String, dynamic> json) {
    return SubtitleSearchItem(
      raw: Map<String, dynamic>.from(json),
      site: _asInt(json['site']),
      siteName: json['site_name']?.toString(),
      title: json['title']?.toString(),
      language: json['language']?.toString(),
      languageIcon: json['language_icon']?.toString(),
      size: _asInt(json['size']),
      pubdate: json['pubdate']?.toString(),
      dateElapsed: json['date_elapsed']?.toString(),
      grabs: _asInt(json['grabs']),
      uploader: json['uploader']?.toString(),
      enclosure: json['enclosure']?.toString(),
      torrentId: json['torrent_id']?.toString(),
      subtitleId: json['subtitle_id']?.toString(),
      fileName: json['file_name']?.toString(),
    );
  }

  final Map<String, dynamic> raw;
  final int? site;
  final String? siteName;
  final String? title;
  final String? language;
  final String? languageIcon;
  final int? size;
  final String? pubdate;
  final String? dateElapsed;
  final int? grabs;
  final String? uploader;
  final String? enclosure;
  final String? torrentId;
  final String? subtitleId;
  final String? fileName;

  String get key {
    final parts = <String>[
      if (site != null) 's$site',
      if ((subtitleId ?? '').isNotEmpty) 'sub$subtitleId',
      if ((torrentId ?? '').isNotEmpty) 't$torrentId',
      if ((enclosure ?? '').isNotEmpty) 'e$enclosure',
    ];
    if (parts.isNotEmpty) return parts.join('|');
    return title ?? identityHashCode(this).toString();
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
