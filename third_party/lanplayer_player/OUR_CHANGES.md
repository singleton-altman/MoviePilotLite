# lanplayer_player 包的宿主适配清单（MoviePilotLite 专用）

> **本包是 lanplayer 源码的复制 + 宿主适配**（非独立维护分叉）。
> 每次从 `D:\Trae CN\torrent\player\lanplayer` 同步新版时，**必须按下面的清单重放适配**，
> 否则会出现「JNI 崩溃 / 无法编译 / 功能失效」。重放脚本逻辑见每节说明。
>
> 同步基准：lanplayer 提交 `300b592`（2026-09-27）

## 1. 包名替换（全包，机械）

所有 Dart 文件中的 `package:lanplayer/` → `package:lanplayer_player/`。

```bash
grep -rl "package:lanplayer/" lib | while read f; do
  sed -i 's#package:lanplayer/#package:lanplayer_player/#g' "$f"
done
```

## 2. Android 原生侧（**包名不能改**）

Kotlin 桥接/插件类（`LibassBridge`、`IsoBridge`、`MpvNative`、`IsoPlugin`、`LibassPlugin`、
`ExoFFmpegPlugin/Player`、`AudioCapabilityPlugin`、`MpvSurfacePlugin`）**必须保持
`com.lanplayer` 包名**——C++ 里的 JNI 函数名是硬编码
`Java_com_lanplayer_<Class>_<method>`，改包名会导致 `UnsatisfiedLinkError` 崩溃。

文件位于 `android/app/src/main/kotlin/com/lanplayer/`（原样复制，勿改名）。
宿主 MainActivity 跨包 import 它们。

## 3. AppTheme.primary 可注入（宿主主题色）

`lib/theme/app_theme.dart`：`primary` 从 `static const` 改为可写属性（默认 lanplayer 原色
`0xFF6366F1`），由宿主调用 `LanPlayerKit.setAccentColor(color)` 注入。

**连带**：`AppTheme.primary` 不再是编译期常量，因此**不能出现在 const 表达式里**，
同步后需修复 `invalid_constant` 报错（player_screen.dart 3 处、subtitle_style_sheet.dart 4 处，
去掉相应 `const` 关键字即可）。

## 4. FilePicker 11 新 API

`FilePicker.platform.pickFiles(` → `FilePicker.pickFiles(`（player_screen.dart、
subtitle_style_sheet.dart 各 1 处；宿主 pubspec 用 file_picker 11.x）。

## 5. 引擎类型（media_kit 已移除）

- `PlayerEngineType` **删除 `mpv` 枚举值**（枚举仅剩 `exo / auto / nativeSurface`）；
- `player_screen.dart` 默认 `_engineType = PlayerEngineType.nativeSurface`；
- `player_manager.dart`：
  - iOS → `exo`（原生内核仅 Android，Kotlin + SurfaceView）；
  - HDR/蓝光 → `nativeSurface`（同为 libmpv，带 tone-mapping）；
  - `mpvOnly` 策略 → `nativeSurface`（MPV 语义由定制内核承接）；
  - 回退：`nativeSurface ↔ exo` 互为兜底；
  - `_createEngineInstance` 的 `mpv`/`auto` 分支 → `NativeSurfaceEngine()`；
  - `currentEngineType`/provider 默认值 → `nativeSurface`。

## 6. 双栈 HTTP（IPv4/IPv6 竞速回退）

- 新增 `lib/services/dual_stack_http.dart`（`createDualStackDio` + `dualStackConnectionFactory`）；
- `media_server_service.dart` 基类 Dio 改用 `createDualStackDio(...)`；
- 原因：Dart 默认不会在 IPv4 被拒后回退 IPv6，域名仅 IPv6 可达时全量请求失败。

## 7. 媒体服务器服务适配（media_server_service.dart）

- **6 处 `Fields` 增加 `UserData`**（getLibraryItems/getSimilarItems/getItemDetails/search/
  findItemByTmdb/getResumeItems）——观看进度依赖它；
- 新增 `findItemByTmdb()`（宿主详情页播放映射：标题搜索 + ProviderIds 比对；
  Emby 4.9 对 AnyProviderIdEquals 返回 500）；
- **ISO 直连端点**：`isoDirectStreamUrl` 改为 `/Items/{id}/Download?api_key=...`
  （Emby 对 ISO 的 `/Videos/{id}/stream` 挂起不响应；Download 端点实测 0.09s 返回 206）；
- 进度上报成功日志提级到 `AppLog.i`（`reportPlaybackProgress OK ... status=`）、
  `reportPlaybackStopped OK ...`（可观测性）。

## 8. 进度上报防护（player_screen.dart）

- `_reportProgress()`：上报位置 clamp 到片长 95% 以内（防 ISO 异常位置把内容误标「已看」）；
- `_cleanup()`：退出收尾的诊断日志（svc 类型 / 是否触发 Stopped），
  排查「继续观看不更新」时看这几行；
- 定时器幂等：使用 lanplayer 的 `utils/periodic_timer.dart`（`ensurePeriodicTimer`）——
  **这是 lanplayer 上游的修复，勿回退成无条件 `cancel + Timer.periodic`**
  （状态回调 ≈250ms 一次，会无限重置 30 秒倒计时）。

## 9. 宿主注入（host/player_host.dart）

`PlayerHostPage` 用 `ProviderScope(overrides: [currentMediaServerServiceProvider
.overrideWithValue(session.service)])` 包裹 `PlayerScreen`；`PlayerSession`/`PlaybackResolver`
为宿主门面。`LanPlayerKit.ensureInitialized()` 负责包内存储初始化（原 lanplayer `main()`
里的初始化搬到此处）。

## 9.5 媒体服务器「本机账号」（宿主侧，最关键的一条）

**问题本质（2026-09-27 三轮实证）**：Emby/Jellyfin **只对「用户登录令牌」建立的
播放会话写入观看进度**；用系统级 API 密钥时上报恒返回 204，但进度被服务端静默
丢弃（`UserData.PlaybackPositionTicks` 永不变化）。表现即"继续观看/详情页进度
永不同步"。

**宿主侧三层修复**（均在 MP 侧，不改包内逻辑）：

1. **配置入口**：设置 → 系统设置 → 媒体服务器 → 每台服务器的账号图标
   （`mediaserver_config_list_page.dart` 的 `_ServerAccountButton` / `_ServerAccountSheet`），
   账号存 SharedPreferences（键 `player_ms_account_<serverName>`）；
2. **服务实例统一**：`_serviceFor` 的缓存键**不得包含 apiKey**——登录会改写 apiKey，
   含它会分裂出第二个「未登录实例」，出现上报走登录实例、取流走旧密钥实例的
   诡异分叉（真机日志：两个 init 并存）；
3. **有账号时不传 API 密钥**：包内 `_ensureAuth()` 第一行是
   `if (apiKey.isNotEmpty) return true;` —— 只要 apiKey 非空就短路、**永不登录**。
   因此宿主在配置了账号时必须传空 apiKey，强制走 `loginByUsernamePassword`
   拿用户令牌。

**验收日志特征**：`init ... hasKey=false hasUser=true` → `尝试用户名密码登录` →
`用户名密码登录成功` → 流地址 `api_key=` 是用户令牌（非配置里的系统密钥）→
退出后服务端 `PlaybackCount`/`LastPlayedDate`/`PlaybackPositionTicks` 全部更新。

## 10. 未同步项（有意跳过）

- `danmaku_matcher.dart`、`http_client.dart` 的 lanplayer 独有改动（非播放核心依赖）；
- lanplayer 的 TV 端、首页/日历/订阅等应用级界面。
