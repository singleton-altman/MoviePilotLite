import 'package:hive_ce/hive.dart';

part 'media_detail_cache.g.dart';

@HiveType(typeId: 1)
class MediaDetailCache {
  @HiveField(0)
  String id;

  @HiveField(1)
  String server;

  @HiveField(2)
  String path;

  @HiveField(3)
  String? title;

  @HiveField(4)
  String? year;

  @HiveField(5)
  String? typeName;

  @HiveField(6)
  String? session;

  @HiveField(7)
  String payload;

  @HiveField(8)
  DateTime updatedAt;

  MediaDetailCache(
    this.id,
    this.server,
    this.path,
    this.payload,
    this.updatedAt, {
    this.title,
    this.year,
    this.typeName,
    this.session,
  });
}
