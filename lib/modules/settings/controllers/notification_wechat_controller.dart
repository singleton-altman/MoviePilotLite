import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

typedef WechatActionResult = ({bool ok, String message});

/// 统一信封业务失败；serverMessage 取服务端信封里可展示的提示文案。
class _EnvelopeFailure implements Exception {
  _EnvelopeFailure(this.serverMessage);

  final String? serverMessage;
}

/// V2's dedicated endpoints and V3.1.5's NotificationAction contract.
class NotificationWechatController extends GetxController {
  NotificationWechatController({
    ApiClient? apiClient,
    Future<bool> Function()? detectV3,
    bool Function()? isAdmin,
  }) : _apiClient = apiClient ?? Get.find<ApiClient>(),
       _detectV3 = detectV3 ?? Get.find<ServerApiVersionService>().isV3,
       _isAdmin = isAdmin ?? (() => Get.find<AppService>().isSuperuser);

  final ApiClient _apiClient;
  final Future<bool> Function() _detectV3;
  final bool Function() _isAdmin;
  final supported = Rxn<bool>();
  final isV3 = false.obs;
  final isLoading = false.obs;
  final isOperating = false.obs;
  final errorText = RxnString();
  final status = Rxn<Map<String, dynamic>>();
  final source = ''.obs;
  final configurations = <Map<String, dynamic>>[].obs;
  final configLoaded = false.obs;
  Timer? _pollTimer;
  DateTime? _pollDeadline;
  bool _closed = false;
  bool _active = true;
  bool _statusInFlight = false;
  bool _initialized = false;
  String? _server;
  int _generation = 0;

  bool get authorized => !_closed && _isAdmin() &&
      (_server == null || _server == _apiClient.baseUrl);
  bool get loggedIn => status.value?['connected'] == true;
  String? get accountId => status.value?['account_id'] as String?;
  String? get qrcodeUrl => status.value?['qrcode_url'] as String?;
  String? get qrStatus => status.value?['qrcode_status'] as String?;
  bool get qrExpired =>
      qrStatus == 'expired' ||
      (_pollDeadline != null && !DateTime.now().isBefore(_pollDeadline!));
  bool get canPoll =>
      authorized &&
      _active &&
      !loggedIn &&
      !qrExpired &&
      qrcodeUrl != null &&
      _pollDeadline != null;
  bool get busy => isLoading.value || isOperating.value;
  List<Map<String, dynamic>> get wechatConfigurations => configurations
      .where((item) => item['type'] == 'wechatclawbot')
      .toList(growable: false);

  @override
  void onReady() {
    super.onReady();
    unawaited(initialize());
  }

  Future<void> initialize() async {
    if (_initialized || _closed) return;
    if (!authorized) {
      supported.value = false;
      errorText.value = '仅管理员可管理通知渠道';
      return;
    }
    _initialized = true;
    _server = _apiClient.baseUrl;
    isLoading.value = true;
    try {
      final v3 = await _detectV3();
      if (!authorized) return;
      isV3.value = v3;
      supported.value = true;
      if (v3) {
        await _loadConfigurations();
        if (!authorized) return;
        if (wechatConfigurations.isEmpty) return;
        source.value =
            wechatConfigurations.first['id'] as String? ??
            wechatConfigurations.first['name'] as String;
      }
    } catch (_) {
      if (!_closed) {
        errorText.value = '无法读取通知配置，请重试';
        supported.value = true;
        _initialized = false;
      }
      return;
    } finally {
      if (!_closed) isLoading.value = false;
    }
    await reload();
  }

  void setActive(bool active) {
    _active = active;
    _pollTimer?.cancel();
    if (active) _schedulePoll();
  }

  void _invalidateStatus() {
    _generation++;
    _pollTimer?.cancel();
    _pollDeadline = null;
    status.value = null;
  }

  Future<void> selectSource(String value) async {
    if (!authorized || busy) return;
    _invalidateStatus();
    source.value = value.trim();
    await reload();
  }

