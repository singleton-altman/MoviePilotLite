import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

class MultifunctionPage extends GetView<MultifunctionController> {
  const MultifunctionPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static bool get _isDark => Get.isDarkMode;
  static Color get _background =>
      _isDark ? const Color(0xFF111827) : const Color(0xFFF4F7FB);
  static Color get _surface =>
      _isDark ? const Color(0xE60B1220) : const Color(0xF7FFFFFF);
  static Color get _surfaceHighest =>
      _isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  static Color get _outlineSoft =>
      _isDark ? const Color(0x14FFFFFF) : const Color(0x1F0F172A);
  static Color get _textPrimary =>
      _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get _textSecondary =>
      _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
  static Color get _textMuted =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get _primary =>
      _isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
  static Color get _primaryStrong =>
      _isDark ? const Color(0xFF3B82F6) : const Color(0xFF1D4ED8);
  static Color get _secondary =>
      _isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7C3AED);
  static Color get _secondaryStrong =>
      _isDark ? const Color(0xFFA855F7) : const Color(0xFF6D28D9);
  static Color get _error =>
      _isDark ? const Color(0xFFFFB4AB) : const Color(0xFFB42318);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: _background,
      extendBodyBehindAppBar: true,
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
          '/site',
          '/downloader',
          '/subscribe-calendar',
        };
        final utilityModules = modules
            .where((module) => !hiddenRoutes.contains(module.route))
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth;
            final horizontalPadding = pageWidth >= 720 ? 24.0 : 20.0;
            final contentMaxWidth = pageWidth >= 1100 ? 1024.0 : 920.0;
            final topPadding = MediaQuery.paddingOf(context).top + 4;

            return Stack(
              children: [
                const Positioned.fill(child: _PageBackdrop()),
                Center(
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
                            ),
                            const SizedBox(height: 16),
                            _buildReleasesSection(
                              pageWidth: pageWidth,
                              segment: calendarSegment,
                              items: calendarItems,
                              module: modulesByRoute['/subscribe-calendar'],
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (modulesByRoute['/site'] != null) ...[
                            _buildSitesSection(modulesByRoute['/site']!),
                            const SizedBox(height: 16),
                          ],
                          if (modulesByRoute['/downloader'] != null) ...[
                            _buildDownloaderSection(
                              pageWidth: pageWidth,
                              module: modulesByRoute['/downloader']!,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (utilityModules.isNotEmpty)
                            _buildUtilitiesSection(
                              pageWidth: pageWidth,
                              modules: utilityModules,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      titleSpacing: 0,
      leading: Builder(
        builder: (buttonContext) => CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: Icon(
            CupertinoIcons.square_grid_2x2_fill,
            size: 18,
            color: _textPrimary,
          ),
        ),
      ),
      title: Text(
        'More',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _textPrimary,
        ),
      ),
      centerTitle: false,
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Get.toNamed('/settings'),
          child: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection({
    required double pageWidth,
    DashboardModuleViewModel? movieModule,
    DashboardModuleViewModel? tvModule,
  }) {
    final info = controller.subscribeInfo.value;
    final moviePosters = _postersForRoute('/subscribe-movie');
    final tvPosters = _postersForRoute('/subscribe-tv');
    final useColumns = pageWidth >= 700;

    final movieCard = _subscriptionCategoryCard(
      title: '电影订阅',
      count: info.movieCount,
      accent: _primaryStrong,
      posters: moviePosters,
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
      onTap: tvModule == null
          ? null
          : () => controller.handleRouteTap(
              tvModule.route,
              title: tvModule.title,
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '订阅',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (!controller.subscribeDataReady.value)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 14, color: _textMuted),
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
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (useColumns)
          Row(
            children: [
              Expanded(child: movieCard),
              const SizedBox(width: 12),
              Expanded(child: tvCard),
            ],
          )
        else
          Column(children: [movieCard, const SizedBox(height: 12), tvCard]),
      ],
    );
  }

  Widget _subscriptionCategoryCard({
    required String title,
    required int count,
    required Color accent,
    required List<String> posters,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: onTap != null,
      label: '$title，共 $count 部',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 132,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _outlineSoft, width: 0.5),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(13),
                  ),
                  child: SizedBox(
                    width: 108,
                    height: double.infinity,
                    child: _buildSubscriptionPosterCollage(
                      title: title,
                      accent: accent,
                      posters: posters,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$count 部',
                          style: TextStyle(
                            color: accent,
                            fontSize: 26,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              '查看订阅',
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                              color: accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionPosterCollage({
    required String title,
    required Color accent,
    required List<String> posters,
  }) {
    if (posters.isEmpty) {
      return ColoredBox(
        color: _surfaceHighest,
        child: Icon(
          title.startsWith('电影')
              ? Icons.movie_filter_rounded
              : Icons.live_tv_rounded,
          color: accent,
          size: 30,
        ),
      );
    }

    final visiblePosters = posters.take(3).toList();
    final leftOffsets = switch (visiblePosters.length) {
      1 => const [19.0],
      2 => const [10.0, 30.0],
      _ => const [5.0, 21.0, 37.0],
    };
    final topOffsets = switch (visiblePosters.length) {
      1 => const [13.0],
      2 => const [17.0, 11.0],
      _ => const [20.0, 15.0, 10.0],
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: _isDark ? 0.08 : 0.055),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: _isDark ? 0.13 : 0.09),
            _surfaceHighest.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Stack(
        children: [
          for (var index = 0; index < visiblePosters.length; index++)
            Positioned(
              left: leftOffsets[index],
              top: topOffsets[index],
              child: Container(
                width: 66,
                height: 102,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: _isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.92),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isDark ? 0.26 : 0.14,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedImage(
                  imageUrl: visiblePosters[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
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
        Row(
          children: [
            Expanded(
              child: Text(
                '上映日历',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            _segmentedControl(
              value: segment,
              onChanged: (next) {
                controller.setCalendarSegment(next);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                            Icons.live_tv_rounded,
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
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
                                child: Text(
                                  seasonEpisodeTag,
                                  style: TextStyle(
                                    color: _primary,
                                    fontSize: 10,
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
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Text(
                            chipText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
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
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            '暂无上映日历数据',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '站点',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
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
                valueColor: _primary,
                showDivider: true,
              ),
              _siteRow(
                icon: Icons.south_east_rounded,
                iconColor: _secondary,
                title: '累计下载',
                subtitle: '站点用户数据汇总流量',
                value: _shortSize(info.totalDownload),
                valueColor: _secondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: iconColor == _error ? _error : _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 28,
                height: 2,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloaderSection({
    required double pageWidth,
    required DashboardModuleViewModel module,
  }) {
    final info = controller.downloaderInfo.value;
    final isCompact = pageWidth < 360;

    return _glassCard(
      onTap: () => controller.handleRouteTap(module.route, title: module.title),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_download_rounded, color: _primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '下载器',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _primary.withValues(alpha: 0.20)),
                ),
                child: Text(
                  '${info.clients.length} 个活跃',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _downloaderMetricCard(
                  icon: Icons.arrow_downward_rounded,
                  label: '下载',
                  value: _metricNumber(info.totalDownloadSpeed),
                  unit: _metricUnit(info.totalDownloadSpeed),
                  accent: _primary,
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: _downloaderMetricCard(
                  icon: Icons.arrow_upward_rounded,
                  label: '上传',
                  value: _metricNumber(info.totalUploadSpeed),
                  unit: _metricUnit(info.totalUploadSpeed),
                  accent: _secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _downloaderMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceHighest.withValues(alpha: _isDark ? 0.34 : 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 4,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Container(
            width: 22,
            height: 2,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilitiesSection({
    required double pageWidth,
    required List<DashboardModuleViewModel> modules,
  }) {
    final crossAxisCount = pageWidth >= 960
        ? 4
        : pageWidth >= 640
        ? 3
        : 2;
    final childAspectRatio = pageWidth >= 640 ? 1.65 : 1.35;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '实用工具',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: modules.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (_, index) => _utilityCard(modules[index], index: index),
        ),
      ],
    );
  }

  Widget _utilityCard(DashboardModuleViewModel module, {required int index}) {
    final title = _utilityTitle(module.title);
    final subtitle = module.primaryText.trim();

    return Semantics(
      button: true,
      label: '$title，$subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              controller.handleRouteTap(module.route, title: module.title),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: module.accent.withValues(alpha: 0.18),
                width: 0.8,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  module.accent.withValues(alpha: index.isEven ? 0.11 : 0.08),
                  _surface,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: module.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(module.icon, size: 21, color: module.accent),
                    ),
                    const Spacer(),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _surfaceHighest.withValues(
                          alpha: _isDark ? 0.36 : 0.82,
                        ),
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
                  title,
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
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _outlineSoft, width: 0.5),
          ),
          child: child,
        ),
      ),
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

  static String _shortDate(String date) {
    if (date.length >= 10) {
      return date.substring(5, 10);
    }
    return date;
  }
}

class _PageBackdrop extends StatelessWidget {
  const _PageBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? const [Color(0xFF111827), Color(0xFF0F172A), Color(0xFF0B1220)]
        : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFEFF4FA)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: [0, 0.56, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            left: -90,
            child: _SoftGlow(
              size: 300,
              color: const Color(
                0xFF3B82F6,
              ).withValues(alpha: isDark ? 0.14 : 0.09),
            ),
          ),
          Positioned(
            top: 220,
            right: -140,
            child: _SoftGlow(
              size: 360,
              color: const Color(
                0xFFA855F7,
              ).withValues(alpha: isDark ? 0.10 : 0.06),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -130,
            child: _SoftGlow(
              size: 340,
              color: const Color(
                0xFF2563EB,
              ).withValues(alpha: isDark ? 0.07 : 0.045),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
