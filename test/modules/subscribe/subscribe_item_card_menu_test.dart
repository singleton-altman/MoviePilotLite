import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/subscribe/models/subscribe_models.dart';
import 'package:moviepilot_mobile/modules/subscribe/widgets/subscribe_item_card.dart';

SubscribeItem _item({String? state}) => SubscribeItem(
  id: 7,
  name: '示例剧集',
  year: '2026',
  type: '电视剧',
  state: state,
  date: '2026-10-21T08:00:00Z',
  username: 'admin',
);

Future<List<String>> _openMenuLabels(
  WidgetTester tester, {
  required bool showExecutionEntries,
  bool isMusic = false,
  bool isTv = true,
}) async {
  final labels = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SubscribeItemCard(
            item: _item(),
            isTv: isTv,
            isMusic: isMusic,
            showExecutionEntries: showExecutionEntries,
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byIcon(Icons.more_horiz));
  await tester.pumpAndSettle();
  for (final type in SubscribeItemCardType.values) {
    final finder = find.text(_labelOf(type));
    if (finder.evaluate().isNotEmpty) {
      labels.add(_labelOf(type));
    }
  }
  return labels;
}

String _labelOf(SubscribeItemCardType type) => switch (type) {
  SubscribeItemCardType.edit => '编辑',
  SubscribeItemCardType.search => '搜索',
  SubscribeItemCardType.detail => '详情',
  SubscribeItemCardType.files => '文件统计',
  SubscribeItemCardType.activity => '活动记录',
  SubscribeItemCardType.logs => '运行日志',
  SubscribeItemCardType.pause => '暂停',
  SubscribeItemCardType.resume => '继续',
  SubscribeItemCardType.reset => '重置',
  SubscribeItemCardType.shared => '分享',
  SubscribeItemCardType.delete => '删除',
};

void main() {
  group('menuItemsFor 入口可见性', () {
    test('v2（executionVisible=false）不包含活动记录与运行日志', () {
      final items = SubscribeItemCard.menuItemsFor(
        isMusic: false,
        isTv: true,
        executionVisible: false,
        paused: false,
        running: false,
      );
      expect(items, isNot(contains(SubscribeItemCardType.activity)));
      expect(items, isNot(contains(SubscribeItemCardType.logs)));
    });

    test('v3 非音乐订阅包含活动记录与运行日志，位于文件统计之后', () {
      final items = SubscribeItemCard.menuItemsFor(
        isMusic: false,
        isTv: true,
        executionVisible: true,
        paused: false,
        running: false,
      );
      expect(items, containsAll(<SubscribeItemCardType>[
        SubscribeItemCardType.activity,
        SubscribeItemCardType.logs,
      ]));
      expect(
        items.indexOf(SubscribeItemCardType.files) + 1,
        items.indexOf(SubscribeItemCardType.activity),
      );
      expect(
        items.indexOf(SubscribeItemCardType.activity) + 1,
        items.indexOf(SubscribeItemCardType.logs),
      );
    });

    test('音乐订阅即使 v3 也不展示执行入口', () {
      final items = SubscribeItemCard.menuItemsFor(
        isMusic: true,
        isTv: false,
        executionVisible: true,
        paused: false,
        running: false,
      );
      expect(items, isNot(contains(SubscribeItemCardType.activity)));
      expect(items, isNot(contains(SubscribeItemCardType.logs)));
      expect(items, isNot(contains(SubscribeItemCardType.shared)));
    });
  });

  group('卡片菜单渲染', () {
    testWidgets('v3 打开菜单展示活动记录与运行日志', (tester) async {
      final labels = await _openMenuLabels(tester, showExecutionEntries: true);
      expect(labels, contains('活动记录'));
      expect(labels, contains('运行日志'));
      expect(labels, contains('文件统计'));
    });

    testWidgets('v2 打开菜单不出现活动记录与运行日志', (tester) async {
      final labels = await _openMenuLabels(tester, showExecutionEntries: false);
      expect(labels, isNot(contains('活动记录')));
      expect(labels, isNot(contains('运行日志')));
    });
  });
}
