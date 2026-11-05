# 功能缺口盘点（对照服务端能力与官方 Web 前端）

> 日期：2026-10-15。契约依据：发布的 Swagger、MoviePilot v2 分支和 v3.1.5 tag，以及对应前端。发布的 Swagger 与两个版本均存在差异，不能直接据此删除兼容逻辑。
> 本文 A/B/C 表格保留最初盘点范围，并非当前缺失清单。早期正则检索与静态分析不足以证明功能不存在或已完成；当前状态以“本轮复核与验收”及实际测试结果为准。没有部署中 V2/V3 服务端的凭据，本轮没有真实服务器联调证据。

## A. 整块缺失的功能

| # | 功能 | 服务端能力 | 官方 Web | 说明 |
|---|------|-----------|---------|------|
| A1 | **音乐模块** | v3 音乐媒体源（MusicBrainz/TheAudioDB/豆瓣音乐）、搜索支持艺术家、音乐订阅 | /music、/music/album、/music/artist、/music/artist/resources、/subscribe/music | App 仅有播放器可播音频文件，无音乐发现/专辑/艺术家/音乐订阅。v3 特性 |
| A2 | **订阅分享广场 + 关注体系** | subscribe/share/statistics、follow 增/删/查、seerr 通知订阅 | /subscribe-share 页面 | App 订阅卡片可"分享"，但无广场（浏览/订阅他人分享）与关注 |
| A3 | **MFA 管理（OTP 绑定 + Passkey）** | /api/v1/mfa ×10：OTP generate/verify/disable；Passkey 注册/认证/列表/删除 | 设定-安全 | App 登录可输入 OTP 验证码，但无法在 App 内绑定/解绑 OTP，无 Passkey 登录 |
| A4 | **MCP 工具** | /api/v1/mcp、mcp/tools、tools/call、tools/{name}/schema；agent 的 MCP 服务器配置（message/agent/mcp/servers ×3） | 智能助手侧栏 | App 有 AI 会话（sessions），无 MCP 工具管理与调用 |
| A5 | **/api/v3 订阅契约** | movie/series CRUD + lookup（Radarr/Sonarr 风格）、system/status | （Web 走 v1） | 第三方集成契约，App 未跟进；可作为长期项 |
| A6 | **下载历史** | history/download 查询/删除 | /history 页（含整理历史） | App 有整理历史（media_organize）与下载器实时任务，但无服务端下载历史页 |
| A7 | **WebPush 通知** | message/webpush/subscribe、webpush/send | 浏览器推送 | App 已集成极光推送；WebPush 为服务端原生通道，可作为补充（低优） |

## B. 已有模块的子功能缺口

| 模块 | 缺失子功能（端点） |
|------|------------------|
| 站点 site | Cookie&UA 更新（cookie/{id}）、CookieCloud 同步、连接测试（test/{id}）、批量优先级（priorities）、重置、认证站点（auth 查/认证）、RSS 站点/支持列表、单站统计详情（statistic/{url}）、域名映射（mapping） |
| 订阅 subscribe | 手动维护动作：刷新订阅（refresh）、刷新 TMDB 信息（check）、搜索所有订阅（search） |
| 插件 plugin | 评分查询/提交（rating）、更新说明（history/{id}）、Release 版本（releases/{id}）、重载（reload/{id}）、插件仪表板卡片（dashboard/meta、dashboard/{id}）、分身（clone）、文件夹管理（folders ×4）、市场联邦（remotes）、Wiki 同步市场（PLUGIN_MARKET/sync-wiki） |
| 系统 system | 重启（restart）、升级（upgrade）、日志文件下载（logging/download）、过滤规则测试（ruletest）、网络测试目标（nettest/targets）、实时消息 SSE（message）、安装统计（usage/statistic） |
| 整理 transfer | 整理队列监控/移除（queue GET/DELETE）、手动整理目的路径匹配（manual/target-path）、集数定位模板推荐（episode-format/recommend）、手动整理成功历史（manual/history）、立即执行整理（now）、AI 重新整理（history/transfer/ai-redo ×2） |
| 存储 storage | 网盘配置全流程：扫码登录（qrcode）、OAuth 授权 URL（auth_url）、确认/保存/重置（check/save/reset）、整理方式（transtype）。现仅只读用量 |
| 设置 settings | 通知渠道配置（notification/wechatclawbot ×5）；LLM 提供商目录（llm/providers）、OAuth 授权流程（provider-auth ×5）、调用测试（llm/test）；分类策略配置（media/category/config）；剧集组（media/groups）；「搜索&下载」「订阅」两个分类处于注释状态待恢复 |
| 智能助手 agent | 可用命令（commands）、附件上传/下载（upload、file/{id}）、按钮回调（callback）、停止任务（stop）、会话展示管理（display） |
| 搜索 search | 按标题模糊搜字幕（subtitle/title/stream；现仅媒体精确搜索）、AI 推荐资源（recommend）、上次搜索上下文（last/context） |
| 缓存 cache | TMDB/豆瓣识别缓存查询/清空（tmdb/cache、douban/cache）；种子缓存的删除/刷新/重新识别（torrent/cache ×3；现仅只读列表） |
| 媒体详情 | 合集详情（tmdb/collection）；Bangumi/AniList 源的相关推荐与详情直查（现相关推荐仅支持 TMDB/豆瓣源） |
| 用户 user | 头像上传（avatar/{id}）、用户级配置读写（config/{key}）、当前用户信息（current） |
| 仪表盘 dashboard | 进程信息（processes）、系统摘要（system）、后台服务执行进度（schedule/{id}/progress） |

