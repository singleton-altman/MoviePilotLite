import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/login/models/login_profile.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../controllers/profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  /// 点击头像：从相册选择并上传（POST /api/v1/user/avatar/{user_id}）。
  Future<void> _pickAvatar() async {
    ToastUtil.loading(message: '正在上传头像…');
    final error = await controller.pickAndUploadAvatar();
    ToastUtil.dismiss();
    if (error == null) {
      ToastUtil.success('头像已更新');
    } else if (error.isNotEmpty) {
      ToastUtil.error(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        left: false,
        right: false,
        child: Obx(() {
          final profile = controller.currentProfile.value;
          final userInfo = controller.currentUserInfo.value;
          if (profile == null) {
            return const Center(child: Text('暂无登录信息'));
          }
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 200,
                centerTitle: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImmersiveHeader(context, profile, userInfo),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Skeletonizer(
                    enabled: controller.isLoading.value,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildAccountCard(profile, userInfo),
                        const SizedBox(height: 16),
                        _buildServerCard(profile, userInfo),
                        const SizedBox(height: 16),
                        _buildThirdPartyCard(userInfo),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _buildLogoutButton(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _buildSwitchAccountButton(context),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildImmersiveHeader(
    BuildContext context,
    LoginProfile profile,
    UserInfo? userInfo,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final displayName = (userInfo?.name.isNotEmpty == true)
        ? userInfo!.name
        : (profile.userName.isNotEmpty ? profile.userName : profile.username);
    final nickname =
        userInfo?.nickname ?? (userInfo?.settings['nickname'] as String? ?? '');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, theme.scaffoldBackgroundColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 24,
          top: kToolbarHeight + 24,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  _buildAvatar(userInfo?.avatar ?? profile.avatar),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 11,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nickname.isNotEmpty ? '@$nickname' : '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (userInfo?.isActive == true)
                        _buildStatusChip(
                          '已激活',
                          icon: CupertinoIcons.check_mark_circled_solid,
                        ),
                      if (userInfo?.isSuperuser == true)
                        _buildStatusChip(
                          '超级管理员',
                          icon: CupertinoIcons.star_fill,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(LoginProfile profile, UserInfo? userInfo) {
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '账户信息',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: CupertinoIcons.at,
            label: '用户名',
            value: profile.username,
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: CupertinoIcons.envelope,
            label: '邮箱',
            value: userInfo?.email ?? '未设置',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: CupertinoIcons.number,
            label: '用户 ID',
            value: (userInfo?.id ?? profile.userId).toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(LoginProfile profile, UserInfo? userInfo) {
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '服务器与安全',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: CupertinoIcons.link,
            label: '服务器',
            value: profile.server,
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: CupertinoIcons.shield_lefthalf_fill,
            label: '权限等级',
            value: 'Level ${profile.level}',
          ),
          const Divider(height: 20),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Get.toNamed('/mfa-settings'),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    icon: CupertinoIcons.lock_shield,
                    label: '二步验证',
                    value: (userInfo?.isOtp == true) ? '已开启' : '未开启',
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: Theme.of(Get.context!)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPartyCard(UserInfo? userInfo) {
    final rows = <Widget>[];

    void addItem({
      required String? id,
      required String label,
      required IconData icon,
    }) {
      if (id == null || id.isEmpty) return;
      if (rows.isNotEmpty) {
        rows.add(const Divider(height: 20));
      }
      rows.add(_buildInfoRow(icon: icon, label: label, value: id));
    }

    if (userInfo != null) {
      addItem(
        id: userInfo.wechatUserId,
        label: '微信',
        icon: CupertinoIcons.chat_bubble_text,
      );
      addItem(
        id: userInfo.telegramUserId,
        label: 'Telegram',
        icon: CupertinoIcons.paperplane,
      );
      addItem(
        id: userInfo.slackUserId,
        label: 'Slack',
        icon: CupertinoIcons.bubble_right,
      );
      addItem(
        id: userInfo.discordUserId,
        label: 'Discord',
        icon: CupertinoIcons.person_2,
      );
      addItem(
        id: userInfo.vocechatUserId,
        label: 'VoceChat',
        icon: CupertinoIcons.chat_bubble,
      );
      addItem(
        id: userInfo.synologyChatUserId,
        label: 'Synology Chat',
        icon: CupertinoIcons.bubble_left_bubble_right,
      );
      addItem(
        id: userInfo.doubanUserId,
        label: '豆瓣',
        icon: CupertinoIcons.book,
      );
    }

    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '第三方账户',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const SizedBox(
              width: double.infinity,
              child: Text(
                '暂无配置的第三方账户',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            )
          else
            Column(children: rows),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: CupertinoColors.systemGrey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              if (value.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(vertical: 12),
        borderRadius: BorderRadius.circular(12),
        color: CupertinoColors.systemRed,
        onPressed: () async {
          final confirmed =
              await showCupertinoDialog<bool>(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: const Text('确认退出登录'),
                  content: const Text('退出后需要重新输入账号密码才能再次登录。'),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('取消'),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('退出登录'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (confirmed) {
            await controller.logout();
          }
        },
        child: const Text(
          '退出登录',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSwitchAccountButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAccountSwitcher(context),
        icon: const Icon(Icons.switch_account_rounded),
        label: const Text('切换账号'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showAccountSwitcher(BuildContext context) async {
    try {
      await controller.loadAvailableProfiles();
    } catch (_) {
      ToastUtil.error('加载已保存账号失败，请稍后重试');
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) => Material(
        color: Theme.of(sheetContext).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.76,
          ),
          child: Obx(() {
            final profiles = controller.availableProfiles;
            final colorScheme = Theme.of(sheetContext).colorScheme;
            return Column(
              children: [
                _buildSheetHandle(colorScheme),
                _buildAccountSheetHeader(sheetContext),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: profiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final profile = profiles[index];
                      final selected =
                          profile.id == controller.currentProfile.value?.id;
                      return _buildAccountOption(
                        sheetContext,
                        profile,
                        selected,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSheetHandle(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildAccountSheetHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.switch_account_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '切换账号',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '服务器地址会随账号一起切换',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '关闭',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption(
    BuildContext context,
    LoginProfile profile,
    bool selected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = profile.username.trim().isEmpty ? '未命名账号' : profile.username;
    final server = profile.server.trim().isEmpty ? '未设置服务器' : profile.server;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title，服务器 $server${selected ? '，当前账号' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: selected
              ? null
              : () async {
                  Navigator.of(context).pop();
                  ToastUtil.loading(message: '正在切换到 $title');
                  final success = await controller.switchAccount(profile);
                  ToastUtil.dismiss();
                  if (!success) {
                    ToastUtil.error('切换账号失败，请稍后重试');
                    return;
                  }
                  if (context.mounted) {
                    Get.offAllNamed('/main');
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.55)
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.75)
                    : colorScheme.outlineVariant.withValues(alpha: 0.7),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                _buildProfileInitial(context, title, selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 8),
                            _buildCurrentBadge(context),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.dns_outlined,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              server,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: selected ? 25 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInitial(
    BuildContext context,
    String title,
    bool selected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: selected
              ? [colorScheme.primary, colorScheme.tertiary]
              : [colorScheme.secondaryContainer, colorScheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        title.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: selected
              ? colorScheme.onPrimary
              : colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildCurrentBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '当前',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return _buildDefaultAvatar();
    }

    try {
      String base64String = avatar;
      if (base64String.startsWith('data:image')) {
        final commaIndex = base64String.indexOf(',');
        if (commaIndex != -1) {
          base64String = base64String.substring(commaIndex + 1);
        }
      }
      final bytes = base64Decode(base64String);
      if (bytes.isEmpty) {
        return _buildDefaultAvatar();
      }
      return CircleAvatar(
        radius: 32,
        backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
      );
    } catch (_) {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return ClipOval(
      child: Assets.images.avatars.avatar1.image(
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
    );
  }
}
