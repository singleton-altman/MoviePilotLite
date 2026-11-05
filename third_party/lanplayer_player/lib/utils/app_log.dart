import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLog {
  static final _logs = Queue<Map<String, dynamic>>();
  static const _max = 200;
  static bool _debugEnabled = false;

  // i/w/e always logged, only d() respects debug toggle
  static void i(String tag, String msg) => _add('INFO', tag, msg);
  static void w(String tag, String msg) => _add('WARN', tag, msg);
  static void e(String tag, String msg, [Object? err]) => _add('ERROR', tag, '$msg${err != null ? ' | $err' : ''}');
  static void d(String tag, String msg) { if (_debugEnabled) _add('DEBUG', tag, msg); }

  static void setDebugEnabled(bool v) => _debugEnabled = v;
  static List<Map<String, dynamic>> get logs => _logs.toList();
  static void clear() => _logs.clear();

  static void _add(String level, String tag, String msg) {
    _logs.addFirst({
      'time': DateTime.now().toIso8601String().substring(11, 19),
      'level': level, 'tag': tag, 'msg': msg,
    });
    if (_logs.length > _max) _logs.removeLast();
    // 同时输出到 logcat：
    // 1. debugPrint → Android logcat 的 "flutter" tag（release/debug 都能抓到）
    // 2. developer.log → Dart VM Service（需要连 Observatory 才能看到）
    final line = '[$level/$tag] $msg';
    debugPrint(line);
    developer.log(line, name: 'lanplayer');
  }
}


