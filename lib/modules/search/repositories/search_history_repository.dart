import 'package:drift/drift.dart' hide Value;
import 'package:drift/drift.dart' as drift show Value;
import 'package:get/get.dart';

import '../../../database/app_database.dart';
import '../../../database/tables/search_history_entries.dart';
import '../../../services/database_service.dart';
import '../models/search_history.dart';

class SearchHistoryRepository extends GetxService {
  SearchHistoryRepository({int maxEntries = 30})
    : _maxEntries = maxEntries < 5 ? 5 : maxEntries;

  static const int defaultFetchLimit = 20;

  final int _maxEntries;

  AppDatabase get _db => Get.find<DatabaseService>().db;

  Future<List<SearchHistoryEntry>> load({int limit = defaultFetchLimit}) async {
    try {
      final rows = await _db.searchHistoryDao.getAll();
      final records = rows
          .map(
            (r) => SearchHistoryEntry(
              id: r.id,
              keyword: r.keyword,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ),
          )
          .toList();
      records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (limit > 0 && records.length > limit) {
        return records.take(limit).toList();
      }
      return records;
    } catch (_) {
      return [];
    }
  }

  Future<void> save(String keyword) async {
    final normalized = _normalize(keyword);
    if (normalized.isEmpty) return;

    final trimmed = keyword.trim();
    final now = DateTime.now();

    try {
      final existing = await _db.searchHistoryDao.findByPk(normalized);
      final createdAt = existing?.createdAt ?? now;
      final display = existing?.keyword ?? trimmed;

      await _db.searchHistoryDao.upsert(
        SearchHistoryEntriesCompanion(
          id: drift.Value(normalized),
          keyword: drift.Value(trimmed.isEmpty ? display : trimmed),
          createdAt: drift.Value(createdAt),
          updatedAt: drift.Value(now),
        ),
      );
      await _trimOverflow();
    } catch (_) {}
  }

  Future<void> remove(String keyword) async {
    final normalized = _normalize(keyword);
    if (normalized.isEmpty) return;
    try {
      await _db.searchHistoryDao.deleteByPk(normalized);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _db.searchHistoryDao.deleteAll();
    } catch (_) {}
  }

  Future<void> _trimOverflow() async {
    final rows = await _db.searchHistoryDao.getAll();
    if (rows.length <= _maxEntries) return;

    final sorted = rows.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final overflow = sorted.skip(_maxEntries).toList();
    if (overflow.isEmpty) return;

    for (final item in overflow) {
      await _db.searchHistoryDao.deleteByPk(item.id);
    }
  }

  String _normalize(String keyword) => keyword.trim().toLowerCase();
}
