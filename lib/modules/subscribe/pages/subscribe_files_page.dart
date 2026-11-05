import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_files_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_files_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/utils/image_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_request_headers.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 与服务端图片代理 URL 保持一致的缓存键，保证预热与弹层内加载命中同一条目。
String _cachedImageKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  final query = uri.queryParameters;
  final inner = query['url'] ?? query['imgurl'];
  return inner != null && inner.isNotEmpty ? inner : url;
}


Future<void> showSubscribeFilesSheet(
  BuildContext context,
  SubscribeItem item,
) async {
  if (item.id == null) {
    ToastUtil.info('无效的订阅');
    return;
  }
  final tag = 'subscribe-files-${item.id}';
  Get.put(SubscribeFilesController(item: item), tag: tag);
  final backdrop = item.backdrop?.trim().isNotEmpty == true
      ? item.backdrop
      : item.poster;
  if (backdrop != null && backdrop.trim().isNotEmpty && context.mounted) {
    final url = ImageUtil.convertCacheImageUrl(backdrop.trim());
    // 服务端图片代理要求资源令牌 Cookie，裸 NetworkImage 带不了请求头，
    // 预热必然 401；预热失败静默交给弹层内的 CachedImage 正常加载。
    precacheImage(
      CachedNetworkImageProvider(
        url,
        cacheKey: _cachedImageKey(url),
        headers: buildImageRequestHeaders(url),
        cacheManager: AppImageCacheManager.instance,
      ),
      context,
      onError: (_, __) {},
    );
  }
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.42,
          maxChildSize: 1,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SubscribeFilesSheet(
                controllerTag: tag,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  } finally {
    if (Get.isRegistered<SubscribeFilesController>(tag: tag)) {
      Get.delete<SubscribeFilesController>(tag: tag);
    }
  }
}

class SubscribeFilesSheet extends StatelessWidget {
  const SubscribeFilesSheet({
    super.key,
    required this.controllerTag,
    this.scrollController,
  });

  final String controllerTag;
  final ScrollController? scrollController;

  SubscribeFilesController get controller =>
      Get.find<SubscribeFilesController>(tag: controllerTag);

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Material(
      color: palette.pageBackground,
      child: Obx(() {
        final loading = controller.isLoading.value;
        final error = controller.errorText.value;
        final data = controller.result.value;
        final episodes = data?.episodes ?? const <SubscribeEpisodeFiles>[];
        final subscribe = controller.displaySubscribe;
        final backdropUrl = _backdropUrl(subscribe, episodes);

        return Stack(
          fit: StackFit.expand,
          children: [
            if (backdropUrl != null)
              Positioned.fill(
                child: CachedImage(
                  imageUrl: backdropUrl,
                  fit: BoxFit.cover,
                ),
              )
            else
              ColoredBox(color: palette.pageBackground),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.pageBackground.withValues(alpha: 0.18),
                      palette.pageBackground.withValues(alpha: 0.42),
                      palette.pageBackground.withValues(alpha: 0.82),
                      palette.pageBackground,
                    ],
                    stops: const [0, 0.28, 0.58, 0.82],
                  ),
                ),
              ),
            ),
            CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _SheetIntro(
                    title: controller.pageTitle,
                    meta: _metaLine(subscribe),
                    vote: subscribe.vote,
                    episodeCount: controller.episodeCount,
                    downloadCount: controller.downloadCount,
                    libraryCount: controller.libraryCount,
                    loading: loading,
                    onClose: () => Navigator.of(context).maybePop(),
                    onRefresh: controller.load,
                  ),
                ),
                if (loading && data == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ListLoadingBody(),
                  )
                else if (error != null && data == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyBody(
                      message: error,
                      actionLabel: '重试',
                      onAction: controller.load,
                    ),
                  )
                else if (episodes.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyBody(message: '暂无相关文件'),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      MediaQuery.paddingOf(context).bottom + 24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index < episodes.length - 1 ? 12 : 0,
                          ),
                          child: _EpisodePosterCard(episode: episodes[index]),
                        ),
                        childCount: episodes.length,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }

  String? _backdropUrl(
    SubscribeItem? subscribe,
    List<SubscribeEpisodeFiles> episodes,
  ) {
    final candidates = <String?>[
      subscribe?.backdrop,
      subscribe?.poster,
      ...episodes.map((e) => e.backdrop),
    ];
    for (final url in candidates) {
      final value = url?.trim() ?? '';
      if (value.isEmpty) continue;
      return ImageUtil.convertCacheImageUrl(value);
    }
    return null;
  }

  String _metaLine(SubscribeItem? subscribe) {
    if (subscribe == null) return '';
    final parts = <String>[
      if ((subscribe.year ?? '').isNotEmpty) subscribe.year!,
      if (subscribe.season != null && subscribe.season! > 0)
        'S${subscribe.season}',
      if ((subscribe.type ?? '').isNotEmpty) subscribe.type!,
    ];
    return parts.join(' · ');
  }
}

