import 'package:drift/drift.dart';

/// Cached media detail payload for offline/fast access.
@DataClassName('MediaDetailCacheRow')
class MediaDetailCaches extends Table {
  TextColumn get id => text()();
  TextColumn get server => text()();
  TextColumn get path => text()();
  TextColumn get title => text().nullable()();
  TextColumn get year => text().nullable()();
  TextColumn get typeName => text().nullable()();
  TextColumn get session => text().nullable()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
