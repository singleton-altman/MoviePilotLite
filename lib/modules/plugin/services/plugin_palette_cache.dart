import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_palette_cache_entry.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/hive_service.dart';
import 'package:moviepilot_mobile/utils/image_cache_manager.dart';
import 'palette_extract.dart';

class PluginPaletteCache extends GetxController {
  final RxMap<String, Color> _cache = <String, Color>{}.obs;
  final Set<String> _pending = {};
  static const int _maxConcurrent = 2;
  int _activeCount = 0;
  final List<Completer<void>> _queue = [];
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
      _saveToHive(url, color);
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
  void onInit() {
    super.onInit();
    if (kIsWeb) return;
    final box = Get.find<HiveService>().pluginPaletteCacheBox;
    for (final entry in box.values) {
      _cache[entry.url] = Color(entry.colorValue);
    }
  }

  void _saveToHive(String url, Color color) {
    if (kIsWeb) return;
    Get.find<HiveService>().pluginPaletteCacheBox.put(
      url,
      PluginPaletteCacheEntry(url, color.value),
    );
  }
}
