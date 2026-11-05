import 'package:hive_ce/hive.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';

part 'agent_cache_models.g.dart';

@HiveType(typeId: 9)
class AgentSessionCache {
  AgentSessionCache({
    this.id,
    required this.sessionId,
    required this.clientSessionId,
    required this.title,
    required this.messageCount,
    this.createdAt,
    this.updatedAt,
  });

  @HiveField(0)
  int? id;

  @HiveField(1)
  String sessionId;

  @HiveField(2)
  String clientSessionId;

  @HiveField(3)
  String title;

  @HiveField(4)
  int messageCount;

  @HiveField(5)
  String? createdAt;

  @HiveField(6)
  String? updatedAt;

  AgentSession toModel() {
    return AgentSession(
      id: id,
      sessionId: sessionId,
      clientSessionId: clientSessionId,
      title: title,
      messageCount: messageCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static AgentSessionCache fromModel(AgentSession session) {
    return AgentSessionCache(
      id: session.id,
      sessionId: session.sessionId,
      clientSessionId: session.clientSessionId,
      title: session.title,
      messageCount: session.messageCount,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
  }
}

@HiveType(typeId: 10)
class AgentChatMessageCache {
  AgentChatMessageCache({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
    this.tools = const [],
    this.attachments = const [],
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String role;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  String status;

  @HiveField(5)
  List<AgentToolEventCache> tools;

  @HiveField(6)
  List<AgentAttachmentCache> attachments;

  AgentChatMessage toModel() {
    return AgentChatMessage(
      id: id,
      role: role,
      content: content,
      createdAt: createdAt,
      status: AgentMessageStatus.values.firstWhere(
        (item) => item.name == status,
        orElse: () => AgentMessageStatus.done,
      ),
      tools: tools.map((tool) => tool.toModel()).toList(growable: false),
      attachments: attachments
          .map((attachment) => attachment.toModel())
          .where((item) => item.hasDisplayValue)
          .toList(growable: false),
    );
  }

  static AgentChatMessageCache fromModel(AgentChatMessage message) {
    return AgentChatMessageCache(
      id: message.id,
      role: message.role,
      content: message.content,
      createdAt: message.createdAt,
      status: message.status.name,
      tools: message.tools
          .map(AgentToolEventCache.fromModel)
          .toList(growable: false),
      attachments: message.attachments
          .map(AgentAttachmentCache.fromModel)
          .toList(growable: false),
    );
  }
}

@HiveType(typeId: 11)
class AgentToolEventCache {
  AgentToolEventCache({
    required this.id,
    required this.message,
    required this.status,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String message;

  @HiveField(2)
  String status;

  AgentToolEvent toModel() {
    return AgentToolEvent(id: id, message: message, status: status);
  }

  static AgentToolEventCache fromModel(AgentToolEvent tool) {
    return AgentToolEventCache(
      id: tool.id,
      message: tool.message,
      status: tool.status,
    );
  }
}

@HiveType(typeId: 12)
class AgentAttachmentCache {
  AgentAttachmentCache({
    required this.id,
    required this.name,
    required this.url,
    required this.mimeType,
    required this.type,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  String mimeType;

  @HiveField(4)
  String type;

  AgentAttachment toModel() {
    return AgentAttachment(
      id: id,
      name: name,
      url: url,
      mimeType: mimeType,
      type: type,
    );
  }

  static AgentAttachmentCache fromModel(AgentAttachment attachment) {
    return AgentAttachmentCache(
      id: attachment.id,
      name: attachment.name,
      url: attachment.url,
      mimeType: attachment.mimeType,
      type: attachment.type,
    );
  }
}

@HiveType(typeId: 13)
class AgentMessagesCacheEntry {
  AgentMessagesCacheEntry({required this.messages});

  @HiveField(0)
  List<AgentChatMessageCache> messages;
}
