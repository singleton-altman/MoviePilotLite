import 'package:flutter/foundation.dart';

class MediaItem {
  final String id;
  final String title;
  final String posterUrl;
  final String? backdropUrl;
  /// 官方标题艺术图（服务器 Logo/ClearLogo,透明底 PNG）。null 时标题回退文字。
  final String? logoUrl;
  final String? overview;
  final double? rating;
  final int? year;
  final String? releaseDate;
  final List<String> genres;
  final MediaType type;
  final int duration;
  final String? imdbId;
  final int? tmdbId;
  final String? quality;
  final bool? isWatched;
  final bool? isFavorite;
  final double? watchProgress;
  final List<MediaSource> sources;
  final String? director;
  final List<String>? cast;
  final List<Map<String, dynamic>>? videoTracks;
  final List<Map<String, dynamic>>? audioTracks;
  final List<Map<String, dynamic>>? subtitleTracks;
  final List<Map<String, dynamic>>? people;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? seriesTitle;
  final String? seriesId;
  final int? totalSeasons;
  final int? totalEpisodes;
  /// 未看(未标记已看完)的集数,用于剧集详情页「已看 A/B 集」统计
  final int? unplayedItemCount;
  final String? filePath;
  /// 是否为合集（BoxSet）：点击后应展示合集内的影视列表，而非合集详情页
  final bool isBoxSet;
  /// 库的 CollectionType（movies/tvshows/boxsets 等），用于决定库内查询参数
  final String? collectionType;

  const MediaItem({
    required this.id,
    required this.title,
    required this.posterUrl,
    this.backdropUrl,
    this.logoUrl,
    this.overview,
    this.rating,
    this.year,
    this.releaseDate,
    this.genres = const [],
    this.type = MediaType.movie,
    this.duration = 0,
    this.imdbId,
    this.tmdbId,
    this.quality,
    this.isWatched,
    this.isFavorite,
    this.watchProgress,
    this.sources = const [],
    this.director,
    this.cast,
    this.videoTracks,
    this.audioTracks,
    this.subtitleTracks,
    this.people,
    this.seasonNumber,
    this.episodeNumber,
    this.seriesTitle,
    this.seriesId,
    this.totalSeasons,
    this.totalEpisodes,
    this.unplayedItemCount,
    this.filePath,
    this.isBoxSet = false,
    this.collectionType,
  });

