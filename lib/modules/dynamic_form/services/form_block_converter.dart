import 'package:moviepilot_mobile/modules/dynamic_form/models/dynamic_form_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_component_subset.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_form_parser.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/utils/vuetify_mappings.dart';

/// 将 FormNode 树转换为移动端 FormBlock 列表，去除 Web/Vuetify 无用参数
class FormBlockConverter {
  static List<FormBlock> convert(DynamicFormResponse response) {
    final blocks = <FormBlock>[];
    final model = response.model;

    // 配置表单：conf + model（表单项 value 从 model[key] 取，key 为 props.model）
    if (response.conf.isNotEmpty) {
      final confRoots = response.conf;
      for (final root in confRoots) {
        final children = root.component == 'VForm' ? root.content : [root];
        for (final node in children) {
          _collectConfNodes(node, blocks, model);
        }
      }
      return blocks;
    }

    // 展示页：page（统计卡片、图表、表格、标题行、折叠卡片等）
    for (final pageNode in response.page) {
      if (VuetifyComponentSubset.isStyle(pageNode.component)) continue;
      if (pageNode.component == 'VAlert') {
        final alert = _extractAlert(pageNode);
        if (alert != null) blocks.add(alert);
        continue;
      }
      if (pageNode.component == 'div') {
        final cls = pageNode.props?['class']?.toString() ?? '';
        if (cls.contains('dashboard-stats')) {
          final statCards = _extractStatCardsFromDashboardStats(pageNode);
          for (final b in statCards) {
            blocks.add(b);
          }
          continue;
        }
      }
      // 兼容顶层 VCard
      if (pageNode.component == 'VCard') {
        // 站点信息卡片：VCardItem+VCardTitle + VRow(4 列邀请统计) + VAlert
        final siteCard = _extractSiteInfoCard(pageNode);
        if (siteCard != null) {
          blocks.add(siteCard);
          continue;
        }
        final expansion = _extractExpansionCard(pageNode);
        if (expansion != null) {
          blocks.add(expansion);
          continue;
        }
        final tableCard = _extractTableFromCard(pageNode);
        if (tableCard != null) {
          if (tableCard.$1.isNotEmpty) {
            blocks.add(PageHeaderBlock(title: tableCard.$1, subtitle: null));
          }
          blocks.add(tableCard.$2);
          continue;
        }
        // VCard > VRow > VCol[] 每列 VIcon + div(数值) + div(标签) 的统计卡片网格
        final statCards = _extractStatCardsFromRow(pageNode);
        if (statCards.isNotEmpty) {
          for (final b in statCards) {
            blocks.add(b);
          }
          continue;
        }
        final statCard = _extractStatCard(pageNode);
        if (statCard != null) blocks.add(statCard);
        continue;
      }
      if (pageNode.component == 'VRow') {
        final header = _extractPageHeader(pageNode);
        if (header != null) {
          blocks.add(header);
          continue;
        }
        for (final col in pageNode.content) {
          if (col.component != 'VCol') continue;
          final child = col.content.isNotEmpty ? col.content.first : null;
          if (child == null) continue;
          if (child.component == 'VCard') {
            final expansion = _extractExpansionCard(child);
            if (expansion != null) {
              blocks.add(expansion);
            } else {
              final card = _extractStatCard(child);
              if (card != null) blocks.add(card);
            }
          } else if (child.component == 'VApexChart') {
            final chart = _extractChart(child);
            if (chart != null) blocks.add(chart);
          } else if (child.component == 'VTable') {
            final table = _extractTable(child);
            if (table != null) blocks.add(table);
          }
        }
      }
    }
    for (final pageNode in response.page) {
      if (VuetifyComponentSubset.isStyle(pageNode.component)) continue;
      _collectFormFields(pageNode, blocks, null);
    }
    return blocks;
  }

