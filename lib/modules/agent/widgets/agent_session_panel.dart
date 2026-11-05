import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/agent/controllers/agent_controller.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';

class AgentSessionPanel extends GetView<AgentController> {
  const AgentSessionPanel({super.key, this.onSelected});

  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.018),
          colorScheme.surface,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.62,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.clock,
                      color: colorScheme.onPrimaryContainer,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '历史会话',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Obx(
                          () => Text(
                            '${controller.sessions.length} 个会话',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '新对话',
                    onPressed: () {
                      controller.startNewSession();
                      onSelected?.call();
                    },
                    icon: const Icon(CupertinoIcons.square_pencil, size: 18),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.34),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.42),
                ),
                child: Obx(() {
                  if (controller.isLoadingSessions.value &&
                      controller.sessions.isEmpty) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  if (controller.sessionError.value != null &&
                      controller.sessions.isEmpty) {
                    return _PanelState(
                      icon: CupertinoIcons.exclamationmark_circle,
                      text: controller.sessionError.value!,
                      actionText: '重试',
                      onTap: () => controller.loadSessions(refresh: true),
                    );
                  }
                  if (controller.sessions.isEmpty) {
                    return const _PanelState(
                      icon: CupertinoIcons.chat_bubble_2,
                      text: '暂无历史会话',
                    );
                  }
                  return RefreshIndicator.adaptive(
                    onRefresh: () => controller.loadSessions(refresh: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                      itemCount:
                          controller.sessions.length +
                          (controller.canLoadMoreSessions ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= controller.sessions.length) {
                          return const _LoadMoreSessionsSentinel();
                        }
                        final session = controller.sessions[index];
                        return _SessionTile(
                          key: ValueKey(session.sessionId),
                          session: session,
                          onTap: () async {
                            final isActive =
                                controller.activeServerSessionId.value ==
                                session.sessionId;
                            if (!isActive) {
                              await controller.loadSession(session);
                            }
                            onSelected?.call();
                          },
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreSessionsSentinel extends StatefulWidget {
  const _LoadMoreSessionsSentinel();

  @override
  State<_LoadMoreSessionsSentinel> createState() =>
      _LoadMoreSessionsSentinelState();
}

class _LoadMoreSessionsSentinelState extends State<_LoadMoreSessionsSentinel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = Get.find<AgentController>();
      if (controller.canLoadMoreSessions) {
        controller.loadSessions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({super.key, required this.session, required this.onTap});

  final AgentSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AgentController>();
    return Obx(() {
      final selected =
          controller.activeServerSessionId.value == session.sessionId;
      return _SessionTileBody(
        session: session,
        selected: selected,
        onTap: onTap,
      );
    });
  }
}

class _SessionTileBody extends StatelessWidget {
  const _SessionTileBody({
    required this.session,
    required this.selected,
    required this.onTap,
  });

  final AgentSession session;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.54)
            : colorScheme.surface.withValues(alpha: 0.88),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.24)
                : colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 3,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.12)
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.52,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.chat_bubble_text,
                    size: 17,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                          color: selected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.text_bubble,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${session.messageCount} 条消息',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '当前',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelState extends StatelessWidget {
  const _PanelState({
    required this.icon,
    required this.text,
    this.actionText,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final String? actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.90),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.62),
                ),
              ),
              child: Icon(icon, size: 25, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            if (actionText != null && onTap != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onTap, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
