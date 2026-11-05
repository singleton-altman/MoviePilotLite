import 'danmaku_matcher.dart';
import 'danmaku_service.dart';

/// 单源双路并行匹配的输入。
///
/// 文件名、哈希、时长的准备留在调用方（它们各自有独立策略与超时），
/// 管线只负责编排与打分。
class DanmakuMatchInput {
  const DanmakuMatchInput({
    required this.sourceId,
    required this.sourceName,
    required this.queryTitle,
    required this.matchFileName,
    this.fileHash,
    this.durationSec,
    this.season,
    this.episode,
  });

  final String sourceId;
  final String sourceName;

  /// 名字搜索用的标题（剧集用 seriesName，电影用条目名）。
  final String queryTitle;

  /// 给 /match 用的文件名（真实发布名优先，见 danmakuMatchFileName）。
  final String matchFileName;
  final String? fileHash;
  final int? durationSec;
  final int? season;
  final int? episode;
}

/// 源侧 IO 能力。真实调用包一层 DanmakuService（它的方法是命名参数，
/// 与 typedef 的位置参数签名对不上）；测试注入假实现，不碰 Dio。
typedef MatchV2Fn = Future<DanmakuMatch?> Function(
    String fileName, String? fileHash, int? duration);
typedef SearchFn = Future<List<DanmakuMatch>> Function(String keyword);

/// 双路并行匹配管线（参照 LinPlayer 的 matchAll 思路）：
///
/// ① `/match` 文件识别（真实发布名 + 哈希 + 时长）——弹弹play 生态的主路径；
/// ② `/search` 名字搜索——文件名不规范时的兜底。
/// 两路**并行**发出，互不等待；结果合并去重后按可信度排序。
///
/// 分数设计（沿用 rankDanmakuCandidates 的档位）：
/// - 文件识别唯一命中（episodeId 直出）：**1.8** —— 必须高于搜索路径满分
///   （标题 1.0 + 季号 0.4 = 1.4），保证精确匹配永远排第一；
/// - 文件识别命中但无单集 ID：标题分 + 0.2（有文件名背书，小加成）；
/// - 搜索路径：标题分 + 季号加成（rankDanmakuCandidates 原样采用）。
///   搜索结果不带集号信号（episodeNumber 多为占位 1），所以**不传**
///   episode/episodeOf 给 ranker，集号定位交给选中后的 getBangumiDetail。
class DanmakuMatchPipeline {
  static Future<List<DanmakuMatchCandidate>> matchSource({
    required DanmakuMatchInput input,
    required MatchV2Fn matchV2,
    required SearchFn search,
  }) async {
    final results = await Future.wait([
      _matchPath(input, matchV2),
      _searchPath(input, search),
    ]);
    return mergeDanmakuCandidates(results);
  }

  static Future<List<DanmakuMatchCandidate>> _matchPath(
    DanmakuMatchInput input,
    MatchV2Fn matchV2,
  ) async {
    try {
      final m =
          await matchV2(input.matchFileName, input.fileHash, input.durationSec);
      if (m == null || m.bangumiId.isEmpty) return const [];
      if (m.episodeId != null && m.episodeId!.isNotEmpty) {
        return [
          DanmakuMatchCandidate(
            sourceId: input.sourceId,
            sourceName: input.sourceName,
            bangumiId: m.bangumiId,
            episodeId: m.episodeId,
            title: m.title,
            episodeNumber: input.episode,
            danmakuCount: m.count,
            score: 1.8,
            reason: '文件识别命中',
          ),
        ];
      }
      final t = danmakuTitleScore(input.queryTitle, m.title);
      return [
        DanmakuMatchCandidate(
          sourceId: input.sourceId,
          sourceName: input.sourceName,
          bangumiId: m.bangumiId,
          title: m.title,
          episodeNumber: input.episode,
          danmakuCount: m.count,
          score: t + 0.2,
          reason: '文件识别（无单集ID） · 标题相似 ${(t * 100).round()}%',
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<List<DanmakuMatchCandidate>> _searchPath(
    DanmakuMatchInput input,
    SearchFn search,
  ) async {
    try {
      final matches = await search(input.queryTitle);
      final ranked = rankDanmakuCandidates<DanmakuMatch>(
        matches,
        query: input.queryTitle,
        titleOf: (m) => m.title,
        season: input.season,
      );
      return ranked
          .map((r) => DanmakuMatchCandidate(
                sourceId: input.sourceId,
                sourceName: input.sourceName,
                bangumiId: r.value.bangumiId,
                title: r.value.title,
                danmakuCount: r.value.count,
                score: r.score,
                reason: r.reason,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
