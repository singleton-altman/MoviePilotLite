import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppSettingController extends GetxController {
  final themeMode = ThemeMode.system.obs;
  final primaryColor = Color(0xFF007AFF).obs;
  final service = Get.find<AppService>();
  final version = '1.0.0'.obs;
  final showSearchButton = true.obs;
  final enableDownloaderManager = false.obs;
  final enableSpecialDownload = false.obs;
  final useExternalBrowser = false.obs;
  final enableFetchMediaserverLibraryStatus = false.obs;

  // 背景图设置
  final backgroundImageEnabled = false.obs;
  final backgroundImageOpacity = 0.5.obs;
  final backgroundImageGradientTop = Colors.transparent.obs;
  final backgroundImageGradientBottom = Colors.black.obs;
  final backgroundImageBytes = Rxn<Uint8List>();
  final backgroundImageUseServer = false.obs;
  final backgroundImageServerUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = service.themeMode.value;
    primaryColor.value = service.primaryColor.value;
    showSearchButton.value = service.showSearchButton.value;
    enableDownloaderManager.value = service.enableDownloaderManager.value;
    enableSpecialDownload.value = service.enableSpecialDownload.value;
    useExternalBrowser.value = service.useExternalBrowser.value;
    enableFetchMediaserverLibraryStatus.value =
        service.enableFetchMediaserverLibraryStatus.value;

    // 同步背景图设置
    backgroundImageEnabled.value = service.backgroundImageEnabled.value;
    backgroundImageOpacity.value = service.backgroundImageOpacity.value;
    backgroundImageGradientTop.value = service.backgroundImageGradientTop.value;
    backgroundImageGradientBottom.value =
        service.backgroundImageGradientBottom.value;
    backgroundImageBytes.value = service.backgroundImageBytes.value;
    backgroundImageUseServer.value = service.backgroundImageUseServer.value;
    backgroundImageServerUrl.value = service.backgroundImageServerUrl.value;

    // 监听变化
    ever(
      service.backgroundImageEnabled,
      (v) => backgroundImageEnabled.value = v,
    );
    ever(
      service.backgroundImageOpacity,
      (v) => backgroundImageOpacity.value = v,
    );
    ever(
      service.backgroundImageGradientTop,
      (v) => backgroundImageGradientTop.value = v,
    );
    ever(
      service.backgroundImageGradientBottom,
      (v) => backgroundImageGradientBottom.value = v,
    );
    ever(service.backgroundImageBytes, (v) => backgroundImageBytes.value = v);
    ever(
      service.backgroundImageUseServer,
      (v) => backgroundImageUseServer.value = v,
    );
    ever(
      service.backgroundImageServerUrl,
      (v) => backgroundImageServerUrl.value = v,
    );

    loadAppVersion();
  }

  void updateThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    service.updateThemeMode(mode);
  }

  void updatePrimaryColor(Color color) {
    primaryColor.value = color;
    service.updatePrimaryColor(color);
  }

  void updateShowSearchButton(bool value) {
    showSearchButton.value = value;
    service.updateShowSearchButton(value);
  }

  void updateEnableDownloaderManager(bool value) {
    enableDownloaderManager.value = value;
    service.updateEnableDownloaderManager(value);
  }

  void updateEnableSpecialDownload(bool value) {
    enableSpecialDownload.value = value;
    service.updateEnableSpecialDownload(value);
  }

  void updateUseExternalBrowser(bool value) {
    useExternalBrowser.value = value;
    service.updateUseExternalBrowser(value);
  }

  void updateEnableFetchMediaserverLibraryStatus(bool value) {
    enableFetchMediaserverLibraryStatus.value = value;
    service.updateEnableFetchMediaserverLibraryStatus(value);
  }

  void updateBackgroundImageEnabled(bool value) {
    backgroundImageEnabled.value = value;
    service.updateBackgroundImageEnabled(value);
  }

  void updateBackgroundImageOpacity(double value) {
    backgroundImageOpacity.value = value;
    service.updateBackgroundImageOpacity(value);
  }

  void updateBackgroundImageGradientTop(Color color) {
    backgroundImageGradientTop.value = color;
    service.updateBackgroundImageGradientTop(color);
  }

  void updateBackgroundImageGradientBottom(Color color) {
    backgroundImageGradientBottom.value = color;
    service.updateBackgroundImageGradientBottom(color);
  }

  Future<void> updateBackgroundImage(Uint8List? bytes) async {
    await service.updateBackgroundImage(bytes);
    backgroundImageBytes.value = bytes;
  }

  Future<void> clearBackgroundImage() async {
    await service.clearBackgroundImage();
  }

  void updateBackgroundImageUseServer(bool value) {
    backgroundImageUseServer.value = value;
    service.updateBackgroundImageUseServer(value);
  }

  void updateBackgroundImageServerUrl(String url) {
    backgroundImageServerUrl.value = url;
    service.updateBackgroundImageServerUrl(url);
  }

  Future<bool> cacheBackgroundImageFromServerUrl() async {
    final ok = await service.cacheBackgroundImageFromServerUrl();
    backgroundImageBytes.value = service.backgroundImageBytes.value;
    return ok;
  }

  loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    version.value = '${packageInfo.version}+${packageInfo.buildNumber}';
  }
}
