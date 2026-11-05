import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_music_sheet.dart';

void main() {
  testWidgets('音乐订阅 sheet 渲染无断言异常', (tester) async {
    const item = SubscribeItem(
      id: 1,
      name: '测试专辑',
      year: '2024',
      type: '音乐',
      state: 'N',
      date: '2025-01-01T00:00:00Z',
      username: 'admin',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () => showSubscribeMusicSheet(context, item),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason: 'sheet 渲染过程中抛出了异常: $exception',
    );
  });
}