  static String _extractCardTitleFromRow(FormNode row) {
    for (final col in row.content) {
      if (col.component != 'VCol') continue;
      for (final node in col.content) {
        if (node.component == 'span') {
          final cls = node.props?['class']?.toString() ?? '';
          if (cls.contains('font-weight-bold')) {
            final t = _textOf(node) ?? _collectText(node).trim();
            if (t.isNotEmpty) return t;
          }
        }
      }
    }
    return '';
  }

  static PageHeaderBlock? _extractPageHeader(FormNode row) {
    if (row.content.length != 1) return null;
    final col = row.content.first;
    if (col.component != 'VCol') return null;
    final div = col.content.isNotEmpty ? col.content.first : null;
    if (div == null || div.component != 'div') return null;
    String? title;
    String? subtitle;
    for (final node in div.content) {
      if (node.component == 'h2' || node.component == 'h1') {
        title = _textOf(node);
        break;
      }
    }
    for (final node in div.content) {
      if (node.component == 'VChip') {
        subtitle = _textOf(node);
        break;
      }
    }
    if (title != null && title.isNotEmpty) {
      return PageHeaderBlock(title: title, subtitle: subtitle);
    }
    return null;
  }

  /// 从 VIcon 节点提取图标名：支持 text、props.icon、content 内文本
  static String? _extractIconNameFromVIcon(FormNode? iconNode) {
    if (iconNode == null) return null;
    var name = iconNode.text?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    name = iconNode.props?['icon']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    if (iconNode.content.isNotEmpty) {
      name = iconNode.content.first.text?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
      name = _collectText(iconNode.content.first).trim();
      if (name.isNotEmpty) return name;
    }
    return null;
  }

  static FormNode? _findComponent(FormNode node, String component) {
    if (node.component == component) return node;
    for (final c in node.content) {
      final found = _findComponent(c, component);
      if (found != null) return found;
    }
    return null;
  }

  static void _collectComponents(
    FormNode node,
    String component,
    List<FormNode> out,
  ) {
    if (node.component == component) {
      out.add(node);
    }
    for (final c in node.content) {
      _collectComponents(c, component, out);
    }
  }

  static ExpansionCardBlock? _extractExpansionCard(FormNode card) {
    FormNode? cardTitleNode;
    FormNode? cardTextNode;
    for (final node in card.content) {
      if (node.component == 'VCardTitle') cardTitleNode = node;
      if (node.component == 'VCardText') cardTextNode = node;
    }
    // 优先从 VCardText 查找；也支持 VCard > VRow > VCol > VExpansionPanels 结构
    var panelsNode = cardTextNode != null
        ? _findComponent(cardTextNode, 'VExpansionPanels')
        : null;
    panelsNode ??= _findComponent(card, 'VExpansionPanels');
    if (panelsNode == null) return null;
    final items = <ExpansionItem>[];
    final panelList = <FormNode>[];
    _collectComponents(panelsNode, 'VExpansionPanel', panelList);
    for (final node in panelList) {
      final item = _extractExpansionPanelItem(node);
      if (item != null) items.add(item);
    }
    if (items.isEmpty) return null;
    String cardTitle = '';
    if (cardTitleNode != null) {
      cardTitle = _collectText(cardTitleNode).trim();
    }
    // 无 VCardTitle 时从首行 VRow > VCol > span.font-weight-bold 提取（如勋章站点名）
    if (cardTitle.isEmpty) {
      for (final node in card.content) {
        if (node.component == 'VRow') {
          cardTitle = _extractCardTitleFromRow(node);
          if (cardTitle.isNotEmpty) break;
        }
      }
    }
    String? cardSubtitle;
    if (cardTitleNode != null) {
      for (final node in cardTitleNode.content) {
        if (node.component == 'VChip') {
          cardSubtitle = _textOf(node);
          break;
        }
      }
    }
    String? iconName;
    final chipItems = <ChipItemData>[];
    for (final node in card.content) {
      if (node.component == 'VRow') {
        _collectChipItems(node, chipItems);
        if (iconName == null) {
          final iconNode = _findComponent(node, 'VIcon');
          iconName = _extractIconNameFromVIcon(iconNode);
        }
      }
    }
    return ExpansionCardBlock(
      cardTitle: cardTitle.isNotEmpty ? cardTitle : '详情',
      cardSubtitle: cardSubtitle,
      items: items,
      iconName: iconName,
      chipItems: chipItems,
    );
  }

