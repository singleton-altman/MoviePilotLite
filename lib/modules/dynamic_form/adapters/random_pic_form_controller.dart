import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/random_pic_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/random_pic_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// RandomPic（随机图床API）插件适配器。
///
/// 插件在 Web 端通过 Vue 联邦组件渲染（`render_mode = vue`），
/// App 侧按插件对外暴露的真实接口重建原生界面：
/// - GET  `/api/v1/plugin/RandomPic/status`   运行状态与统计
/// - GET  `/api/v1/plugin/RandomPic/config`   配置（含默认目录）
/// - POST `/api/v1/plugin/RandomPic/config`   保存配置
/// - GET  `/api/v1/plugin/RandomPic/preview`  随机预览图（图片二进制）
/// - POST `/api/v1/plugin/RandomPic/preview/save` 将预览图保存到服务器本地
class RandomPicFormController extends GetxController
    implements PluginFormAdapter {
  RandomPicFormController({required this.formMode});

  @override
  final String pluginId = 'RandomPic';

  final bool formMode;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  static const _basePath = '/api/v1/plugin/RandomPic';

  @override
  final blocks = <FormBlock>[].obs;

  @override
  final pageNodes = <FormNode>[].obs;

  @override
  final formModel = Rx<Map<String, dynamic>>({});

  @override
  final isLoading = false.obs;

  @override
  final errorText = RxnString();

  @override
  final RxBool actionLoading = false.obs;

  /// 展示页依赖的实时状态
  final status = Rxn<RandomPicStatus>();

  /// 当前配置（保存与启停都会以它为基准，避免漏字段被服务端清空）
  final config = Rxn<RandomPicConfig>();

  /// 访问统计（GET /visits）
  final visits = Rxn<RandomPicVisits>();

  /// 图源测速结果（GET /ping）
  final pings = <String, RandomPicPing>{}.obs;

  /// 网络图片下载任务状态（GET /download/status）
  final downloadStatus = Rxn<RandomPicDownloadStatus>();

  /// 候选下载地址（GET /download/candidates）
  final candidates = <String>[].obs;

  final pinging = false.obs;
  final startingDownload = false.obs;

  Timer? _downloadTimer;

  @override
  bool get supportsSave => formMode;

  @override
  bool get supportsFormEntry => true;

  @override
  List<AppBarActionItem>? get actionList => const [
    AppBarActionItem(
      type: 'refresh',
      label: '刷新状态',
      iconName: 'mdi-refresh',
    ),
  ];

  @override
  Future<void> onAppBarAction(String type) async {
    if (type == 'refresh') await load();
  }

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  @override
  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    try {
      final token = _getToken();
      if (token == null || token.isEmpty) {
        errorText.value = '请先登录';
        blocks.clear();
        formModel.value = {};
        return;
      }

      if (formMode) {
        final statusMap = await _fetchStatus(token);
        if (statusMap != null) {
          status.value = RandomPicStatus.fromJson(statusMap);
        }
        final configMap = await _fetchConfig(token);
        if (configMap == null) {
          errorText.value = '获取插件配置失败';
          blocks.clear();
          formModel.value = {};
          return;
        }
        final parsed = RandomPicConfig.fromJson(configMap);
        config.value = parsed;
        formModel.value = parsed.toFormModel();
        blocks.assignAll(RandomPicConverter.convertForm(config: parsed));
        return;
      }

      final statusMap = await _fetchStatus(token);
      if (statusMap == null) {
        errorText.value = '获取插件状态失败';
        blocks.clear();
        return;
      }
      final parsed = RandomPicStatus.fromJson(statusMap);
      status.value = parsed;
      await _loadPageExtras(token);
      _rebuildBlocks();
      formModel.value = {};
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 RandomPic 数据失败');
      errorText.value = '请求失败，请稍后重试';
      blocks.clear();
      formModel.value = {};
    } finally {
      isLoading.value = false;
    }
  }

  /// 展示页附加数据：访问统计 + 下载任务状态（失败不影响主页面）
  Future<void> _loadPageExtras(String token) async {
    try {
      final resp = await _apiClient.get<dynamic>(
        '$_basePath/visits',
        token: token,
      );
      final map = _extractMap(resp.data);
      if (map != null) visits.value = RandomPicVisits.fromJson(map);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 RandomPic 访问统计失败');
    }
    await _refreshDownloadStatus(token);
  }

  void _rebuildBlocks() {
    final current = status.value;
    if (current == null) return;
    final list = <FormBlock>[
      ...RandomPicConverter.convertPage(
        status: current,
        visits: visits.value,
        pings: pings,
        downloadStatus: downloadStatus.value,
      ),
      if (visits.value != null)
        ...RandomPicConverter.convertVisits(visits.value!),
      ...RandomPicConverter.convertDownloadStatus(
        downloadStatus.value ??
            const RandomPicDownloadStatus(),
      ),
      ...RandomPicConverter.convertPings(pings),
    ];
    blocks.assignAll(list);
  }

  Future<void> _refreshDownloadStatus(String token) async {
    try {
      final resp = await _apiClient.get<dynamic>(
        '$_basePath/download/status',
        token: token,
      );
      final map = _extractMap(resp.data);
      if (map == null) return;
      final parsed = RandomPicDownloadStatus.fromJson(map);
      downloadStatus.value = parsed;
      if (parsed.running) {
        _startDownloadPolling();
      } else {
        _stopDownloadPolling();
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 RandomPic 下载状态失败');
    }
  }

  void _startDownloadPolling() {
    _downloadTimer?.cancel();
    _downloadTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final token = _getToken();
      if (token == null || token.isEmpty) return;
      await _refreshDownloadStatus(token);
      _rebuildBlocks();
    });
  }

  void _stopDownloadPolling() {
    _downloadTimer?.cancel();
    _downloadTimer = null;
  }

  /// 图源连通性测速
  Future<bool> pingSources() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return false;
    pinging.value = true;
    try {
      final resp = await _apiClient.get<dynamic>(
        '$_basePath/ping',
        token: token,
      );
      final map = _extractMap(resp.data);
      final data = map?['data'];
      if (data is Map) {
        final result = <String, RandomPicPing>{};
        for (final entry in data.entries) {
          if (entry.value is Map) {
            result[entry.key.toString()] = RandomPicPing.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            );
          }
        }
        pings.assignAll(result);
        _rebuildBlocks();
        return true;
      }
      ToastUtil.error(map?['message']?.toString() ?? '测速失败');
      return false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: 'RandomPic 图源测速失败');
      ToastUtil.error('测速失败，请稍后重试');
      return false;
    } finally {
      pinging.value = false;
    }
  }

  /// 获取候选下载地址
  Future<List<String>> loadCandidates({
    String source = 'both',
    int count = 30,
  }) async {
    final token = _getToken();
    if (token == null || token.isEmpty) return const [];
    try {
      final resp = await _apiClient.get<dynamic>(
        '$_basePath/download/candidates?source=$source&count=$count',
        token: token,
      );
      final map = _extractMap(resp.data);
      final data = map?['data'];
      final urls = <String>[];
      if (data is Map && data['urls'] is List) {
        for (final url in data['urls'] as List) {
          final text = url?.toString() ?? '';
          if (text.startsWith('http')) urls.add(text);
        }
      }
      candidates.assignAll(urls);
      return urls;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 RandomPic 候选图片失败');
      return const [];
    }
  }

  /// 启动网络图片下载；[urls] 为空时按 [source]/[count] 由插件自行解析
  Future<RandomPicActionResult> startDownload({
    List<String>? urls,
    String source = 'both',
    int? count,
  }) async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      return const RandomPicActionResult(false, '请先登录');
    }
    startingDownload.value = true;
    try {
      final body = <String, dynamic>{
        if (urls != null && urls.isNotEmpty) 'urls': urls,
        if (urls == null || urls.isEmpty) 'source': source,
        if (urls == null || urls.isEmpty) 'count': count ?? 20,
      };
      final resp = await _apiClient.postJson<dynamic>(
        '$_basePath/download',
        body,
        token: token,
      );
      final map = _extractMap(resp.data);
      final ok = (resp.statusCode ?? 0) < 400 && map?['success'] != false;
      final message =
          map?['msg']?.toString() ?? map?['message']?.toString() ?? '';
      if (ok) {
        await _refreshDownloadStatus(token);
        _startDownloadPolling();
        _rebuildBlocks();
      }
      return RandomPicActionResult(
        ok,
        message.isEmpty ? (ok ? '下载任务已启动' : '启动失败') : message,
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '启动 RandomPic 下载失败');
      return const RandomPicActionResult(false, '启动失败，请稍后重试');
    } finally {
      startingDownload.value = false;
    }
  }

  @override
  void onClose() {
    _stopDownloadPolling();
    super.onClose();
  }

  @override
  Future<bool> save() async {
    if (formModel.value.isEmpty) return false;
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    isLoading.value = true;
    errorText.value = null;
    try {
      final body = RandomPicConverter.toConfigBody(formModel.value);
      final result = await _postConfig(body, token);
      if (result != null && result.success) {
        await load();
        return true;
      }
      errorText.value = result?.message ?? '保存失败';
      return false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 RandomPic 配置失败');
      errorText.value = '保存失败，请稍后重试';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 启用/禁用：以完整配置为基准提交，避免服务端把未传字段写成空值。
  Future<bool> setEnabled(bool enabled) async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    actionLoading.value = true;
    errorText.value = null;
    try {
      final baseConfig =
          config.value ??
          RandomPicConfig.fromJson(await _fetchConfig(token) ?? const {});
      final result = await _postConfig(
        baseConfig.copyWith(enable: enabled).toRequestBody(),
        token,
      );
      if (result != null && result.success) {
        config.value = baseConfig.copyWith(enable: enabled);
        await load();
        return true;
      }
      errorText.value = result?.message ?? (enabled ? '启用失败' : '禁用失败');
      return false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '切换 RandomPic 状态失败');
      errorText.value = '操作失败，请稍后重试';
      return false;
    } finally {
      actionLoading.value = false;
    }
  }

  /// 随机预览图地址。[type] 取 auto / pc / mobile
  String previewUrl(String type) {
    final base = (_apiClient.baseUrl ?? '').replaceAll(RegExp(r'/+$'), '');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final typeQuery = type == 'auto' ? '' : '&type=$type';
    return '$base$_basePath/preview?t=$stamp$typeQuery';
  }

  Future<Uint8List?> fetchPreview(String type) async {
    return _apiClient.fetchResourceProxyImage(previewUrl(type));
  }

  /// 把当前预览图保存到服务器本地目录（插件会按横竖屏自动分类）。
  Future<RandomPicActionResult> savePreviewToLocal(Uint8List bytes) async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      return const RandomPicActionResult(false, '请先登录');
    }
    try {
      final formData = dio.FormData();
      formData.files.add(
        MapEntry(
          'file',
          dio.MultipartFile.fromBytes(bytes, filename: 'preview-image.jpg'),
        ),
      );
      final response = await _apiClient.postMultipart<dynamic>(
        '$_basePath/preview/save',
        formData,
        token: token,
      );
      if ((response.statusCode ?? 0) >= 400) {
        return RandomPicActionResult(false, '保存失败 (HTTP ${response.statusCode})');
      }
      final map = _extractMap(response.data);
      final success = map?['success'] != false;
      final message = map?['msg']?.toString() ?? '已保存到本地目录';
      return RandomPicActionResult(success, message);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存预览图到本地失败');
      return const RandomPicActionResult(false, '保存到本地目录失败');
    }
  }

  Future<Map<String, dynamic>?> _fetchStatus(String token) async {
    final response = await _apiClient.get<dynamic>(
      '$_basePath/status',
      token: token,
    );
    if ((response.statusCode ?? 0) >= 400) return null;
    return _extractMap(response.data);
  }

  Future<Map<String, dynamic>?> _fetchConfig(String token) async {
    final response = await _apiClient.get<dynamic>(
      '$_basePath/config',
      token: token,
    );
    if ((response.statusCode ?? 0) >= 400) return null;
    return _extractMap(response.data);
  }

  Future<RandomPicActionResult?> _postConfig(
    Map<String, dynamic> body,
    String token,
  ) async {
    final response = await _apiClient.postJson<dynamic>(
      '$_basePath/config',
      body,
      token: token,
    );
    if ((response.statusCode ?? 0) >= 400) {
      final map = _extractMap(response.data);
      return RandomPicActionResult(
        false,
        map?['detail']?.toString() ??
            map?['message']?.toString() ??
            map?['msg']?.toString() ??
            'HTTP ${response.statusCode}',
      );
    }
    final map = _extractMap(response.data);
    if (map == null) return const RandomPicActionResult(true, '保存成功');
    return RandomPicActionResult(
      map['success'] != false,
      map['msg']?.toString() ??
          map['message']?.toString() ??
          '保存成功',
    );
  }

  Map<String, dynamic>? _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

/// 插件接口的轻量结果：success + 提示文案
class RandomPicActionResult {
  const RandomPicActionResult(this.success, this.message);

  final bool success;
  final String message;
}
