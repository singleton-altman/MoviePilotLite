import 'package:flutter/material.dart';
import 'package:moviepilot_mobile/modules/multifunction/models/multifunction_models.dart';

const List<MultifunctionSection> multifunctionSections = [
  MultifunctionSection(
    title: '开始',
    items: [
      MultifunctionItem(
        title: '搜索结果',
        subtitle: null,
        icon: Icons.search,
        accent: Color(0xFF5C7CFA),
        style: MultifunctionCardStyle.hero,
        meta: '近期',
        route: '/search-result',
      ),
    ],
  ),
  MultifunctionSection(
    title: '订阅',
    items: [
      MultifunctionItem(
        title: '电影订阅',
        icon: Icons.movie_outlined,
        accent: Color(0xFF5C7CFA),
        style: MultifunctionCardStyle.tall,
        route: '/subscribe-movie',
      ),
      MultifunctionItem(
        title: '电视剧订阅',
        icon: Icons.tv,
        accent: Color(0xFF00B894),
        style: MultifunctionCardStyle.tall,
        route: '/subscribe-tv',
      ),
      MultifunctionItem(
        title: '工作流',
        route: '/workflow',
        icon: Icons.account_tree_outlined,
        accent: Color(0xFF0AA8A8),
        style: MultifunctionCardStyle.compact,
      ),
      MultifunctionItem(
        title: '订阅日历',
        icon: Icons.calendar_month_outlined,
        accent: Color(0xFFFFA000),
        style: MultifunctionCardStyle.compact,
        route: '/subscribe-calendar',
      ),
    ],
  ),
  MultifunctionSection(
    title: '整理',
    items: [
      MultifunctionItem(
        title: '下载管理',
        subtitle: '任务队列与速度',
        icon: Icons.download_outlined,
        accent: Color(0xFF3B82F6),
        style: MultifunctionCardStyle.wide,
        route: '/downloader',
      ),
      MultifunctionItem(
        title: '媒体整理',
        subtitle: '命名、归档与去重',
        icon: Icons.folder_outlined,
        accent: Color(0xFF8E44AD),
        style: MultifunctionCardStyle.wide,
        route: '/media-organize',
      ),
      MultifunctionItem(
        title: '文件管理',
        subtitle: '批量清理与归档',
        icon: Icons.snippet_folder_outlined,
        accent: Color(0xFF6D5DF6),
        style: MultifunctionCardStyle.wide,
        route: '/file-manager',
      ),
    ],
  ),
  MultifunctionSection(
    title: '系统',
    layout: MultifunctionSectionLayout.grouped,
    items: [
      MultifunctionItem(
        title: '插件',
        subtitle: '扩展能力管理',
        icon: Icons.grid_view_outlined,
        accent: Color(0xFF8F67FF),
        style: MultifunctionCardStyle.wide,
        route: '/plugin',
      ),
      MultifunctionItem(
        title: '站点管理',
        subtitle: '站点接入与连通性',
        icon: Icons.public_outlined,
        accent: Color(0xFF5C7CFA),
        style: MultifunctionCardStyle.wide,
        route: '/site',
      ),
      MultifunctionItem(
        title: '用户管理',
        subtitle: '权限与访问控制',
        icon: Icons.people_outline,
        accent: Color(0xFF00B894),
        style: MultifunctionCardStyle.wide,
        route: '/user-management',
      ),
      MultifunctionItem(
        title: '设定',
        subtitle: '系统参数配置',
        icon: Icons.settings_outlined,
        accent: Color(0xFFFFA000),
        style: MultifunctionCardStyle.wide,
        route: '/settings',
      ),
    ],
  ),
];
