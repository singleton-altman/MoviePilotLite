// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_icon_cache.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class SiteIconCache extends _SiteIconCache
    with RealmEntity, RealmObjectBase, RealmObject {
  SiteIconCache(String url, String iconBase64) {
    RealmObjectBase.set(this, 'url', url);
    RealmObjectBase.set(this, 'iconBase64', iconBase64);
  }

  SiteIconCache._();

  @override
  String get url => RealmObjectBase.get<String>(this, 'url') as String;
  @override
  set url(String value) => RealmObjectBase.set(this, 'url', value);

  @override
  String get iconBase64 =>
      RealmObjectBase.get<String>(this, 'iconBase64') as String;
  @override
  set iconBase64(String value) =>
      RealmObjectBase.set(this, 'iconBase64', value);

  @override
  Stream<RealmObjectChanges<SiteIconCache>> get changes =>
      RealmObjectBase.getChanges<SiteIconCache>(this);

  @override
  Stream<RealmObjectChanges<SiteIconCache>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<SiteIconCache>(this, keyPaths);

  @override
  SiteIconCache freeze() => RealmObjectBase.freezeObject<SiteIconCache>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'url': url.toEJson(),
      'iconBase64': iconBase64.toEJson(),
    };
  }

  static EJsonValue _toEJson(SiteIconCache value) => value.toEJson();
  static SiteIconCache _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'url': EJsonValue url, 'iconBase64': EJsonValue iconBase64} =>
        SiteIconCache(fromEJson(url), fromEJson(iconBase64)),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(SiteIconCache._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      SiteIconCache,
      'SiteIconCache',
      [
        SchemaProperty('url', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('iconBase64', RealmPropertyType.string),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
