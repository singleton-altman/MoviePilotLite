import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';

void main() {
  group('ImageUtil.convertCacheImageUrl 已是 MoviePilot 代理地址时幂等', () {
    test('空地址原样返回', () {
      expect(ImageUtil.convertCacheImageUrl(''), '');
    });

    test('缓存代理地址不再二次包裹', () {
      const proxied =
          'https://mp.example.com/api/v1/system/cache/image?url=https%3A%2F%2Fimage.tmdb.org%2Ft%2Fp%2Fw200%2Fabc.jpg';
      expect(ImageUtil.convertCacheImageUrl(proxied), proxied);
    });

    test('媒体服务器图片代理地址（system/img/0）不再二次包裹', () {
      const proxied =
          'https://mp.example.com/api/v1/system/img/0?imgurl=http%3A%2F%2F192.168.31.173%3A8096%2FItems%2F6100%2FImages%2FPrimary%23mp_sig%3Dabc%26mp_purpose%3Dresource&use_cookies=true';
      expect(ImageUtil.convertCacheImageUrl(proxied), proxied);
    });

    test('插件图标代理地址（system/img/1）不再二次包裹', () {
      const proxied =
          'https://mp.example.com/api/v1/system/img/1?imgurl=https%3A%2F%2Fexample.com%2Ficon.png';
      expect(ImageUtil.convertCacheImageUrl(proxied), proxied);
    });
  });

  group('isOverseasMusicImageUrl 音乐图片域名识别', () {
    test('coverartarchive 与 archive.org 命中', () {
      expect(
        isOverseasMusicImageUrl(
          'https://coverartarchive.org/release-group/abc/front-500',
        ),
        isTrue,
      );
      expect(
        isOverseasMusicImageUrl(
          'https://archive.org/download/mbid-abc/cover.jpg',
        ),
        isTrue,
      );
    });

    test('TheAudioDB 与 wikimedia 命中', () {
      expect(
        isOverseasMusicImageUrl(
          'https://www.theaudiodb.com/images/media/album/xx.png',
        ),
        isTrue,
      );
      expect(
        isOverseasMusicImageUrl(
          'https://commons.wikimedia.org/wiki/Special:FilePath/A.jpg?width=500',
        ),
        isTrue,
      );
    });

    test('豆瓣与 TMDB 不命中', () {
      expect(
        isOverseasMusicImageUrl('https://img1.doubanio.com/view/album/l/p.jpg'),
        isFalse,
      );
      expect(
        isOverseasMusicImageUrl('https://image.tmdb.org/t/p/w200/abc.jpg'),
        isFalse,
      );
      expect(isOverseasMusicImageUrl(''), isFalse);
    });
  });
}
