import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/douban_folio_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/services/douban_folio_converter.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 豆瓣档案（DoubanFolio）自定义渲染器。
///
/// 页面模式 = 账号卡 + 统计卡 + 同步记录
/// 配置模式 = 账号/扫码登录 + 可编辑配置表单（保存由页面右上角按钮触发）
void registerDoubanFolioRenderer() {
  PluginFormAdapterRegistry.registerRenderer('DoubanFolio', (
    context,
    blocks,
    controller,
    formMode,
    buildBlock,
  ) {
    final adapter = controller.pluginAdapter;
    if (adapter is! DoubanFolioFormController) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: blocks.map((block) => buildBlock(context, block)).toList(),
      );
    }
    return DoubanFolioPageView(
      controller: adapter,
      formMode: formMode,
      blocks: blocks,
      buildBlock: buildBlock,
    );
  });
}

class DoubanFolioPageView extends StatefulWidget {
  const DoubanFolioPageView({
    super.key,
    required this.controller,
    required this.formMode,
    required this.blocks,
    required this.buildBlock,
  });

  final DoubanFolioFormController controller;
  final bool formMode;
  final List<FormBlock> blocks;
  final Widget Function(BuildContext context, FormBlock block) buildBlock;

  @override
  State<DoubanFolioPageView> createState() => _DoubanFolioPageViewState();
}

class _DoubanFolioPageViewState extends State<DoubanFolioPageView> {
  /// 已登录时「重新扫码」：弹出二维码登录对话框
  Future<void> _showReloginDialog(
    BuildContext context,
    DoubanFolioFormController controller,
  ) async {
    unawaited(controller.startQrLogin());
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重新扫码绑定豆瓣'),
        content: SizedBox(
          width: 320,
          child: _QrLoginSection(controller: controller, compact: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    controller.stopQrPolling();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = widget.controller;
      final status = controller.statusData.value;
      final config = controller.formModel.value;
      final loggedIn = status?.loggedIn == true || config['logged_in'] == true;
      final loading = controller.isLoading.value;

      if (status == null && loading) {
        return const Center(child: CupertinoActivityIndicator());
      }
      if (status == null && widget.blocks.isEmpty) {
        return Center(
          child: Text(
            controller.errorText.value ?? '暂无数据',
            style: TextStyle(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
          ),
        );
      }

      final sections = <Widget>[];
      sections.add(
        _AccountSection(
          loggedIn: loggedIn,
          nickname: status?.nickname ?? config['nickname']?.toString() ?? '',
          uid: status?.uid ?? config['uid']?.toString() ?? '',
          avatar: status?.avatar ?? config['avatar']?.toString() ?? '',
          // 已登录时配置页提供「重新扫码」（Cookie 失效后重新绑定）
          showRelogin: widget.formMode && loggedIn,
          onRelogin: () => _showReloginDialog(context, controller),
        ),
      );
      if (status != null) {
        sections.add(_StatsSection(status: status));
      }

      // 页面模式：豆瓣收藏仪表盘（同步记录 / 想看 / 在看 / 看过 页签 + 海报网格）
      if (!widget.formMode && loggedIn) {
        sections.add(_CollectionSection(controller: controller));
      }

      if (widget.formMode && !loggedIn) {
        sections.add(_QrLoginSection(controller: controller));
      }
      if (widget.formMode) {
        sections.add(_AutoSubscribeSection(controller: controller));
        for (final block in widget.blocks) {
          sections.add(widget.buildBlock(context, block));
        }
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) => sections[index],
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon, this.color});

  final String title;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.loggedIn,
    required this.nickname,
    required this.uid,
    required this.avatar,
    this.showRelogin = false,
    this.onRelogin,
  });

