import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/dashboard/widgets/dashboard_skeletons.dart';
import 'package:skeletonizer/skeletonizer.dart';

// Bone / Skeletonizer 都是抽象工厂，运行时是私有实现类，
// find.byType 按精确类型匹配会落空，这里按继承关系判断。
final _boneFinder = find.byWidgetPredicate((widget) => widget is Bone);
final _skeletonizerFinder = find.byWidgetPredicate(
  (widget) => widget is Skeletonizer,
);

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  testWidgets('首屏骨架渲染状态卡与媒体浏览占位', (tester) async {
    await tester.pumpWidget(wrap(const DashboardFirstPaintSkeleton()));
    await tester.pump();

    expect(_skeletonizerFinder, findsWidgets);
    expect(_boneFinder, findsWidgets);
    // 四张状态卡片 + 一段海报轨道
    expect(find.byType(DashboardPosterRailSkeleton), findsOneWidget);
  });

  testWidgets('海报网格骨架按条目数铺满占位', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 360,
          child: DashboardPosterGridSkeleton(itemCount: 6),
        ),
      ),
    );
    await tester.pump();

    expect(_boneFinder, findsNWidgets(6));
    expect(find.byType(AspectRatio), findsNWidgets(6));
  });

  testWidgets('列表骨架按条目数渲染行', (tester) async {
    await tester.pumpWidget(
      wrap(const DashboardListSkeleton(itemCount: 3, showPoster: false)),
    );
    await tester.pump();

    // 每行两个文本占位 + 一个时间占位
    expect(_boneFinder, findsNWidgets(9));
  });

  testWidgets('图表骨架渲染柱状占位', (tester) async {
    await tester.pumpWidget(wrap(const DashboardChartSkeleton()));
    await tester.pump();

    // 两个表头占位 + 七根柱子
    expect(_boneFinder, findsNWidgets(9));
  });
}
