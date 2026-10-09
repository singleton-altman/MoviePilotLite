import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/glass_quality.dart';

// ============================================================
// 玻璃态组件库 — 动态模糊 + 液体玻璃效果
// ============================================================

/// 玻璃态容器
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? shadows;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.5,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: GlassQuality.scaleBlur(blur, context), sigmaY: GlassQuality.scaleBlur(blur, context)),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color:
                  backgroundColor ?? context.surfaceColor.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: borderWidth)
                  : Border.all(
                      color: context.textPrimary.withValues(alpha: 0.15),
                      width: borderWidth,
                    ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.cardColor,
                  context.textPrimary.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 玻璃态底部导航栏
class GlassBottomBar extends StatelessWidget {
  final Widget child;
  final double blur;

  const GlassBottomBar({
    super.key,
    required this.child,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: GlassQuality.scaleBlur(blur, context), sigmaY: GlassQuality.scaleBlur(blur, context)),
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor.withValues(alpha: 0.75),
            border: Border(
              top: BorderSide(
                color: context.textPrimary.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 玻璃态 AppBar
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final double blur;
  final bool centerTitle;

  const GlassAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.blur = 20,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: GlassQuality.scaleBlur(blur, context), sigmaY: GlassQuality.scaleBlur(blur, context)),
        child: Container(
          decoration: BoxDecoration(
            color: context.bgColor.withValues(alpha: 0.55),
            border: Border(
              bottom: BorderSide(
                color: context.textPrimary.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.textPrimary.withValues(alpha: 0.06),
                context.textPrimary.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: centerTitle,
            leading: leading,
            title: title,
            actions: actions,
          ),
        ),
      ),
    );
  }
}

/// 液体玻璃卡片 — 带渐变边框光晕
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.blur = 16,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withValues(alpha: 0.15),
              AppTheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(1.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 1.5),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: GlassQuality.scaleBlur(blur, context), sigmaY: GlassQuality.scaleBlur(blur, context)),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: context.surfaceColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(borderRadius - 1.5),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.textPrimary.withValues(alpha: 0.08),
                    context.textPrimary.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 玻璃态按钮
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isSelected;
  final Color? selectedBorderColor;

  const GlassButton({
    super.key,
    required this.child,
    required this.onTap,
    this.blur = 12,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.isSelected = false,
    this.selectedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: GlassQuality.scaleBlur(blur, context), sigmaY: GlassQuality.scaleBlur(blur, context)),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : context.textPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isSelected
                    ? (selectedBorderColor ?? AppTheme.primary)
                    : context.textPrimary.withValues(alpha: 0.15),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 播放器专用玻璃组件 — 半透明磨砂控制面板
// ============================================================

/// 播放器控制面板 — 半透明磨砂蒙层
/// 用于底部播放控制栏，不遮挡视频画面
class PlayerControlPanel extends StatelessWidget {
  final Widget? child;
  final List<Widget> children;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const PlayerControlPanel({
    super.key,
    this.child,
    this.children = const [],
    this.width,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.playerControlRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassQuality.scaleBlur(AppTheme.playerControlBgBlur, context),
            sigmaY: GlassQuality.scaleBlur(AppTheme.playerControlBgBlur, context),
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 10, 16, 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: AppTheme.playerControlBgOpacity),
              borderRadius: BorderRadius.circular(AppTheme.playerControlRadius),
              border: Border.all(
                color: context.textPrimary.withValues(alpha: AppTheme.playerControlBorderOpacity),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.textPrimary.withValues(alpha: 0.08),
                  context.textPrimary.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: child ?? Column(children: children),
          ),
        ),
      ),
    );
  }
}

/// 播放器顶部控制栏 — 返回按钮 + 标题 + 更多操作
class PlayerTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onPiP;
  final VoidCallback? onChapters;
  final bool showPiP;
  final bool showChapters;

  const PlayerTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.onMore,
    this.onPiP,
    this.onChapters,
    this.showPiP = false,
    this.showChapters = false,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(top: topPadding, left: 8, right: 8),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack ?? () => Navigator.pop(context),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showChapters)
            _GlassIconButton(
              icon: Icons.list_rounded,
              onTap: onChapters,
            ),
          if (showPiP)
            _GlassIconButton(
              icon: Icons.picture_in_picture_alt_rounded,
              onTap: onPiP,
            ),
          SizedBox(width: 8),
          _GlassIconButton(
            icon: Icons.more_vert_rounded,
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

/// 播放器玻璃态图标按钮 — 半透明背景圆形按钮
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassIconButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppTheme.playerButtonSize,
        height: AppTheme.playerButtonSize,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppTheme.playerButtonRadius),
        ),
        child: Icon(
          icon,
          color: context.textPrimary,
          size: AppTheme.playerButtonIconSize,
        ),
      ),
    );
  }
}

