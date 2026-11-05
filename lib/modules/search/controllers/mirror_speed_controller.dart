import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/models/update_mirror.dart';
import 'package:moviepilot_mobile/modules/search/services/update_speed_tester.dart';

/// 下载线路测速的共享状态。
///
/// 更新弹框内联的线路选择与完整的线路管理面板共用同一份结果，
/// 用户在任一处测过速，另一处打开时仍然可见。
class MirrorSpeedController extends GetxController {
  final results = <String, MirrorSpeedResult>{}.obs;
  final testing = <String>{}.obs;
  final testingAll = false.obs;

  UpdateSpeedTester get _tester => Get.isRegistered<UpdateSpeedTester>()
      ? Get.find<UpdateSpeedTester>()
      : Get.put(UpdateSpeedTester(), permanent: true);

  bool isTesting(String mirrorId) => testing.contains(mirrorId);

  MirrorSpeedResult? resultFor(String mirrorId) => results[mirrorId];

  Future<void> testOne(
    UpdateMirror mirror, {
    required String sourceUrl,
  }) async {
    if (testing.contains(mirror.id)) return;
    testing.add(mirror.id);
    results.remove(mirror.id);
    try {
      final result = await _tester.test(mirror, sourceUrl: sourceUrl);
      results[mirror.id] = result;
    } finally {
      testing.remove(mirror.id);
    }
  }

  Future<void> testAll(
    List<UpdateMirror> mirrors, {
    required String sourceUrl,
  }) async {
    if (testingAll.value) return;
    testingAll.value = true;
    testing.addAll(mirrors.map((mirror) => mirror.id));
    for (final mirror in mirrors) {
      results.remove(mirror.id);
    }
    try {
      final measured = await _tester.testAll(mirrors, sourceUrl: sourceUrl);
      results.addAll(measured);
    } finally {
      testing.clear();
      testingAll.value = false;
    }
  }

  /// 已测线路中比当前选择更快的那条，用于「当前最快」提示。
  UpdateMirror? fastest(
    List<UpdateMirror> mirrors, {
    required String selectedId,
  }) {
    final successful = results.values.where((result) => result.ok).toList();
    if (successful.length < 2) return null;
    successful.sort((a, b) => b.bytesPerSecond.compareTo(a.bytesPerSecond));
    final best = successful.first;
    if (best.mirrorId == selectedId) return null;
    for (final mirror in mirrors) {
      if (mirror.id == best.mirrorId) return mirror;
    }
    return null;
  }

  String? fastestHint(
    List<UpdateMirror> mirrors, {
    required String selectedId,
  }) {
    final mirror = fastest(mirrors, selectedId: selectedId);
    if (mirror == null) return null;
    final speed = results[mirror.id]?.displaySpeed ?? '';
    return '当前最快：${mirror.label}（$speed）';
  }
}
