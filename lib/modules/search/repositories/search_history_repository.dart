import 'package:get/get.dart';

import '../../../services/hive_service.dart';
import '../models/search_history.dart';

class SearchHistoryRepository extends GetxService {
  SearchHistoryRepository({int maxEntries = 30})
    : _maxEntries = maxEntries < 5 ? 5 : maxEntries;

  static const int defaultFetchLimit = 20;

  final int _maxEntries;

  List<SearchHistoryEntry> load({int limit = defaultFetchLimit}) {
    final records = Get.find<HiveService>().searchHistoryBox.values.toList();
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (limit <= 0 || records.length <= limit) {
      return records;
    }
    return records.take(limit).toList();
  }

  void save(String keyword) {
    final normalized = _normalize(keyword);
    if (normalized.isEmpty) return;

    final trimmed = keyword.trim();
    final now = DateTime.now();
    final box = Get.find<HiveService>().searchHistoryBox;

    final existing = box.get(normalized);
    final createdAt = existing?.createdAt ?? now;
    final display = existing?.keyword ?? trimmed;

    box.put(
      normalized,
      SearchHistoryEntry(
        normalized,
        trimmed.isEmpty ? display : trimmed,
        createdAt,
        now,
      ),
    );
    _trimOverflow();
  }

  void remove(String keyword) {
    final normalized = _normalize(keyword);
    if (normalized.isEmpty) return;
    Get.find<HiveService>().searchHistoryBox.delete(normalized);
  }

  void clearAll() {
    Get.find<HiveService>().searchHistoryBox.clear();
  }

  void _trimOverflow() {
    final box = Get.find<HiveService>().searchHistoryBox;
    final records = box.values.toList();
    if (records.length <= _maxEntries) return;

    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final overflow = records.skip(_maxEntries).toList();
    if (overflow.isEmpty) return;

    box.deleteAll(overflow.map((e) => e.id));
  }

  String _normalize(String keyword) => keyword.trim().toLowerCase();
}
