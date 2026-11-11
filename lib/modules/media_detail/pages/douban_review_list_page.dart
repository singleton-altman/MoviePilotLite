import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_comment_models.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_review_list_args.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_service.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';
import 'package:moviepilot_mobile/modules/media_detail/widgets/douban_list_item.dart';

class DoubanReviewListController extends GetxController {
  static const int _pageSize = 20;

  final args = DoubanReviewListArgs(
    doubanId: '',
    typeName: '电影',
    title: '',
  ).obs;
  final reviews = <DoubanReview>[].obs;
  final total = 0.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorText = RxnString();

  String? _requestKey;
  int _nextStart = 0;
  int _generation = 0;
  bool get hasMore => _nextStart < total.value;

  @override
  void onInit() {
    super.onInit();
    final value = _parseArgs(Get.arguments);
    if (value != null) {
      args.value = value;
    }
    unawaited(_loadInitial());
  }

  DoubanReviewListArgs? _parseArgs(Object? raw) {
    if (raw is DoubanReviewListArgs) return raw;
    if (raw is! Map) return null;
    final doubanId = _readString(raw, 'doubanId');
    if (doubanId == null || doubanId.isEmpty) return null;
    final initialItems = raw['initialItems'];
    final typeName = _readString(raw, 'typeName') ?? '电影';
    return DoubanReviewListArgs(
      doubanId: doubanId,
      typeName: typeName,
      title: _readString(raw, 'title') ?? '',
      posterPath: _readString(raw, 'posterPath'),
      initialItems: initialItems is List
          ? initialItems
                .whereType<Map>()
                .map(
                  (item) =>
                      DoubanReview.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      initialTotal: _readInt(raw, 'initialTotal') ?? 0,
    );
  }

  String? _readString(Map<dynamic, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _readInt(Map<dynamic, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _loadInitial() async {
    final current = args.value;
    _requestKey = current.doubanId;
    if (current.initialItems.isNotEmpty || current.initialTotal > 0) {
      reviews.assignAll(current.initialItems);
      _nextStart = current.initialItems.length;
      total.value = current.initialTotal > 0
          ? current.initialTotal
          : current.initialItems.length;
      return;
    }
    await reloadReviews();
  }

  Future<void> reloadReviews() async {
    final current = args.value;
    final generation = ++_generation;
    _requestKey = current.doubanId;
    isLoading.value = true;
    errorText.value = null;
    try {
      final page = await Get.find<MediaDetailService>().getDoubanReviews(
        doubanId: current.doubanId,
        typeName: current.typeName,
        start: 0,
        count: _pageSize,
        throwOnError: true,
      );
      if (_requestKey != current.doubanId || generation != _generation) return;
      reviews.assignAll(page.items);
      _nextStart = page.start + page.items.length;
      total.value = page.total > page.items.length
          ? page.total
          : page.items.length;
    } catch (error) {
      if (_requestKey == current.doubanId && generation == _generation) {
        errorText.value = '加载影评失败，请重试';
        if (reviews.isNotEmpty) ToastUtil.error('加载影评失败，请重试');
      }
    } finally {
      if (_requestKey == current.doubanId && generation == _generation) {
        isLoading.value = false;
      }
    }
  }

  Future<void> loadMore() async {
    final current = args.value;
    if (isLoadingMore.value || isLoading.value || !hasMore) return;
    final generation = _generation;
    final start = _nextStart;
    isLoadingMore.value = true;
    try {
      final page = await Get.find<MediaDetailService>().getDoubanReviews(
        doubanId: current.doubanId,
        typeName: current.typeName,
        start: start,
        count: _pageSize,
        throwOnError: true,
      );
      if (_requestKey != current.doubanId || generation != _generation) return;
      _nextStart =
          (page.start < start ? start : page.start) + page.items.length;
      final knownIds = reviews
          .map((review) => review.id)
          .whereType<String>()
          .toSet();
      reviews.addAll(
        page.items.where(
          (review) => review.id == null || !knownIds.contains(review.id),
        ),
      );
      total.value = page.items.isEmpty
          ? reviews.length
          : (page.total < reviews.length ? reviews.length : page.total);
    } catch (_) {
      ToastUtil.error('加载更多影评失败');
    } finally {
      isLoadingMore.value = false;
    }
  }
}

class DoubanReviewListPage extends GetWidget<DoubanReviewListController> {
  const DoubanReviewListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final args = controller.args.value;
      final posterUrl = args.posterPath == null
          ? null
          : ImageUtil.convertCacheImageUrl(args.posterPath!);
      return Scaffold(
        backgroundColor: AppTheme.darkBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.darkBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Get.back(),
            child: const Icon(CupertinoIcons.back),
          ),
          title: const Text(
            '全部影评',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: controller.reloadReviews,
              child: const Icon(
                CupertinoIcons.arrow_clockwise,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        body: _buildBody(context, args, posterUrl),
      );
    });
  }

  Widget _buildBody(
    BuildContext context,
    DoubanReviewListArgs args,
    String? posterUrl,
  ) {
    if (controller.isLoading.value) {
      return _buildSkeleton(context);
    }
    final error = controller.errorText.value;
    if (error != null && error.isNotEmpty && controller.reviews.isEmpty) {
      return _buildError(context, error);
    }
    if (controller.reviews.isEmpty) {
      return _buildEmpty(context);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      itemCount: controller.reviews.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader(context, args, posterUrl);
        if (index == controller.reviews.length + 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LoadMoreFooter(
              hasMore: controller.hasMore,
              isLoading: controller.isLoadingMore.value,
              total: controller.total.value,
              onLoadMore: controller.loadMore,
              label: '查看更多影评',
              endLabel: '没有更多影评了',
            ),
          );
        }
        final review = controller.reviews[index - 1];
        return DoubanListItem(
          title: review.title ?? '豆瓣影评',
          content: review.abstract,
          authorName: review.author?.name ?? '豆瓣用户',
          avatarPath: review.author?.avatar,
          rating: review.rating,
          createTime: review.createTime,
          usefulCount: review.usefulCount ?? 0,
          commentsCount: review.commentsCount ?? 0,
          url: review.url,
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DoubanReviewListArgs args,
    String? posterUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (posterUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedImage(
                imageUrl: posterUrl,
                width: 54,
                height: 78,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  args.title.isEmpty ? '豆瓣影评' : args.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '共 ${controller.total.value} 篇影评',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        height: 132,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chat_bubble_text,
              size: 44,
              color: Colors.white.withValues(alpha: 0.28),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无豆瓣影评',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 40,
              color: Colors.white.withValues(alpha: 0.32),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.66),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: controller.reloadReviews,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
