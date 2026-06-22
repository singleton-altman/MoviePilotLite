import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_api_item_ext.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/search/pages/search_mid_sheet.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_service.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

import 'package:moviepilot_mobile/utils/toast_util.dart';

class RecommendItemBaseCard extends GetView<SubscribeService> {
  const RecommendItemBaseCard({
    super.key,
    required this.item,
    required this.child,
  });

  final RecommendApiItem? item;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Obx(() {
        final subscribeItem = controller.subscribeItems[item?.subscribeKey];
        final isSubscribed = subscribeItem != null && subscribeItem.id != null;
        final appService = Get.find<AppService>();
        final menuActions = <Widget>[
          Material(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item?.overview ?? '',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_sourceLabels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.link,
                          size: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _buildSourceSpans(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (appService.canSubscribe)
            _buildSubscribeAction(
              context,
              isSubscribed: isSubscribed,
              subscribeKey: item!.subscribeKey,
              subscribeItem: subscribeItem,
            ),
          if (appService.canSearch) _buildSearchAction(context),
        ];
        return CupertinoContextMenu.builder(
          enableHapticFeedback: true,
          builder: (context, menuState) {
            return child;
          },
          actions: menuActions,
        );
      }),
    );
  }

  List<String> get _sourceLabels {
    final labels = <String>[];

    void addLabel(String value) {
      if (!labels.contains(value)) {
        labels.add(value);
      }
    }

    final rawSource = item?.source?.trim().toLowerCase() ?? '';
    if (rawSource.contains('douban')) addLabel('豆瓣');
    if (rawSource.contains('imdb')) addLabel('IMDb');
    if (rawSource.contains('bangumi')) addLabel('Bangumi');
    if (rawSource.contains('tmdb') || rawSource.contains('themoviedb')) {
      addLabel('TMDB');
    }

    if ((item?.douban_id ?? '').trim().isNotEmpty) addLabel('豆瓣');
    if ((item?.imdb_id ?? '').trim().isNotEmpty) addLabel('IMDb');
    if ((item?.bangumi_id ?? '').trim().isNotEmpty) addLabel('Bangumi');
    if ((item?.tmdb_id ?? '').trim().isNotEmpty) addLabel('TMDB');

    return labels;
  }

  List<Widget> _buildSourceSpans(BuildContext context) {
    final displays = _sourceDisplays;
    final widgets = <Widget>[];
    for (var index = 0; index < displays.length; index++) {
      final source = displays[index];
      widgets.add(
        Text(
          source.label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: source.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      if (index != displays.length - 1) {
        widgets.add(
          Text(
            '/',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<_SourceDisplay> get _sourceDisplays {
    final displays = <_SourceDisplay>[];

    void addDisplay(String label, Color color) {
      final exists = displays.any((item) => item.label == label);
      if (!exists) {
        displays.add(_SourceDisplay(label: label, color: color));
      }
    }

    final rawSource = item?.source?.trim().toLowerCase() ?? '';
    if (rawSource.contains('douban')) addDisplay('豆瓣', const Color(0xFF42A75C));
    if (rawSource.contains('imdb')) addDisplay('IMDb', const Color(0xFFF5C518));
    if (rawSource.contains('bangumi')) {
      addDisplay('Bangumi', const Color(0xFFF09199));
    }
    if (rawSource.contains('tmdb') || rawSource.contains('themoviedb')) {
      addDisplay('TMDB', const Color(0xFF01B4E4));
    }

    if ((item?.douban_id ?? '').trim().isNotEmpty) {
      addDisplay('豆瓣', const Color(0xFF42A75C));
    }
    if ((item?.imdb_id ?? '').trim().isNotEmpty) {
      addDisplay('IMDb', const Color(0xFFF5C518));
    }
    if ((item?.bangumi_id ?? '').trim().isNotEmpty) {
      addDisplay('Bangumi', const Color(0xFFF09199));
    }
    if ((item?.tmdb_id ?? '').trim().isNotEmpty) {
      addDisplay('TMDB', const Color(0xFF01B4E4));
    }

    return displays;
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
          final (ok, subscribeId) = await controller.toggleMediaSubscribe(
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
          final isTv = item?.type == 'tv' || item?.type == '电视剧';
          final showEditSnack =
              ok && !isSubscribed && isTv && subscribeId != null;
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
              if (showEditSnack) {
                ToastUtil.success(
                  '${item?.title ?? ''} 订阅成功',
                  title: '订阅成功',
                  duration: const Duration(seconds: 3),
                  mainButtonText: '编辑',
                  onMainButtonPressed: () {
                    Get.toNamed(
                      '/subscribe-edit',
                      arguments: SubscribeItem(id: subscribeId),
                    );
                  },
                );
              } else {
                ToastUtil.success(
                  isSubscribed
                      ? '${item?.title} 取消订阅成功'
                      : '${item?.title} 订阅成功',
                );
              }
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
    if (!Get.find<AppService>().canSearch) {
      ToastUtil.info('当前帐号无资源搜索权限');
      return;
    }
    final searchKey = item?.mediaKey;
    final detail = item;
    final season = item?.season;
    final result = await Get.bottomSheet<({String area, List<int> sites})>(
      SiteSelectSheet(hasSegment: true),
      isScrollControlled: true,
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
      if ((detail?.backdrop_path ?? '').isNotEmpty)
        'backdrop': detail!.backdrop_path!,
    };
    if (season != null) {
      params['season'] = season.toString();
    }
    Get.toNamed('/search-media-result', parameters: params);
  }
}

class _SourceDisplay {
  const _SourceDisplay({required this.label, required this.color});

  final String label;
  final Color color;
}