class _ListLoadingBody extends StatelessWidget {
  const _ListLoadingBody();

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '正在加载文件…',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.folder, size: 34, color: palette.faintText),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.mutedText,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              CupertinoButton.filled(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetIntro extends StatelessWidget {
  const _SheetIntro({
    required this.title,
    required this.meta,
    required this.episodeCount,
    required this.downloadCount,
    required this.libraryCount,
    required this.onClose,
    required this.onRefresh,
    this.loading = false,
    this.vote,
  });

  final String title;
  final String meta;
  final int episodeCount;
  final int downloadCount;
  final int libraryCount;
  final bool loading;
  final double? vote;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _CircleIconButton(
                icon: CupertinoIcons.xmark,
                onPressed: onClose,
              ),
              const Spacer(),
              if (vote != null && vote! > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '★ ${vote!.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFD60A),
                    ),
                  ),
                ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                _CircleIconButton(
                  icon: CupertinoIcons.refresh,
                  onPressed: onRefresh,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1.15,
              color: palette.titleText,
              shadows: [
                Shadow(
                  color: palette.pageBackground.withValues(alpha: 0.7),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.bodyText.withValues(alpha: 0.82),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: '分集',
                value: '$episodeCount',
                color: palette.primary,
              ),
              _MetricChip(
                label: '下载',
                value: loading && downloadCount == 0 ? '…' : '$downloadCount',
                color: palette.coolAccent,
              ),
              _MetricChip(
                label: '媒体库',
                value: loading && libraryCount == 0 ? '…' : '$libraryCount',
                color: palette.successAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.36),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _EpisodePosterCard extends StatelessWidget {
  const _EpisodePosterCard({required this.episode});

  final SubscribeEpisodeFiles episode;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final title = episode.title?.trim().isNotEmpty == true
        ? episode.title!.trim()
        : '第 ${episode.episodeKey} 集';
    final backdrop = episode.backdrop?.trim() ?? '';
    final hasLibrary = episode.libraries.isNotEmpty;
    final hasDownload = episode.downloads.isNotEmpty;
    final accent = hasLibrary
        ? palette.successAccent
        : hasDownload
            ? palette.coolAccent
            : palette.mutedText;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: palette.isDark ? 0.78 : 0.90),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.tileBorder),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 132,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (backdrop.isNotEmpty)
                  CachedImage(
                    imageUrl: ImageUtil.convertCacheImageUrl(backdrop),
                    fit: BoxFit.cover,
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.35),
                          palette.surfaceAlt,
                        ],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 12,
                  child: Text(
                    'E${episode.episodeKey}',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -1.2,
                      color: Colors.white.withValues(alpha: 0.92),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Row(
                    children: [
                      if (hasDownload)
                        _StatusPill(
                          icon: CupertinoIcons.arrow_down_circle_fill,
                          label: '${episode.downloads.length}',
                          color: palette.coolAccent,
                        ),
                      if (hasDownload && hasLibrary) const SizedBox(width: 6),
                      if (hasLibrary)
                        _StatusPill(
                          icon: CupertinoIcons.folder_fill,
                          label: '${episode.libraries.length}',
                          color: palette.successAccent,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasDownload || hasLibrary)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDownload) ...[
                    _SectionCaption(
                      icon: CupertinoIcons.arrow_down_circle_fill,
                      label: '下载文件',
                      color: palette.coolAccent,
                    ),
                    const SizedBox(height: 8),
                    ...episode.downloads.map(
                      (e) => _FileRow(
                        kind: _FileKind.download,
                        title: e.torrentTitle?.trim().isNotEmpty == true
                            ? e.torrentTitle!
                            : (e.filePath ?? '未知下载'),
                        chips: [
                          if ((e.siteName ?? '').isNotEmpty) e.siteName!,
                          if ((e.downloader ?? '').isNotEmpty) e.downloader!,
                        ],
                        path: e.filePath,
                      ),
                    ),
                  ],
                  if (hasDownload && hasLibrary) const SizedBox(height: 4),
                  if (hasLibrary) ...[
                    _SectionCaption(
                      icon: CupertinoIcons.folder_fill,
                      label: '媒体库',
                      color: palette.successAccent,
                    ),
                    const SizedBox(height: 8),
                    ...episode.libraries.map(
                      (e) => _FileRow(
                        kind: _FileKind.library,
                        title: _fileName(e.filePath) ?? '未知媒体库文件',
                        chips: [
                          if ((e.storage ?? '').isNotEmpty) e.storage!,
                          if ((e.serverType ?? '').isNotEmpty) e.serverType!,
                        ],
                        path: e.filePath,
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.tray,
                    size: 16,
                    color: palette.faintText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '暂无关联文件',
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String? _fileName(String? path) {
    if (path == null || path.isEmpty) return null;
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

enum _FileKind { download, library }

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.kind,
    required this.title,
    required this.chips,
    this.path,
  });

  final _FileKind kind;
  final String title;
  final List<String> chips;
  final String? path;

  Future<void> _copyPath() async {
    if (path == null || path!.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: path!));
    ToastUtil.success('已复制路径');
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final accent = kind == _FileKind.download
        ? palette.coolAccent
        : palette.successAccent;
    final icon = kind == _FileKind.download
        ? CupertinoIcons.arrow_down_circle_fill
        : CupertinoIcons.folder_fill;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: path == null || path!.isEmpty ? null : _copyPath,
          onLongPress: path == null || path!.isEmpty ? null : _copyPath,
          child: Ink(
            decoration: BoxDecoration(
              color: palette.tileSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.tileBorder),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(icon, size: 17, color: accent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (chips.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: chips
                                        .map(
                                          (chip) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accent.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              chip,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: accent,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                if (chips.isNotEmpty) const SizedBox(height: 8),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: palette.bodyText,
                                    height: 1.35,
                                  ),
                                ),
                                if (path != null &&
                                    path!.isNotEmpty &&
                                    path != title) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    path!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.4,
                                      color: palette.mutedText,
                                      fontFamily: 'Menlo',
                                      fontFamilyFallback: const [
                                        'Courier',
                                        'monospace',
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (path != null && path!.isNotEmpty)
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: IconButton(
                                tooltip: '复制路径',
                                onPressed: _copyPath,
                                icon: Icon(
                                  CupertinoIcons.doc_on_doc,
                                  size: 18,
                                  color: palette.mutedText,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
