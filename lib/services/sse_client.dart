import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:get/get.dart';

/// SSE (Server-Sent Events) 客户端
/// 用于监听服务器推送的实时事件流
class SseClient {
  final _log = Get.find<AppLog>();
  final Dio _dio;
  final String baseUrl;
  final Map<String, String>? headers;

  CancelToken? _cancelToken;
  StreamController<SseEvent>? _streamController;

  SseClient({required this.baseUrl, this.headers, Dio? dio})
    : _dio = dio ?? Dio();

  /// 连接 SSE 端点并返回事件流
  Stream<SseEvent> connect(String endpoint) {
    _cancelToken = CancelToken();
    _streamController = StreamController<SseEvent>.broadcast(
      onCancel: () {
        _log.info('SSE stream cancelled');
        disconnect();
      },
    );

    final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    _log.info('Connecting to SSE: $url');

    _dio
        .get<ResponseBody>(
          url,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'Accept': 'text/event-stream',
              'Cache-Control': 'no-cache',
              ...?headers,
            },
          ),
          cancelToken: _cancelToken,
        )
        .then((response) {
          final statusCode = response.statusCode ?? 0;
          if (statusCode >= 400) {
            _log.error('SSE HTTP error: $statusCode');
            _streamController?.addError('HTTP $statusCode');
            _streamController?.close();
            return;
          }
          _handleStream(response.data);
        })
        .catchError((error) {
          if (error is DioException && error.type == DioExceptionType.cancel) {
            _log.info('SSE connection cancelled');
          } else {
            _log.error('SSE connection error: $error');
          }
          if (!(_streamController?.isClosed ?? true)) {
            _streamController?.addError(error);
            _streamController?.close();
          }
        });

    return _streamController!.stream;
  }

  /// 处理 SSE 流数据
  void _handleStream(ResponseBody? responseBody) {
    if (responseBody == null) {
      _streamController?.close();
      return;
    }

    String buffer = '';

    responseBody.stream
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(
          (line) {
            _log.debug('SSE raw line: $line');

            // SSE 格式: 空行表示一个事件结束
            if (line.isEmpty) {
              if (buffer.isNotEmpty) {
                final event = _parseEvent(buffer);
                if (event != null) {
                  _streamController?.add(event);
                }
                buffer = '';
              }
              return;
            }

            buffer += '$line\n';
          },
          onError: (error) {
            _log.error('SSE stream error: $error');
            _streamController?.addError(error);
          },
          onDone: () {
            _log.info('SSE stream closed');
            _streamController?.close();
          },
          cancelOnError: false,
        );
  }

  /// 解析 SSE 事件
  SseEvent? _parseEvent(String data) {
    String? event;
    final dataBuffer = StringBuffer();
    String? id;
    int? retry;

    final lines = data.split('\n');
    for (final line in lines) {
      if (line.isEmpty) continue;

      // 注释行，忽略
      if (line.startsWith(':')) continue;

      final colonIndex = line.indexOf(':');
      if (colonIndex == -1) continue;

      final field = line.substring(0, colonIndex);
      final value = line.substring(colonIndex + 1).trimLeft();

      switch (field) {
        case 'event':
          event = value;
          break;
        case 'data':
          if (dataBuffer.isNotEmpty) {
            dataBuffer.writeln();
          }
          dataBuffer.write(value);
          break;
        case 'id':
          id = value;
          break;
        case 'retry':
          retry = int.tryParse(value);
          break;
        default:
          break;
      }
    }

    final eventData = dataBuffer.toString().trim();
    if (eventData.isEmpty) return null;

    return SseEvent(
      event: event ?? 'message',
      data: eventData,
      id: id,
      retry: retry,
    );
  }

  /// 断开 SSE 连接
  void disconnect() {
    _log.info('Disconnecting SSE');
    _cancelToken?.cancel('User disconnected');
    _cancelToken = null;
    if (!(_streamController?.isClosed ?? true)) {
      _streamController?.close();
    }
    _streamController = null;
  }

  /// 检查是否已连接
  bool get isConnected =>
      _cancelToken != null && !(_cancelToken?.isCancelled ?? true);
}

/// SSE 事件数据类
class SseEvent {
  final String event;
  final String data;
  final String? id;
  final int? retry;

  const SseEvent({
    required this.event,
    required this.data,
    this.id,
    this.retry,
  });

  /// 尝试将 data 解析为 JSON
  Map<String, dynamic>? get jsonData {
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'SseEvent(event: $event, data: $data, id: $id, retry: $retry)';
}

/// 搜索进度事件
/// 响应格式: {"enable": false, "value": 100, "text": "", "data": {}}
class SearchProgressEvent {
  final bool enable; // 是否启用进度
  final double value; // 进度值 0-100
  final String? text; // 进度文本
  final Map<String, dynamic>? data; // 额外数据

  const SearchProgressEvent({
    required this.enable,
    required this.value,
    this.text,
    this.data,
  });

  factory SearchProgressEvent.fromJson(Map<String, dynamic> json) {
    return SearchProgressEvent(
      enable: json['enable'] as bool? ?? false,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      text: json['text']?.toString(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  /// 获取进度 0.0 - 1.0
  double get progress => (value / 100).clamp(0.0, 1.0);

  /// 获取状态
  String get status {
    if (!enable) return 'completed';
    if (value >= 100) return 'completed';
    return 'searching';
  }

  /// 获取消息
  String? get message => text;

  bool get isCompleted => status == 'completed';
  bool get isSearching => status == 'searching';
  bool get isFailed => status == 'failed';

  @override
  String toString() =>
      'SearchProgressEvent(enable: $enable, value: $value%, text: $text)';
}
