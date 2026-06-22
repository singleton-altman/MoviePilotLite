import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/login_profiles.dart';

part 'login_profile_dao.g.dart';

@DriftAccessor(tables: [LoginProfiles])
class LoginProfileDao extends DatabaseAccessor<AppDatabase>
    with _$LoginProfileDaoMixin {
  LoginProfileDao(super.db);

  Future<List<LoginProfileRow>> getAll() => select(loginProfiles).get();

  Future<LoginProfileRow?> findByPk(String id) =>
      (select(loginProfiles)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(LoginProfilesCompanion row) =>
      into(loginProfiles).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<LoginProfilesCompanion> rows) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(loginProfiles, rows);
    });
  }

  Future<int> deleteByPk(String id) =>
      (delete(loginProfiles)..where((t) => t.id.equals(id))).go();

  Future<int> deleteAll() => delete(loginProfiles).go();

  Future<int> updateAccessToken(String id, String newToken) =>
      (update(loginProfiles)..where((t) => t.id.equals(id)))
          .write(LoginProfilesCompanion(accessToken: Value(newToken)));
}
