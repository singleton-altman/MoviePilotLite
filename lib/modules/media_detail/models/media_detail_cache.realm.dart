// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_detail_cache.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class MediaDetailCache extends _MediaDetailCache
    with RealmEntity, RealmObjectBase, RealmObject {
  MediaDetailCache(
    String id,
    String server,
    String path,
    String payload,
    DateTime updatedAt, {
    String? title,
    String? year,
    String? typeName,
    String? session,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'server', server);
    RealmObjectBase.set(this, 'path', path);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'year', year);
    RealmObjectBase.set(this, 'typeName', typeName);
    RealmObjectBase.set(this, 'session', session);
    RealmObjectBase.set(this, 'payload', payload);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
  }

  MediaDetailCache._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get server => RealmObjectBase.get<String>(this, 'server') as String;
  @override
  set server(String value) => RealmObjectBase.set(this, 'server', value);

  @override
  String get path => RealmObjectBase.get<String>(this, 'path') as String;
  @override
  set path(String value) => RealmObjectBase.set(this, 'path', value);

  @override
  String? get title => RealmObjectBase.get<String>(this, 'title') as String?;
  @override
  set title(String? value) => RealmObjectBase.set(this, 'title', value);

  @override
  String? get year => RealmObjectBase.get<String>(this, 'year') as String?;
  @override
  set year(String? value) => RealmObjectBase.set(this, 'year', value);

  @override
  String? get typeName =>
      RealmObjectBase.get<String>(this, 'typeName') as String?;
  @override
  set typeName(String? value) => RealmObjectBase.set(this, 'typeName', value);

  @override
  String? get session =>
      RealmObjectBase.get<String>(this, 'session') as String?;
  @override
  set session(String? value) => RealmObjectBase.set(this, 'session', value);

  @override
  String get payload => RealmObjectBase.get<String>(this, 'payload') as String;
  @override
  set payload(String value) => RealmObjectBase.set(this, 'payload', value);

  @override
  DateTime get updatedAt =>
      RealmObjectBase.get<DateTime>(this, 'updatedAt') as DateTime;
  @override
  set updatedAt(DateTime value) =>
      RealmObjectBase.set(this, 'updatedAt', value);

  @override
  Stream<RealmObjectChanges<MediaDetailCache>> get changes =>
      RealmObjectBase.getChanges<MediaDetailCache>(this);

  @override
  Stream<RealmObjectChanges<MediaDetailCache>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<MediaDetailCache>(this, keyPaths);

  @override
  MediaDetailCache freeze() =>
      RealmObjectBase.freezeObject<MediaDetailCache>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'server': server.toEJson(),
      'path': path.toEJson(),
      'title': title.toEJson(),
      'year': year.toEJson(),
      'typeName': typeName.toEJson(),
      'session': session.toEJson(),
      'payload': payload.toEJson(),
      'updatedAt': updatedAt.toEJson(),
    };
  }

  static EJsonValue _toEJson(MediaDetailCache value) => value.toEJson();
  static MediaDetailCache _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'server': EJsonValue server,
        'path': EJsonValue path,
        'payload': EJsonValue payload,
        'updatedAt': EJsonValue updatedAt,
      } =>
        MediaDetailCache(
          fromEJson(id),
          fromEJson(server),
          fromEJson(path),
          fromEJson(payload),
          fromEJson(updatedAt),
          title: fromEJson(ejson['title']),
          year: fromEJson(ejson['year']),
          typeName: fromEJson(ejson['typeName']),
          session: fromEJson(ejson['session']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(MediaDetailCache._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      MediaDetailCache,
      'MediaDetailCache',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('server', RealmPropertyType.string),
        SchemaProperty('path', RealmPropertyType.string),
        SchemaProperty('title', RealmPropertyType.string, optional: true),
        SchemaProperty('year', RealmPropertyType.string, optional: true),
        SchemaProperty('typeName', RealmPropertyType.string, optional: true),
        SchemaProperty('session', RealmPropertyType.string, optional: true),
        SchemaProperty('payload', RealmPropertyType.string),
        SchemaProperty('updatedAt', RealmPropertyType.timestamp),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
