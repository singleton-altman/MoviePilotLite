import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/directory/controllers/directory_list_controller.dart';
import 'package:moviepilot_mobile/modules/downloader/controllers/downloader_controller.dart';
import 'package:moviepilot_mobile/modules/rule/controllers/rule_controller.dart';
import 'package:moviepilot_mobile/modules/rule/models/rule_models.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';
import 'package:moviepilot_mobile/modules/settings/models/system_env_model.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_field_state.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_form_manager.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_controller.dart';
import 'package:moviepilot_mobile/modules/site/models/site_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_media_enums.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 订阅编辑 Controller
class SubscribeEditController extends GetxController {
  final _api = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  /// 原始订阅项
  SubscribeItem get item => _item;
  late SubscribeItem _item;

  final isSaving = false.obs;
  final isDetailLoading = false.obs;
  final envData = Rxn<SystemEnvData>();
  final isEditing = true.obs;

  static final List<SettingsFieldConfig> formFields = [
    const SettingsFieldConfig(
      label: '搜索关键词',
      envKey: 'keyword',
      type: SettingsFieldType.text,
      hint: '指定搜索站点时使用的关键词',
    ),
    const SettingsFieldConfig(
      label: '总集数',
      envKey: 'total_episode',
      type: SettingsFieldType.number,
      step: 1,
    ),
    const SettingsFieldConfig(
      label: '开始集数',
      envKey: 'start_episode',
      type: SettingsFieldType.number,
      step: 1,
    ),
    const SettingsFieldConfig(
      label: '质量',
      envKey: 'quality',
      type: SettingsFieldType.select,
      enumKey: 'SUB_QUALITY',
    ),
    const SettingsFieldConfig(
      label: '分辨率',
      envKey: 'resolution',
      type: SettingsFieldType.select,
      enumKey: 'SUB_RESOLUTION',
    ),
    const SettingsFieldConfig(
      label: '特效',
      envKey: 'effect',
      type: SettingsFieldType.select,
      enumKey: 'SUB_EFFECT',
    ),
    const SettingsFieldConfig(
      label: '下载器',
      envKey: 'downloader',
      type: SettingsFieldType.select,
      enumKey: 'SUB_DOWNLOADER',
    ),
    const SettingsFieldConfig(
      label: '保存路径',
      envKey: 'save_path',
      type: SettingsFieldType.select,
      enumKey: 'SUB_SAVE_PATH',
    ),
    const SettingsFieldConfig(
      label: '洗版',
      envKey: 'best_version',
      type: SettingsFieldType.toggle,
    ),
    const SettingsFieldConfig(
      label: '使用 ImdbID 搜索',
      envKey: 'search_imdbid',
      type: SettingsFieldType.toggle,
    ),
    const SettingsFieldConfig(
      label: '包含',
      envKey: 'include',
      type: SettingsFieldType.text,
      hint: '包含规则，支持正则表达式',
    ),
    const SettingsFieldConfig(
      label: '排除',
      envKey: 'exclude',
      type: SettingsFieldType.text,
      hint: '排除规则，支持正则表达式',
    ),
    const SettingsFieldConfig(
      label: '指定剧集组',
      envKey: 'episode_group',
      type: SettingsFieldType.text,
      hint: '按特定剧集组识别和刮削',
    ),
    const SettingsFieldConfig(
      label: '指定季',
      envKey: 'season',
      type: SettingsFieldType.number,
      step: 1,
    ),
    const SettingsFieldConfig(
      label: '自定义类别',
      envKey: 'media_category',
      type: SettingsFieldType.text,
      hint: '指定类别名称，留空自动识别',
    ),
    const SettingsFieldConfig(
      label: '自定义识别词',
      envKey: 'custom_words',
      type: SettingsFieldType.text,
      hint: '只对该订阅使用的识别词',
    ),
  ];

  late final SettingsFormManager form = SettingsFormManager(fields: formFields);

  bool get hasUnsavedEdits {
    if (form.hasPendingChanges) return true;
    if (!_sameIntListAsMultiset(selectedSiteIds, _baselineSiteIds)) return true;
    if (!_sameStringListOrdered(
      selectedPriorityRuleNames,
      _baselinePriorityRuleNames,
    )) {
      return true;
    }
    return false;
  }

