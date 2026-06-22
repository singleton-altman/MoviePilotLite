import 'package:drift_flutter/drift_flutter.dart';
import 'package:get/get.dart';

import '../database/app_database.dart';

/// Central database service — replaces RealmService.
class DatabaseService extends GetxService {
  late final AppDatabase _db;

  AppDatabase get db => _db;

  @override
  Future<void> onInit() async {
    super.onInit();
    _db = AppDatabase(
      driftDatabase(name: 'moviepilot'),
    );
  }

  @override
  void onClose() {
    _db.close();
    super.onClose();
  }
}
