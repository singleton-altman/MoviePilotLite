import 'package:hive_ce/hive.dart';

part 'search_history.g.dart';

@HiveType(typeId: 8)
class SearchHistoryEntry {
  /// 归一化后的关键字，用于去重
  @HiveField(0)
  String id;

  /// 用户实际输入的关键字，保持原大小写
  @HiveField(1)
  String keyword;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  SearchHistoryEntry(this.id, this.keyword, this.createdAt, this.updatedAt);
}
