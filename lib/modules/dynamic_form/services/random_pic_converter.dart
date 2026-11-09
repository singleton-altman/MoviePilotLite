import 'package:moviepilot_mobile/modules/dynamic_form/models/form_block_models.dart';
import 'package:moviepilot_mobile/modules/dynamic_form/models/random_pic_models.dart';

/// RandomPic 插件转换器：把插件 API 的原始 JSON 转成移动端 FormBlock。
///
/// 该插件在 Web 端使用 Vue 联邦组件（`get_render_mode()` 返回 `vue`），
/// App 无法直接渲染其远端组件，因此这里按插件真实接口（v2.3.1）重建原生界面：
/// - page 模式：运行状态、图源配置、图片统计、接口可用性
/// - form 模式：横/竖屏目录、网络图源、下载数量等可编辑项
class RandomPicConverter {
  /// 展示页：status → FormBlock 列表（只读概览）
  static List<FormBlock> convertPage({
    required RandomPicStatus status,
    RandomPicVisits? visits,
    Map<String, RandomPicPing> pings = const {},
    RandomPicDownloadStatus? downloadStatus,
  }) {
    final blocks = <FormBlock>[];

    blocks.addAll([
      FormBlock.statCard(
        caption: '总图片数',
        value: '${status.totalCount}',
        iconName: 'mdi-image-multiple',
        iconColor: 'purple',
      ),
      FormBlock.statCard(
        caption: '横屏图片',
        value: '${status.pcCount}',
        iconName: 'mdi-monitor',
        iconColor: 'blue',
      ),
      FormBlock.statCard(
        caption: '竖屏图片',
        value: '${status.mobileCount}',
        iconName: 'mdi-cellphone',
        iconColor: 'teal',
      ),
      FormBlock.statCard(
        caption: '今日访问',
        value: '${status.todayVisits}',
        iconName: 'mdi-chart-line',
        iconColor: 'orange',
      ),
    ]);

    if (!status.enable) {
      blocks.add(
        const FormBlock.alert(
          type: 'warning',
          text: '插件当前已禁用，随机图床接口不可用。可在右上角「插件配置」中启用。',
        ),
      );
    } else if (!status.configComplete) {
      blocks.add(
        const FormBlock.alert(
          type: 'warning',
          text: '横屏或竖屏图源尚未配置完整，部分接口不可用。请在「插件配置」中补充目录或网络图片源。',
        ),
      );
    }

    blocks.add(
      FormBlock.infoCard(
        title: '运行状态',
        iconName: 'mdi-api',
        iconColor: status.enable ? 'green' : 'grey',
        headerChipText: status.enable ? '已启用' : '已禁用',
        headerChipColor: status.enable ? 'green' : 'grey',
        rows: [
          InfoCardRow(
            iconName: 'mdi-auto-fix',
            label: '自动识别设备',
            chipText: status.autoAvailable ? '正常' : '不可用',
            chipColor: status.autoAvailable ? 'green' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-monitor',
            label: '指定横屏',
            chipText: status.pcAvailable ? '正常' : '不可用',
            chipColor: status.pcAvailable ? 'green' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-cellphone',
            label: '指定竖屏',
            chipText: status.mobileAvailable ? '正常' : '不可用',
            chipColor: status.mobileAvailable ? 'green' : 'grey',
          ),
          InfoCardRow(
            iconName: 'mdi-chart-box-outline',
            label: '统计数据',
            chipText: status.endpointAvailability['stats'] == true
                ? '正常'
                : '不可用',
            chipColor: status.endpointAvailability['stats'] == true
                ? 'green'
                : 'grey',
          ),
        ],
      ),
    );

    blocks.add(
      FormBlock.infoCard(
        title: '图源配置',
        iconName: 'mdi-folder-image',
        iconColor: 'blue',
        rows: [
          InfoCardRow(
            iconName: 'mdi-monitor',
            label: '横屏来源',
            value: status.pcSourceLabel,
          ),
          InfoCardRow(
            iconName: 'mdi-cellphone',
            label: '竖屏来源',
            value: status.mobileSourceLabel,
          ),
          InfoCardRow(
            iconName: 'mdi-camera',
            label: '本地横屏 / 竖屏',
            value: '${status.localPcCount} / ${status.localMobileCount} 张',
          ),
          InfoCardRow(
            iconName: 'mdi-cloud-outline',
            label: '网络横屏 / 竖屏',
            value:
                '${status.networkPcCount} / ${status.networkMobileCount} 张',
          ),
        ],
      ),
    );

    return blocks;
  }

  /// 访问统计：近 7 天趋势 + 最近调用记录
  static List<FormBlock> convertVisits(RandomPicVisits visits) {
    final blocks = <FormBlock>[];
    if (visits.daily.isEmpty && visits.recent.isEmpty) return blocks;

    if (visits.daily.isNotEmpty) {
      blocks.add(
        FormBlock.chart(
          title: '近 7 天访问量',
          labels: visits.daily.map((e) => e.label).toList(),
          series: visits.daily.map((e) => e.count).toList(),
          chartType: 'bar',
        ),
      );
    }

    if (visits.recent.isNotEmpty) {
      final rows = <InfoCardRow>[];
      for (final v in visits.recent.take(10)) {
        rows.add(
          InfoCardRow(
            iconName: v.ok ? 'mdi-check-circle' : 'mdi-close-circle',
            iconColor: v.ok ? 'green' : 'red',
            label: '${v.time} · ${v.source.isEmpty ? '未知来源' : v.source}',
            subtitle:
                '${v.endpoint}${v.type.isEmpty ? '' : ' (${v.type})'}'
                '${v.imageSource.isEmpty ? '' : ' · ${v.imageSource}'}'
                '${v.domain.isEmpty ? '' : ' · ${v.domain}'}',
            value: '${v.elapsedMs}ms',
          ),
        );
      }
      blocks.add(
        FormBlock.infoCard(
          title: '最近访问',
          iconName: 'mdi-history',
          iconColor: 'blue',
          headerChipText: '${visits.recent.length} 条',
          headerChipColor: 'blue',
          rows: rows,
        ),
      );
    }
    return blocks;
  }

