import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:realm/realm.dart';

import '../../../services/realm_service.dart';
import '../models/search_history.dart';

class SearchHistoryRepository extends GetxService {
  SearchHistoryRepository({int maxEntries = 30})
    : _maxEntries = maxEntries < 5 ? 5 : maxEntries;

  static const int defaultFetchLimit = 20;

  final int _maxEntries;
  final List<SearchHistoryEntry> _webEntries = [];

  Realm get _realm => Get.find<RealmService>().realm;

  List<SearchHistoryEntry> load({int limit = defaultFetchLimit}) {
    if (kIsWeb) {
      final records = List<SearchHistoryEntry>.from(_webEntries);
      records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (limit <= 0 || records.length <= limit) {
        return records;
      }
      return records.take(limit).toList();
    }
    final records = _realm.all<SearchHistoryEntry>().toList();
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

    if (kIsWeb) {
      final idx = _webEntries.indexWhere((e) => e.id == normalized);
      final createdAt =
          idx >= 0 ? _webEntries[idx].createdAt : now;
      final display =
          idx >= 0 ? _webEntries[idx].keyword : trimmed;
      if (idx >= 0) {
        _webEntries.removeAt(idx);
      }
      _webEntries.add(
        SearchHistoryEntry(
          normalized,
          trimmed.isEmpty ? display : trimmed,
          createdAt,
          now,
        ),
      );
      _trimOverflowWeb();
      return;
    }

    _realm.write(() {
      final existing = _realm.find<SearchHistoryEntry>(normalized);
      final createdAt = existing?.createdAt ?? now;
      final display = existing?.keyword ?? trimmed;

      _realm.add(
        SearchHistoryEntry(
          normalized,
          trimmed.isEmpty ? display : trimmed,
          createdAt,
          now,
        ),
        update: true,
      );
      _trimOverflow();
    });
  }

  void remove(String keyword) {
    final normalized = _normalize(keyword);
    if (normalized.isEmpty) return;

    if (kIsWeb) {
      _webEntries.removeWhere((e) => e.id == normalized);
      return;
    }

    final record = _realm.find<SearchHistoryEntry>(normalized);
    if (record == null) return;
    _realm.write(() {
      _realm.delete(record);
    });
  }

  void clearAll() {
    if (kIsWeb) {
      _webEntries.clear();
      return;
    }
    final records = _realm.all<SearchHistoryEntry>();
    if (records.isEmpty) return;
    _realm.write(() {
      _realm.deleteMany(records);
    });
  }

  void _trimOverflowWeb() {
    if (_webEntries.length <= _maxEntries) return;
    _webEntries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final overflow = _webEntries.length - _maxEntries;
    if (overflow <= 0) return;
    _webEntries.removeRange(_maxEntries, _webEntries.length);
  }

  void _trimOverflow() {
    final records = _realm.all<SearchHistoryEntry>().toList();
    if (records.length <= _maxEntries) return;

    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final overflow = records.skip(_maxEntries);
    if (overflow.isEmpty) return;

    _realm.write(() {
      for (final item in overflow) {
        _realm.delete(item);
      }
    });
  }

  String _normalize(String keyword) => keyword.trim().toLowerCase();
}
