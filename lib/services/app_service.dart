import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/login/models/login_response.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用全局服务
class AppService extends GetxService {
  final themeMode = ThemeMode.system.obs;
  @override
  Future<void> onInit() async {
    super.onInit();
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = mode;
    prefs.setInt('themeMode', mode.index);
    Get.forceAppUpdate();
  }

  /// 基础URL
  String? _baseUrl;

  /// 缓存的cookie
  String? _cookie;

  /// 获取基础URL
  String? get baseUrl => _baseUrl;

  /// 设置基础URL
  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  /// 清除基础URL
  void clearBaseUrl() {
    _baseUrl = null;
  }

  /// 检查是否有基础URL
  bool get hasBaseUrl => _baseUrl != null && _baseUrl!.isNotEmpty;

  /// 获取缓存的cookie
  String? get cookie => _cookie;

  LoginResponse? _loginResponse;

  LoginResponse? get loginResponse => _loginResponse;

  UserInfo? _userInfo;

  UserInfo? get userInfo => _userInfo;

  /// 设置缓存的cookie
  void setCookie(String cookie) {
    _cookie = cookie;
  }

  /// 清除缓存的cookie
  void clearCookie() {
    _cookie = null;
  }

  saveProfile(String server, LoginResponse login) {
    _loginResponse = login;
    setBaseUrl(server);
  }

  void saveUserInfo(UserInfo userInfo) {
    _userInfo = userInfo;
  }

  /// 检查是否有缓存的cookie
  bool get hasCookie => _cookie != null && _cookie!.isNotEmpty;

  LoginResponse? get latestLoginProfile => _loginResponse;

  String? get latestLoginProfileAccessToken => _loginResponse?.accessToken;
}
