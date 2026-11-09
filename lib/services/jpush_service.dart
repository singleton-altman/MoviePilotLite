import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/ios_widget_navigation_service.dart';

class JPushSetAliasResult {
  const JPushSetAliasResult._({required this.ok, this.errorMessage});

  final bool ok;
  final String? errorMessage;

  static const JPushSetAliasResult success = JPushSetAliasResult._(ok: true);

  static JPushSetAliasResult failure(String message) {
    final t = message.trim();
    return JPushSetAliasResult._(
      ok: false,
      errorMessage: t.isEmpty ? '未知错误' : t,
    );
  }
}

class _SetAliasAttempt {
  const _SetAliasAttempt._({
    required this.ok,
    this.errorMessage,
    this.retryable = false,
  });

  const _SetAliasAttempt.success() : this._(ok: true);

  factory _SetAliasAttempt.failure(
    String message, {
    bool retryable = false,
  }) => _SetAliasAttempt._(
    ok: false,
    errorMessage: message.trim().isEmpty ? '未知错误' : message.trim(),
    retryable: retryable,
  );

  final bool ok;
  final String? errorMessage;
  final bool retryable;
}

class JPushService extends GetxService {
  static const String _appKey = 'e462379fa18ab59e31fd7ac2';
  static const String _channel = 'developer-default';

  /// 极光 iResCode：设置超时。官方说明为网络不佳或初始化尚未完成，建议重试。
  static const int _codeTimeout = 6002;

  final AppLog _talker = Get.find<AppLog>();

  JPushFlutterInterface? _jpush;
  bool _initialized = false;
  bool _registrationReady = false;

  bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<JPushService> init() async {
    await register();
    return this;
  }

