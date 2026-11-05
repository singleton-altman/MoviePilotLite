enum SearchSuggestionCategory {
  mediaTitle,
  mediaCollection,
  actor,
  music,
  share,
  history,
  subscription,
  site,
}

class SearchSuggestionItem {
  const SearchSuggestionItem({
    required this.category,
    required this.title,
    required this.keyword,
    this.leading,
    this.subtitle,
  });

  final SearchSuggestionCategory category;

  /// 主体展示的文案，会在 UI 中根据 keyword 进行高亮
  final String title;

  /// 用户当前输入关键字
  final String keyword;

  /// 左侧的分组标题，例如“媒体”“订阅”等
  final String? leading;

  /// 次级描述
  final String? subtitle;
}
