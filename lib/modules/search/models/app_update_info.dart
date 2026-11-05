class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.tagName,
    required this.releaseName,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkAssetName,
    required this.apkSize,
    this.publishedAt,
  });

  final String currentVersion;
  final int? currentBuildNumber;
  final String latestVersion;
  final int? latestBuildNumber;
  final String tagName;
  final String releaseName;
  final String releaseUrl;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String apkAssetName;
  final int? apkSize;
  final DateTime? publishedAt;

  String get currentLabel => currentBuildNumber == null
      ? currentVersion
      : '$currentVersion+$currentBuildNumber';

  String get latestLabel => latestBuildNumber == null
      ? latestVersion
      : '$latestVersion+$latestBuildNumber';

  bool get hasApk => apkDownloadUrl.isNotEmpty;

  bool get isNewer {
    final current = _ParsedAppVersion(currentVersion, currentBuildNumber);
    final latest = _ParsedAppVersion(latestVersion, latestBuildNumber);
    return latest.compareTo(current) > 0;
  }
}

class ParsedReleaseVersion {
  const ParsedReleaseVersion({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final int? buildNumber;

  static ParsedReleaseVersion fromText(String text) {
    final match = RegExp(
      r'v?(\d+(?:\.\d+){0,3})(?:\+(\d+))?',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return const ParsedReleaseVersion(version: '0.0.0', buildNumber: null);
    }
    return ParsedReleaseVersion(
      version: match.group(1) ?? '0.0.0',
      buildNumber: int.tryParse(match.group(2) ?? ''),
    );
  }
}

class _ParsedAppVersion implements Comparable<_ParsedAppVersion> {
  _ParsedAppVersion(String version, this.buildNumber)
    : parts = _parseVersionParts(version);

  final List<int> parts;
  final int? buildNumber;

  static List<int> _parseVersionParts(String version) {
    final clean = ParsedReleaseVersion.fromText(version).version;
    final values = clean
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    while (values.length < 3) {
      values.add(0);
    }
    return values.take(3).toList(growable: false);
  }

  @override
  int compareTo(_ParsedAppVersion other) {
    for (var i = 0; i < 3; i++) {
      final diff = parts[i].compareTo(other.parts[i]);
      if (diff != 0) return diff;
    }
    final leftBuild = buildNumber;
    final rightBuild = other.buildNumber;
    if (leftBuild == null || rightBuild == null) return 0;
    return leftBuild.compareTo(rightBuild);
  }
}
