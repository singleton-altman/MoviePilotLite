import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';

/// RandomPic 插件专用转换器：将 API 原始 JSON 转换为 FormBlock 列表
class RandomPicConverter {
  /// 展示页：status → FormBlock 列表（只读）
  static List<FormBlock> convertPage({
    required Map<String, dynamic> status,
  }) {
    final blocks = <FormBlock>[];

    _buildStatusSection(blocks, status);
    _buildConfigSummarySection(blocks, status);

    blocks.add(
      const FormBlock.alert(
        type: 'info',
        text: '点击右下角设置按钮可配置随机图床。',
      ),
    );

    return blocks;
  }

  /// 配置页：status → (FormBlock 列表, formModel)
  static (List<FormBlock>, Map<String, dynamic>) convertForm({
    required Map<String, dynamic> status,
  }) {
    final blocks = <FormBlock>[];
    final model = _buildFormModel(status);

    _buildBasicSettingsSection(blocks);
    _buildApiSection(blocks);

    return (blocks, model);
  }

  static void _buildStatusSection(
    List<FormBlock> blocks,
    Map<String, dynamic> status,
  ) {
    final enabled = status['enabled'] == true;
    final cron = status['cron']?.toString() ?? '未设置';
    final nextRun = status['next_run_time']?.toString() ?? '未知';

    blocks.add(
      FormBlock.infoCard(
        title: '当前状态',
        iconName: 'mdi-information',
        iconColor: 'info',
        rows: [
          InfoCardRow(
            iconName: 'mdi-power',
            iconColor: enabled ? 'green' : 'grey',
            label: '插件状态',
            chipText: enabled ? '已启用' : '已禁用',
            chipColor: enabled ? 'green' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-code-braces',
            label: 'CRON表达式',
            chipText: cron,
            chipColor: 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-clock-outline',
            label: '下次运行',
            value: nextRun,
          ),
        ],
      ),
    );
  }

  static void _buildConfigSummarySection(
    List<FormBlock> blocks,
    Map<String, dynamic> status,
  ) {
    final apiUrl = status['api_url']?.toString() ?? '';
    final sourceCount = status['source_count'] ?? 0;

    blocks.add(
      FormBlock.infoCard(
        title: '图床配置',
        iconName: 'mdi-image-multiple',
        iconColor: 'teal',
        rows: [
          if (apiUrl.isNotEmpty)
            InfoCardRow(
              iconName: 'mdi-link',
              iconColor: 'blue',
              label: 'API 地址',
              value: apiUrl,
            ),
          InfoCardRow(
            iconName: 'mdi-counter',
            iconColor: 'green',
            label: '图片源数量',
            chipText: '$sourceCount',
            chipColor: 'teal',
          ),
        ],
        emptyText: apiUrl.isEmpty ? '未配置 API 地址' : null,
      ),
    );
  }

  static void _buildBasicSettingsSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: '基本设置'));
    blocks.add(const FormBlock.switchField(label: '启用插件', name: 'enable'));
    blocks.add(const FormBlock.switchField(label: '启用通知', name: 'notify'));
  }

  static void _buildApiSection(List<FormBlock> blocks) {
    blocks.add(const FormBlock.pageHeader(title: 'API 配置'));
    blocks.add(
      const FormBlock.textField(
        label: 'API 地址',
        name: 'api_url',
        hint: '随机图床 API 地址',
      ),
    );
    blocks.add(
      const FormBlock.cronField(
        label: 'CRON表达式',
        name: 'cron',
        hint: '如：0 */6 * * *（每 6 小时）',
      ),
    );
  }

  static Map<String, dynamic> _buildFormModel(Map<String, dynamic> status) {
    return {
      'enable': status['enabled'] ?? false,
      'notify': status['notify'] ?? true,
      'api_url': status['api_url']?.toString() ?? '',
      'cron': status['cron'] ?? '0 */6 * * *',
    };
  }

  /// formModel → PUT 请求 body
  static Map<String, dynamic> toConfigBody(Map<String, dynamic> model) {
    return Map<String, dynamic>.from(model);
  }
}
