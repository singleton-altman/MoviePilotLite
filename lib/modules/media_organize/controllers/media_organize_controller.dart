import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/storage/controllers/storage_list_controller.dart';
import 'package:moviepilot_mobile/modules/media_organize/services/transfer_assist_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MediaOrganizeStatusFilter { all, success, failed }

enum MediaOrganizeSortKey { date, title, size }

enum MediaOrganizeViewMode { itemList, titleGrouped }

class MediaOrganizeTitleGroup {
  const MediaOrganizeTitleGroup({
    required this.title,
    required this.items,
    required this.totalSize,
    required this.latestDate,
    required this.successCount,
  });

  final String title;
  final List<MediaOrganizeTransferItem> items;
  final int totalSize;
  final String? latestDate;
  final int successCount;
}

class MediaOrganizeDeleteResult {
  const MediaOrganizeDeleteResult({
    required this.totalCount,
    required this.successCount,
  });

  final int totalCount;
  final int successCount;

  int get failureCount => totalCount - successCount;
  bool get allSuccess => successCount == totalCount;
}

class MediaOrganizeController extends GetxController {
  MediaOrganizeController({String? initialKeyword})
    : _initialKeyword = initialKeyword?.trim() ?? '';

  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _authRepository = Get.find<AuthRepository>();
  final _appService = Get.find<AppService>();
  final String _initialKeyword;
  late final _transferAssist = Get.isRegistered<TransferAssistService>()
      ? Get.find<TransferAssistService>()
      : TransferAssistService();
  final _aiRedoSupported = false.obs;
  final aiRedoSubmitting = false.obs;
  String? _aiRedoServer;

  bool get canAiRedo =>
      _aiRedoSupported.value &&
      _aiRedoServer == _apiClient.baseUrl &&
      _appService.canManage &&
      _appService.aiAgentEnabled.value;

  Future<void> _checkAiRedoSupport() async {
    final server = _apiClient.baseUrl;
    _aiRedoSupported.value = false;
    final supported = await _transferAssist.supportsAiRedo();
    if (isClosed || server != _apiClient.baseUrl) return;
    _aiRedoServer = server;
    _aiRedoSupported.value = supported;
  }

  Future<({bool ok, String message})> aiRedoTransfer(
    MediaOrganizeTransferItem item,
  ) async {
    if (!canAiRedo || item.id == null || item.id! <= 0) {
      return (ok: false, message: '当前服务器或帐号不支持 AI 重新整理');
    }
    if (aiRedoSubmitting.value) {
      return (ok: false, message: '正在提交，请勿重复操作');
    }
    aiRedoSubmitting.value = true;
    try {
      final result = await _transferAssist.aiRedoTransfer([item.id!]);
      // Do not automatically retry a file-changing POST or imply completion.
      return (ok: result.ok, message: result.message);
    } finally {
      aiRedoSubmitting.value = false;
    }
  }

  static const int _pageSize = 50;
  static const String _cacheKeyPrefix = 'media_organize_cache_v1';
  static const String _viewModePrefKey = 'media_organize_view_mode_v1';
  static const String _collapsedGroupsPrefKey =
      'media_organize_collapsed_groups_v1';

  final scrollController = ScrollController();
  int _page = 1;
  final hasMore = true.obs;

  final items = <MediaOrganizeTransferItem>[].obs;
  final isLoading = false.obs;
  final errorText = RxnString();
  final keyword = ''.obs;
  final statusFilter = MediaOrganizeStatusFilter.all.obs;
  final sortKey = MediaOrganizeSortKey.date.obs;
  final isSortAscending = false.obs;
  final viewMode = MediaOrganizeViewMode.itemList.obs;
  final selectedItemKeys = <String>{}.obs;
  final collapsedGroupTitles = <String>{}.obs;

