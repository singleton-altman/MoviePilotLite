/// 弹幕匹配的纯函数部分。
///
/// ## 为什么单独拆出来
///
/// 改造前匹配逻辑整块埋在 `player_screen.dart` 的 `_loadDanmaku()` 里 ——
/// 那个方法要挂弹幕服务、要等引擎报时长、要读 provider，没法测。于是「搜
/// "肖申克的救赎"匹配到不相关番剧」这类问题只能靠肉眼在真机上试。
///
/// 这里把**判断**从**IO**里剥出来：标题归一化、相似度打分、集号比对都是纯
/// 函数，可以直接测。
///
/// ## 与旧实现的差别
///
/// 旧实现是一串特例堆出来的**二元过滤**（`contains` → 去后缀再 `contains`
/// → 前 N 字符相等），通过之后 `bestMatch = similarMatches.first` —— 也就是
/// 过滤完全不排序，命中多个时只看服务端返回顺序。这里改成打分排序，
/// 让"更像的"真的排前面。
///
/// 分档参照 D:\Trae CN\linplayer 的 danmaku_matcher.dart：
/// 完全相等 1.0 / 互相包含 0.7 / 字符二元组 Jaccard × 0.6，集号命中额外 +0.3。
library;

/// 归一化标题，用于相似度比较。
///
/// 去掉标点空白，并**去掉「第N季」「第N部」** —— 这一步是旧实现缺的：
/// Emby 里剧名是「咒术回战」，弹幕源里是「咒术回战 第2季」，不去季号的话
/// 核心标题比对会判失败。
String normalizeDanmakuTitle(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[\s\-_:：·・,，.。!！?？~～、/\\\[\]\(\)（）【】]'), '')
    .replaceAll(RegExp(r'第[一二三四五六七八九十百零\d]+[季部期]'), '')
    // 「最终季 / 最終季 / final season」也要去掉：番剧常这么命名
    // （进击的巨人最终季），不去的话 Emby 的「进击的巨人」跟它对不上。
    .replaceAll(RegExp(r'最[终終][季部期]'), '')
    .replaceAll(RegExp(r'final\s*season', caseSensitive: false), '')
    .replaceAll(RegExp(r'(season|s)\s*\d+', caseSensitive: false), '')
    .trim();

/// 字符二元组集合。用于轻量相似度，不引入编辑距离的开销。
Set<String> danmakuBigrams(String s) {
  final set = <String>{};
  if (s.isEmpty) return set;
  if (s.length == 1) return {s};
  for (var i = 0; i < s.length - 1; i++) {
    set.add(s.substring(i, i + 2));
  }
  return set;
}

/// 标题相似度 0~1。
///
/// 完全相等 1.0；一方包含另一方 0.7；否则按二元组 Jaccard × 0.6。
/// 乘 0.6 是为了让「模糊相似」永远排在「包含」之后 —— 否则短标题的
/// Jaccard 容易虚高，把真正的包含关系挤下去。
double danmakuTitleScore(String query, String candidate) {
  final q = normalizeDanmakuTitle(query);
  final c = normalizeDanmakuTitle(candidate);
  if (q.isEmpty || c.isEmpty) return 0;
  if (q == c) return 1.0;
  if (c.contains(q) || q.contains(c)) return 0.7;
  final qg = danmakuBigrams(q);
  final cg = danmakuBigrams(c);
  if (qg.isEmpty || cg.isEmpty) return 0;
  final union = qg.union(cg).length;
  if (union == 0) return 0;
  return (qg.intersection(cg).length / union) * 0.6;
}

/// 低于此分视为「不相关」，直接不用。
///
/// 0.3 这个门槛的作用是挡住「搜肖申克的救赎返回某部无关番剧」那类情况：
/// 纯 Jaccard 上限是 0.6，0.3 相当于要求二元组重叠一半以上。
const double kDanmakuTitleScoreFloor = 0.3;

/// 从标题里抽季号。「第2季」「S02」「Season 2」都认。
int? extractSeasonFromTitle(String title) {
  const cn = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10};
  final cnMatch = RegExp(r'第([一二三四五六七八九十])[季部期]').firstMatch(title);
  if (cnMatch != null) return cn[cnMatch.group(1)!];
  final numMatch = RegExp(r'第(\d+)[季部期]').firstMatch(title);
  if (numMatch != null) return int.tryParse(numMatch.group(1)!);
  final sMatch =
      RegExp(r'(?:season|s)\s*(\d+)', caseSensitive: false).firstMatch(title);
  if (sMatch != null) return int.tryParse(sMatch.group(1)!);
  return null;
}

/// 集号是否命中。
///
/// 弹幕源的 episodeNumber 不保证是纯数字 —— 「第3话」「03」「EP3」都见过，
/// 所以先尝试直接解析，失败再抽第一段数字。
bool danmakuEpisodeMatches(Object? rawEpisodeNumber, int? target) {
  if (target == null) return false;
  final s = rawEpisodeNumber?.toString().trim() ?? '';
  if (s.isEmpty) return false;
  final direct = int.tryParse(s);
  if (direct != null) return direct == target;
  final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
  return digits != null && int.tryParse(digits) == target;
}

/// 一条候选的打分结果。
class DanmakuCandidateScore<T> {
  const DanmakuCandidateScore(this.value, this.score, this.reason);

  final T value;
  final double score;

  /// 人类可读的打分理由，直接显示在「自动匹配候选」列表上，
  /// 用户能看懂为什么这条排第一。
  final String reason;
}

