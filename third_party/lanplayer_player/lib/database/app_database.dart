import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/app_log.dart';

part 'app_database.g.dart';

/// 获取应用文档目录路径（与全项目一致使用 path_provider，Android 上为 filesDir）。
/// 失败时降级到临时目录（异常路径，应避免）。
Future<String> _getApplicationDocumentsDirectory() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    if (dir.path.isNotEmpty) {
      return dir.path;
    }
  } catch (e) {
    AppLog.w('DB', '获取文档目录失败: $e，降级到临时目录');
  }
  return Directory.systemTemp.path;
}

// ─── Type Converters ───

class ServerTypeConverter extends TypeConverter<String, int> {
  const ServerTypeConverter();
  static const _types = ['emby', 'jellyfin', 'fnos', 'plex', 'moviepilot'];
  @override
  String fromSql(int fromDb) => _types[fromDb.clamp(0, _types.length - 1)];
  @override
  int toSql(String value) => _types.indexOf(value).clamp(0, _types.length - 1);
}

// ─── Table Definitions ───

@DataClassName('MediaServerRow')
class MediaServersTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get url => text()();
  IntColumn get serverType => integer().map(const ServerTypeConverter())();
  TextColumn get apiKey => text().nullable()();
  TextColumn get username => text().nullable()();
  TextColumn get password => text().nullable()();
  BoolColumn get isConnected => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DanmakuConfigRow')
class DanmakuConfigsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get url => text()();
  TextColumn get apiKey => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  RealColumn get fontSize => real().withDefault(const Constant(24.0))();
  RealColumn get opacity => real().withDefault(const Constant(1.0))();
  RealColumn get speed => real().withDefault(const Constant(12.0))();
  BoolColumn get showTop => boolean().withDefault(const Constant(true))();
  BoolColumn get showBottom => boolean().withDefault(const Constant(true))();
  BoolColumn get showScroll => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WatchHistoryRow')
class WatchHistoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get posterUrl => text().withDefault(const Constant(''))();
  TextColumn get backdropUrl => text().nullable()();
  TextColumn get serverId => text().nullable()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get seasonNumber => integer().nullable()();
  IntColumn get episodeNumber => integer().nullable()();
  TextColumn get seriesTitle => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FavoriteMovieRow')
class FavoriteMoviesTable extends Table {
  IntColumn get tmdbId => integer()();
  TextColumn get title => text()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get backdropPath => text().nullable()();
  TextColumn get overview => text().nullable()();
  RealColumn get voteAverage => real().nullable()();
  TextColumn get releaseDate => text().nullable()();
  IntColumn get addedAt => integer()();
  TextColumn get type => text().withDefault(const Constant('movie'))();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

@DataClassName('WatchlistMovieRow')
class WatchlistTable extends Table {
  IntColumn get tmdbId => integer()();
  TextColumn get title => text()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get backdropPath => text().nullable()();
  TextColumn get overview => text().nullable()();
  RealColumn get voteAverage => real().nullable()();
  TextColumn get releaseDate => text().nullable()();
  IntColumn get addedAt => integer()();
  TextColumn get type => text().withDefault(const Constant('movie'))();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

@DataClassName('AppSettingRow')
class AppSettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('DanmakuSelectionRow')
class DanmakuSelectionsTable extends Table {
  TextColumn get mediaId => text()();
  TextColumn get episodeId => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {mediaId};
}

// ─── Media Library Cache Tables ───

@DataClassName('MediaLibraryRow')
class MediaLibrariesTable extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text()();
  TextColumn get title => text()();
  TextColumn get posterUrl => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant('folder'))();
  // 库类型（movies/tvshows/boxsets 等），决定查询时是否带上 BoxSet 类型（Jellyfin 必需）
  TextColumn get collectionType => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {serverId, id};
}

@DataClassName('MediaItemCacheRow')
class MediaItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text()();
  TextColumn get libraryId => text()();
  TextColumn get title => text()();
  TextColumn get posterUrl => text().withDefault(const Constant(''))();
  TextColumn get backdropUrl => text().nullable()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get overview => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get releaseDate => text().nullable()();
  TextColumn get genres => text().withDefault(const Constant('[]'))();
  TextColumn get type => text().withDefault(const Constant('movie'))();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  TextColumn get imdbId => text().nullable()();
  IntColumn get tmdbId => integer().nullable()();
  TextColumn get quality => text().nullable()();
  BoolColumn get isWatched => boolean().nullable()();
  BoolColumn get isFavorite => boolean().nullable()();
  RealColumn get watchProgress => real().nullable()();
  TextColumn get sources => text().withDefault(const Constant('[]'))();
  TextColumn get director => text().nullable()();
  TextColumn get cast => text().nullable()();
  TextColumn get videoTracks => text().nullable()();
  TextColumn get audioTracks => text().nullable()();
  TextColumn get subtitleTracks => text().nullable()();
  TextColumn get people => text().nullable()();
  IntColumn get seasonNumber => integer().nullable()();
  IntColumn get episodeNumber => integer().nullable()();
  TextColumn get seriesTitle => text().nullable()();
  IntColumn get totalSeasons => integer().nullable()();
  IntColumn get totalEpisodes => integer().nullable()();
  TextColumn get filePath => text().nullable()();
  BoolColumn get isBoxSet => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get cachedAt => integer().nullable()();

  @override
  // 主键必须含 libraryId:同一媒体条目会出现在多个库(动漫/影片/电视节目
  // 重叠;真机日志实证:网络拉到动漫55部,落库读回只剩42部——旧主键
  // {serverId,id} 下后写的库 insertOrReplace 覆盖行、library_id 被抢走)。
  Set<Column> get primaryKey => {serverId, libraryId, id};
}

