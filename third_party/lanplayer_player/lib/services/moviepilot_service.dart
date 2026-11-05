import 'dart:async';
import 'package:dio/dio.dart';
import '../models/media_models.dart';
import '../utils/app_log.dart';

class MoviePilotService {
  final String baseUrl;
  final String? username;
  final String? password;
  final String? apiKey;
  String? _accessToken;
  final Dio _dio;
  static const String _apiPath = '/api/v1';
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshCompleters = [];
  String? lastError;

  MoviePilotService({
    required this.baseUrl,
    this.username,
    this.password,
    this.apiKey,
    Dio? dioClient,
  }) : _dio = dioClient ?? Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json; charset=utf-8',
          },
        )) {
    _setupInterceptor();
    if (apiKey != null && apiKey!.isNotEmpty) {
      _dio.options.headers['X-API-Key'] = apiKey;
    } else if (username != null && password != null) {
      login();
    }
  }

  void _setupInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null && options.headers['X-API-Key'] == null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final originalRequest = error.requestOptions;
          if (!_isRefreshing && username != null && password != null && originalRequest.headers['X-API-Key'] == null) {
            _isRefreshing = true;
            final completer = Completer<void>();
            _refreshCompleters.add(completer);

            try {
              final success = await login();
              if (success) {
                _refreshCompleters.forEach((c) => c.complete());
                _refreshCompleters.clear();

                originalRequest.headers['Authorization'] = 'Bearer $_accessToken';
                final response = await _dio.request(
                  originalRequest.path,
                  options: Options(
                    method: originalRequest.method,
                    headers: originalRequest.headers,
                  ),
                  data: originalRequest.data,
                  queryParameters: originalRequest.queryParameters,
                );
                return handler.resolve(response);
              } else {
                _refreshCompleters.forEach((c) => c.completeError(error));
                _refreshCompleters.clear();
              }
            } catch (e) {
              _refreshCompleters.forEach((c) => c.completeError(e));
              _refreshCompleters.clear();
            } finally {
              _isRefreshing = false;
            }
          } else if (_isRefreshing && originalRequest.headers['X-API-Key'] == null) {
            final completer = Completer<void>();
            _refreshCompleters.add(completer);
            try {
              await completer.future;
              originalRequest.headers['Authorization'] = 'Bearer $_accessToken';
              final response = await _dio.request(
                originalRequest.path,
                options: Options(
                  method: originalRequest.method,
                  headers: originalRequest.headers,
                ),
                data: originalRequest.data,
                queryParameters: originalRequest.queryParameters,
              );
              return handler.resolve(response);
            } catch (e) {
              return handler.reject(error);
            }
          }
        }
        handler.reject(error);
      },
    ));
  }

  Future<bool> login() async {
    if (username == null || password == null) return false;

    try {
      final response = await _dio.post('$_apiPath/login/access-token',
        data: {'username': username, 'password': password},
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'] ?? response.data['token'];
        _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void setAccessToken(String token) {
    _accessToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
    _dio.options.headers.remove('X-API-Key');
  }

  Future<bool> testConnection() async {
    try {
      final r = await _dio.get('$_apiPath/subscribe/');
      return r.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<List<Map<String, dynamic>>> getSites() async {
    try {
      final response = await _dio.get('$_apiPath/site/');
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchResourcesBySite(int siteId, String keyword) async {
    try {
      final response = await _dio.get('$_apiPath/site/resource/$siteId', queryParameters: {
        'keyword': keyword,
      });
      return (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchMediaByTMDBId(int tmdbId, {String? type}) async {
    try {
      final response = await _dio.get('$_apiPath/search/media/$tmdbId', queryParameters: {
        if (type != null) 'type': type,
      });
      return (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchMediaByTitle(String title, {String? type}) async {
    try {
      final response = await _dio.get('$_apiPath/media/search', queryParameters: {
        'keyword': title,
        if (type != null) 'type': type,
      });
      return (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    try {
      final response = await _dio.get('$_apiPath/subscribe/');
      final data = response.data;
      if (data is Map && data.containsKey('data')) {
        return (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }
      return (data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchSubscriptions(String keyword) async {
    try {
      final response = await _dio.get('$_apiPath/subscribe/search', queryParameters: {
        'keyword': keyword,
      });
      return (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSubscriptionByMediaId(int tmdbId) async {
    try {
      final response = await _dio.get('$_apiPath/subscribe/media/tmdb:$tmdbId');
      final data = response.data as Map<String, dynamic>?;
      
      AppLog.d('MoviePilot', 'getSubscriptionByMediaId($tmdbId): status=${response.statusCode}, data=$data');
      
      if (data == null) return null;
      
      if (data['id'] != null) return data;
      
      if (data['data'] is Map && data['data']['id'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      
      if (data['code'] != null && data['code'] != 0) {
        return null;
      }
      
      return null;
    } catch (e) {
      AppLog.e('MoviePilot', 'getSubscriptionByMediaId($tmdbId) error', e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSubscriptionDetail(String subscribeId) async {
    try {
      final response = await _dio.get('$_apiPath/subscribe/$subscribeId');
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createSubscribe({
    required String title,
    required int tmdbId,
    required String type,
    int? season,
    String? year,
    String? poster,
    String? backdrop,
    String? description,
    int? vote,
    String? date,
    String? quality,
    String? resolution,
    String? effect,
    String? filter,
    String? include,
    String? exclude,
    List<int>? sites,
    int? bestVersion,
    String? savePath,
    int? searchImdbid,
    String? keyword,
    String? doubanId,
    int? bangumiId,
  }) async {
    try {
      // 只发送 MoviePilot Subscribe 模型中定义的字段
      // 参考: https://github.com/jxxghp/MoviePilot/blob/main/app/schemas/subscribe.py
      final data = <String, dynamic>{
        'name': title,
        'tmdbid': tmdbId,
        'type': type,
        if (year != null) 'year': year.toString(),
        if (season != null) 'season': season,
        if (poster != null) 'poster': poster,
        if (backdrop != null) 'backdrop': backdrop,
        if (description != null) 'description': description,
        if (vote != null) 'vote': vote,
        if (date != null) 'date': date,
        if (quality != null) 'quality': quality,
        if (resolution != null) 'resolution': resolution,
        if (effect != null) 'effect': effect,
        if (filter != null) 'filter': filter,
        if (include != null) 'include': include,
        if (exclude != null) 'exclude': exclude,
        if (sites != null && sites.isNotEmpty) 'sites': sites,
        if (bestVersion != null) 'best_version': bestVersion,
        if (savePath != null) 'save_path': savePath,
        if (searchImdbid != null) 'search_imdbid': searchImdbid,
        if (keyword != null) 'keyword': keyword,
        if (doubanId != null) 'doubanid': doubanId,
        if (bangumiId != null) 'bangumiid': bangumiId,
      };

      AppLog.i('MoviePilot', 'createSubscribe request: $data');
      
      final response = await _dio.post('$_apiPath/subscribe/', data: data);
      
      AppLog.i('MoviePilot', 'createSubscribe response: status=${response.statusCode}, data=${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data as Map<String, dynamic>?;
        if (result != null) {
          // 兼容两种响应格式：直接 {id:...} 或包装 {code:0, data:{id:...}}
          if (result['data'] is Map && result['data']['id'] != null) {
            lastError = null;
            return result['data'] as Map<String, dynamic>;
          }
          if (result['id'] != null) {
            lastError = null;
            return result;
          }
          // MoviePilot 返回 success=false 的情况
          if (result['success'] == false) {
            lastError = result['message']?.toString() ?? '订阅失败';
            AppLog.w('MoviePilot', 'createSubscribe 业务失败: $lastError');
            return null;
          }
          // 兼容 code 格式
          if (result['code'] != null && result['code'] != 0) {
            lastError = result['message']?.toString() ?? result['msg']?.toString() ?? '订阅失败';
            AppLog.w('MoviePilot', 'createSubscribe 业务失败(code=${result['code']}): $lastError');
            return null;
          }
        }
        return null;
      }
      return null;
    } on DioException catch (e) {
      // 捕获 HTTP 错误，提取 MoviePilot 返回的具体错误信息
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      AppLog.e('MoviePilot', 'createSubscribe HTTP错误($statusCode): responseData=$responseData', e);
      if (responseData is Map) {
        lastError = responseData['message'] ?? responseData['detail'] ?? responseData['msg'] ?? 'HTTP $statusCode 服务器错误';
        lastError = lastError?.toString() ?? 'HTTP $statusCode 服务器错误';
      } else if (responseData != null) {
        lastError = responseData.toString();
      } else {
        lastError = 'HTTP $statusCode 服务器错误';
      }
      AppLog.e('MoviePilot', 'createSubscribe 错误信息: $lastError');
      return null;
    } catch (e) {
      lastError = e.toString();
      AppLog.e('MoviePilot', 'createSubscribe error', e);
      return null;
    }
  }

  Future<bool> deleteSubscribe(String subscribeId) async {
    try {
      final response = await _dio.delete('$_apiPath/subscribe/$subscribeId');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSubscribeByMediaId(int tmdbId) async {
    try {
      final response = await _dio.delete('$_apiPath/subscribe/media/tmdb:$tmdbId');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateSubscribeStatus(String subscribeId, String status) async {
    try {
      final response = await _dio.put('$_apiPath/subscribe/status/$subscribeId', data: {
        'state': status,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> refreshSubscribe(String subscribeId) async {
    try {
      final response = await _dio.get('$_apiPath/subscribe/reset/$subscribeId');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> refreshAllSubscribes() async {
    try {
      final response = await _dio.get('$_apiPath/subscribe/refresh');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkSubscribes() async {
    try {
      final response = await _dio.get('$_apiPath/subscribe/check');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSubscribeHistory(String type) async {
    try {
      final response = await _dio.get('$_apiPath/subscribe/history/$type');
      return (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPopularSubscribes() async {
    try {
      final response = await _dio.get('$_apiPath/subscribe/popular');
      return (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> recognizeMedia(String name) async {
    try {
      final response = await _dio.get('$_apiPath/media/recognize', queryParameters: {
        'name': name,
      });
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> recognizeMediaFile(String path) async {
    try {
      final response = await _dio.get('$_apiPath/media/recognize_file', queryParameters: {
        'path': path,
      });
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMediaDetail(int mediaId) async {
    try {
      final response = await _dio.get('$_apiPath/media/$mediaId');
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSystemStatus() async {
    try {
      final response = await _dio.get('$_apiPath/system/global');
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    try {
      final response = await _dio.get('$_apiPath/download/');
      return (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> addDownload({
    required String url,
    required int tmdbId,
    String? type,
    String? title,
    int? season,
    int? episode,
    String? quality,
  }) async {
    try {
      final data = <String, dynamic>{
        'url': url,
        'tmdbid': tmdbId,
        if (type != null) 'type': type,
        if (title != null) 'title': title,
        if (season != null) 'season': season,
        if (episode != null) 'episode': episode,
        if (quality != null) 'quality': quality,
      };
      final response = await _dio.post('$_apiPath/download/', data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteDownload(String hashString) async {
    try {
      final response = await _dio.delete('$_apiPath/download/$hashString');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startDownload(String hashString) async {
    try {
      final response = await _dio.get('$_apiPath/download/start/$hashString');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopDownload(String hashString) async {
    try {
      final response = await _dio.get('$_apiPath/download/stop/$hashString');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getDashboardStatistics() async {
    try {
      final response = await _dio.get('$_apiPath/dashboard/statistic');
      return (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDashboardStorage() async {
    try {
      final response = await _dio.get('$_apiPath/dashboard/storage');
      return (response.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<Subscription?> subscribeFromTMDB(TMDBMovie movie, {MediaType mediaType = MediaType.movie}) async {
    final existing = await getSubscriptionByMediaId(movie.id);
    if (existing != null) {
      return Subscription(
        id: existing['id']?.toString() ?? movie.id.toString(),
        title: existing['name']?.toString() ?? movie.title,
        tmdbId: movie.id,
        type: mediaType,
        status: SubscriptionStatus.values.firstWhere(
          (v) => v.toString().split('.').last == (existing['state']?.toString().toLowerCase() ?? 'pending'),
          orElse: () => SubscriptionStatus.pending,
        ),
        moviePilotId: existing['id']?.toString(),
        createdAt: existing['created_at'] != null ? DateTime.tryParse(existing['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
        updatedAt: existing['updated_at'] != null ? DateTime.tryParse(existing['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      );
    }

    final result = await createSubscribe(
      title: movie.title,
      tmdbId: movie.id,
      type: mediaType == MediaType.movie ? '电影' : '电视剧',
      poster: movie.posterPath != null ? 'https://image.tmdb.org/t/p/w500${movie.posterPath}' : null,
      description: movie.overview,
      vote: movie.voteAverage != null ? movie.voteAverage!.round() : null,
      date: movie.releaseDate,
      year: movie.releaseDate?.split('-').first,
    );

    if (result != null) {
      return Subscription(
        id: result['id']?.toString() ?? movie.id.toString(),
        title: movie.title,
        tmdbId: movie.id,
        type: mediaType,
        status: SubscriptionStatus.pending,
        moviePilotId: result['id']?.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return null;
  }

  Future<bool> subscribeByTMDBId({
    required String title,
    required int tmdbId,
    required String type,
    int? season,
    String? quality,
    String? poster,
  }) async {
    final existing = await getSubscriptionByMediaId(tmdbId);
    if (existing != null) return true;

    final result = await createSubscribe(
      title: title,
      tmdbId: tmdbId,
      type: type,
      season: season,
      quality: quality,
      poster: poster,
    );

    return result != null;
  }
}

