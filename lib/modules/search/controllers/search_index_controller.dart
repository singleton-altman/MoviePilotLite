import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/pages/search_mid_sheet.dart';
import 'package:moviepilot_mobile/modules/search/services/search_keyword_hints_service.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

import '../models/search_history.dart';
import '../models/search_suggestion.dart';
import '../repositories/search_history_repository.dart';

class SearchInputPick {
  const SearchInputPick({required this.keyword, this.sourceEntry});

  final String keyword;
  final SearchHistoryEntry? sourceEntry;
}

class SearchIndexController extends GetxController {
  SearchIndexController({SearchHistoryRepository? historyRepository})
    : _historyRepository =
          historyRepository ??
          Get.put(SearchHistoryRepository(), permanent: true);

  static const _debounceDuration = Duration(milliseconds: 150);

  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final RxString keyword = ''.obs;
  final RxBool isEditing = false.obs;
  final RxList<SearchHistoryEntry> histories = <SearchHistoryEntry>[].obs;
  final RxList<SearchSuggestionItem> suggestions = <SearchSuggestionItem>[].obs;
  final RxBool hasSearchFocus = false.obs;

  late final Worker _keywordWorker;
  final SearchHistoryRepository _historyRepository;

  final PageController recommendPagerController = PageController(
    viewportFraction: 0.94,
  );

  static const int _maxHistorySuggestions = 12;

  @override
  void onInit() {
    super.onInit();
    textController.addListener(_handleTextChange);
    focusNode.addListener(_syncSearchFocus);
    _syncSearchFocus();
    _keywordWorker = debounce<String>(
      keyword,
      (_) => _refreshSuggestions(),
      time: _debounceDuration,
    );
    loadHistories();
  }

  void _syncSearchFocus() {
    hasSearchFocus.value = focusNode.hasFocus;
  }

  @override
  void onClose() {
    textController.removeListener(_handleTextChange);
    focusNode.removeListener(_syncSearchFocus);
    textController.dispose();
    focusNode.dispose();
    recommendPagerController.dispose();
    _keywordWorker.dispose();
    super.onClose();
  }

  List<SearchInputPick> get historyInputSuggestions {
    final q = keyword.value.trim().toLowerCase();
    final hintSvc = Get.find<SearchKeywordHintsService>();
    hintSvc.hints.length;
    final hintStrings = hintSvc.hints;
    final fromHistory = List<SearchHistoryEntry>.from(histories)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final seen = <String>{};
    final out = <SearchInputPick>[];
    void addPick(String kw, {SearchHistoryEntry? entry}) {
      final k = kw.trim();
      if (k.isEmpty) return;
      final lo = k.toLowerCase();
      if (!seen.add(lo)) return;
      if (q.isNotEmpty && !lo.contains(q)) return;
      out.add(SearchInputPick(keyword: k, sourceEntry: entry));
    }

    for (final e in fromHistory) {
      if (out.length >= _maxHistorySuggestions) break;
      addPick(e.keyword, entry: e);
    }
    for (final h in hintStrings) {
      if (out.length >= _maxHistorySuggestions) break;
      addPick(h);
    }
    return out;
  }

  void applyHistorySuggestion(SearchInputPick pick) {
    fillKeyword(pick.keyword, focus: false);
    focusNode.unfocus();
    submit(pick.keyword);
  }

  Future<void> loadHistories() async {
    final items = await _historyRepository.load();
    histories.assignAll(items);
  }

  Future<void> saveHistory(String term) async {
    await _historyRepository.save(term);
    await loadHistories();
  }

  void submit([String? value]) {
    var term = (value ?? keyword.value).trim();
    if (term.isEmpty) {
      term = textController.text.trim();
    }
    if (term.isEmpty) return;
    openMediaSearch(term);
  }

