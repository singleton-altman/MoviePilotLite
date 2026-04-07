import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_tabbar_minimize/liquid_tabbar_minimize.dart';
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
import 'package:moviepilot_mobile/modules/search_result/controllers/search_result_controller.dart';
import 'package:moviepilot_mobile/modules/search_result/pages/search_result_page.dart';
import 'package:moviepilot_mobile/services/ios_widget_navigation_service.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moviepilot_mobile/utils/prefs_keys.dart';

class Index extends StatefulWidget {
  const Index({super.key, this.initialIndex});

  final int? initialIndex;

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  final _widgetNavigationService = Get.find<IosWidgetNavigationService>();
  int _selectedIndex = 0;
  double _lastScrollOffset = 0;
  bool _initialIndexApplied = false;

  // Language toggle for testing locale label updates
  final dashboardController = Get.put(DashboardController());
  // Dynamic labels based on language
  List<String> get _labels => ['仪表盘', '推荐', '探索', '更多', '搜索'];

  // Separate ScrollController for each page
  late final ScrollController _homeScrollController;
  late final ScrollController _recommendScrollController;
  late final ScrollController _discoverScrollController;
  late final ScrollController _multifunctionScrollController;
  late final ScrollController _searchResultScrollController;

  @override
  void initState() {
    super.initState();
    _applyInitialIndex();
    if (!_initialIndexApplied) {
      _restoreSelectedIndex();
    }
    Get.put(RecommendController());
    Get.put(DiscoverController());
    Get.put(MultifunctionController());
    Get.put(SearchIndexController());
    _homeScrollController = ScrollController()
      ..addListener(() => _onScroll(_homeScrollController));
    _recommendScrollController = ScrollController()
      ..addListener(() => _onScroll(_recommendScrollController));
    _discoverScrollController = ScrollController()
      ..addListener(() => _onScroll(_discoverScrollController));
    _multifunctionScrollController = ScrollController()
      ..addListener(() => _onScroll(_multifunctionScrollController));
    _searchResultScrollController = ScrollController()
      ..addListener(() => _onScroll(_searchResultScrollController));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _widgetNavigationService.navigateToPendingRoute();
    });
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _recommendScrollController.dispose();
    _discoverScrollController.dispose();
    _multifunctionScrollController.dispose();
    _searchResultScrollController.dispose();
    super.dispose();
  }

  void _onScroll(ScrollController controller) {
    final offset = controller.offset;
    final delta = offset - _lastScrollOffset;

    _handleScroll(offset, delta);

    _lastScrollOffset = offset;
  }

  void _handleScroll(double offset, double delta) {
    // LiquidBottomNavigationBar.handleScroll(offset, delta);
  }

  void _applyInitialIndex() {
    final raw = widget.initialIndex;
    if (raw != null) {
      final clamped = raw.clamp(0, kIndexMaxTab);
      _selectedIndex = clamped is int ? clamped : clamped.toInt();
      _lastScrollOffset = 0;
      _initialIndexApplied = true;
      return;
    }
    final args = Get.arguments;
    if (args is Map && args['initialIndex'] is int) {
      final argRaw = args['initialIndex'] as int;
      final clamped = argRaw.clamp(0, kIndexMaxTab);
      _selectedIndex = clamped is int ? clamped : clamped.toInt();
      _lastScrollOffset = 0;
      _initialIndexApplied = true;
    }
  }

  Future<void> _restoreSelectedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(kIndexLastTabKey);
      if (stored == null) return;
      final clamped = stored.clamp(0, kIndexMaxTab);
      if (clamped == _selectedIndex) return;
      if (!mounted) return;
      setState(() {
        _selectedIndex = clamped is int ? clamped : clamped.toInt();
        _lastScrollOffset = 0;
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
    ScrollController? controller;
    switch (_selectedIndex) {
      case 0:
        controller = _homeScrollController;
      case 1:
        controller = _recommendScrollController;
      case 2:
        controller = _discoverScrollController;
      case 3:
        controller = _multifunctionScrollController;
      case 4:
        controller = _searchResultScrollController;
    }
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        controller.offset,
        duration: Duration.zero,
        curve: Curves.linear,
      );
    }
  }

  // Dedicated page for each tab
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardPage(),
          RecommendPage(scrollController: _recommendScrollController),
          DiscoverPage(scrollController: _discoverScrollController),
          MultifunctionPage(scrollController: _multifunctionScrollController),
          const SearchIndexPage(),
        ],
      ),
      bottomNavigationBar: LiquidBottomNavigationBar(
        selectedItemColor: context.primaryColor,
        unselectedItemColor: context.textPrimaryColor,
        enableMinimize: true,
        // action 按钮不在 items 中，currentIndex 需限定在 0..3，否则 collapsed 时会越界
        currentIndex: _selectedIndex.clamp(0, 3),
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _lastScrollOffset = 0;
          _persistSelectedIndex(index);
          debugPrint('Tab index: $index');
        },
        items: [
          LiquidTabItem(
            widget: const Icon(Icons.home_outlined),
            selectedWidget: const Icon(Icons.home),
            sfSymbol: 'house',
            selectedSfSymbol: 'house.fill',
            label: _labels[0],
          ),
          LiquidTabItem(
            widget: const Icon(Icons.movie_outlined),
            selectedWidget: const Icon(Icons.movie),
            sfSymbol: 'film',
            selectedSfSymbol: 'film.fill',
            label: _labels[1],
          ),
          LiquidTabItem(
            widget: const Icon(Icons.explore_outlined),
            selectedWidget: const Icon(Icons.explore),
            sfSymbol: 'safari',
            selectedSfSymbol: 'safari.fill',
            label: _labels[2],
          ),
          LiquidTabItem(
            widget: const Icon(Icons.grid_view_outlined),
            selectedWidget: const Icon(Icons.grid_view),
            sfSymbol: 'square.grid.2x2',
            selectedSfSymbol: 'square.grid.2x2.fill',
            label: _labels[3],
          ),
        ],
        showActionButton: true,
        actionButton: ActionButtonConfig(
          const Icon(Icons.search),
          'magnifyingglass',
        ),
        onActionTap: () {
          debugPrint('Search tapped!');
          _stopCurrentScrollMomentum();
          setState(() {
            _selectedIndex = 4;
            _lastScrollOffset = 0;
          });
          _persistSelectedIndex(4);
        },
        labelVisibility: LabelVisibility.always,
        height: 68,
        forceCustomBar: true,
        collapseStartOffset: 100,
        animationDuration: const Duration(milliseconds: 100),
      ),
    );
  }
}
