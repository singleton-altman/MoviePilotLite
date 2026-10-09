import 'package:flutter/material.dart';

import '../models/media_models.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'server_image.dart';
import 'tap_feedback.dart';

/// 选集卡片。
///
/// ## 与改造前的区别
///
/// - **选中框只包图片。** 原先边框套在整张卡片（图片 + 标题 + 时长）外面，
///   选中时文字区被一并框住，卡片看起来像个输入框；而且边框占掉的 2px
///   会让图片相对缩一圈，选中/未选中之间有可见的抖动。
/// - **卡片加大**：140×82 → 160×96。原尺寸在手机上缩略图细节几乎看不清。
/// - **选中色**用主题色而不是半透明白 —— 半透明白压在亮缩略图上分辨不出来。
class EpisodeCard extends StatelessWidget {
  const EpisodeCard({
    super.key,
    required this.episode,
    required this.index,
    required this.selected,
    required this.onTap,
    this.imageHeaders,
  });

  final MediaItem episode;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final Map<String, String>? imageHeaders;

  static const double cardWidth = 160;
  static const double imageHeight = 96;
  static const double radius = 12;

  /// 卡片之间的间距。
  ///
  /// 放在 [cardWidth] **之外**（用 margin 而不是 padding）。改造前是
  /// `SizedBox(width: 160)` 里再 `Padding(right: 12)`，于是 12 的间距是从
  /// 160 里抠出来的 —— 加上左右各 2px 选中边框，图片实际只有 144 宽，
  /// 比设计稿的 160 窄了 10%，缩略图细节又看不清了。
  static const double gap = 12;

  /// 选中边框宽度。未选中时用透明边占位，切换时图片不跳。
  static const double borderWidth = 2;

  /// 横向列表需要的高度。
  ///
  /// 不写死数字：标题两行的高度随系统字体缩放变，写死的话大字体下第二行会
  /// 被截断（改造前是 `SizedBox(height: 172)`，注释还写着"高度交给内容撑"，
  /// 名不副实）。这里按实际字号算，并跟着 textScaler 走。
  static double listHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    // 标题 2 行 + 时长 1 行，行高按 1.3 估
    final titleH = scaler.scale(12) * 1.3 * 2;
    final durationH = scaler.scale(11) * 1.3;
    return imageHeight + borderWidth * 2 + 6 + titleH + durationH + 4;
  }

  @override
  Widget build(BuildContext context) {
    final ep = episode;
    final progress = ep.watchProgress;
    final hasProgress =
        progress != null && progress > 0 && progress < 0.98;

    return CardTapFeedback(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
              // 选中边框画在图片这一层，且用 2px 透明边占位 ——
              // 未选中时也占同样的空间，切换选中不会让图片跳一下。
              AnimatedContainer(
                duration: context.motion(AppMotion.toggle),
                curve: AppEase.standard,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius + borderWidth),
                  border: Border.all(
                    color: selected ? AppTheme.primary : Colors.transparent,
                    width: borderWidth,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: SizedBox(
                    width: cardWidth - borderWidth * 2,
                    height: imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: Colors.white.withValues(alpha: 0.08),
                          child: ep.posterUrl.isNotEmpty
                              ? ServerImage(
                                  imageUrl: ep.posterUrl,
                                  headers: imageHeaders,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Center(
                                      child: Icon(Icons.movie,
                                          color: Colors.white24, size: 32)),
                                )
                              : const Center(
                                  child: Icon(Icons.play_circle_outline,
                                      color: Colors.white24, size: 32)),
                        ),
                        // 播放键：选中时实心一点，提示"再点一下就是播放"
                        Center(
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withValues(alpha: selected ? 0.62 : 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.play_arrow_rounded,
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.75),
                                size: 24),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'E${ep.episodeNumber ?? index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (ep.isWatched == true)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        // 续播进度条
                        if (hasProgress)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: SizedBox(
                              height: 3,
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.55),
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // 标题占满剩余空间：列表高度是按 2 行算出来的，这里用 Flexible
              // 吃掉误差，字体缩放时截断也发生在这一层而不是溢出报错。
              Flexible(
                child: Text(
                  ep.title,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (ep.duration > 0)
                Text('${ep.duration ~/ 60}分钟',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}


