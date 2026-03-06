---
name: plugin-adapter-generation
description: Generates MoviePilot mobile plugin form adapters (vue mode). Use when adding a new plugin adapter, creating a controller for a plugin (e.g. P115StrmHelper, ProxmoxVEBackup), or when the user asks to generate or scaffold plugin adapter code.
---

# 插件适配器生成

在 moviepilot_mobile 中为「vue 模式」插件生成适配器：Controller + Converter，并完成注册。服务端需在 `plugin/page/{id}` 或 `plugin/form/{id}` 的响应中返回 `render_mode: "vue"`，前端再按 pluginId 注入对应适配器。

## 何时使用

- 用户要求「新增/创建一个插件适配器」「为 xxx 插件写 adapter」
- 用户提供插件的 HTTP 接口与返回值，要求对接展示页/配置页
- 用户要求「按 P115 / Proxmox 的方式接一个新插件」

## 涉及文件与顺序

| 步骤 | 文件 | 说明 |
|------|------|------|
| 1 | `lib/modules/dynamic_form/adapters/<plugin_snake>_form_controller.dart` | 实现 `PluginFormAdapter` |
| 2 | `lib/modules/dynamic_form/services/<plugin_snake>_converter.dart` | 可选；将 API 数据转为 FormBlock / formModel |
| 3 | `lib/main.dart` | 调用 `PluginFormAdapterRegistry.register(pluginId, factory)` |

插件 ID 使用 PascalCase（如 `P115StrmHelper`），文件名使用 snake_case（如 `p115_strm_helper_form_controller.dart`）。

## 1. Controller 模板

- 实现 `PluginFormAdapter`（或 `PluginFormAdapterWithClean`，仅 TrashClean 用）。
- 依赖：`Get.find<ApiClient>()`、`Get.find<AppService>()`、`Get.find<AppLog>()`；鉴权用 `_getToken()`（与现有 adapter 一致）。
- 常量：`static const _basePath = '/api/v1/plugin/<PluginId>';`
- 必填：`pluginId`、`blocks`、`pageNodes`、`formModel`、`isLoading`、`errorText`、`load()`、`save()`。
- 可选重写：`supportsSave`（默认 false）、`supportsFormEntry`（默认 true）、`actionList`、`onAppBarAction(type)`、`actionLoading`。

**load() 分支**：

- **Page 模式**（`!formMode`）：请求展示用接口（可 `Future.wait` 多个），解析后调用 converter 的 `convertPage(...)`，将返回的 `List<FormBlock>` 赋给 `blocks`，并 `formModel.value = {}`。
- **Form 模式**（`formMode`）：请求配置接口（如 `get_config`），解析后调用 converter 的 `convertForm(config: ...)`，将返回的 `(blocks, formModel)` 分别赋给 `blocks` 和 `formModel`。

**save()**：若 `supportsSave` 为 true，用 `formModel.value` 通过 converter 的 `toConfigBody` 得到 body，`PUT _basePath` 或接口约定路径；否则直接 `return false`。

**错误与空数据**：请求失败或解析失败时设置 `errorText.value`，并清空 `blocks` / `formModel`；不在日志中打印敏感字段。

## 2. Converter 约定（可选但推荐）

- 类名：`<PluginId>Converter`（如 `P115StrmHelperConverter`）。
- **convertPage**：入参为展示接口的原始数据（如 `status`、`userStorage` 等），返回 `List<FormBlock>`。用 `FormBlock.infoCard`、`FormBlock.alert` 等组装只读展示。
- **convertForm**：入参为配置接口返回的 config（Map），返回 `(List<FormBlock>, Map<String, dynamic> formModel)`。用 `FormBlock.pageHeader`、`FormBlock.switchField`、`FormBlock.textArea`、`FormBlock.cronField` 等，且 `formModel` 的 key 与 block 的 `name` 一致。
- **toConfigBody**：入参 `formModel`，返回要 PUT 的 `Map<String, dynamic>`（可做字段名/类型转换）。

FormBlock 类型见 `lib/modules/dynamic_form/models/form_block_models.dart`（如 `infoCard`、`switchField`、`textArea`、`cronField`、`pageHeader`、`alert`）。

## 3. 注册

在 `lib/main.dart` 的 `main()` 中、`runApp` 之前添加：

```dart
import 'package:moviepilot_mobile/modules/dynamic_form/adapters/<plugin_snake>_form_controller.dart';

// 与其它 register 并列
PluginFormAdapterRegistry.register(
  '<PluginId>',
  ({required formMode}) => <PluginId>FormController(formMode: formMode),
);
```

不要修改 `DynamicFormController` 或 `DynamicFormPage` 的插件分支逻辑；仅通过 Registry 注册即可。

## 4. 可选能力

- **不显示保存按钮**：Controller 中 `bool get supportsSave => false`。
- **不显示右下角编辑入口**：Controller 中 `bool get supportsFormEntry => false`。
- **AppBar 操作菜单**：重写 `List<AppBarActionItem> get actionList` 返回项，并实现 `Future<void> onAppBarAction(String type)` 处理点击。`AppBarActionItem(type:, label:, iconName:, iconColor:)` 定义在 `plugin_form_adapter.dart`。
- **自定义渲染**：若需整页自定义 UI（如 Proxmox），在 `PluginFormAdapterRegistry.registerRenderer(pluginId, builder)` 注册，并在 `dynamic_form_page` 中通过 `getCustomRenderer(pluginId)` 分支渲染；一般插件不必实现。

## 5. 参考实现

- 只读展示 + 只读配置（无保存、无编辑入口）：`P115StrmHelperFormController` + `P115StrmHelperConverter`。
- 展示 + 可保存配置 + 定时刷新：`ProxmoxVEBackupFormController` + `ProxmoxVEBackupConverter`。
- 展示 + 保存 + 立即清理：`TrashCleanFormController`（实现 `PluginFormAdapterWithClean`）+ `TrashCleanConverter`。

API 路径、请求方法、请求体与响应格式以服务端 Swagger/文档为准（项目约定：https://api.movie-pilot.org）。