  Future<void> reload({bool autoGenerate = true, bool polling = false}) async {
    if (!authorized ||
        supported.value != true ||
        _statusInFlight ||
        isOperating.value ||
        (isV3.value && source.value.isEmpty)) {
      return;
    }
    final generation = _generation;
    _pollTimer?.cancel();
    _statusInFlight = true;
    if (!polling) isLoading.value = true;
    errorText.value = null;
    try {
      final response = await _request('status', {
        ..._channelParams,
        'refresh_remote': true,
        'auto_generate_qrcode': autoGenerate,
      });
      if (!authorized || generation != _generation) return;
      _check(response);
      _applyStatus(_payload(response.data));
    } catch (error) {
      if (!_closed && generation == _generation) {
        // Never log exceptions: Dio errors may contain QR URLs or credentials.
        final serverMessage =
            error is _EnvelopeFailure ? error.serverMessage : null;
        errorText.value = serverMessage ?? '获取登录状态失败，请重试';
        status.value = null;
        _pollDeadline = null;
      }
    } finally {
      _statusInFlight = false;
      if (!_closed) {
        isLoading.value = false;
        if (generation != _generation && authorized) {
          unawaited(reload());
        } else {
          _schedulePoll();
        }
      }
    }
  }

  void _applyStatus(Map<String, dynamic>? data) {
    if (data == null || data['connected'] is! bool || data['success'] != true) {
      throw const FormatException('Invalid status');
    }
    for (final key in ['account_id', 'qrcode_url', 'qrcode_status']) {
      if (data[key] != null && data[key] is! String) {
        throw const FormatException('Invalid status');
      }
    }
    final previousQr = qrcodeUrl;
    // Keep only documented presentation fields; never retain token-like extras.
    status.value = {
      'connected': data['connected'],
      'account_id': data['account_id'],
      'qrcode_url': data['qrcode_url'],
      'qrcode_status': data['qrcode_status'],
    };
    if (loggedIn || qrcodeUrl == null) {
      _pollDeadline = null;
    } else if (_pollDeadline == null || previousQr != qrcodeUrl) {
      // Backend QR TTL is 240s. Do not extend it on every status poll.
      final updated = data['qrcode_updated_at'];
      final issued = updated is int
          ? DateTime.fromMillisecondsSinceEpoch(updated * 1000)
          : DateTime.now();
      final deadline = issued.add(const Duration(seconds: 240));
      final localLimit = DateTime.now().add(const Duration(seconds: 240));
      _pollDeadline = deadline.isBefore(localLimit) ? deadline : localLimit;
    }
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    if (!canPoll || busy || _statusInFlight) return;
    _pollTimer = Timer(const Duration(seconds: 3), () {
      if (!canPoll) {
        // Notify the QR panel when the local TTL has elapsed.
        if (!_closed) status.refresh();
        return;
      }
      unawaited(reload(autoGenerate: false, polling: true));
    });
  }

  Map<String, dynamic> get _channelParams {
    final params = <String, dynamic>{
      if (source.value.isNotEmpty) 'source': source.value,
    };
    if (isV3.value) {
      for (final item in wechatConfigurations) {
        if ((item['id'] ?? item['name']) != source.value) continue;
        params['fallback_source'] = item['name'];
        final config = item['config'];
        if (config is Map) {
          for (final key in ['WECHATCLAWBOT_BASE_URL', 'WECHATCLAWBOT_DEFAULT_TARGET',
            'WECHATCLAWBOT_ADMINS', 'WECHATCLAWBOT_POLL_TIMEOUT']) {
            if (config.containsKey(key)) params[key] = config[key];
          }
        }
        break;
      }
    }
    return params;
  }

  Future<Response<dynamic>> _request(
    String action,
    Map<String, dynamic> params,
  ) {
    if (isV3.value) {
      return _apiClient.post<dynamic>(
        '/api/v1/notification/manage',
        data: {'target': 'WechatClawBot', 'action': action, 'params': params},
      );
    }
    final endpoint = switch (action) {
      'refresh_qrcode' => 'refresh',
      'test_connection' => 'test',
      'migrate_cache' => 'migrate',
      _ => action,
    };
    final path = '/api/v1/notification/wechatclawbot/$endpoint';
    return action == 'status' || action == 'test_connection'
        ? _apiClient.get<dynamic>(path, queryParameters: params)
        : _apiClient.post<dynamic>(path, queryParameters: params);
  }

  Map<String, dynamic>? _payload(dynamic body) {
    if (body is! Map) return null;
    return Map<String, dynamic>.from(body['data'] is Map ? body['data'] : body);
  }

  void _check(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    final body = response.data;
    if (code < 200 ||
        code >= 300 ||
        body is! Map ||
        body['success'] != true ||
        (body['data'] is Map && body['data']['success'] == false)) {
      throw _EnvelopeFailure(_serverMessage(body));
    }
  }

