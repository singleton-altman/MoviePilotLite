---
name: immersive-backdrop-sheet
description: 沉浸式媒体详情 Bottom Sheet：海报/backdrop 作全屏背景 + 自上而下渐变遮罩 + 半透明内容卡。首屏用已有实体信息瞬时渲染，列表异步加载。参考订阅文件统计 Sheet。
---

# 沉浸式 Backdrop Sheet（媒体详情）

适用：从列表 Item 点开的「次级详情」——文件统计、资源明细、分集状态等。需要媒体氛围感，但不必做成独立路由全页。

## 参考实现

- `lib/modules/subscribe/pages/subscribe_files_page.dart`
  - `showSubscribeFilesSheet` / `SubscribeFilesSheet`
- 入口：列表 `onTap` 直接弹 Sheet（编辑等操作留在菜单）

## 设计风格

### 整体气质

- **Immersive + Exaggerated Minimalism**：大标题、少装饰、强对比，靠海报氛围而非多层卡片堆叠
- **色板**：统一 `DashboardPalette.of(context)`，不硬编码品牌色；下载用 `coolAccent`，媒体库用 `successAccent`
- **图标**：只用 Cupertino/Material Icon，禁止 emoji 当图标
- **触控**：关闭/刷新/复制等热区 ≥ 44×44

### 视觉结构（从上到下）

1. **全屏 Backdrop**（`Stack` 最底层）
   - 优先 `backdrop` → `poster` → 分集 still
   - `BoxFit.cover` 铺满 Sheet
2. **自上而下渐变遮罩**（盖在 backdrop 上）
   - 颜色用 `palette.pageBackground` 的 alpha 渐变，不是纯黑
   - 推荐 stops：`0 / 0.28 / 0.58 / 0.82`
   - alpha：`0.18 → 0.42 → 0.82 → 1.0`
   - 目的：顶部能透出海报，下部与列表区自然融合，避免「大海报块 + 灰白列表」割裂
3. **Intro 区**（可滚动内容顶部）
   - 拖拽条 + 关闭/刷新
   - 大字标题（约 26、w900、轻微 letterSpacing 负值）
   - 次要 meta 一行（年 / 季 / 类型）
   - Metric chip：分集 / 下载 / 媒体库（半透明底 + 细描边）
4. **列表 Item**
   - 卡片本身半透明：`surface` alpha 约 dark `0.78` / light `0.90`，让背景海报隐约透出
   - 顶区：分集 still + 大字 `E{n}` + 状态胶囊（下载/媒体库数量）
   - 底区：分区标题 + 侧强调色条的文件行（左 4px accent）
   - 路径用等宽字体；点击/长按复制，复制按钮 44px

## 交互与性能

### Sheet 容器

```
showModalBottomSheet(
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  → DraggableScrollableSheet(0.92 / 0.42 / 1)
  → ClipRRect(topRadius: 20)
)
```

- 内容主滚动必须吃 `DraggableScrollableSheet` 的 `scrollController`，否则无法下滑关闭
- Controller 用 `Get.put(..., tag:)`，Sheet 关闭后 `Get.delete(tag:)`

### 首屏加速（强制）

- **禁止**整页转圈等接口：打开瞬间用传入的 `SubscribeItem` 渲染 backdrop / 标题 / meta
- `onInit` 即发起请求；列表区单独轻量 loading（「正在加载文件…」）
- 打开前 `precacheImage(NetworkImage(convertedBackdrop))`
- 指标未返回时 chip 可显示 `…`，有 `totalEpisode` 可先填分集预估值

## 反模式（Avoid）

- 顶部再塞一块独立「大海报墙」与下方白底列表硬切
- 纯黑渐变盖死海报，或 alpha 过低导致浅色模式文字不可读
- 整 Sheet 阻塞在 `loading && data == null` 全屏 spinner
- 为该次级详情再注册独立 GetPage 路由（除非要深链分享）
- emoji / 过小复制按钮 / 路径与标题信息重复堆砌无层级

## 复用检查清单

- [ ] Backdrop + pageBackground 渐变遮罩，而非独立海报 Header
- [ ] DashboardPalette 驱动颜色与半透明卡片
- [ ] 已有实体数据瞬时首屏；列表异步
- [ ] DraggableScrollableSheet + scrollController 下传
- [ ] 文件行侧强调条 + ≥44 触控复制
- [ ] 深浅色对比可读（正文不用 faintText）
