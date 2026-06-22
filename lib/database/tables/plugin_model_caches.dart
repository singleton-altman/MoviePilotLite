import 'package:drift/drift.dart';

/// Plugin market listing cache.
@DataClassName('PluginModelCacheRow')
class PluginModelCaches extends Table {
  TextColumn get id => text()();
  TextColumn get pluginName => text()();
  TextColumn get pluginDesc => text()();
  TextColumn get pluginIcon => text()();
  TextColumn get pluginVersion => text()();
  TextColumn get pluginLabel => text()();
  TextColumn get pluginAuthor => text()();
  TextColumn get authorUrl => text()();
  TextColumn get pluginConfigPrefix => text()();
  IntColumn get pluginOrder => integer()();
  IntColumn get authLevel => integer()();
  BoolColumn get installed => boolean()();
  BoolColumn get state => boolean()();
  BoolColumn get hasPage => boolean()();
  BoolColumn get hasUpdate => boolean()();
  BoolColumn get isLocal => boolean()();
  TextColumn get repoUrl => text()();
  IntColumn get installCount => integer()();
  IntColumn get addTime => integer()();
  TextColumn get pluginPublicKey => text()();

  @override
  Set<Column> get primaryKey => {id};
}