## C. 边角（低优先级）

- login/wallpaper 登录页海报（现用服务器壁纸设置间接实现）
- download/paths 可用下载路径查询（添加下载弹层可用它做路径选择）
- auth/providers 认证提供方查询、auth/exchange 插件票据兑换
- mediaserver/exists_remote 远程库存在性查询
- recommend/source 动态推荐源（现硬编码 13 个源，服务端新增源不感知）
- system/setting/public、system/global 非敏感设置读取
- openai/anthropic 兼容接口、webhook、cookiecloud 服务端（App 场景基本用不到，列出仅求全）

## 实现进度

### 2026-10-15 第五轮（已完成，flutter analyze 0 error）

- ✅ **A4 MCP 工具**：新增 mcp 模块与「MCP 工具」页（设置-系统入口，路由 /mcp-tools），双 Tab：
  - 工具 Tab：工具列表（name/description/inputSchema）、参数 Schema 查看、JSON 参数编辑与调用（结果可复制）。MCP 工具族走 X-API-KEY 鉴权（值为服务端 API_TOKEN，超管下自动从 /system/env 读取），未配置时给出明确鉴权提示。
  - 服务器 Tab：Agent 外部 MCP 服务器配置管理（列表/启用停用开关即时保存/单服务器连接测试），走用户鉴权（服务端校验超管）。
- ✅ **B-系统维护**：设置-系统新增「系统维护」页（重启 GET /system/restart、升级 POST /system/upgrade），均带二次确认与风险说明，双线一致。
- ✅ **B-网盘配置流程**：存储卡片新增管理菜单——OAuth 授权链接（auth_url 打开浏览器）、检查扫码/授权结果并保存（check → save）、重置配置（reset，确认）。**v2 独有**（v3.1.5 已并入 storage/manage，入口提示迁移）。
- ✅ **B-缓存管理动作**：缓存页新增全局菜单（刷新种子缓存/清空种子缓存/查看 TMDB 识别缓存/清空 TMDB 识别缓存）与条目级菜单（删除种子缓存/重新识别，按 domain+hash）。**豆瓣识别缓存经双线源码核实不存在**（仅 Swagger 收录，v2/v3.1.5 douban.py 均无 cache 路由），不实现并在审计中记录。
- ✅ **B-字幕标题模糊搜索**：字幕搜索在无媒体标识（纯标题关键词）时自动切换到 subtitle/title/stream（keyword 参数），有标识时保持原媒体精确搜索。
- ✅ **B-用户头像上传**：个人中心头像可点击（带相机角标），从相册选图（image_picker，压缩至 1024px）multipart 上传 POST /api/v1/user/avatar/{user_id}，成功后刷新用户信息。

### 2026-10-15 第四轮（已完成，flutter analyze 0 error）

