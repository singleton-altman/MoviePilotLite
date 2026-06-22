import 'package:altman_downloader_control/controller/downloader_config.dart'
    show DownloaderType;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/download/controllers/download_controller.dart';
import 'package:moviepilot_mobile/modules/downloader/widgets/downloader_config_item_card.dart';
import 'package:moviepilot_mobile/modules/setting/models/setting_models.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 下载器配置列表：使用 Downloaders 列表，并复用运行指标展示。
class DownloaderConfigListPage extends StatefulWidget {
  const DownloaderConfigListPage({super.key});

  @override
  State<DownloaderConfigListPage> createState() =>
      _DownloaderConfigListPageState();
}

class _DownloaderConfigListPageState extends State<DownloaderConfigListPage> {
  bool _privacyModeEnabled = false;
  static const String _prefsPrivacyKey = 'downloader_config_privacy_mode';

  DownloadController get controller => Get.find<DownloadController>();

  @override
  void initState() {
    super.initState();
    _loadPrivacyMode();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.refreshDownloaders();
    });
  }

  Future<void> _loadPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefsPrivacyKey) ?? false;
    if (!mounted) return;
    setState(() => _privacyModeEnabled = value);
  }

  Future<void> _savePrivacyMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsPrivacyKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载器'),
        centerTitle: false,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => controller.refreshDownloaders(),
            child: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingDownloaders && controller.downloaders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.downloaders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_for_offline_outlined,
                  size: 64,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无下载器配置',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refreshDownloaders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.downloaders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildPrivacyToggle(context);
              }
              final itemIndex = index - 1;
              if (itemIndex >= controller.downloaders.length) {
                return const SizedBox.shrink();
              }
              final downloader = controller.downloaders[itemIndex];
              return Obx(
                () => DownloaderConfigItemCard(
                  downloader: downloader,
                  stats: controller.statsFor(downloader.name),
                  obscureHost: _privacyModeEnabled,
                  onTap: () => _navigateToDetail(downloader),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildPrivacyToggle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          const Expanded(child: Text('隐私模式')),
          Switch(
            value: _privacyModeEnabled,
            onChanged: (v) {
              setState(() => _privacyModeEnabled = v);
              _savePrivacyMode(v);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(DownloadClient? client) {
    if (client == null) {
      ToastUtil.warning('前往 web 添加下载器');
      return;
    }

    final type = _getDownloaderType(client.type);
    if (type == null) {
      ToastUtil.warning('下载器类型不支持');
      return;
    }

    final config = {
      'id': client.name,
      'url': client.config?.host ?? '',
      'username': client.config?.username ?? '',
      'password': client.config?.password ?? '',
      'type': type,
      'name': client.name,
    };

    Get.toNamed('/downloader-detail', arguments: {'config': config});
  }

  DownloaderType? _getDownloaderType(String type) {
    switch (type) {
      case 'qbittorrent':
        return DownloaderType.qbittorrent;
      case 'transmission':
        return DownloaderType.transmission;
    }
    return null;
  }
}
