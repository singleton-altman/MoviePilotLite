/// 位图字幕编码（PGS / VobSub / DVB / XSUB…）。
///
/// 这类字幕是**图形帧**，不是文本：Dart 层的文本渲染管线（SubtitleOverlay、
/// libass 桥）都渲染不了。引擎轨道列表据此标记 `isBitmap`，宿主的自动选轨、
/// 循环切轨、字幕来源列表都会跳过它们。
const bitmapSubtitleCodecs = <String>{
  // libmpv(FFmpeg) 用的短名
  'pgs_sub',
  'hdmv_pgs_subtitle',
  'dvd_subtitle',
  'vobsub',
  'dvb_subtitle',
  'subrip_bitmap',
  // ExoPlayer/Media3 用的 MIME 名
  'application/pgs',
  'application/x-pgs',
};

/// 该字幕编码是否为位图字幕（大小写与空白不敏感）。
bool isBitmapSubtitleCodec(String codec) =>
    bitmapSubtitleCodecs.contains(codec.toLowerCase().trim());
