import 'dart:convert';

enum AgentMessageStatus { sending, streaming, done, failed }

class AgentSession {
  const AgentSession({
    this.id,
    required this.sessionId,
    required this.clientSessionId,
    required this.title,
    required this.messageCount,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String sessionId;
  final String clientSessionId;
  final String title;
  final int messageCount;
  final String? createdAt;
  final String? updatedAt;

  factory AgentSession.fromJson(Map<String, dynamic> json) {
    return AgentSession(
      id: _readInt(json['id']),
      sessionId: _readString(json['session_id']),
      clientSessionId: _readString(json['client_session_id']),
      title: _readString(json['title'], fallback: '新的对话'),
      messageCount: _readInt(json['message_count']) ?? 0,
      createdAt: _readNullableString(json['created_at']),
      updatedAt: _readNullableString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'client_session_id': clientSessionId,
      'title': title,
      'message_count': messageCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

class AgentChatMessage {
  const AgentChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
    this.tools = const [],
    this.attachments = const [],
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final AgentMessageStatus status;
  final List<AgentToolEvent> tools;
  final List<AgentAttachment> attachments;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  AgentChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? createdAt,
    AgentMessageStatus? status,
    List<AgentToolEvent>? tools,
    List<AgentAttachment>? attachments,
  }) {
    return AgentChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      tools: tools ?? this.tools,
      attachments: attachments ?? this.attachments,
    );
  }

  factory AgentChatMessage.fromJson(Map<String, dynamic> json) {
    return AgentChatMessage(
      id: _readString(json['id'], fallback: _fallbackId(json['role'])),
      role: _readString(json['role'], fallback: 'assistant'),
      content: _readString(json['content']),
      createdAt: _readDate(json['createdAt'] ?? json['created_at']),
      status: _readStatus(json['status']),
      tools: _readMapList(
        json['tools'],
      ).map(AgentToolEvent.fromJson).toList(growable: false),
      attachments: _readMapList(json['attachments'])
          .map(AgentAttachment.fromJson)
          .where((item) => item.hasDisplayValue)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status.name,
      'tools': tools.map((tool) => tool.toJson()).toList(growable: false),
      'attachments': attachments
          .map((attachment) => attachment.toJson())
          .toList(growable: false),
    };
  }
}

class AgentAttachment {
  const AgentAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.mimeType,
    required this.type,
    this.ref,
    this.localPath,
    this.size,
    this.uploadStatus,
  });

  final String id;
  final String name;
  final String url;
  final String mimeType;
  final String type;
  final String? ref;
  final String? localPath;
  final int? size;
  final String? uploadStatus;

  String get inputRef => ref ?? url;
  bool get isAudio => type == 'audio' || mimeType.startsWith('audio/');

  Map<String, dynamic> toInputJson() {
    if (inputRef.trim().isEmpty) throw StateError('附件引用不能为空');
    return {
      'ref': inputRef,
      if (name.isNotEmpty) 'name': name,
      if (mimeType.isNotEmpty) 'mime_type': mimeType,
      if (localPath != null) 'local_path': localPath,
      if (size != null) 'size': size,
      if (uploadStatus != null) 'status': uploadStatus,
    };
  }

  bool get hasDisplayValue => name.isNotEmpty || url.isNotEmpty;

  bool get isImage {
    final lowerMime = mimeType.toLowerCase();
    final lowerType = type.toLowerCase();
    final lowerUrl = url.toLowerCase();
    return lowerMime.startsWith('image/') ||
        lowerType.contains('image') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp');
  }

  factory AgentAttachment.fromJson(Map<String, dynamic> json) {
    final url = _firstString(json, const [
      'url',
      'src',
      'href',
      'link',
      'path',
      'preview_url',
      'download_url',
      'ref',
    ]);
    final name = _firstString(json, const [
      'name',
      'filename',
      'file_name',
      'title',
      'label',
    ]);
    return AgentAttachment(
      id: _readString(json['id'], fallback: url.isNotEmpty ? url : name),
      name: name,
      url: url,
      mimeType: _firstString(json, const [
        'mime_type',
        'mimetype',
        'mime',
        'content_type',
      ]),
      type: _firstString(json, const ['type', 'kind']),
      ref: _readNullableString(json['ref']),
      localPath: _readNullableString(json['local_path']),
      size: _readInt(json['size']),
      uploadStatus: _readNullableString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'mime_type': mimeType,
      'type': type,
    };
  }
}

class AgentToolEvent {
  const AgentToolEvent({
    required this.id,
    required this.message,
    required this.status,
  });

  final String id;
  final String message;
  final String status;

  factory AgentToolEvent.fromJson(Map<String, dynamic> json) {
    return AgentToolEvent(
      id: _readString(json['id'], fallback: _fallbackId('tool')),
      message: _readString(json['message']),
      status: _readString(json['status'], fallback: 'done'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'message': message, 'status': status};
  }
}

class AgentStreamEvent {
  const AgentStreamEvent({
    required this.type,
    this.sessionId,
    this.content,
    this.message,
    this.raw = const {},
  });

  final String type;
  final String? sessionId;
  final String? content;
  final String? message;
  final Map<String, dynamic> raw;

  factory AgentStreamEvent.fromJson(Map<String, dynamic> json) {
    return AgentStreamEvent(
      type: _readString(json['type'], fallback: 'message'),
      sessionId: _readNullableString(json['session_id']),
      content: _readNullableString(json['content']),
      message: _readNullableString(json['message']),
      raw: json,
    );
  }

  static AgentStreamEvent? fromSseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('data:')) return null;
    final payload = trimmed.substring(5).trimLeft();
    if (payload.isEmpty || payload == '[DONE]') return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return AgentStreamEvent.fromJson(decoded);
      }
      if (decoded is Map) {
        return AgentStreamEvent.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }
}

String _fallbackId(Object? prefix) {
  final safePrefix = prefix?.toString().trim();
  final label = safePrefix == null || safePrefix.isEmpty ? 'agent' : safePrefix;
  return '$label-${DateTime.now().microsecondsSinceEpoch}';
}

List<Map<String, dynamic>> _readMapList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

String _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _readNullableString(json[key]);
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

String _readString(Object? value, {String fallback = ''}) {
  final parsed = _readNullableString(value);
  if (parsed == null || parsed.isEmpty) return fallback;
  return parsed;
}

String? _readNullableString(Object? value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  return raw.isEmpty ? null : raw;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime _readDate(Object? value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return DateTime.now();
  final parsedInt = int.tryParse(raw);
  if (parsedInt != null) {
    return DateTime.fromMillisecondsSinceEpoch(parsedInt);
  }
  return DateTime.tryParse(raw) ?? DateTime.now();
}

AgentMessageStatus _readStatus(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  return switch (raw) {
    'sending' => AgentMessageStatus.sending,
    'streaming' => AgentMessageStatus.streaming,
    'failed' || 'error' => AgentMessageStatus.failed,
    _ => AgentMessageStatus.done,
  };
}
