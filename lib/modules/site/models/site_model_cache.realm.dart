// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_model_cache.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class SiteModelCache extends _SiteModelCache
    with RealmEntity, RealmObjectBase, RealmObject {
  SiteModelCache(
    int id,
    String name,
    String domain,
    String url,
    int pri,
    String rss,
    String cookie,
    String ua,
    String apikey,
    String token,
    int proxy,
    String filter,
    int render,
    int public,
    String note,
    int timeout,
    int limitInterval,
    int limitCount,
    int limitSeconds,
    bool isActive,
    String downloader,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'domain', domain);
    RealmObjectBase.set(this, 'url', url);
    RealmObjectBase.set(this, 'pri', pri);
    RealmObjectBase.set(this, 'rss', rss);
    RealmObjectBase.set(this, 'cookie', cookie);
    RealmObjectBase.set(this, 'ua', ua);
    RealmObjectBase.set(this, 'apikey', apikey);
    RealmObjectBase.set(this, 'token', token);
    RealmObjectBase.set(this, 'proxy', proxy);
    RealmObjectBase.set(this, 'filter', filter);
    RealmObjectBase.set(this, 'render', render);
    RealmObjectBase.set(this, 'public', public);
    RealmObjectBase.set(this, 'note', note);
    RealmObjectBase.set(this, 'timeout', timeout);
    RealmObjectBase.set(this, 'limitInterval', limitInterval);
    RealmObjectBase.set(this, 'limitCount', limitCount);
    RealmObjectBase.set(this, 'limitSeconds', limitSeconds);
    RealmObjectBase.set(this, 'isActive', isActive);
    RealmObjectBase.set(this, 'downloader', downloader);
  }

  SiteModelCache._();

  @override
  int get id => RealmObjectBase.get<int>(this, 'id') as int;
  @override
  set id(int value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get domain => RealmObjectBase.get<String>(this, 'domain') as String;
  @override
  set domain(String value) => RealmObjectBase.set(this, 'domain', value);

  @override
  String get url => RealmObjectBase.get<String>(this, 'url') as String;
  @override
  set url(String value) => RealmObjectBase.set(this, 'url', value);

  @override
  int get pri => RealmObjectBase.get<int>(this, 'pri') as int;
  @override
  set pri(int value) => RealmObjectBase.set(this, 'pri', value);

  @override
  String get rss => RealmObjectBase.get<String>(this, 'rss') as String;
  @override
  set rss(String value) => RealmObjectBase.set(this, 'rss', value);

  @override
  String get cookie => RealmObjectBase.get<String>(this, 'cookie') as String;
  @override
  set cookie(String value) => RealmObjectBase.set(this, 'cookie', value);

  @override
  String get ua => RealmObjectBase.get<String>(this, 'ua') as String;
  @override
  set ua(String value) => RealmObjectBase.set(this, 'ua', value);

  @override
  String get apikey => RealmObjectBase.get<String>(this, 'apikey') as String;
  @override
  set apikey(String value) => RealmObjectBase.set(this, 'apikey', value);

  @override
  String get token => RealmObjectBase.get<String>(this, 'token') as String;
  @override
  set token(String value) => RealmObjectBase.set(this, 'token', value);

  @override
  int get proxy => RealmObjectBase.get<int>(this, 'proxy') as int;
  @override
  set proxy(int value) => RealmObjectBase.set(this, 'proxy', value);

  @override
  String get filter => RealmObjectBase.get<String>(this, 'filter') as String;
  @override
  set filter(String value) => RealmObjectBase.set(this, 'filter', value);

  @override
  int get render => RealmObjectBase.get<int>(this, 'render') as int;
  @override
  set render(int value) => RealmObjectBase.set(this, 'render', value);

  @override
  int get public => RealmObjectBase.get<int>(this, 'public') as int;
  @override
  set public(int value) => RealmObjectBase.set(this, 'public', value);

  @override
  String get note => RealmObjectBase.get<String>(this, 'note') as String;
  @override
  set note(String value) => RealmObjectBase.set(this, 'note', value);

  @override
  int get timeout => RealmObjectBase.get<int>(this, 'timeout') as int;
  @override
  set timeout(int value) => RealmObjectBase.set(this, 'timeout', value);

  @override
  int get limitInterval =>
      RealmObjectBase.get<int>(this, 'limitInterval') as int;
  @override
  set limitInterval(int value) =>
      RealmObjectBase.set(this, 'limitInterval', value);

  @override
  int get limitCount => RealmObjectBase.get<int>(this, 'limitCount') as int;
  @override
  set limitCount(int value) => RealmObjectBase.set(this, 'limitCount', value);

  @override
  int get limitSeconds => RealmObjectBase.get<int>(this, 'limitSeconds') as int;
  @override
  set limitSeconds(int value) =>
      RealmObjectBase.set(this, 'limitSeconds', value);

  @override
  bool get isActive => RealmObjectBase.get<bool>(this, 'isActive') as bool;
  @override
  set isActive(bool value) => RealmObjectBase.set(this, 'isActive', value);

  @override
  String get downloader =>
      RealmObjectBase.get<String>(this, 'downloader') as String;
  @override
  set downloader(String value) =>
      RealmObjectBase.set(this, 'downloader', value);

  @override
  Stream<RealmObjectChanges<SiteModelCache>> get changes =>
      RealmObjectBase.getChanges<SiteModelCache>(this);

  @override
  Stream<RealmObjectChanges<SiteModelCache>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<SiteModelCache>(this, keyPaths);

  @override
  SiteModelCache freeze() => RealmObjectBase.freezeObject<SiteModelCache>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'domain': domain.toEJson(),
      'url': url.toEJson(),
      'pri': pri.toEJson(),
      'rss': rss.toEJson(),
      'cookie': cookie.toEJson(),
      'ua': ua.toEJson(),
      'apikey': apikey.toEJson(),
      'token': token.toEJson(),
      'proxy': proxy.toEJson(),
      'filter': filter.toEJson(),
      'render': render.toEJson(),
      'public': public.toEJson(),
      'note': note.toEJson(),
      'timeout': timeout.toEJson(),
      'limitInterval': limitInterval.toEJson(),
      'limitCount': limitCount.toEJson(),
      'limitSeconds': limitSeconds.toEJson(),
      'isActive': isActive.toEJson(),
      'downloader': downloader.toEJson(),
    };
  }

  static EJsonValue _toEJson(SiteModelCache value) => value.toEJson();
  static SiteModelCache _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'name': EJsonValue name,
        'domain': EJsonValue domain,
        'url': EJsonValue url,
        'pri': EJsonValue pri,
        'rss': EJsonValue rss,
        'cookie': EJsonValue cookie,
        'ua': EJsonValue ua,
        'apikey': EJsonValue apikey,
        'token': EJsonValue token,
        'proxy': EJsonValue proxy,
        'filter': EJsonValue filter,
        'render': EJsonValue render,
        'public': EJsonValue public,
        'note': EJsonValue note,
        'timeout': EJsonValue timeout,
        'limitInterval': EJsonValue limitInterval,
        'limitCount': EJsonValue limitCount,
        'limitSeconds': EJsonValue limitSeconds,
        'isActive': EJsonValue isActive,
        'downloader': EJsonValue downloader,
      } =>
        SiteModelCache(
          fromEJson(id),
          fromEJson(name),
          fromEJson(domain),
          fromEJson(url),
          fromEJson(pri),
          fromEJson(rss),
          fromEJson(cookie),
          fromEJson(ua),
          fromEJson(apikey),
          fromEJson(token),
          fromEJson(proxy),
          fromEJson(filter),
          fromEJson(render),
          fromEJson(public),
          fromEJson(note),
          fromEJson(timeout),
          fromEJson(limitInterval),
          fromEJson(limitCount),
          fromEJson(limitSeconds),
          fromEJson(isActive),
          fromEJson(downloader),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(SiteModelCache._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      SiteModelCache,
      'SiteModelCache',
      [
        SchemaProperty('id', RealmPropertyType.int, primaryKey: true),
        SchemaProperty('name', RealmPropertyType.string),
        SchemaProperty('domain', RealmPropertyType.string),
        SchemaProperty('url', RealmPropertyType.string),
        SchemaProperty('pri', RealmPropertyType.int),
        SchemaProperty('rss', RealmPropertyType.string),
        SchemaProperty('cookie', RealmPropertyType.string),
        SchemaProperty('ua', RealmPropertyType.string),
        SchemaProperty('apikey', RealmPropertyType.string),
        SchemaProperty('token', RealmPropertyType.string),
        SchemaProperty('proxy', RealmPropertyType.int),
        SchemaProperty('filter', RealmPropertyType.string),
        SchemaProperty('render', RealmPropertyType.int),
        SchemaProperty('public', RealmPropertyType.int),
        SchemaProperty('note', RealmPropertyType.string),
        SchemaProperty('timeout', RealmPropertyType.int),
        SchemaProperty('limitInterval', RealmPropertyType.int),
        SchemaProperty('limitCount', RealmPropertyType.int),
        SchemaProperty('limitSeconds', RealmPropertyType.int),
        SchemaProperty('isActive', RealmPropertyType.bool),
        SchemaProperty('downloader', RealmPropertyType.string),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
