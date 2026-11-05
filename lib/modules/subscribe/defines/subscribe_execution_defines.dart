// 订阅执行可观测的展示口径：kind/status/state 标签与图标。
// 文案对齐官方前端 zh-CN 的 subscriptionActivity / execution 词条。

import 'package:flutter/cupertino.dart';

// 服务端 activity kind 白名单（含前端展示顺序）
const List<String> kSubscribeActivityKinds = <String>[
  'refresh',
  'search',
  'created',
  'updated',
  'status',
  'completed',
];

String subscribeActivityKindLabel(String kind) => switch (kind) {
  'refresh' => '刷新匹配',
  'search' => '订阅搜索',
  'created' => '新建订阅',
  'updated' => '更新订阅规则',
  'status' => '订阅状态变更',
  'completed' => '订阅完成',
  _ => kind.isEmpty ? '未知活动' : kind,
};

String subscribeActivityStatusLabel(String status) => switch (status) {
  'queued' => '已安排搜索',
  'not_submitted' => '未提交新下载',
  'running' => '正在处理',
  'waiting' => '等待继续',
  'failed' => '处理失败',
  'cancelled' => '已停止',
  'completed' => '处理完成',
  'empty' => '无可下载资源',
  _ => status.isEmpty ? '未知状态' : status,
};

/// 运行/等待中的状态用警示色，失败用错误色，正常结束用成功色
Color subscribeActivityStatusColor(String status) => switch (status) {
  'running' || 'waiting' || 'queued' => const Color(0xFFF59E0B),
  'failed' => const Color(0xFFEF4444),
  'completed' || 'not_submitted' || 'empty' => const Color(0xFF16A34A),
  'cancelled' => const Color(0xFF0284C7),
  _ => const Color(0xFF0284C7),
};

IconData subscribeActivityKindIcon(String kind) => switch (kind) {
  'refresh' => CupertinoIcons.arrow_2_circlepath,
  'search' => CupertinoIcons.search,
  'created' => CupertinoIcons.add_circled,
  'updated' => CupertinoIcons.gear,
  'status' => CupertinoIcons.pause_circle,
  'completed' => CupertinoIcons.check_mark_circled,
  _ => CupertinoIcons.clock,
};

String subscribeExecutionStateLabel(String state) => switch (state) {
  'queued' => '排队中',
  'scheduled' => '待搜索',
  'running' => '处理中',
  'matching' => '准备中',
  'searching' => '搜索中',
  'waiting_subscription' => '等待任务',
  'waiting_site_budget' => '稍后继续',
  'preparing' => '待下载',
  'submitting' => '提交中',
  'skipped' => '已跳过',
  'failed' => '搜索失败',
  'cancelling' => '停止中',
  'cancelled' => '已停止',
  'completed' => '搜索完成',
  _ => state.isEmpty ? '未知状态' : state,
};

String subscribeActivitySourceLabel(String source) {
  final normalized = source.trim().toLowerCase();
  if (normalized == 'user') return '用户触发';
  if (normalized == 'automatic') return '自动触发';
  return source.isEmpty ? '未知来源' : source;
}

/// 活动概要计数行：刷新/搜索展示轮次口径，其余活动展示提交计数
String subscribeActivityCountsSummary(
  String kind,
  Map<String, int> counts,
) {
  int of(String key) => counts[key] ?? 0;
  switch (kind) {
    case 'refresh':
      if (of('sites') == 0 && of('related') == 0 && of('submitted') == 0) {
        return '';
      }
      return '来源 ${of('sites')} · 相关 ${of('related')} · 提交 ${of('submitted')}';
    case 'search':
      if (of('requested_sites') == 0 &&
          of('sites') == 0 &&
          of('discovered') == 0 &&
          of('submitted') == 0) {
        return '';
      }
      return '站点 ${of('requested_sites')}/${of('sites')} · 发现 ${of('discovered')} · 符合 ${of('qualified')} · 提交 ${of('submitted')}';
    default:
      if (of('submitted') > 0) return '提交下载 ${of('submitted')} 项';
      return '';
  }
}

/// 活动明细键的中文标签；未收录的键原样展示
String subscribeActivityDetailKeyLabel(String key) => switch (key) {
  'reason' => '原因',
  'retry_at' => '自动重试时间',
  'phase' => '阶段',
  'changes' => '变更内容',
  'rules' => '订阅条件快照',
  'resources' => '相关资源',
  _ => key,
};

/// 活动发生时刻的展示文本（本地时区，到分钟）
String subscribeActivityTimeText(String? isoText) {
  if (isoText == null || isoText.isEmpty) return '';
  final dt = DateTime.tryParse(isoText);
  if (dt == null) return isoText;
  final local = dt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
