import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_palette_cache_entry.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/realm_service.dart';
import 'package:moviepilot_mobile/utils/image_cache_manager.dart';
import 'palette_extract.dart';
import 'package:realm/realm.dart';

class PluginPaletteCache extends GetxController {
  Realm get _realm => Get.find<RealmService>().realm;

  /// 缓存：iconUrl -> 主题色
  final RxMap<String, Color> _cache = <String, Color>{}.obs;

  /// 正在提取中的 URL，避免重复请求
  final Set<String> _pending = {};

  /// 最大并发提取数（控制 CPU 占用，避免卡顿）
  static const int _maxConcurrent = 2;
  int _activeCount = 0;
  final List<Completer<void>> _queue = [];

  /// 默认色（提取失败或空 URL 时使用）
  static Color defaultColor = Colors.amberAccent;

  /// 获取已缓存的主题色，若无则返回 null
  Color? getCached(String iconUrl) {
    if (iconUrl.isEmpty) return null;
    return _cache[iconUrl];
  }

  /// 供 Obx 使用：读取颜色并触发提取，提取完成后触发重建
  Color? watchColor(String iconUrl) {
    if (iconUrl.isEmpty) return null;
    final cached = _cache[iconUrl];
    if (cached != null) return cached;
    _fetchOne(iconUrl);
    return null;
  }

  /// 批量预加载：在后台提取尚未缓存的 URL
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
      // 获取cookie，如果没有提供则从AppService获取
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
      _saveToRealm(url, color);
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
    for (final entry in _realm.all<PluginPaletteCacheEntry>()) {
      _cache[entry.url] = Color(entry.colorValue);
    }
  }

  void _saveToRealm(String url, Color color) {
    if (kIsWeb) return;
    _realm.write(() {
      _realm.add(PluginPaletteCacheEntry(url, color.value), update: true);
    });
  }
}
