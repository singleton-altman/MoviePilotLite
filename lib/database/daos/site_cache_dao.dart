import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/site_icon_caches.dart';
import '../tables/site_model_caches.dart';
import '../tables/site_userdata_caches.dart';

part 'site_cache_dao.g.dart';

@DriftAccessor(
    tables: [SiteIconCaches, SiteModelCaches, SiteUserDataCaches])
class SiteCacheDao extends DatabaseAccessor<AppDatabase>
    with _$SiteCacheDaoMixin {
  SiteCacheDao(super.db);

  // --- Site model cache ---

  Future<List<SiteModelCacheRow>> getAllSiteModels() =>
      select(siteModelCaches).get();

  Future<void> replaceAllSiteModels(List<SiteModelCachesCompanion> rows) async {
    await transaction(() async {
      await delete(siteModelCaches).go();
      await batch((batch) {
        batch.insertAllOnConflictUpdate(siteModelCaches, rows);
      });
    });
  }

  // --- Site user data cache ---

  Future<List<SiteUserDataCacheRow>> getAllUserData() =>
      select(siteUserDataCaches).get();

  Future<void> replaceAllUserData(
      List<SiteUserDataCachesCompanion> rows) async {
    await transaction(() async {
      await delete(siteUserDataCaches).go();
      await batch((batch) {
        batch.insertAllOnConflictUpdate(siteUserDataCaches, rows);
      });
    });
  }

  // --- Site icon cache ---

  Future<List<SiteIconCacheRow>> getAllIcons() =>
      select(siteIconCaches).get();

  Future<SiteIconCacheRow?> findIconByUrl(String url) =>
      (select(siteIconCaches)..where((t) => t.url.equals(url)))
          .getSingleOrNull();

  Future<void> upsertIcon(SiteIconCachesCompanion row) =>
      into(siteIconCaches).insertOnConflictUpdate(row);
}