  static SiteInfoCardBlock? _extractSiteInfoCard(FormNode card) {
    FormNode? cardItemNode;
    final cardTextNodes = <FormNode>[];
    for (final node in card.content) {
      if (node.component == 'VCardItem') cardItemNode = node;
      if (node.component == 'VCardText') cardTextNodes.add(node);
    }
    if (cardItemNode == null || cardTextNodes.isEmpty) return null;
    FormNode? titleNode;
    for (final c in cardItemNode.content) {
      if (c.component == 'VCardTitle') {
        titleNode = c;
        break;
      }
    }
    if (titleNode == null) return null;
    String title = '';
    String? iconName;
    String? iconColor;
    for (final div in titleNode.content) {
      if (div.component != 'div') continue;
      for (final node in div.content) {
        if (node.component == 'VIcon') {
          iconName ??= _extractIconNameFromVIcon(node);
          iconColor ??= node.props?['color']?.toString();
        } else if (node.component == 'span') {
          final t = _textOf(node) ?? _collectText(node).trim();
          if (t.isNotEmpty) title = t;
        }
      }
      if (title.isNotEmpty) break;
    }
    if (title.isEmpty) return null;
    final statItems = <StatItemData>[];
    final extraStatItems = <StatItemData>[];
    String? alertText;
    String? alertType;
    String? alertIconName;
    String? infoAlertText;
    String? alertButtonLabel;
    String? alertButtonHref;
    var rowIndex = 0;
    for (final textNode in cardTextNodes) {
      for (final c in textNode.content) {
        if (c.component == 'VRow') {
          final rowItems = _extractStatItemsFromRow(c);
          if (rowItems.isNotEmpty) {
            if (rowIndex == 0) {
              statItems.addAll(rowItems);
            } else {
              extraStatItems.addAll(rowItems);
            }
            rowIndex++;
          }
        } else if (c.component == 'VAlert') {
          final type = c.props?['type']?.toString().toLowerCase() ?? 'info';
          if (type == 'error') {
            alertType = c.props?['type']?.toString();
            final iconNode = _findComponent(c, 'VIcon');
            if (iconNode != null) {
              alertIconName = _extractIconNameFromVIcon(iconNode);
            }
            final textParts = <String>[];
            for (final child in c.content) {
              if (child.component == 'span' || child.component == 'div') {
                final t = _collectText(child).trim();
                if (t.isNotEmpty) textParts.add(t);
              }
            }
            alertText = textParts.join(' ').trim();
          } else if (type == 'info') {
            final textParts = <String>[];
            for (final child in c.content) {
              if (child.component == 'span' || child.component == 'div') {
                final t = _collectText(child).trim();
                if (t.isNotEmpty) textParts.add(t);
              }
              if (child.component == 'VBtn') {
                final href = child.props?['href']?.toString();
                if (href != null && href.isNotEmpty) {
                  alertButtonHref ??= href;
                  for (final btnChild in child.content) {
                    if (btnChild.component == 'span') {
                      final lbl = _collectText(btnChild).trim();
                      if (lbl.isNotEmpty) alertButtonLabel ??= lbl;
                    }
                  }
                }
              }
            }
            infoAlertText = textParts.join(' ').trim();
          }
        }
      }
    }
    if (statItems.isEmpty) return null;
    return SiteInfoCardBlock(
      title: title,
      iconName: iconName,
      iconColor: iconColor,
      statItems: statItems,
      extraStatItems: extraStatItems,
      alertText: alertText?.isNotEmpty == true ? alertText : null,
      alertType: alertType,
      alertIconName: alertIconName,
      infoAlertText: infoAlertText?.isNotEmpty == true ? infoAlertText : null,
      alertButtonLabel: alertButtonLabel?.isNotEmpty == true
          ? alertButtonLabel
          : null,
      alertButtonHref: alertButtonHref?.isNotEmpty == true
          ? alertButtonHref
          : null,
    );
  }

