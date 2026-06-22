import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/dashboard/models/statistic_model.dart';
import 'package:moviepilot_mobile/modules/mediaserver/models/latest_media_model.dart';
import 'package:moviepilot_mobile/modules/mediaserver/models/library_model.dart';
import 'package:moviepilot_mobile/modules/mediaserver/models/mediaserver_model.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

/// 媒体服务器控制器
class MediaServerController extends GetxController {
  /// API客户端
  final apiClient = Get.find<ApiClient>();

  /// Talker日志实例
  final talker = Get.find<AppLog>();

  /// 媒体服务器列表
  final mediaServers = Rx<List<MediaServer>>([]);

  /// 媒体库列表
  final mediaLibraries = Rx<List<MediaLibrary>>([]);

  /// 最新添加媒体列表
  final latestMediaList = Rx<List<LatestMedia>>([]);

  /// 正在播放的媒体
  final playingMedia = Rx<List<LatestMedia>?>(null);

  /// 各媒体服务器统计（GET /api/v1/dashboard/statistic?server=xxx）
  final mediaServerStats = <String, StatisticModel>{}.obs;

  Timer? _statsTimer;
  static const Duration _statsInterval = Duration(seconds: 10);

  /// 加载状态
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(mediaServers, (_) => loadMediaServerStats());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        _statsTimer?.cancel();
        _statsTimer = Timer.periodic(
          _statsInterval,
          (_) => loadMediaServerStats(),
        );
      }
    });
    // 加载媒体服务器数据
    loadMediaServers().then((_) {
      loadMediaServerStats();
      // 加载媒体库数据
      loadMediaLibraries().then((_) {
        final servers = mediaServers.value;
        if (servers.isNotEmpty) {
          loadLatestMediaList(servers.first.name);
          loadPlayingMedia(servers.first.name);
        }
      });
    });
  }

  @override
  void onClose() {
    _statsTimer?.cancel();
    _statsTimer = null;
    super.onClose();
  }

  /// 获取指定媒体服务器的统计数据
  StatisticModel? statsFor(String serverName) => mediaServerStats[serverName];

  /// 加载各媒体服务器统计数据（GET /api/v1/dashboard/statistic?server=xxx）
  Future<void> loadMediaServerStats() async {
    final servers = mediaServers.value;
    if (servers.isEmpty || isClosed) return;
    final Map<String, StatisticModel> newStats = {};
    for (final s in servers) {
      if (s.name.isEmpty) continue;
      try {
        final resp = await apiClient.get<Map<String, dynamic>>(
          '/api/v1/dashboard/statistic',
          queryParameters: {'server': s.name},
        );
        if (resp.statusCode == 200 && resp.data != null) {
          newStats[s.name] = StatisticModel.fromJson(resp.data!);
        }
      } catch (e, st) {
        talker.handle(e, stackTrace: st, message: '获取媒体服务器 ${s.name} 统计失败');
      }
    }
    if (!isClosed) {
      mediaServerStats.assignAll(newStats);
      mediaServerStats.refresh();
    }
  }

  /// 加载媒体服务器数据
  Future<void> loadMediaServers() async {
    try {
      isLoading.value = true;
      talker.info('开始加载媒体服务器数据');
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/system/setting/MediaServers',
      );
      talker.info('媒体服务器API响应状态码: ${response.statusCode}');
      talker.info('媒体服务器API响应数据: ${response.data}');
      if (response.statusCode == 200) {
        final data = response.data!;
        talker.info('媒体服务器API响应数据: $data');
        if (data['success'] == true) {
          if (data.containsKey('data') && data['data'] != null) {
            if (data['data'] is Map<String, dynamic> &&
                data['data'].containsKey('value')) {
              final value = data['data']['value'] as List<dynamic>;
              final servers = value
                  .map((item) => MediaServer.fromJson(item))
                  .toList();
              mediaServers.value = servers;
              talker.info('媒体服务器数据加载成功: ${servers.length} 个服务器');
            } else if (data['data'] is List<dynamic>) {
              // 直接是列表结构
              final servers = (data['data'] as List<dynamic>)
                  .map((item) => MediaServer.fromJson(item))
                  .toList();
              mediaServers.value = servers;
              talker.info('媒体服务器数据加载成功: ${servers.length} 个服务器');
            } else {
              talker.warning('媒体服务器数据格式错误: data字段不是预期的结构');
            }
          } else {
            talker.warning('媒体服务器数据格式错误: 缺少data字段');
          }
        } else {
          talker.warning('媒体服务器数据加载失败: ${data['message']}');
        }
      } else if (response.statusCode == 401) {
        talker.error('媒体服务器数据加载失败: 未授权，请重新登录');
        // 这里可以添加重定向到登录页面的逻辑
      } else {
        talker.warning('媒体服务器数据加载失败，状态码: ${response.statusCode}');
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载媒体服务器数据失败');
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载媒体库信息
  Future<void> loadMediaLibraries() async {
    try {
      isLoading.value = true;
      talker.info('开始加载媒体库数据');

      List<MediaLibrary> allLibraries = [];

      // 从媒体服务器列表中获取所有启用的服务器
      final servers = mediaServers.value;
      talker.info('可用的媒体服务器数量: ${servers.length}');

      if (servers.isEmpty) {
        talker.warning('没有可用的媒体服务器');
        mediaLibraries.value = [];
        return;
      }

      // 为每个启用的服务器加载媒体库
      for (final server in servers) {
        talker.info(
          '检查服务器: ${server.name}, 类型: ${server.type}, 启用状态: ${server.enabled}',
        );
        if (server.enabled) {
          talker.info('加载服务器 ${server.name} 的媒体库数据');
          final response = await apiClient.get<dynamic>(
            '/api/v1/mediaserver/library?server=${server.name}&hidden=true',
          );
          talker.info('服务器 ${server.name} 媒体库API响应状态码: ${response.statusCode}');
          talker.info('服务器 ${server.name} 媒体库API响应数据: ${response.data}');

          if (response.statusCode == 200) {
            final data = response.data!;
            List<MediaLibrary> libraries = [];

            // 处理不同的数据结构
            if (data is List<dynamic>) {
              // 直接是列表结构
              libraries = data
                  .map((item) => MediaLibrary.fromJson(item))
                  .toList();
              talker.info(
                '服务器 ${server.name} 媒体库数据格式: 直接列表, 数量: ${libraries.length}',
              );
            } else if (data is Map<String, dynamic>) {
              // 是包装对象，需要提取data字段
              if (data.containsKey('data') && data['data'] is List<dynamic>) {
                libraries = (data['data'] as List<dynamic>)
                    .map((item) => MediaLibrary.fromJson(item))
                    .toList();
                talker.info(
                  '服务器 ${server.name} 媒体库数据格式: 包装对象, 数量: ${libraries.length}',
                );
              } else if (data.containsKey('success') &&
                  data['success'] == true) {
                // 另一种常见的包装格式
                if (data.containsKey('data') && data['data'] is List<dynamic>) {
                  libraries = (data['data'] as List<dynamic>)
                      .map((item) => MediaLibrary.fromJson(item))
                      .toList();
                  talker.info(
                    '服务器 ${server.name} 媒体库数据格式: 成功包装对象, 数量: ${libraries.length}',
                  );
                } else {
                  talker.warning(
                    '服务器 ${server.name} 媒体库数据格式错误: 成功字段为true但data字段不是列表',
                  );
                }
              } else {
                talker.warning('服务器 ${server.name} 媒体库数据格式错误: 未知的响应格式');
              }
            } else {
              talker.warning('服务器 ${server.name} 媒体库数据格式错误: 响应既不是列表也不是对象');
            }

            allLibraries.addAll(libraries);
            talker.info('服务器 ${server.name} 加载媒体库成功: ${libraries.length} 个媒体库');
          } else {
            talker.warning(
              '服务器 ${server.name} 加载媒体库失败，状态码: ${response.statusCode}',
            );
          }
        } else {
          talker.info('服务器 ${server.name} 未启用，跳过加载');
        }
      }

      mediaLibraries.value = allLibraries;
      talker.info('所有媒体库数据加载成功: ${allLibraries.length} 个媒体库');
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载媒体库数据失败');
      // 确保即使发生错误也更新状态
      mediaLibraries.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新媒体服务器数据（含统计）
  Future<void> refreshMediaServers() async {
    await loadMediaServers();
    await loadMediaServerStats();
  }

  /// 加载媒体服务器最新入库数据
  Future<Map<String, dynamic>?> loadLatestMediaData(String serverName) async {
    try {
      talker.info('开始加载媒体服务器最新入库数据: $serverName');
      // 接口返回格式在不同版本中可能是 Map 包装对象或直接 List，
      // 这里使用 dynamic 接收并在本地做兼容处理，避免类型转换错误。
      final response = await apiClient.get<dynamic>(
        '/api/v1/mediaserver/latest?server=$serverName',
      );
      talker.info('媒体服务器最新入库数据API响应数据: ${response.data}');
      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          // 标准格式：{"success": true, "data": [...]}
          if (data['success'] == true) {
            talker.info('媒体服务器最新入库数据加载成功(包装对象)');
            return data;
          } else {
            talker.warning('媒体服务器最新入库数据加载失败: ${data['message']}');
            return null;
          }
        } else if (data is List<dynamic>) {
          // 兼容直接返回列表的情况：[...]，包一层统一结构返回
          talker.info('媒体服务器最新入库数据加载成功(列表格式)');
          return <String, dynamic>{'success': true, 'data': data};
        } else {
          talker.warning('媒体服务器最新入库数据格式异常: ${data.runtimeType}');
          return null;
        }
      } else if (response.statusCode == 401) {
        talker.error('媒体服务器最新入库数据加载失败: 未授权，请重新登录');
        return null;
      } else {
        talker.warning('媒体服务器最新入库数据加载失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载媒体服务器最新入库数据失败');
      return null;
    }
  }

  /// 加载所有媒体服务器的最近添加媒体列表
  Future<void> loadLatestMediaList(String serverName) async {
    try {
      isLoading.value = true;
      talker.info('开始加载所有媒体服务器的最近添加媒体列表');

      List<LatestMedia> allLatestMedia = [];
      final servers = mediaServers.value;

      for (final server in servers) {
        if (server.enabled) {
          talker.info('加载服务器 ${server.name} 的最近添加媒体');
          final response = await apiClient.get<dynamic>(
            '/api/v1/mediaserver/latest?server=${server.name}',
          );

          if (response.statusCode == 200) {
            final data = response.data!;

            // 处理不同的数据结构
            if (data is Map<String, dynamic>) {
              // 标准响应格式: {"success": true, "data": [...]}
              if (data['success'] == true && data.containsKey('data')) {
                final mediaList = data['data'] as List<dynamic>;
                final latestMedia = mediaList.map((item) {
                  // 直接转换为LatestMedia对象
                  final mediaItem = item as Map<String, dynamic>;
                  // 添加媒体库名称
                  mediaItem['libraryName'] = server.name;
                  return LatestMedia.fromJson(mediaItem);
                }).toList();

                allLatestMedia.addAll(latestMedia);
                talker.info(
                  '服务器 ${server.name} 加载最近添加媒体成功: ${latestMedia.length} 个',
                );
              } else {
                talker.warning('服务器 ${server.name} 最近添加媒体数据格式错误');
              }
            } else if (data is List<dynamic>) {
              // 直接返回列表格式: [...]
              final latestMedia = data.map((item) {
                // 直接转换为LatestMedia对象
                final mediaItem = item as Map<String, dynamic>;
                // 添加媒体库名称
                mediaItem['libraryName'] = server.name;
                return LatestMedia.fromJson(mediaItem);
              }).toList();

              allLatestMedia.addAll(latestMedia);
              talker.info(
                '服务器 ${server.name} 加载最近添加媒体成功: ${latestMedia.length} 个',
              );
            } else {
              talker.warning('服务器 ${server.name} 最近添加媒体数据格式错误: 未知数据类型');
            }
          } else {
            talker.warning(
              '服务器 ${server.name} 加载最近添加媒体失败，状态码: ${response.statusCode}',
            );
          }
        } else {
          talker.info('服务器 ${server.name} 未启用，跳过加载');
        }
      }

      // 按副标题（年份）排序，最新的在前
      allLatestMedia.sort((a, b) => b.subtitle.compareTo(a.subtitle));

      // 更新最新媒体列表
      latestMediaList.value = allLatestMedia;
      talker.info('所有媒体服务器最近添加媒体加载完成: ${allLatestMedia.length} 个');
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载最近添加媒体列表失败');
      latestMediaList.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新最近添加媒体列表
  Future<void> refreshLatestMediaList() async {
    final enabledServers = mediaServers.value.where((server) => server.enabled);
    if (mediaServers.value.isEmpty) {
      talker.warning('没有可用的媒体服务器');
      latestMediaList.value = [];
      return;
    }
    if (enabledServers.isEmpty) {
      talker.warning('没有启用的媒体服务器');
      latestMediaList.value = [];
      return;
    }
    await loadLatestMediaList(enabledServers.first.name);
  }

  /// 加载正在播放的媒体
  Future<void> loadPlayingMedia(String serverName) async {
    try {
      isLoading.value = true;
      talker.info('开始加载正在播放的媒体');
      final response = await apiClient.get<dynamic>(
        '/api/v1/mediaserver/playing?server=$serverName',
      );
      if (response.statusCode == 200) {
        final data = response.data!;
        if (data is List<dynamic>) {
          playingMedia.value = data
              .map((item) => LatestMedia.fromJson(item))
              .toList();
        } else {
          playingMedia.value = [LatestMedia.fromJson(data)];
        }
      }
    } catch (e, st) {
      talker.handle(e, stackTrace: st, message: '加载正在播放的媒体失败');
      playingMedia.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
