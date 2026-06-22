// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LoginProfilesTable extends LoginProfiles
    with TableInfo<$LoginProfilesTable, LoginProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoginProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<String> server = GeneratedColumn<String>(
    'server',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accessTokenMeta = const VerificationMeta(
    'accessToken',
  );
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
    'access_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenTypeMeta = const VerificationMeta(
    'tokenType',
  );
  @override
  late final GeneratedColumn<String> tokenType = GeneratedColumn<String>(
    'token_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _superUserMeta = const VerificationMeta(
    'superUser',
  );
  @override
  late final GeneratedColumn<bool> superUser = GeneratedColumn<bool>(
    'super_user',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("super_user" IN (0, 1))',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionsJsonMeta = const VerificationMeta(
    'permissionsJson',
  );
  @override
  late final GeneratedColumn<String> permissionsJson = GeneratedColumn<String>(
    'permissions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wizardMeta = const VerificationMeta('wizard');
  @override
  late final GeneratedColumn<bool> wizard = GeneratedColumn<bool>(
    'wizard',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wizard" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    server,
    username,
    password,
    accessToken,
    tokenType,
    superUser,
    userId,
    userName,
    avatar,
    level,
    permissionsJson,
    wizard,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'login_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LoginProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server')) {
      context.handle(
        _serverMeta,
        server.isAcceptableOrUnknown(data['server']!, _serverMeta),
      );
    } else if (isInserting) {
      context.missing(_serverMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('access_token')) {
      context.handle(
        _accessTokenMeta,
        accessToken.isAcceptableOrUnknown(
          data['access_token']!,
          _accessTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accessTokenMeta);
    }
    if (data.containsKey('token_type')) {
      context.handle(
        _tokenTypeMeta,
        tokenType.isAcceptableOrUnknown(data['token_type']!, _tokenTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenTypeMeta);
    }
    if (data.containsKey('super_user')) {
      context.handle(
        _superUserMeta,
        superUser.isAcceptableOrUnknown(data['super_user']!, _superUserMeta),
      );
    } else if (isInserting) {
      context.missing(_superUserMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    } else if (isInserting) {
      context.missing(_userNameMeta);
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('permissions_json')) {
      context.handle(
        _permissionsJsonMeta,
        permissionsJson.isAcceptableOrUnknown(
          data['permissions_json']!,
          _permissionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_permissionsJsonMeta);
    }
    if (data.containsKey('wizard')) {
      context.handle(
        _wizardMeta,
        wizard.isAcceptableOrUnknown(data['wizard']!, _wizardMeta),
      );
    } else if (isInserting) {
      context.missing(_wizardMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LoginProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LoginProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      server: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      )!,
      accessToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_token'],
      )!,
      tokenType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_type'],
      )!,
      superUser: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}super_user'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      userName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_name'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      permissionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permissions_json'],
      )!,
      wizard: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wizard'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LoginProfilesTable createAlias(String alias) {
    return $LoginProfilesTable(attachedDatabase, alias);
  }
}