  static List<StatItemData> _extractStatItemsFromRow(FormNode rowNode) {
    final result = <StatItemData>[];
    for (final col in rowNode.content) {
      if (col.component != 'VCol') continue;
      String? value;
      String? label;
      String? itemIconName;
      String? itemIconColor;
      void visit(FormNode node) {
        if (node.component == 'VIcon') {
          itemIconName ??= _extractIconNameFromVIcon(node);
          itemIconColor ??= node.props?['color']?.toString();
        } else if (node.component == 'div') {
          for (final inner in node.content) {
            if (inner.component == 'VIcon') {
              itemIconName ??= _extractIconNameFromVIcon(inner);
              itemIconColor ??= inner.props?['color']?.toString();
            } else if (inner.component == 'div') {
              for (final d in inner.content) {
                if (d.component != 'div') continue;
                final cls = d.props?['class']?.toString() ?? '';
                final t = _collectText(d).trim();
                if (t.isEmpty) continue;
                if (cls.contains('text-caption')) {
                  label ??= t;
                } else {
                  value ??= t;
                }
              }
            }
          }
        }
        for (final c in node.content) {
          visit(c);
        }
      }

      for (final node in col.content) {
        visit(node);
      }
      if (value != null || label != null) {
        result.add(
          StatItemData(
            iconName: itemIconName,
            iconColor: itemIconColor,
            value: value ?? '',
            label: label ?? '',
          ),
        );
      }
    }
    return result;
  }

  static void _collectChipItems(FormNode node, List<ChipItemData> out) {
    if (node.component == 'VChip') {
      final item = _extractChipItem(node);
      if (item != null) out.add(item);
      return;
    }
    for (final c in node.content) {
      _collectChipItems(c, out);
    }
  }

  static ChipItemData? _extractChipItem(FormNode chip) {
    String? iconName;
    String? iconColor;
    final textParts = <String>[];
    final iconNode = _findComponent(chip, 'VIcon');
    if (iconNode != null) {
      iconName = _extractIconNameFromVIcon(iconNode);
      iconColor = iconNode.props?['color']?.toString();
    }
    for (final c in chip.content) {
      if (c.component == 'span' || c.component == 'div') {
        final t = _collectText(c).trim();
        if (t.isNotEmpty) textParts.add(t);
      }
    }
    final text = textParts.join(' ').trim();
    if (text.isEmpty && iconName == null) return null;
    final backgroundColor = chip.props?['color']?.toString();
    return ChipItemData(
      iconName: iconName,
      iconColor: iconColor,
      text: text.isNotEmpty ? text : (iconName ?? ''),
      backgroundColor: backgroundColor,
    );
  }

  static void _collectCaptionLines(FormNode node, List<String> out) {
    if (node.component == 'div') {
      final cls = node.props?['class']?.toString() ?? '';
      if (cls.contains('text-caption')) {
        final t = _collectText(node).trim();
        if (t.isNotEmpty) out.add(t);
      }
      return;
    }
    for (final c in node.content) {
      _collectCaptionLines(c, out);
    }
  }

