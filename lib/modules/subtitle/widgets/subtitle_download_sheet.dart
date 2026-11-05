import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/download/controllers/download_controller.dart';
import 'package:moviepilot_mobile/modules/downloader/models/downloader_stats.dart';
import 'package:moviepilot_mobile/modules/subtitle/controllers/subtitle_search_controller.dart';
import 'package:moviepilot_mobile/modules/subtitle/models/subtitle_search_models.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/widgets/bottom_sheet.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class SubtitleDownloadSheet extends GetView<DownloadController> {
  const SubtitleDownloadSheet({super.key, required this.item});

  final SubtitleSearchItem item;

  SubtitleSearchController get _subtitleController =>
      Get.find<SubtitleSearchController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final background = theme.scaffoldBackgroundColor;
    final backgroundAlt =
        Color.lerp(background, scheme.primary, isDark ? 0.04 : 0.02) ??
        background;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BottomSheetWidget(
        header: Builder(builder: _buildHeader),
        scrollController: controller.scrollController,
        snap: false,
        snapSizes: const [],
        initialChildSize: 0.64,
        minChildSize: 0.3,
        maxChildSize: 0.88,
        builder: (context, scrollController) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundAlt, background],
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            children: [
              _buildSummary(context),
              const SizedBox(height: 12),
              _buildSettings(context),
              const SizedBox(height: 16),
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Stack(
      children: [
        Positioned(
          top: -90,
          left: -70,
          child: Container(
            width: 220,
            height: 180,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  primary.withValues(alpha: 0.22),
                  primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -100,
          bottom: -100,
          child: Container(
            width: 240,
            height: 200,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.secondary.withValues(alpha: 0.14),
                  theme.colorScheme.secondary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.text_bubble_fill,
                        color: primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '下载字幕',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '选择下载器和保存位置',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = (item.title ?? '').trim().isEmpty ? '未命名字幕' : item.title!;
    final siteName = (item.siteName ?? '').trim();
    final language = (item.language ?? '').trim();
    final icon = (item.languageIcon ?? '').trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            thickness: 0.6,
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (siteName.isNotEmpty)
                _MetaItem(
                  icon: CupertinoIcons.globe,
                  text: siteName,
                ),
              if (language.isNotEmpty)
                _MetaItem(
                  iconWidget: icon.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: CachedImage(
                            imageUrl: icon,
                            width: 14,
                            height: 10,
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                  icon: CupertinoIcons.flag,
                  text: language,
                  tintColor: scheme.primary,
                ),
              if (item.size != null && item.size! > 0)
                _MetaItem(
                  icon: CupertinoIcons.doc,
                  text: SizeFormatter.formatSize(item.size, 1),
                  emphasize: true,
                ),
              if ((item.dateElapsed ?? '').trim().isNotEmpty)
                _MetaItem(
                  icon: CupertinoIcons.time,
                  text: item.dateElapsed!.trim(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                '下载设置',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(
            () => _SubsectionLabel(
              title: '下载器',
              value: controller.selectedDownloader.value?.name ?? '未选择',
            ),
          ),
          _buildDownloaderSelector(context),
          const SizedBox(height: 12),
          Obx(
            () => _SubsectionLabel(
              title: '保存目录',
              value: controller.selectedDirectory.value.isEmpty
                  ? '自动匹配'
                  : controller.selectedDirectory.value,
            ),
          ),
          _buildDirectorySelector(context),
        ],
      ),
    );
  }

  Widget _buildDownloaderSelector(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingDownloaders) {
        return const _Placeholder(label: '正在加载');
      }
      final downloaders = controller.downloaders;
      final selected = controller.selectedDownloader.value;
      if (downloaders.isEmpty) {
        return const _Placeholder(label: '暂无可用下载器');
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: downloaders.map((downloader) {
            final stats = controller.statsFor(downloader.name);
            final isSelected = selected?.name == downloader.name;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 188,
                height: 70,
                child: _ChoiceTile(
                  title: downloader.name,
                  subtitle: _downloaderSubtitle(downloader, stats),
                  isSelected: isSelected,
                  accentColor: Theme.of(context).colorScheme.primary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.setDownloader(downloader);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildDirectorySelector(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedDirectory.value;
      final suggestions = controller.directorySuggestions;
      final entries = <String>['', ...suggestions];
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: entries.map((dir) {
            final isAuto = dir.isEmpty;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: isAuto ? 116 : 164,
                height: 46,
                child: _ChoiceTile(
                  title: isAuto ? '自动匹配' : dir,
                  isSelected: selected == dir,
                  accentColor: Theme.of(context).colorScheme.secondary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.setDirectory(dir);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildBottomActions(BuildContext context) {
    return Obx(() {
      final enabled = controller.selectedDownloader.value != null;
      final busy = _subtitleController.downloadingKeys.contains(item.key);
      return SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: enabled && !busy
              ? () async {
                  HapticFeedback.mediumImpact();
                  final path = controller.selectedDirectory.value.trim();
                  final ok = await _subtitleController.downloadSubtitle(
                    item,
                    savePath: path.isEmpty ? null : path,
                  );
                  if (ok && context.mounted) {
                    Navigator.of(context).maybePop();
                  }
                }
              : null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download_rounded, size: 19),
          label: Text(
            busy ? '下载中' : '开始下载',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    });
  }

  String _downloaderSubtitle(dynamic downloader, DownloaderStats? stats) {
    if (stats != null && stats.freeSpace > 0) {
      return '剩余 ${SizeFormatter.formatSize(stats.freeSpace, 1)}';
    }
    return downloader.type.isNotEmpty ? downloader.type.toUpperCase() : '';
  }

  BoxDecoration _panelDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: theme.cardColor.withValues(alpha: isDark ? 0.92 : 0.98),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _outlineColor(context)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Color _outlineColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.7);
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.text,
    this.icon,
    this.iconWidget,
    this.emphasize = false,
    this.tintColor,
  });

  final String text;
  final IconData? icon;
  final Widget? iconWidget;
  final bool emphasize;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color =
        tintColor ?? (emphasize ? scheme.onSurface : scheme.onSurfaceVariant);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconWidget != null)
          iconWidget!
        else if (icon != null)
          Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surface = scheme.surfaceContainerHighest.withValues(
      alpha: isDark ? 0.42 : 0.72,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withValues(alpha: 0.12) : surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.28)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? accentColor : scheme.outline,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 11,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? accentColor : scheme.onSurface,
                      ),
                    ),
                    if ((subtitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
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
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.42 : 0.72,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.4 : 0.7,
          ),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
