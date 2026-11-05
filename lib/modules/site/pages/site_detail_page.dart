import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_detail_controller.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/open_url.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SiteDetailPage extends GetView<SiteDetailController> {
  const SiteDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SiteDetailController>(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(
            controller.siteName.isNotEmpty ? controller.siteName : '站点详情',
          ),
          actions: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                final updated = await Get.toNamed(
                  '/site-edit',
                  arguments: {
                    'siteId': controller.siteId,
                    'siteName': controller.siteName,
                  },
                );
                if (updated == true) {
                  await controller.loadSiteDetail();
                }
              },
              child: const Text('编辑'),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Get.toNamed(
                  '/site-resource',
                  arguments: {
                    'siteId': controller.siteId,
                    'siteName': controller.siteName,
                  },
                );
              },
              child: const Icon(Icons.mediation),
            ),
            PopupMenuButton<String>(
              tooltip: '站点维护',
              icon: const Icon(Icons.more_vert, size: 22),
              onSelected: (value) {
                switch (value) {
                  case 'cookie':
                    _showUpdateCookieDialog(context);
                  case 'test':
                    _runSiteAction('连接测试中…', controller.testSiteConnectivity);
                  case 'cookiecloud':
                    _runSiteAction(
                      'CookieCloud 同步中…',
                      controller.syncCookieCloud,
                    );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'cookie',
                  child: Text('更新 Cookie & UA'),
                ),
                PopupMenuItem(value: 'test', child: Text('连接测试')),
                PopupMenuItem(value: 'cookiecloud', child: Text('CookieCloud 同步')),
              ],
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: controller.refreshAll),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBasicInfoSection(context),
                    const SizedBox(height: 16),
                    Obx(() => _buildChartsSection(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runSiteAction(
    String loadingText,
    Future<({bool ok, String message})> Function() action,
  ) async {
    ToastUtil.loading(message: loadingText);
    final result = await action();
    ToastUtil.dismiss();
    if (result.ok) {
      ToastUtil.success(result.message);
    } else {
      ToastUtil.error(result.message);
    }
  }

  /// 使用站点账号密码更新 Cookie&UA（POST /api/v1/site/cookie/{id}）。
  /// 服务端不支持直接粘贴 Cookie，走账号密码自动登录流程。
  Future<void> _showUpdateCookieDialog(BuildContext context) async {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('更新 Cookie & UA'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '使用站点登录账号密码自动更新 Cookie 与 UA',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: '站点用户名'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入用户名' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: '站点密码'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入密码' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: '二步验证码 / 密钥（可选）',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
    if (submitted != true) return;
    await _runSiteAction(
      '正在更新 Cookie…',
      () => controller.updateSiteCookie(
        username: usernameCtrl.text.trim(),
        password: passwordCtrl.text,
        code: codeCtrl.text,
      ),
    );
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    codeCtrl.dispose();
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    final s = controller.site;
    final theme = Theme.of(context);

    return Section(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Obx(
                () => Hero(
                  tag: 'site-icon-${controller.siteId ?? 0}',
                  child: _buildIcon(controller.iconBase64.value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s?.name ?? controller.siteName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (s != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _buildInfoRow(context, '域名', s.domain),
            _buildInfoRow(
              context,
              '地址',
              s.url,
              withSelectable: true,
              onSelectablePressed: () {
                WebUtil.open(url: s.url);
              },
              selectableIcon: CupertinoIcons.link,
              onSelectableIconPressed: () {
                Get.toNamed(
                  '/web-view',
                  parameters: {'url': s.url, 'cookie': s.cookie ?? ''},
                );
              },
            ),
            _buildInfoRow(context, '优先级', '${s.pri}'),
            _buildInfoRow(context, '状态', s.isActive ? '启用' : '禁用'),
            _buildInfoRow(context, '超时', '${s.timeout} 秒'),
            if (s.note != null && s.note!.isNotEmpty)
              _buildInfoRow(context, '备注', s.note!),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(String? iconBase64) {
    if (iconBase64 != null && iconBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(iconBase64);
        if (bytes.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholderIcon(),
            ),
          );
        }
      } catch (_) {}
    }
    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        CupertinoIcons.globe,
        color: CupertinoColors.systemGrey,
        size: 22,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool withSelectable = false,
    VoidCallback? onSelectablePressed,
    IconData? selectableIcon,
    VoidCallback? onSelectableIconPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label：',
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          GestureDetector(
            onTap: withSelectable ? onSelectablePressed : null,
            child: Text(
              value,
              style: TextStyle(
                decoration: withSelectable
                    ? TextDecoration.underline
                    : null, // ⭐ 底部横线
                decorationThickness: withSelectable ? 1.5 : 0,
                color: withSelectable
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (selectableIcon != null) ...[
            const SizedBox(width: 15),
            GestureDetector(
              onTap: onSelectableIconPressed,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  selectableIcon,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    if (controller.isLoading.value && controller.historyItems.isEmpty) {
      return Section(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    if (controller.errorText.value != null && controller.historyItems.isEmpty) {
      return Section(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.errorText.value ?? '',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: controller.loadUserdataHistory,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    final items = controller.historyItems;
    if (items.isEmpty) {
      return Section(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            '暂无用户数据历史',
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
          ),
        ),
      );
    }

    final chartData = items
        .map(
          (e) => _ChartPoint(
            e.updatedDay,
            e.upload,
            e.download,
            e.seeding,
            e.seedingSize,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildUploadDownloadChart(context, chartData),
        const SizedBox(height: 16),
        _buildSeedingChart(context, chartData),
      ],
    );
  }

  Widget _buildUploadDownloadChart(
    BuildContext context,
    List<_ChartPoint> chartData,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = AppTheme.secondaryColor;

    return Section(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '上传 / 下载变化',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelRotation: -45,
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(fontSize: 10),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: const MajorGridLines(
                  width: 1,
                  color: CupertinoColors.systemGrey5,
                ),
                labelStyle: const TextStyle(fontSize: 10),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
              ),
              series: <CartesianSeries<_ChartPoint, String>>[
                LineSeries<_ChartPoint, String>(
                  dataSource: chartData,
                  xValueMapper: (_ChartPoint d, _) => d.date,
                  yValueMapper: (_ChartPoint d, _) =>
                      d.upload / 1024 / 1024 / 1024,
                  name: '上传 (GB)',
                  color: primary,
                  width: 2,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 4,
                    width: 4,
                  ),
                ),
                LineSeries<_ChartPoint, String>(
                  dataSource: chartData,
                  xValueMapper: (_ChartPoint d, _) => d.date,
                  yValueMapper: (_ChartPoint d, _) =>
                      d.download / 1024 / 1024 / 1024,
                  name: '下载 (GB)',
                  color: secondary,
                  width: 2,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 4,
                    width: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedingChart(BuildContext context, List<_ChartPoint> chartData) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Section(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '做种分布',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelRotation: -45,
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(fontSize: 10),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: const MajorGridLines(
                  width: 1,
                  color: CupertinoColors.systemGrey5,
                ),
                labelStyle: const TextStyle(fontSize: 10),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<_ChartPoint, String>>[
                LineSeries<_ChartPoint, String>(
                  dataSource: chartData,
                  xValueMapper: (_ChartPoint d, _) => d.date,
                  yValueMapper: (_ChartPoint d, _) => d.seeding,
                  name: '做种数',
                  color: primary,
                  width: 2,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 4,
                    width: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  _ChartPoint(
    this.date,
    this.upload,
    this.download,
    this.seeding,
    this.seedingSize,
  );
  final String date;
  final double upload;
  final double download;
  final double seeding;
  final double seedingSize;
}
