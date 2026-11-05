import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/media_detail_model.dart'
    show Actor;
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/api_auth_failure.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

class PersonSearchListController extends GetxController {
  PersonSearchListController({required this.initialKeyword});

  final String initialKeyword;

  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  final RxString keyword = ''.obs;
  final RxList<Actor> items = <Actor>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();
  final RxBool hasMore = false.obs;
  final RxInt currentPage = 1.obs;

  static const _basePath = '/api/v1/media/search';

  int get page => currentPage.value;

  @override
  void onInit() {
    super.onInit();
    keyword.value = initialKeyword.trim();
  }

  @override
  void onReady() {
    super.onReady();
    if (keyword.value.isNotEmpty) {
      search();
    } else {
      error.value = '请输入搜索关键字';
    }
  }

  Future<void> search() async {
    currentPage.value = 1;
    await _fetch(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    await _fetch(page: currentPage.value + 1, append: true);
  }

  Iterable<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      for (final key in const ['data', 'results', 'items', 'list']) {
        final v = raw[key];
        if (v is List) return v;
      }
    }
    return const [];
  }

  Future<void> _fetch({required int page, required bool append}) async {
    final term = keyword.value.trim();
    if (term.isEmpty) return;
    isLoading.value = true;
    error.value = null;

    try {
      final token =
          _appService.loginResponse?.accessToken ??
          _appService.latestLoginProfileAccessToken ??
          _apiClient.token;
      if (token == null || token.isEmpty) {
        error.value = '请先登录后再尝试搜索';
        isLoading.value = false;
        return;
      }

      final params = <String, dynamic>{
        'title': term,
        'type': 'person',
        'page': page,
      };

      final response = await _apiClient.get<dynamic>(
        _basePath,
        token: token,
        timeout: 120,
        queryParameters: params,
      );

      final status = response.statusCode ?? 0;
      if (status == 401 || status == 403) {
        error.value = ApiAuthFailure.from(status, response.data).message;
        isLoading.value = false;
        return;
      }
      if (status >= 400) {
        error.value = '请求失败 (HTTP $status)';
        isLoading.value = false;
        return;
      }

      final raw = response.data;
      final actors = _extractList(
        raw,
      ).whereType<Map<String, dynamic>>().map(Actor.fromJson).toList();

      if (append) {
        items.addAll(actors);
      } else {
        items.assignAll(actors);
      }

      currentPage.value = page;
      hasMore.value = actors.isNotEmpty;
      if (actors.isEmpty && !append) {
        error.value = '没有找到匹配的演员';
      }
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '演员搜索失败');
      error.value = '搜索失败，请稍后重试';
    } finally {
      isLoading.value = false;
    }
  }
}
