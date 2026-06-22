import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/login/models/login_profile.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../controllers/profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

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
            _buildAvatar(userInfo?.avatar ?? profile.avatar),
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
          _buildInfoRow(
            icon: CupertinoIcons.lock_shield,
            label: '二步验证',
            value: (userInfo?.isOtp == true) ? '已开启' : '未开启',
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
