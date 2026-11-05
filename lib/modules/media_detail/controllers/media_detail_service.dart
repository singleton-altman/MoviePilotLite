import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_notexists.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/season_episode_detail.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';

class MediaDetailService extends GetxService {
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();
  final _subscribeService = Get.put(SubscribeService());
  ServerApiVersionService get _serverApiVersionService =>
      Get.find<ServerApiVersionService>();

  Future<List<MediaNotExists>> getMediaNotExists(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/mediaserver/notexists',
        data: payload,
      );
      if (response.statusCode != 200) {
        throw ApiAuthException(response.statusCode!, response.statusMessage);
      }
      final list = response.data as List;

      return list
          .map((e) => MediaNotExists.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.handle(e, message: '获取媒体不存在信息失败');
      return [];
    }
  }

  /// GET /api/v1/media/seasons 获取媒体可订阅的季度列表。
  /// v2 使用原始 mediaid；v3 拆分为 media_source 与 media_id。
  Future<List<SeasonInfo>> getMediaSeasons({
    required String mediaId,
    required String title,
    required String year,
  }) async {
    try {
      final identity = MediaIdentity.parse(mediaId);
      final useV3 =
          identity != null && await _serverApiVersionService.isV3();
      final query = useV3
          ? <String, dynamic>{
              'media_source': identity.source,
              'media_id': identity.id,
              if (title.trim().isNotEmpty) 'title': title.trim(),
              if (year.trim().isNotEmpty) 'year': year.trim(),
            }
          : <String, dynamic>{
              'mediaid': mediaId,
              if (title.trim().isNotEmpty) 'title': title.trim(),
              if (year.trim().isNotEmpty) 'year': year.trim(),
            };
      final response = await _apiClient.get<dynamic>(
        '/api/v1/media/seasons',
        queryParameters: query,
      );
      if (response.statusCode != 200) {
        throw ApiAuthException(
          response.statusCode ?? 0,
          response.statusMessage,
        );
      }
      final data = response.data;
      final rawList = data is List
          ? data
          : data is Map
          ? (data['data'] ??
                data['results'] ??
                data['items'] ??
                data['seasons'])
          : null;
      if (rawList is! List) return [];
      return rawList
          .whereType<Map>()
          .map((e) => SeasonInfo.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.season_number != null)
          .toList();
    } catch (e) {
      _log.handle(e, message: '获取媒体季度列表失败');
      return [];
    }
  }

  /// GET /api/v1/tmdb/{tmdbId}/{seasonNumber} 获取指定季的集数详情列表
  Future<List<SeasonEpisodeDetail>> getSeasonDetail({
    required String reqPath,
  }) async {
    try {
      final response = await _apiClient.get<dynamic>('/api/v1/$reqPath');
      if (response.statusCode != 200) {
        throw ApiAuthException(
          response.statusCode ?? 0,
          response.statusMessage ?? '',
        );
      }
      final list = response.data;
      if (list is! List) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => SeasonEpisodeDetail.fromJson(e))
          .toList();
    } catch (e) {
      _log.handle(e, message: '获取季详情失败');
      return [];
    }
  }

  /// GET /api/v1/subscribe/media/{mediaKey}?season=&title= 获取媒体/季的订阅状态
  /// 参考 media detail：mediaKey 与详情 path 一致，如 tmdb:1434
  /// 返回订阅 item 的 json 结构，未订阅时可能 404 或空
  Future<SubscribeItem?> getSubscribeMediaStatus(
    String mediaKey, {
    int? season,
    String? title,
  }) async {
    try {
      return _subscribeService.fetchAndSaveSubscribeStatus(
        mediaKey,
        season: season,
        title: title,
      );
    } catch (e) {
      _log.handle(e, message: '获取订阅状态失败');
      return null;
    }
  }
}
