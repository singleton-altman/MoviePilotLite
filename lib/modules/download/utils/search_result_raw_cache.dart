import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';

final _rawJsonByItem = Expando<Map<String, dynamic>>();

void cacheSearchResultItemRaw(
  SearchResultItem item,
  Map<String, dynamic> json,
) {
  _rawJsonByItem[item] = Map<String, dynamic>.from(json);
}

SearchResultItem parseAndCacheSearchResultItem(Map<String, dynamic> json) {
  final item = SearchResultItem.fromJson(json);
  cacheSearchResultItemRaw(item, json);
  return item;
}

Map<String, dynamic>? rawTorrentInfoFor(SearchResultItem item) {
  final json = _rawJsonByItem[item];
  final torrent = json?['torrent_info'];
  if (torrent is Map<String, dynamic>) {
    return Map<String, dynamic>.from(torrent);
  }
  if (torrent is Map) {
    return Map<String, dynamic>.from(torrent);
  }
  return null;
}

Map<String, dynamic>? rawMediaInfoFor(SearchResultItem item) {
  final json = _rawJsonByItem[item];
  final media = json?['media_info'];
  if (media is Map<String, dynamic>) {
    return Map<String, dynamic>.from(media);
  }
  if (media is Map) {
    return Map<String, dynamic>.from(media);
  }
  return null;
}
