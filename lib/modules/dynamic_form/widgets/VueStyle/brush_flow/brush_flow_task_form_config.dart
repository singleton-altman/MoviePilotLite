import 'package:flutter/cupertino.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_enums.dart';
import 'package:moviepilot_mobile/modules/settings/models/settings_field_config.dart';

enum BrushFlowTaskFormSegment {
  basic,
  schedule,
  filter,
  quota,
  seed,
  advanced,
}

extension BrushFlowTaskFormSegmentX on BrushFlowTaskFormSegment {
  String get label => switch (this) {
    BrushFlowTaskFormSegment.basic => '基础',
    BrushFlowTaskFormSegment.schedule => '调度',
    BrushFlowTaskFormSegment.filter => '筛选',
    BrushFlowTaskFormSegment.quota => '配额',
    BrushFlowTaskFormSegment.seed => '做种',
    BrushFlowTaskFormSegment.advanced => '高级',
  };
}

class BrushFlowTaskFormConfig {
  BrushFlowTaskFormConfig._();

  static const freeleechOptions = [
    SettingsEnumOption(value: 'free', label: '免费'),
    SettingsEnumOption(value: '2xfree', label: '2X免费'),
    SettingsEnumOption(value: 'half', label: '50%'),
    SettingsEnumOption(value: '', label: '不限'),
  ];

  static const hrOptions = [
    SettingsEnumOption(value: 'yes', label: '包含 H&R'),
    SettingsEnumOption(value: 'no', label: '排除 H&R'),
    SettingsEnumOption(value: '', label: '不限'),
  ];

