import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart'
    show Actor;
import 'package:moviepilot_mobile/modules/search/controllers/person_search_list_controller.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/grid_layout.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/media_source_util.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PersonSearchResultPage extends GetView<PersonSearchListController> {
  const PersonSearchResultPage({super.key});

  static const double _gridSpacing = 12;
  static const double _gridPadding = 16;
  static const double _cardAspectRatio = 0.72;
  static const int _skeletonGridCount = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Obx(() {
        final items = controller.items.toList();
        final isLoading = controller.isLoading.value;
        final error = controller.error.value;
        final hasMore = controller.hasMore.value;
        final keyword = controller.keyword.value.trim();
        final showSkeleton = isLoading && items.isEmpty;
        final showOnlyLoading = isLoading && items.isEmpty && error == null;

        if (showOnlyLoading) {
          return _LoadingScaffold(keyword: keyword);
        }

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: controller.search,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildHeader(
                context,
                keyword: keyword,
              ),
              if (items.isEmpty && !showSkeleton)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    error: error,
                    keyword: keyword,
                    onRetry: controller.search,
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    _gridPadding,
                    4,
                    _gridPadding,
                    8,
                  ),
                  sliver: Skeletonizer.sliver(
                    enabled: showSkeleton,
                    child: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridLayout(
                          context,
                          gridSpacing: _gridSpacing,
                          gridPadding: _gridPadding,
                        ).crossAxisCount,
                        mainAxisSpacing: _gridSpacing,
                        crossAxisSpacing: _gridSpacing,
                        childAspectRatio: _cardAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (showSkeleton) {
                            return const _PersonSkeletonCard();
                          }
                          final item = items[index];
                          return _PersonCard(
                            key: ValueKey(item.id ?? '${item.name}_$index'),
                            item: item,
                          );
                        },
                        childCount: showSkeleton
                            ? _skeletonGridCount
                            : items.length,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    child: LoadMoreFooter(
                      hasMore: hasMore,
                      isLoading: isLoading,
                      hasItems: items.isNotEmpty,
                      onLoadMore: controller.loadMore,
                      endLabel: '没有更多演员了',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String keyword,
  }) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppTheme.darkBackgroundColor.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(CupertinoIcons.chevron_left, color: Colors.white),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '演员搜索',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (keyword.isNotEmpty)
            Text(
              keyword,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.62),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 0.6,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0B1220),
                AppTheme.darkBackgroundColor,
                const Color(0xFF050816),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    CupertinoIcons.chevron_left,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              AppLoading(
                message: keyword.isEmpty ? '正在搜索演员' : '正在搜索「$keyword」',
                messageStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.error,
    required this.keyword,
    required this.onRetry,
  });

  final String? error;
  final String keyword;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isNoResult = error == null || error == '没有找到匹配的演员';
    final title = isNoResult ? '没有找到匹配的演员' : '搜索遇到问题';
    final subtitle = isNoResult
        ? (keyword.isEmpty
              ? '换一个关键词再试试。'
              : '没有命中 “$keyword”，可以试试中英文名或别名。')
        : (error ?? '请稍后重试');

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              isNoResult
                  ? CupertinoIcons.person_2
                  : CupertinoIcons.exclamationmark_circle,
              size: 34,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新搜索'),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({super.key, required this.item});

  final Actor item;

  String get _avatarUrl {
    final avatar = item.profile_path != null && item.profile_path!.isNotEmpty
        ? item.profile_path
        : item.images?.large?.url;
    if (avatar == null || avatar.isEmpty) return '';
    return ImageUtil.convertCacheImageUrl(avatar);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final name = (item.name ?? '').trim().isEmpty ? '未知演员' : item.name!.trim();
    final department = (item.known_for_department ?? '').trim();
    final source = (item.source ?? '').trim();
    final url = _avatarUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final id = item.id;
          if (id == null) return;
          HapticFeedback.selectionClick();
          Get.toNamed(
            '/person-detail',
            parameters: {
              'id': id.toString(),
              'source': MediaSourceUtil.sourceValue(source),
            },
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url.isNotEmpty)
                  CachedImage(imageUrl: url, fit: BoxFit.cover)
                else
                  ColoredBox(
                    color: const Color(0xFF1B2333),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      size: 42,
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x14000000),
                        Color(0x00000000),
                        Color(0xCC0B1220),
                        Color(0xF2050816),
                      ],
                      stops: [0, 0.42, 0.72, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      if (department.isNotEmpty || source.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (department.isNotEmpty)
                              _MiniChip(
                                label: department,
                                color: primary,
                              ),
                            if (source.isNotEmpty)
                              _MiniChip(
                                label: source.toUpperCase(),
                                color: Colors.white70,
                                muted: true,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    this.muted = false,
  });

  final String label;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: muted ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: muted ? 0.16 : 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PersonSkeletonCard extends StatelessWidget {
  const _PersonSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
