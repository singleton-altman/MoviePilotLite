/// 弹幕匹配解析器 —— 评分制选作品 + 集号智能挑选 + 系列级锚点记源。
///
/// 移植 linplayer 的最佳实践（lib/core/utils/danmaku_matcher.dart）：
/// - 标题相似度：归一化（去空白/标点/季号）后完全相等 1.0、包含 0.7、
///   字符二元组 Jaccard × 0.6
/// - 季匹配：正确季 +0.3、错季 -0.5、无季信息中性 —— 错季必须比无季更不可信
/// - 可信阈值 0.5：低于不自动上屏，宁缺毋错
/// - 集号挑选：精确集号 → 「第N话」抽数字 → 位置回退；空列表绝不瞎选
///
/// 全部纯逻辑，无 IO，单测覆盖（test/danmaku_match_resolver_test.dart）。
library;

/// 归一化标题：小写、去空白与中英文标点、剥「第N季/部」
String normalizeTitle(String s) {
  return s
      .toLowerCase()
      .replaceAll(RegExp(r'[\s\-_:：·・,，.。!！?？\[\]\(\)（）'']'), '')
      .replaceAll(RegExp(r'第[一二三四五六七八九十\d]+[季部]'), '')
      .trim();
}

/// 标题相似度 0~1：完全相等 1.0，包含 0.7，二元组 Jaccard × 0.6
double titleScore(String query, String candidate) {
  final q = normalizeTitle(query);
  final c = normalizeTitle(candidate);
  if (q.isEmpty || c.isEmpty) return 0;
  if (q == c) return 1.0;
  if (c.contains(q) || q.contains(c)) return 0.7;
  final qg = _bigrams(q);
  final cg = _bigrams(c);
  if (qg.isEmpty || cg.isEmpty) return 0;
  final inter = qg.intersection(cg).length;
  final union = qg.union(cg).length;
  return union == 0 ? 0 : (inter / union) * 0.6;
}

Set<String> _bigrams(String s) {
  final set = <String>{};
  for (var i = 0; i < s.length - 1; i++) {
    set.add(s.substring(i, i + 2));
  }
  if (s.length == 1) set.add(s);
  return set;
}

/// 从候选标题抽季号（「第二季」/「Season 2」/「S2」），无则 null
int? extractSeasonFromTitle(String title) {
  final lower = title.toLowerCase();
  final cn = RegExp(r'第([一二三四五六七八九十\d]+)季').firstMatch(lower);
  if (cn != null) return _parseCnNum(cn.group(1)!);
  final en = RegExp(r'season\s*(\d+)|s(\d{1,2})(?!\d)').firstMatch(lower);
  if (en != null) return int.tryParse(en.group(1) ?? en.group(2) ?? '');
  return null;
}

int _parseCnNum(String s) {
  const map = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '七': 7, '八': 8, '九': 9, '十': 10};
  if (map.containsKey(s)) return map[s]!;
  return int.tryParse(s) ?? 0;
}

/// 带综合分的候选
class ScoredCandidate<T> {
  const ScoredCandidate(this.item, this.score);
  final T item;
  final double score;
}

/// 自动上屏的可信阈值（linplayer 同款）：低于此分宁可不上，宁缺毋错
const double danmakuConfidentThreshold = 0.5;

bool isConfidentMatch(double score) => score >= danmakuConfidentThreshold;

/// 对番剧级候选打综合分并降序排序：
/// 综合分 = titleScore(剧名, 候选标题) + 季加成（正确季 +0.3 / 错季 -0.5 / 无季 0）
List<ScoredCandidate<T>> rankSeries<T>(
  List<T> items, {
  required String seriesTitle,
  required int? season,
  required String Function(T) titleOf,
  int? Function(T)? seasonOf,
}) {
  double scoreOf(T item) {
    final base = titleScore(seriesTitle, titleOf(item));
    final s = seasonOf?.call(item);
    if (season == null || s == null) return base;
    return base + (s == season ? 0.3 : -0.5);
  }

  final scored = items.map((it) => ScoredCandidate(it, scoreOf(it))).toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return scored;
}

/// 从番剧详情的集列表里挑目标集：精确集号 → 「第N话」抽数字 → 位置回退。
/// [episodes] 是原始 Map 列表（兼容 episodeNumber/episode_number/number 字段）。
Map<String, dynamic>? pickEpisode(List<dynamic> episodes, int? target) {
  if (episodes.isEmpty) return null;
  if (target == null) {
    return Map<String, dynamic>.from(episodes.first as Map);
  }
  String? numOf(dynamic ep) =>
      (ep['episodeNumber'] ?? ep['episode_number'] ?? ep['number'] ?? ep['ep'] ?? ep['index'])
          ?.toString();
  // 1) 精确/抽数字命中
  for (final ep in episodes) {
    final n = numOf(ep);
    if (n == null) continue;
    if (int.tryParse(n) == target) return Map<String, dynamic>.from(ep as Map);
    final digits = RegExp(r'\d+').firstMatch(n)?.group(0);
    if (digits != null && int.tryParse(digits) == target) {
      return Map<String, dynamic>.from(ep as Map);
    }
  }
  // 2) 集号越界按位置回退（部分源集号不规整）
  if (target >= 1 && target <= episodes.length) {
    return Map<String, dynamic>.from(episodes[target - 1] as Map);
  }
  return null;
}

/// 系列级锚点：记住「这部作品匹配到了哪个弹幕系列(bangumiId)」，
/// 下一集免搜索直取同作品按集号解析，空结果回退全量匹配。
class DanmakuSeriesAnchor {
  const DanmakuSeriesAnchor({required this.bangumiId, required this.lastEpisodeNumber});
  final String bangumiId;
  final int lastEpisodeNumber;
}

class DanmakuSeriesAnchorStore {
  final Map<String, DanmakuSeriesAnchor> _anchors = {};

  /// 锚点键：归一化剧名 + 季（不同季是不同锚点，防跨季错集）
  String keyOf({required String seriesTitle, int? season}) =>
      '${normalizeTitle(seriesTitle)}|S${season ?? 0}';

  void remember({
    required String seriesTitle,
    required int? season,
    required String bangumiId,
    required int episodeNumber,
  }) {
    _anchors[keyOf(seriesTitle: seriesTitle, season: season)] = DanmakuSeriesAnchor(
        bangumiId: bangumiId, lastEpisodeNumber: episodeNumber);
  }

  DanmakuSeriesAnchor? anchorFor({required String seriesTitle, int? season}) =>
      _anchors[keyOf(seriesTitle: seriesTitle, season: season)];
}
