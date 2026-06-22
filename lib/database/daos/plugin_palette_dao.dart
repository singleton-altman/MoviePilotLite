import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/plugin_palette_entries.dart';

part 'plugin_palette_dao.g.dart';

@DriftAccessor(tables: [PluginPaletteEntries])
class PluginPaletteDao extends DatabaseAccessor<AppDatabase>
    with _$PluginPaletteDaoMixin {
  PluginPaletteDao(super.db);

  Future<List<PluginPaletteEntryRow>> getAll() =>
      select(pluginPaletteEntries).get();

  Future<void> upsert(PluginPaletteEntriesCompanion row) =>
      into(pluginPaletteEntries).insertOnConflictUpdate(row);
}
