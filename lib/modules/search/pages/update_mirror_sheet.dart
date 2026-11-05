import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/search/models/update_mirror.dart';
import 'package:moviepilot_mobile/modules/search/services/update_mirror_store.dart';
import 'package:moviepilot_mobile/modules/search/widgets/update_mirror_list.dart';
import 'package:moviepilot_mobile/utils/toast_util.dart';

/// 打开自更新下载线路管理面板。
///
/// [sourceUrl] 为最新安装包的下载地址；为空时测速退回到仓库归档包。
Future<void> showUpdateMirrorSheet(
  BuildContext context, {
  String sourceUrl = '',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UpdateMirrorSheet(sourceUrl: sourceUrl),
  );
}

/// 自更新下载线路管理面板：完整的线路列表与自定义加速源维护。
///
/// 更新弹框内只做线路切换，自定义源的增删集中在这里。
class UpdateMirrorSheet extends StatefulWidget {
  const UpdateMirrorSheet({super.key, this.sourceUrl = ''});

  final String sourceUrl;

  @override
  State<UpdateMirrorSheet> createState() => _UpdateMirrorSheetState();
}

class _UpdateMirrorSheetState extends State<UpdateMirrorSheet> {
  late final UpdateMirrorStore _store = Get.find<UpdateMirrorStore>();
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SafeArea(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            shrinkWrap: true,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '更新下载线路',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.all(6),
                    onPressed: Get.back,
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '国内网络访问 GitHub 较慢时，可选择加速源。加速源失败会自动回退直连。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              UpdateMirrorList(sourceUrl: widget.sourceUrl),
              const SizedBox(height: 18),
              _buildAddCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '自定义加速源',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '支持前缀式（如 https://ghproxy.net/）或占位符式（如 https://x/{url}）。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'https://your-proxy.example/',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: colorScheme.primary,
              onPressed: _addCustom,
              child: Text(
                '保存并使用',
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCustom() async {
    final raw = _addController.text.trim();
    final error = UpdateMirror.validateTemplate(raw);
    if (error != null) {
      ToastUtil.error(error);
      return;
    }
    final normalized = UpdateMirror.normalizeTemplate(raw);
    if (normalized == null) {
      ToastUtil.error('地址格式不正确');
      return;
    }
    final duplicated = _store.allMirrors.any(
      (mirror) => !mirror.isDirect && mirror.template.trim() == normalized,
    );
    if (duplicated) {
      ToastUtil.info('该加速源已存在');
      return;
    }
    final added = await _store.addCustom(normalized);
    if (!mounted) return;
    if (added == null) {
      ToastUtil.error('保存失败，请稍后重试');
      return;
    }
    _addController.clear();
    ToastUtil.success('已添加并切换到 ${added.label}');
  }
}
