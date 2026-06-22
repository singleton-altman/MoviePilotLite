import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class MediaOrganizeDetailSheet extends StatelessWidget {
  const MediaOrganizeDetailSheet({
    super.key,
    required this.item,
    required this.srcStorageName,
    required this.destStorageName,
  });

  final MediaOrganizeTransferItem item;
  final String srcStorageName;
  final String destStorageName;

  static Future<void> show(
    BuildContext context, {
    required MediaOrganizeTransferItem item,
    required String srcStorageName,
    required String destStorageName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaOrganizeDetailSheet(
        item: item,
        srcStorageName: srcStorageName,
        destStorageName: destStorageName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => Material(
        color: colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.list(
                children: [
                  _buildOverviewSection(context),
                  const SizedBox(height: 14),
                  _buildPathSection(context),
                  const SizedBox(height: 14),
                  _buildFileSection(context),
                  if (_identifierRows().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildIdentifierSection(context),
                  ],
                  if ((item.errmsg ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildErrorSection(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = (item.title ?? '').trim();
    final status = _statusPresentation(colorScheme);
    final image = (item.image ?? '').trim();

    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 110,
                  child: image.isEmpty
                      ? ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie_creation_outlined,
                            size: 32,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : CachedImage(
                          imageUrl: ImageUtil.convertCacheImageUrl(image),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? '未知媒体' : title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _headerChip(
                            context,
                            icon: status.icon,
                            label: status.label,
                            color: status.color,
                          ),
                          if ((item.type ?? '').trim().isNotEmpty)
                            _headerChip(
                              context,
                              icon: Icons.local_movies_outlined,
                              label: item.type!.trim(),
                              color: colorScheme.primary,
                            ),
                          if ((item.year ?? '').trim().isNotEmpty)
                            _headerChip(
                              context,
                              icon: Icons.calendar_today_outlined,
                              label: item.year!.trim(),
                              color: colorScheme.tertiary,
                            ),
                        ],
                      ),
                      if ((item.category ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Text(
                          item.category!.trim(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colorScheme.outlineVariant),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _headerChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    final rows = <({String label, String value, IconData icon})>[
      (
        label: '整理方式',
        value: _localizedMode(item.mode).isEmpty
            ? '未记录'
            : _localizedMode(item.mode),
        icon: Icons.auto_mode_outlined,
      ),
      (
        label: '季 / 集',
        value: _episodeLabel().isEmpty ? '不适用' : _episodeLabel(),
        icon: Icons.video_library_outlined,
      ),
      (
        label: '整理时间',
        value: (item.date ?? '').trim().isEmpty ? '未记录' : item.date!.trim(),
        icon: Icons.schedule_rounded,
      ),
      (
        label: '下载器',
        value: (item.downloader ?? '').trim().isEmpty
            ? '未记录'
            : item.downloader!.trim(),
        icon: Icons.download_for_offline_outlined,
      ),
    ];

    return _section(
      context,
      title: '整理摘要',
      icon: Icons.fact_check_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 520;
          if (!twoColumns) {
            return Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  _detailRow(
                    context,
                    icon: rows[index].icon,
                    label: rows[index].label,
                    value: rows[index].value,
                  ),
                  if (index != rows.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }
          return Wrap(
            spacing: 16,
            runSpacing: 14,
            children: rows
                .map(
                  (row) => SizedBox(
                    width: (constraints.maxWidth - 16) / 2,
                    child: _detailRow(
                      context,
                      icon: row.icon,
                      label: row.label,
                      value: row.value,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildPathSection(BuildContext context) {
    return _section(
      context,
      title: '转移路径',
      icon: Icons.route_outlined,
      child: Column(
        children: [
          _pathDetail(
            context,
            title: '来源',
            storage: srcStorageName,
            storageKey: item.src_storage,
            path: item.src,
            icon: Icons.file_open_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.south_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          _pathDetail(
            context,
            title: '目标',
            storage: destStorageName,
            storageKey: item.dest_storage,
            path: item.dest,
            icon: Icons.folder_open_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection(BuildContext context) {
    final source = item.src_fileitem;
    final destination = item.dest_fileitem;
    final files = item.files;

    return _section(
      context,
      title: '文件信息',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          _detailRow(
            context,
            icon: Icons.storage_outlined,
            label: '源文件大小',
            value: SizeFormatter.formatSize(source?.size ?? 0),
          ),
          const SizedBox(height: 12),
          _detailRow(
            context,
            icon: Icons.file_copy_outlined,
            label: '记录文件数',
            value: '${files.length} 个',
          ),
          if ((source?.name ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow(
              context,
              icon: Icons.description_outlined,
              label: '源文件名',
              value: source!.name!.trim(),
              selectable: true,
            ),
          ],
          if ((destination?.name ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow(
              context,
              icon: Icons.task_outlined,
              label: '目标文件名',
              value: destination!.name!.trim(),
              selectable: true,
            ),
          ],
          if (files.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '文件列表',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            for (final file in files)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: SelectionArea(
                        child: Text(
                          file,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentifierSection(BuildContext context) {
    return _section(
      context,
      title: '关联标识',
      icon: Icons.fingerprint_rounded,
      child: Column(
        children: [
          for (var index = 0; index < _identifierRows().length; index++) ...[
            _detailRow(
              context,
              icon: Icons.tag_rounded,
              label: _identifierRows()[index].label,
              value: _identifierRows()[index].value,
              selectable: true,
            ),
            if (index != _identifierRows().length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context) {
    final color = item.status == true
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return _section(
      context,
      title: item.status == true ? '处理信息' : '错误信息',
      icon: item.status == true
          ? Icons.info_outline_rounded
          : Icons.error_outline_rounded,
      accent: color,
      child: SelectionArea(
        child: Text(
          item.errmsg!.trim(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: color, height: 1.45),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    Color? accent,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sectionColor = accent ?? colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: sectionColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool selectable = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final valueWidget = Text(
      value,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              if (selectable)
                SelectionArea(child: valueWidget)
              else
                valueWidget,
            ],
          ),
        ),
      ],
    );
  }

  Widget _pathDetail(
    BuildContext context, {
    required String title,
    required String storage,
    required String? storageKey,
    required String? path,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final resolvedStorage = storage.trim().isNotEmpty
        ? storage.trim()
        : (storageKey ?? '').trim();
    final resolvedPath = (path ?? '').trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolvedStorage.isEmpty ? title : '$title · $resolvedStorage',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              SelectionArea(
                child: Text(
                  resolvedPath.isEmpty ? '未记录路径' : resolvedPath,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<({String label, String value})> _identifierRows() {
    return [
      if (item.id != null) (label: '记录 ID', value: item.id.toString()),
      if (item.tmdbid != null) (label: 'TMDB', value: item.tmdbid.toString()),
      if ((item.imdbid ?? '').trim().isNotEmpty)
        (label: 'IMDb', value: item.imdbid!.trim()),
      if (item.tvdbid != null) (label: 'TVDB', value: item.tvdbid.toString()),
      if (item.doubanid != null) (label: '豆瓣', value: item.doubanid.toString()),
      if ((item.download_hash ?? '').trim().isNotEmpty)
        (label: '下载 Hash', value: item.download_hash!.trim()),
    ];
  }

  ({String label, IconData icon, Color color}) _statusPresentation(
    ColorScheme colorScheme,
  ) {
    if (item.status == true) {
      return (
        label: '整理成功',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF22C55E),
      );
    }
    if (item.status == false) {
      return (
        label: '整理失败',
        icon: Icons.error_outline_rounded,
        color: colorScheme.error,
      );
    }
    return (
      label: '状态未知',
      icon: Icons.help_outline_rounded,
      color: colorScheme.onSurfaceVariant,
    );
  }

  String _localizedMode(String? mode) {
    final value = (mode ?? '').trim().toLowerCase();
    switch (value) {
      case 'move':
        return '移动';
      case 'copy':
        return '复制';
      case 'hard link':
      case 'hard_link':
      case 'hardlink':
        return '硬连接';
      case 'soft link':
      case 'soft_link':
      case 'softlink':
        return '软连接';
      default:
        return (mode ?? '').trim();
    }
  }

  String _episodeLabel() {
    final parts = <String>[];
    final seasons = (item.seasons ?? '').trim();
    final episodes = (item.episodes ?? '').trim();
    if (seasons.isNotEmpty) parts.add('S$seasons');
    if (episodes.isNotEmpty) parts.add('E$episodes');
    return parts.join(' ');
  }
}
