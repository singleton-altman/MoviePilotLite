import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_notexists.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/season_episode_detail.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class MediaDetailService extends GetxService {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();
  final _subscribeService = Get.put(SubscribeService());

  String? _getToken() =>
      _appService.loginResponse?.accessToken ??
      _appService.latestLoginProfileAccessToken ??
      _apiClient.token;

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

  Future<List<SeasonInfo>> getSeasonInfo({
    required String mediaId,
    required String season,
    required String title,
    required String year,
  }) async {
    try {
      final payload = {
        'media_id': mediaId,
        'season': season,
        'title': title,
        'year': year,
      };
      final response = await _apiClient.post(
        '/api/v1/mediaserver/seasoninfo',
        data: payload,
      );
      if (response.statusCode != 200) {
        throw ApiAuthException(response.statusCode!, response.statusMessage);
      }
      return (response.data! as List<dynamic>)
          .map((e) => SeasonInfo.fromJson(e))
          .toList();
    } catch (e) {
      _log.handle(e, message: '获取季信息失败');
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
