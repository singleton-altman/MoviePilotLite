# MoviePilot Mobile

基于 [MoviePilot](https://github.com/jxxghp/MoviePilot) 项目的 Flutter 移动端客户端。

## 功能预览（Web）

在线体验：[https://web-brown-kappa-21.vercel.app](https://web-brown-kappa-21.vercel.app)

## HarmonyOS（OHOS）

- OHOS 适配在独立分支 `ohos`
- HAP 需要使用自己的证书进行自签后安装

## 社区与贡献

- 📱 **Telegram 群聊**：[小白裙](https://t.me/+MLbOpDDD1mdlOTM1)，欢迎加入交流
- 🔀 欢迎提交 **Pull Request** 参与贡献
- 🐛 遇到问题请在 [Issues](https://github.com/AltmanTech/MoviePilotLite/issues) 提交反馈
- 🚀 版本发布直达：[Releases](https://github.com/singleton-altman/MoviePilotLite/releases)
- 📝 版本更新记录见 [CHANGELOG](CHANGELOG.md)

## App 推送使用说明

### iOS 用户

#### TestFlight 用户

1. 先前往 [http://106.14.89.6/apply](http://106.14.89.6/apply) 申请推送 Token。
2. 申请完成后，请先进入 Telegram 群并 @ 我一下，方便确认与后续处理。
3. 安装 [MoviePilot-Plugins](https://github.com/singleton-altman/MoviePilot-Plugins) 插件库中的 `APPLitePush` 插件。
4. 在插件配置中填写 Push Token 与 Push API Key：
   - Push Token：通过步骤 1 获取
   - Push API Key：需要到 Telegram 群获取
5. 打开 App，找到该插件，并点击“应用”完成一次 Token 绑定。

#### 非 TestFlight 用户

非 TestFlight 用户可自行搭建推送链路，流程如下：

1. 准备可信的苹果开发者账号，注册 App ID，并为 App 配置推送权限与证书。
2. 在 JPush 注册对应应用。
3. 修改 App 内的 JPush 相关配置后，重新打包 App。
4. 部署推送转发仓库 [moviepilot_apns](https://github.com/singleton-altman/moviepilot_apns)，并配置自己的 JPush App ID 与 Security。
5. Fork [MoviePilot-Plugins](https://github.com/singleton-altman/MoviePilot-Plugins) 插件仓库，将推送服务转发 IP 修改为自己的服务器地址。
6. 按照自己的 Push Key 与 Push Token 配置插件，然后回到 App 内点击“应用”完成绑定。

需要注意的是，App 必须使用 release 方式打包安装，否则可能无法收到推送。

### Android 用户

Android 用户可参考 iOS TestFlight 用户的使用步骤：

1. 申请推送 Token。
2. 申请完成后，请先进入 Telegram 群并 @ 我一下，方便确认与后续处理。
3. 安装 `APPLitePush` 插件。
4. 配置插件中的 Push Token 与 Push API Key。
5. 打开 App，在插件内点击“应用”完成绑定。

需要注意的是，Android 版本目前没有配置渠道 Key 等信息，推送通达率没有任何保证。如果有可以提供相关信息的用户，欢迎通过 Telegram 联系我，感谢支持。

### 使用限制与说明

- App 推送依赖我的转发服务器。
- 非常欢迎有能力、有条件的热心用户自行搭建转发服务器，帮助分担现有服务压力，也让整体推送能力更稳定。
- 当前服务器为阿里云建站服务器，存在限流：每分钟每个 IP 最多可发送 10 条消息。
- 由于资费原因，后续存在主动废弃该服务的可能性。
- 当前 TestFlight 使用的是私人账号，只有极少数用户可用，暂时无法提供给其他用户使用，感谢理解。

## 技术栈

- **框架**: Flutter
- **网络请求**: Dio
- **状态管理**: GetX
- **路由管理**: GetX
- **UI风格**: iOS (Cupertino)
- **数据解析**: Freezed
- **本地数据库**: Realm

## 开发与 CI 说明

- `altman_downloader_control` 通过 Git 依赖引入，默认跟随仓库远端最新提交。
- 为避免 GitHub Actions 继续使用 `pubspec.lock` 中旧的 `resolved-ref`，CI 在执行 `flutter pub get` 前会先执行 `flutter pub upgrade altman_downloader_control`。
- 如果你本地也需要同步该依赖的最新源码，可以手动执行同样的命令后再运行 `flutter pub get`。

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

## 赞赏

如果这个项目对你有帮助，欢迎赞赏支持持续维护。

![赞赏码](donate.JPG)
