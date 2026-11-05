import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/models/update_mirror.dart';
import 'package:moviepilot_mobile/utils/remote_host_guard.dart';

/// 单个下载线路的测速结果。
class MirrorSpeedResult {
  const MirrorSpeedResult({
    required this.mirrorId,
    required this.bytes,
    required this.elapsed,
    this.error,
  });

  final String mirrorId;
  final int bytes;
  final Duration elapsed;
  final String? error;

  bool get ok => error == null && bytes > 0;

  /// 字节/秒；无有效样本时为 0。
  double get bytesPerSecond {
    final micros = elapsed.inMicroseconds;
    if (micros <= 0 || bytes <= 0) return 0;
    return bytes * 1000000 / micros;
  }

  String get displaySpeed {
    if (!ok) return '失败';
    final mbps = bytesPerSecond / (1024 * 1024);
    if (mbps >= 1) return '${mbps.toStringAsFixed(1)} MB/s';
    final kbps = bytesPerSecond / 1024;
    return '${kbps.toStringAsFixed(0)} KB/s';
  }
}

/// 自更新下载线路测速。
///
/// 对每条线路发起带 Range 头的流式请求，在固定时间窗口内统计实际收到的字节数，
/// 得到近似吞吐。窗口结束后立即取消请求，不完整下载安装包。
class UpdateSpeedTester extends GetxService {
  static const Duration defaultBudget = Duration(seconds: 5);
  static const int maxBytes = 8 * 1024 * 1024;

  /// 无可用 APK 地址时的测速目标，保证测的是同一条 GitHub 下载链路。
  static const String fallbackProbeUrl =
      'https://github.com/singleton-altman/MoviePilotLite/archive/refs/heads/master.zip';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: true,
      maxRedirects: 5,
      headers: const {
        'user-agent': 'MoviePilotLite-Mobile',
        'accept': 'application/octet-stream',
      },
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  /// 测试单条线路。
  Future<MirrorSpeedResult> test(
    UpdateMirror mirror, {
    required String sourceUrl,
    Duration budget = defaultBudget,
  }) async {
    final target = mirror.resolve(sourceUrl);
    if (!isSafeRemoteUrl(target)) {
      return MirrorSpeedResult(
        mirrorId: mirror.id,
        bytes: 0,
        elapsed: Duration.zero,
        error: '地址不安全或不受支持',
      );
    }

    final cancelToken = CancelToken();
    var received = 0;
    final stopwatch = Stopwatch()..start();
    final completer = Completer<MirrorSpeedResult>();
    Timer? deadline;

    void finish({String? error}) {
      if (completer.isCompleted) return;
      stopwatch.stop();
      if (!cancelToken.isCancelled) cancelToken.cancel('speed_test_done');
      completer.complete(
        MirrorSpeedResult(
          mirrorId: mirror.id,
          bytes: received,
          elapsed: stopwatch.elapsed,
          error: error,
        ),
      );
    }

    deadline = Timer(budget, finish);

    try {
      final response = await _dio.get<ResponseBody>(
        target,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: const {'range': 'bytes=0-8388607'},
        ),
      );
      final body = response.data;
      if (body == null) {
        finish(error: '无响应内容');
      } else {
        await for (final chunk in body.stream) {
          if (completer.isCompleted) break;
          received += chunk.length;
          if (received >= maxBytes) {
            finish();
            break;
          }
        }
        finish();
      }
    } on DioException catch (e) {
      // 到点后主动取消属于正常结束，不记为失败。
      if (!completer.isCompleted) {
        finish(error: CancelToken.isCancel(e) ? null : _describe(e));
      }
    } catch (e) {
      if (!completer.isCompleted) finish(error: _describe(e));
    } finally {
      deadline.cancel();
    }

    return completer.future;
  }

  /// 并发测试多条线路，返回以线路 id 为键的结果表。
  Future<Map<String, MirrorSpeedResult>> testAll(
    List<UpdateMirror> mirrors, {
    required String sourceUrl,
    Duration budget = defaultBudget,
  }) async {
    final results = await Future.wait(
      mirrors.map(
        (mirror) => test(mirror, sourceUrl: sourceUrl, budget: budget),
      ),
    );
    return {for (final result in results) result.mirrorId: result};
  }

  String _describe(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
          return '连接超时';
        case DioExceptionType.connectionError:
          return '无法连接';
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          return status == null ? '响应异常' : 'HTTP $status';
        case DioExceptionType.badCertificate:
          return '证书错误';
        case DioExceptionType.cancel:
          return '已取消';
        case DioExceptionType.unknown:
          if (error.error is SocketException) return '无法连接';
          return '网络错误';
      }
    }
    return '测速失败';
  }
}
