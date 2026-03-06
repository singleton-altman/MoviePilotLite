import 'package:flutter/material.dart';

/// Vuetify / 动态表单 中使用的颜色与图标映射，用于统一美化表格、芯片等 UI。
class VuetifyMappings {
  VuetifyMappings._();

  /// 解析十六进制颜色（#RRGGBB 或 #AARRGGBB）
  static Color? colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) {
      final r = int.tryParse(s.substring(0, 2), radix: 16);
      final g = int.tryParse(s.substring(2, 4), radix: 16);
      final b = int.tryParse(s.substring(4, 6), radix: 16);
      if (r != null && g != null && b != null) {
        return Color.fromRGBO(r, g, b, 1);
      }
    }
    return null;
  }

  /// Vuetify 颜色名或十六进制 -> Flutter Color
  static Color? colorFromVuetify(String? name) {
    if (name == null || name.isEmpty) return null;
    final hex = colorFromHex(name);
    if (hex != null) return hex;
    return _colorMap[name.toLowerCase()];
  }

  static const Map<String, Color> _colorMap = {
    'success': Color(0xFF4CAF50),
    'error': Color(0xFFF44336),
    'warning': Color(0xFFFF9800),
    'info': Color(0xFF2196F3),
    'primary': Color(0xFF2196F3),
    'secondary': Color(0xFF757575),
    'accent': Color(0xFFFF5722),
    'amber': Color(0xFFFFC107),
    'cyan': Color(0xFF00BCD4),
    'purple': Color(0xFF9C27B0),
    'teal': Color(0xFF009688),
    'indigo': Color(0xFF3F51B5),
    'pink': Color(0xFFE91E63),
    'lime': Color(0xFFCDDC39),
    'brown': Color(0xFF795548),
    'blue': Color(0xFF2196F3),
    'green': Color(0xFF4CAF50),
    'red': Color(0xFFF44336),
    'orange': Color(0xFFFF9800),
    'yellow': Color(0xFFFFEB3B),
    'grey': Color(0xFF9E9E9E),
    'blue-grey': Color(0xFF607D8B),
    'deep-purple': Color(0xFF673AB7),
    'deep-orange': Color(0xFFFF5722),
    'light-blue': Color(0xFF03A9F4),
    'light-green': Color(0xFF8BC34A),
    'grey-lighten-1': Color(0xFFBDBDBD),
    'grey-lighten-2': Color(0xFFE0E0E0),
    'grey-darken-1': Color(0xFF757575),
    'white': Color(0xFFFFFFFF),
    'black': Color(0xFF000000),
  };

  /// MDI 图标名（如 mdi-sync、mdi-crown）-> IconData
  /// VIcon 的图标名通常在 text 字段
  static IconData? iconFromMdi(String? name) {
    if (name == null || name.isEmpty) return null;
    final key = name.toLowerCase().trim();
    return _iconMap[key];
  }

  /// 常用 MDI 名称 -> Material Icons
  static const Map<String, IconData> _iconMap = {
    'mdi-sync': Icons.sync,
    'mdi-check': Icons.check,
    'mdi-close': Icons.close,
    'mdi-check-circle': Icons.check_circle,
    'mdi-close-circle': Icons.cancel,
    'mdi-alert': Icons.warning,
    'mdi-alert-circle': Icons.error,
    'mdi-information': Icons.info,
    'mdi-information-outline': Icons.info_outline,
    'mdi-refresh': Icons.refresh,
    'mdi-refresh-circle': Icons.refresh,
    'mdi-plus': Icons.add,
    'mdi-minus': Icons.remove,
    'mdi-pencil': Icons.edit,
    'mdi-delete': Icons.delete,
    'mdi-download': Icons.download,
    'mdi-upload': Icons.upload,
    'mdi-play': Icons.play_arrow,
    'mdi-pause': Icons.pause,
    'mdi-stop': Icons.stop,
    'mdi-calendar': Icons.calendar_today,
    'mdi-clock': Icons.schedule,
    'mdi-account': Icons.person,
    'mdi-cog': Icons.settings,
    'mdi-home': Icons.home,
    'mdi-arrow-right': Icons.arrow_forward,
    'mdi-arrow-left': Icons.arrow_back,
    'mdi-chevron-down': Icons.expand_more,
    'mdi-chevron-up': Icons.expand_less,
    'mdi-dots-vertical': Icons.more_vert,
    'mdi-dots-horizontal': Icons.more_horiz,
    'mdi-eye': Icons.visibility,
    'mdi-eye-off': Icons.visibility_off,
    'mdi-lock': Icons.lock,
    'mdi-lock-open': Icons.lock_open,
    'mdi-link': Icons.link,
    'mdi-open-in-new': Icons.open_in_new,
    'mdi-content-copy': Icons.copy,
    'mdi-content-save': Icons.save,
    // 勋章墙等统计卡片
    'mdi-office-building': Icons.business,
    'mdi-medal': Icons.emoji_events,
    'mdi-cart-check': Icons.shopping_cart_checkout,
    'mdi-badge-account': Icons.badge,
    'mdi-cancel': Icons.cancel,
    'mdi-help-circle-outline': Icons.help_outline,
    'mdi-crown': Icons.diamond,
    'mdi-star': Icons.star,
    'mdi-star-half': Icons.star_half,
    'mdi-ticket-confirmation': Icons.confirmation_number,
    'mdi-ticket': Icons.confirmation_number,
    'mdi-account-group': Icons.group,
    // 后宫总览 dashboard-stats
    'mdi-domain': Icons.business,
    'mdi-human-queue': Icons.groups,
    'mdi-account-cancel': Icons.person_off,
    'mdi-database-off': Icons.storage_outlined,
    'mdi-store': Icons.store,
    'mdi-diamond': Icons.diamond,
    // TrashClean 插件
    'mdi-power': Icons.power_settings_new,
    'mdi-code-braces': Icons.data_object,
    'mdi-clock-outline': Icons.schedule,
    'mdi-folder-search': Icons.folder_open,
    'mdi-folder-remove': Icons.folder_delete,
    'mdi-folder-off': Icons.folder_off,
    'mdi-package-variant': Icons.inventory_2,
    'mdi-chart-line-variant': Icons.show_chart,
    'mdi-broom': Icons.cleaning_services,
    'mdi-filter': Icons.filter_alt,
    'mdi-history': Icons.history,
    'mdi-progress-clock': Icons.pending,
    'mdi-download-off': Icons.download_done,
    'mdi-flag': Icons.flag,
    // 通用 / 多插件共享
    'mdi-cloud-upload': Icons.cloud_upload,
    'mdi-cloud-download': Icons.cloud_download,
    'mdi-calendar-today': Icons.calendar_today,
    'mdi-movie': Icons.movie,
    'mdi-television': Icons.tv,
    'mdi-television-classic': Icons.tv,
    'mdi-magnify': Icons.search,
    'mdi-delete-sweep': Icons.delete_sweep,
    'mdi-inbox': Icons.inbox,
    'mdi-inbox-outline': Icons.inbox_outlined,
    'mdi-file': Icons.insert_drive_file,
    'mdi-file-document': Icons.description,
    'mdi-image': Icons.image,
    'mdi-video': Icons.videocam,
    'mdi-music': Icons.music_note,
    'mdi-folder': Icons.folder,
    'mdi-folder-open': Icons.folder_open,
    'mdi-heart': Icons.favorite,
    'mdi-heart-outline': Icons.favorite_border,
    'mdi-thumb-up': Icons.thumb_up,
    'mdi-thumb-down': Icons.thumb_down,
    'mdi-share': Icons.share,
    'mdi-send': Icons.send,
    'mdi-email': Icons.email,
    'mdi-phone': Icons.phone,
    'mdi-map-marker': Icons.location_on,
    'mdi-web': Icons.language,
    'mdi-wifi': Icons.wifi,
    'mdi-bluetooth': Icons.bluetooth,
    'mdi-battery': Icons.battery_full,
    'mdi-flash': Icons.flash_on,
    'mdi-lightning-bolt': Icons.flash_on,
    'mdi-database': Icons.storage,
    'mdi-server': Icons.dns,
    'mdi-chip': Icons.memory,
    'mdi-monitor': Icons.monitor,
    'mdi-cellphone': Icons.smartphone,
    'mdi-laptop': Icons.laptop,
    'mdi-printer': Icons.print,
    'mdi-camera': Icons.camera_alt,
    'mdi-microphone': Icons.mic,
    'mdi-volume-high': Icons.volume_up,
    'mdi-bell': Icons.notifications,
    'mdi-bell-outline': Icons.notifications_none,
    'mdi-tag': Icons.label,
    'mdi-bookmark': Icons.bookmark,
    'mdi-bookmark-outline': Icons.bookmark_border,
    'mdi-pin': Icons.push_pin,
    'mdi-clipboard': Icons.content_paste,
    'mdi-chart-bar': Icons.bar_chart,
    'mdi-chart-pie': Icons.pie_chart,
    'mdi-trending-up': Icons.trending_up,
    'mdi-trending-down': Icons.trending_down,
    'mdi-swap-horizontal': Icons.swap_horiz,
    'mdi-swap-vertical': Icons.swap_vert,
    'mdi-sort': Icons.sort,
    'mdi-format-list-bulleted': Icons.format_list_bulleted,
    'mdi-view-grid': Icons.grid_view,
    'mdi-apps': Icons.apps,
    'mdi-menu': Icons.menu,
    'mdi-more-vert': Icons.more_vert,
    'mdi-shield': Icons.shield,
    'mdi-shield-check': Icons.verified_user,
    'mdi-key': Icons.vpn_key,
    'mdi-login': Icons.login,
    'mdi-logout': Icons.logout,
    'mdi-timer': Icons.timer,
    'mdi-timer-sand': Icons.hourglass_empty,
    'mdi-speedometer': Icons.speed,
    'mdi-gauge': Icons.speed,
    'mdi-wrench': Icons.build,
    'mdi-tools': Icons.handyman,
    'mdi-bug': Icons.bug_report,
    'mdi-test-tube': Icons.science,
    'mdi-earth': Icons.public,
    'mdi-translate': Icons.translate,
    'mdi-palette': Icons.palette,
    'mdi-brightness-6': Icons.brightness_6,
    'mdi-weather-sunny': Icons.wb_sunny,
    'mdi-weather-night': Icons.nightlight_round,
    'mdi-trophy': Icons.emoji_events,
    'mdi-gift': Icons.card_giftcard,
    'mdi-fire': Icons.local_fire_department,
    'mdi-water': Icons.water_drop,
    'mdi-leaf': Icons.eco,
    'mdi-paw': Icons.pets,
    'mdi-desktop-mac': Icons.desktop_mac_outlined,
    'mdi-ip': Icons.network_wifi_outlined,
    'mdi-cpu': Icons.cabin_outlined,
    'mdi-memory': Icons.memory_outlined,
    'mdi-harddisk': Icons.storage_outlined,
    'mdi-network': Icons.network_wifi_outlined,
    'mdi-network-off': Icons.network_wifi_outlined,
    'mdi-network-security': Icons.security_outlined,
    'mdi-thermometer': Icons.thermostat_outlined,
    'mdi-chart-line': Icons.show_chart_outlined,
    'mdi-backup-restore': Icons.backup_table_outlined,
    'mdi-file-archive': Icons.file_present_outlined,
    'mdi-snapshot': Icons.camera_alt,
    'mdi-restart': Icons.restart_alt,
    'mdi-client': Icons.laptop_outlined,
    'mdi-cloud': Icons.cloud_outlined,
    'mdi-settings': Icons.settings_outlined,
  };

  /// dashboard-stats 标签 -> MDI 图标名（后端 JSON 无 icon，Web 端按 label 映射）
  static const Map<String, String> _dashboardStatsCaptionToIcon = {
    '站点数量': 'mdi-domain',
    '后宫成员': 'mdi-human-queue',
    '永久邀请数': 'mdi-ticket-confirmation',
    '永久邀请': 'mdi-ticket-confirmation',
    '临时邀请数': 'mdi-ticket',
    '临时邀请': 'mdi-ticket',
    '低分享率': 'mdi-alert-circle',
    '已禁用': 'mdi-account-cancel',
    '无数据': 'mdi-database-off',
  };

  /// 根据 dashboard-stats 标签解析 MDI 图标名
  static String? iconFromDashboardStatsCaption(String? caption) {
    if (caption == null || caption.isEmpty) return null;
    return _dashboardStatsCaptionToIcon[caption.trim()];
  }
}
