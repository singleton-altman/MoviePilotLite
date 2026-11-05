import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/agent/controllers/agent_controller.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_cache_models.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';
import 'package:moviepilot_mobile/modules/agent/repositories/agent_repository.dart';
import 'package:moviepilot_mobile/modules/agent/services/agent_local_cache.dart';

void main() {
  late AgentLocalCache testCache;
  late Directory hiveDir;

  setUp(() async {
    Get.testMode = true;
    Get.put(AppLog());
    hiveDir = Directory.systemTemp.createTempSync('agent_hive_test');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(AgentSessionCacheAdapter());
      Hive.registerAdapter(AgentChatMessageCacheAdapter());
      Hive.registerAdapter(AgentToolEventCacheAdapter());
      Hive.registerAdapter(AgentAttachmentCacheAdapter());
      Hive.registerAdapter(AgentMessagesCacheEntryAdapter());
    }
    testCache = AgentLocalCache(
      sessionBox: await Hive.openBox<AgentSessionCache>('agentSessionCache'),
      messagesBox: await Hive.openBox<AgentMessagesCacheEntry>(
        'agentMessagesCache',
      ),
      metaBox: await Hive.openBox<String>('agentMetaCache'),
    );
  });

  tearDown(() async {
    await Hive.close();
    Get.reset();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  test(
    'ready upload is submitted as an attachment without placeholder text',
    () async {
      final repository = _ActionsRepository();
      final controller = AgentController(
        repository: repository,
        localCache: testCache,
      );
      await controller.uploadAttachment('/local/doc.pdf', 'doc.pdf');
      expect(controller.pendingAttachments.single.name, 'doc.pdf');
      expect(
        repository.uploadSessionId,
        controller.activeClientSessionId.value,
      );
      await controller.sendMessage('');
      expect(repository.sentText, '');
      expect(repository.sentAttachments.single.localPath, '/server/doc.pdf');
      expect(controller.messages.first.content, '');
      expect(controller.messages.first.attachments.single.name, 'doc.pdf');
      expect(controller.pendingAttachments, isEmpty);
      repository.events.add(
        const AgentStreamEvent(
          type: 'attachment',
          raw: {
            'attachment': {
              'url': 'message/agent/file/result',
              'name': 'result.pdf',
            },
          },
        ),
      );
      repository.events.add(const AgentStreamEvent(type: 'done'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.messages.last.attachments.single.name, 'result.pdf');
      expect(controller.isSending.value, isFalse);
      controller.onClose();
      await repository.events.close();
    },
  );

  test('late upload is discarded when starting a new conversation', () async {
    final repository = _ActionsRepository()
      ..uploadGate = Completer<Map<String, dynamic>?>();
    final controller = AgentController(
      repository: repository,
      localCache: testCache,
    );
    final upload = controller.uploadAttachment('/local/doc.pdf', 'doc.pdf');
    expect(controller.isUploading.value, isTrue);
    await controller.startNewSession();
    repository.uploadGate!.complete(repository.receipt);
    expect(await upload, isNull);
    expect(controller.pendingAttachments, isEmpty);
    expect(controller.isUploading.value, isFalse);
    controller.onClose();
    await repository.events.close();
  });

  test(
    'failed stop still cancels local SSE and ignores subsequent events',
    () async {
      final repository = _ActionsRepository()
        ..stopError = StateError('offline');
      final controller = AgentController(
        repository: repository,
        localCache: testCache,
      );
      await controller.sendMessage('hello');
      repository.events.add(
        const AgentStreamEvent(type: 'start', sessionId: 'web-agent:stop'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(await controller.stopActiveSession(), isFalse);
      expect(repository.stoppedSessionId, 'web-agent:stop');
      expect(controller.isSending.value, isFalse);
      expect(controller.messages.last.status, AgentMessageStatus.done);
      repository.events.add(
        const AgentStreamEvent(type: 'delta', content: 'late'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.messages.last.content, isEmpty);
      controller.onClose();
      await repository.events.close();
    },
  );

  test(
    'stop before stream handshake uses client id and cancels late stream',
    () async {
      final repository = _ActionsRepository()
        ..sendGate = Completer<Stream<AgentStreamEvent>>();
      final controller = AgentController(
        repository: repository,
        localCache: testCache,
      );
      final send = controller.sendMessage('first');
      await controller.sendMessage('duplicate');
      expect(repository.sendCalls, 1);
      expect(await controller.stopActiveSession(), isTrue);
      expect(repository.stoppedSessionId, startsWith('mobile-'));
      repository.sendGate!.complete(repository.events.stream);
      await send;
      expect(repository.events.hasListener, isFalse);
      expect(controller.messages.length, 2);
      expect(controller.isSending.value, isFalse);
      controller.onClose();
      await repository.events.close();
    },
  );

  test('new session resets active sending and permits the next send', () async {
    final repository = _ActionsRepository();
    final controller = AgentController(
      repository: repository,
      localCache: testCache,
    );
    await controller.sendMessage('first');
    await controller.startNewSession();
    expect(controller.isSending.value, isFalse);
    expect(controller.messages, isEmpty);
    await repository.events.close();
    repository.events = StreamController<AgentStreamEvent>.broadcast();
    await controller.sendMessage('second');
    expect(repository.sendCalls, 2);
    expect(controller.messages.first.content, 'second');
    controller.onClose();
    await repository.events.close();
  });

  for (final fails in [false, true]) {
    test('new conversation ignores stale history (failure: $fails)', () async {
      final repository = _ActionsRepository()
        ..historyGate = Completer<List<AgentChatMessage>>();
      final controller = AgentController(
        repository: repository,
        localCache: testCache,
      );
      final loading = controller.loadSession(
        const AgentSession(
          sessionId: 'old',
          clientSessionId: 'old-client',
          title: 'Old',
          messageCount: 1,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.isLoadingMessages.value, isTrue);
      await controller.startNewSession();
      expect(controller.isLoadingMessages.value, isFalse);
      expect(controller.canSend, isTrue);
      await controller.sendMessage('new conversation');
      if (fails) {
        repository.historyGate!.completeError(StateError('old history failed'));
      } else {
        repository.historyGate!.complete([
          AgentChatMessage(
            id: 'stale',
            role: 'assistant',
            content: 'old conversation',
            createdAt: DateTime(2026),
            status: AgentMessageStatus.done,
          ),
        ]);
      }
      await loading;
      expect(controller.messages.first.content, 'new conversation');
      expect(controller.messageError.value, isNull);
      expect(controller.isLoadingMessages.value, isFalse);
      controller.onClose();
      await repository.events.close();
    });
  }

  test('handshake timeout settles state and cancels a late stream', () async {
    final repository = _ActionsRepository()
      ..sendGate = Completer<Stream<AgentStreamEvent>>();
    final controller = AgentController(
      repository: repository,
      localCache: testCache,
      streamIdleTimeout: const Duration(milliseconds: 20),
    );
    final sending = controller.sendMessage('hello');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(controller.isSending.value, isFalse);
    expect(controller.messages.last.status, AgentMessageStatus.failed);
    expect(controller.messageError.value, '响应超时，请重试');
    repository.sendGate!.complete(repository.events.stream);
    await sending;
    expect(repository.events.hasListener, isFalse);
    controller.onClose();
    await repository.events.close();
  });

  test('onInit hydrates messages from local cache', () async {
    await testCache.saveLastSession(
      serverSessionId: 'web-agent:cached',
      clientSessionId: 'mobile-cached',
    );
    await testCache.saveMessages('web-agent:cached', [
      AgentChatMessage(
        id: 'assistant-cached',
        role: 'assistant',
        content: '缓存消息',
        createdAt: DateTime(2026),
        status: AgentMessageStatus.done,
      ),
    ]);

    final controller = Get.put(
      AgentController(
        repository: _FakeAgentRepository(),
        localCache: testCache,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.messages.single.content, '缓存消息');
    expect(controller.activeServerSessionId.value, 'web-agent:cached');
  });

  test('sendMessage merges start, tool, and delta stream events', () async {
    final controller = AgentController(
      repository: _FakeAgentRepository(),
      localCache: testCache,
    );

    await controller.sendMessage('推荐历史纪录片');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.activeServerSessionId.value, 'web-agent:abc');
    expect(controller.messages.length, 2);
    expect(controller.messages.first.role, 'user');
    expect(controller.messages.last.role, 'assistant');
    expect(controller.messages.last.content, '你好，世界');
    expect(controller.messages.last.tools.single.message, '执行了 1 次搜索');
    expect(controller.messages.last.status, AgentMessageStatus.done);
    expect(controller.isSending.value, isFalse);
  });

  test('onInit restores last opened session from persisted id', () async {
    await testCache.saveLastSession(
      serverSessionId: 'web-agent:last',
      clientSessionId: 'mobile-last',
    );

    final controller = Get.put(
      AgentController(
        repository: _RestoringAgentRepository(),
        localCache: testCache,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.activeServerSessionId.value, 'web-agent:last');
    expect(controller.activeClientSessionId.value, 'mobile-last');
    expect(controller.messages.single.content, '上次会话');
  });

  test('local cache is isolated by user scope', () async {
    var scope = 'https://server.example|1';
    final scopedCache = AgentLocalCache(
      sessionBox: await Hive.openBox<AgentSessionCache>(
        'scopedAgentSessionCache',
      ),
      messagesBox: await Hive.openBox<AgentMessagesCacheEntry>(
        'scopedAgentMessagesCache',
      ),
      metaBox: await Hive.openBox<String>('scopedAgentMetaCache'),
      scopeKeyProvider: () => scope,
    );

    await scopedCache.saveSessions([
      const AgentSession(
        sessionId: 'web-agent:a',
        clientSessionId: 'mobile-a',
        title: '用户 A',
        messageCount: 1,
      ),
    ]);
    await scopedCache.saveMessages('web-agent:a', [
      AgentChatMessage(
        id: 'message-a',
        role: 'assistant',
        content: '用户 A 消息',
        createdAt: DateTime(2026),
        status: AgentMessageStatus.done,
      ),
    ]);
    await scopedCache.saveLastSession(
      serverSessionId: 'web-agent:a',
      clientSessionId: 'mobile-a',
    );

    scope = 'https://server.example|2';

    expect(await scopedCache.loadSessions(), isEmpty);
    expect(await scopedCache.loadMessages('web-agent:a'), isEmpty);
    expect(await scopedCache.loadLastSession(), isNull);

    await scopedCache.saveSessions([
      const AgentSession(
        sessionId: 'web-agent:b',
        clientSessionId: 'mobile-b',
        title: '用户 B',
        messageCount: 1,
      ),
    ]);

    scope = 'https://server.example|1';

    final sessions = await scopedCache.loadSessions();
    final messages = await scopedCache.loadMessages('web-agent:a');
    final lastSession = await scopedCache.loadLastSession();

    expect(sessions.single.title, '用户 A');
    expect(messages.single.content, '用户 A 消息');
    expect(lastSession?.serverSessionId, 'web-agent:a');
  });

  test('sendMessage uses server session id after start event', () async {
    final repository = _CapturingAgentRepository();
    final controller = AgentController(
      repository: repository,
      localCache: testCache,
    );

    await controller.sendMessage('第一条');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await controller.sendMessage('第二条');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.sentSessionIds.length, 2);
    expect(repository.sentSessionIds.first, startsWith('mobile-'));
    expect(repository.sentSessionIds.last, 'web-agent:server');
  });

  test('loadSession keeps local messages when API returns empty', () async {
    final controller = AgentController(
      repository: _SwitchingAgentRepository(),
      localCache: testCache,
    );

    controller.activeServerSessionId.value = 'web-agent:a';
    controller.activeClientSessionId.value = 'mobile-a';
    controller.messages.assignAll([
      AgentChatMessage(
        id: 'user-a',
        role: 'user',
        content: '本地消息',
        createdAt: DateTime(2026),
        status: AgentMessageStatus.done,
      ),
    ]);
    await testCache.saveMessages('web-agent:a', controller.messages);

    await controller.loadSession(
      const AgentSession(
        sessionId: 'web-agent:b',
        clientSessionId: 'mobile-b',
        title: 'B',
        messageCount: 0,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await controller.loadSession(
      const AgentSession(
        sessionId: 'web-agent:a',
        clientSessionId: 'mobile-a',
        title: 'A',
        messageCount: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.messages.single.content, '本地消息');
  });

  test(
    'sendMessage keeps history without refetching session messages',
    () async {
      final repository = _TrackingAgentRepository();
      final controller = AgentController(
        repository: repository,
        localCache: testCache,
      );

      controller.activeServerSessionId.value = 'web-agent:partial';
      controller.activeClientSessionId.value = 'mobile-partial';
      controller.messages.assignAll([
        AgentChatMessage(
          id: 'user-1',
          role: 'user',
          content: '第一条',
          createdAt: DateTime(2026, 1, 1),
          status: AgentMessageStatus.done,
        ),
        AgentChatMessage(
          id: 'assistant-1',
          role: 'assistant',
          content: '第一条回复',
          createdAt: DateTime(2026, 1, 1, 0, 0, 1),
          status: AgentMessageStatus.done,
        ),
      ]);

      await controller.sendMessage('第二条');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.fetchMessagesCalls, 0);
      expect(controller.messages.length, 4);
      expect(controller.messages.first.content, '第一条');
    },
  );

  test(
    'idle timeout aborts stalled stream without blocking next message',
    () async {
      final repository = _StalledStreamAgentRepository();
      final controller = AgentController(
        repository: repository,
        localCache: testCache,
        streamIdleTimeout: const Duration(milliseconds: 40),
      );

      controller.activeServerSessionId.value = 'web-agent:stall';
      controller.activeClientSessionId.value = 'mobile-stall';

      unawaited(controller.sendMessage('第一条'));
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(controller.isSending.value, isFalse);
      expect(controller.messages.length, 2);
      expect(controller.messages.last.status, AgentMessageStatus.failed);
      expect(controller.messageError.value, '响应超时，请重试');

      await controller.sendMessage('第二条');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.messages.length, 4);
      expect(controller.messages.last.content, '第二条回复');
      expect(controller.isSending.value, isFalse);
    },
  );
}

class _ActionsRepository extends _FakeAgentRepository
    implements AgentRepositoryActions {
  StreamController<AgentStreamEvent> events =
      StreamController<AgentStreamEvent>.broadcast();
  Completer<Stream<AgentStreamEvent>>? sendGate;
  Completer<Map<String, dynamic>?>? uploadGate;
  Completer<List<AgentChatMessage>>? historyGate;
  Object? stopError;
  String? stoppedSessionId;
  String? uploadSessionId;
  String? sentText;
  List<AgentAttachment> sentAttachments = [];
  int sendCalls = 0;
  final receipt = <String, dynamic>{
    'ref': 'message/agent/file/doc',
    'url': 'message/agent/file/doc',
    'name': 'doc.pdf',
    'mime_type': 'application/pdf',
    'local_path': '/server/doc.pdf',
    'status': 'ready',
    'size': 3,
  };

  @override
  Future<Stream<AgentStreamEvent>> sendMessage({
    required String text,
    required String sessionId,
    String? clientSessionId,
  }) async {
    sendCalls++;
    sentText = text;
    return sendGate?.future ?? Future.value(events.stream);
  }

  @override
  Future<Stream<AgentStreamEvent>> sendMessageWithAttachments({
    required String text,
    required String sessionId,
    String? clientSessionId,
    required List<AgentAttachment> attachments,
  }) async {
    sentAttachments = attachments;
    return sendMessage(
      text: text,
      sessionId: sessionId,
      clientSessionId: clientSessionId,
    );
  }

  @override
  Future<List<AgentChatMessage>> fetchSessionMessages(String sessionId) async =>
      historyGate?.future ?? Future.value(const <AgentChatMessage>[]);

  @override
  Future<List<Map<String, dynamic>>> fetchCommands() async => [
    {'command': '/search'},
  ];

  @override
  Future<Map<String, dynamic>?> uploadAttachment(
    String filePath,
    String fileName, {
    String? sessionId,
  }) async {
    uploadSessionId = sessionId;
    return uploadGate?.future ?? Future.value(receipt);
  }

  @override
  Future<bool> stopSession(String sessionId) async {
    stoppedSessionId = sessionId;
    if (stopError != null) throw stopError!;
    return true;
  }

  @override
  Future<Uint8List> downloadAttachment(AgentAttachment attachment) async =>
      Uint8List.fromList([1]);
}

class _FakeAgentRepository implements AgentRepositoryContract {
  @override
  Future<List<AgentSession>> fetchSessions({
    int page = 1,
    int count = 30,
  }) async {
    return const [];
  }

  @override
  Future<List<AgentChatMessage>> fetchSessionMessages(String sessionId) async {
    return const [];
  }

  @override
  Future<Stream<AgentStreamEvent>> sendMessage({
    required String text,
    required String sessionId,
    String? clientSessionId,
  }) async {
    return Stream<AgentStreamEvent>.fromIterable(const [
      AgentStreamEvent(type: 'start', sessionId: 'web-agent:abc'),
      AgentStreamEvent(type: 'tool', message: '执行了 1 次搜索'),
      AgentStreamEvent(type: 'delta', content: '你好'),
      AgentStreamEvent(type: 'delta', content: '，世界'),
    ]);
  }
}

class _RestoringAgentRepository implements AgentRepositoryContract {
  @override
  Future<List<AgentSession>> fetchSessions({
    int page = 1,
    int count = 30,
  }) async {
    return const [
      AgentSession(
        sessionId: 'web-agent:last',
        clientSessionId: 'mobile-last',
        title: '上次',
        messageCount: 1,
      ),
    ];
  }

  @override
  Future<List<AgentChatMessage>> fetchSessionMessages(String sessionId) async {
    return [
      AgentChatMessage(
        id: 'assistant-last',
        role: 'assistant',
        content: '上次会话',
        createdAt: DateTime(2026),
        status: AgentMessageStatus.done,
      ),
    ];
  }

  @override
  Future<Stream<AgentStreamEvent>> sendMessage({
    required String text,
    required String sessionId,
    String? clientSessionId,
  }) async {
    return const Stream<AgentStreamEvent>.empty();
  }
}

class _CapturingAgentRepository implements AgentRepositoryContract {
  final sentSessionIds = <String>[];

  @override
  Future<List<AgentSession>> fetchSessions({
    int page = 1,
    int count = 30,
  }) async {
    return const [];
  }

  @override
  Future<List<AgentChatMessage>> fetchSessionMessages(String sessionId) async {
    return const [];
  }

  @override
  Future<Stream<AgentStreamEvent>> sendMessage({
    required String text,
    required String sessionId,
    String? clientSessionId,
  }) async {
    sentSessionIds.add(sessionId);
    if (sentSessionIds.length == 1) {
      return Stream<AgentStreamEvent>.fromIterable(const [
        AgentStreamEvent(type: 'start', sessionId: 'web-agent:server'),
        AgentStreamEvent(type: 'delta', content: '收到'),
      ]);
    }
    return Stream<AgentStreamEvent>.fromIterable(const [
      AgentStreamEvent(type: 'delta', content: '继续'),
    ]);
  }
}

class _SwitchingAgentRepository implements AgentRepositoryContract {
  @override
  Future<List<AgentSession>> fetchSessions({
    int page = 1,
    int count = 30,
  }) async {
    return const [];
  }

  @override
  Future<List<AgentChatMessage>> fetchSessionMessages(String sessionId) async {
    return const [];
  }

  @override
  Future<Stream<AgentStreamEvent>> sendMessage({
    required String text,
    required String sessionId,
    String? clientSessionId,
  }) async {
    return const Stream<AgentStreamEvent>.empty();
  }
}

class _TrackingAgentRepository implements AgentRepositoryContract {
  int fetchMessagesCalls = 0;

  @override
  Future<List<AgentSession>> fetchSessions({
    int page = 1,
    int count = 30,
  }) async {
    return const [];
  }

  @override
  Future<List<AgentChatMessage>> fetchSessionMessages(String sessionId) async {
    fetchMessagesCalls += 1;
    return [
      AgentChatMessage(
        id: 'user-latest',
        role: 'user',
        content: '第二条',
        createdAt: DateTime(2026, 1, 1, 0, 1),
        status: AgentMessageStatus.done,
      ),
      AgentChatMessage(
        id: 'assistant-latest',
        role: 'assistant',
        content: '仅最新一轮',
        createdAt: DateTime(2026, 1, 1, 0, 1, 1),
        status: AgentMessageStatus.done,
      ),
    ];
  }

  @override
  Future<Stream<AgentStreamEvent>> sendMessage({
    required String text,
    required String sessionId,
    String? clientSessionId,
  }) async {
    return Stream<AgentStreamEvent>.fromIterable(const [
      AgentStreamEvent(type: 'delta', content: '第二条回复'),
      AgentStreamEvent(type: 'done'),
    ]);
  }
}

class _StalledStreamAgentRepository implements AgentRepositoryContract {
  var sendCount = 0;

  @override
  Future<List<AgentSession>> fetchSessions({
    int page = 1,
    int count = 30,
  }) async {
    return const [];
  }

  @override
  Future<List<AgentChatMessage>> fetchSessionMessages(String sessionId) async {
    return const [];
  }

  @override
  Future<Stream<AgentStreamEvent>> sendMessage({
    required String text,
    required String sessionId,
    String? clientSessionId,
  }) async {
    sendCount += 1;
    if (sendCount == 1) {
      final controller = StreamController<AgentStreamEvent>();
      controller.add(
        const AgentStreamEvent(type: 'start', sessionId: 'web-agent:stall'),
      );
      return controller.stream;
    }
    return Stream<AgentStreamEvent>.fromIterable(const [
      AgentStreamEvent(type: 'delta', content: '第二条回复'),
      AgentStreamEvent(type: 'done'),
    ]);
  }
}
