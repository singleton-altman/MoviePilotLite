import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';

/// AppBar 右上角操作项：用于 page 类型动态表单的「命令执行」
class AppBarActionItem {
  const AppBarActionItem({
    required this.type,
    required this.label,
    this.iconName,
    this.iconColor,
  });

  /// 操作类型标识，回调时回传给 adapter
  final String type;

  /// 展示文案
  final String label;

  /// 可选 MDI 图标名，如 mdi-refresh
  final String? iconName;

  /// 可选颜色 key，如 primary、error
  final String? iconColor;
}

/// 插件表单适配器接口：vue 模式插件需实现
abstract class PluginFormAdapter extends GetxController {
  String get pluginId;

  RxList<FormBlock> get blocks;

  RxList<FormNode> get pageNodes;

  Rx<Map<String, dynamic>> get formModel;

  RxBool get isLoading;

  RxnString get errorText;

  /// 行内操作（如容器启动/停止）的 loading 状态，无则返回 null
  RxBool? get actionLoading;

  /// 是否支持保存配置，默认 true
  bool get supportsSave => false;

  /// 是否在展示页显示右下角「编辑/设置」入口按钮，默认 true
  bool get supportsFormEntry => true;

  /// 展示页 AppBar 右上角操作列表，非 form 模式下展示为 PopupMenu，支持命令执行
  List<AppBarActionItem>? get actionList => null;

  /// 用户点击 AppBar actionList 中某一项时调用，[type] 为该项的 [AppBarActionItem.type]
  Future<void> onAppBarAction(String type) async {}

  Future<void> load();

  Future<bool> save();
}

/// 扩展接口：支持「立即清理」等立即执行能力的插件
abstract class PluginFormAdapterWithClean extends PluginFormAdapter {
  Future<Map<String, dynamic>?> triggerClean();

  Future<Map<String, dynamic>?> fetchCleanProgress();
}
