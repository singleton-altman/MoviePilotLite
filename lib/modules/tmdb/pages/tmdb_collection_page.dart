import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_api_item_ext.dart';
import 'package:moviepilot_mobile/modules/recommend/models/recommend_api_item.dart';
import 'package:moviepilot_mobile/modules/tmdb/controllers/tmdb_collection_controller.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class TmdbCollectionPage extends StatefulWidget {
  const TmdbCollectionPage({
    super.key,
    required this.collectionId,
    this.service,
  });
  final int collectionId;
  final TmdbCollectionService? service;

  @override
  State<TmdbCollectionPage> createState() => _TmdbCollectionPageState();
}

class _TmdbCollectionPageState extends State<TmdbCollectionPage> {
  late final TmdbCollectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TmdbCollectionController(
      collectionId: widget.collectionId,
      service: widget.service,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('系列合集')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final items = _controller.items;
          if (_controller.isLoading && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => _controller.load(refresh: true),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == items.length) return _buildFooter(items.isEmpty);
                return _buildMovie(items[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(bool empty) {
    if (_controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_controller.error != null) {
      return Column(
        children: [
          Text(_controller.error!),
          TextButton(
            onPressed: () => _controller.load(),
            child: const Text('重试'),
          ),
        ],
      );
    }
    if (empty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('暂无合集影片')),
      );
    }
    if (_controller.hasMore) {
      return TextButton(
        onPressed: () => _controller.load(),
        child: const Text('加载更多'),
      );
    }
    return const SizedBox(height: 24);
  }

  Widget _buildMovie(RecommendApiItem item) {
    final poster = item.poster_path?.trim() ?? '';
    final mediaKey = item.mediaKey;
    return Card(
      child: InkWell(
        onTap: mediaKey.isEmpty
            ? null
            : () => Get.toNamed(
                '/media-detail',
                parameters: {
                  'path': mediaKey,
                  'type_name': item.type ?? '电影',
                  if (item.title != null) 'title': item.title!,
                  if (item.year != null) 'year': item.year!,
                },
              ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 76,
                height: 114,
                child: poster.isEmpty
                    ? const Icon(Icons.movie_outlined)
                    : CachedImage(
                        imageUrl: ImageUtil.convertCacheImageUrl(poster),
                        borderRadius: BorderRadius.circular(8),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? item.original_title ?? '未命名影片',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                            item.year,
                            if (item.vote_average != null)
                              '评分 ${item.vote_average!.toStringAsFixed(1)}',
                          ]
                          .whereType<String>()
                          .where((text) => text.isNotEmpty)
                          .join(' · '),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.overview ?? '暂无简介',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
