// 音乐模块模型（v3 独有，/api/v1/music/*）。
// 字段与服务端 MusicInfo / MusicArtistInfo / MusicAlbumInfo 对齐，
// 仅保留浏览所需子集，解析全部容错。

class MusicSourceDefine {
  const MusicSourceDefine(this.id, this.label);

  final String id;
  final String label;
}

const List<MusicSourceDefine> kMusicSources = [
  MusicSourceDefine('musicbrainz', 'MusicBrainz'),
  MusicSourceDefine('theaudiodb', 'TheAudioDB'),
  MusicSourceDefine('doubanmusic', '豆瓣音乐'),
];

// /music/explore 仅接受 MusicBrainz 和豆瓣音乐，TheAudioDB 仅用于详情/搜索。
const kMusicExploreSources = [
  MusicSourceDefine('musicbrainz', 'MusicBrainz'),
  MusicSourceDefine('doubanmusic', '豆瓣音乐'),
];

String? _text(dynamic value) {
  if (value is! String && value is! num) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _integer(dynamic value) => value is num
    ? (value.isFinite ? value.toInt() : null)
    : int.tryParse(_text(value) ?? '');

double? _decimal(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(_text(value) ?? '');
  return number?.isFinite == true ? number : null;
}

List<String> _strings(dynamic value) =>
    value is List ? value.map(_text).whereType<String>().toList() : const [];

String musicSource(dynamic value, {String fallback = 'musicbrainz'}) =>
    (_text(value) ?? fallback).trim().toLowerCase();

/// 探索条目（GET /api/v1/music/explore），music_type 为 album / artist / recording。
class MusicExploreItem {
  const MusicExploreItem({
    required this.musicType,
    required this.mediaSource,
    required this.mediaId,
    this.title,
    this.artist,
    this.artists = const [],
    this.year,
    this.coverUrl,
    this.genres = const [],
    this.album,
    this.albumId,
  });

  final String musicType;
  final String mediaSource;
  final String mediaId;
  final String? title;
  final String? artist;
  final List<String> artists;
  final int? year;
  final String? coverUrl;
  final List<String> genres;
  final String? album;
  final String? albumId;

  bool get isArtist => musicType == 'artist';
  bool get isAlbum => musicType == 'album';
  bool get isRecording => !isArtist && !isAlbum;

  String get displayTitle =>
      title?.trim().isNotEmpty == true ? title!.trim() : '未知名称';

  String get displayArtist {
    final a = artist?.trim();
    if (a != null && a.isNotEmpty) return a;
    if (artists.isNotEmpty) return artists.take(2).join(' / ');
    return '';
  }

  factory MusicExploreItem.fromJson(
    Map<String, dynamic> json, {
    String fallbackSource = 'musicbrainz',
  }) {
    return MusicExploreItem(
      musicType: (_text(json['music_type']) ?? 'recording').toLowerCase(),
      mediaSource: musicSource(json['media_source'], fallback: fallbackSource),
      mediaId: _text(json['media_id']) ?? '',
      title: _text(json['title']),
      artist: _text(json['artist']),
      artists: _strings(json['artists']),
      year: _integer(json['year']),
      coverUrl: _text(json['cover_url']) ?? _text(json['poster_path']),
      genres: _strings(json['genres']),
      album: _text(json['album']),
      albumId: _text(json['album_id']),
    );
  }
}

/// 艺术家详情（GET /api/v1/music/artist/{id}）。
class MusicArtistDetail {
  const MusicArtistDetail({
    required this.mediaSource,
    required this.mediaId,
    this.name,
    this.disambiguation,
    this.artistType,
    this.country,
    this.area,
    this.lifeSpan,
    this.imageUrl,
    this.albumCount,
    this.genres = const [],
    this.aliases = const [],
  });

  final String mediaSource;
  final String mediaId;
  final String? name;
  final String? disambiguation;
  final String? artistType;
  final String? country;
  final String? area;
  final String? lifeSpan;
  final String? imageUrl;
  final int? albumCount;
  final List<String> genres;
  final List<String> aliases;

  String get displayName =>
      name?.trim().isNotEmpty == true ? name!.trim() : '未知艺术家';

  factory MusicArtistDetail.fromJson(Map<String, dynamic> json) {
    return MusicArtistDetail(
      mediaSource: musicSource(json['media_source'], fallback: ''),
      mediaId: _text(json['media_id']) ?? '',
      name: _text(json['name']) ?? _text(json['title']),
      disambiguation: _text(json['disambiguation']),
      artistType: _text(json['artist_type']),
      country: _text(json['country']),
      area: _text(json['area']),
      lifeSpan: _text(json['life_span']) ?? _text(json['begin_date']),
      imageUrl: _text(json['image_url']) ?? _text(json['poster_path']),
      albumCount: _integer(json['album_count']),
      genres: _strings(json['genres']),
      aliases: _strings(json['aliases']),
    );
  }
}

/// 专辑内单曲（MusicAlbumInfo.tracks 元素）。
class MusicTrack {
  const MusicTrack({
    this.mediaId,
    this.trackNumber,
    this.discNumber,
    this.title,
    this.artists = const [],
    this.duration,
  });

  final String? mediaId;
  final int? trackNumber;
  final int? discNumber;
  final String? title;
  final List<String> artists;
  final int? duration;

  String get displayTitle =>
      title?.trim().isNotEmpty == true ? title!.trim() : '未知曲目';

  String get displayDuration {
    final seconds = duration ?? 0;
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      mediaId: _text(json['media_id']),
      trackNumber: _integer(json['track_number']),
      discNumber: _integer(json['disc_number']),
      title: _text(json['title']),
      artists: _strings(json['artists']),
      duration: _integer(json['duration']),
    );
  }
}

