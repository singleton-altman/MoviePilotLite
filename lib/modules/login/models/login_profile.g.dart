// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoginProfileAdapter extends TypeAdapter<LoginProfile> {
  @override
  final typeId = 0;

  @override
  LoginProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoginProfile(
      fields[0] as String,
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      fields[4] as String,
      fields[5] as String,
      fields[6] as bool,
      (fields[7] as num).toInt(),
      fields[8] as String,
      (fields[10] as num).toInt(),
      fields[11] as String,
      fields[12] as bool,
      fields[13] as DateTime,
      avatar: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LoginProfile obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.server)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.accessToken)
      ..writeByte(5)
      ..write(obj.tokenType)
      ..writeByte(6)
      ..write(obj.superUser)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.userName)
      ..writeByte(9)
      ..write(obj.avatar)
      ..writeByte(10)
      ..write(obj.level)
      ..writeByte(11)
      ..write(obj.permissionsJson)
      ..writeByte(12)
      ..write(obj.wizard)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
