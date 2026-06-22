import 'package:drift/drift.dart';

/// Site info cache for fast startup display.
@DataClassName('SiteModelCacheRow')
class SiteModelCaches extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get domain => text()();
  TextColumn get url => text()();
  IntColumn get pri => integer()();
  TextColumn get rss => text()();
  TextColumn get cookie => text()();
  TextColumn get ua => text()();
  TextColumn get apikey => text()();
  TextColumn get token => text()();
  IntColumn get proxy => integer()();
  TextColumn get filter => text()();
  IntColumn get render => integer()();
  IntColumn get public => integer()();
  TextColumn get note => text()();
  IntColumn get timeout => integer()();
  IntColumn get limitInterval => integer()();
  IntColumn get limitCount => integer()();
  IntColumn get limitSeconds => integer()();
  BoolColumn get isActive => boolean()();
  TextColumn get downloader => text()();

  @override
  Set<Column> get primaryKey => {id};
}
