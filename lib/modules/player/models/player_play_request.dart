import 'package:lanplayer_player/lanplayer_player.dart' as kit;

/// 播放请求(未解析):点播放时立即跳转播放容器页,由容器页内部完成
/// 条目解析/流地址解析(ISO 解析可能耗时 1-2 秒),避免用户停在详情页无反馈。
class PlayerPlayRequest {
  /// 媒体服务器条目 id(整部剧时为剧集 id,容器内自动定位续播单集)
  final String itemId;

  /// 来源服务器(名称/类型,用于从缓存配置里定位)
  final String? serverName;
  final String? serverType;

  /// 从头开始播(忽略续播位置)
  final bool fromStart;

  /// 是否自动定位「下一集未看完的」(剧集)
  final bool autoNextEpisode;

  /// 加载页展示用
  final String title;
  final String? subtitle;

  /// 已就绪的服务实例(选集播放等场景直接复用)
  final kit.MediaServerService? service;
  final kit.MediaServer? server;
  final List<kit.MediaItem>? episodes;

  const PlayerPlayRequest({
    required this.itemId,
    this.serverName,
    this.serverType,
    this.fromStart = false,
    this.autoNextEpisode = true,
    this.title = '正在准备播放',
    this.subtitle,
    this.service,
    this.server,
    this.episodes,
  });
}
