import 'package:get/get.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/downloader/models/download_history_item.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

/// 下载历史页 Controller。
/// GET /api/v1/history/download（分页）；DELETE /api/v1/history/download
/// 请求体为完整 DownloadHistory 对象（v2/v3.1.5 双线一致）。
class DownloadHistoryController extends GetxController {
  static const int _pageSize = 30;

  final _apiClient = Get.find<ApiClient>();
  final _log = Get.find<AppLog>();

  final items = <DownloadHistoryItem>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorText = RxnString();
  final hasMore = true.obs;

  int _page = 1;

  @override
  void onReady() {
    super.onReady();
    reload();
  }

  Future<void> reload() async {
    if (isLoading.value || isLoadingMore.value) return;
    _page = 1;
    hasMore.value = true;
    items.clear();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    final firstPage = _page == 1;
    if (firstPage) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }
    errorText.value = null;
    try {
      final response = await _apiClient.get<dynamic>(
        '/api/v1/history/download',
        queryParameters: {'page': _page, 'count': _pageSize},
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        errorText.value = '请求失败 (HTTP $status)';
        return;
      }
      final data = response.data;
      if (data is Map && data['success'] == false) {
        errorText.value = data['message']?.toString() ?? '获取下载历史失败';
        return;
      }
      final rawList = data is List
          ? data
          : data is Map
          ? data['data']
          : null;
      if (rawList is! List) {
        errorText.value = '数据格式异常';
        return;
      }
      final pageItems = rawList
          .whereType<Map>()
          .map(
            (e) => DownloadHistoryItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
      items.addAll(pageItems);
      hasMore.value = pageItems.length >= _pageSize;
      _page += 1;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '获取下载历史失败');
      errorText.value = '请求失败，请稍后重试';
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// 删除单条下载历史（危险操作，调用方需先二次确认）。
  /// DELETE 请求体为完整 DownloadHistory 对象，走通用 request 通道。
  /// 返回 null 表示成功，否则为错误文案。
  Future<String?> deleteItem(DownloadHistoryItem item) async {
    if (item.id == null) return '记录缺少标识，无法删除';
    try {
      final response = await _apiClient.request<dynamic>(
        '/api/v1/history/download',
        RequestMethod.delete,
        item.toJson(),
      );
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        return '删除失败 (HTTP $status)';
      }
      final data = response.data;
      if (data is Map && data['success'] == false) {
        return data['message']?.toString() ?? '删除失败';
      }
      items.removeWhere((e) => e.id == item.id);
      return null;
    } catch (e, st) {
      _log.handle(e, stackTrace: st, message: '删除下载历史失败');
      return '删除失败，请稍后重试';
    }
  }
}
