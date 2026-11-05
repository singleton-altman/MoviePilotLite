import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/api_auth_failure.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

class MfaPasskeyItem {
  const MfaPasskeyItem({
    required this.id,
    this.name,
    this.createdAt,
    this.lastUsedAt,
  });
  final int id;
  final String? name;
  final String? createdAt;
  final String? lastUsedAt;

  factory MfaPasskeyItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int || id <= 0) throw const FormatException('无效的通行密钥标识');
    return MfaPasskeyItem(
      id: id,
      name: json['name']?.toString(),
      createdAt: json['created_at']?.toString(),
      lastUsedAt: json['last_used_at']?.toString(),
    );
  }
}

/// V2: /mfa/status/{username} success is the OTP state, not a business failure.
/// V3: /user/current.is_otp. OTP mutation and Passkey management contracts are shared.
/// Passkey registration/authentication are intentionally not implemented here.
class MfaSettingsController extends GetxController {
  MfaSettingsController({
    ApiClient? apiClient,
    AppService? appService,
    ServerApiVersionService? versionService,
  }) : _apiClient = apiClient ?? Get.find<ApiClient>(),
       _appService = appService ?? Get.find<AppService>(),
       _version = versionService ?? Get.find<ServerApiVersionService>();
  final ApiClient _apiClient;
  final AppService _appService;
  final ServerApiVersionService _version;
  final isLoading = false.obs;
  final otpEnabled = Rxn<bool>();
  final otpError = RxnString();
  final passkeyError = RxnString();
  final operationError = RxnString();
  final pendingSecret = RxnString();
  final pendingUri = RxnString();
  final isSubmitting = false.obs;
  final passkeys = <MfaPasskeyItem>[].obs;
  int _generation = 0;
  bool _current(int request) => !isClosed && request == _generation;
  bool get _busy => isLoading.value || isSubmitting.value || isClosed;

  @override
  void onReady() {
    super.onReady();
    loadAll();
  }

  @override
  void onClose() {
    _generation++;
    pendingSecret.value = null;
    pendingUri.value = null;
    super.onClose();
  }

  void _log(Object e, StackTrace st) {
    if (Get.isRegistered<AppLog>()) {
      Get.find<AppLog>().handle(e, stackTrace: st, message: '两步验证请求失败');
    }
  }

  String _error(Object e) => e is StateError
      ? e.message.toString()
      : e is FormatException
      ? '服务端数据格式异常'
      : '请求失败，请稍后重试';

