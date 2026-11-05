import 'dart:convert';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/models/update_mirror.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 自更新加速源选择与自定义线路的持久化存储。
class UpdateMirrorStore extends GetxService {
  static const String _selectedKey = 'app_update_mirror_selected';
  static const String _customKey = 'app_update_mirror_custom';

  /// 内置常用 GitHub 加速源，均支持前缀式与占位符式拼接。
  /// 顺序按实测下载速度排列，首个为默认候选。
  static const List<UpdateMirror> builtinMirrors = [
    UpdateMirror(
      id: 'gh-proxy-org',
      label: 'gh-proxy.org',
      template: 'https://gh-proxy.org/',
      builtin: true,
    ),
    UpdateMirror(
      id: 'gh-proxy',
      label: 'gh-proxy.com',
      template: 'https://gh-proxy.com/',
      builtin: true,
    ),
    UpdateMirror(
      id: 'ghfast',
      label: 'ghfast.top',
      template: 'https://ghfast.top/',
      builtin: true,
    ),
    UpdateMirror(
      id: 'ghproxy',
      label: 'ghproxy.net',
      template: 'https://ghproxy.net/',
      builtin: true,
    ),
  ];

  final selectedId = UpdateMirror.directId.obs;
  final customMirrors = <UpdateMirror>[].obs;

  SharedPreferences? _prefs;
  Future<void>? _loading;

  @override
  Future<void> onInit() async {
    super.onInit();
    await ensureLoaded();
  }

  /// 首次使用时等待偏好设置读取完成，避免读到默认值。
  Future<void> ensureLoaded() => _loading ??= load();

  Future<void> load() async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      final raw = prefs.getString(_customKey);
      customMirrors.assignAll(_decodeCustom(raw));
      final storedSelected = prefs.getString(_selectedKey);
      selectedId.value = _normalizeSelected(storedSelected);
    } catch (_) {
      selectedId.value = UpdateMirror.directId;
      customMirrors.clear();
    }
  }

  List<UpdateMirror> get allMirrors => [
    const UpdateMirror.direct(),
    ...builtinMirrors,
    ...customMirrors,
  ];

  UpdateMirror get selectedMirror {
    final id = selectedId.value;
    for (final mirror in allMirrors) {
      if (mirror.id == id) return mirror;
    }
    return const UpdateMirror.direct();
  }

  Future<void> select(String id) async {
    await ensureLoaded();
    final normalized = _normalizeSelected(id);
    selectedId.value = normalized;
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setString(_selectedKey, normalized);
    } catch (_) {}
  }

  /// 新增自定义加速源；重复地址返回 null。
  Future<UpdateMirror?> addCustom(String template, {String? label}) async {
    await ensureLoaded();
    final error = UpdateMirror.validateTemplate(template);
    if (error != null) return null;
    final normalized = UpdateMirror.normalizeTemplate(template);
    if (normalized == null) return null;
    final exists = allMirrors.any(
      (mirror) => !mirror.isDirect && mirror.template.trim() == normalized,
    );
    if (exists) return null;
    final mirror = UpdateMirror(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      label: (label?.trim().isNotEmpty ?? false)
          ? label!.trim()
          : UpdateMirror.labelFromTemplate(normalized),
      template: normalized,
    );
    customMirrors.add(mirror);
    await _persistCustom();
    await select(mirror.id);
    return mirror;
  }

  Future<void> removeCustom(String id) async {
    await ensureLoaded();
    final removed = customMirrors.any((mirror) => mirror.id == id);
    if (!removed) return;
    customMirrors.removeWhere((mirror) => mirror.id == id);
    await _persistCustom();
    if (selectedId.value == id) {
      await select(UpdateMirror.directId);
    }
  }

  Future<void> _persistCustom() async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setString(
        _customKey,
        jsonEncode(customMirrors.map((mirror) => mirror.toJson()).toList()),
      );
    } catch (_) {}
  }

  String _normalizeSelected(String? id) {
    final value = id?.trim() ?? '';
    if (value.isEmpty) return UpdateMirror.directId;
    final known = allMirrors.any((mirror) => mirror.id == value);
    return known ? value : UpdateMirror.directId;
  }

  List<UpdateMirror> _decodeCustom(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(UpdateMirror.fromJson)
          .whereType<UpdateMirror>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
