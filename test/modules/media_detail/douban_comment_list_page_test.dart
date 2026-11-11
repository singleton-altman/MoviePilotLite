import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_service.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_comment_models.dart';
import 'package:moviepilot_mobile/modules/media_detail/pages/douban_comment_list_page.dart';
import 'package:moviepilot_mobile/modules/media_detail/widgets/douban_list_item.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';

class CommentService extends GetxService implements MediaDetailService {
  final starts = <int>[];
  bool fail = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<DoubanCommentPage> getDoubanComments({
    required String doubanId,
    required String typeName,
    int start = 0,
    int count = 20,
    bool throwOnError = false,
  }) async {
    starts.add(start);
    if (fail) {
      fail = false;
      throw Exception('network');
    }
    return const DoubanCommentPage(
      start: 1,
      total: 2,
      items: [DoubanComment(id: '2', comment: '第二条短评')],
    );
  }
}

void main() {
  tearDown(Get.reset);
  testWidgets('短评列表复用预览并可重试加载更多', (tester) async {
    final service = CommentService();
    Get.put<MediaDetailService>(service);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Get.to(
              () => const DoubanCommentListPage(
                doubanId: '123',
                typeName: '电影',
                title: '电影',
                initialItems: [DoubanComment(id: '1', comment: '第一条短评')],
                initialTotal: 2,
              ),
            ),
            child: const Text('豆瓣短评'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('豆瓣短评'));
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(find.text('全部短评'));
    expect(title.style?.color, Colors.white);
    final back = tester.widget<Icon>(find.byIcon(CupertinoIcons.back));
    expect(back.color, Colors.white);
    expect(find.text('第一条短评'), findsOneWidget);
    expect(find.byType(DoubanListItem), findsOneWidget);
    expect(service.starts, isEmpty);
    await tester.tap(find.text('查看更多短评 · 共 2'));
    await tester.pumpAndSettle();
    expect(find.text('加载失败，请重试'), findsOneWidget);
    expect(find.text('第一条短评'), findsOneWidget);
    await tester.tap(find.text('查看更多短评 · 共 2'));
    await tester.pumpAndSettle();
    expect(service.starts, [1, 1]);
    expect(find.text('第二条短评'), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.back));
    await tester.pumpAndSettle();
    expect(find.text('豆瓣短评'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
