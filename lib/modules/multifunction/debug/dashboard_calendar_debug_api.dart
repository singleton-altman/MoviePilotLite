import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class DashboardCalendarDebugApi {
  DashboardCalendarDebugApi({
    required ApiClient client,
    required DateTime Function() now,
    bool enabled = const bool.fromEnvironment('DEBUG_CALENDAR_MOCK'),
  }) : _client = client,
       _now = now,
       enabled = kDebugMode && enabled;

  final ApiClient _client;
  final DateTime Function() _now;
  final bool enabled;

  Future<Response<dynamic>> get(
    String path, {
    String? token,
    String? username,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (enabled) {
      final payload = _payload(path, username: username);
      if (payload != null) {
        return Response<dynamic>(
          requestOptions: RequestOptions(
            path: path,
            queryParameters: queryParameters,
          ),
          statusCode: 200,
          data: payload,
        );
      }
    }
    return _client.get<dynamic>(
      path,
      token: token,
      queryParameters: queryParameters,
    );
  }

  List<Map<String, dynamic>>? _payload(String path, {String? username}) {
    if (path == '/api/v1/subscribe/') {
      return List.generate(13, (index) {
        final number = index + 1;
        return {
          'id': number,
          'tmdbid': 990000 + number,
          'name': switch (number) {
            11 => '测试剧集 · 晨光',
            12 => '测试剧集 · 未来六天',
            13 => '测试剧集 · 第13条订阅',
            _ => '测试剧集 · 无近期更新 $number',
          },
          'type': number == 13 ? '剧集' : '电视剧',
          'season': 1,
          'poster': '',
          'username': username ?? 'calendar-mock',
        };
      });
    }
    final match = RegExp(r'^/api/v1/tmdb/(9900\d{2})/1$').firstMatch(path);
    if (match == null) return null;
    final number = int.parse(match.group(1)!) - 990000;
    if (number < 1 || number > 13) return null;
    return switch (number) {
      11 => [_episode(-1, 1), _episode(0, 2), _episode(7, 3)],
      12 => [_episode(1, 3), _episode(6, 4)],
      13 => [_episode(0, 5)],
      _ => [],
    };
  }

  Map<String, dynamic> _episode(int dayOffset, int number) {
    final now = _now();
    final date = DateTime(now.year, now.month, now.day + dayOffset);
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return {
      'id': 990000 + number,
      'name': '测试第 $number 集',
      'air_date': '$year-$month-$day',
      'episode_number': number,
      'season_number': 1,
    };
  }
}
