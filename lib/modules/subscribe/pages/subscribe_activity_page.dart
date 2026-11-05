// 订阅活动记录页：kind 内联筛选、history 开关、下拉刷新/加载更多与进行中批次横幅。

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_activity_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/defines/subscribe_execution_defines.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_execution_models.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';

class SubscribeActivityPage extends GetView<SubscribeActivityController> {
  const SubscribeActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('活动记录'),
        centerTitle: false,
        actions: [
          Obx(() {
            if (!controller.isLoading.value) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (!controller.v3Supported.value) {
          return _UnsupportedBody();
        }
        return Column(
          children: [
            Obx(_buildBatchBanner),
            _buildFilterBar(context),
            Expanded(child: _buildList(context)),
          ],
        );
      }),
    );
  }

  /// 进行中搜索批次横幅：展示轮次进度，可取消时提供停止入口
  Widget _buildBatchBanner() {
    final batch = controller.batch.value;
    if (batch == null) return const SizedBox.shrink();
    final color = const Color(0xFF0EA5E9);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '订阅搜索 ${subscribeExecutionStateLabel(batch.phase)} · '
              '${batch.processedCount}/${batch.totalCount}'
              '${batch.submittedCount > 0 ? ' · 已提交 ${batch.submittedCount}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (batch.canCancel)
            TextButton(
              onPressed: controller.cancellingBatch.value
                  ? null
                  : controller.cancelRunningBatch,
              child: Text(
                controller.cancellingBatch.value ? '停止中' : '停止',
                style: TextStyle(fontSize: 13, color: color),
              ),
            ),
        ],
      ),
    );
  }

  /// 内联筛选行：kind 选择 chips + history 开关，随列表同屏滚动区域固定在顶部
  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: Obx(() {
                final current = controller.kind.value;
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _kindChip(label: '全部事件', value: null, current: current),
                    for (final k in kSubscribeActivityKinds)
                      _kindChip(
                        label: subscribeActivityKindLabel(k),
                        value: k,
                        current: current,
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(width: 8),
            Obx(
              () => FilterChip(
                label: const Text('含已完成'),
                selected: controller.history.value,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onSelected: (_) => controller.toggleHistory(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindChip({
    required String label,
    required String? value,
    required String? current,
  }) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        onSelected: (_) => controller.setKind(value),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await controller.reload();
        await controller.loadBatch();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverContent(context),
          Obx(() {
            return SliverToBoxAdapter(
              child: LoadMoreFooter(
                hasMore: controller.hasMore,
                isLoading: controller.isLoadingMore.value,
                hasItems: controller.items.isNotEmpty,
                onLoadMore: controller.loadMore,
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSliverContent(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final error = controller.errorText.value;
      final items = controller.items;
      if (loading && items.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (error != null && items.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: controller.reload,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (items.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('当前范围内还没有订阅活动')),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final event = items[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index < items.length - 1 ? 10 : 0),
              child: _ActivityTile(
                event: event,
                history: controller.history.value,
                subscribeId: controller.subscribeId,
              ),
            );
          }, childCount: items.length),
        ),
      );
    });
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.event,
    required this.history,
    required this.subscribeId,
  });

  final SubscriptionActivityEvent event;
  final bool history;
  final int subscribeId;

  Color get _statusColor => subscribeActivityStatusColor(event.status);

  void _openDetail() {
    if (event.eventId.isEmpty || subscribeId <= 0) return;
    Get.toNamed(
      '/subscribe-activity-detail',
      arguments: {
        'id': subscribeId,
        'event_id': event.eventId,
        'history': history,
        'title': subscribeActivityKindLabel(event.kind),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = subscribeActivityCountsSummary(event.kind, event.counts);
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _openDetail,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  subscribeActivityKindIcon(event.kind),
                  size: 17,
                  color: _statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          subscribeActivityKindLabel(event.kind),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            subscribeActivityStatusLabel(event.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          subscribeActivityTimeText(event.startedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnsupportedBody extends StatelessWidget {
  const _UnsupportedBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.info_circle, size: 34, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              '活动记录需要 MoviePilot v3 服务端',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
