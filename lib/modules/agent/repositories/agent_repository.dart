import 'dart:async';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';
import 'package:moviepilot_mobile/modules/agent/utils/agent_sse_logger.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

abstract class AgentRepositoryContract {
  Future<List<AgentSession>> fetchSessions({int page = 1, int count = 30});

  Future<List<AgentChatMessage>> fetchSessionMessages(String sessionId);

  Future<Stream<AgentStreamEvent>> sendMessage({
    required String text,
    required String sessionId,
    String? clientSessionId,
  });
}

/// Optional capabilities keep text-only repository implementations compatible.
abstract class AgentRepositoryActions {
  Future<Stream<AgentStreamEvent>> sendMessageWithAttachments({
    required String text,
    required String sessionId,
    String? clientSessionId,
    required List<AgentAttachment> attachments,
  });

  Future<Uint8List> downloadAttachment(AgentAttachment attachment);

  /// GET /api/v1/message/agent/commands 可用命令列表
  Future<List<Map<String, dynamic>>> fetchCommands();

  /// POST /api/v1/message/agent/upload 上传附件（multipart file）。
  /// 返回服务端回执（含附件 id/url 等）。
  Future<Map<String, dynamic>?> uploadAttachment(
    String filePath,
    String fileName, {
    String? sessionId,
  });

  /// POST /api/v1/message/agent/sessions/{id}/stop 停止当前任务
  Future<bool> stopSession(String sessionId);
}

class AgentRepository
    implements AgentRepositoryContract, AgentRepositoryActions {
  AgentRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? Get.find<ApiClient>();

  final ApiClient _apiClient;

  @override
  Future<List<Map<String, dynamic>>> fetchCommands() async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/message/agent/commands',
    );
    final data = _responseData(response, '命令列表加载失败');
    final rawList = data is List
        ? data
        : data is Map
        ? data['data']
        : null;
    if (rawList is! List) return const [];
    return rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where(
          (item) =>
              item['command'] is String &&
              (item['command'] as String).startsWith('/'),
        )
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> uploadAttachment(
    String filePath,
    String fileName, {
    String? sessionId,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();
    final mimeType = const {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'flac': 'audio/flac',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'csv': 'text/csv',
      'json': 'application/json',
    }[extension];
    final form = dio.FormData.fromMap({
      'file': await dio.MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: mimeType == null ? null : dio.DioMediaType.parse(mimeType),
      ),
      if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
    });
    final response = await _apiClient.postMultipart<dynamic>(
      '/api/v1/message/agent/upload',
      form,
    );
    final data = _responseData(response, '附件上传失败');
    if (data is! Map ||
        data['ref'] is! String ||
        (data['ref'] as String).trim().isEmpty) {
      throw StateError('服务端未返回有效的附件引用');
    }
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<bool> stopSession(String sessionId) async {
    final encoded = Uri.encodeComponent(sessionId);
    final response = await _apiClient.post<dynamic>(
      '/api/v1/message/agent/sessions/$encoded/stop',
    );
    final data = _responseData(response, '停止任务失败');
    return data is Map && data['stopped'] == true;
  }

  Object? _responseData(dio.Response<dynamic> response, String fallback) {
    final data = response.data;
    final status = response.statusCode ?? 0;
    if (status < 200 ||
        status >= 300 ||
        (data is Map && data['success'] == false)) {
      throw StateError(
        data is Map
            ? (data['message'] ?? data['detail'] ?? fallback).toString()
            : fallback,
      );
    }
    return data is Map && data.containsKey('data') ? data['data'] : data;
  }

  /// Only send credentials to this server's registered attachment endpoint.
  @override
  Future<Uint8List> downloadAttachment(AgentAttachment attachment) async {
    final raw = attachment.url.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw StateError('无效的附件地址');
    }
    String path;
    if (uri.hasScheme || uri.hasAuthority) {
      final base = Uri.tryParse(_apiClient.baseUrl ?? '');
      if (base == null || uri.origin != base.origin) {
        throw StateError('不能向外部附件地址发送认证信息');
      }
      path = uri.path;
    } else {
      path = raw.startsWith('message/agent/file/') ? '/api/v1/$raw' : raw;
    }
    if (!RegExp(r'^/api/v1/message/agent/file/[^/]+$').hasMatch(path) ||
        Uri.parse(
          path,
        ).pathSegments.any((part) => part == '.' || part == '..')) {
      throw StateError('不支持的附件地址');
    }
    final bytes = await _apiClient.fetchResourceProxyImage(path);
    if (bytes == null) throw StateError('附件下载失败，文件可能已过期');
    return bytes;
  }

  @override
  Future<List<AgentSession>> fetchSessions({
    int page = 1,
    int count = 30,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/message/agent/sessions',
      queryParameters: {'page': page, 'count': count},
    );
    final data = _responseData(response, '会话列表加载失败');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => AgentSession.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<List<AgentChatMessage>> fetchSessionMessages(String sessionId) async {
    final encodedSessionId = Uri.encodeComponent(sessionId);
    final response = await _apiClient.get<dynamic>(
      '/api/v1/message/agent/sessions/$encodedSessionId',
    );
    final sessionData = _responseData(response, '历史消息加载失败');
    if (sessionData is! Map) return const [];
    final messages = sessionData['messages'];
    if (messages is! List) return const [];
    return messages
        .whereType<Map>()
        .map(
          (item) => AgentChatMessage.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  @override
  Future<Stream<AgentStreamEvent>> sendMessage({
    required String text,
    required String sessionId,
    String? clientSessionId,
  }) => sendMessageWithAttachments(
    text: text,
    sessionId: sessionId,
    clientSessionId: clientSessionId,
    attachments: const [],
  );

  @override
  Future<Stream<AgentStreamEvent>> sendMessageWithAttachments({
    required String text,
    required String sessionId,
    String? clientSessionId,
    required List<AgentAttachment> attachments,
  }) async {
    final logger = AgentSseLogger();
    logger.logStreamStart(sessionId: sessionId, textLength: text.length);
    final payload = <String, dynamic>{
      'text': text,
      'session_id': sessionId,
      'images': const <String>[],
      'files': attachments
          .where((item) => !item.isAudio)
          .map((item) => item.toInputJson())
          .toList(growable: false),
      'audio_refs': attachments
          .where((item) => item.isAudio)
          .map((item) => item.inputRef)
          .toList(growable: false),
      'echo_user': true,
    };
    debugPrint('[Agent SSE] request payload: $payload');
    final lineStream = await _apiClient.streamPostLines(
      '/api/v1/message/agent/stream',
      data: payload,
    );
    return lineStream
        .map((line) {
          logger.logRawLine(line);
          return line;
        })
        .map(AgentStreamEvent.fromSseLine)
        .where((event) {
          if (event == null) return false;
          logger.logEvent(event);
          return true;
        })
        .cast<AgentStreamEvent>()
        .transform(
          StreamTransformer<AgentStreamEvent, AgentStreamEvent>.fromHandlers(
            handleDone: (sink) {
              logger.logStreamDone();
              sink.close();
            },
            handleError: (error, stackTrace, sink) {
              logger.logStreamError(error);
              sink.addError(error, stackTrace);
            },
          ),
        );
  }
}
