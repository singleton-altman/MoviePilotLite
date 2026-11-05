# UI 优化计划（MoviePilotLite 移动端）

> 基于 2026-10 全量代码调研整理。调研覆盖：整体导航与主题体系、核心内容消费页面（仪表盘/发现/推荐/搜索/详情/订阅）、管理与工具页面、播放器与动态表单。
> 本文档同时作为执行清单：每项标注状态（待办 / 本轮已执行 / 已完成）。

## 背景

应用单点设计能力较强（毛玻璃底部导航、iOS 26 液态玻璃适配、海报取色、skeletonizer 骨架屏、Section 分组卡片、文本溢出处理普遍到位），但缺少全局约束，导致各模块视觉与交互语言割裂。服务端（MoviePilot，FastAPI + Vue/Vuetify）功能主线为：订阅 → 搜索 → 下载 → 整理 → 刮削 → 通知，移动端应围绕这条主链路提供一致体验。

## 现状核心问题（调研结论）

1. 三套色彩体系并存：AppTheme（默认色为无人引用的死值）、AppService 实际默认色、Dashboard 模块私有 DashboardPalette；模块下硬编码 Color() 近 400 处、Colors.white/black 600+ 处。
2. 空态/错误态/加载态无统一组件：「暂无」文案 100+ 处、私有 EmptyState 至少 8 个、加载指示有 lottie / CupertinoActivityIndicator / CircularProgressIndicator / skeletonizer 四种语言。
3. 卡片规格混乱：同层级海报卡圆角 8~25 不等，网格间距 8/10/12/16 各异，描边型与阴影型卡片并存。
4. Material 2 与 Cupertino 大面积混用：返回按钮 5 种写法、Switch 两套、下拉刷新两套、弹层两套、Toast 两套（宿主 Get.snackbar 与播放器包 ScaffoldMessenger）。
5. 交互不一致：发现页无分页；「加载更多」显式按钮与无限滚动并存；下拉刷新有无不一；discover 用 AppBar 图标进筛选而订阅/搜索结果用悬浮玻璃栏。
6. 真实 Bug：弹幕设置页浅色主题白字不可读；种子搜索结果页空态组件未接线（空结果白屏）；下载任务与弹幕服务器删除无二次确认。
7. 工程卫生：recently_added / recently_playing 两个 ~850 行文件近乎复制；两个搜索结果页各自复制悬浮栏；播放器 player_screen 单文件 ~5900 行；死代码与死资产（agent_pet.json、file_item_widget、DiscoverMediaCard）；残留 print 调试输出；l10n 仅 3 个 key 形同虚设。

---

## P0 —— 真 Bug 与安全缺口（本轮执行）

| # | 问题 | 位置 | 方案 | 状态 |
|---|------|------|------|------|
| 0-1 | 弹幕设置页列表文字硬编码白色，浅色主题不可读 | lib/modules/player/pages/danmaku_settings_page.dart | 文字/图标颜色改为跟随主题（colorScheme / AppTheme token） | 本轮已执行 |
| 0-2 | 「删除此服务器」无二次确认 | lib/modules/player/pages/danmaku_settings_page.dart | 删除前弹 CupertinoAlertDialog destructive 确认 | 本轮已执行 |
| 0-3 | 种子搜索结果页空态组件已定义但未接线，空结果白屏 | lib/modules/search/pages/search_media_result_page.dart | 将空态接入正文构建分支（非 loading 且无数据时展示，含重试） | 本轮已执行 |
| 0-4 | 残留 print 调试输出 | lib/modules/player/widgets/detail_play_section.dart、lib/modules/player/pages/episode_picker_sheet.dart | 移除 print，必要处改 applog | 本轮已执行 |
| 0-5 | 下载任务删除无二次确认 | lib/modules/downloader（deleteTask 调用链） | 删除入口弹 CupertinoAlertDialog destructive 确认 | 本轮已执行 |

## P1 —— 设计体系地基（下一轮）

| # | 问题 | 方案 | 状态 |
|---|------|------|------|
| 1-1 | 三套色彩 token 并存 | 建立唯一语义 token 层（pageBackground / surface / textPrimary / textMuted / accent / danger），DashboardPalette 收编，清除 AppTheme 死默认色 | 待办 |
| 1-2 | 空态/错误态/加载态无统一组件 | 新建全局状态视图组件（骨架 / 空+引导动作 / 错误+重试），策略：内容形列表用骨架，动作反馈用统一加载动画 | 待办 |
| 1-3 | 卡片规格混乱 | 定一版卡片规格：海报卡 / 横条行卡 / 信息磁贴三种，圆角按尺寸分档（12/16/20），统一阴影/描边语言与网格间距 | 待办 |
| 1-4 | 硬编码颜色散落（dynamic_form 107 处、search 42、search_result 30、media_detail 29 为重灾区） | 按 1-1 token 逐模块替换，优先 search / search_result / media_detail | 待办 |
| 1-5 | 返回按钮/开关/下拉刷新/弹层各自两套 | 立三条铁律：返回按钮一种、开关一种（CupertinoSwitch）、列表下拉刷新统一 CupertinoSliverRefreshControl 并覆盖全部列表页 | 待办 |

