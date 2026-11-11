import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/media_detail/models/douban_comment_models.dart';
import 'package:moviepilot_mobile/modules/media_detail/widgets/media_danmaku_overlay.dart';

void main() {
  testWidgets('renders three lanes and comment text', (tester) async {
    final comments = [
      for (var index = 0; index < 8; index++)
        DoubanComment(comment: '第 $index 条短评'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 90,
            child: MediaDanmakuOverlay(comments: comments),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('danmaku-0-8')), findsOneWidget);
    expect(find.byKey(const ValueKey('danmaku-1-8')), findsOneWidget);
    expect(find.byKey(const ValueKey('danmaku-2-8')), findsOneWidget);
    expect(find.text('第 0 条短评'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing without comments', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 90,
            child: MediaDanmakuOverlay(comments: []),
          ),
        ),
      ),
    );

    expect(find.textContaining('短评'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
