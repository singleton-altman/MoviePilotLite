import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:get/get.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/pages/dashboard_page.dart';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/discover/pages/discover_page.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/modules/multifunction/pages/multifunction_page.dart';
import 'package:moviepilot_mobile/modules/plugin/controllers/plugin_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/pages/recommend_page.dart';
import 'package:moviepilot_mobile/modules/search/controllers/search_index_controller.dart';
import 'package:moviepilot_mobile/modules/search/pages/search_index_page.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/ios_widget_navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moviepilot_mobile/utils/prefs_keys.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

class Index extends StatefulWidget {
  const Index({super.key, this.initialIndex});

  final int? initialIndex;

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final _appService = Get.find<AppService>();
  final _widgetNavigationService = Get.find<IosWidgetNavigationService>();
  // Stable key so the tab body's element (and its page states/contexts) is
  // reparented rather than torn down when the Scaffold body swaps between the
  // floating bottom bar and the bare stack (e.g. when hiding the nav bar).
  final _tabBodyKey = GlobalKey();
  late final List<ScrollController> _tabScrollControllers;
  int _selectedIndex = 0;
  bool _initialIndexApplied = false;
  bool _restoreSuppressed = false;
  ScrollController? _activeScrollController;
  late final Future<bool> _supportsNativeGlassNavBar;

  /// 已经构建过的 Tab 下标：IndexedStack 会同时 build 与 layout 所有子页，
  /// 只把访问过的 Tab 真正放进去，其余用占位，避免启动时五个页面一起拉数据。
  final Set<int> _builtTabs = {};

  List<String> get _labels => ['仪表盘', '推荐', '探索', '更多', '搜索'];
  List<IconData> get _icons => [
    Icons.home_outlined,
    Icons.movie_outlined,
    Icons.explore_outlined,
    Icons.grid_view_outlined,
    Icons.search_rounded,
  ];
  List<IconData> get _selectedIcons => [
    Icons.home_rounded,
    Icons.movie_rounded,
    Icons.explore_rounded,
    Icons.grid_view_rounded,
    Icons.search_rounded,
  ];

  List<NativeGlassNavBarItem> get _nativeTabs => [
    NativeGlassNavBarItem(label: _labels[0], symbol: 'house.fill'),
    NativeGlassNavBarItem(label: _labels[1], symbol: 'film.fill'),
    NativeGlassNavBarItem(label: _labels[2], symbol: 'safari.fill'),
    NativeGlassNavBarItem(label: _labels[3], symbol: 'square.grid.2x2.fill'),
    NativeGlassNavBarItem(label: _labels[4], symbol: 'magnifyingglass'),
  ];

