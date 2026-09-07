import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/page/downloader_shell_page.dart';
import 'package:moviepilot_mobile/utils/downloader_controller_adaptor.dart';
import 'package:altman_totp/page/totp_manage_page.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/index.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_service.dart';
import 'package:moviepilot_mobile/modules/search/controllers/app_setting_controller.dart';
import 'package:moviepilot_mobile/modules/search/controllers/media_search_list_controller.dart';
import 'package:moviepilot_mobile/modules/search/controllers/person_detail_controller.dart';
import 'package:moviepilot_mobile/modules/search/controllers/person_search_list_controller.dart';
import 'package:moviepilot_mobile/modules/search/controllers/search_controller.dart';
import 'package:moviepilot_mobile/modules/search/pages/app_theme_setting_page.dart';
import 'package:moviepilot_mobile/modules/search/pages/app_setting_page.dart';
import 'package:moviepilot_mobile/modules/search/pages/background_image_setting_page.dart';
import 'package:moviepilot_mobile/modules/search/pages/changelog_page.dart';
import 'package:moviepilot_mobile/modules/search/pages/media_search_list_page.dart';
import 'package:moviepilot_mobile/modules/search/pages/person_detail_page.dart';
import 'package:moviepilot_mobile/modules/search/pages/person_search_result_page.dart';
import 'package:moviepilot_mobile/modules/search/pages/search_media_result_page.dart';
import 'package:moviepilot_mobile/modules/search/services/app_update_service.dart';
import 'package:moviepilot_mobile/modules/subtitle/controllers/subtitle_search_controller.dart';
import 'package:moviepilot_mobile/modules/subtitle/pages/subtitle_search_result_page.dart';
import 'package:moviepilot_mobile/middlewares/route_permission_middleware.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';
import 'package:moviepilot_mobile/services/ios_widget_navigation_service.dart';
import 'package:moviepilot_mobile/services/jpush_service.dart';
import 'package:moviepilot_mobile/l10n/app_localizations.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/hive_service.dart';
import 'package:moviepilot_mobile/utils/image_cache_manager.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:moviepilot_mobile/utils/web_view_screen.dart';
import 'package:moviepilot_mobile/widgets/agent_floating_entry.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'bindings/app_binding.dart';
import 'modules/agent/controllers/agent_controller.dart';
import 'modules/agent/pages/agent_chat_page.dart';
import 'modules/agent/repositories/agent_repository.dart';
import 'modules/dashboard/controllers/dashboard_controller.dart';
import 'modules/dashboard/pages/dashboard_page.dart';
import 'modules/dashboard/pages/background_task_list_page.dart';
import 'modules/login/pages/login_page.dart';
import 'theme/app_theme.dart';
import 'theme/app_scaffold_background.dart';
import 'modules/profile/controllers/profile_controller.dart';
import 'modules/profile/pages/profile_page.dart';
import 'modules/network_test/controllers/network_test_controller.dart';
import 'modules/network_test/pages/network_test_page.dart';
import 'modules/system_health/controllers/system_health_controller.dart';
import 'modules/system_health/pages/system_health_page.dart';
import 'modules/cache/controllers/cache_controller.dart';
import 'modules/cache/pages/cache_page.dart';
import 'modules/server_log/controllers/server_log_controller.dart';
import 'modules/server_log/pages/server_log_page.dart';
import 'modules/system_message/controllers/system_message_controller.dart';
import 'modules/system_message/pages/system_message_page.dart';
import 'modules/media_detail/controllers/media_detail_controller.dart';
import 'modules/media_detail/pages/media_detail_page.dart';
import 'modules/recommend/controllers/recommend_category_list_controller.dart';
import 'modules/recommend/pages/recommend_category_list_page.dart';
import 'modules/search_result/controllers/search_result_controller.dart';
import 'modules/search_result/pages/search_result_page.dart';
import 'modules/subscribe/controllers/subscribe_controller.dart';
import 'modules/subscribe/controllers/subscribe_history_controller.dart';
import 'modules/subscribe/controllers/subscribe_popular_controller.dart';
import 'modules/subscribe/controllers/subscribe_share_controller.dart';
import 'modules/subscribe/controllers/subscribe_calendar_controller.dart';
import 'modules/subscribe/controllers/subscribe_share_statistics_controller.dart';
import 'modules/subscribe/pages/subscribe_calendar_page.dart';
import 'modules/subscribe/pages/subscribe_history_page.dart';
import 'modules/subscribe/pages/subscribe_page.dart';
import 'modules/subscribe/pages/subscribe_popular_page.dart';
import 'modules/subscribe/pages/subscribe_share_page.dart';
import 'modules/subscribe/pages/subscribe_share_statistics_page.dart';
import 'modules/subscribe/controllers/subscribe_edit_controller.dart';
import 'modules/subscribe/pages/subscribe_edit_page.dart';
import 'modules/media_organize/controllers/media_organize_controller.dart';
import 'modules/media_organize/pages/media_organize_page.dart';
import 'modules/download/controllers/download_controller.dart';
import 'modules/downloader/controllers/downloader_controller.dart';
import 'modules/downloader/controllers/downloader_config_controller.dart';
import 'modules/downloader/pages/downloader_config_list_page.dart';
import 'modules/downloader/pages/downloader_config_page.dart';
import 'modules/downloader/pages/downloader_page.dart';
import 'modules/mediaserver/controllers/mediaserver_controller.dart';
import 'modules/mediaserver/pages/mediaserver_config_list_page.dart';
import 'modules/plugin/controllers/plugin_controller.dart';
import 'modules/plugin/controllers/plugin_list_controller.dart';
import 'modules/plugin/pages/plugin_page.dart';
import 'modules/plugin/pages/plugin_list_page.dart';
import 'modules/plugin/services/plugin_palette_cache.dart';
import 'modules/dynamic_form/adapters/plugin_form_adapter_registry.dart';
import 'modules/dynamic_form/adapters/brush_flow_form_controller.dart';
import 'modules/dynamic_form/adapters/p115_strm_helper_form_controller.dart';
import 'modules/dynamic_form/adapters/proxmox_ve_backup_form_controller.dart';
import 'modules/dynamic_form/adapters/subtitle_manual_upload_form_controller.dart';
import 'modules/dynamic_form/adapters/trash_clean_form_controller.dart';
import 'modules/dynamic_form/widgets/VueStyle/applitepush/app_lite_push_widgets.dart';
import 'modules/dynamic_form/widgets/VueStyle/brush_flow/brush_flow_widgets.dart';
import 'modules/dynamic_form/widgets/VueStyle/proxmox_ve/proxmox_ve_backup_widgets.dart';
import 'modules/dynamic_form/widgets/VueStyle/subtitle_manual_upload/subtitle_manual_upload_widgets.dart';
import 'modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'modules/dynamic_form/pages/dynamic_form_page.dart';
import 'modules/site/controllers/site_controller.dart';
import 'modules/site/controllers/site_detail_controller.dart';
import 'modules/site/controllers/site_resource_controller.dart';
import 'modules/site/controllers/site_edit_controller.dart';
import 'modules/site/pages/site_page.dart';
import 'modules/site/pages/site_detail_page.dart';
import 'modules/site/pages/site_resource_page.dart';
import 'modules/site/pages/site_edit_page.dart';
import 'modules/user_management/controllers/user_management_controller.dart';
import 'modules/user_management/pages/user_management_page.dart';
import 'modules/settings/controllers/settings_controller.dart';
import 'modules/settings/controllers/settings_sub_list_controller.dart';
import 'modules/settings/pages/settings_page.dart';
import 'modules/settings/pages/settings_sub_list_page.dart';
import 'modules/settings/pages/settings_detail_placeholder_page.dart';
import 'modules/settings/controllers/settings_advanced_detail_controller.dart';
import 'modules/settings/controllers/settings_organize_scrape_controller.dart';
import 'modules/settings/controllers/settings_site_sync_controller.dart';
import 'modules/settings/controllers/settings_site_options_controller.dart';
import 'modules/settings/controllers/settings_basic_controller.dart';
import 'modules/settings/controllers/settings_search_download_controller.dart';
import 'modules/settings/pages/settings_advanced_detail_page.dart';
import 'modules/settings/pages/settings_basic_page.dart';
import 'modules/settings/pages/settings_search_download_page.dart';
import 'modules/settings/pages/organize_scrape_page.dart';
import 'modules/settings/pages/site_sync_page.dart';
import 'modules/settings/pages/site_options_page.dart';
import 'modules/storage/controllers/storage_list_controller.dart';
import 'modules/storage/pages/storage_list_page.dart';
import 'modules/directory/controllers/directory_list_controller.dart';
import 'modules/directory/pages/directory_list_page.dart';
import 'modules/rule/controllers/rule_controller.dart';
import 'modules/rule/pages/custom_rule_page.dart';
import 'modules/rule/pages/priority_rule_page.dart';
import 'modules/rule/pages/download_rule_page.dart';
import 'modules/workflow/controllers/workflow_controller.dart';
import 'modules/workflow/pages/workflow_page.dart';
import 'modules/file_manager/controllers/file_manager_browser_controller.dart';
import 'modules/file_manager/pages/file_manager_browser_page.dart';

