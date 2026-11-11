import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/media_detail/utils/douban_id_resolver.dart';

void main() {
  const doubanMovie = {
    'title': '沙丘',
    'year': '2021',
    'type': '电影',
    'media_source': 'douban',
    'media_id': '3001114',
    'douban_id': '3001114',
  };

  group('pickDoubanIdFromSearchResults', () {
    test('uses direct douban_id and ignores non-douban source id', () {
      final id = pickDoubanIdFromSearchResults(
        items: [
          {
            'title': '沙丘',
            'year': '2021',
            'type': '电影',
            'media_source': 'themoviedb',
            'media_id': '438631',
            'douban_id': '3001114',
          },
        ],
        title: '沙丘',
        year: '2021',
        typeName: '电影',
      );

      expect(id, '3001114');
    });

    test('falls back to media_id for douban source', () {
      final id = pickDoubanIdFromSearchResults(
        items: [
          {
            'title': '沙丘',
            'year': '2021',
            'type': 'movie',
            'media_source': 'douban',
            'media_id': '3001114',
          },
        ],
        title: '沙丘',
        year: '2021',
        typeName: '电影',
      );

      expect(id, '3001114');
    });

    test('rejects title match with different year', () {
      final id = pickDoubanIdFromSearchResults(
        items: [
          {
            'title': '沙丘',
            'year': '1984',
            'type': '电影',
            'media_source': 'douban',
            'media_id': '1293155',
          },
        ],
        title: '沙丘',
        year: '2021',
        typeName: '电影',
      );

      expect(id, isNull);
    });

    test('accepts exact title and year from title_year or release_date', () {
      final id = pickDoubanIdFromSearchResults(
        items: [
          {
            'title': 'Dune',
            'title_year': '沙丘(2021)',
            'release_date': '2021-09-15',
            'type': 'movie',
            'media_source': 'douban',
            'media_id': '3001114',
          },
        ],
        title: 'Dune',
        year: '2021',
      );

      expect(id, '3001114');
    });

    test('matches aliases and names when year is unknown', () {
      final id = pickDoubanIdFromSearchResults(
        items: [
          {
            'title': '沙丘',
            'original_title': 'Dune',
            'names': ['沙丘：第一部'],
            'type': '电影',
            'media_source': 'douban',
            'media_id': '3001114',
          },
        ],
        title: 'Dune',
      );

      expect(id, '3001114');
    });

    test('filters by media type', () {
      final id = pickDoubanIdFromSearchResults(
        items: [
          {
            'title': '沙丘',
            'year': '2021',
            'type': '电视剧',
            'media_source': 'douban',
            'media_id': '999',
          },
          doubanMovie,
        ],
        title: '沙丘',
        year: '2021',
        typeName: '电影',
      );

      expect(id, '3001114');
    });
  });
}
