import '../models/media_models.dart';
import '../utils/app_log.dart';
import 'storage_service.dart';
import 'http_client.dart';

class TMDBService {
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p';
  static const _headers = {'Accept': 'application/json; charset=utf-8'};
  static const _timeout = Duration(seconds: 10);

  String? _apiKey;
  bool _initialized = false;

  TMDBService() {
    _init();
  }

  Future<void> _init() async {
    final apiKey = await StorageService.getSecure(StorageService.tmdbApiKey);
    if (apiKey != null && apiKey.isNotEmpty) {
      _apiKey = apiKey;
    }
    _initialized = true;
  }

  Future<void> reloadApiKey() async {
    final apiKey = await StorageService.getSecure(StorageService.tmdbApiKey);
    _apiKey = apiKey;
  }

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  String getImageUrl(String path, {String size = 'w500'}) {
    return '$imageBaseUrl/$size$path';
  }

  Map<String, String> get _baseParams => {
    if (_apiKey != null) 'api_key': _apiKey!,
    'language': 'zh-CN',
  };

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _init();
    }
  }

  /// 统一 GET 请求（rhttp 优先，Dio 回退）
  Future<dynamic> _get(String path, {Map<String, String>? extraParams}) async {
    final query = {..._baseParams, if (extraParams != null) ...extraParams};
    return HttpClient.getJson(
      '$baseUrl$path',
      headers: _headers,
      query: query,
      timeout: _timeout,
    );
  }

  Future<List<TMDBMovie>> getTrending({String timeWindow = 'week'}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/trending/movie/$timeWindow');
      final results = data['results'] as List;
      return results.map((json) => TMDBMovie.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TMDBMovie>> getPopular({int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/movie/popular', extraParams: {'page': '$page'});
      final results = data['results'] as List;
      return results.map((json) => TMDBMovie.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TMDBMovie>> getTopRated({int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/movie/top_rated', extraParams: {'page': '$page'});
      final results = data['results'] as List;
      return results.map((json) => TMDBMovie.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TMDBMovie>> getUpcoming({int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/movie/upcoming', extraParams: {'page': '$page'});
      final results = data['results'] as List;
      return results.map((json) => TMDBMovie.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TMDBMovie>> getNowPlaying({int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/movie/now_playing', extraParams: {'page': '$page'});
      final results = data['results'] as List;
      return results.map((json) => TMDBMovie.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TMDBMovie>> searchMovies(String query, {int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/search/movie', extraParams: {'query': query, 'page': '$page'});
      final results = data['results'] as List;
      return results.map((json) => TMDBMovie.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMovieDetails(int movieId) async {
    await _ensureInitialized();
    if (!hasApiKey) return null;
    try {
      return await _get('/movie/$movieId', extraParams: {'append_to_response': 'credits,videos,similar'});
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getMovieCredits(int movieId) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/movie/$movieId/credits');
      if (data is Map && data.containsKey('status_code')) {
        AppLog.w('TMDB', 'getMovieCredits error: ${data['status_message']} (code=${data['status_code']})');
        return [];
      }
      return data['cast'] as List? ?? [];
    } catch (e) {
      AppLog.w('TMDB', 'getMovieCredits exception: $e');
      return [];
    }
  }

  Future<List<TMDBMovie>> getSimilarMovies(int movieId) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/movie/$movieId/similar');
      final results = data['results'] as List;
      return results.map((json) => TMDBMovie.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getTrendingTV({String timeWindow = 'week'}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/trending/tv/$timeWindow');
      return data['results'] as List;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getPopularTV({int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/tv/popular', extraParams: {'page': '$page'});
      return data['results'] as List;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getTopRatedTV({int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/tv/top_rated', extraParams: {'page': '$page'});
      return data['results'] as List;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getOnTheAirTV({int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/tv/on_the_air', extraParams: {'page': '$page'});
      return data['results'] as List;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getAiringTodayTV({int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/tv/airing_today', extraParams: {'page': '$page'});
      return data['results'] as List;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> searchTV(String query, {int page = 1}) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/search/tv', extraParams: {'query': query, 'page': '$page'});
      return data['results'] as List;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTVDetails(int tvId) async {
    await _ensureInitialized();
    if (!hasApiKey) return null;
    try {
      return await _get('/tv/$tvId', extraParams: {'append_to_response': 'credits,videos,similar,external_ids'});
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getTVCredits(int tvId) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/tv/$tvId/credits');
      if (data is Map && data.containsKey('status_code')) {
        AppLog.w('TMDB', 'getTVCredits error: ${data['status_message']} (code=${data['status_code']})');
        return [];
      }
      return data['cast'] as List? ?? [];
    } catch (e) {
      AppLog.w('TMDB', 'getTVCredits exception: $e');
      return [];
    }
  }

  Future<List<dynamic>> getSimilarTV(int tvId) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/tv/$tvId/similar');
      return data['results'] as List;
    } catch (_) {
      return [];
    }
  }

  Future<List<dynamic>> getTVSeasons(int tvId) async {
    await _ensureInitialized();
    if (!hasApiKey) return [];
    try {
      final data = await _get('/tv/$tvId/season/1/episodes');
      return data['episodes'] as List;
    } catch (_) {
      return [];
    }
  }
}