class LoginProfileRow extends DataClass implements Insertable<LoginProfileRow> {
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
  const LoginProfileRow({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server'] = Variable<String>(server);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    map['access_token'] = Variable<String>(accessToken);
    map['token_type'] = Variable<String>(tokenType);
    map['super_user'] = Variable<bool>(superUser);
    map['user_id'] = Variable<int>(userId);
    map['user_name'] = Variable<String>(userName);
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    map['level'] = Variable<int>(level);
    map['permissions_json'] = Variable<String>(permissionsJson);
    map['wizard'] = Variable<bool>(wizard);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LoginProfilesCompanion toCompanion(bool nullToAbsent) {
    return LoginProfilesCompanion(
      id: Value(id),
      server: Value(server),
      username: Value(username),
      password: Value(password),
      accessToken: Value(accessToken),
      tokenType: Value(tokenType),
      superUser: Value(superUser),
      userId: Value(userId),
      userName: Value(userName),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      level: Value(level),
      permissionsJson: Value(permissionsJson),
      wizard: Value(wizard),
      updatedAt: Value(updatedAt),
    );
  }

  factory LoginProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LoginProfileRow(
      id: serializer.fromJson<String>(json['id']),
      server: serializer.fromJson<String>(json['server']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      accessToken: serializer.fromJson<String>(json['accessToken']),
      tokenType: serializer.fromJson<String>(json['tokenType']),
      superUser: serializer.fromJson<bool>(json['superUser']),
      userId: serializer.fromJson<int>(json['userId']),
      userName: serializer.fromJson<String>(json['userName']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      level: serializer.fromJson<int>(json['level']),
      permissionsJson: serializer.fromJson<String>(json['permissionsJson']),
      wizard: serializer.fromJson<bool>(json['wizard']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'server': serializer.toJson<String>(server),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'accessToken': serializer.toJson<String>(accessToken),
      'tokenType': serializer.toJson<String>(tokenType),
      'superUser': serializer.toJson<bool>(superUser),
      'userId': serializer.toJson<int>(userId),
      'userName': serializer.toJson<String>(userName),
      'avatar': serializer.toJson<String?>(avatar),
      'level': serializer.toJson<int>(level),
      'permissionsJson': serializer.toJson<String>(permissionsJson),
      'wizard': serializer.toJson<bool>(wizard),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LoginProfileRow copyWith({
    String? id,
    String? server,
    String? username,
    String? password,
    String? accessToken,
    String? tokenType,
    bool? superUser,
    int? userId,
    String? userName,
    Value<String?> avatar = const Value.absent(),
    int? level,
    String? permissionsJson,
    bool? wizard,
    DateTime? updatedAt,
  }) => LoginProfileRow(
    id: id ?? this.id,
    server: server ?? this.server,
    username: username ?? this.username,
    password: password ?? this.password,
    accessToken: accessToken ?? this.accessToken,
    tokenType: tokenType ?? this.tokenType,
    superUser: superUser ?? this.superUser,
    userId: userId ?? this.userId,
    userName: userName ?? this.userName,
    avatar: avatar.present ? avatar.value : this.avatar,
    level: level ?? this.level,
    permissionsJson: permissionsJson ?? this.permissionsJson,
    wizard: wizard ?? this.wizard,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LoginProfileRow copyWithCompanion(LoginProfilesCompanion data) {
    return LoginProfileRow(
      id: data.id.present ? data.id.value : this.id,
      server: data.server.present ? data.server.value : this.server,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      accessToken: data.accessToken.present
          ? data.accessToken.value
          : this.accessToken,
      tokenType: data.tokenType.present ? data.tokenType.value : this.tokenType,
      superUser: data.superUser.present ? data.superUser.value : this.superUser,
      userId: data.userId.present ? data.userId.value : this.userId,
      userName: data.userName.present ? data.userName.value : this.userName,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      level: data.level.present ? data.level.value : this.level,
      permissionsJson: data.permissionsJson.present
          ? data.permissionsJson.value
          : this.permissionsJson,
      wizard: data.wizard.present ? data.wizard.value : this.wizard,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LoginProfileRow(')
          ..write('id: $id, ')
          ..write('server: $server, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('accessToken: $accessToken, ')
          ..write('tokenType: $tokenType, ')
          ..write('superUser: $superUser, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('avatar: $avatar, ')
          ..write('level: $level, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('wizard: $wizard, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    server,
    username,
    password,
    accessToken,
    tokenType,
    superUser,
    userId,
    userName,
    avatar,
    level,
    permissionsJson,
    wizard,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoginProfileRow &&
          other.id == this.id &&
          other.server == this.server &&
          other.username == this.username &&
          other.password == this.password &&
          other.accessToken == this.accessToken &&
          other.tokenType == this.tokenType &&
          other.superUser == this.superUser &&
          other.userId == this.userId &&
          other.userName == this.userName &&
          other.avatar == this.avatar &&
          other.level == this.level &&
          other.permissionsJson == this.permissionsJson &&
          other.wizard == this.wizard &&
          other.updatedAt == this.updatedAt);
}

class LoginProfilesCompanion extends UpdateCompanion<LoginProfileRow> {
  final Value<String> id;
  final Value<String> server;
  final Value<String> username;
  final Value<String> password;
  final Value<String> accessToken;
  final Value<String> tokenType;
  final Value<bool> superUser;
  final Value<int> userId;
  final Value<String> userName;
  final Value<String?> avatar;
  final Value<int> level;
  final Value<String> permissionsJson;
  final Value<bool> wizard;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LoginProfilesCompanion({
    this.id = const Value.absent(),
    this.server = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.tokenType = const Value.absent(),
    this.superUser = const Value.absent(),
    this.userId = const Value.absent(),
    this.userName = const Value.absent(),
    this.avatar = const Value.absent(),
    this.level = const Value.absent(),
    this.permissionsJson = const Value.absent(),
    this.wizard = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoginProfilesCompanion.insert({
    required String id,
    required String server,
    required String username,
    required String password,
    required String accessToken,
    required String tokenType,
    required bool superUser,
    required int userId,
    required String userName,
    this.avatar = const Value.absent(),
    required int level,
    required String permissionsJson,
    required bool wizard,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       server = Value(server),
       username = Value(username),
       password = Value(password),
       accessToken = Value(accessToken),
       tokenType = Value(tokenType),
       superUser = Value(superUser),
       userId = Value(userId),
       userName = Value(userName),
       level = Value(level),
       permissionsJson = Value(permissionsJson),
       wizard = Value(wizard),
       updatedAt = Value(updatedAt);
  static Insertable<LoginProfileRow> custom({
    Expression<String>? id,
    Expression<String>? server,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? accessToken,
    Expression<String>? tokenType,
    Expression<bool>? superUser,
    Expression<int>? userId,
    Expression<String>? userName,
    Expression<String>? avatar,
    Expression<int>? level,
    Expression<String>? permissionsJson,
    Expression<bool>? wizard,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (server != null) 'server': server,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (accessToken != null) 'access_token': accessToken,
      if (tokenType != null) 'token_type': tokenType,
      if (superUser != null) 'super_user': superUser,
      if (userId != null) 'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (avatar != null) 'avatar': avatar,
      if (level != null) 'level': level,
      if (permissionsJson != null) 'permissions_json': permissionsJson,
      if (wizard != null) 'wizard': wizard,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoginProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? server,
    Value<String>? username,
    Value<String>? password,
    Value<String>? accessToken,
    Value<String>? tokenType,
    Value<bool>? superUser,
    Value<int>? userId,
    Value<String>? userName,
    Value<String?>? avatar,
    Value<int>? level,
    Value<String>? permissionsJson,
    Value<bool>? wizard,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LoginProfilesCompanion(
      id: id ?? this.id,
      server: server ?? this.server,
      username: username ?? this.username,
      password: password ?? this.password,
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      superUser: superUser ?? this.superUser,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatar: avatar ?? this.avatar,
      level: level ?? this.level,
      permissionsJson: permissionsJson ?? this.permissionsJson,
      wizard: wizard ?? this.wizard,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (server.present) {
      map['server'] = Variable<String>(server.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (tokenType.present) {
      map['token_type'] = Variable<String>(tokenType.value);
    }
    if (superUser.present) {
      map['super_user'] = Variable<bool>(superUser.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (permissionsJson.present) {
      map['permissions_json'] = Variable<String>(permissionsJson.value);
    }
    if (wizard.present) {
      map['wizard'] = Variable<bool>(wizard.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoginProfilesCompanion(')
          ..write('id: $id, ')
          ..write('server: $server, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('accessToken: $accessToken, ')
          ..write('tokenType: $tokenType, ')
          ..write('superUser: $superUser, ')
          ..write('userId: $userId, ')
          ..write('userName: $userName, ')
          ..write('avatar: $avatar, ')
          ..write('level: $level, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('wizard: $wizard, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaDetailCachesTable extends MediaDetailCaches
    with TableInfo<$MediaDetailCachesTable, MediaDetailCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaDetailCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<String> server = GeneratedColumn<String>(
    'server',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<String> year = GeneratedColumn<String>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeNameMeta = const VerificationMeta(
    'typeName',
  );
  @override
  late final GeneratedColumn<String> typeName = GeneratedColumn<String>(
    'type_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionMeta = const VerificationMeta(
    'session',
  );
  @override
  late final GeneratedColumn<String> session = GeneratedColumn<String>(
    'session',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    server,
    path,
    title,
    year,
    typeName,
    session,
    payload,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_detail_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaDetailCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server')) {
      context.handle(
        _serverMeta,
        server.isAcceptableOrUnknown(data['server']!, _serverMeta),
      );
    } else if (isInserting) {
      context.missing(_serverMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('type_name')) {
      context.handle(
        _typeNameMeta,
        typeName.isAcceptableOrUnknown(data['type_name']!, _typeNameMeta),
      );
    }
    if (data.containsKey('session')) {
      context.handle(
        _sessionMeta,
        session.isAcceptableOrUnknown(data['session']!, _sessionMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaDetailCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaDetailCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      server: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year'],
      ),
      typeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_name'],
      ),
      session: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MediaDetailCachesTable createAlias(String alias) {
    return $MediaDetailCachesTable(attachedDatabase, alias);
  }
}

class MediaDetailCacheRow extends DataClass
    implements Insertable<MediaDetailCacheRow> {
  final String id;
  final String server;
  final String path;
  final String? title;
  final String? year;
  final String? typeName;
  final String? session;
  final String payload;
  final DateTime updatedAt;
  const MediaDetailCacheRow({
    required this.id,
    required this.server,
    required this.path,
    this.title,
    this.year,
    this.typeName,
    this.session,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server'] = Variable<String>(server);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<String>(year);
    }
    if (!nullToAbsent || typeName != null) {
      map['type_name'] = Variable<String>(typeName);
    }
    if (!nullToAbsent || session != null) {
      map['session'] = Variable<String>(session);
    }
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MediaDetailCachesCompanion toCompanion(bool nullToAbsent) {
    return MediaDetailCachesCompanion(
      id: Value(id),
      server: Value(server),
      path: Value(path),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      typeName: typeName == null && nullToAbsent
          ? const Value.absent()
          : Value(typeName),
      session: session == null && nullToAbsent
          ? const Value.absent()
          : Value(session),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory MediaDetailCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaDetailCacheRow(
      id: serializer.fromJson<String>(json['id']),
      server: serializer.fromJson<String>(json['server']),
      path: serializer.fromJson<String>(json['path']),
      title: serializer.fromJson<String?>(json['title']),
      year: serializer.fromJson<String?>(json['year']),
      typeName: serializer.fromJson<String?>(json['typeName']),
      session: serializer.fromJson<String?>(json['session']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'server': serializer.toJson<String>(server),
      'path': serializer.toJson<String>(path),
      'title': serializer.toJson<String?>(title),
      'year': serializer.toJson<String?>(year),
      'typeName': serializer.toJson<String?>(typeName),
      'session': serializer.toJson<String?>(session),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MediaDetailCacheRow copyWith({
    String? id,
    String? server,
    String? path,
    Value<String?> title = const Value.absent(),
    Value<String?> year = const Value.absent(),
    Value<String?> typeName = const Value.absent(),
    Value<String?> session = const Value.absent(),
    String? payload,
    DateTime? updatedAt,
  }) => MediaDetailCacheRow(
    id: id ?? this.id,
    server: server ?? this.server,
    path: path ?? this.path,
    title: title.present ? title.value : this.title,
    year: year.present ? year.value : this.year,
    typeName: typeName.present ? typeName.value : this.typeName,
    session: session.present ? session.value : this.session,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MediaDetailCacheRow copyWithCompanion(MediaDetailCachesCompanion data) {
    return MediaDetailCacheRow(
      id: data.id.present ? data.id.value : this.id,
      server: data.server.present ? data.server.value : this.server,
      path: data.path.present ? data.path.value : this.path,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      typeName: data.typeName.present ? data.typeName.value : this.typeName,
      session: data.session.present ? data.session.value : this.session,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaDetailCacheRow(')
          ..write('id: $id, ')
          ..write('server: $server, ')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('typeName: $typeName, ')
          ..write('session: $session, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    server,
    path,
    title,
    year,
    typeName,
    session,
    payload,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaDetailCacheRow &&
          other.id == this.id &&
          other.server == this.server &&
          other.path == this.path &&
          other.title == this.title &&
          other.year == this.year &&
          other.typeName == this.typeName &&
          other.session == this.session &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class MediaDetailCachesCompanion extends UpdateCompanion<MediaDetailCacheRow> {
  final Value<String> id;
  final Value<String> server;
  final Value<String> path;
  final Value<String?> title;
  final Value<String?> year;
  final Value<String?> typeName;
  final Value<String?> session;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MediaDetailCachesCompanion({
    this.id = const Value.absent(),
    this.server = const Value.absent(),
    this.path = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.typeName = const Value.absent(),
    this.session = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaDetailCachesCompanion.insert({
    required String id,
    required String server,
    required String path,
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.typeName = const Value.absent(),
    this.session = const Value.absent(),
    required String payload,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       server = Value(server),
       path = Value(path),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<MediaDetailCacheRow> custom({
    Expression<String>? id,
    Expression<String>? server,
    Expression<String>? path,
    Expression<String>? title,
    Expression<String>? year,
    Expression<String>? typeName,
    Expression<String>? session,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (server != null) 'server': server,
      if (path != null) 'path': path,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (typeName != null) 'type_name': typeName,
      if (session != null) 'session': session,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaDetailCachesCompanion copyWith({
    Value<String>? id,
    Value<String>? server,
    Value<String>? path,
    Value<String?>? title,
    Value<String?>? year,
    Value<String?>? typeName,
    Value<String?>? session,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MediaDetailCachesCompanion(
      id: id ?? this.id,
      server: server ?? this.server,
      path: path ?? this.path,
      title: title ?? this.title,
      year: year ?? this.year,
      typeName: typeName ?? this.typeName,
      session: session ?? this.session,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (server.present) {
      map['server'] = Variable<String>(server.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<String>(year.value);
    }
    if (typeName.present) {
      map['type_name'] = Variable<String>(typeName.value);
    }
    if (session.present) {
      map['session'] = Variable<String>(session.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaDetailCachesCompanion(')
          ..write('id: $id, ')
          ..write('server: $server, ')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('typeName: $typeName, ')
          ..write('session: $session, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PluginModelCachesTable extends PluginModelCaches
    with TableInfo<$PluginModelCachesTable, PluginModelCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PluginModelCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginNameMeta = const VerificationMeta(
    'pluginName',
  );
  @override
  late final GeneratedColumn<String> pluginName = GeneratedColumn<String>(
    'plugin_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginDescMeta = const VerificationMeta(
    'pluginDesc',
  );
  @override
  late final GeneratedColumn<String> pluginDesc = GeneratedColumn<String>(
    'plugin_desc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginIconMeta = const VerificationMeta(
    'pluginIcon',
  );
  @override
  late final GeneratedColumn<String> pluginIcon = GeneratedColumn<String>(
    'plugin_icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginVersionMeta = const VerificationMeta(
    'pluginVersion',
  );
  @override
  late final GeneratedColumn<String> pluginVersion = GeneratedColumn<String>(
    'plugin_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginLabelMeta = const VerificationMeta(
    'pluginLabel',
  );
  @override
  late final GeneratedColumn<String> pluginLabel = GeneratedColumn<String>(
    'plugin_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginAuthorMeta = const VerificationMeta(
    'pluginAuthor',
  );
  @override
  late final GeneratedColumn<String> pluginAuthor = GeneratedColumn<String>(
    'plugin_author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorUrlMeta = const VerificationMeta(
    'authorUrl',
  );
  @override
  late final GeneratedColumn<String> authorUrl = GeneratedColumn<String>(
    'author_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginConfigPrefixMeta =
      const VerificationMeta('pluginConfigPrefix');
  @override
  late final GeneratedColumn<String> pluginConfigPrefix =
      GeneratedColumn<String>(
        'plugin_config_prefix',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pluginOrderMeta = const VerificationMeta(
    'pluginOrder',
  );
  @override
  late final GeneratedColumn<int> pluginOrder = GeneratedColumn<int>(
    'plugin_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authLevelMeta = const VerificationMeta(
    'authLevel',
  );
  @override
  late final GeneratedColumn<int> authLevel = GeneratedColumn<int>(
    'auth_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedMeta = const VerificationMeta(
    'installed',
  );
  @override
  late final GeneratedColumn<bool> installed = GeneratedColumn<bool>(
    'installed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("installed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<bool> state = GeneratedColumn<bool>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("state" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hasPageMeta = const VerificationMeta(
    'hasPage',
  );
  @override
  late final GeneratedColumn<bool> hasPage = GeneratedColumn<bool>(
    'has_page',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_page" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hasUpdateMeta = const VerificationMeta(
    'hasUpdate',
  );
  @override
  late final GeneratedColumn<bool> hasUpdate = GeneratedColumn<bool>(
    'has_update',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_update" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isLocalMeta = const VerificationMeta(
    'isLocal',
  );
  @override
  late final GeneratedColumn<bool> isLocal = GeneratedColumn<bool>(
    'is_local',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local" IN (0, 1))',
    ),
  );
  static const VerificationMeta _repoUrlMeta = const VerificationMeta(
    'repoUrl',
  );
  @override
  late final GeneratedColumn<String> repoUrl = GeneratedColumn<String>(
    'repo_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installCountMeta = const VerificationMeta(
    'installCount',
  );
  @override
  late final GeneratedColumn<int> installCount = GeneratedColumn<int>(
    'install_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addTimeMeta = const VerificationMeta(
    'addTime',
  );
  @override
  late final GeneratedColumn<int> addTime = GeneratedColumn<int>(
    'add_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginPublicKeyMeta = const VerificationMeta(
    'pluginPublicKey',
  );
  @override
  late final GeneratedColumn<String> pluginPublicKey = GeneratedColumn<String>(
    'plugin_public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pluginName,
    pluginDesc,
    pluginIcon,
    pluginVersion,
    pluginLabel,
    pluginAuthor,
    authorUrl,
    pluginConfigPrefix,
    pluginOrder,
    authLevel,
    installed,
    state,
    hasPage,
    hasUpdate,
    isLocal,
    repoUrl,
    installCount,
    addTime,
    pluginPublicKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plugin_model_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<PluginModelCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plugin_name')) {
      context.handle(
        _pluginNameMeta,
        pluginName.isAcceptableOrUnknown(data['plugin_name']!, _pluginNameMeta),
      );
    } else if (isInserting) {
      context.missing(_pluginNameMeta);
    }
    if (data.containsKey('plugin_desc')) {
      context.handle(
        _pluginDescMeta,
        pluginDesc.isAcceptableOrUnknown(data['plugin_desc']!, _pluginDescMeta),
      );
    } else if (isInserting) {
      context.missing(_pluginDescMeta);
    }
    if (data.containsKey('plugin_icon')) {
      context.handle(
        _pluginIconMeta,
        pluginIcon.isAcceptableOrUnknown(data['plugin_icon']!, _pluginIconMeta),
      );
    } else if (isInserting) {
      context.missing(_pluginIconMeta);
    }
    if (data.containsKey('plugin_version')) {
      context.handle(
        _pluginVersionMeta,
        pluginVersion.isAcceptableOrUnknown(
          data['plugin_version']!,
          _pluginVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginVersionMeta);
    }
    if (data.containsKey('plugin_label')) {
      context.handle(
        _pluginLabelMeta,
        pluginLabel.isAcceptableOrUnknown(
          data['plugin_label']!,
          _pluginLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginLabelMeta);
    }
    if (data.containsKey('plugin_author')) {
      context.handle(
        _pluginAuthorMeta,
        pluginAuthor.isAcceptableOrUnknown(
          data['plugin_author']!,
          _pluginAuthorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginAuthorMeta);
    }
    if (data.containsKey('author_url')) {
      context.handle(
        _authorUrlMeta,
        authorUrl.isAcceptableOrUnknown(data['author_url']!, _authorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_authorUrlMeta);
    }
    if (data.containsKey('plugin_config_prefix')) {
      context.handle(
        _pluginConfigPrefixMeta,
        pluginConfigPrefix.isAcceptableOrUnknown(
          data['plugin_config_prefix']!,
          _pluginConfigPrefixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginConfigPrefixMeta);
    }
    if (data.containsKey('plugin_order')) {
      context.handle(
        _pluginOrderMeta,
        pluginOrder.isAcceptableOrUnknown(
          data['plugin_order']!,
          _pluginOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginOrderMeta);
    }
    if (data.containsKey('auth_level')) {
      context.handle(
        _authLevelMeta,
        authLevel.isAcceptableOrUnknown(data['auth_level']!, _authLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_authLevelMeta);
    }
    if (data.containsKey('installed')) {
      context.handle(
        _installedMeta,
        installed.isAcceptableOrUnknown(data['installed']!, _installedMeta),
      );
    } else if (isInserting) {
      context.missing(_installedMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('has_page')) {
      context.handle(
        _hasPageMeta,
        hasPage.isAcceptableOrUnknown(data['has_page']!, _hasPageMeta),
      );
    } else if (isInserting) {
      context.missing(_hasPageMeta);
    }
    if (data.containsKey('has_update')) {
      context.handle(
        _hasUpdateMeta,
        hasUpdate.isAcceptableOrUnknown(data['has_update']!, _hasUpdateMeta),
      );
    } else if (isInserting) {
      context.missing(_hasUpdateMeta);
    }
    if (data.containsKey('is_local')) {
      context.handle(
        _isLocalMeta,
        isLocal.isAcceptableOrUnknown(data['is_local']!, _isLocalMeta),
      );
    } else if (isInserting) {
      context.missing(_isLocalMeta);
    }
    if (data.containsKey('repo_url')) {
      context.handle(
        _repoUrlMeta,
        repoUrl.isAcceptableOrUnknown(data['repo_url']!, _repoUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_repoUrlMeta);
    }
    if (data.containsKey('install_count')) {
      context.handle(
        _installCountMeta,
        installCount.isAcceptableOrUnknown(
          data['install_count']!,
          _installCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installCountMeta);
    }
    if (data.containsKey('add_time')) {
      context.handle(
        _addTimeMeta,
        addTime.isAcceptableOrUnknown(data['add_time']!, _addTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_addTimeMeta);
    }
    if (data.containsKey('plugin_public_key')) {
      context.handle(
        _pluginPublicKeyMeta,
        pluginPublicKey.isAcceptableOrUnknown(
          data['plugin_public_key']!,
          _pluginPublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginPublicKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PluginModelCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PluginModelCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pluginName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_name'],
      )!,
      pluginDesc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_desc'],
      )!,
      pluginIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_icon'],
      )!,
      pluginVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_version'],
      )!,
      pluginLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_label'],
      )!,
      pluginAuthor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_author'],
      )!,
      authorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_url'],
      )!,
      pluginConfigPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_config_prefix'],
      )!,
      pluginOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plugin_order'],
      )!,
      authLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auth_level'],
      )!,
      installed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}installed'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}state'],
      )!,
      hasPage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_page'],
      )!,
      hasUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_update'],
      )!,
      isLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local'],
      )!,
      repoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_url'],
      )!,
      installCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}install_count'],
      )!,
      addTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}add_time'],
      )!,
      pluginPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_public_key'],
      )!,
    );
  }

  @override
  $PluginModelCachesTable createAlias(String alias) {
    return $PluginModelCachesTable(attachedDatabase, alias);
  }
}

class PluginModelCacheRow extends DataClass
    implements Insertable<PluginModelCacheRow> {
  final String id;
  final String pluginName;
  final String pluginDesc;
  final String pluginIcon;
  final String pluginVersion;
  final String pluginLabel;
  final String pluginAuthor;
  final String authorUrl;
  final String pluginConfigPrefix;
  final int pluginOrder;
  final int authLevel;
  final bool installed;
  final bool state;
  final bool hasPage;
  final bool hasUpdate;
  final bool isLocal;
  final String repoUrl;
  final int installCount;
  final int addTime;
  final String pluginPublicKey;
  const PluginModelCacheRow({
    required this.id,
    required this.pluginName,
    required this.pluginDesc,
    required this.pluginIcon,
    required this.pluginVersion,
    required this.pluginLabel,
    required this.pluginAuthor,
    required this.authorUrl,
    required this.pluginConfigPrefix,
    required this.pluginOrder,
    required this.authLevel,
    required this.installed,
    required this.state,
    required this.hasPage,
    required this.hasUpdate,
    required this.isLocal,
    required this.repoUrl,
    required this.installCount,
    required this.addTime,
    required this.pluginPublicKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plugin_name'] = Variable<String>(pluginName);
    map['plugin_desc'] = Variable<String>(pluginDesc);
    map['plugin_icon'] = Variable<String>(pluginIcon);
    map['plugin_version'] = Variable<String>(pluginVersion);
    map['plugin_label'] = Variable<String>(pluginLabel);
    map['plugin_author'] = Variable<String>(pluginAuthor);
    map['author_url'] = Variable<String>(authorUrl);
    map['plugin_config_prefix'] = Variable<String>(pluginConfigPrefix);
    map['plugin_order'] = Variable<int>(pluginOrder);
    map['auth_level'] = Variable<int>(authLevel);
    map['installed'] = Variable<bool>(installed);
    map['state'] = Variable<bool>(state);
    map['has_page'] = Variable<bool>(hasPage);
    map['has_update'] = Variable<bool>(hasUpdate);
    map['is_local'] = Variable<bool>(isLocal);
    map['repo_url'] = Variable<String>(repoUrl);
    map['install_count'] = Variable<int>(installCount);
    map['add_time'] = Variable<int>(addTime);
    map['plugin_public_key'] = Variable<String>(pluginPublicKey);
    return map;
  }

  PluginModelCachesCompanion toCompanion(bool nullToAbsent) {
    return PluginModelCachesCompanion(
      id: Value(id),
      pluginName: Value(pluginName),
      pluginDesc: Value(pluginDesc),
      pluginIcon: Value(pluginIcon),
      pluginVersion: Value(pluginVersion),
      pluginLabel: Value(pluginLabel),
      pluginAuthor: Value(pluginAuthor),
      authorUrl: Value(authorUrl),
      pluginConfigPrefix: Value(pluginConfigPrefix),
      pluginOrder: Value(pluginOrder),
      authLevel: Value(authLevel),
      installed: Value(installed),
      state: Value(state),
      hasPage: Value(hasPage),
      hasUpdate: Value(hasUpdate),
      isLocal: Value(isLocal),
      repoUrl: Value(repoUrl),
      installCount: Value(installCount),
      addTime: Value(addTime),
      pluginPublicKey: Value(pluginPublicKey),
    );
  }

  factory PluginModelCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PluginModelCacheRow(
      id: serializer.fromJson<String>(json['id']),
      pluginName: serializer.fromJson<String>(json['pluginName']),
      pluginDesc: serializer.fromJson<String>(json['pluginDesc']),
      pluginIcon: serializer.fromJson<String>(json['pluginIcon']),
      pluginVersion: serializer.fromJson<String>(json['pluginVersion']),
      pluginLabel: serializer.fromJson<String>(json['pluginLabel']),
      pluginAuthor: serializer.fromJson<String>(json['pluginAuthor']),
      authorUrl: serializer.fromJson<String>(json['authorUrl']),
      pluginConfigPrefix: serializer.fromJson<String>(
        json['pluginConfigPrefix'],
      ),
      pluginOrder: serializer.fromJson<int>(json['pluginOrder']),
      authLevel: serializer.fromJson<int>(json['authLevel']),
      installed: serializer.fromJson<bool>(json['installed']),
      state: serializer.fromJson<bool>(json['state']),
      hasPage: serializer.fromJson<bool>(json['hasPage']),
      hasUpdate: serializer.fromJson<bool>(json['hasUpdate']),
      isLocal: serializer.fromJson<bool>(json['isLocal']),
      repoUrl: serializer.fromJson<String>(json['repoUrl']),
      installCount: serializer.fromJson<int>(json['installCount']),
      addTime: serializer.fromJson<int>(json['addTime']),
      pluginPublicKey: serializer.fromJson<String>(json['pluginPublicKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pluginName': serializer.toJson<String>(pluginName),
      'pluginDesc': serializer.toJson<String>(pluginDesc),
      'pluginIcon': serializer.toJson<String>(pluginIcon),
      'pluginVersion': serializer.toJson<String>(pluginVersion),
      'pluginLabel': serializer.toJson<String>(pluginLabel),
      'pluginAuthor': serializer.toJson<String>(pluginAuthor),
      'authorUrl': serializer.toJson<String>(authorUrl),
      'pluginConfigPrefix': serializer.toJson<String>(pluginConfigPrefix),
      'pluginOrder': serializer.toJson<int>(pluginOrder),
      'authLevel': serializer.toJson<int>(authLevel),
      'installed': serializer.toJson<bool>(installed),
      'state': serializer.toJson<bool>(state),
      'hasPage': serializer.toJson<bool>(hasPage),
      'hasUpdate': serializer.toJson<bool>(hasUpdate),
      'isLocal': serializer.toJson<bool>(isLocal),
      'repoUrl': serializer.toJson<String>(repoUrl),
      'installCount': serializer.toJson<int>(installCount),
      'addTime': serializer.toJson<int>(addTime),
      'pluginPublicKey': serializer.toJson<String>(pluginPublicKey),
    };
  }

  PluginModelCacheRow copyWith({
    String? id,
    String? pluginName,
    String? pluginDesc,
    String? pluginIcon,
    String? pluginVersion,
    String? pluginLabel,
    String? pluginAuthor,
    String? authorUrl,
    String? pluginConfigPrefix,
    int? pluginOrder,
    int? authLevel,
    bool? installed,
    bool? state,
    bool? hasPage,
    bool? hasUpdate,
    bool? isLocal,
    String? repoUrl,
    int? installCount,
    int? addTime,
    String? pluginPublicKey,
  }) => PluginModelCacheRow(
    id: id ?? this.id,
    pluginName: pluginName ?? this.pluginName,
    pluginDesc: pluginDesc ?? this.pluginDesc,
    pluginIcon: pluginIcon ?? this.pluginIcon,
    pluginVersion: pluginVersion ?? this.pluginVersion,
    pluginLabel: pluginLabel ?? this.pluginLabel,
    pluginAuthor: pluginAuthor ?? this.pluginAuthor,
    authorUrl: authorUrl ?? this.authorUrl,
    pluginConfigPrefix: pluginConfigPrefix ?? this.pluginConfigPrefix,
    pluginOrder: pluginOrder ?? this.pluginOrder,
    authLevel: authLevel ?? this.authLevel,
    installed: installed ?? this.installed,
    state: state ?? this.state,
    hasPage: hasPage ?? this.hasPage,
    hasUpdate: hasUpdate ?? this.hasUpdate,
    isLocal: isLocal ?? this.isLocal,
    repoUrl: repoUrl ?? this.repoUrl,
    installCount: installCount ?? this.installCount,
    addTime: addTime ?? this.addTime,
    pluginPublicKey: pluginPublicKey ?? this.pluginPublicKey,
  );
  PluginModelCacheRow copyWithCompanion(PluginModelCachesCompanion data) {
    return PluginModelCacheRow(
      id: data.id.present ? data.id.value : this.id,
      pluginName: data.pluginName.present
          ? data.pluginName.value
          : this.pluginName,
      pluginDesc: data.pluginDesc.present
          ? data.pluginDesc.value
          : this.pluginDesc,
      pluginIcon: data.pluginIcon.present
          ? data.pluginIcon.value
          : this.pluginIcon,
      pluginVersion: data.pluginVersion.present
          ? data.pluginVersion.value
          : this.pluginVersion,
      pluginLabel: data.pluginLabel.present
          ? data.pluginLabel.value
          : this.pluginLabel,
      pluginAuthor: data.pluginAuthor.present
          ? data.pluginAuthor.value
          : this.pluginAuthor,
      authorUrl: data.authorUrl.present ? data.authorUrl.value : this.authorUrl,
      pluginConfigPrefix: data.pluginConfigPrefix.present
          ? data.pluginConfigPrefix.value
          : this.pluginConfigPrefix,
      pluginOrder: data.pluginOrder.present
          ? data.pluginOrder.value
          : this.pluginOrder,
      authLevel: data.authLevel.present ? data.authLevel.value : this.authLevel,
      installed: data.installed.present ? data.installed.value : this.installed,
      state: data.state.present ? data.state.value : this.state,
      hasPage: data.hasPage.present ? data.hasPage.value : this.hasPage,
      hasUpdate: data.hasUpdate.present ? data.hasUpdate.value : this.hasUpdate,
      isLocal: data.isLocal.present ? data.isLocal.value : this.isLocal,
      repoUrl: data.repoUrl.present ? data.repoUrl.value : this.repoUrl,
      installCount: data.installCount.present
          ? data.installCount.value
          : this.installCount,
      addTime: data.addTime.present ? data.addTime.value : this.addTime,
      pluginPublicKey: data.pluginPublicKey.present
          ? data.pluginPublicKey.value
          : this.pluginPublicKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PluginModelCacheRow(')
          ..write('id: $id, ')
          ..write('pluginName: $pluginName, ')
          ..write('pluginDesc: $pluginDesc, ')
          ..write('pluginIcon: $pluginIcon, ')
          ..write('pluginVersion: $pluginVersion, ')
          ..write('pluginLabel: $pluginLabel, ')
          ..write('pluginAuthor: $pluginAuthor, ')
          ..write('authorUrl: $authorUrl, ')
          ..write('pluginConfigPrefix: $pluginConfigPrefix, ')
          ..write('pluginOrder: $pluginOrder, ')
          ..write('authLevel: $authLevel, ')
          ..write('installed: $installed, ')
          ..write('state: $state, ')
          ..write('hasPage: $hasPage, ')
          ..write('hasUpdate: $hasUpdate, ')
          ..write('isLocal: $isLocal, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('installCount: $installCount, ')
          ..write('addTime: $addTime, ')
          ..write('pluginPublicKey: $pluginPublicKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pluginName,
    pluginDesc,
    pluginIcon,
    pluginVersion,
    pluginLabel,
    pluginAuthor,
    authorUrl,
    pluginConfigPrefix,
    pluginOrder,
    authLevel,
    installed,
    state,
    hasPage,
    hasUpdate,
    isLocal,
    repoUrl,
    installCount,
    addTime,
    pluginPublicKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PluginModelCacheRow &&
          other.id == this.id &&
          other.pluginName == this.pluginName &&
          other.pluginDesc == this.pluginDesc &&
          other.pluginIcon == this.pluginIcon &&
          other.pluginVersion == this.pluginVersion &&
          other.pluginLabel == this.pluginLabel &&
          other.pluginAuthor == this.pluginAuthor &&
          other.authorUrl == this.authorUrl &&
          other.pluginConfigPrefix == this.pluginConfigPrefix &&
          other.pluginOrder == this.pluginOrder &&
          other.authLevel == this.authLevel &&
          other.installed == this.installed &&
          other.state == this.state &&
          other.hasPage == this.hasPage &&
          other.hasUpdate == this.hasUpdate &&
          other.isLocal == this.isLocal &&
          other.repoUrl == this.repoUrl &&
          other.installCount == this.installCount &&
          other.addTime == this.addTime &&
          other.pluginPublicKey == this.pluginPublicKey);
}

class PluginModelCachesCompanion extends UpdateCompanion<PluginModelCacheRow> {
  final Value<String> id;
  final Value<String> pluginName;
  final Value<String> pluginDesc;
  final Value<String> pluginIcon;
  final Value<String> pluginVersion;
  final Value<String> pluginLabel;
  final Value<String> pluginAuthor;
  final Value<String> authorUrl;
  final Value<String> pluginConfigPrefix;
  final Value<int> pluginOrder;
  final Value<int> authLevel;
  final Value<bool> installed;
  final Value<bool> state;
  final Value<bool> hasPage;
  final Value<bool> hasUpdate;
  final Value<bool> isLocal;
  final Value<String> repoUrl;
  final Value<int> installCount;
  final Value<int> addTime;
  final Value<String> pluginPublicKey;
  final Value<int> rowid;
  const PluginModelCachesCompanion({
    this.id = const Value.absent(),
    this.pluginName = const Value.absent(),
    this.pluginDesc = const Value.absent(),
    this.pluginIcon = const Value.absent(),
    this.pluginVersion = const Value.absent(),
    this.pluginLabel = const Value.absent(),
    this.pluginAuthor = const Value.absent(),
    this.authorUrl = const Value.absent(),
    this.pluginConfigPrefix = const Value.absent(),
    this.pluginOrder = const Value.absent(),
    this.authLevel = const Value.absent(),
    this.installed = const Value.absent(),
    this.state = const Value.absent(),
    this.hasPage = const Value.absent(),
    this.hasUpdate = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.repoUrl = const Value.absent(),
    this.installCount = const Value.absent(),
    this.addTime = const Value.absent(),
    this.pluginPublicKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PluginModelCachesCompanion.insert({
    required String id,
    required String pluginName,
    required String pluginDesc,
    required String pluginIcon,
    required String pluginVersion,
    required String pluginLabel,
    required String pluginAuthor,
    required String authorUrl,
    required String pluginConfigPrefix,
    required int pluginOrder,
    required int authLevel,
    required bool installed,
    required bool state,
    required bool hasPage,
    required bool hasUpdate,
    required bool isLocal,
    required String repoUrl,
    required int installCount,
    required int addTime,
    required String pluginPublicKey,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pluginName = Value(pluginName),
       pluginDesc = Value(pluginDesc),
       pluginIcon = Value(pluginIcon),
       pluginVersion = Value(pluginVersion),
       pluginLabel = Value(pluginLabel),
       pluginAuthor = Value(pluginAuthor),
       authorUrl = Value(authorUrl),
       pluginConfigPrefix = Value(pluginConfigPrefix),
       pluginOrder = Value(pluginOrder),
       authLevel = Value(authLevel),
       installed = Value(installed),
       state = Value(state),
       hasPage = Value(hasPage),
       hasUpdate = Value(hasUpdate),
       isLocal = Value(isLocal),
       repoUrl = Value(repoUrl),
       installCount = Value(installCount),
       addTime = Value(addTime),
       pluginPublicKey = Value(pluginPublicKey);
  static Insertable<PluginModelCacheRow> custom({
    Expression<String>? id,
    Expression<String>? pluginName,
    Expression<String>? pluginDesc,
    Expression<String>? pluginIcon,
    Expression<String>? pluginVersion,
    Expression<String>? pluginLabel,
    Expression<String>? pluginAuthor,
    Expression<String>? authorUrl,
    Expression<String>? pluginConfigPrefix,
    Expression<int>? pluginOrder,
    Expression<int>? authLevel,
    Expression<bool>? installed,
    Expression<bool>? state,
    Expression<bool>? hasPage,
    Expression<bool>? hasUpdate,
    Expression<bool>? isLocal,
    Expression<String>? repoUrl,
    Expression<int>? installCount,
    Expression<int>? addTime,
    Expression<String>? pluginPublicKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pluginName != null) 'plugin_name': pluginName,
      if (pluginDesc != null) 'plugin_desc': pluginDesc,
      if (pluginIcon != null) 'plugin_icon': pluginIcon,
      if (pluginVersion != null) 'plugin_version': pluginVersion,
      if (pluginLabel != null) 'plugin_label': pluginLabel,
      if (pluginAuthor != null) 'plugin_author': pluginAuthor,
      if (authorUrl != null) 'author_url': authorUrl,
      if (pluginConfigPrefix != null)
        'plugin_config_prefix': pluginConfigPrefix,
      if (pluginOrder != null) 'plugin_order': pluginOrder,
      if (authLevel != null) 'auth_level': authLevel,
      if (installed != null) 'installed': installed,
      if (state != null) 'state': state,
      if (hasPage != null) 'has_page': hasPage,
      if (hasUpdate != null) 'has_update': hasUpdate,
      if (isLocal != null) 'is_local': isLocal,
      if (repoUrl != null) 'repo_url': repoUrl,
      if (installCount != null) 'install_count': installCount,
      if (addTime != null) 'add_time': addTime,
      if (pluginPublicKey != null) 'plugin_public_key': pluginPublicKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PluginModelCachesCompanion copyWith({
    Value<String>? id,
    Value<String>? pluginName,
    Value<String>? pluginDesc,
    Value<String>? pluginIcon,
    Value<String>? pluginVersion,
    Value<String>? pluginLabel,
    Value<String>? pluginAuthor,
    Value<String>? authorUrl,
    Value<String>? pluginConfigPrefix,
    Value<int>? pluginOrder,
    Value<int>? authLevel,
    Value<bool>? installed,
    Value<bool>? state,
    Value<bool>? hasPage,
    Value<bool>? hasUpdate,
    Value<bool>? isLocal,
    Value<String>? repoUrl,
    Value<int>? installCount,
    Value<int>? addTime,
    Value<String>? pluginPublicKey,
    Value<int>? rowid,
  }) {
    return PluginModelCachesCompanion(
      id: id ?? this.id,
      pluginName: pluginName ?? this.pluginName,
      pluginDesc: pluginDesc ?? this.pluginDesc,
      pluginIcon: pluginIcon ?? this.pluginIcon,
      pluginVersion: pluginVersion ?? this.pluginVersion,
      pluginLabel: pluginLabel ?? this.pluginLabel,
      pluginAuthor: pluginAuthor ?? this.pluginAuthor,
      authorUrl: authorUrl ?? this.authorUrl,
      pluginConfigPrefix: pluginConfigPrefix ?? this.pluginConfigPrefix,
      pluginOrder: pluginOrder ?? this.pluginOrder,
      authLevel: authLevel ?? this.authLevel,
      installed: installed ?? this.installed,
      state: state ?? this.state,
      hasPage: hasPage ?? this.hasPage,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      isLocal: isLocal ?? this.isLocal,
      repoUrl: repoUrl ?? this.repoUrl,
      installCount: installCount ?? this.installCount,
      addTime: addTime ?? this.addTime,
      pluginPublicKey: pluginPublicKey ?? this.pluginPublicKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pluginName.present) {
      map['plugin_name'] = Variable<String>(pluginName.value);
    }
    if (pluginDesc.present) {
      map['plugin_desc'] = Variable<String>(pluginDesc.value);
    }
    if (pluginIcon.present) {
      map['plugin_icon'] = Variable<String>(pluginIcon.value);
    }
    if (pluginVersion.present) {
      map['plugin_version'] = Variable<String>(pluginVersion.value);
    }
    if (pluginLabel.present) {
      map['plugin_label'] = Variable<String>(pluginLabel.value);
    }
    if (pluginAuthor.present) {
      map['plugin_author'] = Variable<String>(pluginAuthor.value);
    }
    if (authorUrl.present) {
      map['author_url'] = Variable<String>(authorUrl.value);
    }
    if (pluginConfigPrefix.present) {
      map['plugin_config_prefix'] = Variable<String>(pluginConfigPrefix.value);
    }
    if (pluginOrder.present) {
      map['plugin_order'] = Variable<int>(pluginOrder.value);
    }
    if (authLevel.present) {
      map['auth_level'] = Variable<int>(authLevel.value);
    }
    if (installed.present) {
      map['installed'] = Variable<bool>(installed.value);
    }
    if (state.present) {
      map['state'] = Variable<bool>(state.value);
    }
    if (hasPage.present) {
      map['has_page'] = Variable<bool>(hasPage.value);
    }
    if (hasUpdate.present) {
      map['has_update'] = Variable<bool>(hasUpdate.value);
    }
    if (isLocal.present) {
      map['is_local'] = Variable<bool>(isLocal.value);
    }
    if (repoUrl.present) {
      map['repo_url'] = Variable<String>(repoUrl.value);
    }
    if (installCount.present) {
      map['install_count'] = Variable<int>(installCount.value);
    }
    if (addTime.present) {
      map['add_time'] = Variable<int>(addTime.value);
    }
    if (pluginPublicKey.present) {
      map['plugin_public_key'] = Variable<String>(pluginPublicKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PluginModelCachesCompanion(')
          ..write('id: $id, ')
          ..write('pluginName: $pluginName, ')
          ..write('pluginDesc: $pluginDesc, ')
          ..write('pluginIcon: $pluginIcon, ')
          ..write('pluginVersion: $pluginVersion, ')
          ..write('pluginLabel: $pluginLabel, ')
          ..write('pluginAuthor: $pluginAuthor, ')
          ..write('authorUrl: $authorUrl, ')
          ..write('pluginConfigPrefix: $pluginConfigPrefix, ')
          ..write('pluginOrder: $pluginOrder, ')
          ..write('authLevel: $authLevel, ')
          ..write('installed: $installed, ')
          ..write('state: $state, ')
          ..write('hasPage: $hasPage, ')
          ..write('hasUpdate: $hasUpdate, ')
          ..write('isLocal: $isLocal, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('installCount: $installCount, ')
          ..write('addTime: $addTime, ')
          ..write('pluginPublicKey: $pluginPublicKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstalledPluginModelCachesTable extends InstalledPluginModelCaches
    with
        TableInfo<
          $InstalledPluginModelCachesTable,
          InstalledPluginModelCacheRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstalledPluginModelCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginNameMeta = const VerificationMeta(
    'pluginName',
  );
  @override
  late final GeneratedColumn<String> pluginName = GeneratedColumn<String>(
    'plugin_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginDescMeta = const VerificationMeta(
    'pluginDesc',
  );
  @override
  late final GeneratedColumn<String> pluginDesc = GeneratedColumn<String>(
    'plugin_desc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginIconMeta = const VerificationMeta(
    'pluginIcon',
  );
  @override
  late final GeneratedColumn<String> pluginIcon = GeneratedColumn<String>(
    'plugin_icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginVersionMeta = const VerificationMeta(
    'pluginVersion',
  );
  @override
  late final GeneratedColumn<String> pluginVersion = GeneratedColumn<String>(
    'plugin_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginLabelMeta = const VerificationMeta(
    'pluginLabel',
  );
  @override
  late final GeneratedColumn<String> pluginLabel = GeneratedColumn<String>(
    'plugin_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginAuthorMeta = const VerificationMeta(
    'pluginAuthor',
  );
  @override
  late final GeneratedColumn<String> pluginAuthor = GeneratedColumn<String>(
    'plugin_author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorUrlMeta = const VerificationMeta(
    'authorUrl',
  );
  @override
  late final GeneratedColumn<String> authorUrl = GeneratedColumn<String>(
    'author_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginConfigPrefixMeta =
      const VerificationMeta('pluginConfigPrefix');
  @override
  late final GeneratedColumn<String> pluginConfigPrefix =
      GeneratedColumn<String>(
        'plugin_config_prefix',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pluginOrderMeta = const VerificationMeta(
    'pluginOrder',
  );
  @override
  late final GeneratedColumn<int> pluginOrder = GeneratedColumn<int>(
    'plugin_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authLevelMeta = const VerificationMeta(
    'authLevel',
  );
  @override
  late final GeneratedColumn<int> authLevel = GeneratedColumn<int>(
    'auth_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedMeta = const VerificationMeta(
    'installed',
  );
  @override
  late final GeneratedColumn<bool> installed = GeneratedColumn<bool>(
    'installed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("installed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<bool> state = GeneratedColumn<bool>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("state" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hasPageMeta = const VerificationMeta(
    'hasPage',
  );
  @override
  late final GeneratedColumn<bool> hasPage = GeneratedColumn<bool>(
    'has_page',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_page" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hasUpdateMeta = const VerificationMeta(
    'hasUpdate',
  );
  @override
  late final GeneratedColumn<bool> hasUpdate = GeneratedColumn<bool>(
    'has_update',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_update" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isLocalMeta = const VerificationMeta(
    'isLocal',
  );
  @override
  late final GeneratedColumn<bool> isLocal = GeneratedColumn<bool>(
    'is_local',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local" IN (0, 1))',
    ),
  );
  static const VerificationMeta _repoUrlMeta = const VerificationMeta(
    'repoUrl',
  );
  @override
  late final GeneratedColumn<String> repoUrl = GeneratedColumn<String>(
    'repo_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installCountMeta = const VerificationMeta(
    'installCount',
  );
  @override
  late final GeneratedColumn<int> installCount = GeneratedColumn<int>(
    'install_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addTimeMeta = const VerificationMeta(
    'addTime',
  );
  @override
  late final GeneratedColumn<int> addTime = GeneratedColumn<int>(
    'add_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pluginPublicKeyMeta = const VerificationMeta(
    'pluginPublicKey',
  );
  @override
  late final GeneratedColumn<String> pluginPublicKey = GeneratedColumn<String>(
    'plugin_public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pluginName,
    pluginDesc,
    pluginIcon,
    pluginVersion,
    pluginLabel,
    pluginAuthor,
    authorUrl,
    pluginConfigPrefix,
    pluginOrder,
    authLevel,
    installed,
    state,
    hasPage,
    hasUpdate,
    isLocal,
    repoUrl,
    installCount,
    addTime,
    pluginPublicKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installed_plugin_model_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstalledPluginModelCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plugin_name')) {
      context.handle(
        _pluginNameMeta,
        pluginName.isAcceptableOrUnknown(data['plugin_name']!, _pluginNameMeta),
      );
    } else if (isInserting) {
      context.missing(_pluginNameMeta);
    }
    if (data.containsKey('plugin_desc')) {
      context.handle(
        _pluginDescMeta,
        pluginDesc.isAcceptableOrUnknown(data['plugin_desc']!, _pluginDescMeta),
      );
    } else if (isInserting) {
      context.missing(_pluginDescMeta);
    }
    if (data.containsKey('plugin_icon')) {
      context.handle(
        _pluginIconMeta,
        pluginIcon.isAcceptableOrUnknown(data['plugin_icon']!, _pluginIconMeta),
      );
    } else if (isInserting) {
      context.missing(_pluginIconMeta);
    }
    if (data.containsKey('plugin_version')) {
      context.handle(
        _pluginVersionMeta,
        pluginVersion.isAcceptableOrUnknown(
          data['plugin_version']!,
          _pluginVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginVersionMeta);
    }
    if (data.containsKey('plugin_label')) {
      context.handle(
        _pluginLabelMeta,
        pluginLabel.isAcceptableOrUnknown(
          data['plugin_label']!,
          _pluginLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginLabelMeta);
    }
    if (data.containsKey('plugin_author')) {
      context.handle(
        _pluginAuthorMeta,
        pluginAuthor.isAcceptableOrUnknown(
          data['plugin_author']!,
          _pluginAuthorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginAuthorMeta);
    }
    if (data.containsKey('author_url')) {
      context.handle(
        _authorUrlMeta,
        authorUrl.isAcceptableOrUnknown(data['author_url']!, _authorUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_authorUrlMeta);
    }
    if (data.containsKey('plugin_config_prefix')) {
      context.handle(
        _pluginConfigPrefixMeta,
        pluginConfigPrefix.isAcceptableOrUnknown(
          data['plugin_config_prefix']!,
          _pluginConfigPrefixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginConfigPrefixMeta);
    }
    if (data.containsKey('plugin_order')) {
      context.handle(
        _pluginOrderMeta,
        pluginOrder.isAcceptableOrUnknown(
          data['plugin_order']!,
          _pluginOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginOrderMeta);
    }
    if (data.containsKey('auth_level')) {
      context.handle(
        _authLevelMeta,
        authLevel.isAcceptableOrUnknown(data['auth_level']!, _authLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_authLevelMeta);
    }
    if (data.containsKey('installed')) {
      context.handle(
        _installedMeta,
        installed.isAcceptableOrUnknown(data['installed']!, _installedMeta),
      );
    } else if (isInserting) {
      context.missing(_installedMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('has_page')) {
      context.handle(
        _hasPageMeta,
        hasPage.isAcceptableOrUnknown(data['has_page']!, _hasPageMeta),
      );
    } else if (isInserting) {
      context.missing(_hasPageMeta);
    }
    if (data.containsKey('has_update')) {
      context.handle(
        _hasUpdateMeta,
        hasUpdate.isAcceptableOrUnknown(data['has_update']!, _hasUpdateMeta),
      );
    } else if (isInserting) {
      context.missing(_hasUpdateMeta);
    }
    if (data.containsKey('is_local')) {
      context.handle(
        _isLocalMeta,
        isLocal.isAcceptableOrUnknown(data['is_local']!, _isLocalMeta),
      );
    } else if (isInserting) {
      context.missing(_isLocalMeta);
    }
    if (data.containsKey('repo_url')) {
      context.handle(
        _repoUrlMeta,
        repoUrl.isAcceptableOrUnknown(data['repo_url']!, _repoUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_repoUrlMeta);
    }
    if (data.containsKey('install_count')) {
      context.handle(
        _installCountMeta,
        installCount.isAcceptableOrUnknown(
          data['install_count']!,
          _installCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installCountMeta);
    }
    if (data.containsKey('add_time')) {
      context.handle(
        _addTimeMeta,
        addTime.isAcceptableOrUnknown(data['add_time']!, _addTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_addTimeMeta);
    }
    if (data.containsKey('plugin_public_key')) {
      context.handle(
        _pluginPublicKeyMeta,
        pluginPublicKey.isAcceptableOrUnknown(
          data['plugin_public_key']!,
          _pluginPublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pluginPublicKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstalledPluginModelCacheRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstalledPluginModelCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pluginName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_name'],
      )!,
      pluginDesc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_desc'],
      )!,
      pluginIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_icon'],
      )!,
      pluginVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_version'],
      )!,
      pluginLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_label'],
      )!,
      pluginAuthor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_author'],
      )!,
      authorUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_url'],
      )!,
      pluginConfigPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_config_prefix'],
      )!,
      pluginOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plugin_order'],
      )!,
      authLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auth_level'],
      )!,
      installed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}installed'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}state'],
      )!,
      hasPage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_page'],
      )!,
      hasUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_update'],
      )!,
      isLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local'],
      )!,
      repoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_url'],
      )!,
      installCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}install_count'],
      )!,
      addTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}add_time'],
      )!,
      pluginPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_public_key'],
      )!,
    );
  }

  @override
  $InstalledPluginModelCachesTable createAlias(String alias) {
    return $InstalledPluginModelCachesTable(attachedDatabase, alias);
  }
}

class InstalledPluginModelCacheRow extends DataClass
    implements Insertable<InstalledPluginModelCacheRow> {
  final String id;
  final String pluginName;
  final String pluginDesc;
  final String pluginIcon;
  final String pluginVersion;
  final String pluginLabel;
  final String pluginAuthor;
  final String authorUrl;
  final String pluginConfigPrefix;
  final int pluginOrder;
  final int authLevel;
  final bool installed;
  final bool state;
  final bool hasPage;
  final bool hasUpdate;
  final bool isLocal;
  final String repoUrl;
  final int installCount;
  final int addTime;
  final String pluginPublicKey;
  const InstalledPluginModelCacheRow({
    required this.id,
    required this.pluginName,
    required this.pluginDesc,
    required this.pluginIcon,
    required this.pluginVersion,
    required this.pluginLabel,
    required this.pluginAuthor,
    required this.authorUrl,
    required this.pluginConfigPrefix,
    required this.pluginOrder,
    required this.authLevel,
    required this.installed,
    required this.state,
    required this.hasPage,
    required this.hasUpdate,
    required this.isLocal,
    required this.repoUrl,
    required this.installCount,
    required this.addTime,
    required this.pluginPublicKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plugin_name'] = Variable<String>(pluginName);
    map['plugin_desc'] = Variable<String>(pluginDesc);
    map['plugin_icon'] = Variable<String>(pluginIcon);
    map['plugin_version'] = Variable<String>(pluginVersion);
    map['plugin_label'] = Variable<String>(pluginLabel);
    map['plugin_author'] = Variable<String>(pluginAuthor);
    map['author_url'] = Variable<String>(authorUrl);
    map['plugin_config_prefix'] = Variable<String>(pluginConfigPrefix);
    map['plugin_order'] = Variable<int>(pluginOrder);
    map['auth_level'] = Variable<int>(authLevel);
    map['installed'] = Variable<bool>(installed);
    map['state'] = Variable<bool>(state);
    map['has_page'] = Variable<bool>(hasPage);
    map['has_update'] = Variable<bool>(hasUpdate);
    map['is_local'] = Variable<bool>(isLocal);
    map['repo_url'] = Variable<String>(repoUrl);
    map['install_count'] = Variable<int>(installCount);
    map['add_time'] = Variable<int>(addTime);
    map['plugin_public_key'] = Variable<String>(pluginPublicKey);
    return map;
  }

  InstalledPluginModelCachesCompanion toCompanion(bool nullToAbsent) {
    return InstalledPluginModelCachesCompanion(
      id: Value(id),
      pluginName: Value(pluginName),
      pluginDesc: Value(pluginDesc),
      pluginIcon: Value(pluginIcon),
      pluginVersion: Value(pluginVersion),
      pluginLabel: Value(pluginLabel),
      pluginAuthor: Value(pluginAuthor),
      authorUrl: Value(authorUrl),
      pluginConfigPrefix: Value(pluginConfigPrefix),
      pluginOrder: Value(pluginOrder),
      authLevel: Value(authLevel),
      installed: Value(installed),
      state: Value(state),
      hasPage: Value(hasPage),
      hasUpdate: Value(hasUpdate),
      isLocal: Value(isLocal),
      repoUrl: Value(repoUrl),
      installCount: Value(installCount),
      addTime: Value(addTime),
      pluginPublicKey: Value(pluginPublicKey),
    );
  }

  factory InstalledPluginModelCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstalledPluginModelCacheRow(
      id: serializer.fromJson<String>(json['id']),
      pluginName: serializer.fromJson<String>(json['pluginName']),
      pluginDesc: serializer.fromJson<String>(json['pluginDesc']),
      pluginIcon: serializer.fromJson<String>(json['pluginIcon']),
      pluginVersion: serializer.fromJson<String>(json['pluginVersion']),
      pluginLabel: serializer.fromJson<String>(json['pluginLabel']),
      pluginAuthor: serializer.fromJson<String>(json['pluginAuthor']),
      authorUrl: serializer.fromJson<String>(json['authorUrl']),
      pluginConfigPrefix: serializer.fromJson<String>(
        json['pluginConfigPrefix'],
      ),
      pluginOrder: serializer.fromJson<int>(json['pluginOrder']),
      authLevel: serializer.fromJson<int>(json['authLevel']),
      installed: serializer.fromJson<bool>(json['installed']),
      state: serializer.fromJson<bool>(json['state']),
      hasPage: serializer.fromJson<bool>(json['hasPage']),
      hasUpdate: serializer.fromJson<bool>(json['hasUpdate']),
      isLocal: serializer.fromJson<bool>(json['isLocal']),
      repoUrl: serializer.fromJson<String>(json['repoUrl']),
      installCount: serializer.fromJson<int>(json['installCount']),
      addTime: serializer.fromJson<int>(json['addTime']),
      pluginPublicKey: serializer.fromJson<String>(json['pluginPublicKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pluginName': serializer.toJson<String>(pluginName),
      'pluginDesc': serializer.toJson<String>(pluginDesc),
      'pluginIcon': serializer.toJson<String>(pluginIcon),
      'pluginVersion': serializer.toJson<String>(pluginVersion),
      'pluginLabel': serializer.toJson<String>(pluginLabel),
      'pluginAuthor': serializer.toJson<String>(pluginAuthor),
      'authorUrl': serializer.toJson<String>(authorUrl),
      'pluginConfigPrefix': serializer.toJson<String>(pluginConfigPrefix),
      'pluginOrder': serializer.toJson<int>(pluginOrder),
      'authLevel': serializer.toJson<int>(authLevel),
      'installed': serializer.toJson<bool>(installed),
      'state': serializer.toJson<bool>(state),
      'hasPage': serializer.toJson<bool>(hasPage),
      'hasUpdate': serializer.toJson<bool>(hasUpdate),
      'isLocal': serializer.toJson<bool>(isLocal),
      'repoUrl': serializer.toJson<String>(repoUrl),
      'installCount': serializer.toJson<int>(installCount),
      'addTime': serializer.toJson<int>(addTime),
      'pluginPublicKey': serializer.toJson<String>(pluginPublicKey),
    };
  }

  InstalledPluginModelCacheRow copyWith({
    String? id,
    String? pluginName,
    String? pluginDesc,
    String? pluginIcon,
    String? pluginVersion,
    String? pluginLabel,
    String? pluginAuthor,
    String? authorUrl,
    String? pluginConfigPrefix,
    int? pluginOrder,
    int? authLevel,
    bool? installed,
    bool? state,
    bool? hasPage,
    bool? hasUpdate,
    bool? isLocal,
    String? repoUrl,
    int? installCount,
    int? addTime,
    String? pluginPublicKey,
  }) => InstalledPluginModelCacheRow(
    id: id ?? this.id,
    pluginName: pluginName ?? this.pluginName,
    pluginDesc: pluginDesc ?? this.pluginDesc,
    pluginIcon: pluginIcon ?? this.pluginIcon,
    pluginVersion: pluginVersion ?? this.pluginVersion,
    pluginLabel: pluginLabel ?? this.pluginLabel,
    pluginAuthor: pluginAuthor ?? this.pluginAuthor,
    authorUrl: authorUrl ?? this.authorUrl,
    pluginConfigPrefix: pluginConfigPrefix ?? this.pluginConfigPrefix,
    pluginOrder: pluginOrder ?? this.pluginOrder,
    authLevel: authLevel ?? this.authLevel,
    installed: installed ?? this.installed,
    state: state ?? this.state,
    hasPage: hasPage ?? this.hasPage,
    hasUpdate: hasUpdate ?? this.hasUpdate,
    isLocal: isLocal ?? this.isLocal,
    repoUrl: repoUrl ?? this.repoUrl,
    installCount: installCount ?? this.installCount,
    addTime: addTime ?? this.addTime,
    pluginPublicKey: pluginPublicKey ?? this.pluginPublicKey,
  );
  InstalledPluginModelCacheRow copyWithCompanion(
    InstalledPluginModelCachesCompanion data,
  ) {
    return InstalledPluginModelCacheRow(
      id: data.id.present ? data.id.value : this.id,
      pluginName: data.pluginName.present
          ? data.pluginName.value
          : this.pluginName,
      pluginDesc: data.pluginDesc.present
          ? data.pluginDesc.value
          : this.pluginDesc,
      pluginIcon: data.pluginIcon.present
          ? data.pluginIcon.value
          : this.pluginIcon,
      pluginVersion: data.pluginVersion.present
          ? data.pluginVersion.value
          : this.pluginVersion,
      pluginLabel: data.pluginLabel.present
          ? data.pluginLabel.value
          : this.pluginLabel,
      pluginAuthor: data.pluginAuthor.present
          ? data.pluginAuthor.value
          : this.pluginAuthor,
      authorUrl: data.authorUrl.present ? data.authorUrl.value : this.authorUrl,
      pluginConfigPrefix: data.pluginConfigPrefix.present
          ? data.pluginConfigPrefix.value
          : this.pluginConfigPrefix,
      pluginOrder: data.pluginOrder.present
          ? data.pluginOrder.value
          : this.pluginOrder,
      authLevel: data.authLevel.present ? data.authLevel.value : this.authLevel,
      installed: data.installed.present ? data.installed.value : this.installed,
      state: data.state.present ? data.state.value : this.state,
      hasPage: data.hasPage.present ? data.hasPage.value : this.hasPage,
      hasUpdate: data.hasUpdate.present ? data.hasUpdate.value : this.hasUpdate,
      isLocal: data.isLocal.present ? data.isLocal.value : this.isLocal,
      repoUrl: data.repoUrl.present ? data.repoUrl.value : this.repoUrl,
      installCount: data.installCount.present
          ? data.installCount.value
          : this.installCount,
      addTime: data.addTime.present ? data.addTime.value : this.addTime,
      pluginPublicKey: data.pluginPublicKey.present
          ? data.pluginPublicKey.value
          : this.pluginPublicKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstalledPluginModelCacheRow(')
          ..write('id: $id, ')
          ..write('pluginName: $pluginName, ')
          ..write('pluginDesc: $pluginDesc, ')
          ..write('pluginIcon: $pluginIcon, ')
          ..write('pluginVersion: $pluginVersion, ')
          ..write('pluginLabel: $pluginLabel, ')
          ..write('pluginAuthor: $pluginAuthor, ')
          ..write('authorUrl: $authorUrl, ')
          ..write('pluginConfigPrefix: $pluginConfigPrefix, ')
          ..write('pluginOrder: $pluginOrder, ')
          ..write('authLevel: $authLevel, ')
          ..write('installed: $installed, ')
          ..write('state: $state, ')
          ..write('hasPage: $hasPage, ')
          ..write('hasUpdate: $hasUpdate, ')
          ..write('isLocal: $isLocal, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('installCount: $installCount, ')
          ..write('addTime: $addTime, ')
          ..write('pluginPublicKey: $pluginPublicKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pluginName,
    pluginDesc,
    pluginIcon,
    pluginVersion,
    pluginLabel,
    pluginAuthor,
    authorUrl,
    pluginConfigPrefix,
    pluginOrder,
    authLevel,
    installed,
    state,
    hasPage,
    hasUpdate,
    isLocal,
    repoUrl,
    installCount,
    addTime,
    pluginPublicKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstalledPluginModelCacheRow &&
          other.id == this.id &&
          other.pluginName == this.pluginName &&
          other.pluginDesc == this.pluginDesc &&
          other.pluginIcon == this.pluginIcon &&
          other.pluginVersion == this.pluginVersion &&
          other.pluginLabel == this.pluginLabel &&
          other.pluginAuthor == this.pluginAuthor &&
          other.authorUrl == this.authorUrl &&
          other.pluginConfigPrefix == this.pluginConfigPrefix &&
          other.pluginOrder == this.pluginOrder &&
          other.authLevel == this.authLevel &&
          other.installed == this.installed &&
          other.state == this.state &&
          other.hasPage == this.hasPage &&
          other.hasUpdate == this.hasUpdate &&
          other.isLocal == this.isLocal &&
          other.repoUrl == this.repoUrl &&
          other.installCount == this.installCount &&
          other.addTime == this.addTime &&
          other.pluginPublicKey == this.pluginPublicKey);
}

class InstalledPluginModelCachesCompanion
    extends UpdateCompanion<InstalledPluginModelCacheRow> {
  final Value<String> id;
  final Value<String> pluginName;
  final Value<String> pluginDesc;
  final Value<String> pluginIcon;
  final Value<String> pluginVersion;
  final Value<String> pluginLabel;
  final Value<String> pluginAuthor;
  final Value<String> authorUrl;
  final Value<String> pluginConfigPrefix;
  final Value<int> pluginOrder;
  final Value<int> authLevel;
  final Value<bool> installed;
  final Value<bool> state;
  final Value<bool> hasPage;
  final Value<bool> hasUpdate;
  final Value<bool> isLocal;
  final Value<String> repoUrl;
  final Value<int> installCount;
  final Value<int> addTime;
  final Value<String> pluginPublicKey;
  final Value<int> rowid;
  const InstalledPluginModelCachesCompanion({
    this.id = const Value.absent(),
    this.pluginName = const Value.absent(),
    this.pluginDesc = const Value.absent(),
    this.pluginIcon = const Value.absent(),
    this.pluginVersion = const Value.absent(),
    this.pluginLabel = const Value.absent(),
    this.pluginAuthor = const Value.absent(),
    this.authorUrl = const Value.absent(),
    this.pluginConfigPrefix = const Value.absent(),
    this.pluginOrder = const Value.absent(),
    this.authLevel = const Value.absent(),
    this.installed = const Value.absent(),
    this.state = const Value.absent(),
    this.hasPage = const Value.absent(),
    this.hasUpdate = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.repoUrl = const Value.absent(),
    this.installCount = const Value.absent(),
    this.addTime = const Value.absent(),
    this.pluginPublicKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstalledPluginModelCachesCompanion.insert({
    required String id,
    required String pluginName,
    required String pluginDesc,
    required String pluginIcon,
    required String pluginVersion,
    required String pluginLabel,
    required String pluginAuthor,
    required String authorUrl,
    required String pluginConfigPrefix,
    required int pluginOrder,
    required int authLevel,
    required bool installed,
    required bool state,
    required bool hasPage,
    required bool hasUpdate,
    required bool isLocal,
    required String repoUrl,
    required int installCount,
    required int addTime,
    required String pluginPublicKey,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pluginName = Value(pluginName),
       pluginDesc = Value(pluginDesc),
       pluginIcon = Value(pluginIcon),
       pluginVersion = Value(pluginVersion),
       pluginLabel = Value(pluginLabel),
       pluginAuthor = Value(pluginAuthor),
       authorUrl = Value(authorUrl),
       pluginConfigPrefix = Value(pluginConfigPrefix),
       pluginOrder = Value(pluginOrder),
       authLevel = Value(authLevel),
       installed = Value(installed),
       state = Value(state),
       hasPage = Value(hasPage),
       hasUpdate = Value(hasUpdate),
       isLocal = Value(isLocal),
       repoUrl = Value(repoUrl),
       installCount = Value(installCount),
       addTime = Value(addTime),
       pluginPublicKey = Value(pluginPublicKey);
  static Insertable<InstalledPluginModelCacheRow> custom({
    Expression<String>? id,
    Expression<String>? pluginName,
    Expression<String>? pluginDesc,
    Expression<String>? pluginIcon,
    Expression<String>? pluginVersion,
    Expression<String>? pluginLabel,
    Expression<String>? pluginAuthor,
    Expression<String>? authorUrl,
    Expression<String>? pluginConfigPrefix,
    Expression<int>? pluginOrder,
    Expression<int>? authLevel,
    Expression<bool>? installed,
    Expression<bool>? state,
    Expression<bool>? hasPage,
    Expression<bool>? hasUpdate,
    Expression<bool>? isLocal,
    Expression<String>? repoUrl,
    Expression<int>? installCount,
    Expression<int>? addTime,
    Expression<String>? pluginPublicKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pluginName != null) 'plugin_name': pluginName,
      if (pluginDesc != null) 'plugin_desc': pluginDesc,
      if (pluginIcon != null) 'plugin_icon': pluginIcon,
      if (pluginVersion != null) 'plugin_version': pluginVersion,
      if (pluginLabel != null) 'plugin_label': pluginLabel,
      if (pluginAuthor != null) 'plugin_author': pluginAuthor,
      if (authorUrl != null) 'author_url': authorUrl,
      if (pluginConfigPrefix != null)
        'plugin_config_prefix': pluginConfigPrefix,
      if (pluginOrder != null) 'plugin_order': pluginOrder,
      if (authLevel != null) 'auth_level': authLevel,
      if (installed != null) 'installed': installed,
      if (state != null) 'state': state,
      if (hasPage != null) 'has_page': hasPage,
      if (hasUpdate != null) 'has_update': hasUpdate,
      if (isLocal != null) 'is_local': isLocal,
      if (repoUrl != null) 'repo_url': repoUrl,
      if (installCount != null) 'install_count': installCount,
      if (addTime != null) 'add_time': addTime,
      if (pluginPublicKey != null) 'plugin_public_key': pluginPublicKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstalledPluginModelCachesCompanion copyWith({
    Value<String>? id,
    Value<String>? pluginName,
    Value<String>? pluginDesc,
    Value<String>? pluginIcon,
    Value<String>? pluginVersion,
    Value<String>? pluginLabel,
    Value<String>? pluginAuthor,
    Value<String>? authorUrl,
    Value<String>? pluginConfigPrefix,
    Value<int>? pluginOrder,
    Value<int>? authLevel,
    Value<bool>? installed,
    Value<bool>? state,
    Value<bool>? hasPage,
    Value<bool>? hasUpdate,
    Value<bool>? isLocal,
    Value<String>? repoUrl,
    Value<int>? installCount,
    Value<int>? addTime,
    Value<String>? pluginPublicKey,
    Value<int>? rowid,
  }) {
    return InstalledPluginModelCachesCompanion(
      id: id ?? this.id,
      pluginName: pluginName ?? this.pluginName,
      pluginDesc: pluginDesc ?? this.pluginDesc,
      pluginIcon: pluginIcon ?? this.pluginIcon,
      pluginVersion: pluginVersion ?? this.pluginVersion,
      pluginLabel: pluginLabel ?? this.pluginLabel,
      pluginAuthor: pluginAuthor ?? this.pluginAuthor,
      authorUrl: authorUrl ?? this.authorUrl,
      pluginConfigPrefix: pluginConfigPrefix ?? this.pluginConfigPrefix,
      pluginOrder: pluginOrder ?? this.pluginOrder,
      authLevel: authLevel ?? this.authLevel,
      installed: installed ?? this.installed,
      state: state ?? this.state,
      hasPage: hasPage ?? this.hasPage,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      isLocal: isLocal ?? this.isLocal,
      repoUrl: repoUrl ?? this.repoUrl,
      installCount: installCount ?? this.installCount,
      addTime: addTime ?? this.addTime,
      pluginPublicKey: pluginPublicKey ?? this.pluginPublicKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pluginName.present) {
      map['plugin_name'] = Variable<String>(pluginName.value);
    }
    if (pluginDesc.present) {
      map['plugin_desc'] = Variable<String>(pluginDesc.value);
    }
    if (pluginIcon.present) {
      map['plugin_icon'] = Variable<String>(pluginIcon.value);
    }
    if (pluginVersion.present) {
      map['plugin_version'] = Variable<String>(pluginVersion.value);
    }
    if (pluginLabel.present) {
      map['plugin_label'] = Variable<String>(pluginLabel.value);
    }
    if (pluginAuthor.present) {
      map['plugin_author'] = Variable<String>(pluginAuthor.value);
    }
    if (authorUrl.present) {
      map['author_url'] = Variable<String>(authorUrl.value);
    }
    if (pluginConfigPrefix.present) {
      map['plugin_config_prefix'] = Variable<String>(pluginConfigPrefix.value);
    }
    if (pluginOrder.present) {
      map['plugin_order'] = Variable<int>(pluginOrder.value);
    }
    if (authLevel.present) {
      map['auth_level'] = Variable<int>(authLevel.value);
    }
    if (installed.present) {
      map['installed'] = Variable<bool>(installed.value);
    }
    if (state.present) {
      map['state'] = Variable<bool>(state.value);
    }
    if (hasPage.present) {
      map['has_page'] = Variable<bool>(hasPage.value);
    }
    if (hasUpdate.present) {
      map['has_update'] = Variable<bool>(hasUpdate.value);
    }
    if (isLocal.present) {
      map['is_local'] = Variable<bool>(isLocal.value);
    }
    if (repoUrl.present) {
      map['repo_url'] = Variable<String>(repoUrl.value);
    }
    if (installCount.present) {
      map['install_count'] = Variable<int>(installCount.value);
    }
    if (addTime.present) {
      map['add_time'] = Variable<int>(addTime.value);
    }
    if (pluginPublicKey.present) {
      map['plugin_public_key'] = Variable<String>(pluginPublicKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstalledPluginModelCachesCompanion(')
          ..write('id: $id, ')
          ..write('pluginName: $pluginName, ')
          ..write('pluginDesc: $pluginDesc, ')
          ..write('pluginIcon: $pluginIcon, ')
          ..write('pluginVersion: $pluginVersion, ')
          ..write('pluginLabel: $pluginLabel, ')
          ..write('pluginAuthor: $pluginAuthor, ')
          ..write('authorUrl: $authorUrl, ')
          ..write('pluginConfigPrefix: $pluginConfigPrefix, ')
          ..write('pluginOrder: $pluginOrder, ')
          ..write('authLevel: $authLevel, ')
          ..write('installed: $installed, ')
          ..write('state: $state, ')
          ..write('hasPage: $hasPage, ')
          ..write('hasUpdate: $hasUpdate, ')
          ..write('isLocal: $isLocal, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('installCount: $installCount, ')
          ..write('addTime: $addTime, ')
          ..write('pluginPublicKey: $pluginPublicKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PluginPaletteEntriesTable extends PluginPaletteEntries
    with TableInfo<$PluginPaletteEntriesTable, PluginPaletteEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PluginPaletteEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [url, colorValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plugin_palette_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PluginPaletteEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url};
  @override
  PluginPaletteEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PluginPaletteEntryRow(
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
    );
  }

  @override
  $PluginPaletteEntriesTable createAlias(String alias) {
    return $PluginPaletteEntriesTable(attachedDatabase, alias);
  }
}

class PluginPaletteEntryRow extends DataClass
    implements Insertable<PluginPaletteEntryRow> {
  final String url;
  final int colorValue;
  const PluginPaletteEntryRow({required this.url, required this.colorValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['color_value'] = Variable<int>(colorValue);
    return map;
  }

  PluginPaletteEntriesCompanion toCompanion(bool nullToAbsent) {
    return PluginPaletteEntriesCompanion(
      url: Value(url),
      colorValue: Value(colorValue),
    );
  }

  factory PluginPaletteEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PluginPaletteEntryRow(
      url: serializer.fromJson<String>(json['url']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'colorValue': serializer.toJson<int>(colorValue),
    };
  }

  PluginPaletteEntryRow copyWith({String? url, int? colorValue}) =>
      PluginPaletteEntryRow(
        url: url ?? this.url,
        colorValue: colorValue ?? this.colorValue,
      );
  PluginPaletteEntryRow copyWithCompanion(PluginPaletteEntriesCompanion data) {
    return PluginPaletteEntryRow(
      url: data.url.present ? data.url.value : this.url,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PluginPaletteEntryRow(')
          ..write('url: $url, ')
          ..write('colorValue: $colorValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(url, colorValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PluginPaletteEntryRow &&
          other.url == this.url &&
          other.colorValue == this.colorValue);
}

class PluginPaletteEntriesCompanion
    extends UpdateCompanion<PluginPaletteEntryRow> {
  final Value<String> url;
  final Value<int> colorValue;
  final Value<int> rowid;
  const PluginPaletteEntriesCompanion({
    this.url = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PluginPaletteEntriesCompanion.insert({
    required String url,
    required int colorValue,
    this.rowid = const Value.absent(),
  }) : url = Value(url),
       colorValue = Value(colorValue);
  static Insertable<PluginPaletteEntryRow> custom({
    Expression<String>? url,
    Expression<int>? colorValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (colorValue != null) 'color_value': colorValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PluginPaletteEntriesCompanion copyWith({
    Value<String>? url,
    Value<int>? colorValue,
    Value<int>? rowid,
  }) {
    return PluginPaletteEntriesCompanion(
      url: url ?? this.url,
      colorValue: colorValue ?? this.colorValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PluginPaletteEntriesCompanion(')
          ..write('url: $url, ')
          ..write('colorValue: $colorValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SiteIconCachesTable extends SiteIconCaches
    with TableInfo<$SiteIconCachesTable, SiteIconCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SiteIconCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconBase64Meta = const VerificationMeta(
    'iconBase64',
  );
  @override
  late final GeneratedColumn<String> iconBase64 = GeneratedColumn<String>(
    'icon_base64',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [url, iconBase64];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'site_icon_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<SiteIconCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('icon_base64')) {
      context.handle(
        _iconBase64Meta,
        iconBase64.isAcceptableOrUnknown(data['icon_base64']!, _iconBase64Meta),
      );
    } else if (isInserting) {
      context.missing(_iconBase64Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url};
  @override
  SiteIconCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SiteIconCacheRow(
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      iconBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_base64'],
      )!,
    );
  }

  @override
  $SiteIconCachesTable createAlias(String alias) {
    return $SiteIconCachesTable(attachedDatabase, alias);
  }
}

class SiteIconCacheRow extends DataClass
    implements Insertable<SiteIconCacheRow> {
  final String url;
  final String iconBase64;
  const SiteIconCacheRow({required this.url, required this.iconBase64});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['icon_base64'] = Variable<String>(iconBase64);
    return map;
  }

  SiteIconCachesCompanion toCompanion(bool nullToAbsent) {
    return SiteIconCachesCompanion(
      url: Value(url),
      iconBase64: Value(iconBase64),
    );
  }

  factory SiteIconCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SiteIconCacheRow(
      url: serializer.fromJson<String>(json['url']),
      iconBase64: serializer.fromJson<String>(json['iconBase64']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'iconBase64': serializer.toJson<String>(iconBase64),
    };
  }

  SiteIconCacheRow copyWith({String? url, String? iconBase64}) =>
      SiteIconCacheRow(
        url: url ?? this.url,
        iconBase64: iconBase64 ?? this.iconBase64,
      );
  SiteIconCacheRow copyWithCompanion(SiteIconCachesCompanion data) {
    return SiteIconCacheRow(
      url: data.url.present ? data.url.value : this.url,
      iconBase64: data.iconBase64.present
          ? data.iconBase64.value
          : this.iconBase64,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SiteIconCacheRow(')
          ..write('url: $url, ')
          ..write('iconBase64: $iconBase64')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(url, iconBase64);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SiteIconCacheRow &&
          other.url == this.url &&
          other.iconBase64 == this.iconBase64);
}

class SiteIconCachesCompanion extends UpdateCompanion<SiteIconCacheRow> {
  final Value<String> url;
  final Value<String> iconBase64;
  final Value<int> rowid;
  const SiteIconCachesCompanion({
    this.url = const Value.absent(),
    this.iconBase64 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SiteIconCachesCompanion.insert({
    required String url,
    required String iconBase64,
    this.rowid = const Value.absent(),
  }) : url = Value(url),
       iconBase64 = Value(iconBase64);
  static Insertable<SiteIconCacheRow> custom({
    Expression<String>? url,
    Expression<String>? iconBase64,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (iconBase64 != null) 'icon_base64': iconBase64,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SiteIconCachesCompanion copyWith({
    Value<String>? url,
    Value<String>? iconBase64,
    Value<int>? rowid,
  }) {
    return SiteIconCachesCompanion(
      url: url ?? this.url,
      iconBase64: iconBase64 ?? this.iconBase64,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (iconBase64.present) {
      map['icon_base64'] = Variable<String>(iconBase64.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SiteIconCachesCompanion(')
          ..write('url: $url, ')
          ..write('iconBase64: $iconBase64, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SiteModelCachesTable extends SiteModelCaches
    with TableInfo<$SiteModelCachesTable, SiteModelCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SiteModelCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priMeta = const VerificationMeta('pri');
  @override
  late final GeneratedColumn<int> pri = GeneratedColumn<int>(
    'pri',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rssMeta = const VerificationMeta('rss');
  @override
  late final GeneratedColumn<String> rss = GeneratedColumn<String>(
    'rss',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cookieMeta = const VerificationMeta('cookie');
  @override
  late final GeneratedColumn<String> cookie = GeneratedColumn<String>(
    'cookie',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uaMeta = const VerificationMeta('ua');
  @override
  late final GeneratedColumn<String> ua = GeneratedColumn<String>(
    'ua',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apikeyMeta = const VerificationMeta('apikey');
  @override
  late final GeneratedColumn<String> apikey = GeneratedColumn<String>(
    'apikey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proxyMeta = const VerificationMeta('proxy');
  @override
  late final GeneratedColumn<int> proxy = GeneratedColumn<int>(
    'proxy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filterMeta = const VerificationMeta('filter');
  @override
  late final GeneratedColumn<String> filter = GeneratedColumn<String>(
    'filter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _renderMeta = const VerificationMeta('render');
  @override
  late final GeneratedColumn<int> render = GeneratedColumn<int>(
    'render',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicMeta = const VerificationMeta('public');
  @override
  late final GeneratedColumn<int> public = GeneratedColumn<int>(
    'public',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeoutMeta = const VerificationMeta(
    'timeout',
  );
  @override
  late final GeneratedColumn<int> timeout = GeneratedColumn<int>(
    'timeout',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitIntervalMeta = const VerificationMeta(
    'limitInterval',
  );
  @override
  late final GeneratedColumn<int> limitInterval = GeneratedColumn<int>(
    'limit_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitCountMeta = const VerificationMeta(
    'limitCount',
  );
  @override
  late final GeneratedColumn<int> limitCount = GeneratedColumn<int>(
    'limit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitSecondsMeta = const VerificationMeta(
    'limitSeconds',
  );
  @override
  late final GeneratedColumn<int> limitSeconds = GeneratedColumn<int>(
    'limit_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _downloaderMeta = const VerificationMeta(
    'downloader',
  );
  @override
  late final GeneratedColumn<String> downloader = GeneratedColumn<String>(
    'downloader',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    domain,
    url,
    pri,
    rss,
    cookie,
    ua,
    apikey,
    token,
    proxy,
    filter,
    render,
    public,
    note,
    timeout,
    limitInterval,
    limitCount,
    limitSeconds,
    isActive,
    downloader,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'site_model_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<SiteModelCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('pri')) {
      context.handle(
        _priMeta,
        pri.isAcceptableOrUnknown(data['pri']!, _priMeta),
      );
    } else if (isInserting) {
      context.missing(_priMeta);
    }
    if (data.containsKey('rss')) {
      context.handle(
        _rssMeta,
        rss.isAcceptableOrUnknown(data['rss']!, _rssMeta),
      );
    } else if (isInserting) {
      context.missing(_rssMeta);
    }
    if (data.containsKey('cookie')) {
      context.handle(
        _cookieMeta,
        cookie.isAcceptableOrUnknown(data['cookie']!, _cookieMeta),
      );
    } else if (isInserting) {
      context.missing(_cookieMeta);
    }
    if (data.containsKey('ua')) {
      context.handle(_uaMeta, ua.isAcceptableOrUnknown(data['ua']!, _uaMeta));
    } else if (isInserting) {
      context.missing(_uaMeta);
    }
    if (data.containsKey('apikey')) {
      context.handle(
        _apikeyMeta,
        apikey.isAcceptableOrUnknown(data['apikey']!, _apikeyMeta),
      );
    } else if (isInserting) {
      context.missing(_apikeyMeta);
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('proxy')) {
      context.handle(
        _proxyMeta,
        proxy.isAcceptableOrUnknown(data['proxy']!, _proxyMeta),
      );
    } else if (isInserting) {
      context.missing(_proxyMeta);
    }
    if (data.containsKey('filter')) {
      context.handle(
        _filterMeta,
        filter.isAcceptableOrUnknown(data['filter']!, _filterMeta),
      );
    } else if (isInserting) {
      context.missing(_filterMeta);
    }
    if (data.containsKey('render')) {
      context.handle(
        _renderMeta,
        render.isAcceptableOrUnknown(data['render']!, _renderMeta),
      );
    } else if (isInserting) {
      context.missing(_renderMeta);
    }
    if (data.containsKey('public')) {
      context.handle(
        _publicMeta,
        public.isAcceptableOrUnknown(data['public']!, _publicMeta),
      );
    } else if (isInserting) {
      context.missing(_publicMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('timeout')) {
      context.handle(
        _timeoutMeta,
        timeout.isAcceptableOrUnknown(data['timeout']!, _timeoutMeta),
      );
    } else if (isInserting) {
      context.missing(_timeoutMeta);
    }
    if (data.containsKey('limit_interval')) {
      context.handle(
        _limitIntervalMeta,
        limitInterval.isAcceptableOrUnknown(
          data['limit_interval']!,
          _limitIntervalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitIntervalMeta);
    }
    if (data.containsKey('limit_count')) {
      context.handle(
        _limitCountMeta,
        limitCount.isAcceptableOrUnknown(data['limit_count']!, _limitCountMeta),
      );
    } else if (isInserting) {
      context.missing(_limitCountMeta);
    }
    if (data.containsKey('limit_seconds')) {
      context.handle(
        _limitSecondsMeta,
        limitSeconds.isAcceptableOrUnknown(
          data['limit_seconds']!,
          _limitSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitSecondsMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('downloader')) {
      context.handle(
        _downloaderMeta,
        downloader.isAcceptableOrUnknown(data['downloader']!, _downloaderMeta),
      );
    } else if (isInserting) {
      context.missing(_downloaderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SiteModelCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SiteModelCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      pri: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pri'],
      )!,
      rss: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rss'],
      )!,
      cookie: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cookie'],
      )!,
      ua: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ua'],
      )!,
      apikey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apikey'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      proxy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}proxy'],
      )!,
      filter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter'],
      )!,
      render: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}render'],
      )!,
      public: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}public'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      timeout: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timeout'],
      )!,
      limitInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_interval'],
      )!,
      limitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_count'],
      )!,
      limitSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_seconds'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      downloader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}downloader'],
      )!,
    );
  }

  @override
  $SiteModelCachesTable createAlias(String alias) {
    return $SiteModelCachesTable(attachedDatabase, alias);
  }
}

class SiteModelCacheRow extends DataClass
    implements Insertable<SiteModelCacheRow> {
  final int id;
  final String name;
  final String domain;
  final String url;
  final int pri;
  final String rss;
  final String cookie;
  final String ua;
  final String apikey;
  final String token;
  final int proxy;
  final String filter;
  final int render;
  final int public;
  final String note;
  final int timeout;
  final int limitInterval;
  final int limitCount;
  final int limitSeconds;
  final bool isActive;
  final String downloader;
  const SiteModelCacheRow({
    required this.id,
    required this.name,
    required this.domain,
    required this.url,
    required this.pri,
    required this.rss,
    required this.cookie,
    required this.ua,
    required this.apikey,
    required this.token,
    required this.proxy,
    required this.filter,
    required this.render,
    required this.public,
    required this.note,
    required this.timeout,
    required this.limitInterval,
    required this.limitCount,
    required this.limitSeconds,
    required this.isActive,
    required this.downloader,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['domain'] = Variable<String>(domain);
    map['url'] = Variable<String>(url);
    map['pri'] = Variable<int>(pri);
    map['rss'] = Variable<String>(rss);
    map['cookie'] = Variable<String>(cookie);
    map['ua'] = Variable<String>(ua);
    map['apikey'] = Variable<String>(apikey);
    map['token'] = Variable<String>(token);
    map['proxy'] = Variable<int>(proxy);
    map['filter'] = Variable<String>(filter);
    map['render'] = Variable<int>(render);
    map['public'] = Variable<int>(public);
    map['note'] = Variable<String>(note);
    map['timeout'] = Variable<int>(timeout);
    map['limit_interval'] = Variable<int>(limitInterval);
    map['limit_count'] = Variable<int>(limitCount);
    map['limit_seconds'] = Variable<int>(limitSeconds);
    map['is_active'] = Variable<bool>(isActive);
    map['downloader'] = Variable<String>(downloader);
    return map;
  }

  SiteModelCachesCompanion toCompanion(bool nullToAbsent) {
    return SiteModelCachesCompanion(
      id: Value(id),
      name: Value(name),
      domain: Value(domain),
      url: Value(url),
      pri: Value(pri),
      rss: Value(rss),
      cookie: Value(cookie),
      ua: Value(ua),
      apikey: Value(apikey),
      token: Value(token),
      proxy: Value(proxy),
      filter: Value(filter),
      render: Value(render),
      public: Value(public),
      note: Value(note),
      timeout: Value(timeout),
      limitInterval: Value(limitInterval),
      limitCount: Value(limitCount),
      limitSeconds: Value(limitSeconds),
      isActive: Value(isActive),
      downloader: Value(downloader),
    );
  }

  factory SiteModelCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SiteModelCacheRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      domain: serializer.fromJson<String>(json['domain']),
      url: serializer.fromJson<String>(json['url']),
      pri: serializer.fromJson<int>(json['pri']),
      rss: serializer.fromJson<String>(json['rss']),
      cookie: serializer.fromJson<String>(json['cookie']),
      ua: serializer.fromJson<String>(json['ua']),
      apikey: serializer.fromJson<String>(json['apikey']),
      token: serializer.fromJson<String>(json['token']),
      proxy: serializer.fromJson<int>(json['proxy']),
      filter: serializer.fromJson<String>(json['filter']),
      render: serializer.fromJson<int>(json['render']),
      public: serializer.fromJson<int>(json['public']),
      note: serializer.fromJson<String>(json['note']),
      timeout: serializer.fromJson<int>(json['timeout']),
      limitInterval: serializer.fromJson<int>(json['limitInterval']),
      limitCount: serializer.fromJson<int>(json['limitCount']),
      limitSeconds: serializer.fromJson<int>(json['limitSeconds']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      downloader: serializer.fromJson<String>(json['downloader']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'domain': serializer.toJson<String>(domain),
      'url': serializer.toJson<String>(url),
      'pri': serializer.toJson<int>(pri),
      'rss': serializer.toJson<String>(rss),
      'cookie': serializer.toJson<String>(cookie),
      'ua': serializer.toJson<String>(ua),
      'apikey': serializer.toJson<String>(apikey),
      'token': serializer.toJson<String>(token),
      'proxy': serializer.toJson<int>(proxy),
      'filter': serializer.toJson<String>(filter),
      'render': serializer.toJson<int>(render),
      'public': serializer.toJson<int>(public),
      'note': serializer.toJson<String>(note),
      'timeout': serializer.toJson<int>(timeout),
      'limitInterval': serializer.toJson<int>(limitInterval),
      'limitCount': serializer.toJson<int>(limitCount),
      'limitSeconds': serializer.toJson<int>(limitSeconds),
      'isActive': serializer.toJson<bool>(isActive),
      'downloader': serializer.toJson<String>(downloader),
    };
  }

  SiteModelCacheRow copyWith({
    int? id,
    String? name,
    String? domain,
    String? url,
    int? pri,
    String? rss,
    String? cookie,
    String? ua,
    String? apikey,
    String? token,
    int? proxy,
    String? filter,
    int? render,
    int? public,
    String? note,
    int? timeout,
    int? limitInterval,
    int? limitCount,
    int? limitSeconds,
    bool? isActive,
    String? downloader,
  }) => SiteModelCacheRow(
    id: id ?? this.id,
    name: name ?? this.name,
    domain: domain ?? this.domain,
    url: url ?? this.url,
    pri: pri ?? this.pri,
    rss: rss ?? this.rss,
    cookie: cookie ?? this.cookie,
    ua: ua ?? this.ua,
    apikey: apikey ?? this.apikey,
    token: token ?? this.token,
    proxy: proxy ?? this.proxy,
    filter: filter ?? this.filter,
    render: render ?? this.render,
    public: public ?? this.public,
    note: note ?? this.note,
    timeout: timeout ?? this.timeout,
    limitInterval: limitInterval ?? this.limitInterval,
    limitCount: limitCount ?? this.limitCount,
    limitSeconds: limitSeconds ?? this.limitSeconds,
    isActive: isActive ?? this.isActive,
    downloader: downloader ?? this.downloader,
  );
  SiteModelCacheRow copyWithCompanion(SiteModelCachesCompanion data) {
    return SiteModelCacheRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      domain: data.domain.present ? data.domain.value : this.domain,
      url: data.url.present ? data.url.value : this.url,
      pri: data.pri.present ? data.pri.value : this.pri,
      rss: data.rss.present ? data.rss.value : this.rss,
      cookie: data.cookie.present ? data.cookie.value : this.cookie,
      ua: data.ua.present ? data.ua.value : this.ua,
      apikey: data.apikey.present ? data.apikey.value : this.apikey,
      token: data.token.present ? data.token.value : this.token,
      proxy: data.proxy.present ? data.proxy.value : this.proxy,
      filter: data.filter.present ? data.filter.value : this.filter,
      render: data.render.present ? data.render.value : this.render,
      public: data.public.present ? data.public.value : this.public,
      note: data.note.present ? data.note.value : this.note,
      timeout: data.timeout.present ? data.timeout.value : this.timeout,
      limitInterval: data.limitInterval.present
          ? data.limitInterval.value
          : this.limitInterval,
      limitCount: data.limitCount.present
          ? data.limitCount.value
          : this.limitCount,
      limitSeconds: data.limitSeconds.present
          ? data.limitSeconds.value
          : this.limitSeconds,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      downloader: data.downloader.present
          ? data.downloader.value
          : this.downloader,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SiteModelCacheRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('domain: $domain, ')
          ..write('url: $url, ')
          ..write('pri: $pri, ')
          ..write('rss: $rss, ')
          ..write('cookie: $cookie, ')
          ..write('ua: $ua, ')
          ..write('apikey: $apikey, ')
          ..write('token: $token, ')
          ..write('proxy: $proxy, ')
          ..write('filter: $filter, ')
          ..write('render: $render, ')
          ..write('public: $public, ')
          ..write('note: $note, ')
          ..write('timeout: $timeout, ')
          ..write('limitInterval: $limitInterval, ')
          ..write('limitCount: $limitCount, ')
          ..write('limitSeconds: $limitSeconds, ')
          ..write('isActive: $isActive, ')
          ..write('downloader: $downloader')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    domain,
    url,
    pri,
    rss,
    cookie,
    ua,
    apikey,
    token,
    proxy,
    filter,
    render,
    public,
    note,
    timeout,
    limitInterval,
    limitCount,
    limitSeconds,
    isActive,
    downloader,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SiteModelCacheRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.domain == this.domain &&
          other.url == this.url &&
          other.pri == this.pri &&
          other.rss == this.rss &&
          other.cookie == this.cookie &&
          other.ua == this.ua &&
          other.apikey == this.apikey &&
          other.token == this.token &&
          other.proxy == this.proxy &&
          other.filter == this.filter &&
          other.render == this.render &&
          other.public == this.public &&
          other.note == this.note &&
          other.timeout == this.timeout &&
          other.limitInterval == this.limitInterval &&
          other.limitCount == this.limitCount &&
          other.limitSeconds == this.limitSeconds &&
          other.isActive == this.isActive &&
          other.downloader == this.downloader);
}

class SiteModelCachesCompanion extends UpdateCompanion<SiteModelCacheRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> domain;
  final Value<String> url;
  final Value<int> pri;
  final Value<String> rss;
  final Value<String> cookie;
  final Value<String> ua;
  final Value<String> apikey;
  final Value<String> token;
  final Value<int> proxy;
  final Value<String> filter;
  final Value<int> render;
  final Value<int> public;
  final Value<String> note;
  final Value<int> timeout;
  final Value<int> limitInterval;
  final Value<int> limitCount;
  final Value<int> limitSeconds;
  final Value<bool> isActive;
  final Value<String> downloader;
  const SiteModelCachesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.domain = const Value.absent(),
    this.url = const Value.absent(),
    this.pri = const Value.absent(),
    this.rss = const Value.absent(),
    this.cookie = const Value.absent(),
    this.ua = const Value.absent(),
    this.apikey = const Value.absent(),
    this.token = const Value.absent(),
    this.proxy = const Value.absent(),
    this.filter = const Value.absent(),
    this.render = const Value.absent(),
    this.public = const Value.absent(),
    this.note = const Value.absent(),
    this.timeout = const Value.absent(),
    this.limitInterval = const Value.absent(),
    this.limitCount = const Value.absent(),
    this.limitSeconds = const Value.absent(),
    this.isActive = const Value.absent(),
    this.downloader = const Value.absent(),
  });
  SiteModelCachesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String domain,
    required String url,
    required int pri,
    required String rss,
    required String cookie,
    required String ua,
    required String apikey,
    required String token,
    required int proxy,
    required String filter,
    required int render,
    required int public,
    required String note,
    required int timeout,
    required int limitInterval,
    required int limitCount,
    required int limitSeconds,
    required bool isActive,
    required String downloader,
  }) : name = Value(name),
       domain = Value(domain),
       url = Value(url),
       pri = Value(pri),
       rss = Value(rss),
       cookie = Value(cookie),
       ua = Value(ua),
       apikey = Value(apikey),
       token = Value(token),
       proxy = Value(proxy),
       filter = Value(filter),
       render = Value(render),
       public = Value(public),
       note = Value(note),
       timeout = Value(timeout),
       limitInterval = Value(limitInterval),
       limitCount = Value(limitCount),
       limitSeconds = Value(limitSeconds),
       isActive = Value(isActive),
       downloader = Value(downloader);
  static Insertable<SiteModelCacheRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? domain,
    Expression<String>? url,
    Expression<int>? pri,
    Expression<String>? rss,
    Expression<String>? cookie,
    Expression<String>? ua,
    Expression<String>? apikey,
    Expression<String>? token,
    Expression<int>? proxy,
    Expression<String>? filter,
    Expression<int>? render,
    Expression<int>? public,
    Expression<String>? note,
    Expression<int>? timeout,
    Expression<int>? limitInterval,
    Expression<int>? limitCount,
    Expression<int>? limitSeconds,
    Expression<bool>? isActive,
    Expression<String>? downloader,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (domain != null) 'domain': domain,
      if (url != null) 'url': url,
      if (pri != null) 'pri': pri,
      if (rss != null) 'rss': rss,
      if (cookie != null) 'cookie': cookie,
      if (ua != null) 'ua': ua,
      if (apikey != null) 'apikey': apikey,
      if (token != null) 'token': token,
      if (proxy != null) 'proxy': proxy,
      if (filter != null) 'filter': filter,
      if (render != null) 'render': render,
      if (public != null) 'public': public,
      if (note != null) 'note': note,
      if (timeout != null) 'timeout': timeout,
      if (limitInterval != null) 'limit_interval': limitInterval,
      if (limitCount != null) 'limit_count': limitCount,
      if (limitSeconds != null) 'limit_seconds': limitSeconds,
      if (isActive != null) 'is_active': isActive,
      if (downloader != null) 'downloader': downloader,
    });
  }

  SiteModelCachesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? domain,
    Value<String>? url,
    Value<int>? pri,
    Value<String>? rss,
    Value<String>? cookie,
    Value<String>? ua,
    Value<String>? apikey,
    Value<String>? token,
    Value<int>? proxy,
    Value<String>? filter,
    Value<int>? render,
    Value<int>? public,
    Value<String>? note,
    Value<int>? timeout,
    Value<int>? limitInterval,
    Value<int>? limitCount,
    Value<int>? limitSeconds,
    Value<bool>? isActive,
    Value<String>? downloader,
  }) {
    return SiteModelCachesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      url: url ?? this.url,
      pri: pri ?? this.pri,
      rss: rss ?? this.rss,
      cookie: cookie ?? this.cookie,
      ua: ua ?? this.ua,
      apikey: apikey ?? this.apikey,
      token: token ?? this.token,
      proxy: proxy ?? this.proxy,
      filter: filter ?? this.filter,
      render: render ?? this.render,
      public: public ?? this.public,
      note: note ?? this.note,
      timeout: timeout ?? this.timeout,
      limitInterval: limitInterval ?? this.limitInterval,
      limitCount: limitCount ?? this.limitCount,
      limitSeconds: limitSeconds ?? this.limitSeconds,
      isActive: isActive ?? this.isActive,
      downloader: downloader ?? this.downloader,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (pri.present) {
      map['pri'] = Variable<int>(pri.value);
    }
    if (rss.present) {
      map['rss'] = Variable<String>(rss.value);
    }
    if (cookie.present) {
      map['cookie'] = Variable<String>(cookie.value);
    }
    if (ua.present) {
      map['ua'] = Variable<String>(ua.value);
    }
    if (apikey.present) {
      map['apikey'] = Variable<String>(apikey.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (proxy.present) {
      map['proxy'] = Variable<int>(proxy.value);
    }
    if (filter.present) {
      map['filter'] = Variable<String>(filter.value);
    }
    if (render.present) {
      map['render'] = Variable<int>(render.value);
    }
    if (public.present) {
      map['public'] = Variable<int>(public.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (timeout.present) {
      map['timeout'] = Variable<int>(timeout.value);
    }
    if (limitInterval.present) {
      map['limit_interval'] = Variable<int>(limitInterval.value);
    }
    if (limitCount.present) {
      map['limit_count'] = Variable<int>(limitCount.value);
    }
    if (limitSeconds.present) {
      map['limit_seconds'] = Variable<int>(limitSeconds.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (downloader.present) {
      map['downloader'] = Variable<String>(downloader.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SiteModelCachesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('domain: $domain, ')
          ..write('url: $url, ')
          ..write('pri: $pri, ')
          ..write('rss: $rss, ')
          ..write('cookie: $cookie, ')
          ..write('ua: $ua, ')
          ..write('apikey: $apikey, ')
          ..write('token: $token, ')
          ..write('proxy: $proxy, ')
          ..write('filter: $filter, ')
          ..write('render: $render, ')
          ..write('public: $public, ')
          ..write('note: $note, ')
          ..write('timeout: $timeout, ')
          ..write('limitInterval: $limitInterval, ')
          ..write('limitCount: $limitCount, ')
          ..write('limitSeconds: $limitSeconds, ')
          ..write('isActive: $isActive, ')
          ..write('downloader: $downloader')
          ..write(')'))
        .toString();
  }
}

class $SiteUserDataCachesTable extends SiteUserDataCaches
    with TableInfo<$SiteUserDataCachesTable, SiteUserDataCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SiteUserDataCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useridMeta = const VerificationMeta('userid');
  @override
  late final GeneratedColumn<String> userid = GeneratedColumn<String>(
    'userid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userLevelMeta = const VerificationMeta(
    'userLevel',
  );
  @override
  late final GeneratedColumn<String> userLevel = GeneratedColumn<String>(
    'user_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinAtMeta = const VerificationMeta('joinAt');
  @override
  late final GeneratedColumn<String> joinAt = GeneratedColumn<String>(
    'join_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bonusMeta = const VerificationMeta('bonus');
  @override
  late final GeneratedColumn<double> bonus = GeneratedColumn<double>(
    'bonus',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadMeta = const VerificationMeta('upload');
  @override
  late final GeneratedColumn<int> upload = GeneratedColumn<int>(
    'upload',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadMeta = const VerificationMeta(
    'download',
  );
  @override
  late final GeneratedColumn<int> download = GeneratedColumn<int>(
    'download',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratioMeta = const VerificationMeta('ratio');
  @override
  late final GeneratedColumn<double> ratio = GeneratedColumn<double>(
    'ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedingMeta = const VerificationMeta(
    'seeding',
  );
  @override
  late final GeneratedColumn<int> seeding = GeneratedColumn<int>(
    'seeding',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leechingMeta = const VerificationMeta(
    'leeching',
  );
  @override
  late final GeneratedColumn<int> leeching = GeneratedColumn<int>(
    'leeching',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seedingSizeMeta = const VerificationMeta(
    'seedingSize',
  );
  @override
  late final GeneratedColumn<int> seedingSize = GeneratedColumn<int>(
    'seeding_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _leechingSizeMeta = const VerificationMeta(
    'leechingSize',
  );
  @override
  late final GeneratedColumn<int> leechingSize = GeneratedColumn<int>(
    'leeching_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageUnreadMeta = const VerificationMeta(
    'messageUnread',
  );
  @override
  late final GeneratedColumn<int> messageUnread = GeneratedColumn<int>(
    'message_unread',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errMsgMeta = const VerificationMeta('errMsg');
  @override
  late final GeneratedColumn<String> errMsg = GeneratedColumn<String>(
    'err_msg',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedDayMeta = const VerificationMeta(
    'updatedDay',
  );
  @override
  late final GeneratedColumn<String> updatedDay = GeneratedColumn<String>(
    'updated_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedTimeMeta = const VerificationMeta(
    'updatedTime',
  );
  @override
  late final GeneratedColumn<String> updatedTime = GeneratedColumn<String>(
    'updated_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    domain,
    username,
    userid,
    userLevel,
    joinAt,
    bonus,
    upload,
    download,
    ratio,
    seeding,
    leeching,
    seedingSize,
    leechingSize,
    messageUnread,
    errMsg,
    updatedDay,
    updatedTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'site_user_data_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<SiteUserDataCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('userid')) {
      context.handle(
        _useridMeta,
        userid.isAcceptableOrUnknown(data['userid']!, _useridMeta),
      );
    } else if (isInserting) {
      context.missing(_useridMeta);
    }
    if (data.containsKey('user_level')) {
      context.handle(
        _userLevelMeta,
        userLevel.isAcceptableOrUnknown(data['user_level']!, _userLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_userLevelMeta);
    }
    if (data.containsKey('join_at')) {
      context.handle(
        _joinAtMeta,
        joinAt.isAcceptableOrUnknown(data['join_at']!, _joinAtMeta),
      );
    } else if (isInserting) {
      context.missing(_joinAtMeta);
    }
    if (data.containsKey('bonus')) {
      context.handle(
        _bonusMeta,
        bonus.isAcceptableOrUnknown(data['bonus']!, _bonusMeta),
      );
    } else if (isInserting) {
      context.missing(_bonusMeta);
    }
    if (data.containsKey('upload')) {
      context.handle(
        _uploadMeta,
        upload.isAcceptableOrUnknown(data['upload']!, _uploadMeta),
      );
    } else if (isInserting) {
      context.missing(_uploadMeta);
    }
    if (data.containsKey('download')) {
      context.handle(
        _downloadMeta,
        download.isAcceptableOrUnknown(data['download']!, _downloadMeta),
      );
    } else if (isInserting) {
      context.missing(_downloadMeta);
    }
    if (data.containsKey('ratio')) {
      context.handle(
        _ratioMeta,
        ratio.isAcceptableOrUnknown(data['ratio']!, _ratioMeta),
      );
    } else if (isInserting) {
      context.missing(_ratioMeta);
    }
    if (data.containsKey('seeding')) {
      context.handle(
        _seedingMeta,
        seeding.isAcceptableOrUnknown(data['seeding']!, _seedingMeta),
      );
    } else if (isInserting) {
      context.missing(_seedingMeta);
    }
    if (data.containsKey('leeching')) {
      context.handle(
        _leechingMeta,
        leeching.isAcceptableOrUnknown(data['leeching']!, _leechingMeta),
      );
    } else if (isInserting) {
      context.missing(_leechingMeta);
    }
    if (data.containsKey('seeding_size')) {
      context.handle(
        _seedingSizeMeta,
        seedingSize.isAcceptableOrUnknown(
          data['seeding_size']!,
          _seedingSizeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seedingSizeMeta);
    }
    if (data.containsKey('leeching_size')) {
      context.handle(
        _leechingSizeMeta,
        leechingSize.isAcceptableOrUnknown(
          data['leeching_size']!,
          _leechingSizeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_leechingSizeMeta);
    }
    if (data.containsKey('message_unread')) {
      context.handle(
        _messageUnreadMeta,
        messageUnread.isAcceptableOrUnknown(
          data['message_unread']!,
          _messageUnreadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageUnreadMeta);
    }
    if (data.containsKey('err_msg')) {
      context.handle(
        _errMsgMeta,
        errMsg.isAcceptableOrUnknown(data['err_msg']!, _errMsgMeta),
      );
    } else if (isInserting) {
      context.missing(_errMsgMeta);
    }
    if (data.containsKey('updated_day')) {
      context.handle(
        _updatedDayMeta,
        updatedDay.isAcceptableOrUnknown(data['updated_day']!, _updatedDayMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedDayMeta);
    }
    if (data.containsKey('updated_time')) {
      context.handle(
        _updatedTimeMeta,
        updatedTime.isAcceptableOrUnknown(
          data['updated_time']!,
          _updatedTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedTimeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {domain};
  @override
  SiteUserDataCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SiteUserDataCacheRow(
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      userid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}userid'],
      )!,
      userLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_level'],
      )!,
      joinAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}join_at'],
      )!,
      bonus: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bonus'],
      )!,
      upload: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upload'],
      )!,
      download: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}download'],
      )!,
      ratio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ratio'],
      )!,
      seeding: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seeding'],
      )!,
      leeching: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}leeching'],
      )!,
      seedingSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seeding_size'],
      )!,
      leechingSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}leeching_size'],
      )!,
      messageUnread: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_unread'],
      )!,
      errMsg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}err_msg'],
      )!,
      updatedDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_day'],
      )!,
      updatedTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_time'],
      )!,
    );
  }

  @override
  $SiteUserDataCachesTable createAlias(String alias) {
    return $SiteUserDataCachesTable(attachedDatabase, alias);
  }
}

class SiteUserDataCacheRow extends DataClass
    implements Insertable<SiteUserDataCacheRow> {
  final String domain;
  final String username;
  final String userid;
  final String userLevel;
  final String joinAt;
  final double bonus;
  final int upload;
  final int download;
  final double ratio;
  final int seeding;
  final int leeching;
  final int seedingSize;
  final int leechingSize;
  final int messageUnread;
  final String errMsg;
  final String updatedDay;
  final String updatedTime;
  const SiteUserDataCacheRow({
    required this.domain,
    required this.username,
    required this.userid,
    required this.userLevel,
    required this.joinAt,
    required this.bonus,
    required this.upload,
    required this.download,
    required this.ratio,
    required this.seeding,
    required this.leeching,
    required this.seedingSize,
    required this.leechingSize,
    required this.messageUnread,
    required this.errMsg,
    required this.updatedDay,
    required this.updatedTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['domain'] = Variable<String>(domain);
    map['username'] = Variable<String>(username);
    map['userid'] = Variable<String>(userid);
    map['user_level'] = Variable<String>(userLevel);
    map['join_at'] = Variable<String>(joinAt);
    map['bonus'] = Variable<double>(bonus);
    map['upload'] = Variable<int>(upload);
    map['download'] = Variable<int>(download);
    map['ratio'] = Variable<double>(ratio);
    map['seeding'] = Variable<int>(seeding);
    map['leeching'] = Variable<int>(leeching);
    map['seeding_size'] = Variable<int>(seedingSize);
    map['leeching_size'] = Variable<int>(leechingSize);
    map['message_unread'] = Variable<int>(messageUnread);
    map['err_msg'] = Variable<String>(errMsg);
    map['updated_day'] = Variable<String>(updatedDay);
    map['updated_time'] = Variable<String>(updatedTime);
    return map;
  }

  SiteUserDataCachesCompanion toCompanion(bool nullToAbsent) {
    return SiteUserDataCachesCompanion(
      domain: Value(domain),
      username: Value(username),
      userid: Value(userid),
      userLevel: Value(userLevel),
      joinAt: Value(joinAt),
      bonus: Value(bonus),
      upload: Value(upload),
      download: Value(download),
      ratio: Value(ratio),
      seeding: Value(seeding),
      leeching: Value(leeching),
      seedingSize: Value(seedingSize),
      leechingSize: Value(leechingSize),
      messageUnread: Value(messageUnread),
      errMsg: Value(errMsg),
      updatedDay: Value(updatedDay),
      updatedTime: Value(updatedTime),
    );
  }

  factory SiteUserDataCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SiteUserDataCacheRow(
      domain: serializer.fromJson<String>(json['domain']),
      username: serializer.fromJson<String>(json['username']),
      userid: serializer.fromJson<String>(json['userid']),
      userLevel: serializer.fromJson<String>(json['userLevel']),
      joinAt: serializer.fromJson<String>(json['joinAt']),
      bonus: serializer.fromJson<double>(json['bonus']),
      upload: serializer.fromJson<int>(json['upload']),
      download: serializer.fromJson<int>(json['download']),
      ratio: serializer.fromJson<double>(json['ratio']),
      seeding: serializer.fromJson<int>(json['seeding']),
      leeching: serializer.fromJson<int>(json['leeching']),
      seedingSize: serializer.fromJson<int>(json['seedingSize']),
      leechingSize: serializer.fromJson<int>(json['leechingSize']),
      messageUnread: serializer.fromJson<int>(json['messageUnread']),
      errMsg: serializer.fromJson<String>(json['errMsg']),
      updatedDay: serializer.fromJson<String>(json['updatedDay']),
      updatedTime: serializer.fromJson<String>(json['updatedTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'domain': serializer.toJson<String>(domain),
      'username': serializer.toJson<String>(username),
      'userid': serializer.toJson<String>(userid),
      'userLevel': serializer.toJson<String>(userLevel),
      'joinAt': serializer.toJson<String>(joinAt),
      'bonus': serializer.toJson<double>(bonus),
      'upload': serializer.toJson<int>(upload),
      'download': serializer.toJson<int>(download),
      'ratio': serializer.toJson<double>(ratio),
      'seeding': serializer.toJson<int>(seeding),
      'leeching': serializer.toJson<int>(leeching),
      'seedingSize': serializer.toJson<int>(seedingSize),
      'leechingSize': serializer.toJson<int>(leechingSize),
      'messageUnread': serializer.toJson<int>(messageUnread),
      'errMsg': serializer.toJson<String>(errMsg),
      'updatedDay': serializer.toJson<String>(updatedDay),
      'updatedTime': serializer.toJson<String>(updatedTime),
    };
  }

  SiteUserDataCacheRow copyWith({
    String? domain,
    String? username,
    String? userid,
    String? userLevel,
    String? joinAt,
    double? bonus,
    int? upload,
    int? download,
    double? ratio,
    int? seeding,
    int? leeching,
    int? seedingSize,
    int? leechingSize,
    int? messageUnread,
    String? errMsg,
    String? updatedDay,
    String? updatedTime,
  }) => SiteUserDataCacheRow(
    domain: domain ?? this.domain,
    username: username ?? this.username,
    userid: userid ?? this.userid,
    userLevel: userLevel ?? this.userLevel,
    joinAt: joinAt ?? this.joinAt,
    bonus: bonus ?? this.bonus,
    upload: upload ?? this.upload,
    download: download ?? this.download,
    ratio: ratio ?? this.ratio,
    seeding: seeding ?? this.seeding,
    leeching: leeching ?? this.leeching,
    seedingSize: seedingSize ?? this.seedingSize,
    leechingSize: leechingSize ?? this.leechingSize,
    messageUnread: messageUnread ?? this.messageUnread,
    errMsg: errMsg ?? this.errMsg,
    updatedDay: updatedDay ?? this.updatedDay,
    updatedTime: updatedTime ?? this.updatedTime,
  );
  SiteUserDataCacheRow copyWithCompanion(SiteUserDataCachesCompanion data) {
    return SiteUserDataCacheRow(
      domain: data.domain.present ? data.domain.value : this.domain,
      username: data.username.present ? data.username.value : this.username,
      userid: data.userid.present ? data.userid.value : this.userid,
      userLevel: data.userLevel.present ? data.userLevel.value : this.userLevel,
      joinAt: data.joinAt.present ? data.joinAt.value : this.joinAt,
      bonus: data.bonus.present ? data.bonus.value : this.bonus,
      upload: data.upload.present ? data.upload.value : this.upload,
      download: data.download.present ? data.download.value : this.download,
      ratio: data.ratio.present ? data.ratio.value : this.ratio,
      seeding: data.seeding.present ? data.seeding.value : this.seeding,
      leeching: data.leeching.present ? data.leeching.value : this.leeching,
      seedingSize: data.seedingSize.present
          ? data.seedingSize.value
          : this.seedingSize,
      leechingSize: data.leechingSize.present
          ? data.leechingSize.value
          : this.leechingSize,
      messageUnread: data.messageUnread.present
          ? data.messageUnread.value
          : this.messageUnread,
      errMsg: data.errMsg.present ? data.errMsg.value : this.errMsg,
      updatedDay: data.updatedDay.present
          ? data.updatedDay.value
          : this.updatedDay,
      updatedTime: data.updatedTime.present
          ? data.updatedTime.value
          : this.updatedTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SiteUserDataCacheRow(')
          ..write('domain: $domain, ')
          ..write('username: $username, ')
          ..write('userid: $userid, ')
          ..write('userLevel: $userLevel, ')
          ..write('joinAt: $joinAt, ')
          ..write('bonus: $bonus, ')
          ..write('upload: $upload, ')
          ..write('download: $download, ')
          ..write('ratio: $ratio, ')
          ..write('seeding: $seeding, ')
          ..write('leeching: $leeching, ')
          ..write('seedingSize: $seedingSize, ')
          ..write('leechingSize: $leechingSize, ')
          ..write('messageUnread: $messageUnread, ')
          ..write('errMsg: $errMsg, ')
          ..write('updatedDay: $updatedDay, ')
          ..write('updatedTime: $updatedTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    domain,
    username,
    userid,
    userLevel,
    joinAt,
    bonus,
    upload,
    download,
    ratio,
    seeding,
    leeching,
    seedingSize,
    leechingSize,
    messageUnread,
    errMsg,
    updatedDay,
    updatedTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SiteUserDataCacheRow &&
          other.domain == this.domain &&
          other.username == this.username &&
          other.userid == this.userid &&
          other.userLevel == this.userLevel &&
          other.joinAt == this.joinAt &&
          other.bonus == this.bonus &&
          other.upload == this.upload &&
          other.download == this.download &&
          other.ratio == this.ratio &&
          other.seeding == this.seeding &&
          other.leeching == this.leeching &&
          other.seedingSize == this.seedingSize &&
          other.leechingSize == this.leechingSize &&
          other.messageUnread == this.messageUnread &&
          other.errMsg == this.errMsg &&
          other.updatedDay == this.updatedDay &&
          other.updatedTime == this.updatedTime);
}

class SiteUserDataCachesCompanion
    extends UpdateCompanion<SiteUserDataCacheRow> {
  final Value<String> domain;
  final Value<String> username;
  final Value<String> userid;
  final Value<String> userLevel;
  final Value<String> joinAt;
  final Value<double> bonus;
  final Value<int> upload;
  final Value<int> download;
  final Value<double> ratio;
  final Value<int> seeding;
  final Value<int> leeching;
  final Value<int> seedingSize;
  final Value<int> leechingSize;
  final Value<int> messageUnread;
  final Value<String> errMsg;
  final Value<String> updatedDay;
  final Value<String> updatedTime;
  final Value<int> rowid;
  const SiteUserDataCachesCompanion({
    this.domain = const Value.absent(),
    this.username = const Value.absent(),
    this.userid = const Value.absent(),
    this.userLevel = const Value.absent(),
    this.joinAt = const Value.absent(),
    this.bonus = const Value.absent(),
    this.upload = const Value.absent(),
    this.download = const Value.absent(),
    this.ratio = const Value.absent(),
    this.seeding = const Value.absent(),
    this.leeching = const Value.absent(),
    this.seedingSize = const Value.absent(),
    this.leechingSize = const Value.absent(),
    this.messageUnread = const Value.absent(),
    this.errMsg = const Value.absent(),
    this.updatedDay = const Value.absent(),
    this.updatedTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SiteUserDataCachesCompanion.insert({
    required String domain,
    required String username,
    required String userid,
    required String userLevel,
    required String joinAt,
    required double bonus,
    required int upload,
    required int download,
    required double ratio,
    required int seeding,
    required int leeching,
    required int seedingSize,
    required int leechingSize,
    required int messageUnread,
    required String errMsg,
    required String updatedDay,
    required String updatedTime,
    this.rowid = const Value.absent(),
  }) : domain = Value(domain),
       username = Value(username),
       userid = Value(userid),
       userLevel = Value(userLevel),
       joinAt = Value(joinAt),
       bonus = Value(bonus),
       upload = Value(upload),
       download = Value(download),
       ratio = Value(ratio),
       seeding = Value(seeding),
       leeching = Value(leeching),
       seedingSize = Value(seedingSize),
       leechingSize = Value(leechingSize),
       messageUnread = Value(messageUnread),
       errMsg = Value(errMsg),
       updatedDay = Value(updatedDay),
       updatedTime = Value(updatedTime);
  static Insertable<SiteUserDataCacheRow> custom({
    Expression<String>? domain,
    Expression<String>? username,
    Expression<String>? userid,
    Expression<String>? userLevel,
    Expression<String>? joinAt,
    Expression<double>? bonus,
    Expression<int>? upload,
    Expression<int>? download,
    Expression<double>? ratio,
    Expression<int>? seeding,
    Expression<int>? leeching,
    Expression<int>? seedingSize,
    Expression<int>? leechingSize,
    Expression<int>? messageUnread,
    Expression<String>? errMsg,
    Expression<String>? updatedDay,
    Expression<String>? updatedTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (domain != null) 'domain': domain,
      if (username != null) 'username': username,
      if (userid != null) 'userid': userid,
      if (userLevel != null) 'user_level': userLevel,
      if (joinAt != null) 'join_at': joinAt,
      if (bonus != null) 'bonus': bonus,
      if (upload != null) 'upload': upload,
      if (download != null) 'download': download,
      if (ratio != null) 'ratio': ratio,
      if (seeding != null) 'seeding': seeding,
      if (leeching != null) 'leeching': leeching,
      if (seedingSize != null) 'seeding_size': seedingSize,
      if (leechingSize != null) 'leeching_size': leechingSize,
      if (messageUnread != null) 'message_unread': messageUnread,
      if (errMsg != null) 'err_msg': errMsg,
      if (updatedDay != null) 'updated_day': updatedDay,
      if (updatedTime != null) 'updated_time': updatedTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SiteUserDataCachesCompanion copyWith({
    Value<String>? domain,
    Value<String>? username,
    Value<String>? userid,
    Value<String>? userLevel,
    Value<String>? joinAt,
    Value<double>? bonus,
    Value<int>? upload,
    Value<int>? download,
    Value<double>? ratio,
    Value<int>? seeding,
    Value<int>? leeching,
    Value<int>? seedingSize,
    Value<int>? leechingSize,
    Value<int>? messageUnread,
    Value<String>? errMsg,
    Value<String>? updatedDay,
    Value<String>? updatedTime,
    Value<int>? rowid,
  }) {
    return SiteUserDataCachesCompanion(
      domain: domain ?? this.domain,
      username: username ?? this.username,
      userid: userid ?? this.userid,
      userLevel: userLevel ?? this.userLevel,
      joinAt: joinAt ?? this.joinAt,
      bonus: bonus ?? this.bonus,
      upload: upload ?? this.upload,
      download: download ?? this.download,
      ratio: ratio ?? this.ratio,
      seeding: seeding ?? this.seeding,
      leeching: leeching ?? this.leeching,
      seedingSize: seedingSize ?? this.seedingSize,
      leechingSize: leechingSize ?? this.leechingSize,
      messageUnread: messageUnread ?? this.messageUnread,
      errMsg: errMsg ?? this.errMsg,
      updatedDay: updatedDay ?? this.updatedDay,
      updatedTime: updatedTime ?? this.updatedTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (userid.present) {
      map['userid'] = Variable<String>(userid.value);
    }
    if (userLevel.present) {
      map['user_level'] = Variable<String>(userLevel.value);
    }
    if (joinAt.present) {
      map['join_at'] = Variable<String>(joinAt.value);
    }
    if (bonus.present) {
      map['bonus'] = Variable<double>(bonus.value);
    }
    if (upload.present) {
      map['upload'] = Variable<int>(upload.value);
    }
    if (download.present) {
      map['download'] = Variable<int>(download.value);
    }
    if (ratio.present) {
      map['ratio'] = Variable<double>(ratio.value);
    }
    if (seeding.present) {
      map['seeding'] = Variable<int>(seeding.value);
    }
    if (leeching.present) {
      map['leeching'] = Variable<int>(leeching.value);
    }
    if (seedingSize.present) {
      map['seeding_size'] = Variable<int>(seedingSize.value);
    }
    if (leechingSize.present) {
      map['leeching_size'] = Variable<int>(leechingSize.value);
    }
    if (messageUnread.present) {
      map['message_unread'] = Variable<int>(messageUnread.value);
    }
    if (errMsg.present) {
      map['err_msg'] = Variable<String>(errMsg.value);
    }
    if (updatedDay.present) {
      map['updated_day'] = Variable<String>(updatedDay.value);
    }
    if (updatedTime.present) {
      map['updated_time'] = Variable<String>(updatedTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SiteUserDataCachesCompanion(')
          ..write('domain: $domain, ')
          ..write('username: $username, ')
          ..write('userid: $userid, ')
          ..write('userLevel: $userLevel, ')
          ..write('joinAt: $joinAt, ')
          ..write('bonus: $bonus, ')
          ..write('upload: $upload, ')
          ..write('download: $download, ')
          ..write('ratio: $ratio, ')
          ..write('seeding: $seeding, ')
          ..write('leeching: $leeching, ')
          ..write('seedingSize: $seedingSize, ')
          ..write('leechingSize: $leechingSize, ')
          ..write('messageUnread: $messageUnread, ')
          ..write('errMsg: $errMsg, ')
          ..write('updatedDay: $updatedDay, ')
          ..write('updatedTime: $updatedTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryEntriesTable extends SearchHistoryEntries
    with TableInfo<$SearchHistoryEntriesTable, SearchHistoryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keywordMeta = const VerificationMeta(
    'keyword',
  );
  @override
  late final GeneratedColumn<String> keyword = GeneratedColumn<String>(
    'keyword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, keyword, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('keyword')) {
      context.handle(
        _keywordMeta,
        keyword.isAcceptableOrUnknown(data['keyword']!, _keywordMeta),
      );
    } else if (isInserting) {
      context.missing(_keywordMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchHistoryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      keyword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keyword'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SearchHistoryEntriesTable createAlias(String alias) {
    return $SearchHistoryEntriesTable(attachedDatabase, alias);
  }
}

class SearchHistoryEntryRow extends DataClass
    implements Insertable<SearchHistoryEntryRow> {
  final String id;
  final String keyword;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SearchHistoryEntryRow({
    required this.id,
    required this.keyword,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['keyword'] = Variable<String>(keyword);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SearchHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryEntriesCompanion(
      id: Value(id),
      keyword: Value(keyword),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SearchHistoryEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryEntryRow(
      id: serializer.fromJson<String>(json['id']),
      keyword: serializer.fromJson<String>(json['keyword']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'keyword': serializer.toJson<String>(keyword),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SearchHistoryEntryRow copyWith({
    String? id,
    String? keyword,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SearchHistoryEntryRow(
    id: id ?? this.id,
    keyword: keyword ?? this.keyword,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SearchHistoryEntryRow copyWithCompanion(SearchHistoryEntriesCompanion data) {
    return SearchHistoryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      keyword: data.keyword.present ? data.keyword.value : this.keyword,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryEntryRow(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyword, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryEntryRow &&
          other.id == this.id &&
          other.keyword == this.keyword &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SearchHistoryEntriesCompanion
    extends UpdateCompanion<SearchHistoryEntryRow> {
  final Value<String> id;
  final Value<String> keyword;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SearchHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.keyword = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchHistoryEntriesCompanion.insert({
    required String id,
    required String keyword,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       keyword = Value(keyword),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SearchHistoryEntryRow> custom({
    Expression<String>? id,
    Expression<String>? keyword,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyword != null) 'keyword': keyword,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchHistoryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? keyword,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SearchHistoryEntriesCompanion(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (keyword.present) {
      map['keyword'] = Variable<String>(keyword.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LoginProfilesTable loginProfiles = $LoginProfilesTable(this);
  late final $MediaDetailCachesTable mediaDetailCaches =
      $MediaDetailCachesTable(this);
  late final $PluginModelCachesTable pluginModelCaches =
      $PluginModelCachesTable(this);
  late final $InstalledPluginModelCachesTable installedPluginModelCaches =
      $InstalledPluginModelCachesTable(this);
  late final $PluginPaletteEntriesTable pluginPaletteEntries =
      $PluginPaletteEntriesTable(this);
  late final $SiteIconCachesTable siteIconCaches = $SiteIconCachesTable(this);
  late final $SiteModelCachesTable siteModelCaches = $SiteModelCachesTable(
    this,
  );
  late final $SiteUserDataCachesTable siteUserDataCaches =
      $SiteUserDataCachesTable(this);
  late final $SearchHistoryEntriesTable searchHistoryEntries =
      $SearchHistoryEntriesTable(this);
  late final LoginProfileDao loginProfileDao = LoginProfileDao(
    this as AppDatabase,
  );
  late final MediaDetailCacheDao mediaDetailCacheDao = MediaDetailCacheDao(
    this as AppDatabase,
  );
  late final PluginCacheDao pluginCacheDao = PluginCacheDao(
    this as AppDatabase,
  );
  late final PluginPaletteDao pluginPaletteDao = PluginPaletteDao(
    this as AppDatabase,
  );
  late final SiteCacheDao siteCacheDao = SiteCacheDao(this as AppDatabase);
  late final SearchHistoryDao searchHistoryDao = SearchHistoryDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    loginProfiles,
    mediaDetailCaches,
    pluginModelCaches,
    installedPluginModelCaches,
    pluginPaletteEntries,
    siteIconCaches,
    siteModelCaches,
    siteUserDataCaches,
    searchHistoryEntries,
  ];
}

typedef $$LoginProfilesTableCreateCompanionBuilder =
    LoginProfilesCompanion Function({
      required String id,
      required String server,
      required String username,
      required String password,
      required String accessToken,
      required String tokenType,
      required bool superUser,
      required int userId,
      required String userName,
      Value<String?> avatar,
      required int level,
      required String permissionsJson,
      required bool wizard,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LoginProfilesTableUpdateCompanionBuilder =
    LoginProfilesCompanion Function({
      Value<String> id,
      Value<String> server,
      Value<String> username,
      Value<String> password,
      Value<String> accessToken,
      Value<String> tokenType,
      Value<bool> superUser,
      Value<int> userId,
      Value<String> userName,
      Value<String?> avatar,
      Value<int> level,
      Value<String> permissionsJson,
      Value<bool> wizard,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LoginProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LoginProfilesTable> {
  $$LoginProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tokenType => $composableBuilder(
    column: $table.tokenType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get superUser => $composableBuilder(
    column: $table.superUser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wizard => $composableBuilder(
    column: $table.wizard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LoginProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LoginProfilesTable> {
  $$LoginProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tokenType => $composableBuilder(
    column: $table.tokenType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get superUser => $composableBuilder(
    column: $table.superUser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wizard => $composableBuilder(
    column: $table.wizard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LoginProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoginProfilesTable> {
  $$LoginProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tokenType =>
      $composableBuilder(column: $table.tokenType, builder: (column) => column);

  GeneratedColumn<bool> get superUser =>
      $composableBuilder(column: $table.superUser, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wizard =>
      $composableBuilder(column: $table.wizard, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LoginProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoginProfilesTable,
          LoginProfileRow,
          $$LoginProfilesTableFilterComposer,
          $$LoginProfilesTableOrderingComposer,
          $$LoginProfilesTableAnnotationComposer,
          $$LoginProfilesTableCreateCompanionBuilder,
          $$LoginProfilesTableUpdateCompanionBuilder,
          (
            LoginProfileRow,
            BaseReferences<_$AppDatabase, $LoginProfilesTable, LoginProfileRow>,
          ),
          LoginProfileRow,
          PrefetchHooks Function()
        > {
  $$LoginProfilesTableTableManager(_$AppDatabase db, $LoginProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoginProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoginProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoginProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> server = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<String> accessToken = const Value.absent(),
                Value<String> tokenType = const Value.absent(),
                Value<bool> superUser = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> permissionsJson = const Value.absent(),
                Value<bool> wizard = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoginProfilesCompanion(
                id: id,
                server: server,
                username: username,
                password: password,
                accessToken: accessToken,
                tokenType: tokenType,
                superUser: superUser,
                userId: userId,
                userName: userName,
                avatar: avatar,
                level: level,
                permissionsJson: permissionsJson,
                wizard: wizard,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String server,
                required String username,
                required String password,
                required String accessToken,
                required String tokenType,
                required bool superUser,
                required int userId,
                required String userName,
                Value<String?> avatar = const Value.absent(),
                required int level,
                required String permissionsJson,
                required bool wizard,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LoginProfilesCompanion.insert(
                id: id,
                server: server,
                username: username,
                password: password,
                accessToken: accessToken,
                tokenType: tokenType,
                superUser: superUser,
                userId: userId,
                userName: userName,
                avatar: avatar,
                level: level,
                permissionsJson: permissionsJson,
                wizard: wizard,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LoginProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoginProfilesTable,
      LoginProfileRow,
      $$LoginProfilesTableFilterComposer,
      $$LoginProfilesTableOrderingComposer,
      $$LoginProfilesTableAnnotationComposer,
      $$LoginProfilesTableCreateCompanionBuilder,
      $$LoginProfilesTableUpdateCompanionBuilder,
      (
        LoginProfileRow,
        BaseReferences<_$AppDatabase, $LoginProfilesTable, LoginProfileRow>,
      ),
      LoginProfileRow,
      PrefetchHooks Function()
    >;
typedef $$MediaDetailCachesTableCreateCompanionBuilder =
    MediaDetailCachesCompanion Function({
      required String id,
      required String server,
      required String path,
      Value<String?> title,
      Value<String?> year,
      Value<String?> typeName,
      Value<String?> session,
      required String payload,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MediaDetailCachesTableUpdateCompanionBuilder =
    MediaDetailCachesCompanion Function({
      Value<String> id,
      Value<String> server,
      Value<String> path,
      Value<String?> title,
      Value<String?> year,
      Value<String?> typeName,
      Value<String?> session,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MediaDetailCachesTableFilterComposer
    extends Composer<_$AppDatabase, $MediaDetailCachesTable> {
  $$MediaDetailCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeName => $composableBuilder(
    column: $table.typeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get session => $composableBuilder(
    column: $table.session,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaDetailCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaDetailCachesTable> {
  $$MediaDetailCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeName => $composableBuilder(
    column: $table.typeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get session => $composableBuilder(
    column: $table.session,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaDetailCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaDetailCachesTable> {
  $$MediaDetailCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get typeName =>
      $composableBuilder(column: $table.typeName, builder: (column) => column);

  GeneratedColumn<String> get session =>
      $composableBuilder(column: $table.session, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MediaDetailCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaDetailCachesTable,
          MediaDetailCacheRow,
          $$MediaDetailCachesTableFilterComposer,
          $$MediaDetailCachesTableOrderingComposer,
          $$MediaDetailCachesTableAnnotationComposer,
          $$MediaDetailCachesTableCreateCompanionBuilder,
          $$MediaDetailCachesTableUpdateCompanionBuilder,
          (
            MediaDetailCacheRow,
            BaseReferences<
              _$AppDatabase,
              $MediaDetailCachesTable,
              MediaDetailCacheRow
            >,
          ),
          MediaDetailCacheRow,
          PrefetchHooks Function()
        > {
  $$MediaDetailCachesTableTableManager(
    _$AppDatabase db,
    $MediaDetailCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaDetailCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaDetailCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaDetailCachesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> server = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> typeName = const Value.absent(),
                Value<String?> session = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaDetailCachesCompanion(
                id: id,
                server: server,
                path: path,
                title: title,
                year: year,
                typeName: typeName,
                session: session,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String server,
                required String path,
                Value<String?> title = const Value.absent(),
                Value<String?> year = const Value.absent(),
                Value<String?> typeName = const Value.absent(),
                Value<String?> session = const Value.absent(),
                required String payload,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MediaDetailCachesCompanion.insert(
                id: id,
                server: server,
                path: path,
                title: title,
                year: year,
                typeName: typeName,
                session: session,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaDetailCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaDetailCachesTable,
      MediaDetailCacheRow,
      $$MediaDetailCachesTableFilterComposer,
      $$MediaDetailCachesTableOrderingComposer,
      $$MediaDetailCachesTableAnnotationComposer,
      $$MediaDetailCachesTableCreateCompanionBuilder,
      $$MediaDetailCachesTableUpdateCompanionBuilder,
      (
        MediaDetailCacheRow,
        BaseReferences<
          _$AppDatabase,
          $MediaDetailCachesTable,
          MediaDetailCacheRow
        >,
      ),
      MediaDetailCacheRow,
      PrefetchHooks Function()
    >;
typedef $$PluginModelCachesTableCreateCompanionBuilder =
    PluginModelCachesCompanion Function({
      required String id,
      required String pluginName,
      required String pluginDesc,
      required String pluginIcon,
      required String pluginVersion,
      required String pluginLabel,
      required String pluginAuthor,
      required String authorUrl,
      required String pluginConfigPrefix,
      required int pluginOrder,
      required int authLevel,
      required bool installed,
      required bool state,
      required bool hasPage,
      required bool hasUpdate,
      required bool isLocal,
      required String repoUrl,
      required int installCount,
      required int addTime,
      required String pluginPublicKey,
      Value<int> rowid,
    });
typedef $$PluginModelCachesTableUpdateCompanionBuilder =
    PluginModelCachesCompanion Function({
      Value<String> id,
      Value<String> pluginName,
      Value<String> pluginDesc,
      Value<String> pluginIcon,
      Value<String> pluginVersion,
      Value<String> pluginLabel,
      Value<String> pluginAuthor,
      Value<String> authorUrl,
      Value<String> pluginConfigPrefix,
      Value<int> pluginOrder,
      Value<int> authLevel,
      Value<bool> installed,
      Value<bool> state,
      Value<bool> hasPage,
      Value<bool> hasUpdate,
      Value<bool> isLocal,
      Value<String> repoUrl,
      Value<int> installCount,
      Value<int> addTime,
      Value<String> pluginPublicKey,
      Value<int> rowid,
    });

class $$PluginModelCachesTableFilterComposer
    extends Composer<_$AppDatabase, $PluginModelCachesTable> {
  $$PluginModelCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginName => $composableBuilder(
    column: $table.pluginName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginDesc => $composableBuilder(
    column: $table.pluginDesc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginIcon => $composableBuilder(
    column: $table.pluginIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginVersion => $composableBuilder(
    column: $table.pluginVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginLabel => $composableBuilder(
    column: $table.pluginLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginAuthor => $composableBuilder(
    column: $table.pluginAuthor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorUrl => $composableBuilder(
    column: $table.authorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginConfigPrefix => $composableBuilder(
    column: $table.pluginConfigPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pluginOrder => $composableBuilder(
    column: $table.pluginOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get authLevel => $composableBuilder(
    column: $table.authLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get installed => $composableBuilder(
    column: $table.installed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPage => $composableBuilder(
    column: $table.hasPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasUpdate => $composableBuilder(
    column: $table.hasUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installCount => $composableBuilder(
    column: $table.installCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addTime => $composableBuilder(
    column: $table.addTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginPublicKey => $composableBuilder(
    column: $table.pluginPublicKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PluginModelCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $PluginModelCachesTable> {
  $$PluginModelCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginName => $composableBuilder(
    column: $table.pluginName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginDesc => $composableBuilder(
    column: $table.pluginDesc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginIcon => $composableBuilder(
    column: $table.pluginIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginVersion => $composableBuilder(
    column: $table.pluginVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginLabel => $composableBuilder(
    column: $table.pluginLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginAuthor => $composableBuilder(
    column: $table.pluginAuthor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorUrl => $composableBuilder(
    column: $table.authorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginConfigPrefix => $composableBuilder(
    column: $table.pluginConfigPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pluginOrder => $composableBuilder(
    column: $table.pluginOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get authLevel => $composableBuilder(
    column: $table.authLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get installed => $composableBuilder(
    column: $table.installed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPage => $composableBuilder(
    column: $table.hasPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasUpdate => $composableBuilder(
    column: $table.hasUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installCount => $composableBuilder(
    column: $table.installCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addTime => $composableBuilder(
    column: $table.addTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginPublicKey => $composableBuilder(
    column: $table.pluginPublicKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PluginModelCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PluginModelCachesTable> {
  $$PluginModelCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pluginName => $composableBuilder(
    column: $table.pluginName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginDesc => $composableBuilder(
    column: $table.pluginDesc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginIcon => $composableBuilder(
    column: $table.pluginIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginVersion => $composableBuilder(
    column: $table.pluginVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginLabel => $composableBuilder(
    column: $table.pluginLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginAuthor => $composableBuilder(
    column: $table.pluginAuthor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorUrl =>
      $composableBuilder(column: $table.authorUrl, builder: (column) => column);

  GeneratedColumn<String> get pluginConfigPrefix => $composableBuilder(
    column: $table.pluginConfigPrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pluginOrder => $composableBuilder(
    column: $table.pluginOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get authLevel =>
      $composableBuilder(column: $table.authLevel, builder: (column) => column);

  GeneratedColumn<bool> get installed =>
      $composableBuilder(column: $table.installed, builder: (column) => column);

  GeneratedColumn<bool> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<bool> get hasPage =>
      $composableBuilder(column: $table.hasPage, builder: (column) => column);

  GeneratedColumn<bool> get hasUpdate =>
      $composableBuilder(column: $table.hasUpdate, builder: (column) => column);

  GeneratedColumn<bool> get isLocal =>
      $composableBuilder(column: $table.isLocal, builder: (column) => column);

  GeneratedColumn<String> get repoUrl =>
      $composableBuilder(column: $table.repoUrl, builder: (column) => column);

  GeneratedColumn<int> get installCount => $composableBuilder(
    column: $table.installCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addTime =>
      $composableBuilder(column: $table.addTime, builder: (column) => column);

  GeneratedColumn<String> get pluginPublicKey => $composableBuilder(
    column: $table.pluginPublicKey,
    builder: (column) => column,
  );
}

class $$PluginModelCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PluginModelCachesTable,
          PluginModelCacheRow,
          $$PluginModelCachesTableFilterComposer,
          $$PluginModelCachesTableOrderingComposer,
          $$PluginModelCachesTableAnnotationComposer,
          $$PluginModelCachesTableCreateCompanionBuilder,
          $$PluginModelCachesTableUpdateCompanionBuilder,
          (
            PluginModelCacheRow,
            BaseReferences<
              _$AppDatabase,
              $PluginModelCachesTable,
              PluginModelCacheRow
            >,
          ),
          PluginModelCacheRow,
          PrefetchHooks Function()
        > {
  $$PluginModelCachesTableTableManager(
    _$AppDatabase db,
    $PluginModelCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PluginModelCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PluginModelCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PluginModelCachesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pluginName = const Value.absent(),
                Value<String> pluginDesc = const Value.absent(),
                Value<String> pluginIcon = const Value.absent(),
                Value<String> pluginVersion = const Value.absent(),
                Value<String> pluginLabel = const Value.absent(),
                Value<String> pluginAuthor = const Value.absent(),
                Value<String> authorUrl = const Value.absent(),
                Value<String> pluginConfigPrefix = const Value.absent(),
                Value<int> pluginOrder = const Value.absent(),
                Value<int> authLevel = const Value.absent(),
                Value<bool> installed = const Value.absent(),
                Value<bool> state = const Value.absent(),
                Value<bool> hasPage = const Value.absent(),
                Value<bool> hasUpdate = const Value.absent(),
                Value<bool> isLocal = const Value.absent(),
                Value<String> repoUrl = const Value.absent(),
                Value<int> installCount = const Value.absent(),
                Value<int> addTime = const Value.absent(),
                Value<String> pluginPublicKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PluginModelCachesCompanion(
                id: id,
                pluginName: pluginName,
                pluginDesc: pluginDesc,
                pluginIcon: pluginIcon,
                pluginVersion: pluginVersion,
                pluginLabel: pluginLabel,
                pluginAuthor: pluginAuthor,
                authorUrl: authorUrl,
                pluginConfigPrefix: pluginConfigPrefix,
                pluginOrder: pluginOrder,
                authLevel: authLevel,
                installed: installed,
                state: state,
                hasPage: hasPage,
                hasUpdate: hasUpdate,
                isLocal: isLocal,
                repoUrl: repoUrl,
                installCount: installCount,
                addTime: addTime,
                pluginPublicKey: pluginPublicKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pluginName,
                required String pluginDesc,
                required String pluginIcon,
                required String pluginVersion,
                required String pluginLabel,
                required String pluginAuthor,
                required String authorUrl,
                required String pluginConfigPrefix,
                required int pluginOrder,
                required int authLevel,
                required bool installed,
                required bool state,
                required bool hasPage,
                required bool hasUpdate,
                required bool isLocal,
                required String repoUrl,
                required int installCount,
                required int addTime,
                required String pluginPublicKey,
                Value<int> rowid = const Value.absent(),
              }) => PluginModelCachesCompanion.insert(
                id: id,
                pluginName: pluginName,
                pluginDesc: pluginDesc,
                pluginIcon: pluginIcon,
                pluginVersion: pluginVersion,
                pluginLabel: pluginLabel,
                pluginAuthor: pluginAuthor,
                authorUrl: authorUrl,
                pluginConfigPrefix: pluginConfigPrefix,
                pluginOrder: pluginOrder,
                authLevel: authLevel,
                installed: installed,
                state: state,
                hasPage: hasPage,
                hasUpdate: hasUpdate,
                isLocal: isLocal,
                repoUrl: repoUrl,
                installCount: installCount,
                addTime: addTime,
                pluginPublicKey: pluginPublicKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PluginModelCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PluginModelCachesTable,
      PluginModelCacheRow,
      $$PluginModelCachesTableFilterComposer,
      $$PluginModelCachesTableOrderingComposer,
      $$PluginModelCachesTableAnnotationComposer,
      $$PluginModelCachesTableCreateCompanionBuilder,
      $$PluginModelCachesTableUpdateCompanionBuilder,
      (
        PluginModelCacheRow,
        BaseReferences<
          _$AppDatabase,
          $PluginModelCachesTable,
          PluginModelCacheRow
        >,
      ),
      PluginModelCacheRow,
      PrefetchHooks Function()
    >;
typedef $$InstalledPluginModelCachesTableCreateCompanionBuilder =
    InstalledPluginModelCachesCompanion Function({
      required String id,
      required String pluginName,
      required String pluginDesc,
      required String pluginIcon,
      required String pluginVersion,
      required String pluginLabel,
      required String pluginAuthor,
      required String authorUrl,
      required String pluginConfigPrefix,
      required int pluginOrder,
      required int authLevel,
      required bool installed,
      required bool state,
      required bool hasPage,
      required bool hasUpdate,
      required bool isLocal,
      required String repoUrl,
      required int installCount,
      required int addTime,
      required String pluginPublicKey,
      Value<int> rowid,
    });
typedef $$InstalledPluginModelCachesTableUpdateCompanionBuilder =
    InstalledPluginModelCachesCompanion Function({
      Value<String> id,
      Value<String> pluginName,
      Value<String> pluginDesc,
      Value<String> pluginIcon,
      Value<String> pluginVersion,
      Value<String> pluginLabel,
      Value<String> pluginAuthor,
      Value<String> authorUrl,
      Value<String> pluginConfigPrefix,
      Value<int> pluginOrder,
      Value<int> authLevel,
      Value<bool> installed,
      Value<bool> state,
      Value<bool> hasPage,
      Value<bool> hasUpdate,
      Value<bool> isLocal,
      Value<String> repoUrl,
      Value<int> installCount,
      Value<int> addTime,
      Value<String> pluginPublicKey,
      Value<int> rowid,
    });

class $$InstalledPluginModelCachesTableFilterComposer
    extends Composer<_$AppDatabase, $InstalledPluginModelCachesTable> {
  $$InstalledPluginModelCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginName => $composableBuilder(
    column: $table.pluginName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginDesc => $composableBuilder(
    column: $table.pluginDesc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginIcon => $composableBuilder(
    column: $table.pluginIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginVersion => $composableBuilder(
    column: $table.pluginVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginLabel => $composableBuilder(
    column: $table.pluginLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginAuthor => $composableBuilder(
    column: $table.pluginAuthor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorUrl => $composableBuilder(
    column: $table.authorUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginConfigPrefix => $composableBuilder(
    column: $table.pluginConfigPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pluginOrder => $composableBuilder(
    column: $table.pluginOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get authLevel => $composableBuilder(
    column: $table.authLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get installed => $composableBuilder(
    column: $table.installed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPage => $composableBuilder(
    column: $table.hasPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasUpdate => $composableBuilder(
    column: $table.hasUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installCount => $composableBuilder(
    column: $table.installCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addTime => $composableBuilder(
    column: $table.addTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pluginPublicKey => $composableBuilder(
    column: $table.pluginPublicKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstalledPluginModelCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $InstalledPluginModelCachesTable> {
  $$InstalledPluginModelCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginName => $composableBuilder(
    column: $table.pluginName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginDesc => $composableBuilder(
    column: $table.pluginDesc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginIcon => $composableBuilder(
    column: $table.pluginIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginVersion => $composableBuilder(
    column: $table.pluginVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginLabel => $composableBuilder(
    column: $table.pluginLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginAuthor => $composableBuilder(
    column: $table.pluginAuthor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorUrl => $composableBuilder(
    column: $table.authorUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginConfigPrefix => $composableBuilder(
    column: $table.pluginConfigPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pluginOrder => $composableBuilder(
    column: $table.pluginOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get authLevel => $composableBuilder(
    column: $table.authLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get installed => $composableBuilder(
    column: $table.installed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPage => $composableBuilder(
    column: $table.hasPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasUpdate => $composableBuilder(
    column: $table.hasUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installCount => $composableBuilder(
    column: $table.installCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addTime => $composableBuilder(
    column: $table.addTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pluginPublicKey => $composableBuilder(
    column: $table.pluginPublicKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstalledPluginModelCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstalledPluginModelCachesTable> {
  $$InstalledPluginModelCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pluginName => $composableBuilder(
    column: $table.pluginName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginDesc => $composableBuilder(
    column: $table.pluginDesc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginIcon => $composableBuilder(
    column: $table.pluginIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginVersion => $composableBuilder(
    column: $table.pluginVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginLabel => $composableBuilder(
    column: $table.pluginLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pluginAuthor => $composableBuilder(
    column: $table.pluginAuthor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorUrl =>
      $composableBuilder(column: $table.authorUrl, builder: (column) => column);

  GeneratedColumn<String> get pluginConfigPrefix => $composableBuilder(
    column: $table.pluginConfigPrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pluginOrder => $composableBuilder(
    column: $table.pluginOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get authLevel =>
      $composableBuilder(column: $table.authLevel, builder: (column) => column);

  GeneratedColumn<bool> get installed =>
      $composableBuilder(column: $table.installed, builder: (column) => column);

  GeneratedColumn<bool> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<bool> get hasPage =>
      $composableBuilder(column: $table.hasPage, builder: (column) => column);

  GeneratedColumn<bool> get hasUpdate =>
      $composableBuilder(column: $table.hasUpdate, builder: (column) => column);

  GeneratedColumn<bool> get isLocal =>
      $composableBuilder(column: $table.isLocal, builder: (column) => column);

  GeneratedColumn<String> get repoUrl =>
      $composableBuilder(column: $table.repoUrl, builder: (column) => column);

  GeneratedColumn<int> get installCount => $composableBuilder(
    column: $table.installCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addTime =>
      $composableBuilder(column: $table.addTime, builder: (column) => column);

  GeneratedColumn<String> get pluginPublicKey => $composableBuilder(
    column: $table.pluginPublicKey,
    builder: (column) => column,
  );
}

class $$InstalledPluginModelCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstalledPluginModelCachesTable,
          InstalledPluginModelCacheRow,
          $$InstalledPluginModelCachesTableFilterComposer,
          $$InstalledPluginModelCachesTableOrderingComposer,
          $$InstalledPluginModelCachesTableAnnotationComposer,
          $$InstalledPluginModelCachesTableCreateCompanionBuilder,
          $$InstalledPluginModelCachesTableUpdateCompanionBuilder,
          (
            InstalledPluginModelCacheRow,
            BaseReferences<
              _$AppDatabase,
              $InstalledPluginModelCachesTable,
              InstalledPluginModelCacheRow
            >,
          ),
          InstalledPluginModelCacheRow,
          PrefetchHooks Function()
        > {
  $$InstalledPluginModelCachesTableTableManager(
    _$AppDatabase db,
    $InstalledPluginModelCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstalledPluginModelCachesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InstalledPluginModelCachesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstalledPluginModelCachesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pluginName = const Value.absent(),
                Value<String> pluginDesc = const Value.absent(),
                Value<String> pluginIcon = const Value.absent(),
                Value<String> pluginVersion = const Value.absent(),
                Value<String> pluginLabel = const Value.absent(),
                Value<String> pluginAuthor = const Value.absent(),
                Value<String> authorUrl = const Value.absent(),
                Value<String> pluginConfigPrefix = const Value.absent(),
                Value<int> pluginOrder = const Value.absent(),
                Value<int> authLevel = const Value.absent(),
                Value<bool> installed = const Value.absent(),
                Value<bool> state = const Value.absent(),
                Value<bool> hasPage = const Value.absent(),
                Value<bool> hasUpdate = const Value.absent(),
                Value<bool> isLocal = const Value.absent(),
                Value<String> repoUrl = const Value.absent(),
                Value<int> installCount = const Value.absent(),
                Value<int> addTime = const Value.absent(),
                Value<String> pluginPublicKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstalledPluginModelCachesCompanion(
                id: id,
                pluginName: pluginName,
                pluginDesc: pluginDesc,
                pluginIcon: pluginIcon,
                pluginVersion: pluginVersion,
                pluginLabel: pluginLabel,
                pluginAuthor: pluginAuthor,
                authorUrl: authorUrl,
                pluginConfigPrefix: pluginConfigPrefix,
                pluginOrder: pluginOrder,
                authLevel: authLevel,
                installed: installed,
                state: state,
                hasPage: hasPage,
                hasUpdate: hasUpdate,
                isLocal: isLocal,
                repoUrl: repoUrl,
                installCount: installCount,
                addTime: addTime,
                pluginPublicKey: pluginPublicKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pluginName,
                required String pluginDesc,
                required String pluginIcon,
                required String pluginVersion,
                required String pluginLabel,
                required String pluginAuthor,
                required String authorUrl,
                required String pluginConfigPrefix,
                required int pluginOrder,
                required int authLevel,
                required bool installed,
                required bool state,
                required bool hasPage,
                required bool hasUpdate,
                required bool isLocal,
                required String repoUrl,
                required int installCount,
                required int addTime,
                required String pluginPublicKey,
                Value<int> rowid = const Value.absent(),
              }) => InstalledPluginModelCachesCompanion.insert(
                id: id,
                pluginName: pluginName,
                pluginDesc: pluginDesc,
                pluginIcon: pluginIcon,
                pluginVersion: pluginVersion,
                pluginLabel: pluginLabel,
                pluginAuthor: pluginAuthor,
                authorUrl: authorUrl,
                pluginConfigPrefix: pluginConfigPrefix,
                pluginOrder: pluginOrder,
                authLevel: authLevel,
                installed: installed,
                state: state,
                hasPage: hasPage,
                hasUpdate: hasUpdate,
                isLocal: isLocal,
                repoUrl: repoUrl,
                installCount: installCount,
                addTime: addTime,
                pluginPublicKey: pluginPublicKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstalledPluginModelCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstalledPluginModelCachesTable,
      InstalledPluginModelCacheRow,
      $$InstalledPluginModelCachesTableFilterComposer,
      $$InstalledPluginModelCachesTableOrderingComposer,
      $$InstalledPluginModelCachesTableAnnotationComposer,
      $$InstalledPluginModelCachesTableCreateCompanionBuilder,
      $$InstalledPluginModelCachesTableUpdateCompanionBuilder,
      (
        InstalledPluginModelCacheRow,
        BaseReferences<
          _$AppDatabase,
          $InstalledPluginModelCachesTable,
          InstalledPluginModelCacheRow
        >,
      ),
      InstalledPluginModelCacheRow,
      PrefetchHooks Function()
    >;
typedef $$PluginPaletteEntriesTableCreateCompanionBuilder =
    PluginPaletteEntriesCompanion Function({
      required String url,
      required int colorValue,
      Value<int> rowid,
    });
typedef $$PluginPaletteEntriesTableUpdateCompanionBuilder =
    PluginPaletteEntriesCompanion Function({
      Value<String> url,
      Value<int> colorValue,
      Value<int> rowid,
    });

class $$PluginPaletteEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PluginPaletteEntriesTable> {
  $$PluginPaletteEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PluginPaletteEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PluginPaletteEntriesTable> {
  $$PluginPaletteEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PluginPaletteEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PluginPaletteEntriesTable> {
  $$PluginPaletteEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );
}

class $$PluginPaletteEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PluginPaletteEntriesTable,
          PluginPaletteEntryRow,
          $$PluginPaletteEntriesTableFilterComposer,
          $$PluginPaletteEntriesTableOrderingComposer,
          $$PluginPaletteEntriesTableAnnotationComposer,
          $$PluginPaletteEntriesTableCreateCompanionBuilder,
          $$PluginPaletteEntriesTableUpdateCompanionBuilder,
          (
            PluginPaletteEntryRow,
            BaseReferences<
              _$AppDatabase,
              $PluginPaletteEntriesTable,
              PluginPaletteEntryRow
            >,
          ),
          PluginPaletteEntryRow,
          PrefetchHooks Function()
        > {
  $$PluginPaletteEntriesTableTableManager(
    _$AppDatabase db,
    $PluginPaletteEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PluginPaletteEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PluginPaletteEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PluginPaletteEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> url = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PluginPaletteEntriesCompanion(
                url: url,
                colorValue: colorValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String url,
                required int colorValue,
                Value<int> rowid = const Value.absent(),
              }) => PluginPaletteEntriesCompanion.insert(
                url: url,
                colorValue: colorValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PluginPaletteEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PluginPaletteEntriesTable,
      PluginPaletteEntryRow,
      $$PluginPaletteEntriesTableFilterComposer,
      $$PluginPaletteEntriesTableOrderingComposer,
      $$PluginPaletteEntriesTableAnnotationComposer,
      $$PluginPaletteEntriesTableCreateCompanionBuilder,
      $$PluginPaletteEntriesTableUpdateCompanionBuilder,
      (
        PluginPaletteEntryRow,
        BaseReferences<
          _$AppDatabase,
          $PluginPaletteEntriesTable,
          PluginPaletteEntryRow
        >,
      ),
      PluginPaletteEntryRow,
      PrefetchHooks Function()
    >;
typedef $$SiteIconCachesTableCreateCompanionBuilder =
    SiteIconCachesCompanion Function({
      required String url,
      required String iconBase64,
      Value<int> rowid,
    });
typedef $$SiteIconCachesTableUpdateCompanionBuilder =
    SiteIconCachesCompanion Function({
      Value<String> url,
      Value<String> iconBase64,
      Value<int> rowid,
    });

class $$SiteIconCachesTableFilterComposer
    extends Composer<_$AppDatabase, $SiteIconCachesTable> {
  $$SiteIconCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconBase64 => $composableBuilder(
    column: $table.iconBase64,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SiteIconCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $SiteIconCachesTable> {
  $$SiteIconCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconBase64 => $composableBuilder(
    column: $table.iconBase64,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SiteIconCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SiteIconCachesTable> {
  $$SiteIconCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get iconBase64 => $composableBuilder(
    column: $table.iconBase64,
    builder: (column) => column,
  );
}

class $$SiteIconCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SiteIconCachesTable,
          SiteIconCacheRow,
          $$SiteIconCachesTableFilterComposer,
          $$SiteIconCachesTableOrderingComposer,
          $$SiteIconCachesTableAnnotationComposer,
          $$SiteIconCachesTableCreateCompanionBuilder,
          $$SiteIconCachesTableUpdateCompanionBuilder,
          (
            SiteIconCacheRow,
            BaseReferences<
              _$AppDatabase,
              $SiteIconCachesTable,
              SiteIconCacheRow
            >,
          ),
          SiteIconCacheRow,
          PrefetchHooks Function()
        > {
  $$SiteIconCachesTableTableManager(
    _$AppDatabase db,
    $SiteIconCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SiteIconCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SiteIconCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SiteIconCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> url = const Value.absent(),
                Value<String> iconBase64 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SiteIconCachesCompanion(
                url: url,
                iconBase64: iconBase64,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String url,
                required String iconBase64,
                Value<int> rowid = const Value.absent(),
              }) => SiteIconCachesCompanion.insert(
                url: url,
                iconBase64: iconBase64,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SiteIconCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SiteIconCachesTable,
      SiteIconCacheRow,
      $$SiteIconCachesTableFilterComposer,
      $$SiteIconCachesTableOrderingComposer,
      $$SiteIconCachesTableAnnotationComposer,
      $$SiteIconCachesTableCreateCompanionBuilder,
      $$SiteIconCachesTableUpdateCompanionBuilder,
      (
        SiteIconCacheRow,
        BaseReferences<_$AppDatabase, $SiteIconCachesTable, SiteIconCacheRow>,
      ),
      SiteIconCacheRow,
      PrefetchHooks Function()
    >;
typedef $$SiteModelCachesTableCreateCompanionBuilder =
    SiteModelCachesCompanion Function({
      Value<int> id,
      required String name,
      required String domain,
      required String url,
      required int pri,
      required String rss,
      required String cookie,
      required String ua,
      required String apikey,
      required String token,
      required int proxy,
      required String filter,
      required int render,
      required int public,
      required String note,
      required int timeout,
      required int limitInterval,
      required int limitCount,
      required int limitSeconds,
      required bool isActive,
      required String downloader,
    });
typedef $$SiteModelCachesTableUpdateCompanionBuilder =
    SiteModelCachesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> domain,
      Value<String> url,
      Value<int> pri,
      Value<String> rss,
      Value<String> cookie,
      Value<String> ua,
      Value<String> apikey,
      Value<String> token,
      Value<int> proxy,
      Value<String> filter,
      Value<int> render,
      Value<int> public,
      Value<String> note,
      Value<int> timeout,
      Value<int> limitInterval,
      Value<int> limitCount,
      Value<int> limitSeconds,
      Value<bool> isActive,
      Value<String> downloader,
    });

class $$SiteModelCachesTableFilterComposer
    extends Composer<_$AppDatabase, $SiteModelCachesTable> {
  $$SiteModelCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pri => $composableBuilder(
    column: $table.pri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rss => $composableBuilder(
    column: $table.rss,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cookie => $composableBuilder(
    column: $table.cookie,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ua => $composableBuilder(
    column: $table.ua,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apikey => $composableBuilder(
    column: $table.apikey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get proxy => $composableBuilder(
    column: $table.proxy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get render => $composableBuilder(
    column: $table.render,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get public => $composableBuilder(
    column: $table.public,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeout => $composableBuilder(
    column: $table.timeout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitInterval => $composableBuilder(
    column: $table.limitInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitCount => $composableBuilder(
    column: $table.limitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitSeconds => $composableBuilder(
    column: $table.limitSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloader => $composableBuilder(
    column: $table.downloader,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SiteModelCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $SiteModelCachesTable> {
  $$SiteModelCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pri => $composableBuilder(
    column: $table.pri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rss => $composableBuilder(
    column: $table.rss,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cookie => $composableBuilder(
    column: $table.cookie,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ua => $composableBuilder(
    column: $table.ua,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apikey => $composableBuilder(
    column: $table.apikey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get proxy => $composableBuilder(
    column: $table.proxy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filter => $composableBuilder(
    column: $table.filter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get render => $composableBuilder(
    column: $table.render,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get public => $composableBuilder(
    column: $table.public,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeout => $composableBuilder(
    column: $table.timeout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitInterval => $composableBuilder(
    column: $table.limitInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitCount => $composableBuilder(
    column: $table.limitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitSeconds => $composableBuilder(
    column: $table.limitSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloader => $composableBuilder(
    column: $table.downloader,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SiteModelCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SiteModelCachesTable> {
  $$SiteModelCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get pri =>
      $composableBuilder(column: $table.pri, builder: (column) => column);

  GeneratedColumn<String> get rss =>
      $composableBuilder(column: $table.rss, builder: (column) => column);

  GeneratedColumn<String> get cookie =>
      $composableBuilder(column: $table.cookie, builder: (column) => column);

  GeneratedColumn<String> get ua =>
      $composableBuilder(column: $table.ua, builder: (column) => column);

  GeneratedColumn<String> get apikey =>
      $composableBuilder(column: $table.apikey, builder: (column) => column);

  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<int> get proxy =>
      $composableBuilder(column: $table.proxy, builder: (column) => column);

  GeneratedColumn<String> get filter =>
      $composableBuilder(column: $table.filter, builder: (column) => column);

  GeneratedColumn<int> get render =>
      $composableBuilder(column: $table.render, builder: (column) => column);

  GeneratedColumn<int> get public =>
      $composableBuilder(column: $table.public, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get timeout =>
      $composableBuilder(column: $table.timeout, builder: (column) => column);

  GeneratedColumn<int> get limitInterval => $composableBuilder(
    column: $table.limitInterval,
    builder: (column) => column,
  );

  GeneratedColumn<int> get limitCount => $composableBuilder(
    column: $table.limitCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get limitSeconds => $composableBuilder(
    column: $table.limitSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get downloader => $composableBuilder(
    column: $table.downloader,
    builder: (column) => column,
  );
}

class $$SiteModelCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SiteModelCachesTable,
          SiteModelCacheRow,
          $$SiteModelCachesTableFilterComposer,
          $$SiteModelCachesTableOrderingComposer,
          $$SiteModelCachesTableAnnotationComposer,
          $$SiteModelCachesTableCreateCompanionBuilder,
          $$SiteModelCachesTableUpdateCompanionBuilder,
          (
            SiteModelCacheRow,
            BaseReferences<
              _$AppDatabase,
              $SiteModelCachesTable,
              SiteModelCacheRow
            >,
          ),
          SiteModelCacheRow,
          PrefetchHooks Function()
        > {
  $$SiteModelCachesTableTableManager(
    _$AppDatabase db,
    $SiteModelCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SiteModelCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SiteModelCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SiteModelCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<int> pri = const Value.absent(),
                Value<String> rss = const Value.absent(),
                Value<String> cookie = const Value.absent(),
                Value<String> ua = const Value.absent(),
                Value<String> apikey = const Value.absent(),
                Value<String> token = const Value.absent(),
                Value<int> proxy = const Value.absent(),
                Value<String> filter = const Value.absent(),
                Value<int> render = const Value.absent(),
                Value<int> public = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> timeout = const Value.absent(),
                Value<int> limitInterval = const Value.absent(),
                Value<int> limitCount = const Value.absent(),
                Value<int> limitSeconds = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> downloader = const Value.absent(),
              }) => SiteModelCachesCompanion(
                id: id,
                name: name,
                domain: domain,
                url: url,
                pri: pri,
                rss: rss,
                cookie: cookie,
                ua: ua,
                apikey: apikey,
                token: token,
                proxy: proxy,
                filter: filter,
                render: render,
                public: public,
                note: note,
                timeout: timeout,
                limitInterval: limitInterval,
                limitCount: limitCount,
                limitSeconds: limitSeconds,
                isActive: isActive,
                downloader: downloader,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String domain,
                required String url,
                required int pri,
                required String rss,
                required String cookie,
                required String ua,
                required String apikey,
                required String token,
                required int proxy,
                required String filter,
                required int render,
                required int public,
                required String note,
                required int timeout,
                required int limitInterval,
                required int limitCount,
                required int limitSeconds,
                required bool isActive,
                required String downloader,
              }) => SiteModelCachesCompanion.insert(
                id: id,
                name: name,
                domain: domain,
                url: url,
                pri: pri,
                rss: rss,
                cookie: cookie,
                ua: ua,
                apikey: apikey,
                token: token,
                proxy: proxy,
                filter: filter,
                render: render,
                public: public,
                note: note,
                timeout: timeout,
                limitInterval: limitInterval,
                limitCount: limitCount,
                limitSeconds: limitSeconds,
                isActive: isActive,
                downloader: downloader,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SiteModelCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SiteModelCachesTable,
      SiteModelCacheRow,
      $$SiteModelCachesTableFilterComposer,
      $$SiteModelCachesTableOrderingComposer,
      $$SiteModelCachesTableAnnotationComposer,
      $$SiteModelCachesTableCreateCompanionBuilder,
      $$SiteModelCachesTableUpdateCompanionBuilder,
      (
        SiteModelCacheRow,
        BaseReferences<_$AppDatabase, $SiteModelCachesTable, SiteModelCacheRow>,
      ),
      SiteModelCacheRow,
      PrefetchHooks Function()
    >;
typedef $$SiteUserDataCachesTableCreateCompanionBuilder =
    SiteUserDataCachesCompanion Function({
      required String domain,
      required String username,
      required String userid,
      required String userLevel,
      required String joinAt,
      required double bonus,
      required int upload,
      required int download,
      required double ratio,
      required int seeding,
      required int leeching,
      required int seedingSize,
      required int leechingSize,
      required int messageUnread,
      required String errMsg,
      required String updatedDay,
      required String updatedTime,
      Value<int> rowid,
    });
typedef $$SiteUserDataCachesTableUpdateCompanionBuilder =
    SiteUserDataCachesCompanion Function({
      Value<String> domain,
      Value<String> username,
      Value<String> userid,
      Value<String> userLevel,
      Value<String> joinAt,
      Value<double> bonus,
      Value<int> upload,
      Value<int> download,
      Value<double> ratio,
      Value<int> seeding,
      Value<int> leeching,
      Value<int> seedingSize,
      Value<int> leechingSize,
      Value<int> messageUnread,
      Value<String> errMsg,
      Value<String> updatedDay,
      Value<String> updatedTime,
      Value<int> rowid,
    });

class $$SiteUserDataCachesTableFilterComposer
    extends Composer<_$AppDatabase, $SiteUserDataCachesTable> {
  $$SiteUserDataCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userid => $composableBuilder(
    column: $table.userid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userLevel => $composableBuilder(
    column: $table.userLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joinAt => $composableBuilder(
    column: $table.joinAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bonus => $composableBuilder(
    column: $table.bonus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get upload => $composableBuilder(
    column: $table.upload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get download => $composableBuilder(
    column: $table.download,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ratio => $composableBuilder(
    column: $table.ratio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seeding => $composableBuilder(
    column: $table.seeding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leeching => $composableBuilder(
    column: $table.leeching,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seedingSize => $composableBuilder(
    column: $table.seedingSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leechingSize => $composableBuilder(
    column: $table.leechingSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageUnread => $composableBuilder(
    column: $table.messageUnread,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errMsg => $composableBuilder(
    column: $table.errMsg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedDay => $composableBuilder(
    column: $table.updatedDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedTime => $composableBuilder(
    column: $table.updatedTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SiteUserDataCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $SiteUserDataCachesTable> {
  $$SiteUserDataCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userid => $composableBuilder(
    column: $table.userid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userLevel => $composableBuilder(
    column: $table.userLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joinAt => $composableBuilder(
    column: $table.joinAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bonus => $composableBuilder(
    column: $table.bonus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get upload => $composableBuilder(
    column: $table.upload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get download => $composableBuilder(
    column: $table.download,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ratio => $composableBuilder(
    column: $table.ratio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seeding => $composableBuilder(
    column: $table.seeding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leeching => $composableBuilder(
    column: $table.leeching,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seedingSize => $composableBuilder(
    column: $table.seedingSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leechingSize => $composableBuilder(
    column: $table.leechingSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageUnread => $composableBuilder(
    column: $table.messageUnread,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errMsg => $composableBuilder(
    column: $table.errMsg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedDay => $composableBuilder(
    column: $table.updatedDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedTime => $composableBuilder(
    column: $table.updatedTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SiteUserDataCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SiteUserDataCachesTable> {
  $$SiteUserDataCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get userid =>
      $composableBuilder(column: $table.userid, builder: (column) => column);

  GeneratedColumn<String> get userLevel =>
      $composableBuilder(column: $table.userLevel, builder: (column) => column);

  GeneratedColumn<String> get joinAt =>
      $composableBuilder(column: $table.joinAt, builder: (column) => column);

  GeneratedColumn<double> get bonus =>
      $composableBuilder(column: $table.bonus, builder: (column) => column);

  GeneratedColumn<int> get upload =>
      $composableBuilder(column: $table.upload, builder: (column) => column);

  GeneratedColumn<int> get download =>
      $composableBuilder(column: $table.download, builder: (column) => column);

  GeneratedColumn<double> get ratio =>
      $composableBuilder(column: $table.ratio, builder: (column) => column);

  GeneratedColumn<int> get seeding =>
      $composableBuilder(column: $table.seeding, builder: (column) => column);

  GeneratedColumn<int> get leeching =>
      $composableBuilder(column: $table.leeching, builder: (column) => column);

  GeneratedColumn<int> get seedingSize => $composableBuilder(
    column: $table.seedingSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leechingSize => $composableBuilder(
    column: $table.leechingSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get messageUnread => $composableBuilder(
    column: $table.messageUnread,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errMsg =>
      $composableBuilder(column: $table.errMsg, builder: (column) => column);

  GeneratedColumn<String> get updatedDay => $composableBuilder(
    column: $table.updatedDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedTime => $composableBuilder(
    column: $table.updatedTime,
    builder: (column) => column,
  );
}

class $$SiteUserDataCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SiteUserDataCachesTable,
          SiteUserDataCacheRow,
          $$SiteUserDataCachesTableFilterComposer,
          $$SiteUserDataCachesTableOrderingComposer,
          $$SiteUserDataCachesTableAnnotationComposer,
          $$SiteUserDataCachesTableCreateCompanionBuilder,
          $$SiteUserDataCachesTableUpdateCompanionBuilder,
          (
            SiteUserDataCacheRow,
            BaseReferences<
              _$AppDatabase,
              $SiteUserDataCachesTable,
              SiteUserDataCacheRow
            >,
          ),
          SiteUserDataCacheRow,
          PrefetchHooks Function()
        > {
  $$SiteUserDataCachesTableTableManager(
    _$AppDatabase db,
    $SiteUserDataCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SiteUserDataCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SiteUserDataCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SiteUserDataCachesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> domain = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> userid = const Value.absent(),
                Value<String> userLevel = const Value.absent(),
                Value<String> joinAt = const Value.absent(),
                Value<double> bonus = const Value.absent(),
                Value<int> upload = const Value.absent(),
                Value<int> download = const Value.absent(),
                Value<double> ratio = const Value.absent(),
                Value<int> seeding = const Value.absent(),
                Value<int> leeching = const Value.absent(),
                Value<int> seedingSize = const Value.absent(),
                Value<int> leechingSize = const Value.absent(),
                Value<int> messageUnread = const Value.absent(),
                Value<String> errMsg = const Value.absent(),
                Value<String> updatedDay = const Value.absent(),
                Value<String> updatedTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SiteUserDataCachesCompanion(
                domain: domain,
                username: username,
                userid: userid,
                userLevel: userLevel,
                joinAt: joinAt,
                bonus: bonus,
                upload: upload,
                download: download,
                ratio: ratio,
                seeding: seeding,
                leeching: leeching,
                seedingSize: seedingSize,
                leechingSize: leechingSize,
                messageUnread: messageUnread,
                errMsg: errMsg,
                updatedDay: updatedDay,
                updatedTime: updatedTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String domain,
                required String username,
                required String userid,
                required String userLevel,
                required String joinAt,
                required double bonus,
                required int upload,
                required int download,
                required double ratio,
                required int seeding,
                required int leeching,
                required int seedingSize,
                required int leechingSize,
                required int messageUnread,
                required String errMsg,
                required String updatedDay,
                required String updatedTime,
                Value<int> rowid = const Value.absent(),
              }) => SiteUserDataCachesCompanion.insert(
                domain: domain,
                username: username,
                userid: userid,
                userLevel: userLevel,
                joinAt: joinAt,
                bonus: bonus,
                upload: upload,
                download: download,
                ratio: ratio,
                seeding: seeding,
                leeching: leeching,
                seedingSize: seedingSize,
                leechingSize: leechingSize,
                messageUnread: messageUnread,
                errMsg: errMsg,
                updatedDay: updatedDay,
                updatedTime: updatedTime,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SiteUserDataCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SiteUserDataCachesTable,
      SiteUserDataCacheRow,
      $$SiteUserDataCachesTableFilterComposer,
      $$SiteUserDataCachesTableOrderingComposer,
      $$SiteUserDataCachesTableAnnotationComposer,
      $$SiteUserDataCachesTableCreateCompanionBuilder,
      $$SiteUserDataCachesTableUpdateCompanionBuilder,
      (
        SiteUserDataCacheRow,
        BaseReferences<
          _$AppDatabase,
          $SiteUserDataCachesTable,
          SiteUserDataCacheRow
        >,
      ),
      SiteUserDataCacheRow,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryEntriesTableCreateCompanionBuilder =
    SearchHistoryEntriesCompanion Function({
      required String id,
      required String keyword,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SearchHistoryEntriesTableUpdateCompanionBuilder =
    SearchHistoryEntriesCompanion Function({
      Value<String> id,
      Value<String> keyword,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SearchHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoryEntriesTable> {
  $$SearchHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoryEntriesTable> {
  $$SearchHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoryEntriesTable> {
  $$SearchHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get keyword =>
      $composableBuilder(column: $table.keyword, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SearchHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryEntriesTable,
          SearchHistoryEntryRow,
          $$SearchHistoryEntriesTableFilterComposer,
          $$SearchHistoryEntriesTableOrderingComposer,
          $$SearchHistoryEntriesTableAnnotationComposer,
          $$SearchHistoryEntriesTableCreateCompanionBuilder,
          $$SearchHistoryEntriesTableUpdateCompanionBuilder,
          (
            SearchHistoryEntryRow,
            BaseReferences<
              _$AppDatabase,
              $SearchHistoryEntriesTable,
              SearchHistoryEntryRow
            >,
          ),
          SearchHistoryEntryRow,
          PrefetchHooks Function()
        > {
  $$SearchHistoryEntriesTableTableManager(
    _$AppDatabase db,
    $SearchHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SearchHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> keyword = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryEntriesCompanion(
                id: id,
                keyword: keyword,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String keyword,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryEntriesCompanion.insert(
                id: id,
                keyword: keyword,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryEntriesTable,
      SearchHistoryEntryRow,
      $$SearchHistoryEntriesTableFilterComposer,
      $$SearchHistoryEntriesTableOrderingComposer,
      $$SearchHistoryEntriesTableAnnotationComposer,
      $$SearchHistoryEntriesTableCreateCompanionBuilder,
      $$SearchHistoryEntriesTableUpdateCompanionBuilder,
      (
        SearchHistoryEntryRow,
        BaseReferences<
          _$AppDatabase,
          $SearchHistoryEntriesTable,
          SearchHistoryEntryRow
        >,
      ),
      SearchHistoryEntryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LoginProfilesTableTableManager get loginProfiles =>
      $$LoginProfilesTableTableManager(_db, _db.loginProfiles);
  $$MediaDetailCachesTableTableManager get mediaDetailCaches =>
      $$MediaDetailCachesTableTableManager(_db, _db.mediaDetailCaches);
  $$PluginModelCachesTableTableManager get pluginModelCaches =>
      $$PluginModelCachesTableTableManager(_db, _db.pluginModelCaches);
  $$InstalledPluginModelCachesTableTableManager
  get installedPluginModelCaches =>
      $$InstalledPluginModelCachesTableTableManager(
        _db,
        _db.installedPluginModelCaches,
      );
  $$PluginPaletteEntriesTableTableManager get pluginPaletteEntries =>
      $$PluginPaletteEntriesTableTableManager(_db, _db.pluginPaletteEntries);
  $$SiteIconCachesTableTableManager get siteIconCaches =>
      $$SiteIconCachesTableTableManager(_db, _db.siteIconCaches);
  $$SiteModelCachesTableTableManager get siteModelCaches =>
      $$SiteModelCachesTableTableManager(_db, _db.siteModelCaches);
  $$SiteUserDataCachesTableTableManager get siteUserDataCaches =>
      $$SiteUserDataCachesTableTableManager(_db, _db.siteUserDataCaches);
  $$SearchHistoryEntriesTableTableManager get searchHistoryEntries =>
      $$SearchHistoryEntriesTableTableManager(_db, _db.searchHistoryEntries);
}
