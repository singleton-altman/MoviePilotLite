# MoviePilot Mobile

基于 [MoviePilot](https://github.com/jxxghp/MoviePilot) 的 Flutter 跨端客户端，对接 MoviePilot v2 API，在手机上完成订阅、搜索、下载、整理与系统运维等常用操作。

**当前版本**：1.1.8 · **API 文档**：[api.movie-pilot.org](https://api.movie-pilot.org)

---

## 平台支持

| 平台 | 说明 |
|------|------|
| Android | 正式支持；设置页可检查 Release 并热更新 APK |
| iOS | 正式支持；TestFlight / 自签；订阅日历 Widget |
| macOS | 桌面端构建 |
| Web | 功能预览（非主维护目标）→ [在线体验](https://web-brown-kappa-21.vercel.app) |
| HarmonyOS | 独立分支 `ohos`，HAP 需自签证书安装 |

---

## 快速开始（开发）

### 环境

- Flutter 3.38+ / Dart 3.8+
- Android SDK / Xcode（按目标平台准备）
- 可连接的 MoviePilot 服务端

### 常用命令

```bash
flutter pub get
flutter analyze
flutter test
flutter run

# 代码生成（Freezed / JSON / Hive 等）
dart run build_runner build --delete-conflicting-outputs

# 构建
flutter build apk --release --dart-define=FLUTTER_APP_ENV=release
flutter build ios
flutter build macos
```

### 依赖说明

- `altman_downloader_control` 为 Git 依赖，CI 会在 `flutter pub get` 前执行 `flutter pub upgrade altman_downloader_control`，避免 lockfile 中的旧 commit。
- 本地若需同步该库最新代码，可手动执行上述 upgrade 后再 `flutter pub get`。
- 已提交的 `form_block_models.freezed.dart` 存在已知生成问题，**勿随意全量 regenerate**，除非已修复源模型。

---

## App 推送

推送依赖 [MoviePilot-Plugins](https://github.com/singleton-altman/MoviePilot-Plugins) 中的 **APPLitePush** 插件，由作者提供转发服务，**无需自建推送平台**。

### 使用前准备

1. 前往 [http://106.14.89.6/apply](http://106.14.89.6/apply) 申请 **App Push Token**
2. 加入 [Telegram 群](https://t.me/+MLbOpDDD1mdlOTM1)，申请完成后 **@ 管理员** 确认
3. 在 MoviePilot 中安装 **APPLitePush** 插件
4. 在系统 / App 设置中 **开启推送通知权限**

### iOS（TestFlight / 自签）

- 安装包 **Bundle ID 必须为 `com.altman.moviepilot`**，否则无法完成推送绑定
- TestFlight 与自签用户使用同一套配置流程，均走作者转发服务，无需自行部署 JPush / APNs 转发

**插件绑定步骤：**

1. 在插件配置中填写 **Push Key**（Telegram 群获取）与 **App Push Token**（步骤 1 申请）
2. 点击 **保存**
3. 点击 **应用**（App 内完成 alias 绑定）
4. 点击 **发送测试消息** — 正常情况下应收到一条推送

> 建议使用 **Release** 包安装；Debug 包可能无法正常收到推送。

### Android

流程与 iOS 相同：申请 Token → Telegram @ 管理员 → 安装插件 → 按上述步骤填写 Push Key / App Push Token → 保存 → 应用 → 发送测试。当前未配置厂商通道，到达率不保证。

### 限制与说明

- 推送走作者阿里云转发服务器，**单 IP 每分钟最多 10 条**
- 服务可能因成本原因调整；TestFlight 名额有限
- 收不到推送时请先确认：通知权限已开、Bundle ID 正确、已点击「应用」且测试消息已发送

---

## 社区与贡献

- **Telegram**：[小白裙](https://t.me/+MLbOpDDD1mdlOTM1)
- **Issue**：[AltmanTech/MoviePilotLite](https://github.com/AltmanTech/MoviePilotLite/issues)
- **Release**：[singleton-altman/MoviePilotLite](https://github.com/singleton-altman/MoviePilotLite/releases)
- **更新日志**：[CHANGELOG.md](CHANGELOG.md)
- 欢迎 Pull Request

---

## 技术栈

| 类别 | 选型 |
|------|------|
| 框架 | Flutter |
| 状态 / 路由 | GetX |
| 网络 | Dio + Cookie 管理 |
| 本地存储 | Hive CE；SharedPreferences |
| 模型 | Freezed + json_serializable |
| UI | Material 3 + Cupertino 组件混用 |
| 日志 | Talker / Talker Dio |
| 图表 | Syncfusion Charts |
| 推送 | JPush（iOS/Android） |

---

## 许可证

本项目采用 **Business Source License 1.1 (BSL-1.1)**。

- 允许查看与修改源代码
- 生产环境使用在特定条件下可能受限
- **2029-01-21** 起自动转为 **GPL-3.0**

详见 [LICENSE](LICENSE)。

---

## 免责声明

- 本软件仅供学习交流，不得用于商业用途或违法犯罪活动
- 软件对用户行为不知情，一切责任由使用者自行承担

---

## 赞赏

若本项目对你有帮助，欢迎赞赏以支持持续维护。

![赞赏码](donate.JPG)
