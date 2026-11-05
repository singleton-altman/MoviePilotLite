/// 播放列表控制器
/// 管理剧集列表、当前播放索引、上一集/下一集切换
class PlaylistController {
  final List<PlaylistItem> _items = [];
  int _currentIndex = 0;

  List<PlaylistItem> get items => List.unmodifiable(_items);
  int get currentIndex => _currentIndex;
  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// 当前播放项
  PlaylistItem? get current => _items.isEmpty || _currentIndex >= _items.length ? null : _items[_currentIndex];

  /// 下一集
  PlaylistItem? get next => _currentIndex + 1 < _items.length ? _items[_currentIndex + 1] : null;

  /// 上一集
  PlaylistItem? get previous => _currentIndex - 1 >= 0 ? _items[_currentIndex - 1] : null;

  /// 设置播放列表
  void setItems(List<PlaylistItem> items, {int startIndex = 0}) {
    _items
      ..clear()
      ..addAll(items);
    _currentIndex = startIndex.clamp(0, _items.length - 1);
  }

  /// 切换到指定索引
  PlaylistItem? jumpTo(int index) {
    if (index < 0 || index >= _items.length) return null;
    _currentIndex = index;
    return current;
  }

  /// 切换到下一集
  PlaylistItem? nextItem() {
    if (_currentIndex + 1 >= _items.length) return null;
    _currentIndex++;
    return current;
  }

  /// 切换到上一集
  PlaylistItem? previousItem() {
    if (_currentIndex - 1 < 0) return null;
    _currentIndex--;
    return current;
  }

  /// 清空
  void clear() {
    _items.clear();
    _currentIndex = 0;
  }
}

/// 播放列表项
class PlaylistItem {
  final String id;
  final String title;
  final String streamUrl;
  final Map<String, String>? httpHeaders;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? posterUrl;

  const PlaylistItem({
    required this.id,
    required this.title,
    required this.streamUrl,
    this.httpHeaders,
    this.seasonNumber,
    this.episodeNumber,
    this.posterUrl,
  });
}
