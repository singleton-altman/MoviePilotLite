import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/controllers/mirror_speed_controller.dart';
import 'package:moviepilot_mobile/modules/search/models/update_mirror.dart';
import 'package:moviepilot_mobile/modules/search/services/update_mirror_store.dart';
import 'package:moviepilot_mobile/modules/search/services/update_speed_tester.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 下载线路列表：展示线路、测速结果，并支持切换选择。
///
/// [compact] 为 true 时用于更新弹框内联展示，只列出线路与测速徽标；
/// 完整面板额外提供自定义源的新增与删除。
class UpdateMirrorList extends StatefulWidget {
  const UpdateMirrorList({
    super.key,
    this.sourceUrl = '',
    this.compact = false,
    this.onSelected,
  });

  /// 测速目标地址，为空时回退到仓库归档包。
  final String sourceUrl;

  final bool compact;

  /// 用户切换线路后的回调。
  final ValueChanged<UpdateMirror>? onSelected;

  @override
  State<UpdateMirrorList> createState() => _UpdateMirrorListState();
}

class _UpdateMirrorListState extends State<UpdateMirrorList> {
  late final UpdateMirrorStore _store = Get.find<UpdateMirrorStore>();
  late final MirrorSpeedController _speed = Get.isRegistered<MirrorSpeedController>()
      ? Get.find<MirrorSpeedController>()
      : Get.put(MirrorSpeedController(), permanent: true);

  String get _probeUrl =>
      widget.sourceUrl.trim().isEmpty
          ? UpdateSpeedTester.fallbackProbeUrl
          : widget.sourceUrl.trim();

  Future<void> _select(UpdateMirror mirror) async {
    await _store.select(mirror.id);
    widget.onSelected?.call(mirror);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mirrors = _store.allMirrors;
      final selectedId = _store.selectedId.value;
      final hint = _speed.fastestHint(mirrors, selectedId: selectedId);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpeedHeader(context, mirrors, hint),
          const SizedBox(height: 8),
          ...mirrors.map(
            (mirror) => _buildTile(
              context,
              mirror: mirror,
              selected: mirror.id == selectedId,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSpeedHeader(
    BuildContext context,
    List<UpdateMirror> mirrors,
    String? hint,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final busy = _speed.testingAll.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                busy ? '正在测速…' : '测速可帮你在当前网络下选出最快的线路',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              onPressed: busy
                  ? null
                  : () => _speed.testAll(mirrors, sourceUrl: _probeUrl),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy)
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: colorScheme.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.speed_rounded,
                      size: 15,
                      color: colorScheme.primary,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    '测速',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required UpdateMirror mirror,
    required bool selected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canDelete = !widget.compact && !mirror.builtin && !mirror.isDirect;
    return InkWell(
      onTap: () => _select(mirror),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: Row(
          children: [
            Icon(
              mirror.isDirect
                  ? Icons.link_rounded
                  : mirror.builtin
                  ? Icons.bolt_rounded
                  : Icons.tune_rounded,
              size: 19,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mirror.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (!mirror.isDirect && !widget.compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        mirror.template,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildSpeedBadge(context, mirror),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  size: 19,
                  color: colorScheme.primary,
                ),
              ),
            if (canDelete)
              CupertinoButton(
                minimumSize: Size.zero,
                padding: const EdgeInsets.only(left: 8),
                onPressed: () => _confirmDelete(context, mirror),
                child: Icon(
                  CupertinoIcons.delete,
                  size: 17,
                  color: colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedBadge(BuildContext context, UpdateMirror mirror) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final testing = _speed.isTesting(mirror.id);
    final result = _speed.resultFor(mirror.id);

    if (testing) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          color: colorScheme.primary,
        ),
      );
    }

    final Color foreground;
    final String text;
    if (result == null) {
      foreground = colorScheme.onSurfaceVariant;
      text = '测速';
    } else if (result.ok) {
      foreground = colorScheme.primary;
      text = result.displaySpeed;
    } else {
      foreground = colorScheme.error;
      text = result.error ?? '失败';
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _speed.testOne(mirror, sourceUrl: _probeUrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UpdateMirror mirror,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('删除加速源'),
        content: Text('确定删除「${mirror.label}」吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _store.removeCustom(mirror.id);
    }
  }
}
