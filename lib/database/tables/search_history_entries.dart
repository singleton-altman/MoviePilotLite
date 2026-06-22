import 'package:drift/drift.dart';

/// Search history entries keyed by normalized keyword.
@DataClassName('SearchHistoryEntryRow')
class SearchHistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get keyword => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
