import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

import '../models/system_message.dart';

class SystemMessageItem extends StatelessWidget {
  const SystemMessageItem({
    super.key,
    required this.message,
    this.onCommandSelected,
  });

  final SystemMessage message;
  final ValueChanged<String>? onCommandSelected;

  static const double _cardRadius = 18;

  @override
  Widget build(BuildContext context) {
    final hasImage = message.image.trim().length > 1;
    final isUserText = message.action == 0 && message.text.trim().isNotEmpty;
    if (isUserText) {
      return _buildUserTextCard(context);
    }
    if (hasImage) {
      return _buildPosterCard(context);
    }
    if (message.note.isNotEmpty) {
      return _buildNoteCard(context);
    }
    return _buildTextCard(context);
  }

  Widget _wrapCard(
    BuildContext context,
    Widget child, {
    required Color accent,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(_cardRadius);
    return Semantics(
      container: true,
      label: '${_messageType(message)}消息',
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.055),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.04 : 0.025),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.32 : 0.46),
          ),
        ),
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }

  String _messageType(SystemMessage message) {
    final isUserText = message.action == 0 && message.text.trim().isNotEmpty;
    if (isUserText) return '用户';
    final t = message.mtype.trim();
    return t.isEmpty ? '消息' : t;
  }

  Widget _buildCardHeader({
    required BuildContext context,
    IconData? icon,
    required Color color,
    required String type,
    required String time,
    Color? chipBackground,
    Color? chipTextColor,
    Color? chipBorderColor,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final resolvedIcon = icon ?? CupertinoIcons.bell_fill;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Icon(resolvedIcon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        _buildTypeChip(
          type,
          background: chipBackground ?? color.withValues(alpha: 0.12),
          textColor: chipTextColor ?? color,
          borderColor: chipBorderColor ?? color.withValues(alpha: 0.20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            time,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style:
                theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ) ??
                TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTextCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final time = DateFormat('MM-dd HH:mm').format(message.regTime);
    final text = message.text.trim();
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary,
                    Color.lerp(cs.primary, cs.secondary, 0.22) ?? cs.primary,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _buildSelectableText(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const accent = CupertinoColors.systemBlue;
    final time = DateFormat('MM-dd HH:mm').format(message.regTime);
    final parsed = _parseText(message.text);
    final meta = parsed.meta;
    final body = parsed.body;
    final commands = parsed.commands;
    final title = message.title.trim();
    return _wrapCard(
      context,
      Section(
        borderRadius: BorderRadius.circular(_cardRadius),
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context: context,
              icon: CupertinoIcons.bell_fill,
              color: CupertinoColors.systemBlue,
              type: _messageType(message),
              time: time,
            ),
            if (title.isNotEmpty) const SizedBox(height: 10),
            if (title.isNotEmpty)
              _buildSelectableText(
                title,
                style:
                    theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ) ??
                    TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
            if (meta.isNotEmpty) const SizedBox(height: 10),
            if (meta.isNotEmpty) _buildMetaRow(context, meta),
            if (body.isNotEmpty) const SizedBox(height: 10),
            if (body.isNotEmpty)
              _buildBodyPanel(
                context,
                body,
                icon: CupertinoIcons.doc_text,
                accent: accent,
              ),
            if (commands.isNotEmpty) const SizedBox(height: 12),
            if (commands.isNotEmpty) _buildCommandActions(context, commands),
          ],
        ),
      ),
      accent: accent,
    );
  }

  Widget _buildPosterCard(BuildContext context) {
    const accent = CupertinoColors.systemOrange;
    final time = DateFormat('MM-dd HH:mm').format(message.regTime);
    final parsed = _parseText(message.text);
    final meta = parsed.meta;
    final body = parsed.body;
    final commands = parsed.commands;
    return _wrapCard(
      context,
      Section(
        borderRadius: BorderRadius.circular(_cardRadius),
        color: Colors.transparent,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 196,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPosterCover(message.image),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xB3000000)],
                        stops: [0.4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelectableText(
                          message.title.trim(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildTypeChip(
                              _messageType(message),
                              background: Colors.white.withValues(alpha: 0.18),
                              textColor: Colors.white,
                              borderColor: Colors.white.withValues(alpha: 0.35),
                            ),
                            const Spacer(),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meta.isNotEmpty) _buildMetaRow(context, meta),
                  if (body.isNotEmpty) const SizedBox(height: 10),
                  if (body.isNotEmpty)
                    _buildBodyPanel(
                      context,
                      body,
                      icon: CupertinoIcons.text_bubble,
                      accent: accent,
                    ),
                  if (commands.isNotEmpty) const SizedBox(height: 12),
                  if (commands.isNotEmpty)
                    _buildCommandActions(context, commands),
                ],
              ),
            ),
          ],
        ),
      ),
      accent: accent,
    );
  }

  Widget _buildNoteCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const accent = CupertinoColors.systemPurple;
    final time = DateFormat('MM-dd HH:mm').format(message.regTime);
    final items = message.note;
    final primary = items.isNotEmpty ? items.first : null;
    final endIndex = items.length > 3 ? 3 : items.length;
    final secondary = items.length > 1
        ? items.sublist(1, endIndex)
        : const <SystemMessageNote>[];
    final siteName = primary?.siteName ?? '';
    final title = primary?.title ?? '';
    final description = primary?.description ?? '';
    final size = _formatBytes(primary?.size ?? 0);
    final seeders = primary?.seeders ?? 0;
    final peers = primary?.peers ?? 0;
    final grabs = primary?.grabs ?? 0;
    final pubdate = primary?.pubdate ?? '';
    final labels = primary?.labels ?? const <String>[];
    final messageTitle = message.title.trim();
    final noteTitle = title.trim();
    final noteDescription = description.trim();
    return _wrapCard(
      context,
      Section(
        borderRadius: BorderRadius.circular(_cardRadius),
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context: context,
              icon: CupertinoIcons.sparkles,
              color: CupertinoColors.systemPurple,
              type: _messageType(message),
              time: time,
            ),
            const SizedBox(height: 10),
            if (messageTitle.isNotEmpty)
              _buildSelectableText(
                messageTitle,
                style:
                    theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ) ??
                    TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
            if (noteTitle.isNotEmpty) const SizedBox(height: 10),
            if (noteTitle.isNotEmpty)
              _buildSelectableText(
                noteTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            if (noteDescription.isNotEmpty) const SizedBox(height: 8),
            if (noteDescription.isNotEmpty)
              _buildBodyPanel(
                context,
                noteDescription,
                icon: CupertinoIcons.text_quote,
                accent: accent,
              ),
            const SizedBox(height: 8),
            _buildUniqueChips([
              if (siteName.isNotEmpty) '站点：$siteName',
              if (size.isNotEmpty) '大小：$size',
              if (seeders > 0) '做种：$seeders',
              if (peers > 0) '下载：$peers',
              if (grabs > 0) '完成：$grabs',
              if (pubdate.isNotEmpty) '发布：$pubdate',
              ...labels.take(6),
            ]),
            if (secondary.isNotEmpty) const SizedBox(height: 10),
            if (secondary.isNotEmpty)
              Column(
                children: secondary
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              CupertinoIcons.circle_fill,
                              size: 6,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildSelectableText(
                                item.title ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
      accent: accent,
    );
  }

  Widget _buildPosterCover(String url) {
    if (url.isEmpty) {
      return Container(
        color: CupertinoColors.systemGrey4,
        child: const Icon(
          CupertinoIcons.photo,
          color: CupertinoColors.white,
          size: 42,
        ),
      );
    }
    return CachedImage(imageUrl: url, fit: BoxFit.cover);
  }

  Widget _buildTypeChip(
    String type, {
    Color? background,
    Color? textColor,
    Color? borderColor,
  }) {
    final baseColor = textColor ?? CupertinoColors.systemBlue;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background ?? baseColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor ?? baseColor.withValues(alpha: 0.45),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            type.isEmpty ? '消息' : type,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: baseColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, List<String> meta) {
    final seen = <String>{};
    final items = <String>[];
    for (final t in meta) {
      final s = t.trim();
      if (s.isEmpty) continue;
      if (seen.add(s)) items.add(s);
      if (items.length >= 8) break;
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        final text = entry.value;
        return _buildMetaTile(
          context,
          text,
          color: _pickMetaColor(text) ?? _pickChipColor(text, entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildMetaTile(BuildContext context, String text, {Color? color}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final baseColor = color ?? cs.primary;
    final parts = _splitMetaText(text);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 34, maxWidth: 168),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.28 : 0.58,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.34)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.88),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${parts.key} ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      TextSpan(
                        text: parts.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniqueChips(List<String> raw) {
    final seen = <String>{};
    final chips = <String>[];
    for (final t in raw) {
      final s = t.trim();
      if (s.isEmpty) continue;
      if (seen.add(s)) chips.add(s);
      if (chips.length >= 8) break;
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips.asMap().entries.map((entry) {
        final text = entry.value;
        return _buildMetaChip(
          text,
          color: _pickMetaColor(text) ?? _pickChipColor(text, entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildMetaChip(String text, {Color? color}) {
    final baseColor = color ?? CupertinoColors.systemBlue;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: baseColor.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: baseColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyPanel(
    BuildContext context,
    String text, {
    required IconData icon,
    required Color accent,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.24 : 0.46,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _buildSelectableText(
              text,
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                    height: 1.48,
                    color: cs.onSurfaceVariant,
                  ) ??
                  TextStyle(
                    fontSize: 14,
                    height: 1.48,
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandActions(BuildContext context, List<String> commands) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '可执行操作',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          ...commands.map(
            (command) => CupertinoButton(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              borderRadius: BorderRadius.circular(999),
              color: cs.primary,
              onPressed: onCommandSelected == null
                  ? null
                  : () => onCommandSelected!(command),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.arrow_turn_down_right,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    command,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableText(
    String text, {
    required TextStyle style,
    TextAlign? textAlign,
  }) {
    return SelectableText(
      text,
      style: style,
      textAlign: textAlign,
      contextMenuBuilder: (context, editableTextState) {
        final selection = editableTextState.currentTextEditingValue.selection;
        final selectedText = selection.textInside(
          editableTextState.textEditingValue.text,
        );
        final url = _extractUrl(selectedText);
        final items = editableTextState.contextMenuButtonItems.toList();
        if (url != null) {
          items.add(
            ContextMenuButtonItem(
              label: '打开链接',
              onPressed: () {
                editableTextState.hideToolbar();
                WebUtil.open(url: url);
              },
            ),
          );
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: items,
        );
      },
    );
  }

  _ParsedText _parseText(String text) {
    final metaMap = <String, String>{};
    final remain = <String>[];
    final commands = <String>{};
    final lines = text.split('\n');
    var inFence = false;
    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        continue;
      }
      if (trimmed.startsWith('如果按钮不可用')) {
        continue;
      }
      final command = _extractCommand(trimmed);
      if (command != null) {
        commands.add(command);
        continue;
      }
      if (inFence) {
        continue;
      }
      final parts = line.split('：');
      if (parts.length >= 2) {
        final key = parts.first.trim();
        final value = parts.sublist(1).join('：').trim();
        if (value.isNotEmpty &&
            ['站点', '质量', '大小', '评分', '类型', '类别', '标签'].contains(key)) {
          _addMetaEntries(metaMap, line);
          continue;
        }
      }
      remain.add(line);
    }
    final meta = metaMap.entries.map((e) => '${e.key}：${e.value}').toList();
    final body = remain.join('\n').trim();
    return _ParsedText(meta: meta, body: body, commands: commands.toList());
  }

  void _addMetaEntries(Map<String, String> metaMap, String line) {
    final normalized = line.replaceAll('，', ',');
    final matches = RegExp(
      r'(站点|质量|大小|评分|类型|类别|标签)[:：]\s*([^,，]+)',
    ).allMatches(normalized);
    if (matches.isEmpty) {
      final parts = line.split('：');
      if (parts.length >= 2) {
        final key = parts.first.trim();
        final value = parts.sublist(1).join('：').trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          metaMap.putIfAbsent(key, () => value);
        }
      }
      return;
    }
    for (final match in matches) {
      final key = match.group(1)?.trim() ?? '';
      final value = match.group(2)?.trim() ?? '';
      if (key.isNotEmpty && value.isNotEmpty) {
        metaMap.putIfAbsent(key, () => value);
      }
    }
  }

  _MetaParts _splitMetaText(String text) {
    final index = text.indexOf('：');
    if (index <= 0) {
      final fallbackIndex = text.indexOf(':');
      if (fallbackIndex <= 0) return _MetaParts(key: '', value: text);
      return _MetaParts(
        key: text.substring(0, fallbackIndex).trim(),
        value: text.substring(fallbackIndex + 1).trim(),
      );
    }
    return _MetaParts(
      key: text.substring(0, index).trim(),
      value: text.substring(index + 1).trim(),
    );
  }

  String? _extractCommand(String text) {
    final match = RegExp(
      r'^/(redo)\s+\d+$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    return text;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    const k = 1024;
    if (bytes < k) return '$bytes B';
    if (bytes < k * k) return '${(bytes / k).toStringAsFixed(1)} KB';
    if (bytes < k * k * k) {
      return '${(bytes / (k * k)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (k * k * k)).toStringAsFixed(2)} GB';
  }

  Color _pickChipColor(String text, int index) {
    const palette = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemPurple,
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPink,
    ];
    final hash = text.codeUnits.fold(0, (sum, unit) => sum + unit);
    return palette[(hash + index) % palette.length];
  }

  Color? _pickMetaColor(String text) {
    if (text.startsWith('站点')) return CupertinoColors.systemBlue;
    if (text.startsWith('大小')) return CupertinoColors.systemGreen;
    if (text.startsWith('做种')) return CupertinoColors.systemOrange;
    if (text.startsWith('下载')) return CupertinoColors.systemPurple;
    if (text.startsWith('完成')) return CupertinoColors.systemTeal;
    if (text.startsWith('发布')) return CupertinoColors.systemIndigo;
    if (text.startsWith('评分')) return CupertinoColors.activeGreen;
    if (text.startsWith('类型')) return CupertinoColors.systemPurple;
    if (text.startsWith('类别')) return CupertinoColors.systemTeal;
    if (text.startsWith('标签')) return CupertinoColors.systemOrange;
    return null;
  }

  String? _extractUrl(String text) {
    final match = RegExp(
      r'(https?:\/\/\S+|www\.\S+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    var url = match.group(0) ?? '';
    url = url.replaceAll(RegExp(r'[)\],.;:]+$'), '');
    return url.isEmpty ? null : url;
  }
}

class _ParsedText {
  const _ParsedText({
    required this.meta,
    required this.body,
    required this.commands,
  });
  final List<String> meta;
  final String body;
  final List<String> commands;
}

class _MetaParts {
  const _MetaParts({required this.key, required this.value});

  final String key;
  final String value;
}
