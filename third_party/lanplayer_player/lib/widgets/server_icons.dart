import 'package:flutter/material.dart';

class ServerIcons {
  static const Color embyGreen = Color(0xFF10B981);
  static const Color jellyfinBlue = Color(0xFF00A4DC);
  static const Color fnosBlue = Color(0xFF3B82F6);
  static const Color plexGold = Color(0xFFE5A00D);

  static Widget embyIcon({double size = 24, Color? color}) {
    return Image.asset(
      'assets/images/emby.png',
      width: size,
      height: size,
      color: color,
    );
  }

  static Widget jellyfinIcon({double size = 24, Color? color}) {
    return Image.asset(
      'assets/images/jellyfin.png',
      width: size,
      height: size,
      color: color,
    );
  }

  static Widget fnosIcon({double size = 24, Color? color}) {
    return Image.asset(
      'assets/images/fnos.png',
      width: size,
      height: size,
      color: color,
    );
  }

  static Widget plexIcon({double size = 24, Color? color}) {
    return Icon(Icons.play_circle_rounded, size: size, color: color ?? plexGold);
  }

  static Widget forType(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case 'emby':
        return embyIcon(size: size);
      case 'jellyfin':
        return jellyfinIcon(size: size);
      case 'fnos':
        return fnosIcon(size: size);
      case 'plex':
        return plexIcon(size: size);
      default:
        return Icon(Icons.dns_rounded, size: size, color: Colors.grey);
    }
  }

  static Widget forTypeColored(String type, {double size = 24, bool white = false}) {
    switch (type.toLowerCase()) {
      case 'emby':
        return embyIcon(size: size, color: white ? Colors.white : embyGreen);
      case 'jellyfin':
        return jellyfinIcon(size: size, color: white ? Colors.white : jellyfinBlue);
      case 'fnos':
        return fnosIcon(size: size, color: white ? Colors.white : fnosBlue);
      case 'plex':
        return plexIcon(size: size, color: white ? Colors.white : plexGold);
      default:
        return Icon(Icons.dns_rounded, size: size, color: white ? Colors.white : Colors.grey);
    }
  }

  static Color colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'emby':
        return embyGreen;
      case 'jellyfin':
        return jellyfinBlue;
      case 'fnos':
        return fnosBlue;
      case 'plex':
        return plexGold;
      default:
        return Colors.grey;
    }
  }

  static String nameForType(String type) {
    switch (type.toLowerCase()) {
      case 'emby':
        return 'Emby';
      case 'jellyfin':
        return 'Jellyfin';
      case 'fnos':
        return '飞牛影视';
      case 'plex':
        return 'Plex';
      default:
        return '服务器';
    }
  }

  static String descForType(String type) {
    switch (type.toLowerCase()) {
      case 'emby':
        return '功能丰富，可自部署';
      case 'jellyfin':
        return '免费开源，无会员限制';
      case 'fnos':
        return '飞牛NAS自带影视管理';
      case 'plex':
        return '成熟易用，远程访问完善';
      default:
        return '';
    }
  }
}
