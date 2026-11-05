import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_models.dart';
import '../services/storage_service.dart';
import '../services/favorite_service.dart';
import '../utils/app_log.dart';
import 'app_database.dart';

/// 全局 AppDatabase 单例
AppDatabase? _db;

/// drift SQLite 数据库服务
class DbService {
  static AppDatabase get db {
    assert(_db != null, 'DbService.init() 尚未调用');
    return _db!;
  }

  static Future<void> init() async {
    // DbService 内部 _migrateFromSharedPreferences 会同步读 StorageService，
    // 必须等待 StorageService.init() 完成后再启动，避免 LateInitializationError
    await StorageService.ready;
    _db = AppDatabase();
    await _migrateFromSharedPreferences();
  }

  // ─── Media Servers ───

  static Future<List<MediaServer>> getServers() async {
    final rows = await db.mediaServersTable.select().get();
    return rows.map(_serverFromRow).toList();
  }

  static Future<void> saveServers(List<MediaServer> servers) async {
    await db.transaction(() async {
      await db.delete(db.mediaServersTable).go();
      for (final s in servers) {
        await db.into(db.mediaServersTable).insert(
          MediaServersTableCompanion.insert(
            id: s.id,
            name: s.name,
            url: s.url,
            serverType: s.type.name,
            apiKey: Value(s.apiKey),
            username: Value(s.username),
            password: Value(s.password),
            isConnected: Value(s.isConnected),
            isDefault: Value(s.isDefault),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  static Future<void> setDefaultServer(String serverId) async {
    await (db.update(db.mediaServersTable)
          ..where((t) => t.isDefault.equals(true)))
        .write(const MediaServersTableCompanion(isDefault: Value(false)));
    await (db.update(db.mediaServersTable)
          ..where((t) => t.id.equals(serverId)))
        .write(const MediaServersTableCompanion(isDefault: Value(true)));
  }

  static MediaServer _serverFromRow(MediaServerRow row) {
    return MediaServer(
      id: row.id,
      name: row.name,
      url: row.url,
      type: ServerType.values.firstWhere(
        (t) => t.name == row.serverType,
        orElse: () => ServerType.emby,
      ),
      apiKey: row.apiKey,
      username: row.username,
      password: row.password,
      isConnected: row.isConnected,
      isDefault: row.isDefault,
    );
  }

  // ─── Danmaku Configs ───

  static Future<List<DanmakuConfig>> getDanmakuConfigs() async {
    final rows = await db.danmakuConfigsTable.select().get();
    return rows.map(_configFromRow).toList();
  }

  static Future<void> saveDanmakuConfigs(List<DanmakuConfig> configs) async {
    await db.transaction(() async {
      await db.delete(db.danmakuConfigsTable).go();
      for (final c in configs) {
        await db.into(db.danmakuConfigsTable).insert(
          DanmakuConfigsTableCompanion.insert(
            id: c.id,
            name: c.name,
            url: c.url,
            apiKey: Value(c.apiKey),
            isEnabled: Value(c.isEnabled),
            fontSize: Value(c.fontSize),
            opacity: Value(c.opacity),
            speed: Value(c.speed),
            showTop: Value(c.showTop),
            showBottom: Value(c.showBottom),
            showScroll: Value(c.showScroll),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  static DanmakuConfig _configFromRow(DanmakuConfigRow row) {
    return DanmakuConfig(
      id: row.id,
      name: row.name,
      url: row.url,
      apiKey: row.apiKey,
      isEnabled: row.isEnabled,
      fontSize: row.fontSize,
      opacity: row.opacity,
      speed: row.speed,
      showTop: row.showTop,
      showBottom: row.showBottom,
      showScroll: row.showScroll,
    );
  }

  // ─── Watch History ───

  static Future<List<Map<String, dynamic>>> getWatchHistory() async {
    final rows = await (db.select(db.watchHistoryTable)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map((r) => <String, dynamic>{
      'id': r.id,
      'title': r.title,
      'posterUrl': r.posterUrl,
      'backdropUrl': r.backdropUrl,
      'serverId': r.serverId,
      'progress': r.progress,
      'positionMs': r.positionMs,
      'durationMs': r.durationMs,
      'seasonNumber': r.seasonNumber,
      'episodeNumber': r.episodeNumber,
      'seriesTitle': r.seriesTitle,
      'updatedAt': r.updatedAt,
    }).toList();
  }

  static Future<void> addToHistory(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    await (db.delete(db.watchHistoryTable)
          ..where((t) => t.id.equals(id)))
        .go();
    await db.into(db.watchHistoryTable).insert(
      WatchHistoryTableCompanion.insert(
        id: id,
        title: item['title']?.toString() ?? '',
        posterUrl: Value(item['posterUrl']?.toString() ?? ''),
        backdropUrl: Value(item['backdropUrl']?.toString()),
        serverId: Value(item['serverId']?.toString()),
        progress: Value((item['progress'] is num) ? (item['progress'] as num).toDouble() : 0.0),
        positionMs: Value((item['positionMs'] is int) ? item['positionMs'] as int : 0),
        durationMs: Value((item['durationMs'] is int) ? item['durationMs'] as int : 0),
        seasonNumber: Value(item['seasonNumber'] is int ? item['seasonNumber'] as int : null),
        episodeNumber: Value(item['episodeNumber'] is int ? item['episodeNumber'] as int : null),
        seriesTitle: Value(item['seriesTitle']?.toString()),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    // 保留最近 100 条
    final all = await (db.select(db.watchHistoryTable)
          ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
        .get();
    if (all.length > 100) {
      final toDelete = all.take(all.length - 100).map((r) => r.id).toList();
      if (toDelete.isNotEmpty) {
        await (db.delete(db.watchHistoryTable)
              ..where((t) => t.id.isIn(toDelete)))
            .go();
      }
    }
  }

  static Future<void> removeFromHistory(String itemId) async {
    await (db.delete(db.watchHistoryTable)
          ..where((t) => t.id.equals(itemId)))
        .go();
  }

  static Future<void> clearHistory() async {
    await db.delete(db.watchHistoryTable).go();
  }

  // ─── Favorites ───

  static Future<List<FavoriteMovie>> getFavorites() async {
    final rows = await (db.select(db.favoriteMoviesTable)
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .get();
    return rows.map(_favFromRow).toList();
  }

  static Future<void> addFavoriteMovie(FavoriteMovie movie) async {
    await db.into(db.favoriteMoviesTable).insert(
      FavoriteMoviesTableCompanion.insert(
        tmdbId: Value(movie.tmdbId),
        title: movie.title,
        posterPath: Value(movie.posterPath),
        backdropPath: Value(movie.backdropPath),
        overview: Value(movie.overview),
        voteAverage: Value(movie.voteAverage),
        releaseDate: Value(movie.releaseDate),
        addedAt: movie.addedAt.millisecondsSinceEpoch,
        type: Value(movie.type),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  static Future<void> removeFavoriteMovie(int tmdbId) async {
    await (db.delete(db.favoriteMoviesTable)
          ..where((t) => t.tmdbId.equals(tmdbId)))
        .go();
  }

  static Future<bool> isFavoriteMovie(int tmdbId) async {
    final results = await (db.select(db.favoriteMoviesTable)
          ..where((t) => t.tmdbId.equals(tmdbId)))
        .get();
    return results.isNotEmpty;
  }

  static FavoriteMovie _favFromRow(FavoriteMovieRow row) {
    return FavoriteMovie(
      tmdbId: row.tmdbId,
      title: row.title,
      posterPath: row.posterPath,
      backdropPath: row.backdropPath,
      overview: row.overview,
      voteAverage: row.voteAverage,
      releaseDate: row.releaseDate,
      addedAt: DateTime.fromMillisecondsSinceEpoch(row.addedAt),
      type: row.type,
    );
  }

  // ─── Watchlist ───

  static Future<List<FavoriteMovie>> getWatchlist() async {
    final rows = await (db.select(db.watchlistTable)
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .get();
    return rows.map(_watchlistFromRow).toList();
  }

  static Future<void> addToWatchlist(FavoriteMovie movie) async {
    await db.into(db.watchlistTable).insert(
      WatchlistTableCompanion.insert(
        tmdbId: Value(movie.tmdbId),
        title: movie.title,
        posterPath: Value(movie.posterPath),
        backdropPath: Value(movie.backdropPath),
        overview: Value(movie.overview),
        voteAverage: Value(movie.voteAverage),
        releaseDate: Value(movie.releaseDate),
        addedAt: movie.addedAt.millisecondsSinceEpoch,
        type: Value(movie.type),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  static Future<void> removeFromWatchlist(int tmdbId) async {
    await (db.delete(db.watchlistTable)
          ..where((t) => t.tmdbId.equals(tmdbId)))
        .go();
  }

  static FavoriteMovie _watchlistFromRow(WatchlistMovieRow row) {
    return FavoriteMovie(
      tmdbId: row.tmdbId,
      title: row.title,
      posterPath: row.posterPath,
      backdropPath: row.backdropPath,
      overview: row.overview,
      voteAverage: row.voteAverage,
      releaseDate: row.releaseDate,
      addedAt: DateTime.fromMillisecondsSinceEpoch(row.addedAt),
      type: row.type,
    );
  }

  static Future<bool> isInWatchlist(int tmdbId) async {
    final results = await (db.select(db.watchlistTable)
          ..where((t) => t.tmdbId.equals(tmdbId)))
        .get();
    return results.isNotEmpty;
  }

  // ─── Playlist ───

  static Future<List<PlaylistItem>> getPlaylist() async {
    final rows = await (db.select(db.playlistTable)
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .get();
    return rows.map(_playlistFromRow).toList();
  }

  static Future<void> addToPlaylist(PlaylistItem item) async {
    await db.into(db.playlistTable).insert(
      PlaylistTableCompanion.insert(
        itemId: item.itemId,
        title: item.title,
        posterUrl: Value(item.posterUrl),
        backdropUrl: Value(item.backdropUrl),
        overview: Value(item.overview),
        rating: Value(item.rating),
        year: Value(item.year),
        type: Value(item.type.name),
        addedAt: item.addedAt.millisecondsSinceEpoch,
        seriesTitle: Value(item.seriesTitle),
        seasonNumber: Value(item.seasonNumber),
        episodeNumber: Value(item.episodeNumber),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  static Future<void> removeFromPlaylist(String itemId) async {
    await (db.delete(db.playlistTable)
          ..where((t) => t.itemId.equals(itemId)))
        .go();
  }

  static Future<bool> isInPlaylist(String itemId) async {
    final results = await (db.select(db.playlistTable)
          ..where((t) => t.itemId.equals(itemId)))
        .get();
    return results.isNotEmpty;
  }

  static PlaylistItem _playlistFromRow(PlaylistRow row) {
    return PlaylistItem(
      itemId: row.itemId,
      title: row.title,
      posterUrl: row.posterUrl,
      backdropUrl: row.backdropUrl,
      overview: row.overview,
      rating: row.rating,
      year: row.year,
      type: MediaType.values.firstWhere((t) => t.name == row.type, orElse: () => MediaType.movie),
      addedAt: DateTime.fromMillisecondsSinceEpoch(row.addedAt),
      seriesTitle: row.seriesTitle,
      seasonNumber: row.seasonNumber,
      episodeNumber: row.episodeNumber,
    );
  }

  // ─── App Settings (key-value) ───

  static Future<String?> getSetting(String key) async {
    final row = await (db.select(db.appSettingsTable)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  static Future<void> setSetting(String key, String value) async {
    await db.into(db.appSettingsTable).insert(
      AppSettingsTableCompanion.insert(key: key, value: value),
      mode: InsertMode.insertOrReplace,
    );
  }

  static Future<void> removeSetting(String key) async {
    await (db.delete(db.appSettingsTable)
          ..where((t) => t.key.equals(key)))
        .go();
  }

  // ─── Danmaku Selections ───

  static Future<String?> getDanmakuSelection(String mediaId) async {
    final row = await (db.select(db.danmakuSelectionsTable)
          ..where((t) => t.mediaId.equals(mediaId)))
        .getSingleOrNull();
    return row?.episodeId;
  }

  static Future<void> setDanmakuSelection(String mediaId, String episodeId) async {
    await db.into(db.danmakuSelectionsTable).insert(
      DanmakuSelectionsTableCompanion.insert(
        mediaId: mediaId,
        episodeId: episodeId,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  // ─── DanmakuDisplaySettings (JSON blob in app_settings) ───

  static Future<String?> getDanmakuDisplayJson() async {
    return getSetting('danmaku_display');
  }

  static Future<void> setDanmakuDisplayJson(String json) async {
    await setSetting('danmaku_display', json);
  }

  // ─── PlayerSettings (JSON blob in app_settings) ───

  static Future<String?> getPlayerSettingsJson() async {
    return getSetting('player_settings');
  }

  static Future<void> setPlayerSettingsJson(String json) async {
    await setSetting('player_settings', json);
  }

  // ─── SharedPreferences 一次性迁移 ───

  static Future<void> _migrateFromSharedPreferences() async {
    const migrationKey = '_db_migrated_v1';
    final alreadyMigrated = StorageService.getBool(migrationKey) ?? false;
    if (alreadyMigrated) return;

    AppLog.i('DB', '开始从 SharedPreferences 迁移数据到 SQLite...');

    try {
      // 1. 迁移媒体服务器
      final serversJson = StorageService.getJsonList(StorageService.serversKey);
      if (serversJson != null && serversJson.isNotEmpty) {
        final servers = serversJson.map((j) => MediaServer.fromJson(j)).toList();
        await saveServers(servers);
        AppLog.i('DB', '迁移媒体服务器: ${servers.length} 条');
      }

      // 2. 迁移弹幕配置
      final configsJson = StorageService.getJsonList(StorageService.danmakuConfigKey);
      if (configsJson != null && configsJson.isNotEmpty) {
        final configs = configsJson.map((j) => DanmakuConfig.fromJson(j)).toList();
        await saveDanmakuConfigs(configs);
        AppLog.i('DB', '迁移弹幕配置: ${configs.length} 条');
      }

      // 3. 迁移观看历史
      final historyJson = StorageService.getJsonList(StorageService.watchHistoryKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        for (final item in historyJson) {
          await addToHistory(item);
        }
        AppLog.i('DB', '迁移观看历史: ${historyJson.length} 条');
      }

      // 4. 迁移收藏
      final favData = StorageService.getStringList('favorite_movies');
      if (favData != null && favData.isNotEmpty) {
        for (final jsonStr in favData) {
          try {
            final movie = FavoriteMovie.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
            await addFavoriteMovie(movie);
          } catch (_) {}
        }
        AppLog.i('DB', '迁移收藏: ${favData.length} 条');
      }

      // 5. 迁移待看列表
      final watchlistData = StorageService.getStringList('watchlist_movies');
      if (watchlistData != null && watchlistData.isNotEmpty) {
        for (final jsonStr in watchlistData) {
          try {
            final movie = FavoriteMovie.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
            await addToWatchlist(movie);
          } catch (_) {}
        }
        AppLog.i('DB', '迁移待看列表: ${watchlistData.length} 条');
      }

      // 6. 迁移旧收藏 (string ID list)
      final legacyFavs = StorageService.getStringList(StorageService.favoritesKey);
      if (legacyFavs != null && legacyFavs.isNotEmpty) {
        await setSetting('legacy_favorites', jsonEncode(legacyFavs));
        AppLog.i('DB', '迁移旧收藏 ID: ${legacyFavs.length} 条');
      }

      // 7. 迁移播放器设置
      final playerSettings = StorageService.getString(StorageService.playerSettingsKey);
      if (playerSettings != null) {
        await setPlayerSettingsJson(playerSettings);
        AppLog.i('DB', '迁移播放器设置');
      }

      // 8. 迁移弹幕显示设置
      final danmakuDisplay = StorageService.getString('danmaku_display');
      if (danmakuDisplay != null) {
        await setDanmakuDisplayJson(danmakuDisplay);
        AppLog.i('DB', '迁移弹幕显示设置');
      }

      // 9. 迁移其他设置
      for (final key in ['search_sources', 'moviepilot_url', 'moviepilot_username',
                         'secure_moviepilot_api_key', 'secure_moviepilot_password',
                         'carousel_color_cache_v2']) {
        final val = StorageService.getString(key);
        if (val != null) {
          await setSetting(key, val);
        }
      }

      await StorageService.setBool(migrationKey, true);
      AppLog.i('DB', 'SharedPreferences 迁移完成');
    } catch (e) {
      AppLog.e('DB', '迁移失败: $e');
    }
  }

  // ─── Dominant Color Cache ───

  static const Duration _kColorCacheTTL = Duration(hours: 24);

  static Future<Color?> getDominantColor(String url) async {
    final row = await (db.select(db.dominantColorsTable)
          ..where((t) => t.url.equals(url)))
        .getSingleOrNull();
    if (row == null) return null;
    if (DateTime.now().millisecondsSinceEpoch - row.cachedAt > _kColorCacheTTL.inMilliseconds) return null;
    return Color(int.parse('FF${row.color}', radix: 16));
  }

  static Future<void> saveDominantColor(String url, Color color) async {
    final hex = color.value.toRadixString(16).substring(2).toUpperCase();
    await db.into(db.dominantColorsTable).insert(
      DominantColorsTableCompanion.insert(
        url: url,
        color: hex,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  // ─── Danmaku Cache ───

  static const Duration _kDanmakuCacheTTL = Duration(days: 7);

  static Future<String?> getDanmakuCache(String cacheKey) async {
    final row = await (db.select(db.danmakuCacheTable)
          ..where((t) => t.cacheKey.equals(cacheKey)))
        .getSingleOrNull();
    if (row == null) return null;
    if (DateTime.now().millisecondsSinceEpoch - row.cachedAt > _kDanmakuCacheTTL.inMilliseconds) return null;
    return row.data;
  }

  static Future<void> saveDanmakuCache(String cacheKey, String data) async {
    await db.into(db.danmakuCacheTable).insert(
      DanmakuCacheTableCompanion.insert(
        cacheKey: cacheKey,
        data: data,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}

// ─── Riverpod Provider ───

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return DbService.db;
});