  static ExpansionItem? _extractExpansionPanelItem(FormNode panel) {
    FormNode? titleNode;
    FormNode? textNode;
    for (final node in panel.content) {
      if (node.component == 'VExpansionPanelTitle') titleNode = node;
      if (node.component == 'VExpansionPanelText') textNode = node;
    }
    if (titleNode == null) return null;
    String title = '';
    String? subtitle;
    for (final inner in titleNode.content) {
      final div = inner.component == 'div' ? inner : null;
      if (div != null) {
        for (final c in div.content) {
          if (c.component == 'span' &&
              (c.props?['class']?.toString() ?? '').contains('font-weight')) {
            title = _textOf(c) ?? title;
          }
          if (c.component == 'span' &&
              (c.props?['class']?.toString() ?? '').contains('text-caption')) {
            subtitle = _textOf(c);
          }
        }
        if (title.isEmpty) title = _collectText(div).trim();
        break;
      }
    }
    if (title.isEmpty && titleNode.content.isNotEmpty) {
      title = _collectText(titleNode.content.first).trim();
    }
    final bodyLines = <String>[];
    final medalCards = <MedalCardData>[];
    if (textNode != null) {
      for (final node in textNode.content) {
        if (node.component == 'VList') {
          for (final item in node.content) {
            if (item.component == 'VListItem') {
              final line = _collectText(item).trim();
              if (line.isNotEmpty) bodyLines.add(line);
            }
          }
        } else if (node.component == 'VCardTitle') {
          final line = _collectText(node).trim();
          if (line.isNotEmpty) bodyLines.add(line);
        } else if (node.component == 'VRow') {
          for (final col in node.content) {
            if (col.component != 'VCol') continue;
            for (final child in col.content) {
              if (child.component == 'VCard') {
                final medal = _extractMedalCard(child);
                if (medal != null) {
                  medalCards.add(medal);
                } else {
                  final line = _collectMedalCardSummary(child);
                  if (line.isNotEmpty) bodyLines.add(line);
                }
              }
            }
          }
        } else {
          final line = _collectText(node).trim();
          if (line.isNotEmpty) bodyLines.add(line);
        }
      }
    }
    return ExpansionItem(
      title: title,
      subtitle: subtitle,
      bodyLines: bodyLines,
      medalCards: medalCards,
    );
  }

  static MedalCardData? _extractMedalCard(FormNode card) {
    String? title;
    String description = '';
    String? imageUrl;
    final detailLines = <String>[];
    String? price;
    String? actionLabel;
    String? actionColor;
    for (final node in card.content) {
      if (node.component == 'VCardTitle') {
        title = _collectText(node).trim();
      } else if (node.component == 'VImg') {
        imageUrl = node.props?['src']?.toString();
      } else if (node.component == 'div') {
        final text = _collectText(node).trim();
        if (text.isEmpty) continue;
        final cls = node.props?['class']?.toString() ?? '';
        final style = node.props?['style']?.toString() ?? '';
        final isCaption = cls.contains('text-caption');
        final isDesc =
            style.contains('color:#888') || style.contains('color: #888');
        if (isCaption) {
          detailLines.add(text);
        } else if (isDesc && description.isEmpty) {
          description = text;
        }
      } else if (node.component == 'VRow') {
        _collectCaptionLines(node, detailLines);
        final priceInRow = _findPriceInNode(node);
        if (priceInRow != null) price = priceInRow;
        final chip = _findComponent(node, 'VChip');
        if (chip != null) {
          actionLabel = _collectText(chip).trim();
          actionColor = chip.props?['color']?.toString();
        }
      }
    }
    if (title == null || title.isEmpty) return null;
    return MedalCardData(
      title: title,
      description: description,
      imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
      detailLines: detailLines,
      price: price,
      actionLabel: actionLabel,
      actionColor: actionColor,
    );
  }

  static String _collectMedalCardSummary(FormNode card) {
    String? name;
    String? price;
    for (final node in card.content) {
      if (node.component == 'VCardTitle') {
        name = _collectText(node).trim();
      } else {
        final t = _findPriceInNode(node);
        if (t != null) price = t;
      }
    }
    if (name != null && name.isNotEmpty) {
      return price != null && price.isNotEmpty ? '$name · $price' : name;
    }
    return _collectText(card).trim();
  }

  static String? _findPriceInNode(FormNode node) {
    final text = _collectText(node).trim();
    if (!text.contains('价格：')) return null;
    for (final c in node.content) {
      final t = _findPriceInNode(c);
      if (t != null) return t;
    }
    return text;
  }