## P2 —— 主链路交互统一（后续）

| # | 问题 | 方案 | 状态 |
|---|------|------|------|
| 2-1 | 发现页无分页（永远第一页） | 改无限滚动 + 尾部状态组件 | 待办 |
| 2-2 | 「加载更多」显式按钮与无限滚动并存 | 统一无限滚动（LoadMoreFooter 已有，推广使用） | 待办 |
| 2-3 | 筛选入口两套（AppBar 图标 vs 悬浮玻璃栏） | 以 GlassSearchFloatingBar 为基础统一内容型页面筛选交互，discover 迁移 | 待办 |
| 2-4 | 媒体详情页无取色，固定深色背景 | 接入已有取色缓存（PluginPaletteCache），头部渐变随海报变色，配合骨架平滑过渡 | 待办 |
| 2-5 | 详情页订阅反馈文案分支歧义 | 按订阅/取消 × 成功/失败四态明确文案 | 待办 |
| 2-6 | 装饰性假按钮（dashboard 卡片角标圆钮、recommend AppBar 空实现按钮） | 接功能或移除 | 待办 |
| 2-7 | 「从头看」11.5px 文字按钮触达过小 | 扩大点击区域至 ≥44px | 待办 |
| 2-8 | Recommend 页固定深绿底不跟随主题、英文标题、布局靠关键词猜测 | 收敛猜测逻辑至一处并加兜底；标题本地化；明确沉浸深色是否保留为刻意模式 | 待办 |
| 2-9 | 弹幕设置「设为默认」依赖长按，可发现性差 | 行内显式按钮或滑动操作 | 待办 |

## P3 —— 性能、重复代码与打磨（长期）

| # | 问题 | 方案 | 状态 |
|---|------|------|------|
| 3-1 | Section 内部 shrinkWrap 列表被长表单大量嵌套（设置页/动态表单全量构建） | 表单迁 CustomScrollView/sliver 体系 | 待办 |
| 3-2 | recently_added / recently_playing ~850 行复制 | 提炼共享海报 rail 组件 | 待办 |
| 3-3 | 两个搜索结果页各自复制悬浮栏/关键词弹层 | 抽公共组件 | 待办 |
| 3-4 | 播放器包与宿主两套 Toast | 桥接到宿主 ToastUtil | 待办 |
| 3-5 | player_screen 单文件 ~5900 行 | 按手势/HUD/面板拆分 | 待办 |
| 3-6 | 死代码与死资产（agent_pet.json、file_item_widget.dart、DiscoverMediaCard） | 清理 | 待办 |
| 3-7 | 60 个路由零转场定制、全库仅 1 处 Hero | 海报→详情共享元素转场；统一 sheet 动画 | 待办 |
| 3-8 | l10n 形同虚设，中英混杂 | 短期统一为中文（消灭混入英文），长期铺 l10n key | 待办 |
| 3-9 | 底栏避让魔法数（100）、hideBottomNavBar 页面手动开关 | 从导航栏实际高度推导；集中协调可见性 | 待办 |
| 3-10 | setting 与 settings 双模块职责割裂 | 合并模型与页面到同一模块 | 待办 |

## 执行约束

- 每轮改动避开工作区未提交文件（本轮避开：discover、download、dynamic_form、index、.cursorrules 等本地已修改文件）。
- 页面根布局遵守 AGENTS 公约：Scaffold + appBar，不新增 CupertinoPageScaffold 整页根。
- 每轮以 flutter analyze 通过为验收线；涉及行为变更处补充/运行对应测试。

## 执行记录

### 2026-10-15 · P0 轮

- 0-1 弹幕设置页：空态/状态文字/徽标/边框全部改为主题色推导，浅色主题可读；删除服务器增加 ToastUtil.warning destructive 确认（取消保留编辑弹层，确认后删除并关闭）。
- 0-3 种子搜索结果页：空态接入正文分支（区分「未搜到资源」与「筛选后无匹配」两态，均带重新搜索入口）；新增 CupertinoSliverRefreshControl 下拉重新搜索；SSE 搜索进行中不提前显示空态。
- 0-5 下载任务删除：downloader_page 删除入口增加 destructive 确认，文案带任务标题。
- 0-4 调试输出清理：detail_play_section / episode_picker_sheet 的 print 全部改 AppLog（debug/error），移除按钮空转发打印。
- 附带：macos GeneratedPluginRegistrant 由 flutter 工具链补全播放器 PR 新增插件注册（screen_brightness / sqlite3_flutter_libs / video_player_avfoundation），为正确生成物，保留；pubspec.lock 漂移已按约定还原。
- 验收：flutter analyze 全仓库 0 error；改动文件除存量 lint（withOpacity 弃用等历史风格）外无新增问题。
- P1～P3 待后续轮次执行。