/// 专辑详情（GET /api/v1/music/album/{id}）。
class MusicAlbumDetail {
  const MusicAlbumDetail({
    required this.mediaSource,
    required this.mediaId,
    this.title,
    this.artist,
    this.artists = const [],
    this.artistIds = const [],
    this.year,
    this.releaseDate,
    this.totalTracks,
    this.duration,
    this.albumType,
    this.coverUrl,
    this.genres = const [],
    this.rating,
    this.overview,
    this.detailLink,
    this.tracks = const [],
  });

  final String mediaSource;
  final String mediaId;
  final String? title;
  final String? artist;
  final List<String> artists;
  final List<String> artistIds;
  final int? year;
  final String? releaseDate;
  final int? totalTracks;
  final int? duration;
  final String? albumType;
  final String? coverUrl;
  final List<String> genres;
  final double? rating;
  final String? overview;
  final String? detailLink;
  final List<MusicTrack> tracks;

  String get displayTitle =>
      title?.trim().isNotEmpty == true ? title!.trim() : '未知专辑';

  String get displayArtist {
    final a = artist?.trim();
    if (a != null && a.isNotEmpty) return a;
    if (artists.isNotEmpty) return artists.take(2).join(' / ');
    return '';
  }

  factory MusicAlbumDetail.fromJson(Map<String, dynamic> json) {
    return MusicAlbumDetail(
      mediaSource: musicSource(json['media_source'], fallback: ''),
      mediaId: _text(json['media_id']) ?? '',
      title: _text(json['title']),
      artist: _text(json['artist']),
      artists: _strings(json['artists']),
      artistIds: _strings(json['artist_ids']),
      year: _integer(json['year']),
      releaseDate: _text(json['release_date']),
      totalTracks: _integer(json['total_tracks']),
      duration: _integer(json['duration']),
      albumType: _text(json['album_type']),
      coverUrl: _text(json['cover_url']) ?? _text(json['poster_path']),
      genres: _strings(json['genres']),
      rating: _decimal(json['rating']) ?? _decimal(json['vote_average']),
      overview: _text(json['overview']),
      detailLink: _text(json['detail_link']),
      tracks:
          (json['tracks'] is List ? json['tracks'] as List : null)
              ?.whereType<Map>()
              .map((e) => MusicTrack.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

/// 单曲详情（POST /api/v1/music/recognize，music_type: recording）。
///
/// v3 用同一实体返回单曲、专辑与艺术家；这里只保留单曲浏览需要的字段，
/// 一旦 `musicType == 'album'` 调用方应改走专辑详情。
class MusicRecordingDetail {
  const MusicRecordingDetail({
    required this.mediaSource,
    required this.mediaId,
    this.musicType = 'recording',
    this.title,
    this.artist,
    this.artists = const [],
    this.artistIds = const [],
    this.album,
    this.albumId,
    this.albumArtist,
    this.albumType,
    this.year,
    this.releaseDate,
    this.trackNumber,
    this.discNumber,
    this.totalTracks,
    this.duration,
    this.isrc,
    this.coverUrl,
    this.genres = const [],
    this.listenCount,
    this.detailLink,
  });

  final String mediaSource;
  final String mediaId;
  final String musicType;
  final String? title;
  final String? artist;
  final List<String> artists;
  final List<String> artistIds;
  final String? album;
  final String? albumId;
  final String? albumArtist;
  final String? albumType;
  final int? year;
  final String? releaseDate;
  final int? trackNumber;
  final int? discNumber;
  final int? totalTracks;
  final int? duration;
  final String? isrc;
  final String? coverUrl;
  final List<String> genres;
  final int? listenCount;
  final String? detailLink;

  bool get isAlbum => musicType == 'album';
  bool get isArtist => musicType == 'artist';

  String get displayTitle =>
      title?.trim().isNotEmpty == true ? title!.trim() : '未知曲目';

  String get displayArtist {
    final a = artist?.trim();
    if (a != null && a.isNotEmpty) return a;
    if (artists.isNotEmpty) return artists.take(2).join(' / ');
    return '';
  }

  String get displayDuration {
    final seconds = duration ?? 0;
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// 曲目序号文本，多碟专辑按 v3 展示为「碟-轨」。
  String get displayTrackNumber {
    final track = trackNumber;
    if (track == null || track <= 0) return '';
    final disc = discNumber;
    return disc != null && disc > 1 ? '$disc-$track' : track.toString();
  }

  factory MusicRecordingDetail.fromJson(
    Map<String, dynamic> json, {
    String fallbackSource = 'musicbrainz',
  }) {
    return MusicRecordingDetail(
      mediaSource: musicSource(json['media_source'], fallback: fallbackSource),
      mediaId: _text(json['media_id']) ?? '',
      musicType: (_text(json['music_type']) ?? 'recording').toLowerCase(),
      title: _text(json['title']),
      artist: _text(json['artist']),
      artists: _strings(json['artists']),
      artistIds: _strings(json['artist_ids']),
      album: _text(json['album']),
      albumId: _text(json['album_id']),
      albumArtist: _text(json['album_artist']),
      albumType: _text(json['album_type']),
      year: _integer(json['year']),
      releaseDate: _text(json['release_date']),
      trackNumber: _integer(json['track_number']),
      discNumber: _integer(json['disc_number']),
      totalTracks: _integer(json['total_tracks']),
      duration: _integer(json['duration']),
      isrc: _text(json['isrc']),
      coverUrl: _text(json['cover_url']) ?? _text(json['poster_path']),
      genres: _strings(json['genres']),
      listenCount: _integer(json['listen_count']),
      detailLink: _text(json['detail_link']),
    );
  }
}
