import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class RoutePermissionMiddleware extends GetMiddleware {
  RoutePermissionMiddleware({this.permissionRoute});

  final String? permissionRoute;

  @override
  RouteSettings? redirect(String? route) {
    final appService = Get.find<AppService>();
    final targetRoute = permissionRoute ?? route;
    if (appService.canAccessRoute(targetRoute)) {
      return null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastUtil.info(appService.accessDeniedMessage(targetRoute));
    });
    return const RouteSettings(name: '/main');
  }
}
