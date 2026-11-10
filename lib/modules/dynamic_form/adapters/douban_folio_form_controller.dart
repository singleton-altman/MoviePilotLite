import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/douban_folio_converter.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// DoubanFolio（豆瓣档案）插件适配器。
///
/// 插件在 Web 端通过 Vue 联邦组件渲染（`render_mode = vue`），
/// App 侧按插件对外暴露的真实接口重建原生界面：
/// - GET  `/api/v1/plugin/DoubanFolio/config`              配置（含登录态扩展字段）
/// - POST `/api/v1/plugin/DoubanFolio/config`              保存配置
/// - GET  `/api/v1/plugin/DoubanFolio/status`              运行状态
/// - GET  `/api/v1/plugin/DoubanFolio/logs`                同步记录
/// - GET  `/api/v1/plugin/DoubanFolio/qr/start`            获取豆瓣登录二维码
/// - GET  `/api/v1/plugin/DoubanFolio/qr/poll`             轮询扫码状态（约 2 秒一次）
/// - POST `/api/v1/plugin/DoubanFolio/auto_subscribe/check` 立即检查想看自动订阅
class DoubanFolioFormController extends GetxController
    implements PluginFormAdapter {
  DoubanFolioFormController({required this.formMode});

  @override
  final String pluginId = 'DoubanFolio';

  final bool formMode;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  static const _basePath = '/api/v1/plugin/DoubanFolio';
  static const basePathConfig = '$_basePath/config';
  static const basePathStatus = '$_basePath/status';
  static const basePathLogs = '$_basePath/logs';
  static const basePathQrStart = '$_basePath/qr/start';
  static const basePathQrPoll = '$_basePath/qr/poll';
  static const basePathSummary = '$_basePath/collection/summary';
  static const basePathCollection = '$_basePath/collection';
  static const autoSubscribeCheckPath = '$_basePath/auto_subscribe/check';

  /// 海报代理地址：插件服务端下载豆瓣海报，规避图床反爬。
  ///
  /// 插件 /cover 接口只接受 `https://imgN.doubanio.com/view/photo/...` 完整 URL
  /// （见 douban_collect.cover_hosts_path），poster_hd 可能带其他 imgN 子域，
  /// 统一改写为 img1（与 Web 端 Dashboard.vue/AppPage.vue 的 fetchCoverBlob 一致）。
  String coverUrl(String poster) {
    if (poster.isEmpty) return '';
    final path = poster.replaceFirst(
      RegExp(r'^https://img\d+\.doubanio\.com'),
      '',
    );
    return '$_basePath/cover?img=${Uri.encodeComponent('https://img1.doubanio.com$path')}';
  }

  /// 海报字节缓存（sid/poster → bytes），避免列表滚动重复请求
  final Map<String, Uint8List> _coverBytesCache = {};

  /// 已缓存的海报字节（不触发请求）
  Uint8List? peekCoverBytes(String poster) => _coverBytesCache[poster];

  /// 经鉴权接口拉取海报字节（Image.network 无法携带 Bearer token，会 401）
  Future<Uint8List?> fetchCoverBytes(String poster) async {
    if (poster.isEmpty) return null;
    final cached = _coverBytesCache[poster];
    if (cached != null) return cached;
    final token = _getToken();
    if (token == null || token.isEmpty) return null;
    final url = '${(_apiClient.baseUrl ?? '').replaceAll(RegExp(r'/+$'), '')}'
        '${coverUrl(poster)}';
    final bytes = await _apiClient.fetchResourceProxyImage(url);
    if (bytes != null && bytes.length > 100) {
      _coverBytesCache[poster] = bytes;
      return bytes;
    }
    return null;
  }

  @override
  final blocks = <FormBlock>[].obs;

  @override
  final pageNodes = <FormNode>[].obs;

  @override
  final formModel = Rx<Map<String, dynamic>>({});

  @override
  final isLoading = false.obs;

  @override
  final RxBool actionLoading = false.obs;

  @override
  final errorText = RxnString();

  /// 运行状态（GET /status）
  final statusData = Rxn<DoubanFolioStatus>();

  /// 同步记录（GET /logs）
  final logs = <DoubanFolioLog>[].obs;

  /// 扫码状态
  final qrImg = RxnString();
  final qrStatus = RxnString();
  final qrError = RxnString();
  final qrNickname = RxnString();
  final qrExpiresIn = 0.obs;
  final qrPolling = false.obs;
  final autoSubscribeChecking = false.obs;
  final autoSubscribeResult = RxnString();

  /// 收藏仪表盘统计（GET /collection/summary：wish/doing/done + 最近条目）
  final summary = Rxn<Map<String, dynamic>>();

  /// 收藏列表（GET /collection）
  final collectionStatus = 'sync'.obs; // sync / wish / do / collect（与 Web 端页签一致，默认「同步」）
  final collectionCategory = 'movie'.obs; // movie / book / music
  final collectionItems = <Map<String, dynamic>>[].obs;
  final collectionTotal = 0.obs;
  final collectionLoading = false.obs;
  final collectionLoadingMore = false.obs;
  final collectionError = RxnString();

  Timer? _pollTimer;
  Timer? _countdownTimer;

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

      // 拉取配置（form 与 page 都需要登录态字段）
      final configMap = await _fetch(basePathConfig, token);
      if (configMap == null) {
        errorText.value = '获取插件配置失败';
        blocks.clear();
        formModel.value = {};
        return;
      }
      formModel.value = Map<String, dynamic>.from(configMap);
      blocks.assignAll(
        DoubanFolioConverter.convertForm(config: configMap),
      );

      // 页面模式补充状态与同步记录
      final statusMap = await _fetch(basePathStatus, token);
      if (statusMap != null) {
        statusData.value = DoubanFolioStatus.fromJson(statusMap);
      }
      unawaited(loadLogs());

      // 未登录且配置页时自动拉起二维码；已登录页面模式拉收藏仪表盘
      final loggedIn = configMap['logged_in'] == true;
      if (!loggedIn && formMode) {
        await startQrLogin();
      } else if (loggedIn && !formMode) {
        unawaited(loadSummary());
        unawaited(loadCollection());
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 DoubanFolio 数据失败');
      errorText.value = '请求失败，请稍后重试';
      blocks.clear();
      formModel.value = {};
    } finally {
      isLoading.value = false;
    }
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
      final body = DoubanFolioConverter.toConfigBody(formModel.value);
      final response = await _apiClient.postJson<dynamic>(
        basePathConfig,
        body,
        token: token,
      );
      if ((response.statusCode ?? 0) >= 400) {
        errorText.value = '保存失败 (HTTP ${response.statusCode})';
        return false;
      }
      final map = _extractMap(response.data);
      final success = map?['success'] != false;
      if (!success) {
        errorText.value = map?['message']?.toString() ?? '保存失败';
        return false;
      }
      // 响应 data 为保存后的完整配置，回填
      final data = map?['data'];
      if (data is Map) {
        formModel.value = Map<String, dynamic>.from(data);
        blocks.assignAll(
          DoubanFolioConverter.convertForm(
            config: formModel.value,
          ),
        );
      }
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 DoubanFolio 配置失败');
      errorText.value = '保存失败，请稍后重试';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载收藏统计（想看/在看/看过 + 最近条目）
  Future<void> loadSummary() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    try {
      final map = await _fetch(basePathSummary, token);
      if (map != null && map['success'] == true) {
        summary.value = map;
      }
    } catch (e) {
      _log.info('DoubanFolio 收藏统计加载失败: $e');
    }
  }

  /// 加载同步记录（GET /logs，媒体库同步到豆瓣的记录）
  Future<void> loadLogs() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    try {
      final response = await _apiClient.get<dynamic>(basePathLogs, token: token);
      if ((response.statusCode ?? 0) >= 400) return;
      final raw = response.data;
      // v3 信封拦截器对 data 为列表的响应会直接返回载荷本身，
      // 因此这里同时兼容「裸列表」和「{success, data:[...]}」两种形状
      List? list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        final data = raw['data'];
        if (data is List) list = data;
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            list = decoded;
          } else if (decoded is Map && decoded['data'] is List) {
            list = decoded['data'] as List;
          }
        } catch (_) {}
      }
      if (list != null) {
        logs.assignAll(
          list
              .whereType<Map>()
              .map((entry) => DoubanFolioLog.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList(),
        );
      }
    } catch (e) {
      _log.info('DoubanFolio 同步记录加载失败: $e');
    }
  }

  /// 加载收藏列表（重置到第一页）
  Future<void> loadCollection() async {
    // 「同步」页签展示 /logs 记录，不请求收藏接口
    if (collectionStatus.value == 'sync') return;
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    if (collectionLoading.value) return;
    collectionLoading.value = true;
    collectionError.value = null;
    try {
      final map = await _fetchCollection(start: 0, token: token);
      if (map == null || map['success'] != true) {
        collectionError.value =
            map?['message']?.toString() ?? '获取收藏失败，请稍后重试';
        collectionItems.clear();
        collectionTotal.value = 0;
        return;
      }
      collectionTotal.value = _intOf(map['total']);
      collectionItems.assignAll(_itemsOf(map['items']));
    } catch (e) {
      collectionError.value = '获取收藏失败，请稍后重试';
    } finally {
      collectionLoading.value = false;
    }
  }

  /// 加载下一页收藏
  Future<void> loadMoreCollection() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    if (collectionLoadingMore.value || collectionLoading.value) return;
    if (collectionItems.length >= collectionTotal.value) return;
    collectionLoadingMore.value = true;
    try {
      final map = await _fetchCollection(
        start: collectionItems.length,
        token: token,
      );
      if (map != null && map['success'] == true) {
        collectionTotal.value = _intOf(map['total']);
        final known = collectionItems
            .map((e) => e['sid']?.toString())
            .toSet();
        for (final item in _itemsOf(map['items'])) {
          if (known.add(item['sid']?.toString())) {
            collectionItems.add(item);
          }
        }
      }
    } catch (_) {
      // 静默失败
    } finally {
      collectionLoadingMore.value = false;
    }
  }

  /// 切换想看/在看/看过或分类后重新加载
  Future<void> switchCollection({String? status, String? category}) async {
    if (status != null && status != collectionStatus.value) {
      collectionStatus.value = status;
    }
    if (category != null && category != collectionCategory.value) {
      collectionCategory.value = category;
    }
    // 切到「同步」页签时刷新同步记录，不请求收藏接口
    if (collectionStatus.value == 'sync') {
      unawaited(loadLogs());
      return;
    }
    await loadCollection();
  }

  Future<Map<String, dynamic>?> _fetchCollection({
    required int start,
    required String token,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '$basePathCollection'
      '?status=${collectionStatus.value}'
      '&start=$start'
      '&category=${collectionCategory.value}',
      token: token,
    );
    if ((response.statusCode ?? 0) >= 400) return null;
    return _extractMap(response.data);
  }

  List<Map<String, dynamic>> _itemsOf(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// 获取豆瓣登录二维码
  Future<bool> startQrLogin() async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    stopQrPolling();
    qrError.value = null;
    qrNickname.value = null;
    try {
      final map = await _fetch(basePathQrStart, token);
      if (map == null) {
        qrError.value = '获取二维码失败';
        return false;
      }
      _applyQrState(map);
      final st = qrStatus.value;
      if (st == 'expired' || st == 'error') {
        return false;
      }
      _startPolling();
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取豆瓣登录二维码失败');
      qrError.value = '获取二维码失败，请稍后重试';
      return false;
    }
  }

  void _applyQrState(Map<String, dynamic> map) {
    qrStatus.value = map['status']?.toString();
    final img = map['img']?.toString() ?? '';
    qrImg.value = img.isEmpty ? null : img;
    qrError.value = map['error']?.toString().isEmpty == true
        ? null
        : map['error']?.toString();
    qrNickname.value = map['nickname']?.toString().isEmpty == true
        ? null
        : map['nickname']?.toString();
    qrExpiresIn.value = _intOf(map['expire_in']);
  }

  /// 启动扫码轮询：首次 1.2 秒，之后 2 秒一次；本地秒级倒计时
  void _startPolling() {
    stopQrPolling();
    qrPolling.value = true;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!qrPolling.value) return;
      if (qrExpiresIn.value > 0) {
        qrExpiresIn.value = qrExpiresIn.value - 1;
        if (qrExpiresIn.value == 0) {
          qrStatus.value = 'expired';
          stopQrPolling();
        }
      }
    });
    _schedulePoll(first: true);
  }

  void _schedulePoll({bool first = false}) {
    _pollTimer = Timer(
      first
          ? const Duration(milliseconds: 1200)
          : const Duration(milliseconds: 2000),
      () async {
        if (!qrPolling.value) return;
        final token = _getToken();
        if (token == null || token.isEmpty) {
          stopQrPolling();
          return;
        }
        try {
          final map = await _fetch(basePathQrPoll, token);
          if (!qrPolling.value) return;
          if (map == null) {
            _schedulePoll();
            return;
          }
          _applyQrState(map);
          final st = qrStatus.value;
          if (st == 'login') {
            stopQrPolling();
            // 服务端已自动保存 cookie；静默保存一次当前表单并刷新
            await _silentSaveAfterLogin(token);
            await load();
            return;
          }
          if (st == 'expired' || st == 'error') {
            stopQrPolling();
            return;
          }
          _schedulePoll();
        } catch (_) {
          if (qrPolling.value) _schedulePoll();
        }
      },
    );
  }

  Future<void> _silentSaveAfterLogin(String token) async {
    try {
      final body = DoubanFolioConverter.toConfigBody(formModel.value);
      body['cookie'] = formModel.value['cookie']?.toString() ?? '';
      await _apiClient.postJson<dynamic>(basePathConfig, body, token: token);
    } catch (_) {
      // 忽略静默保存失败
    }
  }

  void stopQrPolling() {
    qrPolling.value = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// 立即检查想看自动订阅
  Future<void> checkAutoSubscribe() async {
    final token = _getToken();
    if (token == null || token.isEmpty) return;
    autoSubscribeChecking.value = true;
    try {
      final response = await _apiClient.postJson<dynamic>(
        autoSubscribeCheckPath,
        const {'force': true},
        token: token,
      );
      final map = _extractMap(response.data);
      if (map != null && map['success'] == true) {
        final subscribed = _intOf(map['subscribed']);
        final skipped = _intOf(map['skipped']);
        autoSubscribeResult.value =
            '检查完成：新增订阅 $subscribed 条${skipped > 0 ? '，失败 $skipped 条' : ''}';
      } else {
        autoSubscribeResult.value = map?['message']?.toString() ?? '检查失败';
      }
    } catch (e) {
      autoSubscribeResult.value = '检查失败，请稍后重试';
    } finally {
      autoSubscribeChecking.value = false;
    }
  }

  Future<Map<String, dynamic>?> _fetch(String path, String token) async {
    final response = await _apiClient.get<dynamic>(path, token: token);
    if ((response.statusCode ?? 0) >= 400) return null;
    return _extractMap(response.data);
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

  static int _intOf(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  @override
  void onClose() {
    stopQrPolling();
    super.onClose();
  }
}
