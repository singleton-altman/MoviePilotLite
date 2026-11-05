import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/subtitle_manual_upload_form_controller.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_enums.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_field_state.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_form_manager.dart';
import 'package:moviepilot_mobile/modules/settings/state/settings_form_row_builder.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

void registerSubtitleManualUploadRenderer() {
  PluginFormAdapterRegistry.registerRenderer('SubtitleManualUpload', (
    context,
    blocks,
    controller,
    formMode,
    buildBlock,
  ) {
    final adapter = controller.pluginAdapter;
    if (adapter is! SubtitleManualUploadFormController) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: blocks.map((block) => buildBlock(context, block)).toList(),
      );
    }
    return SubtitleManualUploadRenderer(
      controller: adapter,
      formMode: formMode,
    );
  });
}

class SubtitleManualUploadRenderer extends StatelessWidget {
  const SubtitleManualUploadRenderer({
    super.key,
    required this.controller,
    required this.formMode,
  });

  final SubtitleManualUploadFormController controller;
  final bool formMode;

  @override
  Widget build(BuildContext context) {
    return formMode
        ? _SubtitleConfigView(controller: controller)
        : _SubtitlePageView(controller: controller);
  }
}

class _SubtitlePageView extends StatelessWidget {
  const _SubtitlePageView({required this.controller});

  final SubtitleManualUploadFormController controller;

  static const double _listBottomSpacer = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _ResourceSearchFloatingBar(controller: controller),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, _listBottomSpacer),
          children: [
            _FeedbackBanner(controller: controller),
            _StatusSection(controller: controller),
            const SizedBox(height: 12),
            _QuickActions(controller: controller),
            const SizedBox(height: 12),
            _MediaResults(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _ResourceSearchFloatingBar extends StatelessWidget {
  const _ResourceSearchFloatingBar({required this.controller});

  final SubtitleManualUploadFormController controller;

  static const double _barHeight = 52;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final searching = controller.mediaSearching.value;
      final child = searching
          ? _buildSearchingIndicator(context)
          : Row(
              children: [
                _buildFilterButton(context),
                const SizedBox(width: 8),
                Expanded(child: _buildFakeSearchBar(context)),
                const SizedBox(width: 8),
                _buildSortButton(context),
              ],
            );
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                height: _barHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSearchingIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: CupertinoDynamicColor.resolve(Colors.white, context),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '搜索中…',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return Obx(() {
      final has = controller.hasActiveMediaFilters;
      final color = has
          ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
          : CupertinoDynamicColor.resolve(Colors.white, context);
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: controller.mediaSearching.value
            ? null
            : () => _openMediaFilterSheet(context, controller),
        child: Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: color),
      );
    });
  }

  Widget _buildSortButton(BuildContext context) {
    return Obx(
      () => SortPullDownWidget<SubtitleMediaSortKey>(
        isAscending: controller.mediaSortAscending.value,
        currentValue: controller.mediaSortKey.value,
        options: SubtitleMediaSortKey.values,
        labelBuilder: _mediaSortLabel,
        onDirectionChanged: (asc) {
          final wantAsc = asc;
          if (controller.mediaSortAscending.value != wantAsc) {
            controller.toggleMediaSortDirection();
          }
        },
        onValueChanged: controller.updateMediaSortKey,
      ),
    );
  }

  Widget _buildFakeSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: controller.mediaSearching.value
          ? null
          : () => _openMediaKeywordSheet(context, controller),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 18,
              color: CupertinoDynamicColor.resolve(Colors.white, context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => Text(
                  controller.searchKeyword.value.isEmpty
                      ? '搜索本地资源'
                      : controller.searchKeyword.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _mediaSortLabel(SubtitleMediaSortKey key) {
  switch (key) {
    case SubtitleMediaSortKey.defaultSort:
      return '默认';
    case SubtitleMediaSortKey.title:
      return '标题';
    case SubtitleMediaSortKey.year:
      return '年份';
  }
}

Future<void> _openMediaKeywordSheet(
  BuildContext context,
  SubtitleManualUploadFormController controller,
) async {
  final textController = TextEditingController(
    text: controller.searchKeyword.value,
  );
  final submitted = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final insets = MediaQuery.of(ctx).viewInsets;
      return Padding(
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemBackground,
              ctx,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: CupertinoSearchTextField(
            controller: textController,
            autofocus: true,
            placeholder: '搜索本地资源',
            onSubmitted: (value) => Navigator.of(ctx).pop(value),
          ),
        ),
      );
    },
  );
  textController.dispose();
  if (submitted == null) return;
  controller.updateMediaKeyword(submitted);
}