  static String _collectText(FormNode node) {
    if (node.text != null) return node.text.toString();
    final buf = StringBuffer();
    for (final c in node.content) {
      final t = _collectText(c);
      if (buf.isNotEmpty && t.isNotEmpty) buf.write(' ');
      buf.write(t);
    }
    return buf.toString();
  }

  static void _collectConfNodes(
    FormNode node,
    List<FormBlock> blocks,
    Map<String, dynamic>? model,
  ) {
    final block = _extractGenericFieldBlock(
      node,
      model,
      includeAlert: true,
      includeSelect: true,
    );
    if (block != null) blocks.add(block);
    for (final c in node.content) {
      _collectConfNodes(c, blocks, model);
    }
  }

  static void _collectFormFields(
    FormNode node,
    List<FormBlock> blocks,
    Map<String, dynamic>? model,
  ) {
    final block = _extractGenericFieldBlock(
      node,
      model,
      includeAlert: true,
      includeSelect: true,
    );
    if (block != null) blocks.add(block);
    for (final c in node.content) {
      _collectFormFields(c, blocks, model);
    }
  }

  static FormBlock? _extractGenericFieldBlock(
    FormNode node,
    Map<String, dynamic>? model, {
    required bool includeAlert,
    required bool includeSelect,
  }) {
    final component = node.component;
    if (component == 'VSwitch') {
      return _extractSwitch(node, model);
    }
    if (component == 'VTextField') {
      return _extractTextField(node, model);
    }
    if (component == 'VTextarea') {
      return _extractTextArea(node, model);
    }
    if (VuetifyComponentSubset.isCronLike(component)) {
      return _extractCron(node, model);
    }
    if (includeAlert && component == 'VAlert') {
      return _extractAlert(node);
    }
    if (includeSelect && component == 'VSelect') {
      return _extractSelect(node, model);
    }
    return null;
  }

  static AlertBlock? _extractAlert(FormNode node) {
    final spec = VuetifyFormParser.parseAlert(node);
    if (spec == null) return null;
    return AlertBlock(type: spec.type, text: spec.text);
  }

  static SwitchFieldBlock? _extractSwitch(
    FormNode node,
    Map<String, dynamic>? model,
  ) {
    final spec = VuetifyFormParser.parseSwitch(node, model: model);
    if (spec == null) return null;
    return SwitchFieldBlock(
      label: spec.label,
      value: spec.value,
      name: spec.name,
    );
  }

  static CronFieldBlock? _extractCron(
    FormNode node,
    Map<String, dynamic>? model,
  ) {
    final spec = VuetifyFormParser.parseCron(node, model: model);
    if (spec == null) return null;
    return CronFieldBlock(
      label: spec.label,
      value: spec.value,
      name: spec.name,
      hint: spec.hint,
    );
  }

  static TextFieldBlock? _extractTextField(
    FormNode node,
    Map<String, dynamic>? model,
  ) {
    final spec = VuetifyFormParser.parseTextField(node, model: model);
    if (spec == null) return null;
    return TextFieldBlock(
      label: spec.label,
      value: spec.value,
      name: spec.name,
      hint: spec.hint,
    );
  }

  static TextAreaBlock? _extractTextArea(
    FormNode node,
    Map<String, dynamic>? model,
  ) {
    final spec = VuetifyFormParser.parseTextArea(node, model: model);
    if (spec == null) return null;
    return TextAreaBlock(
      label: spec.label,
      value: spec.value,
      name: spec.name,
      hint: spec.hint,
      rows: spec.maxLines,
    );
  }

  static StatCardBlock? _extractStatCard(FormNode card) {
    String? caption;
    String? value;
    String? iconSrc;
    for (final node in card.content) {
      if (node.component == 'VCardText' || node.component == 'div') {
        _visitForStatCard(node, (c, v, src) {
          caption ??= c;
          value ??= v;
          iconSrc ??= src;
        });
      }
    }
    if (caption != null && value != null) {
      // 去除 /plugin_icon/ 前缀，便于 ImageUtil.convertPluginIconUrl 使用
      String? normalized = iconSrc;
      final src = iconSrc;
      if (src != null && src.isNotEmpty && src.startsWith('/plugin_icon/')) {
        normalized = src.substring('/plugin_icon/'.length);
      }
      return StatCardBlock(
        caption: caption!,
        value: value!,
        iconSrc: normalized,
      );
    }
    return null;
  }

