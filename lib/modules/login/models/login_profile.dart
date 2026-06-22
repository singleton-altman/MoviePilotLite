/// Login profile — stores user credentials for quick re-authentication.
class LoginProfile {
  final String id;
  final String server;
  final String username;
  final String password;
  final String accessToken;
  final String tokenType;
  final bool superUser;
  final int userId;
  final String userName;
  final String? avatar;
  final int level;
  final String permissionsJson;
  final bool wizard;
  final DateTime updatedAt;

  const LoginProfile({
    required this.id,
    required this.server,
    required this.username,
    required this.password,
    required this.accessToken,
    required this.tokenType,
    required this.superUser,
    required this.userId,
    required this.userName,
    this.avatar,
    required this.level,
    required this.permissionsJson,
    required this.wizard,
    required this.updatedAt,
  });
}