/// 播放器控制按钮组 — 包含播放/暂停、快进快退、速度等
class PlayerControlButtons extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onSeekBack;
  final VoidCallback? onSeekForward;
  final VoidCallback? onSpeed;
  final VoidCallback? onEpisode;
  final VoidCallback? onSubtitle;
  final VoidCallback? onAudio;
  final VoidCallback? onChapter;
  final String? speedLabel;
  final bool showEpisode;
  final bool showSubtitle;
  final bool showAudio;
  final bool showChapter;

  const PlayerControlButtons({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    this.onSeekBack,
    this.onSeekForward,
    this.onSpeed,
    this.onEpisode,
    this.onSubtitle,
    this.onAudio,
    this.onChapter,
    this.speedLabel,
    this.showEpisode = false,
    this.showSubtitle = true,
    this.showAudio = false,
    this.showChapter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (onSeekBack != null)
          _ControlChip(
            icon: Icons.replay_10_rounded,
            label: '-10s',
            onTap: onSeekBack!,
          ),
        if (showEpisode && onEpisode != null)
          _ControlChip(
            icon: Icons.list_rounded,
            label: '选集',
            onTap: onEpisode!,
          ),
        // 播放/暂停主按钮
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: AppTheme.playerPlayButtonSize,
            height: AppTheme.playerPlayButtonSize,
            decoration: BoxDecoration(
              color: context.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: AppTheme.playerPlayIconSize,
            ),
          ),
        ),
        if (onSpeed != null)
          _ControlChip(
            icon: Icons.speed_rounded,
            label: speedLabel ?? '1x',
            onTap: onSpeed!,
          ),
        if (showSubtitle && onSubtitle != null)
          _ControlChip(
            icon: Icons.subtitles_outlined,
            label: '字幕',
            onTap: onSubtitle!,
          ),
        if (onSeekForward != null)
          _ControlChip(
            icon: Icons.forward_10_rounded,
            label: '+10s',
            onTap: onSeekForward!,
          ),
      ],
    );
  }
}

/// 控制栏小按钮 — 圆形图标 + 底部标签
class _ControlChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppTheme.playerButtonSize - 8,
            height: AppTheme.playerButtonSize - 8,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: context.textPrimary70,
              size: AppTheme.playerButtonIconSize - 4,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// 播放器进度条 — 包含缓冲进度、播放进度、时间显示
class PlayerProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Duration? buffer;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onChangeStart;
  final VoidCallback? onChangeEnd;
  final bool isSeeking;

  const PlayerProgressBar({
    super.key,
    required this.position,
    required this.duration,
    this.buffer,
    this.onSeek,
    this.onChangeStart,
    this.onChangeEnd,
    this.isSeeking = false,
  });

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final buffered = duration.inMilliseconds > 0 && buffer != null
        ? (buffer!.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      children: [
        Text(
          _formatDuration(position),
          style: TextStyle(
            color: context.textPrimary70,
            fontSize: 12,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 缓冲进度条（底层）
              if (buffered > 0)
                Container(
                  height: AppTheme.playerProgressBufferHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.playerProgressBufferColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * buffered,
                  ),
                ),
              // 播放进度条
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: AppTheme.playerProgressHeight,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: isSeeking
                        ? AppTheme.playerProgressThumbRadiusDrag
                        : AppTheme.playerProgressThumbRadius,
                  ),
                  thumbColor: context.textPrimary,
                  activeTrackColor: AppTheme.playerProgressActiveColor,
                  inactiveTrackColor: AppTheme.playerProgressInactiveColor,
                  overlayColor: AppTheme.primary.withValues(alpha: 0.2),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: progress,
                  onChanged: onSeek != null ? (v) => onSeek!(Duration(milliseconds: (v * duration.inMilliseconds).round())) : null,
                  onChangeStart: (_) => onChangeStart?.call(),
                  onChangeEnd: (_) => onChangeEnd?.call(),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Text(
          _formatDuration(duration),
          style: TextStyle(
            color: context.textPrimary70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// 播放器加载态 — 渐变加载动画
class PlayerLoadingIndicator extends StatelessWidget {
  final String? message;

  const PlayerLoadingIndicator({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppTheme.playerLoadingSize,
            height: AppTheme.playerLoadingSize,
            child: CircularProgressIndicator(
              strokeWidth: AppTheme.playerLoadingStrokeWidth,
              color: AppTheme.playerLoadingColor,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: context.textPrimary70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 播放器缓冲态 — 带缓冲进度提示
class PlayerBufferingIndicator extends StatelessWidget {
  final double? bufferProgress;
  final String? message;

  const PlayerBufferingIndicator({
    super.key,
    this.bufferProgress,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                value: bufferProgress,
                color: AppTheme.primary,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: 12),
              Text(
                message!,
                style: TextStyle(
                  color: context.textPrimary70,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 播放器错误页面 — 解码失败、无网络、文件损坏等
class PlayerErrorPage extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final String? retryLabel;

  const PlayerErrorPage({
    super.key,
    required this.message,
    this.icon,
    this.onRetry,
    this.onBack,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                color: AppTheme.error,
                size: AppTheme.playerErrorIconSize,
              ),
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                color: AppTheme.playerErrorTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            SizedBox(height: 32),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? '重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: context.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.playerErrorButtonRadius),
                  ),
                ),
              ),
            if (onBack != null) ...[
              SizedBox(height: 12),
              TextButton(
                onPressed: onBack,
                child: Text(
                  '返回',
                  style: TextStyle(color: context.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 播放器手势区域提示 — 快进/快退、音量/亮度调节时显示
class PlayerGestureHint extends StatelessWidget {
  final String text;
  final IconData? icon;
  final double progress; // 0.0 - 1.0
  final Duration duration;

  const PlayerGestureHint({
    super.key,
    required this.text,
    this.icon,
    this.progress = 0,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon!, color: context.textPrimary, size: 20),
          if (icon != null) SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (progress > 0) ...[
            SizedBox(width: 12),
            SizedBox(
              width: 60,
              height: 4,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: context.textPrimary.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 播放器音量/亮度滑块面板 — 垂直滑块 + 图标
class PlayerSliderPanel extends StatelessWidget {
  final double value;
  final double max;
  final ValueChanged<double>? onChange;
  final IconData icon;
  final IconData? activeIcon;
  final bool isVolume;
  final String? label;

  const PlayerSliderPanel({
    super.key,
    required this.value,
    this.max = 1.0,
    this.onChange,
    required this.icon,
    this.activeIcon,
    this.isVolume = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppTheme.playerVolumeSliderWidth,
      height: isVolume ? AppTheme.playerVolumeSliderHeight : AppTheme.playerBrightnessSliderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            value > 0 ? (activeIcon ?? icon) : (isVolume ? Icons.volume_off_rounded : Icons.brightness_low_rounded),
            color: context.textPrimary70,
            size: 24,
          ),
          SizedBox(height: 12),
          Expanded(
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: AppTheme.playerSliderTrackHeight,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: AppTheme.playerSliderThumbRadius,
                  ),
                  thumbColor: context.textPrimary,
                  activeTrackColor: context.textPrimary.withValues(alpha: 0.7),
                  inactiveTrackColor: context.textSecondary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: value,
                  max: max,
                  onChanged: onChange,
                ),
              ),
            ),
          ),
          if (label != null) ...[
            SizedBox(height: 8),
            Text(
              label!,
              style: TextStyle(color: context.textPrimary70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// 播放器弹窗面板底部 Sheet — 用于速度、选集、字幕、音轨等选择
class PlayerSheetPanel extends StatelessWidget {
  final String title;
  final Widget? content;
  final List<Widget> children;
  final double? height;

  const PlayerSheetPanel({
    super.key,
    required this.title,
    this.content,
    this.children = const [],
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(AppTheme.playerPanelMargin, 0, AppTheme.playerPanelMargin, AppTheme.playerPanelMargin),
      padding: EdgeInsets.all(AppTheme.playerPanelPadding),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.playerPanelRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          if (children.isNotEmpty) ...children else if (content != null) content!,
        ],
      ),
    );
  }
}

/// 播放器选项项 — 用于弹窗内的单个选择项
class PlayerOptionItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? subtitle;

  const PlayerOptionItem({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.3)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.playerPanelItemRadius),
          border: isSelected
              ? Border.all(color: AppTheme.primary)
              : null,
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(
                icon!,
                color: isSelected ? AppTheme.primary : context.textSecondary,
                size: 20,
              ),
            if (icon != null) SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? context.textPrimary : context.textPrimary70,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

/// 画中画控制面板 — PIP 模式下的精简控制栏
class PipControlPanel extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback? onSeekBack;
  final VoidCallback? onSeekForward;
  final VoidCallback? onClose;

  const PipControlPanel({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    this.onSeekBack,
    this.onSeekForward,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.pipCornerRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onSeekBack != null)
            IconButton(
              onPressed: onSeekBack,
              icon: Icon(Icons.replay_10_rounded),
              iconSize: AppTheme.pipControlButtonSize,
              color: context.textPrimary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          IconButton(
            onPressed: onPlayPause,
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            iconSize: AppTheme.pipControlButtonSize,
            color: context.textPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (onSeekForward != null)
            IconButton(
              onPressed: onSeekForward,
              icon: Icon(Icons.forward_10_rounded),
              iconSize: AppTheme.pipControlButtonSize,
              color: context.textPrimary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (onClose != null) ...[
            SizedBox(width: 8),
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close_rounded),
              iconSize: AppTheme.pipControlButtonSize - 4,
              color: context.textPrimary70,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}


