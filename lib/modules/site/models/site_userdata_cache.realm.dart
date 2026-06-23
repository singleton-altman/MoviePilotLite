// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_userdata_cache.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class SiteUserDataCache extends _SiteUserDataCache
    with RealmEntity, RealmObjectBase, RealmObject {
  SiteUserDataCache(
    String domain,
    String username,
    String userid,
    String userLevel,
    String joinAt,
    double bonus,
    int upload,
    int download,
    double ratio,
    int seeding,
    int leeching,
    int seedingSize,
    int leechingSize,
    int messageUnread,
    String errMsg,
    String updatedDay,
    String updatedTime,
  ) {
    RealmObjectBase.set(this, 'domain', domain);
    RealmObjectBase.set(this, 'username', username);
    RealmObjectBase.set(this, 'userid', userid);
    RealmObjectBase.set(this, 'userLevel', userLevel);
    RealmObjectBase.set(this, 'joinAt', joinAt);
    RealmObjectBase.set(this, 'bonus', bonus);
    RealmObjectBase.set(this, 'upload', upload);
    RealmObjectBase.set(this, 'download', download);
    RealmObjectBase.set(this, 'ratio', ratio);
    RealmObjectBase.set(this, 'seeding', seeding);
    RealmObjectBase.set(this, 'leeching', leeching);
    RealmObjectBase.set(this, 'seedingSize', seedingSize);
    RealmObjectBase.set(this, 'leechingSize', leechingSize);
    RealmObjectBase.set(this, 'messageUnread', messageUnread);
    RealmObjectBase.set(this, 'errMsg', errMsg);
    RealmObjectBase.set(this, 'updatedDay', updatedDay);
    RealmObjectBase.set(this, 'updatedTime', updatedTime);
  }

  SiteUserDataCache._();

  @override
  String get domain => RealmObjectBase.get<String>(this, 'domain') as String;
  @override
  set domain(String value) => RealmObjectBase.set(this, 'domain', value);

  @override
  String get username =>
      RealmObjectBase.get<String>(this, 'username') as String;
  @override
  set username(String value) => RealmObjectBase.set(this, 'username', value);

  @override
  String get userid => RealmObjectBase.get<String>(this, 'userid') as String;
  @override
  set userid(String value) => RealmObjectBase.set(this, 'userid', value);

  @override
  String get userLevel =>
      RealmObjectBase.get<String>(this, 'userLevel') as String;
  @override
  set userLevel(String value) => RealmObjectBase.set(this, 'userLevel', value);

  @override
  String get joinAt => RealmObjectBase.get<String>(this, 'joinAt') as String;
  @override
  set joinAt(String value) => RealmObjectBase.set(this, 'joinAt', value);

  @override
  double get bonus => RealmObjectBase.get<double>(this, 'bonus') as double;
  @override
  set bonus(double value) => RealmObjectBase.set(this, 'bonus', value);

  @override
  int get upload => RealmObjectBase.get<int>(this, 'upload') as int;
  @override
  set upload(int value) => RealmObjectBase.set(this, 'upload', value);

  @override
  int get download => RealmObjectBase.get<int>(this, 'download') as int;
  @override
  set download(int value) => RealmObjectBase.set(this, 'download', value);

  @override
  double get ratio => RealmObjectBase.get<double>(this, 'ratio') as double;
  @override
  set ratio(double value) => RealmObjectBase.set(this, 'ratio', value);

  @override
  int get seeding => RealmObjectBase.get<int>(this, 'seeding') as int;
  @override
  set seeding(int value) => RealmObjectBase.set(this, 'seeding', value);

  @override
  int get leeching => RealmObjectBase.get<int>(this, 'leeching') as int;
  @override
  set leeching(int value) => RealmObjectBase.set(this, 'leeching', value);

  @override
  int get seedingSize => RealmObjectBase.get<int>(this, 'seedingSize') as int;
  @override
  set seedingSize(int value) => RealmObjectBase.set(this, 'seedingSize', value);

  @override
  int get leechingSize => RealmObjectBase.get<int>(this, 'leechingSize') as int;
  @override
  set leechingSize(int value) =>
      RealmObjectBase.set(this, 'leechingSize', value);

  @override
  int get messageUnread =>
      RealmObjectBase.get<int>(this, 'messageUnread') as int;
  @override
  set messageUnread(int value) =>
      RealmObjectBase.set(this, 'messageUnread', value);

  @override
  String get errMsg => RealmObjectBase.get<String>(this, 'errMsg') as String;
  @override
  set errMsg(String value) => RealmObjectBase.set(this, 'errMsg', value);

  @override
  String get updatedDay =>
      RealmObjectBase.get<String>(this, 'updatedDay') as String;
  @override
  set updatedDay(String value) =>
      RealmObjectBase.set(this, 'updatedDay', value);

  @override
  String get updatedTime =>
      RealmObjectBase.get<String>(this, 'updatedTime') as String;
  @override
  set updatedTime(String value) =>
      RealmObjectBase.set(this, 'updatedTime', value);

  @override
  Stream<RealmObjectChanges<SiteUserDataCache>> get changes =>
      RealmObjectBase.getChanges<SiteUserDataCache>(this);

  @override
  Stream<RealmObjectChanges<SiteUserDataCache>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<SiteUserDataCache>(this, keyPaths);

  @override
  SiteUserDataCache freeze() =>
      RealmObjectBase.freezeObject<SiteUserDataCache>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'domain': domain.toEJson(),
      'username': username.toEJson(),
      'userid': userid.toEJson(),
      'userLevel': userLevel.toEJson(),
      'joinAt': joinAt.toEJson(),
      'bonus': bonus.toEJson(),
      'upload': upload.toEJson(),
      'download': download.toEJson(),
      'ratio': ratio.toEJson(),
      'seeding': seeding.toEJson(),
      'leeching': leeching.toEJson(),
      'seedingSize': seedingSize.toEJson(),
      'leechingSize': leechingSize.toEJson(),
      'messageUnread': messageUnread.toEJson(),
      'errMsg': errMsg.toEJson(),
      'updatedDay': updatedDay.toEJson(),
      'updatedTime': updatedTime.toEJson(),
    };
  }

  static EJsonValue _toEJson(SiteUserDataCache value) => value.toEJson();
  static SiteUserDataCache _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'domain': EJsonValue domain,
        'username': EJsonValue username,
        'userid': EJsonValue userid,
        'userLevel': EJsonValue userLevel,
        'joinAt': EJsonValue joinAt,
        'bonus': EJsonValue bonus,
        'upload': EJsonValue upload,
        'download': EJsonValue download,
        'ratio': EJsonValue ratio,
        'seeding': EJsonValue seeding,
        'leeching': EJsonValue leeching,
        'seedingSize': EJsonValue seedingSize,
        'leechingSize': EJsonValue leechingSize,
        'messageUnread': EJsonValue messageUnread,
        'errMsg': EJsonValue errMsg,
        'updatedDay': EJsonValue updatedDay,
        'updatedTime': EJsonValue updatedTime,
      } =>
        SiteUserDataCache(
          fromEJson(domain),
          fromEJson(username),
          fromEJson(userid),
          fromEJson(userLevel),
          fromEJson(joinAt),
          fromEJson(bonus),
          fromEJson(upload),
          fromEJson(download),
          fromEJson(ratio),
          fromEJson(seeding),
          fromEJson(leeching),
          fromEJson(seedingSize),
          fromEJson(leechingSize),
          fromEJson(messageUnread),
          fromEJson(errMsg),
          fromEJson(updatedDay),
          fromEJson(updatedTime),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(SiteUserDataCache._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      SiteUserDataCache,
      'SiteUserDataCache',
      [
        SchemaProperty('domain', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('username', RealmPropertyType.string),
        SchemaProperty('userid', RealmPropertyType.string),
        SchemaProperty('userLevel', RealmPropertyType.string),
        SchemaProperty('joinAt', RealmPropertyType.string),
        SchemaProperty('bonus', RealmPropertyType.double),
        SchemaProperty('upload', RealmPropertyType.int),
        SchemaProperty('download', RealmPropertyType.int),
        SchemaProperty('ratio', RealmPropertyType.double),
        SchemaProperty('seeding', RealmPropertyType.int),
        SchemaProperty('leeching', RealmPropertyType.int),
        SchemaProperty('seedingSize', RealmPropertyType.int),
        SchemaProperty('leechingSize', RealmPropertyType.int),
        SchemaProperty('messageUnread', RealmPropertyType.int),
        SchemaProperty('errMsg', RealmPropertyType.string),
        SchemaProperty('updatedDay', RealmPropertyType.string),
        SchemaProperty('updatedTime', RealmPropertyType.string),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
