import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_models.dart';
import '../providers/app_providers.dart';
import '../screens/player/player_screen.dart';
import '../services/media_server_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// 内嵌播放器 Kit 门面:宿主 App 首次使用前调用 [LanPlayerKit.ensureInitialized]。
class LanPlayerKit {
  static bool _initialized = false;

  /// 初始化包内持久化(SharedPreferences)。幂等,可在宿主启动早期调用。
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await StorageService.init();
    _initialized = true;
  }

  /// 注入宿主主题色,播放页/浏览页的强调色随 MP 主题设置。
  static void setAccentColor(Color color) {
    AppTheme.primary = color;
  }
}

/// 一次播放会话的完整入参,与 PlayerScreen 构造参数一一对齐。
class PlayerSession {
  final MediaItem media;
  final String streamUrl;
  final Map<String, String>? httpHeaders;
  final String? transcodeUrl;
  final List<MediaItem>? episodes;
  final MediaServerService? service;
  final MediaServer? server;
  final int? resumePositionMs;

  const PlayerSession({
    required this.media,
    required this.streamUrl,
    this.httpHeaders,
    this.transcodeUrl,
    this.episodes,
    this.service,
    this.server,
    this.resumePositionMs,
  });
}

/// 播放会话解析:按 itemId 拉全量条目元数据并解析直连流地址
/// (服务端判定不可直连时 getStreamUrl 内部已回退转码流)。
class PlaybackResolver {
  const PlaybackResolver._();

  /// [episodes] 传剧集选集列表时,播放页内启用上/下一集与自动连播。
  static Future<PlayerSession> resolve({
    required MediaServerService service,
    required MediaServer server,
    required String itemId,
    String? quality,
    List<MediaItem>? episodes,
  }) async {
    final item = await service.getItemDetails(itemId);
    final url = await service.getStreamUrl(itemId, quality: quality);
    final progress = item.watchProgress;
    final duration = item.duration;
    final resume = (progress != null && progress > 0 && duration > 0)
        ? (progress * duration * 1000).round()
        : null;
    return PlayerSession(
      media: item,
      streamUrl: url,
      httpHeaders: service.streamHeaders,
      transcodeUrl: service.lastTranscodeUrl,
      episodes: episodes,
      service: service,
      server: server,
      resumePositionMs: resume,
    );
  }
}

/// 宿主路由的播放页:以 ProviderScope 覆盖注入宿主构造的媒体服务器服务,
/// 内部渲染移植自 lanplayer 的 PlayerScreen。
class PlayerHostPage extends ConsumerWidget {
  final PlayerSession session;

  const PlayerHostPage({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        currentMediaServerServiceProvider
            .overrideWithValue(session.service),
      ],
      child: PlayerScreen(
        media: session.media,
        streamUrl: session.streamUrl,
        httpHeaders: session.httpHeaders,
        transcodeUrl: session.transcodeUrl,
        episodes: session.episodes,
        service: session.service,
        server: session.server,
        resumePositionMs: session.resumePositionMs,
      ),
    );
  }
}