  static const fieldsBySegment =
      <BrushFlowTaskFormSegment, List<SettingsFieldConfig>>{
        BrushFlowTaskFormSegment.basic: [
          SettingsFieldConfig(
            label: '任务名称',
            envKey: 'name',
            type: SettingsFieldType.text,
            icon: CupertinoIcons.textformat,
            hint: '例如：馒头',
          ),
          SettingsFieldConfig(
            label: '启用任务',
            envKey: 'enabled',
            type: SettingsFieldType.toggle,
            icon: CupertinoIcons.power,
          ),
          SettingsFieldConfig(
            label: '消息通知',
            envKey: 'notify',
            type: SettingsFieldType.toggle,
            icon: CupertinoIcons.bell,
          ),
          SettingsFieldConfig(
            label: '站点',
            envKey: 'site_id',
            type: SettingsFieldType.select,
            enumKey: 'BRUSH_FLOW_SITE',
            icon: CupertinoIcons.globe,
          ),
          SettingsFieldConfig(
            label: '下载器',
            envKey: 'downloader',
            type: SettingsFieldType.select,
            enumKey: 'BRUSH_FLOW_DOWNLOADER',
            icon: CupertinoIcons.cloud_download,
          ),
        ],
        BrushFlowTaskFormSegment.schedule: [
          SettingsFieldConfig(
            label: '刷流间隔(分)',
            envKey: 'brush_interval',
            type: SettingsFieldType.number,
            step: 1,
            icon: CupertinoIcons.timer,
          ),
          SettingsFieldConfig(
            label: '检查间隔(分)',
            envKey: 'check_interval',
            type: SettingsFieldType.number,
            step: 1,
            icon: CupertinoIcons.clock,
          ),
          SettingsFieldConfig(
            label: 'Cron',
            envKey: 'cron',
            type: SettingsFieldType.text,
            hint: '可留空',
            icon: CupertinoIcons.calendar,
          ),
          SettingsFieldConfig(
            label: '活跃时段',
            envKey: 'active_time_range',
            type: SettingsFieldType.text,
            hint: '如 08:00-23:00',
            icon: CupertinoIcons.time,
          ),
          SettingsFieldConfig(
            label: '时区偏移',
            envKey: 'timezone_offset',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.globe,
          ),
        ],
        BrushFlowTaskFormSegment.filter: [
          SettingsFieldConfig(
            label: '免费类型',
            envKey: 'freeleech',
            type: SettingsFieldType.select,
            enumKey: 'BRUSH_FLOW_FREELEECH',
            icon: CupertinoIcons.tag,
          ),
          SettingsFieldConfig(
            label: 'H&R',
            envKey: 'hr',
            type: SettingsFieldType.select,
            enumKey: 'BRUSH_FLOW_HR',
            icon: CupertinoIcons.exclamationmark_triangle,
          ),
          SettingsFieldConfig(
            label: '包含关键词',
            envKey: 'include',
            type: SettingsFieldType.text,
            hint: '可留空',
            icon: CupertinoIcons.search,
          ),
          SettingsFieldConfig(
            label: '排除关键词',
            envKey: 'exclude',
            type: SettingsFieldType.text,
            hint: '可留空',
            icon: CupertinoIcons.clear,
          ),
          SettingsFieldConfig(
            label: '体积范围',
            envKey: 'size',
            type: SettingsFieldType.text,
            hint: '如 10-100',
            icon: CupertinoIcons.archivebox,
          ),
          SettingsFieldConfig(
            label: '做种人数',
            envKey: 'seeder',
            type: SettingsFieldType.text,
            hint: '如 10',
            icon: CupertinoIcons.person_2,
          ),
          SettingsFieldConfig(
            label: '发布时间',
            envKey: 'pubtime',
            type: SettingsFieldType.text,
            hint: '可留空',
            icon: CupertinoIcons.calendar_badge_plus,
          ),
        ],
        BrushFlowTaskFormSegment.quota: [
          SettingsFieldConfig(
            label: '预留磁盘(GB)',
            envKey: 'disksize',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.device_phone_portrait,
          ),
          SettingsFieldConfig(
            label: '最大上传速度',
            envKey: 'maxupspeed',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.arrow_up_circle,
          ),
          SettingsFieldConfig(
            label: '最大下载速度',
            envKey: 'maxdlspeed',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.arrow_down_circle,
          ),
          SettingsFieldConfig(
            label: '最大下载数',
            envKey: 'maxdlcount',
            type: SettingsFieldType.number,
            step: 1,
            icon: CupertinoIcons.number,
          ),
          SettingsFieldConfig(
            label: '限速上传',
            envKey: 'up_speed',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.arrow_up,
          ),
          SettingsFieldConfig(
            label: '限速下载',
            envKey: 'dl_speed',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.arrow_down,
          ),
        ],
        BrushFlowTaskFormSegment.seed: [
          SettingsFieldConfig(
            label: '做种时间',
            envKey: 'seed_time',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.hourglass,
          ),
          SettingsFieldConfig(
            label: 'H&R 做种时间',
            envKey: 'hr_seed_time',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.hourglass_bottomhalf_fill,
          ),
          SettingsFieldConfig(
            label: '分享率',
            envKey: 'seed_ratio',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.chart_bar,
          ),
          SettingsFieldConfig(
            label: '做种体积',
            envKey: 'seed_size',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.archivebox_fill,
          ),
          SettingsFieldConfig(
            label: '下载耗时',
            envKey: 'download_time',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.stopwatch,
          ),
          SettingsFieldConfig(
            label: '平均做种速度',
            envKey: 'seed_avgspeed',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.speedometer,
          ),
          SettingsFieldConfig(
            label: '不活跃时间',
            envKey: 'seed_inactivetime',
            type: SettingsFieldType.number,
            icon: CupertinoIcons.pause_circle,
          ),
          SettingsFieldConfig(
            label: '删种体积范围',
            envKey: 'delete_size_range',
            type: SettingsFieldType.text,
            hint: '可留空',
            icon: CupertinoIcons.trash,
          ),
          SettingsFieldConfig(
            label: '保留标签',
            envKey: 'delete_except_tags',
            type: SettingsFieldType.text,
            hint: '如 MOVIEPILOT,H&R',
            icon: CupertinoIcons.bookmark,
          ),
          SettingsFieldConfig(
            label: '自动归档天数',
            envKey: 'auto_archive_days',
            type: SettingsFieldType.number,
            step: 1,
            icon: CupertinoIcons.tray_full,
          ),
        ],
        BrushFlowTaskFormSegment.advanced: [
          SettingsFieldConfig(
            label: '保存路径',
            envKey: 'save_path',
            type: SettingsFieldType.text,
            hint: '可留空',
            icon: CupertinoIcons.folder,
          ),
          SettingsFieldConfig(
            label: 'QB 分类',
            envKey: 'qb_category',
            type: SettingsFieldType.text,
            hint: '可留空',
            icon: CupertinoIcons.square_grid_2x2,
          ),
          SettingsFieldConfig(
            label: '排除订阅',
            envKey: 'except_subscribe',
            type: SettingsFieldType.toggle,
            icon: CupertinoIcons.minus_circle,
          ),
          SettingsFieldConfig(
            label: '代理删除',
            envKey: 'proxy_delete',
            type: SettingsFieldType.toggle,
            icon: CupertinoIcons.delete,
          ),
          SettingsFieldConfig(
            label: '非免费删除',
            envKey: 'del_no_free',
            type: SettingsFieldType.toggle,
            icon: CupertinoIcons.xmark_circle,
          ),
          SettingsFieldConfig(
            label: '站点 H&R 活跃',
            envKey: 'site_hr_active',
            type: SettingsFieldType.toggle,
            icon: CupertinoIcons.flame,
          ),
          SettingsFieldConfig(
            label: '跳过站点提示',
            envKey: 'site_skip_tips',
            type: SettingsFieldType.toggle,
            icon: CupertinoIcons.info,
          ),
          SettingsFieldConfig(
            label: 'RSS 支持',
            envKey: 'rss_support',
            type: SettingsFieldType.toggle,
            icon: CupertinoIcons.antenna_radiowaves_left_right,
          ),
        ],
      };

  static List<SettingsFieldConfig> get allFields => fieldsBySegment.values
      .expand((fields) => fields)
      .toList(growable: false);

  static const nullableTextKeys = {
    'cron',
    'active_time_range',
    'include',
    'exclude',
    'size',
    'seeder',
    'pubtime',
    'delete_size_range',
    'save_path',
    'delete_except_tags',
    'qb_category',
    'freeleech',
    'hr',
  };

  static const nullableNumberKeys = {
    'disksize',
    'maxupspeed',
    'maxdlspeed',
    'maxdlcount',
    'seed_time',
    'hr_seed_time',
    'seed_ratio',
    'seed_size',
    'download_time',
    'seed_avgspeed',
    'seed_inactivetime',
    'up_speed',
    'dl_speed',
    'auto_archive_days',
  };

  static const intKeys = {
    'site_id',
    'brush_interval',
    'check_interval',
    'maxdlcount',
  };
}
