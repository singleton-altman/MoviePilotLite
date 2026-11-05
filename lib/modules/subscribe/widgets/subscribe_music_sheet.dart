import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 音乐订阅详情 sheet：展示订阅状态与时间，提供搜索资源 / 删除操作。
Future<void> showSubscribeMusicSheet(
  BuildContext context,
  SubscribeItem item,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.58,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: SubscribeMusicSheet(
              item: item,
              scrollController: scrollController,
            ),
          );
        },
      );
    },
  );
}

class SubscribeMusicSheet extends StatelessWidget {
  const SubscribeMusicSheet({
    super.key,
    required this.item,
    this.scrollController,
  });

  final SubscribeItem item;
  final ScrollController? scrollController;

  SubscribeController? get _controller =>
      Get.isRegistered<SubscribeController>()
      ? Get.find<SubscribeController>()
      : null;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final theme = Theme.of(context);
    final hasCover = item.poster?.trim().isNotEmpty == true;
    final typeLabel = _typeLabel;
    final showTracks = _showTracks;
    final description = item.description?.trim();

    return Material(
      color: palette.pageBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 顶部以封面或音乐主题渐变铺底，向下淡入页面背景
          if (hasCover)
            Positioned.fill(
              child: CachedImage(
                imageUrl: item.poster!.trim(),
                fit: BoxFit.cover,
              ),
            )
          else
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      palette.pageBackground,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.library_music_rounded,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.pageBackground.withValues(alpha: hasCover ? 0.24 : 0.72),
                    palette.pageBackground.withValues(alpha: 0.62),
                    palette.pageBackground,
                  ],
                  stops: const [0, 0.42, 0.78],
                ),
              ),
            ),
          ),
          CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildCover(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMetaPill('音乐', const Color(0xFF8B5CF6)),
                            if (typeLabel != null) ...[
                              const SizedBox(width: 6),
                              _buildMetaPill(typeLabel, const Color(0xFF0284C7)),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              item.name ?? '未知专辑',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if ((item.year ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.year!.trim(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ..._infoRows(context),
                        if (showTracks) ...[
                          _buildDivider(theme),
                          _buildTrackProgressRow(
                            context,
                            downloaded: _downloadedTracks ?? 0,
                            total: _totalTracks ?? 0,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (description != null && description.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '简介',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                          onPressed: () => Get.toNamed(
                            '/music/search',
                            parameters: {
                              'keyword': (item.name ?? '').trim(),
                            },
                          ),
                          icon: const Icon(Icons.search_rounded, size: 19),
                          label: const Text('搜索资源'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(88, 46),
                          foregroundColor: theme.colorScheme.error,
                          backgroundColor: theme.colorScheme.error.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(
                          CupertinoIcons.delete,
                          size: 18,
                        ),
                        label: const Text('删除'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    final hasCover = item.poster?.trim().isNotEmpty == true;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: hasCover
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedImage(
                imageUrl: item.poster!.trim(),
                fit: BoxFit.cover,
              ),
            )
          : const Icon(
              Icons.library_music_rounded,
              size: 38,
              color: Colors.white,
            ),
    );
  }

  Widget _buildMetaPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _infoRows(BuildContext context) {
    return [
      _buildInfoRow(
        context,
        icon: CupertinoIcons.info_circle,
        label: '订阅状态',
        value: _stateLabel,
        valueColor: _stateColor(context),
      ),
      if (_sourceLabel != null)
        _buildInfoRow(
          context,
          icon: CupertinoIcons.globe,
          label: '数据来源',
          value: _sourceLabel!,
        ),
      _buildInfoRow(
        context,
        icon: CupertinoIcons.time,
        label: '订阅时间',
        value: _subscribedAt,
      ),
      if ((item.username ?? '').trim().isNotEmpty)
        _buildInfoRow(
          context,
          icon: CupertinoIcons.person_fill,
          label: '订阅人',
          value: item.username!.trim(),
        ),
    ];
  }

  Widget _buildTrackProgressRow(
    BuildContext context, {
    required int downloaded,
    required int total,
  }) {
    final theme = Theme.of(context);
    final progress = (downloaded / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.music_note,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                '音轨进度',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '$downloaded / $total',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.4,
              ),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF8B5CF6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? get _raw =>
      item.id == null ? null : _controller?.rawSubscribeById['${item.id}'];

  String? _rawText(Map<String, dynamic>? raw, String key) {
    final v = raw?[key];
    if (v == null) return null;
    final t = v.toString().trim();
    return t.isEmpty ? null : t;
  }

  int? _rawInt(Map<String, dynamic>? raw, String key) {
    final v = raw?[key];
    if (v is int) return v;
    return int.tryParse('${v ?? ''}');
  }

  String? get _sourceLabel =>
      switch (_rawText(_raw, 'media_source')?.toLowerCase()) {
        'musicbrainz' => 'MusicBrainz',
        'theaudiodb' => 'TheAudioDB',
        'doubanmusic' => '豆瓣音乐',
        final value => value,
      };

  String? get _typeLabel => switch ((_rawText(_raw, 'music_type') ?? '')
      .toLowerCase()) {
    'album' => '专辑',
    'recording' => '单曲',
    _ => null,
  };

  int? get _totalTracks => _rawInt(_raw, 'total_tracks');

  int? get _downloadedTracks => _rawInt(_raw, 'downloaded_tracks');

  bool get _showTracks {
    final total = _totalTracks;
    return total != null && total > 0;
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 0.6,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }

  String get _stateLabel {
    switch (item.state?.trim().toUpperCase()) {
      case 'R':
        return '订阅中';
      case 'N':
        return '未开始';
      case 'S':
      case 'P':
        return '已暂停';
      default:
        return '待定';
    }
  }

  Color _stateColor(BuildContext context) {
    switch (item.state?.trim().toUpperCase()) {
      case 'R':
        return const Color(0xFF16A34A);
      case 'N':
        return const Color(0xFF0284C7);
      case 'S':
      case 'P':
        return const Color(0xFFF59E0B);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String get _subscribedAt {
    final raw = (item.date ?? '').trim();
    if (raw.isEmpty) return '未知';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final created = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    final relative = SubscribeController.formatRelativeTime(raw);
    return '$created（$relative）';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final id = item.id;
    if (id == null) {
      ToastUtil.info('无效的订阅');
      return;
    }
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('删除订阅'),
        content: Text('确定删除「${item.name ?? '未知专辑'}」的音乐订阅吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final controller = _controller;
    if (controller == null) {
      ToastUtil.error('删除失败，请稍后重试');
      return;
    }
    final ok = await controller.deleteSubscribes('$id');
    if (!ok) {
      ToastUtil.error('删除失败，请稍后重试');
      return;
    }
    ToastUtil.success('已删除音乐订阅');
    if (context.mounted) {
      Navigator.of(context).maybePop();
    }
  }
}
