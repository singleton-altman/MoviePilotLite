import 'dart:convert';

import '../subtitle/subtitle_codecs.dart';

/// mpv `track-list` 属性（JSON 字符串）→ 宿主引擎的轨道契约。
///
/// mpv 的字段名与宿主约定不同（`lang` / `default`），而宿主用「语言|编码」配对
/// 服务器流（`player_screen._subtitleMatchKey` / `_audioMatchKey`）。字段归一
/// 只在这里做一次，产物与 mpv / Exo 两个内核的轨道 map 形状一致：
/// `id`(mpv 数值 id) / `title` / `language` / `codec` / `isDefault`。
class MpvTrackList {
  const MpvTrackList({this.audio = const [], this.subtitle = const []});

  final List<Map<String, dynamic>> audio;
  final List<Map<String, dynamic>> subtitle;

  static const empty = MpvTrackList();

  /// 解析 mpv 的 track-list JSON。
  ///
  /// 解析失败（属性取不到、mpv 未就绪返回 null、内容不是数组、坏 JSON）一律
  /// 返回空列表 —— 轨道列表只是 UI 数据，不该让播放或切轨流程抛异常。
  static MpvTrackList parse(String? json) {
    if (json == null || json.isEmpty) return empty;
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      return empty;
    }
    if (decoded is! List) return empty;

    final audio = <Map<String, dynamic>>[];
    final subtitle = <Map<String, dynamic>>[];
    for (final raw in decoded) {
      if (raw is! Map) continue;
      // 封面图（image:true 的 video 轨）不是可播轨道
      if (raw['image'] == true) continue;
      final entry = <String, dynamic>{
        // id 保持 mpv 的数值：切轨时直接喂给 sid/aid。
        // 列表下标 ≠ id（外挂轨、未选中轨会让两者错位）
        'id': raw['id'],
        'title': raw['title']?.toString() ?? '',
        'language': raw['lang']?.toString() ?? '',
        'codec': raw['codec']?.toString() ?? '',
        'isDefault': raw['default'] == true,
        'forced': raw['forced'] == true,
        'external': raw['external'] == true,
        'selected': raw['selected'] == true,
      };
      switch (raw['type']) {
        case 'audio':
          audio.add(entry);
        case 'sub':
          entry['isBitmap'] = isBitmapSubtitleCodec(entry['codec'] as String);
          subtitle.add(entry);
      }
    }
    return MpvTrackList(audio: audio, subtitle: subtitle);
  }
}