  void _checkHttp(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) throw StateError('请求失败 (HTTP $status)');
  }

  dynamic _payload(Response<dynamic> response) {
    _checkHttp(response);
    final raw = response.data;
    if (raw is Map && raw['success'] == false) {
      throw StateError(raw['message']?.toString() ?? '操作失败');
    }
    return raw is Map && raw.containsKey('data') ? raw['data'] : raw;
  }

  void _requireSuccess(Response<dynamic> response) {
    _checkHttp(response);
    final raw = response.data;
    if (raw is! Map || raw['success'] is! bool) throw const FormatException();
    if (raw['success'] != true) {
      throw StateError(raw['message']?.toString() ?? '操作失败');
    }
  }

  Future<void> loadAll() async {
    if (_busy) return;
    final request = ++_generation;
    isLoading.value = true;
    otpEnabled.value = null;
    otpError.value = null;
    passkeyError.value = null;
    try {
      await Future.wait([_loadOtpStatus(request), _loadPasskeys(request)]);
    } finally {
      if (_current(request)) isLoading.value = false;
    }
  }

  Future<void> _loadOtpStatus(int request) async {
    try {
      final isV3 = await _version.isV3();
      if (!_current(request)) return;
      bool enabled;
      if (isV3) {
        final raw = _payload(
          await _apiClient.get<dynamic>(
            '/api/v1/user/current',
            skipV3EnvelopeUnwrap: true,
          ),
        );
        if (raw is! Map || raw['is_otp'] is! bool) {
          throw const FormatException();
        }
        enabled = raw['is_otp'] as bool;
      } else {
        final username = _appService.loginResponse?.userName.trim() ?? '';
        if (username.isEmpty) {
          throw StateError(ApiAuthFailure.notLoggedInMessage);
        }
        final response = await _apiClient.get<dynamic>(
          '/api/v1/mfa/status/${Uri.encodeComponent(username)}',
          skipV3EnvelopeUnwrap: true,
        );
        _checkHttp(response);
        final raw = response.data;
        if (raw is! Map || raw['success'] is! bool) {
          throw const FormatException();
        }
        enabled = raw['success'] as bool;
      }
      if (_current(request)) otpEnabled.value = enabled;
    } catch (e, st) {
      if (_current(request)) otpError.value = _error(e);
      _log(e, st);
    }
  }

  Future<void> _loadPasskeys(int request) async {
    try {
      final raw = _payload(
        await _apiClient.get<dynamic>(
          '/api/v1/mfa/passkey/list',
          skipV3EnvelopeUnwrap: true,
        ),
      );
      if (raw is! List || raw.any((e) => e is! Map)) {
        throw const FormatException();
      }
      final parsed = raw
          .map(
            (e) => MfaPasskeyItem.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      if (_current(request)) passkeys.assignAll(parsed);
    } catch (e, st) {
      if (_current(request)) passkeyError.value = _error(e);
      _log(e, st);
    }
  }

  Future<bool> generateOtp() async {
    if (_busy) {
      operationError.value = '操作进行中，请稍后重试';
      return false;
    }
    if (otpEnabled.value != false) {
      operationError.value = '请先确认两步验证状态';
      return false;
    }
    isSubmitting.value = true;
    operationError.value = null;
    pendingSecret.value = null;
    pendingUri.value = null;
    try {
      final response = await _apiClient.post<dynamic>(
        '/api/v1/mfa/otp/generate',
      );
      _requireSuccess(response);
      final raw = _payload(response);
      if (raw is! Map || raw['secret'] is! String || raw['uri'] is! String) {
        throw const FormatException();
      }
      final secret = (raw['secret'] as String).trim();
      final uri = (raw['uri'] as String).trim();
      if (secret.isEmpty || Uri.tryParse(uri)?.scheme != 'otpauth') {
        throw const FormatException();
      }
      if (isClosed) return false;
      pendingSecret.value = secret;
      pendingUri.value = uri;
      return true;
    } catch (e, st) {
      if (!isClosed) operationError.value = _error(e);
      _log(e, st);
      return false;
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }

  void cancelPendingOtp() {
    if (isSubmitting.value) return;
    pendingSecret.value = null;
    pendingUri.value = null;
  }

  Future<String?> verifyOtp(String code) async {
    if (_busy) return '操作进行中，请稍后重试';
    final uri = pendingUri.value;
    if (uri == null || uri.isEmpty) return '请先生成绑定密钥';
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) return '请输入 6 位动态验证码';
    return _mutate(
      '/api/v1/mfa/otp/verify',
      {'uri': uri, 'otpPassword': code.trim()},
      () {
        otpEnabled.value = true;
        pendingSecret.value = null;
        pendingUri.value = null;
      },
    );
  }

  Future<String?> disableOtp(String password) async {
    if (_busy) return '操作进行中，请稍后重试';
    if (password.isEmpty) return '请输入账号密码';
    return _mutate('/api/v1/mfa/otp/disable', {'password': password}, () {
      otpEnabled.value = false;
      pendingSecret.value = null;
      pendingUri.value = null;
    });
  }

  Future<String?> deletePasskey(MfaPasskeyItem item, String password) async {
    if (_busy) return '操作进行中，请稍后重试';
    if (password.isEmpty) return '请输入账号密码';
    if (item.id <= 0) return '无效的通行密钥标识';
    return _mutate(
      '/api/v1/mfa/passkey/delete',
      {'passkey_id': item.id, 'password': password},
      () {
        passkeys.removeWhere((e) => e.id == item.id);
      },
    );
  }

  /// Null means confirmed success only; busy, HTTP, business and format errors are non-null.
  Future<String?> _mutate(
    String path,
    Map<String, dynamic> body,
    void Function() onSuccess,
  ) async {
    isSubmitting.value = true;
    operationError.value = null;
    try {
      _requireSuccess(await _apiClient.post<dynamic>(path, data: body));
      if (isClosed) return '页面已关闭';
      onSuccess();
      return null;
    } catch (e, st) {
      final error = _error(e);
      if (!isClosed) operationError.value = error;
      _log(e, st);
      return error;
    } finally {
      if (!isClosed) isSubmitting.value = false;
    }
  }
}
