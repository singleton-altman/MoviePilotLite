import 'package:get/get.dart';
import 'package:realm/realm.dart';

class RealmService extends GetxService {
  RealmService();

  Realm get realm =>
      throw UnsupportedError('Realm 在 Web 上不可用');
}
