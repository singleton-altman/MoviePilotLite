import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_controller.dart';
import 'package:moviepilot_mobile/modules/site/controllers/site_statistic_controller.dart';
import 'package:moviepilot_mobile/modules/site/models/site_statistic_models.dart';
import 'package:moviepilot_mobile/modules/site/models/site_models.dart';
import 'package:moviepilot_mobile/modules/site/pages/site_statistic_page.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/utils/size_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SitePage extends StatefulWidget {
  const SitePage({super.key});

  @override
  State<SitePage> createState() => _SitePageState();
}

enum _SiteStatusFilter { all, normal, failed, slow }

enum _SiteSortType { pri, upload, download }

class _SitePageState extends State<SitePage> {
  final SiteController controller = Get.find<SiteController>();
  static const String _statTag = 'site-page-stat';
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _SiteStatusFilter _statusFilter = _SiteStatusFilter.all;
  _SiteSortType _sortType = _SiteSortType.pri;
  bool _privacyMode = false;

  static const String _prefsPrivacyKey = 'site_page_privacy_mode';
  static const double _floatingBarHeight = 52;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SiteStatisticController>(tag: _statTag)) {
      Get.find<SiteStatisticController>(tag: _statTag).load();
    } else {
      Get.put(SiteStatisticController(), tag: _statTag, permanent: false);
    }
    _loadPrivacyMode();
  }

  Future<void> _loadPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_prefsPrivacyKey) ?? false;
    if (!mounted) return;
    setState(() => _privacyMode = v);
  }

  Future<void> _savePrivacyMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsPrivacyKey, value);
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (Get.isRegistered<SiteStatisticController>(tag: _statTag)) {
      Get.delete<SiteStatisticController>(tag: _statTag);
    }
    super.dispose();
  }

  void _selectItem(SiteItem item) {
    Get.toNamed(
      '/site-detail',
      arguments: {
        'siteId': item.site.id,
        'siteName': item.site.name,
        'site': item.site.toJson(),
      },
    );
  }

  void _openStatistic(BuildContext context) {
    Get.put(SiteStatisticController(), permanent: false);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return const SiteStatisticPage();
      },
    ).then((_) {
      Get.delete<SiteStatisticController>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '站点管理',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openStatistic(context),
            child: const Icon(CupertinoIcons.chart_bar),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFilterSortFloatingBar(context),
      body: Obx(() {
        final statController = Get.find<SiteStatisticController>(
          tag: _SitePageState._statTag,
        );
        final statByDomain = <String, SiteStatisticItem>{
          for (final e in statController.items) e.domain: e,
        };
        if (controller.isLoading.value && controller.items.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (controller.errorText.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.errorText.value ?? '',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: controller.load,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final q = _query.trim().toLowerCase();
        final all = controller.items.toList();
        final filtered = all.where((s) {
          final hit = q.isEmpty
              ? true
              : (s.site.name.toLowerCase().contains(q) ||
                    s.site.domain.toLowerCase().contains(q));
          if (!hit) return false;

          final stat = statByDomain[s.site.domain];
          final failRate = (stat == null || (stat.success + stat.fail) == 0)
              ? 0.0
              : stat.fail / (stat.success + stat.fail);
          final isFailed =
              (s.userData?.errMsg ?? '').trim().isNotEmpty ||
              (stat?.lstState == 1) ||
              failRate > 0.5;
          final isSlow = (stat?.seconds ?? 0) > 5;
          switch (_statusFilter) {
            case _SiteStatusFilter.all:
              return true;
            case _SiteStatusFilter.normal:
              return !isFailed && !isSlow;
            case _SiteStatusFilter.failed:
              return isFailed;
            case _SiteStatusFilter.slow:
              return !isFailed && isSlow;
          }
        }).toList();

        int cmpNum(num a, num b) => a == b ? 0 : (a < b ? -1 : 1);

        filtered.sort((a, b) {
          switch (_sortType) {
            case _SiteSortType.pri:
              return cmpNum(a.site.pri, b.site.pri);
            case _SiteSortType.upload:
              final au = a.userData?.upload ?? 0;
              final bu = b.userData?.upload ?? 0;
              return cmpNum(bu, au);
            case _SiteSortType.download:
              final ad = a.userData?.download ?? 0;
              final bd = b.userData?.download ?? 0;
              return cmpNum(bd, ad);
          }
        });

        return RefreshIndicator(
          onRefresh: controller.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildPrivacyToggle(context)),
              Skeletonizer.sliver(
                enabled:
                    controller.isLoading.value && controller.items.isNotEmpty,
                child: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  sliver: filtered.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('无匹配结果')),
                        )
                      : SliverList.builder(
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _selectItem(item),
                                child: _SiteItemCard(
                                  item: item,
                                  privacyMode: _privacyMode,
                                  statByDomain: statByDomain,
                                ),
                              ),
                            );
                          },
                          itemCount: filtered.length,
                        ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: _floatingBarHeight + 32),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPrivacyToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
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
            value: _privacyMode,
            onChanged: (v) {
              setState(() => _privacyMode = v);
              _savePrivacyMode(v);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSortFloatingBar(BuildContext context) {
    final theme = Theme.of(context);
    final child = Row(
      children: [
        _buildFloatingFilterButton(context),
        const SizedBox(width: 8),
        Expanded(child: _buildFloatingSearchBar(context)),
        const SizedBox(width: 8),
        _buildFloatingSortButton(context),
      ],
    );
    final pill = Container(
      height: _floatingBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: theme.colorScheme.surface.withValues(alpha: 0.2),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: pill,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingFilterButton(BuildContext context) {
    final active = _statusFilter != _SiteStatusFilter.all;
    final color = active
        ? CupertinoDynamicColor.resolve(CupertinoColors.activeBlue, context)
        : CupertinoDynamicColor.resolve(
            CupertinoColors.secondaryLabel,
            context,
          );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () async {
        final selected = await showModalBottomSheet<_SiteStatusFilter>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _SimplePickerSheet<_SiteStatusFilter>(
            title: '筛选',
            values: const [
              _SiteStatusFilter.all,
              _SiteStatusFilter.normal,
              _SiteStatusFilter.failed,
              _SiteStatusFilter.slow,
            ],
            selected: _statusFilter,
            colorOf: (v) => switch (v) {
              _SiteStatusFilter.all => Colors.grey,
              _SiteStatusFilter.normal => Colors.green,
              _SiteStatusFilter.failed => Colors.red,
              _SiteStatusFilter.slow => Colors.yellow,
            },
            labelOf: (v) => v == _SiteStatusFilter.all
                ? '全部'
                : (v == _SiteStatusFilter.normal
                      ? '正常'
                      : (v == _SiteStatusFilter.failed ? '失败' : '缓慢')),
          ),
        );
        if (selected != null && mounted) {
          setState(() => _statusFilter = selected);
        }
      },
      child: Icon(CupertinoIcons.slider_horizontal_3, size: 20, color: color),
    );
  }

  Widget _buildFloatingSortButton(BuildContext context) {
    final color = CupertinoDynamicColor.resolve(
      CupertinoColors.secondaryLabel,
      context,
    );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () async {
        final selected = await showModalBottomSheet<_SiteSortType>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _SimplePickerSheet<_SiteSortType>(
            title: '排序',
            values: const [
              _SiteSortType.pri,
              _SiteSortType.upload,
              _SiteSortType.download,
            ],
            selected: _sortType,
            labelOf: (v) => v == _SiteSortType.pri
                ? '优先级'
                : (v == _SiteSortType.upload ? '上传量' : '下载量'),
          ),
        );
        if (selected != null && mounted) {
          setState(() => _sortType = selected);
        }
      },
      child: Icon(CupertinoIcons.sort_down, size: 20, color: color),
    );
  }

  Widget _buildFloatingSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _openKeywordSheet(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _query.isEmpty ? '搜索站点名称或域名…' : _query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openKeywordSheet(BuildContext context) async {
    final controllerText = TextEditingController(text: _query);
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemBackground,
                ctx,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: CupertinoSearchTextField(
              controller: controllerText,
              autofocus: true,
              placeholder: '搜索站点名称或域名…',
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ),
        );
      },
    );
    controllerText.dispose();
    if (submitted == null) return;
    setState(() => _query = submitted);
    _searchController.text = submitted;
  }
}