  /// 图源测速结果
  static List<FormBlock> convertPings(Map<String, RandomPicPing> pings) {
    if (pings.isEmpty) return const [];
    final rows = <InfoCardRow>[];
    for (final entry in pings.entries) {
      final ping = entry.value;
      rows.add(
        InfoCardRow(
          iconName: !ping.configured
              ? 'mdi-link-off'
              : (ping.ok ? 'mdi-speedometer' : 'mdi-alert-circle'),
          iconColor: !ping.configured
              ? 'grey'
              : (ping.ok ? 'green' : 'red'),
          label: ping.label.isEmpty ? entry.key : ping.label,
          chipText: !ping.configured
              ? '未配置'
              : (ping.ok ? '${ping.ms ?? 0} ms' : '不可用'),
          chipColor: !ping.configured
              ? 'grey'
              : (ping.ok ? 'green' : 'red'),
        ),
      );
    }
    return [
      FormBlock.infoCard(
        title: '图源测速',
        iconName: 'mdi-speedometer',
        iconColor: 'orange',
        rows: rows,
      ),
    ];
  }

  /// 下载任务进度
  static List<FormBlock> convertDownloadStatus(
    RandomPicDownloadStatus status,
  ) {
    if (!status.running &&
        status.total == 0 &&
        status.message.isEmpty) {
      return const [];
    }
    return [
      FormBlock.infoCard(
        title: '网络图片下载',
        iconName: 'mdi-cloud-download',
        iconColor: 'teal',
        headerChipText: status.running ? '下载中' : '已结束',
        headerChipColor: status.running ? 'orange' : 'green',
        rows: [
          if (status.message.isNotEmpty)
            InfoCardRow(
              iconName: 'mdi-information-outline',
              label: status.message,
            ),
          InfoCardRow.progress(
            iconName: 'mdi-progress-download',
            iconColor: 'teal',
            label: '进度',
            progressValue: status.progress,
            chipText: '${status.done}/${status.total}',
            chipColor: 'teal',
          ),
          InfoCardRow(
            iconName: 'mdi-check-circle',
            iconColor: 'green',
            label: '成功 / 失败 / 跳过',
            value: '${status.success} / ${status.failed} / ${status.skipped}',
          ),
          InfoCardRow(
            iconName: 'mdi-monitor',
            iconColor: 'blue',
            label: '横屏 / 竖屏保存',
            value: '${status.pcSaved} / ${status.mobileSaved}',
          ),
        ],
      ),
    ];
  }
  static List<FormBlock> convertForm({required RandomPicConfig config}) {
    final blocks = <FormBlock>[
      const FormBlock.pageHeader(title: '基本设置'),
      FormBlock.switchField(
        label: '启用插件',
        name: 'enable',
        value: config.enable,
      ),
      const FormBlock.pageHeader(title: '横屏图片源'),
      FormBlock.textField(
        label: '横屏图片目录',
        name: 'pc_path',
        value: config.pcPath,
        hint: config.defaultPcPath.isEmpty
            ? '留空则使用插件默认目录'
            : '默认：${config.defaultPcPath}',
      ),
      FormBlock.textField(
        label: '横屏网络图片源',
        name: 'network_image_url_pc',
        value: config.networkImageUrlPc,
        hint: '支持图片直链或 m3u/txt 列表地址',
      ),
      const FormBlock.pageHeader(title: '竖屏图片源'),
      FormBlock.textField(
        label: '竖屏图片目录',
        name: 'mobile_path',
        value: config.mobilePath,
        hint: config.defaultMobilePath.isEmpty
            ? '留空则使用插件默认目录'
            : '默认：${config.defaultMobilePath}',
      ),
      FormBlock.textField(
        label: '竖屏网络图片源',
        name: 'network_image_url_mobile',
        value: config.networkImageUrlMobile,
        hint: '支持图片直链或 m3u/txt 列表地址',
      ),
      const FormBlock.pageHeader(title: '通用'),
      FormBlock.textField(
        label: '通用网络图片源',
        name: 'network_image_url',
        value: config.networkImageUrl,
        hint: '横竖屏都未单独配置时使用，可留空',
      ),
      FormBlock.textField(
        label: '下载数量',
        name: 'download_count',
        value: config.downloadCount.toString(),
        hint: '批量下载网络图片时的单次数量（1-100）',
      ),
      FormBlock.switchField(
        label: '网络图源优先',
        name: 'network_first',
        value: config.networkFirst,
      ),
      FormBlock.switchField(
        label: '首页仪表盘展示',
        name: 'dashboard_enable',
        value: config.dashboardEnable,
      ),
      const FormBlock.alert(
        type: 'info',
        text: '启用插件时，横屏与竖屏至少各配置一个来源（目录或网络地址），否则保存会被拒绝。',
      ),
    ];
    return blocks;
  }

  /// formModel → POST /config 请求体
  static Map<String, dynamic> toConfigBody(Map<String, dynamic> model) {
    return RandomPicConfig.fromFormModel(model).toRequestBody();
  }
}
