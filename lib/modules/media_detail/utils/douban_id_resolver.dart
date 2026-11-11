/// 从 MoviePilot 媒体搜索结果中挑选最匹配的豆瓣 ID。
///
/// 详情接口只有豆瓣来源才会带 douban_id，TMDB 等来源通常为空；
/// 此时用官方 `/api/v1/media/search?media_source=douban` 的结果按
/// 标题 + 年份做严格匹配，避免把翻拍作品的评论挂到错误条目上。
String? pickDoubanIdFromSearchResults({
  required List<dynamic> items,
  required String title,
  String? year,
  String? typeName,
}) {
  final targetTitle = _normalizeTitle(title);
  if (targetTitle.isEmpty) return null;
  final targetYear = _normalizeYear(year);

  String? titleOnlyMatch;
  for (final raw in items.whereType<Map>()) {
    final item = Map<String, dynamic>.from(raw);
    final doubanId = doubanIdFromSearchItem(item);
    if (doubanId == null) continue;
    if (!_typeMatches(item, typeName)) continue;
    if (!_titleMatches(item, targetTitle)) continue;

    final itemYear = _itemYear(item);
    if (targetYear == null) {
      titleOnlyMatch ??= doubanId;
      continue;
    }
    if (itemYear == targetYear) return doubanId;
  }
  return targetYear == null ? titleOnlyMatch : null;
}

/// 读取搜索结果中的豆瓣 ID：优先 douban_id，其次豆瓣来源的 media_id。
String? doubanIdFromSearchItem(Map<String, dynamic> item) {
  final direct = _asString(item['douban_id']);
  if (direct != null && direct != '0') return direct;

  final source = _asString(
    item['media_source'] ?? item['source'],
  )?.toLowerCase();
  if (source == null || !source.contains('douban')) return null;
  final mediaId = _asString(item['media_id'] ?? item['mediaid']);
  if (mediaId == null || mediaId == '0') return null;
  return mediaId;
}

bool _titleMatches(Map<String, dynamic> item, String targetTitle) {
  final candidates = <String?>[
    _asString(item['title']),
    _asString(item['original_title']),
    _asString(item['original_name']),
    _asString(item['en_title']),
  ];
  final names = item['names'];
  if (names is List) {
    candidates.addAll(names.map((name) => _asString(name)));
  }
  return candidates.any((title) => _normalizeTitle(title ?? '') == targetTitle);
}

bool _typeMatches(Map<String, dynamic> item, String? typeName) {
  final expected = _normalizeType(typeName);
  if (expected == null) return true;
  final raw = _asString(item['type'] ?? item['type_name']);
  final actual = _normalizeType(raw);
  return actual == null || actual == expected;
}

String? _normalizeType(String? value) {
  final raw = value?.trim().toLowerCase() ?? '';
  if (raw.isEmpty) return null;
  if (raw.contains('剧') || raw.contains('tv') || raw.contains('series')) {
    return 'tv';
  }
  if (raw.contains('电影') || raw.contains('movie')) return 'movie';
  return null;
}

String? _itemYear(Map<String, dynamic> item) {
  final candidates = <String?>[
    _asString(item['year']),
    _asString(item['title_year']),
    _asString(item['release_date']),
    _asString(item['first_air_date']),
  ];
  for (final candidate in candidates) {
    final normalized = _normalizeYear(candidate);
    if (normalized != null) return normalized;
  }
  return null;
}

String? _normalizeYear(String? value) {
  final match = RegExp(r'(19|20)\d{2}').firstMatch(value?.trim() ?? '');
  return match?.group(0);
}

String _normalizeTitle(String value) {
  return value.trim().toLowerCase().replaceAll(
    RegExp(r'[\s\-_·:：,，.。!！?？"“”‘’()（）\[\]【】/\\|]+'),
    '',
  );
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
