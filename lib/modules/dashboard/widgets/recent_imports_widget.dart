import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_skeletons.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

/// 近期整理组件：最近成功整理入库的媒体记录，对应 Web 端仪表板的「近期整理」卡片
class RecentImportsWidget extends StatelessWidget {
  const RecentImportsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final palette = DashboardPalette.of(context);

    return Obx(() {
      final items = controller.recentImports;
      if (items.isEmpty) {
        if (controller.isWidgetLoading('近期整理')) {
          return const DashboardListSkeleton(itemCount: 4);
        }
        return const DashboardEmptyState(
          icon: CupertinoIcons.film,
          title: '暂无近期整理记录',
          subtitle: '整理成功的媒体会出现在这里',
        );
      }

      return Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _RecentImportRow(item: items[index]),
            if (index != items.length - 1)
              Container(height: 1, color: palette.divider),
          ],
        ],
      );
    });
  }
}

class _RecentImportRow extends StatelessWidget {
  const _RecentImportRow({required this.item});

  final MediaOrganizeTransferItem item;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final title = (item.title ?? '').trim();
    final year = (item.year ?? '').trim();
    final image = (item.image ?? '').trim();
    final detailPath = _detailPath();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: detailPath == null ? null : () => _openDetail(detailPath),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 40,
                  height: 54,
                  child: image.isEmpty
                      ? _buildPosterPlaceholder(palette)
                      : CachedImage(
                          imageUrl: image,
                          width: 40,
                          height: 54,
                          fit: BoxFit.cover,
                          errorWidget: _buildPosterPlaceholder(palette),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      year.isEmpty ? title : '$title ($year)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: palette.titleText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _buildMeta(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatRelativeTime(item.date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.faintText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 15,
                    color: palette.successAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosterPlaceholder(DashboardPaletteData palette) {
    return Container(
      color: palette.surfaceAlt,
      alignment: Alignment.center,
      child: Icon(CupertinoIcons.film, size: 16, color: palette.faintText),
    );
  }

  /// 组合媒体类型、季集与文件大小作为副标题
  String _buildMeta() {
    final parts = <String>[];
    void add(String? value) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) parts.add(text);
    }

    add(item.type);
    add(item.seasons);
    add(item.episodes);
    final size = item.src_fileitem?.size ?? 0;
    if (size > 0) parts.add(SizeFormatter.formatSize(size, 1));
    return parts.join(' · ');
  }

  String? _detailPath() {
    final tmdbId = item.tmdbid;
    if (tmdbId != null && tmdbId > 0) return 'tmdb:$tmdbId';
    final doubanId = item.doubanid;
    if (doubanId != null && doubanId > 0) return 'douban:$doubanId';
    return null;
  }

  void _openDetail(String path) {
    final title = (item.title ?? '').trim();
    final year = (item.year ?? '').trim();
    final type = (item.type ?? '').trim();
    Get.toNamed(
      '/media-detail',
      parameters: {
        'path': path,
        if (title.isNotEmpty) 'title': title,
        if (year.isNotEmpty) 'year': year,
        if (type.isNotEmpty) 'type_name': type,
      },
    );
  }

  /// 将整理时间转换为相对时间文案
  static String _formatRelativeTime(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return '';
    final time = DateTime.tryParse(text.replaceFirst(' ', 'T'));
    if (time == null) return text;
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '$month-$day';
  }
}
