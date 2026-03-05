---
name: dynamic-form-page
description: Guides how to adapt `lib/modules/dynamic_form` so plugin dashboards or configuration forms render correctly. Use when a request involves `/plugin/dynamic-form`, `DynamicFormPage`, new block types, converter tweaks, or controller bindings for a plugin.
---

# Dynamic Form Page Skill

## Intent
- Target tasks that mention `DynamicFormPage`, `/plugin/dynamic-form` routes, or the dynamic form module when a plugin dashboard or configuration form needs adjustment.
- Follow this skill when an ask involves wiring a new plugin into `/plugin/dynamic-form`, creating/editing block types, updating converters for new API payloads, or improving the Vuetify renderer.

## Routing and bindings
- `lib/main.dart` registers `/plugin/dynamic-form/page` (tag `page`) and `/plugin/dynamic-form/form` (tag `form`). Each binding lazy-instantiates `DynamicFormController`, calls `init` with `/api/v1/plugin/page/<id>` or `/api/v1/plugin/form/<id>`, forwards the optional `title`, and sets `apiSavePath = /api/v1/plugin/<id>` for the form route.
- Always pass `controllerTag` into `DynamicFormPage` (or rely on `Get.currentRoute` as the widget currently does) so it finds the correct controller for your route variant.

## Controller and data flow
- `DynamicFormController` owns `apiPath`, `apiSavePath`, `formMode`, `pageNodes`, `blocks`, and `formModel`. `load()` GETs `apiPath`, parses `DynamicFormResponse`, keeps the raw `page` tree for `VuetifyPageRenderer`, and hands `conf`/`model` payloads to `FormBlockConverter`.
- `formModel` stores field values keyed by `props.model`/`name`. `hasFormModel` unlocks the AppBar Save button and the editable widgets in `_buildBlock`. `save()` returns early when nothing is editable, PUTs to `apiSavePath` (or POSTs via `_saveTrashClean`), and updates `saveSuccess`/`errorText`.
- `formModePlugins` lists IDs such as `AutoSignIn`, `TrashClean`, `MonitorPaths`, `SiteStatistic`, `MedalWall`, and `nexusinvitee` that should default to form mode even when routed through `/page`. Add new IDs there when a plugin needs editing instead of read-only streaming. Use `TrashCleanConverter` as the example of combining multiple backend endpoints with both form and dashboard blocks.

## Rendering decisions
- `_toDisplayItems` groups sequential `StatCardBlock`s into `_DisplayStatCardGrid` so stat dashboards stay in 2×2 grids, while other blocks pass through `_buildBlock`.
- `_buildBlock` dispatches on `FormBlock` variants to the widgets under `widgets/`. Update `_buildBlock` (and `_toDisplayItems` if needed) whenever you add a variant.
- When `pageNodes` is populated and `formMode` is false, `DynamicFormPage` renders the recursive `VuetifyPageRenderer`, which already understands `VCard`, `VRow`, `VTextField`, `VSelect`, `VSwitch`, `VTable`, etc. Extend `_VuetifyNode` when the backend introduces a new component.
- The FAB transitions to `/plugin/dynamic-form/form` for the current plugin so users can switch into edit mode. `_CleanProgressSheet` accompanies the TrashClean pipeline by calling `controller.triggerClean()` and `fetchCleanProgress()`.

## Extending the dynamic form page
- Add new block variants to `FormBlock` (models/form_block_models.dart), create a matching widget under `widgets/`, and render it in `_buildBlock`. Feed the backend values through `formModel` so `controller.updateField` can save them.
- Teach `FormBlockConverter` to emit the block via `_collectConfNodes` (configuration payloads) or `_collectFormFields` (page payloads). Use `_extractSwitch`, `_extractTextField`, `_extractCron`, etc., as templates for reading labels, hints, and values.
- If the backend only returns Vuetify nodes, update `widgets/vuetify_renderer.dart` to handle the new `component`/`props`. Reuse `vuetify_css.dart` for spacing and `vuetify_mappings.dart` for colors/icons.
- Always verify that `apiSavePath` points at the endpoint the backend expects and that the names you derive from `props.model`/`props.name` match what the server reads.

## References
- `references/architecture.md` — module layout, routing, controller lifecycle, and the TrashClean example.
- `references/block-types.md` — the current block/widget map, converter notes, and an extension checklist.
