String? normalizeMediaSource(String? raw) {
  final normalized = raw?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return null;
  switch (normalized) {
    case 'tmdb':
    case 'themoviedb':
      return 'themoviedb';
    case 'douban':
      return 'douban';
    case 'bangumi':
      return 'bangumi';
    case 'anilist':
      return 'anilist';
    case 'imdb':
      return 'imdb';
    case 'tvdb':
      return 'tvdb';
    default:
      return normalized;
  }
}

String? legacyPrefixOf(String? source) {
  final normalized = normalizeMediaSource(source);
  if (normalized == null) return null;
  return normalized == 'themoviedb' ? 'tmdb' : normalized;
}

class MediaIdentity {
  const MediaIdentity({required this.source, required this.id});

  final String source;
  final String id;

  static MediaIdentity? parse(String? key) {
    final trimmed = key?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final separator = trimmed.indexOf(':');
    if (separator <= 0) return null;
    final source = normalizeMediaSource(trimmed.substring(0, separator));
    final id = trimmed.substring(separator + 1).trim();
    if (source == null || id.isEmpty || id == '0') return null;
    return MediaIdentity(source: source, id: id);
  }

  String get legacyKey => '${legacyPrefixOf(source)}:$id';
}

Map<String, dynamic> normalizeMediaJson(Map<String, dynamic> json) {
  final result = Map<String, dynamic>.from(json);
  final source = _nonEmptyText(result['source']);
  final mediaSource = _nonEmptyText(result['media_source']);

  if (source == null && mediaSource != null) {
    result['source'] = mediaSource;
  } else if (source != null && mediaSource == null) {
    result['media_source'] = source;
  }

  final normalizedSource = normalizeMediaSource(
    _nonEmptyText(result['source']) ?? _nonEmptyText(result['media_source']),
  );
  if (!_hasValue(result['media_id'])) {
    final fallbackKey = switch (normalizedSource) {
      'themoviedb' => 'tmdb_id',
      'douban' => 'douban_id',
      'bangumi' => 'bangumi_id',
      'tvdb' => 'tvdb_id',
      'imdb' => 'imdb_id',
      _ => null,
    };
    if (fallbackKey != null && _hasIdentityValue(result[fallbackKey])) {
      result['media_id'] = result[fallbackKey].toString().trim();
    }
  }

  if (!_hasValue(result['mediaid_prefix'])) {
    final sourcePrefix = legacyPrefixOf(normalizedSource);
    if (sourcePrefix != null) {
      result['mediaid_prefix'] = sourcePrefix;
    } else if (_hasIdentityValue(result['tmdb_id'])) {
      result['mediaid_prefix'] = 'tmdb';
    } else if (_hasIdentityValue(result['douban_id'])) {
      result['mediaid_prefix'] = 'douban';
    } else if (_hasIdentityValue(result['bangumi_id'])) {
      result['mediaid_prefix'] = 'bangumi';
    }
  }

  return result;
}

Map<String, dynamic> normalizeSubscribeJson(Map<String, dynamic> json) {
  final result = Map<String, dynamic>.from(json);
  final source = normalizeMediaSource(_nonEmptyText(result['media_source']));
  final mediaId = result['media_id'];
  if (source == null || !_hasValue(mediaId)) return result;

  final legacyIdKey = switch (source) {
    'themoviedb' => 'tmdbid',
    'douban' => 'doubanid',
    'bangumi' => 'bangumiid',
    _ => null,
  };
  if (legacyIdKey != null && !_hasValue(result[legacyIdKey])) {
    result[legacyIdKey] = mediaId;
  }
  if (!_hasValue(result['mediaid'])) {
    final prefix = legacyPrefixOf(source);
    if (prefix != null) {
      result['mediaid'] = '$prefix:${mediaId.toString().trim()}';
    }
  }
  return result;
}

Map<String, dynamic> sanitizeMediaIdentityPayload(
  Map<String, dynamic> json,
) {
  final result = Map<String, dynamic>.from(json);
  final source = normalizeMediaSource(
    _nonEmptyText(result['media_source']) ?? _nonEmptyText(result['source']),
  );
  final mediaId = result['media_id'];
  if (source == null || !_hasValue(mediaId)) {
    result.remove('media_source');
    result.remove('media_id');
    return result;
  }

  result['media_source'] = source;
  if (mediaId is String) {
    result['media_id'] = mediaId.trim();
  }
  return result;
}

String? _nonEmptyText(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool _hasValue(Object? value) => _nonEmptyText(value) != null;

bool _hasIdentityValue(Object? value) {
  final text = _nonEmptyText(value);
  return text != null && text != '0';
}
