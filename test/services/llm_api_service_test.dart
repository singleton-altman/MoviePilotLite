import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/llm_api_service.dart';

class _Adapter implements HttpClientAdapter {
  final captured = <RequestOptions>[];
  Map<String, dynamic> Function(RequestOptions options)? responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);
    return ResponseBody.fromString(
      jsonEncode(responder!(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Api implements ApiClient {
  @override
  String? baseUrl = 'https://mp.example/';
  @override
  String? token = 'jwt-token';

  @override
  Future<String?> getCookieHeader({String? url, bool preferCache = true}) async {
    return 'sid=1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LlmApiService _service(_Adapter adapter, bool v3) {
  final dio = Dio()..httpClientAdapter = adapter;
  return LlmApiService(
    apiClient: _Api(),
    isV3: () async => v3,
    dio: dio,
  );
}

void main() {
  test('V2 uses GET llm/models with provider query and parses both shapes',
      () async {
    final adapter = _Adapter()
      ..responder = (options) => {
        'success': true,
        'data': [
          'gpt-4o',
          {'id': 'claude-x', 'name': 'Claude'},
        ],
      };
    final catalog = await _service(adapter, false).listModels(
      provider: 'openai',
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    final request = adapter.captured.single;
    expect(request.method, 'GET');
    expect(request.uri.host, 'mp.example');
    expect(request.uri.path, '/api/v1/llm/models');
    expect(request.queryParameters['provider'], 'openai');
    expect(request.headers['authorization'], 'Bearer jwt-token');
    expect(request.headers['cookie'], 'sid=1');
    expect(catalog.models.map((m) => m.id), ['gpt-4o', 'claude-x']);
    expect(catalog.models[1].name, 'Claude');
  });

  test('V3 uses POST llm/manage with target/action list_models', () async {
    final adapter = _Adapter()
      ..responder = (options) => {
        'success': true,
        'data': {
          'models': [
            {'id': 'gpt-4o', 'name': 'GPT-4o'},
          ],
          'auth_status': {'openai': 'authorized'},
        },
      };
    final catalog = await _service(adapter, true).listModels(
      provider: 'openai',
      apiKey: 'sk-test',
      baseUrl: 'https://api.openai.com/v1',
    );

    final request = adapter.captured.single;
    expect(request.method, 'POST');
    expect(request.uri.host, 'mp.example');
    expect(request.uri.path, '/api/v1/llm/manage');
    expect(request.data, {
      'target': 'openai',
      'action': 'list_models',
      'params': {
        'api_key': 'sk-test',
        'base_url': 'https://api.openai.com/v1',
      },
    });
    expect(catalog.models.single.id, 'gpt-4o');
    expect(catalog.authStatus, {'openai': 'authorized'});
  });

  test('business failure surfaces message and never yields a catalog',
      () async {
    final adapter = _Adapter()
      ..responder = (options) => {'success': false, 'message': '密钥无效'};
    await expectLater(
      _service(adapter, true).listModels(provider: 'openai'),
      throwsA(predicate((e) => e.toString().contains('密钥无效'))),
    );
  });
}
