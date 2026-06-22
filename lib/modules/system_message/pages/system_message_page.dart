import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/system_message_controller.dart';
import '../models/system_message.dart';
import '../widgets/system_message_item.dart';

class SystemMessagePage extends StatefulWidget {
  const SystemMessagePage({super.key});

  @override
  State<SystemMessagePage> createState() => _SystemMessagePageState();
}

class _SystemMessagePageState extends State<SystemMessagePage> {
  late final SystemMessageController controller;

  static const double _pageHorizontalPadding = 16;
  String _selectedType = '全部';

  @override
  void initState() {
    super.initState();
    controller = Get.find<SystemMessageController>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (controller.messages.isEmpty) {
        await controller.loadInitial();
      } else {
        await controller.scrollToBottom();
      }
      await controller.markAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统消息'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _openTypeFilterSheet(context),
              child: Ink(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.54 : 0.82,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.72),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.slider_horizontal_3,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.78),
                    ),
                    if (_selectedType != '全部')
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              Color.lerp(
                    theme.scaffoldBackgroundColor,
                    cs.primary,
                    isDark ? 0.025 : 0.018,
                  ) ??
                  theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Obx(() {
          final items = _applyTypeFilter(controller.messages);
          return Column(
            children: [
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(context)
                    : _buildMessageList(context, items),
              ),
              _buildInputBar(context, controller),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(CupertinoIcons.bell, color: cs.primary),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无系统消息',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '下拉可刷新，也可以点击下方输入框发送消息。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            CupertinoButton.filled(
              onPressed: controller.loadMore,
              child: const Text('刷新'),
            ),
          ],
        ),
      ),
    );
  }

  List<SystemMessage> _applyTypeFilter(List<SystemMessage> items) {
    final selected = _selectedType;
    if (selected == '全部') return items;
    return items.where((m) => _messageType(m) == selected).toList();
  }

  String _messageType(SystemMessage message) {
    final isUserText = message.action == 0 && message.text.trim().isNotEmpty;
    if (isUserText) return '用户';
    final t = message.mtype.trim();
    return t.isEmpty ? '消息' : t;
  }

  List<String> _availableTypesFrom(List<SystemMessage> items) {
    final set = <String>{'全部'};
    for (final m in items) {
      set.add(_messageType(m));
      if (set.length > 12) break;
    }
    return set.toList();
  }

  Future<void> _openTypeFilterSheet(BuildContext context) async {
    final types = _availableTypesFrom(controller.messages);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bg = CupertinoDynamicColor.resolve(
          CupertinoColors.systemBackground,
          ctx,
        );
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemGrey4,
                      ctx,
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '筛选消息类型',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            ctx,
                          ).colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _selectedType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            ctx,
                          ).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: types.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.outline.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (ctx, i) {
                      final type = types[i];
                      final active = type == _selectedType;
                      final icon = _typeIcon(type);
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              ctx,
                            ).colorScheme.onSurface.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: Theme.of(
                              ctx,
                            ).colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                        title: Text(
                          type,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: active
                            ? const Icon(CupertinoIcons.check_mark, size: 18)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(type),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (selected == null) return;
    setState(() => _selectedType = selected);
  }

  IconData _typeIcon(String type) {
    if (type == '全部') return CupertinoIcons.line_horizontal_3_decrease;
    if (type == '用户') return CupertinoIcons.person;
    if (type == '搜索') return CupertinoIcons.sparkles;
    if (type == '消息') return CupertinoIcons.bell;
    return CupertinoIcons.tag;
  }

  Widget _buildMessageList(BuildContext context, List<SystemMessage> items) {
    return CustomScrollView(
      controller: controller.scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: controller.loadMore),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            _pageHorizontalPadding,
            10,
            _pageHorizontalPadding,
            16,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final message = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SystemMessageItem(message: message),
              );
            }, childCount: items.length),
          ),
        ),
        if (!controller.hasMore.value)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Center(
                child: Text(
                  '没有更多了',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 6)),
      ],
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    SystemMessageController controller,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              _pageHorizontalPadding,
              10,
              _pageHorizontalPadding,
              10,
            ),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: isDark ? 0.86 : 0.96),
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.72),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: controller.inputController,
                    placeholder: '输入消息内容',
                    minLines: 1,
                    maxLines: 3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.52 : 0.76,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(
                  () => SizedBox(
                    height: 42,
                    width: 46,
                    child: CupertinoButton.filled(
                      padding: EdgeInsets.zero,
                      onPressed: controller.isSending.value
                          ? null
                          : controller.sendMessage,
                      child: controller.isSending.value
                          ? const CupertinoActivityIndicator(radius: 8)
                          : const Icon(
                              CupertinoIcons.paperplane_fill,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
