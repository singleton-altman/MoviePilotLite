import 'package:realm/realm.dart';

part 'media_detail_cache.realm.dart';

@RealmModel()
class _MediaDetailCache {
  @PrimaryKey()
  late String id;

  late String server;
  late String path;
  String? title;
  String? year;
  String? typeName;
  String? session;

  late String payload;
  late DateTime updatedAt;
}
