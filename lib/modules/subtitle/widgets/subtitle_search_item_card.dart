import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/download/controllers/download_controller.dart';
import 'package:moviepilot_mobile/modules/setting/controllers/setting_controller.dart';
import 'package:moviepilot_mobile/modules/subtitle/models/subtitle_search_models.dart';
import 'package:moviepilot_mobile/modules/subtitle/widgets/subtitle_download_sheet.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class SubtitleSearchItemCard extends StatelessWidget {
  const SubtitleSearchItemCard({
    super.key,
    required this.item,
    this.immersive = false,
    this.downloading = false,
  });

  final SubtitleSearchItem item;
  final bool immersive;
  final bool downloading;

  Color _cardColor(BuildContext context) => immersive
      ? Color.alphaBlend(
          Colors.black.withValues(alpha: 0.18),
          AppTheme.darkCardBackgroundColor,
        )
      : Theme.of(context).colorScheme.surface;

  Color _cardBottomTint(BuildContext context) => immersive
      ? const Color(0xFF101826)
      : Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.76);

  Color _borderColor(BuildContext context) => immersive
      ? Colors.white.withValues(alpha: 0.08)
      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.32);

  Color _primaryText(BuildContext context) => immersive
      ? Colors.white
      : Theme.of(context).colorScheme.onSurface;

  Color _secondaryText(BuildContext context) => immersive
      ? Colors.white.withValues(alpha: 0.72)
      : Theme.of(context).colorScheme.onSurfaceVariant;

  Color _accent(BuildContext context) => immersive
      ? CupertinoColors.activeBlue
      : Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final title = (item.title ?? '').trim().isEmpty ? '未命名字幕' : item.title!;
    final language = (item.language ?? '').trim();
    final siteName = (item.siteName ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: downloading
            ? null
            : () {
                HapticFeedback.selectionClick();
                _openDownloadSheet(context);
              },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor(context)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardColor(context), _cardBottomTint(context)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: immersive ? 0.18 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 14,
                  bottom: 14,
                  child: Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(999),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: _primaryText(context),
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TrailingBadge(
                            downloading: downloading,
                            immersive: immersive,
                            accent: accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (siteName.isNotEmpty)
                            _MetaChip(
                              text: siteName,
                              immersive: immersive,
                              emphasized: true,
                              accent: accent,
                            ),
                          if (language.isNotEmpty)
                            _LanguageChip(
                              language: language,
                              iconUrl: item.languageIcon,
                              immersive: immersive,
                              accent: accent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _MetaFooter(
                        item: item,
                        color: _secondaryText(context),
                      ),
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

  void _openDownloadSheet(BuildContext context) {
    if (!Get.isRegistered<SettingController>()) {
      Get.put(SettingController());
    }
    final downloadController = Get.isRegistered<DownloadController>()
        ? Get.find<DownloadController>()
        : Get.put(DownloadController());
    downloadController.resetSheetTransientState();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubtitleDownloadSheet(item: item),
    );
  }
}

class _TrailingBadge extends StatelessWidget {
  const _TrailingBadge({
    required this.downloading,
    required this.immersive,
    required this.accent,
  });

  final bool downloading;
  final bool immersive;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (downloading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: accent,
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: immersive ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        CupertinoIcons.cloud_download,
        size: 16,
        color: accent,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.text,
    required this.immersive,
    required this.emphasized,
    required this.accent,
  });

  final String text;
  final bool immersive;
  final bool emphasized;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fg = emphasized
        ? accent
        : (immersive
              ? Colors.white.withValues(alpha: 0.78)
              : Theme.of(context).colorScheme.onSurfaceVariant);
    final bg = emphasized
        ? accent.withValues(alpha: immersive ? 0.18 : 0.12)
        : (immersive
              ? Colors.white.withValues(alpha: 0.08)
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.language,
    required this.iconUrl,
    required this.immersive,
    required this.accent,
  });

  final String language;
  final String? iconUrl;
  final bool immersive;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final icon = (iconUrl ?? '').trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: immersive ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: CachedImage(
                imageUrl: icon,
                width: 16,
                height: 11,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 5),
          ] else
            Icon(CupertinoIcons.flag_fill, size: 12, color: accent),
          if (icon.isEmpty) const SizedBox(width: 4),
          Text(
            language,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaFooter extends StatelessWidget {
  const _MetaFooter({required this.item, required this.color});

  final SubtitleSearchItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (item.size != null && item.size! > 0)
        SizeFormatter.formatSize(item.size, 1),
      if ((item.dateElapsed ?? '').trim().isNotEmpty) item.dateElapsed!.trim(),
      if (item.grabs != null) '↓${item.grabs}',
      if ((item.uploader ?? '').trim().isNotEmpty) item.uploader!.trim(),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
