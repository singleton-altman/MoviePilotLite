import 'package:moviepilot_mobile/modules/media_detail/models/douban_comment_models.dart';

/// 豆瓣影评列表页的路由参数。
///
/// 详情页把已加载的第一页影评和总数传过去，避免重复请求。
class DoubanReviewListArgs {
  const DoubanReviewListArgs({
    required this.doubanId,
    required this.typeName,
    required this.title,
    this.posterPath,
    this.initialItems = const [],
    this.initialTotal = 0,
  });

  final String doubanId;
  final String typeName;
  final String title;
  final String? posterPath;
  final List<DoubanReview> initialItems;
  final int initialTotal;
}
