import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_submit_resp.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class SubscribeService extends GetxService {
  final subscribeItems = <String, SubscribeItem?>{}.obs;
  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();

  Future<SubscribeItem?> fetchAndSaveSubscribeStatus(
    String mediaKey, {
    int? season,
    String? title,
  }) async {
    final subscribeItem = await getSubscribeMediaStatus(
      mediaKey,
      season: season,
      title: title,
    );
    final key =
        '$mediaKey${season != null ? ':$season' : ''}${title != null ? ':$title' : ''}';
    subscribeItems[key] = subscribeItem;
    return subscribeItem;
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
      final path = '/api/v1/subscribe/media/$mediaKey';
      final query = <String, dynamic>{};
      if (season != null) query['season'] = season;
      if (title != null && title.trim().isNotEmpty) {
        query['title'] = title.trim();
      }
      final response = await _apiClient.get<dynamic>(
        path,
        queryParameters: query.isNotEmpty ? query : null,
      );
      if (response.statusCode == 404 || response.statusCode == 204) return null;
      if (response.statusCode != 200) return null;
      final data = response.data;
      SubscribeItem? subscribeItem;
      if (data is Map<String, dynamic>) {
        subscribeItem = SubscribeItem.fromJson(data);
      }
      if (data is Map) {
        subscribeItem = SubscribeItem.fromJson(Map<String, dynamic>.from(data));
      }
      if (subscribeItem != null && subscribeItem.id != null) {
        return subscribeItem;
      }
      return null;
    } catch (e) {
      _log.handle(e, message: '获取订阅状态失败');
      return null;
    }
  }

  Future<bool> toggleMediaSubscribe({
    required String mediaKey,
    required bool isTv,
    required bool isSubscribed,
    String? doubanid,
    String? name,
    int? season,
    String? year,
    String? tmdbid,
    String? subscribeId,
  }) async {
    if (isSubscribed) {
      if (subscribeId != null) {
        final ok = await deleteSubscribes(subscribeId);
        return ok;
      } else {
        final ok = await deleteMediaSubscribe(
          mediaKey,
          season: season?.toString() ?? '0',
        );
        return ok;
      }
    }

    if (isTv) {
      final ok = await submitTvSubscribe(
        doubanid: doubanid,
        name: name,
        season: season,
        year: year,
        tmdbid: tmdbid,
      );
      return ok.success == true;
    } else {
      final ok = await submitMovieSubscribe(
        doubanid: doubanid,
        name: name,
        season: season,
        year: year,
        tmdbid: tmdbid,
      );
      return ok.success == true;
    }
  }

  Future<SubscribeSubmitResp> submitSubscribe(
    String mediaType, {
    required Map<String, dynamic> payload,
  }) async {
    try {
      final path = '/api/v1/subscribe/';
      final response = await _apiClient.post(path, data: payload);
      if (response.statusCode == 200) {
        return SubscribeSubmitResp.fromJson(response.data);
      }
      return SubscribeSubmitResp(success: false, message: '请求失败');
    } catch (e) {
      _log.handle(e, message: '提交订阅失败');
      return SubscribeSubmitResp(success: false, message: '请求失败');
    }
  }

  Future<SubscribeSubmitResp> submitMovieSubscribe({
    String? bangumiid,
    int? bestVersion = 0,
    String? doubanid,
    String? episodeGroup = '',
    String? mediaid = '',
    String? name,
    int? season = 0,
    String? tmdbid,
    String? year = '',
  }) async {
    final payload = {
      'bangumiid': bangumiid,
      'best_version': bestVersion,
      'doubanid': doubanid,
      'episode_group': episodeGroup,
      'mediaid': mediaid,
      'name': name,
      'season': season,
      'tmdbid': tmdbid,
      'year': year,
    };
    final resp = await submitSubscribe('movie', payload: payload);
    return resp;
  }

  Future<SubscribeSubmitResp> submitTvSubscribe({
    String? doubanid,
    String? episode_group = '',
    String? mediaid = '',
    String? name,
    int? season = 0,
    String? tmdbid,
    String? year = '',
  }) async {
    final payload = {
      'doubanid': doubanid,
      'episode_group': episode_group,
      'mediaid': mediaid,
      'name': name,
      'season': season,
      'tmdbid': tmdbid,
      'year': year,
      'best_version': 0,
      'type': '电视剧',
    };
    return await submitSubscribe('tv', payload: payload);
  }

  Future<bool> deleteMediaSubscribe(
    String mediaKey, {
    String season = '0',
  }) async {
    final response = await _apiClient.delete(
      '/api/v1/subscribe/media/$mediaKey',
      queryParameters: {'season': season},
    );
    return response.statusCode == 200 && response.data['success'] == true;
  }

  Future<bool> deleteSubscribes(String id) async {
    final response = await _apiClient.delete('/api/v1/subscribe/$id');
    return response.statusCode == 200 && response.data['success'] == true;
  }
}
