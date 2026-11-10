import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/random_pic_form_controller.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 图源连通性测速入口
class RandomPicSpeedTestSection extends StatelessWidget {
  const RandomPicSpeedTestSection({super.key, required this.controller});

  final RandomPicFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.speed, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                '图源测速',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Section(
          child: Obx(() {
            final pinging = controller.pinging.value;
            final pings = controller.pings;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pings.isNotEmpty)
                  for (final entry in pings.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            !entry.value.configured
                                ? Icons.link_off
                                : (entry.value.ok
                                      ? Icons.check_circle
                                      : Icons.error_outline),
                            size: 16,
                            color: !entry.value.configured
                                ? theme.colorScheme.outline
                                : (entry.value.ok
                                      ? Colors.green
                                      : theme.colorScheme.error),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value.label,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            !entry.value.configured
                                ? '未配置'
                                : (entry.value.ok
                                      ? '${entry.value.ms ?? 0} ms'
                                      : '不可用'),
                            style: TextStyle(
                              fontSize: 12,
                              color: !entry.value.configured
                                  ? theme.colorScheme.outline
                                  : (entry.value.ok
                                        ? Colors.green
                                        : theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                if (pings.isNotEmpty) const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: pinging ? null : () => controller.pingSources(),
                    icon: const Icon(Icons.wifi_tethering, size: 18),
                    label: Text(pinging ? '测速中…' : '测试图源连通性'),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
/// RandomPic 网络图片下载面板：候选列表 + 批量下载 + 进度
class RandomPicDownloadPanel extends StatefulWidget {
  const RandomPicDownloadPanel({super.key, required this.controller});

  final RandomPicFormController controller;

  @override
  State<RandomPicDownloadPanel> createState() => _RandomPicDownloadPanelState();
}

class _RandomPicDownloadPanelState extends State<RandomPicDownloadPanel> {
  String _source = 'both';
  int _count = 20;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_download_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                '网络图片下载',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Section(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _source,
                    decoration: const InputDecoration(
                      labelText: '下载源',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'both', child: Text('横屏 + 竖屏', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'pc', child: Text('仅横屏', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'mobile', child: Text('仅竖屏', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (v) => setState(() => _source = v ?? 'both'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: DropdownButtonFormField<int>(
                    initialValue: _count,
                    decoration: const InputDecoration(
                      labelText: '数量',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [10, 20, 30, 50, 100]
                        .map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text('$n', style: const TextStyle(fontSize: 13)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _count = v ?? 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() {
              final starting = controller.startingDownload.value;
              final status = controller.downloadStatus.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: starting
                              ? null
                              : () => _startDownload(count: _count, source: _source),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: Text(starting ? '启动中…' : '开始下载'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: starting ? null : _showCandidates,
                        icon: const Icon(Icons.list_alt, size: 18),
                        label: const Text('候选'),
                      ),
                    ],
                  ),
                  if (status != null && (status.running || status.total > 0)) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: status.progress, minHeight: 4),
                    const SizedBox(height: 6),
                    Text(
                      '${status.message.isEmpty ? (status.running ? '下载中…' : '已结束') : status.message}'
                      ' · ${status.done}/${status.total}'
                      ' · 成功 ${status.success} 失败 ${status.failed} 跳过 ${status.skipped}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 6),
            Text(
              '下载会把网络图源中的图片按横竖屏分类保存到插件本地目录',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startDownload({int count = 20, String source = 'both'}) async {
    final result = await widget.controller.startDownload(
      count: count,
      source: source,
    );
    if (result.success) {
      ToastUtil.success(result.message);
    } else {
      ToastUtil.error(result.message);
    }
  }

  Future<void> _showCandidates() async {
    ToastUtil.loading(message: '获取候选图片…');
    final urls = await widget.controller.loadCandidates(
      source: _source,
      count: _count,
    );
    ToastUtil.dismiss();
    if (!mounted) return;
    if (urls.isEmpty) {
      ToastUtil.error('未获取到候选图片，请检查图源配置');
      return;
    }
    final selected = <String>{...urls};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('候选图片（${urls.length}）'),
          content: SizedBox(
            width: 560,
            height: 380,
            child: ListView.builder(
              itemCount: urls.length,
              itemBuilder: (ctx, index) {
                final url = urls[index];
                return CheckboxListTile(
                  dense: true,
                  value: selected.contains(url),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selected.add(url);
                      } else {
                        selected.remove(url);
                      }
                    });
                  },
                  title: Text(
                    url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('下载选中（${selected.length}）'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && selected.isNotEmpty) {
      final result = await widget.controller.startDownload(
        urls: selected.toList(),
      );
      if (result.success) {
        ToastUtil.success(result.message);
      } else {
        ToastUtil.error(result.message);
      }
    }
  }
}