List<GetMiddleware> permissionGuards([String? permissionRoute]) => [
  RoutePermissionMiddleware(permissionRoute: permissionRoute),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppImageCacheManager.configureGlobalDecodedCache();
  try {
    Get.put(AppLog());
    await Get.putAsync(() => HiveService().init(), permanent: true);
    await Get.putAsync(
      () => IosWidgetNavigationService().init(),
      permanent: true,
    );
    await Get.putAsync(() => JPushService().init(), permanent: true);
    Get.put(IosSharedSessionService(), permanent: true);
    Get.put(AppService());
    Get.put(ApiClient());
    final updateService = Get.put(AppUpdateService(), permanent: true);
    await updateService.cleanupExpiredApkCache(maxAge: Duration.zero);
    Get.put(MediaDetailService());
    Get.put(ImageUtil());
    // 注册 vue 模式插件适配器
    PluginFormAdapterRegistry.register(
      'TrashClean',
      ({required formMode}) => TrashCleanFormController(formMode: formMode),
    );
    PluginFormAdapterRegistry.register(
      'P115StrmHelper',
      ({required formMode}) => P115StrmHelperFormController(formMode: formMode),
    );
    PluginFormAdapterRegistry.register(
      'ProxmoxVEBackup',
      ({required formMode}) =>
          ProxmoxVEBackupFormController(formMode: formMode),
    );
    PluginFormAdapterRegistry.register(
      'SubtitleManualUpload',
      ({required formMode}) =>
          SubtitleManualUploadFormController(formMode: formMode),
    );
    PluginFormAdapterRegistry.register(
      'BrushFlow',
      ({required formMode}) => BrushFlowFormController(formMode: formMode),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
  }
  registerProxmoxVeBackupRenderer();
  registerAppLitePushRenderer();
  registerSubtitleManualUploadRenderer();
  registerBrushFlowRenderer();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    final talker = Get.find<AppLog>();
    final appService = Get.find<AppService>();
    final routeObserver = TalkerRouteObserver(talker.talker);
    return Obx(() {
      final primary = appService.primaryColor.value;
      return GetMaterialApp(
        title: 'MoviePilot',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        themeMode: appService.themeMode.value,
        theme: AppTheme.lightThemeWithPrimary(primary),
        darkTheme: AppTheme.darkThemeWithPrimary(primary),
        initialBinding: AppBinding(),
        initialRoute: '/login',
        navigatorObservers: [
          // 添加Talker路由观察器
          routeObserver,
          AgentFloatingRouteObserver(),
        ],
        getPages: [
          GetPage(
            name: '/main',
            page: () {
              final args = Get.arguments;
              int? initialIndex;
              if (args is Map && args['initialIndex'] is int) {
                initialIndex = args['initialIndex'] as int;
              }
              return Index(initialIndex: initialIndex);
            },
          ),
          GetPage(name: '/login', page: () => const LoginPage()),
          GetPage(name: '/totp-manage', page: () => const TotpManagePage()),
          GetPage(
            name: '/dashboard',
            page: () => const DashboardPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => DashboardController());
            }),
          ),
          GetPage(
            name: '/agent',
            page: () => const AgentChatPage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<AgentRepository>()) {
                Get.lazyPut(() => AgentRepository(), fenix: true);
              }
              if (!Get.isRegistered<AgentController>()) {
                Get.put(AgentController(), permanent: true);
              }
            }),
          ),
          GetPage(
            name: '/background-task-list',
            page: () => const BackgroundTaskListPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => DashboardController());
            }),
            middlewares: permissionGuards('/background-task-list'),
          ),
          GetPage(
            name: '/profile',
            page: () => const ProfilePage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => ProfileController());
            }),
          ),
          GetPage(
            name: '/server-log',
            page: () => const ServerLogPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => ServerLogController());
            }),
          ),
          GetPage(
            name: '/network-test',
            page: () => const NetworkTestPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => NetworkTestController());
            }),
          ),
          GetPage(
            name: '/system-health',
            page: () => const SystemHealthPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SystemHealthController());
            }),
          ),
          GetPage(
            name: '/system-message',
            page: () => const SystemMessagePage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SystemMessageController());
            }),
            middlewares: permissionGuards('/system-message'),
          ),
          GetPage(
            name: '/cache',
            page: () => const CachePage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => CacheController());
            }),
          ),
          GetPage(
            name: '/search-result',
            page: () => const SearchResultPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SearchResultController());
            }),
            middlewares: permissionGuards('/search-result'),
          ),
          GetPage(
            name: '/search-media-result',
            page: () => const SearchMediaResultPage(),
            binding: BindingsBuilder(() {
              final args = Get.parameters;
              Get.lazyPut(() {
                final c = SearchMediaController();
                c.searchType = switch (args['type'] ?? 'media') {
                  'media' => SearchType.media,
                  'title' => SearchType.title,
                  _ => SearchType.media,
                };
                c.mediaSearchKey = args['mediaSearchKey'] ?? '';
                c.area = args['area'] ?? 'title';
                c.sites = (args['sites'] ?? '')
                    .split(',')
                    .where((s) => s.trim().isNotEmpty)
                    .map(int.tryParse)
                    .whereType<int>()
                    .toList();
                c.year = args['year'] ?? '';
                c.season = args['season'];
                c.mtype = args['mtype'] ?? 'movie';
                c.searchText.value = args['title'] ?? '';
                c.prefillTitle = args['title'];
                c.prefillBackdrop = args['backdrop'] ?? args['backdrop_path'];
                return c;
              });
            }),
            middlewares: permissionGuards('/search-media-result'),
          ),
          GetPage(
            name: '/subtitle-search-result',
            page: () => const SubtitleSearchResultPage(),
            binding: BindingsBuilder(() {
              final args = Get.parameters;
              if (Get.isRegistered<SubtitleSearchController>()) {
                Get.delete<SubtitleSearchController>();
              }
              Get.put(
                () {
                  final c = SubtitleSearchController();
                  c.mediaSearchKey = args['mediaSearchKey'] ?? '';
                  c.sites = (args['sites'] ?? '')
                      .split(',')
                      .where((s) => s.trim().isNotEmpty)
                      .map(int.tryParse)
                      .whereType<int>()
                      .toList();
                  c.year = args['year'] ?? '';
                  c.season = args['season'];
                  c.mtype = args['mtype'] ?? '电影';
                  c.title = args['title'] ?? '';
                  c.prefillTitle = args['title'];
                  c.prefillBackdrop =
                      args['backdrop'] ?? args['backdrop_path'];
                  return c;
                }(),
              );
            }),
            middlewares: permissionGuards('/subtitle-search-result'),
          ),
          GetPage(
            name: '/media-search-list',
            page: () => const MediaSearchListPage(),
            binding: BindingsBuilder(() {
              final args = Get.arguments;
              final params = Get.parameters;
              final paramKw = params['keyword']?.trim();
              String? keyword;
              if (paramKw != null && paramKw.isNotEmpty) {
                keyword = paramKw;
              } else if (args is Map && args['keyword'] != null) {
                keyword = args['keyword']?.toString();
              }
              var type = params['type'];
              if ((type == null || type.isEmpty) &&
                  args is Map &&
                  args['type'] != null) {
                type = args['type']?.toString();
              }
              if (Get.isRegistered<MediaSearchListController>()) {
                Get.delete<MediaSearchListController>();
              }
              Get.put(
                MediaSearchListController(
                  initialKeyword: keyword,
                  initialType: type,
                ),
              );
            }),
            middlewares: permissionGuards('/media-search-list'),
          ),
          GetPage(
            name: '/person-search-list',
            page: () => const PersonSearchResultPage(),
            binding: BindingsBuilder(() {
              final keyword = (Get.arguments?['keyword']?.toString() ?? '')
                  .trim();
              Get.put(
                PersonSearchListController(initialKeyword: keyword),
                permanent: false,
              );
            }),
            middlewares: permissionGuards('/person-search-list'),
          ),
          GetPage(
            name: '/person-detail',
            page: () => const PersonDetailPage(),
            binding: BindingsBuilder(() {
              final rawId =
                  Get.arguments?['id']?.toString() ??
                  Get.parameters['id']?.toString() ??
                  '';
              final personId = int.tryParse(rawId) ?? 0;
              final source = Get.parameters['source'] ?? '';
              Get.put(
                PersonDetailController(personId: personId, source: source),
              );
            }),
          ),
          GetPage(
            name: '/subscribe-tv',
            page: () => const SubscribePage(),
            binding: BindingsBuilder(() {
              Get.put(
                SubscribeController()..subscribeType = SubscribeType.tv,
                permanent: false,
              );
            }),
            middlewares: permissionGuards('/subscribe-tv'),
          ),
          GetPage(
            name: '/subscribe-movie',
            page: () => const SubscribePage(),
            binding: BindingsBuilder(() {
              Get.put(
                SubscribeController()..subscribeType = SubscribeType.movie,
                permanent: false,
              );
            }),
            middlewares: permissionGuards('/subscribe-movie'),
          ),
          GetPage(
            name: '/subscribe-popular',
            page: () => const SubscribePopularPage(),
            binding: BindingsBuilder(() {
              Get.put(SubscribePopularController(), permanent: false);
            }),
            middlewares: permissionGuards('/subscribe-popular'),
          ),
          GetPage(
            name: '/subscribe-history',
            page: () => const SubscribeHistoryPage(),
            binding: BindingsBuilder(() {
              Get.put(SubscribeHistoryController(), permanent: false);
            }),
            middlewares: permissionGuards('/subscribe-history'),
          ),
          GetPage(
            name: '/subscribe-share',
            page: () => const SubscribeSharePage(),
            binding: BindingsBuilder(() {
              final keyword = Get.parameters['keyword'];
              Get.put(
                SubscribeShareController()..keyword.value = keyword ?? '',
                permanent: false,
              );
            }),
            middlewares: permissionGuards('/subscribe-share'),
          ),
          GetPage(
            name: '/subscribe-share-statistics',
            page: () => const SubscribeShareStatisticsPage(),
            binding: BindingsBuilder(() {
              Get.put(SubscribeShareStatisticsController(), permanent: false);
            }),
            middlewares: permissionGuards('/subscribe-share-statistics'),
          ),
          GetPage(
            name: '/subscribe-calendar',
            page: () => const SubscribeCalendarPage(),
            binding: BindingsBuilder(() {
              Get.put(SubscribeCalendarController(), permanent: false);
            }),
            middlewares: permissionGuards('/subscribe-calendar'),
          ),
          GetPage(
            name: '/subscribe-edit',
            page: () => const SubscribeEditPage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<DownloaderController>()) {
                Get.put(DownloaderController(), permanent: true);
              }
              if (!Get.isRegistered<DirectoryListController>()) {
                Get.put(DirectoryListController(), permanent: true);
              }
              if (!Get.isRegistered<SiteController>()) {
                Get.put(SiteController(), permanent: true);
              }
              Get.put(SubscribeEditController(), permanent: false);
            }),
            middlewares: permissionGuards('/subscribe-edit'),
          ),
          GetPage(
            name: '/media-organize',
            page: () => const MediaOrganizePage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<StorageListController>()) {
                Get.put(StorageListController(), permanent: true);
              }
              final keyword = Get.parameters['keyword'];
              Get.put(
                MediaOrganizeController(initialKeyword: keyword),
                permanent: false,
              );
            }),
            middlewares: permissionGuards('/media-organize'),
          ),
          GetPage(
            name: '/downloader',
            page: () => const DownloaderPage(),
            binding: BindingsBuilder(() {
              Get.put(DownloaderController(), permanent: false);
            }),
          ),
          GetPage(
            name: '/downloader-config',
            page: () => const DownloaderConfigListPage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<DownloadController>()) {
                Get.put(DownloadController(), permanent: false);
              }
            }),
            middlewares: permissionGuards('/downloader-config'),
          ),
          GetPage(
            name: '/downloader-detail',
            page: () => const DownloaderTorrentListPage(),
            binding: BindingsBuilder(() {
              final args = Get.arguments['config'] as Map<String, dynamic>;
              final config = DownloaderConfig.fromJson(args);
              Get.put(
                DownloaderControllerAdaptor.getController(config),
                permanent: false,
              );
            }),
          ),
          GetPage(
            name: '/downloader-config/form',
            page: () => const DownloaderConfigPage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<DownloaderConfigController>()) {
                Get.put(DownloaderConfigController(), permanent: false);
              }
            }),
          ),
          GetPage(
            name: '/mediaserver-config',
            page: () => const MediaServerConfigListPage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<MediaServerController>()) {
                Get.put(MediaServerController(), permanent: true);
              }
            }),
            middlewares: permissionGuards('/mediaserver-config'),
          ),
          GetPage(
            name: '/plugin',
            page: () => const PluginPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut<PluginPaletteCache>(
                () => PluginPaletteCache(),
                fenix: true,
              );
              if (!Get.isRegistered<PluginController>()) {
                Get.put(PluginController(), permanent: true);
              }
            }),
            middlewares: permissionGuards('/plugin'),
          ),
          GetPage(
            name: '/plugin/dynamic-form/log',
            page: () => const ServerLogPage(),
            binding: BindingsBuilder(() {
              final id = Get.arguments['id']?.toString() ?? '';
              final title = Get.arguments['title']?.toString() ?? '';
              final file = id.isEmpty
                  ? 'moviepilot.log'
                  : 'plugins/${id.toLowerCase()}.log';
              Get.lazyPut(
                () => ServerLogController()
                  ..logFile = file
                  ..title = title,
              );
            }),
            middlewares: permissionGuards('/plugin/dynamic-form/log'),
          ),
          GetPage(
            name: '/plugin-list',
            page: () => const PluginListPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut<PluginPaletteCache>(
                () => PluginPaletteCache(),
                fenix: true,
              );
              Get.put(PluginListController(), permanent: false);
            }),
            middlewares: permissionGuards('/plugin-list'),
          ),
          GetPage(
            name: '/media-detail',
            page: () => const MediaDetailPage(),
            binding: BindingsBuilder(() {
              Get.create(() => MediaDetailController());
            }),
          ),
          GetPage(
            name: '/recommend-category-list',
            page: () => const RecommendCategoryListPage(),
            binding: BindingsBuilder(() {
              final key = Get.parameters['key'] ?? '';
              final title = Get.parameters['title'] ?? '';
              final colorParam = Get.parameters['themeColor'];
              final secondaryColorParam = Get.parameters['secondaryThemeColor'];
              Color? themeColor;
              Color? secondaryColor;
              if (colorParam != null && colorParam.isNotEmpty) {
                try {
                  final value = int.parse(colorParam, radix: 16);
                  themeColor = Color(value);
                } catch (_) {}
              }
              if (secondaryColorParam != null &&
                  secondaryColorParam.isNotEmpty) {
                try {
                  final value = int.parse(secondaryColorParam, radix: 16);
                  secondaryColor = Color(value);
                } catch (_) {}
              }
              Get.put(
                RecommendCategoryListController(
                  key: key,
                  title: title,
                  appBarThemeColor: themeColor,
                  appBarSecondaryThemeColor: secondaryColor,
                ),
                permanent: false,
              );
            }),
            middlewares: permissionGuards('/recommend-category-list'),
          ),

          GetPage(
            name: '/site',
            page: () => const SitePage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<SiteController>()) {
                final controller = Get.put(SiteController(), permanent: true);
                controller.ensureInitialized();
              }
            }),
            middlewares: permissionGuards('/site'),
          ),
          GetPage(
            name: '/site-resource',
            page: () => const SiteResourcePage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SiteResourceController());
            }),
            middlewares: permissionGuards('/site-resource'),
          ),
          GetPage(
            name: '/site-detail',
            page: () => const SiteDetailPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SiteDetailController());
            }),
            middlewares: permissionGuards('/site-detail'),
          ),
          GetPage(
            name: '/site-edit',
            page: () => const SiteEditPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SiteEditController());
            }),
            middlewares: permissionGuards('/site-edit'),
          ),
          GetPage(
            name: '/user-management',
            page: () => const UserManagementPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => UserManagementController());
            }),
            middlewares: permissionGuards('/user-management'),
          ),
          GetPage(
            name: '/storage-list',
            page: () => const StorageListPage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<StorageListController>()) {
                Get.put(StorageListController(), permanent: true);
              }
            }),
            middlewares: permissionGuards('/storage-list'),
          ),
          GetPage(
            name: '/directory-list',
            page: () => const DirectoryListPage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<DirectoryListController>()) {
                Get.put(DirectoryListController(), permanent: true);
              }
            }),
            middlewares: permissionGuards('/directory-list'),
          ),
          GetPage(
            name: '/settings',
            page: () => const SettingsPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SettingsController());
            }),
            middlewares: permissionGuards('/settings'),
          ),
          GetPage(
            name: '/settings/:category',
            page: () => const SettingsSubListPage(),
            binding: BindingsBuilder(() {
              final category = Get.parameters['category'] ?? '';
              final args = Get.arguments as Map<String, dynamic>?;
              final title = args?['title'] as String? ?? category;
              Get.lazyPut(
                () => SettingsSubListController(
                  categoryId: category,
                  pageTitle: title,
                ),
              );
            }),
            middlewares: permissionGuards('/settings'),
          ),
          GetPage(
            name: '/settings/detail',
            page: () => const SettingsDetailPlaceholderPage(),
            middlewares: permissionGuards('/settings'),
          ),
          GetPage(
            name: '/settings/system/basic',
            page: () => const SettingsBasicPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SettingsBasicController());
            }),
            middlewares: permissionGuards('/settings/system/basic'),
          ),
          GetPage(
            name: '/settings/search/basic',
            page: () => const SettingsSearchDownloadPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SettingsSearchDownloadController());
            }),
            middlewares: permissionGuards('/settings/search/basic'),
          ),
          GetPage(
            name: '/settings/advanced/detail',
            page: () => const SettingsAdvancedDetailPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SettingsAdvancedDetailController());
            }),
            middlewares: permissionGuards('/settings/advanced/detail'),
          ),
          GetPage(
            name: '/organize-scrape',
            page: () => const OrganizeScrapePage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SettingsOrganizeScrapeController());
            }),
            middlewares: permissionGuards('/organize-scrape'),
          ),
          GetPage(
            name: '/site-sync',
            page: () => const SiteSyncPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SettingsSiteSyncController());
            }),
            middlewares: permissionGuards('/site-sync'),
          ),
          GetPage(
            name: '/site-options',
            page: () => const SiteOptionsPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => SettingsSiteOptionsController());
            }),
            middlewares: permissionGuards('/site-options'),
          ),
          GetPage(
            name: '/custom-rule',
            page: () => const CustomRulePage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => RuleController(ruleType: RuleType.custom));
            }),
            middlewares: permissionGuards('/custom-rule'),
          ),
          GetPage(
            name: '/priority-rule',
            page: () => const PriorityRulePage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => RuleController(ruleType: RuleType.priority));
            }),
            middlewares: permissionGuards('/priority-rule'),
          ),
          GetPage(
            name: '/download-rule',
            page: () => const DownloadRulePage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => RuleController(ruleType: RuleType.download));
            }),
            middlewares: permissionGuards('/download-rule'),
          ),
          GetPage(
            name: '/workflow',
            page: () => const WorkflowPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => WorkflowController());
            }),
            middlewares: permissionGuards('/workflow'),
          ),
          GetPage(
            name: '/file-manager',
            page: () => const FileManagerBrowserPage(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<StorageListController>()) {
                Get.put(StorageListController(), permanent: true);
              }
              final args = Get.arguments is Map
                  ? Get.arguments as Map
                  : <String, dynamic>{};
              final tag = args['_controllerTag']?.toString();
              Get.put(
                FileManagerBrowserController(
                  isPickerMode: args['isPickerMode'] == true,
                  allowMultipleSelection:
                      args['allowMultipleSelection'] == true,
                  allowFileSelection: args['allowFileSelection'] != false,
                  allowDirSelection: args['allowDirSelection'] != false,
                  initialStorageType: args['initialStorage']?.toString(),
                  initialPath: args['initialPath']?.toString(),
                  allowSelectStorage: args['allowSelectStorage'] != false,
                ),
                tag: tag,
                permanent: false,
              );
            }),
            middlewares: permissionGuards('/file-manager'),
          ),
          GetPage(
            name: '/plugin/dynamic-form/page',
            page: () => const DynamicFormPage(controllerTag: 'page'),
            binding: BindingsBuilder(() {
              final args = Get.arguments;
              final id = args is Map ? args['id']?.toString() : null;
              final title = args is Map ? args['title']?.toString() : null;
              Get.lazyPut(
                () => DynamicFormController()
                  ..init(
                    '/api/v1/plugin/page/$id',
                    title: title,
                    formMode: false,
                    pluginId: id,
                  ),
                tag: 'page',
              );
            }),
            middlewares: permissionGuards('/plugin/dynamic-form/page'),
          ),
          GetPage(
            name: '/plugin/dynamic-form/form',
            page: () => const DynamicFormPage(controllerTag: 'form'),
            binding: BindingsBuilder(() {
              final args = Get.arguments;
              final id = args is Map ? args['id']?.toString() : null;
              final title = args is Map ? args['title']?.toString() : null;
              Get.lazyPut(
                () => DynamicFormController()
                  ..init(
                    '/api/v1/plugin/form/$id',
                    title: title,
                    formMode: true,
                    pluginId: id,
                  )
                  ..apiSavePath = '/api/v1/plugin/$id',
                tag: 'form',
              );
            }),
            middlewares: permissionGuards('/plugin/dynamic-form/form'),
          ),
          GetPage(
            name: '/web-view',
            page: () {
              final args = Get.parameters;
              final url = args['url'] ?? '';
              final cookie = args['cookie'] ?? '';
              return WebViewScreen(url: url, cookie: cookie);
            },
          ),
          GetPage(
            name: '/settings/app/theme-mode',
            page: () => const AppThemeSettingPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => AppSettingController());
            }),
            middlewares: permissionGuards('/settings/app/theme-mode'),
          ),
          GetPage(
            name: '/settings/app/background-image',
            page: () => const BackgroundImageSettingPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => AppSettingController());
            }),
            middlewares: permissionGuards('/settings/app/background-image'),
          ),
          GetPage(
            name: '/settings/app/app-setting',
            page: () => const AppSettingPage(),
            binding: BindingsBuilder(() {
              Get.lazyPut(() => AppSettingController());
            }),
            middlewares: permissionGuards('/settings/app/app-setting'),
          ),
          GetPage(
            name: '/settings/app/changelog',
            page: () => const ChangelogPage(),
            middlewares: permissionGuards('/settings/app/changelog'),
          ),
          GetPage(
            name: '/app/log',
            page: () =>
                TalkerScreen(talker: talker.talker, appBarTitle: 'App日志'),
            middlewares: permissionGuards('/app/log'),
          ),
        ],
        // 配置错误处理
        builder: (context, child) {
          return AppScaffoldBackground(
            child: TalkerWrapper(
              talker: talker.talker,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child ?? const SizedBox.shrink(),
                  const AgentFloatingEntry(),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
