// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_cache_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AgentSessionCacheAdapter extends TypeAdapter<AgentSessionCache> {
  @override
  final typeId = 9;

  @override
  AgentSessionCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgentSessionCache(
      id: fields[0] as int?,
      sessionId: fields[1] as String,
      clientSessionId: fields[2] as String,
      title: fields[3] as String,
      messageCount: fields[4] as int,
      createdAt: fields[5] as String?,
      updatedAt: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AgentSessionCache obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.clientSessionId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.messageCount)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentSessionCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgentChatMessageCacheAdapter extends TypeAdapter<AgentChatMessageCache> {
  @override
  final typeId = 10;

  @override
  AgentChatMessageCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgentChatMessageCache(
      id: fields[0] as String,
      role: fields[1] as String,
      content: fields[2] as String,
      createdAt: fields[3] as DateTime,
      status: fields[4] as String,
      tools: (fields[5] as List).cast<AgentToolEventCache>(),
      attachments: (fields[6] as List).cast<AgentAttachmentCache>(),
    );
  }

  @override
  void write(BinaryWriter writer, AgentChatMessageCache obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.tools)
      ..writeByte(6)
      ..write(obj.attachments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentChatMessageCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgentToolEventCacheAdapter extends TypeAdapter<AgentToolEventCache> {
  @override
  final typeId = 11;

  @override
  AgentToolEventCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgentToolEventCache(
      id: fields[0] as String,
      message: fields[1] as String,
      status: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AgentToolEventCache obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentToolEventCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgentAttachmentCacheAdapter extends TypeAdapter<AgentAttachmentCache> {
  @override
  final typeId = 12;

  @override
  AgentAttachmentCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgentAttachmentCache(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      mimeType: fields[3] as String,
      type: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AgentAttachmentCache obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.mimeType)
      ..writeByte(4)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentAttachmentCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AgentMessagesCacheEntryAdapter
    extends TypeAdapter<AgentMessagesCacheEntry> {
  @override
  final typeId = 13;

  @override
  AgentMessagesCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgentMessagesCacheEntry(
      messages: (fields[0] as List).cast<AgentChatMessageCache>(),
    );
  }

  @override
  void write(BinaryWriter writer, AgentMessagesCacheEntry obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.messages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentMessagesCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
