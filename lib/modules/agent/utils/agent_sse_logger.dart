import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';

class AgentSseLogger {
  AgentSseLogger({AppLog? log}) : _log = log ?? Get.find<AppLog>();

  final AppLog _log;
  int deltaCount = 0;

  void logStreamStart({required String sessionId, required int textLength}) {
    deltaCount = 0;
    _info('开始 sessionId=$sessionId textLen=$textLength');
  }

  void logRawLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;
    _debug('raw: $trimmed');
  }

  void logEvent(AgentStreamEvent event) {
    switch (event.type) {
      case 'delta':
        deltaCount += 1;
        final content = event.content ?? '';
        if (deltaCount <= 5) {
          _debug(
            '[delta#$deltaCount] len=${content.length} ${_preview(content)}',
          );
        } else if (deltaCount == 6) {
          _debug('[delta] 后续增量省略…');
        }
        return;
      case 'start':
        _info('[start] sessionId=${event.sessionId}');
        return;
      case 'tool':
        _info('[tool] ${event.message ?? ''}');
        return;
      case 'error':
        _error('[error] ${event.message ?? ''}');
        return;
      case 'done':
        _info('[done]');
        return;
      default:
        final detail = event.content ?? event.message ?? '';
        _info('[${event.type}] $detail');
    }
  }

  void logStreamDone() {
    _info('结束 deltaCount=$deltaCount');
  }

  void logStreamError(Object error) {
    _error('流错误: $error');
  }

  void logStreamCancelled() {
    _info('流已取消');
  }

  void _debug(String message) {
    debugPrint('[Agent SSE] $message');
    _log.debug('[Agent SSE] $message');
  }

  void _info(String message) {
    debugPrint('[Agent SSE] $message');
    _log.info('[Agent SSE] $message');
  }

  void _error(String message) {
    debugPrint('[Agent SSE] $message');
    _log.error('[Agent SSE] $message');
  }

  String _preview(String value) {
    final normalized = value.replaceAll('\n', r'\n');
    if (normalized.length <= 96) return '"$normalized"';
    return '"${normalized.substring(0, 96)}…"';
  }
}
