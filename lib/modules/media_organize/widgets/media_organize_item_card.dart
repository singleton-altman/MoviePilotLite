import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 媒体整理历史卡片
class MediaOrganizeItemCard extends StatelessWidget {
  const MediaOrganizeItemCard({
    super.key,
    required this.item,
    required this.srcStorageName,
    required this.destStorageName,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.selectionEnabled = false,
    this.selected = false,
    this.showPopupMenu = true,
    this.onSelectionChanged,
    this.onTap,
    this.onDeleteTransferRecordOnly,
    this.onDeleteTransferRecordAndSourceFile,
    this.onDeleteTransferRecordAndMediaLibraryFile,
    this.onDeleteTransferRecordAndSourceFileAndMediaLibraryFile,
  });

  final MediaOrganizeTransferItem item;
  final String srcStorageName;
  final String destStorageName;
  final EdgeInsetsGeometry margin;
  final bool selectionEnabled;
  final bool selected;
  final bool showPopupMenu;
  final ValueChanged<bool>? onSelectionChanged;
  final VoidCallback? onTap;
  final void Function()? onDeleteTransferRecordOnly;
  final void Function()? onDeleteTransferRecordAndSourceFile;
  final void Function()? onDeleteTransferRecordAndMediaLibraryFile;
  final void Function()? onDeleteTransferRecordAndSourceFileAndMediaLibraryFile;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final success = item.status == true;
    final statusColor = success ? const Color(0xFF22C55E) : colorScheme.error;
    final title = (item.title ?? '').trim();

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${title.isEmpty ? '未知媒体' : title}，${success ? '整理成功' : '整理失败'}',
      child: Card(
        margin: margin,
        elevation: 0,
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.7)
                : colorScheme.outlineVariant.withValues(alpha: 0.65),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPoster(context, statusColor),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title.isEmpty ? '未知媒体' : title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(
                                context,
                                success: success,
                                color: statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildMetadata(context),
                          const SizedBox(height: 10),
                          _buildModeRow(context),
                        ],
                      ),
                    ),
                    if (selectionEnabled)
                      Checkbox(
                        value: selected,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (value) =>
                            onSelectionChanged?.call(value ?? false),
                      )
                    else if (showPopupMenu)
                      _buildPopupMenu(context),
                  ],
                ),
                if ((item.errmsg ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMessage(context, success: success),
                ],
                const SizedBox(height: 12),
                _buildTransferFlow(context),
                const SizedBox(height: 11),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context, Color statusColor) {
    final url = (item.image ?? '').trim();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 66,
            height: 96,
            child: url.isEmpty
                ? ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.movie_creation_outlined,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : CachedImage(
                    imageUrl: ImageUtil.convertCacheImageUrl(url),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainer,
                width: 2,
              ),
            ),
            child: Icon(
              item.status == true
                  ? Icons.check_rounded
                  : Icons.priority_high_rounded,
              color: Colors.white,
              size: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    BuildContext context, {
    required bool success,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        success ? '成功' : '失败',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final values = <String>[
      if ((item.type ?? '').trim().isNotEmpty) item.type!.trim(),
      if ((item.category ?? '').trim().isNotEmpty) item.category!.trim(),
      if ((item.year ?? '').trim().isNotEmpty) item.year!.trim(),
    ];
    if (values.isEmpty) {
      return Text(
        '媒体信息未识别',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Text(
      values.join(' · '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildModeRow(BuildContext context) {
    final theme = Theme.of(context);
    final mode = _localizedMode(item.mode);
    final episode = _episodeLabel();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (mode.isNotEmpty)
          _buildCompactChip(
            context,
            icon: _modeIcon(item.mode),
            label: mode,
            color: theme.colorScheme.primary,
          ),
        if (episode.isNotEmpty)
          _buildCompactChip(
            context,
            icon: Icons.video_library_outlined,
            label: episode,
            color: theme.colorScheme.tertiary,
          ),
      ],
    );
  }

  Widget _buildCompactChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, {required bool success}) {
    final color = success
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        item.errmsg!.trim(),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: color, height: 1.3),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTransferFlow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          _buildPathRow(
            context,
            icon: Icons.file_open_outlined,
            label: srcStorageName.isEmpty ? '来源' : srcStorageName,
            path: item.src,
            color: colorScheme.secondary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Icon(
                  Icons.south_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          _buildPathRow(
            context,
            icon: Icons.folder_open_rounded,
            label: destStorageName.isEmpty ? '目标' : destStorageName,
            path: item.dest,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPathRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? path,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                (path ?? '').trim().isEmpty ? '-' : path!.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final fileCount = item.files.length;
    return Row(
      children: [
        Icon(Icons.storage_outlined, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          SizeFormatter.formatSize(item.src_fileitem?.size ?? 0),
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
        if (fileCount > 0) ...[
          const SizedBox(width: 10),
          Icon(Icons.file_copy_outlined, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$fileCount 个文件',
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
        const Spacer(),
        if ((item.date ?? '').trim().isNotEmpty) ...[
          Icon(Icons.schedule_rounded, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              item.date!.trim(),
              style: theme.textTheme.labelSmall?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '删除选项',
      borderRadius: BorderRadius.circular(12),
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onSelected: (value) {
        switch (value) {
          case 'record':
            onDeleteTransferRecordOnly?.call();
            break;
          case 'source':
            onDeleteTransferRecordAndSourceFile?.call();
            break;
          case 'library':
            onDeleteTransferRecordAndMediaLibraryFile?.call();
            break;
          case 'all':
            onDeleteTransferRecordAndSourceFileAndMediaLibraryFile?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        _buildMenuItem(
          context,
          value: 'record',
          label: '仅删除整理记录',
          icon: Icons.history_toggle_off_rounded,
          color: CupertinoColors.systemPurple,
        ),
        _buildMenuItem(
          context,
          value: 'source',
          label: '同时删除源文件',
          icon: Icons.file_open_outlined,
          color: CupertinoColors.systemOrange,
        ),
        _buildMenuItem(
          context,
          value: 'library',
          label: '同时删除媒体库文件',
          icon: Icons.video_library_outlined,
          color: CupertinoColors.systemCyan,
        ),
        _buildMenuItem(
          context,
          value: 'all',
          label: '删除记录及全部文件',
          icon: Icons.delete_forever_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
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

  IconData _modeIcon(String? mode) {
    final value = (mode ?? '').trim().toLowerCase();
    if (value == 'move') return Icons.drive_file_move_outline;
    if (value == 'copy') return Icons.file_copy_outlined;
    if (value.contains('link')) return Icons.link_rounded;
    return Icons.auto_mode_outlined;
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
