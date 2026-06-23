import 'package:realm/realm.dart';

part 'login_profile.realm.dart';

@RealmModel()
class _LoginProfile {
  @PrimaryKey()
  late String id;

  late String server;
  late String username;
  late String password;

  late String accessToken;
  late String tokenType;
  late bool superUser;
  late int userId;
  late String userName;
  String? avatar;
  late int level;
  late String permissionsJson;
  late bool wizard;

  late DateTime updatedAt;
}
