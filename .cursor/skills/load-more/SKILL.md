---
name: load-more
description: 为分页列表添加统一的 LoadMoreFooter 组件（加载更多按钮、loading、没有更多了）。在列表底部分页、加载更多、hasMore、分页 footer 场景使用。
---

# Load More Footer

## 组件

`lib/widgets/load_more_footer.dart` → `LoadMoreFooter`

## 何时使用

- 列表分页，`has_more` / `hasMore` 为 true 时显示「加载更多」
- 无更多数据时显示「没有更多了」
- 请求进行中显示 spinner +「加载中…」

## 用法

```dart
import 'package:moviepilot_mobile/widgets/load_more_footer.dart';

// 列表有内容时放在列表底部
LoadMoreFooter(
  hasMore: controller.hasMore.value,
  isLoading: controller.isLoadingMore.value,
  total: controller.total.value, // 可选，显示「加载更多 · 共 N」
  onLoadMore: controller.loadMore,
)
```

## 参数约定

| 参数 | 说明 |
|------|------|
| `hasMore` | 是否还有下一页 |
| `onLoadMore` | 点击回调；loading 时自动禁用 |
| `isLoading` | 分页请求进行中 |
| `hasItems` | 列表为空时不渲染 footer，默认 `true` |
| `total` | 可选总数，拼进按钮文案 |
| `padding` | 默认 `EdgeInsets.fromLTRB(0, 12, 0, 4)` |
| `label` / `endLabel` | 自定义文案 |

## Controller 约定

- `loadMore()` / `loadMoreXxx()`：仅在 `hasMore && !loading` 时发起请求
- 分页 loading 用独立字段（如 `isLoadingMore`、`mediaSearching && items.isNotEmpty`），避免与全页 loading 混淆
- `total` 来自 API 的 `total` 字段

## 视觉规范

- 全宽圆角卡片（12px），浅色底 + 细边框
- 最小高度 44，满足触控目标
- 主色图标 `expand_more_rounded` + 加粗 label
- loading 时替换为 `CupertinoActivityIndicator(radius: 9)`
- 无更多：居中次要色小字「没有更多了」

## 参考实现

- `lib/modules/dynamic_form/widgets/VueStyle/subtitle_manual_upload/subtitle_manual_upload_widgets.dart`
  - 搜索资源列表：`mediaSearching && medias.isNotEmpty`
  - 匹配历史：`matchHistoryLoading`

## 迁移旧代码

替换 `OutlinedButton.icon` / 裸 `CupertinoButton` 加载更多：

```dart
// Before
if (hasMore)
  OutlinedButton.icon(
    onPressed: controller.loadMore,
    icon: const Icon(Icons.expand_more),
    label: Text('加载更多 · 共 $total'),
  ),

// After
if (items.isNotEmpty)
  LoadMoreFooter(
    hasMore: hasMore,
    total: total,
    isLoading: isLoadingMore,
    onLoadMore: controller.loadMore,
  ),
```

列表为空时不放 footer；有内容且无更多时 footer 自动显示「没有更多了」。
