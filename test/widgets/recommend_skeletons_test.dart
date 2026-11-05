import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/recommend/widgets/recommend_skeletons.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _boneFinder = find.byWidgetPredicate((widget) => widget is Bone);
final _skeletonizerFinder = find.byWidgetPredicate(
  (widget) => widget is Skeletonizer,
);

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF061815),
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  const header = Text('分区标题');

  testWidgets('banner 骨架撑满指定高度', (tester) async {
    await tester.pumpWidget(
      wrap(const RecommendBannerSkeleton(height: 450)),
    );
    await tester.pump();

    expect(_skeletonizerFinder, findsOneWidget);
    expect(
      tester.getSize(find.byType(RecommendBannerSkeleton)).height,
      450,
    );
  });

  testWidgets('海报轨道骨架保留标题并铺出占位卡片', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(const RecommendPosterRailSkeleton(header: header)),
    );
    await tester.pump();

    expect(find.text('分区标题'), findsOneWidget);
    expect(_boneFinder, findsNWidgets(6));
  });

  testWidgets('正在热映骨架使用竖版窄卡', (tester) async {
    await tester.pumpWidget(
      wrap(const RecommendNowPlayingSkeleton(header: header)),
    );
    await tester.pump();

    expect(find.text('分区标题'), findsOneWidget);
    expect(_boneFinder, findsNWidgets(5));
  });

  testWidgets('主推区宽屏为三列布局', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(const RecommendShowcaseSkeleton(header: header, isWide: true)),
    );
    await tester.pump();

    expect(_boneFinder, findsNWidgets(3));
  });

  testWidgets('主推区窄屏为大图加两张次图', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(const RecommendShowcaseSkeleton(header: header, isWide: false)),
    );
    await tester.pump();

    expect(_boneFinder, findsNWidgets(3));
  });

  testWidgets('榜单骨架按视口窄宽切换排布', (tester) async {
    await tester.pumpWidget(
      wrap(const RecommendRankSkeleton(header: header, isNarrow: true)),
    );
    await tester.pump();
    expect(_boneFinder, findsNWidgets(4));

    await tester.pumpWidget(
      wrap(const RecommendRankSkeleton(header: header, isNarrow: false)),
    );
    await tester.pump();
    expect(_boneFinder, findsNWidgets(4));
  });

  testWidgets('热门骨架在窄屏为主图加三条横条', (tester) async {
    await tester.pumpWidget(
      wrap(const RecommendHotSkeleton(header: header, isNarrow: true)),
    );
    await tester.pump();

    expect(find.text('分区标题'), findsOneWidget);
    expect(_boneFinder, findsNWidgets(4));
  });
}
