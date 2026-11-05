import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/agent/models/agent_models.dart';
import 'package:moviepilot_mobile/modules/agent/widgets/agent_message_bubble.dart';

void main() {
  testWidgets(
    'registered attachments use download callback, not external URL launch',
    (tester) async {
      final attachment = AgentAttachment.fromJson({
        'url': 'message/agent/file/abc',
        'name': 'private.png',
        'kind': 'image',
        'mime_type': 'image/png',
      });
      AgentAttachment? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentMessageBubble(
              message: AgentChatMessage(
                id: 'file',
                role: 'assistant',
                content: '',
                createdAt: DateTime(2026),
                status: AgentMessageStatus.done,
                attachments: [attachment],
              ),
              onAttachmentTap: (value) => selected = value,
            ),
          ),
        ),
      );
      await tester.tap(find.text('private.png'));
      expect(selected, same(attachment));
    },
  );

  testWidgets('renders markdown tables in assistant messages', (tester) async {
    final message = AgentChatMessage(
      id: 'assistant-1',
      role: 'assistant',
      content: '''
### 推荐
| 片名 | 年份 |
|------|------|
| 河西走廊 | 2015 |
''',
      createdAt: DateTime(2026),
      status: AgentMessageStatus.done,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgentMessageBubble(message: message),
          ),
        ),
      ),
    );

    expect(find.byType(MarkdownBody), findsWidgets);
    expect(find.byType(Table), findsWidgets);
    expect(_horizontalTableScrollers(), findsWidgets);
    expect(find.text('片名'), findsOneWidget);
    expect(find.text('河西走廊'), findsOneWidget);
  });

  testWidgets('renders compact streamed markdown with markdown plus', (
    tester,
  ) async {
    final message = AgentChatMessage(
      id: 'assistant-2',
      role: 'assistant',
      content: '''
##豆瓣热门榜
| 片名 | 年份 | 豆瓣评分 | 类型 |
|------|------|----------|------|
| **世界的主人** | 2025 | ⭐ 9.0 | 剧情 |
| **我住在凡尔赛的日子** | 2025 | ⭐ 8.4 | 传记/历史 |
##TMDB 高分剧集
| 片名 | 年份 | 评分 | 类型 |
|------|------|------|------|
| **梦魇绝镇** | 2022 | ⭐ 8.5 | 悬疑/惊悚 |
''',
      createdAt: DateTime(2026),
      status: AgentMessageStatus.done,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgentMessageBubble(message: message),
          ),
        ),
      ),
    );

    expect(find.text('豆瓣热门榜'), findsOneWidget);
    expect(find.text('TMDB 高分剧集'), findsOneWidget);
    expect(find.text('世界的主人'), findsOneWidget);
    expect(find.text('★ 9.0'), findsOneWidget);
    expect(find.byType(Table), findsWidgets);
    expect(_horizontalTableScrollers(), findsWidgets);
  });

  testWidgets('normalizes heading table boundary for streamed markdown', (
    tester,
  ) async {
    final message = AgentChatMessage(
      id: 'assistant-3',
      role: 'assistant',
      content: '''
##豆瓣热门榜| 片名 | 年份 | 豆瓣评分 | 类型 |
|------|------|----------|------|
| **我住在凡尔赛的日子** | 2025 | ⭐ 8.4 | 传记/历史 |
''',
      createdAt: DateTime(2026),
      status: AgentMessageStatus.done,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgentMessageBubble(message: message),
          ),
        ),
      ),
    );

    expect(find.text('豆瓣热门榜'), findsOneWidget);
    expect(find.text('片名'), findsOneWidget);
    expect(find.text('我住在凡尔赛的日子'), findsOneWidget);
    expect(find.text('------'), findsNothing);
    expect(find.byType(Table), findsWidgets);
    expect(_horizontalTableScrollers(), findsWidgets);
  });

  testWidgets('renders pipe tables without outer pipes', (tester) async {
    final message = AgentChatMessage(
      id: 'assistant-outer-pipes',
      role: 'assistant',
      content: '''
## 推荐
片名 | 年份 | 评分 | 类型
------|------|------|------
**星际穿越** | 2014 | ⭐ 9.4 | 科幻/冒险
**千与千寻** | 2001 | ⭐ 9.4 | 动画/奇幻
''',
      createdAt: DateTime(2026),
      status: AgentMessageStatus.done,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgentMessageBubble(message: message),
          ),
        ),
      ),
    );

    expect(find.text('星际穿越', findRichText: true), findsOneWidget);
    expect(find.text('千与千寻', findRichText: true), findsOneWidget);
    expect(find.byType(Table), findsWidgets);
    expect(_horizontalTableScrollers(), findsWidgets);
  });

  testWidgets('normalizes compressed table rows from streamed text', (
    tester,
  ) async {
    final message = AgentChatMessage(
      id: 'assistant-compressed-table',
      role: 'assistant',
      content: '''
## 豆瓣电影 TOP250经典

|片名 |年份 |豆瓣评分| 类型 ||------|------|----------|------|| **肖申克的救赎** |1994| ⭐9.7 |剧情/犯罪 || **霸王别姬** | 1993 |⭐ 9.6 |剧情/爱情 || **阿甘正传** | 1994 |⭐ 9.5 |剧情 |## 豆瓣热门剧集

|片名 |年份 |豆瓣评分| 类型 ||------|------|----------|------|| **绘梦婚礼** |2026| ⭐9.5| 爱情/奇幻 || **铁拳教育** |2026| ⭐8.8| 剧情/运动 |
''',
      createdAt: DateTime(2026),
      status: AgentMessageStatus.done,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgentMessageBubble(message: message),
          ),
        ),
      ),
    );

    expect(find.text('肖申克的救赎', findRichText: true), findsOneWidget);
    expect(find.text('霸王别姬', findRichText: true), findsOneWidget);
    expect(find.text('阿甘正传', findRichText: true), findsOneWidget);
    expect(find.text('绘梦婚礼', findRichText: true), findsOneWidget);
    expect(find.textContaining('------'), findsNothing);
    expect(find.byType(Table), findsWidgets);
    expect(_horizontalTableScrollers(), findsWidgets);
  });

  testWidgets('renders multi section table response while streaming', (
    tester,
  ) async {
    final message = AgentChatMessage(
      id: 'assistant-4',
      role: 'assistant',
      content: '''
## 豆瓣电影 TOP250 经典

| 片名 | 年份 | 豆瓣评分 | 类型 |
|------|------|----------|------|
| **肖申克的救赎** | 1994 | ⭐ 9.7 | 剧情/犯罪 |
| **霸王别姬** | 1993 | ⭐ 9.6 | 剧情/爱情 |

## 豆瓣热门剧集

| 片名 | 年份 | 豆瓣评分 | 类型 |
|------|------|----------|------|
| **绘梦婚礼** | 2026 | ⭐ 9.5 | 爱情/奇幻 |
| **铁拳教育** | 2026 | ⭐ 8.8 | 剧情/运动 |

## 豆瓣新片高分

| 片名 | 年份 | 豆瓣评分 | 类型 |
|------|------|----------|------|
| **挽救计划** | 2026 | ⭐ 8.6 | 科幻 |
| **东京出租车** | 2025 | ⭐ 8.0 | 剧情 |
''',
      createdAt: DateTime(2026),
      status: AgentMessageStatus.streaming,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgentMessageBubble(message: message),
          ),
        ),
      ),
    );

    expect(find.text('肖申克的救赎', findRichText: true), findsOneWidget);
    expect(find.text('绘梦婚礼', findRichText: true), findsOneWidget);
    expect(find.text('挽救计划', findRichText: true), findsOneWidget);
    expect(find.textContaining('TOP250'), findsOneWidget);
    expect(find.textContaining('热门剧集'), findsOneWidget);
    expect(find.textContaining('新片高分'), findsOneWidget);
    expect(find.text('★ 9.7', findRichText: true), findsOneWidget);
    expect(find.text('------'), findsNothing);
    expect(find.byType(Table), findsWidgets);
    expect(_horizontalTableScrollers(), findsWidgets);
  });

  testWidgets('renders completed multi section table response', (tester) async {
    final message = AgentChatMessage(
      id: 'assistant-5',
      role: 'assistant',
      content: '''
## 豆瓣电影 TOP250 经典

| 片名 | 年份 | 豆瓣评分 | 类型 |
|------|------|----------|------|
| **肖申克的救赎** | 1994 | ⭐ 9.7 | 剧情/犯罪 |
| **霸王别姬** | 1993 | ⭐ 9.6 | 剧情/爱情 |
| **控方证人** | 1957 | ⭐ 9.6 | 悬疑/犯罪 |
| **泰坦尼克号** | 1997 | ⭐ 9.5 | 爱情/灾难 |
| **阿甘正传** | 1994 | ⭐ 9.5 | 剧情 |
| **美丽人生** | 1997 | ⭐ 9.5 | 剧情/战争 |
| **辛德勒的名单** | 1993 | ⭐ 9.5 | 剧情/历史 |
| **千与千寻** | 2001 | ⭐ 9.4 | 动画/奇幻 |
| **星际穿越** | 2014 | ⭐ 9.4 | 科幻/冒险 |
| **这个杀手不太冷** | 1994 | ⭐ 9.4 | 动作/剧情 |

## 豆瓣热门剧集

| 片名 | 年份 | 豆瓣评分 | 类型 |
|------|------|----------|------|
| **绘梦婚礼** | 2026 | ⭐ 9.5 | 爱情/奇幻 |
| **铁拳教育** | 2026 | ⭐ 8.8 | 剧情/运动 |
| **龙之家族 第三季** | 2026 | ⭐ 8.4 | 奇幻 |
| **校园之外 第一季** | 2026 | ⭐ 8.4 | 剧情 |
| **低智商犯罪** | 2026 | ⭐ 8.2 | 喜剧/犯罪 |
| **躲在超市后门抽烟的两人** | 2026 | ⭐ 8.2 | 剧情 |
| **主角** | 2026 | ⭐ 8.1 | 剧情 |

## 豆瓣新片高分

| 片名 | 年份 | 豆瓣评分 | 类型 |
|------|------|----------|------|
| **挽救计划** | 2026 | ⭐ 8.6 | 科幻 |
| **我，许可** | 2026 | ⭐ 8.1 | 剧情 |
| **东京出租车** | 2025 | ⭐ 8.0 | 剧情 |
| **爱上平行时空的你** | 2025 | ⭐ 8.0 | 爱情/科幻 |
| **她回来的那天** | 2026 | ⭐ 7.5 | 悬疑 |

---

想搜索哪部的资源？或者告诉我你偏好哪种类型（动作、悬疑、爱情、科幻等），我帮你精准推荐。
''',
      createdAt: DateTime(2026),
      status: AgentMessageStatus.done,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AgentMessageBubble(message: message),
          ),
        ),
      ),
    );

    expect(find.text('肖申克的救赎', findRichText: true), findsOneWidget);
    expect(find.text('绘梦婚礼', findRichText: true), findsOneWidget);
    expect(find.text('挽救计划', findRichText: true), findsOneWidget);
    expect(find.text('她回来的那天', findRichText: true), findsOneWidget);
    expect(find.textContaining('TOP250'), findsOneWidget);
    expect(find.textContaining('热门剧集'), findsOneWidget);
    expect(find.textContaining('新片高分'), findsOneWidget);
    expect(
      find.text(
        '想搜索哪部的资源？或者告诉我你偏好哪种类型（动作、悬疑、爱情、科幻等），我帮你精准推荐。',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('------'), findsNothing);
    expect(find.byType(Table), findsWidgets);
    expect(_horizontalTableScrollers(), findsWidgets);
  });
}

Finder _horizontalTableScrollers() {
  return find.byWidgetPredicate((widget) {
    return widget is SingleChildScrollView &&
        widget.scrollDirection == Axis.horizontal;
  });
}
