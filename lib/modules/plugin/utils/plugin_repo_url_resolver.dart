import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';

/// 已安装插件常缺 repo_url，按优先级反推可安装仓库地址。
class PluginRepoUrlResolver {
  static const defaultOfficialRepo =
      'https://github.com/jxxghp/MoviePilot-Plugins';

  static String normalize(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return '';

    if (value.startsWith('git@github.com:')) {
      final path = value
          .substring('git@github.com:'.length)
          .replaceFirst(RegExp(r'\.git$'), '');
      return 'https://github.com/$path';
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return value.replaceFirst(RegExp(r'\.git$'), '');
    }
    final normalizedPath = uri.path.replaceFirst(RegExp(r'\.git$'), '');
    return uri
        .replace(scheme: uri.scheme.isEmpty ? 'https' : uri.scheme, path: normalizedPath)
        .toString()
        .replaceFirst(RegExp(r'/$'), '');
  }

  static List<String> parseMarketRepos(String? pluginMarket) {
    final raw = pluginMarket?.trim() ?? '';
    if (raw.isEmpty) return const [];
    return raw
        .split(RegExp(r'[\n,;]+'))
        .map(normalize)
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  /// 从 author_url 反推可能的插件市场仓库。
  /// 例：https://github.com/thsrite → https://github.com/thsrite/MoviePilot-Plugins
  static List<String> inferFromAuthorUrl(String? authorUrl) {
    final normalized = normalize(authorUrl);
    if (normalized.isEmpty) return const [];
    final uri = Uri.tryParse(normalized);
    if (uri == null) return const [];
    final host = uri.host.toLowerCase();
    if (host != 'github.com' && host != 'www.github.com') {
      return const [];
    }
    final segments = uri.pathSegments
        .where((s) => s.trim().isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) return const [];
    if (segments.length == 1) {
      return ['https://github.com/${segments[0]}/MoviePilot-Plugins'];
    }
    return ['https://github.com/${segments[0]}/${segments[1]}'];
  }

  static List<String> candidatesFor(
    PluginItem item, {
    String? cachedRepoUrl,
    List<String> marketRepos = const [],
  }) {
    final out = <String>[];
    void add(String? value) {
      final n = normalize(value);
      if (n.isEmpty || out.contains(n)) return;
      out.add(n);
    }

    add(item.repoUrl);
    add(cachedRepoUrl);
    for (final repo in marketRepos) {
      add(repo);
    }
    add(defaultOfficialRepo);
    // author_url 仅作兜底（作者主页 ≠ 插件市场仓）
    for (final repo in inferFromAuthorUrl(item.authorUrl)) {
      add(repo);
    }
    return out;
  }

  static String? primaryFor(
    PluginItem item, {
    String? cachedRepoUrl,
    List<String> marketRepos = const [],
  }) {
    final list = candidatesFor(
      item,
      cachedRepoUrl: cachedRepoUrl,
      marketRepos: marketRepos,
    );
    return list.isEmpty ? null : list.first;
  }
}
