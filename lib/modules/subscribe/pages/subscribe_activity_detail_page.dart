// 订阅活动详情页：展示单轮业务活动的状态、来源、计数与明细。

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_activity_detail_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_execution_repository.dart';
import 'package:moviepilot_mobile/modules/subscribe/defines/subscribe_execution_defines.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_execution_models.dart';

class SubscribeActivityDetailPage
    extends GetView<SubscribeActivityDetailController> {
  const SubscribeActivityDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final title = Get.arguments is Map
        ? (Get.arguments as Map)['title']?.toString()
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (title == null || title.isEmpty)
              ? '活动详情'
              : title,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: controller.load,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.event.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = controller.errorText.value;
        if (error != null && controller.event.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: controller.load,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        final event = controller.event.value;
        if (event == null) {
          return const Center(child: Text('活动不存在或无权查看'));
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _HeaderCard(event: event),
              const SizedBox(height: 14),
              _CountsCard(event: event),
              if (event.details.isNotEmpty) ...[
                const SizedBox(height: 14),
                _DetailsCard(details: event.details),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: theme.hintColor),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'Menlo' : null,
                fontFamilyFallback: mono ? const ['Courier', 'monospace'] : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.event});

  final SubscriptionActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final statusColor = subscribeActivityStatusColor(event.status);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  subscribeActivityStatusLabel(event.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                subscribeActivityKindIcon(event.kind),
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Text(
                subscribeActivityKindLabel(event.kind),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: '触发来源',
            value: subscribeActivitySourceLabel(event.source),
          ),
          _InfoRow(
            label: '开始时间',
            value: subscribeActivityTimeText(event.startedAt),
          ),
          if ((event.finishedAt ?? '').isNotEmpty)
            _InfoRow(
              label: '结束时间',
              value: subscribeActivityTimeText(event.finishedAt),
            ),
        ],
      ),
    );
  }
}

class _CountsCard extends StatelessWidget {
  const _CountsCard({required this.event});

  final SubscriptionActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final entries = event.counts.entries
        .where((e) => e.value != 0)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '轮次计数',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entries
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${e.key} ${e.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.details});

  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '活动明细',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 6),
          for (final entry in details.entries) ...[
            _InfoRow(
              label: subscribeActivityDetailKeyLabel(entry.key),
              value: subscribeExecutionDetailValueText(entry.value),
              mono: entry.value is Map || entry.value is List,
            ),
          ],
        ],
      ),
    );
  }
}
