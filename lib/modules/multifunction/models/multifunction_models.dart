import 'package:flutter/material.dart';

enum MultifunctionCardStyle { hero, tall, compact, wide }

enum MultifunctionSectionLayout { mosaic, grouped }

class MultifunctionItem {
  const MultifunctionItem({
    required this.title,
    required this.icon,
    required this.accent,
    required this.style,
    this.subtitle,
    this.badge,
    this.meta,
    this.route,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final MultifunctionCardStyle style;
  final String? badge;
  final String? meta;
  final String? route;
}

class MultifunctionSection {
  const MultifunctionSection({
    required this.title,
    required this.items,
    this.layout = MultifunctionSectionLayout.mosaic,
  });

  final String title;
  final List<MultifunctionItem> items;
  final MultifunctionSectionLayout layout;
}

class PluginSidebarNavItem {
  const PluginSidebarNavItem({
    required this.pluginId,
    required this.navKey,
    required this.title,
    required this.icon,
    required this.section,
    required this.permission,
    required this.order,
  });

  final String pluginId;
  final String navKey;
  final String title;
  final String icon;
  final String section;
  final String permission;
  final int order;

  factory PluginSidebarNavItem.fromJson(Map<String, dynamic> json) {
    final orderRaw = json['order'];
    var order = 0;
    if (orderRaw is int) {
      order = orderRaw;
    } else if (orderRaw is num) {
      order = orderRaw.toInt();
    } else if (orderRaw is String) {
      order = int.tryParse(orderRaw) ?? 0;
    }
    return PluginSidebarNavItem(
      pluginId: json['plugin_id']?.toString() ?? '',
      navKey: json['nav_key']?.toString() ?? 'main',
      title: json['title']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      permission: json['permission']?.toString() ?? '',
      order: order,
    );
  }
}