  void openMediaSearch(
    String keyword, {
    SearchSuggestionItem? suggestion,
  }) async {
    final term = keyword.trim();
    if (term.isEmpty) return;
    focusNode.unfocus();
    try {
      saveHistory(term);
    } catch (_) {}
    switch (suggestion?.category) {
      case SearchSuggestionCategory.mediaTitle:
        Get.toNamed(
          '/media-search-list',
          parameters: {'keyword': term, 'type': 'media'},
        );
        break;
      case SearchSuggestionCategory.mediaCollection:
        Get.toNamed(
          '/media-search-list',
          parameters: {'keyword': term, 'type': 'collection'},
        );
        break;
      case SearchSuggestionCategory.actor:
        Get.toNamed(
          '/media-search-list',
          parameters: {'keyword': term, 'type': 'person'},
        );
        break;
      case SearchSuggestionCategory.share:
        Get.toNamed('/subscribe-share', parameters: {'keyword': term});
        break;
      case SearchSuggestionCategory.history:
        Get.toNamed('/media-organize', parameters: {'keyword': term});
        break;
      case SearchSuggestionCategory.subscription:
        Get.toNamed('/subscribe-tv', parameters: {'keyword': term});
        break;
      case SearchSuggestionCategory.site:
        if (!Get.find<AppService>().canSearch) {
          ToastUtil.info('当前帐号无资源搜索权限');
          return;
        }
        final result = await Get.bottomSheet<({String area, List<int> sites})>(
          SiteSelectSheet(hasSegment: false),
          isScrollControlled: true,
        );
        if (result == null) return;
        final (area, sites) = (result.area, result.sites);
        if (sites.isEmpty) {
          ToastUtil.info('请至少选择一个站点');
          return;
        }
        final params = <String, String>{
          'mediaSearchKey': 'search/title',
          'area': area,
          'sites': sites.join(','),
          'title': term,
          'type': 'title',
        };
        Get.toNamed('/search-media-result', parameters: params);
        break;
      default:
        Get.toNamed(
          '/media-search-list',
          parameters: {'keyword': term, 'type': 'media'},
        );
        break;
    }
  }

  void fillKeyword(String value, {bool focus = false}) {
    textController.text = value;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
    if (focus) {
      focusNode.requestFocus();
    }
  }

  void requestSearchBarFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!focusNode.canRequestFocus) return;
      focusNode.requestFocus();
    });
  }

  void _handleTextChange() {
    final value = textController.text;
    keyword.value = value;
    isEditing.value = value.trim().isNotEmpty;
    if (value.trim().isEmpty) {
      suggestions.clear();
    }
  }

  void _refreshSuggestions() {
    final term = keyword.value.trim();
    if (term.isEmpty) {
      suggestions.clear();
      return;
    }
    suggestions.assignAll(_buildSuggestions(term));
  }

  List<SearchSuggestionItem> _buildSuggestions(String term) {
    final quoted = '"$term"';
    return [
      SearchSuggestionItem(
        category: SearchSuggestionCategory.mediaTitle,
        leading: '媒体',
        title: '电影 / 电视剧 $quoted',
        subtitle: '全局媒体搜索',
        keyword: term,
      ),
      SearchSuggestionItem(
        category: SearchSuggestionCategory.mediaCollection,
        leading: '媒体',
        title: '系列合集 $quoted',
        subtitle: '匹配合集/系列',
        keyword: term,
      ),
      SearchSuggestionItem(
        category: SearchSuggestionCategory.actor,
        leading: '媒体',
        title: '演员 $quoted',
        subtitle: '按演员名称搜索',
        keyword: term,
      ),
      SearchSuggestionItem(
        category: SearchSuggestionCategory.share,
        leading: '媒体',
        title: '搜索订阅分享 $quoted',
        subtitle: '快速查找分享/订阅',
        keyword: term,
      ),
      SearchSuggestionItem(
        category: SearchSuggestionCategory.history,
        leading: '历史',
        title: '历史记录 $quoted',
        subtitle: '基于本地搜索',
        keyword: term,
      ),
      SearchSuggestionItem(
        category: SearchSuggestionCategory.subscription,
        leading: 'TODO://订阅',
        title: quoted,
        subtitle: '订阅库内匹配',
        keyword: term,
      ),
      SearchSuggestionItem(
        category: SearchSuggestionCategory.site,
        leading: '站点',
        title: '站点搜索 $quoted',
        subtitle: '跨站点检索',
        keyword: term,
      ),
    ];
  }

  List<SearchSuggestionItem> get mediaSuggestionItems => suggestions
      .where((item) => _mediaCategories.contains(item.category))
      .toList();

  List<SearchSuggestionItem> get siteSuggestionItems => suggestions
      .where((item) => item.category == SearchSuggestionCategory.site)
      .toList();

  List<SearchSuggestionItem> get localHistorySuggestionItems => suggestions
      .where((item) => item.category == SearchSuggestionCategory.history)
      .toList();

  static const Set<SearchSuggestionCategory> _mediaCategories = {
    SearchSuggestionCategory.mediaTitle,
    SearchSuggestionCategory.mediaCollection,
    SearchSuggestionCategory.actor,
    SearchSuggestionCategory.share,
    SearchSuggestionCategory.subscription,
  };
}
