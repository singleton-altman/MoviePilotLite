import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/download/controllers/download_controller.dart';
import 'package:moviepilot_mobile/modules/downloader/models/downloader_stats.dart';
import 'package:moviepilot_mobile/modules/search_result/models/search_result_models.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';

class DownloadSheet extends GetView<DownloadController> {
  const DownloadSheet({super.key, required this.item});

  final SearchResultItem item;

  AppService get _appService => Get.find<AppService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;
    final sheetSurface = _sheetSurface(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: DraggableScrollableSheet(
        controller: controller.scrollController,
        expand: false,
        snap: false,
        snapSizes: const [],
        initialChildSize: 0.7,
        minChildSize: 0.28,
        maxChildSize: 0.8,
        builder: (context, scrollController) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(
                      sheetSurface,
                      scheme.primary,
                      isDarkTheme(context) ? 0.05 : 0.02,
                    ) ??
                    sheetSurface,
                background,
              ],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Divider(height: 1, color: theme.dividerColor),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    _buildCompactSummary(context),
                    const SizedBox(height: 20),
                    _buildDownloadSettingsSection(context),
                    const SizedBox(height: 12),
                    _buildTmdbInput(context),
                  ],
                ),
              ),
              if (MediaQuery.viewInsetsOf(context).bottom == 0)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  decoration: BoxDecoration(
                    color: sheetSurface.withValues(alpha: 0.96),
                    border: Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.42),
                      ),
                    ),
                  ),
                  child: _buildBottomActions(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 14, 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(
                      alpha: isDarkTheme(context) ? 0.20 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    Icons.download_rounded,
                    color: scheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '下载资源',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '选择下载器和保存位置',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => Navigator.of(context).pop(),
                    child: Ink(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _controlSurface(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.42),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(
    BuildContext context, {
    required String label,
    required IconData icon,
    Color? foreground,
    Color? background,
    Color? borderColor,
    bool emphasized = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = foreground ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            background ??
            scheme.surfaceContainerHighest.withValues(
              alpha: isDarkTheme(context) ? 0.46 : 0.55,
            ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor ?? scheme.outlineVariant.withValues(alpha: 0.44),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionLabel(
    BuildContext context, {
    required String label,
    required String value,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedEntry(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.showAdvanced.value = true,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _panelSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hairlineColor(context)),
          ),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '高级选项 · 手动填写 TMDB ID',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTmdbEditor(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _hairlineColor(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TMDB ID',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                onPressed: () => controller.showAdvanced.value = false,
                child: Text(
                  '收起',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CupertinoTextField(
            controller: TextEditingController.fromValue(
              TextEditingValue(
                text: controller.tmdbId.value,
                selection: TextSelection.collapsed(
                  offset: controller.tmdbId.value.length,
                ),
              ),
            ),
            onChanged: controller.setTmdbId,
            keyboardType: TextInputType.number,
            placeholder: '输入 TMDB ID',
            style: TextStyle(color: scheme.onSurface),
            placeholderStyle: TextStyle(color: scheme.onSurfaceVariant),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            clearButtonMode: OverlayVisibilityMode.editing,
            decoration: BoxDecoration(
              color: _controlSurface(context),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummary(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final torrent = item.torrent_info;
    final title = torrent?.title?.trim() ?? '';
    final siteName = torrent?.site_name?.trim().isNotEmpty == true
        ? torrent!.site_name!.trim()
        : '未知站点';
    final size = torrent?.size ?? 0.0;
    final volumeFactor = _displayVolumeFactor(torrent);
    final downloadFactor = torrent?.downloadvolumefactor;
    final uploadFactor = torrent?.uploadvolumefactor;
    final sizeLabel = SizeFormatter.formatSize(size, 2);
    final trafficSummary = _buildTrafficSummary(
      volumeFactor: volumeFactor,
      downloadFactor: downloadFactor,
      uploadFactor: uploadFactor,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panelSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hairlineColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.28,
              ),
            ),
          if (title.isNotEmpty) const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryBadge(
                context,
                label: siteName,
                icon: CupertinoIcons.globe,
                foreground: scheme.primary,
                background: scheme.primary.withValues(alpha: 0.10),
                borderColor: scheme.primary.withValues(alpha: 0.22),
              ),
              _buildSummaryBadge(
                context,
                label: sizeLabel,
                icon: CupertinoIcons.tray_arrow_down,
                foreground: scheme.onSurface,
                emphasized: true,
              ),
              if (trafficSummary.isNotEmpty)
                _buildSummaryBadge(
                  context,
                  label: trafficSummary,
                  icon: CupertinoIcons.arrow_up_arrow_down_circle,
                  foreground: scheme.secondary,
                  background: scheme.secondary.withValues(alpha: 0.10),
                  borderColor: scheme.secondary.withValues(alpha: 0.22),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSettingsSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panelSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hairlineColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, icon: Icons.tune_rounded, title: '下载设置'),
          const SizedBox(height: 18),
          Obx(
            () => _buildSelectionLabel(
              context,
              label: '下载器',
              value: controller.selectedDownloader.value?.name ?? '未选择',
              accentColor: scheme.primary,
            ),
          ),
          _buildDownloaderSelector(context),
          const SizedBox(height: 22),
          Obx(
            () => _buildSelectionLabel(
              context,
              label: '保存目录',
              value: controller.selectedDirectory.value.isEmpty
                  ? '自动匹配'
                  : controller.selectedDirectory.value,
              accentColor: scheme.secondary,
            ),
          ),
          _buildDirectorySelector(context),
          DownloadPathPicker(
            apiClient: Get.find<ApiClient>(),
            selectedPath: controller.selectedDirectory,
            onSelected: controller.setDirectory,
            requestScope: () => controller.directoryPreferenceScope,
            onPathsLoaded: (paths, scope) =>
                controller.setAvailableDownloadPaths(
                  paths.map((path) => path.savePath),
                  scope: scope,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloaderSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      if (controller.isLoadingDownloaders) {
        return _buildPlaceholderState(context, label: '正在加载下载器');
      }

      final downloaders = controller.downloaders;
      final selected = controller.selectedDownloader.value;

      if (downloaders.isEmpty) {
        return _buildPlaceholderState(context, label: '暂无可用下载器');
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: downloaders.map((downloader) {
            final stats = controller.statsFor(downloader.name);
            final isSelected = selected?.name == downloader.name;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _simpleChoiceChip(
                context,
                label: downloader.name,
                detail: _downloaderDetail(stats),
                selected: isSelected,
                accent: scheme.primary,
                icon: Icons.dns_rounded,
                onTap: () => controller.setDownloader(downloader),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildDirectorySelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final selected = controller.selectedDirectory.value;
      final suggestions = controller.directorySuggestions;
      final entries = <String>['', ...suggestions];

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: entries.map((dir) {
            final isAuto = dir.isEmpty;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _simpleChoiceChip(
                context,
                label: isAuto ? '自动匹配' : _pathLeaf(dir),
                tooltip: isAuto ? '按媒体类型匹配' : dir,
                selected: selected == dir,
                accent: scheme.secondary,
                icon: isAuto
                    ? Icons.auto_awesome_rounded
                    : Icons.folder_rounded,
                onTap: () => controller.setDirectory(dir),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildTmdbInput(BuildContext context) {
    return Obx(() {
      return controller.showAdvanced.value
          ? _buildTmdbEditor(context)
          : _buildAdvancedEntry(context);
    });
  }

  Widget _buildBottomActions(BuildContext context) {
    return Obx(() {
      final showSpecial = _appService.enableSpecialDownload.value;
      final enabled = controller.selectedDownloader.value != null;
      final tmdbId = controller.tmdbId.value.isEmpty
          ? null
          : controller.tmdbId.value;

      if (!showSpecial) {
        return _buildPrimaryButton(
          context,
          label: '开始下载',
          busy: controller.isDownloading.value,
          enabled: enabled,
          onTap: () =>
              controller.startDownload(item: item, customTmdbId: tmdbId),
        );
      }

      return Row(
        children: [
          Expanded(
            child: _buildSecondaryButton(
              context,
              label: '直连下载',
              busy: controller.isSpecialDownloading.value,
              enabled: enabled,
              onTap: () =>
                  controller.startSpecialDownload(context: context, item: item),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildPrimaryButton(
              context,
              label: '开始下载',
              busy: controller.isDownloading.value,
              enabled: enabled,
              onTap: () =>
                  controller.startDownload(item: item, customTmdbId: tmdbId),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPrimaryButton(
    BuildContext context, {
    required String label,
    required bool busy,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = enabled && !busy;
    final background = active ? scheme.primary : scheme.outlineVariant;
    final foreground = active
        ? scheme.onPrimary
        : scheme.onSurfaceVariant.withValues(alpha: 0.62);

    return Semantics(
      button: true,
      enabled: active,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: active ? onTap : null,
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(Icons.download_rounded, size: 19, color: foreground),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context, {
    required String label,
    required bool busy,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: enabled && !busy ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.secondary,
          side: BorderSide(
            color: theme.colorScheme.secondary.withValues(
              alpha: enabled ? 0.72 : 0.20,
            ),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: enabled
              ? theme.colorScheme.secondary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        icon: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.secondary,
                ),
              )
            : const Icon(Icons.link_rounded, size: 19),
        label: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderState(BuildContext context, {required String label}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _controlSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _hairlineColor(context)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String? _downloaderDetail(DownloaderStats? stats) {
    if (stats != null && stats.freeSpace > 0) {
      return SizeFormatter.formatSize(stats.freeSpace, 1);
    }
    return null;
  }

  Color _controlSurface(BuildContext context) {
    final theme = Theme.of(context);
    return theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.44 : 0.58,
    );
  }

  bool isDarkTheme(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _sheetSurface(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? const Color(0xFF131B2E) : theme.scaffoldBackgroundColor;
  }

  Color _panelSurface(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E293B) : theme.cardColor;
  }

  Color _hairlineColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.outlineVariant.withValues(
      alpha: isDarkTheme(context) ? 0.30 : 0.54,
    );
  }

  String _displayVolumeFactor(SearchTorrentInfo? torrent) {
    if (torrent == null) return '';
    final volumeFactor = torrent.volume_factor?.trim() ?? '';
    final downloadFactor = torrent.downloadvolumefactor;
    if (volumeFactor.isEmpty) return '';
    if (downloadFactor != null && downloadFactor != 1) {
      return '';
    }
    return volumeFactor;
  }

  String _buildTrafficSummary({
    required String volumeFactor,
    required double? downloadFactor,
    required double? uploadFactor,
  }) {
    final parts = <String>[];
    if (volumeFactor.isNotEmpty) {
      parts.add(volumeFactor);
    }
    if (downloadFactor != null && downloadFactor != 1) {
      parts.add(
        downloadFactor == 0 ? '下载免费' : '下载 ${(downloadFactor * 100).round()}%',
      );
    }
    if (uploadFactor != null && uploadFactor != 1) {
      parts.add('上传 ${(uploadFactor * 100).round()}%');
    }
    return parts.join('  /  ');
  }
}

String _pathLeaf(String path) {
  final parts = path
      .split(RegExp(r'[\\/]+'))
      .where((part) => part.trim().isNotEmpty);
  if (parts.isEmpty) return path;
  return parts.last;
}

String _choiceLabel(String label, String path) {
  final trimmed = label.trim();
  final normalizedPath = path.trim();
  final looksLikePath =
      trimmed == normalizedPath ||
      trimmed.contains('/') ||
      trimmed.contains('\\');
  return looksLikePath ? _pathLeaf(trimmed) : trimmed;
}

Widget _simpleChoiceChip(
  BuildContext context, {
  required String label,
  required bool selected,
  required Color accent,
  required VoidCallback onTap,
  IconData? icon,
  String? detail,
  String? tooltip,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  final foreground = selected ? scheme.onPrimary : scheme.onSurface;
  final metaColor = selected
      ? scheme.onPrimary.withValues(alpha: 0.76)
      : scheme.onSurfaceVariant;
  final meta = detail?.trim() ?? '';
  final chip = Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? accent
                : (isDark ? const Color(0xFF243044) : const Color(0xFFF3F5F8)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent
                  : scheme.outlineVariant.withValues(
                      alpha: isDark ? 0.46 : 0.72,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? scheme.onPrimary : accent,
                ),
                const SizedBox(width: 7),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 156),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              if (meta.isNotEmpty) ...[
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: metaColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  meta,
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: metaColor,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  final message = tooltip?.trim() ?? '';
  if (message.isEmpty || message == label) return chip;
  return Tooltip(message: message, child: chip);
}

/// A server-provided save_path is opaque: preserve storage URI and directory name.
class DownloadPathOption {
  const DownloadPathOption({required this.label, required this.savePath});
  final String label;
  final String savePath;

  static List<DownloadPathOption> parse(dynamic raw) {
    dynamic data = raw is String ? jsonDecode(raw) : raw;
    if (data is Map) {
      if (data['success'] == false) throw StateError('获取下载路径失败');
      data = data['data'];
    }
    if (data is! List) throw const FormatException('下载路径响应无效');
    final seen = <String>{};
    final result = <DownloadPathOption>[];
    for (final entry in data.whereType<Map>()) {
      var path = entry['save_path'];
      final storage = entry['storage'];
      if ((path is! String || path.trim().isEmpty) &&
          (storage == null || storage == 'local')) {
        path = entry['download_path'];
      }
      if (path is! String || path.trim().isEmpty || !seen.add(path)) continue;
      final name = entry['name'];
      result.add(
        DownloadPathOption(
          label: name is String && name.trim().isNotEmpty ? name : path,
          savePath: path,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}

class DownloadPathService {
  DownloadPathService(this.apiClient);
  final ApiClient apiClient;

  Future<List<DownloadPathOption>> load() async {
    final response = await apiClient.get<dynamic>('/api/v1/download/paths');
    if (response.statusCode != 200) {
      throw ApiHttpException(response.statusCode ?? 0, '获取下载路径失败');
    }
    return DownloadPathOption.parse(response.data);
  }
}

/// Optional picker: never changes automatic matching or existing selections on load.
class DownloadPathPicker extends StatefulWidget {
  const DownloadPathPicker({
    super.key,
    required this.apiClient,
    required this.selectedPath,
    required this.onSelected,
    this.requestScope,
    this.onPathsLoaded,
  });

  final ApiClient apiClient;
  final RxString selectedPath;
  final ValueChanged<String> onSelected;

  /// 当前服务器/用户作用域,加载前捕获,避免切服后旧响应污染新作用域。
  final String Function()? requestScope;

  /// 仅在 /download/paths 成功返回后回调,控制器据此恢复远程目录。
  final void Function(List<DownloadPathOption> paths, String scope)?
  onPathsLoaded;

  @override
  State<DownloadPathPicker> createState() => _DownloadPathPickerState();
}

class _DownloadPathPickerState extends State<DownloadPathPicker> {
  List<DownloadPathOption> _paths = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final scope = widget.requestScope?.call() ?? '';
    try {
      final paths = await DownloadPathService(widget.apiClient).load();
      if (!mounted) return;
      setState(() => _paths = paths);
      widget.onPathsLoaded?.call(paths, scope);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: LinearProgressIndicator(
          minHeight: 3,
          borderRadius: BorderRadius.circular(999),
          backgroundColor: scheme.outlineVariant.withValues(alpha: 0.26),
        ),
      );
    }
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: scheme.error.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 16, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '服务器路径加载失败，可继续自动匹配',
                  maxLines: 2,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    height: 1.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: _load,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  foregroundColor: scheme.error,
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (_paths.isEmpty) return const SizedBox.shrink();
    return Obx(() {
      final selected = widget.selectedPath.value;
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paths
              .map(
                (path) => _simpleChoiceChip(
                  context,
                  label: _choiceLabel(path.label, path.savePath),
                  tooltip: path.savePath,
                  selected: selected == path.savePath,
                  accent: scheme.secondary,
                  icon: Icons.folder_rounded,
                  onTap: () => widget.onSelected(
                    selected == path.savePath ? '' : path.savePath,
                  ),
                ),
              )
              .toList(),
        ),
      );
    });
  }
}