  @override
  void initState() {
    super.initState();
    _supportsNativeGlassNavBar = LiquidGlassHelper.isLiquidGlassSupported();
    _tabScrollControllers = List.generate(
      kIndexMaxTab + 1,
      (_) => ScrollController(),
    );
    _applyInitialIndex();
    if (!_initialIndexApplied) {
      _restoreSelectedIndex();
    }
    // 控制器按需创建：首次构建对应 Tab 页（或别处首次 find）时才初始化，
    // 它们的 onInit/onReady 都会立刻发请求，不能在启动时一起跑。
    Get.lazyPut(() => DashboardController(), fenix: true);
    Get.lazyPut(() => RecommendController(), fenix: true);
    Get.lazyPut(() => DiscoverController(), fenix: true);
    Get.lazyPut(() => MultifunctionController(), fenix: true);
    Get.lazyPut(() => SearchIndexController(), fenix: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widgetNavigationService.navigateToPendingRoute();
      _runPluginAutoBackupOnLaunch();
    });
  }

  Future<void> _runPluginAutoBackupOnLaunch() async {
    if (!_appService.hasLoggedInSession) return;
    if (!_appService.canManage) return;
    if (!Get.isRegistered<PluginController>()) {
      Get.put(PluginController(), permanent: true);
    }
    // 稍延后，等 session/scope 与网络就绪
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    await Get.find<PluginController>().runDailyAutoBackupIfNeeded();
  }

  @override
  void dispose() {
    for (final controller in _tabScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applyInitialIndex() {
    final raw = widget.initialIndex;
    if (raw != null) {
      _selectedIndex = raw.clamp(0, kIndexMaxTab);
      _initialIndexApplied = true;
      return;
    }
    final args = Get.arguments;
    if (args is Map && args['initialIndex'] is int) {
      _selectedIndex = (args['initialIndex'] as int).clamp(0, kIndexMaxTab);
      _initialIndexApplied = true;
    }
  }

  Future<void> _restoreSelectedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(kIndexLastTabKey);
      if (stored == null) return;
      if (_restoreSuppressed) return;
      final clamped = _coerceAllowedTab(stored.clamp(0, kIndexMaxTab));
      if (clamped == _selectedIndex) return;
      if (!mounted) return;
      setState(() {
        _selectedIndex = clamped;
      });
    } catch (_) {
      // ignore restore failures
    }
  }

  Future<void> _persistSelectedIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kIndexLastTabKey, index);
    } catch (_) {
      // ignore persist failures
    }
  }

  void _stopCurrentScrollMomentum() {
    final controller = _activeScrollController;
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        controller.offset,
        duration: Duration.zero,
        curve: Curves.linear,
      );
    }
  }

  bool _canOpenTab(int index) {
    switch (index) {
      case 1:
      case 2:
        return _appService.canDiscovery;
      case 4:
        return _appService.canBrowseMediaCatalog;
      default:
        return true;
    }
  }

  int _coerceAllowedTab(int index) {
    if (_canOpenTab(index)) return index;
    for (final candidate in const [0, 3, 1, 2, 4]) {
      if (_canOpenTab(candidate)) return candidate;
    }
    return 0;
  }

  void _showTabPermissionDenied(int index) {
    switch (index) {
      case 1:
      case 2:
        ToastUtil.info('当前帐号无发现内容权限');
        return;
      case 4:
        ToastUtil.info('请先登录');
        return;
      default:
        return;
    }
  }

  void _handleTabTap(int index) {
    _restoreSuppressed = true;
    _stopCurrentScrollMomentum();
    if (!_canOpenTab(index)) {
      _showTabPermissionDenied(index);
      return;
    }
    if (index == kIndexMaxTab && _selectedIndex == kIndexMaxTab) {
      if (Get.isRegistered<SearchIndexController>()) {
        Get.find<SearchIndexController>().requestSearchBarFocus();
      }
      return;
    }
    setState(() => _selectedIndex = index);
    _persistSelectedIndex(index);
    if (index == 3 && Get.isRegistered<MultifunctionController>()) {
      Get.find<MultifunctionController>().refreshDashboard();
    }
  }

  void _onTabTap(int index) {
    final before = _selectedIndex;
    _handleTabTap(index);
    if (before == _selectedIndex) {
      setState(() {});
    }
  }

  Widget _buildTabBody(int coercedIndex) {
    _activeScrollController = _tabScrollControllers[coercedIndex];
    _builtTabs.add(coercedIndex);
    return IndexedStack(
      key: _tabBodyKey,
      index: coercedIndex,
      children: List.generate(
        kIndexMaxTab + 1,
        (index) => _builtTabs.contains(index)
            ? _buildTabPage(index)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTabPage(int index) {
    final scrollController = _tabScrollControllers[index];
    switch (index) {
      case 0:
        return DashboardPage(scrollController: scrollController);
      case 1:
        return RecommendPage(scrollController: scrollController);
      case 2:
        return DiscoverPage(scrollController: scrollController);
      case 3:
        return MultifunctionPage(scrollController: scrollController);
      default:
        return SearchIndexPage(scrollController: scrollController);
    }
  }

  Widget _buildFloatingBottomBar(Widget body) {
    final colorScheme = Theme.of(context).colorScheme;
    final barWidth = (MediaQuery.sizeOf(context).width - 32).clamp(0.0, 460.0);

    return BottomBar(
      body: body,
      showIcon: false,
      layout: BottomBarLayout(
        width: barWidth,
        offset: 16,
        borderRadius: BorderRadius.circular(28),
        clip: Clip.none,
        fit: StackFit.expand,
      ),
      scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false),
      theme: BottomBarThemeData(
        barDecoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            for (var index = 0; index <= kIndexMaxTab; index++)
              Expanded(
                child: _FloatingTabItem(
                  label: _labels[index],
                  icon: _icons[index],
                  selectedIcon: _selectedIcons[index],
                  selected: _selectedIndex == index,
                  onTap: () => _onTabTap(index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coercedIndex = _coerceAllowedTab(_selectedIndex);
    if (coercedIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedIndex = coercedIndex;
        });
        _persistSelectedIndex(coercedIndex);
      });
    }

    return FutureBuilder<bool>(
      future: _supportsNativeGlassNavBar,
      builder: (context, snapshot) {
        final tabBody = _buildTabBody(coercedIndex);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: tabBody,
          );
        }

        final useNativeGlass = snapshot.data == true;

        return Obx(() {
          final hideNav = _appService.hideBottomNavBar.value;
          return Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: useNativeGlass || hideNav
                ? tabBody
                : _buildFloatingBottomBar(tabBody),
            bottomNavigationBar: useNativeGlass && !hideNav
                ? NativeGlassNavBar(
                    tabs: _nativeTabs,
                    currentIndex: _selectedIndex,
                    tintColor: Theme.of(context).primaryColor,
                    onTap: _onTabTap,
                  )
                : null,
          );
        });
      },
    );
  }
}

class _FloatingTabItem extends StatelessWidget {
  const _FloatingTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.72);

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 22),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
