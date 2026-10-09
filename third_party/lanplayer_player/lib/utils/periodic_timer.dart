import 'dart:async';

/// 幂等周期定时器：**已存在且仍活跃就原样返回**，否则新建一个。
///
/// 为什么需要（真机实证 2026-09-27）：`_startProgressReporting()` 由播放状态
/// 回调高频调用（宿主采样日志实测单次推送 ≈250ms）。之前进度定时器写的是
/// 无条件 `cancel + Timer.periodic(30s)` ⇒ 每次推送都把 30 秒倒计时重置 ⇒
/// 永远等不到触发 ⇒ Emby 的"继续观看"位置只有退出/拖动后才更新。UI 定时器
/// 原先手写了 `isActive` 守卫、进度定时器漏了 —— 抽成这个 helper 后，两个
/// 定时器共用同一条不变量，这类"缺守卫"的洞不会再各犯一次。
Timer ensurePeriodicTimer(Timer? existing, Duration period, void Function() onTick) =>
    (existing != null && existing.isActive)
        ? existing
        : Timer.periodic(period, (_) => onTick());
