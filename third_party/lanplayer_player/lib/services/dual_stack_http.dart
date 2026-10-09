import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../utils/app_log.dart';

/// 创建带「双栈竞速」能力的 Dio。
///
/// 背景:Dart 的 HttpClient 只按 DNS 返回顺序逐个尝试地址,当第一个地址
/// (常见是 IPv4)被拒绝时不会可靠地回退到 IPv6;而 curl/浏览器有
/// Happy Eyeballs 机制所以看起来"域名是好的"。实测场景:域名的 IPv4
/// 端口映射失效、仅 IPv6 可达时,App 全量请求失败而 curl 正常。
///
/// 这里自己解析域名并**并发尝试所有地址**(IPv4/IPv6),先连通的胜出,
/// 从根上消除单栈地址不可达导致的失败。
Dio createDualStackDio({
  required String baseUrl,
  Duration connectTimeout = const Duration(seconds: 10),
  Duration receiveTimeout = const Duration(seconds: 30),
  Map<String, dynamic>? headers,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers,
    ),
  );
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.connectionFactory = dualStackConnectionFactory;
      return client;
    },
  );
  return dio;
}

/// 双栈竞速连接:解析全部地址 → 并发连接 → 第一个成功者胜出,其余取消。
Future<ConnectionTask<Socket>> dualStackConnectionFactory(
  Uri url,
  String? proxyHost,
  int? proxyPort,
) async {
  // 显式代理场景交给底层处理(代理地址通常单一且可达)
  if (proxyHost != null && proxyPort != null) {
    return Socket.startConnect(proxyHost, proxyPort);
  }
  final host = url.host;
  final port = url.port;

  // 已是字面量 IP:直接用
  final literal = InternetAddress.tryParse(host);
  if (literal != null) {
    return Socket.startConnect(literal, port);
  }

  List<InternetAddress> addresses;
  try {
    addresses = await InternetAddress.lookup(
      host,
    ).timeout(const Duration(seconds: 5));
  } catch (e) {
    AppLog.w('Http', 'DNS lookup 失败 $host: $e');
    return Socket.startConnect(host, port);
  }
  if (addresses.isEmpty) {
    return Socket.startConnect(host, port);
  }

  AppLog.i(
    'Http',
    'DNS $host -> ${addresses.map((a) => '${a.address}/${a.type.name}').join(', ')}',
  );

  // 并发发起所有地址的连接
  final tasks = <ConnectionTask<Socket>>[];
  final done = <Completer<bool>>[];
  for (final addr in addresses) {
    try {
      final task = await Socket.startConnect(addr, port);
      tasks.add(task);
      final c = Completer<bool>();
      done.add(c);
      task.socket
          .then((_) {
            if (!c.isCompleted) c.complete(true);
          })
          .catchError((Object _) {
            if (!c.isCompleted) c.complete(false);
          });
    } catch (_) {
      // 该地址发起连接失败,跳过
    }
  }
  if (tasks.isEmpty) return Socket.startConnect(host, port);
  if (tasks.length == 1) return tasks.first;

  // 竞速:第一个成功连接的地址胜出
  final race = Completer<int>();
  for (var i = 0; i < done.length; i++) {
    final idx = i;
    done[i].future.then((ok) {
      if (ok && !race.isCompleted) race.complete(idx);
    });
  }
  int? winner;
  try {
    winner = await race.future.timeout(const Duration(seconds: 10));
  } catch (_) {
    winner = null;
  }
  if (winner == null) {
    for (final t in tasks) {
      t.cancel();
    }
    throw const SocketException('所有地址连接失败');
  }
  if (winner != 0) {
    AppLog.i('Http', '选路成功: ${addresses[winner].address}(跳过不可达地址)');
  }
  for (var i = 0; i < tasks.length; i++) {
    if (i != winner) tasks[i].cancel();
  }
  return tasks[winner];
}
