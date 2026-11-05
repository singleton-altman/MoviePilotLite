import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moviepilot_mobile/modules/download/controllers/download_controller.dart';
import 'package:moviepilot_mobile/modules/download/widgets/download_sheet.dart';
import 'package:moviepilot_mobile/modules/recognize/controllers/recognize_controller.dart';
import 'package:moviepilot_mobile/modules/recognize/pages/recognize_page.dart';
import 'package:moviepilot_mobile/modules/setting/controllers/setting_controller.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_controller.dart';
import 'package:moviepilot_mobile/modules/site/models/site_models.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

import '../models/search_result_models.dart';

class SearchResultTorrentItem extends StatelessWidget {
  const SearchResultTorrentItem({
    super.key,
    required this.item,
    this.similarItems,
    this.immersive = false,
    this.invertColors = false,
    this.onRecognizeInfoTap,
  });

  final SearchResultItem item;
  final List<SearchResultItem>? similarItems;
  final bool immersive;
  final bool invertColors;
  final Function(SearchResultItem)? onRecognizeInfoTap;

  static final Map<int, Future<List<int>?>> _iconFutures = {};

  bool _isInverted() => immersive || invertColors;

  Color cardColor(BuildContext context) => _isInverted()
      ? Color.alphaBlend(
          Colors.black.withValues(alpha: 0.18),
          AppTheme.darkCardBackgroundColor,
        )
      : Theme.of(context).colorScheme.surface;

  Color themeColor(BuildContext context) =>
      _isInverted() ? CupertinoColors.activeBlue : context.primaryColor;

  Color primaryTextColor(BuildContext context) =>
      _isInverted() ? Colors.white : Theme.of(context).colorScheme.onSurface;

  Color secondaryTextColor(BuildContext context) => _isInverted()
      ? Colors.white.withValues(alpha: 0.72)
      : Theme.of(context).colorScheme.onSurfaceVariant;

