import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/subtitle_manual_upload_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

enum SubtitleMediaSortKey { defaultSort, title, year }

class SubtitleManualUploadFormController extends GetxController
    implements PluginFormAdapter {
  SubtitleManualUploadFormController({required this.formMode});

  @override
  final String pluginId = SubtitleManualUploadService.pluginId;

  final bool formMode;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  late final SubtitleManualUploadService _service = SubtitleManualUploadService(
    _apiClient,
  );

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
  RxBool? get actionLoading => busy;

  @override
  bool get supportsSave => formMode;

  @override
  bool get supportsFormEntry => !formMode;

  @override
  List<AppBarActionItem>? get actionList => formMode
      ? null
      : [
          const AppBarActionItem(
            type: 'refresh',
            label: '刷新状态',
            iconName: 'mdi-refresh',
          ),
          const AppBarActionItem(
            type: 'refresh_index',
            label: '刷新资源清单',
            iconName: 'mdi-database-refresh',
          ),
        ];

  final busy = false.obs;
  final rootTab = 'match'.obs;
  final searchKeyword = ''.obs;
  final mediaType = 'all'.obs;
  final mediaSortKey = SubtitleMediaSortKey.defaultSort.obs;
  final mediaSortAscending = true.obs;
  final mediaSearching = false.obs;
  final mediaPage = 1.obs;
  final mediaTotal = 0.obs;
  final mediaHasMore = false.obs;
  final medias = <Map<String, dynamic>>[].obs;
  final selectedMedia = Rxn<Map<String, dynamic>>();
  final seasons = <Map<String, dynamic>>[].obs;
  final selectedSeason = 'all'.obs;
  final targets = <Map<String, dynamic>>[].obs;
  final selectedTargetIds = <String>[].obs;
  final lockedTargetIds = <String>[].obs;
  final expandedTargetIds = <String>[].obs;
  final status = Rx<Map<String, dynamic>>({});
  final onlineStatus = Rx<Map<String, dynamic>>({});
  final autoTransferQueue = Rx<Map<String, dynamic>>({});
  final matchHistoryItems = <Map<String, dynamic>>[].obs;
  final matchHistoryPage = 1.obs;
  final matchHistoryTotal = 0.obs;
  final matchHistoryHasMore = false.obs;
  final matchHistoryLoading = false.obs;
  final expandedHistoryIds = <String>[].obs;
  final messageText = RxnString();
  final preparing = false.obs;
  final applying = false.obs;
  final clearing = false.obs;
  final aiWorking = false.obs;
  final timelineWorking = false.obs;
  final onlineSearching = false.obs;
  final onlineDownloading = false.obs;
  final onlineApplying = false.obs;
  final queueDialogOpen = false.obs;
  final uploadDialogOpen = false.obs;
  final onlineDialogOpen = false.obs;
  final aiDialogOpen = false.obs;
  final uploadTitle = ''.obs;
  final uploadScopeTargets = <Map<String, dynamic>>[].obs;
  final pickedFiles = <fp.PlatformFile>[].obs;
  final uploadPreview = Rxn<Map<String, dynamic>>();
  final fixTimeline = false.obs;
  final batchLanguageSuffix = ''.obs;
  final lastWritten = <Map<String, dynamic>>[].obs;
  final onlineTitle = ''.obs;
  final onlineScope = 'auto'.obs;
  final onlineKeyword = ''.obs;
  final onlineTargets = <Map<String, dynamic>>[].obs;
  final onlineResults = <Map<String, dynamic>>[].obs;
  final onlineMessages = <Map<String, dynamic>>[].obs;
  final onlineView = 'results'.obs;
  final onlineManualKeywords = <String>[].obs;
  final onlineManualLinks = <Map<String, dynamic>>[].obs;
  final onlineSelectedProviders = <String>['assrt', 'opensubtitles'].obs;
  final onlineSelectedResultKeys = <String>[].obs;
  final onlineLanguageFilter = 'all'.obs;
  final onlineProviderFilter = 'all'.obs;
  final aiTasks = Rx<Map<String, dynamic>>({});
  final timelineTasks = Rx<Map<String, dynamic>>({});

  static const _mediaPageSize = 24;
  static const _historyPageSize = 20;
  Timer? _indexTimer;
  Timer? _queueTimer;
  Timer? _aiTimer;
  Timer? _timelineTimer;

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

  @override
  Future<void> load() async {
    isLoading.value = true;
    errorText.value = null;
    messageText.value = null;
    try {
      final token = _requireToken();
      if (formMode) {
        await _loadForm(token);
      } else {
        await _loadPage(token);
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取 SubtitleManualUpload 数据失败');
      errorText.value = SubtitleManualUploadService.errorMessage(
        e,
        '请求失败，请稍后重试',
      );
      if (formMode) formModel.value = {};
      if (!formMode) _ensurePageBlock();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadForm(String token) async {
    final result = await _service.getForm(token);
    final raw = result.raw ?? asMap(result.data);
    final model = asMap(raw?['model']) ?? asMap(result.data) ?? {};
    formModel.value = _normalizeConfig(model);
    blocks.assignAll([
      const FormBlock.pageHeader(title: '字幕匹配配置', subtitle: '保存后插件重新载入配置'),
    ]);
  }

  Future<void> _loadPage(String token) async {
    _ensurePageBlock();
    await Future.wait([
      loadStatus(silent: true),
      loadOnlineStatus(silent: true),
      loadAutoTransferQueue(silent: true),
      runSearch(reset: true, silent: true),
      loadMatchHistory(reset: true, silent: true),
    ]);
    _startQueuePolling();
  }

  @override
  Future<bool> save() async {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      errorText.value = '请先登录';
      return false;
    }
    isLoading.value = true;
    errorText.value = null;
    try {
      final body = _toConfigBody(formModel.value);
      await _service.saveConfig(body, token);
      formModel.value = _normalizeConfig(body);
      ToastUtil.success('配置已保存');
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存 SubtitleManualUpload 配置失败');
      errorText.value = SubtitleManualUploadService.errorMessage(e, '保存失败');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> onAppBarAction(String type) async {
    if (type == 'refresh_index') {
      await refreshIndex();
      return;
    }
    await load();
  }

  Future<void> loadStatus({bool silent = false}) async {
    await _guard(
      () async {
        final result = await _service.status(_requireToken());
        status.value = asMap(result.data) ?? {};
        _scheduleIndexPolling();
      },
      fallback: '加载插件状态失败',
      silent: silent,
    );
  }

  Future<void> loadOnlineStatus({bool silent = false}) async {
    await _guard(
      () async {
        final result = await _service.onlineStatus(_requireToken());
        onlineStatus.value = asMap(result.data) ?? {};
        final enabled = asStringList(onlineStatus.value['enabled_providers']);
        if (enabled.isNotEmpty) onlineSelectedProviders.assignAll(enabled);
      },
      fallback: '加载在线字幕源状态失败',
      silent: silent,
    );
  }

  Future<void> loadAutoTransferQueue({bool silent = false}) async {
    await _guard(
      () async {
        final result = await _service.autoTransferQueue(_requireToken());
        autoTransferQueue.value = asMap(result.data) ?? {};
      },
      fallback: '加载自动入库队列失败',
      silent: silent,
    );
  }

  Future<void> refreshIndex() async {
    busy.value = true;
    await _guard(() async {
      final result = await _service.refreshIndex(_requireToken());
      final data = asMap(result.data) ?? {};
      final index = asMap(data['index']);
      if (index != null) {
        status.value = Map<String, dynamic>.from(status.value)
          ..['index'] = index;
      }
      messageText.value = result.message ?? '媒体库资源清单已开始刷新';
      _scheduleIndexPolling(force: true);
    }, fallback: '刷新媒体库清单失败');
    busy.value = false;
  }

  Future<void> runSearch({bool reset = true, bool silent = false}) async {
    mediaSearching.value = true;
    await _guard(
      () async {
        if (reset) {
          mediaPage.value = 1;
          medias.clear();
          selectedMedia.value = null;
          clearTargetState();
        }
        final page = reset ? 1 : mediaPage.value + 1;
        final result = await _service.search(
          token: _requireToken(),
          keyword: searchKeyword.value.trim(),
          mediaType: mediaType.value,
          page: page,
          pageSize: _mediaPageSize,
        );
        final data = asMap(result.data) ?? {};
        final next = asMapList(data['medias']);
        mediaPage.value = asInt(data['page'], page);
        mediaTotal.value = asInt(data['total'], next.length);
        mediaHasMore.value = data['has_more'] == true;
        if (reset) {
          medias.assignAll(next);
        } else {
          medias.addAll(next);
        }
        if (medias.isEmpty) {
          messageText.value = searchKeyword.value.trim().isEmpty
              ? '本地整理记录里暂时没有可用的视频目标'
              : '没有匹配的视频目标';
        }
      },
      fallback: '搜索本地资源失败',
      silent: silent,
    );
    mediaSearching.value = false;
  }

  bool get hasActiveMediaFilters => mediaType.value != 'all';

  List<Map<String, dynamic>> get visibleMedias {
    if (mediaSortKey.value == SubtitleMediaSortKey.defaultSort) {
      return medias;
    }
    final list = List<Map<String, dynamic>>.from(medias);
    list.sort((a, b) {
      final cmp = switch (mediaSortKey.value) {
        SubtitleMediaSortKey.title => mediaLabel(a).compareTo(mediaLabel(b)),
        SubtitleMediaSortKey.year =>
          asInt(a['year'], 0).compareTo(asInt(b['year'], 0)),
        SubtitleMediaSortKey.defaultSort => 0,
      };
      if (cmp == 0) return 0;
      return mediaSortAscending.value ? cmp : -cmp;
    });
    return list;
  }

  void updateMediaKeyword(String value) {
    searchKeyword.value = value.trim();
    runSearch(reset: true);
  }

  void updateMediaType(String value) {
    if (mediaType.value == value) return;
    mediaType.value = value;
    runSearch(reset: true);
  }

  void updateMediaSortKey(SubtitleMediaSortKey key) {
    mediaSortKey.value = key;
    medias.refresh();
  }

  void toggleMediaSortDirection() {
    mediaSortAscending.value = !mediaSortAscending.value;
    medias.refresh();
  }

  Future<void> loadMoreMedia() async {
    if (!mediaHasMore.value || busy.value) return;
    await runSearch(reset: false);
  }

  Future<void> selectMedia(Map<String, dynamic> media) async {
    selectedMedia.value = media;
    clearTargetState();
    await loadTargets(media: media, season: 'all');
  }

  Future<void> loadTargets({
    Map<String, dynamic>? media,
    String? season,
  }) async {
    final targetMedia = media ?? selectedMedia.value;
    if (targetMedia == null) return;
    busy.value = true;
    await _guard(() async {
      final result = await _service.targets(
        token: _requireToken(),
        media: targetMedia,
        season: season ?? selectedSeason.value,
      );
      final data = asMap(result.data) ?? {};
      selectedMedia.value = asMap(data['media']) ?? targetMedia;
      seasons.assignAll(asMapList(data['seasons']));
      selectedSeason.value = _text(data['selected_season']).isNotEmpty
          ? _text(data['selected_season'])
          : 'all';
      targets.assignAll(asMapList(data['targets']));
      selectedTargetIds.clear();
      expandedTargetIds.clear();
      await loadAiTasks(silent: true);
      await loadTimelineTasks(silent: true);
      if (targets.isEmpty) messageText.value = '没有找到本地可写入的视频文件';
    }, fallback: '读取本地视频目标失败');
    busy.value = false;
  }

  Future<void> changeSeason(String season) async {
    selectedSeason.value = season;
    await loadTargets(season: season);
  }

  void resetSelection() {
    selectedMedia.value = null;
    clearTargetState();
  }

  void clearTargetState() {
    seasons.clear();
    selectedSeason.value = 'all';
    targets.clear();
    selectedTargetIds.clear();
    lockedTargetIds.clear();
    expandedTargetIds.clear();
    uploadPreview.value = null;
    lastWritten.clear();
  }

  void toggleTarget(String targetId, bool selected) {
    if (selected) {
      if (!selectedTargetIds.contains(targetId)) {
        selectedTargetIds.add(targetId);
      }
    } else {
      selectedTargetIds.remove(targetId);
    }
  }

  void toggleSelectAll() {
    if (selectedTargetIds.length == targets.length) {
      selectedTargetIds.clear();
    } else {
      selectedTargetIds.assignAll(targets.map((e) => _text(e['id'])));
    }
  }

  void toggleLock(String targetId) {
    if (lockedTargetIds.contains(targetId)) {
      lockedTargetIds.remove(targetId);
    } else {
      lockedTargetIds.add(targetId);
    }
  }

  void toggleExpandedTarget(String targetId) {
    if (expandedTargetIds.contains(targetId)) {
      expandedTargetIds.remove(targetId);
    } else {
      expandedTargetIds.add(targetId);
    }
  }

  void openBatchUpload() {
    final base = selectedTargets.isNotEmpty ? selectedTargets : targets;
    openUploadDialog(base, selectedTargets.isNotEmpty ? '上传选中字幕' : '上传字幕');
  }

  void openSingleUpload(Map<String, dynamic> target) {
    openUploadDialog([target], '上传 ${compactTargetName(target)}');
  }

  void openUploadDialog(List<Map<String, dynamic>> scope, String title) {
    final usable = scope
        .where((item) => !isTargetActionDisabled(item))
        .toList();
    if (usable.isEmpty) {
      ToastUtil.error('没有可上传的目标');
      return;
    }
    uploadScopeTargets.assignAll(usable);
    uploadTitle.value = title;
    pickedFiles.clear();
    uploadPreview.value = null;
    batchLanguageSuffix.value = '';
    fixTimeline.value = false;
    uploadDialogOpen.value = true;
  }

  Future<void> pickUploadFiles() async {
    final result = await fp.FilePicker.pickFiles(
      allowMultiple: true,
      type: fp.FileType.custom,
      allowedExtensions: [
        'ass',
        'srt',
        'ssa',
        'sbv',
        'sub',
        'vtt',
        'webvtt',
        'zip',
        'rar',
        '7z',
      ],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final known = pickedFiles.map((e) => '${e.name}:${e.size}').toSet();
    for (final file in result.files) {
      if (known.add('${file.name}:${file.size}')) pickedFiles.add(file);
    }
    await prepareUpload();
  }

  void removePickedFile(fp.PlatformFile file) {
    pickedFiles.remove(file);
    uploadPreview.value = null;
  }

  Future<void> prepareUpload() async {
    if (uploadScopeTargets.isEmpty || pickedFiles.isEmpty) return;
    preparing.value = true;
    await _guard(() async {
      final formData = dio.FormData();
      formData.fields.add(
        MapEntry(
          'target_ids',
          jsonEncode(uploadScopeTargets.map((e) => _text(e['id'])).toList()),
        ),
      );
      for (final file in pickedFiles) {
        if (file.path != null && file.path!.isNotEmpty) {
          formData.files.add(
            MapEntry(
              'files',
              await dio.MultipartFile.fromFile(file.path!, filename: file.name),
            ),
          );
        } else if (file.bytes != null) {
          formData.files.add(
            MapEntry(
              'files',
              dio.MultipartFile.fromBytes(file.bytes!, filename: file.name),
            ),
          );
        }
      }
      final result = await _service.prepareUpload(
        token: _requireToken(),
        formData: formData,
      );
      final data = asMap(result.data) ?? {};
      _normalizePreviewSelection(data);
      uploadPreview.value = data;
      messageText.value = result.message ?? '已生成匹配预览';
    }, fallback: '上传预解析失败');
    preparing.value = false;
  }

  Future<void> applyUpload() async {
    final preview = uploadPreview.value;
    if (preview == null) return;
    final items = selectedPreviewItems;
    if (items.isEmpty ||
        items.any((item) => _text(item['target_id']).isEmpty)) {
      ToastUtil.error('请先确认字幕匹配目标');
      return;
    }
    applying.value = true;
    await _guard(() async {
      final result = await _service.applyUpload({
        'session_id': preview['session_id'],
        'fix_timeline': fixTimeline.value && timelineAvailable,
        'allow_risky_offset': fixTimeline.value && timelineNeedsRiskyConfirm,
        'locked_target_ids': lockedTargetIds.toList(),
        'items': items
            .map(
              (item) => {
                'upload_id': item['upload_id'],
                'target_id': item['target_id'],
                'ext': item['ext'],
                'language_suffix': item['language_suffix'],
              },
            )
            .toList(),
      }, _requireToken());
      final data = asMap(result.data) ?? {};
      lastWritten.assignAll(asMapList(data['written']));
      uploadDialogOpen.value = false;
      uploadPreview.value = null;
      pickedFiles.clear();
      messageText.value = result.message ?? '字幕写入完成';
      await loadTargets();
    }, fallback: '写入字幕失败');
    applying.value = false;
  }

  void updatePreviewTarget(String uploadId, String targetId) {
    final preview = uploadPreview.value;
    if (preview == null) return;
    for (final item in asMapList(preview['items'])) {
      if (_text(item['upload_id']) == uploadId) {
        item['target_id'] = targetId;
        item['output_name'] = buildOutputName(targetById[targetId], item);
      }
    }
    uploadPreview.value = Map<String, dynamic>.from(preview);
  }

  void updatePreviewLanguage(String uploadId, String language) {
    final preview = uploadPreview.value;
    if (preview == null) return;
    for (final item in asMapList(preview['items'])) {
      if (_text(item['upload_id']) == uploadId) {
        item['language_suffix'] = language.trim().isEmpty
            ? 'und'
            : language.trim();
        item['output_name'] = buildOutputName(
          targetById[_text(item['target_id'])],
          item,
        );
      }
    }
    uploadPreview.value = Map<String, dynamic>.from(preview);
  }

  void togglePreviewItem(String uploadId, bool selected) {
    final preview = uploadPreview.value;
    if (preview == null) return;
    for (final item in asMapList(preview['items'])) {
      if (_text(item['upload_id']) == uploadId) item['selected'] = selected;
    }
    uploadPreview.value = Map<String, dynamic>.from(preview);
  }

  void applyBatchLanguageSuffix() {
    final suffix = batchLanguageSuffix.value.trim();
    if (suffix.isEmpty) return;
    final preview = uploadPreview.value;
    if (preview == null) return;
    for (final item in asMapList(preview['items'])) {
      if (item['selected'] != false) {
        item['language_suffix'] = suffix;
        item['output_name'] = buildOutputName(
          targetById[_text(item['target_id'])],
          item,
        );
      }
    }
    uploadPreview.value = Map<String, dynamic>.from(preview);
  }

  Future<void> openBatchOnlineSearch() async {
    final base = selectedTargets.isNotEmpty ? selectedTargets : targets;
    await openOnlineDialog(
      base,
      '搜索在线字幕',
      selectedMedia.value?['media_type'] == 'tv' ? 'season' : 'movie',
    );
  }

  Future<void> openSingleOnlineSearch(Map<String, dynamic> target) async {
    await openOnlineDialog(
      [target],
      '搜索 ${compactTargetName(target)}',
      'episode',
    );
  }

  Future<void> openOnlineDialog(
    List<Map<String, dynamic>> scope,
    String title,
    String scopeName,
  ) async {
    final usable = scope
        .where((item) => !isTargetActionDisabled(item))
        .toList();
    if (usable.isEmpty) {
      ToastUtil.error('没有可搜索的目标');
      return;
    }
    onlineTargets.assignAll(usable);
    onlineTitle.value = title;
    onlineScope.value = scopeName;
    onlineKeyword.value = '';
    onlineResults.clear();
    onlineMessages.clear();
    onlineView.value = 'results';
    onlineManualKeywords.clear();
    onlineManualLinks.clear();
    onlineSelectedResultKeys.clear();
    onlineLanguageFilter.value = 'all';
    onlineProviderFilter.value = 'all';
    uploadScopeTargets.assignAll(usable);
    uploadTitle.value = '$title · 在线字幕';
    uploadPreview.value = null;
    pickedFiles.clear();
    onlineDialogOpen.value = true;
    await loadOnlineStatus();
    await loadOnlineManualLinks();
    await runOnlineSearch();
  }

  Future<void> loadOnlineManualLinks() async {
    if (onlineTargets.isEmpty) return;
    await _guard(
      () async {
        final result = await _service.postJsonAction(
          'online_manual_links',
          onlinePayload(),
          _requireToken(),
        );
        final data = asMap(result.data) ?? {};
        onlineManualKeywords.assignAll(asStringList(data['keywords']));
        onlineManualLinks.assignAll(asMapList(data['links']));
      },
      fallback: '生成手动搜索链接失败',
      silent: true,
    );
  }

  Future<void> runOnlineSearch() async {
    if (onlineTargets.isEmpty) return;
    onlineSearching.value = true;
    await _guard(() async {
      final result = await _service.postJsonAction(
        'online_search',
        onlinePayload(),
        _requireToken(),
        timeout: 180,
      );
      final data = asMap(result.data) ?? {};
      onlineResults.assignAll(asMapList(data['results']));
      onlineMessages.assignAll(asMapList(data['messages']));
      onlineSelectedResultKeys.clear();
    }, fallback: '在线字幕搜索失败');
    onlineSearching.value = false;
  }

  Future<bool> downloadOnlinePreview({bool submitAi = false}) async {
    final selected = selectedOnlineResults;
    if (selected.isEmpty) {
      ToastUtil.error('请先选择在线字幕结果');
      return false;
    }
    onlineDownloading.value = true;
    var ok = false;
    await _guard(() async {
      final payload = {
        ...onlinePayload(),
        'results': selected,
        'submit_ai_translate': submitAi,
        'allow_risky_offset': timelineNeedsRiskyConfirm,
      };
      final result = await _service.postJsonAction(
        submitAi ? 'online_ai_submit' : 'online_download_preview',
        payload,
        _requireToken(),
        timeout: 240,
      );
      if (submitAi) {
        aiTasks.value = asMap(result.data) ?? {};
        messageText.value = result.message ?? '已提交在线字幕 AI 翻译';
        onlineDialogOpen.value = false;
        _startAiPolling();
        ok = true;
      } else {
        final data = asMap(result.data) ?? {};
        _normalizePreviewSelection(data);
        data['source'] = 'online';
        uploadPreview.value = data;
        messageText.value = result.message ?? '已下载在线字幕并生成预览';
        ok = true;
      }
    }, fallback: submitAi ? '提交 AI 翻译失败' : '在线字幕下载失败');
    onlineDownloading.value = false;
    return ok;
  }

  Future<bool> applyOnlineDirect() async {
    final selected = selectedOnlineResults;
    if (selected.isEmpty) {
      ToastUtil.error('请先选择在线字幕结果');
      return false;
    }
    onlineApplying.value = true;
    var ok = false;
    await _guard(() async {
      final previewResult = await _service.postJsonAction(
        'online_download_preview',
        {
          ...onlinePayload(),
          'results': selected,
          'submit_ai_translate': false,
          'allow_risky_offset': timelineNeedsRiskyConfirm,
        },
        _requireToken(),
        timeout: 240,
      );
      final preview = asMap(previewResult.data) ?? {};
      _normalizePreviewSelection(preview);
      final items = asMapList(
        preview['items'],
      ).where((item) => item['selected'] != false).toList();
      if (items.isEmpty) {
        throw const SubtitleManualUploadApiException('没有可写入的字幕项', 400);
      }
      final applyResult = await _service.applyUpload({
        'session_id': preview['session_id'],
        'fix_timeline': fixTimeline.value && timelineAvailable,
        'allow_risky_offset': fixTimeline.value && timelineNeedsRiskyConfirm,
        'locked_target_ids': lockedTargetIds.toList(),
        'items': items
            .map(
              (item) => {
                'upload_id': item['upload_id'],
                'target_id': item['target_id'],
                'ext': item['ext'],
                'language_suffix': item['language_suffix'],
              },
            )
            .toList(),
      }, _requireToken());
      final data = asMap(applyResult.data) ?? {};
      lastWritten.assignAll(asMapList(data['written']));
      uploadPreview.value = null;
      onlineSelectedResultKeys.clear();
      messageText.value =
          applyResult.message ?? previewResult.message ?? '字幕写入完成';
      await loadTargets();
      ok = true;
    }, fallback: '在线字幕写入失败');
    onlineApplying.value = false;
    return ok;
  }

  void toggleOnlineResult(Map<String, dynamic> item, bool selected) {
    final key = onlineResultKey(item);
    if (selected) {
      if (!onlineSelectedResultKeys.contains(key)) {
        onlineSelectedResultKeys.add(key);
      }
    } else {
      onlineSelectedResultKeys.remove(key);
    }
    onlineSelectedResultKeys.refresh();
  }

  Future<void> submitAiForTargets([Map<String, dynamic>? target]) async {
    final ids = target == null ? activeTargetIds : [_text(target['id'])];
    if (ids.isEmpty) {
      ToastUtil.error('请先选择要生成 AI 字幕的目标');
      return;
    }
    aiWorking.value = true;
    await _guard(() async {
      final result = await _service.postJsonAction('ai_submit', {
        'target_ids': ids,
        'locked_target_ids': lockedTargetIds.toList(),
        'source_policy': 'auto',
      }, _requireToken());
      aiTasks.value = asMap(result.data) ?? {};
      messageText.value = result.message ?? '已提交 AI 字幕任务';
      _startAiPolling();
    }, fallback: '提交 AI 字幕任务失败');
    aiWorking.value = false;
  }

  Future<void> cancelAiForTargets() async {
    final ids = activeTargetIds;
    if (ids.isEmpty) return;
    aiWorking.value = true;
    await _guard(() async {
      final result = await _service.postJsonAction('ai_cancel', {
        'target_ids': ids,
        'locked_target_ids': lockedTargetIds.toList(),
      }, _requireToken());
      aiTasks.value = asMap(result.data) ?? {};
      messageText.value = result.message ?? '已取消 AI 字幕任务';
    }, fallback: '取消 AI 字幕任务失败');
    aiWorking.value = false;
  }

  Future<void> loadAiTasks({bool silent = false}) async {
    await _guard(
      () async {
        final result = await _service.postJsonAction('ai_tasks', {
          'target_ids': targets.map((e) => _text(e['id'])).toList(),
        }, _requireToken());
        aiTasks.value = asMap(result.data) ?? {};
        if (hasActiveAiTasks) _startAiPolling();
      },
      fallback: '加载 AI 字幕任务失败',
      silent: silent,
    );
  }

  Future<void> fixTimelineForTargets([Map<String, dynamic>? target]) async {
    final targetList = target == null ? selectedTargets : [target];
    final items = targetList
        .where((item) => !isStreamTarget(item))
        .map((item) => {'target_id': item['id']})
        .toList();
    if (items.isEmpty) {
      ToastUtil.error('没有可调轴的目标');
      return;
    }
    await fixExistingTimeline(items, '选中目标');
  }

  Future<void> fixExistingTimeline(
    List<Map<String, dynamic>> items,
    String label,
  ) async {
    timelineWorking.value = true;
    await _guard(() async {
      final result = await _service.postJsonAction('timeline_fix_existing', {
        'items': items,
        'locked_target_ids': lockedTargetIds.toList(),
        'allow_risky_offset': timelineNeedsRiskyConfirm,
      }, _requireToken());
      timelineTasks.value = asMap(result.data) ?? {};
      messageText.value = result.message ?? '已提交智能调轴任务';
      _startTimelinePolling();
    }, fallback: '提交智能调轴失败');
    timelineWorking.value = false;
  }

  Future<void> loadTimelineTasks({bool silent = false}) async {
    await _guard(
      () async {
        final result = await _service.postJsonAction('timeline_tasks', {
          'target_ids': targets.map((e) => _text(e['id'])).toList(),
        }, _requireToken());
        timelineTasks.value = asMap(result.data) ?? {};
        if (hasActiveTimelineTasks) _startTimelinePolling();
      },
      fallback: '加载智能调轴任务失败',
      silent: silent,
    );
  }

  Future<void> clearSelectedSubtitles() async {
    final ids = activeTargetIds;
    if (ids.isEmpty) {
      ToastUtil.error('请先选择目标');
      return;
    }
    clearing.value = true;
    await _guard(() async {
      final result = await _service.postJsonAction('clear_subtitles', {
        'target_ids': ids,
        'locked_target_ids': lockedTargetIds.toList(),
      }, _requireToken());
      messageText.value = result.message ?? '已清理外挂字幕';
      await loadTargets();
    }, fallback: '清理外挂字幕失败');
    clearing.value = false;
  }

  Future<void> deleteSubtitle(
    Map<String, dynamic> target,
    Map<String, dynamic> subtitle,
  ) async {
    await _guard(() async {
      final result = await _service.postJsonAction('delete_subtitle', {
        'target_id': target['id'],
        'subtitle_path': subtitle['path'],
        'subtitle_name': subtitle['name'],
        'locked_target_ids': lockedTargetIds.toList(),
      }, _requireToken());
      messageText.value = result.message ?? '字幕已删除';
      await loadTargets();
      await loadMatchHistory(reset: true, silent: true);
    }, fallback: '删除字幕失败');
  }

  Future<void> restoreSubtitleBackup(
    Map<String, dynamic> target,
    Map<String, dynamic> subtitle,
  ) async {
    await _guard(() async {
      final result = await _service.postJsonAction('restore_subtitle_backup', {
        'target_id': target['id'],
        'subtitle_path': subtitle['path'],
        'subtitle_name': subtitle['name'],
        'locked_target_ids': lockedTargetIds.toList(),
      }, _requireToken());
      messageText.value = result.message ?? '字幕备份已恢复';
      await loadTargets();
    }, fallback: '恢复字幕备份失败');
  }

  Future<void> loadMatchHistory({
    bool reset = true,
    bool silent = false,
  }) async {
    matchHistoryLoading.value = true;
    await _guard(
      () async {
        final page = reset ? 1 : matchHistoryPage.value + 1;
        final result = await _service.matchHistory(
          token: _requireToken(),
          keyword: searchKeyword.value.trim(),
          mediaType: mediaType.value,
          page: page,
          pageSize: _historyPageSize,
        );
        final data = asMap(result.data) ?? {};
        final next = asMapList(data['items']);
        matchHistoryPage.value = asInt(data['page'], page);
        matchHistoryTotal.value = asInt(data['total'], next.length);
        matchHistoryHasMore.value = data['has_more'] == true;
        if (reset) {
          matchHistoryItems.assignAll(next);
        } else {
          matchHistoryItems.addAll(next);
        }
      },
      fallback: '加载匹配历史失败',
      silent: silent,
    );
    matchHistoryLoading.value = false;
  }

  Future<void> loadMoreMatchHistory() async {
    if (!matchHistoryHasMore.value) return;
    await loadMatchHistory(reset: false);
  }

  void toggleHistoryExpanded(String id) {
    if (expandedHistoryIds.contains(id)) {
      expandedHistoryIds.remove(id);
    } else {
      expandedHistoryIds.add(id);
    }
  }

  Future<void> clearHistoryTarget(Map<String, dynamic> target) async {
    clearing.value = true;
    await _guard(() async {
      final result = await _service.postJsonAction('clear_subtitles', {
        'target_ids': [_text(target['id'])],
        'locked_target_ids': lockedTargetIds.toList(),
      }, _requireToken());
      messageText.value = result.message ?? '已删除外挂字幕';
      await loadMatchHistory(reset: true);
    }, fallback: '删除外挂字幕失败');
    clearing.value = false;
  }

  Map<String, dynamic> onlinePayload() => {
    'target_ids': onlineTargets.map((item) => _text(item['id'])).toList(),
    'locked_target_ids': lockedTargetIds.toList(),
    'media': selectedMedia.value,
    'scope': onlineScope.value,
    'keyword': onlineKeyword.value.trim(),
    'providers': onlineSelectedProviders.toList(),
  };

  List<Map<String, dynamic>> get selectedTargets {
    final selected = selectedTargetIds.toSet();
    return targets
        .where((item) => selected.contains(_text(item['id'])))
        .toList();
  }

  List<String> get activeTargetIds {
    final base = selectedTargets.isNotEmpty ? selectedTargets : targets;
    return base
        .where((item) => !isTargetActionDisabled(item))
        .map((item) => _text(item['id']))
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Map<String, Map<String, dynamic>> get targetById => {
    for (final target in uploadScopeTargets) _text(target['id']): target,
    for (final target in targets) _text(target['id']): target,
  };

  List<Map<String, dynamic>> get selectedPreviewItems {
    final preview = uploadPreview.value;
    if (preview == null) return [];
    return asMapList(
      preview['items'],
    ).where((item) => item['selected'] != false).toList();
  }

  List<Map<String, dynamic>> get filteredOnlineResults {
    return onlineResults.where((item) {
      final providerOk =
          onlineProviderFilter.value == 'all' ||
          _text(item['provider']) == onlineProviderFilter.value;
      final languageOk =
          onlineLanguageFilter.value == 'all' ||
          onlineLanguageCategory(item) == onlineLanguageFilter.value;
      return providerOk && languageOk;
    }).toList();
  }

  List<Map<String, dynamic>> get selectedOnlineResults {
    final selected = onlineSelectedResultKeys.toSet();
    return onlineResults
        .where((item) => selected.contains(onlineResultKey(item)))
        .toList();
  }

  bool get timelineAvailable =>
      asMap(status.value['timeline_fixer'])?['available'] == true;

  bool get timelineNeedsRiskyConfirm {
    final seconds = asInt(
      asMap(status.value['timeline_fixer'])?['configured_max_offset_seconds'],
      120,
    );
    return seconds > 120;
  }

  bool get aiAvailable =>
      asMap(status.value['ai_subtitle'])?['available'] == true;

  bool get hasActiveAiTasks {
    final tasks = asMapList(aiTasks.value['tasks']);
    return tasks.any(
      (task) =>
          task['active'] == true ||
          ['pending', 'running', 'in_progress'].contains(_text(task['status'])),
    );
  }

  bool get hasActiveTimelineTasks {
    final tasks = asMapList(timelineTasks.value['tasks']);
    return tasks.any(
      (task) =>
          task['active'] == true ||
          ['pending', 'running', 'in_progress'].contains(_text(task['status'])),
    );
  }

  bool isTargetActionDisabled(Map<String, dynamic> target) {
    final id = _text(target['id']);
    return lockedTargetIds.contains(id) || target['writable'] == false;
  }

  bool isStreamTarget(Map<String, dynamic> target) {
    final path = _text(target['path']).toLowerCase();
    return path.endsWith('.strm') ||
        target['stream'] == true ||
        target['is_stream'] == true;
  }

  String compactTargetName(Map<String, dynamic>? target) {
    if (target == null) return '目标';
    final name = _text(target['name']);
    if (name.isNotEmpty) return name;
    final title = _text(target['title']);
    final episode = _text(target['episode']);
    return [
          title,
          episode,
        ].where((e) => e.isNotEmpty).join(' · ').trim().isEmpty
        ? _text(target['path']).split('/').last
        : [title, episode].where((e) => e.isNotEmpty).join(' · ');
  }

  String mediaLabel(Map<String, dynamic>? media) {
    if (media == null) return '媒体';
    final title = _text(media['title']).isNotEmpty
        ? _text(media['title'])
        : _text(media['name']);
    final year = _text(media['year']);
    return year.isEmpty ? title : '$title ($year)';
  }

  String buildOutputName(
    Map<String, dynamic>? target,
    Map<String, dynamic> item,
  ) {
    final current = _text(item['output_name']);
    if (current.isNotEmpty) return current;
    final base = compactTargetName(target);
    final suffix = _text(item['language_suffix']).isEmpty
        ? 'und'
        : _text(item['language_suffix']);
    final ext = _text(item['ext']).isEmpty
        ? 'srt'
        : _text(item['ext']).replaceFirst('.', '');
    return '$base.$suffix.$ext';
  }

  String onlineResultKey(Map<String, dynamic> item) {
    return [
      item['provider'],
      item['id'],
      item['url'],
      item['download_url'],
      item['title'],
    ].map(_text).join('|');
  }

  String onlineLanguageCategory(Map<String, dynamic> item) {
    final raw = '${item['language']} ${item['language_name']} ${item['title']}'
        .toLowerCase();
    if (raw.contains('中') ||
        raw.contains('chi') ||
        raw.contains('zh') ||
        raw.contains('简') ||
        raw.contains('繁')) {
      return 'chinese';
    }
    if (raw.contains('eng') || raw.contains('英')) {
      return 'english';
    }
    if (raw.contains('jpn') || raw.contains('jap') || raw.contains('日')) {
      return 'japanese';
    }
    return 'other';
  }

  List<String> asStringList(dynamic value) {
    if (value is List) {
      return value.map(_text).where((e) => e.isNotEmpty).toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'[,，\s]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  static Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Map<String, dynamic>> asMapList(dynamic value) {
    if (value is! List) return [];
    return value.map(asMap).whereType<Map<String, dynamic>>().toList();
  }

  static int asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  void _normalizePreviewSelection(Map<String, dynamic> preview) {
    final items = asMapList(preview['items']);
    for (var i = 0; i < items.length; i++) {
      items[i]['selected'] = preview['source'] == 'online' && items.length > 1
          ? i == 0
          : items[i]['selected'] != false;
      items[i]['output_name'] = buildOutputName(
        targetById[_text(items[i]['target_id'])],
        items[i],
      );
    }
    preview['items'] = items;
  }

  Map<String, dynamic> _normalizeConfig(Map<String, dynamic> raw) {
    return {
      'enabled': raw['enabled'] == true,
      'show_sidebar_nav': raw['show_sidebar_nav'] != false,
      'ai_link_enabled': raw['ai_link_enabled'] != false,
      'traditional_to_simplified': raw['traditional_to_simplified'] == true,
      'auto_search_on_transfer': raw['auto_search_on_transfer'] == true,
      'auto_skip_chinese_media_on_transfer':
          raw['auto_skip_chinese_media_on_transfer'] != false,
      'trust_transfer_history_paths':
          raw['trust_transfer_history_paths'] == true,
      'auto_transfer_subtitle_strategy': _choice(
        raw['auto_transfer_subtitle_strategy'],
        'online_then_ai_source',
      ),
      'auto_multi_subtitle_mode': _choice(
        raw['auto_multi_subtitle_mode'],
        'best',
      ),
      'auto_subtitle_language_priority':
          asStringList(raw['auto_subtitle_language_priority']).isEmpty
          ? ['bilingual', 'chi', 'cht', 'eng']
          : asStringList(raw['auto_subtitle_language_priority']),
      'auto_subtitle_format_priority':
          asStringList(raw['auto_subtitle_format_priority']).isEmpty
          ? ['ass', 'srt', 'ssa', 'vtt']
          : asStringList(raw['auto_subtitle_format_priority']),
      'auto_ass_to_srt_for_ai': raw['auto_ass_to_srt_for_ai'] != false,
      'online_providers': asStringList(raw['online_providers']).isEmpty
          ? ['assrt', 'opensubtitles']
          : asStringList(raw['online_providers']),
      'online_use_proxy': raw['online_use_proxy'] == true,
      'subhd_url': _choice(raw['subhd_url'], 'https://subhd.tv'),
      'zimuku_url': _choice(raw['zimuku_url'], 'https://zmk.pw'),
      'assrt_url': _choice(raw['assrt_url'], 'https://2.assrt.net'),
      'assrt_api_url': _choice(raw['assrt_api_url'], 'https://api.assrt.net'),
      'assrt_api_key': _text(raw['assrt_api_key']),
      'opensubtitles_url': _choice(
        raw['opensubtitles_url'],
        'https://www.opensubtitles.com',
      ),
      'opensubtitles_api_url': _choice(
        raw['opensubtitles_api_url'],
        'https://api.opensubtitles.com/api/v1',
      ),
      'opensubtitles_api_key': _text(raw['opensubtitles_api_key']),
      'opensubtitles_username':
          _text(raw['opensubtitles_username']).contains('@')
          ? ''
          : _text(raw['opensubtitles_username']),
      'opensubtitles_password': _text(raw['opensubtitles_password']),
      'timeline_max_offset_seconds': asInt(
        raw['timeline_max_offset_seconds'],
        120,
      ).clamp(1, 300),
      'timeline_min_offset_seconds':
          double.tryParse(_text(raw['timeline_min_offset_seconds'])) ?? 0.2,
      'timeline_vad_mode': _choice(raw['timeline_vad_mode'], 'webrtc'),
      'timeline_allow_risky_offset': raw['timeline_allow_risky_offset'] == true,
      'rar_dependency_mode': _choice(raw['rar_dependency_mode'], 'none'),
      'rar_tool_path': _choice(raw['rar_tool_path'], '/usr/bin/unar'),
    };
  }

  Map<String, dynamic> _toConfigBody(Map<String, dynamic> model) {
    return _normalizeConfig(model)
      ..['online_proxy_migrated'] = true
      ..['assrt_provider_migrated'] = true;
  }

  String _requireToken() {
    final token = _getToken();
    if (token == null || token.isEmpty) {
      throw const SubtitleManualUploadApiException('请先登录', 401);
    }
    return token;
  }

  Future<void> _guard(
    Future<void> Function() body, {
    required String fallback,
    bool silent = false,
  }) async {
    if (!silent) {
      errorText.value = null;
      messageText.value = null;
    }
    try {
      await body();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: fallback);
      final message = SubtitleManualUploadService.errorMessage(e, fallback);
      if (silent) {
        _log.warning(message);
      } else {
        errorText.value = message;
        ToastUtil.error(message);
      }
    }
  }

  void _ensurePageBlock() {
    if (blocks.isEmpty) {
      blocks.assignAll([
        const FormBlock.alert(
          type: 'info',
          text: 'SubtitleManualUpload native renderer',
        ),
      ]);
    }
  }

  void _scheduleIndexPolling({bool force = false}) {
    _indexTimer?.cancel();
    final index = asMap(status.value['index']);
    if (!force && index?['refreshing'] != true) return;
    _indexTimer = Timer(const Duration(seconds: 3), () async {
      await loadStatus(silent: true);
      final next = asMap(status.value['index']);
      if (next?['refreshing'] == true) {
        _scheduleIndexPolling(force: true);
      } else {
        messageText.value = '媒体库资源清单刷新完成';
        if (selectedMedia.value != null) {
          await loadTargets();
        } else {
          await runSearch(reset: true, silent: true);
          await loadMatchHistory(reset: true, silent: true);
        }
      }
    });
  }

  void _startQueuePolling() {
    _queueTimer?.cancel();
    _queueTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => loadAutoTransferQueue(silent: true),
    );
  }

  void _startAiPolling() {
    _aiTimer?.cancel();
    _aiTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await loadAiTasks(silent: true);
      if (!hasActiveAiTasks) {
        _aiTimer?.cancel();
        _aiTimer = null;
      }
    });
  }

  void _startTimelinePolling() {
    _timelineTimer?.cancel();
    _timelineTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await loadTimelineTasks(silent: true);
      if (!hasActiveTimelineTasks) {
        _timelineTimer?.cancel();
        _timelineTimer = null;
      }
    });
  }

  static String _choice(dynamic value, String fallback) {
    final text = _text(value);
    return text.isEmpty ? fallback : text;
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  @override
  void onClose() {
    _indexTimer?.cancel();
    _queueTimer?.cancel();
    _aiTimer?.cancel();
    _timelineTimer?.cancel();
    super.onClose();
  }
}
