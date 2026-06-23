// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_palette_cache_entry.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class PluginPaletteCacheEntry extends _PluginPaletteCacheEntry
    with RealmEntity, RealmObjectBase, RealmObject {
  PluginPaletteCacheEntry(String url, int colorValue) {
    RealmObjectBase.set(this, 'url', url);
    RealmObjectBase.set(this, 'colorValue', colorValue);
  }

  PluginPaletteCacheEntry._();

  @override
  String get url => RealmObjectBase.get<String>(this, 'url') as String;
  @override
  set url(String value) => RealmObjectBase.set(this, 'url', value);

  @override
  int get colorValue => RealmObjectBase.get<int>(this, 'colorValue') as int;
  @override
  set colorValue(int value) => RealmObjectBase.set(this, 'colorValue', value);

  @override
  Stream<RealmObjectChanges<PluginPaletteCacheEntry>> get changes =>
      RealmObjectBase.getChanges<PluginPaletteCacheEntry>(this);

  @override
  Stream<RealmObjectChanges<PluginPaletteCacheEntry>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<PluginPaletteCacheEntry>(this, keyPaths);

  @override
  PluginPaletteCacheEntry freeze() =>
      RealmObjectBase.freezeObject<PluginPaletteCacheEntry>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'url': url.toEJson(),
      'colorValue': colorValue.toEJson(),
    };
  }

  static EJsonValue _toEJson(PluginPaletteCacheEntry value) => value.toEJson();
  static PluginPaletteCacheEntry _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'url': EJsonValue url, 'colorValue': EJsonValue colorValue} =>
        PluginPaletteCacheEntry(fromEJson(url), fromEJson(colorValue)),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(PluginPaletteCacheEntry._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      PluginPaletteCacheEntry,
      'PluginPaletteCacheEntry',
      [
        SchemaProperty('url', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('colorValue', RealmPropertyType.int),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