  Color _cardBorderColor(BuildContext context) => _isInverted()
      ? Colors.white.withValues(alpha: 0.08)
      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.32);

  Color _cardBottomTint(BuildContext context) => _isInverted()
      ? const Color(0xFF101826)
      : Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.76);

  Color _footerSurface(BuildContext context) => _isInverted()
      ? Colors.white.withValues(alpha: 0.03)
      : Theme.of(
          context,
        ).colorScheme.surfaceContainerLow.withValues(alpha: 0.96);

  @override
  Widget build(BuildContext context) {
    final meta = item.meta_info;
    final torrent = item.torrent_info;
    final accent = themeColor(context);
    final title = _displayTitle(item);
    final season = _seasonLabel(item);
    final tags = _buildTags(item);
    final primaryTags = tags.where((tag) => tag.prominent).toList();
    final secondaryTags = tags.where((tag) => !tag.prominent).toList();
    final promotion = _promotionBadgeLabel(item);

    return CupertinoContextMenu.builder(
      enableHapticFeedback: true,
      actions: _buildContextMenuActions(context, item),
      builder: (context, animation) => GestureDetector(
        onTap: () => _openDownloadSheet(context, item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _cardBorderColor(context)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardColor(context), _cardBottomTint(context)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _isInverted() ? 0.18 : 0.06,
                ),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (promotion != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _buildPromotionBadge(
                    promotion,
                    prominent: true,
                    compact: true,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(
                      context,
                      title: title,
                      season: season,
                      promotion: promotion,
                      accent: accent,
                      torrent: torrent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      torrent?.title ?? meta?.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor(
                          context,
                        ).withValues(alpha: 0.92),
                      ),
                    ),
                    if ((meta?.subtitle ?? torrent?.description)?.isNotEmpty ??
                        false) ...[
                      const SizedBox(height: 8),
                      Text(
                        meta?.subtitle ?? torrent?.description ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14.5,
                          height: 1.45,
                          color: secondaryTextColor(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildMetaRow(context, item),
                    if (primaryTags.isNotEmpty || secondaryTags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildTagSection(
                        context,
                        primaryTags: primaryTags,
                        secondaryTags: secondaryTags,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildMoreFooter(context, item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContextMenuActions(
    BuildContext context,
    SearchResultItem item,
  ) {
    final downloadUrl = item.torrent_info?.enclosure?.trim() ?? '';
    final pageUrl = item.torrent_info?.page_url?.trim() ?? '';
    final actions = <Widget>[
      CupertinoContextMenuAction(
        trailingIcon: CupertinoIcons.arrow_down_circle,
        onPressed: () {
          Navigator.of(context).pop();
          _copyUrl(downloadUrl, emptyMessage: '暂无下载地址');
        },
        child: const Text('复制下载地址'),
      ),
    ];

    if (pageUrl.isNotEmpty && pageUrl != downloadUrl) {
      actions.add(
        CupertinoContextMenuAction(
          trailingIcon: CupertinoIcons.link,
          onPressed: () {
            Navigator.of(context).pop();
            _copyUrl(pageUrl, emptyMessage: '暂无页面地址');
          },
          child: const Text('复制页面地址'),
        ),
      );
    }

    return actions;
  }

  void _copyUrl(String url, {required String emptyMessage}) {
    final value = url.trim();
    if (value.isEmpty) {
      ToastUtil.info(emptyMessage);
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    ToastUtil.success('已复制，可直接粘贴');
  }

  Widget _buildHeader(
    BuildContext context, {
    required String title,
    required String? season,
    required String? promotion,
    required Color accent,
    required SearchTorrentInfo? torrent,
  }) {
    final hasMetaRow =
        (torrent?.seeders ?? 0) > 0 ||
        (torrent?.peers ?? 0) > 0 ||
        season != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: promotion != null ? 70 : 0),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: primaryTextColor(context),
            ),
          ),
        ),
        if (hasMetaRow) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: _buildSiteIndicator(context)),
                    if (season != null) ...[
                      const SizedBox(width: 8),
                      _buildSeasonChip(season, accent: accent, dense: true),
                    ],
                  ],
                ),
              ),
              if ((torrent?.seeders ?? 0) > 0 || (torrent?.peers ?? 0) > 0) ...[
                const SizedBox(width: 12),
                _buildTorrentStats(context, torrent),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTorrentStats(BuildContext context, SearchTorrentInfo? torrent) {
    final seeders = torrent?.seeders ?? 0;
    final peers = torrent?.peers ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (seeders > 0)
          _buildStatPill(
            context,
            icon: Icons.arrow_upward_rounded,
            label: '$seeders',
            color: const Color(0xFF84CC16),
            prominent: true,
          ),
        if (seeders > 0 && peers > 0) const SizedBox(width: 8),
        if (peers > 0)
          _buildStatPill(
            context,
            icon: Icons.arrow_downward_rounded,
            label: '$peers',
            color: const Color(0xFFFB7185),
          ),
      ],
    );
  }

  Widget _buildMoreFooter(BuildContext context, SearchResultItem item) {
    final accent = themeColor(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: _footerSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isInverted()
              ? Colors.white.withValues(alpha: 0.06)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (onRecognizeInfoTap != null) {
                onRecognizeInfoTap?.call(item);
                return;
              }
              await _showRecognizeSheet(context, item);
            },
            child: _buildFooterAction(
              context,
              icon: CupertinoIcons.sparkles,
              label: '识别',
              color: accent,
            ),
          ),
          if (similarItems != null && similarItems!.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildFooterHint(
              context,
              label: '相似 ${similarItems!.length}',
              icon: CupertinoIcons.square_stack_3d_up,
            ),
          ],
          const Spacer(),
          _buildSizePill(context, item, compact: true),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openInfoSheet(context, item),
            child: _buildFooterIconAction(
              context,
              icon: Icons.info_outline_rounded,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: _isInverted() ? 0.22 : 0.16),
              color.withValues(alpha: _isInverted() ? 0.14 : 0.10),
            ],
          ),
          border: Border.all(
            color: color.withValues(alpha: _isInverted() ? 0.26 : 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: _isInverted() ? 0.10 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterIconAction(
    BuildContext context, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: _isInverted() ? 0.18 : 0.14),
            color.withValues(alpha: _isInverted() ? 0.10 : 0.08),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: _isInverted() ? 0.26 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: _isInverted() ? 0.10 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildFooterHint(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final color = secondaryTextColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isInverted()
              ? [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.04),
                ]
              : [
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.78),
                ],
        ),
        border: Border.all(
          color: _isInverted()
              ? Colors.white.withValues(alpha: 0.06)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecognizeSheet(
    BuildContext context,
    SearchResultItem item,
  ) async {
    final initialTitle = item.torrent_info?.title?.trim().isNotEmpty == true
        ? item.torrent_info?.title?.trim()
        : item.meta_info?.title?.trim();
    final initialSubtitle = item.meta_info?.subtitle?.trim().isNotEmpty == true
        ? item.meta_info?.subtitle?.trim()
        : item.torrent_info?.description?.trim();

    if (Get.isRegistered<RecognizeController>()) {
      Get.delete<RecognizeController>();
    }
    Get.put(
      RecognizeController(
        initialTitle: initialTitle,
        initialSubtitle: initialSubtitle,
      ),
    );
    await showModalBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.36,
        maxChildSize: 1,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: RecognizePage(scrollController: scrollController),
        ),
      ),
    );
    if (Get.isRegistered<RecognizeController>()) {
      Get.delete<RecognizeController>();
    }
  }

  Widget _buildSiteIndicator(BuildContext context) {
    final siteName = _siteName(item);
    final siteId = item.torrent_info?.site;
    final theme = Theme.of(context);
    final controller = Get.isRegistered<SiteController>()
        ? Get.find<SiteController>()
        : Get.put(SiteController());

    return Obx(() {
      SiteItem? siteItem;
      if (siteId != null) {
        for (final value in controller.items) {
          if (value.site.id == siteId) {
            siteItem = value;
            break;
          }
        }
      }

      final icon = _buildSiteIcon(context, controller, siteItem);
      return Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _isInverted()
              ? Colors.white.withValues(alpha: 0.06)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.72,
                ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isInverted()
                ? Colors.white.withValues(alpha: 0.06)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                siteName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor(context),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSiteIcon(
    BuildContext context,
    SiteController controller,
    SiteItem? siteItem,
  ) {
    final bytes = siteItem?.iconBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return _imageFromBytes(bytes);
    }
    if (siteItem != null) {
      final future = _iconFutures.putIfAbsent(
        siteItem.site.id,
        () => controller.loadIcon(siteItem.site),
      );
      return FutureBuilder<List<int>?>(
        future: future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data != null && data.isNotEmpty) {
            return _imageFromBytes(data);
          }
          return _placeholderIcon(context);
        },
      );
    }
    return _placeholderIcon(context);
  }

  Widget _imageFromBytes(List<int> bytes) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Image.memory(
        Uint8List.fromList(bytes),
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(
        Icons.public,
        size: 11,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSeasonChip(
    String text, {
    required Color accent,
    bool dense = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _isInverted() ? 0.26 : 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: _isInverted() ? 0.26 : 0.12),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: dense ? 10 : 11.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, SearchResultItem item) {
    final timeLabel = _timeLabel(item);
    final grabs = item.torrent_info?.grabs ?? 0;
    final freeLabel = _freeDeadlineLabel(item);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildMetaPill(
          context,
          icon: CupertinoIcons.clock,
          label: timeLabel,
          color: const Color(0xFF94A3B8),
        ),
        if (grabs > 0)
          _buildMetaPill(
            context,
            icon: CupertinoIcons.arrow_down_circle,
            label: '$grabs 次下载',
            color: const Color(0xFF22C55E),
          ),
        if (freeLabel != null)
          _buildMetaPill(
            context,
            icon: CupertinoIcons.gift,
            label: freeLabel,
            color: const Color(0xFFF59E0B),
          ),
      ],
    );
  }

  Widget _buildMetaPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _isInverted()
            ? color.withValues(alpha: 0.14)
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: _isInverted() ? 0.20 : 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    bool prominent = false,
  }) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    if (prominent) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: textStyle?.copyWith(
              color: color,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isInverted() ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: textStyle?.copyWith(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizePill(
    BuildContext context,
    SearchResultItem item, {
    bool dense = false,
    bool compact = false,
  }) {
    final accent = themeColor(context);
    final size = item.torrent_info?.size;
    final label = size == null ? '--' : SizeFormatter.formatSize(size, 2);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : (dense ? 9 : 12),
        vertical: compact ? 5 : (dense ? 4 : 6),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 10 : 10),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: _isInverted() ? 0.82 : 0.74),
            accent.withValues(alpha: _isInverted() ? 0.64 : 0.58),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: _isInverted() ? 0.12 : 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : (dense ? 10.5 : 12),
        ),
      ),
    );
  }

  Widget _buildTagSection(
    BuildContext context, {
    required List<_TorrentTag> primaryTags,
    required List<_TorrentTag> secondaryTags,
  }) {
    final visiblePrimary = primaryTags.take(6).toList();
    final visibleSecondary = secondaryTags.take(3).toList();
    final overflowCount =
        primaryTags.length +
        secondaryTags.length -
        visiblePrimary.length -
        visibleSecondary.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visiblePrimary.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...visiblePrimary.map(_buildPrimaryTagChip),
              if (overflowCount > 0)
                _buildMutedTagChip(context, '+$overflowCount'),
            ],
          ),
        if (visibleSecondary.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: visibleSecondary.map((tag) {
              return _buildMutedTagChip(context, tag.text);
            }).toList(),
          ),
        ],
      ],
    );
  }

  List<_TorrentTag> _buildTags(SearchResultItem item, {int? maxCount}) {
    final meta = item.meta_info;
    final torrent = item.torrent_info;
    final tags = <_TorrentTag>[
      if ((meta?.web_source ?? '').isNotEmpty)
        _TorrentTag(text: meta!.web_source!, prominent: true),
      if ((meta?.resource_type ?? '').isNotEmpty)
        _TorrentTag(text: meta!.resource_type!, prominent: true),
      if ((meta?.resource_pix ?? '').isNotEmpty)
        _TorrentTag(text: meta!.resource_pix!, prominent: true),
      if ((meta?.video_encode ?? '').isNotEmpty)
        _TorrentTag(text: meta!.video_encode!, prominent: true),
      if ((meta?.audio_encode ?? '').isNotEmpty)
        _TorrentTag(text: meta!.audio_encode!, prominent: true),
      if ((meta?.resource_effect ?? '').isNotEmpty)
        _TorrentTag(text: meta!.resource_effect!, prominent: true),
      if ((meta?.edition ?? '').isNotEmpty)
        _TorrentTag(text: meta!.edition!, prominent: false),
      if ((meta?.resource_team ?? '').isNotEmpty)
        _TorrentTag(text: meta!.resource_team!, prominent: false),
      ...?torrent?.labels?.map(
        (label) => _TorrentTag(text: label, prominent: false),
      ),
    ];

    final unique = <String>{};
    final result = <_TorrentTag>[];
    for (final tag in tags) {
      final cleaned = tag.text.trim();
      if (cleaned.isEmpty || unique.contains(cleaned)) continue;
      unique.add(cleaned);
      result.add(_TorrentTag(text: cleaned, prominent: tag.prominent));
      if (maxCount != null && result.length >= maxCount) break;
    }
    return result;
  }

  Widget _buildPrimaryTagChip(_TorrentTag tag) {
    final style = _tagStyle(tag.text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: style.background.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        tag.text,
        style: TextStyle(
          color: style.foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMutedTagChip(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _isInverted()
            ? Colors.white.withValues(alpha: 0.05)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isInverted()
              ? Colors.white.withValues(alpha: 0.06)
              : scheme.outlineVariant.withValues(alpha: 0.85),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 10.5,
          color: secondaryTextColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPromotionBadge(
    String text, {
    bool dense = false,
    bool prominent = false,
    bool compact = false,
  }) {
    final color = _promotionColor(text);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: prominent ? (compact ? 10 : 14) : (dense ? 7 : 9),
        vertical: prominent ? (compact ? 6 : 8) : (dense ? 3 : 5),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(prominent ? (compact ? 13 : 16) : 12),
          bottomRight: Radius.circular(prominent ? 0 : 12),
          topLeft: Radius.circular(prominent ? 0 : 12),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: compact ? 6 : 10,
            offset: Offset(0, compact ? 3 : 5),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: prominent ? (compact ? 10.5 : 12) : (dense ? 10 : 11),
        ),
      ),
    );
  }

  _ChipStyle _tagStyle(String text) {
    final normalized = text.toLowerCase();
    if (normalized.contains('apple tv')) {
      return const _ChipStyle(
        background: Color(0xFF7C3AED),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('web-dl') || normalized.contains('webrip')) {
      return const _ChipStyle(
        background: Color(0xFFFF5B3A),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('2160') || normalized == '4k') {
      return const _ChipStyle(
        background: Color(0xFF6D5EF8),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('h265') ||
        normalized.contains('x265') ||
        normalized.contains('10bit')) {
      return const _ChipStyle(
        background: Color(0xFFF59E0B),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('hdr') || normalized.contains('dolby')) {
      return const _ChipStyle(
        background: Color(0xFF8B2BBF),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('atmos') ||
        normalized.contains('ddp') ||
        normalized.contains('dts')) {
      return const _ChipStyle(
        background: Color(0xFFEF4444),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('中字') ||
        normalized.contains('字幕') ||
        normalized.contains('简') ||
        normalized.contains('繁')) {
      return const _ChipStyle(
        background: Color(0xFF6274D8),
        foreground: Colors.white,
      );
    }
    if (normalized.contains('cmctv') ||
        normalized.contains('mteam') ||
        normalized.contains('team') ||
        normalized.contains('aru')) {
      return const _ChipStyle(
        background: Color(0xFF0F9B8E),
        foreground: Colors.white,
      );
    }

    final palette = [
      const _ChipStyle(background: Color(0xFF7C3AED), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFF2563EB), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFF059669), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFFF97316), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFFDB2777), foreground: Colors.white),
      const _ChipStyle(background: Color(0xFF0EA5E9), foreground: Colors.white),
    ];
    final index = text.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[index % palette.length];
  }

  String? _promotionBadgeLabel(SearchResultItem item) {
    final torrent = item.torrent_info;
    if (torrent == null) return null;

    final downloadFactor = torrent.downloadvolumefactor;
    if (downloadFactor != null) {
      if (downloadFactor == 0) return '免费';
      if (downloadFactor > 0 && downloadFactor < 1) {
        return '${(downloadFactor * 100).round()}%';
      }
    }

    final volume = torrent.volume_factor ?? '';
    if (volume.contains('%')) return volume;
    if (volume.contains('免费')) return '免费';
    return null;
  }

  Color _promotionColor(String text) {
    if (text.contains('免费')) return const Color(0xFF94C83D);
    return const Color(0xFFFF6B2C);
  }

  String? _freeDeadlineLabel(SearchResultItem item) {
    final torrent = item.torrent_info;
    final freeDiff = torrent?.freedate_diff?.trim();
    if (freeDiff != null && freeDiff.isNotEmpty) {
      return '限免 $freeDiff';
    }
    final freeDate = torrent?.freedate?.trim();
    if (freeDate != null && freeDate.isNotEmpty) {
      return '限免中';
    }
    if ((torrent?.downloadvolumefactor ?? 1) == 0) {
      return '免费';
    }
    return null;
  }

  String _displayTitle(SearchResultItem item) {
    final mediaTitle = item.media_info?.title?.trim().isNotEmpty == true
        ? item.media_info!.title!.trim()
        : null;
    if (mediaTitle != null) return mediaTitle;

    final meta = item.meta_info;
    return meta?.name?.trim().isNotEmpty == true
        ? meta!.name!.trim()
        : meta?.cn_name?.trim().isNotEmpty == true
        ? meta!.cn_name!.trim()
        : meta?.en_name?.trim().isNotEmpty == true
        ? meta!.en_name!.trim()
        : meta?.title?.trim().isNotEmpty == true
        ? meta!.title!.trim()
        : item.torrent_info?.title ?? '未知标题';
  }

  String? _seasonLabel(SearchResultItem item) {
    final season = item.meta_info?.season_episode?.trim();
    if (season != null && season.isNotEmpty) return season;

    final value = item.meta_info?.begin_season ?? item.meta_info?.total_season;
    if (value != null && value > 0) {
      return 'S${value.toString().padLeft(2, '0')}';
    }
    return null;
  }

  String _siteName(SearchResultItem item) {
    return item.torrent_info?.site_name ?? '未知站点';
  }

  String _timeLabel(SearchResultItem item) {
    final torrent = item.torrent_info;
    final elapsed = torrent?.date_elapsed?.replaceAll('\n', ' ').trim();
    if (elapsed != null && elapsed.isNotEmpty) {
      return elapsed;
    }

    final raw = torrent?.pubdate;
    if (raw == null || raw.isEmpty) return '未知时间';

    final parsed = _parseDate(raw);
    if (parsed == null) return raw;

    final diff = DateTime.now().difference(parsed);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()}年前';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}个月前';
    if (diff.inDays >= 1) return '${diff.inDays}天前';
    if (diff.inHours >= 1) return '${diff.inHours}小时前';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }

  DateTime? _parseDate(String raw) {
    final format = DateFormat('yyyy-MM-dd HH:mm:ss');
    try {
      return format.parseUtc(raw).toLocal();
    } catch (_) {
      try {
        return format.parse(raw);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _openInfoSheet(
    BuildContext context,
    SearchResultItem item,
  ) async {
    WebUtil.open(url: item.torrent_info?.page_url);
  }

  void _openDownloadSheet(BuildContext context, SearchResultItem item) {
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController());
    }
    final downloadController = Get.isRegistered<DownloadController>()
        ? Get.find<DownloadController>()
        : Get.put(DownloadController());
    downloadController.resetSheetTransientState();
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadSheet(item: item),
    );
  }
}

class _ChipStyle {
  const _ChipStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class _TorrentTag {
  const _TorrentTag({required this.text, required this.prominent});

  final String text;
  final bool prominent;
}