@DataClassName('MediaCarouselRow')
class MediaCarouselTable extends Table {
  TextColumn get serverId => text()();
  TextColumn get itemId => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get itemJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {serverId, itemId};
}

@DataClassName('MediaCacheMetaRow')
class MediaCacheMetaTable extends Table {
  TextColumn get serverId => text()();
  IntColumn get lastRefreshTime => integer().nullable()();
  TextColumn get carouselIds => text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {serverId};
}

// ─── Cache Tables ───

@DataClassName('DominantColorRow')
class DominantColorsTable extends Table {
  TextColumn get url => text()();
  TextColumn get color => text()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {url};
}

@DataClassName('DanmakuCacheRow')
class DanmakuCacheTable extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get data => text()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

@DataClassName('PlaylistRow')
class PlaylistTable extends Table {
  TextColumn get itemId => text()();
  TextColumn get title => text()();
  TextColumn get posterUrl => text().withDefault(const Constant(''))();
  TextColumn get backdropUrl => text().nullable()();
  TextColumn get overview => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get type => text().withDefault(const Constant('movie'))();
  IntColumn get addedAt => integer()();
  TextColumn get seriesTitle => text().nullable()();
  IntColumn get seasonNumber => integer().nullable()();
  IntColumn get episodeNumber => integer().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};
}

// ─── Database ───

@DriftDatabase(tables: [
  MediaServersTable,
  DanmakuConfigsTable,
  WatchHistoryTable,
  FavoriteMoviesTable,
  WatchlistTable,
  AppSettingsTable,
  DanmakuSelectionsTable,
  MediaLibrariesTable,
  MediaItemsTable,
  MediaCarouselTable,
  MediaCacheMetaTable,
  DominantColorsTable,
  DanmakuCacheTable,
  PlaylistTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8;

  /// drift 无列存在性检查 API；from<2 分支可能刚用当前定义建表（已含新列），
  /// 也可能旧表存在但缺新列，用 try/catch 兜底 duplicate column。
  Future<void> _tryAddColumn(Migrator m, TableInfo table, GeneratedColumn column) async {
    try {
      await m.addColumn(table, column);
      AppLog.i('DB', 'migration: added ${column.name}');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('duplicate column')) {
        AppLog.i('DB', 'migration: ${column.name} already exists, skip');
      } else {
        rethrow;
      }
    }
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        AppLog.i('DB', 'onCreate: createAll');
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        AppLog.i('DB', 'onUpgrade from=$from to=$to');
        if (from < 2) {
          await m.createTable(mediaLibrariesTable);
          await m.createTable(mediaItemsTable);
          await m.createTable(mediaCarouselTable);
          await m.createTable(mediaCacheMetaTable);
        }
        if (from == 2) {
          await m.addColumn(mediaItemsTable, mediaItemsTable.cachedAt);
        }
        await _tryAddColumn(m, mediaLibrariesTable, mediaLibrariesTable.collectionType);
        await _tryAddColumn(m, mediaItemsTable, mediaItemsTable.isBoxSet);
        // v8：官方标题艺术图(Logo) URL,TV 首页/详情页标题用
        await _tryAddColumn(m, mediaItemsTable, mediaItemsTable.logoUrl);
        try {
          await m.database.delete(mediaCacheMetaTable).go();
        } catch (_) {}
        // v5：新增提色缓存 + 弹幕缓存
        if (from < 5) {
          await m.createTable(dominantColorsTable);
          await m.createTable(danmakuCacheTable);
        }
        // v6：补建 playlist_table —— 它声明进了 schema 但 v5 迁移漏了建表分支，
        // 已升级到 v5 的老库上 getPlaylist 每次都抛 no such table（真机日志
        // 2026-08-28 实证）。drift 的 createTable 生成 IF NOT EXISTS，重复执行安全。
        if (from < 6) {
          await m.createTable(playlistTable);
        }
        // v7：mediaItemsTable 主键加 libraryId（跨库同 id 条目互相覆盖导致
        // 各库数量比服务器少）。纯缓存表,直接重建——下次启动缓存为空会
        // 触发一次全量网络刷新,数据自愈。
        if (from < 7) {
          await customStatement('DROP TABLE IF EXISTS media_items_table');
          await m.createTable(mediaItemsTable);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await _getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder, 'lanplayer.db'));
    return NativeDatabase.createInBackground(file);
  });
}
