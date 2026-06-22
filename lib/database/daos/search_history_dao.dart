import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/search_history_entries.dart';

part 'search_history_dao.g.dart';

@DriftAccessor(tables: [SearchHistoryEntries])
class SearchHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$SearchHistoryDaoMixin {
  SearchHistoryDao(super.db);

  Future<List<SearchHistoryEntryRow>> getAll() =>
      select(searchHistoryEntries).get();

  Future<SearchHistoryEntryRow?> findByPk(String id) =>
      (select(searchHistoryEntries)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsert(SearchHistoryEntriesCompanion row) =>
      into(searchHistoryEntries).insertOnConflictUpdate(row);

  Future<int> deleteByPk(String id) =>
      (delete(searchHistoryEntries)..where((t) => t.id.equals(id))).go();

  Future<int> deleteAll() => delete(searchHistoryEntries).go();
}
