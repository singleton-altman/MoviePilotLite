import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:moviepilot_mobile/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:moviepilot_mobile/modules/dashboard/pages/dashboard_page.dart';
import 'package:moviepilot_mobile/modules/discover/controllers/discover_controller.dart';
import 'package:moviepilot_mobile/modules/discover/pages/discover_page.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/modules/multifunction/pages/multifunction_page.dart';
import 'package:moviepilot_mobile/modules/recommend/controllers/recommend_controller.dart';
import 'package:moviepilot_mobile/modules/recommend/pages/recommend_page.dart';
import 'package:moviepilot_mobile/modules/search/controllers/search_index_controller.dart';
import 'package:moviepilot_mobile/modules/search/pages/search_index_page.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/ios_widget_navigation_service.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
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
  late final List<ScrollController> _tabScrollControllers;
  int _selectedIndex = 0;
  bool _initialIndexApplied = false;
  bool _restoreSuppressed = false;
  ScrollController? _activeScrollController;

  // Language toggle for testing locale label updates
  final dashboardController = Get.put(DashboardController());
  // Dynamic labels based on language
  List<String> get _labels => ['仪表盘', '推荐', '探索', '更多', '搜索'];

  @override
  void initState() {
    super.initState();
    _tabScrollControllers = List.generate(
      kIndexMaxTab + 1,
      (_) => ScrollController(),
    );
    _applyInitialIndex();
    if (!_initialIndexApplied) {
      _restoreSelectedIndex();
    }
    Get.put(RecommendController());
    Get.put(DiscoverController());
    Get.put(MultifunctionController());
    Get.put(SearchIndexController(), permanent: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widgetNavigationService.navigateToPendingRoute();
    });
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
      final clamped = raw.clamp(0, kIndexMaxTab);
      _selectedIndex = clamped;
      _initialIndexApplied = true;
      return;
    }
    final args = Get.arguments;
    if (args is Map && args['initialIndex'] is int) {
      final argRaw = args['initialIndex'] as int;
      final clamped = argRaw.clamp(0, kIndexMaxTab);
      _selectedIndex = clamped;
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

  Widget _buildTabItem({
    required int index,
    required IconData iconOutlined,
    required IconData iconFilled,
    required String label,
  }) {
    final selected = _selectedIndex == index;
    final primary = context.primaryColor;
    final fg = selected ? primary : context.textPrimaryColor;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
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
          },
          borderRadius: BorderRadius.circular(999),
          splashColor: primary.withValues(alpha: 0.12),
          highlightColor: primary.withValues(alpha: 0.06),
          child: Ink(
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? iconFilled : iconOutlined,
                    size: 22,
                    color: fg,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1,
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarChild() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          _buildTabItem(
            index: 0,
            iconOutlined: Icons.home_outlined,
            iconFilled: Icons.home_rounded,
            label: _labels[0],
          ),
          _buildTabItem(
            index: 1,
            iconOutlined: Icons.movie_outlined,
            iconFilled: Icons.movie_rounded,
            label: _labels[1],
          ),
          _buildTabItem(
            index: 2,
            iconOutlined: Icons.explore_outlined,
            iconFilled: Icons.explore_rounded,
            label: _labels[2],
          ),
          _buildTabItem(
            index: 3,
            iconOutlined: Icons.grid_view_outlined,
            iconFilled: Icons.grid_view_rounded,
            label: _labels[3],
          ),
          _buildTabItem(
            index: 4,
            iconOutlined: Icons.search_rounded,
            iconFilled: Icons.search_rounded,
            label: _labels[4],
          ),
        ],
      ),
    );
  }

  // Dedicated page for each tab
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barFill = isDark ? scheme.surfaceContainerHigh : Colors.white;
    final outline = scheme.outline.withValues(alpha: 0.28);
    final w = MediaQuery.sizeOf(context).width - 32;
    return BottomBar(
      fit: StackFit.expand,
      clip: Clip.none,
      showIcon: false,
      hideOnScroll: false,
      scrollDeltaThreshold: 8,
      start: 2,
      end: 0,
      offset: 12,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: w,
      borderRadius: BorderRadius.circular(22),
      barColor: Colors.transparent,
      barDecoration: BoxDecoration(
        color: barFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: outline, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      barAlignment: Alignment.bottomCenter,
      respectSafeArea: true,
      child: _buildBottomBarChild(),
      body: (context, controller) {
        _activeScrollController = _tabScrollControllers[coercedIndex];
        final i = coercedIndex;
        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: i,
            children: [
              DashboardPage(scrollController: _tabScrollControllers[0]),
              RecommendPage(scrollController: _tabScrollControllers[1]),
              DiscoverPage(scrollController: _tabScrollControllers[2]),
              MultifunctionPage(scrollController: _tabScrollControllers[3]),
              SearchIndexPage(scrollController: _tabScrollControllers[4]),
            ],
          ),
        );
      },
    );
  }
}
