import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

/// 用户订阅统计
class UserSubscribeStats {
  const UserSubscribeStats({this.movieCount = 0, this.tvCount = 0});
  final int movieCount;
  final int tvCount;
}

class UserManagementController extends GetxController {
  final _authRepo = Get.find<AuthRepository>();
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  final items = <UserInfo>[].obs;
  final subscribeStatsMap = <int, UserSubscribeStats>{}.obs;
  final isLoading = false.obs;
  final errorText = RxnString();
  final searchKeyword = ''.obs;

  bool get canManage => _appService.isSuperuser;

  List<UserInfo> get filteredItems {
    final kw = searchKeyword.value.trim().toLowerCase();
    if (kw.isEmpty) return List<UserInfo>.from(items);
    return items
        .where(
          (u) =>
              u.name.toLowerCase().contains(kw) ||
              u.email.toLowerCase().contains(kw),
        )
        .toList();
  }

  UserSubscribeStats? getStatsForUser(int userId) => subscribeStatsMap[userId];

  @override
  void onReady() {
    super.onReady();
    if (!canManage) {
      errorText.value = '当前帐号无账户管理权限';
      items.clear();
      subscribeStatsMap.clear();
      return;
    }
    load();
  }

  Future<void> load() async {
    if (!canManage) {
      errorText.value = '当前帐号无账户管理权限';
      items.clear();
      subscribeStatsMap.clear();
      return;
    }
    isLoading.value = true;
    errorText.value = null;

    try {
      final users = await _authRepo.listUsers();
      items.value = users;

      if (users.isEmpty) {
        isLoading.value = false;
        return;
      }

      final Map<int, UserSubscribeStats> stats = {};
      await Future.wait(
        users.map((u) async {
          final s = await _fetchSubscribeStats(u.name);
          if (s != null) stats[u.id] = s;
        }),
      );
      subscribeStatsMap.value = stats;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载用户列表失败');
      errorText.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<UserSubscribeStats?> _fetchSubscribeStats(String username) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/subscribe/user/$username',
      );
      if (response.statusCode != null && response.statusCode! >= 400) {
        return null;
      }
      final raw = response.data;
      final list = raw is List ? raw : <dynamic>[];
      int movieCount = 0;
      int tvCount = 0;
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final sub = SubscribeItem.fromJson(item);
        final t = sub.type?.trim().toLowerCase() ?? '';
        if (t.contains('电影') || t.contains('movie') || t == 'movie') {
          movieCount++;
        } else if (t.contains('电视剧') || t.contains('tv') || t == 'tv') {
          tvCount++;
        }
      }
      return UserSubscribeStats(movieCount: movieCount, tvCount: tvCount);
    } catch (_) {
      return null;
    }
  }

  void search(String keyword) {
    searchKeyword.value = keyword.trim();
  }

  Future<void> deleteUser(int userId) async {
    if (!canManage) {
      errorText.value = '当前帐号无账户管理权限';
      return;
    }
    try {
      await _apiClient.delete('/api/v1/user/id/$userId');
      items.removeWhere((u) => u.id == userId);
    } catch (e) {
      _log.handle(e, message: '删除用户失败');
    }
  }
}
