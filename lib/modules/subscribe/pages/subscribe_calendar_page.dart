import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_calendar_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_calendar_models.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

String get _todayUtcString =>
    DateTime.now().toUtc().toIso8601String().substring(0, 10);

DateTime? _tryParseDate(String value) {
  if (value.isEmpty || value == '未定') return null;
  return DateTime.tryParse(value);
}

String _weekdayLabel(String value) {
  final date = _tryParseDate(value);
  if (date == null) return '待定';
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return labels[date.weekday - 1];
}

String _shortDateLabel(String value) {
  final date = _tryParseDate(value);
  if (date == null) return value;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day';
}

class SubscribeCalendarPage extends GetView<SubscribeCalendarController> {
  const SubscribeCalendarPage({super.key});

  static const double _horizontalPadding = 16;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
        CupertinoColors.systemGroupedBackground,
        context,
      ),
      appBar: AppBar(
        title: const Text('订阅日历'),
        centerTitle: false,
        actions: [_buildExpiredToggle(context)],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildExpiredToggle(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final enabled = controller.hideExpired.value;
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          borderRadius: BorderRadius.circular(999),
          onPressed: controller.toggleHideExpired,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                size: 16,
                color: enabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                enabled ? '隐藏过期' : '显示全部',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final error = controller.errorText.value;
      final items = controller.visibleItems;
      final grouped = controller.visibleItemsGroupedByDate;
      final options = controller.showOptions;
      final selectedShowKey = controller.selectedShowKey.value;

      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            14,
            _horizontalPadding,
            24,
          ),
          children: [
            if (options.isNotEmpty) ...[_buildShowFilter(context, options)],
            const SizedBox(height: 18),
            if (loading && items.isEmpty)
              _StateCard.loading()
            else if (error != null && items.isEmpty)
              _StateCard.error(message: error, onRetry: controller.load)
            else if (items.isEmpty)
              _StateCard.empty(
                message: selectedShowKey == null ? '暂无剧集日历' : '当前筛选条件下暂无剧集',
              )
            else
              ..._buildGroupedContent(grouped),
          ],
        ),
      );
    });
  }

  Widget _buildShowFilter(
    BuildContext context,
    List<MapEntry<String, String>> options,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.secondarySystemGroupedBackground,
          context,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '剧集筛选',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${options.length + 1} 项',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: '全部',
                  selected: controller.selectedShowKey.value == null,
                  onTap: () => controller.setShowFilter(null),
                ),
                ...options.map(
                  (e) => _FilterChip(
                    label: e.value,
                    selected: controller.selectedShowKey.value == e.key,
                    onTap: () => controller.setShowFilter(e.key),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedContent(
    List<MapEntry<String, List<CalendarEpisodeItem>>> grouped,
  ) {
    final widgets = <Widget>[];
    for (final entry in grouped) {
      widgets.add(_DayHeader(date: entry.key, itemCount: entry.value.length));
      for (var index = 0; index < entry.value.length; index++) {
        widgets.add(
          _TimelineEpisodeTile(
            item: entry.value[index],
            isFirst: index == 0,
            isLast: index == entry.value.length - 1,
          ),
        );
      }
    }
    return widgets;
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.itemCount});

  final String date;
  final int itemCount;

  bool get _isPast =>
      date.isNotEmpty && date != '未定' && date.compareTo(_todayUtcString) < 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = date == _todayUtcString;
    final isUndated = date == '未定';
    final isPast = _isPast;

    final title = isToday
        ? '今天'
        : isUndated
        ? '未定'
        : _shortDateLabel(date);
    final subtitle = isToday
        ? '今天更新'
        : isUndated
        ? '播出时间待定'
        : _weekdayLabel(date);

    final accentColor = isToday
        ? theme.colorScheme.primary
        : isUndated
        ? theme.colorScheme.tertiary
        : isPast
        ? theme.colorScheme.outline
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$itemCount 集',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : CupertinoDynamicColor.resolve(
                CupertinoColors.tertiarySystemGroupedBackground,
                context,
              ),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineEpisodeTile extends StatelessWidget {
  const _TimelineEpisodeTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  static const double _timelineLineWidth = 2;
  static const double _dotSize = 10;
  static const double _posterWidth = 92;
  static const double _posterHeight = 124;

  final CalendarEpisodeItem item;
  final bool isFirst;
  final bool isLast;

  bool get _isPast =>
      item.airDate.isNotEmpty && item.airDate.compareTo(_todayUtcString) < 0;

  bool get _isToday => item.airDate == _todayUtcString;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ep = item.episode;
    final seasonNumber = ep.seasonNumber ?? item.seasonNumber;
    final episodeNumber = ep.episodeNumber;
    final lineColor = _isToday
        ? theme.colorScheme.primary.withValues(alpha: 0.28)
        : _isPast
        ? theme.colorScheme.outline.withValues(alpha: 0.14)
        : theme.colorScheme.outline.withValues(alpha: 0.2);
    final dotColor = _isToday
        ? theme.colorScheme.primary
        : _isPast
        ? theme.colorScheme.outline
        : theme.colorScheme.secondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: _timelineLineWidth,
                    height: 6,
                    color: lineColor,
                  ),
                Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: _timelineLineWidth,
                      margin: const EdgeInsets.only(top: 2),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondarySystemGroupedBackground,
                    context,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPoster(context, episodeNumber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  ep.name ?? '第 ${episodeNumber ?? 0} 集',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusPill(
                                label: _statusText,
                                color: _statusColor(theme),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.showName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _SeasonEpisodePill(
                                label:
                                    'S$seasonNumber${episodeNumber == null ? '' : 'E$episodeNumber'}',
                              ),
                              if (ep.runtime != null && ep.runtime! > 0)
                                _MetaPill(label: '${ep.runtime} 分钟'),
                              _MetaPill(label: _subtitleText),
                            ],
                          ),
                          if (ep.overview != null &&
                              ep.overview!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              ep.overview!.trim(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  String get _subtitleText {
    if (item.airDate.isEmpty) return '播出待定';
    final weekday = _weekdayLabel(item.airDate);
    if (_isToday) return '今天更新';
    if (_isPast) return '${_shortDateLabel(item.airDate)} · $weekday';
    return '${_shortDateLabel(item.airDate)} · $weekday';
  }

  String get _statusText {
    if (item.airDate.isEmpty) return '待定';
    if (_isToday) return '今天';
    if (_isPast) return '已播';
    return '即将播出';
  }

  Color _statusColor(ThemeData theme) {
    if (item.airDate.isEmpty) return theme.colorScheme.tertiary;
    if (_isToday) return theme.colorScheme.primary;
    if (_isPast) return theme.colorScheme.outline;
    return theme.colorScheme.secondary;
  }

  Widget _buildPoster(BuildContext context, int? episodeNumber) {
    final theme = Theme.of(context);
    final ep = item.episode;
    String? url = ep.stillPath;
    if (url == null || url.isEmpty) url = item.showPoster;

    final posterChild = (url != null && url.isNotEmpty)
        ? CachedImage(
            imageUrl: _normalizePosterUrl(url),
            fit: BoxFit.cover,
            width: _posterWidth,
            height: _posterHeight,
          )
        : Container(
            width: _posterWidth,
            height: _posterHeight,
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.tertiarySystemGroupedBackground,
                context,
              ),
            ),
            child: Icon(
              CupertinoIcons.tv,
              color: theme.colorScheme.outline,
              size: 28,
            ),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          posterChild,
          if (episodeNumber != null)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.54),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'EP $episodeNumber',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _normalizePosterUrl(String url) {
    var normalized = url;
    if (!normalized.startsWith('http')) {
      normalized = 'https://image.tmdb.org/t/p/w500$normalized';
    }
    return ImageUtil.convertCacheImageUrl(normalized);
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.tertiarySystemGroupedBackground,
          context,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SeasonEpisodePill extends StatelessWidget {
  const _SeasonEpisodePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard._({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.loading = false,
  });

  factory _StateCard.loading() {
    return const _StateCard._(
      icon: CupertinoIcons.refresh,
      title: '正在整理剧集日历',
      message: '稍等一下，马上就好',
      loading: true,
    );
  }

  factory _StateCard.empty({required String message}) {
    return _StateCard._(
      icon: CupertinoIcons.calendar_badge_minus,
      title: '这里暂时还是空的',
      message: message,
    );
  }

  factory _StateCard.error({
    required String message,
    required VoidCallback onRetry,
  }) {
    return _StateCard._(
      icon: CupertinoIcons.exclamationmark_triangle,
      title: '加载失败',
      message: message,
      onRetry: onRetry,
    );
  }

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.secondarySystemGroupedBackground,
          context,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.tertiarySystemFill,
                context,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: onRetry,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              borderRadius: BorderRadius.circular(999),
              child: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}
