import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_comment_models.dart';

void main() {
  group('DoubanCommentPage', () {
    test('parses comment page with author and numeric strings', () {
      final page = DoubanCommentPage.fromJson({
        'start': 0,
        'count': 2,
        'total': 42,
        'items': [
          {
            'id': 'c1',
            'comment': ' 很好看的电影 ',
            'rating': '4',
            'vote_count': '128',
            'create_time': '2026-01-01',
            'author': {
              'id': 'u1',
              'name': '影迷甲',
              'avatar': 'https://img.example.com/a.jpg',
              'url': 'https://www.douban.com/people/u1/',
            },
            'url': 'https://movie.douban.com/review/1/',
          },
          {'comment': '一般般', 'rating': 2.5},
        ],
      });

      expect(page.start, 0);
      expect(page.count, 2);
      expect(page.total, 42);
      expect(page.items, hasLength(2));

      final first = page.items.first;
      expect(first.id, 'c1');
      expect(first.comment, '很好看的电影');
      expect(first.rating, 4.0);
      expect(first.voteCount, 128);
      expect(first.createTime, '2026-01-01');
      expect(first.author?.name, '影迷甲');
      expect(first.author?.avatar, 'https://img.example.com/a.jpg');
      expect(first.url, 'https://movie.douban.com/review/1/');

      expect(page.items.last.author, isNull);
      expect(page.items.last.rating, 2.5);
    });

    test('unwraps v3 success envelope and tolerates missing meta', () {
      final page = DoubanCommentPage.fromJson({
        'success': true,
        'data': {
          'items': [
            {'comment': '只有一条'},
          ],
        },
      });

      expect(page.start, 0);
      expect(page.count, 1);
      expect(page.total, 1);
      expect(page.items.single.comment, '只有一条');
    });

    test('returns empty page for unknown payload', () {
      final page = DoubanCommentPage.fromJson(const {});

      expect(page.items, isEmpty);
      expect(page.total, 0);
    });
  });

  group('DoubanReviewPage', () {
    test('parses review page with review fields', () {
      final page = DoubanReviewPage.fromJson({
        'start': 20,
        'count': 1,
        'total': 35,
        'items': [
          {
            'id': 'r1',
            'title': '一场漫长的告别',
            'abstract': '影片用极简的镜头语言讲述了...',
            'rating': '5.0',
            'useful_count': '99',
            'comments_count': 12,
            'create_time': '2026-02-02 10:00:00',
            'author': {'name': '影评人乙'},
            'url': 'https://movie.douban.com/review/2/',
          },
        ],
      });

      expect(page.start, 20);
      expect(page.count, 1);
      expect(page.total, 35);

      final review = page.items.single;
      expect(review.id, 'r1');
      expect(review.title, '一场漫长的告别');
      expect(review.abstract, '影片用极简的镜头语言讲述了...');
      expect(review.rating, 5.0);
      expect(review.usefulCount, 99);
      expect(review.commentsCount, 12);
      expect(review.createTime, '2026-02-02 10:00:00');
      expect(review.author?.name, '影评人乙');
      expect(review.url, 'https://movie.douban.com/review/2/');
    });
  });
}
