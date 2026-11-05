import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/controllers/app_setting_controller.dart';
import 'package:moviepilot_mobile/models/app_icon_option.dart';
import 'package:moviepilot_mobile/theme/section.dart';
import 'package:moviepilot_mobile/widgets/section_header.dart';

/// 预设主题色
const _presetColors = [
  (Color(0xFF007AFF), 'iOS 蓝'),
  (Color(0xFF34C759), '绿色'),
  (Color(0xFFAF52DE), '紫色'),
  (Color(0xFFFF9500), '橙色'),
  (Color(0xFFFF3B30), '红色'),
  (Color(0xFF00BCD4), '青色'),
  (Color(0xFFE91E63), '粉色'),
  (Color(0xFF3F51B5), '靛蓝'),
];

class AppThemeSettingPage extends GetView<AppSettingController> {
  const AppThemeSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('主题设置'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Section(
              header: SectionHeader(title: '主题模式'),
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              separatorBuilder: (context) => Divider(
                height: 0.1,
                color: Theme.of(context).dividerColor,
                endIndent: 16,
                indent: 16,
              ),
              children: [ThemeMode.system, ThemeMode.light, ThemeMode.dark]
                  .map(
                    (mode) => _buildThemeMode(context, mode, () {
                      controller.updateThemeMode(mode);
                    }),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            _buildAppIconSection(context),
            const SizedBox(height: 24),
            Section(
              header: SectionHeader(title: '主题色'),
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              separatorBuilder: (context) => Divider(
                height: 0.1,
                color: Theme.of(context).dividerColor,
                endIndent: 16,
                indent: 16,
              ),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _presetColors.map((e) {
                        final (color, label) = e;
                        final isSelected = _colorEquals(
                          color,
                          controller.primaryColor.value,
                        );
                        return GestureDetector(
                          onTap: () => controller.updatePrimaryColor(color),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          width: 3,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIconSection(BuildContext context) {
    return Section(
      header: const SectionHeader(title: '应用图标'),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final selectedId = controller.selectedAppIconId.value;
        final isChanging = controller.isChangingAppIcon.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width < 330
                ? 3
                : width >= 520
                ? 5
                : 4;
            final itemWidth = (width - 10 * (columns - 1)) / columns;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: appIconOptions
                  .map(
                    (option) => SizedBox(
                      width: itemWidth,
                      child: _buildAppIconOption(
                        context,
                        option,
                        selectedId: selectedId,
                        isChanging: isChanging,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        );
      }),
    );
  }

  Widget _buildAppIconOption(
    BuildContext context,
    AppIconOption option, {
    required String selectedId,
    required bool isChanging,
  }) {
    final selected = selectedId == option.id;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disabled = isChanging && !selected;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: disabled ? 0.52 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isChanging ? null : () => controller.updateAppIcon(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected
                  ? option.previewColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? option.previewColor.withValues(alpha: 0.7)
                    : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: option.previewColor.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: scheme.surface,
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.26,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 9,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                option.assetPath,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            width: 23,
                            height: 23,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.cardColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      if (isChanging && selected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  option.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? scheme.onSurface : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected ? '使用中' : option.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? option.previewColor
                        : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _colorEquals(Color a, Color b) =>
      (a.r * 255).round() == (b.r * 255).round() &&
      (a.g * 255).round() == (b.g * 255).round() &&
      (a.b * 255).round() == (b.b * 255).round();

  String _themeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  Widget _buildThemeMode(
    BuildContext context,
    ThemeMode themeMode,
    VoidCallback onTap,
  ) {
    final color = Theme.of(context).primaryColor;
    return ListTile(
      // leading: Icon(_themeModeIcon(themeMode), size: 24),
      title: Text(
        _themeModeName(themeMode),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
      trailing: themeMode == controller.themeMode.value
          ? Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.check, color: Colors.white, size: 15),
            )
          : null,
      onTap: onTap,
    );
  }
}
