/// 豆瓣短评 / 影评的接口模型。
///
/// 对应服务端 `app/schemas/comment.py`：
/// - GET /api/v1/douban/interests/{doubanid}/{type_name}
/// - GET /api/v1/douban/reviews/{doubanid}/{type_name}
class DoubanCommentAuthor {
  const DoubanCommentAuthor({this.id, this.name, this.avatar, this.url});

  final String? id;
  final String? name;
  final String? avatar;
  final String? url;

  factory DoubanCommentAuthor.fromJson(Map<String, dynamic> json) {
    return DoubanCommentAuthor(
      id: _asString(json['id']),
      name: _asString(json['name']),
      avatar: _asString(json['avatar']),
      url: _asString(json['url']),
    );
  }
}

class DoubanComment {
  const DoubanComment({
    this.id,
    this.comment,
    this.rating,
    this.voteCount,
    this.createTime,
    this.author,
    this.url,
  });

  final String? id;
  final String? comment;
  final double? rating;
  final int? voteCount;
  final String? createTime;
  final DoubanCommentAuthor? author;
  final String? url;

  factory DoubanComment.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    return DoubanComment(
      id: _asString(json['id']),
      comment: _asString(json['comment']),
      rating: _asDouble(json['rating']),
      voteCount: _asInt(json['vote_count']),
      createTime: _asString(json['create_time']),
      author: author is Map
          ? DoubanCommentAuthor.fromJson(Map<String, dynamic>.from(author))
          : null,
      url: _asString(json['url']),
    );
  }
}

class DoubanReview {
  const DoubanReview({
    this.id,
    this.title,
    this.abstract,
    this.rating,
    this.usefulCount,
    this.commentsCount,
    this.createTime,
    this.author,
    this.url,
  });

  final String? id;
  final String? title;
  final String? abstract;
  final double? rating;
  final int? usefulCount;
  final int? commentsCount;
  final String? createTime;
  final DoubanCommentAuthor? author;
  final String? url;

  factory DoubanReview.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    return DoubanReview(
      id: _asString(json['id']),
      title: _asString(json['title']),
      abstract: _asString(json['abstract']),
      rating: _asDouble(json['rating']),
      usefulCount: _asInt(json['useful_count']),
      commentsCount: _asInt(json['comments_count']),
      createTime: _asString(json['create_time']),
      author: author is Map
          ? DoubanCommentAuthor.fromJson(Map<String, dynamic>.from(author))
          : null,
      url: _asString(json['url']),
    );
  }
}

class DoubanCommentPage {
  const DoubanCommentPage({
    this.start = 0,
    this.count = 0,
    this.total = 0,
    this.items = const [],
  });

  final int start;
  final int count;
  final int total;
  final List<DoubanComment> items;

  factory DoubanCommentPage.fromJson(Map<String, dynamic> json) {
    final page = _unwrapPage(json);
    final items = _asList(page['items'] ?? page['comments'] ?? page['data']);
    return DoubanCommentPage(
      start: _asInt(page['start']) ?? 0,
      count: _asInt(page['count']) ?? items.length,
      total: _asInt(page['total']) ?? items.length,
      items: items
          .whereType<Map>()
          .map(
            (item) => DoubanComment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class DoubanReviewPage {
  const DoubanReviewPage({
    this.start = 0,
    this.count = 0,
    this.total = 0,
    this.items = const [],
  });

  final int start;
  final int count;
  final int total;
  final List<DoubanReview> items;

  factory DoubanReviewPage.fromJson(Map<String, dynamic> json) {
    final page = _unwrapPage(json);
    final items = _asList(page['items'] ?? page['reviews'] ?? page['data']);
    return DoubanReviewPage(
      start: _asInt(page['start']) ?? 0,
      count: _asInt(page['count']) ?? items.length,
      total: _asInt(page['total']) ?? items.length,
      items: items
          .whereType<Map>()
          .map((item) => DoubanReview.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

Map<String, dynamic> _unwrapPage(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map && json['success'] is bool) {
    return Map<String, dynamic>.from(data);
  }
  return json;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
