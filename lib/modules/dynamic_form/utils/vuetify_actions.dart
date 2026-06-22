import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class VuetifyClickAction {
  const VuetifyClickAction({
    required this.api,
    required this.method,
    required this.params,
  });

  final String api;
  final String method;
  final Map<String, dynamic> params;
}

class VuetifyActionExecutor {
  VuetifyActionExecutor._();

  static VuetifyClickAction? extractClickAction(FormNode node) {
    final events = node.events;
    if (events == null) return null;
    final click = events['click'];
    if (click is! Map) return null;
    final api = click['api']?.toString();
    final method = click['method']?.toString().toLowerCase() ?? 'get';
    if (api == null || api.isEmpty) return null;
    final rawParams = click['params'];
    final params = rawParams is Map
        ? Map<String, dynamic>.from(rawParams)
        : const <String, dynamic>{};
    return VuetifyClickAction(api: api, method: method, params: params);
  }

  static Future<void> execute(
    VuetifyClickAction action, {
    Future<void> Function()? onSuccessReload,
  }) async {
    try {
      final apiClient = Get.find<ApiClient>();
      final appService = Get.find<AppService>();
      final token =
          appService.loginResponse?.accessToken ??
          appService.latestLoginProfileAccessToken ??
          apiClient.token;
      if (token == null || token.isEmpty) {
        ToastUtil.error('请先登录');
        return;
      }

      final cookieHeader =
          await apiClient.getCookieHeader() ?? appService.cookie;
      final headers = cookieHeader != null && cookieHeader.isNotEmpty
          ? <String, dynamic>{'cookie': cookieHeader}
          : null;

      final apiPath = normalizeApiPath(action.api);
      final response = await switch (action.method) {
        'post' => apiClient.post<dynamic>(
          apiPath,
          data: action.params.isEmpty ? null : action.params,
          token: token,
          headers: headers,
        ),
        'put' => apiClient.put<dynamic>(
          apiPath,
          action.params.isEmpty ? null : action.params,
          token: token,
          headers: headers,
        ),
        'delete' => apiClient.delete<dynamic>(
          apiPath,
          queryParameters: action.params.isEmpty ? null : action.params,
          token: token,
          headers: headers,
        ),
        _ => apiClient.get<dynamic>(
          apiPath,
          queryParameters: action.params.isEmpty ? null : action.params,
          token: token,
          headers: headers,
        ),
      };

      final status = response.statusCode ?? 0;
      final message = extractResponseMessage(response.data);
      if (status >= 400) {
        ToastUtil.error(message ?? '操作失败 (HTTP $status)');
        return;
      }

      if (onSuccessReload != null) {
        await onSuccessReload();
      }
      ToastUtil.success(message ?? '操作成功');
    } catch (e, st) {
      Get.find<AppLog>().handle(e, stackTrace: st, message: 'API 调用失败');
      ToastUtil.error('操作失败，请稍后重试');
    }
  }

  static String? extractResponseMessage(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in const ['message', 'msg', 'detail']) {
        final value = map[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }
    if (data is String) {
      final value = data.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static String normalizeApiPath(String api) {
    final value = api.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/api/')) {
      return value;
    }
    if (value.startsWith('api/')) {
      return '/$value';
    }
    if (value.startsWith('/')) {
      return '/api/v1$value';
    }
    return '/api/v1/$value';
  }
}