  final bool loggedIn;
  final String nickname;
  final String uid;
  final String avatar;
  final bool showRelogin;
  final VoidCallback? onRelogin;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    Widget avatarWidget;
    if (avatar.startsWith('data:image')) {
      try {
        final base64Part = avatar.substring(avatar.indexOf(',') + 1);
        avatarWidget = CircleAvatar(
          radius: 24,
          backgroundImage: MemoryImage(base64Decode(base64Part)),
        );
      } catch (_) {
        avatarWidget = const CircleAvatar(
          radius: 24,
          child: Icon(Icons.person_outline),
        );
      }
    } else {
      avatarWidget = const CircleAvatar(
        radius: 24,
        child: Icon(Icons.person_outline),
      );
    }
    return Section(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          avatarWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        loggedIn
                            ? (nickname.isEmpty ? '豆瓣用户' : nickname)
                            : '未绑定豆瓣账号',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (loggedIn
                                    ? const Color(0xFF2E9E5B)
                                    : const Color(0xFFFB8C00))
                                .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        loggedIn ? '已登录' : '待配置',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: loggedIn
                              ? const Color(0xFF2E9E5B)
                              : const Color(0xFFFB8C00),
                        ),
                      ),
                    ),
                  ],
                ),
                if (uid.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('UID $uid', style: mutedStyle),
                ],
              ],
            ),
          ),
          if (showRelogin)
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: onRelogin,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 16),
                  SizedBox(width: 4),
                  Text('重新扫码'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.status});

  final DoubanFolioStatus status;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData, Color)>[
      (
        '已同步条目',
        '${status.processedCount}',
        Icons.sync_rounded,
        const Color(0xFF1E88E5),
      ),
      (
        '等待处理',
        '${status.waitCount}',
        Icons.hourglass_top_rounded,
        const Color(0xFFFB8C00),
      ),
      (
        '插件状态',
        status.enabled ? '运行中' : '已停用',
        Icons.power_rounded,
        status.enabled ? const Color(0xFF2E9E5B) : Colors.grey,
      ),
      (
        '失效通知',
        status.notify ? '已开启' : '已关闭',
        Icons.notifications_outlined,
        const Color(0xFF7C4DFF),
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Section(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                children: [
                  Icon(items[i].$3, size: 20, color: items[i].$4),
                  const SizedBox(height: 6),
                  Text(
                    items[i].$2,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].$1,
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.secondaryLabel,
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QrLoginSection extends StatelessWidget {
  const _QrLoginSection({required this.controller, this.compact = false});

  final DoubanFolioFormController controller;

  /// 紧凑模式（对话框内使用），二维码略小
  final bool compact;

  ImageProvider? _imageOf(String? img) {
    if (img == null || img.isEmpty) return null;
    if (img.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(img.substring(img.indexOf(',') + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(img);
  }

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    final qrSize = compact ? 148.0 : 172.0;
    return Section(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: '扫码绑定豆瓣',
            icon: Icons.qr_code_scanner_rounded,
            color: Color(0xFF2E7D32),
          ),
          Obx(() {
            final image = _imageOf(controller.qrImg.value);
            final statusText = controller.qrStatus.value;
            final error = controller.qrError.value;
            final expiresIn = controller.qrExpiresIn.value;

            final overlayText = statusText == 'scanned'
                ? '已扫码，请在手机上确认'
                : statusText == 'expired'
                ? '二维码已过期'
                : statusText == 'error'
                ? (error ?? '二维码状态异常')
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: image != null
                            ? Image(
                                image: image,
                                width: qrSize,
                                height: qrSize,
                                fit: BoxFit.cover,
                              )
                            : SizedBox(
                                width: qrSize,
                                height: qrSize,
                                child: const Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              ),
                      ),
                      if (overlayText != null)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              overlayText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (controller.qrPolling.value && expiresIn > 0)
                  Center(
                    child: Text(
                      '二维码 ${expiresIn ~/ 60}:${(expiresIn % 60).toString().padLeft(2, '0')} 后过期',
                      style: TextStyle(
                        fontSize: 12,
                        color: expiresIn <= 30
                            ? const Color(0xFFE53935)
                            : CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel,
                                context,
                              ),
                      ),
                    ),
                  ),
                if (error != null && overlayText == null)
                  Center(child: Text(error, style: mutedStyle)),
                const SizedBox(height: 10),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.startQrLogin(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('刷新二维码'),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _AutoSubscribeSection extends StatelessWidget {
  const _AutoSubscribeSection({required this.controller});

  final DoubanFolioFormController controller;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Section(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: '想看自动订阅',
            icon: Icons.auto_awesome_rounded,
            color: Color(0xFF7C4DFF),
          ),
          Obx(() {
            final checking = controller.autoSubscribeChecking.value;
            final result = controller.autoSubscribeResult.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '立即检查豆瓣想看并同步订阅到 MoviePilot',
                        style: mutedStyle,
                      ),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: checking
                          ? null
                          : () async {
                              await controller.checkAutoSubscribe();
                              final result =
                                  controller.autoSubscribeResult.value;
                              if (result != null) {
                                ToastUtil.info(result);
                              }
                            },
                      child: checking
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CupertinoActivityIndicator(radius: 6),
                            )
                          : const Text('立即检查'),
                    ),
                  ],
                ),
                if (result != null) ...[
                  const SizedBox(height: 6),
                  Text(result, style: mutedStyle),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// 豆瓣收藏仪表盘：统计卡 + 同步/状态/分类切换 + 海报网格（分页加载）
class _CollectionSection extends StatelessWidget {
  const _CollectionSection({required this.controller});

  final DoubanFolioFormController controller;

  /// 与 Web 端 AppPage 页签一致：同步 / 在看 / 想看 / 看过
  static const _statusTabs = [
    ('同步', 'sync', Color(0xFF7C4DFF)),
    ('在看', 'do', Color(0xFF1E88E5)),
    ('想看', 'wish', Color(0xFFFB8C00)),
    ('看过', 'collect', Color(0xFF2E9E5B)),
  ];

  static const _categoryTabs = [
    ('影视', 'movie'),
    ('图书', 'book'),
    ('音乐', 'music'),
  ];

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 12.5,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    return Obx(() {
      final summary = controller.summary.value;
      final currentStatus = controller.collectionStatus.value;
      final currentCategory = controller.collectionCategory.value;
      final items = controller.collectionItems;
      final total = controller.collectionTotal.value;
      final loading = controller.collectionLoading.value;
      final loadingMore = controller.collectionLoadingMore.value;
      final error = controller.collectionError.value;
      final logs = controller.logs;
      final isSync = currentStatus == 'sync';
      // 页签数量：同步 = 记录条数；其余取收藏统计
      int? countOf(String key) {
        if (key == 'sync') return logs.length;
        if (summary == null) return null;
        return switch (key) {
          'do' => (summary['doing'] as num?)?.toInt(),
          'wish' => (summary['wish'] as num?)?.toInt(),
          'collect' => (summary['done'] as num?)?.toInt(),
          _ => null,
        };
      }

      return Section(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: '豆瓣收藏',
              icon: Icons.local_movies_rounded,
              color: const Color(0xFF007722),
            ),
            // 页签：同步 / 在看 / 想看 / 看过（带数量，同 Web 端）
            Row(
              children: [
                for (final (label, value, color) in _statusTabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        countOf(value) != null ? '$label ${countOf(value)}' : label,
                      ),
                      selected: currentStatus == value,
                      selectedColor: color.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        color: currentStatus == value ? color : null,
                        fontWeight: currentStatus == value
                            ? FontWeight.w600
                            : null,
                      ),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) =>
                          controller.switchCollection(status: value),
                    ),
                  ),
                const Spacer(),
                // 分类页签仅收藏（想看/在看/看过）时显示
                if (!isSync)
                  for (final (label, value) in _categoryTabs)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _CategoryChip(
                        label: label,
                        selected: currentCategory == value,
                        onTap: () =>
                            controller.switchCollection(category: value),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            if (isSync) ...[
              // 同步记录：面板标题 + 海报网格（成功/失败/未匹配角标），同 Web 端
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(
                      '同步记录（${logs.length}）',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        '媒体库同步到豆瓣的记录 · 最多保留 50 条',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoDynamicColor.resolve(
                            CupertinoColors.secondaryLabel,
                            context,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (logs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('暂无同步记录', style: mutedStyle),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 3;
                    final width =
                        (constraints.maxWidth - 16) / crossAxisCount;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        for (final log in logs)
                          SizedBox(
                            width: width,
                            child: _SyncRecordCard(
                              controller: controller,
                              log: log,
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ] else ...[
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CupertinoActivityIndicator(),
                  ),
                )
              else if (error != null && items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text(error, style: mutedStyle)),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('暂无收藏', style: mutedStyle)),
                )
              else ...[
                _PosterGrid(
                  controller: controller,
                  items: items,
                  isMovie: currentCategory == 'movie',
                ),
                const SizedBox(height: 10),
                if (items.length < total)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: loadingMore
                          ? null
                          : () => controller.loadMoreCollection(),
                      icon: loadingMore
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CupertinoActivityIndicator(radius: 7),
                            )
                          : const Icon(Icons.expand_more_rounded, size: 18),
                      label: Text(
                        loadingMore
                            ? '加载中…'
                            : '加载更多（${items.length}/$total）',
                      ),
                    ),
                  )
                else
                  Center(child: Text('共 $total 条', style: mutedStyle)),
              ],
            ],
          ],
        ),
      );
    });
  }
}

/// 同步记录卡片：海报（左上角成功/失败/未匹配角标）+ 标题 + 时间·类型 + 消息
class _SyncRecordCard extends StatelessWidget {
  const _SyncRecordCard({required this.controller, required this.log});

  final DoubanFolioFormController controller;
  final DoubanFolioLog log;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 11,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    final (badgeColor, badgeText) = switch (log.result) {
      'fail' => (const Color(0xFFD32F2F), '失败'),
      'not_found' => (const Color(0xFFE68214), '未匹配'),
      _ => (const Color(0xFF2E963D), '成功'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4.2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (log.poster.isNotEmpty)
                  _PosterImage(controller: controller, poster: log.poster)
                else
                  _PosterPlaceholder(
                    icon: log.isFail
                        ? Icons.error_outline_rounded
                        : log.isNotFound
                        ? Icons.search_rounded
                        : Icons.check_circle_outline_rounded,
                  ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          log.title,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          log.type.isEmpty ? log.time : '${log.time} · ${log.type}',
          style: mutedStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (log.message.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            log.message,
            style: mutedStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

/// 海报网格：3 列卡片（海报 / 标题 / 年份·评分 / 标记日期）
class _PosterGrid extends StatelessWidget {
  const _PosterGrid({
    required this.controller,
    required this.items,
    required this.isMovie,
  });

  final DoubanFolioFormController controller;
  final List<Map<String, dynamic>> items;
  final bool isMovie;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 3;
        final width = (constraints.maxWidth - 16) / crossAxisCount;
        return Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _PosterCard(
                  controller: controller,
                  item: item,
                  isMovie: isMovie,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.controller,
    required this.item,
    required this.isMovie,
  });

  final DoubanFolioFormController controller;
  final Map<String, dynamic> item;
  final bool isMovie;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 11,
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      ),
    );
    final poster = (item['poster_hd'] ?? item['poster'] ?? '').toString();
    final rating = isMovie
        ? (item['douban_rating'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final myRating = (item['my_rating'] as num?)?.toInt() ?? 0;

    Widget posterWidget;
    if (poster.isNotEmpty) {
      posterWidget = _PosterImage(controller: controller, poster: poster);
    } else {
      posterWidget = const _PosterPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4.2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                posterWidget,
                if (rating > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Color(0xFFFFC107),
                          ),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          item['title']?.toString() ?? '',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          [
            if ((item['year'] ?? '').toString().isNotEmpty)
              item['year'].toString(),
            if (myRating > 0) '我的评分 $myRating',
            if ((item['date'] ?? '').toString().isNotEmpty)
              item['date'].toString(),
          ].join(' · '),
          style: mutedStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// 海报图：经插件 /cover 代理鉴权加载（Image.network 无 Bearer 会 401）
class _PosterImage extends StatefulWidget {
  const _PosterImage({required this.controller, required this.poster});

  final DoubanFolioFormController controller;
  final String poster;

  @override
  State<_PosterImage> createState() => _PosterImageState();
}

class _PosterImageState extends State<_PosterImage> {
  Uint8List? _bytes;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _PosterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poster != widget.poster) _load();
  }

  Future<void> _load() async {
    final cached = widget.controller.peekCoverBytes(widget.poster);
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }
    if (_loading) return;
    _loading = true;
    final bytes = await widget.controller.fetchCoverBytes(widget.poster);
    _loading = false;
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _failed = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return _PosterPlaceholder(
        icon: _failed
            ? Icons.image_not_supported_outlined
            : Icons.movie_outlined,
        loading: !_failed,
      );
    }
    return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({this.icon = Icons.movie_outlined, this.loading = false});

  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.tertiarySystemFill,
        context,
      ),
      alignment: Alignment.center,
      child: loading
          ? const CupertinoActivityIndicator()
          : Icon(
              icon,
              size: 28,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
    );
  }
}
