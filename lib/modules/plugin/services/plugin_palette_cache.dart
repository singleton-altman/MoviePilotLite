import 'dart:async';

import 'package:drift/drift.dart' hide Value;
import 'package:drift/drift.dart' as drift show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/database/app_database.dart';
import 'package:moviepilot_mobile/database/tables/plugin_palette_entries.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/database_service.dart';
import 'package:moviepilot_mobile/utils/image_cache_manager.dart';
import 'palette_extract.dart';

class PluginPaletteCache extends GetxController {
  AppDatabase get _db => Get.find<DatabaseService>().db;

  /// Cache: iconUrl -> palette color
  final RxMap<String, Color> _cache = <String, Color>{}.obs;

  /// URLs currently being extracted
  final Set<String> _pending = {};

  /// Max concurrent extractions
  static const int _maxConcurrent = 2;
  int _activeCount = 0;
  final List<Completer<void>> _queue = [];

  /// Default color (fallback)
  static Color defaultColor = Colors.amberAccent;

  Color? getCached(String iconUrl) {
    if (iconUrl.isEmpty) return null;
    return _cache[iconUrl];
  }

  Color? watchColor(String iconUrl) {
    if (iconUrl.isEmpty) return null;
    final cached = _cache[iconUrl];
    if (cached != null) return cached;
    _fetchOne(iconUrl);
    return null;
  }

  void preload(Iterable<String> urls) {
    for (final url in urls) {
      if (url.isEmpty) continue;
      if (_cache.containsKey(url)) continue;
      if (_pending.contains(url)) continue;
      _fetchOne(url);
    }
  }

  Future<void> _fetchOne(String url) async {
    if (_cache.containsKey(url) || _pending.contains(url)) return;
    _pending.add(url);

    while (_activeCount >= _maxConcurrent && _queue.isNotEmpty) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }
    _activeCount++;

    try {
      if (kIsWeb) {
        _cache[url] = defaultColor;
        return;
      }
      final headers = <String, String>{};
      final imageCookie = Get.find<AppService>().cookie;
      if (imageCookie != null && imageCookie.isNotEmpty) {
        headers['cookie'] = imageCookie;
      }
      final file = await AppImageCacheManager.instance.getSingleFile(
        url,
        headers: headers,
      );
      final color = await extractPaletteFromCachedFile(file, defaultColor);
      _cache[url] = color;
      await _saveToDb(url, color);
    } catch (error) {
      _cache[url] = defaultColor;
    } finally {
      _pending.remove(url);
      _activeCount--;
      if (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        if (!next.isCompleted) next.complete();
      }
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    if (kIsWeb) return;
    try {
      final entries = await _db.pluginPaletteDao.getAll();
      for (final entry in entries) {
        _cache[entry.url] = Color(entry.colorValue);
      }
    } catch (_) {}
  }

  Future<void> _saveToDb(String url, Color color) async {
    if (kIsWeb) return;
    try {
      await _db.pluginPaletteDao.upsert(
        PluginPaletteEntriesCompanion(
          url: drift.Value(url),
          colorValue: drift.Value(color.value),
        ),
      );
    } catch (_) {}
  }
}
