import 'package:flutter/material.dart';

import 'package:moviepilot_mobile/modules/dynamic_form/adapters/plugin_form_adapter.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';

/// 插件适配器工厂：根据 formMode 创建 page 或 form 模式下的 adapter
typedef PluginFormAdapterFactory = PluginFormAdapter Function({
  required bool formMode,
});

/// 自定义渲染器：由插件注册，接收 blocks、controller、formMode、buildBlock 回调
typedef PluginFormRendererBuilder = Widget Function(
  BuildContext context,
  List<FormBlock> blocks,
  DynamicFormController controller,
  bool formMode,
  Widget Function(BuildContext context, FormBlock block) buildBlock,
);

/// 插件表单适配器注册表：pluginId -> 工厂方法 / 自定义渲染器
class PluginFormAdapterRegistry {
  PluginFormAdapterRegistry._();

  static final Map<String, PluginFormAdapterFactory> _factories = {};
  static final Map<String, PluginFormRendererBuilder> _renderers = {};

  /// 注册插件适配器
  static void register(String pluginId, PluginFormAdapterFactory factory) {
    _factories[pluginId] = factory;
  }

  /// 注册插件自定义渲染器（可选）
  static void registerRenderer(
    String pluginId,
    PluginFormRendererBuilder builder,
  ) {
    _renderers[pluginId] = builder;
  }

  /// 是否已注册该插件
  static bool hasAdapter(String pluginId) => _factories.containsKey(pluginId);

  /// 是否已注册自定义渲染器
  static bool hasCustomRenderer(String pluginId) =>
      _renderers.containsKey(pluginId);

  /// 获取自定义渲染器
  static PluginFormRendererBuilder? getCustomRenderer(String pluginId) =>
      _renderers[pluginId];

  /// 创建适配器实例（调用方负责 Get.put 等生命周期）
  static PluginFormAdapter? createAdapter(
    String pluginId, {
    required bool formMode,
  }) {
    final factory = _factories[pluginId];
    if (factory == null) return null;
    return factory(formMode: formMode);
  }
}
