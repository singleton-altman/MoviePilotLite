import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_api_item_ext.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/search/pages/search_mid_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class RecommendItemCard extends GetView<SubscribeService> {
  const RecommendItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.width,
  }) : isPlaceholder = false;

  const RecommendItemCard.placeholder({super.key, this.width})
    : item = null,
      isPlaceholder = true,
      onTap = null;

  final RecommendApiItem? item;
  final bool isPlaceholder;
  final VoidCallback? onTap;
  final double? width;

  static const double cardWidth = 150;
  static const double cardRadius = 10;

  double get _cardWidth => width ?? cardWidth;
  double get _cardHeight => _cardWidth * 1.4;

  @override
  Widget build(BuildContext context) {
    if (isPlaceholder || item == null) {
      return _buildPlaceholder();
    }
    return Material(
      child: Obx(() {
        final subscribeItem = controller.subscribeItems[item!.subscribeKey];

        final isSubscribed = subscribeItem != null && subscribeItem.id != null;
        return CupertinoContextMenu.builder(
          builder: (context, menuState) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: _buildContent(),
            );
          },
          actions: [
            Material(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  item?.overview ?? '',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            _buildSubscribeAction(
              context,
              isSubscribed: isSubscribed,
              subscribeKey: item!.subscribeKey,
              subscribeItem: subscribeItem,
            ),
            _buildSearchAction(context),
          ],
        );
      }),
    );
  }

  Widget _buildSubscribeAction(
    BuildContext context, {
    required bool isSubscribed,
    SubscribeItem? subscribeItem,
    required String subscribeKey,
  }) {
    return Material(
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);
          final ok = await controller.toggleMediaSubscribe(
            mediaKey: item!.mediaKey,
            isTv: item?.type == 'tv',
            isSubscribed: isSubscribed,
            doubanid: item?.douban_id?.toString(),
            name: item?.title,
            season: item?.season,
            tmdbid: item?.tmdb_id?.toString(),
            year: item?.year,
            subscribeId: subscribeItem?.id?.toString(),
          );
          if (ok && isSubscribed) {
            controller.subscribeItems[subscribeKey] = null;
          }
          if (ok && !isSubscribed) {
            controller.fetchAndSaveSubscribeStatus(
              item!.mediaKey,
              season: item?.season,
              title: item?.title,
            );
          }
          Future.delayed(const Duration(milliseconds: 200), () {
            if (ok) {
              ToastUtil.success(
                isSubscribed ? '${item?.title} 取消订阅成功' : '${item?.title} 订阅成功',
              );
            } else {
              ToastUtil.error(
                isSubscribed ? '${item?.title} 取消订阅失败' : '${item?.title} 订阅失败',
              );
            }
          });
        },
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              SizedBox(width: 16),
              Text(
                isSubscribed ? '取消订阅' : '订阅',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSubscribed ? Colors.red : Colors.grey,
                ),
              ),
              Spacer(),
              Icon(
                isSubscribed ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                size: 20,
                color: isSubscribed ? Colors.red : Colors.grey,
              ),
              SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAction(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _openSearch(context);
        },
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              SizedBox(width: 16),
              Text('搜索'),
              Spacer(),
              Icon(
                Icons.search,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) async {
    final searchKey = item?.mediaKey;
    final detail = item;
    final season = item?.season;
    final result = await Get.bottomSheet<({String area, List<int> sites})>(
      SiteSelectSheet(hasSegment: true),
    );
    if (result == null) return;
    final (area, sites) = (result.area, result.sites);
    if (sites.isEmpty) {
      ToastUtil.info('请至少选择一个站点');
      return;
    }
    var params = <String, String>{
      'mediaSearchKey': searchKey ?? '',
      'area': area,
      'sites': sites.join(','),
      'year': detail?.year ?? '',
      'mtype': detail?.type ?? 'movie',
      'title': detail?.title ?? '',
    };
    if (season != null) {
      params['season'] = season.toString();
    }
    Get.toNamed('/search-media-result', parameters: params);
  }

  Widget _buildContent() {
    final data = item;
    return SizedBox(
      width: _cardWidth,
      height: _cardHeight,
      child: Stack(
        children: [
          _buildPoster(data),
          if (data?.type != null && data!.type!.isNotEmpty)
            Positioned(left: 10, top: 10, child: _buildPill(data.type!)),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildTitle(data?.title ?? ''),
          ),
          if (data?.vote_average != null && data!.vote_average! > 0)
            Positioned(
              right: 10,
              top: 10,
              child: _buildPill(
                data?.vote_average?.toStringAsFixed(1) ?? '',
                background: const Color(0xFF7C4DFF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(cardRadius),
          bottomRight: Radius.circular(cardRadius),
        ),
        gradient: LinearGradient(colors: [Colors.black, Colors.transparent]),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPoster(RecommendApiItem? data) {
    var imageUrl = data?.poster_path;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageUrl = ImageUtil.convertCacheImageUrl(imageUrl);
      return CachedImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: _cardWidth,
        height: _cardHeight,
        borderRadius: BorderRadius.circular(cardRadius),
      );
    }
    return Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9FA8DA), Color(0xFF5C6BC0)],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return SizedBox(
      width: _cardWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          height: _cardHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFE1E3EA),
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String text, {Color background = const Color(0xFF4C6FFF)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
