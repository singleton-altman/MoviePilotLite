# MoviePilot Mobile

基于 [MoviePilot](https://github.com/jxxghp/MoviePilot) 项目的 Flutter 移动端客户端。

## 社区与贡献

- 📱 **Telegram 群聊**：[小白裙](https://t.me/+MLbOpDDD1mdlOTM1)，欢迎加入交流
- 🔀 欢迎提交 **Pull Request** 参与贡献
- 🐛 遇到问题请在 [Issues](https://github.com/AltmanTech/MoviePilotLite/issues) 提交反馈

## 技术栈

- **框架**: Flutter
- **网络请求**: Dio
- **状态管理**: GetX
- **路由管理**: GetX
- **UI风格**: iOS (Cupertino)
- **数据解析**: Freezed
- **本地数据库**: Realm

## 功能特性

- ✅ 登录功能（支持多用户管理）
- ✅ 服务器地址、账号、密码本地存储
- ✅ 历史账号选择与自动填充
- ✅ 登录响应数据持久化
- ✅ Dashboard 仪表盘（存储空间、媒体统计、实时速率、后台任务、最新入库）

## 发布打包

### Fastlane 本地打包

```bash
# 仅打包 Android APK
fastlane android

# 仅打包 iOS IPA
fastlane ios

# 同时打包 iOS + Android
fastlane build_all
```

Android Release 打包需要预先设置环境变量：`ANDROID_KEYSTORE_PATH`、`KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD`。

### 生成 Android Release Keystore

首次打包前需生成 keystore（仅执行一次）：

```bash
keytool -genkey -v -keystore moviepilot-release.keystore \
  -alias moviepilot -keyalg RSA -keysize 2048 -validity 10000
```

将 keystore 转为 Base64 存入 GitHub Secrets：

```bash
openssl base64 -A -in moviepilot-release.keystore | tr -d '\n' | pbcopy
```

### GitHub Actions 自动打包

- **触发器**：每周五 UTC 00:00 自动执行，或通过 Actions 页面手动触发
- **产物**：在 GitHub Release 中上传 APK 和未签名的 iOS 应用
- **Release 命名**：`yyyy-MM-dd-HH-mm-{version}`（如 `2025-02-14-09-30-1.0.0`）

需在仓库 Settings → Secrets and variables → Actions 中配置：

**变量（Variables）**：启用 iOS 打包时，新建变量 `BUILD_IOS` 并设为 `true`。不设置则仅打包 Android。

**Secrets**：

| Secret | 说明 |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | Base64 编码的 keystore 文件内容 |
| `KEYSTORE_PASSWORD` | keystore 密码 |
| `KEY_ALIAS` | 密钥别名（如 `moviepilot`） |
| `KEY_PASSWORD` | 密钥密码 |

未设置变量 `BUILD_IOS=true` 时，将仅打包 Android APK。

**iOS 打包说明**：
- 采用未签名模式打包，无需 iOS 开发者证书和 Provisioning Profile
- 生成的是 `.app.zip` 文件，需要通过 Xcode 或其他工具安装到设备
- 由于是未签名应用，需要在设备上信任开发者才能运行

## 插件适配进度

| 插件 | ID | 图标 | Auth | 作者 | 状态 |
|------|-----|------|------|------|------|
| 站点自动签到 | `AutoSignIn` | `signin.png` | 2 | [thsrite](https://github.com/thsrite) | ✅ 已完成 |
| 站点数据统计 | `SiteStatistic` | `statistic.png` | 2 | [lightolly](https://github.com/lightolly) | ✅ 已完成 |
| 勋章墙 | `MedalWall` | [Medal.png](https://raw.githubusercontent.com/KoWming/MoviePilot-Plugins/main/icons/Medal.png) | 2 | [KoWming](https://github.com/KoWming) | ✅ 已完成 |
| 后宫管理系统 | `nexusinvitee` | [nexusinvitee.png](https://raw.githubusercontent.com/madrays/MoviePilot-Plugins/main/icons/nexusinvitee.png) | 2 | [madrays](https://github.com/madrays) | ✅ 已完成 |
| 垃圾文件清理 | `TrashClean` | [clean1.png](https://raw.githubusercontent.com/madrays/MoviePilot-Plugins/main/icons/clean1.png) | 1 | [madrays](https://github.com/madrays) | ✅ 已完成 |
| P115StrmHelper | `P115StrmHelper` | - | - | [DDSRem](https://github.com/DDSRem) | 🔄 适配中 (预计 1.0.2) |
| ProxmoxVEBackup | `ProxmoxVEBackup` | - | - | [xijin285](https://github.com/xijin285) | 基础适配 |
| 随机图床状态 | `RandomPic` | - | - | [xijin285](https://github.com/xijin285) | 🔄 适配中 (预计 1.0.2) |

## 未来路线

### 已完成
- ✅ 登录、多用户管理、动态壁纸
- ✅ Dashboard 仪表盘、后台任务列表
- ✅ Profile、系统消息、Server Log
- ✅ 搜索、媒体详情、推荐分类
- ✅ 订阅（TV/Movie、热门、分享、分享统计、订阅日历、编辑）
- ✅ 下载器、下载器配置
- ✅ 媒体服务器配置
- ✅ 存储、目录、整理刮削
- ✅ 设置（基础/搜索/高级）
- ✅ 规则（自定义/优先级/下载）
- ✅ 用户管理
- ✅ 站点、站点同步、站点选项
- ✅ 插件、动态表单
- ✅ GitHub Actions 打包（Android）
- ✅ Xcode Cloud 打包并上传 GitHub Release（iOS）

### 待完成
- ⏳ Dashboard 编辑
- ⏳ Profile 编辑
- ⏳ 系统消息 Stream

## 许可证

本项目采用 **Business Source License 1.1 (BSL-1.1)** 许可证。

**重要说明**:
- 本许可证允许查看和修改源代码
- 在特定条件下，生产环境使用可能受到限制
- 许可证将在 **2029-01-21** 自动转换为 **GPL-3.0** 许可证

详细信息请参阅 [LICENSE](LICENSE) 文件。

## 免责声明

- 本软件仅供学习交流使用，任何人不得将本软件用于商业用途
- 任何人不得将本软件用于违法犯罪活动
- 软件对用户行为不知情，一切责任由使用者承担
