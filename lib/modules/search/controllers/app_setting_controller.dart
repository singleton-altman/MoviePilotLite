import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/models/app_update_info.dart';
import 'package:moviepilot_mobile/modules/search/pages/update_mirror_sheet.dart';
import 'package:moviepilot_mobile/modules/search/services/app_update_installer.dart';
import 'package:moviepilot_mobile/modules/search/services/app_update_service.dart';
import 'package:moviepilot_mobile/modules/search/services/update_mirror_store.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/models/app_icon_option.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppSettingController extends GetxController {
  final themeMode = ThemeMode.system.obs;
  final primaryColor = Color(0xFF007AFF).obs;
  final selectedAppIconId = 'default'.obs;
  final isChangingAppIcon = false.obs;
  final service = Get.find<AppService>();
  final version = '1.0.0'.obs;
  final showSearchButton = true.obs;
  final enableDownloaderManager = false.obs;
  final enableSpecialDownload = false.obs;
  final useExternalBrowser = false.obs;
  final enableFetchMediaserverLibraryStatus = false.obs;
  final isCheckingUpdate = false.obs;
  final isDownloadingUpdate = false.obs;
  final downloadProgress = 0.0.obs;
  final updateInfo = Rxn<AppUpdateInfo>();
  final downloadedApkPath = RxnString();
  CancelToken? _downloadCancelToken;
  late final AppUpdateService _updateService;
  late final UpdateMirrorStore _mirrorStore;

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
    selectedAppIconId.value = service.selectedAppIconId.value;
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
    _updateService = Get.isRegistered<AppUpdateService>()
        ? Get.find<AppUpdateService>()
        : Get.put(AppUpdateService(), permanent: true);
    _mirrorStore = Get.isRegistered<UpdateMirrorStore>()
        ? Get.find<UpdateMirrorStore>()
        : Get.put(UpdateMirrorStore(), permanent: true);

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

  Future<void> updateAppIcon(AppIconOption option) async {
    if (isChangingAppIcon.value || selectedAppIconId.value == option.id) return;
    isChangingAppIcon.value = true;
    try {
      final changed = await service.updateAppIcon(option.id);
      if (changed) {
        selectedAppIconId.value = option.id;
        Get.rawSnackbar(message: '已切换为「${option.name}」图标');
      } else {
        Get.rawSnackbar(message: '当前平台暂不支持更换应用图标');
      }
    } finally {
      isChangingAppIcon.value = false;
    }
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

  String get updateStatusText {
    if (isCheckingUpdate.value) return '检查中';
    if (isDownloadingUpdate.value) {
      final percent = (downloadProgress.value * 100)
          .clamp(0, 100)
          .toStringAsFixed(0);
      return '$percent%';
    }
    final info = updateInfo.value;
    if (info != null && info.isNewer) {
      return '发现 ${info.latestLabel}';
    }
    return version.value;
  }

  String get updateMirrorLabel => _mirrorStore.selectedMirror.label;

  Future<void> handleVersionTap(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      ToastUtil.info('当前平台暂不支持检查更新');
      return;
    }
    if (isDownloadingUpdate.value) {
      _showDownloadProgressSheet();
      return;
    }
    final info = updateInfo.value;
    final apkPath = downloadedApkPath.value;
    if (Platform.isAndroid &&
        info != null &&
        info.isNewer &&
        apkPath != null &&
        apkPath.isNotEmpty) {
      await installDownloadedApk();
      return;
    }
    await checkForUpdate(showUpToDate: true);
  }

  Future<void> checkForUpdate({bool showUpToDate = false}) async {
    if (isCheckingUpdate.value) return;
    isCheckingUpdate.value = true;
    try {
      final info = await _updateService.fetchLatestRelease();
      updateInfo.value = info;
      if (!info.isNewer) {
        if (Platform.isIOS) {
          _showUpdateDialog(info);
          return;
        }
        if (showUpToDate) {
          ToastUtil.success('当前已是最新版本');
        }
        return;
      }
      _showUpdateDialog(info);
    } on AppUpdateException catch (e) {
      // 拉取失败往往正是加速源不可用所致，必须仍能进入线路设置自救。
      ToastUtil.error(e.message, mainButtonText: '配置加速源', onMainButtonPressed: _openMirrorManagerFromToast);
    } catch (_) {
      ToastUtil.error('检查更新失败，请稍后重试', mainButtonText: '配置加速源', onMainButtonPressed: _openMirrorManagerFromToast);
    } finally {
      isCheckingUpdate.value = false;
    }
  }

  /// 从提示条直接打开线路管理，用于检查更新失败后的自救入口。
  void _openMirrorManagerFromToast() {
    final context = Get.context;
    if (context == null) return;
    _openMirrorManager(
      context,
      sourceUrl: updateInfo.value?.apkDownloadUrl ?? '',
    );
  }

  Future<void> downloadLatestApk(AppUpdateInfo info) async {
    if (isDownloadingUpdate.value) {
      _showDownloadProgressSheet();
      return;
    }
    if (!info.hasApk) {
      ToastUtil.error('最新 Release 未找到 APK 安装包');
      return;
    }

    await _mirrorStore.ensureLoaded();
    final mirror = _mirrorStore.selectedMirror;
    isDownloadingUpdate.value = true;
    downloadProgress.value = 0;
    downloadedApkPath.value = null;
    _downloadCancelToken = CancelToken();
    _showDownloadProgressSheet();
    try {
      final path = await _updateService.downloadApk(
        info,
        mirror: mirror,
        cancelToken: _downloadCancelToken,
        onProgress: (received, total) {
          if (total > 0) {
            downloadProgress.value = received / total;
          }
        },
      );
      downloadedApkPath.value = path;
      downloadProgress.value = 1;
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
      _showInstallDialog(info);
    } on DioException catch (e) {
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
      if (CancelToken.isCancel(e)) {
        ToastUtil.info('已取消下载');
      } else {
        ToastUtil.error('APK 下载失败，请稍后重试');
      }
    } catch (_) {
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
      ToastUtil.error('APK 下载失败，请稍后重试');
    } finally {
      isDownloadingUpdate.value = false;
      _downloadCancelToken = null;
    }
  }

  void sendDownloadToBackground() {
    if (!isDownloadingUpdate.value) return;
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    ToastUtil.info('更新包已转入后台下载');
  }

  void cancelUpdateDownload() {
    if (!isDownloadingUpdate.value) return;
    _downloadCancelToken?.cancel('user_cancelled');
  }

  Future<void> installDownloadedApk() async {
    final path = downloadedApkPath.value;
    if (path == null || path.isEmpty) {
      ToastUtil.info('请先下载最新 APK');
      return;
    }
    final result = await AppUpdateInstaller.installApk(path);
    switch (result) {
      case AppInstallResult.launched:
        ToastUtil.success('已打开系统安装器');
      case AppInstallResult.permissionRequired:
        ToastUtil.info('请允许安装未知来源应用后再次点击安装');
      case AppInstallResult.missingFile:
        downloadedApkPath.value = null;
        ToastUtil.error('安装包已失效，请重新下载');
      case AppInstallResult.unsupported:
        ToastUtil.error('当前设备不支持自动安装 APK');
    }
  }

  /// 仅测试使用：覆盖平台判断，验证各平台下的内容与按钮。
  @visibleForTesting
  /// 仅测试使用：覆盖 Android 平台判断。
  @visibleForTesting
  bool? debugIsAndroidOverride;

  /// 仅测试使用：直接打开更新弹框。
  @visibleForTesting
  void showUpdateDialogForTest(AppUpdateInfo info) => _showUpdateDialog(info);

  bool get _isAndroid => debugIsAndroidOverride ?? Platform.isAndroid;

  void _showUpdateDialog(AppUpdateInfo info) {
    final canDownloadApk = _isAndroid;
    final size = info.apkSize == null
        ? ''
        : SizeFormatter.formatSize(info.apkSize!.toDouble());
    final notes = _normalizedReleaseNotes(info.releaseNotes);
    Get.dialog<void>(
      Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final screenHeight = MediaQuery.sizeOf(context).height;
          final maxHeight = screenHeight * 0.76;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.system_update_alt_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.isNewer ? '发现新版本' : '版本更新日志',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                info.releaseName.isEmpty
                                    ? info.tagName
                                    : info.releaseName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildUpdateVersionChip(
                                context,
                                label: '当前版本',
                                value: info.currentLabel,
                              ),
                              _buildUpdateVersionChip(
                                context,
                                label: '最新版本',
                                value: info.latestLabel,
                                emphasized: true,
                              ),
                              if (size.isNotEmpty)
                                _buildUpdateVersionChip(
                                  context,
                                  label: canDownloadApk ? '安装包' : 'Release',
                                  value: size,
                                ),
                            ],
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              '更新内容',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.42),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: MarkdownBody(
                                data: notes,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet.fromTheme(theme)
                                    .copyWith(
                                      p: theme.textTheme.bodyMedium?.copyWith(
                                        height: 1.45,
                                      ),
                                      listBullet: theme.textTheme.bodyMedium,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            color: colorScheme.surfaceContainerHighest,
                            onPressed: Get.back,
                            child: Text(
                              info.isNewer ? '稍后' : '关闭',
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            color: colorScheme.primary,
                            onPressed: () {
                              Get.back();
                              if (!canDownloadApk) {
                                WebUtil.open(
                                  url: info.releaseUrl,
                                  internal: false,
                                );
                              } else if (info.isNewer) {
                                downloadLatestApk(info);
                              }
                            },
                            child: Text(
                              canDownloadApk
                                  ? (info.isNewer ? '下载更新' : '完成')
                                  : '前往 Release',
                              style: TextStyle(color: colorScheme.onPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildUpdateVersionChip(
    BuildContext context, {
    required String label,
    required String value,
    bool emphasized = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = emphasized
        ? colorScheme.primary.withValues(alpha: 0.12)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.52);
    final fg = emphasized ? colorScheme.primary : colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emphasized
              ? colorScheme.primary.withValues(alpha: 0.18)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMirrorManager(
    BuildContext context, {
    String sourceUrl = '',
  }) async {
    await showUpdateMirrorSheet(context, sourceUrl: sourceUrl);
  }

  void _showInstallDialog(AppUpdateInfo info) {
    Get.dialog<void>(
      CupertinoAlertDialog(
        title: const Text('下载完成'),
        content: Text('MoviePilot ${info.latestLabel} 已下载完成，可以开始安装。'),
        actions: [
          CupertinoDialogAction(onPressed: Get.back, child: const Text('稍后')),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Get.back();
              installDownloadedApk();
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  void _showDownloadProgressSheet() {
    if (Get.isBottomSheetOpen == true) return;
    Get.bottomSheet<void>(
      Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return Obx(
            () => SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '正在下载更新',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(downloadProgress.value * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: downloadProgress.value <= 0
                          ? null
                          : downloadProgress.value.clamp(0, 1),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: colorScheme.surfaceContainerHighest,
                            onPressed: sendDownloadToBackground,
                            child: Text(
                              '后台下载',
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: colorScheme.error,
                            onPressed: cancelUpdateDownload,
                            child: Text(
                              '取消下载',
                              style: TextStyle(color: colorScheme.onError),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  String _normalizedReleaseNotes(String notes) {
    final normalized = notes
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
    return normalized;
  }

  loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    version.value = '${packageInfo.version}+${packageInfo.buildNumber}';
  }
}