Future<void> _openMediaFilterSheet(
  BuildContext context,
  SubtitleManualUploadFormController controller,
) async {
  final selected = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          color: theme.colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '资源类型',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                for (final entry in const [
                  ('all', '全部'),
                  ('movie', '电影'),
                  ('tv', '剧集'),
                ])
                  ListTile(
                    title: Text(entry.$2),
                    trailing: controller.mediaType.value == entry.$1
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(entry.$1),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
  if (selected == null) return;
  controller.updateMediaType(selected);
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = controller.status.value['enabled'] == true;
      final colors = Theme.of(context).colorScheme;
      return _Panel(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.subtitles_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            _StatusDot(label: enabled ? '运行中' : '未启用', active: enabled),
          ],
        ),
      );
    });
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.history,
            label: '匹配历史',
            onTap: () {
              _push(
                context,
                '匹配历史',
                (_) => _HistoryPanelLoader(controller: controller),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            icon: Icons.queue,
            label: '自动队列',
            onTap: () {
              _push(
                context,
                '自动入库队列',
                (_) => _AutoQueuePanelLoader(controller: controller),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final error = controller.errorText.value;
      final message = controller.messageText.value;
      if (error == null && message == null) return const SizedBox.shrink();
      final isError = error != null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _Panel(
          color: isError
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            isError ? error : message!,
            style: TextStyle(
              color: isError
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    });
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.status.value;
      final index =
          SubtitleManualUploadFormController.asMap(status['index']) ?? {};
      final archive =
          SubtitleManualUploadFormController.asMap(status['archive_support']) ??
          {};
      final timeline =
          SubtitleManualUploadFormController.asMap(status['timeline_fixer']) ??
          {};
      final ai =
          SubtitleManualUploadFormController.asMap(status['ai_subtitle']) ?? {};
      final enabled = status['enabled'] == true;
      final indexReady = index['ready'] == true;
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final mediaCount = index['media_count'] ?? 0;
      final videoCount = index['entry_count'] ?? 0;

      return Section(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        header: const SectionHeader(title: '运行概览'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: _StatusLed(active: enabled),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                      children: [
                        TextSpan(
                          text: enabled ? '已启用' : '未启用',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  ',
                          style: TextStyle(color: scheme.outline),
                        ),
                        TextSpan(
                          text: '$mediaCount',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' 媒体  ·  ',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        TextSpan(
                          text: '$videoCount',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' 视频',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        if (!indexReady) ...[
                          TextSpan(
                            text: '  ·  ',
                            style: TextStyle(color: scheme.outline),
                          ),
                          TextSpan(
                            text: '索引更新中',
                            style: TextStyle(
                              color: scheme.tertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!indexReady)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.tertiary,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _CapChip(
                    label: 'RAR',
                    ready: archive['rar'] == true,
                  ),
                ),
                Expanded(
                  child: _CapChip(
                    label: '调轴',
                    ready: timeline['available'] == true,
                  ),
                ),
                Expanded(
                  child: _CapChip(
                    label: 'AI',
                    ready: ai['available'] == true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _StatusLed extends StatelessWidget {
  const _StatusLed({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.outline;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}

class _CapChip extends StatelessWidget {
  const _CapChip({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = ready ? scheme.onSurface : scheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ready ? Icons.check_rounded : Icons.close_rounded,
          size: 13,
          color: ready ? scheme.primary : scheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _MediaResults extends StatelessWidget {
  const _MediaResults({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final medias = controller.visibleMedias;
      final hasMore = controller.mediaHasMore.value;
      final total = controller.mediaTotal.value;
      final keyword = controller.searchKeyword.value.trim();
      final typeLabel = switch (controller.mediaType.value) {
        'movie' => '电影',
        'tv' => '剧集',
        _ => '全部',
      };
      final subtitle = keyword.isEmpty
          ? '本地媒体库 · $typeLabel'
          : '「$keyword」· $typeLabel';

      if (medias.isEmpty && !controller.mediaSearching.value) {
        return Section(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(12),
          header: SectionHeader(title: '搜索资源', subtitle: subtitle),
          child: const _EmptyPanel(text: '暂无资源，刷新清单或输入关键词试试'),
        );
      }

      return Section(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        header: SectionHeader(
          title: '搜索资源',
          subtitle: medias.isEmpty ? subtitle : '$subtitle · $total 个结果',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.hasActiveMediaFilters || keyword.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (keyword.isNotEmpty)
                      _MetaChip(label: '关键词: $keyword'),
                    if (controller.hasActiveMediaFilters)
                      _MetaChip(label: '类型: $typeLabel'),
                  ],
                ),
              ),
            if (controller.mediaSearching.value && medias.isEmpty)
              const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              for (final media in medias)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MediaListCard(
                    media: media,
                    onTap: () {
                      _push(
                        context,
                        controller.mediaLabel(media),
                        (_) => _TargetDetailLoader(
                          controller: controller,
                          media: media,
                        ),
                      ).then((_) => controller.resetSelection());
                    },
                  ),
                ),
            if (medias.isNotEmpty)
              LoadMoreFooter(
                hasMore: hasMore,
                total: total,
                isLoading:
                    controller.mediaSearching.value && medias.isNotEmpty,
                onLoadMore: controller.loadMoreMedia,
              ),
          ],
        ),
      );
    });
  }
}

class _MediaListCard extends StatelessWidget {
  const _MediaListCard({
    required this.media,
    required this.onTap,
  });

  final Map<String, dynamic> media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isTv = _isTvMedia(media);
    final title = _mediaDisplayTitle(media);
    final year = _mediaYearText(media);
    final stats = _mediaStats(media);

    return _ListCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MediaListPoster(
              url: _mediaPoster(media),
              isTv: isTv,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.28,
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (year != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      year,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: stats,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaListPoster extends StatelessWidget {
  const _MediaListPoster({required this.url, required this.isTv});

  final String url;
  final bool isTv;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _Poster(url: url, isTv: isTv, width: 72, height: 102),
          Positioned(
            left: 5,
            bottom: 5,
            child: _MediaPosterTypeTag(isTv: isTv),
          ),
        ],
      ),
    );
  }
}

class _MediaPosterTypeTag extends StatelessWidget {
  const _MediaPosterTypeTag({required this.isTv});

  final bool isTv;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          isTv ? '剧集' : '电影',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _MediaStatChip extends StatelessWidget {
  const _MediaStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: scheme.primary.withValues(alpha: 0.88),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetDetail extends StatelessWidget {
  const _TargetDetail({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final media = controller.selectedMedia.value;
      final targetCount = controller.targets.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FeedbackBanner(controller: controller),
          _TargetSummaryPanel(controller: controller, media: media),
          const SizedBox(height: 12),
          _SectionHeader(
            title: '视频目标',
            trailing: targetCount == 0 ? null : '$targetCount 个',
          ),
          const SizedBox(height: 12),
          if (controller.busy.value && controller.targets.isEmpty)
            const _LoadingPanel(text: '正在读取本地视频目标')
          else if (controller.targets.isEmpty)
            const _EmptyPanel(text: '没有可写入目标')
          else
            for (final target in controller.targets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TargetCard(controller: controller, target: target),
              ),
        ],
      );
    });
  }
}

class _TargetSummaryPanel extends StatelessWidget {
  const _TargetSummaryPanel({required this.controller, required this.media});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic>? media;

  @override
  Widget build(BuildContext context) {
    final selectedCount = controller.selectedTargetIds.length;
    final targetCount = controller.targets.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.mediaLabel(media),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCount == 0
                          ? '$targetCount 个视频目标'
                          : '已选择 $selectedCount / $targetCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (controller.seasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SeasonPill(
                    label: '全部',
                    selected: controller.selectedSeason.value == 'all',
                    onTap: () => controller.changeSeason('all'),
                  ),
                  for (final season in controller.seasons)
                    _SeasonPill(
                      label: _seasonLabel(season),
                      selected:
                          controller.selectedSeason.value ==
                          '${season['value'] ?? season['season']}',
                      onTap: () => controller.changeSeason(
                        '${season['value'] ?? season['season']}',
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          _TargetSummaryActions(
            controller: controller,
            onUpload: () {
              controller.openBatchUpload();
              _push(
                context,
                controller.uploadTitle.value,
                (_) => _UploadPanel(controller: controller),
              );
            },
            onOnline: () {
              _pushOnlineSheet(
                context,
                controller,
                start: controller.openBatchOnlineSearch,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TargetSummaryActions extends StatelessWidget {
  const _TargetSummaryActions({
    required this.controller,
    required this.onUpload,
    required this.onOnline,
  });

  final SubtitleManualUploadFormController controller;
  final VoidCallback onUpload;
  final VoidCallback onOnline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TargetDirectActionButton(
                icon: Icons.travel_explore,
                label: '在线搜索',
                primary: true,
                onTap: onOnline,
              ),
            ),
            const SizedBox(width: 8),
            _TargetMoreMenuButton(controller: controller, onUpload: onUpload),
          ],
        ),
      ],
    );
  }
}

class _TargetDetailLoader extends StatefulWidget {
  const _TargetDetailLoader({required this.controller, required this.media});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> media;

  @override
  State<_TargetDetailLoader> createState() => _TargetDetailLoaderState();
}

class _TargetDetailLoaderState extends State<_TargetDetailLoader> {
  @override
  void initState() {
    super.initState();
    widget.controller.selectedMedia.value = widget.media;
    widget.controller.clearTargetState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.loadTargets(media: widget.media, season: 'all');
    });
  }

  @override
  Widget build(BuildContext context) {
    return _TargetDetail(controller: widget.controller);
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.controller, required this.target});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> target;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = '${target['id'] ?? ''}';
      final selected = controller.selectedTargetIds.contains(id);
      final expanded = controller.expandedTargetIds.contains(id);
      final disabled = controller.isTargetActionDisabled(target);
      final subtitles = SubtitleManualUploadFormController.asMapList(
        target['subtitles'],
      );
      final colors = Theme.of(context).colorScheme;
      final theme = Theme.of(context);
      final path = _targetPath(target);
      final sizeText = '${target['size_text'] ?? ''}'.trim();
      final pathLine = [
        if (path.isNotEmpty) path,
        if (sizeText.isNotEmpty) sizeText,
      ].join(' · ');

      return _ListCard(
        selected: selected,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => controller.toggleExpandedTarget(id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 2, 2, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TargetSelectMark(
                          selected: selected,
                          onTap: () => controller.toggleTarget(id, !selected),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      controller.compactTargetName(target),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            height: 1.25,
                                          ),
                                    ),
                                  ),
                                  if (subtitles.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${subtitles.length}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                  Icon(
                                    expanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              if (pathLine.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  pathLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                              if (target['writable'] == false) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '不可写',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.error,
                                    fontWeight: FontWeight.w500,
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
              ),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Row(
                  children: [
                    Expanded(
                      child: _TargetDirectActionButton(
                        icon: Icons.travel_explore,
                        label: '在线字幕',
                        primary: true,
                        compact: true,
                        enabled: !disabled,
                        onTap: () {
                          _pushOnlineSheet(
                            context,
                            controller,
                            start: () =>
                                controller.openSingleOnlineSearch(target),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: _TargetDirectActionButton(
                        icon: Icons.upload_file,
                        label: '上传',
                        compact: true,
                        enabled: !disabled,
                        onTap: () {
                          controller.openSingleUpload(target);
                          _push(
                            context,
                            controller.uploadTitle.value,
                            (_) => _UploadPanel(controller: controller),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (expanded || subtitles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: colors.outline.withValues(alpha: 0.2),
                ),
                if (subtitles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
                    child: Text(
                      '暂无外挂字幕',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final subtitle in subtitles)
                    _SubtitleRow(
                      controller: controller,
                      target: target,
                      subtitle: subtitle,
                    ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _TargetSelectMark extends StatelessWidget {
  const _TargetSelectMark({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          size: 20,
          color: selected ? colors.primary : colors.outline,
        ),
      ),
    );
  }
}

class _TargetDirectActionButton extends StatelessWidget {
  const _TargetDirectActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.compact = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fg = colors.primary;
    final bg = colors.surfaceContainerHighest.withValues(
      alpha: primary ? 0.42 : 0.28,
    );
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: _TargetMenuButtonSurface(
        icon: icon,
        label: label,
        foreground: enabled ? fg : theme.disabledColor.withValues(alpha: 0.70),
        background: enabled
            ? bg
            : colors.surfaceContainerHighest.withValues(alpha: 0.20),
        borderColor: enabled
            ? colors.primary.withValues(alpha: primary ? 0.28 : 0.16)
            : colors.outlineVariant.withValues(alpha: 0.42),
        minHeight: compact ? 38 : 42,
        textStyle:
            (compact ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)
                ?.copyWith(
                  color: enabled
                      ? fg
                      : theme.disabledColor.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
      ),
    );
  }
}

class _TargetMoreMenuButton extends StatelessWidget {
  const _TargetMoreMenuButton({
    required this.controller,
    required this.onUpload,
  });

  final SubtitleManualUploadFormController controller;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PopupMenuButton<String>(
      tooltip: '更多操作',
      onSelected: (value) {
        switch (value) {
          case 'upload':
            onUpload();
            break;
          case 'ai':
            _confirmAction(
              context,
              title: 'AI',
              onConfirm: () async => controller.submitAiForTargets(),
            );
            break;
          case 'timeline':
            _confirmAction(
              context,
              title: '调轴',
              onConfirm: () async => controller.fixTimelineForTargets(),
            );
            break;
          case 'clear':
            _confirmAction(
              context,
              title: '清空',
              destructive: true,
              onConfirm: () async => controller.clearSelectedSubtitles(),
            );
            break;
          case 'cancel_ai':
            _confirmAction(
              context,
              title: '取消 AI',
              onConfirm: () async => controller.cancelAiForTargets(),
            );
            break;
          case 'select_all':
            controller.toggleSelectAll();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'upload',
          child: ListTile(
            leading: Icon(Icons.upload_file),
            title: Text('上传文件'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'ai',
          enabled: controller.aiAvailable,
          child: const ListTile(
            leading: Icon(Icons.auto_awesome),
            title: Text('AI 生成'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'timeline',
          enabled: controller.timelineAvailable,
          child: const ListTile(
            leading: Icon(Icons.graphic_eq),
            title: Text('智能调轴'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'select_all',
          child: ListTile(
            leading: Icon(Icons.select_all),
            title: Text('全选'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'cancel_ai',
          child: ListTile(
            leading: Icon(Icons.cancel_outlined),
            title: Text('取消 AI'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'clear',
          child: ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: colors.error),
            title: Text('清空字幕', style: TextStyle(color: colors.error)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: SizedBox(
        width: 116,
        child: _TargetMenuButtonSurface(
          icon: Icons.more_horiz,
          label: '更多',
          foreground: colors.onSurfaceVariant,
          background: colors.surfaceContainerHighest.withValues(alpha: 0.22),
          borderColor: colors.outlineVariant.withValues(alpha: 0.62),
          minHeight: 42,
          textStyle: theme.textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TargetMenuButtonSurface extends StatelessWidget {
  const _TargetMenuButtonSurface({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.borderColor,
    required this.minHeight,
    this.textStyle,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final double minHeight;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.matchHistoryItems.isEmpty) {
        return const _EmptyPanel(text: '暂无匹配历史');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: '已有外挂字幕',
            trailing: '${controller.matchHistoryTotal.value} 条',
          ),
          const SizedBox(height: 8),
          for (final item in controller.matchHistoryItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _HistoryCard(controller: controller, item: item),
            ),
          LoadMoreFooter(
            hasMore: controller.matchHistoryHasMore.value,
            hasItems: controller.matchHistoryItems.isNotEmpty,
            total: controller.matchHistoryTotal.value,
            isLoading: controller.matchHistoryLoading.value,
            onLoadMore: controller.loadMoreMatchHistory,
          ),
        ],
      );
    });
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.controller, required this.item});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = '${item['id'] ?? item['title'] ?? ''}';
      final expanded = controller.expandedHistoryIds.contains(id);
      final targets = SubtitleManualUploadFormController.asMapList(
        item['targets'],
      );
      return _ListCard(
        child: Column(
          children: [
            ListTile(
              leading: _Poster(url: _mediaPoster(item)),
              title: Text(
                controller.mediaLabel(item),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('${targets.length} 个目标有外挂字幕'),
              trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              onTap: () => controller.toggleHistoryExpanded(id),
            ),
            if (expanded) const Divider(height: 1),
            if (expanded)
              for (final target in targets)
                ListTile(
                  dense: true,
                  title: Text(
                    controller.compactTargetName(target),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${SubtitleManualUploadFormController.asMapList(target['subtitles']).length} 个字幕',
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: '在线搜索',
                        onPressed: () {
                          _pushOnlineSheet(
                            context,
                            controller,
                            start: () =>
                                controller.openSingleOnlineSearch(target),
                          );
                        },
                        icon: const Icon(Icons.travel_explore),
                      ),
                      IconButton(
                        tooltip: '调轴',
                        onPressed: controller.timelineAvailable
                            ? () => _confirmAction(
                                context,
                                title: '历史字幕调轴',
                                onConfirm: () =>
                                    controller.fixExistingTimeline([
                                      {'target_id': target['id']},
                                    ], '历史字幕'),
                              )
                            : null,
                        icon: const Icon(Icons.graphic_eq),
                      ),
                      IconButton(
                        tooltip: '删除外挂字幕',
                        onPressed: () => _confirmAction(
                          context,
                          title: '删除外挂字幕',
                          message: '此操作会删除该目标的外挂字幕，是否继续？',
                          destructive: true,
                          onConfirm: () =>
                              controller.clearHistoryTarget(target),
                        ),
                        icon: const Icon(Icons.delete_sweep_outlined),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      );
    });
  }
}

class _HistoryPanelLoader extends StatefulWidget {
  const _HistoryPanelLoader({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  State<_HistoryPanelLoader> createState() => _HistoryPanelLoaderState();
}

class _HistoryPanelLoaderState extends State<_HistoryPanelLoader> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.loadMatchHistory(reset: true);
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && widget.controller.matchHistoryItems.isEmpty) {
      return const _LoadingPanel(text: '正在读取匹配历史');
    }
    return _HistoryPanel(controller: widget.controller);
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = controller.uploadPreview.value;
      final items = preview == null
          ? <Map<String, dynamic>>[]
          : SubtitleManualUploadFormController.asMapList(preview['items']);
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelTitle(
              title: controller.uploadTitle.value,
              icon: Icons.upload_file,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: controller.preparing.value
                      ? null
                      : controller.pickUploadFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('选择字幕/压缩包'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.pickedFiles.isEmpty
                      ? null
                      : controller.prepareUpload,
                  icon: const Icon(Icons.preview),
                  label: const Text('重新预览'),
                ),
              ],
            ),
            if (controller.pickedFiles.isEmpty && items.isEmpty) ...[
              const SizedBox(height: 12),
              const _InlineHint(
                icon: Icons.attach_file,
                text: '选择字幕文件或压缩包后，会先生成可确认的写入预览。',
              ),
            ],
            if (controller.pickedFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final file in controller.pickedFiles)
                _PickedFileRow(
                  file: file,
                  onRemove: () => controller.removePickedFile(file),
                ),
            ],
            if (items.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: _fieldDecoration(
                        context,
                        label: '批量语言后缀',
                        dense: true,
                      ),
                      onChanged: (value) =>
                          controller.batchLanguageSuffix.value = value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: controller.applyBatchLanguageSuffix,
                    child: const Text('应用'),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: controller.fixTimeline.value,
                onChanged: controller.timelineAvailable
                    ? (value) => controller.fixTimeline.value = value
                    : null,
                title: const Text('写入后智能调轴'),
                subtitle: Text(
                  controller.timelineAvailable ? '流媒体目标会自动跳过' : '调轴依赖不可用',
                ),
              ),
              for (final item in items)
                _PreviewItem(controller: controller, item: item),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: controller.applying.value
                      ? null
                      : () async {
                          await controller.applyUpload();
                          if (!context.mounted ||
                              controller.uploadPreview.value != null) {
                            return;
                          }
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                  icon: controller.applying.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.done),
                  label: const Text('确认写入'),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({required this.controller, required this.item});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final uploadId = '${item['upload_id'] ?? ''}';
    return Obx(() {
      final preview = controller.uploadPreview.value;
      var current = item;
      for (final entry in SubtitleManualUploadFormController.asMapList(
        preview?['items'],
      )) {
        if ('${entry['upload_id'] ?? ''}' == uploadId) {
          current = entry;
          break;
        }
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _ListCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: current['selected'] != false,
                  onChanged: (value) =>
                      controller.togglePreviewItem(uploadId, value == true),
                  title: Text(
                    '${current['source_name'] ?? '字幕文件'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text('${current['output_name'] ?? ''}'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: '${current['target_id'] ?? ''}'.isEmpty
                      ? null
                      : '${current['target_id']}',
                  decoration: _fieldDecoration(
                    context,
                    label: '目标视频',
                    dense: true,
                  ),
                  items: controller.uploadScopeTargets
                      .map(
                        (target) => DropdownMenuItem(
                          value: '${target['id']}',
                          child: Text(controller.compactTargetName(target)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.updatePreviewTarget(uploadId, value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: '${current['language_suffix'] ?? ''}',
                  decoration: _fieldDecoration(
                    context,
                    label: '语言后缀',
                    dense: true,
                  ),
                  onChanged: (value) =>
                      controller.updatePreviewLanguage(uploadId, value),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _OnlinePanel extends StatelessWidget {
  const _OnlinePanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final results = controller.filteredOnlineResults;
      final manualLinkCount = controller.onlineManualLinks.fold<int>(
        0,
        (sum, provider) =>
            sum +
            SubtitleManualUploadFormController.asMapList(
              provider['links'],
            ).length,
      );
      final targetCount = controller.onlineTargets.length;
      final providerCount = controller.onlineSelectedProviders.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnlineHeader(
            title: controller.onlineTitle.value,
            targetCount: targetCount,
            providerCount: providerCount,
          ),
          const SizedBox(height: 14),
          Text(
            '字幕源',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final provider in const [
                'subhd',
                'zimuku',
                'assrt',
                'opensubtitles',
              ])
                _ProviderChip(
                  label: _providerName(provider),
                  selected: controller.onlineSelectedProviders.contains(
                    provider,
                  ),
                  onTap: () {
                    if (controller.onlineSelectedProviders.contains(provider)) {
                      controller.onlineSelectedProviders.remove(provider);
                    } else {
                      controller.onlineSelectedProviders.add(provider);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          _OnlineSegmentContainer(
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: controller.onlineView.value,
              backgroundColor: Colors.transparent,
              thumbColor: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.all(3),
              children: {
                'results': _OnlineSegmentLabel(
                  icon: Icons.subtitles_outlined,
                  label: '搜索结果',
                  count: results.length,
                  selected: controller.onlineView.value == 'results',
                ),
                'manual': _OnlineSegmentLabel(
                  icon: Icons.open_in_new,
                  label: '手动搜索',
                  count: manualLinkCount,
                  selected: controller.onlineView.value == 'manual',
                ),
              },
              onValueChanged: (next) {
                if (next == null) return;
                controller.onlineView.value = next;
              },
            ),
          ),
          const SizedBox(height: 14),
          if (controller.onlineSearching.value)
            const _CenterStatusView(
              loading: true,
              text: '正在搜索在线字幕',
            )
          else if (controller.onlineView.value == 'manual')
            _ManualSearchPanel(controller: controller)
          else if (results.isEmpty)
            const _CenterStatusView(
              text: '暂无在线字幕结果，可切换字幕源或使用手动搜索链接。',
            )
          else
            for (final item in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OnlineResultCard(controller: controller, item: item),
              ),
        ],
      );
    });
  }
}

class _OnlineHeader extends StatelessWidget {
  const _OnlineHeader({
    required this.title,
    required this.targetCount,
    required this.providerCount,
  });

  final String title;
  final int targetCount;
  final int providerCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.travel_explore_outlined,
            size: 20,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$targetCount 个目标 · $providerCount 个字幕源已启用',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnlineActionBar extends StatelessWidget {
  const _OnlineActionBar({
    required this.controller,
    required this.sheetContext,
  });

  final SubtitleManualUploadFormController controller;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedCount = controller.onlineSelectedResultKeys.length;
      final downloading = controller.onlineDownloading.value;
      final applying = controller.onlineApplying.value;
      final busy = downloading || applying;

      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _OnlineCommandButton(
                  icon: Icons.save_alt_outlined,
                  label: applying
                      ? '写入中'
                      : selectedCount == 0
                      ? '直接写入'
                      : '写入 $selectedCount',
                  primary: true,
                  onTap: busy || selectedCount == 0
                      ? null
                      : () async {
                          final ok = await controller.applyOnlineDirect();
                          if (ok && sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OnlineCommandButton(
                  icon: Icons.preview_outlined,
                  label: downloading ? '生成中' : '预览',
                  onTap: busy || selectedCount == 0
                      ? null
                      : () => _openUploadPreview(sheetContext, controller),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OnlineCommandButton(
                  icon: Icons.auto_awesome,
                  label: 'AI',
                  confirm: true,
                  onTap: controller.aiAvailable && !busy
                      ? () async {
                          Navigator.of(sheetContext).pop();
                          await controller.downloadOnlinePreview(
                            submitAi: true,
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

void _openUploadPreview(
  BuildContext sheetContext,
  SubtitleManualUploadFormController controller,
) {
  _push(
    sheetContext,
    controller.uploadTitle.value,
    (_) => _UploadPreviewLoader(controller: controller),
    footerBuilder: (previewContext) => _PreviewApplyFooter(
      controller: controller,
      sheetContext: previewContext,
    ),
  );
}

class _UploadPreviewLoader extends StatefulWidget {
  const _UploadPreviewLoader({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  State<_UploadPreviewLoader> createState() => _UploadPreviewLoaderState();
}

class _UploadPreviewLoaderState extends State<_UploadPreviewLoader> {
  var _loading = true;
  String? _error;

  Future<void> _runPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    widget.controller.errorText.value = null;
    widget.controller.uploadPreview.value = null;
    final ok = await widget.controller.downloadOnlinePreview();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = ok
          ? null
          : widget.controller.errorText.value ?? '预览生成失败，请重试';
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPreview());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || widget.controller.onlineDownloading.value) {
      return const _CenterStatusView(
        loading: true,
        text: '正在下载并生成预览…',
      );
    }
    if (widget.controller.uploadPreview.value == null) {
      return Column(
        children: [
          _CenterStatusView(text: _error ?? '预览生成失败，请重试'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _runPreview,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ),
        ],
      );
    }
    final preview = widget.controller.uploadPreview.value;
    if (preview?['source'] == 'online') {
      return _OnlinePreviewPanel(controller: widget.controller);
    }
    return _UploadPanel(controller: widget.controller);
  }
}

class _OnlinePreviewPanel extends StatelessWidget {
  const _OnlinePreviewPanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Obx(() {
      final preview = controller.uploadPreview.value;
      final items = preview == null
          ? <Map<String, dynamic>>[]
          : SubtitleManualUploadFormController.asMapList(preview['items']);
      final selectedCount = items.where((e) => e['selected'] != false).length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '写入预览',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '已选 $selectedCount / ${items.length} 个字幕，确认目标与语言后缀后可写入',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: controller.fixTimeline.value,
            onChanged: controller.timelineAvailable
                ? (value) => controller.fixTimeline.value = value
                : null,
            title: const Text('写入后智能调轴'),
            subtitle: Text(
              controller.timelineAvailable ? '流媒体目标会自动跳过' : '调轴依赖不可用',
            ),
          ),
          const SizedBox(height: 4),
          for (final item in items)
            _OnlinePreviewItem(controller: controller, item: item),
        ],
      );
    });
  }
}

class _OnlinePreviewItem extends StatelessWidget {
  const _OnlinePreviewItem({required this.controller, required this.item});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final uploadId = '${item['upload_id'] ?? ''}';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(() {
      final preview = controller.uploadPreview.value;
      var current = item;
      for (final entry in SubtitleManualUploadFormController.asMapList(
        preview?['items'],
      )) {
        if ('${entry['upload_id'] ?? ''}' == uploadId) {
          current = entry;
          break;
        }
      }
      final selected = current['selected'] != false;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.28)
                  : scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected,
                  onChanged: (value) =>
                      controller.togglePreviewItem(uploadId, value == true),
                  title: Text(
                    '${current['source_name'] ?? current['title'] ?? '字幕文件'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${current['output_name'] ?? ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: DropdownButtonFormField<String>(
                    value: '${current['target_id'] ?? ''}'.isEmpty
                        ? null
                        : '${current['target_id']}',
                    decoration: _fieldDecoration(
                      context,
                      label: '目标视频',
                      dense: true,
                    ),
                    items: controller.uploadScopeTargets
                        .map(
                          (target) => DropdownMenuItem(
                            value: '${target['id']}',
                            child: Text(controller.compactTargetName(target)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.updatePreviewTarget(uploadId, value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextFormField(
                    initialValue: '${current['language_suffix'] ?? ''}',
                    decoration: _fieldDecoration(
                      context,
                      label: '语言后缀',
                      dense: true,
                    ),
                    onChanged: (value) =>
                        controller.updatePreviewLanguage(uploadId, value),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _PreviewApplyFooter extends StatelessWidget {
  const _PreviewApplyFooter({
    required this.controller,
    required this.sheetContext,
  });

  final SubtitleManualUploadFormController controller;
  final BuildContext sheetContext;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = controller.uploadPreview.value;
      if (preview == null) {
        return const SizedBox.shrink();
      }
      final applying = controller.applying.value;
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: FilledButton.icon(
            onPressed: applying
                ? null
                : () async {
                    await controller.applyUpload();
                    if (!sheetContext.mounted) return;
                    if (controller.uploadPreview.value == null &&
                        Navigator.of(sheetContext).canPop()) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
            icon: applying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all),
            label: Text(applying ? '写入中…' : '确认写入'),
          ),
        ),
      );
    });
  }
}

class _CenterStatusView extends StatelessWidget {
  const _CenterStatusView({required this.text, this.loading = false});

  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 280,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                Icon(
                  Icons.subtitles_off_outlined,
                  size: 32,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
                ),
              const SizedBox(height: 14),
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineSegmentContainer extends StatelessWidget {
  const _OnlineSegmentContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.42 : 0.58,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: child,
    );
  }
}

class _OnlineSegmentLabel extends StatelessWidget {
  const _OnlineSegmentLabel({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            count.toString(),
            style: TextStyle(
              color: color.withValues(alpha: selected ? 0.9 : 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualSearchPanel extends StatelessWidget {
  const _ManualSearchPanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    final providers = controller.onlineManualLinks;
    final keywords = controller.onlineManualKeywords;
    if (providers.isEmpty) {
      return const _EmptyPanel(text: '暂无手动搜索链接');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (keywords.isNotEmpty) ...[
          _Panel(
            child: _OnlineControlGroup(
              title: '推荐关键词',
              icon: Icons.manage_search,
              compact: true,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final keyword in keywords) _MetaChip(label: keyword),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _SectionHeader(title: '手动搜索', trailing: '${providers.length} 个字幕源'),
        const SizedBox(height: 8),
        for (final provider in providers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ManualProviderCard(provider: provider),
          ),
      ],
    );
  }
}

class _ManualProviderCard extends StatelessWidget {
  const _ManualProviderCard({required this.provider});

  final Map<String, dynamic> provider;

  @override
  Widget build(BuildContext context) {
    final links = SubtitleManualUploadFormController.asMapList(
      provider['links'],
    );
    final name = '${provider['name'] ?? provider['provider'] ?? '字幕源'}';
    final host = '${provider['host'] ?? provider['root_url'] ?? ''}'.trim();
    return _ListCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.public,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (host.isNotEmpty)
                  Text(
                    host,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (links.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final link in links)
                    _ManualLinkChip(
                      label: Text('${link['keyword'] ?? '打开搜索'}'),
                      onTap: () => _launch('${link['url'] ?? ''}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnlinePanelLoader extends StatefulWidget {
  const _OnlinePanelLoader({required this.controller, required this.start});

  final SubtitleManualUploadFormController controller;
  final Future<void> Function() start;

  @override
  State<_OnlinePanelLoader> createState() => _OnlinePanelLoaderState();
}

class _OnlinePanelLoaderState extends State<_OnlinePanelLoader> {
  bool _preparing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.start();
      if (!mounted) return;
      setState(() => _preparing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_preparing) {
      return const _OnlinePreparingView();
    }
    return _OnlinePanel(controller: widget.controller);
  }
}

class _AutoQueuePanel extends StatelessWidget {
  const _AutoQueuePanel({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final queue = controller.autoTransferQueue.value;
      final tasks = SubtitleManualUploadFormController.asMapList(
        queue['tasks'],
      );
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelTitle(title: '自动入库队列', icon: Icons.queue),
            if (tasks.isEmpty)
              const _InlineHint(icon: Icons.done_all, text: '暂无队列任务')
            else
              for (final task in tasks.take(20))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ListCard(
                    child: ListTile(
                      leading: const Icon(Icons.task_alt),
                      title: Text('${task['title'] ?? task['name'] ?? '任务'}'),
                      subtitle: Text(
                        '${task['status'] ?? task['message'] ?? ''}',
                      ),
                    ),
                  ),
                ),
          ],
        ),
      );
    });
  }
}

class _AutoQueuePanelLoader extends StatefulWidget {
  const _AutoQueuePanelLoader({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  State<_AutoQueuePanelLoader> createState() => _AutoQueuePanelLoaderState();
}

class _AutoQueuePanelLoaderState extends State<_AutoQueuePanelLoader> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.loadAutoTransferQueue();
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = SubtitleManualUploadFormController.asMapList(
      widget.controller.autoTransferQueue.value['tasks'],
    );
    if (_loading && tasks.isEmpty) {
      return const _LoadingPanel(text: '正在读取自动入库队列');
    }
    return _AutoQueuePanel(controller: widget.controller);
  }
}

const _subtitleBasicFields = <SettingsFieldConfig>[
  SettingsFieldConfig(
    label: '启用插件',
    envKey: 'enabled',
    type: SettingsFieldType.toggle,
    icon: Icons.power_settings_new,
  ),
  SettingsFieldConfig(
    label: '显示侧边栏入口',
    envKey: 'show_sidebar_nav',
    type: SettingsFieldType.toggle,
    icon: Icons.view_sidebar_outlined,
  ),
  SettingsFieldConfig(
    label: '启用 AI 字幕联动',
    envKey: 'ai_link_enabled',
    type: SettingsFieldType.toggle,
    icon: Icons.auto_awesome,
  ),
  SettingsFieldConfig(
    label: '写入前繁体转简体',
    envKey: 'traditional_to_simplified',
    type: SettingsFieldType.toggle,
    icon: Icons.translate,
  ),
  SettingsFieldConfig(
    label: '入库后自动搜索匹配字幕',
    envKey: 'auto_search_on_transfer',
    type: SettingsFieldType.toggle,
    icon: Icons.manage_search,
  ),
  SettingsFieldConfig(
    label: '入库自动处理跳过中文资源',
    envKey: 'auto_skip_chinese_media_on_transfer',
    type: SettingsFieldType.toggle,
    icon: Icons.skip_next,
  ),
  SettingsFieldConfig(
    label: '信任整理历史路径',
    envKey: 'trust_transfer_history_paths',
    type: SettingsFieldType.toggle,
    icon: Icons.verified_user_outlined,
  ),
  SettingsFieldConfig(
    label: '入库后字幕处理策略',
    envKey: 'auto_transfer_subtitle_strategy',
    type: SettingsFieldType.select,
    enumKey: 'SMU_AUTO_TRANSFER_STRATEGY',
    icon: Icons.rule,
  ),
  SettingsFieldConfig(
    label: '自动多字幕处理',
    envKey: 'auto_multi_subtitle_mode',
    type: SettingsFieldType.select,
    enumKey: 'SMU_MULTI_SUBTITLE_MODE',
    icon: Icons.library_add_check_outlined,
  ),
  SettingsFieldConfig(
    label: '英文 ASS 转临时 SRT 后提交 AI',
    envKey: 'auto_ass_to_srt_for_ai',
    type: SettingsFieldType.toggle,
    icon: Icons.closed_caption_outlined,
  ),
];

const _subtitleOnlineFields = <SettingsFieldConfig>[
  SettingsFieldConfig(
    label: 'API 搜索和下载使用系统代理',
    envKey: 'online_use_proxy',
    type: SettingsFieldType.toggle,
    icon: Icons.vpn_lock_outlined,
  ),
  SettingsFieldConfig(
    label: 'SubHD 站点地址',
    envKey: 'subhd_url',
    type: SettingsFieldType.text,
    icon: Icons.link,
  ),
  SettingsFieldConfig(
    label: 'Zimuku 站点地址',
    envKey: 'zimuku_url',
    type: SettingsFieldType.text,
    icon: Icons.link,
  ),
  SettingsFieldConfig(
    label: '射手网(伪) 手动搜索地址',
    envKey: 'assrt_url',
    type: SettingsFieldType.text,
    icon: Icons.link,
  ),
  SettingsFieldConfig(
    label: '射手网(伪) API 地址',
    envKey: 'assrt_api_url',
    type: SettingsFieldType.text,
    icon: Icons.api,
  ),
  SettingsFieldConfig(
    label: '射手网(伪) API Key',
    envKey: 'assrt_api_key',
    type: SettingsFieldType.text,
    obscureText: true,
    icon: Icons.key,
  ),
  SettingsFieldConfig(
    label: 'OpenSubtitles 手动搜索地址',
    envKey: 'opensubtitles_url',
    type: SettingsFieldType.text,
    icon: Icons.link,
  ),
  SettingsFieldConfig(
    label: 'OpenSubtitles API 地址',
    envKey: 'opensubtitles_api_url',
    type: SettingsFieldType.text,
    icon: Icons.api,
  ),
  SettingsFieldConfig(
    label: 'OpenSubtitles API Key',
    envKey: 'opensubtitles_api_key',
    type: SettingsFieldType.text,
    obscureText: true,
    icon: Icons.key,
  ),
  SettingsFieldConfig(
    label: 'OpenSubtitles 用户名',
    envKey: 'opensubtitles_username',
    type: SettingsFieldType.text,
    icon: Icons.person_outline,
  ),
  SettingsFieldConfig(
    label: 'OpenSubtitles 密码',
    envKey: 'opensubtitles_password',
    type: SettingsFieldType.text,
    obscureText: true,
    icon: Icons.password,
  ),
];

const _subtitleTimelineFields = <SettingsFieldConfig>[
  SettingsFieldConfig(
    label: '智能调轴最大偏移秒数',
    envKey: 'timeline_max_offset_seconds',
    type: SettingsFieldType.number,
    unit: '秒',
    step: 1,
    icon: Icons.timer_outlined,
  ),
  SettingsFieldConfig(
    label: '最小应用阈值',
    envKey: 'timeline_min_offset_seconds',
    type: SettingsFieldType.number,
    unit: '秒',
    step: 1,
    icon: Icons.timer,
  ),
  SettingsFieldConfig(
    label: '音频 VAD 模式',
    envKey: 'timeline_vad_mode',
    type: SettingsFieldType.select,
    enumKey: 'SMU_TIMELINE_VAD_MODE',
    icon: Icons.graphic_eq,
  ),
  SettingsFieldConfig(
    label: '全局允许高风险偏移',
    envKey: 'timeline_allow_risky_offset',
    type: SettingsFieldType.toggle,
    icon: Icons.warning_amber_rounded,
  ),
];

const _subtitleRarFields = <SettingsFieldConfig>[
  SettingsFieldConfig(
    label: '压缩包解压器处理方式',
    envKey: 'rar_dependency_mode',
    type: SettingsFieldType.select,
    enumKey: 'SMU_RAR_DEPENDENCY_MODE',
    icon: Icons.archive_outlined,
  ),
  SettingsFieldConfig(
    label: '容器内映射路径',
    envKey: 'rar_tool_path',
    type: SettingsFieldType.text,
    icon: Icons.folder_outlined,
    conditionKey: 'rar_dependency_mode',
    conditionValue: 'mapped_binary',
  ),
];

const _subtitleConfigFields = <SettingsFieldConfig>[
  ..._subtitleBasicFields,
  ..._subtitleOnlineFields,
  ..._subtitleTimelineFields,
  ..._subtitleRarFields,
];

const _subtitleConfigOptions = <String, List<SettingsEnumOption>>{
  'SMU_AUTO_TRANSFER_STRATEGY': [
    SettingsEnumOption(value: 'online_then_ai_source', label: '在线优先，AI 兜底'),
    SettingsEnumOption(value: 'online_source_only', label: '只用在线匹配'),
    SettingsEnumOption(value: 'ai_source_only', label: '只用 AI 生成'),
  ],
  'SMU_MULTI_SUBTITLE_MODE': [
    SettingsEnumOption(value: 'best', label: '按偏好选择最佳'),
    SettingsEnumOption(value: 'chinese_all', label: '中文/双语全部入库'),
    SettingsEnumOption(value: 'all', label: '全部入库'),
  ],
  'SMU_TIMELINE_VAD_MODE': [
    SettingsEnumOption(value: 'webrtc', label: 'WebRTC VAD'),
    SettingsEnumOption(value: 'rms', label: 'RMS 能量阈值'),
  ],
  'SMU_RAR_DEPENDENCY_MODE': [
    SettingsEnumOption(value: 'none', label: '不处理，仅检测'),
    SettingsEnumOption(value: 'container_install', label: '加载插件时尝试安装'),
    SettingsEnumOption(value: 'mapped_binary', label: '使用宿主机映射文件'),
  ],
};

const _subtitleMultiOptions = <String, Map<String, String>>{
  'language_priority': {
    'bilingual': '双语',
    'chi': '简中',
    'cht': '繁中',
    'eng': '英文',
    'jpn': '日文',
  },
  'format_priority': {'ass': 'ASS', 'srt': 'SRT', 'ssa': 'SSA', 'vtt': 'VTT'},
  'online_providers': {
    'subhd': 'SubHD',
    'zimuku': 'Zimuku',
    'assrt': '射手网(伪)',
    'opensubtitles': 'OpenSubtitles',
  },
};

class _SubtitleConfigView extends StatefulWidget {
  const _SubtitleConfigView({required this.controller});

  final SubtitleManualUploadFormController controller;

  @override
  State<_SubtitleConfigView> createState() => _SubtitleConfigViewState();
}

class _SubtitleConfigViewState extends State<_SubtitleConfigView> {
  late final SettingsFormManager _form = SettingsFormManager(
    fields: _subtitleConfigFields,
  );
  final List<Worker> _workers = [];
  final Map<TextEditingController, VoidCallback> _textListeners = {};
  bool _hydrating = false;

  SubtitleManualUploadFormController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    for (final field in _subtitleConfigFields) {
      final state = _form.stateFor(field);
      switch (state) {
        case SettingsTextFieldState():
          void listener() => _syncFormModelFromForm();
          state.controller.addListener(listener);
          _textListeners[state.controller] = listener;
          break;
        case SettingsNumberFieldState():
          void listener() => _syncFormModelFromForm();
          state.controller.addListener(listener);
          _textListeners[state.controller] = listener;
          break;
        case SettingsToggleFieldState():
          _workers.add(
            ever<bool>(state.value, (_) => _syncFormModelFromForm()),
          );
          break;
        case SettingsSelectFieldState():
          _workers.add(
            ever<String>(state.value, (_) => _syncFormModelFromForm()),
          );
          break;
        case SettingsFieldState():
          break;
      }
    }
    _hydrateFromModel(controller.formModel.value);
  }

  @override
  void dispose() {
    for (final entry in _textListeners.entries) {
      entry.key.removeListener(entry.value);
    }
    for (final worker in _workers) {
      worker.dispose();
    }
    _form.dispose();
    super.dispose();
  }

  void _hydrateFromModel(Map<String, dynamic> model) {
    _hydrating = true;
    _form.hydrateAll((key) => model[key]);
    _hydrating = false;
  }

  void _syncFormModelFromForm() {
    if (_hydrating) return;
    final next = Map<String, dynamic>.from(controller.formModel.value);
    for (final field in _subtitleConfigFields) {
      next[field.envKey] = _form.effectiveValue(field.envKey);
    }
    controller.formModel.value = next;
  }

  List<SettingsFieldConfig> _visibleFields(List<SettingsFieldConfig> fields) {
    return fields
        .where(
          (field) =>
              _form.shouldShow(field, (key) => _form.effectiveValue(key)),
        )
        .toList();
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<SettingsFieldConfig> fields,
    required SettingsFormRowBuilder rowBuilder,
    List<Widget> extras = const [],
  }) {
    final visibleFields = _visibleFields(fields);
    return Section(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      header: SectionHeader(title: title),
      children: [
        for (final field in visibleFields)
          rowBuilder.buildRow(
            context,
            field,
            editMode: true,
            readValue: (key) => controller.formModel.value[key],
          ),
        ...extras,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final model = controller.formModel.value;
      _hydrateFromModel(model);
      final rowBuilder = SettingsFormRowBuilder(
        form: _form,
        optionsOf: (key) => _subtitleConfigOptions[key] ?? const [],
      );
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _FeedbackBanner(controller: controller),
          _buildSection(
            context,
            title: '基础与自动处理',
            fields: _subtitleBasicFields,
            rowBuilder: rowBuilder,
            extras: [
              _ConfigMultiSelectField(
                controller: controller,
                name: 'auto_subtitle_language_priority',
                label: '语言优先级',
                options: _subtitleMultiOptions['language_priority']!,
              ),
              _ConfigMultiSelectField(
                controller: controller,
                name: 'auto_subtitle_format_priority',
                label: '格式优先级',
                options: _subtitleMultiOptions['format_priority']!,
              ),
            ],
          ),
          _buildSection(
            context,
            title: '在线字幕搜索',
            fields: _subtitleOnlineFields,
            rowBuilder: rowBuilder,
            extras: [
              _ConfigMultiSelectField(
                controller: controller,
                name: 'online_providers',
                label: '启用字幕源',
                options: _subtitleMultiOptions['online_providers']!,
              ),
            ],
          ),
          _buildSection(
            context,
            title: '智能调轴',
            fields: _subtitleTimelineFields,
            rowBuilder: rowBuilder,
          ),
          _buildSection(
            context,
            title: 'RAR / 7Z 解压器',
            fields: _subtitleRarFields,
            rowBuilder: rowBuilder,
          ),
        ],
      );
    });
  }
}

class _ConfigMultiSelectField extends StatelessWidget {
  const _ConfigMultiSelectField({
    required this.controller,
    required this.name,
    required this.label,
    required this.options,
  });

  final SubtitleManualUploadFormController controller;
  final String name;
  final String label;
  final Map<String, String> options;

  @override
  Widget build(BuildContext context) {
    final selected = controller.asStringList(controller.formModel.value[name]);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in options.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: selected.contains(entry.key),
                  selectedColor: colors.primary.withValues(alpha: 0.14),
                  checkmarkColor: colors.primary,
                  side: BorderSide(
                    color: selected.contains(entry.key)
                        ? colors.primary.withValues(alpha: 0.35)
                        : colors.outlineVariant,
                  ),
                  labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected.contains(entry.key)
                        ? colors.primary
                        : colors.onSurfaceVariant,
                    fontWeight: selected.contains(entry.key)
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                  onSelected: (checked) {
                    final next = selected.toList();
                    if (checked) {
                      if (!next.contains(entry.key)) next.add(entry.key);
                    } else {
                      next.remove(entry.key);
                    }
                    controller.formModel.value = {
                      ...controller.formModel.value,
                      name: next,
                    };
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnlineControlGroup extends StatelessWidget {
  const _OnlineControlGroup({
    required this.title,
    required this.icon,
    required this.child,
    this.accent = false,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tint = accent ? colors.primary : colors.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: tint),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: tint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 10),
        child,
      ],
    );
  }
}

class _OnlineCommandButton extends StatelessWidget {
  const _OnlineCommandButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.primary = false,
    this.confirm = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool confirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onTap != null;
    final foreground = primary ? colors.onPrimary : colors.primary;
    final background = primary ? colors.primary : colors.surface;
    final disabled = theme.disabledColor;
    return Material(
      color: enabled
          ? background
          : colors.surfaceContainerHighest.withValues(alpha: 0.52),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled
            ? () {
                if (!confirm) {
                  onTap?.call();
                  return;
                }
                _confirmAction(
                  context,
                  title: label,
                  onConfirm: () async => onTap?.call(),
                );
              }
            : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? (primary
                        ? colors.primary
                        : colors.outline.withValues(alpha: 0.36))
                  : colors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled ? foreground : disabled.withValues(alpha: 0.62),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: enabled
                        ? foreground
                        : disabled.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonPill extends StatelessWidget {
  const _SeasonPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: theme.primaryColor.withValues(alpha: 0.14),
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: selected ? theme.primaryColor : null,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    final fg = selected ? theme.primaryColor : colors.onSurfaceVariant;
    final bg = selected
        ? theme.primaryColor.withValues(alpha: 0.11)
        : colors.surface;
    final borderColor = selected
        ? theme.primaryColor.withValues(alpha: 0.50)
        : colors.outline.withValues(alpha: 0.34);
    return IntrinsicWidth(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check, size: 14, color: fg),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

class _ManualLinkChip extends StatelessWidget {
  const _ManualLinkChip({required this.label, required this.onTap});

  final Widget label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.primaryColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, size: 15, color: theme.primaryColor),
              const SizedBox(width: 5),
              DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                child: label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  const _SubtitleRow({
    required this.controller,
    required this.target,
    required this.subtitle,
  });

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> target;
  final Map<String, dynamic> subtitle;

  @override
  Widget build(BuildContext context) {
    final title = '${subtitle['name'] ?? subtitle['path'] ?? '字幕'}';
    final meta = '${subtitle['language'] ?? subtitle['size_text'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              Icons.closed_caption_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (meta.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _IconAction(
            tooltip: '调轴',
            icon: Icons.graphic_eq,
            onTap: controller.timelineAvailable
                ? () => controller.fixExistingTimeline([
                    {
                      'target_id': target['id'],
                      'subtitle_path': subtitle['path'],
                    },
                  ], '单个字幕')
                : null,
          ),
          _IconAction(
            tooltip: '恢复备份',
            icon: Icons.restore,
            onTap: () => controller.restoreSubtitleBackup(target, subtitle),
          ),
          _IconAction(
            tooltip: '删除',
            icon: Icons.delete_outline,
            onTap: () => controller.deleteSubtitle(target, subtitle),
          ),
        ],
      ),
    );
  }
}

class _OnlineResultCard extends StatelessWidget {
  const _OnlineResultCard({required this.controller, required this.item});

  final SubtitleManualUploadFormController controller;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final key = controller.onlineResultKey(item);
    final provider = _providerName('${item['provider'] ?? ''}');
    final language = '${item['language'] ?? item['language_name'] ?? ''}';

    return Obx(() {
      final selected = controller.onlineSelectedResultKeys.contains(key);
      return _ListCard(
        onTap: () => controller.toggleOnlineResult(item, !selected),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                visualDensity: VisualDensity.compact,
                onChanged: (value) =>
                    controller.toggleOnlineResult(item, value == true),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['title'] ?? item['name'] ?? '在线字幕'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MetaChip(label: provider),
                        if (language.trim().isNotEmpty)
                          _MetaChip(label: language),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _OnlinePreparingView extends StatelessWidget {
  const _OnlinePreparingView();

  @override
  Widget build(BuildContext context) {
    return const _CenterStatusView(
      loading: true,
      text: '正在读取字幕源并准备搜索',
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.tooltip, required this.icon, this.onTap});

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onTap != null;
    final destructive = tooltip.contains('删除');
    final accent = destructive ? colors.error : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: enabled
              ? colors.surfaceContainerHighest.withValues(alpha: 0.42)
              : colors.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(9),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () => _confirmAction(
                    context,
                    title: tooltip,
                    destructive: destructive,
                    onConfirm: () async => onTap?.call(),
                  ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 19,
                color: enabled
                    ? accent
                    : theme.disabledColor.withValues(alpha: 0.58),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color ?? theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.child, this.onTap, this.selected = false});

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderColor = selected
        ? colors.primary.withValues(alpha: 0.55)
        : colors.outline.withValues(alpha: 0.32);
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.16)
          : theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 1.2 : 0.6),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: title, subtitle: trailing);
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String label,
  IconData? icon,
  bool dense = false,
}) {
  final primary = Theme.of(context).primaryColor;
  final enabledBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.42),
    ),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: primary.withValues(alpha: 0.65)),
  );
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12,
      vertical: dense ? 10 : 12,
    ),
    enabledBorder: enabledBorder,
    focusedBorder: focusedBorder,
    border: enabledBorder,
    filled: true,
    fillColor: Colors.transparent,
    prefixIcon: icon == null ? null : Icon(icon, size: 18),
    isDense: dense,
  );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.url,
    this.isTv = false,
    this.width = 48,
    this.height = 68,
  });

  final String url;
  final bool isTv;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isTv ? Icons.live_tv_outlined : Icons.movie_outlined,
        color: scheme.primary.withValues(alpha: 0.75),
        size: 22,
      ),
    );
    if (url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}

class _PickedFileRow extends StatelessWidget {
  const _PickedFileRow({required this.file, required this.onRemove});

  final fp.PlatformFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(file.name),
      subtitle: Text(_formatBytes(file.size)),
      trailing: IconButton(
        tooltip: '移除',
        onPressed: onRemove,
        icon: const Icon(Icons.close),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(text),
          ],
        ),
      ),
    );
  }
}

String _mediaPoster(Map<String, dynamic> item) {
  return '${item['poster_thumb_url'] ?? item['poster_url'] ?? ''}';
}

bool _isTvMedia(Map<String, dynamic> item) {
  final type = '${item['media_type'] ?? ''}'.trim().toLowerCase();
  return type == 'tv' || type == 'series' || type == '电视剧';
}

String _mediaDisplayTitle(Map<String, dynamic> item) {
  final title = '${item['title'] ?? item['name'] ?? ''}'.trim();
  return title.isEmpty ? '未知媒体' : title;
}

String? _mediaYearText(Map<String, dynamic> item) {
  final year = '${item['year'] ?? ''}'.trim();
  return year.isEmpty ? null : year;
}

List<Widget> _mediaStats(Map<String, dynamic> item) {
  final isTv = _isTvMedia(item);
  final videoCount = SubtitleManualUploadFormController.asInt(
    item['target_count'] ?? item['path_count'],
    0,
  );
  final chips = <Widget>[];

  if (isTv) {
    var seasonCount = SubtitleManualUploadFormController.asInt(
      item['season_count'],
      0,
    );
    var episodeCount = SubtitleManualUploadFormController.asInt(
      item['episode_count'],
      0,
    );
    if (seasonCount == 0 || episodeCount == 0) {
      final seasons = SubtitleManualUploadFormController.asMapList(
        item['seasons'],
      );
      if (seasonCount == 0 && seasons.isNotEmpty) {
        seasonCount = seasons.length;
      }
      if (episodeCount == 0) {
        for (final season in seasons) {
          episodeCount += SubtitleManualUploadFormController.asInt(
            season['episode_count'] ?? season['episodes'],
            0,
          );
        }
      }
    }
    if (seasonCount > 0) {
      chips.add(
        _MediaStatChip(
          icon: Icons.layers_outlined,
          label: '$seasonCount 季',
        ),
      );
    }
    if (episodeCount > 0) {
      chips.add(
        _MediaStatChip(
          icon: Icons.playlist_play_rounded,
          label: '$episodeCount 集',
        ),
      );
    }
  }

  if (videoCount > 0) {
    chips.add(
      _MediaStatChip(
        icon: Icons.videocam_outlined,
        label: '$videoCount 视频',
      ),
    );
  }

  return chips;
}

String _targetPath(Map<String, dynamic> target) {
  return '${target['path'] ?? ''}'.trim();
}

String _seasonLabel(Map<String, dynamic> season) {
  final title = '${season['title'] ?? season['label'] ?? ''}';
  if (title.isNotEmpty) return title;
  final value = '${season['value'] ?? season['season'] ?? ''}';
  return value == 'all' ? '全部' : '第 $value 季';
}

String _providerName(String provider) {
  switch (provider) {
    case 'subhd':
      return 'SubHD';
    case 'zimuku':
      return 'Zimuku';
    case 'assrt':
      return '射手网(伪)';
    case 'opensubtitles':
      return 'OpenSubtitles';
    default:
      return provider;
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

Future<void> _confirmAction(
  BuildContext context, {
  required String title,
  required Future<void> Function() onConfirm,
  String? message,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _SubtitleConfirmDialog(
      title: title,
      message: message ?? '确认执行此操作？',
      destructive: destructive,
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await onConfirm();
}

Future<void> _launch(String rawUrl) async {
  await WebUtil.open(url: rawUrl);
}

Future<T?> _push<T>(
  BuildContext context,
  String title,
  WidgetBuilder childBuilder, {
  WidgetBuilder? footerBuilder,
  WidgetBuilder? headerActionsBuilder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.36,
      maxChildSize: 1,
      expand: false,
      builder: (contentContext, scrollController) => _SubtitleBottomSheet(
        title: title,
        scrollController: scrollController,
        childBuilder: childBuilder,
        footerBuilder: footerBuilder,
        headerActionsBuilder: headerActionsBuilder,
      ),
    ),
  );
}

Future<void> _pushOnlineSheet(
  BuildContext hostContext,
  SubtitleManualUploadFormController controller, {
  required Future<void> Function() start,
  String title = '在线字幕',
}) {
  return _push(
    hostContext,
    title,
    (_) => _OnlinePanelLoader(controller: controller, start: start),
    headerActionsBuilder: (_) => Obx(() {
      if (controller.onlineSearching.value) {
        return const Padding(
          padding: EdgeInsets.only(right: 4),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      }
      return IconButton(
        tooltip: '重新搜索',
        onPressed: controller.runOnlineSearch,
        icon: const Icon(Icons.refresh_rounded),
      );
    }),
    footerBuilder: (sheetContext) => _OnlineActionBar(
      controller: controller,
      sheetContext: sheetContext,
    ),
  );
}

class _SubtitleConfirmDialog extends StatelessWidget {
  const _SubtitleConfirmDialog({
    required this.title,
    required this.message,
    required this.destructive,
  });

  final String title;
  final String message;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = destructive ? colors.error : colors.primary;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    destructive
                        ? Icons.warning_amber_rounded
                        : Icons.help_outline_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: destructive
                          ? colors.onError
                          : colors.onPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('确认'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtitleBottomSheet extends StatelessWidget {
  const _SubtitleBottomSheet({
    required this.title,
    required this.scrollController,
    required this.childBuilder,
    this.footerBuilder,
    this.headerActionsBuilder,
  });

  final String title;
  final ScrollController scrollController;
  final WidgetBuilder childBuilder;
  final WidgetBuilder? footerBuilder;
  final WidgetBuilder? headerActionsBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: colors.surface,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (headerActionsBuilder != null)
                    headerActionsBuilder!(context),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.outlineVariant),
            Expanded(
              child: CustomScrollView(
                controller: scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      footerBuilder == null ? 24 + bottomInset : 16,
                    ),
                    sliver: SliverToBoxAdapter(child: childBuilder(context)),
                  ),
                ],
              ),
            ),
            if (footerBuilder != null) footerBuilder!(context),
          ],
        ),
      ),
    );
  }
}
