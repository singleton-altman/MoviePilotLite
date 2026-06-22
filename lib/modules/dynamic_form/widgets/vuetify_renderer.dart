import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/controllers/dynamic_form_controller.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_actions.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_component_subset.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_css.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_display_support.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_form_parser.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_layout_support.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_text_support.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/vuetify_display_widgets.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/vuetify_form_fields.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/vuetify_layout_widgets.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/vuetify_text_widgets.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/chart_widget.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/widgets/vuetify_primitives.dart';

/// 通用 Vuetify 组件树渲染器：将 FormNode 递归转换为 iOS 原生风格的 Flutter Widget。
class VuetifyPageRenderer extends StatelessWidget {
  const VuetifyPageRenderer({
    super.key,
    required this.nodes,
    required this.controller,
  });

  final List<FormNode> nodes;
  final DynamicFormController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        if (node.component == 'style') return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: index < nodes.length - 1 ? 12 : 0),
          child: _VuetifyNode(node: node, controller: controller),
        );
      },
    );
  }
}

class _VuetifyNode extends StatelessWidget {
  const _VuetifyNode({
    required this.node,
    this.controller,
    this.parentWidth,
    this.siblingCount,
    this.ctx = const VuetifyRenderContext(),
  });

  final FormNode node;
  final DynamicFormController? controller;
  final double? parentWidth;

  /// Number of sibling VCol elements in the parent VRow (for auto-sizing).
  final int? siblingCount;
  final VuetifyRenderContext ctx;

