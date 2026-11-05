import 'package:moviepilot_mobile/modules/plugin/models/plugin_models.dart';

enum PluginBackupDiffKind {
  added,
  removed,
  changed,
  same,
}

class PluginBackupDiffEntry {
  const PluginBackupDiffEntry({
    required this.kind,
    required this.id,
    this.left,
    this.right,
  });

  final PluginBackupDiffKind kind;
  final String id;
  final PluginItem? left;
  final PluginItem? right;

  PluginItem? get installCandidate {
    switch (kind) {
      case PluginBackupDiffKind.added:
      case PluginBackupDiffKind.changed:
        return right;
      case PluginBackupDiffKind.removed:
        return left;
      case PluginBackupDiffKind.same:
        return right ?? left;
    }
  }

  String get displayName =>
      (right ?? left)?.pluginName.trim().isNotEmpty == true
      ? (right ?? left)!.pluginName
      : id;

  String get leftVersion => (left?.pluginVersion ?? '').trim();
  String get rightVersion => (right?.pluginVersion ?? '').trim();
}

class PluginBackupDiffResult {
  const PluginBackupDiffResult({
    required this.entries,
    required this.leftLabel,
    required this.rightLabel,
  });

  final List<PluginBackupDiffEntry> entries;
  final String leftLabel;
  final String rightLabel;

  List<PluginBackupDiffEntry> ofKind(PluginBackupDiffKind kind) =>
      entries.where((e) => e.kind == kind).toList(growable: false);

  int get addedCount => ofKind(PluginBackupDiffKind.added).length;
  int get removedCount => ofKind(PluginBackupDiffKind.removed).length;
  int get changedCount => ofKind(PluginBackupDiffKind.changed).length;
  int get sameCount => ofKind(PluginBackupDiffKind.same).length;
}

PluginBackupDiffResult computePluginBackupDiff({
  required List<PluginItem> left,
  required List<PluginItem> right,
  required String leftLabel,
  required String rightLabel,
}) {
  final leftMap = <String, PluginItem>{
    for (final item in left)
      if (item.id.trim().isNotEmpty) item.id: item,
  };
  final rightMap = <String, PluginItem>{
    for (final item in right)
      if (item.id.trim().isNotEmpty) item.id: item,
  };
  final ids = {...leftMap.keys, ...rightMap.keys}.toList()..sort();
  final entries = <PluginBackupDiffEntry>[];
  for (final id in ids) {
    final l = leftMap[id];
    final r = rightMap[id];
    if (l == null && r != null) {
      entries.add(
        PluginBackupDiffEntry(
          kind: PluginBackupDiffKind.added,
          id: id,
          right: r,
        ),
      );
      continue;
    }
    if (l != null && r == null) {
      entries.add(
        PluginBackupDiffEntry(
          kind: PluginBackupDiffKind.removed,
          id: id,
          left: l,
        ),
      );
      continue;
    }
    if (l != null && r != null) {
      final changed = _isChanged(l, r);
      entries.add(
        PluginBackupDiffEntry(
          kind: changed
              ? PluginBackupDiffKind.changed
              : PluginBackupDiffKind.same,
          id: id,
          left: l,
          right: r,
        ),
      );
    }
  }
  entries.sort((a, b) {
    final kindOrder = a.kind.index.compareTo(b.kind.index);
    if (kindOrder != 0) return kindOrder;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  return PluginBackupDiffResult(
    entries: entries,
    leftLabel: leftLabel,
    rightLabel: rightLabel,
  );
}

bool _isChanged(PluginItem left, PluginItem right) {
  String norm(String? v) => (v ?? '').trim();
  return norm(left.pluginVersion) != norm(right.pluginVersion) ||
      norm(left.pluginName) != norm(right.pluginName) ||
      norm(left.repoUrl) != norm(right.repoUrl) ||
      norm(left.pluginAuthor) != norm(right.pluginAuthor);
}
