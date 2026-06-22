import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchKeywordHintsService extends GetxService {
  static const _prefsKey = 'search_media_title_hints_v1';
  static const _maxHints = 500;

  final RxList<String> hints = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _reloadFromDisk();
  }

  Future<void> _reloadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        hints.clear();
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        hints.clear();
        return;
      }
      final list = decoded.whereType<String>().toList();
      hints.assignAll(list);
    } catch (_) {
      hints.clear();
    }
  }

  static Iterable<String> _titlesFromItem(RecommendApiItem item) sync* {
    for (final s in [
      item.title,
      item.en_title,
      item.original_title,
      item.original_name,
      item.title_year,
    ]) {
      if (s == null) continue;
      final t = s.trim();
      if (t.isNotEmpty) yield t;
    }
  }

  Future<void> ingestFromItems(Iterable<RecommendApiItem> items) async {
    final batch = <String>{};
    for (final i in items) {
      for (final t in _titlesFromItem(i)) {
        if (t.length >= 2 && t.length <= 120) batch.add(t);
      }
    }
    if (batch.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      var existing = <String>[];
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          existing = decoded.whereType<String>().toList();
        }
      }
      final seen = existing.map((e) => e.toLowerCase()).toSet();
      final merged = <String>[];
      for (final t in batch) {
        final k = t.toLowerCase();
        if (seen.add(k)) merged.add(t);
      }
      merged.addAll(existing);
      if (merged.length > _maxHints) {
        merged.removeRange(_maxHints, merged.length);
      }
      await prefs.setString(_prefsKey, jsonEncode(merged));
      hints.assignAll(merged);
    } catch (_) {}
  }
}