  MediaItem copyWith({
    String? id,
    String? title,
    String? posterUrl,
    String? backdropUrl,
    String? overview,
    double? rating,
    int? year,
    String? releaseDate,
    List<String>? genres,
    MediaType? type,
    bool? isBoxSet,
    String? collectionType,
    int? duration,
    String? imdbId,
    int? tmdbId,
    String? quality,
    bool? isWatched,
    bool? isFavorite,
    double? watchProgress,
    List<MediaSource>? sources,
    int? seasonNumber,
    int? episodeNumber,
    String? seriesTitle,
    String? seriesId,
    int? totalSeasons,
    int? totalEpisodes,
    int? unplayedItemCount,
    String? filePath,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      overview: overview ?? this.overview,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      releaseDate: releaseDate ?? this.releaseDate,
      genres: genres ?? this.genres,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      imdbId: imdbId ?? this.imdbId,
      tmdbId: tmdbId ?? this.tmdbId,
      quality: quality ?? this.quality,
      isWatched: isWatched ?? this.isWatched,
      isFavorite: isFavorite ?? this.isFavorite,
      watchProgress: watchProgress ?? this.watchProgress,
      sources: sources ?? this.sources,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      seriesId: seriesId ?? this.seriesId,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      unplayedItemCount: unplayedItemCount ?? this.unplayedItemCount,
      filePath: filePath ?? this.filePath,
      isBoxSet: isBoxSet ?? this.isBoxSet,
      collectionType: collectionType ?? this.collectionType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'logoUrl': logoUrl,
      'overview': overview,
      'rating': rating,
      'year': year,
      'releaseDate': releaseDate,
      'genres': genres,
      'type': type.name,
      'duration': duration,
      'imdbId': imdbId,
      'tmdbId': tmdbId,
      'quality': quality,
      'isWatched': isWatched,
      'isFavorite': isFavorite,
      'watchProgress': watchProgress,
      'sources': sources.map((s) => s.toJson()).toList(),
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'seriesTitle': seriesTitle,
      'seriesId': seriesId,
      'totalSeasons': totalSeasons,
      'totalEpisodes': totalEpisodes,
      'filePath': filePath,
      'isBoxSet': isBoxSet,
      'collectionType': collectionType,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String,
      backdropUrl: json['backdropUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      overview: json['overview'] as String?,
      rating: json['rating'] as double?,
      year: json['year'] as int?,
      releaseDate: json['releaseDate'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      type: MediaType.values.firstWhere((t) => t.name == json['type'], orElse: () => MediaType.movie),
      duration: json['duration'] as int? ?? 0,
      imdbId: json['imdbId'] as String?,
      tmdbId: json['tmdbId'] as int?,
      quality: json['quality'] as String?,
      isWatched: json['isWatched'] as bool?,
      isFavorite: json['isFavorite'] as bool?,
      watchProgress: json['watchProgress'] as double?,
      sources: (json['sources'] as List<dynamic>?)?.map((s) => MediaSource.fromJson(s as Map<String, dynamic>)).toList() ?? [],
      seasonNumber: json['seasonNumber'] as int?,
      episodeNumber: json['episodeNumber'] as int?,
      seriesTitle: json['seriesTitle'] as String?,
      isBoxSet: json['isBoxSet'] as bool? ?? false,
      collectionType: json['collectionType'] as String?,
      seriesId: json['seriesId'] as String?,
      totalSeasons: json['totalSeasons'] as int?,
      totalEpisodes: json['totalEpisodes'] as int?,
      filePath: json['filePath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          posterUrl == other.posterUrl &&
          backdropUrl == other.backdropUrl &&
          overview == other.overview &&
          rating == other.rating &&
          year == other.year &&
          releaseDate == other.releaseDate &&
          listEquals(genres, other.genres) &&
          type == other.type &&
          duration == other.duration &&
          imdbId == other.imdbId &&
          tmdbId == other.tmdbId &&
          quality == other.quality &&
          isWatched == other.isWatched &&
          isFavorite == other.isFavorite &&
          watchProgress == other.watchProgress &&
          listEquals(sources, other.sources);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      posterUrl.hashCode ^
      backdropUrl.hashCode ^
      overview.hashCode ^
      rating.hashCode ^
      year.hashCode ^
      releaseDate.hashCode ^
      genres.hashCode ^
      type.hashCode ^
      duration.hashCode ^
      imdbId.hashCode ^
      tmdbId.hashCode ^
      quality.hashCode ^
      isWatched.hashCode ^
      isFavorite.hashCode ^
      watchProgress.hashCode ^
      sources.hashCode;
}

enum MediaType { movie, series, episode }

class MediaSource {
  final String id;
  final String name;
  final String type;
  final String? url;
  final String? quality;
  final int? size;

  const MediaSource({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.quality,
    this.size,
  });

  MediaSource copyWith({
    String? id,
    String? name,
    String? type,
    String? url,
    String? quality,
    int? size,
  }) {
    return MediaSource(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      quality: quality ?? this.quality,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'url': url,
      'quality': quality,
      'size': size,
    };
  }

  factory MediaSource.fromJson(Map<String, dynamic> json) {
    return MediaSource(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      url: json['url'] as String?,
      quality: json['quality'] as String?,
      size: json['size'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaSource &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          url == other.url &&
          quality == other.quality &&
          size == other.size;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      url.hashCode ^
      quality.hashCode ^
      size.hashCode;
}

class MediaServer {
  final String id;
  final String name;
  final String url;
  final ServerType type;
  final String? apiKey;
  final String? username;
  final String? password;
  final bool isConnected;
  final bool isDefault;

  const MediaServer({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.apiKey,
    this.username,
    this.password,
    this.isConnected = true,
    this.isDefault = false,
  });

  MediaServer copyWith({
    String? id,
    String? name,
    String? url,
    ServerType? type,
    String? apiKey,
    String? username,
    String? password,
    bool? isConnected,
    bool? isDefault,
  }) {
    return MediaServer(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      apiKey: apiKey ?? this.apiKey,
      username: username ?? this.username,
      password: password ?? this.password,
      isConnected: isConnected ?? this.isConnected,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type.name,
      'apiKey': apiKey,
      'username': username,
      'password': password,
      'isConnected': isConnected,
      'isDefault': isDefault,
    };
  }

  factory MediaServer.fromJson(Map<String, dynamic> json) {
    return MediaServer(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      type: ServerType.values.firstWhere((t) => t.name == json['type'], orElse: () => ServerType.emby),
      apiKey: json['apiKey'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      isConnected: json['isConnected'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaServer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          url == other.url &&
          type == other.type &&
          apiKey == other.apiKey &&
          username == other.username &&
          password == other.password &&
          isConnected == other.isConnected &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      url.hashCode ^
      type.hashCode ^
      apiKey.hashCode ^
      username.hashCode ^
      password.hashCode ^
      isConnected.hashCode ^
      isDefault.hashCode;
}

enum ServerType { emby, jellyfin, fnos, plex, moviepilot }

class DanmakuConfig {
  final String id;
  final String name;
  final String url;
  final String? apiKey;
  final bool isEnabled;
  final double fontSize;
  final double opacity;
  final double speed;
  final bool showTop;
  final bool showBottom;
  final bool showScroll;

  const DanmakuConfig({
    required this.id,
    required this.name,
    required this.url,
    this.apiKey,
    this.isEnabled = true,
    this.fontSize = 24,
    this.opacity = 1.0,
    this.speed = 12,
    this.showTop = true,
    this.showBottom = true,
    this.showScroll = true,
  });

  DanmakuConfig copyWith({
    String? id,
    String? name,
    String? url,
    String? apiKey,
    bool? isEnabled,
    double? fontSize,
    double? opacity,
    double? speed,
    bool? showTop,
    bool? showBottom,
    bool? showScroll,
  }) {
    return DanmakuConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      apiKey: apiKey ?? this.apiKey,
      isEnabled: isEnabled ?? this.isEnabled,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      speed: speed ?? this.speed,
      showTop: showTop ?? this.showTop,
      showBottom: showBottom ?? this.showBottom,
      showScroll: showScroll ?? this.showScroll,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'apiKey': apiKey,
      'isEnabled': isEnabled,
      'fontSize': fontSize,
      'opacity': opacity,
      'speed': speed,
      'showTop': showTop,
      'showBottom': showBottom,
      'showScroll': showScroll,
    };
  }

  factory DanmakuConfig.fromJson(Map<String, dynamic> json) {
    return DanmakuConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      apiKey: json['apiKey'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true,
      fontSize: json['fontSize'] as double? ?? 24,
      opacity: json['opacity'] as double? ?? 1.0,
      speed: json['speed'] as double? ?? 12,
      showTop: json['showTop'] as bool? ?? true,
      showBottom: json['showBottom'] as bool? ?? true,
      showScroll: json['showScroll'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DanmakuConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          url == other.url &&
          apiKey == other.apiKey &&
          isEnabled == other.isEnabled &&
          fontSize == other.fontSize &&
          opacity == other.opacity &&
          speed == other.speed &&
          showTop == other.showTop &&
          showBottom == other.showBottom &&
          showScroll == other.showScroll;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      url.hashCode ^
      apiKey.hashCode ^
      isEnabled.hashCode ^
      fontSize.hashCode ^
      opacity.hashCode ^
      speed.hashCode ^
      showTop.hashCode ^
      showBottom.hashCode ^
      showScroll.hashCode;
}

class TMDBMovie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? voteAverage;
  final String? releaseDate;
  final List<int> genreIds;
  final bool? adult;
  final String? originalLanguage;
  final String? originalTitle;
  final double? popularity;
  final int? voteCount;
  final bool? video;

  const TMDBMovie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.voteAverage,
    this.releaseDate,
    this.genreIds = const [],
    this.adult,
    this.originalLanguage,
    this.originalTitle,
    this.popularity,
    this.voteCount,
    this.video,
  });

  TMDBMovie copyWith({
    int? id,
    String? title,
    String? posterPath,
    String? backdropPath,
    String? overview,
    double? voteAverage,
    String? releaseDate,
    List<int>? genreIds,
    bool? adult,
    String? originalLanguage,
    String? originalTitle,
    double? popularity,
    int? voteCount,
    bool? video,
  }) {
    return TMDBMovie(
      id: id ?? this.id,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
      genreIds: genreIds ?? this.genreIds,
      adult: adult ?? this.adult,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      originalTitle: originalTitle ?? this.originalTitle,
      popularity: popularity ?? this.popularity,
      voteCount: voteCount ?? this.voteCount,
      video: video ?? this.video,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'overview': overview,
      'voteAverage': voteAverage,
      'releaseDate': releaseDate,
      'genreIds': genreIds,
      'adult': adult,
      'originalLanguage': originalLanguage,
      'originalTitle': originalTitle,
      'popularity': popularity,
      'voteCount': voteCount,
      'video': video,
    };
  }

  factory TMDBMovie.fromJson(Map<String, dynamic> json) {
    return TMDBMovie(
      id: json['id'] as int,
      title: json['title'] as String,
      posterPath: json['poster_path'] as String? ?? json['posterPath'] as String?,
      backdropPath: json['backdrop_path'] as String? ?? json['backdropPath'] as String?,
      overview: json['overview'] as String?,
      voteAverage: json['vote_average'] as double? ?? json['voteAverage'] as double?,
      releaseDate: json['release_date'] as String? ?? json['releaseDate'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)?.cast<int>() ?? [],
      adult: json['adult'] as bool?,
      originalLanguage: json['original_language'] as String?,
      originalTitle: json['original_title'] as String?,
      popularity: json['popularity'] as double?,
      voteCount: json['vote_count'] as int?,
      video: json['video'] as bool?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TMDBMovie &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          posterPath == other.posterPath &&
          backdropPath == other.backdropPath &&
          overview == other.overview &&
          voteAverage == other.voteAverage &&
          releaseDate == other.releaseDate &&
          listEquals(genreIds, other.genreIds) &&
          adult == other.adult &&
          originalLanguage == other.originalLanguage &&
          originalTitle == other.originalTitle &&
          popularity == other.popularity &&
          voteCount == other.voteCount &&
          video == other.video;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      posterPath.hashCode ^
      backdropPath.hashCode ^
      overview.hashCode ^
      voteAverage.hashCode ^
      releaseDate.hashCode ^
      genreIds.hashCode ^
      adult.hashCode ^
      originalLanguage.hashCode ^
      originalTitle.hashCode ^
      popularity.hashCode ^
      voteCount.hashCode ^
      video.hashCode;
}

class Subscription {
  final String id;
  final String title;
  final int tmdbId;
  final MediaType type;
  final SubscriptionStatus status;
  final String? moviePilotId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? posterUrl;
  final String? quality;

  const Subscription({
    required this.id,
    required this.title,
    required this.tmdbId,
    required this.type,
    this.status = SubscriptionStatus.pending,
    this.moviePilotId,
    this.createdAt,
    this.updatedAt,
    this.posterUrl,
    this.quality,
  });

  Subscription copyWith({
    String? id,
    String? title,
    int? tmdbId,
    MediaType? type,
    SubscriptionStatus? status,
    String? moviePilotId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? posterUrl,
    String? quality,
  }) {
    return Subscription(
      id: id ?? this.id,
      title: title ?? this.title,
      tmdbId: tmdbId ?? this.tmdbId,
      type: type ?? this.type,
      status: status ?? this.status,
      moviePilotId: moviePilotId ?? this.moviePilotId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      posterUrl: posterUrl ?? this.posterUrl,
      quality: quality ?? this.quality,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'tmdbId': tmdbId,
      'type': type.name,
      'status': status.name,
      'moviePilotId': moviePilotId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'posterUrl': posterUrl,
      'quality': quality,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final mpId = json['id'];
    final tmdbId = json['tmdbid'] ?? json['tmdbId'];
    final typeValue = (json['type'] ?? 'movie').toString().trim();
    // MoviePilot 用 state 字段（'R' 订阅中 / 'D' 已完成），兼容旧 status 字段
    final statusValue = (json['state'] ?? json['status'] ?? 'pending').toString().trim();

    String? posterUrl;
    final poster = json['poster'] as String? ?? json['posterPath'] as String?;
    if (poster != null && poster.isNotEmpty) {
      if (poster.startsWith('http')) {
        posterUrl = poster;
      } else {
        posterUrl = 'https://image.tmdb.org/t/p/w342$poster';
      }
    }

    final parsedTmdbId = tmdbId is int ? tmdbId : int.tryParse(tmdbId.toString()) ?? 0;

    // type 兼容：英文名（movie/series/tv）+ 中文名（电影/电视剧/剧集）
    final t = typeValue.toLowerCase();
    MediaType type;
    if (t == 'movie' || typeValue == '电影') {
      type = MediaType.movie;
    } else if (t == 'series' || t == 'tv' || typeValue == '电视剧' || typeValue == '剧集') {
      type = MediaType.series;
    } else {
      type = MediaType.movie;
    }

    // status 兼容：MoviePilot state 码（R=订阅中 D=已完成）+ 英文状态名
    SubscriptionStatus status;
    switch (statusValue.toUpperCase()) {
      case 'R':
      case 'PENDING':
      case '订阅中':
        status = SubscriptionStatus.pending;
      case 'D':
      case 'COMPLETED':
      case 'DONE':
      case '已完成':
      case '完成':
        status = SubscriptionStatus.completed;
      case 'DOWNLOADING':
        status = SubscriptionStatus.downloading;
      case 'F':
      case 'FAILED':
        status = SubscriptionStatus.failed;
      default:
        status = SubscriptionStatus.values.firstWhere(
          (s) => s.name == statusValue.toLowerCase(),
          orElse: () => SubscriptionStatus.pending,
        );
    }

    // 日期字段兼容：MoviePilot 返回蛇形 created_at/updated_at
    final createdRaw = json['created_at'] ?? json['createdAt'];
    final updatedRaw = json['updated_at'] ?? json['updatedAt'];

    return Subscription(
      id: '$parsedTmdbId-${type.name}',
      title: json['title'] as String? ?? json['name'] as String? ?? '未知标题',
      tmdbId: parsedTmdbId,
      type: type,
      status: status,
      moviePilotId: mpId is String ? mpId : (mpId is int ? mpId.toString() : null),
      createdAt: createdRaw != null ? DateTime.tryParse(createdRaw.toString()) : null,
      updatedAt: updatedRaw != null ? DateTime.tryParse(updatedRaw.toString()) : null,
      posterUrl: posterUrl,
      quality: json['quality'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          tmdbId == other.tmdbId &&
          type == other.type &&
          status == other.status &&
          moviePilotId == other.moviePilotId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          posterUrl == other.posterUrl &&
          quality == other.quality;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      tmdbId.hashCode ^
      type.hashCode ^
      status.hashCode ^
      moviePilotId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      posterUrl.hashCode ^
      quality.hashCode;
}

enum SubscriptionStatus { pending, downloading, completed, failed }


