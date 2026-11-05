import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/utils/deep_link_route.dart';

/// 桌面小组件/推送深链跳转。
///
/// 通道由 iOS AppDelegate 与 Android MainActivity 共同实现：启动时取回
/// 冷启动挂起的路由，运行中接收 `openWidgetRoute` 立即跳转。
class IosWidgetNavigationService extends GetxService {
  static const _channel = MethodChannel('org.moviepilot/widget_navigation');
  static const _duplicateWindow = Duration(milliseconds: 800);

  DeepLinkTarget? _pendingRoute;
  String? _lastNavigationKey;
  DateTime? _lastNavigationAt;

  Future<IosWidgetNavigationService> init() async {
    if (!_isSupportedPlatform) return this;
    _channel.setMethodCallHandler(_handleMethodCall);
    try {
      final route = await _channel.invokeMethod<String>(
        'getPendingWidgetRoute',
      );
      _storePendingRoute(route);
    } catch (_) {}
    return this;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'openWidgetRoute') return;
    final route = parseDeepLinkTarget(call.arguments?.toString());
    if (route == null) return;
    _pendingRoute = route;
    _tryNavigateImmediately();
  }

  void _storePendingRoute(String? route) {
    final normalized = parseDeepLinkTarget(route);
    if (normalized == null) return;
    _pendingRoute = normalized;
  }

  void enqueueDeepLink(String? raw) {
    final target = parseDeepLinkTarget(raw);
    if (target == null) return;
    _pendingRoute = target;
    _tryNavigateImmediately();
  }

  void enqueueTarget(DeepLinkTarget target) {
    _pendingRoute = target;
    _tryNavigateImmediately();
  }

  void _tryNavigateImmediately() {
    final currentRoute = Get.currentRoute;
    if (currentRoute == '/login' || currentRoute.isEmpty) return;
    navigateToPendingRoute();
  }

  void navigateToPendingRoute() {
    if (kIsWeb) return;
    final target = _pendingRoute;
    if (target == null || target.route.isEmpty) return;
    final navigationKey = _navigationKeyFor(target);
    final now = DateTime.now();
    final lastAt = _lastNavigationAt;
    if (_lastNavigationKey == navigationKey &&
        lastAt != null &&
        now.difference(lastAt) < _duplicateWindow) {
      _pendingRoute = null;
      return;
    }
    _lastNavigationKey = navigationKey;
    _lastNavigationAt = now;
    _pendingRoute = null;
    Future.microtask(() {
      if (Get.currentRoute == target.route) return;
      Get.toNamed(
        target.route,
        parameters: target.parameters.isEmpty ? null : target.parameters,
      );
    });
  }

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  String _navigationKeyFor(DeepLinkTarget target) {
    if (target.parameters.isEmpty) return target.route;
    final keys = target.parameters.keys.toList()..sort();
    final params = keys.map((k) => '$k=${target.parameters[k]}').join('&');
    return '${target.route}?$params';
  }
}
