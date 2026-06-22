import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';

/// MoviePilot Web 前端通用 JSON/Vuetify 渲染链路中，移动端当前聚焦支持的组件子集。
///
/// 这不是 Vuetify 的全量映射，而是围绕通用插件页真实高频结构收敛出的子集：
/// - 容器布局：VCard / VRow / VCol / VTabs / VTab / VDivider
/// - 展示组件：VAlert / VChip / VImg / VTable / VApexChart / VExpansionPanels
/// - 表单组件：VSwitch / VTextField / VTextarea / VSelect / cron
/// - 基础节点：div / span / h1~h3 / table tags
class VuetifyComponentSubset {
  VuetifyComponentSubset._();

  static const Set<String> rawRenderableComponents = {
    'style',
    'VCard',
    'VCardText',
    'VCardTitle',
    'VCardItem',
    'VCardSubtitle',
    'VRow',
    'VCol',
    'VIcon',
    'VBtn',
    'VAlert',
    'VChip',
    'VImg',
    'VTable',
    'VApexChart',
    'VTabs',
    'VTab',
    'VExpansionPanels',
    'VExpansionPanel',
    'VExpansionPanelTitle',
    'VExpansionPanelText',
    'VSpacer',
    'VForm',
    'VSwitch',
    'VTextField',
    'VTextarea',
    'VSelect',
    'VDivider',
    'div',
    'span',
    'thead',
    'tbody',
    'tr',
    'th',
    'td',
  };

  static const Set<String> formFieldComponents = {
    'VSwitch',
    'VTextField',
    'VTextarea',
    'VSelect',
  };

  static bool isStyle(String component) => component == 'style';

  static bool isHeading(String component) =>
      component == 'h1' || component == 'h2' || component == 'h3';

  static bool isCronLike(String component) =>
      component == 'cron' || component.toLowerCase().contains('cron');

  static bool isFormField(String component) =>
      formFieldComponents.contains(component) || isCronLike(component);

  static bool supportsRawComponent(String component) =>
      rawRenderableComponents.contains(component) ||
      isHeading(component) ||
      isCronLike(component);

  static List<String> collectUnsupportedRawComponents(List<FormNode> nodes) {
    final unsupported = <String>{};

    void visit(FormNode node) {
      final component = node.component.trim();
      if (component.isNotEmpty && !supportsRawComponent(component)) {
        unsupported.add(component);
      }
      for (final child in node.content) {
        visit(child);
      }
    }

    for (final node in nodes) {
      visit(node);
    }

    return unsupported.toList()..sort();
  }
}
