import 'package:hive_ce/hive.dart';

part 'login_profile.g.dart';

@HiveType(typeId: 0)
class LoginProfile {
  @HiveField(0)
  String id;

  @HiveField(1)
  String server;

  @HiveField(2)
  String username;

  @HiveField(3)
  String password;

  @HiveField(4)
  String accessToken;

  @HiveField(5)
  String tokenType;

  @HiveField(6)
  bool superUser;

  @HiveField(7)
  int userId;

  @HiveField(8)
  String userName;

  @HiveField(9)
  String? avatar;

  @HiveField(10)
  int level;

  @HiveField(11)
  String permissionsJson;

  @HiveField(12)
  bool wizard;

  @HiveField(13)
  DateTime updatedAt;

  LoginProfile(
    this.id,
    this.server,
    this.username,
    this.password,
    this.accessToken,
    this.tokenType,
    this.superUser,
    this.userId,
    this.userName,
    this.level,
    this.permissionsJson,
    this.wizard,
    this.updatedAt, {
    this.avatar,
  });
}
