/// 轨道标题解析（字幕轨 / 音轨通用）。
///
/// ## 名字为什么总是不对
///
/// 三个来源各有各的坑，之前的实现只处理了第一个：
///
/// 1. **大小写不一致。** 服务端（Emby/Jellyfin）的 MediaStreams 用首字母大写的
///    key（DisplayTitle / Title / Language / Codec），引擎（mpv / Exo）用小写。
///    只查小写会让服务端轨道全都退化成"轨 N"。
///
/// 2. **引擎会自己伪造标题。** mpv 在真实标题缺失时把 `title` 填成
///    `'音轨 3'` 这种占位串。于是"优先用 title"的顺序反而**优先选中了占位符**，
///    把本可以拼出来的「日语 FLAC 5.1」挤掉了。所以这里要认出并丢弃占位标题。
///
/// 3. **兜底直接吐语言码。** 上一版在没有标题时 `return lang`，屏幕上就是
///    `chi` / `jpn` / `und` —— 对用户来说这跟没有名字没区别。现在兜底改成
///    **拼一个可读名**：语言名 + 编码 + 声道 + 内封/外挂，同语言多轨再加序号。
library;

/// ISO 639-1/639-2 语言码 → 中文名。
///
/// 只收常见的；命中不了就原样返回语言码（比显示"未知"信息量大）。
const Map<String, String> _languageNames = {
  'zh': '中文', 'chi': '中文', 'zho': '中文',
  'chs': '简体中文', 'cht': '繁体中文',
  'zh-cn': '简体中文', 'zh-hans': '简体中文',
  'zh-tw': '繁体中文', 'zh-hk': '繁体中文', 'zh-hant': '繁体中文',
  'yue': '粤语', 'can': '粤语',
  'en': '英语', 'eng': '英语',
  'ja': '日语', 'jpn': '日语',
  'ko': '韩语', 'kor': '韩语',
  'fr': '法语', 'fre': '法语', 'fra': '法语',
  'de': '德语', 'ger': '德语', 'deu': '德语',
  'es': '西班牙语', 'spa': '西班牙语',
  'pt': '葡萄牙语', 'por': '葡萄牙语',
  'ru': '俄语', 'rus': '俄语',
  'it': '意大利语', 'ita': '意大利语',
  'th': '泰语', 'tha': '泰语',
  'vi': '越南语', 'vie': '越南语',
  'ar': '阿拉伯语', 'ara': '阿拉伯语',
  'hi': '印地语', 'hin': '印地语',
  'id': '印尼语', 'ind': '印尼语',
  'ms': '马来语', 'may': '马来语', 'msa': '马来语',
  'und': '未知语言', 'mul': '多语言',
};

/// 语言码 → 可读语言名。
String languageName(String? code) {
  final c = (code ?? '').trim().toLowerCase();
  if (c.isEmpty) return '';
  return _languageNames[c] ?? code!.trim();
}

/// 判断标题是否只是引擎/服务端拼的占位串。
///
/// mpv 的 `'音轨 3'`、Exo 的 `'Audio 2'`、我们自己历史上的 `'轨 1'` 都属于
/// 这一类：它们不含任何真实信息，却会挡住下面拼可读名的逻辑。
bool isPlaceholderTrackTitle(String title) {
  final t = title.trim();
  if (t.isEmpty) return true;
  // 「音轨 3」「字幕 2」「轨 1」「Audio 2」「Subtitle 1」「Track 4」
  return RegExp(
    r'^(音轨|字幕轨?|轨(道)?|audio|subtitle|sub|track)\s*[#]?\d+$',
    caseSensitive: false,
  ).hasMatch(t);
}

/// 读一个可能是大写 key 也可能是小写 key 的字段。
String _field(Map<String, dynamic> t, List<String> keys) {
  for (final k in keys) {
    final v = t[k];
    if (v != null) {
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
  }
  return '';
}

/// 声道数 → 习惯叫法（2 → 立体声，6 → 5.1）。
String _channelLabel(String raw) {
  final n = int.tryParse(raw.trim());
  if (n == null) return raw.trim();
  return switch (n) {
    1 => '单声道',
    2 => '立体声',
    6 => '5.1',
    8 => '7.1',
    _ => '${n}ch',
  };
}

/// 轨道的可读名。
///
/// [siblings] 给出同类轨道全集时，同语言的多条轨道会带上序号
/// （「中文 #1」「中文 #2」），否则两条中文字幕在列表里长得一模一样、没法选。
String trackDisplayTitle(
  Map<String, dynamic> track, {
  int? index,
  String prefix = '轨',
  List<Map<String, dynamic>>? siblings,
}) {
  // 1) 服务端给的可读名最可信（Emby 的 DisplayTitle 形如
  //    "Chinese - PGSSUB" / "English - Dolby Digital - 5.1 - Default"）
  final display = _field(track, const ['DisplayTitle', 'displayTitle']);
  if (display.isNotEmpty && !isPlaceholderTrackTitle(display)) return display;

  // 2) 人工填的标题（压制组常写「简日双语」这类），但要排除占位串
  final title = _field(track, const ['Title', 'title']);
  if (title.isNotEmpty && !isPlaceholderTrackTitle(title)) return title;

  // 3) 拼一个：语言 + 编码 + 声道 + 内封/外挂
  final langCode = _field(track, const ['Language', 'language', 'lang']);
  final lang = languageName(langCode);
  final codec = _field(track, const ['Codec', 'codec']).toUpperCase();
  final channels = _field(track, const ['Channels', 'channels', 'audiochannels']);
  final isExternal = track['IsExternal'] == true || track['isExternal'] == true;

  final parts = <String>[
    if (lang.isNotEmpty) lang,
    if (codec.isNotEmpty) codec,
    if (channels.isNotEmpty) _channelLabel(channels),
  ];

  if (parts.isNotEmpty) {
    // 同语言多轨时加序号，否则列表里分不出谁是谁
    if (siblings != null && langCode.isNotEmpty) {
      final sameLang = siblings
          .where((s) =>
              _field(s, const ['Language', 'language', 'lang']).toLowerCase() ==
              langCode.toLowerCase())
          .toList();
      if (sameLang.length > 1) {
        final pos = sameLang.indexOf(track);
        if (pos >= 0) parts.add('#${pos + 1}');
      }
    }
    parts.add(isExternal ? '外挂' : '内封');
    return parts.join(' · ');
  }

  // 4) 实在什么都没有
  return index != null ? '$prefix ${index + 1}' : prefix;
}
