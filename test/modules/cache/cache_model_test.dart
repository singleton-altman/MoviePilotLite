import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/cache/models/cache_model.dart';

void main() {
  // v3 信封经 unwrapV3EnvelopeOnResponse 拆包后，fetchCache 实际拿到的形态：
  // 顶层 data 是条目列表，success/message 由信封补齐。
  // media_year 服务端为 str | int（MediaInfo.year 是数字），不能按 String 裸 cast。
  test('解析拆包后的 v3 载荷（media_year 为数字与空串）', () {
    final json = <String, dynamic>{
      'count': 2,
      'sites': 1,
      'success': true,
      'message': null,
      'data': [
        {
          'hash': 'abc',
          'domain': 'example.org',
          'title': '标题',
          'description': null,
          'size': 1024,
          'site_name': '站点',
          'media_name': '片名',
          'media_year': 2024,
          'media_type': '电影',
          'season_episode': 'S01E01',
          'resource_term': '1080p',
        },
        {
          'hash': 'def',
          'domain': 'example.org',
          'media_year': '',
        },
      ],
    };

    final res = parseCacheResponse(json);

    expect(res, isNotNull);
    expect(res!.success, isTrue);
    expect(res.data!.count, 2);
    expect(res.data!.sites, 1);
    expect(res.data!.items, hasLength(2));
    expect(res.data!.items![0].mediaYear, '2024');
    expect(res.data!.items![0].size, 1024);
    expect(res.data!.items![1].mediaYear, '');
  });

  // 未拆包（V2 直传信封）时的原始形态，同样要能解析。
  test('解析原始 Response 信封', () {
    final envelope = <String, dynamic>{
      'success': true,
      'message': null,
      'data': {
        'count': 1,
        'sites': 1,
        'data': [
          {
            'hash': 'abc',
            'domain': 'example.org',
            'media_year': 1998,
          },
        ],
      },
    };

    final viaParse = parseCacheResponse(envelope);
    expect(viaParse, isNotNull);
    expect(viaParse!.success, isTrue);
    expect(viaParse.data!.items!.single.mediaYear, '1998');

    final viaFromJson = CacheResponse.fromJson(envelope);
    expect(viaFromJson.success, isTrue);
    expect(viaFromJson.data!.items!.single.mediaYear, '1998');
  });

  test('解析失败信封时保留 success/message', () {
    final res = parseCacheResponse(<String, dynamic>{
      'success': false,
      'message': '获取缓存失败',
      'data': null,
    });

    expect(res, isNotNull);
    expect(res!.success, isFalse);
    expect(res.message, '获取缓存失败');
    expect(res.data, isNull);
  });

  test('纯列表形态与字符串形态', () {
    final items = [
      {'hash': 'abc', 'domain': 'example.org', 'media_year': 2020},
    ];

    final fromList = parseCacheResponse(items);
    expect(fromList, isNotNull);
    expect(fromList!.data!.items!.single.mediaYear, '2020');

    final fromString = parseCacheResponse(jsonEncode(items));
    expect(fromString, isNotNull);
    expect(fromString!.data!.items, hasLength(1));
  });

  test('无法识别的形态返回 null', () {
    expect(parseCacheResponse(null), isNull);
    expect(parseCacheResponse(123), isNull);
    expect(parseCacheResponse(<String, dynamic>{}), isNull);
  });
}
