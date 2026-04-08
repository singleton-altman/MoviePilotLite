import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:dio/dio.dart';
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
  final showSearchButton = true.obs;
  final enableDownloaderManager = false.obs;
  final enableSpecialDownload = false.obs;
  final useExternalBrowser = false.obs;
  final enableFetchMediaserverLibraryStatus = false.obs;

  // 背景图设置
  final backgroundImageBytes = Rxn<Uint8List>();
  final backgroundImageOpacity = 0.5.obs;
  final backgroundImageGradientTop = Colors.transparent.obs;
  final backgroundImageGradientBottom = Colors.black.obs;
  final backgroundImageEnabled = false.obs;
  final backgroundImageUseServer = false.obs;
  final backgroundImageServerUrl = ''.obs;

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
    showSearchButton.value = prefs.getBool('showSearchButton') ?? true;
    enableDownloaderManager.value =
        prefs.getBool('enableDownloaderManager') ?? false;
    enableSpecialDownload.value =
        prefs.getBool('enableSpecialDownload') ?? false;
    useExternalBrowser.value = isHarmonyOs
        ? true
        : prefs.getBool('useExternalBrowser') ?? false;
    enableFetchMediaserverLibraryStatus.value =
        prefs.getBool('enableFetchMediaserverLibraryStatus') ?? false;

    // 背景图设置
    backgroundImageEnabled.value =
        prefs.getBool('backgroundImageEnabled') ?? false;
    backgroundImageOpacity.value =
        prefs.getDouble('backgroundImageOpacity') ?? 0.5;
    backgroundImageUseServer.value =
        prefs.getBool('backgroundImageUseServer') ?? false;
    backgroundImageServerUrl.value =
        prefs.getString('backgroundImageServerUrl') ?? '';

    final imageBase64 = prefs.getString('backgroundImageBase64');
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        backgroundImageBytes.value = base64Decode(imageBase64);
      } catch (_) {}
    }

    final gradientTopValue = prefs.getInt('backgroundGradientTop');
    if (gradientTopValue != null) {
      backgroundImageGradientTop.value = Color(gradientTopValue);
    }
    final gradientBottomValue = prefs.getInt('backgroundGradientBottom');
    if (gradientBottomValue != null) {
      backgroundImageGradientBottom.value = Color(gradientBottomValue);
    }

    if (backgroundImageEnabled.value && backgroundImageUseServer.value) {
      await cacheBackgroundImageFromServerUrl();
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

  Future<void> updateShowSearchButton(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    showSearchButton.value = value;
    await prefs.setBool('showSearchButton', value);
  }

  Future<void> updateEnableDownloaderManager(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    enableDownloaderManager.value = value;
    await prefs.setBool('enableDownloaderManager', value);
  }

  Future<void> updateEnableSpecialDownload(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    enableSpecialDownload.value = value;
    await prefs.setBool('enableSpecialDownload', value);
  }

  Future<void> updateUseExternalBrowser(bool value) async {
    if (isHarmonyOs) {
      ToastUtil.error('不支持在鸿蒙系统中使用外部浏览器');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    useExternalBrowser.value = value;
    await prefs.setBool('useExternalBrowser', value);
  }

  Future<void> updateEnableFetchMediaserverLibraryStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    enableFetchMediaserverLibraryStatus.value = value;
    await prefs.setBool('enableFetchMediaserverLibraryStatus', value);
  }

  Future<void> updateBackgroundImageEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageEnabled.value = value;
    await prefs.setBool('backgroundImageEnabled', value);
  }

  Future<void> updateBackgroundImageOpacity(double value) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageOpacity.value = value;
    await prefs.setDouble('backgroundImageOpacity', value);
  }

  Future<void> updateBackgroundImageGradientTop(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageGradientTop.value = color;
    await prefs.setInt('backgroundGradientTop', color.toARGB32());
  }

  Future<void> updateBackgroundImageGradientBottom(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageGradientBottom.value = color;
    await prefs.setInt('backgroundGradientBottom', color.toARGB32());
  }

  Future<void> updateBackgroundImage(Uint8List? bytes) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageBytes.value = bytes;
    if (bytes != null) {
      await prefs.setString('backgroundImageBase64', base64Encode(bytes));
    } else {
      await prefs.remove('backgroundImageBase64');
    }
  }

  Future<void> updateBackgroundImageUseServer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageUseServer.value = value;
    await prefs.setBool('backgroundImageUseServer', value);
  }

  Future<void> updateBackgroundImageServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageServerUrl.value = url;
    await prefs.setString('backgroundImageServerUrl', url);
  }

  bool _isValidHttpUrl(String url) {
    final u = Uri.tryParse(url.trim());
    if (u == null) return false;
    if (!u.hasScheme) return false;
    return u.scheme == 'http' || u.scheme == 'https';
  }

  String _cacheBustingUrl(String url) {
    final uri = Uri.parse(url);
    final qp = Map<String, String>.from(uri.queryParameters);
    qp['_t'] = DateTime.now().millisecondsSinceEpoch.toString();
    qp['_r'] = math.Random().nextInt(1 << 30).toString();
    return uri.replace(queryParameters: qp).toString();
  }

  Future<bool> cacheBackgroundImageFromServerUrl() async {
    final raw = backgroundImageServerUrl.value.trim();
    if (!_isValidHttpUrl(raw)) return false;
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          responseType: ResponseType.bytes,
          headers: const {'cache-control': 'no-cache', 'pragma': 'no-cache'},
        ),
      );
      final resp = await dio.get<List<int>>(_cacheBustingUrl(raw));
      if (resp.statusCode != 200) return false;
      final data = resp.data;
      if (data == null || data.isEmpty) return false;
      await updateBackgroundImage(Uint8List.fromList(data));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    backgroundImageBytes.value = null;
    backgroundImageEnabled.value = false;
    await prefs.remove('backgroundImageBase64');
    await prefs.setBool('backgroundImageEnabled', false);
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

  bool get isHarmonyOs =>
      Platform.operatingSystem == 'ohos' ||
      Platform.operatingSystem == 'harmonyos';
}