/// 给候选打分并排序（高分在前），低于门槛的丢掉。
///
/// [titleOf] / [seasonOf] / [episodeOf] 让调用方适配自己的候选类型，
/// 不必让这个模块依赖具体的 DanmakuMatch。
List<DanmakuCandidateScore<T>> rankDanmakuCandidates<T>(
  List<T> candidates, {
  required String query,
  required String Function(T) titleOf,
  int? season,
  int? episode,
  Object? Function(T)? episodeOf,
}) {
  final out = <DanmakuCandidateScore<T>>[];
  for (final c in candidates) {
    final title = titleOf(c);
    var score = danmakuTitleScore(query, title);
    final reasons = <String>[];
    if (score >= 1.0) {
      reasons.add('标题完全一致');
    } else if (score >= 0.7) {
      reasons.add('标题包含');
    } else {
      reasons.add('标题相似 ${(score * 100).round()}%');
    }

    // 季号命中是很强的信号：Emby 的季号和弹幕源标题里的季号对上，
    // 基本可以确定是同一季，给足加成让它压过纯标题分。
    if (season != null) {
      final s = extractSeasonFromTitle(title);
      if (s != null) {
        if (s == season) {
          score += 0.4;
          reasons.add('季号匹配 S$season');
        } else {
          // 季号明确不一致是**反向**信号 —— 第1季和第2季的标题相似度很高，
          // 不扣分的话很容易串季。
          score -= 0.3;
          reasons.add('季号不符（源 S$s）');
        }
      }
    }

    if (episode != null && episodeOf != null) {
      if (danmakuEpisodeMatches(episodeOf(c), episode)) {
        score += 0.3;
        reasons.add('集号匹配 E$episode');
      }
    }

    if (score < kDanmakuTitleScoreFloor) continue;
    out.add(DanmakuCandidateScore(c, score, reasons.join(' · ')));
  }
  out.sort((a, b) => b.score.compareTo(a.score));
  return out;
}

/// 构造给 `/match` 用的文件名。
///
/// **优先真实文件名**（服务端存的发布名，形如
/// `[SubGroup] Title - 05 [1080p][x265].mkv`）。dandanplay 的 `/match` 就是
/// 按发布名设计的，那串信息量远大于我们自己拼的 `Title S01E05` ——
/// 旧实现只拼后者，等于把 `/match` 最擅长的输入丢掉了。
///
/// 拿不到路径时才退回拼装名。
String danmakuMatchFileName({
  String? filePath,
  required String title,
  int? season,
  int? episode,
}) {
  final p = filePath?.trim() ?? '';
  if (p.isNotEmpty) {
    final norm = p.replaceAll('\\', '/');
    final i = norm.lastIndexOf('/');
    final base = i >= 0 ? norm.substring(i + 1) : norm;
    if (base.isNotEmpty) return base;
  }
  if (season != null && episode != null) {
    return '$title S${season.toString().padLeft(2, '0')}'
        'E${episode.toString().padLeft(2, '0')}';
  }
  if (episode != null) {
    return '$title E${episode.toString().padLeft(2, '0')}';
  }
  return title;
}

/// 一条弹幕匹配候选（跨源统一视图）。
///
/// 两条路径都会产出它：
/// - 文件识别路径：`episodeId` 直出（唯一命中，可信度最高）；
/// - 名字搜索路径：通常只有 `bangumiId`，`episodeId` 要等选中后用
///   getBangumiDetail 解析（播放页已有 _matchEpisodeNumber 做集号定位）。
class DanmakuMatchCandidate {
  const DanmakuMatchCandidate({
    required this.sourceId,
    required this.sourceName,
    required this.bangumiId,
    this.episodeId,
    required this.title,
    this.episodeTitle = '',
    this.episodeNumber,
    this.danmakuCount = 0,
    required this.score,
    required this.reason,
  });

  final String sourceId;
  final String sourceName;

  /// 番剧 ID（搜索路径必有；文件识别路径与 episodeId 同源返回）。
  final String bangumiId;

  /// 单集 ID。搜索路径可能为 null —— 用时需 getBangumiDetail 解析。
  final String? episodeId;

  final String title;
  final String episodeTitle;
  final int? episodeNumber;
  final int danmakuCount;

  /// 可信度分，越高越可信。文件识别唯一命中 1.8；搜索路径 = 标题分 + 季号
  /// 加成（rankDanmakuCandidates 产物，满分 1.0+0.4=1.4，搜索路径不带集号）。
  final double score;

  /// 人类可读的打分理由，直接显示在候选列表上。
  final String reason;

  /// 去重/选中态统一键：`sourceId|episodeId(缺省回退 bangumiId)`。
  String get key => '$sourceId|${episodeId ?? bangumiId}';
}

/// 合并多源候选：同源同集去重留高分 → 优先源 +0.01 微调（只影响并列）→ 分数降序。
///
/// 跨源**不**去重：同一集来自两个服务器时都保留，让用户可见可切。
List<DanmakuMatchCandidate> mergeDanmakuCandidates(
  Iterable<List<DanmakuMatchCandidate>> perSource, {
  String? preferredSourceId,
}) {
  final byKey = <String, DanmakuMatchCandidate>{};
  for (final candidates in perSource) {
    for (final c in candidates) {
      final prev = byKey[c.key];
      if (prev == null || c.score > prev.score) byKey[c.key] = c;
    }
  }
  final out = byKey.values.toList()
    ..sort((a, b) {
      final biasA = a.sourceId == preferredSourceId ? 0.01 : 0.0;
      final biasB = b.sourceId == preferredSourceId ? 0.01 : 0.0;
      return (b.score + biasB).compareTo(a.score + biasA);
    });
  return out;
}
