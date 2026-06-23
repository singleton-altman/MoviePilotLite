import 'package:realm/realm.dart';

part 'search_history.realm.dart';

@RealmModel()
class _SearchHistoryEntry {
  /// 归一化后的关键字，用于去重
  @PrimaryKey()
  late String id;

  /// 用户实际输入的关键字，保持原大小写
  late String keyword;

  late DateTime createdAt;

  late DateTime updatedAt;
}
