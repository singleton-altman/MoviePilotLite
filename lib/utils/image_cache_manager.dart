import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_file_service_factory_stub.dart'
    if (dart.library.io) 'package:moviepilot_mobile/utils/image_file_service_factory_io.dart'
    if (dart.library.js_interop) 'package:moviepilot_mobile/utils/image_file_service_factory_web.dart';

/// 全局图片缓存管理器（缓存 7 天）
class AppImageCacheManager {
  AppImageCacheManager._();

  static const int decodedImageMaximumSize = 80;
  static const int decodedImageMaximumSizeBytes = 48 * 1024 * 1024;

  static final CacheManager instance = _NonEmptyCacheManager();

  static void configureGlobalDecodedCache() {
    final cache = PaintingBinding.instance.imageCache;
    if (cache.maximumSize > decodedImageMaximumSize) {
      cache.maximumSize = decodedImageMaximumSize;
    }
    if (cache.maximumSizeBytes > decodedImageMaximumSizeBytes) {
      cache.maximumSizeBytes = decodedImageMaximumSizeBytes;
    }
  }
}

class _NonEmptyCacheManager extends CacheManager {
  _NonEmptyCacheManager()
    : super(
        Config(
          'appImageCache',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 300,
          fileService: _RejectEmptyFileService(createAppImageFileService()),
        ),
      );

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    final info = await super.getFileFromCache(
      key,
      ignoreMemCache: ignoreMemCache,
    );
    if (info == null) return null;
    try {
      final file = info.file;
      if (!await file.exists() || await file.length() == 0) {
        await removeFile(key);
        return null;
      }
    } catch (_) {
      await removeFile(key);
      return null;
    }
    return info;
  }
}

class _RejectEmptyFileService extends FileService {
  _RejectEmptyFileService(this._inner) {
    concurrentFetches = _inner.concurrentFetches;
  }

  final FileService _inner;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await _inner.get(url, headers: headers);
    if (response.contentLength == 0) {
      throw Exception('Empty image response');
    }
    return _RejectEmptyFileServiceResponse(response);
  }
}

class _RejectEmptyFileServiceResponse implements FileServiceResponse {
  _RejectEmptyFileServiceResponse(this._inner);

  final FileServiceResponse _inner;

  @override
  Stream<List<int>> get content async* {
    var hasBytes = false;
    await for (final chunk in _inner.content) {
      if (chunk.isEmpty) continue;
      hasBytes = true;
      yield chunk;
    }
    if (!hasBytes) {
      throw Exception('Empty image response');
    }
  }

  @override
  int? get contentLength => _inner.contentLength;

  @override
  int get statusCode => _inner.statusCode;

  @override
  DateTime get validTill => _inner.validTill;

  @override
  String? get eTag => _inner.eTag;

  @override
  String get fileExtension => _inner.fileExtension;
}
