# Dynamic Form Architecture

## Module layout
- `lib/modules/dynamic_form/pages/dynamic_form_page.dart`: single `DynamicFormPage` widget that renders a list of `FormBlock` items or, when available, the raw Vuetify `FormNode` tree via `VuetifyPageRenderer`. The `controllerTag` matches one of the bindings defined in `lib/main.dart`.
- `controllers/dynamic_form_controller.dart`: owns `apiPath`, optional `apiSavePath`, `formMode`, `pageNodes`, `blocks`, and the helpers for `load`, `save`, `triggerClean`, and `fetchCleanProgress`. It uses the shared `ApiClient`, `AppService`, and `AppLog`.
- `models/`: `dynamic_form_models.dart` defines `DynamicFormResponse` and the recursive `FormNode` used by the Vuetify renderer. `form_block_models.dart` defines the sealed `FormBlock` variants that `DynamicFormPage` renders.
- `services/form_block_converter.dart`: turns API responses into `FormBlock` lists (page vs. config) plus the `model` map for `formMode`. `services/trash_clean_converter.dart` shows how to map plugin-specific status/clean APIs into `FormBlock` details and `formModel` defaults.
- `widgets/`: a widget per block variant plus `vuetify_renderer.dart` for rendering `FormNode` trees, and `utils/vuetify_*` utilities for aligning colors/icons.

## Routing & bindings
- `lib/main.dart` registers two `GetPage` routes for the dynamic form flow: `/plugin/dynamic-form/page` and `/plugin/dynamic-form/form`. Each binding lazy-loads a `DynamicFormController` (tagged `page` or `form`), calls `init(...)` with `/api/v1/plugin/page/<id>` or `/api/v1/plugin/form/<id>`, passes the optional `title`/`pluginId`, and sets `apiSavePath` for the form route.
- `DynamicFormPage` resolves the controller via `Get.find` with `controllerTag` (or derives it from the current route) so the same widget can render either mode.

## Data flow
- `load()` obtains the token, GETs the configured `apiPath`, parses the response into `DynamicFormResponse`, keeps the original `page` tree for `VuetifyPageRenderer`, and converts the payload into `FormBlock` and `formModel` via `FormBlockConverter`.
- `save()` is gated by `formModel` being non-empty, uses `apiSavePath`, and sets `saveSuccess`/`errorText` based on the PUT result. `TrashClean` overrides the endpoint and body through `TrashCleanConverter.toConfigBody`.
- `formMode`: the controller sets `formMode.value = true` when the route is `/plugin/dynamic-form/form` or `pluginId` matches `formModePlugins`. That is why the Save button and editable widgets only appear for `formMode` plugins.

## Rendering
- `_toDisplayItems` groups consecutive `StatCardBlock`s into `_DisplayStatCardGrid`, while every other block is rendered individually via `_buildBlock`.
- `_buildBlock` dispatches each variant to its corresponding widget (see references/block-types.md). Add new widgets by extending this `switch` and inserting the widget when the block type changes.
- The AppBar adds a Save button when `controller.hasFormModel` and provides a FAB that pushes `/plugin/dynamic-form/form` to edit the same plugin. `TrashClean`-specific UI (clean button, progress sheet) lives inside `DynamicFormPage` and `_CleanProgressSheet`.
- When `pageNodes` contains Vuetify nodes and `formMode` is false, `VuetifyPageRenderer` shows the recursive `_VuetifyNode` tree that understands `VCard`, `VRow`, `VSelect`, etc. Extend that renderer when the backend introduces a new `component` you need to mock.

## Conversion helpers
- `FormBlockConverter` handles both `conf` (form-mode definition) and `page` (dashboard view) payloads. `_collectConfNodes` looks for `VSwitch`, `VTextField`, `VTextarea`, `cron*`, `VAlert`, and `VSelect`; `_collectFormFields` repeats that logic for `page` nodes. When the backend emits a new field type, update both collectors and the `FormBlock` sealed class.
- `vuetify_mappings.dart` maps Vuetify icons/colors to Flutter equivalents, and `vuetify_css.dart` parses margin/padding classes for the renderer.

## Special cases
- `TrashCleanConverter` demonstrates how to turn multiple APIs (status/clean_result/clean_progress/stats/downloaders) into a read-only dashboard plus a form. It also shows how to build complex `InfoCardBlock`s with metadata rows, chip lines, and action hints.
- `formModePlugins` contains plugin IDs that should default to `formMode` (AutoSignIn, TrashClean, MonitorPaths, SiteStatistic, MedalWall, nexusinvitee). Add a new ID there when its configuration screen also needs field editing.

Refer to references/block-types.md for the block/widget mapping and extension guidance.
