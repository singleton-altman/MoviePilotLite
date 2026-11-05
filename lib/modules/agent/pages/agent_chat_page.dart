import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/agent/controllers/agent_controller.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';
import 'package:moviepilot_mobile/modules/agent/widgets/agent_input_bar.dart';
import 'package:moviepilot_mobile/modules/agent/widgets/agent_message_bubble.dart';
import 'package:moviepilot_mobile/modules/agent/widgets/agent_session_panel.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class AgentChatPage extends StatefulWidget {
  const AgentChatPage({super.key});

  @override
  State<AgentChatPage> createState() => _AgentChatPageState();
}

class _AgentChatPageState extends State<AgentChatPage> {
  final _inputController = TextEditingController();
  late final AgentController _controller;
  bool _isSessionPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AgentController>();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _openSessionDrawer() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isSessionPanelOpen) return;
    setState(() => _isSessionPanelOpen = true);
  }

  void _closeSessionDrawer() {
    if (!_isSessionPanelOpen) return;
    setState(() => _isSessionPanelOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final showSidePanel = MediaQuery.sizeOf(context).width >= 840;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _AgentAppBar(
        showSessionAction: !showSidePanel,
        onTapSessions: _openSessionDrawer,
        onTapNewSession: () {
          _inputController.clear();
          _controller.startNewSession();
        },
      ),
      body: showSidePanel
          ? Row(
              children: [
                const SizedBox(width: 312, child: AgentSessionPanel()),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: _ChatPane(controller: _inputController)),
              ],
            )
          : Stack(
              children: [
                _ChatPane(controller: _inputController),
                _SessionPanelOverlay(
                  visible: _isSessionPanelOpen,
                  onClose: _closeSessionDrawer,
                ),
              ],
            ),
    );
  }
}

class _SessionPanelOverlay extends StatelessWidget {
  const _SessionPanelOverlay({required this.visible, required this.onClose});