- ✅ **B-插件管理增强**：插件卡片菜单新增「更新与评分」入口，打开管理面板——更新说明（GET plugin/history/{id}，按版本分组）、版本列表（GET plugin/releases/{id}，Release 支持判定 + 最新/当前版本对照）、评分（GET/POST plugin/rating/{id}，平均分/人数/我的评分 + 0.5-5.0 滑杆提交）；面板顶部提供重载（v3.1.5 为 POST、v2 为 GET，先 POST 后按 404/405 回退）。
- ✅ **B-整理队列监控**：新增 transfer 模块整理队列页（GET /api/v1/transfer/queue），按媒体分组展示任务（文件名/下载器/状态中文映射），支持按任务移除（DELETE 原样回传该任务的 fileitem 请求体，二次确认）；入口在媒体整理页顶栏。
- ✅ **B-通知渠道设置**：设置-系统分类新增「通知渠道」子项，微信 ClawBot 管理页（登录状态、刷新二维码、测试连通、迁移登录缓存、退出登录）。**v2 独有**：v3.1.5 已移除该端点族，v3 服务端展示迁移说明。
- 版本核验补充：plugin reload 方法在 v2(GET)/v3.1.5(POST) 间有差异，采用先 POST 后回退；transfer/queue 双线一致；wechatclawbot 仅 v2。

### 2026-10-15 第三轮（已完成，flutter analyze 0 error）

- ✅ **A1 音乐模块补完（播放 + 订阅）**：专辑页新增「播放」与「订阅」操作。播放走既有 PlayerLaunchController 链路：以「艺术家 + 专辑名」在已配置媒体服务器检索音频条目（文件扩展名 + 音视频流判定），命中后携带播放列表进入内嵌播放器，未入库时明确提示；订阅按 v3 契约 POST /api/v1/subscribe/（type=音乐、music_type=album、media_source/media_id 身份），绕过影视身份清洗避免音乐身份被剥离。
- ✅ **A3 MFA（OTP 全量 + Passkey 管理）**：新增 mfa 模块与「两步验证」设置页（路由 /mfa-settings，入口在个人中心「二步验证」行）。OTP：状态查询（v2 走 /mfa/status/{username}，v3 走 /user/current 的 is_otp）、生成绑定密钥（secret + otpauth URI 可复制）、验证码绑定、密码确认解绑；Passkey：列表查看与密码确认删除。双版本端点一致无需门控。**Passkey 注册/登录的 WebAuthn 交互需平台能力（关联域名、原生插件），App 内不伪造，注册引导到 Web 端**——此项为平台配置依赖，非纯代码可实现。
- 端点核验补充：mfa 在 v2/v3.1.5 双线均存在；/mfa/status/{username} 仅 v2 有（v3 改由 user/current 携带）。

### 2026-10-15 第二轮（已完成，flutter analyze 0 error）

- ✅ **A2 follow 关注体系 + 入口扩展**：subscribe_share_controller 新增已关注列表加载（GET /follow）、关注/取消关注（POST/DELETE /follow?share_uid=）与「只看关注」过滤；分享卡片在分享人旁新增关注/已关注按钮；广场页 AppBar 新增只看关注过滤开关。订阅页分享入口从仅剧集 tab 扩展到全部 tab（广场本身不区分类型）。双版本一致无需门控。
- ✅ **A1 音乐模块首轮（浏览）**：新增 music 模块——音乐库浏览页（GET /api/v1/music/explore，MusicBrainz/TheAudioDB/豆瓣音乐三源切换 + 分页）、艺术家页（artist 详情 + 专辑分页）、专辑页（详情 + 曲目列表）；v3 独有能力按 isV3 探测门控，v2 服务端显示引导提示；入口在「更多」页新增「媒体 · 音乐库」分组卡片。路由 /music、/music/artist、/music/album。首轮不含播放与音乐订阅，列为后续轮次。
- 顺手清理：分享卡片中无调用的死方法 _buildMoreButton。

### 2026-10-15 第一轮（已完成，flutter analyze 0 error）

- ✅ **A6 下载历史**：新增 downloader 模块下的 download_history_item 模型、download_history_controller、download_history_page（骨架/空态/错误重试/下拉刷新/分页加载），路由 /download-history，入口在下载管理页 AppBar。
- ✅ **B-订阅维护动作**：subscribe_service 新增 refresh/check/search 三方法与 maintenanceSupported（v2 独有，v3 隐藏入口并提示），订阅页 AppBar 新增维护入口与操作面板。
- ✅ **B-站点 Cookie 维护（部分）**：site_detail_controller 新增更新 Cookie&UA（账号密码流）、连接测试、CookieCloud 同步；站点详情页 AppBar 新增维护菜单与更新弹窗。批量优先级/认证站点等仍待做。
- 更正：A2 订阅分享**部分已存在**——subscribe_share_controller 已接 /api/v1/subscribe/shares（广场）与 share/statistics（统计），入口在订阅页（当前仅剧集 tab 显示）；剩余缺口为 follow 关注增删查与电影/动画 tab 入口。

