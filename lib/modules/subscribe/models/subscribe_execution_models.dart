// 订阅执行可观测数据模型。
//
// 对齐 v3 服务端 app/schemas/subscribe.py：
// SubscriptionActivityEvent / SubscriptionActivityPage / SubscriptionBatchStatus。
// 响应经统一信封拆包后到达，这里消费的是拆包后的业务数据。

class SubscriptionActivityEvent {
  const SubscriptionActivityEvent({
    required this.eventId,
    required this.kind,
    required this.source,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.counts = const {},
    this.details = const {},
    this.detailsLoaded = true,
  });

  final String eventId;

  /// 订阅业务活动类型：created|updated|status|completed|refresh|search
  final String kind;

  /// 触发该业务活动的入口或来源
  final String source;

  /// 本轮业务活动的运行或结束状态，独立于订阅是否启用
  final String status;

  final String startedAt;
  final String? finishedAt;

  /// 活动涉及的分类计数（sites/discovered/related/submitted 等）
  final Map<String, int> counts;

  /// 活动明细；列表接口仅保留 reason/retry_at/phase/changes 等轻量摘要
  final Map<String, dynamic> details;

  /// 是否已加载完整明细；false 时可按需请求活动详情
  final bool detailsLoaded;

  factory SubscriptionActivityEvent.fromJson(Map<String, dynamic> json) {
    return SubscriptionActivityEvent(
      eventId: json['event_id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startedAt: json['started_at']?.toString() ?? '',
      finishedAt: json['finished_at']?.toString(),
      counts: _intMap(json['counts']),
      details: _jsonMap(json['details']),
      detailsLoaded: json['details_loaded'] is bool
          ? json['details_loaded'] as bool
          : true,
    );
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, int>{};
    raw.forEach((key, value) {
      final v = value is int ? value : int.tryParse('$value');
      if (v != null) out[key.toString()] = v;
    });
    return out;
  }

  static Map<String, dynamic> _jsonMap(dynamic raw) {
    if (raw is! Map) return const {};
    return Map<String, dynamic>.from(raw);
  }

  int? countOf(String key) => counts[key];
}

/// 活动游标分页；next_cursor 为空表示没有后续记录
class SubscriptionActivityPage {
  const SubscriptionActivityPage({
    this.items = const [],
    this.nextCursor,
  });

  final List<SubscriptionActivityEvent> items;
  final String? nextCursor;

  factory SubscriptionActivityPage.fromJson(dynamic raw) {
    if (raw is! Map) return const SubscriptionActivityPage();
    final itemsRaw = raw['items'];
    final items = <SubscriptionActivityEvent>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map) {
          items.add(
            SubscriptionActivityEvent.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }
    final cursor = raw['next_cursor']?.toString();
    return SubscriptionActivityPage(
      items: items,
      nextCursor: (cursor == null || cursor.isEmpty || cursor == 'null')
          ? null
          : cursor,
    );
  }
}

/// 订阅搜索批次状态（GET /subscribe/execution/batches）。
class SubscriptionBatchStatus {
  const SubscriptionBatchStatus({
    required this.batchId,
    required this.source,
    required this.state,
    required this.phase,
    required this.totalCount,
    required this.processedCount,
    required this.finishedCount,
    required this.failedCount,
    required this.cancelledCount,
    required this.createdAt,
    required this.updatedAt,
    this.downloadCounts = const {},
    this.downloads = const [],
    this.downloadsOmitted = 0,
    this.skippedCount = 0,
    this.currentSubscriptionId,
    this.currentSiteId,
    this.error,
    this.canCancel = false,
  });

  final String batchId;
  final String source;
  final String state;
  final String phase;
  final int totalCount;
  final int processedCount;
  final int finishedCount;
  final int failedCount;
  final int cancelledCount;
  final String createdAt;
  final String updatedAt;

  /// 成功下载分类计数：submitted/initial_submitted/upgrade_submitted/full_upgrade_submitted
  final Map<String, int> downloadCounts;
  final List<Map<String, dynamic>> downloads;
  final int downloadsOmitted;
  final int skippedCount;
  final int? currentSubscriptionId;
  final int? currentSiteId;
  final String? error;
  final bool canCancel;

  /// 服务端活跃批次状态集合（app/application/subscription/status.py _ACTIVE_STATES）
  static const activeStates = <String>{
    'queued',
    'running',
    'matching',
    'searching',
    'scheduled',
    'waiting_subscription',
    'waiting_site_budget',
    'preparing',
    'submitting',
    'cancelling',
  };

  bool get isActive => activeStates.contains(state);

  int get submittedCount => downloadCounts['submitted'] ?? 0;

  factory SubscriptionBatchStatus.fromJson(Map<String, dynamic> json) {
    final downloads = <Map<String, dynamic>>[];
    final downloadsRaw = json['downloads'];
    if (downloadsRaw is List) {
      for (final item in downloadsRaw) {
        if (item is Map) {
          downloads.add(Map<String, dynamic>.from(item));
        }
      }
    }
    int intOf(String key, [int fallback = 0]) {
      final value = json[key];
      return value is int ? value : int.tryParse('${value ?? ''}') ?? fallback;
    }

    return SubscriptionBatchStatus(
      batchId: json['batch_id']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      phase: json['phase']?.toString() ?? '',
      totalCount: intOf('total_count'),
      processedCount: intOf('processed_count'),
      finishedCount: intOf('finished_count'),
      failedCount: intOf('failed_count'),
      cancelledCount: intOf('cancelled_count'),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      downloadCounts: SubscriptionActivityEvent._intMap(json['download_counts']),
      downloads: downloads,
      downloadsOmitted: intOf('downloads_omitted'),
      skippedCount: intOf('skipped_count'),
      currentSubscriptionId: json['current_subscription_id'] is int
          ? json['current_subscription_id'] as int
          : int.tryParse('${json['current_subscription_id']}'),
      currentSiteId: json['current_site_id'] is int
          ? json['current_site_id'] as int
          : int.tryParse('${json['current_site_id']}'),
      error: json['error']?.toString(),
      canCancel: json['can_cancel'] == true,
    );
  }
}
