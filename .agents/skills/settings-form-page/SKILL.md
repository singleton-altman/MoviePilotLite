---
name: settings-form-page
description: Implements settings-style form pages using SettingsFormManager, SettingsFieldConfig, and SettingsFormRowBuilder. Use when adding or refactoring a page backed by env key/value fields, system settings forms, directory-like single-object editors, or when the user asks to use the project’s shared form logic for a form UI.
---

# 表单结构页（Settings 表单管线）

在 moviepilot_mobile 中，面向「多字段 + 选择与保存」的页面优先使用统一的 **字段配置 + 表单管理器 + Row 构建器**，避免手写 `TextEditingController` / `Map` pending。

## 必读路径

| 职责 | 路径 |
|------|------|
| 字段声明 | `lib/modules/settings/models/settings_field_config.dart` |
| 枚举选项 | `lib/modules/settings/models/settings_enums.dart`（`settingsEnums`、`enumValueToLabel`） |
| 表单状态 | `lib/modules/settings/state/settings_field_state.dart` |
| 管理器 | `lib/modules/settings/state/settings_form_manager.dart` |
| UI 映射 | `lib/modules/settings/state/settings_form_row_builder.dart` |
| 行控件 | `lib/modules/settings/widgets/settings_field_row.dart` 及子 row |
| 页面根布局 | 见仓库根 `AGENTS.md`：`Scaffold` + `appBar` + `body` |

## 实现步骤（新页面）

### 1. 静态字段表

- 新建或复用 `List<SettingsFieldConfig>`（与 `envKey`、后端 `/api/v1/system/env` 或业务 PATCH 的 key 一致）。
- `select` 类字段设 `enumKey`，选项放在 `settingsEnums`。
- 条件显示：`conditionKey` + `conditionValue`（与 `form.shouldShow(field, readValue)` 配合）。
- 参考：`settings_basic_config.dart`、`settings_organize_config.dart`。

### 2. Controller（GetxController）

- `late final SettingsFormManager form = SettingsFormManager(fields: ...);`
- `final isEditing = true.obs;`（默认开启编辑态，保持 Rx）
- **加载成功**：`form.hydrateAll((k) => envData?.valueFor(k))`（或从其它模型 `read key`）；非「仅远程覆盖」场景可按需 `clearDirty()`。
- **保存**：`final patch = form.toPatch()`；空 map 则无需请求；成功后再 `form.clearDirty()`。
- **关闭**：`onClose` 里 `form.dispose()`。
- **编辑模式**（可选）：进入编辑前 `hydrateAll` + `clearDirty`；取消时再次 `hydrateAll` 自远程/快照恢复。
- 写接口须遵守 `AGENTS.md` 与 Swagger（如系统环境 `POST /api/v1/system/env` 等）。

### 3. Page UI

- 根组件：`Scaffold`，`appBar: AppBar(...)`（或项目约定的等价顶栏），主体在 `body`。
- `AppBar` 右侧按钮默认提供「保存」（调用 `controller.saveEdit()`）。
- 构建 `SettingsFormRowBuilder(form: controller.form, optionsOf: (k) => settingsEnums[k] ?? const [], onCopied: ..., optionLeadingOf: ...)`。
- 对每个 `SettingsFieldConfig`：`rowBuilder.buildRow(context, field, editMode: controller.isEditing.value, readValue: (k) => ...)`。
- `editMode` 为 `false` 时 Row 为只读（由 `SettingsFormRowBuilder` 与 `editable` 联动）。
- 页面内分区使用 `theme/section.dart` 的 `Section` + `widgets/section_header.dart` 的 `SectionHeader` 实现（与 `settings_basic_page.dart` 一致）。

### 4. 校验

- 改动后对该页与 controller 执行 `dart analyze`。

## 骨架屏（必需）- Skeletonizer

- 页面必须基于 `skeletonizer` 构建骨架屏（参考 `settings_basic_page.dart`）。
- **禁止全屏 loading**（不要用整页 `Center(CupertinoActivityIndicator())` 覆盖内容）。
- 骨架 item 使用**原始组件**的空/默认状态渲染（保持同一套 Row/Section 结构）。
- 若主体是 `ListView`/列表：骨架数据量固定 **5** 条（用占位数据驱动渲染），避免 0 条导致空白。
- 建议模式：
  - `Skeletonizer(enabled: controller.isLoading.value && controller.envData.value == null, child: <正常页面内容>)`
  - 真实数据到达后正常显示；骨架期间仍可滚动。

## 特殊场景

- **选项依赖**：对 `SettingsSelectFieldState` 使用 `ever`、或动态 `optionsOf`，参考 `DirectoryEditController` 的 media 联动。
- **非 env 数据源**：仍用同一套 `SettingsFormManager`，`hydrateAll` / `toPatch` 的 read/write 对应你的 Map 或模型字段即可（目录编辑即此类）。

## 参考实现

- 系统 env + 保存：`SettingsBasicController` / `SettingsAdvancedDetailController`、`SettingsOrganizeScrapeController`。
- 分区 + 保存按钮：`settings_basic_page.dart`、`settings_advanced_detail_page.dart`。
- 条件区块 + 自定义选项 lead：`DirectoryEditPage` + `settings_option_visuals.dart`。
