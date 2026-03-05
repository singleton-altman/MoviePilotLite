# Form Blocks and Widgets

| Block variant | Role | Widget file | Notes |
| --- | --- | --- | --- |
| `statCard` | Dashboard stat block (title + value + optional icon). | `widgets/stat_card_widget.dart` | Used in consecutive grids; `_toDisplayItems` groups a run of them. |
| `chart` | Pie/line chart pulled from `page` nodes. | `widgets/chart_widget.dart` | Accepts labels/series and respects `chartType`. |
| `table` | Simple table with headers + rows. | `widgets/table_widget.dart` | Wraps Flutter table layout. |
| `switchField` | Toggle for boolean config. | `widgets/switch_field_widget.dart` | Binds to `controller.getBoolValue` and `updateField`. |
| `cronField` | CRON expression editor. | `widgets/cron_field_widget.dart` | Defaults hint to `0 0 * * *`. |
| `textField` | Single-line text input. | `widgets/text_field_widget.dart` | Mirrors `VTextField` placeholder/hint. |
| `textArea` | Multi-line text input. | `widgets/text_area_widget.dart` | Respects `rows` (2–10). |
| `selectField` | Dropdown (single or multi select). | `widgets/select_field_widget.dart` | Uses `SelectOption` list; `multiple` flag controls chips. |
| `pageHeader` | Section header (title + optional subtitle). | `widgets/page_header_widget.dart` | Observes `DynamicFormController`. |
| `expansionCard` | Expandable panel list (title + items + chips). | `widgets/expansion_card_widget.dart` | Each `ExpansionItem` can include `MedalCardData`. |
| `alert` | Inline information banner. | `widgets/alert_widget.dart` | Type controls color. |
| `siteInfoCard` | Rich card tailored for site summary. | `widgets/site_info_card_widget.dart` | Renders stat lines, alerts, and purchase hints. |
| `infoCard` | Cupertino list-style info card. | `widgets/info_card_widget.dart` | Supports rows with icons, chip, value. |

## Extension checklist

1. **Models**: Add the new variant to `lib/modules/dynamic_form/models/form_block_models.dart` (sealed class + any helper data classes).  
2. **Widget**: Create a widget under `widgets/`, expose the expected props, and handle `controller` bindings if it writes to `formModel`.  
3. **Renderer**: Update `_buildBlock` in `DynamicFormPage` and any grouping logic (e.g., `_buildStatCardGrid`) to include your variant. Place shared layout helpers (padding, spacing) nearby so they stay consistent.  
4. **Conversion**: Teach `FormBlockConverter` to return the new block. For API fields, extend `_collectConfNodes` (form mode) and/or `_collectFormFields` (page mode). Use `_valueFromModel`/`_extract*` helpers to populate `FormBlock` data.  
5. **Vuetify fallback**: If the backend sends the block as part of the Vuetify node tree instead of `conf`, add handling to `_VuetifyNode` in `utils/vuetify_renderer.dart`. Map any new `component` or `props` to Flutter equivalents, referencing `vuetify_css.dart` and `vuetify_mappings.dart` for color/icon helpers.  
6. **Save path**: If the block modifies writable state, ensure `DynamicFormController.apiSavePath` is set (see `/plugin/dynamic-form/form` binding) and that `name`/`model` keys align with the backend payload.

## FormBlockConverter details

- `_collectConfNodes` is invoked when `response.conf` exists (configuration screens). It looks for `VSwitch`, `VTextField`, `VTextarea`, `cron` components, `VAlert`, and `VSelect`.  
- `_collectFormFields` walks `response.page` to surface the same editable widgets even when the server only returns `page`.  
- `_extract*` helpers (`_extractSwitch`, `_extractCron`, etc.) pull labels, model keys, hints, and values using `props['model']`, `props['name']`, and the optional `model` map. They default to empty strings so widgets render sensibly even when props are missing.  
- Use `VuetifyMappings` to translate colors/icons when converting dashboards (`statCard`, `siteInfoCard`, etc.).
