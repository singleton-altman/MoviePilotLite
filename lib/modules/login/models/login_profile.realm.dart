// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_profile.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class LoginProfile extends _LoginProfile
    with RealmEntity, RealmObjectBase, RealmObject {
  LoginProfile(
    String id,
    String server,
    String username,
    String password,
    String accessToken,
    String tokenType,
    bool superUser,
    int userId,
    String userName,
    int level,
    String permissionsJson,
    bool wizard,
    DateTime updatedAt, {
    String? avatar,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'server', server);
    RealmObjectBase.set(this, 'username', username);
    RealmObjectBase.set(this, 'password', password);
    RealmObjectBase.set(this, 'accessToken', accessToken);
    RealmObjectBase.set(this, 'tokenType', tokenType);
    RealmObjectBase.set(this, 'superUser', superUser);
    RealmObjectBase.set(this, 'userId', userId);
    RealmObjectBase.set(this, 'userName', userName);
    RealmObjectBase.set(this, 'avatar', avatar);
    RealmObjectBase.set(this, 'level', level);
    RealmObjectBase.set(this, 'permissionsJson', permissionsJson);
    RealmObjectBase.set(this, 'wizard', wizard);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
  }

  LoginProfile._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get server => RealmObjectBase.get<String>(this, 'server') as String;
  @override
  set server(String value) => RealmObjectBase.set(this, 'server', value);

  @override
  String get username =>
      RealmObjectBase.get<String>(this, 'username') as String;
  @override
  set username(String value) => RealmObjectBase.set(this, 'username', value);

  @override
  String get password =>
      RealmObjectBase.get<String>(this, 'password') as String;
  @override
  set password(String value) => RealmObjectBase.set(this, 'password', value);

  @override
  String get accessToken =>
      RealmObjectBase.get<String>(this, 'accessToken') as String;
  @override
  set accessToken(String value) =>
      RealmObjectBase.set(this, 'accessToken', value);

  @override
  String get tokenType =>
      RealmObjectBase.get<String>(this, 'tokenType') as String;
  @override
  set tokenType(String value) => RealmObjectBase.set(this, 'tokenType', value);

  @override
  bool get superUser => RealmObjectBase.get<bool>(this, 'superUser') as bool;
  @override
  set superUser(bool value) => RealmObjectBase.set(this, 'superUser', value);

  @override
  int get userId => RealmObjectBase.get<int>(this, 'userId') as int;
  @override
  set userId(int value) => RealmObjectBase.set(this, 'userId', value);

  @override
  String get userName =>
      RealmObjectBase.get<String>(this, 'userName') as String;
  @override
  set userName(String value) => RealmObjectBase.set(this, 'userName', value);

  @override
  String? get avatar => RealmObjectBase.get<String>(this, 'avatar') as String?;
  @override
  set avatar(String? value) => RealmObjectBase.set(this, 'avatar', value);

  @override
  int get level => RealmObjectBase.get<int>(this, 'level') as int;
  @override
  set level(int value) => RealmObjectBase.set(this, 'level', value);

  @override
  String get permissionsJson =>
      RealmObjectBase.get<String>(this, 'permissionsJson') as String;
  @override
  set permissionsJson(String value) =>
      RealmObjectBase.set(this, 'permissionsJson', value);

  @override
  bool get wizard => RealmObjectBase.get<bool>(this, 'wizard') as bool;
  @override
  set wizard(bool value) => RealmObjectBase.set(this, 'wizard', value);

  @override
  DateTime get updatedAt =>
      RealmObjectBase.get<DateTime>(this, 'updatedAt') as DateTime;
  @override
  set updatedAt(DateTime value) =>
      RealmObjectBase.set(this, 'updatedAt', value);

  @override
  Stream<RealmObjectChanges<LoginProfile>> get changes =>
      RealmObjectBase.getChanges<LoginProfile>(this);

  @override
  Stream<RealmObjectChanges<LoginProfile>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<LoginProfile>(this, keyPaths);

  @override
  LoginProfile freeze() => RealmObjectBase.freezeObject<LoginProfile>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'server': server.toEJson(),
      'username': username.toEJson(),
      'password': password.toEJson(),
      'accessToken': accessToken.toEJson(),
      'tokenType': tokenType.toEJson(),
      'superUser': superUser.toEJson(),
      'userId': userId.toEJson(),
      'userName': userName.toEJson(),
      'avatar': avatar.toEJson(),
      'level': level.toEJson(),
      'permissionsJson': permissionsJson.toEJson(),
      'wizard': wizard.toEJson(),
      'updatedAt': updatedAt.toEJson(),
    };
  }

  static EJsonValue _toEJson(LoginProfile value) => value.toEJson();
  static LoginProfile _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'server': EJsonValue server,
        'username': EJsonValue username,
        'password': EJsonValue password,
        'accessToken': EJsonValue accessToken,
        'tokenType': EJsonValue tokenType,
        'superUser': EJsonValue superUser,
        'userId': EJsonValue userId,
        'userName': EJsonValue userName,
        'level': EJsonValue level,
        'permissionsJson': EJsonValue permissionsJson,
        'wizard': EJsonValue wizard,
        'updatedAt': EJsonValue updatedAt,
      } =>
        LoginProfile(
          fromEJson(id),
          fromEJson(server),
          fromEJson(username),
          fromEJson(password),
          fromEJson(accessToken),
          fromEJson(tokenType),
          fromEJson(superUser),
          fromEJson(userId),
          fromEJson(userName),
          fromEJson(level),
          fromEJson(permissionsJson),
          fromEJson(wizard),
          fromEJson(updatedAt),
          avatar: fromEJson(ejson['avatar']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(LoginProfile._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      LoginProfile,
      'LoginProfile',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('server', RealmPropertyType.string),
        SchemaProperty('username', RealmPropertyType.string),
        SchemaProperty('password', RealmPropertyType.string),
        SchemaProperty('accessToken', RealmPropertyType.string),
        SchemaProperty('tokenType', RealmPropertyType.string),
        SchemaProperty('superUser', RealmPropertyType.bool),
        SchemaProperty('userId', RealmPropertyType.int),
        SchemaProperty('userName', RealmPropertyType.string),
        SchemaProperty('avatar', RealmPropertyType.string, optional: true),
        SchemaProperty('level', RealmPropertyType.int),
        SchemaProperty('permissionsJson', RealmPropertyType.string),
        SchemaProperty('wizard', RealmPropertyType.bool),
        SchemaProperty('updatedAt', RealmPropertyType.timestamp),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
