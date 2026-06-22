import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_controller.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

enum SubscribeItemCardType {
  edit,
  search,
  detail,
  pause,
  resume,
  reset,
  shared,
  delete,
}

enum SubscribeItemCardLayout { list, grid }

class SubscribeItemCard extends StatelessWidget {
  const SubscribeItemCard({
    super.key,
    required this.item,
    required this.isTv,
    this.layout = SubscribeItemCardLayout.list,
    this.onTap,
    this.onMoreTap,
  });

  final SubscribeItem item;
  final bool isTv;
  final SubscribeItemCardLayout layout;
  final VoidCallback? onTap;
  final Function(SubscribeItemCardType type)? onMoreTap;

  static const double _cardRadius = 22;
  static const double _listCardHeight = 220;
  static const double _posterWidth = 84;
  static const double _posterHeight = 124;

  @override
  Widget build(BuildContext context) {
    return layout == SubscribeItemCardLayout.grid
        ? _buildGridCard(context)
        : _buildListCard(context);
  }

  Widget _buildListCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: onTap,
        child: Container(
          height: _listCardHeight,
          decoration: _cardDecoration(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackdrop(),
                Positioned.fill(child: _buildGradientOverlay()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildMetaPill(
                                label: _stateLabel,
                                color: _stateColor,
                              ),
                              if ((item.year ?? '').isNotEmpty)
                                _buildMetaPill(
                                  label: item.year!,
                                  color: Colors.white.withValues(alpha: 0.16),
                                  textColor: Colors.white,
                                ),
                            ],
                          ),
                          const Spacer(),
                          _buildMoreButton(context),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildPosterThumb(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _titleWithSeason,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_subtitle.isNotEmpty)
                                  Text(
                                    _subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                _buildFooterMetrics(
                                  compact: false,
                                  timeAtTrailing: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_hasProgressBar) ...[
                        const SizedBox(height: 10),
                        _buildProgressSection(compact: false),
                      ],
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

  Widget _buildGridCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardRadius),
        onTap: onTap,
        child: Container(
          decoration: _cardDecoration(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Column(
              children: [
                Expanded(
                  flex: 7,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildBackdrop(),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.58),
                              ],
                              stops: const [0, 0.45, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _buildMetaPill(
                          label: _stateLabel,
                          color: _stateColor,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: _buildMoreButton(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0F1723), Color(0xFF131E2B)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleWithSeason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_subtitle.isNotEmpty)
                          Text(
                            _subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: Colors.white.withValues(alpha: 0.74),
                            ),
                          ),
                        const Spacer(),
                        _buildFooterMetrics(
                          compact: true,
                          timeAtTrailing: false,
                        ),
                        if (_hasProgressBar) ...[
                          const SizedBox(height: 10),
                          _buildProgressSection(compact: true),
                        ],
                      ],
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

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ],
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 0.8,
      ),
    );
  }

  Widget _buildBackdrop() {
    var url = item.backdrop;
    if (url == null || url.isEmpty) url = item.poster;
    if (url != null && url.isNotEmpty) {
      url = ImageUtil.convertCacheImageUrl(url);
      return CachedImage(imageUrl: url, fit: BoxFit.cover);
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF30435D), Color(0xFF192436)],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.28),
            Colors.black.withValues(alpha: 0.82),
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
    );
  }

  Widget _buildMetaPill({
    required String label,
    required Color color,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }

  Widget _buildFooterMetrics({
    required bool compact,
    required bool timeAtTrailing,
  }) {
    final textColor = Colors.white.withValues(alpha: 0.88);
    final secondaryColor = Colors.white.withValues(alpha: 0.58);
    final userTextColor = const Color(0xFFFFD166);
    final userIconColor = const Color(0xFFFFB84D);
    final fontSize = compact ? 10.5 : 11.5;
    final spacing = compact ? 8.0 : 10.0;

    final children = <Widget>[
      Expanded(
        flex: compact ? 4 : 5,
        child: _buildInlineMetric(
          icon: CupertinoIcons.person_fill,
          label: item.username ?? 'admin',
          fontSize: fontSize,
          textColor: userTextColor,
          iconColor: userIconColor,
        ),
      ),
      if (isTv && _hasEpisodeInfo) ...[
        SizedBox(width: spacing),
        Expanded(
          flex: compact ? 3 : 4,
          child: _buildInlineMetric(
            icon: CupertinoIcons.play_rectangle_fill,
            label: _episodeProgress,
            fontSize: fontSize,
            textColor: textColor,
            iconColor: secondaryColor,
          ),
        ),
      ],
      SizedBox(width: spacing),
      Expanded(
        flex: compact ? 4 : 3,
        child: _buildInlineMetric(
          icon: CupertinoIcons.time,
          label: SubscribeController.formatRelativeTime(
            item.lastUpdate ?? item.date,
          ),
          fontSize: fontSize,
          textColor: textColor,
          iconColor: secondaryColor,
          alignEnd: timeAtTrailing,
        ),
      ),
    ];

    return Row(children: children);
  }

  Widget _buildInlineMetric({
    required IconData icon,
    required String label,
    required double fontSize,
    required Color textColor,
    required Color iconColor,
    bool alignEnd = false,
  }) {
    return Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPosterThumb() {
    var url = item.poster;
    if (url != null && url.isNotEmpty) {
      url = ImageUtil.convertCacheImageUrl(url);
      return Container(
        width: _posterWidth,
        height: _posterHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: _posterWidth,
            height: _posterHeight,
          ),
        ),
      );
    }
    return Container(
      width: _posterWidth,
      height: _posterHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.16),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    final isPaused = item.state?.toUpperCase() == 'S';
    final isRunning = item.state?.toUpperCase() == 'R';
    final items = [
      SubscribeItemCardType.edit,
      SubscribeItemCardType.search,
      SubscribeItemCardType.detail,
    ];
    if (isPaused) {
      items.add(SubscribeItemCardType.resume);
    }
    if (isRunning) {
      items.add(SubscribeItemCardType.pause);
    }
    items.add(SubscribeItemCardType.reset);
    if (isTv) {
      items.add(SubscribeItemCardType.shared);
    }
    items.add(SubscribeItemCardType.delete);
    return PopupMenuButton(
      onSelected: onMoreTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: EdgeInsets.zero,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      offset: const Offset(0, 10),
      surfaceTintColor: Colors.white,
      itemBuilder: (context) => items
          .map(
            (e) => PopupMenuItem(
              value: e,
              child: Row(
                children: [
                  Icon(_iconButton(e), size: 16, color: _iconButtonColor(e)),
                  const SizedBox(width: 8),
                  Text(
                    _iconButtonLabel(e),
                    style: TextStyle(fontSize: 14, color: _iconButtonColor(e)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Icon(Icons.more_horiz, size: 16, color: Colors.white),
      ),
    );
  }

  IconData _iconButton(SubscribeItemCardType type) {
    switch (type) {
      case SubscribeItemCardType.edit:
        return Icons.edit;
      case SubscribeItemCardType.detail:
        return Icons.info;
      case SubscribeItemCardType.pause:
        return Icons.pause;
      case SubscribeItemCardType.resume:
        return Icons.play_arrow;
      case SubscribeItemCardType.reset:
        return Icons.refresh;
      case SubscribeItemCardType.shared:
        return Icons.share;
      case SubscribeItemCardType.delete:
        return Icons.delete;
      case SubscribeItemCardType.search:
        return Icons.search;
    }
  }

  String _iconButtonLabel(SubscribeItemCardType type) {
    switch (type) {
      case SubscribeItemCardType.edit:
        return '编辑';
      case SubscribeItemCardType.detail:
        return '详情';
      case SubscribeItemCardType.pause:
        return '暂停';
      case SubscribeItemCardType.resume:
        return '继续';
      case SubscribeItemCardType.reset:
        return '重置';
      case SubscribeItemCardType.shared:
        return '分享';
      case SubscribeItemCardType.delete:
        return '删除';
      case SubscribeItemCardType.search:
        return '搜索';
    }
  }

  Color _iconButtonColor(SubscribeItemCardType type) {
    switch (type) {
      case SubscribeItemCardType.edit:
        return Colors.blue;
      case SubscribeItemCardType.detail:
        return Colors.green;
      case SubscribeItemCardType.pause:
        return Colors.orange;
      case SubscribeItemCardType.resume:
        return Colors.green;
      case SubscribeItemCardType.reset:
        return Colors.blue;
      case SubscribeItemCardType.shared:
        return Colors.purple;
      case SubscribeItemCardType.delete:
        return Colors.red;
      case SubscribeItemCardType.search:
        return Colors.blue;
    }
  }

  Widget _buildProgressSection({required bool compact}) {
    return _buildProgressBar();
  }

  Widget _buildProgressBar() {
    final total = item.totalEpisode ?? 1;
    final current = total - (item.lackEpisode ?? total);
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.6,
        ),
      ),
      child: FractionallySizedBox(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7DD3FC).withValues(alpha: 0.95),
                const Color(0xFF38BDF8).withValues(alpha: 0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _titleWithSeason {
    final name = item.name ?? '未知';
    if (isTv && item.season != null && item.season! > 0) {
      return '$name S${item.season.toString().padLeft(2, '0')}';
    }
    return name;
  }

  String get _subtitle {
    final values = <String>[
      if ((item.type ?? '').isNotEmpty) item.type!,
      if ((item.description ?? '').isNotEmpty) item.description!,
    ];
    return values.join(' · ');
  }

  bool get _hasProgressBar {
    if (!isTv) return false;
    final total = item.totalEpisode;
    return total != null && total > 0;
  }

  bool get _hasEpisodeInfo {
    final total = item.totalEpisode;
    final lack = item.lackEpisode;
    return (total != null && total > 0) || (lack != null && lack >= 0);
  }

  String get _episodeProgress {
    final total = item.totalEpisode ?? 0;
    final lack = item.lackEpisode ?? total;
    final current = total > 0 ? (total - lack).clamp(0, total) : 0;
    return '$current / $total';
  }

  String get _stateLabel {
    if (item.bestVersion != null && item.bestVersion != 0) {
      return '刷版';
    }
    switch (item.state?.trim().toUpperCase()) {
      case 'R':
        return '订阅中';
      case 'N':
        return '未开始';
      case 'S':
        return '已暂停';
      case 'P':
        return '暂停';
      default:
        return '待定';
    }
  }

  Color get _stateColor {
    if (item.bestVersion != null && item.bestVersion != 0) {
      return const Color(0xFF8B5CF6).withValues(alpha: 0.82);
    }
    switch (item.state?.trim().toUpperCase()) {
      case 'R':
        return const Color(0xFF16A34A).withValues(alpha: 0.84);
      case 'N':
        return const Color(0xFF0284C7).withValues(alpha: 0.84);
      case 'S':
      case 'P':
        return const Color(0xFFF59E0B).withValues(alpha: 0.84);
      default:
        return Colors.white.withValues(alpha: 0.16);
    }
  }
}
