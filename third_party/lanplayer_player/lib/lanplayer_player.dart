/// lanplayer_player — 从 lanplayer 抽取的内嵌播放器 Kit。
///
/// 宿主(MoviePilotLite)使用方式:
///   1. 启动早期 await LanPlayerKit.ensureInitialized();
///   2. 用媒体服务器凭据构造 MediaServerService(EmbyService/JellyfinService);
///   3. PlaybackResolver.resolve(...) 组装 PlayerSession;
///   4. 路由 push PlayerHostPage(session: ...)。
library;

export 'host/player_host.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope, ProviderOverride, ConsumerWidget, ConsumerStatefulWidget, ConsumerState, WidgetRef;
export 'models/media_models.dart';
export 'player/player.dart';
export 'providers/app_providers.dart';
export 'services/media_server_service.dart';
export 'services/dual_stack_http.dart';
export 'services/danmaku_service.dart';
export 'database/database_service.dart';
export 'services/storage_service.dart';
export 'widgets/server_image.dart';
export 'screens/servers/media_library_screen.dart';
