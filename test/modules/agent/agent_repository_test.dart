import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';
import 'package:moviepilot_mobile/modules/agent/repositories/agent_repository.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

void main() {
  late _ApiClient client;
  late AgentRepository repository;

  tearDown(Get.reset);

  setUp(() {
    Get.testMode = true;
    Get.put(AppLog());
    client = _ApiClient();
    repository = AgentRepository(apiClient: client);
  });

  test('sessions and history support V2 and V3 response shapes', () async {
    final sessions = [
      {'session_id': 'web-agent:test', 'title': 'Test', 'message_count': 1},
    ];
    final history = {
      'messages': [
        {'id': 'reply', 'role': 'assistant', 'content': 'hello'},
      ],
    };
    for (final wrapped in [false, true]) {
      client.response = wrapped
          ? {'success': true, 'data': sessions}
          : sessions;
      expect(
        (await repository.fetchSessions()).single.sessionId,
        'web-agent:test',
      );
      client.response = wrapped ? {'success': true, 'data': history} : history;
      expect(
        (await repository.fetchSessionMessages(
          'web-agent:test',
        )).single.content,
        'hello',
      );
      expect(client.path, '/api/v1/message/agent/sessions/web-agent%3Atest');
    }
    client.response = {'success': false, 'message': 'denied'};
    await expectLater(repository.fetchSessions(), throwsStateError);
    await expectLater(
      repository.fetchSessionMessages('test'),
      throwsStateError,
    );
  });

  test('commands accept V2 envelopes and V3 unwrapped lists', () async {
    final commands = [
      {'command': '/search', 'description': 'Search', 'category': 'Media'},
      {'command': ''},
    ];
    for (final data in [
      {'success': true, 'data': commands},
      commands,
    ]) {
      client.response = data;
      expect((await repository.fetchCommands()).single['command'], '/search');
      expect(client.path, '/api/v1/message/agent/commands');
    }
    client.response = {'success': false, 'message': '管理员限定'};
    await expectLater(repository.fetchCommands(), throwsStateError);
    client.status = 403;
    client.response = [];
    await expectLater(repository.fetchCommands(), throwsStateError);
  });

  test(
    'upload multipart preserves ready receipt and rejects failed receipts',
    () async {
      final directory = await Directory.systemTemp.createTemp('agent_upload');
      addTearDown(() => directory.delete(recursive: true));
      final file = await File(
        '${directory.path}/sample.png',
      ).writeAsBytes([1, 2, 3]);
      final receipt = {
        'ref': 'message/agent/file/abc',
        'url': 'message/agent/file/abc',
        'local_path': '/server/temp/sample.png',
        'name': 'sample.png',
        'mime_type': 'image/png',
        'kind': 'image',
        'size': 3,
        'status': 'ready',
      };
      for (final data in [
        {'success': true, 'data': receipt},
        receipt,
      ]) {
        client.response = data;
        expect(
          await repository.uploadAttachment(
            file.path,
            'sample.png',
            sessionId: 'mobile-1',
          ),
          receipt,
        );
        expect(client.path, '/api/v1/message/agent/upload');
        expect(Map.fromEntries(client.form!.fields), {
          'session_id': 'mobile-1',
        });
        expect(client.form!.files.single.key, 'file');
        expect(client.form!.files.single.value.filename, 'sample.png');
        expect(
          client.form!.files.single.value.contentType.toString(),
          'image/png',
        );
      }
      for (final data in [
        {'success': false, 'message': '失败'},
        {
          'success': true,
          'data': {'id': 'not-a-ref'},
        },
        null,
      ]) {
        client.response = data;
        await expectLater(
          repository.uploadAttachment(file.path, 'sample.png'),
          throwsStateError,
        );
      }
      client.status = 413;
      await expectLater(
        repository.uploadAttachment(file.path, 'sample.png'),
        throwsStateError,
      );
    },
  );

  test(
    'stream sends schema file objects and audio refs without invented fields',
    () async {
      final file = AgentAttachment.fromJson({
        'ref': 'message/agent/file/doc',
        'name': 'doc.pdf',
        'mime_type': 'application/pdf',
        'local_path': '/server/doc.pdf',
        'size': 123,
        'status': 'ready',
      });
      final audio = AgentAttachment.fromJson({
        'ref': 'message/agent/file/audio',
        'kind': 'audio',
        'mime_type': 'audio/mp4',
      });
      final stream = await repository.sendMessageWithAttachments(
        text: '',
        sessionId: 'mobile-session',
        clientSessionId: 'client-only',
        attachments: [file, audio],
      );
      expect((await stream.toList()).single.type, 'done');
      expect(client.path, '/api/v1/message/agent/stream');
      expect(client.payload, {
        'text': '',
        'session_id': 'mobile-session',
        'images': [],
        'files': [
          {
            'ref': 'message/agent/file/doc',
            'name': 'doc.pdf',
            'mime_type': 'application/pdf',
            'local_path': '/server/doc.pdf',
            'size': 123,
            'status': 'ready',
          },
        ],
        'audio_refs': ['message/agent/file/audio'],
        'echo_user': true,
      });
      await repository.sendMessage(text: 'hello', sessionId: 'server-session');
      expect((client.payload as Map)['files'], isEmpty);
    },
  );

  test('stop reads stopped flag rather than envelope success', () async {
    for (final data in [
      {
        'success': true,
        'data': {'stopped': false},
      },
      {'stopped': false},
    ]) {
      client.response = data;
      expect(await repository.stopSession('web-agent:a/b'), isFalse);
      expect(
        client.path,
        '/api/v1/message/agent/sessions/web-agent%3Aa%2Fb/stop',
      );
    }
    client.response = {
      'success': true,
      'data': {'stopped': true},
    };
    expect(await repository.stopSession('session'), isTrue);
    client.response = {'success': false};
    await expectLater(repository.stopSession('session'), throwsStateError);
  });

  test(
    'download uses authenticated client with normalized same-server path',
    () async {
      for (final url in [
        'message/agent/file/abc',
        '/api/v1/message/agent/file/abc',
        'https://server.example/api/v1/message/agent/file/abc',
      ]) {
        final attachment = AgentAttachment.fromJson({'url': url});
        expect(await repository.downloadAttachment(attachment), [1, 2, 3]);
        expect(client.path, '/api/v1/message/agent/file/abc');
      }
      final calls = client.downloadCalls;
      for (final url in [
        'https://evil.example/api/v1/message/agent/file/abc',
        '//evil.example/api/v1/message/agent/file/abc',
        '/api/v1/user/',
        '/server/local/file',
        '/api/v1/message/agent/file/../secret',
        '/api/v1/message/agent/file/abc?token=secret',
      ]) {
        await expectLater(
          repository.downloadAttachment(AgentAttachment.fromJson({'url': url})),
          throwsA(isA<StateError>()),
        );
      }
      expect(client.downloadCalls, calls);
      client.bytes = null;
      await expectLater(
        repository.downloadAttachment(
          AgentAttachment.fromJson({'url': 'message/agent/file/expired'}),
        ),
        throwsStateError,
      );
    },
  );
}

class _ApiClient implements ApiClient {
  Object? response;
  int status = 200;
  String? path;
  Object? payload;
  FormData? form;
  int downloadCalls = 0;
  Uint8List? bytes = Uint8List.fromList([1, 2, 3]);

  @override
  String get baseUrl => 'https://server.example';

  Response<T> _response<T>(String path) {
    this.path = path;
    return Response<T>(
      data: response as T?,
      statusCode: status,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
    bool skipV3EnvelopeUnwrap = false,
  }) async => _response<T>(path);

  @override
  Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
  }) async => _response<T>(path);

  @override
  Future<Response<T>> postMultipart<T>(
    String path,
    FormData formData, {
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) async {
    form = formData;
    return _response<T>(path);
  }

  @override
  Future<Stream<String>> streamPostLines(
    String path, {
    Object? data,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) async {
    this.path = path;
    payload = data;
    return Stream.value('data: {"type":"done"}');
  }

  @override
  Future<Uint8List?> fetchResourceProxyImage(String absoluteUrl) async {
    path = absoluteUrl;
    downloadCalls++;
    return bytes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
