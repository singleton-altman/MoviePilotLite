import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

class JPushService extends GetxService {
  static const String _appKey = 'e462379fa18ab59e31fd7ac2';
  static const String _channel = 'developer-default';

  final AppLog _talker = Get.find<AppLog>();

  JPushFlutterInterface? _jpush;
  bool _initialized = false;

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

    try {
      final result = await jpush.setAlias(normalizedAlias);
      final errorCode = result['errorCode'];
      if (errorCode is num && errorCode != 0) {
        _talker.warning('设置 JPush Alias 失败: $result');
        final detail = result['msg'] ??
            result['message'] ??
            result['content'] ??
            result.toString();
        return JPushSetAliasResult.failure(
          '极光设置 Alias 失败（错误码 $errorCode）: $detail',
        );
      }
      final appliedAlias = await getAlias();
      if (appliedAlias != normalizedAlias) {
        _talker.warning(
          '设置 JPush Alias 后校验不一致，期望: $normalizedAlias，实际: ${appliedAlias ?? 'null'}',
        );
        return JPushSetAliasResult.failure(
          'Alias 未立即生效（期望: $normalizedAlias，当前: ${appliedAlias ?? '无'}），请检查网络或稍后重试',
        );
      }
      _talker.info('设置 JPush Alias 成功: $normalizedAlias');
      return JPushSetAliasResult.success;
    } catch (e, stackTrace) {
      _talker.handle(
        e,
        stackTrace: stackTrace,
        message: '设置 JPush Alias 失败: $e',
      );
      return JPushSetAliasResult.failure(e.toString());
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
