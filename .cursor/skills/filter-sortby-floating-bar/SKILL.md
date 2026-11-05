---
name: filter-sortby-floating-bar
description: Build pages with 搜索/筛选/排序 的“floating bar”（姐狗味）交互：筛选按钮 + fake input + sortBy，放在 floatingActionButton 且使用 FloatingActionButtonLocation.centerDocked。参考 SearchMediaResultPage 的结构与视觉实现。
---

# 带搜索/筛选/排序的 Floating Bar 页面（centerDocked）

适用场景：列表型页面需要「关键字搜索/筛选(Filter)/排序(SortBy)」，且希望交互入口固定在底部中间（`FloatingActionButtonLocation.centerDocked`），呈现“悬浮玻璃胶囊条”的观感。

## 参考实现

- `lib/modules/search/pages/search_media_result_page.dart`
  - `floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked`
  - `_buildFloatingBar`：Filter / FakeInput / SortBy
  - BackdropFilter blur + pill 容器

## 必备结构

### 1）Page 结构（Scaffold）

- `Scaffold`
  - `floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked`
  - `floatingActionButton: _buildFloatingBar(context)`
  - `body: _buildBody(...)`
- `body` 底部预留空间，避免列表最后一项被 floating bar 覆盖（参考 SearchMediaResultPage 的 bottom spacer 处理）。

### 2）Controller/State 约定

最少需要三个状态：

- `keyword`：当前搜索关键字（String）
- `filters`：筛选条件（结构自定义，建议可序列化，便于持久化/恢复）
- `sortKey + sortDirection`：排序 key 与升降序

推荐约定（与 SearchMediaResultPage 一致）：

- `visibleItems`：基于 keyword/filters/sort 计算后的展示列表
- `hasActiveFilters`：是否存在激活筛选，用于高亮 filter 图标
- `updateKeyword(String v)`：更新 keyword 并触发列表刷新
- `openFilterSheet()`：打开筛选 sheet，返回新 filters
- `updateSortKey(K key)` / `toggleSortDirection()`：更新排序

### 3）Floating Bar（“姐狗味”胶囊条）

布局：`Row([filterButton, Expanded(fakeInput), sortButton])`

视觉关键点（从 SearchMediaResultPage 抽取）：

- 外层：带透明白色蒙层的容器（`Colors.white.withValues(alpha: 0.2)`）
- 外层建议加浅色边框（与 subscribe 页一致）：
  - `border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1), width: 0.5)`
- `ClipRRect(borderRadius: 999)` + `BackdropFilter(ImageFilter.blur(sigmaX: 90, sigmaY: 90))`
- 内层 pill：固定高度（如 52），左右 padding（如 16），圆角 999
- 三个入口：
  - Filter：`CupertinoIcons.slider_horizontal_3`（有激活筛选时变色）
  - FakeInput：非 TextField，用 `GestureDetector` 打开 keyword 输入 sheet
  - SortBy：使用 pull-down/菜单式排序控件（项目已有 `SortPullDownWidget`）

### 4）FakeInput（筛选输入入口）

- 不是 TextField，避免抢焦点/键盘抖动
- 点击后弹出底部 sheet 输入 keyword（建议 `CupertinoSearchTextField`）
- sheet 建议：
  - `isScrollControlled: true`
  - `backgroundColor: Colors.transparent`
  - 根据 `MediaQuery.viewInsets.bottom` 做 padding

### 5）Filter Sheet（筛选弹层）


- `SearchMediaResultPage` 使用 `SearchResultFilterSheet` + section config 组织筛选项
- 你的页面可复用同类结构：把筛选项配置化（section + items），返回用户选择结果

### 6）SortBy（排序入口）

建议复用 `lib/modules/search_result/widgets/sort_pull_down_widget.dart`：

- 支持选择 sortKey
- 支持切换 asc/desc（方向按钮或二段交互）
- 通过 `labelBuilder` 映射展示文案（参考 `SearchMediaResultPage._sortLabel`）

## 交互细节（强制）

- Filter/Sort/Keyword 改动后：
  - 必须同步刷新 `visibleItems`
  - 必须保证返回页面时状态保持
- 列表底部必须加 spacer，避免最后几项被 floating bar 遮挡
- 若页面有异步加载（网络）：
  - skeleton 期间仍显示 floating bar（可禁用某些按钮，但保持布局稳定）

## 快速落地清单

- 在页面 `Scaffold` 上设置：
  - `floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked`
  - `floatingActionButton: _buildFloatingBar(context)`
- 实现：
  - `_buildFloatingFilterButton`
  - `_buildFakeSearchBar`（GestureDetector + text 展示 + icon）
  - `_buildFloatingSortButton`（SortPullDownWidget）
  - `_openKeywordSheet`（CupertinoSearchTextField）
  - `_openFilterSheet`（modal sheet）
- body 加底部间距：高度 ≥ floating bar 高度 + 额外安全距离

