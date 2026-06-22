import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/system_message.dart';

class SystemMessageController extends GetxController {
  final _apiClient = Get.find<ApiClient>();
  final _appService = Get.find<AppService>();
  final _log = Get.find<AppLog>();

  bool get _canAccessMessages => _appService.isSuperuser;

  static const String _lastReadMessageIdKey = 'last_read_message_id';
  // MP的 message sse 似乎有问题，此处改为轮询
  static const Duration _pollingInterval = Duration(seconds: 10);

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;

  final messages = <SystemMessage>[].obs;
  final scrollController = ScrollController();
  final inputController = TextEditingController();
  final isSending = false.obs;

  /// 是否有未读消息（用于 dashboard 红点显示）
  final hasUnreadMessages = false.obs;

  /// 已查阅的最大消息 ID
  int _lastReadMessageId = 0;

  /// 当前列表中的最大消息 ID
  int _currentMaxMessageId = 0;

  int _page = 1;
  final int _size = 20;
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    _loadLastReadMessageId();
    if (_canAccessMessages) {
      _startPolling();
    }
  }

  @override
  void onClose() {
    _stopPolling();
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// 加载已查阅的最大消息 ID
  Future<void> _loadLastReadMessageId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastReadMessageId = prefs.getInt(_lastReadMessageIdKey) ?? 0;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '加载已读消息 ID 失败');
    }
  }

  /// 保存已查阅的最大消息 ID
  Future<void> _saveLastReadMessageId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastReadMessageIdKey, id);
      _lastReadMessageId = id;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '保存已读消息 ID 失败');
    }
  }

  /// 启动定时轮询
  void _startPolling() {
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _fetchLatestMessages();
    });
  }

  /// 停止定时轮询
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// 登出时清理运行态，避免继续轮询旧会话
  void clearForLogout() {
    _stopPolling();
    isLoading.value = false;
    isLoadingMore.value = false;
    hasMore.value = true;
    isSending.value = false;
    hasUnreadMessages.value = false;
    messages.clear();
    inputController.clear();
    _page = 1;
    _currentMaxMessageId = 0;
  }

  /// 定时获取最新消息列表并与当前列表 diff 对比插入数据
  Future<void> _fetchLatestMessages() async {
    if (!_canAccessMessages) return;
    if (isLoading.value) return;

    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/message/web?page=1&size=$_size',
      );
      final data = response.data;
      if (data == null) return;

      final list = _extractList(data);
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(SystemMessage.fromJson)
          .toList();

      // 按时间升序：旧在上，新在下
      items.sort((a, b) => a.regTime.compareTo(b.regTime));

      if (items.isEmpty) return;

      // 计算当前列表中的最大消息 ID
      final currentIds = messages.map((m) => m.id).toSet();
      final newMaxId = items.map((m) => m.id).reduce((a, b) => a > b ? a : b);

      // 找出新消息（不在当前列表中的消息）
      final newMessages = items
          .where((m) => !currentIds.contains(m.id))
          .toList();

      if (newMessages.isNotEmpty) {
        // 按时间顺序插入新消息
        for (final message in newMessages) {
          // 找到应该插入的位置（保持时间升序）
          int insertIndex = messages.length;
          for (int i = 0; i < messages.length; i++) {
            if (message.regTime.isBefore(messages[i].regTime)) {
              insertIndex = i;
              break;
            }
          }
          messages.insert(insertIndex, message);
        }

        // 如果当前在底部，自动滚动到底部
        if (scrollController.hasClients) {
          final position = scrollController.position;
          final isNearBottom = position.pixels >= position.maxScrollExtent - 50;
          if (isNearBottom) {
            _scrollToBottom();
          }
        }
      }

      // 更新当前最大消息 ID
      _currentMaxMessageId = newMaxId;

      // 检查是否有未读消息
      _checkUnreadStatus();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取最新消息失败');
    }
  }

  /// 检查未读消息状态
  void _checkUnreadStatus() {
    hasUnreadMessages.value = _currentMaxMessageId > _lastReadMessageId;
  }

  /// 用户查看消息后，记录消息页面内最大的 message id，同时移除小红点
  Future<void> markAsRead() async {
    if (messages.isEmpty) return;

    // 找到当前列表中的最大消息 ID
    final maxId = messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);

    // 保存已读状态
    await _saveLastReadMessageId(maxId);

    // 更新当前最大消息 ID
    _currentMaxMessageId = maxId;

    // 移除红点
    hasUnreadMessages.value = false;
  }

  Future<void> loadInitial() async {
    if (!_canAccessMessages) return;
    isLoading.value = true;
    _page = 1;
    hasMore.value = true;
    messages.clear();
    try {
      await _fetchPage(_page, appendOlder: false);
      // 初始化后检查未读状态
      _checkUnreadStatus();
    } finally {
      isLoading.value = false;
      await _scrollToBottom();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      _page += 1;
      await _fetchPage(_page, appendOlder: true);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _fetchPage(int page, {required bool appendOlder}) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/message/web?page=$page&size=$_size',
      );
      final data = response.data;
      if (data == null) return;

      final list = _extractList(data);
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(SystemMessage.fromJson)
          .toList();

      // 按时间升序：旧在上，新在下
      items.sort((a, b) => a.regTime.compareTo(b.regTime));

      if (appendOlder) {
        if (items.isEmpty) {
          hasMore.value = false;
        } else {
          messages.insertAll(0, items);
        }
      } else {
        messages.assignAll(items);
      }

      // 更新当前最大消息 ID
      if (items.isNotEmpty) {
        final maxId = items.map((m) => m.id).reduce((a, b) => a > b ? a : b);
        if (maxId > _currentMaxMessageId) {
          _currentMaxMessageId = maxId;
        }
      }

      // 兜底判断是否还有更多
      if (items.length < _size) {
        hasMore.value = false;
      }

      return;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取系统消息失败');
    }
  }

  List<dynamic> _extractList(dynamic root) {
    if (root is List) return root;
    if (root is Map<String, dynamic>) {
      final direct = root['data'];
      if (direct is List) return direct;
      if (direct is Map<String, dynamic>) {
        for (final key in ['items', 'list', 'records', 'data']) {
          final value = direct[key];
          if (value is List) return value;
        }
      }
    }
    return const [];
  }

  Future<void> _scrollToBottom() {
    return scrollToBottom();
  }

  /// 公共方法：滚动到底部
  Future<void> scrollToBottom({int retries = 6}) async {
    await WidgetsBinding.instance.endOfFrame;

    if (!scrollController.hasClients) {
      if (retries <= 0) return;
      await Future.delayed(const Duration(milliseconds: 80));
      return scrollToBottom(retries: retries - 1);
    }

    final position = scrollController.position;
    if (!position.hasContentDimensions) {
      if (retries <= 0) return;
      await Future.delayed(const Duration(milliseconds: 80));
      return scrollToBottom(retries: retries - 1);
    }

    final target = position.maxScrollExtent;
    if ((position.pixels - target).abs() > 1) {
      scrollController.jumpTo(target);
    }

    if (retries <= 0) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!scrollController.hasClients) return;
    final latestTarget = scrollController.position.maxScrollExtent;
    if ((latestTarget - target).abs() > 1) {
      await Future.delayed(const Duration(milliseconds: 16));
      return scrollToBottom(retries: retries - 1);
    }
  }

  Future<void> sendMessage() async {
    if (!_canAccessMessages) return;
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    isSending.value = true;
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/message/web',
        queryParameters: {'text': text},
      );
      inputController.clear();
      await _fetchPage(1, appendOlder: false);
      final maxId = messages.map((m) => m.id).reduce((a, b) => a > b ? a : b);
      if (maxId >= _currentMaxMessageId) {
        _currentMaxMessageId = maxId;
        _saveLastReadMessageId(maxId);
      }
      _saveLastReadMessageId(maxId);
      await _scrollToBottom();
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '发送消息失败');
    } finally {
      isSending.value = false;
    }
  }
}
