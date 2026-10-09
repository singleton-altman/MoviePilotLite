import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lanplayer_player/lanplayer_player.dart' as kit;

import '../controllers/player_launch_controller.dart';
import '../models/player_play_request.dart';

/// 播放容器页:点播放后**立即**进入本页并显示加载动效,
/// 由本页内部完成条目/流地址解析(ISO 解析可能 1-2 秒),
/// 解析完成后原地切换为播放器(零页面切换动画)——
/// 把"卡在详情页无反馈"变成"播放页里有进度"。
///
/// 入参两种:
/// - [kit.PlayerSession]  :已解析完成的会话(选集播放等路径),直接开播;
/// - [PlayerPlayRequest]  :未解析请求,本页负责解析。
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  kit.PlayerSession? _session;
  Object? _error;
  String _title = '正在准备播放';
  String? _subtitle;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is kit.PlayerSession) {
      _session = args;
      return;
    }
    if (args is PlayerPlayRequest) {
      _title = args.title;
      _subtitle = args.subtitle;
      _start(args);
      return;
    }
    _error = '播放参数缺失';
  }

  /// 加载层延时出现:解析在 400ms 内完成时不闪任何加载态
  void _startDelayedOverlay() {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _session == null) {
        setState(() => _showOverlay = true);
      }
    });
  }

  Future<void> _start(PlayerPlayRequest req) async {
    _startDelayedOverlay();
    try {
      final session = await PlayerLaunchController.to.resolveForPlayback(
        itemId: req.itemId,
        serverName: req.serverName,
        serverType: req.serverType,
        fromStart: req.fromStart,
        autoNextEpisode: req.autoNextEpisode,
        service: req.service,
        server: req.server,
        episodes: req.episodes,
      );
      if (!mounted) return;
      setState(() => _session = session);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session != null) {
      return kit.PlayerHostPage(session: session);
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: true,
        child: Center(
          child: _error != null ? _buildError() : _buildLoading(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return AnimatedOpacity(
      opacity: _showOverlay ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(
            radius: 16,
            color: CupertinoColors.white,
          ),
          const SizedBox(height: 18),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_subtitle != null && _subtitle!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemOrange,
            size: 40,
          ),
          const SizedBox(height: 16),
          const Text(
            '无法开始播放',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_error',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(
            onPressed: () => Get.back<void>(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}
