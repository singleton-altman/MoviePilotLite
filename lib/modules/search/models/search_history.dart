/// Search history entry keyed by normalized keyword.
class SearchHistoryEntry {
  /// Normalized keyword for dedup
  final String id;

  /// User-typed keyword preserving original casing
  final String keyword;

  final DateTime createdAt;
  final DateTime updatedAt;

  const SearchHistoryEntry({
    required this.id,
    required this.keyword,
    required this.createdAt,
    required this.updatedAt,
  });
}
