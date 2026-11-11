import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moviepilot_mobile/modules/media_detail/controllers/media_detail_service.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_comment_models.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_review_list_args.dart';
import 'package:moviepilot_mobile/modules/media_detail/pages/douban_review_list_page.dart';
import 'package:moviepilot_mobile/modules/media_detail/widgets/douban_list_item.dart';

class FakeReviewService extends GetxService implements MediaDetailService {
  final starts = <int>[];
  bool failNext = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<DoubanReviewPage> getDoubanReviews({
    required String doubanId,
    required String typeName,
    int start = 0,
    int count = 20,
    bool throwOnError = false,
  }) async {
    starts.add(start);
    if (failNext) {
      failNext = false;
      throw Exception('network');
    }
    return const DoubanReviewPage(
      start: 1,
      total: 2,
      items: [DoubanReview(id: '2', title: '第二篇影评')],
    );
  }
}

void main() {
  tearDown(Get.reset);

  testWidgets('复用预览并在加载失败后重试下一页', (tester) async {
    final service = FakeReviewService();
    Get.put<MediaDetailService>(service);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Get.to(
              () => DoubanReviewListPage(key: UniqueKey()),
              binding: BindingsBuilder(
                () => Get.create(() => DoubanReviewListController()),
              ),
              preventDuplicates: false,
              arguments: const DoubanReviewListArgs(
                doubanId: '3001114',
                typeName: '电影',
                title: '沙丘',
                initialItems: [DoubanReview(id: '1', title: '第一篇影评')],
                initialTotal: 2,
              ),
            ),
            child: const Text('查看更多'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('查看更多'));
    await tester.pumpAndSettle();
    expect(find.text('第一篇影评'), findsOneWidget);
    expect(find.byType(DoubanListItem), findsOneWidget);
    expect(service.starts, isEmpty);
    await tester.tap(find.text('查看更多影评 · 共 2'));
    await tester.pumpAndSettle();
    expect(find.text('第一篇影评'), findsOneWidget);
    expect(service.starts, [1]);
    await tester.tap(find.text('查看更多影评 · 共 2'));
    await tester.pumpAndSettle();
    expect(service.starts, [1, 1]);
    await tester.scrollUntilVisible(find.text('第二篇影评'), 200);
    expect(find.text('第二篇影评'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