### 版本适配说明

- 订阅维护三动作（refresh/check/search）：v2 有、v3.1.5 已移除 → 按 isV3 门控。
- 下载历史、站点 Cookie/测试/CookieCloud：v2 与 v3.1.5 双线一致，无需门控。

## 本轮复核与验收（2026-10-15 第六轮）

本节是当前唯一有效的完成度依据。历史轮次标题中的「已完成，flutter analyze 0 error」只代表当时的静态分析状态，不代表端到端验收。本轮证据：全量 `flutter test` 253 项全部通过、全量 `flutter analyze` 0 error（余 1068 条 warnings/infos 为存量 lint，主要是 freezed 注解 534 条与 GetX protected 成员 70 条，分布在本轮未触碰的文件）。**没有真实 V2/V3 服务端联调，以下均为源码核对 + mock/本地桩测试结论。**

### 已验证（有针对性回归测试）

- **手动整理辅助**：target-path / episode-format / manual-history / AI 重整按 V2 与 v3.1.5 源码核对接通；target-path 与 manual-history 实际返回对象而非列表；AI 重整仅在服务端发布能力、管理权限、AI 已启用且历史 ID 有效时出现；真实文件操作前二次确认；存储切换/目录刷新/迟到响应不覆盖用户输入。18 项测试（12 service + 6 widget）。
- **插件管理**：文件夹增删改与成员编辑、克隆防重、remotes 元数据展示（不执行组件）、release/评分/更新历史、reload 按 V2 GET / V3 POST 分流；保存前读取服务器快照拒绝过期编辑（无原子写，跨客户端竞态仍在）。32 项测试。
- **智能助手**：附件走真实带鉴权 multipart 上传与同源下载（非原先错误的“附件名拼进文本”）、命令选择、本地 SSE 停止与后端 stop 分离；V2 包裹 / V3 裸两种信封兼容；握手超时、迟到历史/上传、重复发送均有 generation 防护。32 项测试。限制：图片以文件对象提交（未走 images 数组）、无内联预览、无 V3 commands/run。
- **MCP**：服务器配置完整 JSON 深拷贝保留（不再丢 args/env/headers/未知字段）；管理权限 fail-closed；控制器与 AppService 实例 + 服务器/账号 + App/API 地址绑定，切服/切号后旧 key、旧配置、迟到回滚一律失效；请求钉住原 URL 与 bearer。33 项测试。
- **推荐源/合集/用户配置/下载路径**：recommend/source 仅做扩展源、保留默认 13 源；修复 Dart Uri 会先规范化再校验导致 `..` 路径穿越检查失效的安全缺陷（先检查原始解码路径）；新增 TMDB 合集页（详情页直达）；user/config GET 值在 data.value、POST body 即 value 本身；/download/paths 用 save_path。15 项测试。下载弹层的远程目录恢复按 服务器+用户 作用域持久化，仅在当前作用域服务端 save_path 集合内恢复，弹层加载前捕获作用域、过期响应由控制器丢弃。
- **下载历史**：模型修正为与 Swagger 一致（seasons/episodes/userid 为可空字符串、note 任意 JSON、补 episode_group），深拷贝保留未知字段；删除缺 id 拒绝；business false 不清列表。含专项测试。
- **整理队列**：reload 防重入、business false 不改本地、删除需管理权限 + 缺 path 拒绝 + storage+path 去重、失败不移除任务；空队列可刷新。3 项测试。
- **版本探测**：media/source 404 缓存为 V2 空能力集；business false / 临时失败 / 格式异常不缓存；请求钉住捕获时的绝对地址与 token，切服在途响应整体丢弃。5 项测试。
- **系统健康检查**：回退只保留 /system/ping 并建模为单条「服务连接」（该版本无模块级健康检查的事实如实展示）；删除把 /system/versions（GitHub Release 列表）误当健康结果的解析；moduletest 业务 false 不再伪装 disabled（消息明确表达未启用除外）。4 项测试。
- **LLM 模型列表**：删除未经证实的 /system/llm-models 回退；V2 走 GET llm/models，v3.1.5 走 POST llm/manage（target=provider、action=list_models，已核对 v3.1.5 运行时 provider_manage 与 LlmProviderAction 枚举字面量）；旧 V2 字符串列表与新 records 两种形状都解析；错误消息脱敏。3 项测试。
- **音频播放链路（重建后）**：早期「播放完成」声明不成立（原 MediaServerService 仅搜 Movie/Series）。现以可选 AudioSearchCapability 落地：Emby/Jellyfin 实现音轨检索（/Items 专辑过滤 + 无视频流校验 + 艺术家/专辑规范化匹配 + disc/track 排序），FnOS 显式不支持；音乐库经 supportsAudioSearch 探测后调用 searchAudio，播放页音频队列与自动连播独立于视频偏好。测试在 test/modules/player/audio_media_server_test.dart 与 test/modules/music/**。**未在真实媒体服务器上播放验证**。
- **权限与安全**：/mcp-tools、/system-maintenance 收紧为超管；新路由补 permissionGuards；Dio 日志关闭请求/响应头与正文（API_TOKEN、MCP env/headers、OTP、密码不再进日志）；MCP API-key 场景使用 skipUnauthorizedHandling，避免 401 误清 JWT（含本地 HTTP 服务回归）。
- **插件表单适配策略落地**（2026-10-16）：经服务端基类核实，插件渲染模式只有 vuetify（get_form 返回 Vuetify 组件树 JSON）与 vue（插件自带编译后前端）两种，服务端不存在第三种扁平字段格式。适配顺序确定为：特殊插件 ID 的原生适配器（TrashClean/P115StrmHelper/ProxmoxVEBackup/SubtitleManualUpload/BrushFlow/AppLitePush）最高优先；vuetify 模式走通用渲染并本轮补强——model/v-model/modelvalue 三种绑定键兼容（对齐官方 FormRender）、conf 单 dict/非 Map 条目宽容归一化、表单中不支持组件列表提示「请在 Web 端调整」；其余 vue 插件留待逐插件适配，当前显示引导空态（说明 + 服务器地址复制/打开 Web 端）。3 项回归测试。注意：注册过的插件 ID 会强制走适配器，即使服务端改回 vuetify 树也不回退，属有意取舍。

### 部分实现 / 待继续

- **存储授权**：V2 二维码/OAuth/check/save/reset 流程已有（第五轮）；**V3 storage/manage 契约适配未完成**（代理中断），V3 端仍提示迁移。
- **通知渠道**：V2 wechatclawbot 管理完整；**V3 notification/config/manage UI 未做**。
- **MFA**：OTP 绑定/解绑、Passkey 列表/删除可用；**Passkey 注册/登录需平台 WebAuthn 能力，未实现**。
- **LLM**：模型列表已接真实契约；provider 目录（llm/providers）、OAuth 授权流、llm/test 调用测试 UI 未做。
- **音乐**：目录/艺术家/专辑/订阅/播放入口已有；**音乐订阅管理页、播放未真机验证**。
- **订阅/站点复核**（关注切换、维护动作版本、凭据弹窗生命周期等审计任务）因执行中断未完成，现状按第五轮结果保留。

### 仍未开始（保持缺口）

- A5 /api/v3 Radarr/Sonarr 兼容契约（是否属于移动端需求待产品裁剪）
- A7 WebPush 与原生通知差异
- 站点批量优先级、认证站点、域名映射、单站统计
- 分类策略与剧集组配置（media/category/config、media/groups）
- 插件 dashboard 卡片、wiki 市场同步
- 系统 dashboard 进程/后台进度（processes、schedule/{id}/progress）
- auth/providers、auth/exchange、login/wallpaper
- last/context 搜索上下文、AI 推荐资源（search/recommend）

## 建议优先级


1. **高价值**：A1 音乐模块、A2 订阅分享广场、A6 下载历史、B-站点 Cookie 维护（Cookie/UA 更新 + CookieCloud + 连接测试）、B-订阅维护动作（三个手动刷新/搜索）。
2. **中价值**：A3 MFA/Passkey、A4 MCP 工具、B-插件评分/更新/重载、B-整理队列、B-网盘配置流程、B-设置通知渠道。
3. **低优先**：A5 /api/v3 契约、A7 WebPush、C 类边角。

> 版本纠正：音乐目录属于 V3；MFA、MCP、助手附件与停止、插件分组、整理辅助在所核对的 V2/V3 源码均存在，不能统一按 V3 门控。通知与存储管理在两版本间有真实契约差异，须分别适配。发现源接口在 V2 也存在，不能用它判断 V3。版本探测保留媒体来源接口；404 可缓存为 V2 能力缺失，临时失败和错误业务信封不缓存为版本结论。
