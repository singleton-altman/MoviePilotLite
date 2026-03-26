# Changelog

## 2026-03-22
- 修复 bug
- 下载管理能力升级：支持 qBittorrent（qB）与 Transmission（TR）种子管理。
- 统一种子列表展示与基础操作（暂停、恢复、删除、重命名、分类/标签、限速）。
- 下载器页面结构调整，增强不同下载器类型下的兼容性。

## 2026-03-23

- 新增下载任务页面 `torrent_download_screen`，补全 qBittorrent/Transmission 提交逻辑与错误提示。
- 下载管理页支持筛选与排序条件本地持久化恢复，减少页面状态回退。
- 优化种子列表项视觉层级与间距，降低信息拥挤感。
- 调整下载管理入口路由逻辑，支持按设置切换到下载器配置页。
- 修复媒体详情页骨架加载与 `soft_edge_blur` 组合导致的断言问题。
- 移除种子管理本地 Realm 缓存逻辑，回归在线数据流。
- fix: douban media detail subscribe state error
- 新增独立 `altman_totp` package，支持 TOTP 新增、编辑、删除、选择回填登录 OTP。
- TOTP 本地存储改为 `sqflite`，支持多条记录与 UUID 主键。
- 新增 TOTP 扫码录入与手动密钥录入，支持解析 `otpauth://` 并自动回填用户名。
- 登录页 OTP 选择改为 modal 方式拉起 TOTP 选择页。
- TOTP 管理页与编辑页增加验证码倒计时与逆向进度显示。
- TOTP 管理页支持单项导出，提供二维码与字符串（含 `name`、`key`）复制。
- 增加 iOS/Android 相机权限配置以支持二维码扫描。
- tv 类型订阅完成后支持二次编辑

## 2026-03-26
- 订阅页/搜索结果页的搜索与筛选入口统一为 `centerDocked` 悬浮条（fake input + filter + sort）。
- 更新 floating bar skill：补充浅色边框规范。
