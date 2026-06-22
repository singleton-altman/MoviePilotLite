import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

bool _apiBaseSameOriginAsApp(String apiBase) {
  final t = apiBase.trim();
  if (t.isEmpty) return false;
  try {
    final api = Uri.parse(t);
    final app = Uri.base;
    if (api.scheme != 'http' && api.scheme != 'https') return false;
    if (app.scheme != 'http' && app.scheme != 'https') return false;
    return api.origin == app.origin;
  } catch (_) {
    return false;
  }
}

void configureDioHttpClientAdapter(Dio dio) {
  final cred = _apiBaseSameOriginAsApp(dio.options.baseUrl);
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: cred);
}
