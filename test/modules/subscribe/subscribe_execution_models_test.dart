import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/subscribe/defines/subscribe_execution_defines.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_execution_models.dart';

void main() {
  group('SubscriptionActivityEvent', () {
    test('按 v3 活动列表（概要）契约解析字段', () {
      // 列表接口的条目：details 仅保留 reason/retry_at/phase/changes，details_loaded=false
      final event = SubscriptionActivityEvent.fromJson(<String, dynamic>{
        'event_id': 'evt-abc_123',
        'kind': 'search',
        'source': 'user',
        'status': 'completed',
        'started_at': '2026-10-21T08:30:00.000+08:00',
        'finished_at': '2026-10-21T08:32:10.000+08:00',
        'counts': {
          'requested_sites': 4,
          'sites': 4,
          'discovered': 30,
          'qualified': 2,
          'submitted': 1,
        },
        'details': {'reason': '命中订阅规则', 'phase': 'submitting'},
        'details_loaded': false,
      });

      expect(event.eventId, 'evt-abc_123');
      expect(event.kind, 'search');
      expect(event.source, 'user');
      expect(event.status, 'completed');
      expect(event.startedAt, '2026-10-21T08:30:00.000+08:00');
      expect(event.finishedAt, '2026-10-21T08:32:10.000+08:00');
      expect(event.counts['submitted'], 1);
      expect(event.counts['requested_sites'], 4);
      expect(event.details['reason'], '命中订阅规则');
      expect(event.detailsLoaded, isFalse);
      expect(event.countOf('qualified'), 2);
    });

    test('活动详情（完整明细）契约：details_loaded 缺省为 true', () {
      final event = SubscriptionActivityEvent.fromJson(<String, dynamic>{
        'event_id': 'evt-1',
        'kind': 'refresh',
        'source': 'automatic',
        'status': 'waiting',
        'started_at': '2026-10-21T08:00:00.000Z',
        'finished_at': null,
        'counts': <String, int>{},
        'details': {
          'resources': [
            {'title': '示例资源', 'site': '示例站'},
          ],
          'rules': {'resolution': '1080p'},
        },
      });

      expect(event.finishedAt, isNull);
      expect(event.detailsLoaded, isTrue);
      expect(event.counts, isEmpty);
      final resources = event.details['resources'] as List;
      expect((resources.first as Map)['title'], '示例资源');
    });

    test('异常形态容错：非 Map 输入不抛出', () {
      final event = SubscriptionActivityEvent.fromJson(<String, dynamic>{
        'event_id': 12,
        'counts': 'not-a-map',
        'details': null,
      });
      expect(event.eventId, '12');
      expect(event.counts, isEmpty);
      expect(event.details, isEmpty);
    });
  });

  group('SubscriptionActivityPage', () {
    test('解析 items 与 next_cursor 游标分页', () {
      final page = SubscriptionActivityPage.fromJson(<String, dynamic>{
        'items': [
          {'event_id': 'a', 'kind': 'search', 'status': 'completed'},
          {'event_id': 'b', 'kind': 'refresh', 'status': 'waiting'},
        ],
        'next_cursor': 'c1',
      });
      expect(page.items.length, 2);
      expect(page.items.first.eventId, 'a');
      expect(page.nextCursor, 'c1');
    });

    test('next_cursor 为空时没有后续页', () {
      final page = SubscriptionActivityPage.fromJson(<String, dynamic>{
        'items': <Object>[],
        'next_cursor': null,
      });
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test('信封拆包后为 null 或非法形态时返回空页', () {
      expect(SubscriptionActivityPage.fromJson(null).items, isEmpty);
      expect(SubscriptionActivityPage.fromJson('bad').nextCursor, isNull);
    });
  });

  group('SubscriptionBatchStatus', () {
    test('按 v3 批次状态契约解析全部字段', () {
      final batch = SubscriptionBatchStatus.fromJson(<String, dynamic>{
        'batch_id': 'batch-9',
        'source': 'automatic',
        'state': 'running',
        'phase': 'searching',
        'total_count': 8,
        'processed_count': 3,
        'finished_count': 2,
        'failed_count': 1,
        'cancelled_count': 0,
        'created_at': '2026-10-21T08:00:00.000Z',
        'updated_at': '2026-10-21T08:05:00.000Z',
        'download_counts': {
          'submitted': 4,
          'initial_submitted': 3,
          'upgrade_submitted': 1,
          'full_upgrade_submitted': 0,
        },
        'downloads': [
          {'title': '资源A', 'subscription_download': 'initial'},
        ],
        'downloads_omitted': 0,
        'skipped_count': 2,
        'current_subscription_id': 77,
        'current_site_id': 5,
        'error': null,
        'can_cancel': true,
      });

      expect(batch.batchId, 'batch-9');
      expect(batch.state, 'running');
      expect(batch.phase, 'searching');
      expect(batch.totalCount, 8);
      expect(batch.processedCount, 3);
      expect(batch.finishedCount, 2);
      expect(batch.failedCount, 1);
      expect(batch.cancelledCount, 0);
      expect(batch.skippedCount, 2);
      expect(batch.submittedCount, 4);
      expect(batch.downloads.single['title'], '资源A');
      expect(batch.downloadsOmitted, 0);
      expect(batch.currentSubscriptionId, 77);
      expect(batch.currentSiteId, 5);
      expect(batch.error, isNull);
      expect(batch.canCancel, isTrue);
      expect(batch.isActive, isTrue);
    });

    test('终态批次不是活跃批次', () {
      for (final state in ['completed', 'failed', 'cancelled', 'skipped']) {
        final batch = SubscriptionBatchStatus.fromJson(<String, dynamic>{
          'batch_id': 'b',
          'source': 'user',
          'state': state,
          'phase': state,
          'total_count': 0,
          'processed_count': 0,
          'finished_count': 0,
          'failed_count': 0,
          'cancelled_count': 0,
          'created_at': '',
          'updated_at': '',
        });
        expect(batch.isActive, isFalse, reason: '$state 应为终态');
      }
    });

    test('数字字段容错：字符串数字可解析', () {
      final batch = SubscriptionBatchStatus.fromJson(<String, dynamic>{
        'batch_id': 'b',
        'total_count': '12',
        'processed_count': '3',
      });
      expect(batch.totalCount, 12);
      expect(batch.processedCount, 3);
    });
  });

  group('展示口径', () {
    test('kind 标签覆盖服务端白名单', () {
      expect(subscribeActivityKindLabel('refresh'), '刷新匹配');
      expect(subscribeActivityKindLabel('search'), '订阅搜索');
      expect(subscribeActivityKindLabel('created'), '新建订阅');
      expect(subscribeActivityKindLabel('updated'), '更新订阅规则');
      expect(subscribeActivityKindLabel('status'), '订阅状态变更');
      expect(subscribeActivityKindLabel('completed'), '订阅完成');
      expect(subscribeActivityKindLabel('other'), 'other');
    });

    test('搜索轮次计数行按前端口径拼接', () {
      final summary = subscribeActivityCountsSummary('search', {
        'requested_sites': 4,
        'sites': 4,
        'discovered': 30,
        'qualified': 2,
        'submitted': 1,
      });
      expect(summary, '站点 4/4 · 发现 30 · 符合 2 · 提交 1');
      expect(subscribeActivityCountsSummary('search', {}), isEmpty);
      expect(
        subscribeActivityCountsSummary('refresh', {'sites': 3, 'submitted': 1}),
        contains('来源 3'),
      );
    });

    test('时间文本本地化为到分钟', () {
      final text = subscribeActivityTimeText('2026-10-21T08:30:00.000Z');
      expect(text, matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$')));
      expect(subscribeActivityTimeText(null), isEmpty);
      expect(subscribeActivityTimeText(''), isEmpty);
    });
  });
}
