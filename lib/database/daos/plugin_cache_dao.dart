import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/installed_plugin_caches.dart';
import '../tables/plugin_model_caches.dart';

part 'plugin_cache_dao.g.dart';

@DriftAccessor(tables: [PluginModelCaches, InstalledPluginModelCaches])
class PluginCacheDao extends DatabaseAccessor<AppDatabase>
    with _$PluginCacheDaoMixin {
  PluginCacheDao(super.db);

  // --- Plugin market cache ---

  Future<List<PluginModelCacheRow>> getAllPluginModels() =>
      select(pluginModelCaches).get();

  Future<List<PluginModelCacheRow>> getPluginModelsByScope(
      bool Function(String id) scopeMatcher) async {
    final all = await select(pluginModelCaches).get();
    return all.where((e) => scopeMatcher(e.id)).toList();
  }

  Future<void> deletePluginModelsByScope(
      bool Function(String id) scopeMatcher) async {
    final all = await select(pluginModelCaches).get();
    final toDelete = all.where((e) => scopeMatcher(e.id)).toList();
    await batch((batch) {
      batch.deleteWhere(
        pluginModelCaches,
        (t) => t.id.isIn(toDelete.map((e) => e.id)),
      );
    });
  }

  Future<void> replacePluginModelsByScope(
    bool Function(String id) scopeMatcher,
    List<PluginModelCachesCompanion> rows,
  ) async {
    await transaction(() async {
      await deletePluginModelsByScope(scopeMatcher);
      await batch((batch) {
        batch.insertAllOnConflictUpdate(pluginModelCaches, rows);
      });
    });
  }

  Future<int> deleteAllPluginModels() => delete(pluginModelCaches).go();

  // --- Installed plugin cache ---

  Future<List<InstalledPluginModelCacheRow>> getAllInstalledPlugins() =>
      select(installedPluginModelCaches).get();

  Future<List<InstalledPluginModelCacheRow>> getInstalledPluginsByScope(
      bool Function(String id) scopeMatcher) async {
    final all = await select(installedPluginModelCaches).get();
    return all.where((e) => scopeMatcher(e.id)).toList();
  }

  Future<void> deleteInstalledPluginsByScope(
      bool Function(String id) scopeMatcher) async {
    final all = await select(installedPluginModelCaches).get();
    final toDelete = all.where((e) => scopeMatcher(e.id)).toList();
    await batch((batch) {
      batch.deleteWhere(
        installedPluginModelCaches,
        (t) => t.id.isIn(toDelete.map((e) => e.id)),
      );
    });
  }

  Future<void> replaceInstalledPluginsByScope(
    bool Function(String id) scopeMatcher,
    List<InstalledPluginModelCachesCompanion> rows,
  ) async {
    await transaction(() async {
      await deleteInstalledPluginsByScope(scopeMatcher);
      await batch((batch) {
        batch.insertAllOnConflictUpdate(installedPluginModelCaches, rows);
      });
    });
  }

  Future<int> deleteAllInstalledPlugins() =>
      delete(installedPluginModelCaches).go();
}