  static bool _sameIntListAsMultiset(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sa = List<int>.from(a)..sort();
    final sb = List<int>.from(b)..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  static bool _sameStringListOrdered(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _captureBaseline() {
    _baselineSiteIds = List<int>.from(selectedSiteIds);
    _baselinePriorityRuleNames = List<String>.from(selectedPriorityRuleNames);
  }

  // --- 基础 ---
  final keyword = ''.obs;
  final totalEpisode = 0.obs;
  final startEpisode = 0.obs;
  final quality = MediaQuality.defaultValue.obs;
  final resolution = MediaResolution.defaultValue.obs;
  final effect = MediaEffect.defaultValue.obs;
  final selectedSiteIds = <int>[].obs;
  List<int> _baselineSiteIds = const [];
  List<String> _baselinePriorityRuleNames = const [];
  final selectedDownloader = ''.obs;
  final selectedSavePath = ''.obs;
  final bestVersion = false.obs;
  final searchImdbid = false.obs;

  // --- 进阶 ---
  final include = ''.obs;
  final exclude = ''.obs;
  final selectedPriorityRuleNames = <String>[].obs; // 顺序多选，可拖拽排序
  final episodeGroup = ''.obs;
  final season = 0.obs;
  final mediaCategory = ''.obs;
  final customWords = ''.obs;

  // 季选项 0-199
  static List<int> get seasonOptions => List.generate(200, (i) => i);

  DownloaderController get _downloaderController =>
      Get.find<DownloaderController>();
  DirectoryListController get _directoryController =>
      Get.find<DirectoryListController>();
  RuleController get _ruleController =>
      Get.find<RuleController>(tag: 'subscribe_edit_priority');
  SiteController get _siteController => Get.find<SiteController>();
  SubscribeController get _subscribeController {
    if (Get.isRegistered<SubscribeController>()) {
      return Get.find<SubscribeController>();
    }
    return Get.put(SubscribeController(), permanent: false);
  }

  /// 下载器列表（从 downloader controller）
  List<String> get downloaders =>
      _downloaderController.downloaders.map((c) => c.name).toList();

  /// 保存路径列表（从 directory controller）
  List<String> get savePaths => _directoryController.directorySuggestions;

  /// 优先级规则列表（从 rule controller）
  List<UserFilterRuleGroup> get priorityRules => _ruleController.priorityRules;

  /// 全部站点（用于 picker 展示，可配合 [subscribableSiteIds] 做禁用）
  List<SiteModel> get allSites =>
      _siteController.items.map((e) => e.site).toList();

  /// env 内用户配置的可订阅站点 ID 集合；为 null 表示全部可选
  Set<int>? get subscribableSiteIds {
    final env = envData.value;
    if (env == null) return null;
    final searchSource = env.searchSource;
    if (searchSource == null || searchSource.isEmpty) return null;
    final ids = searchSource
        .split(RegExp(r'[,，\s]+'))
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();
    return ids.isEmpty ? null : ids;
  }

  /// 订阅站点 picker 的可选站点 ID；优先用 RssSites API 结果，否则用 env searchSource
  /// null 表示全部可选
  Set<int>? get selectableSiteIds {
    final rss = _siteController.rssSiteIds.value;
    if (rss != null && rss.isNotEmpty) return rss;
    return subscribableSiteIds;
  }

  /// 可用站点列表（仅可选站点，或全部站点）
  /// 供订阅站点 picker 展示；可选性由 selectableSiteIds 控制
  List<SiteModel> get availableSites {
    final ids = selectableSiteIds;
    if (ids != null && ids.isNotEmpty) {
      return _siteController.items
          .map((e) => e.site)
          .where((s) => ids.contains(s.id))
          .toList();
    }
    return _siteController.items.map((e) => e.site).toList();
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SubscribeItem) {
      _item = args;
      _initFromItem();
    } else {
      _item = const SubscribeItem();
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (!_appService.canSubscribe) {
      ToastUtil.info('当前帐号无订阅权限');
      Future.microtask(Get.back);
      return;
    }
    _loadEnv();
    _ensureControllersLoaded();
    _siteController.load();
    _siteController.loadRssSiteIds();
    final type = (_item.type ?? '').toLowerCase();
    final isMovie = type.contains('movie') ||
        type.contains('电影') ||
        type.contains('film');
    _subscribeController.subscribeType =
        isMovie ? SubscribeType.movie : SubscribeType.tv;
    if (_item.id != null) {
      _loadSubscribeDetail();
    }
  }

  /// 进入编辑页时拉取最新订阅详情，更新 _item 并刷新 UI
  Future<void> _loadSubscribeDetail() async {
    final id = _item.id;
    if (id == null) return;
    isDetailLoading.value = true;
    try {
      final resp = await _api.get<dynamic>('/api/v1/subscribe/$id');
      if (resp.statusCode == null || resp.statusCode! >= 400) return;
      final body = resp.data;
      if (body == null) return;
      Map<String, dynamic>? raw;
      if (body is Map<String, dynamic>) {
        raw = body['data'] as Map<String, dynamic>? ?? body;
      }
      if (raw != null) {
        _item = SubscribeItem.fromJson(raw);
        _initFromItem();
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取订阅详情失败');
    } finally {
      isDetailLoading.value = false;
    }
  }

  void _initFromItem() {
    keyword.value = _item.keyword ?? '';
    totalEpisode.value = _item.totalEpisode ?? 0;
    startEpisode.value = _item.startEpisode ?? 0;
    quality.value =
        MediaQuality.fromValue(_item.quality) ?? MediaQuality.defaultValue;
    resolution.value =
        MediaResolution.fromValue(_item.resolution) ??
        MediaResolution.defaultValue;
    effect.value =
        MediaEffect.fromValue(_item.effect) ?? MediaEffect.defaultValue;
    selectedSiteIds.value = _item.sites ?? [];
    selectedDownloader.value = _item.downloader ?? '';
    selectedSavePath.value = _item.savePath ?? '';
    bestVersion.value = (_item.bestVersion ?? 0) != 0;
    searchImdbid.value = (_item.searchImdbid ?? 0) != 0;

    include.value = _item.include ?? '';
    exclude.value = _item.exclude ?? '';
    mediaCategory.value = _item.mediaCategory ?? '';
    customWords.value = _item.customWords ?? '';
    season.value = _item.season ?? 0;
    episodeGroup.value = _item.episodeGroup?.toString() ?? '';

    final fg = _item.filterGroups;
    if (fg is List) {
      selectedPriorityRuleNames.value = fg
          .map(
            (e) => e is Map
                ? (e['name'] ?? e['rule_string'] ?? '').toString()
                : e.toString(),
          )
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (fg != null) {
      selectedPriorityRuleNames.value = [fg.toString()];
    } else {
      selectedPriorityRuleNames.value = [];
    }

    _hydrateFormFromItem();
  }

  void _hydrateFormFromItem() {
    form.hydrateValue('keyword', keyword.value);
    form.hydrateValue('total_episode', totalEpisode.value);
    form.hydrateValue('start_episode', startEpisode.value);
    form.hydrateValue('quality', quality.value.value);
    form.hydrateValue('resolution', resolution.value.value);
    form.hydrateValue('effect', effect.value.value);
    form.hydrateValue('downloader', selectedDownloader.value);
    form.hydrateValue('save_path', selectedSavePath.value);
    form.hydrateValue('best_version', bestVersion.value);
    form.hydrateValue('search_imdbid', searchImdbid.value);
    form.hydrateValue('include', include.value);
    form.hydrateValue('exclude', exclude.value);
    form.hydrateValue('episode_group', episodeGroup.value);
    form.hydrateValue('season', season.value);
    form.hydrateValue('media_category', mediaCategory.value);
    form.hydrateValue('custom_words', customWords.value);
    form.clearDirty();
    _captureBaseline();
  }

  Future<void> _loadEnv() async {
    try {
      final resp = await _api.get<Map<String, dynamic>>('/api/v1/system/env');
      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        final body = resp.data;
        if (body != null) {
          final parsed = SystemEnvResponse.fromJson(body);
          if (parsed.success && parsed.data != null) {
            envData.value = parsed.data;
          }
        }
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载 env 失败');
    }
  }

  void _ensureControllersLoaded() {
    if (!_downloaderController.downloaders.isNotEmpty) {
      _downloaderController.loadDownloaders();
    }
    if (_directoryController.directories.isEmpty) {
      _directoryController.loadDirectories();
    }
    if (!Get.isRegistered<RuleController>(tag: 'subscribe_edit_priority')) {
      Get.put(
        RuleController(ruleType: RuleType.priority),
        tag: 'subscribe_edit_priority',
      );
    } else {
      final rc = Get.find<RuleController>(tag: 'subscribe_edit_priority');
      if (rc.ruleType == RuleType.priority && rc.priorityRules.isEmpty) {
        rc.load();
      }
    }
    if (_siteController.items.isEmpty) {
      _siteController.load();
    }
  }

  void setKeyword(String v) {
    keyword.value = v;
    form.state<SettingsTextFieldState>('keyword').controller.text = v;
  }
  void setTotalEpisode(int v) {
    totalEpisode.value = v;
    form.state<SettingsNumberFieldState>('total_episode').setNumber(v);
  }
  void setStartEpisode(int v) {
    startEpisode.value = v;
    form.state<SettingsNumberFieldState>('start_episode').setNumber(v);
  }
  void setQuality(String v) {
    quality.value = MediaQuality.fromValue(v) ?? MediaQuality.defaultValue;
    form.state<SettingsSelectFieldState>('quality').value.value =
        quality.value.value;
  }
  void setResolution(String v) {
    resolution.value =
        MediaResolution.fromValue(v) ?? MediaResolution.defaultValue;
    form.state<SettingsSelectFieldState>('resolution').value.value =
        resolution.value.value;
  }
  void setEffect(String v) {
    effect.value = MediaEffect.fromValue(v) ?? MediaEffect.defaultValue;
    form.state<SettingsSelectFieldState>('effect').value.value =
        effect.value.value;
  }
  void setSelectedSites(List<int> ids) =>
      selectedSiteIds.value = List.from(ids);
  void setDownloader(String v) {
    selectedDownloader.value = v;
    form.state<SettingsSelectFieldState>('downloader').value.value = v;
  }
  void setSavePath(String v) {
    selectedSavePath.value = v;
    form.state<SettingsSelectFieldState>('save_path').value.value = v;
  }
  void setBestVersion(bool v) {
    bestVersion.value = v;
    form.state<SettingsToggleFieldState>('best_version').value.value = v;
  }
  void setSearchImdbid(bool v) {
    searchImdbid.value = v;
    form.state<SettingsToggleFieldState>('search_imdbid').value.value = v;
  }

  void setInclude(String v) {
    include.value = v;
    form.state<SettingsTextFieldState>('include').controller.text = v;
  }
  void setExclude(String v) {
    exclude.value = v;
    form.state<SettingsTextFieldState>('exclude').controller.text = v;
  }
  void setMediaCategory(String v) {
    mediaCategory.value = v;
    form.state<SettingsTextFieldState>('media_category').controller.text = v;
  }
  void setCustomWords(String v) {
    customWords.value = v;
    form.state<SettingsTextFieldState>('custom_words').controller.text = v;
  }
  void setSeason(int v) {
    season.value = v;
    form.state<SettingsNumberFieldState>('season').setNumber(v);
  }
  void setEpisodeGroup(String v) {
    episodeGroup.value = v;
    form.state<SettingsTextFieldState>('episode_group').controller.text = v;
  }
  void setPriorityRuleNames(List<String> names) =>
      selectedPriorityRuleNames.value = List.from(names);

  void reorderPriorityRule(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = selectedPriorityRuleNames.removeAt(oldIndex);
    selectedPriorityRuleNames.insert(newIndex, item);
  }

  Future<bool> save() async {
    if (_item.id == null) return false;
    isSaving.value = true;
    try {
      final fullPayload = Map<String, dynamic>.from(_item.toJson());
      fullPayload.addAll(_buildPayload());
      final ok = await _subscribeController.updateSubscribeData(
        _item.id!,
        fullPayload: fullPayload,
      );
      if (!ok) {
        ToastUtil.error('保存失败');
        return false;
      }
      _subscribeController.loadUserSubscribes();
      form.clearDirty();
      _captureBaseline();
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存订阅失败');
      ToastUtil.error('保存失败');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Map<String, dynamic> _buildPayload() {
    final keywordVal =
        form.state<SettingsTextFieldState>('keyword').controller.text.trim();
    final totalEpisodeVal = (num.tryParse(
              form.state<SettingsNumberFieldState>('total_episode')
                  .controller
                  .text
                  .trim(),
            ) ??
            0)
        .toInt();
    final startEpisodeVal = (num.tryParse(
              form.state<SettingsNumberFieldState>('start_episode')
                  .controller
                  .text
                  .trim(),
            ) ??
            0)
        .toInt();
    final qualityVal =
        form.state<SettingsSelectFieldState>('quality').value.value.trim();
    final resolutionVal =
        form.state<SettingsSelectFieldState>('resolution').value.value.trim();
    final effectVal =
        form.state<SettingsSelectFieldState>('effect').value.value.trim();
    final downloaderVal =
        form.state<SettingsSelectFieldState>('downloader').value.value.trim();
    final savePathVal =
        form.state<SettingsSelectFieldState>('save_path').value.value.trim();
    final bestVersionVal =
        form.state<SettingsToggleFieldState>('best_version').value.value;
    final searchImdbidVal =
        form.state<SettingsToggleFieldState>('search_imdbid').value.value;
    final includeVal =
        form.state<SettingsTextFieldState>('include').controller.text.trim();
    final excludeVal =
        form.state<SettingsTextFieldState>('exclude').controller.text.trim();
    final mediaCategoryVal = form
        .state<SettingsTextFieldState>('media_category')
        .controller
        .text
        .trim();
    final customWordsVal =
        form.state<SettingsTextFieldState>('custom_words').controller.text.trim();
    final episodeGroupVal =
        form.state<SettingsTextFieldState>('episode_group').controller.text.trim();
    final seasonVal = (num.tryParse(
              form.state<SettingsNumberFieldState>('season').controller.text.trim(),
            ) ??
            0)
        .toInt();
    return {
      'keyword': keywordVal.isEmpty ? null : keywordVal,
      'total_episode': totalEpisodeVal,
      'start_episode': startEpisodeVal,
      'quality': qualityVal,
      'resolution': resolutionVal,
      'effect': effectVal,
      'sites': selectedSiteIds.isEmpty ? null : selectedSiteIds.toList(),
      'downloader': downloaderVal.isEmpty ? null : downloaderVal,
      'save_path': savePathVal.isEmpty ? null : savePathVal,
      'best_version': bestVersionVal ? 1 : 0,
      'search_imdbid': searchImdbidVal ? 1 : 0,
      'include': includeVal.isEmpty ? null : includeVal,
      'exclude': excludeVal.isEmpty ? null : excludeVal,
      'media_category': mediaCategoryVal.isEmpty ? null : mediaCategoryVal,
      'custom_words': customWordsVal.isEmpty ? null : customWordsVal,
      'season': seasonVal,
      'episode_group': episodeGroupVal.isEmpty ? null : episodeGroupVal,
      'filter_groups': selectedPriorityRuleNames.isEmpty
          ? null
          : selectedPriorityRuleNames.map((n) => n).toList(),
    };
  }

  Future<bool> deleteSubscribe() async {
    if (_item.id == null) return false;
    isSaving.value = true;
    try {
      final ok = await _subscribeController.deleteSubscribes(
        _item.id.toString(),
      );
      if (ok) {
        _subscribeController.loadUserSubscribes();
        return true;
      }
      return false;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '取消订阅失败');
      ToastUtil.error('取消失败');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> refreshPage() async {
    await _loadEnv();
    await _loadSubscribeDetail();
  }

  @override
  void onClose() {
    form.dispose();
    super.onClose();
  }
}
