import 'package:drift/drift.dart';

/// Site user data (latest snapshot) cache keyed by domain.
@DataClassName('SiteUserDataCacheRow')
class SiteUserDataCaches extends Table {
  TextColumn get domain => text()();
  TextColumn get username => text()();
  TextColumn get userid => text()();
  TextColumn get userLevel => text()();
  TextColumn get joinAt => text()();
  RealColumn get bonus => real()();
  IntColumn get upload => integer()();
  IntColumn get download => integer()();
  RealColumn get ratio => real()();
  IntColumn get seeding => integer()();
  IntColumn get leeching => integer()();
  IntColumn get seedingSize => integer()();
  IntColumn get leechingSize => integer()();
  IntColumn get messageUnread => integer()();
  TextColumn get errMsg => text()();
  TextColumn get updatedDay => text()();
  TextColumn get updatedTime => text()();

  @override
  Set<Column> get primaryKey => {domain};
}
