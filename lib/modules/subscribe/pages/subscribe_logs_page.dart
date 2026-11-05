// 订阅运行日志页：默认最近 100 行，可切换 600 行/全部并手动刷新；等宽字体查看。

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_logs_controller.dart';

class SubscribeLogsPage extends StatefulWidget {
  const SubscribeLogsPage({super.key});

  @override
  State<SubscribeLogsPage> createState() => _SubscribeLogsPageState();
}

class _SubscribeLogsPageState extends State<SubscribeLogsPage> {
  final ScrollController _scrollController = ScrollController();
  Worker? _contentWorker;

  SubscribeLogsController get controller =>
      Get.find<SubscribeLogsController>();

  String _lengthLabel(int length) => switch (length) {
    -1 => '全部日志',
    _ => '最近 $length 行',
  };

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    // 刷新完成后定位到日志尾部（服务端按时间正序返回）
    _contentWorker = ever(controller.content, (_) => _jumpToBottom());
  }

  @override
  void dispose() {
    _contentWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运行日志'),
        centerTitle: false,
        actions: [
          Obx(
            () => PopupMenuButton<int>(
              tooltip: '日志长度',
              initialValue: controller.selectedLength.value,
              onSelected: controller.setLength,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              itemBuilder: (context) => SubscribeLogsController.lengthOptions
                  .map(
                    (length) => PopupMenuItem(
                      value: length,
                      child: Text(_lengthLabel(length)),
                    ),
                  )
                  .toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _lengthLabel(controller.selectedLength.value),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: controller.reload,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (!controller.v3Supported.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.info_circle, size: 34, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    '运行日志需要 MoviePilot v3 服务端',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }
        final loading = controller.isLoading.value;
        final error = controller.errorText.value;
        final content = controller.content.value;
        if (loading && content.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (error != null && content.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  CupertinoButton.filled(
                    onPressed: controller.reload,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    '暂无执行日志，下一次搜索或 RSS 匹配后开始记录',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: SelectableText(
                  content,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    fontFamily: 'Menlo',
                    fontFamilyFallback: const ['Courier', 'monospace'],
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
            if (loading)
              const Positioned(
                top: 8,
                right: 12,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        );
      }),
    );
  }
}