  /// div.dashboard-stats > div.dashboard-stats__item[] 每项: title + value
  static List<StatCardBlock> _extractStatCardsFromDashboardStats(
    FormNode dashboardNode,
  ) {
    final result = <StatCardBlock>[];
    for (final child in dashboardNode.content) {
      if (child.component != 'div') continue;
      final cls = child.props?['class']?.toString() ?? '';
      if (!cls.contains('dashboard-stats__item')) continue;
      String? caption;
      String? value;
      String? iconColor;
      for (final item in child.content) {
        if (item.component != 'div') continue;
        final itemCls = item.props?['class']?.toString() ?? '';
        if (itemCls.contains('dashboard-stats__title')) {
          caption = _collectText(item).trim();
          if (itemCls.contains('text-warning')) {
            iconColor = '#FF9800';
          } else if (itemCls.contains('text-error')) {
            iconColor = '#F44336';
          } else if (itemCls.contains('text-grey')) {
            iconColor = '#9E9E9E';
          }
        } else if (itemCls.contains('dashboard-stats__value')) {
          value ??= _collectText(item).trim();
        }
      }
      if (caption != null && caption.isNotEmpty && value != null) {
        final iconName = VuetifyMappings.iconFromDashboardStatsCaption(caption);
        result.add(
          StatCardBlock(
            caption: caption,
            value: value,
            iconSrc: null,
            iconName: iconName,
            iconColor: iconColor,
          ),
        );
      }
    }
    return result;
  }

  /// VCard > VRow > VCol[] 每列: VIcon + div(数值) + div(标签)，支持嵌套 div.text-center
  static List<StatCardBlock> _extractStatCardsFromRow(FormNode card) {
    final result = <StatCardBlock>[];
    FormNode? rowNode;
    for (final node in card.content) {
      if (node.component == 'VRow') {
        rowNode = node;
        break;
      }
    }
    if (rowNode == null) return result;
    for (final col in rowNode.content) {
      if (col.component != 'VCol') continue;
      String? value;
      String? caption;
      String? iconName;
      String? iconColor;
      void visit(FormNode node) {
        if (node.component == 'VIcon') {
          iconName ??= _extractIconNameFromVIcon(node);
          iconColor ??= node.props?['color']?.toString();
        } else if (node.component == 'div') {
          final cls = node.props?['class']?.toString() ?? '';
          final style = node.props?['style']?.toString() ?? '';
          final isValue =
              cls.contains('font-weight-bold') ||
              cls.contains('text-h5') ||
              style.contains('font-size: 2rem') ||
              style.contains('font-size:2rem');
          final isCaption =
              cls.contains('text-body-2') || cls.contains('text-caption');
          if (isValue || isCaption) {
            final text = _collectText(node).trim();
            if (text.isNotEmpty) {
              if (isValue) value ??= text;
              if (isCaption) caption ??= text;
            }
          }
          for (final c in node.content) {
            visit(c);
          }
        }
      }

      for (final node in col.content) {
        visit(node);
      }
      final c = caption;
      final v = value;
      if (c != null && v != null) {
        result.add(
          StatCardBlock(
            caption: c,
            value: v,
            iconSrc: null,
            iconName: iconName,
            iconColor: iconColor,
          ),
        );
      }
    }
    return result;
  }