class _SiteItemCard extends StatelessWidget {
  const _SiteItemCard({
    this.item,
    required this.privacyMode,
    required this.statByDomain,
  });

  final SiteItem? item;
  final bool privacyMode;
  final Map<String, SiteStatisticItem> statByDomain;

  @override
  Widget build(BuildContext context) {
    final site = item?.site;
    final user = item?.userData;
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final outline = theme.colorScheme.outline;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUpdateTime(context, user, statByDomain[site?.domain ?? '']),
          _buildSiteInfo(
            context,
            siteName: site?.name ?? '',
            icon: item != null
                ? _buildIcon(item!.iconBytes, item!.iconBase64)
                : _placeholderIcon(),
            siteId: site?.id,
            isActive: site?.isActive ?? true,
            privacyMode: privacyMode,
            user: user,
          ),
          const SizedBox(height: 10),
          if (user != null) _buildTotalData(context, user),
        ],
      ),
    );
  }

  Widget _buildUpdateTime(
    BuildContext context,
    SiteUserDataModel? user,
    SiteStatisticItem? metrics,
  ) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final date =
        (user != null &&
            (user.updatedDay.isNotEmpty || user.updatedTime.isNotEmpty))
        ? '${user.updatedDay} ${user.updatedTime}'.trim()
        : '-';
    final statusColor = _statusColor(metrics);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.update_rounded, size: 14, color: onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '更新时间: $date',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacer(),
          _BreathingStatusDot(color: statusColor),
        ],
      ),
    );
  }

  Color _statusColor(SiteStatisticItem? metrics) {
    if (metrics == null) {
      return Colors.green;
    }
    final total = metrics.success + metrics.fail;
    final failRate = total > 0 ? metrics.fail / total : 0.0;
    if (metrics.lstState == 1 || failRate > 0.5) {
      return Colors.red;
    }
    if (metrics.seconds > 5) {
      return Colors.yellow;
    }
    return Colors.green;
  }

  Widget _buildSiteInfo(
    BuildContext context, {
    required String siteName,
    required Widget icon,
    required int? siteId,
    required bool isActive,
    required bool privacyMode,
    required SiteUserDataModel? user,
  }) {
    final theme = Theme.of(context);
    final surfaceContainer = theme.colorScheme.surfaceContainer;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    final sensitiveContent = Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: SizedBox(width: 56, height: 56, child: icon),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    siteName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 8),
                  if (user != null && user.userLevel.isNotEmpty)
                    Text(
                      user.userLevel,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (user != null && user.messageUnread > 0) ...[
                    const SizedBox(width: 8),
                    _buildChip('未读 ${user.messageUnread}', AppTheme.errorColor),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              if (user != null)
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: user.username.isEmpty
                                    ? '-'
                                    : user.username,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: user.userid.isEmpty
                                    ? '-'
                                    : ' / ID ${user.userid}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: surfaceContainer.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          sensitiveContent,
          if (privacyMode)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    color: theme.colorScheme.surface.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalData(BuildContext context, SiteUserDataModel user) {
    final theme = Theme.of(context);
    final surfaceContainer = theme.colorScheme.surfaceContainer;
    final outline = theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: surfaceContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: outline.withValues(alpha: 0.08), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDataItem(
                  context,
                  Icons.storage_rounded,
                  '总上传量',
                  SizeFormatter.formatSize(user.upload.toDouble(), 2),
                  CupertinoColors.systemGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDataItem(
                  context,
                  Icons.numbers_rounded,
                  '总下载量',
                  SizeFormatter.formatSize(user.download.toDouble(), 2),
                  CupertinoColors.systemBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDataItem(
                  context,
                  Icons.storage_rounded,
                  '做种体积',
                  SizeFormatter.formatSize(user.seedingSize.toDouble()),
                  CupertinoColors.systemPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDataItem(
                  context,
                  Icons.numbers_rounded,
                  '做种数',
                  user.seeding.toString(),
                  CupertinoColors.systemPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDataItem(
                  context,
                  Icons.stars_rounded,
                  '积分',
                  user.bonus.toString(),
                  AppTheme.infoColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDataItem(
                  context,
                  Icons.trending_up_rounded,
                  '分享率',
                  user.ratio.toString(),
                  _ratioColor(user.ratio),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 优先使用已解码的 iconBytes，避免在 build 时重复 base64 解码导致滑动卡顿；兼容带 data:image/xxx;base64, 前缀的 iconBase64
  Widget _buildIcon(List<int>? iconBytes, String? iconBase64) {
    Uint8List? bytes;
    if (iconBytes != null && iconBytes.isNotEmpty) {
      bytes = Uint8List.fromList(iconBytes);
    } else if (iconBase64 != null && iconBase64.isNotEmpty) {
      try {
        String base64 = iconBase64.trim();
        if (base64.contains(',')) {
          final comma = base64.indexOf(',');
          base64 = base64.substring(comma + 1).trim();
        }
        if (base64.isNotEmpty) {
          final decoded = base64Decode(base64);
          if (decoded.isNotEmpty) bytes = decoded;
        }
      } catch (_) {}
    }
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _placeholderIcon(),
        ),
      );
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

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _ratioColor(double ratio) {
    if (ratio >= 5) return AppTheme.successColor;
    if (ratio >= 1) return AppTheme.infoColor;
    return AppTheme.errorColor;
  }
}

class _SimplePickerSheet<T> extends StatelessWidget {
  const _SimplePickerSheet({
    required this.title,
    required this.values,
    required this.labelOf,
    required this.selected,
    this.colorOf,
  });

  final String title;
  final List<T> values;
  final String Function(T value) labelOf;
  final T selected;
  final Color Function(T value)? colorOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final outline = theme.colorScheme.outline.withValues(alpha: 0.12);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: values.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
                itemBuilder: (context, index) {
                  final v = values[index];
                  final isSelected = v == selected;
                  return ListTile(
                    title: Row(
                      children: [
                        if (colorOf != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorOf!(v),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          labelOf(v),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(v),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingStatusDot extends StatefulWidget {
  const _BreathingStatusDot({required this.color});

  final Color color;

  @override
  State<_BreathingStatusDot> createState() => _BreathingStatusDotState();
}

class _BreathingStatusDotState extends State<_BreathingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.9,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacity = Tween<double>(
      begin: 0.45,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