  List<String> get titleOptions {
    final titles = <String>{};
    for (final item in items) {
      final title = item.title?.trim() ?? '';
      if (title.isNotEmpty) {
        titles.add(title);
      }
    }
    final result = titles.toList();
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  List<MediaOrganizeTransferItem> get filteredItems {
    final q = keyword.value.trim().toLowerCase();
    final filtered = items.where((item) {
      final matchesKeyword = q.isEmpty ? true : _matchKeyword(item, q);
      if (!matchesKeyword) return false;
      switch (statusFilter.value) {
        case MediaOrganizeStatusFilter.all:
          return true;
        case MediaOrganizeStatusFilter.success:
          return item.status == true;
        case MediaOrganizeStatusFilter.failed:
          return item.status != true;
      }
    }).toList();

    filtered.sort(_compareItems);
    return filtered;
  }

  List<MediaOrganizeTitleGroup> get groupedItems {
    final grouped = <String, List<MediaOrganizeTransferItem>>{};
    for (final item in filteredItems) {
      final title = titleForItem(item);
      grouped.putIfAbsent(title, () => <MediaOrganizeTransferItem>[]).add(item);
    }

    final groups = grouped.entries.map((entry) {
      final groupItems = List<MediaOrganizeTransferItem>.from(entry.value)
        ..sort(_compareItems);
      final latestDate = _latestDateOf(groupItems);
      final totalSize = groupItems.fold<int>(
        0,
        (sum, item) => sum + (item.src_fileitem?.size ?? 0),
      );
      final successCount = groupItems
          .where((item) => item.status == true)
          .length;
      return MediaOrganizeTitleGroup(
        title: entry.key,
        items: groupItems,
        totalSize: totalSize,
        latestDate: latestDate,
        successCount: successCount,
      );
    }).toList();

    groups.sort(_compareGroups);
    return groups;
  }

  bool get hasActiveFilters =>
      statusFilter.value != MediaOrganizeStatusFilter.all;
  bool get isGroupedView =>
      viewMode.value == MediaOrganizeViewMode.titleGrouped;
  bool get hasSelection => selectedItemKeys.isNotEmpty;
  int get selectedCount => selectedItems.length;
  List<MediaOrganizeTransferItem> get selectedItems => filteredItems
      .where((item) => selectedItemKeys.contains(itemKeyOf(item)))
      .toList(growable: false);
  StorageListController get _storageController =>
      Get.find<StorageListController>();

  List<StorageSetting> get storages => _storageController.storages;
  Map<String, String> get storageNameMap =>
      Map.from(_storageController.storageNameMap);

  @override
  void onReady() {
    super.onReady();
    if (_initialKeyword.isNotEmpty) {
      keyword.value = _initialKeyword;
    }
    unawaited(_bootstrap());
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// 委托 StorageListController 加载存储列表
  Future<void> loadStorages() async {
    await _storageController.loadStorages();
  }

  Future<void> _bootstrap() async {
    await _restorePreferences();
    await _restoreCachedItems();
    unawaited(loadStorages());
    await load();
  }

  /// 根据 storage type 获取显示名称
  String getStorageName(String? type) {
    return _storageController.getStorageName(type);
  }

  void updateKeyword(String value) {
    final next = value.trim();
    if (keyword.value == next) return;
    keyword.value = next;
    clearSelection();
    unawaited(_restoreCachedItems());
    load();
  }

  void updateStatusFilter(MediaOrganizeStatusFilter value) {
    if (statusFilter.value == value) return;
    statusFilter.value = value;
    clearSelection();
  }

  Future<void> resetFiltersToAll() async {
    final shouldReload =
        keyword.value.isNotEmpty ||
        statusFilter.value != MediaOrganizeStatusFilter.all;
    keyword.value = '';
    statusFilter.value = MediaOrganizeStatusFilter.all;
    clearSelection();
    if (!shouldReload) return;
    await _restoreCachedItems();
    await load();
  }

  void updateSortKey(MediaOrganizeSortKey value) {
    sortKey.value = value;
  }

  void updateSortDirection(bool ascending) {
    isSortAscending.value = ascending;
  }

  void updateViewMode(MediaOrganizeViewMode value) {
    if (viewMode.value == value) return;
    viewMode.value = value;
    if (value == MediaOrganizeViewMode.itemList) {
      clearSelection();
    } else {
      collapseAllGroups();
    }
    unawaited(_saveViewMode());
  }

  void toggleViewMode() {
    updateViewMode(
      viewMode.value == MediaOrganizeViewMode.itemList
          ? MediaOrganizeViewMode.titleGrouped
          : MediaOrganizeViewMode.itemList,
    );
  }

  String titleForItem(MediaOrganizeTransferItem item) {
    final title = item.title?.trim() ?? '';
    return title.isEmpty ? '未命名标题' : title;
  }

  String itemKeyOf(MediaOrganizeTransferItem item) {
    final id = item.id;
    if (id != null) {
      return 'id:$id';
    }
    return [
      item.title ?? '',
      item.date ?? '',
      item.src ?? '',
      item.dest ?? '',
    ].join('::');
  }

  bool isItemSelected(MediaOrganizeTransferItem item) {
    return selectedItemKeys.contains(itemKeyOf(item));
  }

  void toggleItemSelection(MediaOrganizeTransferItem item) {
    final key = itemKeyOf(item);
    if (selectedItemKeys.contains(key)) {
      selectedItemKeys.remove(key);
    } else {
      selectedItemKeys.add(key);
    }
  }

  void clearSelection() {
    if (selectedItemKeys.isEmpty) return;
    selectedItemKeys.clear();
  }

  int selectedCountForGroup(MediaOrganizeTitleGroup group) {
    return group.items.where(isItemSelected).length;
  }

  bool isGroupFullySelected(MediaOrganizeTitleGroup group) {
    return group.items.isNotEmpty &&
        group.items.every((item) => isItemSelected(item));
  }

  bool isGroupPartiallySelected(MediaOrganizeTitleGroup group) {
    final count = selectedCountForGroup(group);
    return count > 0 && count < group.items.length;
  }

  void toggleGroupSelection(MediaOrganizeTitleGroup group) {
    if (isGroupFullySelected(group)) {
      clearGroupSelection(group);
      return;
    }
    selectGroup(group);
  }

  void selectGroup(MediaOrganizeTitleGroup group) {
    for (final item in group.items) {
      selectedItemKeys.add(itemKeyOf(item));
    }
  }

  void clearGroupSelection(MediaOrganizeTitleGroup group) {
    for (final item in group.items) {
      selectedItemKeys.remove(itemKeyOf(item));
    }
  }

  void invertGroupSelection(MediaOrganizeTitleGroup group) {
    for (final item in group.items) {
      final key = itemKeyOf(item);
      if (selectedItemKeys.contains(key)) {
        selectedItemKeys.remove(key);
      } else {
        selectedItemKeys.add(key);
      }
    }
  }

  bool isGroupCollapsed(String title) {
    return collapsedGroupTitles.contains(title);
  }

  void toggleGroupCollapsed(String title) {
    if (collapsedGroupTitles.contains(title)) {
      collapsedGroupTitles.remove(title);
    } else {
      collapsedGroupTitles.add(title);
    }
    unawaited(_saveCollapsedGroups());
  }

  void collapseAllGroups() {
    collapsedGroupTitles
      ..clear()
      ..addAll(groupedItems.map((group) => group.title));
    unawaited(_saveCollapsedGroups());
  }

  Future<void> load() async {
    unawaited(_checkAiRedoSupport());
    await _refreshImageCookie();
    final hasLocalData = items.isNotEmpty;
    clearSelection();
    isLoading.value = true;
    errorText.value = null;
    _page = 1;
    hasMore.value = true;
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/history/transfer',
        queryParameters: {
          'page': _page,
          'count': _pageSize,
          if (keyword.value.isNotEmpty) 'title': keyword.value,
        },
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        if (!hasLocalData) {
          items.clear();
        }
        return;
      }
      final list = _extractList(response.data);
      final parsed = <MediaOrganizeTransferItem>[];
      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          try {
            final item = MediaOrganizeTransferItem.fromJson(raw);
            parsed.add(item);
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析整理历史失败');
            continue;
          }
        }
      }
      items.assignAll(parsed);
      hasMore.value = parsed.length >= _pageSize;
      _pruneCollapsedGroups();
      await _saveCachedItems(parsed);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取整理历史失败');
      errorText.value = '请求失败，请稍后重试';
      if (!hasLocalData) {
        items.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value || items.isEmpty) return;
    isLoading.value = true;
    _page += 1;
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/history/transfer',
        queryParameters: {
          'page': _page,
          'count': _pageSize,
          if (keyword.value.isNotEmpty) 'title': keyword.value,
        },
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        _page -= 1;
        hasMore.value = false;
        return;
      }
      final list = _extractList(response.data);
      final parsed = <MediaOrganizeTransferItem>[];
      for (final raw in list) {
        if (raw is Map<String, dynamic>) {
          try {
            final item = MediaOrganizeTransferItem.fromJson(raw);
            parsed.add(item);
          } catch (e, st) {
            _log.handle(e, stackTrace: st, message: '解析整理历史失败');
            continue;
          }
        }
      }
      items.addAll(parsed);
      hasMore.value = parsed.length >= _pageSize;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载更多整理历史失败');
      _page -= 1;
    } finally {
      isLoading.value = false;
    }
  }

  String _cacheKeyForKeyword(String raw) {
    final value = raw.trim().toLowerCase();
    return '$_cacheKeyPrefix::$value';
  }

  Future<void> _restoreCachedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKeyForKeyword(keyword.value));
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final parsed = <MediaOrganizeTransferItem>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        try {
          parsed.add(MediaOrganizeTransferItem.fromJson(item));
        } catch (_) {
          continue;
        }
      }
      if (parsed.isEmpty) return;
      items.assignAll(parsed);
      hasMore.value = parsed.length >= _pageSize;
      _pruneCollapsedGroups();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '读取整理历史缓存失败');
    }
  }

  Future<void> _saveCachedItems(List<MediaOrganizeTransferItem> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = list.map((e) => e.toJson()).toList(growable: false);
      await prefs.setString(
        _cacheKeyForKeyword(keyword.value),
        jsonEncode(payload),
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '写入整理历史缓存失败');
    }
  }

  Iterable<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        final list = data['list'];
        if (list is List) return list;
      }
    }
    return const [];
  }

  Future<bool> deleteTransferRecord(
    MediaOrganizeTransferItem item, {
    required bool deletesrc,
    required bool deletedest,
  }) async {
    try {
      final response = await _apiClient.request<dynamic>(
        '/api/v1/history/transfer',
        RequestMethod.delete,
        item.toJson(),
        queryParameters: {'deletesrc': deletesrc, 'deletedest': deletedest},
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        return false;
      }
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == false) {
        return false;
      }
      items.remove(item);
      selectedItemKeys.remove(itemKeyOf(item));
      _pruneCollapsedGroups();
      return true;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '删除整理历史失败');
      return false;
    }
  }

  Future<MediaOrganizeDeleteResult> deleteSelectedTransferRecords({
    required bool deletesrc,
    required bool deletedest,
  }) async {
    final targets = selectedItems.toList(growable: false);
    var successCount = 0;
    for (final item in targets) {
      final success = await deleteTransferRecord(
        item,
        deletesrc: deletesrc,
        deletedest: deletedest,
      );
      if (success) {
        successCount += 1;
      }
    }
    return MediaOrganizeDeleteResult(
      totalCount: targets.length,
      successCount: successCount,
    );
  }

  bool _matchKeyword(MediaOrganizeTransferItem item, String keyword) {
    final fields = <String?>[
      item.title,
      item.type,
      item.category,
      item.mode,
      item.year,
      item.src,
      item.dest,
      item.errmsg,
      item.date,
      item.src_storage,
      item.dest_storage,
    ];
    return fields.any((field) => (field ?? '').toLowerCase().contains(keyword));
  }

  int _compareItems(MediaOrganizeTransferItem a, MediaOrganizeTransferItem b) {
    final factor = isSortAscending.value ? 1 : -1;
    switch (sortKey.value) {
      case MediaOrganizeSortKey.date:
        return _compareNullableStrings(a.date, b.date) * factor;
      case MediaOrganizeSortKey.title:
        return _compareNullableStrings(a.title, b.title) * factor;
      case MediaOrganizeSortKey.size:
        return _compareNullableInts(
              a.src_fileitem?.size ?? 0,
              b.src_fileitem?.size ?? 0,
            ) *
            factor;
    }
  }

  int _compareGroups(MediaOrganizeTitleGroup a, MediaOrganizeTitleGroup b) {
    final factor = isSortAscending.value ? 1 : -1;
    switch (sortKey.value) {
      case MediaOrganizeSortKey.date:
        return _compareNullableStrings(a.latestDate, b.latestDate) * factor;
      case MediaOrganizeSortKey.title:
        return _compareNullableStrings(a.title, b.title) * factor;
      case MediaOrganizeSortKey.size:
        return _compareNullableInts(a.totalSize, b.totalSize) * factor;
    }
  }

  int _compareNullableStrings(String? a, String? b) {
    return (a ?? '').toLowerCase().compareTo((b ?? '').toLowerCase());
  }

  int _compareNullableInts(int a, int b) {
    if (a == b) return 0;
    return a < b ? -1 : 1;
  }

  Future<void> _refreshImageCookie() async {
    final server = _appService.baseUrl ?? _apiClient.baseUrl;
    final token =
        _appService.loginResponse?.accessToken ??
        _appService.latestLoginProfileAccessToken ??
        _apiClient.token;
    if (server == null || server.isEmpty || token == null || token.isEmpty) {
      return;
    }
    try {
      await _authRepository.getUserGlobalConfig(
        server: server,
        accessToken: token,
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '刷新媒体整理图片 Cookie 失败');
    }
  }

  String? _latestDateOf(List<MediaOrganizeTransferItem> items) {
    String? latest;
    for (final item in items) {
      final value = item.date;
      if (value == null || value.isEmpty) continue;
      if (latest == null || _compareNullableStrings(latest, value) < 0) {
        latest = value;
      }
    }
    return latest;
  }

  Future<void> _restorePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeName = prefs.getString(_viewModePrefKey);
      final restoredMode = MediaOrganizeViewMode.values.firstWhereOrNull(
        (mode) => mode.name == modeName,
      );
      if (restoredMode != null) {
        viewMode.value = restoredMode;
      }
      final titles = prefs.getStringList(_collapsedGroupsPrefKey) ?? const [];
      collapsedGroupTitles
        ..clear()
        ..addAll(titles);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '读取整理历史展示偏好失败');
    }
  }

  Future<void> _saveViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_viewModePrefKey, viewMode.value.name);
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '写入整理历史展示偏好失败');
    }
  }

  Future<void> _saveCollapsedGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _collapsedGroupsPrefKey,
        collapsedGroupTitles.toList(growable: false),
      );
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '写入整理历史折叠状态失败');
    }
  }

  void _pruneCollapsedGroups() {
    final validTitles = titleOptions.toSet()..add('未命名标题');
    final before = collapsedGroupTitles.length;
    collapsedGroupTitles.removeWhere((title) => !validTitles.contains(title));
    if (before != collapsedGroupTitles.length) {
      unawaited(_saveCollapsedGroups());
    }
  }
}