  Future<void> register() async {
    if (!_isSupportedPlatform) return;
    if (_initialized) {
      _requestPermissions();
      return;
    }

    try {
      final jpush = JPush.newJPush();
      _bindEventHandlers(jpush);
      jpush.setup(
        appKey: _appKey,
        channel: _channel,
        production: kReleaseMode,
        debug: !kReleaseMode,
      );
      _jpush = jpush;
      _initialized = true;

      _talker.info('JPush 注册完成');
      Future<void>.delayed(
        const Duration(milliseconds: 300),
        _requestPermissions,
      );
      unawaited(
        Future<void>.delayed(const Duration(seconds: 1), _logRegistrationId),
      );
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace: stackTrace, message: 'JPush 初始化失败: $e');
    }
  }

  void _bindEventHandlers(JPushFlutterInterface jpush) {
    jpush.addEventHandler(
      onReceiveNotification: (event) async {
        _talker.info('JPush 收到通知: $event');
      },
      onOpenNotification: (event) async {
        _talker.info('JPush 打开通知: $event');
        _handleNotificationOpened(Map<String, dynamic>.from(event));
      },
      onReceiveMessage: (event) async {
        _talker.info('JPush 收到透传消息: $event');
      },
      onReceiveNotificationAuthorization: (event) async {
        _talker.info('JPush 通知授权状态变化: $event');
      },
      onConnected: (event) async {
        _talker.info('JPush 连接状态变化: $event');
      },
      onCommandResult: (event) async {
        _talker.info('JPush 命令回调: $event');
      },
      onReceiveDeviceToken: (event) async {
        _talker.info('JPush 收到设备凭证: $event');
      },
    );
  }

  void _handleNotificationOpened(Map<String, dynamic> event) {
    if (!Get.isRegistered<IosWidgetNavigationService>()) return;
    final nav = Get.find<IosWidgetNavigationService>();
    final raw = _moviePilotUrlFromJPushEvent(event) ??
        _systemMessageHintFromJPushEvent(event);
    if (raw == null) return;
    nav.enqueueDeepLink(raw);
  }

  String? _moviePilotUrlFromJPushEvent(Map<String, dynamic> event) {
    String? hit;
    void walk(dynamic n) {
      if (hit != null) return;
      if (n is String) {
        final t = n.trim();
        if (t.startsWith('moviepilot://')) hit = t;
        return;
      }
      if (n is Map) {
        for (final v in n.values) {
          walk(v);
          if (hit != null) return;
        }
      }
    }

    walk(event);
    return hit;
  }

  String? _systemMessageHintFromJPushEvent(Map<String, dynamic> event) {
    const keys = {'page', 'open_page', 'target_page', 'type'};
    const values = {'system_message', 'system-message', 'systemmessage'};
    for (final map in _jpushMapsToScan(event)) {
      for (final k in keys) {
        final v = map[k];
        if (v is! String) continue;
        final t = v.trim().toLowerCase();
        if (values.contains(t) || t == '/system-message') {
          return 'moviepilot://system-message';
        }
      }
    }
    return null;
  }

  Iterable<Map<String, dynamic>> _jpushMapsToScan(
    Map<String, dynamic> root,
  ) sync* {
    yield root;
    final ex = root['extras'];
    if (ex is! Map) return;
    final top = Map<String, dynamic>.from(ex);
    yield top;
    for (final v in top.values) {
      if (v is Map) {
        yield Map<String, dynamic>.from(v);
      }
    }
  }

  void _requestPermissions() {
    final jpush = _jpush;
    if (jpush == null) return;

    if (Platform.isAndroid) {
      jpush.requestRequiredPermission();
      return;
    }

    if (Platform.isIOS) {
      jpush.applyPushAuthority(
        const NotificationSettingsIOS(alert: true, badge: true, sound: true),
      );
    }
  }

  Future<void> _logRegistrationId() async {
    final registrationId = await getRegistrationId();
    if (registrationId != null && registrationId.isNotEmpty) {
      _talker.info('JPush Registration ID: $registrationId');
    }
  }

  Future<String?> getRegistrationId({
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    await register();
    final jpush = _jpush;
    if (jpush == null) return null;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final registrationId = await jpush.getRegistrationID();
        if (registrationId.isNotEmpty) {
          _registrationReady = true;
          return registrationId;
        }
      } catch (e, stackTrace) {
        _talker.handle(
          e,
          stackTrace: stackTrace,
          message: '获取 JPush Registration ID 失败: $e',
        );
        return null;
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(retryDelay);
      }
    }

    return null;
  }

  /// 等待 SDK 完成注册（拿得到 registrationID 才算就绪）。
  ///
  /// 极光 SDK 的 alias/tag 操作在初始化尚未完成时会直接回 6002 超时，
  /// 所以设置 Alias 之前先等一小段，超时上限内没就绪就照常尝试。
  Future<void> _waitUntilRegistered({
    int maxAttempts = 8,
    Duration retryDelay = const Duration(milliseconds: 700),
  }) async {
    if (_registrationReady) return;

    await register();
    final jpush = _jpush;
    if (jpush == null) return;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final registrationId = await jpush.getRegistrationID();
        if (registrationId.isNotEmpty) {
          _registrationReady = true;
          _talker.info('JPush SDK 已就绪: $registrationId');
          return;
        }
      } catch (e, stackTrace) {
        _talker.handle(
          e,
          stackTrace: stackTrace,
          message: '等待 JPush 就绪时读取 Registration ID 失败: $e',
        );
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(retryDelay);
      }
    }

    _talker.warning('等待 JPush SDK 就绪超时，仍继续尝试设置 Alias');
  }

  Future<JPushSetAliasResult> setAlias(String alias) async {
    final normalizedAlias = alias.trim();
    if (normalizedAlias.isEmpty) {
      return JPushSetAliasResult.failure('Alias 为空');
    }

    await register();
    final jpush = _jpush;
    if (jpush == null) {
      return JPushSetAliasResult.failure('JPush 未初始化（仅支持 iOS / Android）');
    }

    await _waitUntilRegistered();

    const maxAttempts = 3;
    String? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final outcome = await _setAliasOnce(jpush, normalizedAlias);
      if (outcome.ok) {
        final appliedAlias = await getAlias();
        if (appliedAlias == normalizedAlias) {
          _talker.info('设置 JPush Alias 成功: $normalizedAlias');
          return JPushSetAliasResult.success;
        }
        _talker.warning(
          '设置 JPush Alias 后校验不一致，期望: $normalizedAlias，实际: ${appliedAlias ?? 'null'}',
        );
        return JPushSetAliasResult.failure(
          'Alias 未立即生效（期望: $normalizedAlias，当前: ${appliedAlias ?? '无'}），请检查网络或稍后重试',
        );
      }

      lastError = outcome.errorMessage;
      if (!outcome.retryable || attempt == maxAttempts) break;

      final delay = Duration(milliseconds: 800 * attempt);
      _talker.warning(
        '设置 JPush Alias 第 $attempt 次失败（$lastError），${delay.inMilliseconds}ms 后重试',
      );
      await Future<void>.delayed(delay);
    }

    return JPushSetAliasResult.failure(lastError ?? '设置 JPush Alias 失败');
  }

  Future<_SetAliasAttempt> _setAliasOnce(
    JPushFlutterInterface jpush,
    String alias,
  ) async {
    try {
      final result = await jpush.setAlias(alias);
      final errorCode = result['errorCode'];
      if (errorCode is num && errorCode != 0) {
        return _SetAliasAttempt.failure(
          _describeAliasError(errorCode.toInt(), result),
          retryable: errorCode.toInt() == _codeTimeout,
        );
      }
      return const _SetAliasAttempt.success();
    } on PlatformException catch (e, stackTrace) {
      _talker.handle(
        e,
        stackTrace: stackTrace,
        message: '设置 JPush Alias 失败: ${e.code} ${e.message}',
      );
      final code = _aliasErrorCodeFromPlatformException(e);
      if (code == null) {
        return _SetAliasAttempt.failure(_platformExceptionMessage(e));
      }
      return _SetAliasAttempt.failure(
        _describeAliasError(code, const {}),
        retryable: code == _codeTimeout,
      );
    } catch (e, stackTrace) {
      _talker.handle(
        e,
        stackTrace: stackTrace,
        message: '设置 JPush Alias 失败: $e',
      );
      return _SetAliasAttempt.failure(e.toString());
    }
  }

  /// iOS 原生层把 iResCode 塞进 PlatformException 的 code（形如 "Error 6002"），
  /// Android 侧则回 errorCode 字段，这里统一把数字抠出来。
  int? _aliasErrorCodeFromPlatformException(PlatformException e) {
    final fromDetails = e.details;
    if (fromDetails is num) return fromDetails.toInt();
    if (fromDetails is Map) {
      final v = fromDetails['errorCode'];
      if (v is num) return v.toInt();
    }
    final match = RegExp(r'(\d{4})').firstMatch(e.code);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  String _platformExceptionMessage(PlatformException e) {
    final detail = e.message?.trim();
    if (detail != null &&
        detail.isNotEmpty &&
        !detail.toLowerCase().contains('couldn\'t be completed')) {
      return detail;
    }
    return 'JPush 调用失败（${e.code}），请检查网络后重试';
  }

  String _describeAliasError(int code, Map<dynamic, dynamic> result) {
    final detail = result['msg'] ?? result['message'] ?? result['content'];
    switch (code) {
      case _codeTimeout:
        return '极光设置 Alias 超时（6002），通常是网络不稳定或推送服务尚未就绪，请稍后重试';
      case 6001:
        return '极光设置 Alias 失败（6001）：参数为空';
      case 6003:
        return '极光设置 Alias 失败（6003）：Alias 含不合法字符';
      case 6004:
        return '极光设置 Alias 失败（6004）：Alias 超长（最多 40 字节）';
      case 6011:
        return '极光设置 Alias 失败（6011）：操作过于频繁，请稍后再试';
      case 6027:
        return '极光设置 Alias 失败（6027）：该 Alias 已绑定 10 台设备，请先解绑旧设备';
      default:
        final suffix = detail == null ? '' : '：$detail';
        return '极光设置 Alias 失败（错误码 $code）$suffix';
    }
  }

  Future<String?> getAlias({
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    await register();
    final jpush = _jpush;
    if (jpush == null) return null;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final result = await jpush.getAlias();
        final alias = result['alias']?.toString().trim();
        if (alias != null && alias.isNotEmpty) {
          return alias;
        }
      } catch (e, stackTrace) {
        _talker.handle(
          e,
          stackTrace: stackTrace,
          message: '获取 JPush Alias 失败: $e',
        );
        return null;
      }

      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(retryDelay);
      }
    }

    return null;
  }
}
