import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/gen/assets.gen.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:moviepilot_mobile/modules/user_management/controllers/user_management_controller.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/widgets/app_glass_card.dart';

class UserManagementItemCard extends StatelessWidget {
  const UserManagementItemCard({
    super.key,
    required this.user,
    required this.stats,
    this.onEdit,
    this.onDelete,
  });

  final UserInfo user;
  final UserSubscribeStats? stats;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final title = user.displayTitle;
    final username = user.usernameLabel;
    final hasNickname = title != username;

    return AppGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      accentColor: primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildAvatar(user.avatar),
                  if (user.isSuperuser)
                    Positioned(top: -4, left: -4, child: _buildAdminBadge()),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (hasNickname)
                          Text(
                            '@$username',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Spacer(),
                        if (onDelete != null && !user.isSuperuser)
                          GestureDetector(
                            onTap: onDelete,
                            child: Icon(
                              CupertinoIcons.delete_solid,
                              size: 18,
                              color: CupertinoColors.systemRed,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (user.isSuperuser)
                          _buildAdminChip()
                        else
                          _buildChip('普通用户', CupertinoColors.systemGrey),
                        if (user.isActive)
                          _buildChip('激活', AppTheme.successColor)
                        else
                          _buildChip('已停用', CupertinoColors.systemGrey),
                        if (user.isOtp)
                          _buildChip('2FA', CupertinoColors.activeBlue),
                      ],
                    ),
                    if (stats != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.film, size: 15, color: primary),
                            const SizedBox(width: 4),
                            Text(
                              '${stats!.movieCount}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(CupertinoIcons.tv, size: 15, color: primary),
                            const SizedBox(width: 4),
                            Text(
                              '${stats!.tvCount}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (user.email.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(CupertinoIcons.envelope, size: 16, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: CupertinoColors.systemGrey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
        radius: 28,
        backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
      );
    } catch (_) {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return ClipOval(
      child: Assets.images.avatars.avatar1.image(
        width: 56,
        height: 56,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildAdminBadge() {
    const gold = Color(0xFFFFB020);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1B8), Color(0xFFFFB020)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        CupertinoIcons.star_fill,
        size: 12,
        color: Color(0xFF6B3A00),
      ),
    );
  }

  Widget _buildAdminChip() {
    const gold = Color(0xFFFFB020);
    const ink = Color(0xFF7A4300);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFE8A3).withValues(alpha: 0.38),
            gold.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: gold.withValues(alpha: 0.34), width: 0.7),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(CupertinoIcons.star_fill, size: 11, color: ink),
          SizedBox(width: 4),
          Text(
            '管理员',
            style: TextStyle(
              fontSize: 12,
              color: ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
