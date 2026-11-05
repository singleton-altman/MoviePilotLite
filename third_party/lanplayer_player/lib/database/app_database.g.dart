// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MediaServersTableTable extends MediaServersTable
    with TableInfo<$MediaServersTableTable, MediaServerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaServersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<String, int> serverType =
      GeneratedColumn<int>('server_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<String>($MediaServersTableTable.$converterserverType);
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
      'api_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isConnectedMeta =
      const VerificationMeta('isConnected');
  @override
  late final GeneratedColumn<bool> isConnected = GeneratedColumn<bool>(
      'is_connected', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_connected" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
      'is_default', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        url,
        serverType,
        apiKey,
        username,
        password,
        isConnected,
        isDefault
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_servers_table';
  @override
  VerificationContext validateIntegrity(Insertable<MediaServerRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(_apiKeyMeta,
          apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    }
    if (data.containsKey('is_connected')) {
      context.handle(
          _isConnectedMeta,
          isConnected.isAcceptableOrUnknown(
              data['is_connected']!, _isConnectedMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaServerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaServerRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      serverType: $MediaServersTableTable.$converterserverType.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}server_type'])!),
      apiKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}api_key']),
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username']),
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password']),
      isConnected: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_connected'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
    );
  }

  @override
  $MediaServersTableTable createAlias(String alias) {
    return $MediaServersTableTable(attachedDatabase, alias);
  }

  static TypeConverter<String, int> $converterserverType =
      const ServerTypeConverter();
}

class MediaServerRow extends DataClass implements Insertable<MediaServerRow> {
  final String id;
  final String name;
  final String url;
  final String serverType;
  final String? apiKey;
  final String? username;
  final String? password;
  final bool isConnected;
  final bool isDefault;
  const MediaServerRow(
      {required this.id,
      required this.name,
      required this.url,
      required this.serverType,
      this.apiKey,
      this.username,
      this.password,
      required this.isConnected,
      required this.isDefault});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    {
      map['server_type'] = Variable<int>(
          $MediaServersTableTable.$converterserverType.toSql(serverType));
    }
    if (!nullToAbsent || apiKey != null) {
      map['api_key'] = Variable<String>(apiKey);
    }
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    map['is_connected'] = Variable<bool>(isConnected);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  MediaServersTableCompanion toCompanion(bool nullToAbsent) {
    return MediaServersTableCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      serverType: Value(serverType),
      apiKey:
          apiKey == null && nullToAbsent ? const Value.absent() : Value(apiKey),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      isConnected: Value(isConnected),
      isDefault: Value(isDefault),
    );
  }

  factory MediaServerRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaServerRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      serverType: serializer.fromJson<String>(json['serverType']),
      apiKey: serializer.fromJson<String?>(json['apiKey']),
      username: serializer.fromJson<String?>(json['username']),
      password: serializer.fromJson<String?>(json['password']),
      isConnected: serializer.fromJson<bool>(json['isConnected']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'serverType': serializer.toJson<String>(serverType),
      'apiKey': serializer.toJson<String?>(apiKey),
      'username': serializer.toJson<String?>(username),
      'password': serializer.toJson<String?>(password),
      'isConnected': serializer.toJson<bool>(isConnected),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  MediaServerRow copyWith(
          {String? id,
          String? name,
          String? url,
          String? serverType,
          Value<String?> apiKey = const Value.absent(),
          Value<String?> username = const Value.absent(),
          Value<String?> password = const Value.absent(),
          bool? isConnected,
          bool? isDefault}) =>
      MediaServerRow(
        id: id ?? this.id,
        name: name ?? this.name,
        url: url ?? this.url,
        serverType: serverType ?? this.serverType,
        apiKey: apiKey.present ? apiKey.value : this.apiKey,
        username: username.present ? username.value : this.username,
        password: password.present ? password.value : this.password,
        isConnected: isConnected ?? this.isConnected,
        isDefault: isDefault ?? this.isDefault,
      );
  MediaServerRow copyWithCompanion(MediaServersTableCompanion data) {
    return MediaServerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      serverType:
          data.serverType.present ? data.serverType.value : this.serverType,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      isConnected:
          data.isConnected.present ? data.isConnected.value : this.isConnected,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaServerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('serverType: $serverType, ')
          ..write('apiKey: $apiKey, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('isConnected: $isConnected, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, url, serverType, apiKey, username,
      password, isConnected, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaServerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.serverType == this.serverType &&
          other.apiKey == this.apiKey &&
          other.username == this.username &&
          other.password == this.password &&
          other.isConnected == this.isConnected &&
          other.isDefault == this.isDefault);
}

class MediaServersTableCompanion extends UpdateCompanion<MediaServerRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> url;
  final Value<String> serverType;
  final Value<String?> apiKey;
  final Value<String?> username;
  final Value<String?> password;
  final Value<bool> isConnected;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const MediaServersTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.serverType = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.isConnected = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaServersTableCompanion.insert({
    required String id,
    required String name,
    required String url,
    required String serverType,
    this.apiKey = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.isConnected = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        url = Value(url),
        serverType = Value(serverType);
  static Insertable<MediaServerRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<int>? serverType,
    Expression<String>? apiKey,
    Expression<String>? username,
    Expression<String>? password,
    Expression<bool>? isConnected,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (serverType != null) 'server_type': serverType,
      if (apiKey != null) 'api_key': apiKey,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (isConnected != null) 'is_connected': isConnected,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaServersTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? url,
      Value<String>? serverType,
      Value<String?>? apiKey,
      Value<String?>? username,
      Value<String?>? password,
      Value<bool>? isConnected,
      Value<bool>? isDefault,
      Value<int>? rowid}) {
    return MediaServersTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      serverType: serverType ?? this.serverType,
      apiKey: apiKey ?? this.apiKey,
      username: username ?? this.username,
      password: password ?? this.password,
      isConnected: isConnected ?? this.isConnected,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (serverType.present) {
      map['server_type'] = Variable<int>(
          $MediaServersTableTable.$converterserverType.toSql(serverType.value));
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (isConnected.present) {
      map['is_connected'] = Variable<bool>(isConnected.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaServersTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('serverType: $serverType, ')
          ..write('apiKey: $apiKey, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('isConnected: $isConnected, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DanmakuConfigsTableTable extends DanmakuConfigsTable
    with TableInfo<$DanmakuConfigsTableTable, DanmakuConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DanmakuConfigsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
      'api_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isEnabledMeta =
      const VerificationMeta('isEnabled');
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'is_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _fontSizeMeta =
      const VerificationMeta('fontSize');
  @override
  late final GeneratedColumn<double> fontSize = GeneratedColumn<double>(
      'font_size', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(24.0));
  static const VerificationMeta _opacityMeta =
      const VerificationMeta('opacity');
  @override
  late final GeneratedColumn<double> opacity = GeneratedColumn<double>(
      'opacity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
      'speed', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(12.0));
  static const VerificationMeta _showTopMeta =
      const VerificationMeta('showTop');
  @override
  late final GeneratedColumn<bool> showTop = GeneratedColumn<bool>(
      'show_top', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_top" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showBottomMeta =
      const VerificationMeta('showBottom');
  @override
  late final GeneratedColumn<bool> showBottom = GeneratedColumn<bool>(
      'show_bottom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_bottom" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _showScrollMeta =
      const VerificationMeta('showScroll');
  @override
  late final GeneratedColumn<bool> showScroll = GeneratedColumn<bool>(
      'show_scroll', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("show_scroll" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        url,
        apiKey,
        isEnabled,
        fontSize,
        opacity,
        speed,
        showTop,
        showBottom,
        showScroll
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'danmaku_configs_table';
  @override
  VerificationContext validateIntegrity(Insertable<DanmakuConfigRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(_apiKeyMeta,
          apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta));
    }
    if (data.containsKey('is_enabled')) {
      context.handle(_isEnabledMeta,
          isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta));
    }
    if (data.containsKey('font_size')) {
      context.handle(_fontSizeMeta,
          fontSize.isAcceptableOrUnknown(data['font_size']!, _fontSizeMeta));
    }
    if (data.containsKey('opacity')) {
      context.handle(_opacityMeta,
          opacity.isAcceptableOrUnknown(data['opacity']!, _opacityMeta));
    }
    if (data.containsKey('speed')) {
      context.handle(
          _speedMeta, speed.isAcceptableOrUnknown(data['speed']!, _speedMeta));
    }
    if (data.containsKey('show_top')) {
      context.handle(_showTopMeta,
          showTop.isAcceptableOrUnknown(data['show_top']!, _showTopMeta));
    }
    if (data.containsKey('show_bottom')) {
      context.handle(
          _showBottomMeta,
          showBottom.isAcceptableOrUnknown(
              data['show_bottom']!, _showBottomMeta));
    }
    if (data.containsKey('show_scroll')) {
      context.handle(
          _showScrollMeta,
          showScroll.isAcceptableOrUnknown(
              data['show_scroll']!, _showScrollMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DanmakuConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DanmakuConfigRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      apiKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}api_key']),
      isEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_enabled'])!,
      fontSize: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}font_size'])!,
      opacity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}opacity'])!,
      speed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed'])!,
      showTop: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_top'])!,
      showBottom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_bottom'])!,
      showScroll: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_scroll'])!,
    );
  }

  @override
  $DanmakuConfigsTableTable createAlias(String alias) {
    return $DanmakuConfigsTableTable(attachedDatabase, alias);
  }
}

class DanmakuConfigRow extends DataClass
    implements Insertable<DanmakuConfigRow> {
  final String id;
  final String name;
  final String url;
  final String? apiKey;
  final bool isEnabled;
  final double fontSize;
  final double opacity;
  final double speed;
  final bool showTop;
  final bool showBottom;
  final bool showScroll;
  const DanmakuConfigRow(
      {required this.id,
      required this.name,
      required this.url,
      this.apiKey,
      required this.isEnabled,
      required this.fontSize,
      required this.opacity,
      required this.speed,
      required this.showTop,
      required this.showBottom,
      required this.showScroll});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || apiKey != null) {
      map['api_key'] = Variable<String>(apiKey);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['font_size'] = Variable<double>(fontSize);
    map['opacity'] = Variable<double>(opacity);
    map['speed'] = Variable<double>(speed);
    map['show_top'] = Variable<bool>(showTop);
    map['show_bottom'] = Variable<bool>(showBottom);
    map['show_scroll'] = Variable<bool>(showScroll);
    return map;
  }

  DanmakuConfigsTableCompanion toCompanion(bool nullToAbsent) {
    return DanmakuConfigsTableCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      apiKey:
          apiKey == null && nullToAbsent ? const Value.absent() : Value(apiKey),
      isEnabled: Value(isEnabled),
      fontSize: Value(fontSize),
      opacity: Value(opacity),
      speed: Value(speed),
      showTop: Value(showTop),
      showBottom: Value(showBottom),
      showScroll: Value(showScroll),
    );
  }

  factory DanmakuConfigRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DanmakuConfigRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      apiKey: serializer.fromJson<String?>(json['apiKey']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      fontSize: serializer.fromJson<double>(json['fontSize']),
      opacity: serializer.fromJson<double>(json['opacity']),
      speed: serializer.fromJson<double>(json['speed']),
      showTop: serializer.fromJson<bool>(json['showTop']),
      showBottom: serializer.fromJson<bool>(json['showBottom']),
      showScroll: serializer.fromJson<bool>(json['showScroll']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'apiKey': serializer.toJson<String?>(apiKey),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'fontSize': serializer.toJson<double>(fontSize),
      'opacity': serializer.toJson<double>(opacity),
      'speed': serializer.toJson<double>(speed),
      'showTop': serializer.toJson<bool>(showTop),
      'showBottom': serializer.toJson<bool>(showBottom),
      'showScroll': serializer.toJson<bool>(showScroll),
    };
  }

  DanmakuConfigRow copyWith(
          {String? id,
          String? name,
          String? url,
          Value<String?> apiKey = const Value.absent(),
          bool? isEnabled,
          double? fontSize,
          double? opacity,
          double? speed,
          bool? showTop,
          bool? showBottom,
          bool? showScroll}) =>
      DanmakuConfigRow(
        id: id ?? this.id,
        name: name ?? this.name,
        url: url ?? this.url,
        apiKey: apiKey.present ? apiKey.value : this.apiKey,
        isEnabled: isEnabled ?? this.isEnabled,
        fontSize: fontSize ?? this.fontSize,
        opacity: opacity ?? this.opacity,
        speed: speed ?? this.speed,
        showTop: showTop ?? this.showTop,
        showBottom: showBottom ?? this.showBottom,
        showScroll: showScroll ?? this.showScroll,
      );
  DanmakuConfigRow copyWithCompanion(DanmakuConfigsTableCompanion data) {
    return DanmakuConfigRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      fontSize: data.fontSize.present ? data.fontSize.value : this.fontSize,
      opacity: data.opacity.present ? data.opacity.value : this.opacity,
      speed: data.speed.present ? data.speed.value : this.speed,
      showTop: data.showTop.present ? data.showTop.value : this.showTop,
      showBottom:
          data.showBottom.present ? data.showBottom.value : this.showBottom,
      showScroll:
          data.showScroll.present ? data.showScroll.value : this.showScroll,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DanmakuConfigRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('apiKey: $apiKey, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('fontSize: $fontSize, ')
          ..write('opacity: $opacity, ')
          ..write('speed: $speed, ')
          ..write('showTop: $showTop, ')
          ..write('showBottom: $showBottom, ')
          ..write('showScroll: $showScroll')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, url, apiKey, isEnabled, fontSize,
      opacity, speed, showTop, showBottom, showScroll);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DanmakuConfigRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.apiKey == this.apiKey &&
          other.isEnabled == this.isEnabled &&
          other.fontSize == this.fontSize &&
          other.opacity == this.opacity &&
          other.speed == this.speed &&
          other.showTop == this.showTop &&
          other.showBottom == this.showBottom &&
          other.showScroll == this.showScroll);
}

class DanmakuConfigsTableCompanion extends UpdateCompanion<DanmakuConfigRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> url;
  final Value<String?> apiKey;
  final Value<bool> isEnabled;
  final Value<double> fontSize;
  final Value<double> opacity;
  final Value<double> speed;
  final Value<bool> showTop;
  final Value<bool> showBottom;
  final Value<bool> showScroll;
  final Value<int> rowid;
  const DanmakuConfigsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.opacity = const Value.absent(),
    this.speed = const Value.absent(),
    this.showTop = const Value.absent(),
    this.showBottom = const Value.absent(),
    this.showScroll = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DanmakuConfigsTableCompanion.insert({
    required String id,
    required String name,
    required String url,
    this.apiKey = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.opacity = const Value.absent(),
    this.speed = const Value.absent(),
    this.showTop = const Value.absent(),
    this.showBottom = const Value.absent(),
    this.showScroll = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        url = Value(url);
  static Insertable<DanmakuConfigRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? apiKey,
    Expression<bool>? isEnabled,
    Expression<double>? fontSize,
    Expression<double>? opacity,
    Expression<double>? speed,
    Expression<bool>? showTop,
    Expression<bool>? showBottom,
    Expression<bool>? showScroll,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (apiKey != null) 'api_key': apiKey,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (fontSize != null) 'font_size': fontSize,
      if (opacity != null) 'opacity': opacity,
      if (speed != null) 'speed': speed,
      if (showTop != null) 'show_top': showTop,
      if (showBottom != null) 'show_bottom': showBottom,
      if (showScroll != null) 'show_scroll': showScroll,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DanmakuConfigsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? url,
      Value<String?>? apiKey,
      Value<bool>? isEnabled,
      Value<double>? fontSize,
      Value<double>? opacity,
      Value<double>? speed,
      Value<bool>? showTop,
      Value<bool>? showBottom,
      Value<bool>? showScroll,
      Value<int>? rowid}) {
    return DanmakuConfigsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      apiKey: apiKey ?? this.apiKey,
      isEnabled: isEnabled ?? this.isEnabled,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      speed: speed ?? this.speed,
      showTop: showTop ?? this.showTop,
      showBottom: showBottom ?? this.showBottom,
      showScroll: showScroll ?? this.showScroll,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (fontSize.present) {
      map['font_size'] = Variable<double>(fontSize.value);
    }
    if (opacity.present) {
      map['opacity'] = Variable<double>(opacity.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (showTop.present) {
      map['show_top'] = Variable<bool>(showTop.value);
    }
    if (showBottom.present) {
      map['show_bottom'] = Variable<bool>(showBottom.value);
    }
    if (showScroll.present) {
      map['show_scroll'] = Variable<bool>(showScroll.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DanmakuConfigsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('apiKey: $apiKey, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('fontSize: $fontSize, ')
          ..write('opacity: $opacity, ')
          ..write('speed: $speed, ')
          ..write('showTop: $showTop, ')
          ..write('showBottom: $showBottom, ')
          ..write('showScroll: $showScroll, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchHistoryTableTable extends WatchHistoryTable
    with TableInfo<$WatchHistoryTableTable, WatchHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterUrlMeta =
      const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
      'poster_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _backdropUrlMeta =
      const VerificationMeta('backdropUrl');
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
      'backdrop_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
      'progress', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _positionMsMeta =
      const VerificationMeta('positionMs');
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
      'position_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _seasonNumberMeta =
      const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
      'season_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _episodeNumberMeta =
      const VerificationMeta('episodeNumber');
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
      'episode_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _seriesTitleMeta =
      const VerificationMeta('seriesTitle');
  @override
  late final GeneratedColumn<String> seriesTitle = GeneratedColumn<String>(
      'series_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        posterUrl,
        backdropUrl,
        serverId,
        progress,
        positionMs,
        durationMs,
        seasonNumber,
        episodeNumber,
        seriesTitle,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history_table';
  @override
  VerificationContext validateIntegrity(Insertable<WatchHistoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta,
          posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(
          _backdropUrlMeta,
          backdropUrl.isAcceptableOrUnknown(
              data['backdrop_url']!, _backdropUrlMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('position_ms')) {
      context.handle(
          _positionMsMeta,
          positionMs.isAcceptableOrUnknown(
              data['position_ms']!, _positionMsMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('season_number')) {
      context.handle(
          _seasonNumberMeta,
          seasonNumber.isAcceptableOrUnknown(
              data['season_number']!, _seasonNumberMeta));
    }
    if (data.containsKey('episode_number')) {
      context.handle(
          _episodeNumberMeta,
          episodeNumber.isAcceptableOrUnknown(
              data['episode_number']!, _episodeNumberMeta));
    }
    if (data.containsKey('series_title')) {
      context.handle(
          _seriesTitleMeta,
          seriesTitle.isAcceptableOrUnknown(
              data['series_title']!, _seriesTitleMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_url'])!,
      backdropUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backdrop_url']),
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}progress'])!,
      positionMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position_ms'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      seasonNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_number']),
      episodeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_number']),
      seriesTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_title']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WatchHistoryTableTable createAlias(String alias) {
    return $WatchHistoryTableTable(attachedDatabase, alias);
  }
}

class WatchHistoryRow extends DataClass implements Insertable<WatchHistoryRow> {
  final String id;
  final String title;
  final String posterUrl;
  final String? backdropUrl;
  final String? serverId;
  final double progress;
  final int positionMs;
  final int durationMs;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? seriesTitle;
  final int updatedAt;
  const WatchHistoryRow(
      {required this.id,
      required this.title,
      required this.posterUrl,
      this.backdropUrl,
      this.serverId,
      required this.progress,
      required this.positionMs,
      required this.durationMs,
      this.seasonNumber,
      this.episodeNumber,
      this.seriesTitle,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['poster_url'] = Variable<String>(posterUrl);
    if (!nullToAbsent || backdropUrl != null) {
      map['backdrop_url'] = Variable<String>(backdropUrl);
    }
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['progress'] = Variable<double>(progress);
    map['position_ms'] = Variable<int>(positionMs);
    map['duration_ms'] = Variable<int>(durationMs);
    if (!nullToAbsent || seasonNumber != null) {
      map['season_number'] = Variable<int>(seasonNumber);
    }
    if (!nullToAbsent || episodeNumber != null) {
      map['episode_number'] = Variable<int>(episodeNumber);
    }
    if (!nullToAbsent || seriesTitle != null) {
      map['series_title'] = Variable<String>(seriesTitle);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  WatchHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryTableCompanion(
      id: Value(id),
      title: Value(title),
      posterUrl: Value(posterUrl),
      backdropUrl: backdropUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropUrl),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      progress: Value(progress),
      positionMs: Value(positionMs),
      durationMs: Value(durationMs),
      seasonNumber: seasonNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonNumber),
      episodeNumber: episodeNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeNumber),
      seriesTitle: seriesTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesTitle),
      updatedAt: Value(updatedAt),
    );
  }

  factory WatchHistoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      posterUrl: serializer.fromJson<String>(json['posterUrl']),
      backdropUrl: serializer.fromJson<String?>(json['backdropUrl']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      progress: serializer.fromJson<double>(json['progress']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      seasonNumber: serializer.fromJson<int?>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int?>(json['episodeNumber']),
      seriesTitle: serializer.fromJson<String?>(json['seriesTitle']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'posterUrl': serializer.toJson<String>(posterUrl),
      'backdropUrl': serializer.toJson<String?>(backdropUrl),
      'serverId': serializer.toJson<String?>(serverId),
      'progress': serializer.toJson<double>(progress),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'seasonNumber': serializer.toJson<int?>(seasonNumber),
      'episodeNumber': serializer.toJson<int?>(episodeNumber),
      'seriesTitle': serializer.toJson<String?>(seriesTitle),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  WatchHistoryRow copyWith(
          {String? id,
          String? title,
          String? posterUrl,
          Value<String?> backdropUrl = const Value.absent(),
          Value<String?> serverId = const Value.absent(),
          double? progress,
          int? positionMs,
          int? durationMs,
          Value<int?> seasonNumber = const Value.absent(),
          Value<int?> episodeNumber = const Value.absent(),
          Value<String?> seriesTitle = const Value.absent(),
          int? updatedAt}) =>
      WatchHistoryRow(
        id: id ?? this.id,
        title: title ?? this.title,
        posterUrl: posterUrl ?? this.posterUrl,
        backdropUrl: backdropUrl.present ? backdropUrl.value : this.backdropUrl,
        serverId: serverId.present ? serverId.value : this.serverId,
        progress: progress ?? this.progress,
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
        seasonNumber:
            seasonNumber.present ? seasonNumber.value : this.seasonNumber,
        episodeNumber:
            episodeNumber.present ? episodeNumber.value : this.episodeNumber,
        seriesTitle: seriesTitle.present ? seriesTitle.value : this.seriesTitle,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WatchHistoryRow copyWithCompanion(WatchHistoryTableCompanion data) {
    return WatchHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      backdropUrl:
          data.backdropUrl.present ? data.backdropUrl.value : this.backdropUrl,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      progress: data.progress.present ? data.progress.value : this.progress,
      positionMs:
          data.positionMs.present ? data.positionMs.value : this.positionMs,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      seriesTitle:
          data.seriesTitle.present ? data.seriesTitle.value : this.seriesTitle,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('serverId: $serverId, ')
          ..write('progress: $progress, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      posterUrl,
      backdropUrl,
      serverId,
      progress,
      positionMs,
      durationMs,
      seasonNumber,
      episodeNumber,
      seriesTitle,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.posterUrl == this.posterUrl &&
          other.backdropUrl == this.backdropUrl &&
          other.serverId == this.serverId &&
          other.progress == this.progress &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.seriesTitle == this.seriesTitle &&
          other.updatedAt == this.updatedAt);
}

class WatchHistoryTableCompanion extends UpdateCompanion<WatchHistoryRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> posterUrl;
  final Value<String?> backdropUrl;
  final Value<String?> serverId;
  final Value<double> progress;
  final Value<int> positionMs;
  final Value<int> durationMs;
  final Value<int?> seasonNumber;
  final Value<int?> episodeNumber;
  final Value<String?> seriesTitle;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const WatchHistoryTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.serverId = const Value.absent(),
    this.progress = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.seriesTitle = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchHistoryTableCompanion.insert({
    required String id,
    required String title,
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.serverId = const Value.absent(),
    this.progress = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.seriesTitle = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        updatedAt = Value(updatedAt);
  static Insertable<WatchHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<String>? backdropUrl,
    Expression<String>? serverId,
    Expression<double>? progress,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<String>? seriesTitle,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (serverId != null) 'server_id': serverId,
      if (progress != null) 'progress': progress,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (seriesTitle != null) 'series_title': seriesTitle,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchHistoryTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? posterUrl,
      Value<String?>? backdropUrl,
      Value<String?>? serverId,
      Value<double>? progress,
      Value<int>? positionMs,
      Value<int>? durationMs,
      Value<int?>? seasonNumber,
      Value<int?>? episodeNumber,
      Value<String?>? seriesTitle,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return WatchHistoryTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      serverId: serverId ?? this.serverId,
      progress: progress ?? this.progress,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      seriesTitle: seriesTitle ?? this.seriesTitle,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (seriesTitle.present) {
      map['series_title'] = Variable<String>(seriesTitle.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('serverId: $serverId, ')
          ..write('progress: $progress, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteMoviesTableTable extends FavoriteMoviesTable
    with TableInfo<$FavoriteMoviesTableTable, FavoriteMovieRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteMoviesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
      'tmdb_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterPathMeta =
      const VerificationMeta('posterPath');
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
      'poster_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _backdropPathMeta =
      const VerificationMeta('backdropPath');
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
      'backdrop_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _overviewMeta =
      const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
      'overview', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _voteAverageMeta =
      const VerificationMeta('voteAverage');
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
      'vote_average', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _releaseDateMeta =
      const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
      'release_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
      'added_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('movie'));
  @override
  List<GeneratedColumn> get $columns => [
        tmdbId,
        title,
        posterPath,
        backdropPath,
        overview,
        voteAverage,
        releaseDate,
        addedAt,
        type
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_movies_table';
  @override
  VerificationContext validateIntegrity(Insertable<FavoriteMovieRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta,
          tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_path')) {
      context.handle(
          _posterPathMeta,
          posterPath.isAcceptableOrUnknown(
              data['poster_path']!, _posterPathMeta));
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
          _backdropPathMeta,
          backdropPath.isAcceptableOrUnknown(
              data['backdrop_path']!, _backdropPathMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta,
          overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('vote_average')) {
      context.handle(
          _voteAverageMeta,
          voteAverage.isAcceptableOrUnknown(
              data['vote_average']!, _voteAverageMeta));
    }
    if (data.containsKey('release_date')) {
      context.handle(
          _releaseDateMeta,
          releaseDate.isAcceptableOrUnknown(
              data['release_date']!, _releaseDateMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  FavoriteMovieRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteMovieRow(
      tmdbId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tmdb_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_path']),
      backdropPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backdrop_path']),
      overview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}overview']),
      voteAverage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}vote_average']),
      releaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}release_date']),
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}added_at'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
    );
  }

  @override
  $FavoriteMoviesTableTable createAlias(String alias) {
    return $FavoriteMoviesTableTable(attachedDatabase, alias);
  }
}

class FavoriteMovieRow extends DataClass
    implements Insertable<FavoriteMovieRow> {
  final int tmdbId;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? voteAverage;
  final String? releaseDate;
  final int addedAt;
  final String type;
  const FavoriteMovieRow(
      {required this.tmdbId,
      required this.title,
      this.posterPath,
      this.backdropPath,
      this.overview,
      this.voteAverage,
      this.releaseDate,
      required this.addedAt,
      required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || voteAverage != null) {
      map['vote_average'] = Variable<double>(voteAverage);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    map['added_at'] = Variable<int>(addedAt);
    map['type'] = Variable<String>(type);
    return map;
  }

  FavoriteMoviesTableCompanion toCompanion(bool nullToAbsent) {
    return FavoriteMoviesTableCompanion(
      tmdbId: Value(tmdbId),
      title: Value(title),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      voteAverage: voteAverage == null && nullToAbsent
          ? const Value.absent()
          : Value(voteAverage),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      addedAt: Value(addedAt),
      type: Value(type),
    );
  }

  factory FavoriteMovieRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteMovieRow(
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      title: serializer.fromJson<String>(json['title']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
      overview: serializer.fromJson<String?>(json['overview']),
      voteAverage: serializer.fromJson<double?>(json['voteAverage']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tmdbId': serializer.toJson<int>(tmdbId),
      'title': serializer.toJson<String>(title),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
      'overview': serializer.toJson<String?>(overview),
      'voteAverage': serializer.toJson<double?>(voteAverage),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'addedAt': serializer.toJson<int>(addedAt),
      'type': serializer.toJson<String>(type),
    };
  }

  FavoriteMovieRow copyWith(
          {int? tmdbId,
          String? title,
          Value<String?> posterPath = const Value.absent(),
          Value<String?> backdropPath = const Value.absent(),
          Value<String?> overview = const Value.absent(),
          Value<double?> voteAverage = const Value.absent(),
          Value<String?> releaseDate = const Value.absent(),
          int? addedAt,
          String? type}) =>
      FavoriteMovieRow(
        tmdbId: tmdbId ?? this.tmdbId,
        title: title ?? this.title,
        posterPath: posterPath.present ? posterPath.value : this.posterPath,
        backdropPath:
            backdropPath.present ? backdropPath.value : this.backdropPath,
        overview: overview.present ? overview.value : this.overview,
        voteAverage: voteAverage.present ? voteAverage.value : this.voteAverage,
        releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
        addedAt: addedAt ?? this.addedAt,
        type: type ?? this.type,
      );
  FavoriteMovieRow copyWithCompanion(FavoriteMoviesTableCompanion data) {
    return FavoriteMovieRow(
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      title: data.title.present ? data.title.value : this.title,
      posterPath:
          data.posterPath.present ? data.posterPath.value : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
      overview: data.overview.present ? data.overview.value : this.overview,
      voteAverage:
          data.voteAverage.present ? data.voteAverage.value : this.voteAverage,
      releaseDate:
          data.releaseDate.present ? data.releaseDate.value : this.releaseDate,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteMovieRow(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('overview: $overview, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('addedAt: $addedAt, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tmdbId, title, posterPath, backdropPath,
      overview, voteAverage, releaseDate, addedAt, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteMovieRow &&
          other.tmdbId == this.tmdbId &&
          other.title == this.title &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath &&
          other.overview == this.overview &&
          other.voteAverage == this.voteAverage &&
          other.releaseDate == this.releaseDate &&
          other.addedAt == this.addedAt &&
          other.type == this.type);
}

class FavoriteMoviesTableCompanion extends UpdateCompanion<FavoriteMovieRow> {
  final Value<int> tmdbId;
  final Value<String> title;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<String?> overview;
  final Value<double?> voteAverage;
  final Value<String?> releaseDate;
  final Value<int> addedAt;
  final Value<String> type;
  const FavoriteMoviesTableCompanion({
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.type = const Value.absent(),
  });
  FavoriteMoviesTableCompanion.insert({
    this.tmdbId = const Value.absent(),
    required String title,
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.releaseDate = const Value.absent(),
    required int addedAt,
    this.type = const Value.absent(),
  })  : title = Value(title),
        addedAt = Value(addedAt);
  static Insertable<FavoriteMovieRow> custom({
    Expression<int>? tmdbId,
    Expression<String>? title,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<String>? overview,
    Expression<double>? voteAverage,
    Expression<String>? releaseDate,
    Expression<int>? addedAt,
    Expression<String>? type,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (overview != null) 'overview': overview,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (releaseDate != null) 'release_date': releaseDate,
      if (addedAt != null) 'added_at': addedAt,
      if (type != null) 'type': type,
    });
  }

  FavoriteMoviesTableCompanion copyWith(
      {Value<int>? tmdbId,
      Value<String>? title,
      Value<String?>? posterPath,
      Value<String?>? backdropPath,
      Value<String?>? overview,
      Value<double?>? voteAverage,
      Value<String?>? releaseDate,
      Value<int>? addedAt,
      Value<String>? type}) {
    return FavoriteMoviesTableCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
      addedAt: addedAt ?? this.addedAt,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteMoviesTableCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('overview: $overview, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('addedAt: $addedAt, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $WatchlistTableTable extends WatchlistTable
    with TableInfo<$WatchlistTableTable, WatchlistMovieRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchlistTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
      'tmdb_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterPathMeta =
      const VerificationMeta('posterPath');
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
      'poster_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _backdropPathMeta =
      const VerificationMeta('backdropPath');
  @override
  late final GeneratedColumn<String> backdropPath = GeneratedColumn<String>(
      'backdrop_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _overviewMeta =
      const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
      'overview', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _voteAverageMeta =
      const VerificationMeta('voteAverage');
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
      'vote_average', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _releaseDateMeta =
      const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
      'release_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
      'added_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('movie'));
  @override
  List<GeneratedColumn> get $columns => [
        tmdbId,
        title,
        posterPath,
        backdropPath,
        overview,
        voteAverage,
        releaseDate,
        addedAt,
        type
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watchlist_table';
  @override
  VerificationContext validateIntegrity(Insertable<WatchlistMovieRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta,
          tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_path')) {
      context.handle(
          _posterPathMeta,
          posterPath.isAcceptableOrUnknown(
              data['poster_path']!, _posterPathMeta));
    }
    if (data.containsKey('backdrop_path')) {
      context.handle(
          _backdropPathMeta,
          backdropPath.isAcceptableOrUnknown(
              data['backdrop_path']!, _backdropPathMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta,
          overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('vote_average')) {
      context.handle(
          _voteAverageMeta,
          voteAverage.isAcceptableOrUnknown(
              data['vote_average']!, _voteAverageMeta));
    }
    if (data.containsKey('release_date')) {
      context.handle(
          _releaseDateMeta,
          releaseDate.isAcceptableOrUnknown(
              data['release_date']!, _releaseDateMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  WatchlistMovieRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchlistMovieRow(
      tmdbId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tmdb_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_path']),
      backdropPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backdrop_path']),
      overview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}overview']),
      voteAverage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}vote_average']),
      releaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}release_date']),
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}added_at'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
    );
  }

  @override
  $WatchlistTableTable createAlias(String alias) {
    return $WatchlistTableTable(attachedDatabase, alias);
  }
}

class WatchlistMovieRow extends DataClass
    implements Insertable<WatchlistMovieRow> {
  final int tmdbId;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double? voteAverage;
  final String? releaseDate;
  final int addedAt;
  final String type;
  const WatchlistMovieRow(
      {required this.tmdbId,
      required this.title,
      this.posterPath,
      this.backdropPath,
      this.overview,
      this.voteAverage,
      this.releaseDate,
      required this.addedAt,
      required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || backdropPath != null) {
      map['backdrop_path'] = Variable<String>(backdropPath);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || voteAverage != null) {
      map['vote_average'] = Variable<double>(voteAverage);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    map['added_at'] = Variable<int>(addedAt);
    map['type'] = Variable<String>(type);
    return map;
  }

  WatchlistTableCompanion toCompanion(bool nullToAbsent) {
    return WatchlistTableCompanion(
      tmdbId: Value(tmdbId),
      title: Value(title),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      backdropPath: backdropPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropPath),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      voteAverage: voteAverage == null && nullToAbsent
          ? const Value.absent()
          : Value(voteAverage),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      addedAt: Value(addedAt),
      type: Value(type),
    );
  }

  factory WatchlistMovieRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchlistMovieRow(
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      title: serializer.fromJson<String>(json['title']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      backdropPath: serializer.fromJson<String?>(json['backdropPath']),
      overview: serializer.fromJson<String?>(json['overview']),
      voteAverage: serializer.fromJson<double?>(json['voteAverage']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tmdbId': serializer.toJson<int>(tmdbId),
      'title': serializer.toJson<String>(title),
      'posterPath': serializer.toJson<String?>(posterPath),
      'backdropPath': serializer.toJson<String?>(backdropPath),
      'overview': serializer.toJson<String?>(overview),
      'voteAverage': serializer.toJson<double?>(voteAverage),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'addedAt': serializer.toJson<int>(addedAt),
      'type': serializer.toJson<String>(type),
    };
  }

  WatchlistMovieRow copyWith(
          {int? tmdbId,
          String? title,
          Value<String?> posterPath = const Value.absent(),
          Value<String?> backdropPath = const Value.absent(),
          Value<String?> overview = const Value.absent(),
          Value<double?> voteAverage = const Value.absent(),
          Value<String?> releaseDate = const Value.absent(),
          int? addedAt,
          String? type}) =>
      WatchlistMovieRow(
        tmdbId: tmdbId ?? this.tmdbId,
        title: title ?? this.title,
        posterPath: posterPath.present ? posterPath.value : this.posterPath,
        backdropPath:
            backdropPath.present ? backdropPath.value : this.backdropPath,
        overview: overview.present ? overview.value : this.overview,
        voteAverage: voteAverage.present ? voteAverage.value : this.voteAverage,
        releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
        addedAt: addedAt ?? this.addedAt,
        type: type ?? this.type,
      );
  WatchlistMovieRow copyWithCompanion(WatchlistTableCompanion data) {
    return WatchlistMovieRow(
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      title: data.title.present ? data.title.value : this.title,
      posterPath:
          data.posterPath.present ? data.posterPath.value : this.posterPath,
      backdropPath: data.backdropPath.present
          ? data.backdropPath.value
          : this.backdropPath,
      overview: data.overview.present ? data.overview.value : this.overview,
      voteAverage:
          data.voteAverage.present ? data.voteAverage.value : this.voteAverage,
      releaseDate:
          data.releaseDate.present ? data.releaseDate.value : this.releaseDate,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistMovieRow(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('overview: $overview, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('addedAt: $addedAt, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tmdbId, title, posterPath, backdropPath,
      overview, voteAverage, releaseDate, addedAt, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchlistMovieRow &&
          other.tmdbId == this.tmdbId &&
          other.title == this.title &&
          other.posterPath == this.posterPath &&
          other.backdropPath == this.backdropPath &&
          other.overview == this.overview &&
          other.voteAverage == this.voteAverage &&
          other.releaseDate == this.releaseDate &&
          other.addedAt == this.addedAt &&
          other.type == this.type);
}

class WatchlistTableCompanion extends UpdateCompanion<WatchlistMovieRow> {
  final Value<int> tmdbId;
  final Value<String> title;
  final Value<String?> posterPath;
  final Value<String?> backdropPath;
  final Value<String?> overview;
  final Value<double?> voteAverage;
  final Value<String?> releaseDate;
  final Value<int> addedAt;
  final Value<String> type;
  const WatchlistTableCompanion({
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.type = const Value.absent(),
  });
  WatchlistTableCompanion.insert({
    this.tmdbId = const Value.absent(),
    required String title,
    this.posterPath = const Value.absent(),
    this.backdropPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.releaseDate = const Value.absent(),
    required int addedAt,
    this.type = const Value.absent(),
  })  : title = Value(title),
        addedAt = Value(addedAt);
  static Insertable<WatchlistMovieRow> custom({
    Expression<int>? tmdbId,
    Expression<String>? title,
    Expression<String>? posterPath,
    Expression<String>? backdropPath,
    Expression<String>? overview,
    Expression<double>? voteAverage,
    Expression<String>? releaseDate,
    Expression<int>? addedAt,
    Expression<String>? type,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (posterPath != null) 'poster_path': posterPath,
      if (backdropPath != null) 'backdrop_path': backdropPath,
      if (overview != null) 'overview': overview,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (releaseDate != null) 'release_date': releaseDate,
      if (addedAt != null) 'added_at': addedAt,
      if (type != null) 'type': type,
    });
  }

  WatchlistTableCompanion copyWith(
      {Value<int>? tmdbId,
      Value<String>? title,
      Value<String?>? posterPath,
      Value<String?>? backdropPath,
      Value<String?>? overview,
      Value<double?>? voteAverage,
      Value<String?>? releaseDate,
      Value<int>? addedAt,
      Value<String>? type}) {
    return WatchlistTableCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      overview: overview ?? this.overview,
      voteAverage: voteAverage ?? this.voteAverage,
      releaseDate: releaseDate ?? this.releaseDate,
      addedAt: addedAt ?? this.addedAt,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (backdropPath.present) {
      map['backdrop_path'] = Variable<String>(backdropPath.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistTableCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('posterPath: $posterPath, ')
          ..write('backdropPath: $backdropPath, ')
          ..write('overview: $overview, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('addedAt: $addedAt, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_table';
  @override
  VerificationContext validateIntegrity(Insertable<AppSettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingRow copyWith({String? key, String? value}) => AppSettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSettingRow copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsTableCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DanmakuSelectionsTableTable extends DanmakuSelectionsTable
    with TableInfo<$DanmakuSelectionsTableTable, DanmakuSelectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DanmakuSelectionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _episodeIdMeta =
      const VerificationMeta('episodeId');
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
      'episode_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [mediaId, episodeId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'danmaku_selections_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<DanmakuSelectionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(_episodeIdMeta,
          episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta));
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  DanmakuSelectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DanmakuSelectionRow(
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      episodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}episode_id'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DanmakuSelectionsTableTable createAlias(String alias) {
    return $DanmakuSelectionsTableTable(attachedDatabase, alias);
  }
}

class DanmakuSelectionRow extends DataClass
    implements Insertable<DanmakuSelectionRow> {
  final String mediaId;
  final String episodeId;
  final int updatedAt;
  const DanmakuSelectionRow(
      {required this.mediaId,
      required this.episodeId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    map['episode_id'] = Variable<String>(episodeId);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DanmakuSelectionsTableCompanion toCompanion(bool nullToAbsent) {
    return DanmakuSelectionsTableCompanion(
      mediaId: Value(mediaId),
      episodeId: Value(episodeId),
      updatedAt: Value(updatedAt),
    );
  }

  factory DanmakuSelectionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DanmakuSelectionRow(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'episodeId': serializer.toJson<String>(episodeId),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DanmakuSelectionRow copyWith(
          {String? mediaId, String? episodeId, int? updatedAt}) =>
      DanmakuSelectionRow(
        mediaId: mediaId ?? this.mediaId,
        episodeId: episodeId ?? this.episodeId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DanmakuSelectionRow copyWithCompanion(DanmakuSelectionsTableCompanion data) {
    return DanmakuSelectionRow(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DanmakuSelectionRow(')
          ..write('mediaId: $mediaId, ')
          ..write('episodeId: $episodeId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, episodeId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DanmakuSelectionRow &&
          other.mediaId == this.mediaId &&
          other.episodeId == this.episodeId &&
          other.updatedAt == this.updatedAt);
}

class DanmakuSelectionsTableCompanion
    extends UpdateCompanion<DanmakuSelectionRow> {
  final Value<String> mediaId;
  final Value<String> episodeId;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DanmakuSelectionsTableCompanion({
    this.mediaId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DanmakuSelectionsTableCompanion.insert({
    required String mediaId,
    required String episodeId,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : mediaId = Value(mediaId),
        episodeId = Value(episodeId),
        updatedAt = Value(updatedAt);
  static Insertable<DanmakuSelectionRow> custom({
    Expression<String>? mediaId,
    Expression<String>? episodeId,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (episodeId != null) 'episode_id': episodeId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DanmakuSelectionsTableCompanion copyWith(
      {Value<String>? mediaId,
      Value<String>? episodeId,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return DanmakuSelectionsTableCompanion(
      mediaId: mediaId ?? this.mediaId,
      episodeId: episodeId ?? this.episodeId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DanmakuSelectionsTableCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('episodeId: $episodeId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaLibrariesTableTable extends MediaLibrariesTable
    with TableInfo<$MediaLibrariesTableTable, MediaLibraryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaLibrariesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterUrlMeta =
      const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
      'poster_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('folder'));
  static const VerificationMeta _collectionTypeMeta =
      const VerificationMeta('collectionType');
  @override
  late final GeneratedColumn<String> collectionType = GeneratedColumn<String>(
      'collection_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, serverId, title, posterUrl, type, collectionType, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_libraries_table';
  @override
  VerificationContext validateIntegrity(Insertable<MediaLibraryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta,
          posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('collection_type')) {
      context.handle(
          _collectionTypeMeta,
          collectionType.isAcceptableOrUnknown(
              data['collection_type']!, _collectionTypeMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, id};
  @override
  MediaLibraryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaLibraryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_url'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      collectionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}collection_type']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $MediaLibrariesTableTable createAlias(String alias) {
    return $MediaLibrariesTableTable(attachedDatabase, alias);
  }
}

class MediaLibraryRow extends DataClass implements Insertable<MediaLibraryRow> {
  final String id;
  final String serverId;
  final String title;
  final String posterUrl;
  final String type;
  final String? collectionType;
  final int sortOrder;
  const MediaLibraryRow(
      {required this.id,
      required this.serverId,
      required this.title,
      required this.posterUrl,
      required this.type,
      this.collectionType,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server_id'] = Variable<String>(serverId);
    map['title'] = Variable<String>(title);
    map['poster_url'] = Variable<String>(posterUrl);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || collectionType != null) {
      map['collection_type'] = Variable<String>(collectionType);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  MediaLibrariesTableCompanion toCompanion(bool nullToAbsent) {
    return MediaLibrariesTableCompanion(
      id: Value(id),
      serverId: Value(serverId),
      title: Value(title),
      posterUrl: Value(posterUrl),
      type: Value(type),
      collectionType: collectionType == null && nullToAbsent
          ? const Value.absent()
          : Value(collectionType),
      sortOrder: Value(sortOrder),
    );
  }

  factory MediaLibraryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaLibraryRow(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      posterUrl: serializer.fromJson<String>(json['posterUrl']),
      type: serializer.fromJson<String>(json['type']),
      collectionType: serializer.fromJson<String?>(json['collectionType']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String>(serverId),
      'title': serializer.toJson<String>(title),
      'posterUrl': serializer.toJson<String>(posterUrl),
      'type': serializer.toJson<String>(type),
      'collectionType': serializer.toJson<String?>(collectionType),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  MediaLibraryRow copyWith(
          {String? id,
          String? serverId,
          String? title,
          String? posterUrl,
          String? type,
          Value<String?> collectionType = const Value.absent(),
          int? sortOrder}) =>
      MediaLibraryRow(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        title: title ?? this.title,
        posterUrl: posterUrl ?? this.posterUrl,
        type: type ?? this.type,
        collectionType:
            collectionType.present ? collectionType.value : this.collectionType,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  MediaLibraryRow copyWithCompanion(MediaLibrariesTableCompanion data) {
    return MediaLibraryRow(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      type: data.type.present ? data.type.value : this.type,
      collectionType: data.collectionType.present
          ? data.collectionType.value
          : this.collectionType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaLibraryRow(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('type: $type, ')
          ..write('collectionType: $collectionType, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, serverId, title, posterUrl, type, collectionType, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaLibraryRow &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.posterUrl == this.posterUrl &&
          other.type == this.type &&
          other.collectionType == this.collectionType &&
          other.sortOrder == this.sortOrder);
}

class MediaLibrariesTableCompanion extends UpdateCompanion<MediaLibraryRow> {
  final Value<String> id;
  final Value<String> serverId;
  final Value<String> title;
  final Value<String> posterUrl;
  final Value<String> type;
  final Value<String?> collectionType;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const MediaLibrariesTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.type = const Value.absent(),
    this.collectionType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaLibrariesTableCompanion.insert({
    required String id,
    required String serverId,
    required String title,
    this.posterUrl = const Value.absent(),
    this.type = const Value.absent(),
    this.collectionType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        serverId = Value(serverId),
        title = Value(title);
  static Insertable<MediaLibraryRow> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<String>? type,
    Expression<String>? collectionType,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (type != null) 'type': type,
      if (collectionType != null) 'collection_type': collectionType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaLibrariesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? serverId,
      Value<String>? title,
      Value<String>? posterUrl,
      Value<String>? type,
      Value<String?>? collectionType,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return MediaLibrariesTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      type: type ?? this.type,
      collectionType: collectionType ?? this.collectionType,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (collectionType.present) {
      map['collection_type'] = Variable<String>(collectionType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaLibrariesTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('type: $type, ')
          ..write('collectionType: $collectionType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTableTable extends MediaItemsTable
    with TableInfo<$MediaItemsTableTable, MediaItemCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _libraryIdMeta =
      const VerificationMeta('libraryId');
  @override
  late final GeneratedColumn<String> libraryId = GeneratedColumn<String>(
      'library_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterUrlMeta =
      const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
      'poster_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _backdropUrlMeta =
      const VerificationMeta('backdropUrl');
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
      'backdrop_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _logoUrlMeta =
      const VerificationMeta('logoUrl');
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
      'logo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _overviewMeta =
      const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
      'overview', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _releaseDateMeta =
      const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
      'release_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
      'genres', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('movie'));
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _imdbIdMeta = const VerificationMeta('imdbId');
  @override
  late final GeneratedColumn<String> imdbId = GeneratedColumn<String>(
      'imdb_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
      'tmdb_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _qualityMeta =
      const VerificationMeta('quality');
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
      'quality', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isWatchedMeta =
      const VerificationMeta('isWatched');
  @override
  late final GeneratedColumn<bool> isWatched = GeneratedColumn<bool>(
      'is_watched', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_watched" IN (0, 1))'));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_favorite" IN (0, 1))'));
  static const VerificationMeta _watchProgressMeta =
      const VerificationMeta('watchProgress');
  @override
  late final GeneratedColumn<double> watchProgress = GeneratedColumn<double>(
      'watch_progress', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sourcesMeta =
      const VerificationMeta('sources');
  @override
  late final GeneratedColumn<String> sources = GeneratedColumn<String>(
      'sources', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _directorMeta =
      const VerificationMeta('director');
  @override
  late final GeneratedColumn<String> director = GeneratedColumn<String>(
      'director', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _castMeta = const VerificationMeta('cast');
  @override
  late final GeneratedColumn<String> cast = GeneratedColumn<String>(
      'cast', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _videoTracksMeta =
      const VerificationMeta('videoTracks');
  @override
  late final GeneratedColumn<String> videoTracks = GeneratedColumn<String>(
      'video_tracks', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioTracksMeta =
      const VerificationMeta('audioTracks');
  @override
  late final GeneratedColumn<String> audioTracks = GeneratedColumn<String>(
      'audio_tracks', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subtitleTracksMeta =
      const VerificationMeta('subtitleTracks');
  @override
  late final GeneratedColumn<String> subtitleTracks = GeneratedColumn<String>(
      'subtitle_tracks', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _peopleMeta = const VerificationMeta('people');
  @override
  late final GeneratedColumn<String> people = GeneratedColumn<String>(
      'people', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _seasonNumberMeta =
      const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
      'season_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _episodeNumberMeta =
      const VerificationMeta('episodeNumber');
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
      'episode_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _seriesTitleMeta =
      const VerificationMeta('seriesTitle');
  @override
  late final GeneratedColumn<String> seriesTitle = GeneratedColumn<String>(
      'series_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalSeasonsMeta =
      const VerificationMeta('totalSeasons');
  @override
  late final GeneratedColumn<int> totalSeasons = GeneratedColumn<int>(
      'total_seasons', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalEpisodesMeta =
      const VerificationMeta('totalEpisodes');
  @override
  late final GeneratedColumn<int> totalEpisodes = GeneratedColumn<int>(
      'total_episodes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isBoxSetMeta =
      const VerificationMeta('isBoxSet');
  @override
  late final GeneratedColumn<bool> isBoxSet = GeneratedColumn<bool>(
      'is_box_set', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_box_set" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        serverId,
        libraryId,
        title,
        posterUrl,
        backdropUrl,
        logoUrl,
        overview,
        rating,
        year,
        releaseDate,
        genres,
        type,
        duration,
        imdbId,
        tmdbId,
        quality,
        isWatched,
        isFavorite,
        watchProgress,
        sources,
        director,
        cast,
        videoTracks,
        audioTracks,
        subtitleTracks,
        people,
        seasonNumber,
        episodeNumber,
        seriesTitle,
        totalSeasons,
        totalEpisodes,
        filePath,
        isBoxSet,
        sortOrder,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items_table';
  @override
  VerificationContext validateIntegrity(Insertable<MediaItemCacheRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('library_id')) {
      context.handle(_libraryIdMeta,
          libraryId.isAcceptableOrUnknown(data['library_id']!, _libraryIdMeta));
    } else if (isInserting) {
      context.missing(_libraryIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta,
          posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(
          _backdropUrlMeta,
          backdropUrl.isAcceptableOrUnknown(
              data['backdrop_url']!, _backdropUrlMeta));
    }
    if (data.containsKey('logo_url')) {
      context.handle(_logoUrlMeta,
          logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta,
          overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('release_date')) {
      context.handle(
          _releaseDateMeta,
          releaseDate.isAcceptableOrUnknown(
              data['release_date']!, _releaseDateMeta));
    }
    if (data.containsKey('genres')) {
      context.handle(_genresMeta,
          genres.isAcceptableOrUnknown(data['genres']!, _genresMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('imdb_id')) {
      context.handle(_imdbIdMeta,
          imdbId.isAcceptableOrUnknown(data['imdb_id']!, _imdbIdMeta));
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta,
          tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    }
    if (data.containsKey('quality')) {
      context.handle(_qualityMeta,
          quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta));
    }
    if (data.containsKey('is_watched')) {
      context.handle(_isWatchedMeta,
          isWatched.isAcceptableOrUnknown(data['is_watched']!, _isWatchedMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('watch_progress')) {
      context.handle(
          _watchProgressMeta,
          watchProgress.isAcceptableOrUnknown(
              data['watch_progress']!, _watchProgressMeta));
    }
    if (data.containsKey('sources')) {
      context.handle(_sourcesMeta,
          sources.isAcceptableOrUnknown(data['sources']!, _sourcesMeta));
    }
    if (data.containsKey('director')) {
      context.handle(_directorMeta,
          director.isAcceptableOrUnknown(data['director']!, _directorMeta));
    }
    if (data.containsKey('cast')) {
      context.handle(
          _castMeta, cast.isAcceptableOrUnknown(data['cast']!, _castMeta));
    }
    if (data.containsKey('video_tracks')) {
      context.handle(
          _videoTracksMeta,
          videoTracks.isAcceptableOrUnknown(
              data['video_tracks']!, _videoTracksMeta));
    }
    if (data.containsKey('audio_tracks')) {
      context.handle(
          _audioTracksMeta,
          audioTracks.isAcceptableOrUnknown(
              data['audio_tracks']!, _audioTracksMeta));
    }
    if (data.containsKey('subtitle_tracks')) {
      context.handle(
          _subtitleTracksMeta,
          subtitleTracks.isAcceptableOrUnknown(
              data['subtitle_tracks']!, _subtitleTracksMeta));
    }
    if (data.containsKey('people')) {
      context.handle(_peopleMeta,
          people.isAcceptableOrUnknown(data['people']!, _peopleMeta));
    }
    if (data.containsKey('season_number')) {
      context.handle(
          _seasonNumberMeta,
          seasonNumber.isAcceptableOrUnknown(
              data['season_number']!, _seasonNumberMeta));
    }
    if (data.containsKey('episode_number')) {
      context.handle(
          _episodeNumberMeta,
          episodeNumber.isAcceptableOrUnknown(
              data['episode_number']!, _episodeNumberMeta));
    }
    if (data.containsKey('series_title')) {
      context.handle(
          _seriesTitleMeta,
          seriesTitle.isAcceptableOrUnknown(
              data['series_title']!, _seriesTitleMeta));
    }
    if (data.containsKey('total_seasons')) {
      context.handle(
          _totalSeasonsMeta,
          totalSeasons.isAcceptableOrUnknown(
              data['total_seasons']!, _totalSeasonsMeta));
    }
    if (data.containsKey('total_episodes')) {
      context.handle(
          _totalEpisodesMeta,
          totalEpisodes.isAcceptableOrUnknown(
              data['total_episodes']!, _totalEpisodesMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('is_box_set')) {
      context.handle(_isBoxSetMeta,
          isBoxSet.isAcceptableOrUnknown(data['is_box_set']!, _isBoxSetMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, libraryId, id};
  @override
  MediaItemCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItemCacheRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      libraryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}library_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_url'])!,
      backdropUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backdrop_url']),
      logoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo_url']),
      overview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}overview']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year']),
      releaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}release_date']),
      genres: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genres'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      imdbId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}imdb_id']),
      tmdbId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tmdb_id']),
      quality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quality']),
      isWatched: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_watched']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite']),
      watchProgress: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}watch_progress']),
      sources: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sources'])!,
      director: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}director']),
      cast: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cast']),
      videoTracks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}video_tracks']),
      audioTracks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_tracks']),
      subtitleTracks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtitle_tracks']),
      people: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}people']),
      seasonNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_number']),
      episodeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_number']),
      seriesTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_title']),
      totalSeasons: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_seasons']),
      totalEpisodes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_episodes']),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path']),
      isBoxSet: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_box_set'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at']),
    );
  }

  @override
  $MediaItemsTableTable createAlias(String alias) {
    return $MediaItemsTableTable(attachedDatabase, alias);
  }
}

class MediaItemCacheRow extends DataClass
    implements Insertable<MediaItemCacheRow> {
  final String id;
  final String serverId;
  final String libraryId;
  final String title;
  final String posterUrl;
  final String? backdropUrl;
  final String? logoUrl;
  final String? overview;
  final double? rating;
  final int? year;
  final String? releaseDate;
  final String genres;
  final String type;
  final int duration;
  final String? imdbId;
  final int? tmdbId;
  final String? quality;
  final bool? isWatched;
  final bool? isFavorite;
  final double? watchProgress;
  final String sources;
  final String? director;
  final String? cast;
  final String? videoTracks;
  final String? audioTracks;
  final String? subtitleTracks;
  final String? people;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? seriesTitle;
  final int? totalSeasons;
  final int? totalEpisodes;
  final String? filePath;
  final bool isBoxSet;
  final int sortOrder;
  final int? cachedAt;
  const MediaItemCacheRow(
      {required this.id,
      required this.serverId,
      required this.libraryId,
      required this.title,
      required this.posterUrl,
      this.backdropUrl,
      this.logoUrl,
      this.overview,
      this.rating,
      this.year,
      this.releaseDate,
      required this.genres,
      required this.type,
      required this.duration,
      this.imdbId,
      this.tmdbId,
      this.quality,
      this.isWatched,
      this.isFavorite,
      this.watchProgress,
      required this.sources,
      this.director,
      this.cast,
      this.videoTracks,
      this.audioTracks,
      this.subtitleTracks,
      this.people,
      this.seasonNumber,
      this.episodeNumber,
      this.seriesTitle,
      this.totalSeasons,
      this.totalEpisodes,
      this.filePath,
      required this.isBoxSet,
      required this.sortOrder,
      this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server_id'] = Variable<String>(serverId);
    map['library_id'] = Variable<String>(libraryId);
    map['title'] = Variable<String>(title);
    map['poster_url'] = Variable<String>(posterUrl);
    if (!nullToAbsent || backdropUrl != null) {
      map['backdrop_url'] = Variable<String>(backdropUrl);
    }
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    map['genres'] = Variable<String>(genres);
    map['type'] = Variable<String>(type);
    map['duration'] = Variable<int>(duration);
    if (!nullToAbsent || imdbId != null) {
      map['imdb_id'] = Variable<String>(imdbId);
    }
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<int>(tmdbId);
    }
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<String>(quality);
    }
    if (!nullToAbsent || isWatched != null) {
      map['is_watched'] = Variable<bool>(isWatched);
    }
    if (!nullToAbsent || isFavorite != null) {
      map['is_favorite'] = Variable<bool>(isFavorite);
    }
    if (!nullToAbsent || watchProgress != null) {
      map['watch_progress'] = Variable<double>(watchProgress);
    }
    map['sources'] = Variable<String>(sources);
    if (!nullToAbsent || director != null) {
      map['director'] = Variable<String>(director);
    }
    if (!nullToAbsent || cast != null) {
      map['cast'] = Variable<String>(cast);
    }
    if (!nullToAbsent || videoTracks != null) {
      map['video_tracks'] = Variable<String>(videoTracks);
    }
    if (!nullToAbsent || audioTracks != null) {
      map['audio_tracks'] = Variable<String>(audioTracks);
    }
    if (!nullToAbsent || subtitleTracks != null) {
      map['subtitle_tracks'] = Variable<String>(subtitleTracks);
    }
    if (!nullToAbsent || people != null) {
      map['people'] = Variable<String>(people);
    }
    if (!nullToAbsent || seasonNumber != null) {
      map['season_number'] = Variable<int>(seasonNumber);
    }
    if (!nullToAbsent || episodeNumber != null) {
      map['episode_number'] = Variable<int>(episodeNumber);
    }
    if (!nullToAbsent || seriesTitle != null) {
      map['series_title'] = Variable<String>(seriesTitle);
    }
    if (!nullToAbsent || totalSeasons != null) {
      map['total_seasons'] = Variable<int>(totalSeasons);
    }
    if (!nullToAbsent || totalEpisodes != null) {
      map['total_episodes'] = Variable<int>(totalEpisodes);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    map['is_box_set'] = Variable<bool>(isBoxSet);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || cachedAt != null) {
      map['cached_at'] = Variable<int>(cachedAt);
    }
    return map;
  }

  MediaItemsTableCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsTableCompanion(
      id: Value(id),
      serverId: Value(serverId),
      libraryId: Value(libraryId),
      title: Value(title),
      posterUrl: Value(posterUrl),
      backdropUrl: backdropUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropUrl),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      genres: Value(genres),
      type: Value(type),
      duration: Value(duration),
      imdbId:
          imdbId == null && nullToAbsent ? const Value.absent() : Value(imdbId),
      tmdbId:
          tmdbId == null && nullToAbsent ? const Value.absent() : Value(tmdbId),
      quality: quality == null && nullToAbsent
          ? const Value.absent()
          : Value(quality),
      isWatched: isWatched == null && nullToAbsent
          ? const Value.absent()
          : Value(isWatched),
      isFavorite: isFavorite == null && nullToAbsent
          ? const Value.absent()
          : Value(isFavorite),
      watchProgress: watchProgress == null && nullToAbsent
          ? const Value.absent()
          : Value(watchProgress),
      sources: Value(sources),
      director: director == null && nullToAbsent
          ? const Value.absent()
          : Value(director),
      cast: cast == null && nullToAbsent ? const Value.absent() : Value(cast),
      videoTracks: videoTracks == null && nullToAbsent
          ? const Value.absent()
          : Value(videoTracks),
      audioTracks: audioTracks == null && nullToAbsent
          ? const Value.absent()
          : Value(audioTracks),
      subtitleTracks: subtitleTracks == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitleTracks),
      people:
          people == null && nullToAbsent ? const Value.absent() : Value(people),
      seasonNumber: seasonNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonNumber),
      episodeNumber: episodeNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeNumber),
      seriesTitle: seriesTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesTitle),
      totalSeasons: totalSeasons == null && nullToAbsent
          ? const Value.absent()
          : Value(totalSeasons),
      totalEpisodes: totalEpisodes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalEpisodes),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      isBoxSet: Value(isBoxSet),
      sortOrder: Value(sortOrder),
      cachedAt: cachedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedAt),
    );
  }

  factory MediaItemCacheRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItemCacheRow(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      libraryId: serializer.fromJson<String>(json['libraryId']),
      title: serializer.fromJson<String>(json['title']),
      posterUrl: serializer.fromJson<String>(json['posterUrl']),
      backdropUrl: serializer.fromJson<String?>(json['backdropUrl']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      overview: serializer.fromJson<String?>(json['overview']),
      rating: serializer.fromJson<double?>(json['rating']),
      year: serializer.fromJson<int?>(json['year']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      genres: serializer.fromJson<String>(json['genres']),
      type: serializer.fromJson<String>(json['type']),
      duration: serializer.fromJson<int>(json['duration']),
      imdbId: serializer.fromJson<String?>(json['imdbId']),
      tmdbId: serializer.fromJson<int?>(json['tmdbId']),
      quality: serializer.fromJson<String?>(json['quality']),
      isWatched: serializer.fromJson<bool?>(json['isWatched']),
      isFavorite: serializer.fromJson<bool?>(json['isFavorite']),
      watchProgress: serializer.fromJson<double?>(json['watchProgress']),
      sources: serializer.fromJson<String>(json['sources']),
      director: serializer.fromJson<String?>(json['director']),
      cast: serializer.fromJson<String?>(json['cast']),
      videoTracks: serializer.fromJson<String?>(json['videoTracks']),
      audioTracks: serializer.fromJson<String?>(json['audioTracks']),
      subtitleTracks: serializer.fromJson<String?>(json['subtitleTracks']),
      people: serializer.fromJson<String?>(json['people']),
      seasonNumber: serializer.fromJson<int?>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int?>(json['episodeNumber']),
      seriesTitle: serializer.fromJson<String?>(json['seriesTitle']),
      totalSeasons: serializer.fromJson<int?>(json['totalSeasons']),
      totalEpisodes: serializer.fromJson<int?>(json['totalEpisodes']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      isBoxSet: serializer.fromJson<bool>(json['isBoxSet']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      cachedAt: serializer.fromJson<int?>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String>(serverId),
      'libraryId': serializer.toJson<String>(libraryId),
      'title': serializer.toJson<String>(title),
      'posterUrl': serializer.toJson<String>(posterUrl),
      'backdropUrl': serializer.toJson<String?>(backdropUrl),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'overview': serializer.toJson<String?>(overview),
      'rating': serializer.toJson<double?>(rating),
      'year': serializer.toJson<int?>(year),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'genres': serializer.toJson<String>(genres),
      'type': serializer.toJson<String>(type),
      'duration': serializer.toJson<int>(duration),
      'imdbId': serializer.toJson<String?>(imdbId),
      'tmdbId': serializer.toJson<int?>(tmdbId),
      'quality': serializer.toJson<String?>(quality),
      'isWatched': serializer.toJson<bool?>(isWatched),
      'isFavorite': serializer.toJson<bool?>(isFavorite),
      'watchProgress': serializer.toJson<double?>(watchProgress),
      'sources': serializer.toJson<String>(sources),
      'director': serializer.toJson<String?>(director),
      'cast': serializer.toJson<String?>(cast),
      'videoTracks': serializer.toJson<String?>(videoTracks),
      'audioTracks': serializer.toJson<String?>(audioTracks),
      'subtitleTracks': serializer.toJson<String?>(subtitleTracks),
      'people': serializer.toJson<String?>(people),
      'seasonNumber': serializer.toJson<int?>(seasonNumber),
      'episodeNumber': serializer.toJson<int?>(episodeNumber),
      'seriesTitle': serializer.toJson<String?>(seriesTitle),
      'totalSeasons': serializer.toJson<int?>(totalSeasons),
      'totalEpisodes': serializer.toJson<int?>(totalEpisodes),
      'filePath': serializer.toJson<String?>(filePath),
      'isBoxSet': serializer.toJson<bool>(isBoxSet),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'cachedAt': serializer.toJson<int?>(cachedAt),
    };
  }

  MediaItemCacheRow copyWith(
          {String? id,
          String? serverId,
          String? libraryId,
          String? title,
          String? posterUrl,
          Value<String?> backdropUrl = const Value.absent(),
          Value<String?> logoUrl = const Value.absent(),
          Value<String?> overview = const Value.absent(),
          Value<double?> rating = const Value.absent(),
          Value<int?> year = const Value.absent(),
          Value<String?> releaseDate = const Value.absent(),
          String? genres,
          String? type,
          int? duration,
          Value<String?> imdbId = const Value.absent(),
          Value<int?> tmdbId = const Value.absent(),
          Value<String?> quality = const Value.absent(),
          Value<bool?> isWatched = const Value.absent(),
          Value<bool?> isFavorite = const Value.absent(),
          Value<double?> watchProgress = const Value.absent(),
          String? sources,
          Value<String?> director = const Value.absent(),
          Value<String?> cast = const Value.absent(),
          Value<String?> videoTracks = const Value.absent(),
          Value<String?> audioTracks = const Value.absent(),
          Value<String?> subtitleTracks = const Value.absent(),
          Value<String?> people = const Value.absent(),
          Value<int?> seasonNumber = const Value.absent(),
          Value<int?> episodeNumber = const Value.absent(),
          Value<String?> seriesTitle = const Value.absent(),
          Value<int?> totalSeasons = const Value.absent(),
          Value<int?> totalEpisodes = const Value.absent(),
          Value<String?> filePath = const Value.absent(),
          bool? isBoxSet,
          int? sortOrder,
          Value<int?> cachedAt = const Value.absent()}) =>
      MediaItemCacheRow(
        id: id ?? this.id,
        serverId: serverId ?? this.serverId,
        libraryId: libraryId ?? this.libraryId,
        title: title ?? this.title,
        posterUrl: posterUrl ?? this.posterUrl,
        backdropUrl: backdropUrl.present ? backdropUrl.value : this.backdropUrl,
        logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
        overview: overview.present ? overview.value : this.overview,
        rating: rating.present ? rating.value : this.rating,
        year: year.present ? year.value : this.year,
        releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
        genres: genres ?? this.genres,
        type: type ?? this.type,
        duration: duration ?? this.duration,
        imdbId: imdbId.present ? imdbId.value : this.imdbId,
        tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
        quality: quality.present ? quality.value : this.quality,
        isWatched: isWatched.present ? isWatched.value : this.isWatched,
        isFavorite: isFavorite.present ? isFavorite.value : this.isFavorite,
        watchProgress:
            watchProgress.present ? watchProgress.value : this.watchProgress,
        sources: sources ?? this.sources,
        director: director.present ? director.value : this.director,
        cast: cast.present ? cast.value : this.cast,
        videoTracks: videoTracks.present ? videoTracks.value : this.videoTracks,
        audioTracks: audioTracks.present ? audioTracks.value : this.audioTracks,
        subtitleTracks:
            subtitleTracks.present ? subtitleTracks.value : this.subtitleTracks,
        people: people.present ? people.value : this.people,
        seasonNumber:
            seasonNumber.present ? seasonNumber.value : this.seasonNumber,
        episodeNumber:
            episodeNumber.present ? episodeNumber.value : this.episodeNumber,
        seriesTitle: seriesTitle.present ? seriesTitle.value : this.seriesTitle,
        totalSeasons:
            totalSeasons.present ? totalSeasons.value : this.totalSeasons,
        totalEpisodes:
            totalEpisodes.present ? totalEpisodes.value : this.totalEpisodes,
        filePath: filePath.present ? filePath.value : this.filePath,
        isBoxSet: isBoxSet ?? this.isBoxSet,
        sortOrder: sortOrder ?? this.sortOrder,
        cachedAt: cachedAt.present ? cachedAt.value : this.cachedAt,
      );
  MediaItemCacheRow copyWithCompanion(MediaItemsTableCompanion data) {
    return MediaItemCacheRow(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      libraryId: data.libraryId.present ? data.libraryId.value : this.libraryId,
      title: data.title.present ? data.title.value : this.title,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      backdropUrl:
          data.backdropUrl.present ? data.backdropUrl.value : this.backdropUrl,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      overview: data.overview.present ? data.overview.value : this.overview,
      rating: data.rating.present ? data.rating.value : this.rating,
      year: data.year.present ? data.year.value : this.year,
      releaseDate:
          data.releaseDate.present ? data.releaseDate.value : this.releaseDate,
      genres: data.genres.present ? data.genres.value : this.genres,
      type: data.type.present ? data.type.value : this.type,
      duration: data.duration.present ? data.duration.value : this.duration,
      imdbId: data.imdbId.present ? data.imdbId.value : this.imdbId,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      quality: data.quality.present ? data.quality.value : this.quality,
      isWatched: data.isWatched.present ? data.isWatched.value : this.isWatched,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      watchProgress: data.watchProgress.present
          ? data.watchProgress.value
          : this.watchProgress,
      sources: data.sources.present ? data.sources.value : this.sources,
      director: data.director.present ? data.director.value : this.director,
      cast: data.cast.present ? data.cast.value : this.cast,
      videoTracks:
          data.videoTracks.present ? data.videoTracks.value : this.videoTracks,
      audioTracks:
          data.audioTracks.present ? data.audioTracks.value : this.audioTracks,
      subtitleTracks: data.subtitleTracks.present
          ? data.subtitleTracks.value
          : this.subtitleTracks,
      people: data.people.present ? data.people.value : this.people,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      seriesTitle:
          data.seriesTitle.present ? data.seriesTitle.value : this.seriesTitle,
      totalSeasons: data.totalSeasons.present
          ? data.totalSeasons.value
          : this.totalSeasons,
      totalEpisodes: data.totalEpisodes.present
          ? data.totalEpisodes.value
          : this.totalEpisodes,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      isBoxSet: data.isBoxSet.present ? data.isBoxSet.value : this.isBoxSet,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemCacheRow(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('libraryId: $libraryId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('overview: $overview, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('genres: $genres, ')
          ..write('type: $type, ')
          ..write('duration: $duration, ')
          ..write('imdbId: $imdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('quality: $quality, ')
          ..write('isWatched: $isWatched, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('watchProgress: $watchProgress, ')
          ..write('sources: $sources, ')
          ..write('director: $director, ')
          ..write('cast: $cast, ')
          ..write('videoTracks: $videoTracks, ')
          ..write('audioTracks: $audioTracks, ')
          ..write('subtitleTracks: $subtitleTracks, ')
          ..write('people: $people, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('totalSeasons: $totalSeasons, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('filePath: $filePath, ')
          ..write('isBoxSet: $isBoxSet, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        serverId,
        libraryId,
        title,
        posterUrl,
        backdropUrl,
        logoUrl,
        overview,
        rating,
        year,
        releaseDate,
        genres,
        type,
        duration,
        imdbId,
        tmdbId,
        quality,
        isWatched,
        isFavorite,
        watchProgress,
        sources,
        director,
        cast,
        videoTracks,
        audioTracks,
        subtitleTracks,
        people,
        seasonNumber,
        episodeNumber,
        seriesTitle,
        totalSeasons,
        totalEpisodes,
        filePath,
        isBoxSet,
        sortOrder,
        cachedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItemCacheRow &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.libraryId == this.libraryId &&
          other.title == this.title &&
          other.posterUrl == this.posterUrl &&
          other.backdropUrl == this.backdropUrl &&
          other.logoUrl == this.logoUrl &&
          other.overview == this.overview &&
          other.rating == this.rating &&
          other.year == this.year &&
          other.releaseDate == this.releaseDate &&
          other.genres == this.genres &&
          other.type == this.type &&
          other.duration == this.duration &&
          other.imdbId == this.imdbId &&
          other.tmdbId == this.tmdbId &&
          other.quality == this.quality &&
          other.isWatched == this.isWatched &&
          other.isFavorite == this.isFavorite &&
          other.watchProgress == this.watchProgress &&
          other.sources == this.sources &&
          other.director == this.director &&
          other.cast == this.cast &&
          other.videoTracks == this.videoTracks &&
          other.audioTracks == this.audioTracks &&
          other.subtitleTracks == this.subtitleTracks &&
          other.people == this.people &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.seriesTitle == this.seriesTitle &&
          other.totalSeasons == this.totalSeasons &&
          other.totalEpisodes == this.totalEpisodes &&
          other.filePath == this.filePath &&
          other.isBoxSet == this.isBoxSet &&
          other.sortOrder == this.sortOrder &&
          other.cachedAt == this.cachedAt);
}

class MediaItemsTableCompanion extends UpdateCompanion<MediaItemCacheRow> {
  final Value<String> id;
  final Value<String> serverId;
  final Value<String> libraryId;
  final Value<String> title;
  final Value<String> posterUrl;
  final Value<String?> backdropUrl;
  final Value<String?> logoUrl;
  final Value<String?> overview;
  final Value<double?> rating;
  final Value<int?> year;
  final Value<String?> releaseDate;
  final Value<String> genres;
  final Value<String> type;
  final Value<int> duration;
  final Value<String?> imdbId;
  final Value<int?> tmdbId;
  final Value<String?> quality;
  final Value<bool?> isWatched;
  final Value<bool?> isFavorite;
  final Value<double?> watchProgress;
  final Value<String> sources;
  final Value<String?> director;
  final Value<String?> cast;
  final Value<String?> videoTracks;
  final Value<String?> audioTracks;
  final Value<String?> subtitleTracks;
  final Value<String?> people;
  final Value<int?> seasonNumber;
  final Value<int?> episodeNumber;
  final Value<String?> seriesTitle;
  final Value<int?> totalSeasons;
  final Value<int?> totalEpisodes;
  final Value<String?> filePath;
  final Value<bool> isBoxSet;
  final Value<int> sortOrder;
  final Value<int?> cachedAt;
  final Value<int> rowid;
  const MediaItemsTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.libraryId = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.genres = const Value.absent(),
    this.type = const Value.absent(),
    this.duration = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.quality = const Value.absent(),
    this.isWatched = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.watchProgress = const Value.absent(),
    this.sources = const Value.absent(),
    this.director = const Value.absent(),
    this.cast = const Value.absent(),
    this.videoTracks = const Value.absent(),
    this.audioTracks = const Value.absent(),
    this.subtitleTracks = const Value.absent(),
    this.people = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.seriesTitle = const Value.absent(),
    this.totalSeasons = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.filePath = const Value.absent(),
    this.isBoxSet = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemsTableCompanion.insert({
    required String id,
    required String serverId,
    required String libraryId,
    required String title,
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.genres = const Value.absent(),
    this.type = const Value.absent(),
    this.duration = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.quality = const Value.absent(),
    this.isWatched = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.watchProgress = const Value.absent(),
    this.sources = const Value.absent(),
    this.director = const Value.absent(),
    this.cast = const Value.absent(),
    this.videoTracks = const Value.absent(),
    this.audioTracks = const Value.absent(),
    this.subtitleTracks = const Value.absent(),
    this.people = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.seriesTitle = const Value.absent(),
    this.totalSeasons = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.filePath = const Value.absent(),
    this.isBoxSet = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        serverId = Value(serverId),
        libraryId = Value(libraryId),
        title = Value(title);
  static Insertable<MediaItemCacheRow> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? libraryId,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<String>? backdropUrl,
    Expression<String>? logoUrl,
    Expression<String>? overview,
    Expression<double>? rating,
    Expression<int>? year,
    Expression<String>? releaseDate,
    Expression<String>? genres,
    Expression<String>? type,
    Expression<int>? duration,
    Expression<String>? imdbId,
    Expression<int>? tmdbId,
    Expression<String>? quality,
    Expression<bool>? isWatched,
    Expression<bool>? isFavorite,
    Expression<double>? watchProgress,
    Expression<String>? sources,
    Expression<String>? director,
    Expression<String>? cast,
    Expression<String>? videoTracks,
    Expression<String>? audioTracks,
    Expression<String>? subtitleTracks,
    Expression<String>? people,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<String>? seriesTitle,
    Expression<int>? totalSeasons,
    Expression<int>? totalEpisodes,
    Expression<String>? filePath,
    Expression<bool>? isBoxSet,
    Expression<int>? sortOrder,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (libraryId != null) 'library_id': libraryId,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (overview != null) 'overview': overview,
      if (rating != null) 'rating': rating,
      if (year != null) 'year': year,
      if (releaseDate != null) 'release_date': releaseDate,
      if (genres != null) 'genres': genres,
      if (type != null) 'type': type,
      if (duration != null) 'duration': duration,
      if (imdbId != null) 'imdb_id': imdbId,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (quality != null) 'quality': quality,
      if (isWatched != null) 'is_watched': isWatched,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (watchProgress != null) 'watch_progress': watchProgress,
      if (sources != null) 'sources': sources,
      if (director != null) 'director': director,
      if (cast != null) 'cast': cast,
      if (videoTracks != null) 'video_tracks': videoTracks,
      if (audioTracks != null) 'audio_tracks': audioTracks,
      if (subtitleTracks != null) 'subtitle_tracks': subtitleTracks,
      if (people != null) 'people': people,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (seriesTitle != null) 'series_title': seriesTitle,
      if (totalSeasons != null) 'total_seasons': totalSeasons,
      if (totalEpisodes != null) 'total_episodes': totalEpisodes,
      if (filePath != null) 'file_path': filePath,
      if (isBoxSet != null) 'is_box_set': isBoxSet,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? serverId,
      Value<String>? libraryId,
      Value<String>? title,
      Value<String>? posterUrl,
      Value<String?>? backdropUrl,
      Value<String?>? logoUrl,
      Value<String?>? overview,
      Value<double?>? rating,
      Value<int?>? year,
      Value<String?>? releaseDate,
      Value<String>? genres,
      Value<String>? type,
      Value<int>? duration,
      Value<String?>? imdbId,
      Value<int?>? tmdbId,
      Value<String?>? quality,
      Value<bool?>? isWatched,
      Value<bool?>? isFavorite,
      Value<double?>? watchProgress,
      Value<String>? sources,
      Value<String?>? director,
      Value<String?>? cast,
      Value<String?>? videoTracks,
      Value<String?>? audioTracks,
      Value<String?>? subtitleTracks,
      Value<String?>? people,
      Value<int?>? seasonNumber,
      Value<int?>? episodeNumber,
      Value<String?>? seriesTitle,
      Value<int?>? totalSeasons,
      Value<int?>? totalEpisodes,
      Value<String?>? filePath,
      Value<bool>? isBoxSet,
      Value<int>? sortOrder,
      Value<int?>? cachedAt,
      Value<int>? rowid}) {
    return MediaItemsTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      libraryId: libraryId ?? this.libraryId,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      overview: overview ?? this.overview,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      releaseDate: releaseDate ?? this.releaseDate,
      genres: genres ?? this.genres,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      imdbId: imdbId ?? this.imdbId,
      tmdbId: tmdbId ?? this.tmdbId,
      quality: quality ?? this.quality,
      isWatched: isWatched ?? this.isWatched,
      isFavorite: isFavorite ?? this.isFavorite,
      watchProgress: watchProgress ?? this.watchProgress,
      sources: sources ?? this.sources,
      director: director ?? this.director,
      cast: cast ?? this.cast,
      videoTracks: videoTracks ?? this.videoTracks,
      audioTracks: audioTracks ?? this.audioTracks,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      people: people ?? this.people,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      filePath: filePath ?? this.filePath,
      isBoxSet: isBoxSet ?? this.isBoxSet,
      sortOrder: sortOrder ?? this.sortOrder,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (libraryId.present) {
      map['library_id'] = Variable<String>(libraryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (imdbId.present) {
      map['imdb_id'] = Variable<String>(imdbId.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (isWatched.present) {
      map['is_watched'] = Variable<bool>(isWatched.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (watchProgress.present) {
      map['watch_progress'] = Variable<double>(watchProgress.value);
    }
    if (sources.present) {
      map['sources'] = Variable<String>(sources.value);
    }
    if (director.present) {
      map['director'] = Variable<String>(director.value);
    }
    if (cast.present) {
      map['cast'] = Variable<String>(cast.value);
    }
    if (videoTracks.present) {
      map['video_tracks'] = Variable<String>(videoTracks.value);
    }
    if (audioTracks.present) {
      map['audio_tracks'] = Variable<String>(audioTracks.value);
    }
    if (subtitleTracks.present) {
      map['subtitle_tracks'] = Variable<String>(subtitleTracks.value);
    }
    if (people.present) {
      map['people'] = Variable<String>(people.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (seriesTitle.present) {
      map['series_title'] = Variable<String>(seriesTitle.value);
    }
    if (totalSeasons.present) {
      map['total_seasons'] = Variable<int>(totalSeasons.value);
    }
    if (totalEpisodes.present) {
      map['total_episodes'] = Variable<int>(totalEpisodes.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (isBoxSet.present) {
      map['is_box_set'] = Variable<bool>(isBoxSet.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('libraryId: $libraryId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('overview: $overview, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('genres: $genres, ')
          ..write('type: $type, ')
          ..write('duration: $duration, ')
          ..write('imdbId: $imdbId, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('quality: $quality, ')
          ..write('isWatched: $isWatched, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('watchProgress: $watchProgress, ')
          ..write('sources: $sources, ')
          ..write('director: $director, ')
          ..write('cast: $cast, ')
          ..write('videoTracks: $videoTracks, ')
          ..write('audioTracks: $audioTracks, ')
          ..write('subtitleTracks: $subtitleTracks, ')
          ..write('people: $people, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('totalSeasons: $totalSeasons, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('filePath: $filePath, ')
          ..write('isBoxSet: $isBoxSet, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaCarouselTableTable extends MediaCarouselTable
    with TableInfo<$MediaCarouselTableTable, MediaCarouselRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaCarouselTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _itemJsonMeta =
      const VerificationMeta('itemJson');
  @override
  late final GeneratedColumn<String> itemJson = GeneratedColumn<String>(
      'item_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  List<GeneratedColumn> get $columns => [serverId, itemId, sortOrder, itemJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_carousel_table';
  @override
  VerificationContext validateIntegrity(Insertable<MediaCarouselRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('item_json')) {
      context.handle(_itemJsonMeta,
          itemJson.isAcceptableOrUnknown(data['item_json']!, _itemJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId, itemId};
  @override
  MediaCarouselRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaCarouselRow(
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      itemJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_json'])!,
    );
  }

  @override
  $MediaCarouselTableTable createAlias(String alias) {
    return $MediaCarouselTableTable(attachedDatabase, alias);
  }
}

class MediaCarouselRow extends DataClass
    implements Insertable<MediaCarouselRow> {
  final String serverId;
  final String itemId;
  final int sortOrder;
  final String itemJson;
  const MediaCarouselRow(
      {required this.serverId,
      required this.itemId,
      required this.sortOrder,
      required this.itemJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<String>(serverId);
    map['item_id'] = Variable<String>(itemId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['item_json'] = Variable<String>(itemJson);
    return map;
  }

  MediaCarouselTableCompanion toCompanion(bool nullToAbsent) {
    return MediaCarouselTableCompanion(
      serverId: Value(serverId),
      itemId: Value(itemId),
      sortOrder: Value(sortOrder),
      itemJson: Value(itemJson),
    );
  }

  factory MediaCarouselRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaCarouselRow(
      serverId: serializer.fromJson<String>(json['serverId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      itemJson: serializer.fromJson<String>(json['itemJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<String>(serverId),
      'itemId': serializer.toJson<String>(itemId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'itemJson': serializer.toJson<String>(itemJson),
    };
  }

  MediaCarouselRow copyWith(
          {String? serverId,
          String? itemId,
          int? sortOrder,
          String? itemJson}) =>
      MediaCarouselRow(
        serverId: serverId ?? this.serverId,
        itemId: itemId ?? this.itemId,
        sortOrder: sortOrder ?? this.sortOrder,
        itemJson: itemJson ?? this.itemJson,
      );
  MediaCarouselRow copyWithCompanion(MediaCarouselTableCompanion data) {
    return MediaCarouselRow(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      itemJson: data.itemJson.present ? data.itemJson.value : this.itemJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaCarouselRow(')
          ..write('serverId: $serverId, ')
          ..write('itemId: $itemId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('itemJson: $itemJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverId, itemId, sortOrder, itemJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaCarouselRow &&
          other.serverId == this.serverId &&
          other.itemId == this.itemId &&
          other.sortOrder == this.sortOrder &&
          other.itemJson == this.itemJson);
}

class MediaCarouselTableCompanion extends UpdateCompanion<MediaCarouselRow> {
  final Value<String> serverId;
  final Value<String> itemId;
  final Value<int> sortOrder;
  final Value<String> itemJson;
  final Value<int> rowid;
  const MediaCarouselTableCompanion({
    this.serverId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.itemJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaCarouselTableCompanion.insert({
    required String serverId,
    required String itemId,
    this.sortOrder = const Value.absent(),
    this.itemJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : serverId = Value(serverId),
        itemId = Value(itemId);
  static Insertable<MediaCarouselRow> custom({
    Expression<String>? serverId,
    Expression<String>? itemId,
    Expression<int>? sortOrder,
    Expression<String>? itemJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (itemId != null) 'item_id': itemId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (itemJson != null) 'item_json': itemJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaCarouselTableCompanion copyWith(
      {Value<String>? serverId,
      Value<String>? itemId,
      Value<int>? sortOrder,
      Value<String>? itemJson,
      Value<int>? rowid}) {
    return MediaCarouselTableCompanion(
      serverId: serverId ?? this.serverId,
      itemId: itemId ?? this.itemId,
      sortOrder: sortOrder ?? this.sortOrder,
      itemJson: itemJson ?? this.itemJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (itemJson.present) {
      map['item_json'] = Variable<String>(itemJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaCarouselTableCompanion(')
          ..write('serverId: $serverId, ')
          ..write('itemId: $itemId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('itemJson: $itemJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaCacheMetaTableTable extends MediaCacheMetaTable
    with TableInfo<$MediaCacheMetaTableTable, MediaCacheMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaCacheMetaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastRefreshTimeMeta =
      const VerificationMeta('lastRefreshTime');
  @override
  late final GeneratedColumn<int> lastRefreshTime = GeneratedColumn<int>(
      'last_refresh_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _carouselIdsMeta =
      const VerificationMeta('carouselIds');
  @override
  late final GeneratedColumn<String> carouselIds = GeneratedColumn<String>(
      'carousel_ids', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns =>
      [serverId, lastRefreshTime, carouselIds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_cache_meta_table';
  @override
  VerificationContext validateIntegrity(Insertable<MediaCacheMetaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('last_refresh_time')) {
      context.handle(
          _lastRefreshTimeMeta,
          lastRefreshTime.isAcceptableOrUnknown(
              data['last_refresh_time']!, _lastRefreshTimeMeta));
    }
    if (data.containsKey('carousel_ids')) {
      context.handle(
          _carouselIdsMeta,
          carouselIds.isAcceptableOrUnknown(
              data['carousel_ids']!, _carouselIdsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serverId};
  @override
  MediaCacheMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaCacheMetaRow(
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id'])!,
      lastRefreshTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_refresh_time']),
      carouselIds: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}carousel_ids'])!,
    );
  }

  @override
  $MediaCacheMetaTableTable createAlias(String alias) {
    return $MediaCacheMetaTableTable(attachedDatabase, alias);
  }
}

class MediaCacheMetaRow extends DataClass
    implements Insertable<MediaCacheMetaRow> {
  final String serverId;
  final int? lastRefreshTime;
  final String carouselIds;
  const MediaCacheMetaRow(
      {required this.serverId,
      this.lastRefreshTime,
      required this.carouselIds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['server_id'] = Variable<String>(serverId);
    if (!nullToAbsent || lastRefreshTime != null) {
      map['last_refresh_time'] = Variable<int>(lastRefreshTime);
    }
    map['carousel_ids'] = Variable<String>(carouselIds);
    return map;
  }

  MediaCacheMetaTableCompanion toCompanion(bool nullToAbsent) {
    return MediaCacheMetaTableCompanion(
      serverId: Value(serverId),
      lastRefreshTime: lastRefreshTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefreshTime),
      carouselIds: Value(carouselIds),
    );
  }

  factory MediaCacheMetaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaCacheMetaRow(
      serverId: serializer.fromJson<String>(json['serverId']),
      lastRefreshTime: serializer.fromJson<int?>(json['lastRefreshTime']),
      carouselIds: serializer.fromJson<String>(json['carouselIds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverId': serializer.toJson<String>(serverId),
      'lastRefreshTime': serializer.toJson<int?>(lastRefreshTime),
      'carouselIds': serializer.toJson<String>(carouselIds),
    };
  }

  MediaCacheMetaRow copyWith(
          {String? serverId,
          Value<int?> lastRefreshTime = const Value.absent(),
          String? carouselIds}) =>
      MediaCacheMetaRow(
        serverId: serverId ?? this.serverId,
        lastRefreshTime: lastRefreshTime.present
            ? lastRefreshTime.value
            : this.lastRefreshTime,
        carouselIds: carouselIds ?? this.carouselIds,
      );
  MediaCacheMetaRow copyWithCompanion(MediaCacheMetaTableCompanion data) {
    return MediaCacheMetaRow(
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      lastRefreshTime: data.lastRefreshTime.present
          ? data.lastRefreshTime.value
          : this.lastRefreshTime,
      carouselIds:
          data.carouselIds.present ? data.carouselIds.value : this.carouselIds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaCacheMetaRow(')
          ..write('serverId: $serverId, ')
          ..write('lastRefreshTime: $lastRefreshTime, ')
          ..write('carouselIds: $carouselIds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(serverId, lastRefreshTime, carouselIds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaCacheMetaRow &&
          other.serverId == this.serverId &&
          other.lastRefreshTime == this.lastRefreshTime &&
          other.carouselIds == this.carouselIds);
}

class MediaCacheMetaTableCompanion extends UpdateCompanion<MediaCacheMetaRow> {
  final Value<String> serverId;
  final Value<int?> lastRefreshTime;
  final Value<String> carouselIds;
  final Value<int> rowid;
  const MediaCacheMetaTableCompanion({
    this.serverId = const Value.absent(),
    this.lastRefreshTime = const Value.absent(),
    this.carouselIds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaCacheMetaTableCompanion.insert({
    required String serverId,
    this.lastRefreshTime = const Value.absent(),
    this.carouselIds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : serverId = Value(serverId);
  static Insertable<MediaCacheMetaRow> custom({
    Expression<String>? serverId,
    Expression<int>? lastRefreshTime,
    Expression<String>? carouselIds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverId != null) 'server_id': serverId,
      if (lastRefreshTime != null) 'last_refresh_time': lastRefreshTime,
      if (carouselIds != null) 'carousel_ids': carouselIds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaCacheMetaTableCompanion copyWith(
      {Value<String>? serverId,
      Value<int?>? lastRefreshTime,
      Value<String>? carouselIds,
      Value<int>? rowid}) {
    return MediaCacheMetaTableCompanion(
      serverId: serverId ?? this.serverId,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
      carouselIds: carouselIds ?? this.carouselIds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (lastRefreshTime.present) {
      map['last_refresh_time'] = Variable<int>(lastRefreshTime.value);
    }
    if (carouselIds.present) {
      map['carousel_ids'] = Variable<String>(carouselIds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaCacheMetaTableCompanion(')
          ..write('serverId: $serverId, ')
          ..write('lastRefreshTime: $lastRefreshTime, ')
          ..write('carouselIds: $carouselIds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DominantColorsTableTable extends DominantColorsTable
    with TableInfo<$DominantColorsTableTable, DominantColorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DominantColorsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [url, color, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dominant_colors_table';
  @override
  VerificationContext validateIntegrity(Insertable<DominantColorRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url};
  @override
  DominantColorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DominantColorRow(
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $DominantColorsTableTable createAlias(String alias) {
    return $DominantColorsTableTable(attachedDatabase, alias);
  }
}

class DominantColorRow extends DataClass
    implements Insertable<DominantColorRow> {
  final String url;
  final String color;
  final int cachedAt;
  const DominantColorRow(
      {required this.url, required this.color, required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['color'] = Variable<String>(color);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  DominantColorsTableCompanion toCompanion(bool nullToAbsent) {
    return DominantColorsTableCompanion(
      url: Value(url),
      color: Value(color),
      cachedAt: Value(cachedAt),
    );
  }

  factory DominantColorRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DominantColorRow(
      url: serializer.fromJson<String>(json['url']),
      color: serializer.fromJson<String>(json['color']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'color': serializer.toJson<String>(color),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  DominantColorRow copyWith({String? url, String? color, int? cachedAt}) =>
      DominantColorRow(
        url: url ?? this.url,
        color: color ?? this.color,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  DominantColorRow copyWithCompanion(DominantColorsTableCompanion data) {
    return DominantColorRow(
      url: data.url.present ? data.url.value : this.url,
      color: data.color.present ? data.color.value : this.color,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DominantColorRow(')
          ..write('url: $url, ')
          ..write('color: $color, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(url, color, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DominantColorRow &&
          other.url == this.url &&
          other.color == this.color &&
          other.cachedAt == this.cachedAt);
}

class DominantColorsTableCompanion extends UpdateCompanion<DominantColorRow> {
  final Value<String> url;
  final Value<String> color;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const DominantColorsTableCompanion({
    this.url = const Value.absent(),
    this.color = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DominantColorsTableCompanion.insert({
    required String url,
    required String color,
    required int cachedAt,
    this.rowid = const Value.absent(),
  })  : url = Value(url),
        color = Value(color),
        cachedAt = Value(cachedAt);
  static Insertable<DominantColorRow> custom({
    Expression<String>? url,
    Expression<String>? color,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (color != null) 'color': color,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DominantColorsTableCompanion copyWith(
      {Value<String>? url,
      Value<String>? color,
      Value<int>? cachedAt,
      Value<int>? rowid}) {
    return DominantColorsTableCompanion(
      url: url ?? this.url,
      color: color ?? this.color,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DominantColorsTableCompanion(')
          ..write('url: $url, ')
          ..write('color: $color, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DanmakuCacheTableTable extends DanmakuCacheTable
    with TableInfo<$DanmakuCacheTableTable, DanmakuCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DanmakuCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [cacheKey, data, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'danmaku_cache_table';
  @override
  VerificationContext validateIntegrity(Insertable<DanmakuCacheRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  DanmakuCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DanmakuCacheRow(
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $DanmakuCacheTableTable createAlias(String alias) {
    return $DanmakuCacheTableTable(attachedDatabase, alias);
  }
}

class DanmakuCacheRow extends DataClass implements Insertable<DanmakuCacheRow> {
  final String cacheKey;
  final String data;
  final int cachedAt;
  const DanmakuCacheRow(
      {required this.cacheKey, required this.data, required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['data'] = Variable<String>(data);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  DanmakuCacheTableCompanion toCompanion(bool nullToAbsent) {
    return DanmakuCacheTableCompanion(
      cacheKey: Value(cacheKey),
      data: Value(data),
      cachedAt: Value(cachedAt),
    );
  }

  factory DanmakuCacheRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DanmakuCacheRow(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      data: serializer.fromJson<String>(json['data']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'data': serializer.toJson<String>(data),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  DanmakuCacheRow copyWith({String? cacheKey, String? data, int? cachedAt}) =>
      DanmakuCacheRow(
        cacheKey: cacheKey ?? this.cacheKey,
        data: data ?? this.data,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  DanmakuCacheRow copyWithCompanion(DanmakuCacheTableCompanion data) {
    return DanmakuCacheRow(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      data: data.data.present ? data.data.value : this.data,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DanmakuCacheRow(')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, data, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DanmakuCacheRow &&
          other.cacheKey == this.cacheKey &&
          other.data == this.data &&
          other.cachedAt == this.cachedAt);
}

class DanmakuCacheTableCompanion extends UpdateCompanion<DanmakuCacheRow> {
  final Value<String> cacheKey;
  final Value<String> data;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const DanmakuCacheTableCompanion({
    this.cacheKey = const Value.absent(),
    this.data = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DanmakuCacheTableCompanion.insert({
    required String cacheKey,
    required String data,
    required int cachedAt,
    this.rowid = const Value.absent(),
  })  : cacheKey = Value(cacheKey),
        data = Value(data),
        cachedAt = Value(cachedAt);
  static Insertable<DanmakuCacheRow> custom({
    Expression<String>? cacheKey,
    Expression<String>? data,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (data != null) 'data': data,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DanmakuCacheTableCompanion copyWith(
      {Value<String>? cacheKey,
      Value<String>? data,
      Value<int>? cachedAt,
      Value<int>? rowid}) {
    return DanmakuCacheTableCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      data: data ?? this.data,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DanmakuCacheTableCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTableTable extends PlaylistTable
    with TableInfo<$PlaylistTableTable, PlaylistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _posterUrlMeta =
      const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
      'poster_url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _backdropUrlMeta =
      const VerificationMeta('backdropUrl');
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
      'backdrop_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _overviewMeta =
      const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
      'overview', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('movie'));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
      'added_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _seriesTitleMeta =
      const VerificationMeta('seriesTitle');
  @override
  late final GeneratedColumn<String> seriesTitle = GeneratedColumn<String>(
      'series_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _seasonNumberMeta =
      const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
      'season_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _episodeNumberMeta =
      const VerificationMeta('episodeNumber');
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
      'episode_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        itemId,
        title,
        posterUrl,
        backdropUrl,
        overview,
        rating,
        year,
        type,
        addedAt,
        seriesTitle,
        seasonNumber,
        episodeNumber
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_table';
  @override
  VerificationContext validateIntegrity(Insertable<PlaylistRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta,
          posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(
          _backdropUrlMeta,
          backdropUrl.isAcceptableOrUnknown(
              data['backdrop_url']!, _backdropUrlMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta,
          overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('series_title')) {
      context.handle(
          _seriesTitleMeta,
          seriesTitle.isAcceptableOrUnknown(
              data['series_title']!, _seriesTitleMeta));
    }
    if (data.containsKey('season_number')) {
      context.handle(
          _seasonNumberMeta,
          seasonNumber.isAcceptableOrUnknown(
              data['season_number']!, _seasonNumberMeta));
    }
    if (data.containsKey('episode_number')) {
      context.handle(
          _episodeNumberMeta,
          episodeNumber.isAcceptableOrUnknown(
              data['episode_number']!, _episodeNumberMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  PlaylistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistRow(
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poster_url'])!,
      backdropUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backdrop_url']),
      overview: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}overview']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}added_at'])!,
      seriesTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_title']),
      seasonNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_number']),
      episodeNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_number']),
    );
  }

  @override
  $PlaylistTableTable createAlias(String alias) {
    return $PlaylistTableTable(attachedDatabase, alias);
  }
}

class PlaylistRow extends DataClass implements Insertable<PlaylistRow> {
  final String itemId;
  final String title;
  final String posterUrl;
  final String? backdropUrl;
  final String? overview;
  final double? rating;
  final int? year;
  final String type;
  final int addedAt;
  final String? seriesTitle;
  final int? seasonNumber;
  final int? episodeNumber;
  const PlaylistRow(
      {required this.itemId,
      required this.title,
      required this.posterUrl,
      this.backdropUrl,
      this.overview,
      this.rating,
      this.year,
      required this.type,
      required this.addedAt,
      this.seriesTitle,
      this.seasonNumber,
      this.episodeNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['title'] = Variable<String>(title);
    map['poster_url'] = Variable<String>(posterUrl);
    if (!nullToAbsent || backdropUrl != null) {
      map['backdrop_url'] = Variable<String>(backdropUrl);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['type'] = Variable<String>(type);
    map['added_at'] = Variable<int>(addedAt);
    if (!nullToAbsent || seriesTitle != null) {
      map['series_title'] = Variable<String>(seriesTitle);
    }
    if (!nullToAbsent || seasonNumber != null) {
      map['season_number'] = Variable<int>(seasonNumber);
    }
    if (!nullToAbsent || episodeNumber != null) {
      map['episode_number'] = Variable<int>(episodeNumber);
    }
    return map;
  }

  PlaylistTableCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTableCompanion(
      itemId: Value(itemId),
      title: Value(title),
      posterUrl: Value(posterUrl),
      backdropUrl: backdropUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropUrl),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      type: Value(type),
      addedAt: Value(addedAt),
      seriesTitle: seriesTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesTitle),
      seasonNumber: seasonNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonNumber),
      episodeNumber: episodeNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeNumber),
    );
  }

  factory PlaylistRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistRow(
      itemId: serializer.fromJson<String>(json['itemId']),
      title: serializer.fromJson<String>(json['title']),
      posterUrl: serializer.fromJson<String>(json['posterUrl']),
      backdropUrl: serializer.fromJson<String?>(json['backdropUrl']),
      overview: serializer.fromJson<String?>(json['overview']),
      rating: serializer.fromJson<double?>(json['rating']),
      year: serializer.fromJson<int?>(json['year']),
      type: serializer.fromJson<String>(json['type']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      seriesTitle: serializer.fromJson<String?>(json['seriesTitle']),
      seasonNumber: serializer.fromJson<int?>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int?>(json['episodeNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'title': serializer.toJson<String>(title),
      'posterUrl': serializer.toJson<String>(posterUrl),
      'backdropUrl': serializer.toJson<String?>(backdropUrl),
      'overview': serializer.toJson<String?>(overview),
      'rating': serializer.toJson<double?>(rating),
      'year': serializer.toJson<int?>(year),
      'type': serializer.toJson<String>(type),
      'addedAt': serializer.toJson<int>(addedAt),
      'seriesTitle': serializer.toJson<String?>(seriesTitle),
      'seasonNumber': serializer.toJson<int?>(seasonNumber),
      'episodeNumber': serializer.toJson<int?>(episodeNumber),
    };
  }

  PlaylistRow copyWith(
          {String? itemId,
          String? title,
          String? posterUrl,
          Value<String?> backdropUrl = const Value.absent(),
          Value<String?> overview = const Value.absent(),
          Value<double?> rating = const Value.absent(),
          Value<int?> year = const Value.absent(),
          String? type,
          int? addedAt,
          Value<String?> seriesTitle = const Value.absent(),
          Value<int?> seasonNumber = const Value.absent(),
          Value<int?> episodeNumber = const Value.absent()}) =>
      PlaylistRow(
        itemId: itemId ?? this.itemId,
        title: title ?? this.title,
        posterUrl: posterUrl ?? this.posterUrl,
        backdropUrl: backdropUrl.present ? backdropUrl.value : this.backdropUrl,
        overview: overview.present ? overview.value : this.overview,
        rating: rating.present ? rating.value : this.rating,
        year: year.present ? year.value : this.year,
        type: type ?? this.type,
        addedAt: addedAt ?? this.addedAt,
        seriesTitle: seriesTitle.present ? seriesTitle.value : this.seriesTitle,
        seasonNumber:
            seasonNumber.present ? seasonNumber.value : this.seasonNumber,
        episodeNumber:
            episodeNumber.present ? episodeNumber.value : this.episodeNumber,
      );
  PlaylistRow copyWithCompanion(PlaylistTableCompanion data) {
    return PlaylistRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      title: data.title.present ? data.title.value : this.title,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      backdropUrl:
          data.backdropUrl.present ? data.backdropUrl.value : this.backdropUrl,
      overview: data.overview.present ? data.overview.value : this.overview,
      rating: data.rating.present ? data.rating.value : this.rating,
      year: data.year.present ? data.year.value : this.year,
      type: data.type.present ? data.type.value : this.type,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      seriesTitle:
          data.seriesTitle.present ? data.seriesTitle.value : this.seriesTitle,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRow(')
          ..write('itemId: $itemId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('overview: $overview, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('type: $type, ')
          ..write('addedAt: $addedAt, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      itemId,
      title,
      posterUrl,
      backdropUrl,
      overview,
      rating,
      year,
      type,
      addedAt,
      seriesTitle,
      seasonNumber,
      episodeNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistRow &&
          other.itemId == this.itemId &&
          other.title == this.title &&
          other.posterUrl == this.posterUrl &&
          other.backdropUrl == this.backdropUrl &&
          other.overview == this.overview &&
          other.rating == this.rating &&
          other.year == this.year &&
          other.type == this.type &&
          other.addedAt == this.addedAt &&
          other.seriesTitle == this.seriesTitle &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber);
}

class PlaylistTableCompanion extends UpdateCompanion<PlaylistRow> {
  final Value<String> itemId;
  final Value<String> title;
  final Value<String> posterUrl;
  final Value<String?> backdropUrl;
  final Value<String?> overview;
  final Value<double?> rating;
  final Value<int?> year;
  final Value<String> type;
  final Value<int> addedAt;
  final Value<String?> seriesTitle;
  final Value<int?> seasonNumber;
  final Value<int?> episodeNumber;
  final Value<int> rowid;
  const PlaylistTableCompanion({
    this.itemId = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.type = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.seriesTitle = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistTableCompanion.insert({
    required String itemId,
    required String title,
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.type = const Value.absent(),
    required int addedAt,
    this.seriesTitle = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        title = Value(title),
        addedAt = Value(addedAt);
  static Insertable<PlaylistRow> custom({
    Expression<String>? itemId,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<String>? backdropUrl,
    Expression<String>? overview,
    Expression<double>? rating,
    Expression<int>? year,
    Expression<String>? type,
    Expression<int>? addedAt,
    Expression<String>? seriesTitle,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (overview != null) 'overview': overview,
      if (rating != null) 'rating': rating,
      if (year != null) 'year': year,
      if (type != null) 'type': type,
      if (addedAt != null) 'added_at': addedAt,
      if (seriesTitle != null) 'series_title': seriesTitle,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistTableCompanion copyWith(
      {Value<String>? itemId,
      Value<String>? title,
      Value<String>? posterUrl,
      Value<String?>? backdropUrl,
      Value<String?>? overview,
      Value<double?>? rating,
      Value<int?>? year,
      Value<String>? type,
      Value<int>? addedAt,
      Value<String?>? seriesTitle,
      Value<int?>? seasonNumber,
      Value<int?>? episodeNumber,
      Value<int>? rowid}) {
    return PlaylistTableCompanion(
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      overview: overview ?? this.overview,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      type: type ?? this.type,
      addedAt: addedAt ?? this.addedAt,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (seriesTitle.present) {
      map['series_title'] = Variable<String>(seriesTitle.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTableCompanion(')
          ..write('itemId: $itemId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('overview: $overview, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('type: $type, ')
          ..write('addedAt: $addedAt, ')
          ..write('seriesTitle: $seriesTitle, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediaServersTableTable mediaServersTable =
      $MediaServersTableTable(this);
  late final $DanmakuConfigsTableTable danmakuConfigsTable =
      $DanmakuConfigsTableTable(this);
  late final $WatchHistoryTableTable watchHistoryTable =
      $WatchHistoryTableTable(this);
  late final $FavoriteMoviesTableTable favoriteMoviesTable =
      $FavoriteMoviesTableTable(this);
  late final $WatchlistTableTable watchlistTable = $WatchlistTableTable(this);
  late final $AppSettingsTableTable appSettingsTable =
      $AppSettingsTableTable(this);
  late final $DanmakuSelectionsTableTable danmakuSelectionsTable =
      $DanmakuSelectionsTableTable(this);
  late final $MediaLibrariesTableTable mediaLibrariesTable =
      $MediaLibrariesTableTable(this);
  late final $MediaItemsTableTable mediaItemsTable =
      $MediaItemsTableTable(this);
  late final $MediaCarouselTableTable mediaCarouselTable =
      $MediaCarouselTableTable(this);
  late final $MediaCacheMetaTableTable mediaCacheMetaTable =
      $MediaCacheMetaTableTable(this);
  late final $DominantColorsTableTable dominantColorsTable =
      $DominantColorsTableTable(this);
  late final $DanmakuCacheTableTable danmakuCacheTable =
      $DanmakuCacheTableTable(this);
  late final $PlaylistTableTable playlistTable = $PlaylistTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        mediaServersTable,
        danmakuConfigsTable,
        watchHistoryTable,
        favoriteMoviesTable,
        watchlistTable,
        appSettingsTable,
        danmakuSelectionsTable,
        mediaLibrariesTable,
        mediaItemsTable,
        mediaCarouselTable,
        mediaCacheMetaTable,
        dominantColorsTable,
        danmakuCacheTable,
        playlistTable
      ];
}

typedef $$MediaServersTableTableCreateCompanionBuilder
    = MediaServersTableCompanion Function({
  required String id,
  required String name,
  required String url,
  required String serverType,
  Value<String?> apiKey,
  Value<String?> username,
  Value<String?> password,
  Value<bool> isConnected,
  Value<bool> isDefault,
  Value<int> rowid,
});
typedef $$MediaServersTableTableUpdateCompanionBuilder
    = MediaServersTableCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> url,
  Value<String> serverType,
  Value<String?> apiKey,
  Value<String?> username,
  Value<String?> password,
  Value<bool> isConnected,
  Value<bool> isDefault,
  Value<int> rowid,
});

class $$MediaServersTableTableFilterComposer
    extends Composer<_$AppDatabase, $MediaServersTableTable> {
  $$MediaServersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<String, String, int> get serverType =>
      $composableBuilder(
          column: $table.serverType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isConnected => $composableBuilder(
      column: $table.isConnected, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));
}

class $$MediaServersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaServersTableTable> {
  $$MediaServersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverType => $composableBuilder(
      column: $table.serverType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isConnected => $composableBuilder(
      column: $table.isConnected, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));
}

class $$MediaServersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaServersTableTable> {
  $$MediaServersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumnWithTypeConverter<String, int> get serverType =>
      $composableBuilder(
          column: $table.serverType, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<bool> get isConnected => $composableBuilder(
      column: $table.isConnected, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$MediaServersTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaServersTableTable,
    MediaServerRow,
    $$MediaServersTableTableFilterComposer,
    $$MediaServersTableTableOrderingComposer,
    $$MediaServersTableTableAnnotationComposer,
    $$MediaServersTableTableCreateCompanionBuilder,
    $$MediaServersTableTableUpdateCompanionBuilder,
    (
      MediaServerRow,
      BaseReferences<_$AppDatabase, $MediaServersTableTable, MediaServerRow>
    ),
    MediaServerRow,
    PrefetchHooks Function()> {
  $$MediaServersTableTableTableManager(
      _$AppDatabase db, $MediaServersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaServersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaServersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaServersTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<String> serverType = const Value.absent(),
            Value<String?> apiKey = const Value.absent(),
            Value<String?> username = const Value.absent(),
            Value<String?> password = const Value.absent(),
            Value<bool> isConnected = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaServersTableCompanion(
            id: id,
            name: name,
            url: url,
            serverType: serverType,
            apiKey: apiKey,
            username: username,
            password: password,
            isConnected: isConnected,
            isDefault: isDefault,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String url,
            required String serverType,
            Value<String?> apiKey = const Value.absent(),
            Value<String?> username = const Value.absent(),
            Value<String?> password = const Value.absent(),
            Value<bool> isConnected = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaServersTableCompanion.insert(
            id: id,
            name: name,
            url: url,
            serverType: serverType,
            apiKey: apiKey,
            username: username,
            password: password,
            isConnected: isConnected,
            isDefault: isDefault,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaServersTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaServersTableTable,
    MediaServerRow,
    $$MediaServersTableTableFilterComposer,
    $$MediaServersTableTableOrderingComposer,
    $$MediaServersTableTableAnnotationComposer,
    $$MediaServersTableTableCreateCompanionBuilder,
    $$MediaServersTableTableUpdateCompanionBuilder,
    (
      MediaServerRow,
      BaseReferences<_$AppDatabase, $MediaServersTableTable, MediaServerRow>
    ),
    MediaServerRow,
    PrefetchHooks Function()>;
typedef $$DanmakuConfigsTableTableCreateCompanionBuilder
    = DanmakuConfigsTableCompanion Function({
  required String id,
  required String name,
  required String url,
  Value<String?> apiKey,
  Value<bool> isEnabled,
  Value<double> fontSize,
  Value<double> opacity,
  Value<double> speed,
  Value<bool> showTop,
  Value<bool> showBottom,
  Value<bool> showScroll,
  Value<int> rowid,
});
typedef $$DanmakuConfigsTableTableUpdateCompanionBuilder
    = DanmakuConfigsTableCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> url,
  Value<String?> apiKey,
  Value<bool> isEnabled,
  Value<double> fontSize,
  Value<double> opacity,
  Value<double> speed,
  Value<bool> showTop,
  Value<bool> showBottom,
  Value<bool> showScroll,
  Value<int> rowid,
});

class $$DanmakuConfigsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DanmakuConfigsTableTable> {
  $$DanmakuConfigsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fontSize => $composableBuilder(
      column: $table.fontSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get opacity => $composableBuilder(
      column: $table.opacity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showTop => $composableBuilder(
      column: $table.showTop, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showBottom => $composableBuilder(
      column: $table.showBottom, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showScroll => $composableBuilder(
      column: $table.showScroll, builder: (column) => ColumnFilters(column));
}

class $$DanmakuConfigsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DanmakuConfigsTableTable> {
  $$DanmakuConfigsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get apiKey => $composableBuilder(
      column: $table.apiKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fontSize => $composableBuilder(
      column: $table.fontSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get opacity => $composableBuilder(
      column: $table.opacity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showTop => $composableBuilder(
      column: $table.showTop, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showBottom => $composableBuilder(
      column: $table.showBottom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showScroll => $composableBuilder(
      column: $table.showScroll, builder: (column) => ColumnOrderings(column));
}

class $$DanmakuConfigsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DanmakuConfigsTableTable> {
  $$DanmakuConfigsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<double> get fontSize =>
      $composableBuilder(column: $table.fontSize, builder: (column) => column);

  GeneratedColumn<double> get opacity =>
      $composableBuilder(column: $table.opacity, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<bool> get showTop =>
      $composableBuilder(column: $table.showTop, builder: (column) => column);

  GeneratedColumn<bool> get showBottom => $composableBuilder(
      column: $table.showBottom, builder: (column) => column);

  GeneratedColumn<bool> get showScroll => $composableBuilder(
      column: $table.showScroll, builder: (column) => column);
}

class $$DanmakuConfigsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DanmakuConfigsTableTable,
    DanmakuConfigRow,
    $$DanmakuConfigsTableTableFilterComposer,
    $$DanmakuConfigsTableTableOrderingComposer,
    $$DanmakuConfigsTableTableAnnotationComposer,
    $$DanmakuConfigsTableTableCreateCompanionBuilder,
    $$DanmakuConfigsTableTableUpdateCompanionBuilder,
    (
      DanmakuConfigRow,
      BaseReferences<_$AppDatabase, $DanmakuConfigsTableTable, DanmakuConfigRow>
    ),
    DanmakuConfigRow,
    PrefetchHooks Function()> {
  $$DanmakuConfigsTableTableTableManager(
      _$AppDatabase db, $DanmakuConfigsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DanmakuConfigsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DanmakuConfigsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DanmakuConfigsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<String?> apiKey = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<double> fontSize = const Value.absent(),
            Value<double> opacity = const Value.absent(),
            Value<double> speed = const Value.absent(),
            Value<bool> showTop = const Value.absent(),
            Value<bool> showBottom = const Value.absent(),
            Value<bool> showScroll = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DanmakuConfigsTableCompanion(
            id: id,
            name: name,
            url: url,
            apiKey: apiKey,
            isEnabled: isEnabled,
            fontSize: fontSize,
            opacity: opacity,
            speed: speed,
            showTop: showTop,
            showBottom: showBottom,
            showScroll: showScroll,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String url,
            Value<String?> apiKey = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<double> fontSize = const Value.absent(),
            Value<double> opacity = const Value.absent(),
            Value<double> speed = const Value.absent(),
            Value<bool> showTop = const Value.absent(),
            Value<bool> showBottom = const Value.absent(),
            Value<bool> showScroll = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DanmakuConfigsTableCompanion.insert(
            id: id,
            name: name,
            url: url,
            apiKey: apiKey,
            isEnabled: isEnabled,
            fontSize: fontSize,
            opacity: opacity,
            speed: speed,
            showTop: showTop,
            showBottom: showBottom,
            showScroll: showScroll,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DanmakuConfigsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DanmakuConfigsTableTable,
    DanmakuConfigRow,
    $$DanmakuConfigsTableTableFilterComposer,
    $$DanmakuConfigsTableTableOrderingComposer,
    $$DanmakuConfigsTableTableAnnotationComposer,
    $$DanmakuConfigsTableTableCreateCompanionBuilder,
    $$DanmakuConfigsTableTableUpdateCompanionBuilder,
    (
      DanmakuConfigRow,
      BaseReferences<_$AppDatabase, $DanmakuConfigsTableTable, DanmakuConfigRow>
    ),
    DanmakuConfigRow,
    PrefetchHooks Function()>;
typedef $$WatchHistoryTableTableCreateCompanionBuilder
    = WatchHistoryTableCompanion Function({
  required String id,
  required String title,
  Value<String> posterUrl,
  Value<String?> backdropUrl,
  Value<String?> serverId,
  Value<double> progress,
  Value<int> positionMs,
  Value<int> durationMs,
  Value<int?> seasonNumber,
  Value<int?> episodeNumber,
  Value<String?> seriesTitle,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$WatchHistoryTableTableUpdateCompanionBuilder
    = WatchHistoryTableCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> posterUrl,
  Value<String?> backdropUrl,
  Value<String?> serverId,
  Value<double> progress,
  Value<int> positionMs,
  Value<int> durationMs,
  Value<int?> seasonNumber,
  Value<int?> episodeNumber,
  Value<String?> seriesTitle,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$WatchHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $WatchHistoryTableTable> {
  $$WatchHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl => $composableBuilder(
      column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WatchHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchHistoryTableTable> {
  $$WatchHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl => $composableBuilder(
      column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WatchHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchHistoryTableTable> {
  $$WatchHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => column);

  GeneratedColumn<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WatchHistoryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WatchHistoryTableTable,
    WatchHistoryRow,
    $$WatchHistoryTableTableFilterComposer,
    $$WatchHistoryTableTableOrderingComposer,
    $$WatchHistoryTableTableAnnotationComposer,
    $$WatchHistoryTableTableCreateCompanionBuilder,
    $$WatchHistoryTableTableUpdateCompanionBuilder,
    (
      WatchHistoryRow,
      BaseReferences<_$AppDatabase, $WatchHistoryTableTable, WatchHistoryRow>
    ),
    WatchHistoryRow,
    PrefetchHooks Function()> {
  $$WatchHistoryTableTableTableManager(
      _$AppDatabase db, $WatchHistoryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchHistoryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchHistoryTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> posterUrl = const Value.absent(),
            Value<String?> backdropUrl = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<int> positionMs = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<int?> seasonNumber = const Value.absent(),
            Value<int?> episodeNumber = const Value.absent(),
            Value<String?> seriesTitle = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WatchHistoryTableCompanion(
            id: id,
            title: title,
            posterUrl: posterUrl,
            backdropUrl: backdropUrl,
            serverId: serverId,
            progress: progress,
            positionMs: positionMs,
            durationMs: durationMs,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            seriesTitle: seriesTitle,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String> posterUrl = const Value.absent(),
            Value<String?> backdropUrl = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<int> positionMs = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<int?> seasonNumber = const Value.absent(),
            Value<int?> episodeNumber = const Value.absent(),
            Value<String?> seriesTitle = const Value.absent(),
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WatchHistoryTableCompanion.insert(
            id: id,
            title: title,
            posterUrl: posterUrl,
            backdropUrl: backdropUrl,
            serverId: serverId,
            progress: progress,
            positionMs: positionMs,
            durationMs: durationMs,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            seriesTitle: seriesTitle,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WatchHistoryTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WatchHistoryTableTable,
    WatchHistoryRow,
    $$WatchHistoryTableTableFilterComposer,
    $$WatchHistoryTableTableOrderingComposer,
    $$WatchHistoryTableTableAnnotationComposer,
    $$WatchHistoryTableTableCreateCompanionBuilder,
    $$WatchHistoryTableTableUpdateCompanionBuilder,
    (
      WatchHistoryRow,
      BaseReferences<_$AppDatabase, $WatchHistoryTableTable, WatchHistoryRow>
    ),
    WatchHistoryRow,
    PrefetchHooks Function()>;
typedef $$FavoriteMoviesTableTableCreateCompanionBuilder
    = FavoriteMoviesTableCompanion Function({
  Value<int> tmdbId,
  required String title,
  Value<String?> posterPath,
  Value<String?> backdropPath,
  Value<String?> overview,
  Value<double?> voteAverage,
  Value<String?> releaseDate,
  required int addedAt,
  Value<String> type,
});
typedef $$FavoriteMoviesTableTableUpdateCompanionBuilder
    = FavoriteMoviesTableCompanion Function({
  Value<int> tmdbId,
  Value<String> title,
  Value<String?> posterPath,
  Value<String?> backdropPath,
  Value<String?> overview,
  Value<double?> voteAverage,
  Value<String?> releaseDate,
  Value<int> addedAt,
  Value<String> type,
});

class $$FavoriteMoviesTableTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteMoviesTableTable> {
  $$FavoriteMoviesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropPath => $composableBuilder(
      column: $table.backdropPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));
}

class $$FavoriteMoviesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteMoviesTableTable> {
  $$FavoriteMoviesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropPath => $composableBuilder(
      column: $table.backdropPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));
}

class $$FavoriteMoviesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteMoviesTableTable> {
  $$FavoriteMoviesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => column);

  GeneratedColumn<String> get backdropPath => $composableBuilder(
      column: $table.backdropPath, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => column);

  GeneratedColumn<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$FavoriteMoviesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FavoriteMoviesTableTable,
    FavoriteMovieRow,
    $$FavoriteMoviesTableTableFilterComposer,
    $$FavoriteMoviesTableTableOrderingComposer,
    $$FavoriteMoviesTableTableAnnotationComposer,
    $$FavoriteMoviesTableTableCreateCompanionBuilder,
    $$FavoriteMoviesTableTableUpdateCompanionBuilder,
    (
      FavoriteMovieRow,
      BaseReferences<_$AppDatabase, $FavoriteMoviesTableTable, FavoriteMovieRow>
    ),
    FavoriteMovieRow,
    PrefetchHooks Function()> {
  $$FavoriteMoviesTableTableTableManager(
      _$AppDatabase db, $FavoriteMoviesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteMoviesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteMoviesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteMoviesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> tmdbId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> posterPath = const Value.absent(),
            Value<String?> backdropPath = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<double?> voteAverage = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            Value<int> addedAt = const Value.absent(),
            Value<String> type = const Value.absent(),
          }) =>
              FavoriteMoviesTableCompanion(
            tmdbId: tmdbId,
            title: title,
            posterPath: posterPath,
            backdropPath: backdropPath,
            overview: overview,
            voteAverage: voteAverage,
            releaseDate: releaseDate,
            addedAt: addedAt,
            type: type,
          ),
          createCompanionCallback: ({
            Value<int> tmdbId = const Value.absent(),
            required String title,
            Value<String?> posterPath = const Value.absent(),
            Value<String?> backdropPath = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<double?> voteAverage = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            required int addedAt,
            Value<String> type = const Value.absent(),
          }) =>
              FavoriteMoviesTableCompanion.insert(
            tmdbId: tmdbId,
            title: title,
            posterPath: posterPath,
            backdropPath: backdropPath,
            overview: overview,
            voteAverage: voteAverage,
            releaseDate: releaseDate,
            addedAt: addedAt,
            type: type,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FavoriteMoviesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FavoriteMoviesTableTable,
    FavoriteMovieRow,
    $$FavoriteMoviesTableTableFilterComposer,
    $$FavoriteMoviesTableTableOrderingComposer,
    $$FavoriteMoviesTableTableAnnotationComposer,
    $$FavoriteMoviesTableTableCreateCompanionBuilder,
    $$FavoriteMoviesTableTableUpdateCompanionBuilder,
    (
      FavoriteMovieRow,
      BaseReferences<_$AppDatabase, $FavoriteMoviesTableTable, FavoriteMovieRow>
    ),
    FavoriteMovieRow,
    PrefetchHooks Function()>;
typedef $$WatchlistTableTableCreateCompanionBuilder = WatchlistTableCompanion
    Function({
  Value<int> tmdbId,
  required String title,
  Value<String?> posterPath,
  Value<String?> backdropPath,
  Value<String?> overview,
  Value<double?> voteAverage,
  Value<String?> releaseDate,
  required int addedAt,
  Value<String> type,
});
typedef $$WatchlistTableTableUpdateCompanionBuilder = WatchlistTableCompanion
    Function({
  Value<int> tmdbId,
  Value<String> title,
  Value<String?> posterPath,
  Value<String?> backdropPath,
  Value<String?> overview,
  Value<double?> voteAverage,
  Value<String?> releaseDate,
  Value<int> addedAt,
  Value<String> type,
});

class $$WatchlistTableTableFilterComposer
    extends Composer<_$AppDatabase, $WatchlistTableTable> {
  $$WatchlistTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropPath => $composableBuilder(
      column: $table.backdropPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));
}

class $$WatchlistTableTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchlistTableTable> {
  $$WatchlistTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropPath => $composableBuilder(
      column: $table.backdropPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));
}

class $$WatchlistTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchlistTableTable> {
  $$WatchlistTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
      column: $table.posterPath, builder: (column) => column);

  GeneratedColumn<String> get backdropPath => $composableBuilder(
      column: $table.backdropPath, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<double> get voteAverage => $composableBuilder(
      column: $table.voteAverage, builder: (column) => column);

  GeneratedColumn<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$WatchlistTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WatchlistTableTable,
    WatchlistMovieRow,
    $$WatchlistTableTableFilterComposer,
    $$WatchlistTableTableOrderingComposer,
    $$WatchlistTableTableAnnotationComposer,
    $$WatchlistTableTableCreateCompanionBuilder,
    $$WatchlistTableTableUpdateCompanionBuilder,
    (
      WatchlistMovieRow,
      BaseReferences<_$AppDatabase, $WatchlistTableTable, WatchlistMovieRow>
    ),
    WatchlistMovieRow,
    PrefetchHooks Function()> {
  $$WatchlistTableTableTableManager(
      _$AppDatabase db, $WatchlistTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchlistTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchlistTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchlistTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> tmdbId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> posterPath = const Value.absent(),
            Value<String?> backdropPath = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<double?> voteAverage = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            Value<int> addedAt = const Value.absent(),
            Value<String> type = const Value.absent(),
          }) =>
              WatchlistTableCompanion(
            tmdbId: tmdbId,
            title: title,
            posterPath: posterPath,
            backdropPath: backdropPath,
            overview: overview,
            voteAverage: voteAverage,
            releaseDate: releaseDate,
            addedAt: addedAt,
            type: type,
          ),
          createCompanionCallback: ({
            Value<int> tmdbId = const Value.absent(),
            required String title,
            Value<String?> posterPath = const Value.absent(),
            Value<String?> backdropPath = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<double?> voteAverage = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            required int addedAt,
            Value<String> type = const Value.absent(),
          }) =>
              WatchlistTableCompanion.insert(
            tmdbId: tmdbId,
            title: title,
            posterPath: posterPath,
            backdropPath: backdropPath,
            overview: overview,
            voteAverage: voteAverage,
            releaseDate: releaseDate,
            addedAt: addedAt,
            type: type,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WatchlistTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WatchlistTableTable,
    WatchlistMovieRow,
    $$WatchlistTableTableFilterComposer,
    $$WatchlistTableTableOrderingComposer,
    $$WatchlistTableTableAnnotationComposer,
    $$WatchlistTableTableCreateCompanionBuilder,
    $$WatchlistTableTableUpdateCompanionBuilder,
    (
      WatchlistMovieRow,
      BaseReferences<_$AppDatabase, $WatchlistTableTable, WatchlistMovieRow>
    ),
    WatchlistMovieRow,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableTableCreateCompanionBuilder
    = AppSettingsTableCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppSettingsTableTableUpdateCompanionBuilder
    = AppSettingsTableCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTableTable,
    AppSettingRow,
    $$AppSettingsTableTableFilterComposer,
    $$AppSettingsTableTableOrderingComposer,
    $$AppSettingsTableTableAnnotationComposer,
    $$AppSettingsTableTableCreateCompanionBuilder,
    $$AppSettingsTableTableUpdateCompanionBuilder,
    (
      AppSettingRow,
      BaseReferences<_$AppDatabase, $AppSettingsTableTable, AppSettingRow>
    ),
    AppSettingRow,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableTableManager(
      _$AppDatabase db, $AppSettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsTableCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsTableCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTableTable,
    AppSettingRow,
    $$AppSettingsTableTableFilterComposer,
    $$AppSettingsTableTableOrderingComposer,
    $$AppSettingsTableTableAnnotationComposer,
    $$AppSettingsTableTableCreateCompanionBuilder,
    $$AppSettingsTableTableUpdateCompanionBuilder,
    (
      AppSettingRow,
      BaseReferences<_$AppDatabase, $AppSettingsTableTable, AppSettingRow>
    ),
    AppSettingRow,
    PrefetchHooks Function()>;
typedef $$DanmakuSelectionsTableTableCreateCompanionBuilder
    = DanmakuSelectionsTableCompanion Function({
  required String mediaId,
  required String episodeId,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$DanmakuSelectionsTableTableUpdateCompanionBuilder
    = DanmakuSelectionsTableCompanion Function({
  Value<String> mediaId,
  Value<String> episodeId,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$DanmakuSelectionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DanmakuSelectionsTableTable> {
  $$DanmakuSelectionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get episodeId => $composableBuilder(
      column: $table.episodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DanmakuSelectionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DanmakuSelectionsTableTable> {
  $$DanmakuSelectionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get episodeId => $composableBuilder(
      column: $table.episodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DanmakuSelectionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DanmakuSelectionsTableTable> {
  $$DanmakuSelectionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DanmakuSelectionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DanmakuSelectionsTableTable,
    DanmakuSelectionRow,
    $$DanmakuSelectionsTableTableFilterComposer,
    $$DanmakuSelectionsTableTableOrderingComposer,
    $$DanmakuSelectionsTableTableAnnotationComposer,
    $$DanmakuSelectionsTableTableCreateCompanionBuilder,
    $$DanmakuSelectionsTableTableUpdateCompanionBuilder,
    (
      DanmakuSelectionRow,
      BaseReferences<_$AppDatabase, $DanmakuSelectionsTableTable,
          DanmakuSelectionRow>
    ),
    DanmakuSelectionRow,
    PrefetchHooks Function()> {
  $$DanmakuSelectionsTableTableTableManager(
      _$AppDatabase db, $DanmakuSelectionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DanmakuSelectionsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$DanmakuSelectionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DanmakuSelectionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> mediaId = const Value.absent(),
            Value<String> episodeId = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DanmakuSelectionsTableCompanion(
            mediaId: mediaId,
            episodeId: episodeId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String mediaId,
            required String episodeId,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DanmakuSelectionsTableCompanion.insert(
            mediaId: mediaId,
            episodeId: episodeId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DanmakuSelectionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DanmakuSelectionsTableTable,
        DanmakuSelectionRow,
        $$DanmakuSelectionsTableTableFilterComposer,
        $$DanmakuSelectionsTableTableOrderingComposer,
        $$DanmakuSelectionsTableTableAnnotationComposer,
        $$DanmakuSelectionsTableTableCreateCompanionBuilder,
        $$DanmakuSelectionsTableTableUpdateCompanionBuilder,
        (
          DanmakuSelectionRow,
          BaseReferences<_$AppDatabase, $DanmakuSelectionsTableTable,
              DanmakuSelectionRow>
        ),
        DanmakuSelectionRow,
        PrefetchHooks Function()>;
typedef $$MediaLibrariesTableTableCreateCompanionBuilder
    = MediaLibrariesTableCompanion Function({
  required String id,
  required String serverId,
  required String title,
  Value<String> posterUrl,
  Value<String> type,
  Value<String?> collectionType,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$MediaLibrariesTableTableUpdateCompanionBuilder
    = MediaLibrariesTableCompanion Function({
  Value<String> id,
  Value<String> serverId,
  Value<String> title,
  Value<String> posterUrl,
  Value<String> type,
  Value<String?> collectionType,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$MediaLibrariesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MediaLibrariesTableTable> {
  $$MediaLibrariesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl => $composableBuilder(
      column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get collectionType => $composableBuilder(
      column: $table.collectionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$MediaLibrariesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaLibrariesTableTable> {
  $$MediaLibrariesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl => $composableBuilder(
      column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get collectionType => $composableBuilder(
      column: $table.collectionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$MediaLibrariesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaLibrariesTableTable> {
  $$MediaLibrariesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get collectionType => $composableBuilder(
      column: $table.collectionType, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$MediaLibrariesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaLibrariesTableTable,
    MediaLibraryRow,
    $$MediaLibrariesTableTableFilterComposer,
    $$MediaLibrariesTableTableOrderingComposer,
    $$MediaLibrariesTableTableAnnotationComposer,
    $$MediaLibrariesTableTableCreateCompanionBuilder,
    $$MediaLibrariesTableTableUpdateCompanionBuilder,
    (
      MediaLibraryRow,
      BaseReferences<_$AppDatabase, $MediaLibrariesTableTable, MediaLibraryRow>
    ),
    MediaLibraryRow,
    PrefetchHooks Function()> {
  $$MediaLibrariesTableTableTableManager(
      _$AppDatabase db, $MediaLibrariesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaLibrariesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaLibrariesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaLibrariesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> serverId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> posterUrl = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> collectionType = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaLibrariesTableCompanion(
            id: id,
            serverId: serverId,
            title: title,
            posterUrl: posterUrl,
            type: type,
            collectionType: collectionType,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String serverId,
            required String title,
            Value<String> posterUrl = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> collectionType = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaLibrariesTableCompanion.insert(
            id: id,
            serverId: serverId,
            title: title,
            posterUrl: posterUrl,
            type: type,
            collectionType: collectionType,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaLibrariesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaLibrariesTableTable,
    MediaLibraryRow,
    $$MediaLibrariesTableTableFilterComposer,
    $$MediaLibrariesTableTableOrderingComposer,
    $$MediaLibrariesTableTableAnnotationComposer,
    $$MediaLibrariesTableTableCreateCompanionBuilder,
    $$MediaLibrariesTableTableUpdateCompanionBuilder,
    (
      MediaLibraryRow,
      BaseReferences<_$AppDatabase, $MediaLibrariesTableTable, MediaLibraryRow>
    ),
    MediaLibraryRow,
    PrefetchHooks Function()>;
typedef $$MediaItemsTableTableCreateCompanionBuilder = MediaItemsTableCompanion
    Function({
  required String id,
  required String serverId,
  required String libraryId,
  required String title,
  Value<String> posterUrl,
  Value<String?> backdropUrl,
  Value<String?> logoUrl,
  Value<String?> overview,
  Value<double?> rating,
  Value<int?> year,
  Value<String?> releaseDate,
  Value<String> genres,
  Value<String> type,
  Value<int> duration,
  Value<String?> imdbId,
  Value<int?> tmdbId,
  Value<String?> quality,
  Value<bool?> isWatched,
  Value<bool?> isFavorite,
  Value<double?> watchProgress,
  Value<String> sources,
  Value<String?> director,
  Value<String?> cast,
  Value<String?> videoTracks,
  Value<String?> audioTracks,
  Value<String?> subtitleTracks,
  Value<String?> people,
  Value<int?> seasonNumber,
  Value<int?> episodeNumber,
  Value<String?> seriesTitle,
  Value<int?> totalSeasons,
  Value<int?> totalEpisodes,
  Value<String?> filePath,
  Value<bool> isBoxSet,
  Value<int> sortOrder,
  Value<int?> cachedAt,
  Value<int> rowid,
});
typedef $$MediaItemsTableTableUpdateCompanionBuilder = MediaItemsTableCompanion
    Function({
  Value<String> id,
  Value<String> serverId,
  Value<String> libraryId,
  Value<String> title,
  Value<String> posterUrl,
  Value<String?> backdropUrl,
  Value<String?> logoUrl,
  Value<String?> overview,
  Value<double?> rating,
  Value<int?> year,
  Value<String?> releaseDate,
  Value<String> genres,
  Value<String> type,
  Value<int> duration,
  Value<String?> imdbId,
  Value<int?> tmdbId,
  Value<String?> quality,
  Value<bool?> isWatched,
  Value<bool?> isFavorite,
  Value<double?> watchProgress,
  Value<String> sources,
  Value<String?> director,
  Value<String?> cast,
  Value<String?> videoTracks,
  Value<String?> audioTracks,
  Value<String?> subtitleTracks,
  Value<String?> people,
  Value<int?> seasonNumber,
  Value<int?> episodeNumber,
  Value<String?> seriesTitle,
  Value<int?> totalSeasons,
  Value<int?> totalEpisodes,
  Value<String?> filePath,
  Value<bool> isBoxSet,
  Value<int> sortOrder,
  Value<int?> cachedAt,
  Value<int> rowid,
});

class $$MediaItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTableTable> {
  $$MediaItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get libraryId => $composableBuilder(
      column: $table.libraryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl => $composableBuilder(
      column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logoUrl => $composableBuilder(
      column: $table.logoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genres => $composableBuilder(
      column: $table.genres, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imdbId => $composableBuilder(
      column: $table.imdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWatched => $composableBuilder(
      column: $table.isWatched, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get watchProgress => $composableBuilder(
      column: $table.watchProgress, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sources => $composableBuilder(
      column: $table.sources, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get director => $composableBuilder(
      column: $table.director, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cast => $composableBuilder(
      column: $table.cast, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get videoTracks => $composableBuilder(
      column: $table.videoTracks, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioTracks => $composableBuilder(
      column: $table.audioTracks, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subtitleTracks => $composableBuilder(
      column: $table.subtitleTracks,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get people => $composableBuilder(
      column: $table.people, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSeasons => $composableBuilder(
      column: $table.totalSeasons, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalEpisodes => $composableBuilder(
      column: $table.totalEpisodes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBoxSet => $composableBuilder(
      column: $table.isBoxSet, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$MediaItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTableTable> {
  $$MediaItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get libraryId => $composableBuilder(
      column: $table.libraryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl => $composableBuilder(
      column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logoUrl => $composableBuilder(
      column: $table.logoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genres => $composableBuilder(
      column: $table.genres, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imdbId => $composableBuilder(
      column: $table.imdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tmdbId => $composableBuilder(
      column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quality => $composableBuilder(
      column: $table.quality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWatched => $composableBuilder(
      column: $table.isWatched, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get watchProgress => $composableBuilder(
      column: $table.watchProgress,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sources => $composableBuilder(
      column: $table.sources, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get director => $composableBuilder(
      column: $table.director, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cast => $composableBuilder(
      column: $table.cast, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get videoTracks => $composableBuilder(
      column: $table.videoTracks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioTracks => $composableBuilder(
      column: $table.audioTracks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subtitleTracks => $composableBuilder(
      column: $table.subtitleTracks,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get people => $composableBuilder(
      column: $table.people, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSeasons => $composableBuilder(
      column: $table.totalSeasons,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalEpisodes => $composableBuilder(
      column: $table.totalEpisodes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBoxSet => $composableBuilder(
      column: $table.isBoxSet, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTableTable> {
  $$MediaItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get libraryId =>
      $composableBuilder(column: $table.libraryId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => column);

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get releaseDate => $composableBuilder(
      column: $table.releaseDate, builder: (column) => column);

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get imdbId =>
      $composableBuilder(column: $table.imdbId, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<bool> get isWatched =>
      $composableBuilder(column: $table.isWatched, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<double> get watchProgress => $composableBuilder(
      column: $table.watchProgress, builder: (column) => column);

  GeneratedColumn<String> get sources =>
      $composableBuilder(column: $table.sources, builder: (column) => column);

  GeneratedColumn<String> get director =>
      $composableBuilder(column: $table.director, builder: (column) => column);

  GeneratedColumn<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => column);

  GeneratedColumn<String> get videoTracks => $composableBuilder(
      column: $table.videoTracks, builder: (column) => column);

  GeneratedColumn<String> get audioTracks => $composableBuilder(
      column: $table.audioTracks, builder: (column) => column);

  GeneratedColumn<String> get subtitleTracks => $composableBuilder(
      column: $table.subtitleTracks, builder: (column) => column);

  GeneratedColumn<String> get people =>
      $composableBuilder(column: $table.people, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => column);

  GeneratedColumn<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => column);

  GeneratedColumn<int> get totalSeasons => $composableBuilder(
      column: $table.totalSeasons, builder: (column) => column);

  GeneratedColumn<int> get totalEpisodes => $composableBuilder(
      column: $table.totalEpisodes, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<bool> get isBoxSet =>
      $composableBuilder(column: $table.isBoxSet, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$MediaItemsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaItemsTableTable,
    MediaItemCacheRow,
    $$MediaItemsTableTableFilterComposer,
    $$MediaItemsTableTableOrderingComposer,
    $$MediaItemsTableTableAnnotationComposer,
    $$MediaItemsTableTableCreateCompanionBuilder,
    $$MediaItemsTableTableUpdateCompanionBuilder,
    (
      MediaItemCacheRow,
      BaseReferences<_$AppDatabase, $MediaItemsTableTable, MediaItemCacheRow>
    ),
    MediaItemCacheRow,
    PrefetchHooks Function()> {
  $$MediaItemsTableTableTableManager(
      _$AppDatabase db, $MediaItemsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> serverId = const Value.absent(),
            Value<String> libraryId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> posterUrl = const Value.absent(),
            Value<String?> backdropUrl = const Value.absent(),
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            Value<String> genres = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<String?> imdbId = const Value.absent(),
            Value<int?> tmdbId = const Value.absent(),
            Value<String?> quality = const Value.absent(),
            Value<bool?> isWatched = const Value.absent(),
            Value<bool?> isFavorite = const Value.absent(),
            Value<double?> watchProgress = const Value.absent(),
            Value<String> sources = const Value.absent(),
            Value<String?> director = const Value.absent(),
            Value<String?> cast = const Value.absent(),
            Value<String?> videoTracks = const Value.absent(),
            Value<String?> audioTracks = const Value.absent(),
            Value<String?> subtitleTracks = const Value.absent(),
            Value<String?> people = const Value.absent(),
            Value<int?> seasonNumber = const Value.absent(),
            Value<int?> episodeNumber = const Value.absent(),
            Value<String?> seriesTitle = const Value.absent(),
            Value<int?> totalSeasons = const Value.absent(),
            Value<int?> totalEpisodes = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<bool> isBoxSet = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaItemsTableCompanion(
            id: id,
            serverId: serverId,
            libraryId: libraryId,
            title: title,
            posterUrl: posterUrl,
            backdropUrl: backdropUrl,
            logoUrl: logoUrl,
            overview: overview,
            rating: rating,
            year: year,
            releaseDate: releaseDate,
            genres: genres,
            type: type,
            duration: duration,
            imdbId: imdbId,
            tmdbId: tmdbId,
            quality: quality,
            isWatched: isWatched,
            isFavorite: isFavorite,
            watchProgress: watchProgress,
            sources: sources,
            director: director,
            cast: cast,
            videoTracks: videoTracks,
            audioTracks: audioTracks,
            subtitleTracks: subtitleTracks,
            people: people,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            seriesTitle: seriesTitle,
            totalSeasons: totalSeasons,
            totalEpisodes: totalEpisodes,
            filePath: filePath,
            isBoxSet: isBoxSet,
            sortOrder: sortOrder,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String serverId,
            required String libraryId,
            required String title,
            Value<String> posterUrl = const Value.absent(),
            Value<String?> backdropUrl = const Value.absent(),
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            Value<String> genres = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<String?> imdbId = const Value.absent(),
            Value<int?> tmdbId = const Value.absent(),
            Value<String?> quality = const Value.absent(),
            Value<bool?> isWatched = const Value.absent(),
            Value<bool?> isFavorite = const Value.absent(),
            Value<double?> watchProgress = const Value.absent(),
            Value<String> sources = const Value.absent(),
            Value<String?> director = const Value.absent(),
            Value<String?> cast = const Value.absent(),
            Value<String?> videoTracks = const Value.absent(),
            Value<String?> audioTracks = const Value.absent(),
            Value<String?> subtitleTracks = const Value.absent(),
            Value<String?> people = const Value.absent(),
            Value<int?> seasonNumber = const Value.absent(),
            Value<int?> episodeNumber = const Value.absent(),
            Value<String?> seriesTitle = const Value.absent(),
            Value<int?> totalSeasons = const Value.absent(),
            Value<int?> totalEpisodes = const Value.absent(),
            Value<String?> filePath = const Value.absent(),
            Value<bool> isBoxSet = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaItemsTableCompanion.insert(
            id: id,
            serverId: serverId,
            libraryId: libraryId,
            title: title,
            posterUrl: posterUrl,
            backdropUrl: backdropUrl,
            logoUrl: logoUrl,
            overview: overview,
            rating: rating,
            year: year,
            releaseDate: releaseDate,
            genres: genres,
            type: type,
            duration: duration,
            imdbId: imdbId,
            tmdbId: tmdbId,
            quality: quality,
            isWatched: isWatched,
            isFavorite: isFavorite,
            watchProgress: watchProgress,
            sources: sources,
            director: director,
            cast: cast,
            videoTracks: videoTracks,
            audioTracks: audioTracks,
            subtitleTracks: subtitleTracks,
            people: people,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            seriesTitle: seriesTitle,
            totalSeasons: totalSeasons,
            totalEpisodes: totalEpisodes,
            filePath: filePath,
            isBoxSet: isBoxSet,
            sortOrder: sortOrder,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaItemsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaItemsTableTable,
    MediaItemCacheRow,
    $$MediaItemsTableTableFilterComposer,
    $$MediaItemsTableTableOrderingComposer,
    $$MediaItemsTableTableAnnotationComposer,
    $$MediaItemsTableTableCreateCompanionBuilder,
    $$MediaItemsTableTableUpdateCompanionBuilder,
    (
      MediaItemCacheRow,
      BaseReferences<_$AppDatabase, $MediaItemsTableTable, MediaItemCacheRow>
    ),
    MediaItemCacheRow,
    PrefetchHooks Function()>;
typedef $$MediaCarouselTableTableCreateCompanionBuilder
    = MediaCarouselTableCompanion Function({
  required String serverId,
  required String itemId,
  Value<int> sortOrder,
  Value<String> itemJson,
  Value<int> rowid,
});
typedef $$MediaCarouselTableTableUpdateCompanionBuilder
    = MediaCarouselTableCompanion Function({
  Value<String> serverId,
  Value<String> itemId,
  Value<int> sortOrder,
  Value<String> itemJson,
  Value<int> rowid,
});

class $$MediaCarouselTableTableFilterComposer
    extends Composer<_$AppDatabase, $MediaCarouselTableTable> {
  $$MediaCarouselTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemJson => $composableBuilder(
      column: $table.itemJson, builder: (column) => ColumnFilters(column));
}

class $$MediaCarouselTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaCarouselTableTable> {
  $$MediaCarouselTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemJson => $composableBuilder(
      column: $table.itemJson, builder: (column) => ColumnOrderings(column));
}

class $$MediaCarouselTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaCarouselTableTable> {
  $$MediaCarouselTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get itemJson =>
      $composableBuilder(column: $table.itemJson, builder: (column) => column);
}

class $$MediaCarouselTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaCarouselTableTable,
    MediaCarouselRow,
    $$MediaCarouselTableTableFilterComposer,
    $$MediaCarouselTableTableOrderingComposer,
    $$MediaCarouselTableTableAnnotationComposer,
    $$MediaCarouselTableTableCreateCompanionBuilder,
    $$MediaCarouselTableTableUpdateCompanionBuilder,
    (
      MediaCarouselRow,
      BaseReferences<_$AppDatabase, $MediaCarouselTableTable, MediaCarouselRow>
    ),
    MediaCarouselRow,
    PrefetchHooks Function()> {
  $$MediaCarouselTableTableTableManager(
      _$AppDatabase db, $MediaCarouselTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaCarouselTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaCarouselTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaCarouselTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> serverId = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> itemJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaCarouselTableCompanion(
            serverId: serverId,
            itemId: itemId,
            sortOrder: sortOrder,
            itemJson: itemJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String serverId,
            required String itemId,
            Value<int> sortOrder = const Value.absent(),
            Value<String> itemJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaCarouselTableCompanion.insert(
            serverId: serverId,
            itemId: itemId,
            sortOrder: sortOrder,
            itemJson: itemJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaCarouselTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaCarouselTableTable,
    MediaCarouselRow,
    $$MediaCarouselTableTableFilterComposer,
    $$MediaCarouselTableTableOrderingComposer,
    $$MediaCarouselTableTableAnnotationComposer,
    $$MediaCarouselTableTableCreateCompanionBuilder,
    $$MediaCarouselTableTableUpdateCompanionBuilder,
    (
      MediaCarouselRow,
      BaseReferences<_$AppDatabase, $MediaCarouselTableTable, MediaCarouselRow>
    ),
    MediaCarouselRow,
    PrefetchHooks Function()>;
typedef $$MediaCacheMetaTableTableCreateCompanionBuilder
    = MediaCacheMetaTableCompanion Function({
  required String serverId,
  Value<int?> lastRefreshTime,
  Value<String> carouselIds,
  Value<int> rowid,
});
typedef $$MediaCacheMetaTableTableUpdateCompanionBuilder
    = MediaCacheMetaTableCompanion Function({
  Value<String> serverId,
  Value<int?> lastRefreshTime,
  Value<String> carouselIds,
  Value<int> rowid,
});

class $$MediaCacheMetaTableTableFilterComposer
    extends Composer<_$AppDatabase, $MediaCacheMetaTableTable> {
  $$MediaCacheMetaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastRefreshTime => $composableBuilder(
      column: $table.lastRefreshTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get carouselIds => $composableBuilder(
      column: $table.carouselIds, builder: (column) => ColumnFilters(column));
}

class $$MediaCacheMetaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaCacheMetaTableTable> {
  $$MediaCacheMetaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastRefreshTime => $composableBuilder(
      column: $table.lastRefreshTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get carouselIds => $composableBuilder(
      column: $table.carouselIds, builder: (column) => ColumnOrderings(column));
}

class $$MediaCacheMetaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaCacheMetaTableTable> {
  $$MediaCacheMetaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get lastRefreshTime => $composableBuilder(
      column: $table.lastRefreshTime, builder: (column) => column);

  GeneratedColumn<String> get carouselIds => $composableBuilder(
      column: $table.carouselIds, builder: (column) => column);
}

class $$MediaCacheMetaTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaCacheMetaTableTable,
    MediaCacheMetaRow,
    $$MediaCacheMetaTableTableFilterComposer,
    $$MediaCacheMetaTableTableOrderingComposer,
    $$MediaCacheMetaTableTableAnnotationComposer,
    $$MediaCacheMetaTableTableCreateCompanionBuilder,
    $$MediaCacheMetaTableTableUpdateCompanionBuilder,
    (
      MediaCacheMetaRow,
      BaseReferences<_$AppDatabase, $MediaCacheMetaTableTable,
          MediaCacheMetaRow>
    ),
    MediaCacheMetaRow,
    PrefetchHooks Function()> {
  $$MediaCacheMetaTableTableTableManager(
      _$AppDatabase db, $MediaCacheMetaTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaCacheMetaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaCacheMetaTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaCacheMetaTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> serverId = const Value.absent(),
            Value<int?> lastRefreshTime = const Value.absent(),
            Value<String> carouselIds = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaCacheMetaTableCompanion(
            serverId: serverId,
            lastRefreshTime: lastRefreshTime,
            carouselIds: carouselIds,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String serverId,
            Value<int?> lastRefreshTime = const Value.absent(),
            Value<String> carouselIds = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaCacheMetaTableCompanion.insert(
            serverId: serverId,
            lastRefreshTime: lastRefreshTime,
            carouselIds: carouselIds,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaCacheMetaTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaCacheMetaTableTable,
    MediaCacheMetaRow,
    $$MediaCacheMetaTableTableFilterComposer,
    $$MediaCacheMetaTableTableOrderingComposer,
    $$MediaCacheMetaTableTableAnnotationComposer,
    $$MediaCacheMetaTableTableCreateCompanionBuilder,
    $$MediaCacheMetaTableTableUpdateCompanionBuilder,
    (
      MediaCacheMetaRow,
      BaseReferences<_$AppDatabase, $MediaCacheMetaTableTable,
          MediaCacheMetaRow>
    ),
    MediaCacheMetaRow,
    PrefetchHooks Function()>;
typedef $$DominantColorsTableTableCreateCompanionBuilder
    = DominantColorsTableCompanion Function({
  required String url,
  required String color,
  required int cachedAt,
  Value<int> rowid,
});
typedef $$DominantColorsTableTableUpdateCompanionBuilder
    = DominantColorsTableCompanion Function({
  Value<String> url,
  Value<String> color,
  Value<int> cachedAt,
  Value<int> rowid,
});

class $$DominantColorsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DominantColorsTableTable> {
  $$DominantColorsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$DominantColorsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DominantColorsTableTable> {
  $$DominantColorsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$DominantColorsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DominantColorsTableTable> {
  $$DominantColorsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$DominantColorsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DominantColorsTableTable,
    DominantColorRow,
    $$DominantColorsTableTableFilterComposer,
    $$DominantColorsTableTableOrderingComposer,
    $$DominantColorsTableTableAnnotationComposer,
    $$DominantColorsTableTableCreateCompanionBuilder,
    $$DominantColorsTableTableUpdateCompanionBuilder,
    (
      DominantColorRow,
      BaseReferences<_$AppDatabase, $DominantColorsTableTable, DominantColorRow>
    ),
    DominantColorRow,
    PrefetchHooks Function()> {
  $$DominantColorsTableTableTableManager(
      _$AppDatabase db, $DominantColorsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DominantColorsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DominantColorsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DominantColorsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> url = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DominantColorsTableCompanion(
            url: url,
            color: color,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String url,
            required String color,
            required int cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DominantColorsTableCompanion.insert(
            url: url,
            color: color,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DominantColorsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DominantColorsTableTable,
    DominantColorRow,
    $$DominantColorsTableTableFilterComposer,
    $$DominantColorsTableTableOrderingComposer,
    $$DominantColorsTableTableAnnotationComposer,
    $$DominantColorsTableTableCreateCompanionBuilder,
    $$DominantColorsTableTableUpdateCompanionBuilder,
    (
      DominantColorRow,
      BaseReferences<_$AppDatabase, $DominantColorsTableTable, DominantColorRow>
    ),
    DominantColorRow,
    PrefetchHooks Function()>;
typedef $$DanmakuCacheTableTableCreateCompanionBuilder
    = DanmakuCacheTableCompanion Function({
  required String cacheKey,
  required String data,
  required int cachedAt,
  Value<int> rowid,
});
typedef $$DanmakuCacheTableTableUpdateCompanionBuilder
    = DanmakuCacheTableCompanion Function({
  Value<String> cacheKey,
  Value<String> data,
  Value<int> cachedAt,
  Value<int> rowid,
});

class $$DanmakuCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $DanmakuCacheTableTable> {
  $$DanmakuCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$DanmakuCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DanmakuCacheTableTable> {
  $$DanmakuCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$DanmakuCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DanmakuCacheTableTable> {
  $$DanmakuCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$DanmakuCacheTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DanmakuCacheTableTable,
    DanmakuCacheRow,
    $$DanmakuCacheTableTableFilterComposer,
    $$DanmakuCacheTableTableOrderingComposer,
    $$DanmakuCacheTableTableAnnotationComposer,
    $$DanmakuCacheTableTableCreateCompanionBuilder,
    $$DanmakuCacheTableTableUpdateCompanionBuilder,
    (
      DanmakuCacheRow,
      BaseReferences<_$AppDatabase, $DanmakuCacheTableTable, DanmakuCacheRow>
    ),
    DanmakuCacheRow,
    PrefetchHooks Function()> {
  $$DanmakuCacheTableTableTableManager(
      _$AppDatabase db, $DanmakuCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DanmakuCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DanmakuCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DanmakuCacheTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cacheKey = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DanmakuCacheTableCompanion(
            cacheKey: cacheKey,
            data: data,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cacheKey,
            required String data,
            required int cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DanmakuCacheTableCompanion.insert(
            cacheKey: cacheKey,
            data: data,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DanmakuCacheTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DanmakuCacheTableTable,
    DanmakuCacheRow,
    $$DanmakuCacheTableTableFilterComposer,
    $$DanmakuCacheTableTableOrderingComposer,
    $$DanmakuCacheTableTableAnnotationComposer,
    $$DanmakuCacheTableTableCreateCompanionBuilder,
    $$DanmakuCacheTableTableUpdateCompanionBuilder,
    (
      DanmakuCacheRow,
      BaseReferences<_$AppDatabase, $DanmakuCacheTableTable, DanmakuCacheRow>
    ),
    DanmakuCacheRow,
    PrefetchHooks Function()>;
typedef $$PlaylistTableTableCreateCompanionBuilder = PlaylistTableCompanion
    Function({
  required String itemId,
  required String title,
  Value<String> posterUrl,
  Value<String?> backdropUrl,
  Value<String?> overview,
  Value<double?> rating,
  Value<int?> year,
  Value<String> type,
  required int addedAt,
  Value<String?> seriesTitle,
  Value<int?> seasonNumber,
  Value<int?> episodeNumber,
  Value<int> rowid,
});
typedef $$PlaylistTableTableUpdateCompanionBuilder = PlaylistTableCompanion
    Function({
  Value<String> itemId,
  Value<String> title,
  Value<String> posterUrl,
  Value<String?> backdropUrl,
  Value<String?> overview,
  Value<double?> rating,
  Value<int?> year,
  Value<String> type,
  Value<int> addedAt,
  Value<String?> seriesTitle,
  Value<int?> seasonNumber,
  Value<int?> episodeNumber,
  Value<int> rowid,
});

class $$PlaylistTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistTableTable> {
  $$PlaylistTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl => $composableBuilder(
      column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => ColumnFilters(column));
}

class $$PlaylistTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistTableTable> {
  $$PlaylistTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl => $composableBuilder(
      column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview => $composableBuilder(
      column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber,
      builder: (column) => ColumnOrderings(column));
}

class $$PlaylistTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistTableTable> {
  $$PlaylistTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl => $composableBuilder(
      column: $table.backdropUrl, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get seriesTitle => $composableBuilder(
      column: $table.seriesTitle, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
      column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
      column: $table.episodeNumber, builder: (column) => column);
}

class $$PlaylistTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaylistTableTable,
    PlaylistRow,
    $$PlaylistTableTableFilterComposer,
    $$PlaylistTableTableOrderingComposer,
    $$PlaylistTableTableAnnotationComposer,
    $$PlaylistTableTableCreateCompanionBuilder,
    $$PlaylistTableTableUpdateCompanionBuilder,
    (
      PlaylistRow,
      BaseReferences<_$AppDatabase, $PlaylistTableTable, PlaylistRow>
    ),
    PlaylistRow,
    PrefetchHooks Function()> {
  $$PlaylistTableTableTableManager(_$AppDatabase db, $PlaylistTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> itemId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> posterUrl = const Value.absent(),
            Value<String?> backdropUrl = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> addedAt = const Value.absent(),
            Value<String?> seriesTitle = const Value.absent(),
            Value<int?> seasonNumber = const Value.absent(),
            Value<int?> episodeNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistTableCompanion(
            itemId: itemId,
            title: title,
            posterUrl: posterUrl,
            backdropUrl: backdropUrl,
            overview: overview,
            rating: rating,
            year: year,
            type: type,
            addedAt: addedAt,
            seriesTitle: seriesTitle,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String itemId,
            required String title,
            Value<String> posterUrl = const Value.absent(),
            Value<String?> backdropUrl = const Value.absent(),
            Value<String?> overview = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<String> type = const Value.absent(),
            required int addedAt,
            Value<String?> seriesTitle = const Value.absent(),
            Value<int?> seasonNumber = const Value.absent(),
            Value<int?> episodeNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistTableCompanion.insert(
            itemId: itemId,
            title: title,
            posterUrl: posterUrl,
            backdropUrl: backdropUrl,
            overview: overview,
            rating: rating,
            year: year,
            type: type,
            addedAt: addedAt,
            seriesTitle: seriesTitle,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlaylistTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaylistTableTable,
    PlaylistRow,
    $$PlaylistTableTableFilterComposer,
    $$PlaylistTableTableOrderingComposer,
    $$PlaylistTableTableAnnotationComposer,
    $$PlaylistTableTableCreateCompanionBuilder,
    $$PlaylistTableTableUpdateCompanionBuilder,
    (
      PlaylistRow,
      BaseReferences<_$AppDatabase, $PlaylistTableTable, PlaylistRow>
    ),
    PlaylistRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediaServersTableTableTableManager get mediaServersTable =>
      $$MediaServersTableTableTableManager(_db, _db.mediaServersTable);
  $$DanmakuConfigsTableTableTableManager get danmakuConfigsTable =>
      $$DanmakuConfigsTableTableTableManager(_db, _db.danmakuConfigsTable);
  $$WatchHistoryTableTableTableManager get watchHistoryTable =>
      $$WatchHistoryTableTableTableManager(_db, _db.watchHistoryTable);
  $$FavoriteMoviesTableTableTableManager get favoriteMoviesTable =>
      $$FavoriteMoviesTableTableTableManager(_db, _db.favoriteMoviesTable);
  $$WatchlistTableTableTableManager get watchlistTable =>
      $$WatchlistTableTableTableManager(_db, _db.watchlistTable);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
  $$DanmakuSelectionsTableTableTableManager get danmakuSelectionsTable =>
      $$DanmakuSelectionsTableTableTableManager(
          _db, _db.danmakuSelectionsTable);
  $$MediaLibrariesTableTableTableManager get mediaLibrariesTable =>
      $$MediaLibrariesTableTableTableManager(_db, _db.mediaLibrariesTable);
  $$MediaItemsTableTableTableManager get mediaItemsTable =>
      $$MediaItemsTableTableTableManager(_db, _db.mediaItemsTable);
  $$MediaCarouselTableTableTableManager get mediaCarouselTable =>
      $$MediaCarouselTableTableTableManager(_db, _db.mediaCarouselTable);
  $$MediaCacheMetaTableTableTableManager get mediaCacheMetaTable =>
      $$MediaCacheMetaTableTableTableManager(_db, _db.mediaCacheMetaTable);
  $$DominantColorsTableTableTableManager get dominantColorsTable =>
      $$DominantColorsTableTableTableManager(_db, _db.dominantColorsTable);
  $$DanmakuCacheTableTableTableManager get danmakuCacheTable =>
      $$DanmakuCacheTableTableTableManager(_db, _db.danmakuCacheTable);
  $$PlaylistTableTableTableManager get playlistTable =>
      $$PlaylistTableTableTableManager(_db, _db.playlistTable);
}
