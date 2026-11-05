import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Dashboard 各区块在「已发起请求、数据还没回来」时的占位骨架。
///
/// 这里只描述形状，具体颜色跟随面板配色，深浅色模式都能融入。
class DashboardPosterGridSkeleton extends StatelessWidget {
  const DashboardPosterGridSkeleton({
    super.key,
    this.itemCount = 9,
    this.columns = 3,
    this.aspectRatio = 1 / 1.32,
    this.padding = const EdgeInsets.symmetric(horizontal: 6),
  });

  final int itemCount;
  final int columns;
  final double aspectRatio;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    final rows = (itemCount / columns).ceil();
    return Padding(
      padding: padding,
      child: Skeletonizer(
        child: Column(
          children: [
            for (var row = 0; row < rows; row++) ...[
              Row(
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Bone(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    if (column != columns - 1) const SizedBox(width: gap),
                  ],
                ],
              ),
              if (row != rows - 1) const SizedBox(height: gap),
            ],
          ],
        ),
      ),
    );
  }
}

/// 首屏骨架：配置尚未读到、还无法确定要显示哪些区块时使用。
/// 形状对齐默认布局（状态卡 2x2 + 容量卡 + 媒体浏览 + 图表），
/// 真实区块挂上后按各自身份就地替换。
class DashboardFirstPaintSkeleton extends StatelessWidget {
  const DashboardFirstPaintSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonSectionTitle(width: 48),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 16.0;
              final cardWidth = (constraints.maxWidth - spacing) / 2;
              return Skeletonizer(
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (var index = 0; index < 4; index++)
                      SizedBox(
                        width: cardWidth,
                        child: Bone(
                          height: 108,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          _SkeletonSectionTitle(width: 72),
          const SizedBox(height: 16),
          Skeletonizer(
            child: Bone(height: 168, borderRadius: BorderRadius.circular(18)),
          ),
          const SizedBox(height: 32),
          _SkeletonSectionTitle(width: 64),
          const SizedBox(height: 16),
          const DashboardPosterRailSkeleton(),
          const SizedBox(height: 32),
          _SkeletonSectionTitle(width: 56),
          const SizedBox(height: 16),
          Skeletonizer(
            child: Bone(height: 260, borderRadius: BorderRadius.circular(18)),
          ),
        ],
      ),
    );
  }
}

class _SkeletonSectionTitle extends StatelessWidget {
  const _SkeletonSectionTitle({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Bone(
        width: width,
        height: 20,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// 横向媒体库/轨道骨架
class DashboardPosterRailSkeleton extends StatelessWidget {
  const DashboardPosterRailSkeleton({
    super.key,
    this.height = 202,
    this.itemWidth = 280,
    this.itemCount = 3,
  });

  final double height;
  final double itemWidth;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Skeletonizer(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: itemWidth,
            child: Bone(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

/// 列表型区块（近期整理 / 后台任务）骨架
class DashboardListSkeleton extends StatelessWidget {
  const DashboardListSkeleton({
    super.key,
    this.itemCount = 4,
    this.showPoster = true,
  });

  final int itemCount;
  final bool showPoster;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Skeletonizer(
      child: Column(
        children: [
          for (var index = 0; index < itemCount; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  if (showPoster) ...[
                    Bone(
                      width: 40,
                      height: 54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone(
                          width: double.infinity,
                          height: 13,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        Bone(
                          width: 120,
                          height: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Bone(
                    width: 42,
                    height: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            if (index != itemCount - 1)
              Container(height: 1, color: palette.divider),
          ],
        ],
      ),
    );
  }
}

/// 统计柱状图区块骨架（入库趋势）
class DashboardChartSkeleton extends StatelessWidget {
  const DashboardChartSkeleton({super.key, this.height = 176});

  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Skeletonizer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Bone(
                width: 76,
                height: 22,
                borderRadius: BorderRadius.circular(999),
              ),
              const Spacer(),
              Bone(
                width: 56,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < 7; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Bone(
                        height: 40.0 + (index % 3) * 26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: palette.divider),
        ],
      ),
    );
  }
}
