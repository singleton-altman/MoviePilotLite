import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';

class HttpPathBuilderUtil {
  static String buildHttpPath(DiscoverSource source, String mediaId) {
    final key = _keyForSource(source);
    return '$key:$mediaId';
  }

  static String _keyForSource(DiscoverSource source) {
    switch (source) {
      case DiscoverSource.tmdb:
        return 'tmdb';
      case DiscoverSource.douban:
        return 'douban';
      case DiscoverSource.bangumi:
        return 'bangumi';
      case DiscoverSource.anilist:
        return 'anilist';
    }
  }

  static String buildMediaPath(RecommendApiItem item) {
    final storedPrefix = item.mediaid_prefix;
    final prefix = storedPrefix != null && storedPrefix.isNotEmpty
        ? storedPrefix
        : legacyPrefixOf(normalizeMediaSource(item.source));
    final mediaId = item.media_id;
    if (prefix != null &&
        prefix.isNotEmpty &&
        mediaId != null &&
        mediaId.isNotEmpty) {
      return '$prefix:$mediaId';
    }
    final tmdbId = item.tmdb_id;
    if (tmdbId != null && tmdbId.isNotEmpty) {
      return buildHttpPath(DiscoverSource.tmdb, tmdbId);
    }
    final doubanId = item.douban_id;
    if (doubanId != null && doubanId.isNotEmpty) {
      return buildHttpPath(DiscoverSource.douban, doubanId);
    }
    final bangumiId = item.bangumi_id;
    if (bangumiId != null && bangumiId.isNotEmpty) {
      return buildHttpPath(DiscoverSource.bangumi, bangumiId);
    }
    return '';
  }
}
