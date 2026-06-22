import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/media_detail_caches.dart';

part 'media_detail_cache_dao.g.dart';

@DriftAccessor(tables: [MediaDetailCaches])
class MediaDetailCacheDao extends DatabaseAccessor<AppDatabase>
    with _$MediaDetailCacheDaoMixin {
  MediaDetailCacheDao(super.db);

  Future<MediaDetailCacheRow?> findByPk(String id) =>
      (select(mediaDetailCaches)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsert(MediaDetailCachesCompanion row) =>
      into(mediaDetailCaches).insertOnConflictUpdate(row);
}
