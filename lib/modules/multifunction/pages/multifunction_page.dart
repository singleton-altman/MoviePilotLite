import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_widget_styles.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/modules/multifunction/models/multifunction_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_mappings.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/app_glass_card.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';
import 'package:moviepilot_mobile/widgets/dashboard_scaffold.dart';

class MultifunctionPage extends GetView<MultifunctionController> {
  const MultifunctionPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  DashboardPaletteData get _palette =>
      DashboardPalette.of(Get.context ?? Get.overlayContext!);

  bool get _isDark => _palette.isDark;
  Color get _surface => _palette.surface;
  Color get _surfaceHighest => _palette.surfaceAlt;
  Color get _outlineSoft => _palette.tileBorder;
  Color get _textPrimary => _palette.titleText;
  Color get _textSecondary => _palette.bodyText;
  Color get _textMuted => _palette.mutedText;
  Color get _primary => _palette.primary;
  Color get _primaryStrong => _palette.primary;
  Color get _secondary => _palette.coolAccent;
  Color get _secondaryStrong => _palette.warmAccent;
  Color get _error => _palette.warningAccent;

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      appBar: _buildNavigationBar(context),
      body: Obx(() {
        final modules = controller.buildDashboardModules();
        final modulesByRoute = <String, DashboardModuleViewModel>{
          for (final module in modules) module.route: module,
        };
        final calendarSegment = controller.calendarSegment.value;
        final calendarInfo = controller.calendarInfo.value;
        final calendarItems = calendarSegment == 'today'
            ? calendarInfo.todayItems
            : calendarInfo.weekItems;
        final hiddenRoutes = <String>{
          '/subscribe-movie',
          '/subscribe-tv',
          '/subscribe-music',
          '/music',
          '/site',
          '/downloader',
          '/subscribe-calendar',
          '/plugin',
        };
        final utilityModules = modules
            .where((module) => !hiddenRoutes.contains(module.route))
            .toList();
        final sidebarNavItems = controller.sidebarNavItems;

        return LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth;
            final horizontalPadding = pageWidth >= 720 ? 24.0 : 20.0;
            final contentMaxWidth = pageWidth >= 1100 ? 1024.0 : 920.0;
            final topPadding = MediaQuery.paddingOf(context).top + 12;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: RefreshIndicator(
                  onRefresh: controller.refreshDashboard,
                  color: _primaryStrong,
                  backgroundColor: _surfaceHighest,
                  child: ListView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      104,
                    ),
                    children: [
                      if (controller.canAccessSubscribe) ...[
                        _buildSubscriptionSection(
                          pageWidth: pageWidth,
                          movieModule: modulesByRoute['/subscribe-movie'],
                          tvModule: modulesByRoute['/subscribe-tv'],
                          musicModule: modulesByRoute['/subscribe-music'],
                        ),
                        const SizedBox(height: 24),
                        _buildReleasesSection(
                          pageWidth: pageWidth,
                          segment: calendarSegment,
                          items: calendarItems,
                          module: modulesByRoute['/subscribe-calendar'],
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (controller.musicLibrarySupported.value) ...[
                        _buildMusicSection(module: modulesByRoute['/music']),
                        const SizedBox(height: 24),
                      ],
                      if (modulesByRoute['/site'] != null) ...[
                        _buildSitesSection(modulesByRoute['/site']!),
                        const SizedBox(height: 24),
                      ],
                      if (modulesByRoute['/downloader'] != null) ...[
                        _buildDownloaderSection(pageWidth: pageWidth),
                        const SizedBox(height: 24),
                      ],
                      if (controller.canAccessManage) ...[
                        _buildPluginSidebarSection(
                          pageWidth: pageWidth,
                          items: sidebarNavItems,
                          pluginModule: modulesByRoute['/plugin'],
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (utilityModules.isNotEmpty)
                        _buildUtilitiesSection(modules: utilityModules),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  PreferredSizeWidget _buildNavigationBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      titleSpacing: 20,
      title: Row(
        children: [
          Text(
            '更多',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            final online = controller.subscribeDataReady.value;
            final statusColor = online
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: _isDark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    online ? '已连接' : '连接中',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      centerTitle: false,
      actions: [
        Semantics(
          button: true,
          label: '设置',
          child: SizedBox(
            width: 44,
            height: 44,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Get.toNamed('/settings'),
              child: Icon(CupertinoIcons.settings, size: 20, color: _textMuted),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    IconData? icon,
    Color? accent,
    String? trailing,
    VoidCallback? onTap,
    Widget? trailingWidget,
  }) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                height: 1.2,
              ),
            ),
          ),
          if (trailingWidget != null) trailingWidget,
          if (trailing != null && trailingWidget == null) ...[
            Text(
              trailing,
              style: TextStyle(
                color: _textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(CupertinoIcons.chevron_forward, size: 14, color: _textMuted),
            ],
          ],
          if (trailing == null && trailingWidget == null && onTap != null)
            Icon(CupertinoIcons.chevron_forward, size: 14, color: _textMuted),
        ],
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: trailing == null ? title : '$title，$trailing',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }

  Widget _buildSubscriptionSection({
    required double pageWidth,
    DashboardModuleViewModel? movieModule,
    DashboardModuleViewModel? tvModule,
    DashboardModuleViewModel? musicModule,
  }) {
    final info = controller.subscribeInfo.value;
    final moviePosters = _postersForRoute('/subscribe-movie');
    final tvPosters = _postersForRoute('/subscribe-tv');
    final musicPosters = _postersForRoute('/subscribe-music');
    final useColumns = pageWidth >= 700;

    final movieCard = _subscriptionCategoryCard(
      title: '电影订阅',
      count: info.movieCount,
      accent: _primaryStrong,
      posters: moviePosters,
      icon: Icons.movie_filter_rounded,
      unit: '部',
      onTap: movieModule == null
          ? null
          : () => controller.handleRouteTap(
              movieModule.route,
              title: movieModule.title,
            ),
    );
    final tvCard = _subscriptionCategoryCard(
      title: '剧集订阅',
      count: info.tvCount,
      accent: _secondaryStrong,
      posters: tvPosters,
      icon: Icons.live_tv_rounded,
      unit: '部',
      onTap: tvModule == null
          ? null
          : () => controller.handleRouteTap(
              tvModule.route,
              title: tvModule.title,
            ),
    );
    final musicCard = _subscriptionCategoryCard(
      title: '音乐订阅',
      count: info.musicCount,
      accent: const Color(0xFF8B5CF6),
      posters: musicPosters,
      icon: Icons.library_music_rounded,
      unit: '张',
      onTap: musicModule == null
          ? null
          : () => controller.handleRouteTap(
              musicModule.route,
              title: musicModule.title,
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '订阅',
          icon: CupertinoIcons.star_fill,
          accent: _primary,
          trailing: controller.subscribeDataReady.value
              ? '共 ${info.movieCount + info.tvCount + info.musicCount} 个'
              : null,
          onTap: controller.subscribeDataReady.value
              ? () => Get.toNamed('/subscribe-calendar')
              : null,
          trailingWidget: !controller.subscribeDataReady.value
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 14,
                      color: _textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '数据暂不可用',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : null,
        ),
        const SizedBox(height: 8),
        if (useColumns)
          Row(
            children: [
              Expanded(child: movieCard),
              const SizedBox(width: 12),
              Expanded(child: tvCard),
              const SizedBox(width: 12),
              Expanded(child: musicCard),
            ],
          )
        else
          Column(
            children: [
              movieCard,
              const SizedBox(height: 12),
              tvCard,
              const SizedBox(height: 12),
              musicCard,
            ],
          ),
      ],
    );
  }

  Widget _subscriptionCategoryCard({
    required String title,
    required int count,
    required Color accent,
    required List<String> posters,
    required IconData icon,
    required String unit,
    VoidCallback? onTap,
  }) {
    final backdrop = posters.isNotEmpty ? posters.first.trim() : '';
    final fanPosters = posters.length > 1
        ? posters.sublist(1, posters.length.clamp(2, 4)).toList()
        : <String>[];
    return Semantics(
      button: onTap != null,
      label: '$title，共 $count $unit',
      child: AppGlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        borderRadius: 24,
        accentColor: accent,
        child: SizedBox(
          height: 132,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (backdrop.isNotEmpty)
                  CachedImage(imageUrl: backdrop, fit: BoxFit.cover)
                else
                  _buildSubscriptionPlaceholder(accent: accent, icon: icon),
                Positioned.fill(child: _buildCardScrim()),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (fanPosters.isNotEmpty)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: _buildMiniPosterFan(fanPosters),
                  ),
                Positioned(
                  left: 16,
                  right: fanPosters.isNotEmpty ? 118 : 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              unit,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 底部渐变遮罩：压暗封面以承载白色文字
  Widget _buildCardScrim() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.16),
            Colors.black.withValues(alpha: 0.68),
          ],
          stops: const [0, 0.42, 1],
        ),
      ),
    );
  }

  /// 次要封面扇形堆叠（最多两张）
  Widget _buildMiniPosterFan(List<String> posters) {
    const angles = [-0.16, 0.16];
    final children = <Widget>[];
    for (var i = 0; i < posters.length; i++) {
      children.add(
        Positioned(
          left: i * 22.0,
          child: Transform.rotate(
            angle: angles[i % 2],
            child: Container(
              width: 44,
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.9),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedImage(imageUrl: posters[i], fit: BoxFit.cover),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: 44 + (posters.length > 1 ? 22.0 : 0),
      height: 72,
      child: Stack(children: children.reversed.toList()),
    );
  }

  /// 无封面时的占位背景：品类主色渐变 + 扇形铺排的图标封面
  Widget _buildSubscriptionPlaceholder({
    required Color accent,
    required IconData icon,
  }) {
    final placeholders = [
      (angle: -0.21, left: 6.0, top: 22.0),
      (angle: 0.0, left: 26.0, top: 16.0),
      (angle: 0.21, left: 46.0, top: 22.0),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: _isDark ? 0.4 : 0.32),
            _surfaceHighest.withValues(alpha: _isDark ? 0.86 : 0.92),
          ],
        ),
      ),
      child: Stack(
        children: [
          for (final tile in placeholders)
            Positioned(
              left: tile.left,
              top: tile.top,
              child: Transform.rotate(
                angle: tile.angle,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _surfaceHighest.withValues(
                      alpha: _isDark ? 0.82 : 0.92,
                    ),
                    border: Border.all(
                      color: _isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.9),
                      width: 1.1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: accent.withValues(alpha: _isDark ? 0.9 : 0.78),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 音乐库专属入口：v3 旗舰新特性，紫色 Hero 卡突出展示
  Widget _buildMusicSection({DashboardModuleViewModel? module}) {
    final route = module?.route ?? '/music';
    final title = module?.title ?? '音乐库';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '音乐',
          icon: Icons.library_music_rounded,
          accent: const Color(0xFF8B5CF6),
          trailing: 'v3 新特性',
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: '音乐库，专辑与音乐人浏览',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () =>
                  controller.handleRouteTap(route, title: module?.title),
              child: Container(
                height: 92,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isDark
                        ? [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                            const Color(0xFF4C1D95).withValues(alpha: 0.85),
                          ]
                        : [
                            const Color(0xFFA78BFA).withValues(alpha: 0.88),
                            const Color(0xFF6D28D9).withValues(alpha: 0.94),
                          ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -12,
                      bottom: -22,
                      child: Icon(
                        Icons.library_music_rounded,
                        size: 116,
                        color: Colors.white.withValues(alpha: 0.13),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: const Text(
                                        'v3 新特性',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '专辑 · 艺术家 · 音轨浏览与媒体库播放',
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: 0.78,
                                    ),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReleasesSection({
    required double pageWidth,
    required String segment,
    required List<DashboardCalendarEntry> items,
    DashboardModuleViewModel? module,
  }) {
    final cardWidth = pageWidth >= 720 ? 144.0 : 128.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '上映日历',
          icon: CupertinoIcons.calendar,
          accent: _secondary,
          trailingWidget: _segmentedControl(
            value: segment,
            onChanged: (next) {
              controller.setCalendarSegment(next);
            },
          ),
        ),
        if (controller.isCalendarMockEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '测试数据 · 仅“更多”页 · 今天 2 集 / 本周 4 集',
              style: TextStyle(color: _secondary, fontSize: 13),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          key: ValueKey('release-$segment'),
          height: items.isEmpty ? 88 : 206,
          child: items.isEmpty
              ? _emptyReleasesCard(module)
              : ListView.separated(
                  key: ValueKey('release-list-$segment'),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return _releasePosterCard(
                      width: cardWidth,
                      entry: item,
                      chipText: segment == 'today'
                          ? item.episodeCode
                          : _shortDate(item.airDate),
                      seasonEpisodeTag: segment == 'week'
                          ? item.episodeCode
                          : null,
                      onTap: module == null
                          ? null
                          : () => controller.handleRouteTap(
                              module.route,
                              title: module.title,
                            ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemCount: items.length,
                ),
        ),
        if (items.isNotEmpty && controller.calendarError.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              controller.calendarError.value!,
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _segmentedControl({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return CupertinoTheme(
      data: CupertinoThemeData(primaryColor: _textPrimary),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: value,
        backgroundColor: _surface,
        thumbColor: _surfaceHighest,
        children: {
          'today': Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '今天',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
          'week': Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '本周',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
        },
        onValueChanged: (next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }

  Widget _releasePosterCard({
    required double width,
    required DashboardCalendarEntry entry,
    required String chipText,
    String? seasonEpisodeTag,
    VoidCallback? onTap,
  }) {
    final poster = controller.normalizePoster(entry.poster);
    return Semantics(
      button: onTap != null,
      label: [
        entry.showName,
        if (seasonEpisodeTag != null) seasonEpisodeTag,
        chipText,
      ].join('，'),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _surfaceHighest,
                      border: Border.all(color: _outlineSoft),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (poster.isNotEmpty)
                          CachedImage(
                            imageUrl: ImageUtil.convertCacheImageUrl(poster),
                            fit: BoxFit.cover,
                          )
                        else
                          Center(
                            child: Icon(
                              CupertinoIcons.tv,
                              color: _textMuted,
                              size: 28,
                            ),
                          ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: seasonEpisodeTag == null
                              ? const SizedBox.shrink()
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    seasonEpisodeTag,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              chipText,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.showName,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyReleasesCard(DashboardModuleViewModel? module) {
    return GestureDetector(
      onTap: module == null
          ? null
          : () => controller.handleRouteTap(module.route, title: module.title),
      child: _glassCard(
        child: Center(
          child: Text(
            controller.calendarError.value ??
                (controller.isLoadingDashboard.value
                    ? '上映日历加载中…'
                    : '暂无上映日历数据'),
            style: TextStyle(
              color: _textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSitesSection(DashboardModuleViewModel module) {
    final info = controller.siteInfo.value;
    final shareRate = info.totalDownload > 0
        ? (info.totalUpload / info.totalDownload).toStringAsFixed(2)
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '站点',
          icon: CupertinoIcons.globe,
          accent: _primary,
          trailing: controller.siteDataReady.value
              ? '${info.siteCount} 个站点在线'
              : null,
          onTap: () =>
              controller.handleRouteTap(module.route, title: module.title),
        ),
        const SizedBox(height: 8),
        _glassCard(
          onTap: () =>
              controller.handleRouteTap(module.route, title: module.title),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _siteRow(
                icon: Icons.dns_rounded,
                iconColor: _primary,
                title: '站点数量',
                subtitle: '当前已接入并启用的站点',
                value: '${info.siteCount} 个',
                valueColor: _textPrimary,
                showDivider: true,
              ),
              _siteRow(
                icon: Icons.north_east_rounded,
                iconColor: _primaryStrong,
                title: '累计上传',
                subtitle: '站点用户数据汇总流量',
                value: _shortSize(info.totalUpload),
                valueColor: _secondary,
                showDivider: true,
              ),
              _siteRow(
                icon: Icons.south_east_rounded,
                iconColor: _secondary,
                title: '累计下载',
                subtitle: '站点用户数据汇总流量',
                value: _shortSize(info.totalDownload),
                valueColor: _palette.successAccent,
                showDivider: true,
              ),
              _siteRow(
                icon: Icons.balance_rounded,
                iconColor: _palette.warmAccent,
                title: '平均分享率',
                subtitle: '上传与下载流量比值',
                value: shareRate,
                valueColor: _palette.warmAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _siteRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    required Color valueColor,
    bool showDivider = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: _outlineSoft, width: 0.5))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: iconColor == _error ? _error : _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloaderSection({required double pageWidth}) {
    final info = controller.downloaderInfo.value;
    final clients = info.clients;
    final isCompact = pageWidth < 360;
    final ready = controller.downloaderDataReady.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '下载器',
          icon: CupertinoIcons.arrow_down_circle_fill,
          accent: _secondary,
          trailing: ready ? '${clients.length} 个' : '加载中',
          onTap: controller.openDownloaderList,
        ),
        const SizedBox(height: 8),
        _glassCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _downloaderMetricCard(
                      icon: CupertinoIcons.arrow_down_circle_fill,
                      label: '下载',
                      value: _metricNumber(info.totalDownloadSpeed),
                      unit: _metricUnit(info.totalDownloadSpeed),
                      accent: _primary,
                      active: info.totalDownloadSpeed > 0,
                    ),
                  ),
                  SizedBox(width: isCompact ? 8 : 12),
                  Expanded(
                    child: _downloaderMetricCard(
                      icon: CupertinoIcons.arrow_up_circle_fill,
                      label: '上传',
                      value: _metricNumber(info.totalUploadSpeed),
                      unit: _metricUnit(info.totalUploadSpeed),
                      accent: _secondary,
                      active: info.totalUploadSpeed > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!ready)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (clients.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      '暂无下载器，点击上方前往配置',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                for (var i = 0; i < clients.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _buildDownloaderClientRow(clients[i]),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDownloaderClientRow(DownloaderClientInfo client) {
    final typeLabel = _downloaderTypeLabel(client.type);
    return Semantics(
      button: true,
      label:
          '${client.name}，${typeLabel.isEmpty ? '' : '$typeLabel，'}'
          '下载 ${_formatSpeedText(client.downloadSpeed)}，'
          '上传 ${_formatSpeedText(client.uploadSpeed)}',
      child: Material(
        color: _surfaceHighest.withValues(alpha: _isDark ? 0.34 : 0.72),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => controller.openDownloaderClient(client),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _surface.withValues(alpha: _isDark ? 0.9 : 1),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _outlineSoft),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _downloaderLogo(client.type).image(
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          client.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (typeLabel.isNotEmpty) typeLabel,
                            '↓ ${_formatSpeedText(client.downloadSpeed)}',
                            '↑ ${_formatSpeedText(client.uploadSpeed)}',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: _textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _downloaderTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'qbittorrent':
        return 'qB';
      case 'transmission':
        return 'TR';
      default:
        return type.trim();
    }
  }

  AssetGenImage _downloaderLogo(String type) {
    return switch (type.toLowerCase()) {
      'qbittorrent' => Assets.images.logos.qbittorrent,
      'transmission' => Assets.images.logos.transmission,
      _ => Assets.images.logos.downloader,
    };
  }

  String _formatSpeedText(double value) {
    final parts = _sizeParts(value);
    return '${parts.$1} ${parts.$2}/s';
  }

  Widget _downloaderMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color accent,
    bool active = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (active ? const Color(0xFF10B981) : _textMuted)
                      .withValues(alpha: _isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  active ? 'Active' : '空闲',
                  style: TextStyle(
                    color: active ? const Color(0xFF10B981) : _textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 4,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPluginSidebarSection({
    required double pageWidth,
    required List<PluginSidebarNavItem> items,
    DashboardModuleViewModel? pluginModule,
  }) {
    final crossAxisCount = pageWidth >= 960
        ? 4
        : pageWidth >= 640
        ? 3
        : 2;
    final childAspectRatio = pageWidth >= 640 ? 1.65 : 1.35;
    final pluginMeta = pluginModule?.primaryText.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '插件中心',
          icon: CupertinoIcons.square_grid_2x2_fill,
          accent: _palette.warmAccent,
          trailing: items.isEmpty
              ? (pluginMeta.isEmpty ? null : pluginMeta)
              : '已启用 ${items.length} 个',
          onTap: () => controller.handleRouteTap('/plugin', title: '插件'),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (_, index) =>
                _pluginSidebarCard(items[index], index: index),
          ),
        ],
      ],
    );
  }

  Widget _pluginSidebarCard(PluginSidebarNavItem item, {required int index}) {
    final accent = _sidebarAccent(item.section, index);
    final icon =
        VuetifyMappings.iconFromMdi(item.icon) ?? Icons.extension_outlined;
    final softAccent = _softUtilityAccent(accent);
    final iconBackground = _isDark
        ? accent.withValues(alpha: 0.14)
        : softAccent.withValues(alpha: 0.72);
    final arrowBackground = _surfaceHighest.withValues(
      alpha: _isDark ? 0.36 : 0.54,
    );
    final subtitle = _sidebarSectionLabel(item.section);

    return Semantics(
      button: true,
      label: '${item.title}，$subtitle',
      child: AppGlassCard(
        onTap: () => controller.handleSidebarNavTap(item),
        padding: const EdgeInsets.all(14),
        borderRadius: 24,
        accentColor: accent,
        surfaceAlpha: _isDark ? 0.54 : 0.70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: _isDark ? 0.08 : 0.14),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(icon, size: 21, color: accent),
                ),
                const Spacer(),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: arrowBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _sidebarAccent(String section, int index) {
    switch (section) {
      case 'organize':
        return _palette.warmAccent;
      case 'system':
        return _palette.coolAccent;
      default:
        return index.isEven ? _primary : _secondary;
    }
  }

  String _sidebarSectionLabel(String section) {
    switch (section) {
      case 'organize':
        return '整理插件';
      case 'system':
        return '系统插件';
      default:
        return '插件功能';
    }
  }

  Widget _buildUtilitiesSection({
    required List<DashboardModuleViewModel> modules,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: '实用工具',
          icon: CupertinoIcons.wrench_fill,
          accent: _primary,
        ),
        const SizedBox(height: 8),
        _glassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < modules.length; index++)
                _utilityRow(
                  module: modules[index],
                  showDivider: index < modules.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _utilityRow({
    required DashboardModuleViewModel module,
    required bool showDivider,
  }) {
    final title = _utilityTitle(module.title);
    final meta = module.primaryText.trim();
    final subtitle = module.secondaryText.trim();

    return Semantics(
      button: true,
      label: meta.isEmpty ? title : '$title，$meta',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              controller.handleRouteTap(module.route, title: module.title),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Container(
              decoration: BoxDecoration(
                border: showDivider
                    ? Border(
                        bottom: BorderSide(color: _outlineSoft, width: 0.5),
                      )
                    : null,
              ),
              padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: module.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(module.icon, size: 19, color: module.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      meta,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: _textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return AppGlassCard(
      onTap: onTap,
      padding: padding,
      borderRadius: 24,
      surfaceAlpha: _isDark ? 0.52 : 0.78,
      borderAlpha: _isDark ? 0.10 : 0.28,
      child: child,
    );
  }

  List<String> _postersForRoute(String route) {
    return controller.subscribeInfo.value.posterItems
        .where((item) => item.route == route && item.poster.trim().isNotEmpty)
        .map((item) => controller.normalizePoster(item.poster))
        .where((poster) => poster.isNotEmpty)
        .take(3)
        .toList();
  }

  String _metricNumber(double value) {
    final units = _sizeParts(value);
    return units.$1;
  }

  String _metricUnit(double value) {
    final units = _sizeParts(value);
    return '${units.$2}/s';
  }

  (String, String) _sizeParts(double value) {
    final units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = value;
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final amount = size >= 100
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return (amount, units[unitIndex]);
  }

  String _shortSize(double value) {
    final parts = _sizeParts(value);
    return '${parts.$1} ${parts.$2}';
  }

  String _utilityTitle(String title) {
    if (title == '媒体整理') return '媒体整理';
    if (title == '文件管理') return '文件管理';
    if (title == '工作流') return '工作流';
    if (title == '插件') return '插件';
    if (title == '用户管理') return '用户管理';
    return title;
  }

  Color _softUtilityAccent(Color accent) {
    if (_isDark) return accent;
    return Color.lerp(_surface, accent, 0.11) ?? accent.withValues(alpha: 0.11);
  }

  static String _shortDate(String date) {
    if (date.length >= 10) {
      return date.substring(5, 10);
    }
    return date;
  }
}
