import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/utils/image_request_headers.dart';

void main() {
  group('图片请求头 Cookie 作用域', () {
    test('同源（MoviePilot 服务端）才附带 Cookie', () {
      final headers = buildImageRequestHeaders(
        'https://mp.example.com/api/v1/system/cache/image?url=https%3A%2F%2Fimage.tmdb.org%2Ft%2Fp%2Fw500%2Fa.jpg',
        cookie: 'token=abc',
        serverBaseUrl: 'https://mp.example.com',
      );
      expect(headers['cookie'], 'token=abc');
    });

    test('第三方域名（TMDB 直链）不附带 Cookie', () {
      final headers = buildImageRequestHeaders(
        'https://image.tmdb.org/t/p/w500/a.jpg',
        cookie: 'token=abc',
        serverBaseUrl: 'https://mp.example.com',
      );
      expect(headers, isEmpty);
    });

    test('豆瓣图片直链不附带 Cookie', () {
      final headers = buildImageRequestHeaders(
        'https://img9.doubanio.com/view/photo/s_ratio_poster/public/x.jpg',
        cookie: 'token=abc',
        serverBaseUrl: 'https://mp.example.com',
      );
      expect(headers, isEmpty);
    });

    test('端口不同但域名相同视为同源（代理/web 端口差异）', () {
      final headers = buildImageRequestHeaders(
        'http://192.168.1.10:3000/api/v1/system/img/0?imgurl=x',
        cookie: 'token=abc',
        serverBaseUrl: 'https://192.168.1.10:8443',
      );
      expect(headers['cookie'], 'token=abc');
    });

    test('Cookie 为空时不产生请求头', () {
      final headers = buildImageRequestHeaders(
        'https://mp.example.com/api/v1/system/cache/image?url=x',
        cookie: '',
        serverBaseUrl: 'https://mp.example.com',
      );
      expect(headers, isEmpty);
    });

    test('未配置服务端地址时不发送 Cookie', () {
      final headers = buildImageRequestHeaders(
        'https://mp.example.com/api/v1/system/cache/image?url=x',
        cookie: 'token=abc',
        serverBaseUrl: '',
      );
      expect(headers, isEmpty);
    });
  });

  group('isSameOriginAsServer', () {
    test('空地址返回 false', () {
      expect(isSameOriginAsServer('', serverBaseUrl: 'https://a.com'), isFalse);
    });

    test('非法地址返回 false', () {
      expect(isSameOriginAsServer('http://', serverBaseUrl: 'https://a.com'),
          isFalse);
    });
  });
}
