import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/utils/media_identity_util.dart';

/// 用户订阅统计
class UserSubscribeStats {
  const UserSubscribeStats({this.movieCount = 0, this.tvCount = 0});
  final int movieCount;
  final int tvCount;

  int get totalCount => movieCount + tvCount;
}

enum UserManagementStatusFilter { all, active, inactive }

enum UserManagementRoleFilter { all, admin, user }

enum UserManagementOtpFilter { all, enabled, disabled }

enum UserManagementSortKey { username, email, role, subscribe }

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
  final statusFilter = UserManagementStatusFilter.all.obs;
  final roleFilter = UserManagementRoleFilter.all.obs;
  final otpFilter = UserManagementOtpFilter.all.obs;
  final sortKey = UserManagementSortKey.username.obs;
  final sortAscending = true.obs;

  bool get canManage => _appService.isSuperuser;

  bool get hasActiveFilters =>
      statusFilter.value != UserManagementStatusFilter.all ||
      roleFilter.value != UserManagementRoleFilter.all ||
      otpFilter.value != UserManagementOtpFilter.all;

  List<UserInfo> get visibleItems {
    final kw = searchKeyword.value.trim().toLowerCase();
    final result = items.where((u) {
      if (kw.isNotEmpty) {
        final nickname = u.nicknameOrSetting?.toLowerCase() ?? '';
        final username = u.usernameLabel.toLowerCase();
        final email = u.email.toLowerCase();
        if (!nickname.contains(kw) &&
            !username.contains(kw) &&
            !email.contains(kw)) {
          return false;
        }
      }

      switch (statusFilter.value) {
        case UserManagementStatusFilter.all:
          break;
        case UserManagementStatusFilter.active:
          if (!u.isActive) return false;
          break;
        case UserManagementStatusFilter.inactive:
          if (u.isActive) return false;
          break;
      }

      switch (roleFilter.value) {
        case UserManagementRoleFilter.all:
          break;
        case UserManagementRoleFilter.admin:
          if (!u.isSuperuser) return false;
          break;
        case UserManagementRoleFilter.user:
          if (u.isSuperuser) return false;
          break;
      }

      switch (otpFilter.value) {
        case UserManagementOtpFilter.all:
          break;
        case UserManagementOtpFilter.enabled:
          if (!u.isOtp) return false;
          break;
        case UserManagementOtpFilter.disabled:
          if (u.isOtp) return false;
          break;
      }

      return true;
    }).toList();

    result.sort((a, b) {
      final direction = sortAscending.value ? 1 : -1;
      final compare = switch (sortKey.value) {
        UserManagementSortKey.username =>
          a.usernameLabel.toLowerCase().compareTo(
            b.usernameLabel.toLowerCase(),
          ),
        UserManagementSortKey.email => a.email.toLowerCase().compareTo(
          b.email.toLowerCase(),
        ),
        UserManagementSortKey.role => _roleWeight(a).compareTo(_roleWeight(b)),
        UserManagementSortKey.subscribe =>
          (getStatsForUser(a.id)?.totalCount ?? 0).compareTo(
            getStatsForUser(b.id)?.totalCount ?? 0,
          ),
      };
      return compare * direction;
    });

    return result;
  }

  List<UserInfo> get filteredItems => visibleItems;

  UserSubscribeStats? getStatsForUser(int userId) => subscribeStatsMap[userId];

  int _roleWeight(UserInfo user) => user.isSuperuser ? 0 : 1;

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
        final sub = SubscribeItem.fromJson(normalizeSubscribeJson(item));
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
    updateKeyword(keyword);
  }

  void updateKeyword(String keyword) {
    searchKeyword.value = keyword.trim();
  }

  void updateStatusFilter(UserManagementStatusFilter value) {
    statusFilter.value = value;
  }

  void updateRoleFilter(UserManagementRoleFilter value) {
    roleFilter.value = value;
  }

  void updateOtpFilter(UserManagementOtpFilter value) {
    otpFilter.value = value;
  }

  void clearFilters() {
    statusFilter.value = UserManagementStatusFilter.all;
    roleFilter.value = UserManagementRoleFilter.all;
    otpFilter.value = UserManagementOtpFilter.all;
  }

  void updateSortKey(UserManagementSortKey value) {
    sortKey.value = value;
  }

  void updateSortDirection(bool ascending) {
    sortAscending.value = ascending;
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
