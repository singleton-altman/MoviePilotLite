import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/multifunction/controllers/multifunction_controller.dart';
import 'package:moviepilot_mobile/modules/multifunction/models/multifunction_models.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';

/// 多功能页（More）：按 section 展示功能入口。
///
/// 每个 section 有两种布局：
/// - [MultifunctionSectionLayout.grouped]：分组列表，单列垂直堆叠，每行「图标 + 标题/副标题 + meta/右箭头」
/// - [MultifunctionSectionLayout.mosaic]：网格/卡片，按 [MultifunctionCardStyle] 决定每张卡样式与宽度
class MultifunctionPage extends GetView<MultifunctionController> {
  const MultifunctionPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildNavigationBar(context),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          for (final section in controller.sections)
            SliverToBoxAdapter(child: _buildSection(context, section)),
          SliverToBoxAdapter(child: SizedBox(height: _bottomSpacer(context))),
        ],
      ),
    );
  }

  double _bottomSpacer(BuildContext context) {
    return 100;
  }

  AppBar _buildNavigationBar(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.grid_view_rounded, color: context.primaryColor),
      ),
      title: const Text(
        'More',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(Icons.settings_outlined),
          onPressed: () => Get.toNamed('/settings'),
        ),
      ],
    );
  }

  /// 构建单个 section：上方标题 + 下方内容。
  /// grouped 时用 [_buildGroupedSection]，否则用 Wrap 布局各卡片，宽度由 [_itemWidth] 决定。
  Widget _buildSection(BuildContext context, MultifunctionSection section) {
    final theme = Theme.of(context);
    final isGrouped = section.layout == MultifunctionSectionLayout.grouped;
    final accent = _sectionAccent(context, section);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        12,
        _horizontalPadding,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionIcon(section, accent),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isGrouped)
            _buildGroupedSection(context, section)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final fullWidth = constraints.maxWidth;
                final halfWidth = (fullWidth - _cardSpacing) / 2;
                return Wrap(
                  spacing: _cardSpacing,
                  runSpacing: _cardSpacing,
                  children: [
                    for (final item in section.items)
                      SizedBox(
                        width: _itemWidth(item.style, fullWidth, halfWidth),
                        child: _buildItemCard(context, item),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionIcon(MultifunctionSection section, Color accent) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_sectionIconData(section.title), size: 16, color: accent),
    );
  }

  Color _sectionAccent(BuildContext context, MultifunctionSection section) {
    if (section.items.isNotEmpty) {
      return section.items.first.accent;
    }
    return Theme.of(context).colorScheme.primary;
  }

  IconData _sectionIconData(String title) {
    switch (title) {
      case '开始':
        return Icons.bolt_outlined;
      case '订阅':
        return Icons.subscriptions_outlined;
      case '整理':
        return Icons.auto_awesome_mosaic_outlined;
      case '系统':
        return Icons.settings_suggest_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  /// 分组列表样式：圆角边框卡片，内部多行，行间 Divider。
  /// 每行由 [_buildGroupedRow] 生成，样式：左图标气泡 + 标题/副标题 + 右 meta + 右箭头。
  Widget _buildGroupedSection(
    BuildContext context,
    MultifunctionSection section,
  ) {
    final borderRadius = BorderRadius.circular(18);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: AppTheme.borderColor.withOpacity(0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int index = 0; index < section.items.length; index++) ...[
            _buildGroupedRow(
              context,
              section.items[index],
              isFirst: index == 0,
              isLast: index == section.items.length - 1,
            ),
            if (index != section.items.length - 1)
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.4)),
          ],
        ],
      ),
    );
  }

  /// 分组行：水平布局 [图标 38x38] [标题/副标题] [meta?] [右箭头]，点击跳转。
  Widget _buildGroupedRow(
    BuildContext context,
    MultifunctionItem item, {
    required bool isFirst,
    required bool isLast,
  }) {
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(18) : Radius.zero,
      bottom: isLast ? const Radius.circular(18) : Radius.zero,
    );
    final accent = item.accent;
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: () => controller.handleTap(item),
      borderRadius: radius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildIconBubble(accent, item.icon, size: 38),
            SizedBox(width: screenWidth < 400 ? 5 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.subtitle != null)
                    Text(item.subtitle!, style: _secondaryTextStyle(context)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.meta != null)
                  Text(
                    item.meta!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (item.meta != null) const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 按样式返回卡片宽度：hero/wide 全宽，tall/compact 半宽（可并排 2 个）。
  double _itemWidth(
    MultifunctionCardStyle style,
    double fullWidth,
    double halfWidth,
  ) {
    switch (style) {
      case MultifunctionCardStyle.hero:
      case MultifunctionCardStyle.wide:
        return fullWidth;
      case MultifunctionCardStyle.tall:
      case MultifunctionCardStyle.compact:
        return halfWidth;
    }
  }

  /// 根据 item.style 分发到对应卡片构建方法。
  Widget _buildItemCard(BuildContext context, MultifunctionItem item) {
    switch (item.style) {
      case MultifunctionCardStyle.hero:
        return _buildHeroCard(context, item);
      case MultifunctionCardStyle.tall:
        return _buildTallCard(context, item);
      case MultifunctionCardStyle.compact:
        return _buildCompactCard(context, item);
      case MultifunctionCardStyle.wide:
        return _buildWideCard(context, item);
    }
  }

  /// hero：全宽，高 100，渐变背景 + 光晕，横向 [大图标 50] [标题/副标题] [meta 芯片?] [右箭头]。
  /// 例：搜索结果
  Widget _buildHeroCard(BuildContext context, MultifunctionItem item) {
    final accent = item.accent;
    final gradient = LinearGradient(
      colors: [accent.withOpacity(0.18), accent.withOpacity(0.04)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return _buildCardShell(
      context,
      item,
      height: 100,
      gradient: gradient,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -18,
            child: _buildGlowCircle(accent.withOpacity(0.18), 72),
          ),
          Positioned(
            right: 20,
            bottom: -22,
            child: _buildGlowCircle(accent.withOpacity(0.12), 54),
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 16),
                _buildIconBubble(accent, item.icon, size: 50),
                const SizedBox(width: 12),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (item.subtitle != null)
                  Text(item.subtitle!, style: _secondaryTextStyle(context)),
                if (item.meta != null) ...[
                  const SizedBox(height: 12),
                  _buildMetaChip(context, item.meta!, accent),
                ],
                Spacer(),
                Icon(Icons.chevron_right, color: accent),
                SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// tall：半宽，高 170，纵向 [图标 44] [Spacer] [标题] [副标题] [badge?]，右下光晕。
  /// 例：电影订阅、电视剧订阅（可并排）
  Widget _buildTallCard(BuildContext context, MultifunctionItem item) {
    final accent = item.accent;
    return _buildCardShell(
      context,
      item,
      height: 170,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -16,
            child: _buildGlowCircle(accent.withOpacity(0.12), 70),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconBubble(accent, item.icon, size: 44),
                const Spacer(),
                Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                if (item.subtitle != null)
                  Text(item.subtitle!, style: _secondaryTextStyle(context)),
                if (item.badge != null) ...[
                  const SizedBox(height: 10),
                  _buildBadge(context, item.badge!, accent),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// compact：半宽，高 88，横向 [图标 38] [标题/副标题] [meta 芯片 或 右箭头]。
  /// 例：工作流、订阅日历（可并排）
  Widget _buildCompactCard(BuildContext context, MultifunctionItem item) {
    final accent = item.accent;
    return _buildCardShell(
      context,
      item,
      height: 88,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _buildIconBubble(accent, item.icon, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.subtitle != null)
                    Text(item.subtitle!, style: _secondaryTextStyle(context)),
                ],
              ),
            ),
            if (item.meta != null)
              _buildMetaChip(context, item.meta!, accent)
            else
              Icon(Icons.chevron_right, color: accent),
          ],
        ),
      ),
    );
  }

  /// wide：全宽，高 100，横向 [图标 44] [标题/副标题/meta] [右侧迷你柱状图]。
  /// 例：下载管理、媒体整理
  Widget _buildWideCard(BuildContext context, MultifunctionItem item) {
    final accent = item.accent;
    return _buildCardShell(
      context,
      item,
      height: 80,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          children: [
            _buildIconBubble(accent, item.icon, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (item.subtitle != null)
                    Text(item.subtitle!, style: _secondaryTextStyle(context)),
                  if (item.meta != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.meta!,
                      style: _secondaryTextStyle(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            _buildMiniBars(accent),
          ],
        ),
      ),
    );
  }

  /// 卡片外壳：固定高度、圆角、主题色底，内嵌 child，点击跳转。
  Widget _buildCardShell(
    BuildContext context,
    MultifunctionItem item, {
    required double height,
    required Widget child,
    Gradient? gradient,
  }) {
    final borderRadius = BorderRadius.circular(18);
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: InkWell(
        onTap: () => controller.handleTap(item),
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.cardColor,
            gradient: gradient,
            borderRadius: borderRadius,
          ),
          child: ClipRRect(borderRadius: borderRadius, child: child),
        ),
      ),
    );
  }

  TextStyle _secondaryTextStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return base?.copyWith(color: context.textSecondaryColor) ??
        TextStyle(color: context.textSecondaryColor, fontSize: 13);
  }

  /// 图标气泡：圆角方形容器，accent 色底 + 图标。
  Widget _buildIconBubble(Color accent, IconData icon, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.16),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Icon(icon, color: accent, size: size * 0.55),
    );
  }

  /// 徽标：accent 色背景的小标签，用于 tall 卡片。
  Widget _buildBadge(BuildContext context, String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// meta 芯片：右侧小标签（如「近期」），用于 hero / compact 卡片。
  Widget _buildMetaChip(BuildContext context, String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 迷你柱状图：3 条递减宽度的小横条，用于 wide 卡片右侧装饰。
  Widget _buildMiniBars(Color accent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMiniBar(accent, 28),
        const SizedBox(height: 6),
        _buildMiniBar(accent.withOpacity(0.6), 20),
        const SizedBox(height: 6),
        _buildMiniBar(accent.withOpacity(0.35), 14),
      ],
    );
  }

  Widget _buildMiniBar(Color color, double width) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  /// 光晕圆：用于 hero / tall 卡片背景装饰。
  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
