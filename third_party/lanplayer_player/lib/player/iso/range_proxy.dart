import 'dart:async';
import 'dart:io';


/// 本地 Range 代理:把对「虚拟 m2ts」的 HTTP 请求翻译成对远端 ISO
/// 静态流的区间读,让播放内核把原盘正片当普通 m2ts 网络流播放。
///
/// - 内核发 Range: bytes=a-b → 翻译为远端 Range: bytes=isoOffset+a-isoOffset+b
/// - 不带 Range → 从虚拟文件头开始开放读取(206/200 语义照常)
/// - 代理是流式转发,不落盘;生命周期由调用方管理(stop)
class RangeProxy {
  RangeProxy({
    required this.remoteUrl,
    required this.headers,
    required this.isoOffset,
    this.m2tsSize = 0,
  });

  final String remoteUrl;
  final Map<String, String> headers;

  /// m2ts 在 ISO 内的起始字节偏移
  final int isoOffset;

  /// m2ts 字节数;0 = 到卷尾(由远端 Content-Range 定界)
  final int m2tsSize;

  HttpServer? _server;
  HttpClient? _client;
  int _port = 0;

  String get baseUrl => 'http://127.0.0.1:$_port/stream.m2ts';
  bool get isRunning => _server != null;

  Future<String> start() async {
    if (_server != null) return baseUrl;
    _client = HttpClient();
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    _server!.listen(
      (req) => _handle(req).catchError((_) {
        try {
          req.response.close();
        } catch (_) {}
      }),
      onError: (_) {},
    );
    return baseUrl;
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    await s?.close(force: true);
    _client?.close(force: true);
    _client = null;
  }

  Future<void> _handle(HttpRequest req) async {
    final range = req.headers.value(HttpHeaders.rangeHeader);
    var start = 0;
    int? endIncl; // 闭区间末尾(虚拟坐标系)

    if (range != null && range.startsWith('bytes=')) {
      final spec = range.substring(6).split(',').first;
      final dash = spec.indexOf('-');
      if (dash < 0) {
        req.response.statusCode = 400;
        await req.response.close();
        return;
      }
      final a = spec.substring(0, dash).trim();
      final b = spec.substring(dash + 1).trim();
      if (a.isEmpty) {
        // 后缀形式 bytes=-n:最后 n 字节
        final n = int.tryParse(b) ?? 0;
        if (m2tsSize <= 0) {
          req.response.statusCode = 416;
          await req.response.close();
          return;
        }
        start = (m2tsSize - n).clamp(0, m2tsSize);
      } else {
        start = int.tryParse(a) ?? 0;
        if (b.isNotEmpty) endIncl = int.tryParse(b);
      }
    }

    // 边界裁剪(虚拟长度已知时)
    if (m2tsSize > 0) {
      if (start >= m2tsSize) {
        req.response.statusCode = 416;
        req.response.headers.set(
            HttpHeaders.contentRangeHeader, 'bytes */$m2tsSize');
        await req.response.close();
        return;
      }
      if (endIncl != null && endIncl >= m2tsSize) endIncl = m2tsSize - 1;
    }

    // 翻译为远端区间
    final realStart = isoOffset + start;
    final realEndIncl = endIncl == null ? null : isoOffset + endIncl;
    final realRange = realEndIncl == null
        ? 'bytes=$realStart-'
        : 'bytes=$realStart-$realEndIncl';

    final client = _client ??= HttpClient();
    try {
      final creq = await client
          .getUrl(Uri.parse(remoteUrl))
          .timeout(const Duration(seconds: 20));
      creq.headers.set(HttpHeaders.rangeHeader, realRange);
      headers.forEach((k, v) => creq.headers.set(k, v));
      final cres = await creq.close().timeout(const Duration(seconds: 20));

      final resp = req.response;
      resp.statusCode = 200;
      resp.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      resp.headers.contentType = ContentType.binary;

      if (m2tsSize > 0) {
        final len = endIncl == null ? m2tsSize - start : endIncl - start + 1;
        resp.statusCode = endIncl == null ? 200 : 206;
        resp.headers.set(HttpHeaders.contentLengthHeader, len.toString());
        if (endIncl != null) {
          resp.headers.set(HttpHeaders.contentRangeHeader,
              'bytes $start-$endIncl/$m2tsSize');
        }
      }
      await resp.flush();
      await cres.pipe(resp);
    } catch (_) {
      try {
        await req.response.close();
      } catch (_) {}
    } finally {
      client.close(force: true);
    }
  }
}
