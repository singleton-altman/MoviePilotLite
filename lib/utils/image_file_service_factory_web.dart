import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/browser_client.dart';

FileService createAppImageFileService() {
  final client = BrowserClient()..withCredentials = false;
  return HttpFileService(httpClient: client);
}
