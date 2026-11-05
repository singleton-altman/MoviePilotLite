import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingsOptionVisual {
  const SettingsOptionVisual({this.icon, this.asset, this.color});

  final IconData? icon;
  final String? asset;
  final Color? color;
}

const Map<String, Map<String, SettingsOptionVisual>> settingsOptionVisuals = {
  'WALLPAPER': {
    'tmdb': SettingsOptionVisual(icon: Icons.movie_outlined),
    'bing': SettingsOptionVisual(icon: Icons.image_outlined),
    'mediaserver': SettingsOptionVisual(icon: Icons.dns_outlined),
    'custom': SettingsOptionVisual(icon: Icons.link_outlined),
    'none': SettingsOptionVisual(icon: Icons.block_outlined),
  },
  'RECOGNIZE_SOURCE': {
    'themoviedb': SettingsOptionVisual(icon: Icons.public_outlined),
    'douban': SettingsOptionVisual(icon: Icons.local_movies_outlined),
  },
  'SEARCH_SOURCE': {
    'themoviedb': SettingsOptionVisual(icon: Icons.public_outlined),
    'douban': SettingsOptionVisual(icon: Icons.local_movies_outlined),
    'bangumi': SettingsOptionVisual(icon: Icons.tv_outlined),
  },
  'SCRAP_SOURCE': {
    'douban': SettingsOptionVisual(asset: 'assets/images/logos/douban.png'),
    'themoviedb': SettingsOptionVisual(asset: 'assets/images/logos/tmdb.png'),
  },
  'LLM_PROVIDER': {
    'deepseek': SettingsOptionVisual(icon: Icons.psychology_alt_outlined),
    'openai': SettingsOptionVisual(icon: Icons.auto_awesome_outlined),
    'google': SettingsOptionVisual(icon: Icons.cloud_outlined),
  },
  'DIR_MONITOR_TYPE': {
    'monitor': SettingsOptionVisual(icon: Icons.remove_red_eye_outlined),
    'downloader': SettingsOptionVisual(icon: Icons.download_outlined),
    'manual': SettingsOptionVisual(icon: Icons.pan_tool_outlined),
    'none': SettingsOptionVisual(icon: Icons.block_outlined),
  },
  'DIR_TRANSFER_TYPE': {
    'copy': SettingsOptionVisual(icon: Icons.copy_all_outlined),
    'move': SettingsOptionVisual(icon: Icons.drive_file_move_outline),
    'softlink': SettingsOptionVisual(icon: Icons.link_outlined),
    'link': SettingsOptionVisual(icon: Icons.link),
  },
  'DIR_OVERWRITE_MODE': {
    'always': SettingsOptionVisual(icon: Icons.autorenew),
    'never': SettingsOptionVisual(icon: Icons.do_not_disturb_on_outlined),
    'size': SettingsOptionVisual(icon: Icons.swap_vert),
    'latest': SettingsOptionVisual(icon: Icons.schedule),
  },
  'DIR_MEDIA_TYPE': {
    '': SettingsOptionVisual(icon: Icons.all_inclusive),
    '电影': SettingsOptionVisual(icon: Icons.movie_outlined),
    '电视剧': SettingsOptionVisual(icon: Icons.tv_outlined),
  },
};

Widget? buildSettingsOptionLeading(
  BuildContext context,
  String enumKey,
  String value,
) {
  final visual = settingsOptionVisuals[enumKey]?[value.toLowerCase()];
  if (visual == null) return null;
  if (visual.asset != null) {
    final path = visual.asset!;
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, width: 18, height: 18, fit: BoxFit.contain);
    }
    return Image.asset(path, width: 18, height: 18, fit: BoxFit.contain);
  }
  if (visual.icon != null) {
    return Icon(
      visual.icon,
      size: 18,
      color: visual.color ?? Theme.of(context).colorScheme.primary,
    );
  }
  return null;
}
