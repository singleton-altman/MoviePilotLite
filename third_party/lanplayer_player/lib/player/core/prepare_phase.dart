/// 进入播放的准备阶段 —— 播放页加载层据此显示**真实**阶段文案。
///
/// 背景：原盘 ISO 从点播到出画约 3 秒（ISO 解析 1.2s + mpv 启动/解复用探测
/// 1.8s）。这段等待原先发生在详情页、零反馈，是"打开慢"的主要观感来源。
/// 现在入口立刻跳转，播放页自己解析并逐阶段提示进度。
enum PreparePhase {
  /// 向服务端要流地址（普通文件）
  resolving,

  /// 解析原盘 ISO（libudfread 开卷 + 定位正片，1~3 秒）
  openingIso,

  /// 启动播放内核（创建 mpv/Exo 并加载流）
  startingEngine,

  /// 内核已起，等缓冲出画
  buffering,
}

/// 普通文件的加载层延时阈值：**低于它就完全不显示**。
///
/// 普通文件本来就"点击就能打开"（解析只是一次 API 往返），若立刻显示转圈会
/// 凭空多出一次闪烁 —— 只有真要等几秒的场景才看得到动画。
const Duration kPrepareOverlayDelay = Duration(milliseconds: 400);

/// 进入某阶段后，加载层要多久才浮现。
///
/// 原盘 ISO **立刻显示**：它必然要解析 1~3 秒，先黑屏 400ms 再突然转圈反而更顿；
/// 普通文件走 400ms 延时，快路径保持零闪烁。
Duration prepareOverlayDelay(PreparePhase phase) {
  return phase == PreparePhase.openingIso
      ? Duration.zero
      : kPrepareOverlayDelay;
}

/// 准备阶段 → 阶段名（**只进日志**，界面上不显示文字，用户只要一个动画）。
String preparePhaseLabel(PreparePhase phase) {
  switch (phase) {
    case PreparePhase.resolving:
      return '正在连接服务端…';
    case PreparePhase.openingIso:
      return '正在解析原盘…';
    case PreparePhase.startingEngine:
      return '正在启动播放内核…';
    case PreparePhase.buffering:
      return '正在缓冲…';
  }
}
