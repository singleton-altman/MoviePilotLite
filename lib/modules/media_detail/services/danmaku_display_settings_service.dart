import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/danmaku_display_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 弹幕显示配置的本地持久化服务。
///
/// 详情页弹幕和后续播放器弹幕渲染都应从这里读取同一份配置。
class DanmakuDisplaySettingsService extends GetxService {
  static const _prefsKey = 'danmaku_display_settings_v1';

  final settings = DanmakuDisplaySettings.defaults.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        settings.value = DanmakuDisplaySettings.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      // 配置损坏时保留默认值，不阻塞详情页。
    }
  }

  /// 拖动滑块时先更新内存，避免每一帧都写磁盘。
  void preview(DanmakuDisplaySettings value) {
    settings.value = value;
  }

  Future<void> persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(settings.value.toJson()));
    } catch (_) {
      // 持久化失败不影响当前会话内的展示。
    }
  }

  Future<void> update(DanmakuDisplaySettings value) async {
    preview(value);
    await persist();
  }

  Future<void> reset() => update(DanmakuDisplaySettings.defaults);
}
