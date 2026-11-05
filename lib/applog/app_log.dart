import 'package:get/get.dart';
import 'package:talker/talker.dart';

class AppLog extends GetxService {
  final _talker = Talker(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: true,
      maxHistoryItems: 100,
    ),
  );

  Talker get talker => _talker;

  void init() {
    _talker.log("Log init");
  }

  void debug(String message) {
    _talker.log(message);
  }

  void error(String message) {
    _talker.error(message);
  }

  void warning(String message) {
    _talker.warning(message);
  }

  void info(String message) {
    _talker.info(message);
  }

  void handle(Object e, {StackTrace? stackTrace, dynamic message}) {
    _talker.error(message);
    // _talker.handle(e, stackTrace, message);
  }
}
