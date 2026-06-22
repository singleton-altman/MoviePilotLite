import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:altman_totp/services/totp_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import '../../../utils/toast_util.dart';
import '../models/login_profile.dart';
import '../repositories/auth_repository.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/utils/prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  final _repository = Get.find<AuthRepository>();
  final _totpService = Get.find<TotpService>();
  final _talker = Get.find<AppLog>();
  final imageUtil = Get.find<ImageUtil>();

  /// 默认壁纸（无本地缓存时使用，如首次安装）
  static const List<String> defaultWallpapers = [
    'https://image.tmdb.org/t/p/original/7HKpc11uQfxnw0Y8tRUYn1fsKqE.jpg',
    'https://image.tmdb.org/t/p/original/hHDNOlATHhre4eZ7aYz5cdyJLik.jpg',
    'https://image.tmdb.org/t/p/original/7mkUu1F2hVUNgz24xO8HPx0D6mK.jpg',
    'https://image.tmdb.org/t/p/original/6YjnTRBz704LF1uJ3ZC4wsS9T8r.jpg',
    'https://image.tmdb.org/t/p/original/77TCOiGEmHYLndIw4jsf6uUra4X.jpg',
    'https://image.tmdb.org/t/p/original/gklrevVndG98GHGDwfm8y8kxESo.jpg',
    'https://image.tmdb.org/t/p/original/yWCZc2TcsCYbMMjvUIsczmQi2TX.jpg',
    'https://image.tmdb.org/t/p/original/tNONILTe9OJz574KZWaLze4v6RC.jpg',
    'https://image.tmdb.org/t/p/original/thgemkoLauZxcqe6KX8wxqEc70z.jpg',
    'https://image.tmdb.org/t/p/original/5QsLvWh8J1mXl1W05wNJknMmhzR.jpg',
  ];

  final serverController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  final profiles = <LoginProfile>[].obs;
  final selectedProfile = Rxn<LoginProfile>();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  /// 当前步骤：1=仅服务器，2=账号密码
  final step = 1.obs;
  final isAutoLogin = false.obs;

  /// 壁纸 URL 列表
  final wallpapers = <String>[].obs;

  /// 当前显示的壁纸索引（用于轮播）
  final currentWallpaperIndex = 0.obs;

  Timer? _wallpaperTimer;

  @override
  void onInit() {
    _totpService.load();
    _loadSavedWallpapers();
    unawaited(_bootstrapSavedSession());
    serverController.addListener(_autofillTotpIfMatched);
    usernameController.addListener(_autofillTotpIfMatched);
    super.onInit();
  }

  /// 加载上次登录保存的壁纸；无缓存时使用默认壁纸（如首次安装）
  Future<void> _loadSavedWallpapers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(kLoginWallpapersKey);
      List<String> list = <String>[];

      if (json != null && json.isNotEmpty) {
        final decoded = jsonDecode(json);
        list = decoded is List
            ? decoded
                  .whereType<String>()
                  .where((s) => s.startsWith('http'))
                  .toList()
            : <String>[];
      }

      wallpapers.assignAll(list.isNotEmpty ? list : defaultWallpapers);
      currentWallpaperIndex.value = 0;
      _startWallpaperTimer();
    } catch (e) {
      _talker.warning('加载壁纸缓存失败: $e');
      wallpapers.assignAll(defaultWallpapers);
      _startWallpaperTimer();
    }
  }

  /// 保存壁纸列表供下次登录使用
  Future<void> _saveWallpapers() async {
    if (wallpapers.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        kLoginWallpapersKey,
        jsonEncode(wallpapers.toList()),
      );
    } catch (e) {
      _talker.warning('保存壁纸缓存失败: $e');
    }
  }

  @override
  void onClose() {
    _wallpaperTimer?.cancel();
    serverController.removeListener(_autofillTotpIfMatched);
    usernameController.removeListener(_autofillTotpIfMatched);
    super.onClose();
  }

  /// 进入下一步：验证服务器、获取壁纸、进入步骤 2
  Future<void> goToNextStep() async {
    final server = serverController.text.trim();
    if (server.isEmpty) {
      ToastUtil.info('请输入服务器地址');
      return;
    }

    // 简单校验 URL 格式
    final uri = Uri.tryParse(server);
    if (uri == null || !uri.hasScheme) {
      ToastUtil.info('请输入有效的服务器地址（含协议，如 https://example.com）');
      return;
    }

    isLoading.value = true;
    try {
      final list = await _repository.fetchWallpapers(server);
      wallpapers.assignAll(list.isNotEmpty ? list : defaultWallpapers);
      currentWallpaperIndex.value = 0;
      step.value = 2;
      _startWallpaperTimer();
    } catch (e) {
      _talker.warning('获取壁纸失败: $e');
      wallpapers.assignAll(defaultWallpapers);
      _startWallpaperTimer();
      step.value = 2;
    } finally {
      isLoading.value = false;
    }
  }

  /// 返回步骤 1（保留壁纸以保持背景一致）
  void goToStep1() {
    step.value = 1;
    // 不清理壁纸，保持与步骤 2 相同的背景效果
  }

  void _startWallpaperTimer() {
    _stopWallpaperTimer();
    if (wallpapers.isEmpty || wallpapers.length < 2) return;

    _wallpaperTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      currentWallpaperIndex.value =
          (currentWallpaperIndex.value + 1) % wallpapers.length;
    });
  }

  void _stopWallpaperTimer() {
    _wallpaperTimer?.cancel();
    _wallpaperTimer = null;
  }

  void resetForLogout() {
    isAutoLogin.value = false;
    isLoading.value = false;
    step.value = 1;
  }

  Future<void> _bootstrapSavedSession() async {
    await _loadProfiles();
    await _restoreLocalSessionIfAvailable();
  }

  Future<void> _restoreLocalSessionIfAvailable() async {
    if (profiles.isEmpty) return;

    final latestProfile = profiles.first;
    if (latestProfile.accessToken.isEmpty) return;

    isAutoLogin.value = true;
    try {
      _repository.restoreLocalSession(profile: latestProfile);
      _talker.info('已恢复本地登录态');

      final lastIndex = await _loadLastTabIndex();
      if (lastIndex != null) {
        Get.offAllNamed('/main', arguments: {'initialIndex': lastIndex});
      } else {
        Get.offAllNamed('/main');
      }
      imageUtil.loadGlobalCachedConfig();
      Future.delayed(const Duration(seconds: 1), () {
        isAutoLogin.value = false;
      });
    } catch (e) {
      _talker.warning('恢复本地登录态失败: $e');
      isAutoLogin.value = false;
    }
  }

  Future<void> _loadProfiles() async {
    final list = await _repository.getProfilesAsync();
    _applyProfilesList(list);
  }

  void _applyProfilesList(List<LoginProfile> list) {
    profiles.assignAll(list);
    if (profiles.isEmpty) {
      selectedProfile.value = null;
      return;
    }

    final currentId = selectedProfile.value?.id;
    LoginProfile? match;
    if (currentId != null) {
      for (final p in profiles) {
        if (p.id == currentId) {
          match = p;
          break;
        }
      }
    }
    fillFromProfile(match ?? profiles.first);
  }

  Future<void> deleteProfile(LoginProfile profile) async {
    final id = profile.id;
    final username = profile.username;
    final server = profile.server;
    final password = profile.password;
    final wasSelected = selectedProfile.value?.id == id;
    final formStillMatches =
        serverController.text.trim() == server.trim() &&
        usernameController.text.trim() == username.trim() &&
        passwordController.text == password;

    try {
      await _repository.deleteProfile(id);
      final remaining = await _repository.getProfilesAsync();
      profiles.assignAll(remaining);

      if (wasSelected) {
        selectedProfile.value = null;
        if (formStillMatches) {
          otpController.clear();
          passwordController.clear();
          usernameController.clear();
          serverController.clear();
          step.value = 1;
        }
      } else {
        final selectedId = selectedProfile.value?.id;
        if (selectedId != null) {
          LoginProfile? refreshedSelection;
          for (final item in remaining) {
            if (item.id == selectedId) {
              refreshedSelection = item;
              break;
            }
          }
          selectedProfile.value = refreshedSelection;
        }
      }

      ToastUtil.success('已删除账号 $username');
    } catch (e) {
      _talker.warning('删除登录账号失败: $e');
      ToastUtil.error('删除账号失败，请稍后重试');
    }
  }

  void fillFromProfile(LoginProfile profile) {
    selectedProfile.value = profile;
    serverController.text = profile.server;
    usernameController.text = profile.username;
    passwordController.text = profile.password;
    _autofillTotpIfMatched(force: true);

    // 若当前在步骤 1，选中历史账号后直接进入步骤 2 并拉取壁纸
    if (step.value == 1) {
      goToNextStep();
    }
  }

  Future<void> submitLogin() async {
    final server = serverController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text;
    _autofillTotpIfMatched();
    final otpPassword = otpController.text.trim();

    if (server.isEmpty || username.isEmpty || password.isEmpty) {
      ToastUtil.info('服务器地址、用户名和密码不能为空');
      return;
    }

    isLoading.value = true;
    try {
      await _repository.login(
        server: server,
        username: username,
        password: password,
        otpPassword: otpPassword,
      );
      await _saveWallpapers();
      imageUtil.loadGlobalCachedConfig();
      await _loadProfiles();
      ToastUtil.success(
        '已保存账号信息',
        title: '登录成功',
        snackPosition: SnackPosition.TOP,
      );
      // 跳转到 Dashboard
      final lastIndex = await _loadLastTabIndex();
      if (lastIndex != null) {
        Get.offAllNamed('/main', arguments: {'initialIndex': lastIndex});
      } else {
        Get.offAllNamed('/main');
      }
    } catch (e) {
      ToastUtil.error(e.toString(), title: '登录失败');
    } finally {
      isLoading.value = false;
    }
  }

  void _autofillTotpIfMatched({bool force = false}) {
    final server = serverController.text.trim();
    final username = usernameController.text.trim();
    if (server.isEmpty || username.isEmpty) return;
    final code = _totpService.generateCurrentCode(server, username);
    if (code == null || code.isEmpty) return;
    if (!force && otpController.text.trim().isNotEmpty) return;
    otpController.text = code;
  }

  Future<int?> _loadLastTabIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(kIndexLastTabKey);
      if (stored == null) return null;
      final clamped = stored.clamp(0, kIndexMaxTab);
      return clamped;
    } catch (_) {
      return null;
    }
  }
}
