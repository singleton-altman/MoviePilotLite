import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';

void main() {
  test('parses agent session and history message payloads', () {
    final session = AgentSession.fromJson({
      'id': 2,
      'session_id': 'web-agent:abc',
      'client_session_id': 'web-123',
      'title': '历史纪录片推荐',
      'message_count': 2,
    });

    expect(session.sessionId, 'web-agent:abc');
    expect(session.clientSessionId, 'web-123');
    expect(session.messageCount, 2);

    final message = AgentChatMessage.fromJson({
      'id': 'assistant-1',
      'role': 'assistant',
      'content': 'hello',
      'createdAt': 1782443961996,
      'status': 'done',
      'tools': [
        {'id': 'tool-1', 'message': '执行了 10 次搜索', 'status': 'done'},
      ],
      'attachments': [
        {'name': 'cover', 'url': 'https://example.com/a.png'},
        {'filename': 'doc.pdf', 'href': 'https://example.com/doc.pdf'},
      ],
    });

    expect(message.isAssistant, isTrue);
    expect(message.tools.single.message, '执行了 10 次搜索');
    expect(message.attachments.first.isImage, isTrue);
    expect(message.attachments.last.isImage, isFalse);
  });

  test('parses sse data lines', () {
    final start = AgentStreamEvent.fromSseLine(
      'data: {"type":"start","session_id":"web-agent:abc"}',
    );
    final delta = AgentStreamEvent.fromSseLine(
      'data: {"type":"delta","content":"你好"}',
    );

    expect(start?.type, 'start');
    expect(start?.sessionId, 'web-agent:abc');
    expect(delta?.content, '你好');
    expect(AgentStreamEvent.fromSseLine('event: ping'), isNull);
  });
}
