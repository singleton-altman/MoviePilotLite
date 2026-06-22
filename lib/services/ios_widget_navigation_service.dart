import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/utils/deep_link_route.dart';

class IosWidgetNavigationService extends GetxService {
  static const _channel = MethodChannel('org.moviepilot/widget_navigation');

  DeepLinkTarget? _pendingRoute;

  Future<IosWidgetNavigationService> init() async {
    if (!_isIos) return this;
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
    _pendingRoute = null;
    Future.microtask(() {
      if (Get.currentRoute == target.route) return;
      Get.toNamed(
        target.route,
        parameters: target.parameters.isEmpty ? null : target.parameters,
      );
    });
  }

  bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