  final bool visible;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width < 380 ? width * 0.90 : 336.0;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              top: 0,
              right: visible ? 0 : -panelWidth,
              bottom: 0,
              width: panelWidth,
              child: Material(
                color: colorScheme.surface,
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                child: AgentSessionPanel(onSelected: onClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AgentAppBar({
    required this.showSessionAction,
    required this.onTapSessions,
    required this.onTapNewSession,
  });

  final bool showSessionAction;
  final VoidCallback onTapSessions;
  final VoidCallback onTapNewSession;

  @override
  Size get preferredSize => const Size.fromHeight(69);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 68,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        tooltip: '返回',
        onPressed: Get.back,
        icon: const Icon(CupertinoIcons.chevron_left),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              CupertinoIcons.sparkles,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Agent 对话',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(() {
                  final controller = Get.find<AgentController>();
                  final connected =
                      controller.activeServerSessionId.value?.isNotEmpty ??
                      false;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: connected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.56,
                                ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        connected ? '已连接会话' : '新会话',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (showSessionAction)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton.filledTonal(
              tooltip: '历史会话',
              onPressed: onTapSessions,
              icon: const Icon(CupertinoIcons.sidebar_right, size: 19),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton.filled(
            tooltip: '新对话',
            onPressed: onTapNewSession,
            icon: const Icon(CupertinoIcons.square_pencil, size: 18),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _ChatPane extends StatefulWidget {
  const _ChatPane({required this.controller});

  final TextEditingController controller;

  @override
  State<_ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<_ChatPane> {
  final _scrollController = ScrollController();
  late final AgentController _controller;
  Worker? _messagesWorker;

  /// GET /api/v1/message/agent/commands 命令面板（点击插入到输入框）。
  Future<void> _showCommandsSheet() async {
    ToastUtil.loading(message: '正在获取命令…');
    List<Map<String, dynamic>> commands;
    try {
      commands = await _controller.fetchCommands();
    } catch (e) {
      ToastUtil.dismiss();
      if (mounted) {
        ToastUtil.error(e is StateError ? e.message.toString() : '命令列表加载失败');
      }
      return;
    }
    ToastUtil.dismiss();
    if (!mounted) return;
    if (commands.isEmpty) {
      ToastUtil.info('服务端未提供命令列表');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 6),
              child: Text(
                '可用命令',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final command in commands)
              ListTile(
                dense: true,
                title: Text(
                  (command['command'] ??
                          command['name'] ??
                          command['cmd'] ??
                          '')
                      .toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: command['description']?.toString().isNotEmpty == true
                    ? Text(
                        command['description'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onTap: () {
                  final name =
                      (command['command'] ??
                              command['name'] ??
                              command['cmd'] ??
                              '')
                          .toString();
                  if (!_controller.canSend) {
                    Navigator.of(sheetContext).pop();
                    return;
                  }
                  final text = widget.controller.text.trimLeft();
                  final arguments = text.startsWith('/')
                      ? text.replaceFirst(RegExp(r'^/\S*\s*'), '')
                      : text;
                  // Slash commands are only dispatched at the start of input.
                  widget.controller.text = '$name $arguments';
                  widget.controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: widget.controller.text.length),
                  );
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 选择文件并上传为助手附件（POST /api/v1/message/agent/upload）。
  Future<void> _pickAndUploadAttachment() async {
    if (!_controller.canSend) return;
    try {
      final result = await FilePicker.pickFiles(allowMultiple: false);
      final file = result?.files.firstOrNull;
      if (!mounted || file == null || file.path == null) return;
      ToastUtil.loading(message: '正在上传附件…');
      final receipt = await _controller.uploadAttachment(file.path!, file.name);
      ToastUtil.dismiss();
      if (!mounted || receipt == null) return;
      ToastUtil.success('附件已就绪，发送消息后提交');
    } catch (e) {
      ToastUtil.dismiss();
      ToastUtil.error(e is StateError ? e.message : '上传失败，请稍后重试');
    }
  }

  Future<void> _downloadAttachment(AgentAttachment attachment) async {
    ToastUtil.loading(message: '正在下载附件…');
    try {
      final bytes = await _controller.downloadAttachment(attachment);
      ToastUtil.dismiss();
      if (!mounted) return;
      final name = attachment.name.split(RegExp(r'[/\\]')).last.trim();
      final path = await FilePicker.saveFile(
        fileName: name.isEmpty ? 'attachment' : name,
        bytes: bytes,
      );
      if (path != null) ToastUtil.success('附件已保存');
    } catch (e) {
      ToastUtil.dismiss();
      ToastUtil.error(e is StateError ? e.message.toString() : '附件下载失败');
    }
  }

  /// 停止当前会话正在执行的任务。
  Future<void> _stopActiveSession() async {
    final ok = await _controller.stopActiveSession();
    if (ok) {
      ToastUtil.success('已发送停止指令');
    } else {
      ToastUtil.info('已停止本地接收，服务端未确认停止或任务已结束');
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AgentController>();
    _messagesWorker = ever(_controller.messages, (_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messagesWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.025),
          colorScheme.surface,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_controller.isLoadingMessages.value) {
                return const Center(child: CupertinoActivityIndicator());
              }
              if (_controller.messages.isEmpty) {
                return const _EmptyChat();
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
                itemCount: _controller.messages.length,
                itemBuilder: (context, index) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: AgentMessageBubble(
                      message: _controller.messages[index],
                      onAttachmentTap: _downloadAttachment,
                    ),
                  );
                },
              );
            }),
          ),
          Obx(() {
            final error = _controller.messageError.value;
            if (error == null || error.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_circle,
                          size: 18,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          Obx(
            () => Wrap(
              spacing: 8,
              children: [
                for (final attachment in _controller.pendingAttachments)
                  InputChip(
                    label: Text(
                      attachment.name.isEmpty ? '附件' : attachment.name,
                    ),
                    onDeleted: _controller.canSend
                        ? () =>
                              _controller.pendingAttachments.remove(attachment)
                        : null,
                  ),
                if (_controller.isUploading.value) const Text('正在上传附件…'),
              ],
            ),
          ),
          Obx(
            () => AgentInputBar(
              controller: widget.controller,
              enabled: _controller.canSend,
              hasAttachments: _controller.pendingAttachments.isNotEmpty,
              onSend: () {
                if (!_controller.canSend) return;
                final text = widget.controller.text;
                unawaited(_controller.sendMessage(text));
                widget.controller.clear();
              },
              onCommandsTap: _controller.canSend ? _showCommandsSheet : null,
              onAttachTap:
                  _controller.canSend && _controller.supportsAttachments
                  ? _pickAndUploadAttachment
                  : null,
              onStopTap:
                  _controller.isSending.value && !_controller.isStopping.value
                  ? _stopActiveSession
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 60), () {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.75),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                CupertinoIcons.sparkles,
                size: 31,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '开始一段 Agent 对话',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                '媒体推荐、资源搜索、订阅整理',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: const [
                _EmptyPromptPill(text: '找片'),
                _EmptyPromptPill(text: '整理订阅'),
                _EmptyPromptPill(text: '解释结果'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPromptPill extends StatelessWidget {
  const _EmptyPromptPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
