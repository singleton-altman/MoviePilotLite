import '../models/media_models.dart';
import '../database/database_service.dart';

class FavoriteService {
  // 不再依赖 SharedPreferences，全部委托给 DbService (SQLite)

  static List<FavoriteMovie> _cachedFavorites = [];
  static List<FavoriteMovie> _cachedWatchlist = [];
  static List<PlaylistItem> _cachedPlaylist = [];

  /// 启动时预加载
  static Future<void> preload() async {
    _cachedFavorites = await DbService.getFavorites();
    _cachedWatchlist = await DbService.getWatchlist();
    _cachedPlaylist = await DbService.getPlaylist();
  }

  List<FavoriteMovie> getFavorites() => _cachedFavorites;

  Future<void> addFavorite(TMDBMovie movie) async {
    final fav = FavoriteMovie.fromTMDBMovie(movie, DateTime.now());
    await DbService.addFavoriteMovie(fav);
    _cachedFavorites = await DbService.getFavorites();
  }

  Future<void> removeFavorite(int tmdbId) async {
    await DbService.removeFavoriteMovie(tmdbId);
    _cachedFavorites.removeWhere((f) => f.tmdbId == tmdbId);
  }

  bool isFavorite(int tmdbId) => _cachedFavorites.any((f) => f.tmdbId == tmdbId);

  // ─── Watchlist ───

  List<FavoriteMovie> getWatchlist() => _cachedWatchlist;

  Future<void> addToWatchlist(TMDBMovie movie) async {
    final fav = FavoriteMovie.fromTMDBMovie(movie, DateTime.now());
    await DbService.addToWatchlist(fav);
    _cachedWatchlist = await DbService.getWatchlist();
  }

  Future<void> removeFromWatchlist(int tmdbId) async {
    await DbService.removeFromWatchlist(tmdbId);
    _cachedWatchlist.removeWhere((f) => f.tmdbId == tmdbId);
  }

  bool isInWatchlist(int tmdbId) => _cachedWatchlist.any((f) => f.tmdbId == tmdbId);

  // ─── Playlist ───

  List<PlaylistItem> getPlaylist() => _cachedPlaylist;

  Future<void> addToPlaylist(MediaItem item) async {
    final p = PlaylistItem.fromMediaItem(item, DateTime.now());
    await DbService.addToPlaylist(p);
    _cachedPlaylist = await DbService.getPlaylist();
  }

  Future<void> removeFromPlaylist(String itemId) async {
    await DbService.removeFromPlaylist(itemId);
    _cachedPlaylist.removeWhere((p) => p.itemId == itemId);
  }

  bool isInPlaylist(String itemId) => _cachedPlaylist.any((p) => p.itemId == itemId);
}

class PlaylistItem {
  final String itemId;
  final String title;
  final String posterUrl;
  final String? backdropUrl;
  final String? overview;
  final double? rating;
  final int? year;
  final MediaType type;
  final DateTime addedAt;
  final String? seriesTitle;
  final int? seasonNumber;
  final int? episodeNumber;

  PlaylistItem({
    required this.itemId,
    required this.title,
    required this.posterUrl,
    this.backdropUrl,
    this.overview,
    this.rating,
    this.year,
    required this.type,
    required this.addedAt,
    this.seriesTitle,
    this.seasonNumber,
    this.episodeNumber,
  });

  factory PlaylistItem.fromMediaItem(MediaItem item, DateTime addedAt) {
    return PlaylistItem(
      itemId: item.id,
      title: item.title,
      posterUrl: item.posterUrl,
      backdropUrl: item.backdropUrl,
      overview: item.overview,
      rating: item.rating,
      year: item.year,
      type: item.type,
      addedAt: addedAt,
      seriesTitle: item.seriesTitle,
      seasonNumber: item.seasonNumber,
      episodeNumber: item.episodeNumber,
    );
  }

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      itemId: json['itemId'] as String,
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String,
      backdropUrl: json['backdropUrl'] as String?,
      overview: json['overview'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      year: json['year'] as int?,
      type: MediaType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MediaType.movie,
      ),
      addedAt: DateTime.parse(json['addedAt'] as String),
      seriesTitle: json['seriesTitle'] as String?,
      seasonNumber: json['seasonNumber'] as int?,
      episodeNumber: json['episodeNumber'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'title': title,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'overview': overview,
      'rating': rating,
      'year': year,
      'type': type.name,
      'addedAt': addedAt.toIso8601String(),
      'seriesTitle': seriesTitle,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
    };
  }
}

class FavoriteMovie {
  final int tmdbId;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? voteAverage;
  final String? releaseDate;
  final DateTime addedAt;
  final String type;

  FavoriteMovie({
    required this.tmdbId,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.voteAverage,
    this.releaseDate,
    required this.addedAt,
    this.type = 'movie',
  });

  factory FavoriteMovie.fromTMDBMovie(TMDBMovie movie, DateTime addedAt) {
    return FavoriteMovie(
      tmdbId: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      overview: movie.overview,
      voteAverage: movie.voteAverage,
      releaseDate: movie.releaseDate,
      addedAt: addedAt,
      type: 'movie',
    );
  }

  factory FavoriteMovie.fromJson(Map<String, dynamic> json) {
    return FavoriteMovie(
      tmdbId: json['tmdbId'] as int,
      title: json['title'] as String,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      releaseDate: json['releaseDate'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
      type: json['type'] as String? ?? 'movie',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': tmdbId,
      'title': title,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'overview': overview,
      'voteAverage': voteAverage,
      'releaseDate': releaseDate,
      'addedAt': addedAt.toIso8601String(),
      'type': type,
    };
  }

  TMDBMovie toTMDBMovie() {
    return TMDBMovie(
      id: tmdbId,
      title: title,
      posterPath: posterPath,
      backdropPath: backdropPath,
      overview: overview,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
    );
  }
}
