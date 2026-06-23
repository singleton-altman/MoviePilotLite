// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_history.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class SearchHistoryEntry extends _SearchHistoryEntry
    with RealmEntity, RealmObjectBase, RealmObject {
  SearchHistoryEntry(
    String id,
    String keyword,
    DateTime createdAt,
    DateTime updatedAt,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'keyword', keyword);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'updatedAt', updatedAt);
  }

  SearchHistoryEntry._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get keyword => RealmObjectBase.get<String>(this, 'keyword') as String;
  @override
  set keyword(String value) => RealmObjectBase.set(this, 'keyword', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  DateTime get updatedAt =>
      RealmObjectBase.get<DateTime>(this, 'updatedAt') as DateTime;
  @override
  set updatedAt(DateTime value) =>
      RealmObjectBase.set(this, 'updatedAt', value);

  @override
  Stream<RealmObjectChanges<SearchHistoryEntry>> get changes =>
      RealmObjectBase.getChanges<SearchHistoryEntry>(this);

  @override
  Stream<RealmObjectChanges<SearchHistoryEntry>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<SearchHistoryEntry>(this, keyPaths);

  @override
  SearchHistoryEntry freeze() =>
      RealmObjectBase.freezeObject<SearchHistoryEntry>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'keyword': keyword.toEJson(),
      'createdAt': createdAt.toEJson(),
      'updatedAt': updatedAt.toEJson(),
    };
  }

  static EJsonValue _toEJson(SearchHistoryEntry value) => value.toEJson();
  static SearchHistoryEntry _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'keyword': EJsonValue keyword,
        'createdAt': EJsonValue createdAt,
        'updatedAt': EJsonValue updatedAt,
      } =>
        SearchHistoryEntry(
          fromEJson(id),
          fromEJson(keyword),
          fromEJson(createdAt),
          fromEJson(updatedAt),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(SearchHistoryEntry._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      SearchHistoryEntry,
      'SearchHistoryEntry',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('keyword', RealmPropertyType.string),
        SchemaProperty('createdAt', RealmPropertyType.timestamp),
        SchemaProperty('updatedAt', RealmPropertyType.timestamp),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
