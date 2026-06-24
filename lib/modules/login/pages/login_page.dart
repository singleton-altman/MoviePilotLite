import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:altman_totp/page/totp_manage_page.dart';
import 'package:moviepilot_mobile/widgets/cached_image.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_button.dart';
import '../controllers/login_controller.dart';
import '../models/login_profile.dart';
import 'account_picker_page.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final stepValue = controller.step.value;
        final isAutoLogin = controller.isAutoLogin.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(context),
            if (isAutoLogin)
              Center(
                child: CupertinoActivityIndicator(color: CupertinoColors.white),
              )
            else
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (stepValue == 2) _buildBackButton(context),
                          const SizedBox(height: 24),
                          _buildHeader(context),
                          const SizedBox(height: 32),
                          if (stepValue == 1) ...[
                            _buildServerStep(context),
                            const SizedBox(height: 16),
                            _buildProfilePicker(context),
                          ] else ...[
                            _buildCredentialsStep(context),
                            const SizedBox(height: 16),
                            _buildProfilePicker(context),
                            const SizedBox(height: 24),
                            Obx(
                              () => CustomButton(
                                text: '登录并保存',
                                icon: CupertinoIcons.check_mark,
                                isLoading: controller.isLoading.value,
                                onPressed: () => controller.submitLogin(),
                                borderRadius: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  /// 背景逻辑：有壁纸则显示壁纸+遮罩，否则显示渐变色（步骤 1、2 一致）
  Widget _buildBackground(BuildContext context) {
    return Obx(() {
      final list = controller.wallpapers;
      if (list.isEmpty) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.background,
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1a1a2e)
                    : const Color(0xFFe8eaf6),
              ],
            ),
          ),
        );
      }

      final idx = controller.currentWallpaperIndex.value % list.length;
      final url = list[idx];

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: Stack(
          key: ValueKey(url),
          fit: StackFit.expand,
          children: [
            CachedImage(imageUrl: url, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CupertinoButton(
        padding: const EdgeInsets.only(left: 0, top: 8, bottom: 8),
        minSize: 0,
        onPressed: () => controller.goToStep1(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.back, color: CupertinoColors.white),
            const SizedBox(width: 6),
            Text(
              '更换服务器',
              style: TextStyle(color: CupertinoColors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController textController,
    String placeholder, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    bool autocorrect = true,
    bool enableSuggestions = true,
    void Function(String)? onSubmitted,
    TextInputAction? textInputAction,
    Widget? suffix,
  }) {
    final hasWallpapers = controller.wallpapers.isNotEmpty;
    final textColor = hasWallpapers ? CupertinoColors.white : null;
    final placeholderStyle = hasWallpapers
        ? TextStyle(color: CupertinoColors.white.withOpacity(0.7))
        : null;
    final fillColor = hasWallpapers
        ? CupertinoColors.white.withOpacity(0.15)
        : CupertinoColors.systemGrey6;
    final borderColor = hasWallpapers
        ? CupertinoColors.white.withOpacity(0.3)
        : CupertinoColors.systemGrey4;
    final prefixColor = hasWallpapers
        ? CupertinoColors.white
        : CupertinoColors.systemGrey;

    return CupertinoTextField(
      controller: textController,
      placeholder: placeholder,
      placeholderStyle: placeholderStyle,
      style: textColor != null ? TextStyle(color: textColor) : null,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      prefix: prefix != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconTheme(
                data: IconThemeData(size: 18, color: prefixColor),
                child: prefix,
              ),
            )
          : null,
      suffix: suffix,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clearButtonMode: OverlayVisibilityMode.editing,
    );
  }

  Widget _buildPasswordField() {
    return Obx(() {
      final hasWallpapers = controller.wallpapers.isNotEmpty;
      final textColor = hasWallpapers ? CupertinoColors.white : null;
      final fillColor = hasWallpapers
          ? CupertinoColors.white.withOpacity(0.15)
          : CupertinoColors.systemGrey6;
      final borderColor = hasWallpapers
          ? CupertinoColors.white.withOpacity(0.3)
          : CupertinoColors.systemGrey4;
      final prefixColor = hasWallpapers
          ? CupertinoColors.white
          : CupertinoColors.systemGrey;
      final suffixColor = hasWallpapers
          ? CupertinoColors.white
          : CupertinoColors.systemGrey;

      return CupertinoTextField(
        controller: controller.passwordController,
        placeholder: '密码',
        placeholderStyle: hasWallpapers
            ? TextStyle(color: CupertinoColors.white.withOpacity(0.7))
            : null,
        style: textColor != null ? TextStyle(color: textColor) : null,
        obscureText: !controller.isPasswordVisible.value,
        keyboardType: TextInputType.text,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconTheme(
            data: IconThemeData(size: 18, color: prefixColor),
            child: const Icon(CupertinoIcons.lock),
          ),
        ),
        suffix: CupertinoButton(
          padding: const EdgeInsets.only(right: 8),
          minSize: 0,
          onPressed: () {
            controller.isPasswordVisible.value =
                !controller.isPasswordVisible.value;
          },
          child: Icon(
            controller.isPasswordVisible.value
                ? CupertinoIcons.eye_slash
                : CupertinoIcons.eye,
            size: 20,
            color: suffixColor,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        clearButtonMode: OverlayVisibilityMode.editing,
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    final hasWallpapers = controller.wallpapers.isNotEmpty;
    final stepValue = controller.step.value;
    final primary = hasWallpapers
        ? CupertinoColors.white
        : context.primaryColor;
    final subtitleColor = hasWallpapers
        ? CupertinoColors.white.withOpacity(0.9)
        : CupertinoColors.systemGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withOpacity(0.2),
          ),
          padding: const EdgeInsets.all(10),
          child: SvgPicture.asset(
            'assets/logo.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(primary, BlendMode.srcIn),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stepValue == 2 ? '输入账号密码登录' : '使用你的账户登录以访问 MoviePilot 服务',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: subtitleColor),
        ),
      ],
    );
  }

  Widget _buildServerStep(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller.serverController,
            '服务器地址（含协议，如 https://example.com）',
            keyboardType: TextInputType.url,
            prefix: const Icon(CupertinoIcons.link),
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.goToNextStep(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () => controller.goToNextStep(),
              child: Text('下一步'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsStep(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller.usernameController,
            '用户名',
            keyboardType: TextInputType.text,
            prefix: const Icon(CupertinoIcons.person),
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: 10),
          _buildPasswordField(),
          const SizedBox(height: 10),
          _buildTextField(
            controller.otpController,
            '二步验证码（如未启用可留空）',
            keyboardType: TextInputType.number,
            prefix: const Icon(CupertinoIcons.number),
            suffix: CupertinoButton(
              padding: const EdgeInsets.only(right: 8),
              minimumSize: const Size(0, 0),
              onPressed: () async {
                final code = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => TotpManagePage(
                    selectMode: true,
                    targetServer: controller.serverController.text.trim(),
                    targetUsername: controller.usernameController.text.trim(),
                  ),
                );
                if (code is String && code.isNotEmpty) {
                  controller.otpController.text = code;
                }
              },
              child: const Text('选择'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicker(BuildContext context) {
    final selected = controller.selectedProfile.value;
    final hasWallpapers = controller.wallpapers.isNotEmpty;
    final titleColor = hasWallpapers ? CupertinoColors.white : null;
    final subtitleColor = hasWallpapers
        ? CupertinoColors.white.withOpacity(0.8)
        : CupertinoColors.systemGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '历史账号',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: titleColor ?? CupertinoColors.label,
              ),
            ),
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Get.toNamed('/totp-manage'),
                  child: Text(
                    'TOTP',
                    style: TextStyle(
                      color: hasWallpapers
                          ? CupertinoColors.white
                          : CupertinoColors.activeBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: controller.profiles.isEmpty
                      ? null
                      : () => _showPicker(context),
                  child: Text(
                    '更多',
                    style: TextStyle(
                      color: hasWallpapers
                          ? CupertinoColors.white
                          : CupertinoColors.activeBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (controller.profiles.isEmpty)
          Text('暂无已保存账号', style: TextStyle(color: subtitleColor))
        else ...[
          Builder(
            builder: (context) =>
                _buildProfileChips(context, controller.profiles, selected),
          ),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${selected.username} @ ${selected.server}',
                style: TextStyle(
                  color: hasWallpapers
                      ? CupertinoColors.white.withOpacity(0.95)
                      : context.primaryColor,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildProfileChips(
    BuildContext context,
    List<LoginProfile> profiles,
    LoginProfile? selected,
  ) {
    final hasWallpapers = controller.wallpapers.isNotEmpty;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: profiles
          .map(
            (p) => GestureDetector(
              onTap: () => controller.fillFromProfile(p),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected?.id == p.id
                      ? (hasWallpapers
                            ? CupertinoColors.white.withOpacity(0.25)
                            : context.primaryColor.withOpacity(0.15))
                      : (hasWallpapers
                            ? CupertinoColors.white.withOpacity(0.15)
                            : Theme.of(context).colorScheme.surface),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected?.id == p.id
                        ? (hasWallpapers
                              ? CupertinoColors.white
                              : context.primaryColor)
                        : (hasWallpapers
                              ? CupertinoColors.white.withOpacity(0.4)
                              : CupertinoColors.systemGrey4),
                  ),
                ),
                child: Text(
                  p.username,
                  style: TextStyle(
                    color: selected?.id == p.id
                        ? (hasWallpapers
                              ? CupertinoColors.white
                              : context.primaryColor)
                        : (hasWallpapers
                              ? CupertinoColors.white.withOpacity(0.9)
                              : CupertinoColors.label),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AccountPickerPage(),
    );
  }
}