  static void _visitForStatCard(
    FormNode node,
    void Function(String? caption, String? value, String? iconSrc) out,
  ) {
    if (node.component == 'VImg') {
      final src = node.props?['src']?.toString();
      if (src != null && src.isNotEmpty) out(null, null, src);
      return;
    }
    if (node.component == 'span') {
      final text = _textOf(node);
      if (text != null && text.isNotEmpty) {
        final props = node.props;
        final cls = props?['class']?.toString() ?? '';
        if (cls.contains('text-caption')) {
          out(text, null, null);
        } else if (cls.contains('text-h6')) {
          out(null, text, null);
        }
      }
      return;
    }
    for (final c in node.content) {
      _visitForStatCard(c, out);
    }
  }

  static String? _textOf(FormNode node) {
    if (node.text != null) return node.text.toString().trim();
    if (node.content.length == 1 && node.content.first.component == 'span') {
      return _textOf(node.content.first);
    }
    return null;
  }

  static ChartBlock? _extractChart(FormNode chart) {
    final spec = VuetifyFormParser.parseChart(chart);
    if (spec == null) return null;
    return ChartBlock(
      title: spec.title,
      labels: spec.labels,
      series: spec.series,
      chartType: spec.chartType,
    );
  }

  /// 从 VCard（VCardTitle + VCardText > VTable）中提取标题与表格
  static (String title, TableBlock table)? _extractTableFromCard(
    FormNode card,
  ) {
    FormNode? cardTitleNode;
    FormNode? cardTextNode;
    for (final node in card.content) {
      if (node.component == 'VCardTitle') cardTitleNode = node;
      if (node.component == 'VCardText') cardTextNode = node;
    }
    if (cardTextNode == null) return null;
    final tableNode = _findComponent(cardTextNode, 'VTable');
    if (tableNode == null) return null;
    final table = _extractTable(tableNode);
    if (table == null) return null;
    String title = '';
    if (cardTitleNode != null) title = _collectText(cardTitleNode).trim();
    return (title, table);
  }

  /// 解析 td：若含 VIcon 则返回 {icon, color, label?}，否则返回纯文本
  static dynamic _extractTableCell(FormNode td) {
    final iconNode = _findComponent(td, 'VIcon');
    if (iconNode != null) {
      final iconName = _extractIconNameFromVIcon(iconNode);
      final color = iconNode.props?['color']?.toString().trim();
      final label = _collectText(td).replaceAll(iconName ?? '', '').trim();
      return <String, dynamic>{
        'icon': iconName ?? '',
        'color': color ?? '',
        if (label.isNotEmpty) 'label': label,
      };
    }
    final cell = td.text?.toString().trim();
    return cell != null && cell.isNotEmpty ? cell : _collectText(td).trim();
  }

  static TableBlock? _extractTable(FormNode table) {
    final headers = <String>[];
    final rows = <List<dynamic>>[];
    for (final node in table.content) {
      if (node.component == 'thead') {
        // thead 可能为 thead > tr > th
        for (final tr in node.content) {
          if (tr.component == 'tr') {
            for (final th in tr.content) {
              if (th.component == 'th') {
                headers.add(_collectText(th).trim());
              }
            }
            break;
          }
        }
        if (headers.isEmpty) {
          for (final th in node.content) {
            if (th.component == 'th') headers.add(_collectText(th).trim());
          }
        }
      } else if (node.component == 'tbody') {
        for (final tr in node.content) {
          if (tr.component == 'tr') {
            final row = <dynamic>[];
            for (final td in tr.content) {
              if (td.component == 'td') {
                row.add(_extractTableCell(td));
              }
            }
            rows.add(row);
          }
        }
      }
    }
    if (headers.isNotEmpty || rows.isNotEmpty) {
      return TableBlock(headers: headers, rows: rows);
    }
    return null;
  }

  static SelectFieldBlock? _extractSelect(
    FormNode node,
    Map<String, dynamic>? model,
  ) {
    final spec = VuetifyFormParser.parseSelect(node, model: model);
    if (spec == null) return null;
    return SelectFieldBlock(
      label: spec.label,
      items: spec.items
          .map((item) => SelectOption(title: item.title, value: item.value))
          .toList(),
      value: spec.value,
      name: spec.name,
      multiple: spec.multiple,
    );
  }
}
