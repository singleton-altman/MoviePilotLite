import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/models/login_profile.dart';
import 'package:moviepilot_mobile/modules/login/controllers/login_controller.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_controller.dart';
import 'package:moviepilot_mobile/modules/system_message/controllers/system_message_controller.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';

/// Profile 控制器：负责当前登录用户 / 登录档案的展示与后续扩展
class ProfileController extends GetxController {
  final _appService = Get.find<AppService>();
  final _authRepository = Get.find<AuthRepository>();
  final _iosSharedSessionService = Get.find<IosSharedSessionService>();
  final _talker = Get.find<AppLog>();

  /// 当前登录配置（登录档案）
  final currentProfile = Rxn<LoginProfile>();

  /// 当前用户信息（来自 /api/v1/user）
  final currentUserInfo = Rxn<UserInfo>();

  /// 是否正在加载
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadCurrentProfile());
  }

  @override
  void onReady() {
    super.onReady();
    // 页面展示后再拉取一次最新的用户信息
    loadCurrentUserInfo();
  }

  /// Read latest login profile from the database.
  Future<void> loadCurrentProfile() async {
    try {
      isLoading.value = true;
      final profiles = await _authRepository.getProfilesAsync();
      if (profiles.isEmpty) {
        currentProfile.value = null;
        return;
      }
      profiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      currentProfile.value = profiles.first;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get current user info (from API first, then DB)
  Future<void> loadCurrentUserInfo() async {
    final profiles = await _authRepository.getProfilesAsync();
    if (profiles.isEmpty) {
      currentUserInfo.value = null;
      return;
    }
    profiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final latest = profiles.first;

    try {
      isLoading.value = true;
      final userInfo = await _authRepository.getUserInfoByRole(
        role: latest.username,
      );
      if (userInfo != null) {
        currentUserInfo.value = userInfo;
      }
    } catch (e) {
      _talker.error('获取用户信息失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 退出登录：清空本地会话并回到登录页
  Future<void> logout() async {
    // 停止消息轮询并清理 controller
    if (Get.isRegistered<SystemMessageController>()) {
      Get.find<SystemMessageController>().clearForLogout();
    }

    // 清空内存中的登录信息
    _appService.clearBaseUrl();
    _appService.clearCookie();
    _appService.clearLoginState();
    await _iosSharedSessionService.clearSession();
    if (Get.isRegistered<SiteController>()) {
      Get.delete<SiteController>(force: true);
    }
    if (Get.isRegistered<LoginController>()) {
      Get.find<LoginController>().resetForLogout();
    }

    currentProfile.value = null;
    currentUserInfo.value = null;

    // 跳转到登录页面
    Get.offAllNamed('/login');
  }
}
