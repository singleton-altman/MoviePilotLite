import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/login/models/login_response.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用全局服务
class AppService extends GetxService {
  static const Color _defaultPrimaryColor = Color(0xFF007AFF);

  final themeMode = ThemeMode.system.obs;
  final primaryColor = _defaultPrimaryColor.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    // 主题色：以 RGB 存储，读取后还原
    final r = prefs.getInt('primaryColorR');
    final g = prefs.getInt('primaryColorG');
    final b = prefs.getInt('primaryColorB');
    if (r != null && g != null && b != null) {
      primaryColor.value = Color.fromARGB(255, r, g, b);
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = mode;
    prefs.setInt('themeMode', mode.index);
    Get.forceAppUpdate();
  }

  Future<void> updatePrimaryColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    primaryColor.value = color;
    final r = (color.r * 255).round().clamp(0, 255).toInt();
    final g = (color.g * 255).round().clamp(0, 255).toInt();
    final b = (color.b * 255).round().clamp(0, 255).toInt();
    prefs.setInt('primaryColorR', r);
    prefs.setInt('primaryColorG', g);
    prefs.setInt('primaryColorB', b);
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

  /// 清除登录态（内存）
  void clearLoginState() {
    _loginResponse = null;
    _userInfo = null;
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
