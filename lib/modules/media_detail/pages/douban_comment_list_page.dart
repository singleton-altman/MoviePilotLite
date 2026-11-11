import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_service.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_comment_models.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';
import 'package:moviepilot_mobile/modules/media_detail/widgets/douban_list_item.dart';

class DoubanCommentListPage extends StatefulWidget {
  const DoubanCommentListPage({
    super.key,
    required this.doubanId,
    required this.typeName,
    required this.title,
    this.initialItems = const [],
    this.initialTotal = 0,
  });

  final String doubanId;
  final String typeName;
  final String title;
  final List<DoubanComment> initialItems;
  final int initialTotal;

  @override
  State<DoubanCommentListPage> createState() => _DoubanCommentListPageState();
}

class _DoubanCommentListPageState extends State<DoubanCommentListPage> {
  late List<DoubanComment> _items;
  late int _total;
  late int _nextStart;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initialItems);
    _total = widget.initialTotal > _items.length
        ? widget.initialTotal
        : _items.length;
    _nextStart = _items.length;
    if (_items.isEmpty) _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final start = reset ? 0 : _nextStart;
    try {
      final page = await Get.find<MediaDetailService>().getDoubanComments(
        doubanId: widget.doubanId,
        typeName: widget.typeName,
        start: start,
        count: 20,
        throwOnError: true,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        final ids = _items.map((item) => item.id).whereType<String>().toSet();
        _items.addAll(
          page.items.where((item) => item.id == null || ids.add(item.id!)),
        );
        _nextStart =
            (page.start < start ? start : page.start) + page.items.length;
        _total = page.items.isEmpty ? _nextStart : page.total;
        if (_total < _nextStart) _total = _nextStart;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackgroundColor,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
        title: const Text(
          '全部短评',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _items.isEmpty
          ? Center(
              child: _loading
                  ? const CupertinoActivityIndicator()
                  : _failed
                  ? TextButton(
                      onPressed: () => _load(reset: true),
                      child: const Text('加载失败，点击重试'),
                    )
                  : const Text(
                      '暂无豆瓣短评',
                      style: TextStyle(color: Colors.white70),
                    ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 32),
              itemCount: _items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title.isEmpty ? '豆瓣短评' : widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '共 $_total 条短评',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (index == _items.length + 1) {
                  return Column(
                    children: [
                      if (_failed)
                        const Text(
                          '加载失败，请重试',
                          style: TextStyle(color: Colors.white70),
                        ),
                      LoadMoreFooter(
                        hasMore: _nextStart < _total,
                        isLoading: _loading,
                        total: _total,
                        onLoadMore: () => _load(),
                        label: '查看更多短评',
                        endLabel: '没有更多短评了',
                      ),
                    ],
                  );
                }
                final item = _items[index - 1];
                return DoubanListItem(
                  authorName: item.author?.name ?? '豆瓣用户',
                  avatarPath: item.author?.avatar,
                  rating: item.rating,
                  createTime: item.createTime,
                  usefulCount: item.voteCount ?? 0,
                  content: item.comment,
                  url: item.url,
                );
              },
            ),
    );
  }
}