  Map<String, Widget Function(BuildContext)> get _builders => {
    'style': (_) => const SizedBox.shrink(),
    'VCard': _buildVCard,
    'VCardText': _buildVCardText,
    'VCardTitle': _buildVCardTitle,
    'VCardItem': _buildChildren,
    'VCardSubtitle': (context) => _buildTextNode(
      context,
      defaultStyle: TextStyle(
        fontSize: 13,
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.secondaryLabel,
          context,
        ),
      ),
    ),
    'VRow': _buildVRow,
    'VCol': _buildVCol,
    'VIcon': _buildVIcon,
    'VBtn': _buildVBtn,
    'VAlert': _buildVAlert,
    'VChip': _buildVChip,
    'VImg': _buildVImg,
    'VTable': _buildVTable,
    'VApexChart': _buildVApexChart,
    'VTabs': _buildVTabs,
    'VTab': _buildVTab,
    'VExpansionPanels': _buildVExpansionPanels,
    'VExpansionPanel': _buildVExpansionPanel,
    'div': _buildDiv,
    'span': _buildSpan,
    'VSpacer': (_) => const SizedBox.shrink(),
    'VForm': _buildChildren,
    'VSwitch': _buildVSwitch,
    'VTextField': _buildVTextField,
    'VTextarea': _buildVTextarea,
    'VSelect': _buildVSelect,
    'cron': _buildCron,
    'VDivider': (_) => const Divider(height: 1),
    'VExpansionPanelTitle': _buildChildren,
    'VExpansionPanelText': _buildChildren,
    'thead': _buildChildren,
    'tbody': _buildChildren,
    'tr': _buildChildren,
    'th': _buildChildren,
    'td': _buildChildren,
  };

  @override
  Widget build(BuildContext context) {
    final builder = _builders[node.component];
    if (builder != null) {
      return builder(context);
    }
    if (VuetifyComponentSubset.isHeading(node.component)) {
      return _buildHeading(context);
    }
    if (VuetifyComponentSubset.isCronLike(node.component)) {
      return _buildCron(context);
    }
    return _buildDefault(context);
  }

  // ---------------------------------------------------------------------------
  // VCard
  // ---------------------------------------------------------------------------

  Widget _buildVCard(BuildContext context) {
    final variant = node.props?['variant']?.toString() ?? '';
    final colorName = node.props?['color']?.toString();
    final color = VuetifyCss.resolveColor(colorName);

    // Tonal stat-card pattern detection:
    // VCard[tonal,color] > VCardText > [VIcon, div(value), div(label)]
    if (variant == 'tonal' && color != null) {
      final statCardSpec = VuetifyDisplaySupport.resolveTonalStatCardSpec(
        node,
        color,
      );
      if (statCardSpec != null) {
        final margin = VuetifyLayoutSupport.resolveCardSpec(
          context,
          node,
          ctx,
        ).margin;
        return Padding(
          padding: margin,
          child: VuetifyTonalStatCard(
            color: statCardSpec.color,
            iconData: statCardSpec.iconData,
            value: statCardSpec.value,
            label: statCardSpec.label,
          ),
        );
      }
    }
    final spec = VuetifyLayoutSupport.resolveCardSpec(context, node, ctx);
    return VuetifyCardView(
      spec: spec,
      child: _buildChildColumn(context, spec.childContext),
    );
  }

  // ---------------------------------------------------------------------------
  // VCardText / VCardTitle
  // ---------------------------------------------------------------------------

  Widget _buildVCardText(BuildContext context) {
    final spec = VuetifyLayoutSupport.resolveDivSpec(context, node, ctx);
    final effectivePadding = spec.padding == EdgeInsets.zero
        ? const EdgeInsets.all(12)
        : spec.padding;

    return Padding(
      padding: effectivePadding,
      child: _buildChildColumn(
        context,
        spec.childContext,
        crossAlignment: spec.isCenter ? CrossAxisAlignment.center : null,
      ),
    );
  }

  Widget _buildVCardTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: _buildTextNode(
        context,
        defaultStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VRow — Wrap layout
  // ---------------------------------------------------------------------------

  Widget _buildVRow(BuildContext context) {
    final spec = VuetifyLayoutSupport.resolveRowSpec(node);
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        return VuetifyWrapRowView(
          spec: spec,
          children: node.content.map((child) {
            return _VuetifyNode(
              node: child,
              controller: controller,
              parentWidth: availableWidth,
              siblingCount: spec.colCount > 1 ? spec.colCount : null,
              ctx: ctx,
            );
          }).toList(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // VCol — sized by cols prop
  // ---------------------------------------------------------------------------

  Widget _buildVCol(BuildContext context) {
    final spec = VuetifyLayoutSupport.resolveColSpec(
      node: node,
      parentWidth: parentWidth,
      siblingCount: siblingCount,
      renderContext: ctx,
    );

    Widget child;
    if (node.content.length == 1) {
      child = _VuetifyNode(
        node: node.content.first,
        controller: controller,
        ctx: spec.childContext,
      );
    } else {
      child = _buildChildColumn(
        context,
        spec.childContext,
        crossAlignment: spec.center ? CrossAxisAlignment.center : null,
      );
    }

    return VuetifyColView(spec: spec, child: child);
  }

  // ---------------------------------------------------------------------------
  // VIcon — with optional color badge background
  // ---------------------------------------------------------------------------

  Widget _buildVIcon(BuildContext context) {
    final spec = VuetifyDisplaySupport.resolveIconSpec(
      context,
      node,
      inheritedColor: ctx.parentColor,
      insideTonalCard: ctx.insideTonalCard,
    );
    return VuetifyIconView(spec: spec);
  }

  // ---------------------------------------------------------------------------
  // VBtn — iOS-native button
  // ---------------------------------------------------------------------------

  Widget _buildVBtn(BuildContext context) {
    final spec = VuetifyDisplaySupport.resolveButtonSpec(context, node);
    final clickEvent = VuetifyActionExecutor.extractClickAction(node);
    return VuetifyButtonView(
      spec: spec,
      onPressed: clickEvent != null
          ? () => _executeClickAction(clickEvent)
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // VAlert
  // ---------------------------------------------------------------------------

  Widget _buildVAlert(BuildContext context) {
    final spec = VuetifyDisplaySupport.resolveAlertDisplaySpec(node);
    if (spec == null) return const SizedBox.shrink();
    final palette = VuetifyDisplaySupport.resolveAlertVisual(spec.type);
    return VuetifyAlertView(spec: spec, palette: palette);
  }

  // ---------------------------------------------------------------------------
  // VChip
  // ---------------------------------------------------------------------------

  Widget _buildVChip(BuildContext context) {
    final spec = VuetifyDisplaySupport.resolveChipSpec(node);
    return VuetifyChipView(spec: spec);
  }

  // ---------------------------------------------------------------------------
  // VImg
  // ---------------------------------------------------------------------------

  Widget _buildVImg(BuildContext context) {
    final spec = VuetifyDisplaySupport.resolveImageSpec(node);
    if (spec == null) return const SizedBox.shrink();
    return VuetifyImageView(spec: spec);
  }

  // ---------------------------------------------------------------------------
  // VApexChart
  // ---------------------------------------------------------------------------

  Widget _buildVApexChart(BuildContext context) {
    final spec = VuetifyFormParser.parseChart(node);
    if (spec == null) {
      return const SizedBox.shrink();
    }

    return ChartWidget(
      block: ChartBlock(
        title: spec.title,
        labels: spec.labels,
        series: spec.series,
        chartType: spec.chartType,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VTable
  // ---------------------------------------------------------------------------

  Widget _buildVTable(BuildContext context) {
    final spec = VuetifyDisplaySupport.resolveTableSpec(node);
    if (spec == null) return const SizedBox.shrink();
    return VuetifyTableView(spec: spec);
  }

  // ---------------------------------------------------------------------------
  // VTabs / VTab
  // ---------------------------------------------------------------------------

  Widget _buildVTabs(BuildContext context) {
    final spec = VuetifyDisplaySupport.resolveTabsSpec(node);
    if (spec == null || spec.items.isEmpty) return _buildChildren(context);
    return VuetifyTabsView(spec: spec, onTapTab: _handleNodeTap);
  }

  Widget _buildVTab(BuildContext context) => VuetifyTabsView(
    spec: VuetifyTabsSpec(
      items: [
        VuetifyTabItemSpec(
          node: node,
          label: VuetifyTextSupport.collectVisibleText(node),
          isSelected: false,
        ),
      ],
      grow: false,
    ),
    onTapTab: _handleNodeTap,
  );

  // ---------------------------------------------------------------------------
  // VExpansionPanels / VExpansionPanel
  // ---------------------------------------------------------------------------

  Widget _buildVExpansionPanels(BuildContext context) {
    return Column(
      children: node.content.map((child) {
        return _VuetifyNode(node: child, controller: controller, ctx: ctx);
      }).toList(),
    );
  }

  Widget _buildVExpansionPanel(BuildContext context) {
    FormNode? titleNode;
    FormNode? textNode;
    for (final c in node.content) {
      if (c.component == 'VExpansionPanelTitle') titleNode = c;
      if (c.component == 'VExpansionPanelText') textNode = c;
    }

    return VuetifyExpansionTile(
      titleNode: titleNode,
      textNode: textNode,
      controller: controller,
      buildNode: (child) =>
          _VuetifyNode(node: child, controller: controller, ctx: ctx),
      collectText: _collectNodeText,
    );
  }

  // ---------------------------------------------------------------------------
  // div / span — with proper text-center propagation & d-flex layout
  // ---------------------------------------------------------------------------

  Widget _buildDiv(BuildContext context) {
    final spec = VuetifyLayoutSupport.resolveDivSpec(context, node, ctx);
    final cls = node.props?['class']?.toString();

    if (VuetifyCss.isDashboardStats(cls)) {
      return _buildDashboardStatsSection(context, spec);
    }
    if (VuetifyCss.isDashboardStatsItem(cls)) {
      return _buildDashboardStatsItem(context, spec);
    }
    if (VuetifyCss.isDashboardStatsTitle(cls)) {
      return _buildDashboardStatsTitle(context, spec);
    }
    if (VuetifyCss.isDashboardStatsValue(cls)) {
      return _buildDashboardStatsValue(context, spec);
    }

    // Leaf div with text only
    if (node.text != null && node.content.isEmpty) {
      final text = node.text.toString().trim();
      if (text.isEmpty) return const SizedBox.shrink();
      return VuetifyTextView(
        text: text,
        style: spec.textStyle,
        padding: spec.margin + spec.padding,
        textAlign: spec.isCenter ? TextAlign.center : null,
      );
    }

    // d-flex → Row layout with Flexible children to prevent overflow
    if (spec.isDFlex) {
      return VuetifyFlexRowView(
        padding: spec.margin + spec.padding,
        mainAxisAlignment: spec.mainAxis,
        crossAxisAlignment: spec.crossAxis,
        children: node.content.map((c) {
          if (c.component == 'VSpacer') {
            return const Expanded(child: SizedBox.shrink());
          }
          return Flexible(
            child: _VuetifyNode(node: c, controller: controller, ctx: ctx),
          );
        }).toList(),
      );
    }

    // Default → Column
    Widget child;
    if (node.content.isNotEmpty) {
      child = VuetifyColumnView(
        crossAxisAlignment: spec.isCenter
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: node.content.map((c) {
          return _VuetifyNode(
            node: c,
            controller: controller,
            ctx: spec.childContext,
          );
        }).toList(),
      );
    } else {
      final text = node.text?.toString().trim() ?? '';
      child = text.isNotEmpty
          ? VuetifyTextView(
              text: text,
              style: spec.textStyle,
              textAlign: spec.isCenter ? TextAlign.center : null,
            )
          : const SizedBox.shrink();
    }

    if (spec.margin == EdgeInsets.zero && spec.padding == EdgeInsets.zero) {
      return child;
    }
    return Padding(padding: spec.margin + spec.padding, child: child);
  }

  Widget _buildDashboardStatsSection(BuildContext _, VuetifyDivSpec spec) {
    const spacing = 12.0;

    return Padding(
      padding: spec.margin + spec.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final columns = switch (maxWidth) {
            > 900 => 4,
            > 640 => 3,
            > 360 => 2,
            _ => 1,
          };
          final itemWidth = (maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: node.content.map((child) {
              return SizedBox(
                width: itemWidth,
                child: _VuetifyNode(
                  node: child,
                  controller: controller,
                  ctx: spec.childContext.copyWith(centerContent: true),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDashboardStatsItem(BuildContext context, VuetifyDivSpec spec) {
    return Container(
      padding: spec.padding == EdgeInsets.zero
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
          : spec.padding,
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.tertiarySystemGroupedBackground,
          context,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _buildChildColumn(
        context,
        spec.childContext.copyWith(centerContent: true),
        crossAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  Widget _buildDashboardStatsTitle(BuildContext context, VuetifyDivSpec spec) {
    final text = _collectNodeText(node);
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: spec.margin + const EdgeInsets.only(bottom: 8),
      child: VuetifyTextView(
        text: text,
        style: spec.textStyle.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color:
              VuetifyCss.resolveTextColorFromClasses(
                node.props?['class']?.toString(),
              ) ??
              CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDashboardStatsValue(BuildContext context, VuetifyDivSpec spec) {
    final text = _collectNodeText(node);
    if (text.isEmpty) return const SizedBox.shrink();

    return VuetifyTextView(
      text: text,
      style: spec.textStyle.copyWith(
        fontSize: 26,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color:
            VuetifyCss.resolveTextColorFromClasses(
              node.props?['class']?.toString(),
            ) ??
            CupertinoDynamicColor.resolve(CupertinoColors.label, context),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSpan(BuildContext context) {
    final text = node.text?.toString().trim() ?? _collectNodeText(node);
    if (text.isEmpty) return const SizedBox.shrink();
    final spec = VuetifyLayoutSupport.resolveSpanSpec(context, node, text);

    return VuetifyTextView(
      text: spec.text,
      style: spec.style,
      padding: spec.margin,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildHeading(BuildContext context) {
    final text = _collectNodeText(node);
    final spec = VuetifyLayoutSupport.resolveHeadingSpec(node, text);
    if (spec == null) return const SizedBox.shrink();
    return VuetifyHeadingView(spec: spec);
  }

  // ---------------------------------------------------------------------------
  // Form fields (VSwitch / VTextField / VTextarea / VSelect)
  // ---------------------------------------------------------------------------

  Widget _buildVSwitch(BuildContext context) {
    final spec = VuetifyFormParser.parseSwitch(node);
    if (spec == null) return const SizedBox.shrink();
    return VuetifySwitchField(spec: spec, controller: controller);
  }

  Widget _buildCron(BuildContext context) {
    final spec = VuetifyFormParser.parseCron(node);
    if (spec == null) return const SizedBox.shrink();
    return VuetifyCronField(spec: spec, controller: controller);
  }

  Widget _buildVTextField(BuildContext context) {
    final spec = VuetifyFormParser.parseTextField(node);
    if (spec == null) return const SizedBox.shrink();
    return VuetifyTextInputField(
      label: spec.label,
      hint: spec.hint,
      name: spec.name,
      controller: controller,
      maxLines: spec.maxLines,
    );
  }

  Widget _buildVTextarea(BuildContext context) {
    final spec = VuetifyFormParser.parseTextArea(node);
    if (spec == null) return const SizedBox.shrink();
    return VuetifyTextInputField(
      label: spec.label,
      hint: spec.hint,
      name: spec.name,
      controller: controller,
      maxLines: spec.maxLines,
    );
  }

  Widget _buildVSelect(BuildContext context) {
    final spec = VuetifyFormParser.parseSelect(node);
    if (spec == null || controller == null || spec.name == null) {
      return const SizedBox.shrink();
    }
    return VuetifySelectField(spec: spec, controller: controller!);
  }

  // ---------------------------------------------------------------------------
  // Default fallback
  // ---------------------------------------------------------------------------

  Widget _buildDefault(BuildContext context) {
    if (node.content.isEmpty) {
      final text = node.text?.toString().trim() ?? '';
      if (text.isEmpty) return const SizedBox.shrink();
      return VuetifyTextView(
        text: text,
        style: TextStyle(
          fontSize: 14,
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
        ),
      );
    }
    return _buildChildColumn(context, ctx);
  }

  Widget _buildChildren(BuildContext context) =>
      _buildChildColumn(context, ctx);

  Widget _buildChildColumn(
    BuildContext context,
    VuetifyRenderContext childCtx, {
    CrossAxisAlignment? crossAlignment,
  }) {
    final center =
        crossAlignment == CrossAxisAlignment.center || childCtx.centerContent;
    return VuetifyColumnView(
      expandWidth: center,
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : (crossAlignment ?? CrossAxisAlignment.start),
      children: node.content.map((child) {
        return _VuetifyNode(node: child, controller: controller, ctx: childCtx);
      }).toList(),
    );
  }

  Widget _buildTextNode(BuildContext context, {TextStyle? defaultStyle}) {
    final text = _collectNodeText(node);
    if (text.isNotEmpty) {
      return VuetifyTextView(
        text: text,
        style:
            defaultStyle ??
            TextStyle(
              fontSize: 14,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.label,
                context,
              ),
            ),
      );
    }
    return _buildChildColumn(context, ctx);
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  /// Collect visible text from a node tree, skipping VIcon nodes
  /// (whose text is an MDI icon name, not user-visible text).
  static String _collectNodeText(FormNode node) {
    return VuetifyTextSupport.collectVisibleText(node);
  }

  Future<void> _executeClickAction(VuetifyClickAction action) {
    return VuetifyActionExecutor.execute(
      action,
      onSuccessReload: controller?.load,
    );
  }

  void _handleNodeTap(FormNode tappedNode) {
    final clickEvent = VuetifyActionExecutor.extractClickAction(tappedNode);
    if (clickEvent != null) {
      _executeClickAction(clickEvent);
    }
  }
}
