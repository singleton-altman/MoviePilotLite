import 'dart:convert';
import 'package:drift/drift.dart';
import '../models/media_models.dart';
import '../utils/app_log.dart';
import 'app_database.dart';
import 'database_service.dart';

class MediaLibraryRepository {
  static AppDatabase get _db => DbService.db;

  static Future<List<MediaItem>> getLibraries(String serverId) async {
    final rows = await (_db.select(_db.mediaLibrariesTable)
          ..where((t) => t.serverId.equals(serverId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows.map(_libraryFromRow).toList();
  }

  static Future<Map<String, List<MediaItem>>> getLibraryItems(String serverId) async {
    final rows = await (_db.select(_db.mediaItemsTable)
          ..where((t) => t.serverId.equals(serverId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    final result = <String, List<MediaItem>>{};
    for (final row in rows) {
      final item = _mediaItemFromRow(row);
      result.putIfAbsent(row.libraryId, () => []).add(item);
    }
    return result;
  }

  static Future<List<MediaItem>> getCarouselItems(String serverId) async {
    final rows = await (_db.select(_db.mediaCarouselTable)
          ..where((t) => t.serverId.equals(serverId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    return rows.map((row) {
      try {
        final json = jsonDecode(row.itemJson) as Map<String, dynamic>;
        return MediaItem.fromJson(json);
      } catch (_) {
        return MediaItem(
          id: row.itemId,
          title: '',
          posterUrl: '',
        );
      }
    }).toList();
  }

  static Future<DateTime?> getLastRefreshTime(String serverId) async {
    final row = await (_db.select(_db.mediaCacheMetaTable)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
    if (row?.lastRefreshTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(row!.lastRefreshTime!);
  }

  static Future<bool> hasCache(String serverId) async {
    final count = _db.mediaItemsTable.id.count();
    final result = await (_db.selectOnly(_db.mediaItemsTable)
          ..where(_db.mediaItemsTable.serverId.equals(serverId))
          ..addColumns([count]))
        .getSingle();
    return (result.read(count) ?? 0) > 0;
  }

  static Future<void> saveLibraries(
    String serverId,
    List<MediaItem> libraries,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.mediaLibrariesTable)
            ..where((t) => t.serverId.equals(serverId)))
          .go();

      for (var i = 0; i < libraries.length; i++) {
        final lib = libraries[i];
        await _db.into(_db.mediaLibrariesTable).insert(
              MediaLibrariesTableCompanion.insert(
                id: lib.id,
                serverId: serverId,
                title: lib.title,
                posterUrl: Value(lib.posterUrl),
                type: Value(lib.type.name),
                collectionType: Value(lib.collectionType),
                sortOrder: Value(i),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  static Future<void> saveLibraryItems(
    String serverId,
    Map<String, List<MediaItem>> itemsMap,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.mediaItemsTable)
            ..where((t) => t.serverId.equals(serverId)))
          .go();

      var sortOrder = 0;
      for (final entry in itemsMap.entries) {
        final libraryId = entry.key;
        final items = entry.value;
        for (final item in items) {
          await _db.into(_db.mediaItemsTable).insert(
                _mediaItemToCompanion(serverId, libraryId, item, sortOrder++),
                mode: InsertMode.insertOrReplace,
              );
        }
      }
    });
    AppLog.i('MediaLibraryRepo', 'Saved ${itemsMap.length} libraries items for server $serverId');
  }

  static Future<void> saveCarouselItems(
    String serverId,
    List<MediaItem> carouselItems,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.mediaCarouselTable)
            ..where((t) => t.serverId.equals(serverId)))
          .go();

      for (var i = 0; i < carouselItems.length; i++) {
        final item = carouselItems[i];
        await _db.into(_db.mediaCarouselTable).insert(
              MediaCarouselTableCompanion.insert(
                serverId: serverId,
                itemId: item.id,
                sortOrder: Value(i),
                itemJson: Value(jsonEncode(item.toJson())),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  static Future<void> updateLastRefreshTime(
    String serverId,
    DateTime time,
  ) async {
    await _db.into(_db.mediaCacheMetaTable).insert(
          MediaCacheMetaTableCompanion.insert(
            serverId: serverId,
            lastRefreshTime: Value(time.millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  static Future<void> saveAll({
    required String serverId,
    required List<MediaItem> libraries,
    required Map<String, List<MediaItem>> libraryItems,
    required List<MediaItem> carouselItems,
    required DateTime lastRefreshTime,
  }) async {
    await _db.transaction(() async {
      await saveLibraries(serverId, libraries);
      await saveLibraryItems(serverId, libraryItems);
      await saveCarouselItems(serverId, carouselItems);
      await updateLastRefreshTime(serverId, lastRefreshTime);
    });
    AppLog.i('MediaLibraryRepo', 'All cache saved for server $serverId');
  }

  static Future<void> upsertLibraries(
    String serverId,
    List<MediaItem> libraries,
  ) async {
    await _db.transaction(() async {
      final existingIds = await (_db.selectOnly(_db.mediaLibrariesTable)
            ..where(_db.mediaLibrariesTable.serverId.equals(serverId))
            ..addColumns([_db.mediaLibrariesTable.id]))
          .map((row) => row.read(_db.mediaLibrariesTable.id)!)
          .get();
      final newIds = libraries.map((l) => l.id).toSet();
      final toDelete = existingIds.where((id) => !newIds.contains(id)).toList();
      if (toDelete.isNotEmpty) {
        await (_db.delete(_db.mediaLibrariesTable)
              ..where((t) => t.serverId.equals(serverId) & t.id.isIn(toDelete)))
            .go();
      }
      for (var i = 0; i < libraries.length; i++) {
        final lib = libraries[i];
        await _db.into(_db.mediaLibrariesTable).insert(
              MediaLibrariesTableCompanion.insert(
                id: lib.id,
                serverId: serverId,
                title: lib.title,
                posterUrl: Value(lib.posterUrl),
                type: Value(lib.type.name),
                collectionType: Value(lib.collectionType),
                sortOrder: Value(i),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  static Future<void> upsertLibraryItems(
    String serverId,
    Map<String, List<MediaItem>> itemsMap,
  ) async {
    await _db.transaction(() async {
      final allNewIds = <String>{};
      for (final items in itemsMap.values) {
        for (final item in items) {
          allNewIds.add(item.id);
        }
      }
      final existingIds = await (_db.selectOnly(_db.mediaItemsTable)
            ..where(_db.mediaItemsTable.serverId.equals(serverId))
            ..addColumns([_db.mediaItemsTable.id]))
          .map((row) => row.read(_db.mediaItemsTable.id)!)
          .get();
      final toDelete = existingIds.where((id) => !allNewIds.contains(id)).toList();
      if (toDelete.isNotEmpty) {
        await (_db.delete(_db.mediaItemsTable)
              ..where((t) => t.serverId.equals(serverId) & t.id.isIn(toDelete)))
            .go();
      }
      var sortOrder = 0;
      for (final entry in itemsMap.entries) {
        final libraryId = entry.key;
        final items = entry.value;
        for (final item in items) {
          await _db.into(_db.mediaItemsTable).insert(
                _mediaItemToCompanion(serverId, libraryId, item, sortOrder++),
                mode: InsertMode.insertOrReplace,
              );
        }
      }
    });
    AppLog.i('MediaLibraryRepo', 'Upserted library items for server $serverId');
  }

  static Future<void> upsertCarouselItems(
    String serverId,
    List<MediaItem> carouselItems,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.mediaCarouselTable)
            ..where((t) => t.serverId.equals(serverId)))
          .go();
      for (var i = 0; i < carouselItems.length; i++) {
        final item = carouselItems[i];
        await _db.into(_db.mediaCarouselTable).insert(
              MediaCarouselTableCompanion.insert(
                serverId: serverId,
                itemId: item.id,
                sortOrder: Value(i),
                itemJson: Value(jsonEncode(item.toJson())),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  static Future<void> upsertAll({
    required String serverId,
    required List<MediaItem> libraries,
    required Map<String, List<MediaItem>> libraryItems,
    required List<MediaItem> carouselItems,
    required DateTime lastRefreshTime,
  }) async {
    await _db.transaction(() async {
      await upsertLibraries(serverId, libraries);
      await upsertLibraryItems(serverId, libraryItems);
      await upsertCarouselItems(serverId, carouselItems);
      await updateLastRefreshTime(serverId, lastRefreshTime);
    });
    AppLog.i('MediaLibraryRepo', 'All cache upserted for server $serverId');
  }

  static Future<void> clearCache(String serverId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.mediaLibrariesTable)
            ..where((t) => t.serverId.equals(serverId)))
          .go();
      await (_db.delete(_db.mediaItemsTable)
            ..where((t) => t.serverId.equals(serverId)))
          .go();
      await (_db.delete(_db.mediaCarouselTable)
            ..where((t) => t.serverId.equals(serverId)))
          .go();
      await (_db.delete(_db.mediaCacheMetaTable)
            ..where((t) => t.serverId.equals(serverId)))
          .go();
    });
  }

  // ==================== 详情缓存 ====================
  static const Duration _kDetailCacheTTL = Duration(hours: 24);

  /// 获取单个媒体项的详情缓存（带 TTL 检查）
  static Future<MediaItem?> getDetailCache(String serverId, String itemId) async {
    // v7 起主键含 libraryId:同一条目跨库会有多行,这里取最新缓存的一行。
    // (用 singleOrNull 会在多行时抛 "Too many elements",真机日志实证)
    final rows = await (_db.select(_db.mediaItemsTable)
          ..where((t) => t.serverId.equals(serverId) & t.id.equals(itemId)))
        .get();
    if (rows.isEmpty) return null;
    final row = rows.reduce((a, b) {
      final at = a.cachedAt ?? 0;
      final bt = b.cachedAt ?? 0;
      return at >= bt ? a : b;
    });

    if (row.cachedAt != null) {
      final cached = DateTime.fromMillisecondsSinceEpoch(row.cachedAt!);
      if (DateTime.now().difference(cached) > _kDetailCacheTTL) {
        return null;
      }
    } else {
      return null;
    }

    return _mediaItemFromRow(row);
  }

  /// 保存单个媒体项的详情缓存
  static Future<void> saveDetailCache(
    String serverId,
    String libraryId,
    MediaItem item,
  ) async {
    await _db.into(_db.mediaItemsTable).insert(
          _mediaItemToCompanion(serverId, libraryId, item, 0).copyWith(
            cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  static MediaItem _libraryFromRow(MediaLibraryRow row) {
    return MediaItem(
      id: row.id,
      title: row.title,
      posterUrl: row.posterUrl,
      type: MediaType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => MediaType.movie,
      ),
      collectionType: row.collectionType,
    );
  }

  static MediaItem _mediaItemFromRow(MediaItemCacheRow row) {
    return MediaItem(
      id: row.id,
      title: row.title,
      posterUrl: row.posterUrl,
      backdropUrl: row.backdropUrl,
      logoUrl: row.logoUrl,
      overview: row.overview,
      rating: row.rating,
      year: row.year,
      releaseDate: row.releaseDate,
      genres: _decodeStringList(row.genres),
      type: MediaType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => MediaType.movie,
      ),
      duration: row.duration,
      imdbId: row.imdbId,
      tmdbId: row.tmdbId,
      quality: row.quality,
      isWatched: row.isWatched,
      isFavorite: row.isFavorite,
      watchProgress: row.watchProgress,
      sources: _decodeSources(row.sources),
      director: row.director,
      cast: row.cast != null ? _decodeStringList(row.cast!) : null,
      videoTracks: row.videoTracks != null ? _decodeDynamicList(row.videoTracks!) : null,
      audioTracks: row.audioTracks != null ? _decodeDynamicList(row.audioTracks!) : null,
      subtitleTracks: row.subtitleTracks != null ? _decodeDynamicList(row.subtitleTracks!) : null,
      people: row.people != null ? _decodeDynamicList(row.people!) : null,
      seasonNumber: row.seasonNumber,
      episodeNumber: row.episodeNumber,
      seriesTitle: row.seriesTitle,
      totalSeasons: row.totalSeasons,
      totalEpisodes: row.totalEpisodes,
      filePath: row.filePath,
      isBoxSet: row.isBoxSet,
    );
  }

  static MediaItemsTableCompanion _mediaItemToCompanion(
    String serverId,
    String libraryId,
    MediaItem item,
    int sortOrder,
  ) {
    return MediaItemsTableCompanion.insert(
      id: item.id,
      serverId: serverId,
      libraryId: libraryId,
      title: item.title,
      posterUrl: Value(item.posterUrl),
      backdropUrl: Value(item.backdropUrl),
      logoUrl: Value(item.logoUrl),
      overview: Value(item.overview),
      rating: Value(item.rating),
      year: Value(item.year),
      releaseDate: Value(item.releaseDate),
      genres: Value(jsonEncode(item.genres)),
      type: Value(item.type.name),
      duration: Value(item.duration),
      imdbId: Value(item.imdbId),
      tmdbId: Value(item.tmdbId),
      quality: Value(item.quality),
      isWatched: Value(item.isWatched),
      isFavorite: Value(item.isFavorite),
      watchProgress: Value(item.watchProgress),
      sources: Value(jsonEncode(item.sources.map((s) => s.toJson()).toList())),
      director: Value(item.director),
      cast: Value(item.cast != null ? jsonEncode(item.cast) : null),
      videoTracks: Value(item.videoTracks != null ? jsonEncode(item.videoTracks) : null),
      audioTracks: Value(item.audioTracks != null ? jsonEncode(item.audioTracks) : null),
      subtitleTracks: Value(item.subtitleTracks != null ? jsonEncode(item.subtitleTracks) : null),
      people: Value(item.people != null ? jsonEncode(item.people) : null),
      seasonNumber: Value(item.seasonNumber),
      episodeNumber: Value(item.episodeNumber),
      seriesTitle: Value(item.seriesTitle),
      totalSeasons: Value(item.totalSeasons),
      totalEpisodes: Value(item.totalEpisodes),
      filePath: Value(item.filePath),
      isBoxSet: Value(item.isBoxSet),
      sortOrder: Value(sortOrder),
    );
  }

  static List<String> _decodeStringList(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return const [];
  }

  static List<MediaSource> _decodeSources(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .map((e) => MediaSource.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  static List<Map<String, dynamic>>? _decodeDynamicList(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }
}
