/// Cached media detail payload for offline/fast access.
class MediaDetailCache {
  final String id;
  final String server;
  final String path;
  final String? title;
  final String? year;
  final String? typeName;
  final String? session;
  final String payload;
  final DateTime updatedAt;

  const MediaDetailCache({
    required this.id,
    required this.server,
    required this.path,
    this.title,
    this.year,
    this.typeName,
    this.session,
    required this.payload,
    required this.updatedAt,
  });
}
