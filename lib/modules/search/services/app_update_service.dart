import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/search/models/app_update_info.dart';
import 'package:moviepilot_mobile/modules/search/models/update_mirror.dart';
import 'package:moviepilot_mobile/modules/settings/models/system_env_model.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateService extends GetxService {
  AppUpdateService() : _dio = Dio(_baseOptions);

  static const String releasesApi =
      'https://api.github.com/repos/singleton-altman/MoviePilotLite/releases';
  static const String releasesUrl =
      'https://github.com/singleton-altman/MoviePilotLite/releases';
  static const Duration cachedApkTtl = Duration(days: 7);
  static final RegExp _androidReleaseTagPattern = RegExp(
    r'^release-v\d+(?:\.\d+){1,3}-\d{4}-\d{2}-\d{2}$',
    caseSensitive: false,
  );

  static final BaseOptions _baseOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 10),
    sendTimeout: const Duration(seconds: 30),
    followRedirects: true,
    maxRedirects: 5,
    headers: const {
      'accept': 'application/vnd.github+json',
      'user-agent': 'MoviePilotLite-Mobile',
    },
    validateStatus: (status) => status != null && status < 500,
  );

  final Dio _dio;
  final _log = Get.find<AppLog>();
  final _apiClient = Get.find<ApiClient>();

  Future<AppUpdateInfo> fetchLatestRelease() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber);
    final githubToken = await _loadConfiguredGithubToken();
    final response = await _dio.get<dynamic>(
      releasesApi,
      queryParameters: const {'per_page': 30},
      options: Options(headers: _githubHeaders(githubToken)),
    );
    final status = response.statusCode ?? 0;
    if (status == 403 && _isRateLimited(response.data)) {
      throw AppUpdateException(
        githubToken == null
            ? 'GitHub API 已限流，请先在系统基础设置中配置 Github Token'
            : 'GitHub API 已限流，请检查 Github Token 是否有效',
      );
    }
    final releases = response.data;
    if (status < 200 || status >= 300 || releases is! List) {
      throw AppUpdateException('获取最新版本失败');
    }

    final data = _selectLatestAndroidRelease(releases);
    if (data == null) {
      throw AppUpdateException('未找到合法的安卓发布版本');
    }
    final assets = data['assets'];
    final apkAsset = assets is List
        ? _selectApkAsset(assets.whereType<Map>().toList())
        : null;
    final tagName = _stringValue(data['tag_name']);
    final releaseName = _stringValue(data['name']);
    final versionSource = [
      tagName,
      releaseName,
      _stringValue(apkAsset?['name']),
    ].firstWhere((value) => value.trim().isNotEmpty, orElse: () => '0.0.0');
    final latestVersion = ParsedReleaseVersion.fromText(versionSource);

    return AppUpdateInfo(
      currentVersion: packageInfo.version,
      currentBuildNumber: currentBuild,
      latestVersion: latestVersion.version,
      latestBuildNumber: latestVersion.buildNumber,
      tagName: tagName,
      releaseName: releaseName.isEmpty ? tagName : releaseName,
      releaseUrl: _stringValue(data['html_url'], fallback: releasesUrl),
      releaseNotes: _stringValue(data['body']),
      apkDownloadUrl: _stringValue(apkAsset?['browser_download_url']),
      apkAssetName: _stringValue(apkAsset?['name']),
      apkSize: _intValue(apkAsset?['size']),
      publishedAt: DateTime.tryParse(_stringValue(data['published_at'])),
    );
  }

  /// 按 [mirror] 指定的线路下载 APK。
  ///
  /// 加速源失败（网络错误或返回非安装包内容）时，若 [fallbackToDirect] 为真则
  /// 自动改用直连重试一次，避免用户手动切换线路。
  Future<String> downloadApk(
    AppUpdateInfo info, {
    UpdateMirror mirror = const UpdateMirror.direct(),
    bool fallbackToDirect = true,
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    if (!info.hasApk) {
      throw AppUpdateException('未找到 APK 安装包');
    }
    final attempts = <UpdateMirror>[
      mirror,
      if (fallbackToDirect && !mirror.isDirect) const UpdateMirror.direct(),
    ];
    Object? lastError;
    for (var index = 0; index < attempts.length; index++) {
      final current = attempts[index];
      try {
        return await _downloadOnce(
          info,
          current,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
      } catch (e) {
        if (e is DioException && CancelToken.isCancel(e)) rethrow;
        lastError = e;
        if (index < attempts.length - 1) {
          _log.warning('经 ${current.label} 下载失败，改用直连重试: $e');
          onProgress(0, 0);
        }
      }
    }
    if (lastError is AppUpdateException) throw lastError;
    throw AppUpdateException(
      lastError == null ? 'APK 下载失败' : 'APK 下载失败：$lastError',
    );
  }

  Future<String> _downloadOnce(
    AppUpdateInfo info,
    UpdateMirror mirror, {
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final updateDir = await _updateCacheDirectory(create: true);
    final fileName = _safeFileName(
      info.apkAssetName.isEmpty
          ? 'MoviePilot-${info.latestLabel}.apk'
          : info.apkAssetName,
    );
    final file = File('${updateDir.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
    try {
      await _dio.download(
        mirror.resolve(info.apkDownloadUrl),
        file.path,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
          headers: const {'accept': 'application/octet-stream'},
        ),
      );
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      if (!exists || size <= 0) {
        throw AppUpdateException('APK 下载失败');
      }
      if (!await _looksLikeApk(file)) {
        throw AppUpdateException('${mirror.label} 返回的不是安装包，请更换加速源');
      }
    } catch (_) {
      await _deleteFileIfExists(file);
      rethrow;
    }
    _log.info('APK 下载完成（${mirror.label}）: ${file.path}');
    return file.path;
  }

  /// APK 是 ZIP 容器，头部必须是 `PK\x03\x04`。加速源异常时常常返回 HTML 错误页。
  Future<bool> _looksLikeApk(File file) async {
    try {
      final raf = await file.open();
      try {
        final header = await raf.read(4);
        return header.length >= 4 &&
            header[0] == 0x50 &&
            header[1] == 0x4B &&
            header[2] == 0x03 &&
            header[3] == 0x04;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> cleanupExpiredApkCache({Duration maxAge = cachedApkTtl}) async {
    try {
      final updateDir = await _updateCacheDirectory(create: false);
      if (!await updateDir.exists()) return;
      final now = DateTime.now();
      await for (final entity in updateDir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last.toLowerCase();
        if (!name.endsWith('.apk')) continue;
        final stat = await entity.stat();
        if (maxAge == Duration.zero || now.difference(stat.modified) > maxAge) {
          await _deleteFileIfExists(entity);
        }
      }
    } catch (e) {
      _log.warning('清理过期 APK 缓存失败: $e');
    }
  }

  Map<dynamic, dynamic>? _selectApkAsset(List<Map<dynamic, dynamic>> assets) {
    final apkAssets = assets.where((asset) {
      final name = _stringValue(asset['name']).toLowerCase();
      return name.endsWith('.apk');
    }).toList();
    if (apkAssets.isEmpty) return null;
    apkAssets.sort((a, b) => _assetScore(b).compareTo(_assetScore(a)));
    return apkAssets.first;
  }

  Map<dynamic, dynamic>? _selectLatestAndroidRelease(List<dynamic> releases) {
    final candidates = releases.whereType<Map>().where((release) {
      final tagName = _stringValue(release['tag_name']);
      return _androidReleaseTagPattern.hasMatch(tagName);
    }).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final left = DateTime.tryParse(_stringValue(a['published_at']));
      final right = DateTime.tryParse(_stringValue(b['published_at']));
      if (left != null && right != null) return right.compareTo(left);
      if (left != null) return -1;
      if (right != null) return 1;
      return _stringValue(b['tag_name']).compareTo(_stringValue(a['tag_name']));
    });
    return candidates.first;
  }

  int _assetScore(Map<dynamic, dynamic> asset) {
    final name = _stringValue(asset['name']).toLowerCase();
    var score = 0;
    if (name.contains('universal')) score += 8;
    if (name.contains('android')) score += 6;
    if (name.contains('release')) score += 4;
    if (name.contains('arm64')) score += 2;
    if (name.contains('debug')) score -= 8;
    return score;
  }

  String _safeFileName(String value) {
    final trimmed = value.trim();
    final name = trimmed.isEmpty ? 'MoviePilot.apk' : trimmed;
    return name.replaceAll(RegExp(r'[^\w.\-()+]'), '_');
  }

  Future<Directory> _updateCacheDirectory({required bool create}) async {
    final dir = await getTemporaryDirectory();
    final updateDir = Directory('${dir.path}/app_updates');
    if (create && !await updateDir.exists()) {
      await updateDir.create(recursive: true);
    }
    return updateDir;
  }

  Future<void> _deleteFileIfExists(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      _log.warning('删除 APK 缓存失败: $e');
    }
  }

  String _stringValue(Object? value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, String> _githubHeaders(String? token) {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty) return const {};
    return {'authorization': 'Bearer $normalized'};
  }

  Future<String?> _loadConfiguredGithubToken() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/system/env',
        skipUnauthorizedHandling: true,
      );
      final status = response.statusCode ?? 0;
      final body = response.data;
      if (status < 200 || status >= 300 || body == null) return null;
      final parsed = SystemEnvResponse.fromJson(body);
      final data = parsed.data;
      final token = data?.githubToken?.trim();
      if (token != null && token.isNotEmpty) return token;
      final repoToken = data?.repoGithubToken?.trim();
      return repoToken == null || repoToken.isEmpty ? null : repoToken;
    } catch (e) {
      _log.warning('读取 Github Token 失败: $e');
      return null;
    }
  }

  bool _isRateLimited(Object? data) {
    if (data is! Map) return false;
    final message = _stringValue(data['message']).toLowerCase();
    return message.contains('rate limit');
  }
}

class AppUpdateException implements Exception {
  AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}
