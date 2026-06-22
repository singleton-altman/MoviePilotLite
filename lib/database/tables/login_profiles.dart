import 'package:drift/drift.dart';

/// Login profile table — stores user credentials for quick re-authentication.
@DataClassName('LoginProfileRow')
class LoginProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get server => text()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  TextColumn get accessToken => text()();
  TextColumn get tokenType => text()();
  BoolColumn get superUser => boolean()();
  IntColumn get userId => integer()();
  TextColumn get userName => text()();
  TextColumn get avatar => text().nullable()();
  IntColumn get level => integer()();
  TextColumn get permissionsJson => text()();
  BoolColumn get wizard => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