  /// 只采纳统一信封里字符串形态的 message 用于展示；
  /// 其余响应原文可能回显二维码或凭据，一律丢弃。
  String? _serverMessage(dynamic body) {
    if (body is! Map) return null;
    final message = body['message'];
    if (message is String) {
      final trimmed = message.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  Future<WechatActionResult> _action(
    String action,
    String label, {
    Map<String, dynamic>? params,
  }) async {
    if (!authorized) return (ok: false, message: '仅管理员可管理通知渠道');
    if (supported.value != true) return (ok: false, message: '请先加载通知配置');
    if (busy || _statusInFlight) return (ok: false, message: '操作进行中');
    if (isV3.value && source.value.isEmpty && action != 'migrate_cache') {
      return (ok: false, message: '请先添加并选择微信 ClawBot 渠道');
    }
    isOperating.value = true;
    _pollTimer?.cancel();
    if (action == 'refresh_qrcode') _invalidateStatus();
    try {
      final response = await _request(
        action,
        params ?? _channelParams,
      );
      if (!authorized) return (ok: false, message: '页面已关闭或权限已变更');
      _check(response);
      if (action == 'refresh_qrcode') {
        _pollDeadline = null;
        _applyStatus(_payload(response.data));
      } else if (action == 'logout' || action == 'migrate_cache') {
        _invalidateStatus();
        if (action == 'logout') {
          status.value = {'connected': false};
        }
      }
      return (ok: true, message: '$label成功');
    } catch (error) {
      // No raw business response/exception is exposed: it may echo secrets.
      // 仅透出统一信封 message（v3 manage 失败提示），其余一律给通用文案。
      final serverMessage =
          error is _EnvelopeFailure ? error.serverMessage : null;
      return (
        ok: false,
        message: serverMessage ?? '$label失败，请检查渠道配置或稍后重试',
      );
    } finally {
      if (!_closed) {
        isOperating.value = false;
        _schedulePoll();
      }
    }
  }

  Future<WechatActionResult> refreshQrcode() =>
      _action('refresh_qrcode', '刷新二维码');
  Future<WechatActionResult> logout() => _action('logout', '退出登录');
  Future<WechatActionResult> test() => _action('test_connection', '测试连通性');

  Future<WechatActionResult> migrate({
    required String oldSource,
    required String newSource,
    bool cleanupOld = false,
    bool overwrite = false,
  }) async {
    final oldName = oldSource.trim();
    final newName = newSource.trim();
    if (oldName.isEmpty || newName.isEmpty || oldName == newName) {
      return (ok: false, message: '请输入不同的原渠道名称和新渠道名称');
    }
    return _action(
      'migrate_cache',
      '迁移缓存',
      params: {
        if (isV3.value) 'old_name': oldName else 'old_source': oldName,
        if (isV3.value) 'new_name': newName else 'new_source': newName,
        'cleanup_old': cleanupOld,
        'overwrite': overwrite,
      },
    );
  }

  Future<List<Map<String, dynamic>>> _readConfigurations() async {
    final response = await _apiClient.get<dynamic>(
      '/api/v1/system/setting/Notifications',
      skipV3EnvelopeUnwrap: true,
    );
    _check(response);
    final data = _payload(response.data);
    if (data == null || !data.containsKey('value')) {
      throw const FormatException('Invalid configuration');
    }
    final value = data['value'];
    if (value == null) return [];
    if (value is! List || value.any((item) => item is! Map)) {
      throw const FormatException('Invalid configuration');
    }
    final items = value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    final identities = <String>{};
    for (final item in items) {
      if (item['name'] is! String || (item['name'] as String).trim().isEmpty ||
          item['type'] is! String ||
          (item['id'] != null && (item['id'] is! String || (item['id'] as String).isEmpty)) ||
          (item['config'] != null && item['config'] is! Map) ||
          (item['enabled'] != null && item['enabled'] is! bool) ||
          (item['switchs'] != null && (item['switchs'] is! List ||
            (item['switchs'] as List).any((v) => v is! String)))) {
        throw const FormatException('Invalid channel');
      }
      if (!identities.add((item['id'] ?? item['name']) as String)) {
        throw const FormatException('Duplicate channel');
      }
      if (item['type'] == 'wechatclawbot' && item['config'] is Map) {
        final config = item['config'] as Map;
        for (final key in ['WECHATCLAWBOT_BASE_URL', 'WECHATCLAWBOT_DEFAULT_TARGET', 'WECHATCLAWBOT_ADMINS']) {
          if (config[key] != null && config[key] is! String) throw const FormatException('Invalid channel config');
        }
        if (config['WECHATCLAWBOT_POLL_TIMEOUT'] != null && config['WECHATCLAWBOT_POLL_TIMEOUT'] is! int) {
          throw const FormatException('Invalid timeout');
        }
      }
    }
    return items;
  }

  Future<void> _loadConfigurations() async {
    final items = await _readConfigurations();
    if (!authorized) return;
    configurations.assignAll(items);
    configLoaded.value = true;
  }

  Future<void> reloadConfigurations() async {
    if (!authorized || !isV3.value || busy || _statusInFlight) return;
    isLoading.value = true;
    _invalidateStatus();
    try {
      await _loadConfigurations();
      if (!authorized) return;
      final choices = wechatConfigurations;
      if (!choices.any(
        (item) => (item['id'] ?? item['name']) == source.value,
      )) {
        source.value = choices.isEmpty
            ? ''
            : (choices.first['id'] ?? choices.first['name']) as String;
      }
      errorText.value = null;
    } catch (_) {
      if (!_closed) errorText.value = '读取通知配置失败，请重试';
    } finally {
      if (!_closed) isLoading.value = false;
    }
    if (authorized) await reload();
  }

  /// Full-array V3 save: retain all other channels/unknown config keys and IDs.
  /// Re-read before writing to refuse overwriting a changed server snapshot.
  Future<WechatActionResult> saveChannel({
    Map<String, dynamic>? original,
    String? name,
    bool enabled = false,
    Map<String, dynamic>? config,
    List<String>? switchs,
    bool delete = false,
  }) async {
    if (!authorized) return (ok: false, message: '仅管理员可管理通知渠道');
    if (!isV3.value || !configLoaded.value) {
      return (ok: false, message: '请先读取 v3 通知配置');
    }
    if (busy || _statusInFlight) return (ok: false, message: '操作进行中');
    final items = configurations
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final index = original == null
        ? -1
        : items.indexWhere(
            (item) =>
                (original['id'] != null
                    ? item['id'] == original['id']
                    : item['name'] == original['name']) &&
                item['type'] == 'wechatclawbot',
          );
    if (original != null && index < 0) {
      return (ok: false, message: '渠道已变更，请刷新后重试');
    }
    if (delete) {
      if (index < 0) return (ok: false, message: '未选择渠道');
      items.removeAt(index);
    } else {
      final trimmed = name?.trim() ?? '';
      if (trimmed.isEmpty ||
          items.asMap().entries.any(
            (entry) =>
                entry.key != index &&
                entry.value['name']?.toString().trim().toLowerCase() ==
                    trimmed.toLowerCase(),
          )) {
        return (ok: false, message: '渠道名称不能为空或与其它渠道重复');
      }
      final updated = {
        ...?original,
        'id':
            original?['id'] ??
            (original != null
                ? 'legacy-${original['type'] ?? 'notification'}-${original['name'] ?? 'unnamed'}'
                : List.generate(
                    16,
                    (_) => Random.secure()
                        .nextInt(256)
                        .toRadixString(16)
                        .padLeft(2, '0'),
                  ).join()),
        'name': trimmed,
        'type': 'wechatclawbot',
        'enabled': enabled,
        'config': {...?original?['config'] as Map?, ...?config},
        if (switchs != null) 'switchs': switchs,
      };
      if (index < 0) {
        items.add(updated);
      } else {
        items[index] = updated;
      }
    }
    isOperating.value = true;
    _pollTimer?.cancel();
    try {
      final current = await _readConfigurations();
      if (!authorized) return (ok: false, message: '页面已关闭或权限已变更');
      if (jsonEncode(current) != jsonEncode(configurations.toList())) {
        return (ok: false, message: '服务端配置已变更，请刷新后重试');
      }
      for (final item in items) {
        // Match the endpoint's previous-config identity fallback, for every
        // legacy channel, not just the edited one.
        item['id'] ??= 'legacy-${item['type'] ?? 'notification'}-${item['name'] ?? 'unnamed'}';
      }
      configLoaded.value = false;
      final response = await _apiClient.postJson<dynamic>(
        '/api/v1/notification/config',
        items,
      );
      if (!authorized) return (ok: false, message: '页面已关闭或权限已变更');
      // Persistence can succeed while cache reconciliation fails. Always re-read.
      _invalidateStatus();
      await _loadConfigurations();
      _check(response);
      source.value = delete
          ? ''
          : (items[index < 0 ? items.length - 1 : index]['id'] as String);
      return (ok: true, message: delete ? '渠道已删除' : '通知配置已保存');
    } catch (_) {
      return (ok: false, message: '保存未完成，配置可能已写入但缓存同步失败，请刷新确认后重试');
    } finally {
      if (!_closed) isOperating.value = false;
    }
  }

  @override
  void onClose() {
    _closed = true;
    _generation++;
    _pollTimer?.cancel();
    status.value = null;
    configurations.clear();
    super.onClose();
  }
}
