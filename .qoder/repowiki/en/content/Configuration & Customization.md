# Configuration & Customization

<cite>
**Referenced Files in This Document**
- [main.dart](file://lib/main.dart)
- [pubspec.yaml](file://pubspec.yaml)
- [l10n.yaml](file://l10n.yaml)
- [app_en.arb](file://lib/l10n/app_en.arb)
- [app_zh.arb](file://lib/l10n/app_zh.arb)
- [app_localizations.dart](file://lib/l10n/app_localizations.dart)
- [app_theme.dart](file://lib/theme/app_theme.dart)
- [environment.toml](file://.codex/environments/environment.toml)
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)
- [settings_advanced_config.dart](file://lib/modules/settings/models/settings_advanced_config.dart)
- [settings_basic_config.dart](file://lib/modules/settings/models/settings_basic_config.dart)
- [settings_organize_config.dart](file://lib/modules/settings/models/settings_organize_config.dart)
- [settings_search_download_config.dart](file://lib/modules/settings/models/settings_search_download_config.dart)
- [settings_site_options_config.dart](file://lib/modules/settings/models/settings_site_options_config.dart)
- [settings_site_sync_config.dart](file://lib/modules/settings/models/settings_site_sync_config.dart)
- [settings_controller.dart](file://lib/modules/settings/controllers/settings_controller.dart)
- [settings_advanced_list_controller.dart](file://lib/modules/settings/controllers/settings_advanced_list_controller.dart)
- [settings_advanced_detail_controller.dart](file://lib/modules/settings/controllers/settings_advanced_detail_controller.dart)
- [settings_basic_controller.dart](file://lib/modules/settings/controllers/settings_basic_controller.dart)
- [settings_organize_scrape_controller.dart](file://lib/modules/settings/controllers/settings_organize_scrape_controller.dart)
- [settings_search_download_controller.dart](file://lib/modules/settings/controllers/settings_search_download_controller.dart)
- [settings_site_options_controller.dart](file://lib/modules/settings/controllers/settings_site_options_controller.dart)
- [settings_site_sync_controller.dart](file://lib/modules/settings/controllers/settings_site_sync_controller.dart)
- [settings_sub_list_controller.dart](file://lib/modules/settings/controllers/settings_sub_list_controller.dart)
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [styles.xml](file://android/app/src/main/res/values/styles.xml)
- [styles.xml (night)](file://android/app/src/main/res/values-night/styles.xml)
- [AppDelegate.swift](file://ios/Runner/AppDelegate.swift)
- [Info.plist](file://ios/Runner/Info.plist)
- [GeneratedPluginRegistrant.java](file://android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java)
- [GeneratedPluginRegistrant.h](file://ios/Runner/GeneratedPluginRegistrant.h)
- [GeneratedPluginRegistrant.m](file://ios/Runner/GeneratedPluginRegistrant.m)
- [flutter_export_environment.sh](file://ios/Flutter/flutter_export_environment.sh)
- [FlutterInputs.xcfilelist](file://macos/Runner/Configs/FlutterInputs.xcfilelist)
- [FlutterOutputs.xcfilelist](file://macos/Runner/Configs/FlutterOutputs.xcfilelist)
- [requirements.txt](file://requirements.txt)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [Dependency Analysis](#dependency-analysis)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Conclusion](#conclusion)
10. [Appendices](#appendices)

## Introduction
This document explains how MoviePilot Mobile manages configuration and customization. It covers environment configuration, feature flags, runtime configuration, localization and internationalization, theming and branding, UI personalization, environment-specific settings, validation, extension points, security considerations, sensitive data handling, and configuration migration strategies. The goal is to help developers and operators configure, extend, and maintain the application effectively across development and production environments.

## Project Structure
MoviePilot Mobile is a Flutter application with platform-specific integrations for Android and iOS, plus macOS support. Configuration surfaces appear in several places:
- Application bootstrap and environment wiring in the main entrypoint
- Localization resources and generation pipeline
- Theme and UI customization via a dedicated theme module
- Settings-driven configuration models and controllers for user-facing customization
- Platform manifests and Gradle/Xcode configuration for environment-specific builds
- Environment definition files for deployment orchestration

```mermaid
graph TB
subgraph "Flutter App"
M["lib/main.dart"]
L["lib/l10n/*"]
T["lib/theme/*"]
S["lib/modules/settings/*"]
end
subgraph "Environment Config"
E[".codex/environments/environment.toml"]
P["pubspec.yaml"]
Y["l10n.yaml"]
end
subgraph "Platform Config"
A["android/app/src/main/AndroidManifest.xml"]
AS["android/app/src/main/res/values/styles.xml"]
AN["android/app/src/main/res/values-night/styles.xml"]
I["ios/Runner/AppDelegate.swift"]
IP["ios/Runner/Info.plist"]
end
M --> L
M --> T
M --> S
P --> Y
Y --> L
E --> M
A --> M
I --> M
AS --> M
AN --> M
IP --> M
```

**Diagram sources**
- [main.dart](file://lib/main.dart)
- [l10n.yaml](file://l10n.yaml)
- [environment.toml](file://.codex/environments/environment.toml)
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [styles.xml](file://android/app/src/main/res/values/styles.xml)
- [styles.xml (night)](file://android/app/src/main/res/values-night/styles.xml)
- [AppDelegate.swift](file://ios/Runner/AppDelegate.swift)
- [Info.plist](file://ios/Runner/Info.plist)

**Section sources**
- [main.dart](file://lib/main.dart)
- [pubspec.yaml](file://pubspec.yaml)
- [l10n.yaml](file://l10n.yaml)
- [environment.toml](file://.codex/environments/environment.toml)
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [styles.xml](file://android/app/src/main/res/values/styles.xml)
- [styles.xml (night)](file://android/app/src/main/res/values-night/styles.xml)
- [AppDelegate.swift](file://ios/Runner/AppDelegate.swift)
- [Info.plist](file://ios/Runner/Info.plist)

## Core Components
- Environment configuration management: centralized via a TOML environment definition and integrated into the Flutter build/runtime via pubspec and platform manifests.
- Feature flags: exposed through settings models and controllers to enable/disable features at runtime.
- Runtime configuration: user-facing settings organized by functional areas (basic, advanced, organize, search/download, site sync/options).
- Localization and internationalization: ARB-backed translations with generated localization delegates and locale resolution.
- Theming and branding: a dedicated theme module for color palettes, typography, and platform-specific styles.
- Security and sensitive data: platform keystore/signing and secure storage integration points for secrets.
- Migration strategies: settings models define current schema; future migrations can evolve models and apply upgrades in controllers.

**Section sources**
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)
- [settings_advanced_config.dart](file://lib/modules/settings/models/settings_advanced_config.dart)
- [settings_basic_config.dart](file://lib/modules/settings/models/settings_basic_config.dart)
- [settings_organize_config.dart](file://lib/modules/settings/models/settings_organize_config.dart)
- [settings_search_download_config.dart](file://lib/modules/settings/models/settings_search_download_config.dart)
- [settings_site_options_config.dart](file://lib/modules/settings/models/settings_site_options_config.dart)
- [settings_site_sync_config.dart](file://lib/modules/settings/models/settings_site_sync_config.dart)
- [app_theme.dart](file://lib/theme/app_theme.dart)
- [l10n.yaml](file://l10n.yaml)
- [app_en.arb](file://lib/l10n/app_en.arb)
- [app_zh.arb](file://lib/l10n/app_zh.arb)

## Architecture Overview
The configuration architecture combines Flutter’s localization and theme systems with a settings-driven model and environment-specific platform configuration.

```mermaid
graph TB
Env["Environment Definition<br/>.codex/environments/environment.toml"]
Pub["pubspec.yaml"]
LGen["l10n.yaml -> ARB Generation"]
Loc["lib/l10n/*"]
Theme["lib/theme/app_theme.dart"]
Settings["lib/modules/settings/*"]
Env --> Pub
Pub --> LGen
LGen --> Loc
Loc --> Settings
Theme --> Settings
Env --> Settings
```

**Diagram sources**
- [environment.toml](file://.codex/environments/environment.toml)
- [pubspec.yaml](file://pubspec.yaml)
- [l10n.yaml](file://l10n.yaml)
- [app_localizations.dart](file://lib/l10n/app_localizations.dart)
- [app_theme.dart](file://lib/theme/app_theme.dart)
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)

## Detailed Component Analysis

### Environment Configuration Management
- Centralized environment definition: a TOML file stores environment variables and feature flags for deployment orchestration.
- Flutter integration: pubspec.yaml defines build-time and localization settings; platform manifests (Android/iOS) consume environment variables for signing and runtime behavior.
- Build-time vs runtime: environment variables are embedded during build; runtime toggles are managed via settings models.

```mermaid
sequenceDiagram
participant Dev as "Developer"
participant Env as "environment.toml"
participant Pub as "pubspec.yaml"
participant Gradle as "Android Gradle"
participant Xcode as "iOS Xcode"
participant App as "main.dart"
Dev->>Env : Define env vars and flags
Dev->>Pub : Reference env in build config
Dev->>Gradle : Inject vars into Android build
Dev->>Xcode : Inject vars into iOS build
Gradle-->>App : Build artifacts with env
Xcode-->>App : Build artifacts with env
App-->>App : Resolve env at startup
```

**Diagram sources**
- [environment.toml](file://.codex/environments/environment.toml)
- [pubspec.yaml](file://pubspec.yaml)
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [AppDelegate.swift](file://ios/Runner/AppDelegate.swift)
- [main.dart](file://lib/main.dart)

**Section sources**
- [environment.toml](file://.codex/environments/environment.toml)
- [pubspec.yaml](file://pubspec.yaml)
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [AppDelegate.swift](file://ios/Runner/AppDelegate.swift)
- [main.dart](file://lib/main.dart)

### Feature Flags and Runtime Configuration
- Feature flags: represented as booleans or enums in settings models; toggled via settings controllers.
- Functional areas:
  - Basic configuration: foundational options.
  - Advanced configuration: power-user options grouped by feature area.
  - Organize and scrape configuration: post-processing and library management.
  - Search and download configuration: scraping and automation preferences.
  - Site options and site synchronization: external service integration settings.
- Controllers coordinate persistence, validation, and UI updates.

```mermaid
classDiagram
class SettingsConfig {
+fields : List<FieldConfig>
+advanced : AdvancedConfig
+basic : BasicConfig
+organize : OrganizeConfig
+searchDownload : SearchDownloadConfig
+siteOptions : SiteOptionsConfig
+siteSync : SiteSyncConfig
}
class SettingsController {
+load()
+save()
+validate()
}
class AdvancedListController
class AdvancedDetailController
class BasicController
class OrganizeScrapeController
class SearchDownloadController
class SiteOptionsController
class SiteSyncController
class SubListController
SettingsController --> SettingsConfig : "loads/saves"
AdvancedListController --> SettingsController : "updates"
AdvancedDetailController --> SettingsController : "updates"
BasicController --> SettingsController : "updates"
OrganizeScrapeController --> SettingsController : "updates"
SearchDownloadController --> SettingsController : "updates"
SiteOptionsController --> SettingsController : "updates"
SiteSyncController --> SettingsController : "updates"
SubListController --> SettingsController : "updates"
```

**Diagram sources**
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)
- [settings_advanced_config.dart](file://lib/modules/settings/models/settings_advanced_config.dart)
- [settings_basic_config.dart](file://lib/modules/settings/models/settings_basic_config.dart)
- [settings_organize_config.dart](file://lib/modules/settings/models/settings_organize_config.dart)
- [settings_search_download_config.dart](file://lib/modules/settings/models/settings_search_download_config.dart)
- [settings_site_options_config.dart](file://lib/modules/settings/models/settings_site_options_config.dart)
- [settings_site_sync_config.dart](file://lib/modules/settings/models/settings_site_sync_config.dart)
- [settings_controller.dart](file://lib/modules/settings/controllers/settings_controller.dart)
- [settings_advanced_list_controller.dart](file://lib/modules/settings/controllers/settings_advanced_list_controller.dart)
- [settings_advanced_detail_controller.dart](file://lib/modules/settings/controllers/settings_advanced_detail_controller.dart)
- [settings_basic_controller.dart](file://lib/modules/settings/controllers/settings_basic_controller.dart)
- [settings_organize_scrape_controller.dart](file://lib/modules/settings/controllers/settings_organize_scrape_controller.dart)
- [settings_search_download_controller.dart](file://lib/modules/settings/controllers/settings_search_download_controller.dart)
- [settings_site_options_controller.dart](file://lib/modules/settings/controllers/settings_site_options_controller.dart)
- [settings_site_sync_controller.dart](file://lib/modules/settings/controllers/settings_site_sync_controller.dart)
- [settings_sub_list_controller.dart](file://lib/modules/settings/controllers/settings_sub_list_controller.dart)

**Section sources**
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)
- [settings_advanced_config.dart](file://lib/modules/settings/models/settings_advanced_config.dart)
- [settings_basic_config.dart](file://lib/modules/settings/models/settings_basic_config.dart)
- [settings_organize_config.dart](file://lib/modules/settings/models/settings_organize_config.dart)
- [settings_search_download_config.dart](file://lib/modules/settings/models/settings_search_download_config.dart)
- [settings_site_options_config.dart](file://lib/modules/settings/models/settings_site_options_config.dart)
- [settings_site_sync_config.dart](file://lib/modules/settings/models/settings_site_sync_config.dart)
- [settings_controller.dart](file://lib/modules/settings/controllers/settings_controller.dart)
- [settings_advanced_list_controller.dart](file://lib/modules/settings/controllers/settings_advanced_list_controller.dart)
- [settings_advanced_detail_controller.dart](file://lib/modules/settings/controllers/settings_advanced_detail_controller.dart)
- [settings_basic_controller.dart](file://lib/modules/settings/controllers/settings_basic_controller.dart)
- [settings_organize_scrape_controller.dart](file://lib/modules/settings/controllers/settings_organize_scrape_controller.dart)
- [settings_search_download_controller.dart](file://lib/modules/settings/controllers/settings_search_download_controller.dart)
- [settings_site_options_controller.dart](file://lib/modules/settings/controllers/settings_site_options_controller.dart)
- [settings_site_sync_controller.dart](file://lib/modules/settings/controllers/settings_site_sync_controller.dart)
- [settings_sub_list_controller.dart](file://lib/modules/settings/controllers/settings_sub_list_controller.dart)

### Localization Setup and Internationalization
- Translation source files: ARB files under lib/l10n define localized keys and fallbacks.
- Localization generation: l10n.yaml drives the code generation pipeline to produce strongly-typed delegates.
- Locale resolution: the generated delegate resolves locales at runtime; platform-specific resources support light/dark themes.

```mermaid
flowchart TD
Start(["Localization Init"]) --> LoadARB["Load ARB Files<br/>lib/l10n/*.arb"]
LoadARB --> GenCode["Generate Localizations<br/>l10n.yaml"]
GenCode --> Delegate["Localized Delegate"]
Delegate --> Resolve["Resolve Locale at Runtime"]
Resolve --> ApplyTheme["Apply Platform Styles<br/>values/styles.xml (+ night)"]
ApplyTheme --> End(["UI Rendered"])
```

**Diagram sources**
- [l10n.yaml](file://l10n.yaml)
- [app_en.arb](file://lib/l10n/app_en.arb)
- [app_zh.arb](file://lib/l10n/app_zh.arb)
- [app_localizations.dart](file://lib/l10n/app_localizations.dart)
- [styles.xml](file://android/app/src/main/res/values/styles.xml)
- [styles.xml (night)](file://android/app/src/main/res/values-night/styles.xml)

**Section sources**
- [l10n.yaml](file://l10n.yaml)
- [app_en.arb](file://lib/l10n/app_en.arb)
- [app_zh.arb](file://lib/l10n/app_zh.arb)
- [app_localizations.dart](file://lib/l10n/app_localizations.dart)
- [styles.xml](file://android/app/src/main/res/values/styles.xml)
- [styles.xml (night)](file://android/app/src/main/res/values-night/styles.xml)

### Theme Customization and Branding
- Central theme module: app_theme.dart encapsulates color schemes, typography, and brand tokens.
- Platform-specific styles: Android values and values-night styles.xml tailor UI appearance per mode.
- Branding assets: logos and images under assets/images support branding across UI.

```mermaid
graph LR
Theme["lib/theme/app_theme.dart"]
AStyles["android/app/src/main/res/values/styles.xml"]
NStyles["android/app/src/main/res/values-night/styles.xml"]
Assets["assets/images/logos/*"]
Theme --> AStyles
Theme --> NStyles
Assets --> Theme
```

**Diagram sources**
- [app_theme.dart](file://lib/theme/app_theme.dart)
- [styles.xml](file://android/app/src/main/res/values/styles.xml)
- [styles.xml (night)](file://android/app/src/main/res/values-night/styles.xml)

**Section sources**
- [app_theme.dart](file://lib/theme/app_theme.dart)
- [styles.xml](file://android/app/src/main/res/values/styles.xml)
- [styles.xml (night)](file://android/app/src/main/res/values-night/styles.xml)

### Environment-Specific Configurations (Dev vs Prod)
- Android: environment variables injected via Gradle; signing configs and manifest placeholders configured for build variants.
- iOS: environment variables exported via shell scripts and consumed by Xcode build settings; Info.plist entries reflect environment.
- macOS: similar environment wiring via Flutter configuration lists.

```mermaid
sequenceDiagram
participant Gradle as "Android Gradle"
participant Xcode as "iOS Xcode"
participant MacCfg as "macOS Flutter Cfg"
participant Manifest as "AndroidManifest.xml"
participant Plist as "Info.plist"
Gradle->>Manifest : Inject env placeholders
Xcode->>Plist : Inject env keys
MacCfg->>MacCfg : Resolve inputs/outputs
```

**Diagram sources**
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [flutter_export_environment.sh](file://ios/Flutter/flutter_export_environment.sh)
- [Info.plist](file://ios/Runner/Info.plist)
- [FlutterInputs.xcfilelist](file://macos/Runner/Configs/FlutterInputs.xcfilelist)
- [FlutterOutputs.xcfilelist](file://macos/Runner/Configs/FlutterOutputs.xcfilelist)

**Section sources**
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [flutter_export_environment.sh](file://ios/Flutter/flutter_export_environment.sh)
- [Info.plist](file://ios/Runner/Info.plist)
- [FlutterInputs.xcfilelist](file://macos/Runner/Configs/FlutterInputs.xcfilelist)
- [FlutterOutputs.xcfilelist](file://macos/Runner/Configs/FlutterOutputs.xcfilelist)

### Configuration Validation
- Settings models define field-level validation rules and constraints.
- Controllers orchestrate validation before persisting changes.
- Runtime checks ensure invalid combinations are prevented.

```mermaid
flowchart TD
Enter(["User Change"]) --> Validate["Validate Settings Model"]
Validate --> Valid{"Valid?"}
Valid --> |No| ShowError["Show Validation Error"]
Valid --> |Yes| Persist["Persist to Storage"]
Persist --> Refresh["Refresh UI"]
ShowError --> Wait["Await Correction"]
Wait --> Enter
```

**Diagram sources**
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)
- [settings_controller.dart](file://lib/modules/settings/controllers/settings_controller.dart)

**Section sources**
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)
- [settings_controller.dart](file://lib/modules/settings/controllers/settings_controller.dart)

### Extension Points and Advanced User Settings
- Settings controllers expose extension hooks for custom fields and actions.
- Field configuration supports diverse input types and rendering hints.
- Advanced controllers handle complex workflows (e.g., advanced list/detail, organize/scrape, site sync/options).

```mermaid
classDiagram
class FieldConfig {
+key : String
+type : FieldType
+visuals : OptionVisuals
}
class OptionVisuals {
+label : String
+description : String
+group : String
}
FieldConfig --> OptionVisuals : "rendering hints"
```

**Diagram sources**
- [settings_field_config.dart](file://lib/modules/settings/models/settings_field_config.dart)
- [settings_option_visuals.dart](file://lib/modules/settings/models/settings_option_visuals.dart)

**Section sources**
- [settings_field_config.dart](file://lib/modules/settings/models/settings_field_config.dart)
- [settings_option_visuals.dart](file://lib/modules/settings/models/settings_option_visuals.dart)

### Configuration Security and Sensitive Data Handling
- Secrets and credentials: platform keystore/signing and secure storage integration points are used to protect sensitive data.
- Environment variables: avoid embedding secrets directly in source; rely on platform-managed keystores and secure storage APIs.
- Plugin registration: GeneratedPluginRegistrant integrates plugins securely at build time.

```mermaid
graph LR
Secrets["Secure Storage / Keystore"] --> Controllers["Settings Controllers"]
Controllers --> UI["Settings UI"]
Plugins["GeneratedPluginRegistrant.*"] --> Controllers
```

**Diagram sources**
- [GeneratedPluginRegistrant.java](file://android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java)
- [GeneratedPluginRegistrant.h](file://ios/Runner/GeneratedPluginRegistrant.h)
- [GeneratedPluginRegistrant.m](file://ios/Runner/GeneratedPluginRegistrant.m)

**Section sources**
- [GeneratedPluginRegistrant.java](file://android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java)
- [GeneratedPluginRegistrant.h](file://ios/Runner/GeneratedPluginRegistrant.h)
- [GeneratedPluginRegistrant.m](file://ios/Runner/GeneratedPluginRegistrant.m)

### Configuration Migration Strategies
- Current schema: settings models define the present configuration surface.
- Migration approach: evolve models and controllers to handle schema changes; apply upgrades on load with backward compatibility checks.
- Recommendations: version fields, safe defaults, and rollback strategies for breaking changes.

**Section sources**
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)
- [settings_advanced_config.dart](file://lib/modules/settings/models/settings_advanced_config.dart)
- [settings_basic_config.dart](file://lib/modules/settings/models/settings_basic_config.dart)
- [settings_organize_config.dart](file://lib/modules/settings/models/settings_organize_config.dart)
- [settings_search_download_config.dart](file://lib/modules/settings/models/settings_search_download_config.dart)
- [settings_site_options_config.dart](file://lib/modules/settings/models/settings_site_options_config.dart)
- [settings_site_sync_config.dart](file://lib/modules/settings/models/settings_site_sync_config.dart)

## Dependency Analysis
Configuration dependencies span Flutter localization, theme, settings models, and platform build systems.

```mermaid
graph TB
L10N["l10n.yaml"] --> ARBs["lib/l10n/*.arb"]
ARBs --> Localizations["app_localizations.dart"]
Theme["lib/theme/app_theme.dart"] --> UI["UI Components"]
Settings["settings models/controllers"] --> UI
Env["environment.toml"] --> Build["pubspec.yaml"]
Build --> Android["AndroidManifest.xml"]
Build --> iOS["Info.plist"]
```

**Diagram sources**
- [l10n.yaml](file://l10n.yaml)
- [app_en.arb](file://lib/l10n/app_en.arb)
- [app_zh.arb](file://lib/l10n/app_zh.arb)
- [app_localizations.dart](file://lib/l10n/app_localizations.dart)
- [app_theme.dart](file://lib/theme/app_theme.dart)
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)
- [environment.toml](file://.codex/environments/environment.toml)
- [pubspec.yaml](file://pubspec.yaml)
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [Info.plist](file://ios/Runner/Info.plist)

**Section sources**
- [l10n.yaml](file://l10n.yaml)
- [app_localizations.dart](file://lib/l10n/app_localizations.dart)
- [app_theme.dart](file://lib/theme/app_theme.dart)
- [settings_config.dart](file://lib/modules/settings/models/settings_config.dart)
- [environment.toml](file://.codex/environments/environment.toml)
- [pubspec.yaml](file://pubspec.yaml)
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [Info.plist](file://ios/Runner/Info.plist)

## Performance Considerations
- Keep localization keys minimal and hierarchical to reduce bundle size.
- Defer heavy initialization until after environment is resolved.
- Cache validated settings to avoid repeated computation.
- Use platform-specific resource qualifiers to optimize theme rendering.

## Troubleshooting Guide
- Localization not applied:
  - Verify l10n.yaml targets correct ARB paths.
  - Confirm app_localizations.dart was regenerated after ARB changes.
- Theme inconsistencies:
  - Check platform styles.xml and values-night/styles.xml for overrides.
- Settings not persisting:
  - Ensure controllers call save() and validate() before applying.
- Environment variables missing:
  - Confirm Gradle/Xcode build injects placeholders and Info.plist entries.

**Section sources**
- [l10n.yaml](file://l10n.yaml)
- [app_localizations.dart](file://lib/l10n/app_localizations.dart)
- [styles.xml](file://android/app/src/main/res/values/styles.xml)
- [styles.xml (night)](file://android/app/src/main/res/values-night/styles.xml)
- [settings_controller.dart](file://lib/modules/settings/controllers/settings_controller.dart)
- [AndroidManifest.xml](file://android/app/src/main/AndroidManifest.xml)
- [Info.plist](file://ios/Runner/Info.plist)

## Conclusion
MoviePilot Mobile’s configuration and customization framework combines environment-driven settings, robust localization, and a flexible theming system. By leveraging settings models and controllers, developers can introduce feature flags, personalize UI, and manage environment-specific behavior while maintaining strong validation and security practices. Migration strategies should evolve models carefully to preserve backward compatibility.

## Appendices
- Additional platform configuration files:
  - Android Gradle and properties files for build customization.
  - iOS CocoaPods and entitlements for secure capabilities.
  - macOS Flutter configuration lists for environment resolution.

**Section sources**
- [requirements.txt](file://requirements.txt)