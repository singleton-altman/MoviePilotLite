// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserInfoImpl _$$UserInfoImplFromJson(
  Map<String, dynamic> json,
) => _$UserInfoImpl(
  id: (json['id'] as num).toInt(),
  name: (json['name'] ?? json['username'] ?? json['user_name'] ?? '') as String,
  email: json['email'] as String,
  isActive: json['is_active'] as bool,
  isSuperuser: json['is_superuser'] as bool,
  avatar: json['avatar'] as String?,
  isOtp: json['is_otp'] as bool,
  permissions: json['permissions'] as Map<String, dynamic>? ?? {},
  settings: json['settings'] as Map<String, dynamic>? ?? {},
);

Map<String, dynamic> _$$UserInfoImplToJson(_$UserInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'is_active': instance.isActive,
      'is_superuser': instance.isSuperuser,
      'avatar': instance.avatar,
      'is_otp': instance.isOtp,
      'permissions': instance.permissions,
      'settings': instance.settings,
    };
