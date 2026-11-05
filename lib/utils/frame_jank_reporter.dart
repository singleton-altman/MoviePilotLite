import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';

/// 开发期诊断：把超过阈值的慢帧连同所在路由记进日志，并拆开 build（Dart 主线程）
/// 与 raster（GPU 线程）两段耗时，用来判断「假死」卡在哪一侧。
///
/// 只在非 release 构建安装；release 下不注册回调，没有任何开销。
class FrameJankReporter {
  FrameJankReporter._();

  /// 单帧 build 或 raster 任一超过该值即记录。60fps 预算是 16ms，
  /// 100ms 以上已经是肉眼可见的卡顿，几百毫秒以上就是用户说的假死。
  static const Duration _threshold = Duration(milliseconds: 100);

  static bool _installed = false;

  static void install() {
    if (kReleaseMode || _installed) return;
    _installed = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> timings) {
    if (!Get.isRegistered<AppLog>()) return;
    final log = Get.find<AppLog>();
    for (final timing in timings) {
      final build = timing.buildDuration;
      final raster = timing.rasterDuration;
      if (build < _threshold && raster < _threshold) continue;
      final side = build >= raster ? 'Dart 主线程(build)' : 'GPU 线程(raster)';
      log.warning(
        '慢帧 ${timing.totalSpan.inMilliseconds}ms '
        '[build ${build.inMilliseconds}ms / raster ${raster.inMilliseconds}ms] '
        '主要在 $side，路由 ${Get.currentRoute}',
      );
    }
  }
}
