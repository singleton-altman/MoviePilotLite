// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_plugin_model_cache.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class InstalledPluginModelCache extends _InstalledPluginModelCache
    with RealmEntity, RealmObjectBase, RealmObject {
  InstalledPluginModelCache(
    String id,
    String pluginName,
    String pluginDesc,
    String pluginIcon,
    String pluginVersion,
    String pluginLabel,
    String pluginAuthor,
    String authorUrl,
    String pluginConfigPrefix,
    int pluginOrder,
    int authLevel,
    bool installed,
    bool state,
    bool hasPage,
    bool hasUpdate,
    bool isLocal,
    String repoUrl,
    int installCount,
    int addTime,
    String pluginPublicKey,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'pluginName', pluginName);
    RealmObjectBase.set(this, 'pluginDesc', pluginDesc);
    RealmObjectBase.set(this, 'pluginIcon', pluginIcon);
    RealmObjectBase.set(this, 'pluginVersion', pluginVersion);
    RealmObjectBase.set(this, 'pluginLabel', pluginLabel);
    RealmObjectBase.set(this, 'pluginAuthor', pluginAuthor);
    RealmObjectBase.set(this, 'authorUrl', authorUrl);
    RealmObjectBase.set(this, 'pluginConfigPrefix', pluginConfigPrefix);
    RealmObjectBase.set(this, 'pluginOrder', pluginOrder);
    RealmObjectBase.set(this, 'authLevel', authLevel);
    RealmObjectBase.set(this, 'installed', installed);
    RealmObjectBase.set(this, 'state', state);
    RealmObjectBase.set(this, 'hasPage', hasPage);
    RealmObjectBase.set(this, 'hasUpdate', hasUpdate);
    RealmObjectBase.set(this, 'isLocal', isLocal);
    RealmObjectBase.set(this, 'repoUrl', repoUrl);
    RealmObjectBase.set(this, 'installCount', installCount);
    RealmObjectBase.set(this, 'addTime', addTime);
    RealmObjectBase.set(this, 'pluginPublicKey', pluginPublicKey);
  }

  InstalledPluginModelCache._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get pluginName =>
      RealmObjectBase.get<String>(this, 'pluginName') as String;
  @override
  set pluginName(String value) =>
      RealmObjectBase.set(this, 'pluginName', value);

  @override
  String get pluginDesc =>
      RealmObjectBase.get<String>(this, 'pluginDesc') as String;
  @override
  set pluginDesc(String value) =>
      RealmObjectBase.set(this, 'pluginDesc', value);

  @override
  String get pluginIcon =>
      RealmObjectBase.get<String>(this, 'pluginIcon') as String;
  @override
  set pluginIcon(String value) =>
      RealmObjectBase.set(this, 'pluginIcon', value);

  @override
  String get pluginVersion =>
      RealmObjectBase.get<String>(this, 'pluginVersion') as String;
  @override
  set pluginVersion(String value) =>
      RealmObjectBase.set(this, 'pluginVersion', value);

  @override
  String get pluginLabel =>
      RealmObjectBase.get<String>(this, 'pluginLabel') as String;
  @override
  set pluginLabel(String value) =>
      RealmObjectBase.set(this, 'pluginLabel', value);

  @override
  String get pluginAuthor =>
      RealmObjectBase.get<String>(this, 'pluginAuthor') as String;
  @override
  set pluginAuthor(String value) =>
      RealmObjectBase.set(this, 'pluginAuthor', value);

  @override
  String get authorUrl =>
      RealmObjectBase.get<String>(this, 'authorUrl') as String;
  @override
  set authorUrl(String value) => RealmObjectBase.set(this, 'authorUrl', value);

  @override
  String get pluginConfigPrefix =>
      RealmObjectBase.get<String>(this, 'pluginConfigPrefix') as String;
  @override
  set pluginConfigPrefix(String value) =>
      RealmObjectBase.set(this, 'pluginConfigPrefix', value);

  @override
  int get pluginOrder => RealmObjectBase.get<int>(this, 'pluginOrder') as int;
  @override
  set pluginOrder(int value) => RealmObjectBase.set(this, 'pluginOrder', value);

  @override
  int get authLevel => RealmObjectBase.get<int>(this, 'authLevel') as int;
  @override
  set authLevel(int value) => RealmObjectBase.set(this, 'authLevel', value);

  @override
  bool get installed => RealmObjectBase.get<bool>(this, 'installed') as bool;
  @override
  set installed(bool value) => RealmObjectBase.set(this, 'installed', value);

  @override
  bool get state => RealmObjectBase.get<bool>(this, 'state') as bool;
  @override
  set state(bool value) => RealmObjectBase.set(this, 'state', value);

  @override
  bool get hasPage => RealmObjectBase.get<bool>(this, 'hasPage') as bool;
  @override
  set hasPage(bool value) => RealmObjectBase.set(this, 'hasPage', value);

  @override
  bool get hasUpdate => RealmObjectBase.get<bool>(this, 'hasUpdate') as bool;
  @override
  set hasUpdate(bool value) => RealmObjectBase.set(this, 'hasUpdate', value);

  @override
  bool get isLocal => RealmObjectBase.get<bool>(this, 'isLocal') as bool;
  @override
  set isLocal(bool value) => RealmObjectBase.set(this, 'isLocal', value);

  @override
  String get repoUrl => RealmObjectBase.get<String>(this, 'repoUrl') as String;
  @override
  set repoUrl(String value) => RealmObjectBase.set(this, 'repoUrl', value);

  @override
  int get installCount => RealmObjectBase.get<int>(this, 'installCount') as int;
  @override
  set installCount(int value) =>
      RealmObjectBase.set(this, 'installCount', value);

  @override
  int get addTime => RealmObjectBase.get<int>(this, 'addTime') as int;
  @override
  set addTime(int value) => RealmObjectBase.set(this, 'addTime', value);

  @override
  String get pluginPublicKey =>
      RealmObjectBase.get<String>(this, 'pluginPublicKey') as String;
  @override
  set pluginPublicKey(String value) =>
      RealmObjectBase.set(this, 'pluginPublicKey', value);

  @override
  Stream<RealmObjectChanges<InstalledPluginModelCache>> get changes =>
      RealmObjectBase.getChanges<InstalledPluginModelCache>(this);

  @override
  Stream<RealmObjectChanges<InstalledPluginModelCache>> changesFor([
    List<String>? keyPaths,
  ]) =>
      RealmObjectBase.getChangesFor<InstalledPluginModelCache>(this, keyPaths);

  @override
  InstalledPluginModelCache freeze() =>
      RealmObjectBase.freezeObject<InstalledPluginModelCache>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'pluginName': pluginName.toEJson(),
      'pluginDesc': pluginDesc.toEJson(),
      'pluginIcon': pluginIcon.toEJson(),
      'pluginVersion': pluginVersion.toEJson(),
      'pluginLabel': pluginLabel.toEJson(),
      'pluginAuthor': pluginAuthor.toEJson(),
      'authorUrl': authorUrl.toEJson(),
      'pluginConfigPrefix': pluginConfigPrefix.toEJson(),
      'pluginOrder': pluginOrder.toEJson(),
      'authLevel': authLevel.toEJson(),
      'installed': installed.toEJson(),
      'state': state.toEJson(),
      'hasPage': hasPage.toEJson(),
      'hasUpdate': hasUpdate.toEJson(),
      'isLocal': isLocal.toEJson(),
      'repoUrl': repoUrl.toEJson(),
      'installCount': installCount.toEJson(),
      'addTime': addTime.toEJson(),
      'pluginPublicKey': pluginPublicKey.toEJson(),
    };
  }

  static EJsonValue _toEJson(InstalledPluginModelCache value) =>
      value.toEJson();
  static InstalledPluginModelCache _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'pluginName': EJsonValue pluginName,
        'pluginDesc': EJsonValue pluginDesc,
        'pluginIcon': EJsonValue pluginIcon,
        'pluginVersion': EJsonValue pluginVersion,
        'pluginLabel': EJsonValue pluginLabel,
        'pluginAuthor': EJsonValue pluginAuthor,
        'authorUrl': EJsonValue authorUrl,
        'pluginConfigPrefix': EJsonValue pluginConfigPrefix,
        'pluginOrder': EJsonValue pluginOrder,
        'authLevel': EJsonValue authLevel,
        'installed': EJsonValue installed,
        'state': EJsonValue state,
        'hasPage': EJsonValue hasPage,
        'hasUpdate': EJsonValue hasUpdate,
        'isLocal': EJsonValue isLocal,
        'repoUrl': EJsonValue repoUrl,
        'installCount': EJsonValue installCount,
        'addTime': EJsonValue addTime,
        'pluginPublicKey': EJsonValue pluginPublicKey,
      } =>
        InstalledPluginModelCache(
          fromEJson(id),
          fromEJson(pluginName),
          fromEJson(pluginDesc),
          fromEJson(pluginIcon),
          fromEJson(pluginVersion),
          fromEJson(pluginLabel),
          fromEJson(pluginAuthor),
          fromEJson(authorUrl),
          fromEJson(pluginConfigPrefix),
          fromEJson(pluginOrder),
          fromEJson(authLevel),
          fromEJson(installed),
          fromEJson(state),
          fromEJson(hasPage),
          fromEJson(hasUpdate),
          fromEJson(isLocal),
          fromEJson(repoUrl),
          fromEJson(installCount),
          fromEJson(addTime),
          fromEJson(pluginPublicKey),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(InstalledPluginModelCache._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      InstalledPluginModelCache,
      'InstalledPluginModelCache',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('pluginName', RealmPropertyType.string),
        SchemaProperty('pluginDesc', RealmPropertyType.string),
        SchemaProperty('pluginIcon', RealmPropertyType.string),
        SchemaProperty('pluginVersion', RealmPropertyType.string),
        SchemaProperty('pluginLabel', RealmPropertyType.string),
        SchemaProperty('pluginAuthor', RealmPropertyType.string),
        SchemaProperty('authorUrl', RealmPropertyType.string),
        SchemaProperty('pluginConfigPrefix', RealmPropertyType.string),
        SchemaProperty('pluginOrder', RealmPropertyType.int),
        SchemaProperty('authLevel', RealmPropertyType.int),
        SchemaProperty('installed', RealmPropertyType.bool),
        SchemaProperty('state', RealmPropertyType.bool),
        SchemaProperty('hasPage', RealmPropertyType.bool),
        SchemaProperty('hasUpdate', RealmPropertyType.bool),
        SchemaProperty('isLocal', RealmPropertyType.bool),
        SchemaProperty('repoUrl', RealmPropertyType.string),
        SchemaProperty('installCount', RealmPropertyType.int),
        SchemaProperty('addTime', RealmPropertyType.int),
        SchemaProperty('pluginPublicKey', RealmPropertyType.string),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
