import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AgentInputBar extends StatelessWidget {
  const AgentInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.hasAttachments = false,
    this.onCommandsTap,
    this.onAttachTap,
    this.onStopTap,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool hasAttachments;
  final VoidCallback onSend;
  final VoidCallback? onCommandsTap;
  final VoidCallback? onAttachTap;
  final VoidCallback? onStopTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.98),
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend =
                    enabled && (value.text.trim().isNotEmpty || hasAttachments);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.fromLTRB(10, 7, 7, 7),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      colorScheme.primary.withValues(
                        alpha: canSend ? 0.035 : 0.018,
                      ),
                      colorScheme.surface,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: canSend
                          ? colorScheme.primary.withValues(alpha: 0.38)
                          : colorScheme.outlineVariant.withValues(alpha: 0.48),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!enabled && onStopTap != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5,
                            bottom: 5,
                            right: 6,
                          ),
                          child: GestureDetector(
                            onTap: onStopTap,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: colorScheme.error.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.stop_fill,
                                color: colorScheme.error,
                                size: 16,
                              ),
                            ),
                          ),
                        )
                      else if (onCommandsTap != null ||
                          onAttachTap != null) ...[
                        if (onCommandsTap != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 5,
                              bottom: 5,
                              right: 6,
                            ),
                            child: GestureDetector(
                              onTap: onCommandsTap,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.command,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        if (onAttachTap != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 5,
                              bottom: 5,
                              right: 6,
                            ),
                            child: GestureDetector(
                              onTap: onAttachTap,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.paperclip,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: canSend
                                ? colorScheme.primary.withValues(alpha: 0.12)
                                : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            CupertinoIcons.text_bubble,
                            color: canSend
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Semantics(
                          label: '消息输入框',
                          textField: true,
                          child: TextField(
                            controller: controller,
                            enabled: enabled,
                            minLines: 1,
                            maxLines: 5,
                            cursorColor: colorScheme.primary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: enabled
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                              letterSpacing: 0,
                            ),
                            strutStyle: const StrutStyle(
                              fontSize: 15,
                              height: 1.45,
                              forceStrutHeight: false,
                            ),
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: enabled ? '向 Agent 提问' : 'Agent 正在回复',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.58,
                                ),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                                letterSpacing: 0,
                              ),
                              isDense: true,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        enabled: canSend,
                        label: '发送消息',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(42, 42),
                          onPressed: canSend ? onSend : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOut,
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: canSend
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: canSend
                                    ? colorScheme.primary
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_up,
                              color: canSend
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
