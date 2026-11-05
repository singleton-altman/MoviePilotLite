import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/profile/models/user_info.dart';
import 'package:moviepilot_mobile/modules/user_management/controllers/user_management_controller.dart';
import 'package:moviepilot_mobile/modules/user_management/widgets/user_management_item_card.dart';
import 'package:moviepilot_mobile/modules/search_result/widgets/sort_pull_down_widget.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';
import 'package:moviepilot_mobile/widgets/app_loading.dart';
import 'package:moviepilot_mobile/widgets/glass_search_floating_bar.dart';

class UserManagementPage extends GetView<UserManagementController> {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Get.back(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) {
          return const Center(child: AppLoading());
        }
        if (controller.errorText.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.errorText.value ?? '',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: controller.load,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }
        final users = controller.visibleItems;
        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: controller.load),
            if (users.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else
              SliverList.builder(
                itemBuilder: (context, index) {
                  if (index >= users.length) return const SizedBox.shrink();
                  final user = users[index];
                  final stats = controller.getStatsForUser(user.id);
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                      right: 16,
                      left: 16,
                    ),
                    child: UserManagementItemCard(
                      user: user,
                      stats: stats,
                      onDelete: () => _onDeleteUser(user),
                    ),
                  );
                },
                itemCount: users.length,
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    GlassSearchFloatingBar.height +
                    52 +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOverview(BuildContext context, List<UserInfo> visibleUsers) {
    final theme = Theme.of(context);
    final total = controller.items.length;
    final active = controller.items.where((u) => u.isActive).length;
    final admin = controller.items.where((u) => u.isSuperuser).length;
    final subtitle =
        controller.searchKeyword.value.isEmpty && !controller.hasActiveFilters
        ? '共 $total 位用户'
        : '显示 ${visibleUsers.length} / $total 位用户';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.person_2_fill,
            color: theme.colorScheme.primary,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '账户中心',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _buildMetric(context, '$active', '激活'),
          const SizedBox(width: 10),
          _buildMetric(context, '$admin', '管理员'),
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 58,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_crop_circle,
            size: 44,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.66),
          ),
          const SizedBox(height: 12),
          Text(
            '没有匹配的用户',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '调整搜索关键词或筛选条件后再试',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBar(BuildContext context) {
    return Obx(
      () => GlassSearchFloatingBar(
        keyword: controller.searchKeyword.value,
        searchPlaceholder: '搜索用户名、昵称、邮箱…',
        onKeywordSubmitted: controller.updateKeyword,
        leading: _buildFloatingFilterButton(context),
        trailing: _buildFloatingSortButton(context),
      ),
    );
  }

  Widget _buildFloatingFilterButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Obx(() {
      final active = controller.hasActiveFilters;
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () => _openFilterSheet(context),
        child: Icon(
          CupertinoIcons.slider_horizontal_3,
          size: 20,
          color: active
              ? theme.colorScheme.primary
              : (isDark ? Colors.white : theme.colorScheme.onSurface),
        ),
      );
    });
  }

  Widget _buildFloatingSortButton(BuildContext context) {
    return Obx(
      () => SortPullDownWidget<UserManagementSortKey>(
        isAscending: controller.sortAscending.value,
        currentValue: controller.sortKey.value,
        options: UserManagementSortKey.values,
        labelBuilder: _sortLabel,
        onDirectionChanged: controller.updateSortDirection,
        onValueChanged: controller.updateSortKey,
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '筛选用户',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(34, 34),
                        onPressed: controller.clearFilters,
                        child: const Text('重置'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFilterSection<UserManagementStatusFilter>(
                    context,
                    title: '状态',
                    current: controller.statusFilter.value,
                    values: UserManagementStatusFilter.values,
                    labelBuilder: _statusLabel,
                    onChanged: controller.updateStatusFilter,
                  ),
                  _buildFilterSection<UserManagementRoleFilter>(
                    context,
                    title: '角色',
                    current: controller.roleFilter.value,
                    values: UserManagementRoleFilter.values,
                    labelBuilder: _roleLabel,
                    onChanged: controller.updateRoleFilter,
                  ),
                  _buildFilterSection<UserManagementOtpFilter>(
                    context,
                    title: '两步验证',
                    current: controller.otpFilter.value,
                    values: UserManagementOtpFilter.values,
                    labelBuilder: _otpLabel,
                    onChanged: controller.updateOtpFilter,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSection<T>(
    BuildContext context, {
    required String title,
    required T current,
    required List<T> values,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (value) => _buildFilterOption<T>(
                    context,
                    value: value,
                    current: current,
                    label: labelBuilder(value),
                    onChanged: onChanged,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption<T>(
    BuildContext context, {
    required T value,
    required T current,
    required String label,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);
    final selected = value == current;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.16)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.42 : 0.62,
                ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.42)
                : theme.colorScheme.outline.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? theme.colorScheme.primary : null,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static String _sortLabel(UserManagementSortKey key) {
    switch (key) {
      case UserManagementSortKey.username:
        return '用户名';
      case UserManagementSortKey.email:
        return '邮箱';
      case UserManagementSortKey.role:
        return '角色';
      case UserManagementSortKey.subscribe:
        return '订阅';
    }
  }

  static String _statusLabel(UserManagementStatusFilter value) {
    switch (value) {
      case UserManagementStatusFilter.all:
        return '全部';
      case UserManagementStatusFilter.active:
        return '已激活';
      case UserManagementStatusFilter.inactive:
        return '已停用';
    }
  }

  static String _roleLabel(UserManagementRoleFilter value) {
    switch (value) {
      case UserManagementRoleFilter.all:
        return '全部';
      case UserManagementRoleFilter.admin:
        return '管理员';
      case UserManagementRoleFilter.user:
        return '普通用户';
    }
  }

  static String _otpLabel(UserManagementOtpFilter value) {
    switch (value) {
      case UserManagementOtpFilter.all:
        return '全部';
      case UserManagementOtpFilter.enabled:
        return '已开启';
      case UserManagementOtpFilter.disabled:
        return '未开启';
    }
  }

  void _onDeleteUser(UserInfo user) {
    ToastUtil.warning(
      '删除用户 ${user.usernameLabel}?',
      onConfirm: () {
        controller.deleteUser(user.id);
      },
    );
  }
}
