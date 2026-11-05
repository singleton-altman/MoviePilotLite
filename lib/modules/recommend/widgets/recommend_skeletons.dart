import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 推荐页是深色底，默认的浅灰微光在这里会刺眼，换成低对比度的深色微光。
const ShimmerEffect _recommendShimmer = ShimmerEffect(
  baseColor: Color(0xFF16211F),
  highlightColor: Color(0xFF243130),
);

/// 推荐页各分区的首屏骨架。
///
/// 分区标题来自本地静态配置，数据未回来时标题是确定的，所以骨架保留标题
/// （由调用方传入真实的 header），只把内容换成同尺寸的占位块。尺寸与真实
/// 卡片对齐，数据到达后就地替换，不产生布局跳动。
class RecommendBannerSkeleton extends StatelessWidget {
  const RecommendBannerSkeleton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      effect: _recommendShimmer,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const Bone(),
      ),
    );
  }
}

/// 横向海报轨道（对应 200 高的 ListView.separated）
class RecommendPosterRailSkeleton extends StatelessWidget {
  const RecommendPosterRailSkeleton({super.key, required this.header});

  final Widget header;

  static const int _itemCount = 6;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Skeletonizer(
          effect: _recommendShimmer,
          child: SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: _itemCount,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Bone(
                width: 150,
                height: 200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// 正在热映轨道（180 高、116 宽的竖版卡片）
class RecommendNowPlayingSkeleton extends StatelessWidget {
  const RecommendNowPlayingSkeleton({super.key, required this.header});

  final Widget header;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Skeletonizer(
          effect: _recommendShimmer,
          child: SizedBox(
            height: 180,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => Bone(
                width: 116,
                height: 180,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// 主推卡片区（一张大图 + 两张次图）
class RecommendShowcaseSkeleton extends StatelessWidget {
  const RecommendShowcaseSkeleton({
    super.key,
    required this.header,
    required this.isWide,
  });

  final Widget header;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        header,
        Skeletonizer(
          effect: _recommendShimmer,
          child: isWide
              ? SizedBox(
                  height: 250,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      for (var i = 0; i < 3; i++) ...[
                        Expanded(
                          flex: i == 0 ? 2 : 1,
                          child: Bone(
                            height: 250,
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        if (i != 2) const SizedBox(width: 16),
                      ],
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: Bone(
                          height: 250,
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Bone(
                              height: 250,
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Bone(
                              height: 250,
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ],
    );
  }
}

/// 榜单区：四张带名次的竖版卡片
class RecommendRankSkeleton extends StatelessWidget {
  const RecommendRankSkeleton({
    super.key,
    required this.header,
    required this.isNarrow,
  });

  final Widget header;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Skeletonizer(
          effect: _recommendShimmer,
          child: isNarrow
              ? Column(
                  children: [
                    for (var row = 0; row < 2; row++) ...[
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          for (var column = 0; column < 2; column++) ...[
                            Expanded(
                              child: Bone(
                                height: 190,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            if (column == 0) const SizedBox(width: 8),
                          ],
                          const SizedBox(width: 16),
                        ],
                      ),
                      if (row == 0) const SizedBox(height: 8),
                    ],
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        Expanded(
                          child: Bone(
                            height: 220,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        if (i != 3) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// 热门区：一张主图 + 右侧横条列表
class RecommendHotSkeleton extends StatelessWidget {
  const RecommendHotSkeleton({
    super.key,
    required this.header,
    required this.isNarrow,
  });

  final Widget header;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Skeletonizer(
          effect: _recommendShimmer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isNarrow
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Bone(
                        height: 250,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < 3; i++) ...[
                        Bone(
                          height: 66,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        if (i != 2) const SizedBox(height: 16),
                      ],
                    ],
                  )
                : SizedBox(
                    height: 250,
                    child: Row(
                      children: [
                        Expanded(
                          child: Bone(
                            height: 250,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            children: [
                              for (var i = 0; i < 3; i++) ...[
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Bone(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
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
        const SizedBox(height: 16),
      ],
    );
  }
}
