import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_block_models.freezed.dart';

/// 移动端精简后的表单区块（去除 Vuetify/Web 无用参数）
@freezed
sealed class FormBlock with _$FormBlock {
  const FormBlock._();

  /// 统计卡片：图标 + 标题 + 数值（支持 MDI 图标名与颜色）
  const factory FormBlock.statCard({
    required String caption,
    required String value,
    String? iconSrc,
    String? iconName,
    String? iconColor,
  }) = StatCardBlock;

  /// 图表：标题 + 标签 + 数据 + 类型
  const factory FormBlock.chart({
    String? title,
    @Default([]) List<String> labels,
    @Default([]) List<num> series,
    @Default('pie') String chartType,
  }) = ChartBlock;

  /// 表格：表头 + 行数据
  const factory FormBlock.table({
    @Default([]) List<String> headers,
    @Default([]) List<List<dynamic>> rows,
    @Default([]) List<InfoCardRowMenuItem>? actions,
    void Function(String type, int index)? onAction,
  }) = TableBlock;

  /// 开关：标签 + 当前值
  const factory FormBlock.switchField({
    required String label,
    @Default(false) bool value,
    String? name,
  }) = SwitchFieldBlock;

  /// Cron 表达式：标签 + 当前值
  const factory FormBlock.cronField({
    required String label,
    @Default('') String value,
    String? name,
    String? hint,
  }) = CronFieldBlock;

  /// 单行文本：标签 + 当前值
  const factory FormBlock.textField({
    required String label,
    @Default('') String value,
    String? name,
    String? hint,
  }) = TextFieldBlock;

  /// 多行文本：标签 + 当前值
  const factory FormBlock.textArea({
    required String label,
    @Default('') String value,
    String? name,
    String? hint,
    @Default(3) int rows,
  }) = TextAreaBlock;

  /// 提示条：类型 + 文案
  const factory FormBlock.alert({
    @Default('info') String type,
    required String text,
  }) = AlertBlock;

  /// 下拉选择：标签 + 选项列表 + 当前值（单选或多选）
  const factory FormBlock.selectField({
    required String label,
    @Default([]) List<SelectOption> items,
    dynamic value,
    String? name,
    @Default(false) bool multiple,
  }) = SelectFieldBlock;

  /// 页面标题行：标题 + 可选副标题
  const factory FormBlock.pageHeader({
    required String title,
    String? subtitle,
  }) = PageHeaderBlock;

  /// 折叠卡片：卡片标题 + 副标题 + 可折叠项列表（支持图标与数量摘要芯片）
  const factory FormBlock.expansionCard({
    required String cardTitle,
    String? cardSubtitle,
    @Default([]) List<ExpansionItem> items,
    String? iconName,
    @Default([]) List<String> chipLines,
    @Default([]) List<ChipItemData> chipItems,
  }) = ExpansionCardBlock;

  /// 站点信息卡片：标题 + 图标 + 统计项 + 错误提示 + 魔力值行 + 购买说明 + 购买按钮（后宫管理系统等）
  const factory FormBlock.siteInfoCard({
    required String title,
    String? iconName,
    String? iconColor,
    @Default([]) List<StatItemData> statItems,
    @Default([]) List<StatItemData> extraStatItems,
    String? alertText,
    String? alertType,
    String? alertIconName,
    String? infoAlertText,
    String? alertButtonLabel,
    String? alertButtonHref,
  }) = SiteInfoCardBlock;

  /// 信息卡片：CupertinoListSection.insetGrouped 风格，
  /// 用于展示带图标行列表、空状态、内嵌提示的卡片区块
  const factory FormBlock.infoCard({
    required String title,
    String? iconName,
    String? iconColor,
    @Default([]) List<InfoCardRow> rows,
    String? headerChipText,
    String? headerChipColor,
    String? emptyText,
    String? emptyIconName,
    String? alertText,
    String? alertType,
  }) = InfoCardBlock;
}

/// 站点信息卡片的单行统计项：图标 + 数值 + 标签
@freezed
class StatItemData with _$StatItemData {
  const factory StatItemData({
    String? iconName,
    String? iconColor,
    required String value,
    required String label,
  }) = _StatItemData;
}

/// 芯片项：图标 + 文本 + 背景色（VChip 内 VIcon + span 结构）
@freezed
class ChipItemData with _$ChipItemData {
  const factory ChipItemData({
    String? iconName,
    String? iconColor,
    required String text,
    String? backgroundColor,
  }) = _ChipItemData;
}

/// 折叠项：标题 + 副标题 + 正文行 + 勋章卡片列表
@freezed
class ExpansionItem with _$ExpansionItem {
  const factory ExpansionItem({
    required String title,
    String? subtitle,
    @Default([]) List<String> bodyLines,
    @Default([]) List<MedalCardData> medalCards,
  }) = _ExpansionItem;
}

/// 勋章卡片：标题、描述、图片、详情行、价格、操作按钮
@freezed
class MedalCardData with _$MedalCardData {
  const factory MedalCardData({
    required String title,
    @Default('') String description,
    String? imageUrl,
    @Default([]) List<String> detailLines,
    String? price,
    String? actionLabel,
    String? actionColor,
  }) = _MedalCardData;
}

/// 选择项：标题 + 值
@freezed
class SelectOption with _$SelectOption {
  const factory SelectOption({required String title, required dynamic value}) =
      _SelectOption;
}

/// 信息卡片行：图标 + 标签 + 可选副标题 + 右侧值/Chip
@freezed
class InfoCardRow with _$InfoCardRow {
  const factory InfoCardRow({
    String? iconName,
    String? iconColor,
    required String label,
    String? subtitle,
    String? value,
    String? chipText,
    String? chipColor,
    Map<String, dynamic>? events,
  }) = InfoCardRowBase;

  const factory InfoCardRow.progress({
    String? iconName,
    String? iconColor,
    required String label,
    String? subtitle,
    required double progressValue,
    String? progressLabel,
    String? progressColor,
    String? progressBackgroundColor,
    String? value,
    String? chipText,
    String? chipColor,
    Map<String, dynamic>? events,
  }) = InfoCardRowProgress;

  const factory InfoCardRow.menu({
    String? iconName,
    String? iconColor,
    required String label,
    String? subtitle,
    String? value,
    String? chipText,
    String? chipColor,
    @Default([]) List<InfoCardRowMenuItem> menuItems,
    Map<String, dynamic>? events,
  }) = InfoCardRowMenu;

  const factory InfoCardRow.group({
    String? iconName,
    String? iconColor,
    required String label,
    String? subtitle,
    String? value,
    String? chipText,
    String? chipColor,
    @Default([]) List<InfoCardRowMenuItem> menuItems,
    Map<String, dynamic>? events,
  }) = InfoCardRowMenu;
}

@freezed
class InfoCardRowMenuItem with _$InfoCardRowMenuItem {
  const factory InfoCardRowMenuItem({
    required String label,
    String? iconName,
    String? iconColor,
    bool? isEnabled,
    Map<String, dynamic>? events,
  }) = _InfoCardRowMenuItem;
}
