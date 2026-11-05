import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';
import 'package:moviepilot_mobile/modules/agent/repositories/agent_repository.dart';
import 'package:moviepilot_mobile/modules/agent/services/agent_local_cache.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class AgentController extends GetxController {
  AgentController({
    AgentRepositoryContract? repository,
    AgentLocalCache? localCache,
    Duration? streamIdleTimeout,
    Duration? streamOverallTimeout,
  }) : _repository = repository ?? Get.find<AgentRepository>(),
       _localCache = localCache ?? AgentLocalCache(),
       _streamIdleTimeout = streamIdleTimeout ?? const Duration(seconds: 90),
       _streamOverallTimeout =
           streamOverallTimeout ?? const Duration(minutes: 10);

  static const _streamTimeoutMessage = '响应超时，请重试';

  final AgentRepositoryContract _repository;
  final AgentLocalCache _localCache;
  final Duration _streamIdleTimeout;
  final Duration _streamOverallTimeout;
  final _log = Get.find<AppLog>();

  final sessions = <AgentSession>[].obs;
  final messages = <AgentChatMessage>[].obs;
  final isLoadingSessions = false.obs;
  final isLoadingMessages = false.obs;
  final isSending = false.obs;
  final isStopping = false.obs;
  final isUploading = false.obs;
  final pendingAttachments = <AgentAttachment>[].obs;
  int _streamGeneration = 0;
  int _conversationGeneration = 0;
  bool _disposed = false;
  String? _outboundSessionId;

  bool get supportsAttachments => _repository is AgentRepositoryActions;
  bool get canSend =>
      !_disposed &&
      !isSending.value &&
      !isStopping.value &&
      !isUploading.value &&
      !isLoadingMessages.value;

  void _clearAttachmentDraft() {
    _conversationGeneration++;
    pendingAttachments.clear();
    isUploading.value = false;
  }

  final sessionError = RxnString();
  final messageError = RxnString();
  final activeClientSessionId = RxnString();
  final activeServerSessionId = RxnString();

  final Map<String, List<AgentChatMessage>> _messagesBySession = {};

  StreamSubscription<AgentStreamEvent>? _streamSubscription;
  String? _activeAssistantMessageId;
  int _sessionPage = 1;
  bool _hasMoreSessions = true;
  bool _restoreAttempted = false;
  Timer? _persistDebounce;
  bool _sessionsRefreshInFlight = false;
  Timer? _streamIdleTimer;
  Timer? _streamOverallTimer;
  Worker? _scopeWorker;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<AppService>()) {
      final appService = Get.find<AppService>();
      _scopeWorker = ever<String>(
        appService.agentCacheScopeKey,
        _handleCacheScopeChanged,
      );
      if (appService.agentCacheScopeKey.value.isEmpty) return;
    }
    unawaited(_hydrateFromLocalCache());
    loadSessions(refresh: true);
  }

  Future<void> _handleCacheScopeChanged(String scopeKey) async {
    _clearAttachmentDraft();
    await _cancelStream(markFailed: false);
    _persistDebounce?.cancel();
    _persistDebounce = null;
    _activeAssistantMessageId = null;
    _messagesBySession.clear();
    sessions.clear();
    messages.clear();
    activeClientSessionId.value = null;
    activeServerSessionId.value = null;
    sessionError.value = null;
    messageError.value = null;
    isLoadingSessions.value = false;
    isLoadingMessages.value = false;
    isSending.value = false;
    _sessionPage = 1;
    _hasMoreSessions = true;
    _restoreAttempted = false;
    if (scopeKey.isEmpty) return;
    await _hydrateFromLocalCache();
    await loadSessions(refresh: true);
  }

  Future<void> _hydrateFromLocalCache() async {
    if (messages.isNotEmpty || isSending.value) return;
    try {
      final lastSession = await _localCache.loadLastSession();
      if (lastSession == null) return;
      final cached = await _resolveCachedMessages(lastSession.serverSessionId);
      if (cached.isEmpty) return;
      activeServerSessionId.value = lastSession.serverSessionId;
      activeClientSessionId.value = lastSession.clientSessionId;
      messages.assignAll(cached);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '恢复 Agent 本地消息失败');
    }
  }

  @override
  void onClose() {
    _disposed = true;
    ++_streamGeneration;
    _clearAttachmentDraft();
    _scopeWorker?.dispose();
    _persistDebounce?.cancel();
    _clearStreamTimeouts();
    _flushActiveMessagesToDisk();
    unawaited(_cancelSubscription(_streamSubscription));
    _streamSubscription = null;
    super.onClose();
  }

  Future<void> clearForLogout() async {
    _clearAttachmentDraft();
    await _cancelStream(markFailed: false);
    _persistDebounce?.cancel();
    _persistDebounce = null;
    _activeAssistantMessageId = null;
    _messagesBySession.clear();
    sessions.clear();
    messages.clear();
    activeClientSessionId.value = null;
    activeServerSessionId.value = null;
    sessionError.value = null;
    messageError.value = null;
    isLoadingSessions.value = false;
    isLoadingMessages.value = false;
    isSending.value = false;
    _sessionPage = 1;
    _hasMoreSessions = true;
    _restoreAttempted = false;
  }

  bool get canLoadMoreSessions => !isLoadingSessions.value && _hasMoreSessions;

  Future<void> loadSessions({bool refresh = false}) async {
    if (isLoadingSessions.value) return;
    if (!refresh && !_hasMoreSessions) return;
    isLoadingSessions.value = true;
    sessionError.value = null;
    if (refresh) {
      _sessionPage = 1;
      _hasMoreSessions = true;
      final cached = await _localCache.loadSessions();
      if (cached.isNotEmpty) {
        sessions.assignAll(cached);
      }
    }
    try {
      final next = await _repository.fetchSessions(page: _sessionPage);
      if (refresh) {
        sessions.assignAll(next);
      } else {
        sessions.addAll(next);
      }
      _hasMoreSessions = next.isNotEmpty;
      if (next.isNotEmpty) {
        _sessionPage += 1;
      }
      if (sessions.isNotEmpty) {
        unawaited(_localCache.saveSessions(sessions));
      }
      if (refresh) {
        unawaited(_restoreLastSessionIfPossible());
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载 Agent 会话失败');
      if (sessions.isEmpty) {
        sessionError.value = '会话列表加载失败';
      }
    } finally {
      isLoadingSessions.value = false;
    }
  }

  Future<void> loadSession(AgentSession session) async {
    _clearAttachmentDraft();
    final generation = _conversationGeneration;
    bool isCurrent() => !_disposed && generation == _conversationGeneration;
    isLoadingMessages.value = true;
    try {
      await _cancelStream(markFailed: false);
      if (!isCurrent()) return;
      _flushActiveMessagesToDisk();

      final loadingSessionId = session.sessionId;
      activeClientSessionId.value = session.clientSessionId;
      activeServerSessionId.value = loadingSessionId;
      messageError.value = null;

      final cached = await _resolveCachedMessages(loadingSessionId);
      if (!isCurrent()) return;
      messages.assignAll(cached);

      final history = await _repository.fetchSessionMessages(loadingSessionId);
      if (!isCurrent() || isSending.value) return;
      if (history.isEmpty) return;
      final merged = _mergeSessionMessages(
        List<AgentChatMessage>.from(messages),
        history,
      );
      messages.assignAll(merged);
      _rememberMessages(loadingSessionId, merged, immediate: true);
      unawaited(_persistLastSession(session));
    } catch (e, st) {
      if (!isCurrent()) return;
      _log.handle(e, stackTrace: st, message: '加载 Agent 历史消息失败');
      if (messages.isEmpty) {
        final fallback = await _resolveCachedMessages(session.sessionId);
        if (!isCurrent()) return;
        if (fallback.isNotEmpty) {
          messages.assignAll(fallback);
        } else {
          messageError.value = '历史消息加载失败';
        }
      }
    } finally {
      if (isCurrent()) {
        isLoadingMessages.value = false;
      }
    }
  }

  Future<void> startNewSession() async {
    _clearAttachmentDraft();
    await _cancelStream(markFailed: false);
    isLoadingMessages.value = false;
    _flushActiveMessagesToDisk();
    activeClientSessionId.value = null;
    activeServerSessionId.value = null;
    messageError.value = null;
    messages.clear();
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (!canSend || (trimmed.isEmpty && pendingAttachments.isEmpty)) return;
    final attachments = List<AgentAttachment>.unmodifiable(pendingAttachments);
    if (attachments.isNotEmpty && !supportsAttachments) return;
    // Reserve the send before awaiting so two taps cannot create two streams.
    isSending.value = true;
    final generation = ++_streamGeneration;
    messageError.value = null;
    final serverSessionId = activeServerSessionId.value;
    if (activeClientSessionId.value == null ||
        activeClientSessionId.value!.isEmpty) {
      activeClientSessionId.value = _newClientSessionId();
    }
    final outboundSessionId = serverSessionId == null || serverSessionId.isEmpty
        ? activeClientSessionId.value!
        : serverSessionId;
    _outboundSessionId = outboundSessionId;

    final now = DateTime.now();
    final userMessage = AgentChatMessage(
      id: _messageId('user'),
      role: 'user',
      content: trimmed,
      attachments: attachments,
      createdAt: now,
      status: AgentMessageStatus.done,
    );
    final assistantMessage = AgentChatMessage(
      id: _messageId('assistant'),
      role: 'assistant',
      content: '',
      createdAt: now,
      status: AgentMessageStatus.streaming,
    );
    _activeAssistantMessageId = assistantMessage.id;
    messages.addAll([userMessage, assistantMessage]);
    _persistActiveMessages();
    pendingAttachments.clear();
    _armStreamTimeouts();

    try {
      debugPrint(
        '[Agent SSE] 订阅 outboundSessionId=$outboundSessionId '
        'clientSessionId=${activeClientSessionId.value}',
      );
      _log.info(
        'Agent SSE 订阅 outboundSessionId=$outboundSessionId '
        'clientSessionId=${activeClientSessionId.value}',
      );
      final stream = attachments.isEmpty
          ? await _repository.sendMessage(
              text: trimmed,
              sessionId: outboundSessionId,
              clientSessionId: activeClientSessionId.value,
            )
          : await (_repository as AgentRepositoryActions)
                .sendMessageWithAttachments(
                  text: trimmed,
                  sessionId: outboundSessionId,
                  clientSessionId: activeClientSessionId.value,
                  attachments: attachments,
                );
      if (_disposed || generation != _streamGeneration) {
        // The HTTP handshake can finish after stop, navigation, or logout.
        await stream.listen((_) {}).cancel();
        return;
      }
      _streamSubscription = stream.listen(
        (event) {
          if (_disposed || generation != _streamGeneration) return;
          _touchStreamIdleTimeout();
          applyStreamEvent(event);
        },
        onError: (error, stackTrace) {
          if (_disposed || generation != _streamGeneration) return;
          _log.handle(error, stackTrace: stackTrace, message: 'Agent SSE 失败');
          unawaited(
            _abortActiveStream(failed: true, errorMessage: '消息发送失败，请稍后重试'),
          );
        },
        onDone: () {
          if (_disposed || generation != _streamGeneration) return;
          unawaited(_abortActiveStream(failed: false));
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      if (_disposed || generation != _streamGeneration) return;
      _log.handle(e, stackTrace: st, message: 'Agent 消息发送失败');
      ++_streamGeneration;
      _finishStreaming(failed: true);
      pendingAttachments.assignAll(attachments);
      messageError.value = '消息发送失败，请稍后重试';
      ToastUtil.error(messageError.value!);
    }
  }

  void applyStreamEvent(AgentStreamEvent event) {
    switch (event.type) {
      case 'start':
        final sessionId = event.sessionId;
        if (sessionId != null && sessionId.isNotEmpty) {
          final previousKey = _activeSessionCacheKey();
          activeServerSessionId.value = sessionId;
          if (previousKey != null &&
              previousKey.isNotEmpty &&
              previousKey != sessionId) {
            _migrateSessionCache(previousKey, sessionId);
          }
          _persistActiveMessages(immediate: true);
          unawaited(_persistActiveSession());
          _upsertActiveSessionSummary();
        }
        break;
      case 'attachment':
        final raw = event.raw['attachment'];
        final index = _assistantIndex();
        if (raw is Map && index != -1) {
          final attachment = AgentAttachment.fromJson(
            Map<String, dynamic>.from(raw),
          );
          if (attachment.hasDisplayValue) {
            final current = messages[index];
            messages[index] = current.copyWith(
              attachments: [...current.attachments, attachment],
            );
            _persistActiveMessages();
          }
        }
        break;
      case 'tool':
        _appendTool(event);
        break;
      case 'delta':
        final content = event.content;
        if (content != null && content.isNotEmpty) {
          _appendDelta(content);
        }
        break;
      case 'error':
        unawaited(
          _abortActiveStream(
            failed: true,
            errorMessage: event.message ?? 'Agent 返回错误',
          ),
        );
        break;
      case 'done':
        unawaited(_abortActiveStream(failed: false));
        break;
      default:
        final content = event.content;
        if (content != null && content.isNotEmpty) {
          _appendDelta(content);
        }
        break;
    }
  }

  Future<void> _cancelStream({required bool markFailed}) async {
    ++_streamGeneration;
    _clearStreamTimeouts();
    final subscription = _streamSubscription;
    _streamSubscription = null;
    if (isSending.value) _finishStreaming(failed: markFailed);
    await _cancelSubscription(subscription);
  }

  Future<void> _cancelSubscription(
    StreamSubscription<AgentStreamEvent>? subscription,
  ) async {
    try {
      await subscription?.cancel();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '取消 Agent SSE 失败');
    }
  }

  void _armStreamTimeouts() {
    _clearStreamTimeouts();
    _touchStreamIdleTimeout();
    _streamOverallTimer = Timer(_streamOverallTimeout, () {
      unawaited(
        _abortActiveStream(failed: true, errorMessage: _streamTimeoutMessage),
      );
    });
  }

  void _touchStreamIdleTimeout() {
    _streamIdleTimer?.cancel();
    if (!isSending.value) return;
    _streamIdleTimer = Timer(_streamIdleTimeout, () {
      unawaited(
        _abortActiveStream(failed: true, errorMessage: _streamTimeoutMessage),
      );
    });
  }

  void _clearStreamTimeouts() {
    _streamIdleTimer?.cancel();
    _streamOverallTimer?.cancel();
    _streamIdleTimer = null;
    _streamOverallTimer = null;
  }

  Future<void> _abortActiveStream({
    required bool failed,
    String? errorMessage,
  }) async {
    if (!isSending.value && _streamSubscription == null) return;
    ++_streamGeneration;
    final subscription = _streamSubscription;
    _streamSubscription = null;
    // Settle local state synchronously, never let an old cancel finish a new send.
    _finishStreaming(failed: failed);
    if (errorMessage != null && errorMessage.isNotEmpty) {
      messageError.value = errorMessage;
    }
    _upsertActiveSessionSummary();
    if (!failed) unawaited(_syncAfterStreamDone());
    await _cancelSubscription(subscription);
  }

  void _appendDelta(String delta) {
    final index = _assistantIndex();
    if (index == -1) return;
    final current = messages[index];
    messages[index] = current.copyWith(
      content: '${current.content}$delta',
      status: AgentMessageStatus.streaming,
    );
    _persistActiveMessages();
  }

  void _appendTool(AgentStreamEvent event) {
    final index = _assistantIndex();
    if (index == -1) return;
    final current = messages[index];
    final raw = event.raw;
    final tool = AgentToolEvent.fromJson({
      'id': raw['id'],
      'message': event.message ?? raw['content'],
      'status': raw['status'] ?? 'done',
    });
    messages[index] = current.copyWith(tools: [...current.tools, tool]);
    _persistActiveMessages();
  }

  void _finishStreaming({bool failed = false}) {
    _clearStreamTimeouts();
    final index = _assistantIndex();
    if (index != -1) {
      final current = messages[index];
      messages[index] = current.copyWith(
        status: failed ? AgentMessageStatus.failed : AgentMessageStatus.done,
      );
    }
    _streamSubscription = null;
    _activeAssistantMessageId = null;
    isSending.value = false;
    _persistActiveMessages(immediate: true);
  }

  int _assistantIndex() {
    final id = _activeAssistantMessageId;
    if (id == null) return -1;
    return messages.indexWhere((message) => message.id == id);
  }

  String? _activeSessionCacheKey() {
    final serverId = activeServerSessionId.value;
    if (serverId != null && serverId.isNotEmpty) {
      return serverId;
    }
    final clientId = activeClientSessionId.value;
    if (clientId != null && clientId.isNotEmpty) {
      return clientId;
    }
    return null;
  }

  void _persistActiveMessages({bool immediate = false}) {
    final key = _activeSessionCacheKey();
    if (key == null) return;
    _rememberMessages(key, messages, immediate: immediate);
  }

  void _flushActiveMessagesToDisk() {
    _persistDebounce?.cancel();
    _persistDebounce = null;
    final key = _activeSessionCacheKey();
    if (key == null || messages.isEmpty) return;
    final snapshot =
        _messagesBySession[key] ?? List<AgentChatMessage>.from(messages);
    unawaited(_localCache.saveMessages(key, snapshot));
  }

  void _rememberMessages(
    String key,
    List<AgentChatMessage> source, {
    bool immediate = false,
  }) {
    final snapshot = List<AgentChatMessage>.from(source);
    _messagesBySession[key] = snapshot;
    if (immediate) {
      _persistDebounce?.cancel();
      _persistDebounce = null;
      unawaited(_localCache.saveMessages(key, snapshot));
      return;
    }
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_localCache.saveMessages(key, snapshot));
    });
  }

  Future<List<AgentChatMessage>> _resolveCachedMessages(
    String sessionKey,
  ) async {
    final memory = _messagesBySession[sessionKey];
    if (memory != null && memory.isNotEmpty) {
      return memory;
    }
    final disk = await _localCache.loadMessages(sessionKey);
    if (disk.isNotEmpty) {
      _messagesBySession[sessionKey] = disk;
    }
    return disk;
  }

  void _migrateSessionCache(String fromKey, String toKey) {
    final cached =
        _messagesBySession[fromKey] ??
        (_messagesBySession[toKey] ?? List<AgentChatMessage>.from(messages));
    _messagesBySession[toKey] = cached;
    _messagesBySession.remove(fromKey);
    unawaited(_localCache.migrateMessages(fromKey, toKey));
  }

  String _newClientSessionId() {
    final random = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'mobile-${DateTime.now().millisecondsSinceEpoch}-$random';
  }

  String _messageId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _syncAfterStreamDone() async {
    _upsertActiveSessionSummary();
    unawaited(_refreshSessionsQuietly());
  }

  void _upsertActiveSessionSummary() {
    final sessionId = activeServerSessionId.value;
    final clientSessionId = activeClientSessionId.value;
    if (sessionId == null ||
        sessionId.isEmpty ||
        clientSessionId == null ||
        clientSessionId.isEmpty) {
      return;
    }

    final summary = AgentSession(
      sessionId: sessionId,
      clientSessionId: clientSessionId,
      title: _deriveSessionTitle(),
      messageCount: messages.length,
    );
    final index = sessions.indexWhere((item) => item.sessionId == sessionId);
    if (index >= 0) {
      final existing = sessions[index];
      sessions[index] = AgentSession(
        id: existing.id,
        sessionId: sessionId,
        clientSessionId: clientSessionId,
        title: summary.title,
        messageCount: summary.messageCount,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
      );
    } else {
      sessions.insert(0, summary);
    }
    sessions.refresh();
    unawaited(_localCache.saveSessions(sessions));
  }

  String _deriveSessionTitle() {
    for (final message in messages) {
      if (message.isUser && message.content.trim().isNotEmpty) {
        final text = message.content.trim();
        return text.length <= 24 ? text : '${text.substring(0, 24)}…';
      }
    }
    return '新的对话';
  }

  Future<void> _refreshSessionsQuietly() async {
    if (_sessionsRefreshInFlight) return;
    _sessionsRefreshInFlight = true;
    try {
      final next = await _repository.fetchSessions(page: 1, count: 30);
      if (next.isEmpty) return;
      sessions.assignAll(next);
      unawaited(_localCache.saveSessions(sessions));
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '后台刷新 Agent 会话列表失败');
    } finally {
      _sessionsRefreshInFlight = false;
    }
  }

  List<AgentChatMessage> _mergeSessionMessages(
    List<AgentChatMessage> local,
    List<AgentChatMessage> incoming,
  ) {
    if (incoming.isEmpty) return local;
    if (local.isEmpty) return incoming;
    if (incoming.length < local.length) return local;
    if (incoming.length > local.length) return incoming;

    final merged = <AgentChatMessage>[];
    for (var i = 0; i < local.length; i++) {
      merged.add(_pickRicherMessage(local[i], incoming[i]));
    }
    return merged;
  }

  AgentChatMessage _pickRicherMessage(
    AgentChatMessage local,
    AgentChatMessage incoming,
  ) {
    final localScore = _messageRichnessScore(local);
    final incomingScore = _messageRichnessScore(incoming);
    if (incomingScore > localScore) return incoming;
    if (localScore > incomingScore) return local;
    if (incoming.tools.length > local.tools.length) return incoming;
    return local;
  }

  int _messageRichnessScore(AgentChatMessage message) {
    var score = message.content.length;
    if (message.status == AgentMessageStatus.done) score += 4;
    score += message.tools.length * 12;
    score += message.attachments.length * 6;
    return score;
  }

  Future<void> _restoreLastSessionIfPossible() async {
    if (_restoreAttempted) return;
    if (messages.isNotEmpty || isSending.value) {
      _restoreAttempted = true;
      return;
    }
    try {
      final lastSession = await _localCache.loadLastSession();
      if (lastSession == null) {
        _restoreAttempted = true;
        return;
      }
      final serverSessionId = lastSession.serverSessionId;
      final matched = sessions.where(
        (session) => session.sessionId == serverSessionId,
      );
      if (matched.isEmpty) {
        final cached = await _resolveCachedMessages(serverSessionId);
        if (cached.isNotEmpty) {
          activeServerSessionId.value = serverSessionId;
          activeClientSessionId.value = lastSession.clientSessionId;
          messages.assignAll(cached);
        }
        _restoreAttempted = true;
        return;
      }
      _restoreAttempted = true;
      await loadSession(matched.first);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '恢复 Agent 上次会话失败');
    }
  }

  Future<void> _persistLastSession(AgentSession session) async {
    await _localCache.saveLastSession(
      serverSessionId: session.sessionId,
      clientSessionId: session.clientSessionId,
    );
  }

  Future<void> _persistActiveSession() async {
    final serverSessionId = activeServerSessionId.value;
    final clientSessionId = activeClientSessionId.value;
    if (serverSessionId == null ||
        serverSessionId.isEmpty ||
        clientSessionId == null ||
        clientSessionId.isEmpty) {
      return;
    }
    await _localCache.saveLastSession(
      serverSessionId: serverSessionId,
      clientSessionId: clientSessionId,
    );
  }

  AgentRepositoryActions get _actions {
    final repository = _repository;
    if (repository is! AgentRepositoryActions) {
      throw UnsupportedError('当前服务不支持此操作');
    }
    return repository as AgentRepositoryActions;
  }

  Future<List<Map<String, dynamic>>> fetchCommands() =>
      _actions.fetchCommands();

  Future<Uint8List> downloadAttachment(AgentAttachment attachment) =>
      _actions.downloadAttachment(attachment);

  Future<Map<String, dynamic>?> uploadAttachment(
    String filePath,
    String fileName,
  ) async {
    if (!canSend) return null;
    final actions = _actions;
    final generation = _conversationGeneration;
    activeClientSessionId.value ??= _newClientSessionId();
    isUploading.value = true;
    try {
      final receipt = await actions.uploadAttachment(
        filePath,
        fileName,
        sessionId: activeServerSessionId.value ?? activeClientSessionId.value,
      );
      if (_disposed || generation != _conversationGeneration) return null;
      if (receipt == null) throw StateError('附件上传失败');
      final attachment = AgentAttachment.fromJson(receipt);
      if (attachment.ref == null || attachment.ref!.isEmpty) {
        throw StateError('服务端未返回有效的附件引用');
      }
      pendingAttachments.add(attachment);
      return receipt;
    } finally {
      if (!_disposed && generation == _conversationGeneration) {
        isUploading.value = false;
      }
    }
  }

  Future<bool> stopActiveSession() async {
    if (!isSending.value || isStopping.value) return false;
    final sessionId = activeServerSessionId.value ?? _outboundSessionId;
    isStopping.value = true;
    // Local cancellation is independent of backend acknowledgement or failure.
    final cancellation = _cancelStream(markFailed: false);
    try {
      if (sessionId == null || sessionId.isEmpty) return false;
      return await _actions.stopSession(sessionId);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '停止 Agent 任务失败');
      return false;
    } finally {
      await cancellation;
      isStopping.value = false;
    }
  }
}
